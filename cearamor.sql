-- 1Relatório com a quantidade de empréstimos nos últimos 12 meses, agrupados por mês,
-- mostrando quais os quantitativos de obras emprestadas, tipos de obra, valores pagos
-- em multas para cada tipo de obra.

SELECT 
    DATE_FORMAT(e.data_emprestimo, '%Y-%m') AS ano_mes,
    td.nome AS tipo_obra,
    COUNT(e.id) AS total_emprestimos,
    COUNT(DISTINCT e.id_obra) AS obras_distintas,
    COALESCE(SUM(m.valor_final), 0) AS valor_total_multas
FROM emprestimo e
JOIN obra o ON e.id_obra = o.id
JOIN tipodeobra td ON o.id_tipoDeObra = td.id
LEFT JOIN multas m ON e.id = m.id_emprestimo
WHERE e.data_emprestimo >= DATE_SUB("2025-03-16", INTERVAL 12 MONTH)
GROUP BY ano_mes, tipo_obra
ORDER BY ano_mes ASC, tipo_obra ASC;

-- 2Relatório com as estatísticas de uso por obra como média de empréstimos por mês,
-- média por semestre, popularidade de obras (ranking das mais emprestadas) e histórico
-- de multas.
SELECT 
    o.id AS id_obra,
    o.titulo,
    COUNT(e.id) AS total_emprestimos,
    
    ROUND(COUNT(e.id) / PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(MIN(e.data_emprestimo), '%Y%m')), 2) AS media_emp_mensal,
    
    ROUND(COUNT(e.id) / 
        (GREATEST(TIMESTAMPDIFF(MONTH, MIN(e.data_emprestimo), CURDATE()) / 6, 1)), 2
    ) AS media_emp_semestral,

    COALESCE(SUM(m.valor_final), 0) AS valor_total_multas

FROM obra o
LEFT JOIN emprestimo e ON o.id = e.id_obra
LEFT JOIN multas m ON m.id_emprestimo = e.id

GROUP BY o.id, o.titulo
ORDER BY total_emprestimos DESC;
------------------------------------------------------------------------------------------------------------------------------------------
-- versao com quantidade:
SELECT 
    o.id AS id_obra,
    o.titulo,
    COUNT(e.id) AS total_emprestimos,

    -- Média mensal de empréstimos desde o primeiro registro
    ROUND(COUNT(e.id) / PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(MIN(e.data_emprestimo), '%Y%m')), 2) AS media_emp_mensal,

    -- Média semestral
    ROUND(COUNT(e.id) / 
        (GREATEST(TIMESTAMPDIFF(MONTH, MIN(e.data_emprestimo), CURDATE()) / 6, 1)), 2
    ) AS media_emp_semestral,

    -- Valor total de multas
    COALESCE(SUM(m.valor_final), 0.00) AS valor_total_multas,

    -- Quantidade de multas associadas à obra
    COUNT(m.id_multa) AS qtd_multas

FROM obra o
LEFT JOIN emprestimo e ON o.id = e.id_obra
LEFT JOIN multas m ON m.id_emprestimo = e.id

GROUP BY o.id, o.titulo
ORDER BY total_emprestimos DESC;
-- Uma relação de todas as obras divididas por Área do Conhecimento (Banco de dados,
-- programação, saúde, psicologia etc), quantidade de volumes no acervo, quantidade de
-- volumes emprestados, quantidade de volumes em atraso, valores já pagos em multas
-- para cada obra

SELECT 
    o.id AS id_obra,
    o.titulo,
    c.nome_categoria AS area_conhecimento,
    o.qntd_disponivel AS volumes_no_acervo,

    -- Quantidade de volumes emprestados
    (SELECT COUNT(*) FROM emprestimo e2 WHERE e2.id_obra = o.id) AS volumes_emprestados,

    -- Quantidade de volumes em atraso
    (SELECT COUNT(*) 
     FROM emprestimo e3 
     WHERE e3.id_obra = o.id 
       AND e3.data_devolucao > e3.data_prev_devolucao) AS volumes_em_atraso,

    -- Valor total de multas já pagas para esta obra
    COALESCE((
        SELECT SUM(m.valor_final)
        FROM emprestimo e4
        JOIN multas m ON m.id_emprestimo = e4.id
        WHERE e4.id_obra = o.id
    ), 0.00) AS valor_total_multas_pagas

FROM obra o
JOIN categoria c ON o.id_categoria = c.id
ORDER BY area_conhecimento, o.titulo;

-- relatorio 4
SELECT
    u.nome AS nome_usuario,
    u.telefone AS celular,
    o.titulo AS titulo_obra,
    t.nome AS tipo_obra,
    
    DATEDIFF(CURDATE(), e.data_prev_devolucao) AS dias_em_atraso,
    
    ROUND(DATEDIFF(CURDATE(), e.data_prev_devolucao) * 1.50, 2) AS multa_estimativa

FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id
JOIN obra o ON e.id_obra = o.id
JOIN tipodeobra t ON o.id_tipoDeObra = t.id

WHERE e.data_devolucao IS NULL
  AND CURDATE() > e.data_prev_devolucao

ORDER BY dias_em_atraso DESC;
