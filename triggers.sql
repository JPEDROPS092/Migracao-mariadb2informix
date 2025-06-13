
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
AFTER INSERT ON itemvenda
REFERENCING NEW AS new_row
FOR EACH ROW
(
    UPDATE produto
    SET prosaldo = prosaldo - new_row.itvqtde
    WHERE procodigo = new_row.itvprocodigo;
);