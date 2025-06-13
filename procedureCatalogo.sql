--Maria
create procedure sp_tabelas_relacionadas (p_bd varchar(255), p_table varchar(255))
begin
	select constraint_schema as 'banco', referenced_table_name as 'tabela', table_name as 'relacionamento',  -- consulta o relacionamento em que a tabela está como chave estrangeira
    referenced_column_name as 'lado 1', column_name as 'lado n'
	from information_schema.key_column_usage
	where constraint_schema = p_bd and referenced_table_name = p_table

	union

	select constraint_schema as 'banco', table_name as 'tabela',referenced_table_name as 'relacionamento', -- consulta o relacionamento em que outras tabelas estão como chave estrangeira
    referenced_column_name as 'lado 1', column_name as 'lado n'
	from information_schema.key_column_usage
	where constraint_schema = p_bd and table_name = p_table;
end $$
delimiter ;








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