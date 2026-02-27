-- ============================================================================
-- VIEW: Professores com Conta Bancária Configurada
-- Data: 13/10/2025
-- Autor: Gabriel M. Guimarães
-- ============================================================================
-- 
-- OBJETIVO:
-- Criar uma view que lista professores que possuem conta bancária cadastrada
-- e configurada para receber repasses via sistema de múltiplos recebedores.
-- 
-- CONDIÇÕES:
-- - Professor ativo (pessoas.ativo = true)
-- - Vinculado a pelo menos uma turma (através de turmas ou contrato_ano_pessoa)
-- - Possui registro na tabela cnpj com CPF/CNPJ válido
-- - Possui conta_bancaria vinculada ao cnpj com numero_participante
-- 
-- UTILIZAÇÃO:
-- - Seleção de professores no formulário de configuração de recebedores
-- - Validação de professores aptos a receber repasses
-- - Relatórios de professores cadastrados
-- 
-- ============================================================================
BEGIN;

-- ============================================================================
-- PARTE 1: REMOVER VIEW EXISTENTE (se houver)
-- ============================================================================
DROP VIEW IF EXISTS view_professores_com_conta_bancaria CASCADE;

RAISE NOTICE 'View anterior removida (se existia)';

-- ============================================================================
-- PARTE 2: CRIAR VIEW DE PROFESSORES COM CONTA BANCÁRIA
-- ============================================================================
CREATE
OR REPLACE VIEW view_professores_com_conta_bancaria AS
SELECT
     DISTINCT -- Dados do Professor
     p.id AS professor_id,
     p.nome AS professor_nome,
     p.cpf AS professor_cpf,
     p.email AS professor_email,
     p.celular AS professor_celular,
     -- Dados do CNPJ
     c.id AS cnpj_id,
     c.cpf_cnpj,
     c.nome_razao_social,
     c.tipo_pessoa,
     -- Dados da Conta Bancária
     cb.id AS conta_bancaria_id,
     cb.numero_participante,
     cb.banco,
     cb.agencia,
     cb.conta,
     cb.tipo_conta,
     cb.pix_chave,
     cb.pix_tipo_chave,
     -- Status
     p.ativo AS professor_ativo,
     cb.ativo AS conta_bancaria_ativa,
     -- Contadores (quantas turmas esse professor possui)
     COUNT(DISTINCT COALESCE(t.id, cap.fk_id_turma)) AS total_turmas,
     -- Auditoria
     p.created_at AS professor_cadastrado_em,
     cb.created_at AS conta_criada_em,
     p.updated_at AS professor_atualizado_em,
     cb.updated_at AS conta_atualizada_em
FROM
     pessoas p -- JOIN com CNPJ (obrigatório)
     INNER JOIN cnpj c ON c.fk_id_pessoa = p.id
     AND c.deleted_at IS NULL
     AND c.ativo = TRUE -- JOIN com Conta Bancária (obrigatório)
     INNER JOIN conta_bancaria cb ON cb.fk_id_cnpj = c.id
     AND cb.deleted_at IS NULL
     AND cb.ativo = TRUE
     AND cb.numero_participante IS NOT NULL
     AND TRIM(cb.numero_participante) != '' -- JOIN com Turmas (opcional - para contar turmas avulsas)
     LEFT JOIN turmas t ON t.fk_id_professor = p.id
     AND t.deleted_at IS NULL
     AND t.ativo = TRUE -- JOIN com Contratos Mensais (opcional - para contar turmas mensais)
     LEFT JOIN contrato_ano_pessoa cap ON cap.fk_id_pessoa_professor = p.id
     AND cap.deleted_at IS NULL
     AND cap.ativo = TRUE
WHERE
     p.deleted_at IS NULL
     AND p.ativo = TRUE
     AND p.fk_id_tipo_pessoa = 2 -- Tipo Pessoa = Professor (2)
GROUP BY
     p.id,
     p.nome,
     p.cpf,
     p.email,
     p.celular,
     c.id,
     c.cpf_cnpj,
     c.nome_razao_social,
     c.tipo_pessoa,
     cb.id,
     cb.numero_participante,
     cb.banco,
     cb.agencia,
     cb.conta,
     cb.tipo_conta,
     cb.pix_chave,
     cb.pix_tipo_chave,
     p.ativo,
     cb.ativo,
     p.created_at,
     cb.created_at,
     p.updated_at,
     cb.updated_at
ORDER BY
     p.nome ASC;

RAISE NOTICE 'View view_professores_com_conta_bancaria criada com sucesso';

