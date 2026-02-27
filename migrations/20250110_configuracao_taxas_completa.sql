-- Migração: Inserir configurações padrão de taxas por modalidade (ATUALIZADA)
-- Data: 2025-01-10
-- Descrição: Inclui todas as modalidades do sistema de conciliação bancária
-- Inserir configurações padrão de taxas por modalidade
INSERT INTO
     configuracao_taxas_modalidade (
          fk_id_modalidade_aula,
          pix_tipo,
          pix_valor,
          boleto_tipo,
          boleto_valor,
          ativo
     )
VALUES
     -- ID 1: Aula Particular (CA-AP)
     (
          1,
          'Percentual',
          85.00,
          'Percentual',
          90.00,
          TRUE
     ),
     -- ID 2: Aula em Grupo (CA-AG)  
     (
          2,
          'Percentual',
          80.00,
          'Percentual',
          85.00,
          TRUE
     ),
     -- ID 3: Pré-Prova (CA-PP)
     (
          3,
          'Percentual',
          75.00,
          'Percentual',
          80.00,
          TRUE
     ),
     -- ID 6: Contrato Mensal (CA-CT)
     (
          6,
          'Percentual',
          90.00,
          'Percentual',
          95.00,
          TRUE
     ),
     -- ID 7: Turma Vestibular (CA-TV)
     (
          7,
          'Percentual',
          90.00,
          'Percentual',
          95.00,
          TRUE
     ),
     -- ID 8: Turma Mentoria (CA-TM)
     (
          8,
          'Percentual',
          85.00,
          'Percentual',
          90.00,
          TRUE
     );

-- Verificar configurações inseridas com modalidades
SELECT
     ctm.id,
     ma.nome AS modalidade,
     CASE
          WHEN ma.nome = 'Aula Particular' THEN 'CA-AP'
          WHEN ma.nome = 'Aula em Grupo' THEN 'CA-AG'
          WHEN ma.nome = 'Pré-Prova' THEN 'CA-PP'
          WHEN ma.nome = 'Contrato' THEN 'CA-CT'
          WHEN ma.nome = 'Turma Vestibular' THEN 'CA-TV'
          WHEN ma.nome = 'Turma Mentoria' THEN 'CA-TM'
     END AS codigo_conciliacao,
     ctm.pix_tipo,
     ctm.pix_valor || '%' AS taxa_pix,
     ctm.boleto_tipo,
     ctm.boleto_valor || '%' AS taxa_boleto,
     ctm.ativo
FROM
     configuracao_taxas_modalidade ctm
     JOIN modalidade_aula ma ON ma.id = ctm.fk_id_modalidade_aula
WHERE
     ctm.ativo = TRUE
ORDER BY
     ctm.fk_id_modalidade_aula;