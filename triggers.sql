select procodigo, pronome, prosaldo from produto where procodigo = 1;

insert into itemvenda (itvvencodigo, itvprocodigo, itvqtde) values (200, 2, 4);


CREATE TRIGGER trg_itemvenda
INSERT ON itemvenda
REFERENCING NEW AS n
FOR EACH ROW (
UPDATE produto
SET prosaldo = prosaldo - n.itvqtde
WHERE procodigo = n.itvprocodigo
);