CREATE VIEW vw_cliente_bai_estcivil (
    clicodigo,
    clinome,
    clisexo,
    bainome,
    estdescricao,
    baizoncodigo,
    clidtcadastro
) AS
SELECT
    c.clicodigo,
    c.clinome,
    c.clisexo,
    b.bainome,
    e.estdescricao,
    b.baizoncodigo,
    c.clidtcadastro
FROM cliente c, bairro b, estadocivil e
WHERE c.clibaicodigo = b.baicodigo AND c.cliestcodigo = e.estcodigo;