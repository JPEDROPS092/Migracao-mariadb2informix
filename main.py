import tkinter as tk
import os
import json
import threading
import traceback
from tkinter import ttk, messagebox, filedialog, scrolledtext
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict

# Database connectors
try:
    import mysql.connector
    MYSQL_AVAILABLE = True
except ImportError:
    MYSQL_AVAILABLE = False
    print("AVISO: mysql-connector-python não encontrado. Funcionalidades MariaDB serão limitadas.")
    print("Instale com: pip install mysql-connector-python")

try:
    import ifxpy  # Para Informix
    INFORMIX_AVAILABLE = True
except ImportError:
    INFORMIX_AVAILABLE = False
    print("AVISO: ifxpy não encontrado. Funcionalidades Informix (conexão direta) serão limitadas.")
    print("Instale com: pip install ifxpy")
    print("Lembre-se que ifxpy requer o driver do Informix (IBM Informix Client SDK) instalado e configurado no sistema.")

@dataclass
class Column:
    name: str
    data_type: str
    max_length: Optional[int] = None
    is_nullable: bool = True
    default_value: Optional[str] = None
    is_primary_key: bool = False
    is_auto_increment: bool = False

@dataclass
class Table:
    name: str
    columns: List[Column]
    row_count: int = 0

@dataclass
class MigrationConfig:
    source_host: str
    source_port: int
    source_database: str
    source_user: str
    source_password: str
    target_host: str
    target_port: int
    target_database: str
    target_user: str
    target_password: str
    selected_tables: List[str]
    migrate_data: bool = True
    batch_size: int = 1000

class TypeMapper:
    """Mapeia tipos MariaDB para Informix"""

    MARIADB_TO_INFORMIX = {
        'TINYINT': 'SMALLINT',
        'SMALLINT': 'SMALLINT',
        'MEDIUMINT': 'INTEGER',
        'INT': 'INTEGER',
        'INTEGER': 'INTEGER',
        'BIGINT': 'BIGINT',
        'DECIMAL': 'DECIMAL',
        'NUMERIC': 'DECIMAL',
        'FLOAT': 'REAL', # MariaDB FLOAT is single-precision
        'DOUBLE': 'FLOAT', # MariaDB DOUBLE is double-precision, maps to Informix FLOAT
        'REAL': 'FLOAT', # MariaDB REAL is an alias for DOUBLE
        'BIT': 'BOOLEAN',
        'BOOL': 'BOOLEAN',
        'BOOLEAN': 'BOOLEAN',
        'CHAR': 'CHAR',
        'VARCHAR': 'VARCHAR',
        'BINARY': 'BYTE',
        'VARBINARY': 'BYTE',
        'TINYBLOB': 'BYTE',
        'BLOB': 'BYTE',
        'MEDIUMBLOB': 'BYTE',
        'LONGBLOB': 'BYTE',
        'TINYTEXT': 'LVARCHAR',
        'TEXT': 'TEXT',
        'MEDIUMTEXT': 'TEXT',
        'LONGTEXT': 'TEXT',
        'ENUM': 'VARCHAR', # Needs careful handling of length
        'SET': 'VARCHAR',  # Needs careful handling of length
        'DATE': 'DATE',
        'TIME': 'DATETIME HOUR TO SECOND',
        'DATETIME': 'DATETIME YEAR TO SECOND',
        'TIMESTAMP': 'DATETIME YEAR TO SECOND',
        'YEAR': 'SMALLINT', # Informix doesn't have a YEAR type, SMALLINT is a common mapping
        'JSON': 'LVARCHAR' # Or JSON/BSON type if Informix version supports it and driver handles it
    }

    @classmethod
    def map_type(cls, mariadb_type: str, length: Optional[int] = None, precision: Optional[int] = None, scale: Optional[int] = None) -> str:
        base_type = mariadb_type.upper().split('(')[0]  # Remove any size/precision from type name
        informix_type = cls.MARIADB_TO_INFORMIX.get(base_type)
        
        if not informix_type:
            return 'VARCHAR(255)'  # Default fallback type
            
        # Add length/precision/scale where appropriate
        if base_type in ['CHAR', 'VARCHAR', 'BINARY', 'VARBINARY']:
            length = length or 255  # Default length if none specified
            return f"{informix_type}({length})"
        elif base_type in ['DECIMAL', 'NUMERIC']:
            p = precision or 10  # Default precision
            s = scale or 0      # Default scale
            return f"{informix_type}({p},{s})"
        
        return informix_type


class MariaDBExtractor:
    def __init__(self):
        self.connection = None

    def connect(self, config: Dict[str, Any]) -> bool:
        if not MYSQL_AVAILABLE:
            raise RuntimeError("MySQL connector não está disponível")
        try:
            self.connection = mysql.connector.connect(
                host=config['source_host'],
                port=config['source_port'],
                database=config['source_database'],
                user=config['source_user'],
                password=config['source_password']
            )
            return True
        except mysql.connector.Error as e:
            raise RuntimeError(f"Erro ao conectar ao MariaDB: {str(e)}")
        except Exception as e:
            raise RuntimeError(f"Erro inesperado: {str(e)}")

    def get_tables(self) -> List[str]:
        if not self.connection:
            raise RuntimeError("Não conectado ao banco de dados")
        cursor = self.connection.cursor()
        cursor.execute("SHOW FULL TABLES WHERE Table_Type = 'BASE TABLE'") # Ignora views
        tables = [table[0] for table in cursor.fetchall()]
        cursor.close()
        return tables

    def get_table_info(self, table_name: str) -> Table:
        if not self.connection:
            raise RuntimeError("Não conectado ao banco de dados")
        cursor = self.connection.cursor()

        # Obter estrutura da tabela
        cursor.execute(f"DESCRIBE `{table_name}`")
        columns_info_raw = cursor.fetchall()

        # Obter informações mais detalhadas de INFORMATION_SCHEMA
        cursor.execute("""
            SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
                   NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE,
                   COLUMN_DEFAULT, COLUMN_KEY, EXTRA
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """, (table_name,))
        schema_columns_info = {row[0]: row for row in cursor.fetchall()}

        columns = []
        for col_raw in columns_info_raw:
            field_name = col_raw[0]
            schema_info = schema_columns_info[field_name]
            
            column = Column(
                name=field_name,
                data_type=schema_info[1].upper(),
                max_length=schema_info[2],
                is_nullable=schema_info[5] == 'YES',
                default_value=schema_info[6],
                is_primary_key=col_raw[3] == 'PRI',
                is_auto_increment='auto_increment' in col_raw[5].lower() if col_raw[5] else False
            )
            columns.append(column)

        # Obter contagem de registros
        cursor.execute(f"SELECT COUNT(*) FROM `{table_name}`")
        row_count = cursor.fetchone()[0]

        cursor.close()
        return Table(name=table_name, columns=columns, row_count=row_count)

    def get_table_data(self, table_name: str, batch_size: int, offset: int) -> List[Dict]:
        if not self.connection:
            raise RuntimeError("Não conectado ao banco de dados")
        
        cursor = self.connection.cursor(dictionary=True, buffered=True)
        query = f"SELECT * FROM `{table_name}` LIMIT %s OFFSET %s"
        
        try:
            cursor.execute(query, (batch_size, offset))
            data = cursor.fetchall()
            return data
        except mysql.connector.Error as e:
            raise RuntimeError(f"Erro ao obter dados da tabela {table_name}: {str(e)}")
        finally:
            cursor.close()

    def close(self):
        if self.connection and self.connection.is_connected():
            self.connection.close()

