

# Ambiente de Migração de Banco de Dados: MariaDB para Informix com Docker Compose

Este projeto utiliza Docker Compose para configurar rapidamente um ambiente com um servidor MariaDB e um servidor Informix Developer Edition. O objetivo é facilitar o desenvolvimento e teste de scripts de migração de dados e esquemas entre esses dois sistemas de gerenciamento de banco de dados.

## Conteúdo

- [Ambiente de Migração de Banco de Dados: MariaDB para Informix com Docker Compose](#ambiente-de-migração-de-banco-de-dados-mariadb-para-informix-com-docker-compose)
  - [Conteúdo](#conteúdo)
  - [Pré-requisitos](#pré-requisitos)
  - [Estrutura do Projeto](#estrutura-do-projeto)
  - [Como Começar](#como-começar)
  - [Acessando o Banco de Dados Informix](#acessando-o-banco-de-dados-informix)
    - [Conectando via dbaccess](#conectando-via-dbaccess)
    - [Executando Scripts SQL](#executando-scripts-sql)
    - [DML (Data Manipulation Language) - Linguagem de Manipulação de Dados](#dml-data-manipulation-language---linguagem-de-manipulação-de-dados)
      - [`CREATE TABLE`](#create-table)
      - [`ALTER TABLE`](#alter-table)
      - [`DROP TABLE`](#drop-table)
    - [DML (Data Manipulation Language) - Linguagem de Manipulação de Dados](#dml-data-manipulation-language---linguagem-de-manipulação-de-dados-1)
      - [`INSERT`](#insert)
      - [`SELECT`](#select)
      - [`UPDATE`](#update)
      - [`DELETE`](#delete)
    - [Controle de Transação](#controle-de-transação)
    - [Procedure para consultar informações do catálogo](#procedure-para-consultar-informações-do-catálogo)

## Pré-requisitos

*   **Docker instalado**: [Instruções de Instalação do Docker](https://docs.docker.com/get-docker/)
*   **Docker Compose instalado** (docker compose v2).

## Estrutura do Projeto

```text
.
├── docker-compose.yml       # Configuração dos containers
├── scripts/
│   ├── ifxtables.sql        # Exemplo de scripts SQL de criação de banco
│   ├── ifxinserts.sql       # Exemplo de criação de tabelas
│   ├── ifxconstraints.sql   # Exemplo de inserção de dados
│   └── ...                  # Outros scripts de migração
└── README.md                # Este documento
```

## Como Começar

1.  **Clone ou Baixe os Arquivos**

    ```bash
    git clone <URL_REPOSITORIO>
    cd <PASTA_DO_PROJETO>
    ```

2.  **Inicie os Contêineres**

    ```bash
    docker compose up -d
    ```

    Aguarde alguns instantes até que os bancos estejam prontos. Você pode acompanhar com:
    
    ```bash
    docker ps
    ```

## Acessando o Banco de Dados Informix

### Conectando via dbaccess

1.  Acesse o container do Informix:

    ```bash
    docker exec -it informix_db_docs bash
    ```

2.  Inicie o utilitário:

    ```bash
    dbaccess
    ```

3.  No menu do `dbaccess`, escolha:

    ```
    -> DATABASE -> CREATE -> NOME_DO_BANCO
    ```
    

### Executando Scripts SQL

1. Saia do contêiner com o comando `exit`

2.  Copie os scripts para dentro do contêiner:

    ```bash
    docker cp ./scripts/ifxtables.sql informix_db_docs:/home/informix/ifxtables.sql
    docker cp ./scripts/ifxinserts.sql informix_db_docs:/home/informix/ifxinserts.sql
    docker cp ./scripts/ifxconstraints.sql informix_db_docs:/home/informix/ifxconstraints.sql
    ... #restante dos scripts
    ```
3. Entre no contêiner `docker exec -it informix_db_docs bash`

2.  Execute os scripts com `dbaccess` na seguinte ordem:

    ```bash
    dbaccess <NOME_DO_BANCO> /home/informix/ifxtables.sql
    dbaccess <NOME_DO_BANCO> /home/informix/ifxinserts.sql
    dbaccess <NOME_DO_BANCO> /home/informix/ifxconstraints.sql
    dbaccess <NOME_DO_BANCO> /home/informix/ifxviews.sql
    ```
    
    **Exemplo:**
    
    ```bash
    dbaccess abd_migration /home/informix/01_criacao_banco.sql
    ```

**Navegação no dbaccess**

*   `DATABASE` → Escolha o banco
*   `Query-language` → Para escrever e executar SQL
*   `Use-editor` → Editar SQL com editor externo (vi por padrão)
*   `Exit` → Sair

<br/>

### DML (Data Manipulation Language) - Linguagem de Manipulação de Dados

Comandos usados para consultar, inserir, atualizar e excluir dados *dentro* das tabelas.

---

#### `CREATE TABLE`
Cria uma nova tabela para armazenar dados.

**Sintaxe e Tipos de Dados Comuns:**
```sql
CREATE TABLE nome_da_tabela (
    nome_coluna1 TIPO_DE_DADO [CONSTRAINTS],
    nome_coluna2 TIPO_DE_DADO [CONSTRAINTS],
    ...
    PRIMARY KEY (nome_coluna_pk)
);
```
*   `SERIAL` ou `SERIAL8`: Inteiro autoincrementável (similar ao `AUTO_INCREMENT` do MySQL/MariaDB). `SERIAL` é 32-bit, `SERIAL8` é 64-bit.
*   `INTEGER`: Número inteiro.
*   `VARCHAR(n)`: String de caracteres com tamanho variável até `n`.
*   `CHAR(n)`: String de caracteres com tamanho fixo de `n`.
*   `DECIMAL(p, s)` ou `MONEY(p, s)`: Número decimal com precisão `p` e escala `s`.
*   `DATE`: Armazena apenas a data (ano, mês, dia).
*   `DATETIME YEAR TO SECOND`: Armazena data e hora.

**Exemplo:**
```sql
CREATE TABLE clientes (
    id_cliente      SERIAL NOT NULL,
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    data_cadastro   DATE,
    saldo           DECIMAL(10, 2),
    PRIMARY KEY (id_cliente)
);
```

---

#### `ALTER TABLE`
Modifica a estrutura de uma tabela existente.

**Exemplos:**

*   **Adicionar uma coluna:**
    ```sql
    ALTER TABLE clientes ADD (
        telefone VARCHAR(20)
    );
    ```

*   **Modificar uma coluna:**
    ```sql
    ALTER TABLE clientes MODIFY (
        email VARCHAR(255)
    );
    ```

*   **Remover uma coluna:**
    ```sql
    ALTER TABLE clientes DROP (saldo);
    ```

*   **Adicionar uma restrição (constraint):**
    ```sql
    ALTER TABLE clientes ADD CONSTRAINT chk_saldo CHECK (saldo >= 0);
    ```

---

#### `DROP TABLE`
Exclui permanentemente uma tabela e todos os seus dados. **Use com extremo cuidado!**

**Sintaxe:**
```sql
DROP TABLE nome_da_tabela;
```

**Exemplo:**
```sql
DROP TABLE clientes;
```

---
### DML (Data Manipulation Language) - Linguagem de Manipulação de Dados

Comandos usados para consultar, inserir, atualizar e excluir dados *dentro* das tabelas.

---

#### `INSERT`
Adiciona novas linhas (registros) a uma tabela.

**Sintaxe:**
```sql
INSERT INTO nome_da_tabela (coluna1, coluna2, ...)
VALUES (valor1, valor2, ...);
```

**Exemplo:**
```sql
INSERT INTO clientes (nome, email, data_cadastro, saldo)
VALUES ('João da Silva', 'joao.silva@email.com', '2023-10-27', 150.75);

-- Como id_cliente é SERIAL, ele será gerado automaticamente.
```

---

#### `SELECT`
Consulta e recupera dados de uma ou mais tabelas.

**Exemplos:**

*   **Selecionar todas as colunas de todos os clientes:**
    ```sql
    SELECT * FROM clientes;
    ```

*   **Selecionar colunas específicas com um filtro (`WHERE`):**
    ```sql
    SELECT nome, email FROM clientes WHERE saldo > 100;
    ```

*   **Ordenar os resultados (`ORDER BY`):**
    ```sql
    SELECT * FROM clientes ORDER BY nome ASC; -- ASC (ascendente), DESC (descendente)
    ```

*   **Limitar o número de resultados (específico do Informix):**
    O Informix usa `FIRST` em vez de `LIMIT`.
    ```sql
    SELECT FIRST 10 * FROM clientes ORDER BY data_cadastro DESC;
    ```

*   **Paginação (específico do Informix):**
    Use `SKIP` para pular registros e `FIRST` para pegar a quantidade desejada.
    ```sql
    -- Pega 10 registros, pulando os primeiros 20 (página 3, com 10 por página)
    SELECT SKIP 20 FIRST 10 * FROM clientes ORDER BY nome;
    ```

---

#### `UPDATE`
Modifica dados existentes em uma tabela. **Sempre use a cláusula `WHERE` para evitar atualizar todos os registros!**

**Sintaxe:**
```sql
UPDATE nome_da_tabela
SET coluna1 = valor1, coluna2 = valor2, ...
WHERE condicao;
```

**Exemplo:**
```sql
UPDATE clientes
SET email = 'joao.silva.novo@email.com', saldo = 200.00
WHERE id_cliente = 1;
```

---

#### `DELETE`
Remove linhas de uma tabela. **Sempre use a cláusula `WHERE` para evitar excluir todos os dados da tabela!**

**Sintaxe:**
```sql
DELETE FROM nome_da_tabela WHERE condicao;
```

**Exemplo:**
```sql
DELETE FROM clientes WHERE email = 'cliente.inativo@email.com';
```

---

### Controle de Transação

Para bancos de dados criados com `LOG MODE ANSI`, você pode (e deve) agrupar comandos DML em transações para garantir a integridade dos dados.

*   **`BEGIN WORK`**: Inicia uma transação.
*   **`COMMIT WORK`**: Confirma e salva permanentemente todas as alterações feitas na transação.
*   **`ROLLBACK WORK`**: Descarta todas as alterações feitas na transação.

**Exemplo:**
```sql
BEGIN WORK;

UPDATE contas SET saldo = saldo - 100 WHERE id_conta = 'A';
UPDATE contas SET saldo = saldo + 100 WHERE id_conta = 'B';

-- Se tudo ocorreu bem
COMMIT WORK;

-- Se algo deu errado no meio do caminho, você poderia executar
-- ROLLBACK WORK;
```


---

### Procedure para consultar informações do catálogo

1.  Criar a procedure com `dbaccess`:

    ```bash
    dbaccess <NOME_DO_BANCO> /home/informix/procedureCatalogo.sql
    ```

2. Executar a procedure:
   ```bash
    dbaccess -> Query-language -> New -> "EXECUTE PROCEDURE listar_relacionamentos('nome_tabela');" -> ESC -> RUN
    ```



### Triggers de atualização 

1.  Criar trigger com `dbaccess`:

    ```bash
    dbaccess <NOME_DO_BANCO> /home/informix/triggers.sql
    ```

2. Testar trigger saldo_produto:
   
- Verificar saldo de algum produto: 
  ```
  SELECT procodigo, pronome, prosaldo FROM produto WHERE procodigo = 2;
  ```

- Realizar uma venda: 
  ```
  INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (200, 2, 4);
  ```

- Verificar se o saldo atualizou: 
  ```
  SELECT procodigo, pronome, prosaldo FROM produto WHERE procodigo = 2;
  ```

### Transactions 

1.  Testar transaction na interface do informix(Banco criado com `LOG MODE ANSI`): 
  ```
  dbaccess -> Query-language -> New -> "Conteúdo do arquivo 'transactions.sql'" -> ESC -> RUN
  ```
