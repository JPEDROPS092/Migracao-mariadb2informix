# `README.md` Completo:


# Ambiente de Migração de Banco de Dados: MariaDB para Informix com Docker Compose

Este projeto utiliza Docker Compose para configurar rapidamente um ambiente com um servidor MariaDB e um servidor Informix Developer Edition. O objetivo é facilitar o desenvolvimento e teste de scripts de migração de dados e esquemas entre esses dois sistemas de gerenciamento de banco de dados.

## Conteúdo

- [Pré-requisitos](#pré-requisitos)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Como Começar](#como-começar)
  - [1. Clone ou Baixe os Arquivos](#1-clone-ou-baixe-os-arquivos)
  - [2. Inicie os Contêineres](#2-inicie-os-contêineres)
- [Acessando o Banco de Dados MariaDB](#acessando-o-banco-de-dados-mariadb)
  - [Detalhes da Conexão (MariaDB)](#detalhes-da-conexão-mariadb)
  - [Conectando via CLI (MariaDB)](#conectando-via-cli-mariadb)
  - [Conectando via Ferramenta Gráfica (MariaDB)](#conectando-via-ferramenta-gráfica-mariadb)
- [Acessando o Banco de Dados Informix](#acessando-o-banco-de-dados-informix)
  - [Detalhes da Conexão (Informix)](#detalhes-da-conexão-informix)
  - [Conectando via `dbaccess` (dentro do contêiner Informix)](#conectando-via-dbaccess-dentro-do-contêiner-informix)
  - [Conectando via Ferramenta Gráfica (Informix)](#conectando-via-ferramenta-gráfica-informix)
- [Gerenciando os Contêineres](#gerenciando-os-contêineres)
  - [Verificar Logs](#verificar-logs)
  - [Parar os Contêineres](#parar-os-contêineres)
  - [Parar e Remover Contêineres (sem remover volumes)](#parar-e-remover-contêineres-sem-remover-volumes)
  - [Parar e Remover Contêineres e Volumes (PERDA DE DADOS)](#parar-e-remover-contêineres-e-volumes-perda-de-dados)
- [Observações Importantes](#observações-importantes)
- [Solução de Problemas Comuns](#solução-de-problemas-comuns)

## Pré-requisitos

- Docker instalado: [Instruções de Instalação do Docker](https://docs.docker.com/get-docker/)
- Docker Compose instalado (geralmente incluído com Docker Desktop, ou `docker compose` CLI v2).

## Estrutura do Projeto

```

.
└── docker-compose.yml  # Arquivo de configuração do Docker Compose
└── README.md           # Este arquivo

```

## Como Começar

### 1. Clone ou Baixe os Arquivos

Se este projeto estiver em um repositório Git:
```bash
git clone <>
cd <>
```

Ou, simplesmente crie um arquivo `docker-compose.yml` no seu diretório de projeto com o conteúdo fornecido acima.

### 2. Inicie os Contêineres

No diretório onde o arquivo `docker-compose.yml` está localizado, execute:

```bash
docker compose up -d
```

O `-d` executa os contêineres em modo "detached" (em segundo plano).

Aguarde alguns instantes para que os bancos de dados sejam inicializados. Você pode verificar o status com `docker ps`. Os `healthchecks` configurados ajudarão a determinar se os serviços estão prontos.

## Acessando o Banco de Dados MariaDB

### Detalhes da Conexão (MariaDB)

- **Host**: `localhost` (ou o IP da sua máquina Docker, se não for local)
- **Porta**: `3307` (mapeada da porta 3306 do contêiner)
- **Usuário Root**: `root`
- **Senha Root**: `admin`
- **Banco de Dados Padrão**: `abd_migration`
- **Usuário Adicional**: `admin`
- **Senha do Usuário Adicional**: `admin`

### Conectando via CLI (MariaDB)

Você pode usar o cliente `mysql` (se instalado localmente):

```bash
mysql -h 127.0.0.1 -P 3307 -u admin -padmin abd_migration
```

Ou, para acessar como root:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -padmin
```

Alternativamente, acesse o CLI dentro do contêiner:

```bash
docker exec -it mariadb_migration mysql -u admin -padmin abd_migration
```

### Conectando via Ferramenta Gráfica (MariaDB)

Use sua ferramenta gráfica preferida (DBeaver, HeidiSQL, MySQL Workbench, etc.) com os detalhes de conexão acima.

## Acessando o Banco de Dados Informix

### Detalhes da Conexão (Informix)

- **Host**: `localhost` (ou o IP da sua máquina Docker)
- **Porta SQL (onsoctcp)**: `9088`
- **Porta DRDA**: `9089`
- **Nome do Servidor Informix (INFORMIXSERVER)**: Geralmente `ids_1` (verifique os logs do contêiner `migration_informix` na primeira inicialização se tiver dúvidas, procurando por `INFORMIXSERVER`).
- **Usuário Padrão**: `informix` (geralmente sem senha para conexões locais dentro do contêiner ou com senha `informix`. Para conexões externas, pode ser necessário configurar ou usar uma senha padrão, se houver).
- **Banco de Dados Inicial (exemplo)**: `sysmaster` (banco de dados do sistema para informações de metadados). Você pode criar seus próprios bancos de dados.

### Conectando via `dbaccess` (dentro do contêiner Informix)

1. Entre no contêiner:

   ```bash
   docker exec -it informix_database bash
   ```
2. Uma vez dentro do contêiner, use o utilitário `dbaccess`:

   ```bash
   # Conectar ao banco de dados sysmaster (geralmente não pede senha para o usuário 'informix' aqui)
   dbaccess sysmaster -
   ```

   O `-` ao final tenta conectar sem prompt de senha. Se pedir senha, tente `informix` ou deixe em branco.
3. Dentro do `dbaccess`:

   ```sql
   -- Listar todos os bancos de dados
   SELECT name FROM sysdatabases;

   -- Criar um novo banco de dados (exemplo)
   -- CREATE DATABASE meu_banco WITH LOG; -- (Execute no menu SQL do dbaccess)

   -- Conectar a um banco de dados específico (ex: abd_migration, se criado)
   -- DATABASE abd_migration; -- (Execute no menu Database > Select do dbaccess)

   -- Listar todas as tabelas do usuário atual no banco conectado
   SELECT tabname FROM systables WHERE tabtype = 'T' AND tabid > 99;

   -- Sair do dbaccess
   -- Selecione a opção Exit no menu.
   ```

   Para sair do `dbaccess`, navegue pelos menus ou use `Ctrl+C` se estiver preso e depois digite `quit;` se voltar ao prompt SQL.

### Conectando via Ferramenta Gráfica (Informix)

Use sua ferramenta gráfica preferida que suporte Informix (ex: DBeaver). Você precisará do driver JDBC do Informix.

- **Driver JDBC**: Geralmente `ifxjdbc.jar`. DBeaver pode baixá-lo automaticamente.
- **URL JDBC Típica**:
  `jdbc:informix-sqli://localhost:9088/sysmaster:INFORMIXSERVER=ids_1;USER=informix;PASSWORD=informix`
  (Ajuste `sysmaster` para o nome do seu banco de dados alvo, ex: `abd_migration`).
  (A senha `informix` pode ou não ser necessária/correta dependendo da configuração da imagem).
- **Usuário**: `informix`
- **Senha**: Tente `informix`, ou deixe em branco inicialmente. A imagem `ibmcom/informix-developer-database` pode não definir uma senha para o usuário `informix` por padrão para conexões externas ou pode ser `informix`.

## Gerenciando os Contêineres

### Verificar Logs

Para ver os logs de um contêiner específico (útil para depuração):

```bash
docker logs mariadb_migration
docker logs migration_informix
```

Para seguir os logs em tempo real:

```bash
docker logs -f migration_informix
```

### Parar os Contêineres

Isso para os contêineres, mas não os remove. Seus dados nos volumes persistirão.

```bash
docker compose stop
```

### Parar e Remover Contêineres (sem remover volumes)

Isso para e remove os contêineres. Os volumes nomeados (`mariadb_data`, `informix_data`) **não** são removidos, então seus dados são preservados.

```bash
docker compose down
```

### Parar e Remover Contêineres e Volumes (PERDA DE DADOS)

**CUIDADO**: Isso para e remove os contêineres E os volumes nomeados, resultando na **perda de todos os dados** armazenados nos bancos de dados.

```bash
docker compose down -v
```

## Observações Importantes

- **Versões de Imagem**: É altamente recomendável fixar as versões das imagens (ex: `mariadb:10.11`, `ibmcom/informix-developer-database:14.10.FC12DE`) no `docker-compose.yml` em vez de usar `latest`. Isso garante um ambiente consistente e reprodutível.
- **`privileged: true` para Informix**: O contêiner Informix requer privilégios elevados para configurar corretamente os parâmetros do kernel e memória compartilhada dentro do ambiente Docker.
- **Persistência de Dados**: Os dados são persistidos usando volumes nomeados do Docker (`mariadb_data`, `informix_data`). Eles residem na sua máquina host (gerenciados pelo Docker) e sobrevivem à remoção dos contêineres (a menos que você use `docker compose down -v`).
- **Healthchecks**: Os `healthchecks` ajudam o Docker a determinar se os serviços estão realmente prontos e saudáveis, não apenas se o processo principal do contêiner foi iniciado.
- **Nome do Servidor Informix**: O `INFORMIXSERVER` é crucial para conexões ao Informix. O padrão na imagem developer é `ids_1`, mas sempre verifique os logs na primeira execução se encontrar problemas de conexão.
- **Memória para Informix**: A imagem `ibmcom/informix-developer-database` é otimizada para desenvolvimento. Para produção ou cargas de trabalho pesadas, você precisaria de uma imagem licenciada e mais recursos (CPU/RAM) alocados ao Docker.

## Solução de Problemas Comuns

- **Erro de "Porta já em uso"**: Verifique se as portas `3307` ou `9088`/`9089` já estão sendo usadas por outros serviços na sua máquina host. Altere as portas no lado do host no `docker-compose.yml` (ex: `"3308:3306"`) se necessário.
- **Contêiner Informix não inicia / `healthcheck` falha**:
  - Verifique os logs (`docker logs migration_informix`).
  - Certifique-se de que o Docker tem recursos suficientes (CPU/RAM), especialmente se estiver em uma máquina com recursos limitados. O Informix pode ser mais exigente.
  - O `start_period` no healthcheck dá um tempo para o Informix iniciar. Se demorar muito, ele pode ser marcado como não saudável.
- **Não consigo conectar ao Informix com GUI**:
  - Verifique se o nome do servidor (`INFORMIXSERVER=ids_1`) está correto na sua string de conexão JDBC.
  - Tente diferentes combinações de usuário/senha (`informix`/`informix`, `informix`/em branco).
  - Certifique-se de que o firewall não está bloqueando a porta `9088`.
  - Confirme se o driver JDBC do Informix está corretamente configurado na sua ferramenta.

```

Este `README.md` fornece uma visão geral abrangente de como usar o `docker-compose.yml` fornecido, desde a configuração inicial até o acesso e gerenciamento dos bancos de dados.
```
