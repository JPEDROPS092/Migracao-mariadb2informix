---
marp: true
theme: default
paginate: true
---

# Criação de triggers, utilização do catálogo e comandos para controle de transações.

### Matheus Víctor  
### Alysson Gabriel  
### Rian Rodrigues  
### João Pedro
 


---

# 1. Triggers

## **1.1 Ajuste da quantidade de moradores de bairros, a partir da atualização do bairro de clientes**


---
   

## **1.2 Trigger para atualizar a quantidade de saldo do produto, ao realizar uma venda deste produto**

---

# 2. Catálogo

## **2.1 Diagramas**


---
   

## **2.2 Procedure - relacionamento entre tabelas**


---


# 3. Transações

## **3.1 Trasações no informix**


---
   







### **1 - TRIGGERS**

No Informix, os triggers são criados com uma sintaxe um pouco diferente, geralmente definindo a lógica diretamente no corpo do trigger, sem a necessidade de uma função separada.

#### **1.1 - Ajuste da quantidade de moradores de bairros**

Criaremos três triggers separados, um para cada evento (`INSERT`, `DELETE`, `UPDATE`), para manter a clareza e a eficiência.

**Trigger para INSERT**
Quando um novo cliente é cadastrado, incrementa a contagem de pessoas no bairro correspondente.

```sql
-- Trigger para INSERT na tabela cliente
CREATE TRIGGER trg_cliente_after_insert
    INSERT ON cliente
    REFERENCING NEW AS n
    FOR EACH ROW (
        UPDATE bairro
        SET baiqtdepessoas = baiqtdepessoas + 1
        WHERE baicodigo = n.clibaicodigo
    );
```

**Trigger para DELETE**
Quando um cliente é removido, decrementa a contagem de pessoas do seu bairro.

```sql
-- Trigger para DELETE na tabela cliente
CREATE TRIGGER trg_cliente_after_delete
    DELETE ON cliente
    REFERENCING OLD AS o
    FOR EACH ROW (
        UPDATE bairro
        SET baiqtdepessoas = baiqtdepessoas - 1
        WHERE baicodigo = o.clibaicodigo
    );
```

**Trigger para UPDATE**
Quando o bairro de um cliente é alterado (`clibaicodigo`), decrementa a contagem do bairro antigo e incrementa a do novo.

![alt text](triggerinsert.png)

---

#### **1.2 - Trigger para atualizar o saldo do produto**

Este trigger será acionado após a inserção de um novo registro em `itemvenda` para subtrair a quantidade vendida do saldo do produto.

![alt text](triggerupdate.png)
---







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




