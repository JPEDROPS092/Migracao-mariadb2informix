
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