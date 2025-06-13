-- Scripts de teste para Informix Database
-- Execute estes comandos para testar a conectividade e funcionalidade

-- 1. Verificar versão do servidor
SELECT DBINFO('version', 'full') AS server_version FROM sysmaster:sysdual;

-- 2. Verificar data/hora atual
SELECT CURRENT YEAR TO SECOND AS current_datetime FROM sysmaster:sysdual;

-- 3. Verificar usuário atual
SELECT USER AS current_user FROM sysmaster:sysdual;

-- 4. Listar databases disponíveis
SELECT name, is_logging, is_buff_log, is_ansi, owner 
FROM sysdatabases 
ORDER BY name;

-- 5. Criar database de teste (se não existir)
-- CREATE DATABASE test_migration WITH LOG;

-- 6. Usar database de teste
-- DATABASE test_migration;

-- 7. Criar tabela de exemplo
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    created_at DATETIME YEAR TO SECOND DEFAULT CURRENT YEAR TO SECOND
);

-- 8. Inserir dados de exemplo
INSERT INTO employees (name, email, department, salary, hire_date) VALUES
    ('João Silva', 'joao.silva@empresa.com', 'TI', 5500.00, '2023-01-15'),
    ('Maria Santos', 'maria.santos@empresa.com', 'RH', 4800.00, '2023-02-20'),
    ('Pedro Oliveira', 'pedro.oliveira@empresa.com', 'Vendas', 6200.00, '2023-03-10'),
    ('Ana Costa', 'ana.costa@empresa.com', 'TI', 5800.00, '2023-04-05'),
    ('Carlos Ferreira', 'carlos.ferreira@empresa.com', 'Financeiro', 5200.00, '2023-05-12');

-- 9. Consultar dados inseridos
SELECT * FROM employees ORDER BY hire_date;

-- 10. Consultas com agregação
SELECT 
    department,
    COUNT(*) as total_employees,
    AVG(salary) as avg_salary,
    MAX(salary) as max_salary,
    MIN(salary) as min_salary
FROM employees 
GROUP BY department
ORDER BY avg_salary DESC;

-- 11. Consulta com JOIN (criar tabela relacionada)
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    manager_name VARCHAR(100),
    budget DECIMAL(12,2)
);

INSERT INTO departments (dept_name, manager_name, budget) VALUES
    ('TI', 'Roberto Tech', 150000.00),
    ('RH', 'Lucia People', 80000.00),
    ('Vendas', 'Antonio Sales', 200000.00),
    ('Financeiro', 'Sandra Money', 120000.00);

-- 12. JOIN entre tabelas
SELECT 
    e.name as employee_name,
    e.department,
    d.manager_name,
    d.budget as dept_budget,
    e.salary
FROM employees e
LEFT JOIN departments d ON e.department = d.dept_name
ORDER BY e.department, e.name;

-- 13. Verificar estrutura das tabelas
SELECT 
    tabname,
    colname,
    coltype,
    collength,
    colno
FROM syscolumns 
WHERE tabid IN (
    SELECT tabid FROM systables 
    WHERE tabname IN ('employees', 'departments')
    AND tabtype = 'T'
)
ORDER BY tabname, colno;

-- 14. Verificar índices
SELECT 
    i.idxname,
    t.tabname,
    i.idxtype,
    i.clustered,
    i.part1,
    i.part2
FROM sysindices i
JOIN systables t ON i.tabid = t.tabid
WHERE t.tabname IN ('employees', 'departments')
ORDER BY t.tabname, i.idxname;

-- 15. Verificar constraints
SELECT 
    t.tabname,
    c.constrname,
    c.constrtype,
    c.idxname
FROM sysconstraints c
JOIN systables t ON c.tabid = t.tabid
WHERE t.tabname IN ('employees', 'departments')
ORDER BY t.tabname, c.constrname;

-- 16. Teste de transação
BEGIN WORK;
    UPDATE employees SET salary = salary * 1.05 WHERE department = 'TI';
    SELECT name, salary FROM employees WHERE department = 'TI';
ROLLBACK WORK;

-- Verificar se o rollback funcionou
SELECT name, salary FROM employees WHERE department = 'TI';

-- 17. Criar procedure simples
CREATE PROCEDURE get_employee_count(dept_name VARCHAR(50))
    RETURNING INT;
    
    DEFINE count_emp INT;
    
    SELECT COUNT(*) INTO count_emp 
    FROM employees 
    WHERE department = dept_name;
    
    RETURN count_emp;
    
END PROCEDURE;

-- Executar procedure
EXECUTE PROCEDURE get_employee_count('TI');

-- 18. Criar view
CREATE VIEW employee_summary AS
SELECT 
    department,
    COUNT(*) as total_employees,
    AVG(salary) as avg_salary,
    SUM(salary) as total_payroll
FROM employees
GROUP BY department;

-- Consultar view
SELECT * FROM employee_summary ORDER BY total_payroll DESC;

-- 19. Teste de performance com dados em massa
CREATE TEMP TABLE temp_data (
    id SERIAL,
    random_number INT,
    random_text VARCHAR(50),
    created_at DATETIME YEAR TO SECOND DEFAULT CURRENT YEAR TO SECOND
);

-- Inserir dados em lote
INSERT INTO temp_data (random_number, random_text)
SELECT 
    MOD(ROWID, 1000) as random_number,
    'Test_Data_' || ROWID as random_text
FROM sysmaster:sysdual
WHERE ROWID <= 10000;

-- Consultar dados temporários
SELECT COUNT(*) as total_records FROM temp_data;
SELECT * FROM temp_data WHERE random_number < 10 ORDER BY id LIMIT 5;

-- 20. Limpeza (descomente se quiser limpar as tabelas de teste)
-- DROP VIEW IF EXISTS employee_summary;
-- DROP PROCEDURE IF EXISTS get_employee_count;
-- DROP TABLE IF EXISTS employees;
-- DROP TABLE IF EXISTS departments;
-- DROP TABLE IF EXISTS temp_data;