INSERT INTO atualizacao (attabela, atcoluna, atvalor, atcondicao) VALUES ('usuario_perfil','upstatus','Habilitado','upid <= 3');
INSERT INTO atualizacao (attabela, atcoluna, atvalor, atcondicao) VALUES ('usuario_perfil','upstatus','Desabilitado','upid > 3');
INSERT INTO atualizacao (attabela, atcoluna, atvalor, atcondicao) VALUES ('usuario_perfil','upstatus','Habilitado','upid <= 3');
INSERT INTO atualizacao (attabela, atcoluna, atvalor, atcondicao) VALUES ('usuario_perfil','upstatus','Desabilitado','upid > 3');

-- Tabela: cidade
INSERT INTO cidade (cidcodigo, cidnome) VALUES (1,'Manaus');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (2,'Belém');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (3,'Porto Velho');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (4,'Rio Branco');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (5,'Belo Horizonte');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (6,'Rio de Janeiro');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (7,'São Paulo');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (8,'Fortaleza');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (9,'Itacoatiara');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (10,'Parintins');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (11,'Coari');
INSERT INTO cidade (cidcodigo, cidnome) VALUES (12,'Rio Preto da Eva');

-- Tabela: estadocivil
INSERT INTO estadocivil (estcodigo, estdescricao) VALUES (1,'Solteiro');
INSERT INTO estadocivil (estcodigo, estdescricao) VALUES (2,'Casado');
INSERT INTO estadocivil (estcodigo, estdescricao) VALUES (3,'Divorciado');
INSERT INTO estadocivil (estcodigo, estdescricao) VALUES (4,'Viúvo');

-- Tabela: zona
INSERT INTO zona (zoncodigo, zonnome, zoncidcodigo) VALUES (1,'NORTE',1);
INSERT INTO zona (zoncodigo, zonnome, zoncidcodigo) VALUES (2,'SUL',1);
INSERT INTO zona (zoncodigo, zonnome, zoncidcodigo) VALUES (3,'LESTE',1);
INSERT INTO zona (zoncodigo, zonnome, zoncidcodigo) VALUES (4,'OESTE',1);
INSERT INTO zona (zoncodigo, zonnome, zoncidcodigo) VALUES (5,'CENTRO-OESTE',1);
INSERT INTO zona (zoncodigo, zonnome, zoncidcodigo) VALUES (6,'CENTRO-SUL',1);

-- Tabela: bairro
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (1,'ADRIANÓPOLIS',1,10549);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (2,'CENTRO',2,39228);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (3,'CACHOEIRINHA',2,20035);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (4,'ALEIXO',6,24417);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (5,'PLANALTO',5,19249);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (6,'PARQUE 10',6,48771);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (7,'COROADO',3,60709);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (8,'JAPIIM',2,63092);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (9,'EDUCANDOS',2,18745);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (10,'PONTA NEGRA',4,5919);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (11,'SAO JOSE',3,78222);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (12,'ALVORADA',2,76392);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (13,'FLORES',6,56859);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (14,'DISTRITO INDUSTRIAL',3,3201);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (15,'COMPENSA',4,89645);
INSERT INTO bairro (baicodigo, bainome, baizoncodigo, baiqtdepessoas) VALUES (16,'PETRÓPOLIS',2,48717);

