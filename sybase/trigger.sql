use abd2030;


CREATE TRIGGER trg_atualiza_saldo_produto
ON abd2030.dbo.itemvenda
FOR INSERT AS
BEGIN
	SET NOCOUNT ON
    UPDATE produto
    SET prosaldo = produto.prosaldo - inserted.itvqtde
    FROM produto, inserted
    WHERE produto.procodigo = inserted.itvprocodigo
END
   

SELECT * FROM produto where procodigo = 4;

SELECT * FROM itemvenda where itvvencodigo = 120;
SELECT * FROM venda;


INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde)
VALUES (120, 4, 2);
