BEGIN WORK;

INSERT INTO venda (vencodigo, vendata, venfilcodigo, venclicodigo, venfuncodigo, venfpcodigo)
VALUES (3, TODAY, 1, 10, 25, 1);

INSERT INTO itemvenda (itvvencodigo, itvprocodigo, itvqtde)
VALUES (203, 123, 2);

UPDATE produto
SET prosaldo = prosaldo - 2
WHERE procodigo = 123;

COMMIT WORK;