class InformixGenerator:
    @staticmethod
    def generate_create_table(table: Table) -> str:
        sql_parts = [f"CREATE TABLE {table.name} ("]
        column_definitions = []
        for column in table.columns:
            # Passar precisão e escala para o TypeMapper
            informix_type = TypeMapper.map_type(
                column.data_type,
                column.max_length,
                getattr(column, 'precision', None),
                getattr(column, 'scale', None)
            )
            col_def = f"    {column.name} {informix_type}"

            if column.is_auto_increment:
                if informix_type == 'BIGINT':
                    col_def += " BIGSERIAL"
                else:
                    col_def += " SERIAL"
            
            if not column.is_nullable:
                col_def += " NOT NULL"

            if not column.is_auto_increment and column.default_value is not None:
                if column.data_type.upper() in ['VARCHAR', 'CHAR', 'TEXT', 'LVARCHAR', 'ENUM', 'SET', 'JSON', 'DATE', 'TIME', 'DATETIME', 'TIMESTAMP']:
                    if str(column.default_value).upper() in ("CURRENT_TIMESTAMP", "NOW()"):
                         col_def += " DEFAULT CURRENT YEAR TO SECOND"
                    elif str(column.default_value).upper() == "NULL":
                        pass
                    else:
                        default_val = str(column.default_value).replace("'", "''")
                        col_def += f" DEFAULT '{default_val}'"
                elif column.data_type.upper() in ['BIT', 'BOOL', 'BOOLEAN']:
                    if str(column.default_value).lower() in ['1', 'true', 't']:
                        col_def += " DEFAULT 't'"
                    elif str(column.default_value).lower() in ['0', 'false', 'f']:
                        col_def += " DEFAULT 'f'"
                else:
                    try:
                        num_val = float(column.default_value)
                        col_def += f" DEFAULT {num_val}"
                    except (ValueError, TypeError):
                         if str(column.default_value).upper() != "NULL":
                            default_val = str(column.default_value).replace("'", "''")
                            col_def += f" DEFAULT '{default_val}'"

            column_definitions.append(col_def)

        pk_columns = [col.name for col in table.columns if col.is_primary_key]
        if pk_columns:
            column_definitions.append(f"    PRIMARY KEY ({', '.join(pk_columns)})")

        sql_parts.append(',\n'.join(column_definitions))
        sql_parts.append(");")

        return '\n'.join(sql_parts)


    @staticmethod
    def generate_insert_statements(table: Table, data: List[Dict]) -> List[str]:
        if not data:
            return []

        statements = []
        # Colunas para INSERT não devem incluir as auto_increment (SERIAL/BIGSERIAL)
        columns_for_insert = [col.name for col in table.columns if not col.is_auto_increment]
        
        if not columns_for_insert: # Caso todas as colunas sejam auto_increment (raro, mas possível)
            # Informix requer `INSERT INTO table VALUES (0)` or `DEFAULT` for single SERIAL column
            # Se houver múltiplas colunas SERIAL, a sintaxe de INSERT pode ser mais complexa
            # ou a tabela pode não ser populável diretamente desta forma.
            # Para este caso simplificado, se não há colunas não-SERIAL, não geramos INSERTs.
            # Ou, se for uma única coluna SERIAL, pode-se usar:
            # if len(table.columns) == 1 and table.columns[0].is_auto_increment:
            #     for _ in data: # data aqui seria apenas para contar quantos inserts
            #         statements.append(f"INSERT INTO {table.name} ({table.columns[0].name}) VALUES (0);") # Ou DEFAULT
            return []


        for row in data:
            values = []
            for col_name in columns_for_insert:
                value = row.get(col_name) # MariaDB connector com dictionary=True retorna dict
                
                # Encontrar o tipo da coluna MariaDB para formatação correta
                source_column_type = ""
                for col_obj in table.columns:
                    if col_obj.name == col_name:
                        source_column_type = col_obj.data_type.upper()
                        break

                if value is None:
                    values.append('NULL')
                elif isinstance(value, datetime):
                    # Handle all datetime types in one block
                    if hasattr(value, 'hour') and hasattr(value, 'minute'):  # Has time component
                        if hasattr(value, 'year'):  # Full datetime
                            values.append(f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'") # DATETIME YEAR TO SECOND
                        else:  # Just time
                            values.append(f"'{value.strftime('%H:%M:%S')}'") # DATETIME HOUR TO SECOND
                    else:  # Just date
                        values.append(f"'{value.strftime('%Y-%m-%d')}'") # DATE
                elif isinstance(value, (bytes, bytearray)):
                    # Para BYTE/VARBYTE no Informix, usaremos a função HEX() para scripts puros SQL.
                    # Isso é uma abordagem simplificada que funciona para scripts SQL.
                    hex_value = value.hex()
                    # Para tamanhos grandes, dividimos em chunks para evitar problemas com linha muito longa
                    max_chunk = 1000  # Tamanho máximo por linha de SQL
                    if len(hex_value) > max_chunk:
                        chunks = [hex_value[i:i+max_chunk] for i in range(0, len(hex_value), max_chunk)]
                        concat = "DECODE(" + " || ".join(f"'{chunk}'" for chunk in chunks) + ", 'hex')"
                        values.append(concat)
                    else:
                        values.append(f"DECODE('{hex_value}', 'hex')")
                elif isinstance(value, str):
                    escaped_value = value.replace("'", "''") # Escapar aspas simples
                    values.append(f"'{escaped_value}'")
                elif isinstance(value, (int, float)):
                    values.append(str(value))
                elif source_column_type == 'BIT' or source_column_type == 'BOOLEAN': # MariaDB BIT(1) ou BOOL
                    values.append("'t'" if value else "'f'") # Informix BOOLEAN 't' ou 'f'
                else:
                    # Fallback para outros tipos, tentando converter para string e escapar
                    escaped_value = str(value).replace("'", "''")
                    values.append(f"'{escaped_value}'")

            sql = f"INSERT INTO {table.name} ({', '.join(columns_for_insert)}) VALUES ({', '.join(values)});"
            statements.append(sql)

        return statements

class MigrationApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Migrador MariaDB para Informix (Gerador de Scripts)")
        self.root.geometry("1000x700")

        self.extractor = MariaDBExtractor()
        self.tables_info: Dict[str, Table] = {} # type hint
        self.migration_running = False

        self.setup_ui()
        self.check_dependencies() # Chamada aqui para logar no terminal cedo

    def check_dependencies(self):
        python_missing = []
        if not MYSQL_AVAILABLE:
            python_missing.append("mysql-connector-python")
        if not INFORMIX_AVAILABLE:
            python_missing.append("pyodbc")

        print("\n--- Verificação de Dependências ---")
        if python_missing:
            install_command = "pip install " + " ".join(python_missing)
            msg_gui = (
                f"Bibliotecas Python não encontradas:\n{', '.join(python_missing)}\n\n"
                f"Instale com: {install_command}\n\n"
                "Adicionalmente, para conectar ao Informix via pyodbc (se a migração direta fosse implementada aqui), "
                "o driver IBM Informix ODBC (parte do Client SDK/CSDK) deve estar instalado e configurado no sistema."
            )
            msg_terminal = (
                f"AVISO: Bibliotecas Python não encontradas: {', '.join(python_missing)}.\n"
                f"Tente instalar com: {install_command}\n"
                "Lembre-se: Para o pyodbc se conectar ao Informix, o driver IBM Informix ODBC "
                "(parte do Client SDK/CSDK) precisa estar instalado e configurado no seu sistema operacional. "
                "Esta aplicação não pode instalá-lo para você. A migração direta para Informix NÃO está implementada, apenas geração de scripts."
            )
            messagebox.showwarning("Dependências Ausentes", msg_gui)
            print(msg_terminal)
        else:
            print("INFO: As bibliotecas Python mysql-connector-python e pyodbc foram encontradas.")
            print("INFO: Esta aplicação foca na GERAÇÃO DE SCRIPTS SQL. A conexão direta com Informix (usando pyodbc)\n"
                  "      para executar os scripts não está implementada aqui. Para isso, o IBM Informix Client SDK (ODBC driver)\n"
                  "      deve estar instalado e configurado no sistema onde os scripts seriam executados (ex: com dbaccess ou uma ferramenta Python).")

        if not MYSQL_AVAILABLE:
            print("PROBLEMA POTENCIAL: Conexão com MariaDB e extração de dados falhará sem 'mysql-connector-python'.")
        # Como o foco é geração de scripts, a ausência de pyodbc é menos crítica para a funcionalidade principal,
        # mas ainda é bom avisar se o usuário espera conexão direta.
        if not INFORMIX_AVAILABLE:
            print("AVISO: A biblioteca 'pyodbc' não foi encontrada. Se uma funcionalidade de conexão direta com Informix fosse adicionada, ela não funcionaria.\n"
                  "       Mesmo com 'pyodbc', a conexão falharia sem o driver ODBC do Informix instalado no sistema.")
        print("-----------------------------------\n")


    def setup_ui(self):
        # Notebook para abas
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Aba de Configuração
        config_frame = ttk.Frame(notebook)
        notebook.add(config_frame, text="Configuração")
        self.setup_config_tab(config_frame)

        # Aba de Seleção de Tabelas
        tables_frame = ttk.Frame(notebook)
        notebook.add(tables_frame, text="Tabelas")
        self.setup_tables_tab(tables_frame)

        # Aba de Geração de Scripts (anteriormente Migração)
        scripts_frame = ttk.Frame(notebook)
        notebook.add(scripts_frame, text="Geração de Scripts") # Renomeado
        self.setup_scripts_tab(scripts_frame) # Renomeado

        # Aba de Log
        log_frame = ttk.Frame(notebook)
        notebook.add(log_frame, text="Log")
        self.setup_log_tab(log_frame)

    def setup_config_tab(self, parent):
        # Frame para MariaDB
        maria_frame = ttk.LabelFrame(parent, text="MariaDB (Origem)")
        maria_frame.pack(fill=tk.X, padx=10, pady=5, ipadx=5, ipady=5)

        ttk.Label(maria_frame, text="Host:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        self.maria_host = ttk.Entry(maria_frame, width=30)
        self.maria_host.insert(0, "localhost")
        self.maria_host.grid(row=0, column=1, padx=5, pady=2)

        ttk.Label(maria_frame, text="Porta:").grid(row=0, column=2, sticky=tk.W, padx=5, pady=2)
        self.maria_port = ttk.Entry(maria_frame, width=10)
        self.maria_port.insert(0, "3306")
        self.maria_port.grid(row=0, column=3, padx=5, pady=2)

        ttk.Label(maria_frame, text="Database:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        self.maria_db = ttk.Entry(maria_frame, width=30)
        self.maria_db.grid(row=1, column=1, padx=5, pady=2)

        ttk.Label(maria_frame, text="Usuário:").grid(row=1, column=2, sticky=tk.W, padx=5, pady=2)
        self.maria_user = ttk.Entry(maria_frame, width=20)
        self.maria_user.grid(row=1, column=3, padx=5, pady=2)

        ttk.Label(maria_frame, text="Senha:").grid(row=2, column=0, sticky=tk.W, padx=5, pady=2)
        self.maria_pass = ttk.Entry(maria_frame, width=30, show="*")
        self.maria_pass.grid(row=2, column=1, padx=5, pady=2)

        ttk.Button(maria_frame, text="Testar Conexão",
                  command=self.test_mariadb_connection).grid(row=2, column=3, padx=5, pady=5)

        # Frame para Informix (mantido para contexto, mas sem teste de conexão)
        informix_frame = ttk.LabelFrame(parent, text="Informix (Destino - para referência nos scripts)")
        informix_frame.pack(fill=tk.X, padx=10, pady=5, ipadx=5, ipady=5)
        
        ttk.Label(informix_frame, text="Nome do Servidor (Informix Server):").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        self.informix_server_name = ttk.Entry(informix_frame, width=30) # Para dbaccess
        self.informix_server_name.insert(0, "minstance_net") # Exemplo
        self.informix_server_name.grid(row=0, column=1, padx=5, pady=2)

        ttk.Label(informix_frame, text="Nome do Database:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        self.informix_db_name_script = ttk.Entry(informix_frame, width=30) # Para dbaccess
        self.informix_db_name_script.insert(0, "mydatabase") # Exemplo
        self.informix_db_name_script.grid(row=1, column=1, padx=5, pady=2)


        # Opções de Geração
        options_frame = ttk.LabelFrame(parent, text="Opções de Geração de Scripts")
        options_frame.pack(fill=tk.X, padx=10, pady=5, ipadx=5, ipady=5)

        self.migrate_data_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Gerar scripts de DADOS (INSERTs)",
                       variable=self.migrate_data_var).pack(anchor=tk.W, padx=5, pady=2)

        batch_frame = ttk.Frame(options_frame)
        batch_frame.pack(fill=tk.X, padx=5, pady=2, anchor=tk.W)
        ttk.Label(batch_frame, text="Tamanho do lote para leitura de dados de MariaDB:").pack(side=tk.LEFT)
        self.batch_size_entry = ttk.Entry(batch_frame, width=10) # Renomeado para evitar conflito
        self.batch_size_entry.insert(0, "1000")
        self.batch_size_entry.pack(side=tk.LEFT, padx=5)

        # Botões de ação
        action_frame = ttk.Frame(parent)
        action_frame.pack(fill=tk.X, padx=10, pady=10)

        ttk.Button(action_frame, text="Carregar Tabelas de MariaDB",
                  command=self.load_tables).pack(side=tk.LEFT, padx=5)
        ttk.Button(action_frame, text="Salvar Configuração",
                  command=self.save_config).pack(side=tk.LEFT, padx=5)
        ttk.Button(action_frame, text="Carregar Configuração",
                  command=self.load_config).pack(side=tk.LEFT, padx=5)

    def setup_tables_tab(self, parent):
        main_frame = ttk.Frame(parent)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        tables_frame = ttk.LabelFrame(main_frame, text="Selecionar Tabelas para Geração de Scripts")
        tables_frame.pack(fill=tk.BOTH, expand=True, pady=5)

        columns = ('Selecionar', 'Nome', 'Colunas', 'Registros') # Removido Tamanho Estimado por simplicidade
        self.tables_tree = ttk.Treeview(tables_frame, columns=columns, show='headings', height=15)

        self.tables_tree.heading('Selecionar', text='Sel.')
        self.tables_tree.column('Selecionar', width=50, anchor=tk.CENTER)
        self.tables_tree.heading('Nome', text='Nome')
        self.tables_tree.column('Nome', width=250)
        self.tables_tree.heading('Colunas', text='Colunas')
        self.tables_tree.column('Colunas', width=100, anchor=tk.CENTER)
        self.tables_tree.heading('Registros', text='Registros')
        self.tables_tree.column('Registros', width=100, anchor=tk.E)
        
        self.tables_tree.bind('<ButtonRelease-1>', self.toggle_table_selection_treeview)


        scrollbar = ttk.Scrollbar(tables_frame, orient=tk.VERTICAL, command=self.tables_tree.yview)
        self.tables_tree.configure(yscrollcommand=scrollbar.set)
        self.tables_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        selection_frame = ttk.Frame(main_frame)
        selection_frame.pack(fill=tk.X, pady=5)
        ttk.Button(selection_frame, text="Selecionar Todas",
                  command=lambda: self.toggle_all_tables(True)).pack(side=tk.LEFT, padx=5)
        ttk.Button(selection_frame, text="Desselecionar Todas",
                  command=lambda: self.toggle_all_tables(False)).pack(side=tk.LEFT, padx=5)
        ttk.Button(selection_frame, text="Ver Estrutura Mapeada",
                  command=self.view_table_structure).pack(side=tk.LEFT, padx=5)

    # Nova função para lidar com cliques na Treeview
    def toggle_table_selection_treeview(self, event):
        item_id = self.tables_tree.identify_row(event.y)
        if not item_id:
            return
        
        column_id = self.tables_tree.identify_column(event.x)
        if column_id == '#1': # Somente se clicou na primeira coluna (Seleção)
            current_values = list(self.tables_tree.item(item_id, 'values'))
            current_name = current_values[1] # Nome da tabela
            is_selected = self.tables_tree.set(item_id, 'Selecionar') == '✓'

            if is_selected:
                self.tables_tree.set(item_id, 'Selecionar', '')
            else:
                self.tables_tree.set(item_id, 'Selecionar', '✓')


    def toggle_all_tables(self, select=True):
        for item_id in self.tables_tree.get_children():
            self.tables_tree.set(item_id, 'Selecionar', '✓' if select else '')


    def setup_scripts_tab(self, parent): # Renomeado de setup_migration_tab
        progress_frame = ttk.LabelFrame(parent, text="Progresso da Geração de Scripts")
        progress_frame.pack(fill=tk.X, padx=10, pady=10, ipadx=5, ipady=5)

        self.progress_var = tk.StringVar(value="Pronto para gerar scripts")
        ttk.Label(progress_frame, textvariable=self.progress_var).pack(pady=5, anchor=tk.W, padx=10)

        self.progress_bar = ttk.Progressbar(progress_frame, mode='determinate')
        self.progress_bar.pack(fill=tk.X, padx=10, pady=5)

        control_frame = ttk.Frame(progress_frame)
        control_frame.pack(pady=10)

        self.generate_button = ttk.Button(control_frame, text="Gerar Scripts SQL",
                                      command=self.start_script_generation) # Comando alterado
        self.generate_button.pack(side=tk.LEFT, padx=5)

        self.stop_button = ttk.Button(control_frame, text="Parar Geração", # Texto alterado
                                     command=self.stop_script_generation, state=tk.DISABLED) # Comando alterado
        self.stop_button.pack(side=tk.LEFT, padx=5)

        summary_frame = ttk.LabelFrame(parent, text="Resumo da Geração")
        summary_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10, ipadx=5, ipady=5)
        self.summary_text = scrolledtext.ScrolledText(summary_frame, height=15, wrap=tk.WORD)
        self.summary_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.summary_text.configure(state='disabled') # Read-only

    def setup_log_tab(self, parent):
        log_frame_outer = ttk.LabelFrame(parent, text="Log de Eventos")
        log_frame_outer.pack(fill=tk.BOTH, expand=True, padx=10, pady=10, ipadx=5, ipady=5)

        self.log_text = scrolledtext.ScrolledText(log_frame_outer, height=25, wrap=tk.WORD)
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.log_text.configure(state='disabled') # Read-only

        log_buttons = ttk.Frame(log_frame_outer)
        log_buttons.pack(fill=tk.X, pady=5, padx=5)
        ttk.Button(log_buttons, text="Limpar Log", command=self.clear_log).pack(side=tk.LEFT, padx=5)
        ttk.Button(log_buttons, text="Salvar Log", command=self.save_log).pack(side=tk.LEFT, padx=5)

    def log_message(self, message: str, level: str = "INFO"):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}"
        
        # Log to GUI
        self.log_text.configure(state='normal')
        self.log_text.insert(tk.END, log_entry + "\n")
        self.log_text.see(tk.END)
        self.log_text.configure(state='disabled')
        
        # Log to terminal
        print(log_entry)
        
        if self.root: # Garante que a raiz existe antes de atualizar
            self.root.update_idletasks() # Para atualizar a GUI imediatamente

    def clear_log(self):
        self.log_text.configure(state='normal')
        self.log_text.delete(1.0, tk.END)
        self.log_text.configure(state='disabled')
        self.log_message("Log limpo.", level="ACTION")

    def save_log(self):
        filename = filedialog.asksaveasfilename(
            defaultextension=".log",
            filetypes=[("Arquivos de Log", "*.log"), ("Arquivos de texto", "*.txt")]
        )
        if filename:
            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    f.write(self.log_text.get(1.0, tk.END))
                self.log_message(f"Log salvo em: {filename}", level="SUCCESS")
            except Exception as e:
                messagebox.showerror("Erro", f"Erro ao salvar o log:\n{str(e)}")
                self.log_message(f"Erro ao salvar log: {str(e)}", level="ERROR")

    def test_mariadb_connection(self):
        if not MYSQL_AVAILABLE:
            msg = "mysql-connector-python não está instalado. Não é possível testar a conexão."
            self.log_message(msg, level="ERROR")
            messagebox.showerror("Dependência Ausente", msg)
            return
        try:
            config = {
                'source_host': self.maria_host.get(),
                'source_port': int(self.maria_port.get()),
                'source_database': self.maria_db.get(),
                'source_user': self.maria_user.get(),
                'source_password': self.maria_pass.get()
            }
            if not all(config.values()):
                messagebox.showerror("Erro de Entrada", "Todos os campos devem ser preenchidos.")
                self.log_message("Tentativa de conexão com campos vazios.", level="WARNING")
                return

            self.log_message(f"Testando conexão com MariaDB: {config['source_user']}@{config['source_host']}:{config['source_port']}/{config['source_database']}", level="INFO")
            if self.extractor.connect(config):
                messagebox.showinfo("Sucesso", "Conexão estabelecida com sucesso.")
                self.log_message("Conexão com MariaDB testada com sucesso.", level="SUCCESS")
            else:
                raise RuntimeError("Falha na conexão sem erro específico.")

        except ValueError:
            messagebox.showerror("Erro de Entrada", "Porta deve ser um número.")
            self.log_message("Erro de entrada: Porta deve ser um número.", level="ERROR")
        except Exception as e:
            messagebox.showerror("Erro na Conexão", f"Erro ao conectar ao MariaDB:\n{str(e)}")
            self.log_message(f"Erro na conexão MariaDB: {str(e)}", level="ERROR")
        finally:
            if self.extractor.connection:
                self.extractor.close()

    def load_tables(self):
        if not MYSQL_AVAILABLE:
            msg = "mysql-connector-python não está instalado. Não é possível carregar tabelas."
            self.log_message(msg, level="ERROR")
            messagebox.showerror("Dependência Ausente", msg)
            return
        try:
            config = {
                'source_host': self.maria_host.get(),
                'source_port': int(self.maria_port.get()),
                'source_database': self.maria_db.get(),
                'source_user': self.maria_user.get(),
                'source_password': self.maria_pass.get()
            }
            if not all(config.values()):
                messagebox.showerror("Erro de Entrada", "Todos os campos devem ser preenchidos.")
                self.log_message("Tentativa de carregar tabelas com campos vazios.", level="WARNING")
                return

            self.log_message("Conectando ao MariaDB para carregar tabelas...", level="INFO")
            if not self.extractor.connect(config):
                raise RuntimeError("Falha na conexão sem erro específico.")

            self.log_message("Conectado. Carregando lista de tabelas...", level="INFO")

            # Limpar tabelas anteriores
            for item in self.tables_tree.get_children():
                self.tables_tree.delete(item)
            self.tables_info.clear()

            tables_names = self.extractor.get_tables()
            self.log_message(f"Encontradas {len(tables_names)} tabelas. Obtendo detalhes...", level="INFO")

            if not tables_names:
                messagebox.showwarning("Aviso", "Nenhuma tabela encontrada no banco de dados.")
                self.log_message("Nenhuma tabela encontrada.", level="WARNING")
                return

            self.progress_bar['maximum'] = len(tables_names)
            self.progress_bar['value'] = 0
            
            for i, table_name in enumerate(tables_names, 1):
                try:
                    table_info = self.extractor.get_table_info(table_name)
                    self.tables_info[table_name] = table_info
                    
                    # Adicionar à Treeview
                    self.tables_tree.insert('', 'end', values=(
                        '',  # Checkbox column
                        table_name,
                        len(table_info.columns),
                        f"{table_info.row_count:,}"  # Format with thousands separator
                    ))
                    
                    self.progress_bar['value'] = i
                    self.progress_var.set(f"Carregando tabela {i} de {len(tables_names)}: {table_name}")
                    self.root.update_idletasks()
                except Exception as e:
                    self.log_message(f"Erro ao carregar detalhes da tabela {table_name}: {str(e)}", level="ERROR")
            
            self.progress_var.set(f"Carregadas {len(self.tables_info)} tabelas com sucesso.")
            self.log_message(f"Carregadas informações de {len(self.tables_info)} tabelas.", level="SUCCESS")
            if len(self.tables_info) != len(tables_names):
                self.log_message(f"AVISO: {len(tables_names) - len(self.tables_info)} tabelas não puderam ser carregadas.", level="WARNING")

        except ValueError:
            messagebox.showerror("Erro de Entrada", "Porta deve ser um número.")
            self.log_message("Erro de entrada ao carregar tabelas: Porta deve ser um número.", level="ERROR")
        except Exception as e:
            messagebox.showerror("Erro", f"Erro ao carregar tabelas de MariaDB:\n{str(e)}")
            self.log_message(f"Erro ao carregar tabelas: {str(e)}", level="ERROR")
        finally:
            if self.extractor.connection:
                self.extractor.close()
            self.progress_bar['value'] = 0
            if not self.tables_info:
                self.progress_var.set("Não há tabelas carregadas.")


    def view_table_structure(self):
        selection = self.tables_tree.selection()
        if not selection:
            messagebox.showwarning("Aviso", "Selecione uma tabela na lista para ver sua estrutura.")
            return

        item_id = selection[0]
        # O nome da tabela é o segundo valor (índice 1)
        table_name_from_tree = self.tables_tree.item(item_id, 'values')[1]

        if table_name_from_tree not in self.tables_info:
            self.log_message(f"Informações da tabela '{table_name_from_tree}' não encontradas localmente.", level="WARNING")
            messagebox.showerror("Erro", f"Informações da tabela '{table_name_from_tree}' não estão carregadas.")
            return

        table_info = self.tables_info[table_name_from_tree]

        structure_window = tk.Toplevel(self.root)
        structure_window.title(f"Estrutura Mapeada: {table_info.name}")
        structure_window.geometry("750x450")
        structure_window.transient(self.root)
        structure_window.grab_set()

        cols = ('Nome Coluna', 'Tipo MariaDB', 'Max Len', 'Precisão', 'Escala', 'Tipo Informix', 'Nulo?', 'Padrão', 'PK?', 'AI?')
        tree = ttk.Treeview(structure_window, columns=cols, show='headings')
        for col_name in cols:
            tree.heading(col_name, text=col_name)
            tree.column(col_name, width=int(700/len(cols)), anchor=tk.W) # Ajuste de largura

        for column in table_info.columns:
            informix_type = TypeMapper.map_type(
                column.data_type,
                column.max_length,
                getattr(column, 'precision', None),
                getattr(column, 'scale', None)
            )
            tree.insert('', tk.END, values=(
                column.name,
                column.data_type,
                column.max_length if column.max_length is not None else '-',
                getattr(column, 'precision', '-') if getattr(column, 'precision', None) is not None else '-',
                getattr(column, 'scale', '-') if getattr(column, 'scale', None) is not None else '-',
                informix_type,
                "Sim" if column.is_nullable else "Não",
                str(column.default_value)[:20] if column.default_value is not None else "-", # Limita o tamanho do default
                "Sim" if column.is_primary_key else "Não",
                "Sim" if column.is_auto_increment else "Não"
            ))

        vsb = ttk.Scrollbar(structure_window, orient="vertical", command=tree.yview)
        hsb = ttk.Scrollbar(structure_window, orient="horizontal", command=tree.xview)
        tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)
        
        tree.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')
        hsb.grid(row=1, column=0, sticky='ew')

        structure_window.grid_rowconfigure(0, weight=1)
        structure_window.grid_columnconfigure(0, weight=1)

        self.log_message(f"Visualizando estrutura mapeada para a tabela: {table_info.name}", level="INFO")


    def get_selected_tables_names(self) -> List[str]:
        selected = []
        for item_id in self.tables_tree.get_children():
            if self.tables_tree.set(item_id, 'Selecionar') == '✓':
                table_name = self.tables_tree.item(item_id)['values'][1]  # The table name is in the second column
                selected.append(table_name)
        return selected

    # Renomeado de start_migration para refletir a nova funcionalidade
    def start_script_generation(self):
        if self.migration_running: # Reutilizando a flag de controle
            self.log_message("Geração de scripts já está em andamento.", level="WARNING")
            return

        selected_tables_names = self.get_selected_tables_names()
        if not selected_tables_names:
            messagebox.showwarning("Aviso", "Nenhuma tabela selecionada para gerar scripts.")
            self.log_message("Tentativa de gerar scripts sem tabelas selecionadas.", level="WARNING")
            return

        # Validar configurações de MariaDB
        if not all([self.maria_host.get(), self.maria_port.get(), self.maria_db.get(), self.maria_user.get()]):
            messagebox.showerror("Erro de Configuração", "Preencha todas as configurações do MariaDB (Host, Porta, Database, Usuário).")
            self.log_message("Configurações do MariaDB incompletas para geração de scripts.", level="ERROR")
            return
        try:
            int(self.maria_port.get())
            int(self.batch_size_entry.get())
        except ValueError:
            messagebox.showerror("Erro de Configuração", "Porta do MariaDB e Tamanho do Lote devem ser números.")
            self.log_message("Porta ou Tamanho do Lote não são numéricos.", level="ERROR")
            return


        # Escolher diretório para salvar os scripts
        self.output_directory = filedialog.askdirectory(title="Selecione o diretório para salvar os scripts")
        if not self.output_directory:
            self.log_message("Seleção de diretório cancelada pelo usuário.", level="INFO")
            return

        self.migration_running = True
        self.generate_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        self.log_message(f"Iniciando geração de scripts para: {', '.join(selected_tables_names)}", level="ACTION")
        self.log_message(f"Scripts serão salvos em: {self.output_directory}", level="INFO")

        # Limpar resumo anterior
        self.summary_text.configure(state='normal')
        self.summary_text.delete(1.0, tk.END)
        self.summary_text.configure(state='disabled')


        thread = threading.Thread(target=self.perform_script_generation, args=(selected_tables_names,))
        thread.daemon = True # Permite que a aplicação feche mesmo se a thread estiver rodando
        thread.start()

    # Renomeado de perform_migration
    def perform_script_generation(self, selected_tables_names: List[str]):
        try:
            self.progress_var.set("Iniciando geração de scripts...")
            self.progress_bar['maximum'] = len(selected_tables_names)
            self.progress_bar['value'] = 0

            # Conectar ao MariaDB para buscar dados se necessário
            # A conexão só é feita se formos buscar dados
            if self.migrate_data_var.get():
                maria_config = {
                    'host': self.maria_host.get(),
                    'port': int(self.maria_port.get()),
                    'database': self.maria_db.get(),
                    'user': self.maria_user.get(),
                    'password': self.maria_pass.get()
                }
                self.log_message("Conectando ao MariaDB para extrair dados...", level="INFO")
                if not self.extractor.connect(maria_config): # connect pode levantar exceção
                    self.log_message("Falha ao conectar ao MariaDB para extração de dados.", level="ERROR")
                    # A exceção de connect() já deve ter sido logada.
                    # Não precisamos fazer mais nada aqui, o finally cuidará do estado.
                    return # Sai da função se a conexão falhar

            ddl_scripts_content = []
            ddl_scripts_content.append(f"-- Script de CRIAÇÃO DE ESTRUTURA (DDL) para Informix")
            ddl_scripts_content.append(f"-- Gerado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            ddl_scripts_content.append(f"-- Origem: MariaDB - {self.maria_db.get()}")
            ddl_scripts_content.append(f"-- Destino: Informix - {self.informix_db_name_script.get()} (servidor: {self.informix_server_name.get()})\n")

            total_records_processed = 0
            generated_data_files = []

            for i, table_name in enumerate(selected_tables_names):
                if not self.migration_running:
                    self.log_message("Geração de scripts interrompida pelo usuário.", level="WARNING")
                    break
                
                self.progress_var.set(f"Gerando para tabela: {table_name} ({i+1}/{len(selected_tables_names)})")
                self.log_message(f"Processando tabela: {table_name}", level="INFO")

                if table_name not in self.tables_info:
                    self.log_message(f"Skipping {table_name}: Informações não encontradas (não foi carregada?).", level="WARNING")
                    self.progress_bar['value'] = i + 1
                    continue
                
                table_info = self.tables_info[table_name]

                # Gerar DDL (CREATE TABLE)
                ddl = InformixGenerator.generate_create_table(table_info)
                ddl_scripts_content.append(f"\n-- ESTRUTURA PARA A TABELA: {table_name}\n")
                ddl_scripts_content.append(ddl)
                ddl_scripts_content.append("\n")
                self.log_message(f"DDL gerado para {table_name}.", level="DEBUG")

                # Gerar DML (INSERTs) se solicitado
                if self.migrate_data_var.get() and table_info.row_count > 0:
                    self.log_message(f"Iniciando extração de dados para {table_name} ({table_info.row_count} registros).", level="INFO")
                    
                    # Garantir que estamos conectados (se ainda não estivermos)
                    if not self.extractor.connection or not self.extractor.connection.is_connected():
                         if not self.extractor.connect(maria_config): # type: ignore
                            self.log_message(f"Falha ao reconectar ao MariaDB para {table_name}. Pulando dados.", level="ERROR")
                            continue # Pula para a próxima tabela

                    table_data_filename = os.path.join(self.output_directory, f"{table_name}_data.sql")
                    generated_data_files.append(os.path.basename(table_data_filename))
                    
                    with open(table_data_filename, 'w', encoding='utf-8') as dml_file:
                        dml_file.write(f"-- DADOS (DML) PARA A TABELA: {table_name}\n")
                        dml_file.write(f"-- Total de Registros: {table_info.row_count}\n\n")

                        batch_size = int(self.batch_size_entry.get())
                        records_in_table_processed = 0
                        for offset in range(0, table_info.row_count, batch_size):
                            if not self.migration_running: break

                            self.progress_var.set(f"{table_name}: Extraindo {offset+1}-{min(offset+batch_size, table_info.row_count)} de {table_info.row_count}")
                            self.root.update_idletasks()

                            try:
                                data_batch = self.extractor.get_table_data(table_name, batch_size, offset)
                            except Exception as e_fetch:
                                self.log_message(f"Erro ao buscar dados para {table_name} (lote {offset // batch_size + 1}): {e_fetch}", "ERROR")
                                break # Interrompe a busca de dados para esta tabela em caso de erro

                            if not data_batch: # Pode acontecer se a contagem inicial estiver errada ou houver problema
                                self.log_message(f"Nenhum dado retornado para {table_name} no lote {offset // batch_size + 1}. Finalizando dados para esta tabela.", "WARNING")
                                break


                            insert_statements = InformixGenerator.generate_insert_statements(table_info, data_batch)
                            for stmt in insert_statements:
                                dml_file.write(stmt + "\n")
                            
                            records_in_table_processed += len(data_batch)
                            total_records_processed += len(data_batch)

                        self.log_message(f"Script DML gerado para {table_name} com {records_in_table_processed} registros: {table_data_filename}", level="INFO")
                
                elif self.migrate_data_var.get() and table_info.row_count == 0:
                    self.log_message(f"Tabela {table_name} não possui registros. Script de dados não será gerado.", level="INFO")

                self.progress_bar['value'] = i + 1
            # Fim do loop de tabelas

            # Salvar o script DDL principal
            ddl_main_filename = os.path.join(self.output_directory, "00_CREATE_TABLES_ALL.sql")
            with open(ddl_main_filename, 'w', encoding='utf-8') as f:
                f.write('\n'.join(ddl_scripts_content))
            self.log_message(f"Script DDL principal salvo: {ddl_main_filename}", level="SUCCESS")

            # Gerar script de execução (exemplo para dbaccess)
            exec_script_filename = os.path.join(self.output_directory, "RUN_ALL_SCRIPTS.sh")
            with open(exec_script_filename, 'w', encoding='utf-8') as f:
                f.write("#!/bin/bash\n")
                f.write("# Script para executar os arquivos SQL gerados no Informix usando dbaccess.\n")
                f.write("# Certifique-se de que as variáveis de ambiente do Informix (INFORMIXDIR, INFORMIXSERVER, etc.)\n")
                f.write("# e o PATH estejam configurados corretamente.\n\n")
                f.write(f"DB_NAME=\"{self.informix_db_name_script.get() or 'seu_banco_de_dados'}\"\n")
                f.write(f"INFORMIXSERVER_TO_USE=\"{self.informix_server_name.get() or 'seu_servidor_informix'}\"\n\n")
                f.write("echo \"Verifique e ajuste DB_NAME e INFORMIXSERVER_TO_USE neste script antes de executar.\"\n")
                f.write("read -p \"Pressione Enter para continuar após verificar...\"\n\n")
                f.write(f"echo \"Executando script de criação de tabelas: {os.path.basename(ddl_main_filename)}\"\n")
                f.write(f"dbaccess \"$DB_NAME\"@{self.informix_server_name.get()} \"{os.path.basename(ddl_main_filename)}\" || exit 1\n\n")
                if self.migrate_data_var.get() and generated_data_files:
                    f.write("echo \"Executando scripts de inserção de dados...\"\n")
                    for data_file in generated_data_files:
                        f.write(f"echo \"  - {data_file}\"\n")
                        f.write(f"  dbaccess \"$DB_NAME\"@{self.informix_server_name.get()} \"{data_file}\" || echo \"ERRO ao executar {data_file}. Continuando...\"\n")
                f.write("\n_done\necho \"Execução dos scripts concluída.\"\n")
            
            # Tornar executável (Linux/macOS)
            try:
                os.chmod(exec_script_filename, 0o755) # rwxr-xr-x
                self.log_message(f"Script de execução salvo e tornado executável: {exec_script_filename}", level="SUCCESS")
            except OSError as e_chmod:
                 self.log_message(f"Script de execução salvo: {exec_script_filename}. Falha ao tornar executável (chmod): {e_chmod}", level="WARNING")


            # Atualizar resumo na GUI
            summary_content = f"GERAÇÃO DE SCRIPTS CONCLUÍDA ({'COM' if self.migration_running else 'INTERROMPIDA'})\n"
            summary_content += f"Data/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            summary_content += f"Diretório de Saída: {self.output_directory}\n"
            summary_content += f"Tabelas processadas: {self.progress_bar['value']} de {len(selected_tables_names)}\n"
            if self.migrate_data_var.get():
                summary_content += f"Total de registros processados para DML: {total_records_processed}\n"
            summary_content += "\nArquivos Gerados:\n"
            summary_content += f"  - {os.path.basename(ddl_main_filename)} (Estrutura DDL)\n"
            if self.migrate_data_var.get():
                for df in generated_data_files:
                    summary_content += f"  - {df} (Dados DML)\n"
            summary_content += f"  - {os.path.basename(exec_script_filename)} (Script de execução .sh)\n"
            
            self.summary_text.configure(state='normal')
            self.summary_text.delete(1.0, tk.END)
            self.summary_text.insert(1.0, summary_content)
            self.summary_text.configure(state='disabled')

            if self.migration_running: # Se não foi interrompido
                self.progress_var.set("Geração de scripts concluída!")
                self.log_message("=== GERAÇÃO DE SCRIPTS CONCLUÍDA ===", level="SUCCESS")
                messagebox.showinfo("Sucesso", f"Geração de scripts concluída!\nSalvos em: {self.output_directory}")
            else:
                self.progress_var.set("Geração interrompida.")
                self.log_message("Geração de scripts interrompida.", level="WARNING")
                messagebox.showwarning("Interrompido", "A geração de scripts foi interrompida.")


        except Exception as e_gen:
            self.log_message(f"ERRO CRÍTICO durante a geração de scripts: {str(e_gen)}", level="CRITICAL")
            import traceback
            self.log_message(traceback.format_exc(), level="DEBUG") # Log stack trace
            messagebox.showerror("Erro na Geração", f"Ocorreu um erro crítico:\n{str(e_gen)}")
            self.progress_var.set("Erro na geração de scripts!")
        finally:
            if self.extractor.connection and self.extractor.connection.is_connected():
                self.extractor.close()
                self.log_message("Conexão MariaDB fechada.", level="INFO")
            
            self.migration_running = False
            self.generate_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)
            self.progress_bar['value'] = 0 # Reset progress bar

    # Renomeado de stop_migration
    def stop_script_generation(self):
        if self.migration_running:
            self.migration_running = False # Sinaliza para a thread parar
            self.log_message("Solicitação de parada da geração de scripts enviada...", level="ACTION")
            self.stop_button.config(state=tk.DISABLED) # Evitar cliques múltiplos
        else:
            self.log_message("Nenhuma geração de scripts em andamento para parar.", level="INFO")


    def save_config(self):
        config = {
            'mariadb': {
                'host': self.maria_host.get(),
                'port': self.maria_port.get(),
                'database': self.maria_db.get(),
                'user': self.maria_user.get(),
                'password': self.maria_pass.get() # Salvar senha pode ser um risco de segurança
            },
            'informix_script_refs': { # Referências para os scripts
                'server_name': self.informix_server_name.get(),
                'db_name': self.informix_db_name_script.get()
            },
            'options': {
                'generate_data_scripts': self.migrate_data_var.get(),
                'batch_size': self.batch_size_entry.get()
            }
        }

        filename = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("Arquivos JSON de Configuração", "*.json"), ("Todos os arquivos", "*.*")],
            title="Salvar Configuração"
        )

        if filename:
            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(config, f, indent=4, ensure_ascii=False)
                self.log_message(f"Configuração salva em: {filename}", level="SUCCESS")
                messagebox.showinfo("Sucesso", f"Configuração salva em:\n{filename}")
            except Exception as e:
                self.log_message(f"Erro ao salvar configuração: {e}", level="ERROR")
                messagebox.showerror("Erro ao Salvar", f"Não foi possível salvar a configuração:\n{e}")

    def load_config(self):
        filename = filedialog.askopenfilename(
            filetypes=[("Arquivos JSON de Configuração", "*.json"), ("Todos os arquivos", "*.*")],
            title="Carregar Configuração"
        )

        if filename:
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    config = json.load(f)

                # Carregar configurações MariaDB
                maria = config.get('mariadb', {})
                self.maria_host.delete(0, tk.END); self.maria_host.insert(0, maria.get('host', 'localhost'))
                self.maria_port.delete(0, tk.END); self.maria_port.insert(0, maria.get('port', '3306'))
                self.maria_db.delete(0, tk.END); self.maria_db.insert(0, maria.get('database', ''))
                self.maria_user.delete(0, tk.END); self.maria_user.insert(0, maria.get('user', ''))
                self.maria_pass.delete(0, tk.END); self.maria_pass.insert(0, maria.get('password', ''))

                # Carregar referências Informix
                informix_refs = config.get('informix_script_refs', {})
                self.informix_server_name.delete(0, tk.END); self.informix_server_name.insert(0, informix_refs.get('server_name', ''))
                self.informix_db_name_script.delete(0, tk.END); self.informix_db_name_script.insert(0, informix_refs.get('db_name', ''))

                # Carregar opções
                options = config.get('options', {})
                self.migrate_data_var.set(options.get('generate_data_scripts', True))
                self.batch_size_entry.delete(0, tk.END); self.batch_size_entry.insert(0, str(options.get('batch_size', 1000)))

                self.log_message(f"Configuração carregada de: {filename}", level="SUCCESS")
                messagebox.showinfo("Sucesso", f"Configuração carregada de:\n{filename}")

            except FileNotFoundError:
                self.log_message(f"Arquivo de configuração não encontrado: {filename}", level="ERROR")
                messagebox.showerror("Erro", f"Arquivo não encontrado:\n{filename}")
            except json.JSONDecodeError:
                self.log_message(f"Erro ao decodificar JSON do arquivo: {filename}", level="ERROR")
                messagebox.showerror("Erro", f"Arquivo de configuração inválido (não é JSON válido):\n{filename}")
            except Exception as e:
                self.log_message(f"Erro desconhecido ao carregar configuração: {e}", level="ERROR")
                messagebox.showerror("Erro", f"Erro ao carregar configuração:\n{str(e)}")


