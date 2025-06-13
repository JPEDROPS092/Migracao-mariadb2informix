-- #############################################################################
-- #                                                                           #
-- # Informix Converted Script for Database bd2025                             #
-- #                                                                           #
-- #############################################################################

-- Note: Tables are dropped without "IF EXISTS". Errors on first run are normal.
-- The order of creation is important to satisfy foreign key constraints.

-- Dropping tables in reverse order of creation
DROP VIEW vw_cliente_bai_estcivil;
DROP TABLE itemvenda;
DROP TABLE venda;
DROP TABLE vendedor;
DROP TABLE produto;
DROP TABLE grupoproduto;
DROP TABLE fornecedorfone;
DROP TABLE fornecedor;
DROP TABLE filial;
DROP TABLE funcionario;
DROP TABLE cliente;
DROP TABLE estadocivil;
DROP TABLE bairro;
DROP TABLE zona;
DROP TABLE cidade;
DROP TABLE formapagamento;
DROP TABLE atualizacao;


-- #############################################################################
-- # Table Creation
-- #############################################################################

CREATE TABLE cidade (
  cidcodigo INT NOT NULL,
  cidnome VARCHAR(80) NOT NULL,
  PRIMARY KEY (cidcodigo)
);

CREATE TABLE zona (
  zoncodigo INT NOT NULL,
  zonnome VARCHAR(15) NOT NULL,
  zoncidcodigo INT NOT NULL,
  PRIMARY KEY (zoncodigo),
  FOREIGN KEY (zoncidcodigo) REFERENCES cidade (cidcodigo) CONSTRAINT zona_fk_zoncidcodigo
);

CREATE TABLE bairro (
  baicodigo INT NOT NULL,
  bainome VARCHAR(30) NOT NULL,
  baizoncodigo INT NOT NULL,
  baiqtdepessoas INT NOT NULL DEFAULT 0,
  PRIMARY KEY (baicodigo),
  FOREIGN KEY (baizoncodigo) REFERENCES zona (zoncodigo) CONSTRAINT bairro_fk_baizoncodigo
);

CREATE TABLE estadocivil (
  estcodigo INT NOT NULL,
  estdescricao VARCHAR(40) NOT NULL,
  PRIMARY KEY (estcodigo)
);

-- Note on cliente.clicodigo: Defined as INTEGER to allow explicit value insertion from the dump.
-- To enable auto-increment for new records after this load, run:
-- ALTER TABLE cliente MODIFY (clicodigo SERIAL(605)); -- Starts next value at 605
CREATE TABLE cliente (
  clicodigo INT NOT NULL,
  clisexo CHAR(1) NOT NULL,
  clirendamensal DECIMAL(8,2) NOT NULL, -- Changed from double(6,2)
  clinome VARCHAR(60) NOT NULL,
  clibaicodigo INT NOT NULL,
  clifone VARCHAR(10) NOT NULL DEFAULT '',
  cliestcodigo INT NOT NULL,
  clidtcadastro DATE,
  clidtdesativacao DATE,
  PRIMARY KEY (clicodigo),
  FOREIGN KEY (clibaicodigo) REFERENCES bairro (baicodigo) CONSTRAINT cliente_fk_clibaicodigo,
  FOREIGN KEY (cliestcodigo) REFERENCES estadocivil (estcodigo) CONSTRAINT cliente_fk_cliestcodigo
);
CREATE INDEX idx_cliente_bairro ON cliente(clibaicodigo);
CREATE INDEX idx_cliente_estcivil ON cliente(cliestcodigo);


