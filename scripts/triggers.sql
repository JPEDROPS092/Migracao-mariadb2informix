CREATE TRIGGER tg_atualizar_bairro_cliente
AFTER UPDATE OF clibaicodigo ON cliente
REFERENCING OLD AS old NEW AS new
FOR EACH ROW
WHEN (new.clibaicodigo != old.clibaicodigo)
(
    UPDATE bairro
    SET baiqtdepessoas = baiqtdepessoas + 1
    WHERE baicodigo = new.clibaicodigo;

    UPDATE bairro
    SET baiqtdepessoas = baiqtdepessoas - 1
    WHERE baicodigo = old.clibaicodigo;
);





CREATE TRIGGER tg_atualiza_saldo_produto
INSERT ON itemvenda
REFERENCING NEW AS n
FOR EACH ROW
(
    UPDATE produto
    SET prosaldo = prosaldo - n.itvqtde
    WHERE procodigo = n.itvprocodigo
);