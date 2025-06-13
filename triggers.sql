DROP TRIGGER tg_atualizar_bairro_cliente;

DELIMITER $$

CREATE TRIGGER tg_atualizar_bairro_cliente AFTER UPDATE ON cliente
FOR EACH ROW
	BEGIN
		IF NEW.clibaicodigo <> OLD.clibaicodigo THEN
			UPDATE bairro SET baiqtdepessoas = baiqtdepessoas + 1
			WHERE baicodigo = NEW.clibaicodigo;
			
			UPDATE bairro SET baiqtdepessoas = baiqtdepessoas - 1
			WHERE baicodigo = OLD.clibaicodigo;
		END IF;
	END$$

DELIMITER ;





      
-- Primeiro, o comando para remover o trigger, caso ele já exista.
-- A sintaxe é a mesma, mas é bom garantir.
DROP TRIGGER tg_atualizar_bairro_cliente;

-- Criação do trigger com a sintaxe do Informix
CREATE TRIGGER tg_atualizar_bairro_cliente
    ON cliente -- A tabela onde o trigger será disparado
    FOR UPDATE -- O evento que dispara o trigger (UPDATE)
    REFERENCING NEW AS new OLD AS old -- Define como vamos nos referir aos valores novos e antigos
    ( -- O corpo do trigger no Informix começa com parênteses

        -- A lógica IF...THEN...END IF é a mesma do MariaDB
        IF new.clibaicodigo <> old.clibaicodigo THEN
        
            -- Ação 1: Incrementa o contador de pessoas no NOVO bairro do cliente
            UPDATE bairro 
            SET baiqtdepessoas = baiqtdepessoas + 1
            WHERE baicodigo = new.clibaicodigo;
            
            -- Ação 2: Decrementa o contador de pessoas no ANTIGO bairro do cliente
            UPDATE bairro 
            SET baiqtdepessoas = baiqtdepessoas - 1
            WHERE baicodigo = old.clibaicodigo;
            
        END IF;
    ); -- O corpo do trigger termina com parênteses e um ponto e vírgula

    







--------------------------------------------------------------------------------------------------







DESC produto;

DROP TRIGGER tg_atualiza_saldo_produto;

DELIMITER $$

CREATE TRIGGER tg_atualiza_saldo_produto AFTER INSERT ON itemvenda
FOR EACH ROW
	BEGIN
		UPDATE produto
        SET prosaldo = prosaldo - new.itvqtde
        WHERE procodigo = NEW.itvprocodigo;
    END $$

DELIMITER ;










      
-- Comando para remover o trigger se ele já existir.
DROP TRIGGER tg_atualiza_saldo_produto;

-- Criação do trigger com a sintaxe do Informix.
CREATE TRIGGER tg_atualiza_saldo_produto
    ON itemvenda -- Tabela onde o trigger será disparado
    FOR INSERT   -- Evento que dispara o trigger (INSERT)
    REFERENCING NEW AS new -- Define o alias para o novo registro
    ( -- Início do corpo do trigger

        -- Ação: Atualiza a tabela 'produto' para subtrair a quantidade vendida do saldo.
        UPDATE produto
        SET prosaldo = prosaldo - new.itvqtde
        WHERE procodigo = new.itvprocodigo;
        
    ); -- Fim do corpo do trigger

    