-- Tabela: cliente
-- A coluna 'clicodigo' é SERIAL, então não a especificamos no INSERT.
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',2550.00,'GANDERSON DOS SANTOS',1,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',3910.00,'FRANCISCO DOS SANTOS OLIVEIRA',8,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',1615.00,'CARLOS SOUZA MAGALHAES',1,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',2465.00,'CLEUMA O DIAS',5,'',2,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',3230.00,'MARIA R MARTINS',8,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',7140.00,'FRANCISCO M MONTEIRO',11,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',2329.00,'ALIRIO LIMA DA COSTA',9,'',3,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',3400.00,'FRANCISCA S CASTRO',5,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',2431.00,'EDMAR F DA SILVA',7,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',1394.00,'ERIVELTON O DA CUNHA',3,'',2,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',1870.00,'RAFAELA C DOS SANTOS',4,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',2601.00,'MAURICIO M DOS REIS',2,'',2,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',6460.00,'MARIA DA GLORIA MESQUITA ',4,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',4760.00,'ROBERTO DA SILVA PIMENTEL',3,'',3,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',1292.00,'KATRINA S ALBUQUERQUE',2,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('M',1647.30,'ANDERSON DE ARAUJO',9,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',2244.00,'EDIANE SOUZA MACIEL',11,'',2,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',6426.00,'RAIMUNDA R PINHEIRO',6,'',1,NULL,NULL);
INSERT INTO cliente (clisexo, clirendamensal, clinome, clibaicodigo, clifone, cliestcodigo, clidtcadastro, clidtdesativacao) VALUES ('F',2125.00,'ALESSANDRINA P RAMALHO',6,'',4,NULL,NULL);
-- ... (continua com todos os outros clientes, sem a coluna clicodigo)