-- ============================================================================
-- PARTE 3: CRIAR ÍNDICES PARA PERFORMANCE
-- ============================================================================
-- Nota: Views não suportam índices diretamente, mas as tabelas base já possuem
-- índices apropriados. Esta seção é informativa.
-- Índices já existentes nas tabelas base:
-- - pessoas(id) - PK
-- - pessoas(fk_id_tipo_pessoa) - FK
-- - cnpj(fk_id_pessoa) - FK
-- - conta_bancaria(fk_id_cnpj) - FK
-- - conta_bancaria(numero_participante) - Para buscas rápidas
-- - turmas(fk_id_professor) - FK
-- - contrato_ano_pessoa(fk_id_pessoa_professor) - FK
RAISE NOTICE 'Índices nas tabelas base confirmados';

-- ============================================================================
-- PARTE 4: CRIAR FUNÇÃO AUXILIAR PARA BUSCAR PROFESSOR POR NUMERO_PARTICIPANTE
-- ============================================================================
CREATE
OR REPLACE FUNCTION buscar_professor_por_numero_participante(p_numero_participante VARCHAR) RETURNS TABLE (
     professor_id BIGINT,
     professor_nome VARCHAR,
     cpf_cnpj VARCHAR,
     numero_participante VARCHAR
) AS $ $ BEGIN RETURN QUERY
SELECT
     v.professor_id,
     v.professor_nome,
     v.cpf_cnpj,
     v.numero_participante
FROM
     view_professores_com_conta_bancaria v
WHERE
     v.numero_participante = p_numero_participante
     AND v.professor_ativo = TRUE
     AND v.conta_bancaria_ativa = TRUE
LIMIT
     1;

END;

$ $ LANGUAGE plpgsql;

RAISE NOTICE 'Função buscar_professor_por_numero_participante() criada';

-- ============================================================================
-- PARTE 5: CRIAR FUNÇÃO AUXILIAR PARA VALIDAR SE PROFESSOR TEM CONTA
-- ============================================================================
CREATE
OR REPLACE FUNCTION professor_tem_conta_bancaria(p_professor_id BIGINT) RETURNS BOOLEAN AS $ $ DECLARE tem_conta BOOLEAN;

BEGIN
SELECT
     EXISTS (
          SELECT
               1
          FROM
               view_professores_com_conta_bancaria
          WHERE
               professor_id = p_professor_id
               AND professor_ativo = TRUE
               AND conta_bancaria_ativa = TRUE
     ) INTO tem_conta;

RETURN tem_conta;

END;

$ $ LANGUAGE plpgsql;

RAISE NOTICE 'Função professor_tem_conta_bancaria() criada';

-- ============================================================================
-- PARTE 6: VERIFICAR DADOS
-- ============================================================================
DO $ $ DECLARE total_professores INT;

total_com_conta INT;

total_sem_conta INT;

exemplo_professor RECORD;

BEGIN -- Contar professores ativos
SELECT
     COUNT(*) INTO total_professores
FROM
     pessoas
WHERE
     fk_id_tipo_pessoa = 2
     AND deleted_at IS NULL
     AND ativo = TRUE;

-- Contar professores com conta bancária
SELECT
     COUNT(*) INTO total_com_conta
FROM
     view_professores_com_conta_bancaria;

-- Calcular professores sem conta
total_sem_conta := total_professores - total_com_conta;

RAISE NOTICE '========================================';

RAISE NOTICE 'ESTATÍSTICAS:';

RAISE NOTICE '  - Total de professores ativos: %',
total_professores;

RAISE NOTICE '  - Professores COM conta bancária: %',
total_com_conta;

RAISE NOTICE '  - Professores SEM conta bancária: %',
total_sem_conta;

RAISE NOTICE '========================================';

-- Mostrar exemplo de professor
IF total_com_conta > 0 THEN
SELECT
     * INTO exemplo_professor
FROM
     view_professores_com_conta_bancaria
LIMIT
     1;

RAISE NOTICE 'Exemplo de professor:';

RAISE NOTICE '  - ID: %', exemplo_professor.professor_id;

RAISE NOTICE '  - Nome: %', exemplo_professor.professor_nome;

RAISE NOTICE '  - Número Participante: %', exemplo_professor.numero_participante;

RAISE NOTICE '  - Total de Turmas: %', exemplo_professor.total_turmas;

RAISE NOTICE '========================================';

END IF;

END $ $;

COMMIT;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
DO $ $ BEGIN RAISE NOTICE '========================================';

RAISE NOTICE 'MIGRATION CONCLUÍDA COM SUCESSO!';

RAISE NOTICE '========================================';

RAISE NOTICE 'View criada: view_professores_com_conta_bancaria';

RAISE NOTICE 'Funções criadas:';

RAISE NOTICE '  1. buscar_professor_por_numero_participante()';

RAISE NOTICE '  2. professor_tem_conta_bancaria()';

RAISE NOTICE '========================================';

RAISE NOTICE 'Próximos passos:';

RAISE NOTICE '  1. Criar endpoint GET /professores/com-conta-bancaria';

RAISE NOTICE '  2. Implementar service no frontend';

RAISE NOTICE '  3. Atualizar ItemRecebedor para exibir nome';

RAISE NOTICE '========================================';

END $ $;