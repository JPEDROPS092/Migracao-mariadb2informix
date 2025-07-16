BEGIN TRANSACTION;

BEGIN TRY
   
    INSERT INTO dbo.venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo)
    VALUES (120, GETDATE(), 1, 600, 5, 1);

    
    INSERT INTO dbo.itemvenda (itvvencodigo, itvprocodigo, itvqtde)
    VALUES (124, 23, 2); 

    INSERT INTO dbo.itemvenda (itvvencodigo, itvprocodigo, itvqtde)
    VALUES (124, 22, 1); 

    
    COMMIT TRANSACTION;
    PRINT 'Venda 120 concluída e estoque atualizado pelo trigger com sucesso.';

END TRY
BEGIN CATCH
   
    ROLLBACK TRANSACTION;
    PRINT 'Erro na transação. Nenhuma alteração foi salva. Erro: ' + ERROR_MESSAGE();
END CATCH;



SELECT * FROM produto WHERE procodigo = 23;

SELECT * FROM produto WHERE procodigo = 22;

SELECT * FROM itemvenda WHERE itvvencodigo = 124;

