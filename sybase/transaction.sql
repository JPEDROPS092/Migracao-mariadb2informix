BEGIN TRANSACTION

-- Primeira inserção na tabela venda
INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo)
VALUES (120, GETDATE(), 1, 600, 5, 1);

-- Verifica erro
IF @@error != 0
BEGIN
    ROLLBACK TRANSACTION
    PRINT "Erro ao inserir na tabela venda."
    RETURN
END

-- Primeira inserção na tabela itemvenda
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde)
VALUES (124, 23, 2);

-- Verifica erro
IF @@error != 0
BEGIN
    ROLLBACK TRANSACTION
    PRINT "Erro ao inserir primeiro item de venda."
    RETURN
END

-- Segunda inserção na tabela itemvenda
INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde)
VALUES (124, 22, 1);

-- Verifica erro
IF @@error != 0
BEGIN
    ROLLBACK TRANSACTION
    PRINT "Erro ao inserir segundo item de venda."
    RETURN
END

-- Tudo certo? Commit.
COMMIT TRANSACTION
PRINT "Venda 120 concluída e estoque atualizado pelo trigger com sucesso."
