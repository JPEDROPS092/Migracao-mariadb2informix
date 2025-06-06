# sql_converter_logic.py
import re

class SQLConverter:
    def __init__(self):
        self.warnings = []
        self.converted_items_count = 0

    def _reset_state(self):
        self.warnings = []
        self.converted_items_count = 0

    def _add_warning(self, message):
        if message not in self.warnings: # Evitar duplicados
            self.warnings.append(message)

    def _increment_conversion_count(self, count=1):
        self.converted_items_count += count

    def convert(self, mariadb_sql: str) -> tuple[str, list, int]:
        self._reset_state()
        informix_sql = mariadb_sql

        # --- Pré-processamento e Detecção de Blocos ---
        # Lidar com DELIMITER para stored procedures/functions
        # Esta é uma abordagem simplificada. Scripts complexos com DELIMITER podem precisar de mais.
        delimiter_pattern = re.compile(r"DELIMITER\s+(.+)", re.IGNORECASE)
        custom_delimiter = None
        delimiters_found = list(delimiter_pattern.finditer(informix_sql))

        if delimiters_found:
            self._add_warning("Instruções 'DELIMITER' detectadas. Tentando processar blocos de Stored Procedure/Function.")
            # Remove as declarações DELIMITER em si
            informix_sql = delimiter_pattern.sub("", informix_sql)
            
            # Supõe que o último delimitador definido é o que finaliza os blocos
            # e que o delimitador padrão é ';' antes do primeiro DELIMITER
            # Isso é uma simplificação!
            
            # Regex para CREATE PROCEDURE/FUNCTION ... END delimiter
            # Captura (CREATE [OR REPLACE] PROCEDURE/FUNCTION ...)(corpo)(END)(delimitador customizado)
            proc_func_pattern_custom_delim = re.compile(
                r"(CREATE\s+(?:OR\s+REPLACE\s+)?(?:PROCEDURE|FUNCTION)\s+[\w`]+\s*\(.*?\)\s*(?:RETURNS\s+\w+\s*)?.*?)(END)\s*(\S{2,})", 
                re.IGNORECASE | re.DOTALL
            )
            
            def replace_proc_func_end_custom(match):
                self._increment_conversion_count()
                # O delimitador customizado é o match.group(3)
                # Se o delimitador customizado for por exemplo "$$", e a linha é "END$$"
                # queremos substituir por "END PROCEDURE;" ou "END FUNCTION;"
                proc_type = "PROCEDURE" if "PROCEDURE" in match.group(1).upper() else "FUNCTION"
                return f"{match.group(1)}END {proc_type};"

            informix_sql = proc_func_pattern_custom_delim.sub(replace_proc_func_end_custom, informix_sql)


        # --- Conversões Gerais (aplicadas em todo o script) ---

        # 1. `AUTO_INCREMENT` → `SERIAL`
        #    Também cobre `BIGINT AUTO_INCREMENT` -> `SERIAL8`
        #    e remove `DEFAULT NULL` ou `NOT NULL` se estiver com AUTO_INCREMENT
        def replace_auto_increment(match):
            self._increment_conversion_count()
            type_before = match.group(1).upper() if match.group(1) else "INT"
            if "BIGINT" in type_before:
                return "SERIAL8"
            return "SERIAL"
        
        informix_sql = re.sub(
            r"\b(BIGINT|INT(?:EGER)?)\b\s+(NOT\s+NULL\s+|NULL\s+|DEFAULT\s+NULL\s+)?AUTO_INCREMENT",
            replace_auto_increment, informix_sql, flags=re.IGNORECASE
        )
        informix_sql = re.sub(
            r"\bAUTO_INCREMENT\b", "SERIAL", informix_sql, flags=re.IGNORECASE
        ) # Pega AUTO_INCREMENT sozinho

        # 2. `DATETIME` → `DATETIME YEAR TO SECOND`
        #    Evitar `DATETIME YEAR TO ...` já existente
        datetime_pattern = re.compile(r"\bDATETIME\b(?!\s+YEAR\b)", re.IGNORECASE)
        if datetime_pattern.search(informix_sql):
            self._increment_conversion_count(len(datetime_pattern.findall(informix_sql)))
            informix_sql = datetime_pattern.sub("DATETIME YEAR TO SECOND", informix_sql)

        # 3. `TEXT` → `CLOB` (e variantes como LONGTEXT, MEDIUMTEXT, TINYTEXT)
        text_types_pattern = re.compile(r"\b(LONGTEXT|MEDIUMTEXT|TINYTEXT|TEXT)\b", re.IGNORECASE)
        if text_types_pattern.search(informix_sql):
            self._increment_conversion_count(len(text_types_pattern.findall(informix_sql)))
            informix_sql = text_types_pattern.sub("CLOB", informix_sql)

        # 4. `NOW()` → `CURRENT YEAR TO SECOND`
        now_pattern = re.compile(r"\bNOW\(\s*\)", re.IGNORECASE)
        if now_pattern.search(informix_sql):
            self._increment_conversion_count(len(now_pattern.findall(informix_sql)))
            informix_sql = now_pattern.sub("CURRENT YEAR TO SECOND", informix_sql)

        # 5. Remover aspas invertidas (`)
        backtick_pattern = re.compile(r"`([^`]+)`")
        if backtick_pattern.search(informix_sql):
            # Não necessariamente conta como "conversão" principal, mas é uma mudança.
            # self._increment_conversion_count(len(backtick_pattern.findall(informix_sql)))
            informix_sql = backtick_pattern.sub(r"\1", informix_sql)


        # 6. `LIMIT` → `FIRST` / `SKIP FIRST`
        #    Processa SELECTs que podem ou não terminar com ';'
        #    `SELECT ... LIMIT count` -> `SELECT FIRST count ...`
        #    `SELECT ... LIMIT offset, count` -> `SELECT SKIP offset FIRST count ...`
        
        # LIMIT offset, count
        limit_offset_count_pattern = re.compile(
            r"\b(SELECT)\b((?:\s*(?:ALL|DISTINCT))?\s*(?:.*?))"  # SELECT e o corpo (não guloso até LIMIT)
            r"\bLIMIT\s+(\d+)\s*,\s*(\d+)\s*([;\n]|$)",
            re.IGNORECASE | re.DOTALL # DOTALL para `.*?` cruzar linhas
        )
        def replace_limit_offset_count(match):
            self._increment_conversion_count()
            select_keyword = match.group(1) # "SELECT" ou "select"
            select_body = match.group(2).strip() # Corpo da query
            offset = match.group(3)
            count = match.group(4)
            terminator = match.group(5) # ';' ou fim de linha
            # Informix: SELECT SKIP offset FIRST count col1, col2 ...
            return f"{select_keyword} SKIP {offset} FIRST {count} {select_body}{terminator}"
        
        informix_sql, num_subs = limit_offset_count_pattern.subn(replace_limit_offset_count, informix_sql)
        if num_subs == 0: # Só tenta o próximo se o anterior não casou
            # LIMIT count
            limit_count_pattern = re.compile(
                r"\b(SELECT)\b((?:\s*(?:ALL|DISTINCT))?\s*(?:.*?))" # SELECT e o corpo
                r"\bLIMIT\s+(\d+)\s*([;\n]|$)",
                re.IGNORECASE | re.DOTALL
            )
            def replace_limit_count(match):
                self._increment_conversion_count()
                select_keyword = match.group(1)
                select_body = match.group(2).strip()
                count = match.group(3)
                terminator = match.group(4)
                return f"{select_keyword} FIRST {count} {select_body}{terminator}"
            informix_sql = limit_count_pattern.sub(replace_limit_count, informix_sql)
        
        if "LIMIT" in informix_sql.upper(): # Se ainda houver LIMIT, pode ser complexo
            self._add_warning("Cláusulas 'LIMIT' complexas ou em subqueries podem precisar de revisão manual.")

        # 7. Stored Procedures/Functions: `END` -> `END PROCEDURE;` ou `END FUNCTION;`
        #    Isto é para casos onde não havia DELIMITER e o final é `END;`
        #    Procura por CREATE PROCEDURE/FUNCTION ... END;
        proc_func_pattern_semicolon_end = re.compile(
            r"(CREATE\s+(?:OR\s+REPLACE\s+)?(PROCEDURE|FUNCTION)\s+[\w`]+\s*\(.*?\)\s*(?:RETURNS\s+\w+\s*)?.*?)(END\s*;)",
            re.IGNORECASE | re.DOTALL
        )
        def replace_proc_func_end_semicolon(match):
            self._increment_conversion_count()
            proc_type = match.group(2).upper() # PROCEDURE ou FUNCTION
            return f"{match.group(1)}END {proc_type};"
        
        informix_sql = proc_func_pattern_semicolon_end.sub(replace_proc_func_end_semicolon, informix_sql)

        # --- Ajustes Finais e Avisos ---
        # CREATE TABLE:
        #   - Chaves Primárias e Estrangeiras: A sintaxe básica é similar.
        #     MariaDB: PRIMARY KEY (col), FOREIGN KEY (col) REFERENCES tbl(col)
        #     Informix: PRIMARY KEY (col), FOREIGN KEY (col) REFERENCES tbl(col) [CONSTRAINT name]
        #     Não requer grandes mudanças na sintaxe básica, mas nomes de constraints podem ser adicionados no Informix.
        #     Se `SERIAL` for usado, ele geralmente implica PK e NOT NULL.
        #     O usuário deve revisar se `SERIAL` sozinho é suficiente ou se `PRIMARY KEY` explícito é necessário.
        if "CREATE TABLE" in informix_sql.upper():
            if "SERIAL" in informix_sql.upper() and "PRIMARY KEY" in informix_sql.upper():
                 self._add_warning("Verifique definições de PRIMARY KEY em tabelas com colunas SERIAL. SERIAL já pode atuar como PK.")
            self._add_warning("Revise a sintaxe de PRIMARY KEY e FOREIGN KEY para conformidade com Informix (nomes de constraint, etc.).")

        if "ALTER TABLE" in informix_sql.upper():
            self._add_warning("Comandos ALTER TABLE podem ter sintaxe variada. Revise-os cuidadosamente.")
            # Exemplo: MariaDB `ALTER TABLE t MODIFY col VARCHAR(255);`
            # Informix: `ALTER TABLE t MODIFY col VARCHAR(255);` (similar para simples)
            #           `ALTER TABLE t ADD CONSTRAINT ...` (similar)
            # A lógica de conversão de tipos de dados já deve ter ajudado aqui.

        # CREATE VIEW
        view_pattern = re.compile(r"CREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+\S+\s+AS\s+(SELECT.*?)(?:\s*WITH\s+CASCADED\s+CHECK\s+OPTION)?\s*;", re.IGNORECASE | re.DOTALL)
        if view_pattern.search(informix_sql):
            self._increment_conversion_count(len(view_pattern.findall(informix_sql)))
            self._add_warning("CREATE VIEW detectado. A query SELECT interna foi processada pelas regras gerais (ex: LIMIT). Revise a view completa.")
            # A estrutura `CREATE VIEW name AS SELECT ...` é a mesma.
            # A remoção de `WITH CASCADED CHECK OPTION` se presente (não comum no Informix).
            informix_sql = re.sub(r"\s*WITH\s+CASCADED\s+CHECK\s+OPTION", "", informix_sql, flags=re.IGNORECASE)
            
        # Comentários
        # MariaDB: -- comment, # comment, /* comment */
        # Informix: -- comment, { comment } /* comment */
        # Substituir # por --
        hash_comment_pattern = re.compile(r"^\s*#.*$", re.MULTILINE)
        if hash_comment_pattern.search(informix_sql):
            self._increment_conversion_count(len(hash_comment_pattern.findall(informix_sql)))
            informix_sql = hash_comment_pattern.sub(lambda m: "--" + m.group(0).lstrip("# "), informix_sql)
            self._add_warning("Comentários '#' foram convertidos para '--'. Revise se algum '#' era usado dentro de strings.")

        # Alerta geral para Stored Procedures/Functions
        if "PROCEDURE" in informix_sql.upper() or "FUNCTION" in informix_sql.upper():
            self._add_warning("Stored Procedures/Functions convertidas de forma básica. Lógica interna (loops, variáveis, SQL procedural) EXIGE revisão manual detalhada devido a grandes diferenças entre MariaDB SPL e Informix SPL.")

        # INSERT, UPDATE, DELETE: A sintaxe básica é muito similar.
        # As conversões de NOW() e tipos de dados já ajudam.
        # Nenhuma conversão específica para a estrutura do comando em si, a menos que LIMIT fosse usado (raro).
        
        return informix_sql.strip(), self.warnings, self.converted_items_count