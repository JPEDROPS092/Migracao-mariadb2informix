DROP TRIGGER TRG_AtualizaSaldoProduto_AposVenda;

CREATE TRIGGER TRG_AtualizaSaldoProduto_AposVenda
ON [dbo].[itemvenda]
AFTER INSERT
AS
BEGIN
    
    SET NOCOUNT ON;


  
    WITH VendasAgrupadas AS (
        SELECT
            itvprocodigo,
            SUM(itvqtde) AS TotalVendido
        FROM
            inserted 
        GROUP BY
            itvprocodigo
    )
    
    UPDATE p
    SET
        p.prosaldo = p.prosaldo - va.TotalVendido
    FROM
        dbo.produto AS p
    INNER JOIN
        VendasAgrupadas AS va ON p.procodigo = va.itvprocodigo;

END




SELECT * FROM produto WHERE procodigo = 2;

SELECT * FROM itemvenda WHERE itvvencodigo = 123;

INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde)
VALUES (123, 2, 5);