def main():
    # --- Informações Iniciais no Terminal ---
    print("="*70)
    print("Iniciando Migrador MariaDB para Informix (Gerador de Scripts SQL)")
    print("="*70)
    print("Este utilitário ajuda a gerar scripts SQL para migrar esquemas e dados de MariaDB para Informix.")
    print("A execução direta da migração NÃO está implementada. Os scripts gerados (DDL, DML, .sh) devem ser revisados e executados manualmente ou por outras ferramentas (ex: dbaccess).")
    print("\nProblemas comuns que podem impedir o funcionamento correto da EXTRAÇÃO de MariaDB:")
    print("1. Ausência da biblioteca Python: 'mysql-connector-python'.")
    print("   - Instale-a via pip: pip install mysql-connector-python")
    print("2. Configurações de conexão com MariaDB incorretas (host, porta, usuário, senha, nome do banco).")
    print("3. Servidor MariaDB não está em execução ou não está acessível pela rede (firewalls, etc.).")
    print("4. Permissões insuficientes para o usuário do MariaDB (SELECT em tabelas, SHOW TABLES, acesso ao INFORMATION_SCHEMA).")
    print("\nPara a EXECUÇÃO dos scripts gerados no Informix (fora desta aplicação):")
    print("1. O IBM Informix Client SDK (CSDK) deve estar instalado e configurado na máquina onde os scripts serão executados.")
    print("   Isso inclui a configuração correta do driver ODBC e variáveis de ambiente (INFORMIXDIR, etc.).")
    print("2. O servidor Informix deve estar em execução e acessível.")
    print("3. O usuário que executará os scripts no Informix deve ter as permissões necessárias (CREATE TABLE, INSERT, etc.).")
    print("4. Os scripts gerados (especialmente os de DADOS) podem ser grandes. Considere o impacto no servidor Informix.")
    print("-" * 70)
    # --- Fim das Informações Iniciais ---

    root = tk.Tk()
    app = MigrationApp(root)

    menubar = tk.Menu(root)
    root.config(menu=menubar)

    file_menu = tk.Menu(menubar, tearoff=0)
    menubar.add_cascade(label="Arquivo", menu=file_menu)
    # file_menu.add_command(label="Nova Configuração", command=lambda: None) # Pode ser implementado para limpar campos
    file_menu.add_command(label="Salvar Configuração", command=app.save_config)
    file_menu.add_command(label="Carregar Configuração", command=app.load_config)
    file_menu.add_separator()
    file_menu.add_command(label="Sair", command=root.quit)

    tools_menu = tk.Menu(menubar, tearoff=0)
    menubar.add_cascade(label="Ferramentas", menu=tools_menu)
    tools_menu.add_command(label="Testar Conexão MariaDB", command=app.test_mariadb_connection)
    tools_menu.add_command(label="Carregar Tabelas de MariaDB", command=app.load_tables)
    # Removido "Gerar Scripts SQL" do menu, pois está na aba principal

    help_menu = tk.Menu(menubar, tearoff=0)
    menubar.add_cascade(label="Ajuda", menu=help_menu)
    def show_about():
        messagebox.showinfo(
            "Sobre - Migrador MariaDB para Informix (Gerador de Scripts)",
            "Versão: 1.1.0\n\n"
            "Este utilitário facilita a migração de bancos de dados MariaDB para Informix "
            "através da geração de scripts SQL (DDL para estrutura e DML para dados).\n\n"
            "Funcionalidades Principais:\n"
            "- Conexão com MariaDB para extrair metadados e dados.\n"
            "- Mapeamento de tipos de dados de MariaDB para Informix.\n"
            "- Geração de scripts CREATE TABLE para Informix.\n"
            "- Geração de scripts INSERT para popular dados no Informix.\n"
            "- Geração de um script shell (.sh) de exemplo para executar os SQLs via 'dbaccess'.\n\n"
            "Dependências Python (para extração de MariaDB):\n"
            f"- mysql-connector-python ({'Instalado' if MYSQL_AVAILABLE else 'NÃO INSTALADO - instale via pip'})\n"
            f"- pyodbc ({'Instalado' if INFORMIX_AVAILABLE else 'NÃO INSTALADO - instale via pip, usado para referência de tipos, não para conexão direta aqui'})\n\n"
            "Importante: A execução dos scripts no Informix é de responsabilidade do usuário e requer "
            "o IBM Informix Client SDK devidamente configurado."
        )
    help_menu.add_command(label="Sobre", command=show_about)


    def on_closing():
        if app.migration_running:
            if messagebox.askokcancel("Sair?", "A geração de scripts está em andamento. Deseja realmente interromper e sair?"):
                app.stop_script_generation() # Tenta parar a thread
                # Pode ser necessário esperar um pouco para a thread finalizar se ela estiver em uma operação longa
                # No entanto, como a thread é daemon, ela será terminada quando o processo principal sair.
                root.destroy()
        else:
            if messagebox.askokcancel("Sair?", "Deseja fechar o aplicativo?"):
                root.destroy()

    root.protocol("WM_DELETE_WINDOW", on_closing)
    root.mainloop()

if __name__ == "__main__":
    main()