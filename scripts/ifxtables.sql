CREATE TABLE atualizacao (
    atid SERIAL NOT NULL,
    attabela VARCHAR(255),
    atcoluna VARCHAR(255),
    atvalor VARCHAR(255),
    atcondicao VARCHAR(255),
    PRIMARY KEY (atid)
);

-- Tabela: cidade
CREATE TABLE cidade (
    cidcodigo INTEGER NOT NULL,
    cidnome VARCHAR(80) NOT NULL,
    PRIMARY KEY (cidcodigo)
);

-- Tabela: zona
CREATE TABLE zona (
    zoncodigo INTEGER NOT NULL,
    zonnome VARCHAR(15) NOT NULL,
    zoncidcodigo INTEGER NOT NULL,
    PRIMARY KEY (zoncodigo)
);

-- Tabela: bairro
CREATE TABLE bairro (
    baicodigo INTEGER NOT NULL,
    bainome VARCHAR(30) NOT NULL,
    baizoncodigo INTEGER NOT NULL,
    baiqtdepessoas INTEGER NOT NULL, -- Informix não tem UNSIGNED, INTEGER é suficiente
    PRIMARY KEY (baicodigo)
);

-- Tabela: estadocivil
CREATE TABLE estadocivil (
    estcodigo INTEGER NOT NULL,
    estdescricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (estcodigo)
);

-- Tabela: cliente
CREATE TABLE cliente (
    clicodigo SERIAL NOT NULL,
    clisexo CHAR(1) NOT NULL,
    clirendamensal DECIMAL(8,2) NOT NULL, -- Aumentei a precisão para 8,2 para acomodar a soma
    clinome VARCHAR(60) NOT NULL,
    clibaicodigo INTEGER NOT NULL,
    clifone VARCHAR(10) NOT NULL,
    cliestcodigo INTEGER NOT NULL,
    clidtcadastro DATE,
    clidtdesativacao DATE,
    PRIMARY KEY (clicodigo)
);

-- Tabela: funcionario
CREATE TABLE funcionario (
    funcodigo INTEGER NOT NULL,
    funnome VARCHAR(50) NOT NULL,
    funsalario DECIMAL(8,2) NOT NULL,
    funbaicodigo INTEGER NOT NULL,
    funcodgerente INTEGER,
    fundtdem DATE,
    funestcodigo INTEGER NOT NULL,
    funsenha VARCHAR(20),
    funlogin VARCHAR(30),
    fundtnascto DATE,
    PRIMARY KEY (funcodigo)
);

-- Tabela: filial
CREATE TABLE filial (
    filcodigo INTEGER NOT NULL,
    filnome VARCHAR(40) NOT NULL,
    filcodgerente INTEGER NOT NULL,
    filbaicodigo INTEGER NOT NULL,
    PRIMARY KEY (filcodigo)
);

-- Tabela: formapagamento
CREATE TABLE formapagamento (
    fpcodigo SMALLINT NOT NULL,
    fpdescricao VARCHAR(60) NOT NULL,
    fpativo BOOLEAN NOT NULL, -- TINYINT(1) mapeado para BOOLEAN ('t'/'f')
    PRIMARY KEY (fpcodigo)
);

-- Tabela: fornecedor
CREATE TABLE fornecedor (
    forcnpj CHAR(18) NOT NULL,
    fornome VARCHAR(100) NOT NULL,
    forfone CHAR(9) NOT NULL,
    forcidcodigo INTEGER NOT NULL,
    PRIMARY KEY (forcnpj)
);

-- Tabela: fornecedorfone
CREATE TABLE fornecedorfone (
    ffforcnpj CHAR(18) NOT NULL,
    fffone CHAR(9) NOT NULL,
    PRIMARY KEY (ffforcnpj, fffone)
);

-- Tabela: grupoproduto
CREATE TABLE grupoproduto (
    grpcodigo INTEGER NOT NULL,
    grpdescricao VARCHAR(40) NOT NULL,
    grpcomissao DECIMAL(4,2) NOT NULL,
    grpativo CHAR(1) NOT NULL,
    PRIMARY KEY (grpcodigo)
);

-- Tabela: produto
CREATE TABLE produto (
    procodigo INTEGER NOT NULL,
    pronome VARCHAR(80) NOT NULL,
    procusto DECIMAL(9,2) NOT NULL,
    propreco DECIMAL(9,2) NOT NULL,
    proativo CHAR(1) NOT NULL,
    progrpcodigo INTEGER NOT NULL,
    prosaldo INTEGER NOT NULL,
    proforcnpj CHAR(18) NOT NULL,
    PRIMARY KEY (procodigo)
);

-- Tabela: vendedor
CREATE TABLE vendedor (
    vefuncodigo INTEGER NOT NULL,
    PRIMARY KEY (vefuncodigo)
);

-- Tabela: venda
CREATE TABLE venda (
    vencodigo INTEGER NOT NULL,
    vendata DATE NOT NULL,
    venfilcodigo INTEGER NOT NULL,
    venclicodigo INTEGER NOT NULL,
    venfuncodigo INTEGER NOT NULL,
    venfpcodigo SMALLINT,
    PRIMARY KEY (vencodigo)
);

-- Tabela: itemvenda
CREATE TABLE itemvenda (
    itvvencodigo INTEGER NOT NULL,
    itvprocodigo INTEGER NOT NULL,
    itvqtde INTEGER NOT NULL,
    PRIMARY KEY (itvvencodigo, itvprocodigo)
);