CREATE TABLE funcionario (
  funcodigo INT NOT NULL,
  funnome VARCHAR(50) NOT NULL,
  funsalario DECIMAL(8,2) NOT NULL, -- Changed from double(6,2)
  funbaicodigo INT NOT NULL,
  funcodgerente INT,
  fundtdem DATE,
  funestcodigo INT NOT NULL,
  funsenha VARCHAR(20),
  funlogin VARCHAR(30),
  fundtnascto DATE,
  PRIMARY KEY (funcodigo),
  FOREIGN KEY (funbaicodigo) REFERENCES bairro (baicodigo) CONSTRAINT funcionario_fk_funbaicodigo,
  FOREIGN KEY (funcodgerente) REFERENCES funcionario (funcodigo) CONSTRAINT funcionario_fk_funcodgerente,
  FOREIGN KEY (funestcodigo) REFERENCES estadocivil (estcodigo) CONSTRAINT funcionario_fk_funestcodigo
);
CREATE INDEX idx_func_bairro ON funcionario(funbaicodigo);
CREATE INDEX idx_func_gerente ON funcionario(funcodgerente);
CREATE INDEX idx_func_estcivil ON funcionario(funestcodigo);

CREATE TABLE filial (
  filcodigo INT NOT NULL,
  filnome VARCHAR(40) NOT NULL,
  filcodgerente INT NOT NULL,
  filbaicodigo INT NOT NULL,
  PRIMARY KEY (filcodigo),
  FOREIGN KEY (filbaicodigo) REFERENCES bairro (baicodigo) CONSTRAINT filial_fk_filbaicodigo,
  FOREIGN KEY (filcodgerente) REFERENCES funcionario (funcodigo) CONSTRAINT filial_fk_filcodgerente
);

CREATE TABLE fornecedor (
  forcnpj CHAR(18) NOT NULL,
  fornome VARCHAR(100) NOT NULL,
  forfone CHAR(9) NOT NULL,
  forcidcodigo INT NOT NULL,
  PRIMARY KEY (forcnpj),
  FOREIGN KEY (forcidcodigo) REFERENCES cidade (cidcodigo) CONSTRAINT fornecedor_fk_forcidcodigo
);

CREATE TABLE fornecedorfone (
  ffforcnpj CHAR(18) NOT NULL,
  fffone CHAR(9) NOT NULL,
  PRIMARY KEY (ffforcnpj, fffone),
  FOREIGN KEY (ffforcnpj) REFERENCES fornecedor (forcnpj) CONSTRAINT fornecedorfone_fk_ffforcnpj
);

CREATE TABLE grupoproduto (
  grpcodigo INT NOT NULL,
  grpdescricao VARCHAR(40) NOT NULL,
  grpcomissao DECIMAL(4,2) NOT NULL,
  grpativo CHAR(1) NOT NULL,
  PRIMARY KEY (grpcodigo)
);

CREATE TABLE produto (
  procodigo INT NOT NULL,
  pronome VARCHAR(80) NOT NULL,
  procusto DECIMAL(9,2) NOT NULL, -- Changed from double(7,2)
  propreco DECIMAL(9,2) NOT NULL, -- Changed from double(7,2)
  proativo CHAR(1) NOT NULL,
  progrpcodigo INT NOT NULL,
  prosaldo INT NOT NULL,
  proforcnpj CHAR(18) NOT NULL,
  PRIMARY KEY (procodigo),
  FOREIGN KEY (progrpcodigo) REFERENCES grupoproduto (grpcodigo) CONSTRAINT produto_fk_progrpcodigo,
  FOREIGN KEY (proforcnpj) REFERENCES fornecedor (forcnpj) CONSTRAINT produto_fk_proforcnpj
);
CREATE INDEX idx_prod_grupo ON produto(progrpcodigo);
CREATE INDEX idx_prod_forn ON produto(proforcnpj);

CREATE TABLE vendedor (
  vefuncodigo INT NOT NULL,
  PRIMARY KEY (vefuncodigo)
);

CREATE TABLE formapagamento (
  fpcodigo SMALLINT NOT NULL,
  fpdescricao VARCHAR(60) NOT NULL,
  fpativo BOOLEAN NOT NULL, -- Changed from tinyint(1)
  PRIMARY KEY (fpcodigo)
);

