`sql_converter_logic.py` script, explaining its methodology.

# Documentação da Lógica de Conversão SQL (MariaDB para Informix)

Este documento descreve a metodologia e as regras de conversão implementadas na classe `SQLConverter` presente no arquivo `sql_converter_logic.py`.

## 1. Introdução

A classe `SQLConverter` tem como objetivo auxiliar na migração de scripts SQL escritos para MariaDB (ou MySQL, dada a similaridade) para o dialeto SQL utilizado pelo banco de dados IBM Informix. A ferramenta opera através de uma série de substituições baseadas em expressões regulares (regex) para mapear sintaxes comuns e tipos de dados entre as duas plataformas.

É importante notar que esta ferramenta realiza uma conversão *assistida* e *não* é uma solução de migração 100% automatizada. Devido às diferenças sintáticas e, especialmente, procedurais (em Stored Procedures e Functions) entre MariaDB e Informix, a saída gerada **exige revisão manual** por um especialista em Informix para garantir a correção e otimização.

## 2. Metodologia Geral

A abordagem principal da classe `SQLConverter` é a seguinte:

1.  **Reset de Estado:** Ao iniciar uma nova conversão, o estado interno (avisos e contador de itens convertidos) é limpo.
2.  **Leitura do Script:** O script SQL de entrada (MariaDB) é lido como uma única string.
3.  **Processamento Sequencial:** Uma série de regras de conversão são aplicadas sequencialmente à string SQL. Cada regra utiliza expressões regulares para encontrar padrões MariaDB e substituí-los por seus equivalentes Informix.
4.  **Geração de Avisos:** Durante o processo, se a ferramenta encontrar sintaxes ou estruturas que foram convertidas de forma simplificada, ou que são conhecidamente complexas e exigem revisão manual, um aviso é adicionado a uma lista interna.
5.  **Contagem de Conversões:** Cada substituição baseada em regex que representa uma conversão sintática ou de tipo de dado significativa incrementa um contador.
6.  **Retorno:** A função `convert` retorna a string SQL modificada (Informix), a lista de avisos gerados e a contagem total de itens convertidos.

## 3. Regras de Conversão Implementadas

A classe aplica as seguintes regras de conversão, na ordem especificada no código:

*   **Lidar com `DELIMITER` para Stored Procedures/Functions:**
    *   **MariaDB:** Usa `DELIMITER //` antes de um bloco (PROCEDURE, FUNCTION, TRIGGER, EVENT) e `//` no final, voltando ao delimitador padrão (`;`) com `DELIMITER ;`.
    *   **Informix:** Não usa `DELIMITER` da mesma forma. Blocos de procedimento/função terminam explicitamente com `END PROCEDURE;` ou `END FUNCTION;`.
    *   **Implementação:** O código detecta declarações `DELIMITER`, as remove do script principal e, posteriormente, ajusta o final de blocos `CREATE PROCEDURE`/`FUNCTION` que terminam com um delimitador customizado para `END PROCEDURE;` ou `END FUNCTION;`.
    *   **Aviso:** Um aviso é gerado indicando que `DELIMITER` foi detectado, pois o tratamento é simplificado e complexidades (múltiplos delimitadores, DELIMITER em outros contextos) não são totalmente cobertas.

*   **`AUTO_INCREMENT` → `SERIAL` / `SERIAL8`:**
    *   **MariaDB:** Usa a palavra-chave `AUTO_INCREMENT` em colunas numéricas (INT, BIGINT) para geração automática de IDs únicos. Frequentemente acompanhado de `PRIMARY KEY` e/ou `NOT NULL`/`DEFAULT NULL`.
    *   **Informix:** Usa tipos de dados `SERIAL` (para INT) e `SERIAL8` (para BIGINT) para geração automática de IDs. `SERIAL` e `SERIAL8` geralmente implicam `NOT NULL` e são frequentemente usados como chaves primárias.
    *   **Implementação:** O código substitui `AUTO_INCREMENT` por `SERIAL` ou `SERIAL8`, tentando identificar o tipo numérico associado (INT vs BIGINT). Também tenta remover `NOT NULL` ou `DEFAULT NULL` se aparecem junto com `AUTO_INCREMENT`, pois `SERIAL` já lida com isso.
    *   **Nota:** O uso de `SERIAL`/`SERIAL8` no Informix geralmente já estabelece a coluna como chave primária. A coexistência de `SERIAL` e `PRIMARY KEY` explícito na mesma coluna na saída pode ocorrer e exige revisão.

