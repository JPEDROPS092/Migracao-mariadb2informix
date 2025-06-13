drop procedure sp_tabelas_relacionadas;

delimiter $$
create procedure sp_tabelas_relacionadas (p_bd varchar(255), p_table varchar(255))
begin
	select constraint_schema as 'banco', referenced_table_name as 'tabela', column_name as 'campo',
	table_name as 'relacionamento', referenced_column_name as 'campo relacionamento'
	from information_schema.key_column_usage
	where constraint_schema = p_bd and referenced_table_name = p_table

	union

	select constraint_schema as 'banco', table_name as 'tabela', column_name as 'campo',
	referenced_table_name as 'relacionamento', referenced_column_name as 'campo relacionamento'
	from information_schema.key_column_usage
	where constraint_schema = p_bd and table_name = p_table;
end $$
delimiter ;

call sp_tabelas_relacionadas('bd2025', 'cliente');









SELECT stp.tabname AS lado1, str.tabname AS ladoN FROM systables str
JOIN sysconstraints sc ON str.tabid = sc.tabid
JOIN sysreferences sr ON sc.constrid = sr.constrid
JOIN systables stp on sr.ptabid = stp.tabid
WHERE stp.tabname = 'cliente'

UNION

SELECT stp.tabname AS lado1, str.tabname AS ladoN
FROM systables str
JOIN sysconstraints sc ON str.tabid = sc.tabid
JOIN sysreferences sr ON sc.constrid = sr.constrid
JOIN systables stp on sr.ptabid = stp.tabid
WHERE str.tabname = 'cliente';













CREATE PROCEDURE listar_relacionamentos(p_tabname VARCHAR(50))
RETURNING VARCHAR(50), VARCHAR(50);
DEFINE lado1 VARCHAR(50);
DEFINE ladoN VARCHAR(50);

FOREACH
    SELECT stp.tabname, str.tabname
    INTO lado1, ladoN
    FROM systables str
    JOIN sysconstraints sc ON str.tabid = sc.tabid
    JOIN sysreferences sr ON sc.constrid = sr.constrid
    JOIN systables stp ON sr.ptabid = stp.tabid
    WHERE stp.tabname = p_tabname

    UNION

    SELECT stp.tabname, str.tabname
    FROM systables str
    JOIN sysconstraints sc ON str.tabid = sc.tabid
    JOIN sysreferences sr ON sc.constrid = sr.constrid
    JOIN systables stp ON sr.ptabid = stp.tabid
    WHERE str.tabname = p_tabname

RETURN lado1, ladoN WITH RESUME;
END FOREACH;

END PROCEDURE;