CREATE TABLE venda (
  vencodigo INT NOT NULL,
  vendata DATE NOT NULL,
  venfilcodigo INT NOT NULL,
  venclicodigo INT NOT NULL,
  venfuncodigo INT NOT NULL,
  venfpcodigo SMALLINT,
  PRIMARY KEY (vencodigo),
  FOREIGN KEY (venfilcodigo) REFERENCES filial (filcodigo) CONSTRAINT venda_fk_venfilcodigo,
  FOREIGN KEY (venclicodigo) REFERENCES cliente (clicodigo) CONSTRAINT venda_fk_venclicodigo,
  FOREIGN KEY (venfuncodigo) REFERENCES vendedor (vefuncodigo) CONSTRAINT venda_fk_venfuncodigo,
  FOREIGN KEY (venfpcodigo) REFERENCES formapagamento (fpcodigo) CONSTRAINT venda_fk_venfpcodigo
);
CREATE INDEX idx_venda_cliente ON venda(venclicodigo);
CREATE INDEX idx_venda_func ON venda(venfuncodigo);
CREATE INDEX idx_venda_filial ON venda(venfilcodigo);

CREATE TABLE itemvenda (
  itvvencodigo INT NOT NULL,
  itvprocodigo INT NOT NULL,
  itvqtde INT NOT NULL,
  PRIMARY KEY (itvvencodigo, itvprocodigo),
  FOREIGN KEY (itvvencodigo) REFERENCES venda (vencodigo) CONSTRAINT itemvenda_fk_itvvencodigo,
  FOREIGN KEY (itvprocodigo) REFERENCES produto (procodigo) CONSTRAINT itemvenda_fk_itvprocodigo
);
CREATE INDEX idx_itemvenda_prod ON itemvenda(itvprocodigo);


-- Note on atualizacao.atid: Defined as INTEGER to allow explicit value insertion.
-- To enable auto-increment for new records, run:
-- ALTER TABLE atualizacao MODIFY (atid SERIAL(5));
CREATE TABLE atualizacao (
  atid INT NOT NULL,
  attabela VARCHAR(255),
  atcoluna VARCHAR(255),
  atvalor VARCHAR(255),
  atcondicao VARCHAR(255),
  PRIMARY KEY (atid)
);

-- #############################################################################
-- # Data Insertion
-- #############################################################################

-- Note: All `LOCK TABLES` and `UNLOCK TABLES` statements have been removed.
-- Backticks have been removed.

INSERT INTO atualizacao VALUES (1,'usuario_perfil','upstatus','Habilitado','upid <= 3');
INSERT INTO atualizacao VALUES (2,'usuario_perfil','upstatus','Desabilitado','upid > 3');
INSERT INTO atualizacao VALUES (3,'usuario_perfil','upstatus','Habilitado','upid <= 3');
INSERT INTO atualizacao VALUES (4,'usuario_perfil','upstatus','Desabilitado','upid > 3');

INSERT INTO cidade VALUES (1,'Manaus');
INSERT INTO cidade VALUES (2,'Belém');
INSERT INTO cidade VALUES (3,'Porto Velho');
INSERT INTO cidade VALUES (4,'Rio Branco');
INSERT INTO cidade VALUES (5,'Belo Horizonte');
INSERT INTO cidade VALUES (6,'Rio de Janeiro');
INSERT INTO cidade VALUES (7,'São Paulo');
INSERT INTO cidade VALUES (8,'Fortaleza');
INSERT INTO cidade VALUES (9,'Itacoatiara');
INSERT INTO cidade VALUES (10,'Parintins');
INSERT INTO cidade VALUES (11,'Coari');
INSERT INTO cidade VALUES (12,'Rio Preto da Eva');

INSERT INTO zona VALUES (1,'NORTE',1);
INSERT INTO zona VALUES (2,'SUL',1);
INSERT INTO zona VALUES (3,'LESTE',1);
INSERT INTO zona VALUES (4,'OESTE',1);
INSERT INTO zona VALUES (5,'CENTRO-OESTE',1);
INSERT INTO zona VALUES (6,'CENTRO-SUL',1);