*   **`DATETIME` → `DATETIME YEAR TO SECOND`:**
    *   **MariaDB:** O tipo `DATETIME` armazena data e hora (YYYY-MM-DD HH:MM:SS).
    *   **Informix:** O tipo `DATETIME` requer especificação da granularidade (ex: `DATETIME YEAR TO SECOND`, `DATETIME DAY TO MINUTE`).
    *   **Implementação:** Substitui a palavra-chave `DATETIME` por `DATETIME YEAR TO SECOND`, exceto se já for seguida por `YEAR` (evitando converter `DATETIME YEAR TO DAY` para `DATETIME YEAR TO SECOND YEAR TO DAY`).
    *   **Nota:** Outras granularidades de `DATETIME` no MariaDB (`DATE`, `TIME`, `TIMESTAMP`) não são convertidas por esta regra específica, mas Informix tem equivalentes (`DATE`, `TIME`, `TIMESTAMP`). `TIMESTAMP` no MariaDB frequentemente tem comportamento de atualização automática que não é replicado automaticamente.

*   **`TEXT` e Variantes → `CLOB`:**
    *   **MariaDB:** Usa `TEXT`, `TINYTEXT`, `MEDIUMTEXT`, `LONGTEXT` para armazenar strings longas.
    *   **Informix:** Usa `CLOB` (Character Large Object) para strings longas.
    *   **Implementação:** Substitui as palavras-chave `TEXT`, `TINYTEXT`, `MEDIUMTEXT`, `LONGTEXT` por `CLOB`.

*   **`NOW()` → `CURRENT YEAR TO SECOND`:**
    *   **MariaDB:** A função `NOW()` retorna a data e hora atuais.
    *   **Informix:** A expressão `CURRENT YEAR TO SECOND` retorna a data e hora atuais.
    *   **Implementação:** Substitui a função `NOW()` (com parênteses) por `CURRENT YEAR TO SECOND`.

*   **Remoção de Aspas Invertidas (` `):**
    *   **MariaDB:** Usa aspas invertidas para delimitar identificadores (nomes de tabelas, colunas, etc.), especialmente se contiverem caracteres especiais ou forem palavras reservadas.
    *   **Informix:** Usa aspas duplas (`"`) para delimitar identificadores que necessitam de citação. Aspas invertidas não são usadas.
    *   **Implementação:** Remove as aspas invertidas ao redor de identificadores. ` `identificador` ` torna-se `identificador`.
    *   **Nota:** O código não adiciona automaticamente aspas duplas onde elas *poderiam* ser necessárias no Informix (ex: para identificadores com espaços). Isso exige revisão manual se identificadores especiais forem usados.

*   **`LIMIT` → `FIRST` / `SKIP FIRST`:**
    *   **MariaDB:** A cláusula `LIMIT` em `SELECT` permite restringir o número de linhas retornadas (`LIMIT count`) e/ou pular as primeiras linhas (`LIMIT offset, count`).
    *   **Informix:** Usa as cláusulas `FIRST` (para o número de linhas) e `SKIP` (para o offset) após a palavra-chave `SELECT`. A ordem é `SELECT [SKIP offset] [FIRST count] ...`.
    *   **Implementação:** O código primeiro procura pelo padrão `SELECT ... LIMIT offset, count` e o reescreve como `SELECT SKIP offset FIRST count ...`. Se esse padrão não for encontrado, ele procura por `SELECT ... LIMIT count` e o reescreve como `SELECT FIRST count ...`.
    *   **Aviso:** Um aviso é gerado se a palavra `LIMIT` ainda estiver presente após as substituições, indicando que pode haver uso complexo (ex: subqueries) que exige revisão manual.

*   **Ajuste de `END;` em Stored Procedures/Functions:**
    *   **MariaDB:** Frequentemente usa `END;` para finalizar blocos em scripts sem `DELIMITER` customizado.
    *   **Informix:** Exige `END PROCEDURE;` ou `END FUNCTION;` para finalizar explicitamente os blocos correspondentes.
    *   **Implementação:** Procura por `CREATE PROCEDURE`/`FUNCTION` seguido por um corpo e terminando com `END;` e substitui por `END PROCEDURE;` ou `END FUNCTION;`. Isso complementa o tratamento de `DELIMITER`.

*   **Comentários `#` → `--`:**
    *   **MariaDB:** Permite comentários de linha que começam com `#`.
    *   **Informix:** Comentários de linha usam `--`. `#` não é um marcador de comentário padrão.
    *   **Implementação:** Substitui linhas que começam com `#` (ignorando espaços iniciais) por `--`.
    *   **Aviso:** Um aviso é gerado, pois o `#` pode ter sido usado dentro de strings literais, onde não deveria ser substituído.

## 4. Avisos Gerados e Necessidade de Revisão Manual