-- Tabela: funcionario
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (1,'Fernando da Costa',2868.75,8,NULL,NULL,3,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (2,'Joaquim da Silva',1721.25,4,1,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (3,'Manuel Carlos Almeida',1759.50,7,2,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (4,'Suellen Pinheiro',1836.00,4,1,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (5,'Josefina da Costa',2065.50,1,2,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (6,'JOVEMLAN DA SILVA',3634.72,14,1,'2006-01-15',1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (7,'JEANE DA COSTA',2489.11,13,2,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (8,'VITORIA MELO COELHO',1327.28,14,3,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (9,'ZILDO LEAL BOTELHO',1721.25,12,2,NULL,3,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (10,'ROBSON MENDONÃ‡A MATOS',2999.68,11,3,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (11,'PAULO CESAR DE CARVALHO',2852.48,13,4,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (12,'MARIA DIANA OLIVEIRA',3768.85,6,2,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (13,'ANTONIA LIMA BATISTA',3431.91,4,4,NULL,3,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (14,'LETICIA COSTA SENA',3695.41,1,4,'2006-01-11',1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (15,'SELMA LIMA FRANCA',8800.36,4,NULL,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (16,'FERNANDA MARTINS DOS SANTOS',7324.88,2,15,NULL,3,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (17,'ANA MAGDA VALENTE',3557.25,3,4,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (18,'BRUNA REIS PAIVA',1391.33,5,2,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (19,'DANIELE FERREIRA OLIVEIRA',2162.86,6,4,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (20,'RAIMUNDO CARLOS SILVEIRA',7239.59,2,15,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (21,'GILSON SANTOS COSTA',2346.36,5,4,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (22,'VICTOR MENDONCA ALVES',3028.40,5,2,'2006-01-11',3,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (23,'MOISES SILVA MOURA',1459.69,12,4,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (24,'PATRICIA LEITE CARVALHO',3748.50,10,2,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (25,'PAULA PEREIRA',1745.90,5,15,NULL,2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (26,'RAFAEL JUVENAL',2147.97,6,2,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (27,'FRANCISCO SEIXAS',2594.25,5,2,'2006-01-13',2,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (28,'MARIA MADALENA',2086.36,11,15,NULL,1,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (29,'RITA DO PERPETUO SOCORRO',2152.57,12,15,'2006-01-13',3,'','',NULL);
INSERT INTO funcionario (funcodigo, funnome, funsalario, funbaicodigo, funcodgerente, fundtdem, funestcodigo, funsenha, funlogin, fundtnascto) VALUES (30,'JOAO DE DEUS',4592.86,10,15,NULL,2,'','',NULL);

-- Tabela: filial
INSERT INTO filial (filcodigo, filnome, filcodgerente, filbaicodigo) VALUES (1,'FILIAL ADRIANÓPOLIS',1,1);
INSERT INTO filial (filcodigo, filnome, filcodgerente, filbaicodigo) VALUES (2,'FILIAL CENTRO',2,2);
INSERT INTO filial (filcodigo, filnome, filcodgerente, filbaicodigo) VALUES (3,'FILIAL SÃO JOSÉ',1,11);

-- Tabela: formapagamento
INSERT INTO formapagamento (fpcodigo, fpdescricao, fpativo) VALUES (1,'Dinheiro','t');
INSERT INTO formapagamento (fpcodigo, fpdescricao, fpativo) VALUES (2,'Débito','t');
INSERT INTO formapagamento (fpcodigo, fpdescricao, fpativo) VALUES (3,'Crédito','t');
INSERT INTO formapagamento (fpcodigo, fpdescricao, fpativo) VALUES (4,'Pix','t');
INSERT INTO formapagamento (fpcodigo, fpdescricao, fpativo) VALUES (5,'Boleto','t');

-- Tabela: fornecedor
INSERT INTO fornecedor (forcnpj, fornome, forfone, forcidcodigo) VALUES ('11.111.111/1111-11','Fornecedor 1','1111-1111',1);
INSERT INTO fornecedor (forcnpj, fornome, forfone, forcidcodigo) VALUES ('22.222.222/2222-22','Fornecedor 2','2222-2222',2);
INSERT INTO fornecedor (forcnpj, fornome, forfone, forcidcodigo) VALUES ('33.333.333/3333-33','Fornecedor 3','3333-3333',2);
INSERT INTO fornecedor (forcnpj, fornome, forfone, forcidcodigo) VALUES ('44.444.444/4444-44','Fornecedor 4','4444-4444',4);
INSERT INTO fornecedor (forcnpj, fornome, forfone, forcidcodigo) VALUES ('55.555.555/5555-55','Fornecedor 5','5555-5555',3);

-- Tabela: grupoproduto
INSERT INTO grupoproduto (grpcodigo, grpdescricao, grpcomissao, grpativo) VALUES (1,'TELEFONIA E CELULAR',2.75,'');
INSERT INTO grupoproduto (grpcodigo, grpdescricao, grpcomissao, grpativo) VALUES (2,'FOTO',1.25,'');
INSERT INTO grupoproduto (grpcodigo, grpdescricao, grpcomissao, grpativo) VALUES (3,'ELETRO-ELETRONICOS',3.50,'');
INSERT INTO grupoproduto (grpcodigo, grpdescricao, grpcomissao, grpativo) VALUES (4,'INFORMATICA',3.75,'');
INSERT INTO grupoproduto (grpcodigo, grpdescricao, grpcomissao, grpativo) VALUES (5,'MOVEIS',4.25,'');
INSERT INTO grupoproduto (grpcodigo, grpdescricao, grpcomissao, grpativo) VALUES (6,'MEDICAMENTOS',2.75,'');

-- Tabela: produto
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (1,'Impressora deskjet HP 1150',800.00,1400.00,'1',4,10,'22.222.222/2222-22');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (2,'No Break 1kva',270.00,4500.00,'0',4,23,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (3,'Bebedouro Esmaltec',134.00,429.00,'1',3,7,'44.444.444/4444-44');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (4,'Fax Panasonic KX-FT908BGR',301.00,520.00,'0',1,9,'22.222.222/2222-22');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (5,'Tv 29" Toshiba',800.00,1076.00,'1',3,13,'33.333.333/3333-33');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (6,'Tv 20" SEMP',360.00,480.00,'1',3,17,'33.333.333/3333-33');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (7,'Monitor 15" LCD Samsung 540L',480.00,817.00,'1',4,3,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (8,'Sapateira com 4 gavetas',150.00,222.00,'1',5,6,'44.444.444/4444-44');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (9,'Notebook LG LS70',4500.00,6999.00,'0',4,21,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (10,'Aparelho DVD Sony DVP-NS45',230.00,470.00,'1',3,17,'22.222.222/2222-22');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (11,'Maquina Fotografica Panasonic',295.00,599.00,'1',2,12,'55.555.555/5555-55');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (12,'Maquina Fotografica Yashica CX400',453.00,745.00,'0',2,15,'55.555.555/5555-55');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (13,'Maquina Fotografica Philips Key008',370.00,691.00,'1',2,15,'55.555.555/5555-55');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (14,'Mini System Sony GNX100',1095.00,2196.00,'1',3,10,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (15,'Fogao 6B Eletrolux',870.00,1499.00,'1',3,15,'22.222.222/2222-22');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (16,'Geladeira Brastemp 330L',760.00,1599.00,'0',3,10,'44.444.444/4444-44');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (17,'Escrivaninha para Computador',134.00,259.00,'1',5,10,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (18,'Mesa de Centro 15 MG',87.00,164.00,'1',5,10,'44.444.444/4444-44');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (19,'Ar Condicionado 7500 Btus 110v',490.00,799.00,'1',3,10,'22.222.222/2222-22');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (20,'Forno Microondas Brastemp',340.00,789.00,'1',3,10,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (21,'Celular motorola v80',750.00,1200.00,'1',1,28,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (22,'Camera Digital Kodak KSX-1290',2000.00,4500.00,'1',2,15,'33.333.333/3333-33');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (23,'Maquina de Lavar Loucas LG',450.00,750.00,'1',3,10,'11.111.111/1111-11');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (24,'Palm Zire V',560.00,950.00,'1',4,27,'33.333.333/3333-33');
INSERT INTO produto (procodigo, pronome, procusto, propreco, proativo, progrpcodigo, prosaldo, proforcnpj) VALUES (25,'Poltrona com 2 lugares',375.00,890.00,'1',5,8,'11.111.111/1111-11');

-- Tabela: vendedor
INSERT INTO vendedor (vefuncodigo) VALUES (2);
INSERT INTO vendedor (vefuncodigo) VALUES (3);
INSERT INTO vendedor (vefuncodigo) VALUES (4);
INSERT INTO vendedor (vefuncodigo) VALUES (5);
INSERT INTO vendedor (vefuncodigo) VALUES (6);
INSERT INTO vendedor (vefuncodigo) VALUES (7);
INSERT INTO vendedor (vefuncodigo) VALUES (8);
INSERT INTO vendedor (vefuncodigo) VALUES (9);
INSERT INTO vendedor (vefuncodigo) VALUES (10);
INSERT INTO vendedor (vefuncodigo) VALUES (11);
INSERT INTO vendedor (vefuncodigo) VALUES (12);
INSERT INTO vendedor (vefuncodigo) VALUES (13);
INSERT INTO vendedor (vefuncodigo) VALUES (14);
INSERT INTO vendedor (vefuncodigo) VALUES (16);
INSERT INTO vendedor (vefuncodigo) VALUES (17);
INSERT INTO vendedor (vefuncodigo) VALUES (18);
INSERT INTO vendedor (vefuncodigo) VALUES (19);
INSERT INTO vendedor (vefuncodigo) VALUES (20);
INSERT INTO vendedor (vefuncodigo) VALUES (21);
INSERT INTO vendedor (vefuncodigo) VALUES (22);
INSERT INTO vendedor (vefuncodigo) VALUES (23);
INSERT INTO vendedor (vefuncodigo) VALUES (25);
INSERT INTO vendedor (vefuncodigo) VALUES (26);
INSERT INTO vendedor (vefuncodigo) VALUES (27);
INSERT INTO vendedor (vefuncodigo) VALUES (28);
INSERT INTO vendedor (vefuncodigo) VALUES (29);
INSERT INTO vendedor (vefuncodigo) VALUES (30);

-- Tabela: venda
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (1,'2024-01-02',1,10,9,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (2,'2024-01-02',2,1,2,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (3,'2024-01-02',3,30,3,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (4,'2024-01-02',2,5,3,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (5,'2024-01-02',3,6,4,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (6,'2024-01-02',2,2,8,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (7,'2024-01-02',3,8,9,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (8,'2024-01-02',2,2,6,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (9,'2024-01-02',2,90,2,1);
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo) VALUES (10,'2024-01-02',2,12,7,1);
-- ... (continua com todas as outras vendas)

-- Tabela: itemvenda
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (1,5,20);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (1,14,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (1,24,5);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (2,10,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (2,11,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (2,20,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (3,1,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (4,2,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (4,7,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (5,6,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (6,5,3);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (6,15,3);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (7,9,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (8,4,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (8,12,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (9,3,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (9,8,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (9,13,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (10,10,1);
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde) VALUES (10,12,1);