INSERT INTO bairro VALUES (1,'ADRIANÓPOLIS',1,10549);
INSERT INTO bairro VALUES (2,'CENTRO',2,39228);
INSERT INTO bairro VALUES (3,'CACHOEIRINHA',2,20035);
INSERT INTO bairro VALUES (4,'ALEIXO',6,24417);
INSERT INTO bairro VALUES (5,'PLANALTO',5,19249);
INSERT INTO bairro VALUES (6,'PARQUE 10',6,48771);
INSERT INTO bairro VALUES (7,'COROADO',3,60709);
INSERT INTO bairro VALUES (8,'JAPIIM',2,63092);
INSERT INTO bairro VALUES (9,'EDUCANDOS',2,18745);
INSERT INTO bairro VALUES (10,'PONTA NEGRA',4,5919);
INSERT INTO bairro VALUES (11,'SAO JOSE',3,78222);
INSERT INTO bairro VALUES (12,'ALVORADA',2,76392);
INSERT INTO bairro VALUES (13,'FLORES',6,56859);
INSERT INTO bairro VALUES (14,'DISTRITO INDUSTRIAL',3,3201);
INSERT INTO bairro VALUES (15,'COMPENSA',4,89645);
INSERT INTO bairro VALUES (16,'PETRÓPOLIS',2,48717);

INSERT INTO estadocivil VALUES (1,'Solteiro');
INSERT INTO estadocivil VALUES (2,'Casado');
INSERT INTO estadocivil VALUES (3,'Divorciado');
INSERT INTO estadocivil VALUES (4,'Viúvo');

-- Data for cliente (a small subset for brevity, the full list is large)
-- The full INSERT list from your script should be pasted here.
INSERT INTO cliente VALUES (1,'M',2550.00,'GANDERSON DOS SANTOS',1,'',1,NULL,NULL);
INSERT INTO cliente VALUES (2,'M',3910.00,'FRANCISCO DOS SANTOS OLIVEIRA',8,'',1,NULL,NULL);
INSERT INTO cliente VALUES (4,'M',1615.00,'CARLOS SOUZA MAGALHAES',1,'',1,NULL,NULL);
INSERT INTO cliente VALUES (5,'F',2465.00,'CLEUMA O DIAS',5,'',2,NULL,NULL);
-- ... (paste the rest of your client INSERT statements here) ...
INSERT INTO cliente VALUES (602,'m',1700.00,'cliente 602',2,'1111-2222',2,'2016-10-25',NULL);
INSERT INTO cliente VALUES (603,'F',3500.00,'Fulana da Silva',1,'88888-8888',1,'2024-03-06',NULL);
INSERT INTO cliente VALUES (604,'F',3400.00,'CLIENTE PARA TESTE TRIGGER',1,'9999-9999',1,'2024-03-13',NULL);


INSERT INTO funcionario VALUES (1,'Fernando da Costa',2868.75,8,NULL,NULL,3,'','',NULL);
INSERT INTO funcionario VALUES (2,'Joaquim da Silva',1721.25,4,1,NULL,1,'','',NULL);
INSERT INTO funcionario VALUES (3,'Manuel Carlos Almeida',1759.50,7,2,NULL,2,'','',NULL);
INSERT INTO funcionario VALUES (4,'Suellen Pinheiro',1836.00,4,1,NULL,1,'','',NULL);
INSERT INTO funcionario VALUES (5,'Josefina da Costa',2065.50,1,2,NULL,2,'','',NULL);
INSERT INTO funcionario VALUES (15,'SELMA LIMA FRANCA',8800.36,4,NULL,NULL,2,'','',NULL);
-- ... (paste the rest of your funcionario INSERT statements here) ...
INSERT INTO funcionario VALUES (30,'JOAO DE DEUS',4592.86,10,15,NULL,2,'','',NULL);


