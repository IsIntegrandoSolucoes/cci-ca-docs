-- ============================================================================
-- Migration: Corrigir view_receita_analitico para calcular receita líquida do professor
-- Data: 2025-01-15
-- Descrição: 
--   - Problema: View mostra valor BRUTO do pagamento, mas professor recebe apenas
--     sua parte do split (geralmente 75-90%)
--   - Solução: JOIN com configuracao_recebedores para buscar percentual do professor
--     e calcular sua receita líquida considerando splits
--   - Reportado por: Professor informou diferença de R$ 398 entre relatório e depósito
-- ============================================================================

-- 1. Dropar view antiga
DROP VIEW IF EXISTS view_receita_analitico CASCADE;

-- 2. Criar view corrigida com cálculo de splits
CREATE OR REPLACE VIEW view_receita_analitico AS
WITH modalidade_splits AS (
    -- Buscar percentual do professor para cada modalidade
    SELECT 
        ma.id AS id_modalidade,
        ma.nome AS nome_modalidade,
        cr.percentual AS percentual_professor,
        cr.identificador_recebedor
    FROM configuracao_taxas_modalidade ctm
    INNER JOIN modalidade_aula ma ON ma.id = ctm.fk_id_modalidade_aula
    INNER JOIN configuracao_recebedores cr ON cr.fk_id_configuracao_modalidade = ctm.id
    WHERE cr.tipo_recebedor = 'Participante'
      AND cr.ativo = true
      AND ctm.ativo = true
      AND ctm.deleted_at IS NULL
      AND cr.deleted_at IS NULL
)
SELECT 
    a.fk_id_pessoa,
    c.nome,
    a.fk_id_turma,
    d.descricao AS nome_turma,
    d.fk_id_disciplina,
    e.nome AS nome_disciplina,
    d.modalidade AS modalidade_turma,
    a.data_pagamento,
    a.parcela,
    
    -- Valor BRUTO pago pelo aluno
    a.valor_pago AS valor_bruto_aluno,
    
    -- Percentual que o professor recebe (baseado no texto de modalidade da turma)
    COALESCE(ms.percentual_professor, 100) AS percentual_professor,
    
    -- Valor LÍQUIDO que o professor recebe
    CASE 
        WHEN ms.percentual_professor IS NOT NULL THEN
            ROUND((a.valor_pago * ms.percentual_professor / 100.0)::numeric, 2)
        ELSE
            a.valor_pago
    END AS valor_liquido_professor,
    
    -- Descontos
    a.desconto_vencimento,
    
    -- Informações do pagamento
    b.valor_multa_pagamento,
    b.valor_juros_pagamento,
    b.valor_tarifa_recebedor,
    b.codigo_conciliacao_solicitacao
    
FROM contrato_ano_pessoa a
LEFT JOIN pagamentos b ON b.codigo_conciliacao_solicitacao::text ~~ (('CA-CT-'::text || a.id) || '-%'::text)
INNER JOIN pessoas c ON a.fk_id_pessoa = c.id
INNER JOIN turmas d ON a.fk_id_turma = d.id
INNER JOIN disciplinas e ON d.fk_id_disciplina = e.id
-- JOIN com modalidade_splits usando LOWER para match flexível (Online = online)
LEFT JOIN modalidade_splits ms ON LOWER(TRIM(d.modalidade)) = LOWER(TRIM(ms.nome_modalidade))

WHERE a.data_pagamento IS NOT NULL
  AND a.deleted_at IS NULL;

-- 3. Adicionar comentário na view
COMMENT ON VIEW view_receita_analitico IS 
'View corrigida para exibir receita LÍQUIDA do professor considerando splits configurados.
- valor_bruto_aluno: Valor total pago pelo aluno
- percentual_professor: Percentual que o professor recebe (75-90% tipicamente)
- valor_liquido_professor: Valor efetivo que o professor recebe após split com convênio
- Correção aplicada em 2025-01-15 para resolver discrepância de R$ 398 reportada';

-- 4. Conceder permissões (ajustar conforme necessário)
GRANT SELECT ON view_receita_analitico TO authenticated;

-- ============================================================================
-- Verificações pós-migration
-- ============================================================================

-- Consulta de teste: Verificar se splits estão sendo calculados
SELECT 
    nome,
    nome_turma,
    modalidade,
    valor_bruto_aluno,
    percentual_professor,
    valor_liquido_professor,
    (valor_bruto_aluno - valor_liquido_professor) AS diferenca_convenio
FROM view_receita_analitico
WHERE data_pagamento >= '2024-01-01'
LIMIT 5;

-- Consulta de validação: Somar receita líquida por professor
SELECT 
    fk_id_pessoa,
    nome,
    COUNT(*) AS total_pagamentos,
    SUM(valor_bruto_aluno) AS total_bruto,
    SUM(valor_liquido_professor) AS total_liquido_professor,
    SUM(valor_bruto_aluno - valor_liquido_professor) AS total_repassado_convenio
FROM view_receita_analitico
WHERE data_pagamento >= '2024-01-01'
GROUP BY fk_id_pessoa, nome
ORDER BY total_liquido_professor DESC;
