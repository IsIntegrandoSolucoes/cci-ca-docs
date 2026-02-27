-- Migração: Adicionar modalidades de aula faltantes
-- Data: 2025-01-10
-- Descrição: Inclui Turmas Vestibular e Turmas Mentoria para completar sistema de conciliação
-- Inserir modalidades faltantes
INSERT INTO
     modalidade_aula (nome, descricao, tipo_pagamento, ativo)
VALUES
     (
          'Turma Vestibular',
          'Curso preparatório para vestibular com aulas em turma',
          'mensalidade',
          TRUE
     ),
     (
          'Turma Mentoria',
          'Programa de mentoria acadêmica com aulas especializadas',
          'mensalidade',
          TRUE
     );

-- Verificar modalidades inseridas
SELECT
     id,
     nome,
     descricao,
     tipo_pagamento,
     ativo,
     created_at
FROM
     modalidade_aula
WHERE
     nome IN ('Turma Vestibular', 'Turma Mentoria')
ORDER BY
     id;

-- Verificar todas as modalidades para mapeamento
SELECT
     id,
     nome,
     CASE
          WHEN nome = 'Aula Particular' THEN 'CA-AP'
          WHEN nome = 'Aula em Grupo' THEN 'CA-AG'
          WHEN nome = 'Pré-Prova' THEN 'CA-PP'
          WHEN nome = 'Contrato' THEN 'CA-CT'
          WHEN nome = 'Turma Vestibular' THEN 'CA-TV'
          WHEN nome = 'Turma Mentoria' THEN 'CA-TM'
          ELSE 'N/A'
     END AS codigo_conciliacao
FROM
     modalidade_aula
WHERE
     ativo = TRUE
ORDER BY
     id;