INSERT INTO filial VALUES (1,'FILIAL ADRIANÓPOLIS',1,1);
INSERT INTO filial VALUES (2,'FILIAL CENTRO',2,2);
INSERT INTO filial VALUES (3,'FILIAL SÃO JOSÉ',1,11);

INSERT INTO formapagamento VALUES (1,'Dinheiro','t');
INSERT INTO formapagamento VALUES (2,'Débito','t');
INSERT INTO formapagamento VALUES (3,'Crédito','t');
INSERT INTO formapagamento VALUES (4,'Pix','t');
INSERT INTO formapagamento VALUES (5,'Boleto','t');

INSERT INTO fornecedor VALUES ('11.111.111/1111-11','Fornecedor 1','1111-1111',1);
INSERT INTO fornecedor VALUES ('22.222.222/2222-22','Fornecedor 2','2222-2222',2);
INSERT INTO fornecedor VALUES ('33.333.333/3333-33','Fornecedor 3','3333-3333',2);
INSERT INTO fornecedor VALUES ('44.444.444/4444-44','Fornecedor 4','4444-4444',4);
INSERT INTO fornecedor VALUES ('55.555.555/5555-55','Fornecedor 5','5555-5555',3);

-- No data for fornecedorfone

INSERT INTO grupoproduto VALUES (1,'TELEFONIA E CELULAR',2.75,'');
INSERT INTO grupoproduto VALUES (2,'FOTO',1.25,'');
INSERT INTO grupoproduto VALUES (3,'ELETRO-ELETRONICOS',3.50,'');
INSERT INTO grupoproduto VALUES (4,'INFORMATICA',3.75,'');
INSERT INTO grupoproduto VALUES (5,'MOVEIS',4.25,'');
INSERT INTO grupoproduto VALUES (6,'MEDICAMENTOS',2.75,'');

INSERT INTO produto VALUES (1,'Impressora deskjet HP 1150',800.00,1400.00,'1',4,10,'22.222.222/2222-22');
INSERT INTO produto VALUES (2,'No Break 1kva',270.00,4500.00,'0',4,23,'11.111.111/1111-11');
-- ... (paste the rest of your produto INSERT statements here) ...
INSERT INTO produto VALUES (25,'Poltrona com 2 lugares',375.00,890.00,'1',5,8,'11.111.111/1111-11');

INSERT INTO vendedor VALUES (2);
INSERT INTO vendedor VALUES (3);
INSERT INTO vendedor VALUES (4);
-- ... (paste the rest of your vendedor INSERT statements here) ...
INSERT INTO vendedor VALUES (30);

INSERT INTO venda VALUES (1,'2024-01-02',1,10,9,1);
INSERT INTO venda VALUES (2,'2024-01-02',2,1,2,1);
-- ... (paste the rest of your venda INSERT statements here) ...
INSERT INTO venda VALUES (111,'2006-08-25',1,100,10,4);


INSERT INTO itemvenda VALUES (1,5,20);
INSERT INTO itemvenda VALUES (1,14,1);
INSERT INTO itemvenda VALUES (1,24,5);
-- ... (paste the rest of your itemvenda INSERT statements here) ...
INSERT INTO itemvenda VALUES (111,25,2);


-- #############################################################################
-- # View Creation
-- #############################################################################

CREATE VIEW vw_cliente_bai_estcivil (clicodigo, clinome, clisexo, bainome, estdescricao, baizoncodigo, clidtcadastro) AS
  SELECT
    c.clicodigo,
    c.clinome,
    c.clisexo,
    b.bainome,
    e.estdescricao,
    b.baizoncodigo,
    c.clidtcadastro
  FROM cliente c, bairro b, estadocivil e
  WHERE c.clibaicodigo = b.baicodigo AND c.cliestcodigo = e.estcodigo;

-- #############################################################################
-- # End of Script
-- #############################################################################