A classe `SQLConverter` gera avisos específicos para chamar a atenção do usuário para áreas críticas que requerem inspeção manual:

*   **`DELIMITER` detectado:** O tratamento é básico. Scripts complexos com múltiplos `DELIMITER`s ou seu uso em outros contextos podem falhar.
*   **`LIMIT` complexas:** O tratamento foca em `LIMIT` no nível superior de `SELECT`. Usos em subqueries ou outras formas podem não ser convertidos.
*   **`CREATE TABLE` - `SERIAL` e `PRIMARY KEY`:** Verificar se o uso de `SERIAL` é suficiente ou se a declaração `PRIMARY KEY` explícita é necessária ou redundante.
*   **`CREATE TABLE` - Chaves/Constraints:** Revisar a sintaxe de `PRIMARY KEY` e `FOREIGN KEY` para conformidade com Informix, especialmente nomes de `CONSTRAINT`.
*   **`ALTER TABLE` detectado:** A sintaxe de `ALTER TABLE` pode variar significativamente entre os SGBDs, especialmente para modificações complexas, adição/remoção de constraints nomeadas, etc.
*   **`CREATE VIEW` detectado:** A query `SELECT` interna é convertida pelas regras gerais, mas a sintaxe completa da view e opções específicas podem precisar de ajuste. A opção `WITH CASCADED CHECK OPTION` do MariaDB é removida, pois não é padrão no Informix.
*   **Comentários `#`:** Verificar se a substituição para `--` não impactou `char`/`varchar` literais que continham `#`.
*   **Stored Procedures/Functions (Geral):** **Este é o ponto mais crítico.** A conversão lida apenas com a estrutura externa (`DELIMITER`, `END`). A **lógica interna** (variáveis, tipos de dados procedurais, cursores, loops, condicionais, tratamento de erros, chamadas a outras procedures/functions, SQL embarcado) é drasticamente diferente entre MariaDB SQL/SPL e Informix SPL (Stored Procedure Language). **A totalidade do corpo das procedures/functions exige reescrita ou adaptação manual detalhada.**

Além dos avisos explícitos, a revisão manual deve focar em:

*   **Tipos de Dados:** A conversão cobre apenas os tipos mais comuns (`AUTO_INCREMENT`, `DATETIME`, `TEXT`). Outros tipos (ex: `ENUM`, `SET`, tipos espaciais, `JSON`, `DECIMAL` com precisão/escala específicas) podem precisar de mapeamento manual para tipos Informix (`DECIMAL`, `LVARCHAR`, etc.).
*   **Funções Built-in:** MariaDB e Informix possuem conjuntos diferentes de funções nativas (data, string, agregados, matemáticos, etc.). Funções MariaDB sem equivalente direto em Informix falharão e precisarão ser reescritas ou substituídas. A conversão de `NOW()` para `CURRENT YEAR TO SECOND` é uma exceção pontual.
*   **Sintaxe Específica:** Comandos como `INSERT IGNORE`, `REPLACE INTO`, `ON DUPLICATE KEY UPDATE` no MariaDB não têm equivalentes diretos e simples no Informix e exigirão lógica alternativa (ex: usando `MERGE`).
*   **Otimização:** Mesmo que a sintaxe seja convertida, a forma como as queries são otimizadas difere. `SELECT FIRST/SKIP` pode ter implicações de performance diferentes de `LIMIT`. Índices, hints e estatísticas são específicos de cada SGBD.
*   **Transações:** A sintaxe básica `COMMIT`/`ROLLBACK` é similar, mas o gerenciamento de transações, níveis de isolamento e locking podem ter diferenças importantes.

## 5. Como Usar

A classe `SQLConverter` é instanciada, e o método `convert` é chamado passando a string SQL MariaDB como argumento:

```python
converter = SQLConverter()
informix_sql, warnings, converted_count = converter.convert(maria_sql_string)

# Utilizar informix_sql, warnings e converted_count
print("SQL convertido:")
print(informix_sql)
print("\nAvisos:")
for warning in warnings:
    print(f"- {warning}")
print(f"\nTotal de itens convertidos: {converted_count}")
```

## 6. Conclusão

A ferramenta `SQLConverter` fornece uma base útil para a migração de scripts MariaDB para Informix, automatizando a conversão de sintaxes e tipos de dados comuns. No entanto, a natureza significativa das diferenças entre os dois SGBDs, particularmente em procedimentos armazenados e funções, significa que a **revisão e adaptação manual são etapas essenciais** e inevitáveis do processo de migração. Utilize os avisos gerados pela ferramenta como um guia para as áreas que necessitam de maior atenção.
```