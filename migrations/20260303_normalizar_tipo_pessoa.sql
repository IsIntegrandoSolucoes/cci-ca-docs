-- =====================================================
-- Migration: Normalização de tipo_pessoa
-- Data: 2026-03-03
-- Descrição: Define os valores canônicos de tipo_pessoa,
--            adiciona novos perfis (Coordenação, Secretaria),
--            e corrige usos legados inconsistentes.
--
-- MAPA FINAL:
--   1 = Aluno
--   2 = Responsável Financeiro   ← confirmar uso em alunoService.ts (criar responsável)
--   3 = Funcionário (genérico)   ← substitui "Admin" legado de anotações
--   4 = Professor
--   5 = Coordenador              ← NOVO: acesso ao admin, gestão acadêmica/turmas
--   6 = Secretaria               ← NOVO: acesso ao admin, gestão de alunos/contratos
--   8 = Administrador Interno    ← Super Admin CCI-CA (acesso total)
--
-- Regra de acesso ao admin panel (cci-ca-admin):
--   tipo_pessoa IN (4, 5, 6, 8) → pode logar no admin
--   tipo_pessoa = 8              → Super Admin (sem restrições)
--   tipo_pessoa = 4              → Professor (rotas filtradas por ProfessorFilterContext)
--   tipo_pessoa = 5              → Coordenador (menu acadêmico + estrutura)
--   tipo_pessoa = 6              → Secretaria (menu alunos + contratos + financeiro operacional)
-- =====================================================
BEGIN;

-- =====================================================
-- 1. GARANTIR QUE VALORES CANÔNICOS EXISTAM
--    (INSERT ... ON CONFLICT DO UPDATE para idempotência)
-- =====================================================
INSERT INTO
  tipo_pessoa (id, descricao)
VALUES
  (1, 'Aluno'),
  (2, 'Responsável Financeiro'),
  (3, 'Funcionário'),
  (4, 'Professor'),
  (5, 'Coordenador'),
  (6, 'Secretaria'),
  (8, 'Administrador') ON CONFLICT (id) DO
UPDATE
SET
  descricao = EXCLUDED.descricao,
  updated_at = CURRENT_TIMESTAMP;

-- =====================================================
-- 2. CORRIGIR DADOS LEGADOS
--    tipo_pessoa = 3 estava sendo usado como "Admin" em
--    anotações antigas. Migrar para tipo 3 = Funcionário
--    (redefinido) ou manter ID sem alterar pessoas existentes.
--    Tipo 3 era usado apenas internamente; pessoas reais
--    com esse tipo eram da equipe → reclassificar como 8
--    (Administrador) ou manter como Funcionário (3).
-- =====================================================
-- Professores cadastrados com tipo_pessoa = 2 (legado, antes de existir ID 4)
-- devem ser migrados para tipo_pessoa = 4.
-- Atenção: tipo 2 agora = Responsável Financeiro.
-- Esta atualização só afeta registros que tenham conta_bancaria ou
-- estejam vinculados à tabela de professores, confirmando que são professores.
UPDATE
  pessoas
SET
  fk_id_tipo_pessoa = 4,
  updated_at = CURRENT_TIMESTAMP
WHERE
  fk_id_tipo_pessoa = 2
  AND deleted_at IS NULL
  AND EXISTS (
    SELECT
      1
    FROM
      professores p
    WHERE
      p.fk_id_pessoa = pessoas.id
      AND p.deleted_at IS NULL
  );

-- =====================================================
-- 3. CORRIGIR FUNÇÕES RLS PARA PROFESSOR (ID = 4)
--    As funções fn_lms_is_professor() e fn_lms_is_admin_interno()
--    usam JOIN na descrição do tipo_pessoa — frágil.
--    Recriar usando IDs diretos que agora são canônicos.
-- =====================================================
-- fn_lms_is_professor: usa ID 4 (canônico)
CREATE
OR REPLACE FUNCTION fn_lms_is_professor() RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      pessoas
    WHERE
      uid = auth.uid() :: text
      AND fk_id_tipo_pessoa = 4
      AND deleted_at IS NULL
  );

$ $;

COMMENT ON FUNCTION fn_lms_is_professor() IS 'Verifica se o usuário autenticado é Professor (tipo_pessoa = 4)';

-- fn_lms_is_admin_interno: usa ID 8 (canônico)
CREATE
OR REPLACE FUNCTION fn_lms_is_admin_interno() RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      pessoas
    WHERE
      uid = auth.uid() :: text
      AND fk_id_tipo_pessoa = 8
      AND deleted_at IS NULL
  );

$ $;

COMMENT ON FUNCTION fn_lms_is_admin_interno() IS 'Verifica se o usuário autenticado é Administrador Interno (tipo_pessoa = 8)';

-- fn_is_admin_panel_user: novo — verifica se pode logar no admin panel
-- Tipos com acesso ao admin: Professor (4), Coordenador (5), Secretaria (6), Admin (8)
CREATE
OR REPLACE FUNCTION fn_is_admin_panel_user() RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      pessoas
    WHERE
      uid = auth.uid() :: text
      AND fk_id_tipo_pessoa IN (4, 5, 6, 8)
      AND deleted_at IS NULL
  );

$ $;

COMMENT ON FUNCTION fn_is_admin_panel_user() IS 'Verifica se o usuário autenticado tem acesso ao painel admin (Professor=4, Coordenador=5, Secretaria=6, Admin=8)';

-- fn_get_tipo_pessoa_atual: utilitário — retorna o tipo_pessoa do usuário logado
CREATE
OR REPLACE FUNCTION fn_get_tipo_pessoa_atual() RETURNS INTEGER LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  fk_id_tipo_pessoa :: INTEGER
FROM
  pessoas
WHERE
  uid = auth.uid() :: text
  AND deleted_at IS NULL
LIMIT
  1;

$ $;

COMMENT ON FUNCTION fn_get_tipo_pessoa_atual() IS 'Retorna o tipo_pessoa (como INTEGER) do usuário autenticado';

-- =====================================================
-- 4. COMMENTS DE DOCUMENTAÇÃO NA TABELA TIPO_PESSOA
-- =====================================================
COMMENT ON TABLE tipo_pessoa IS 'Tipos de pessoa do sistema. Controla acesso a portais e funcionalidades.
   1=Aluno (portal aluno), 2=Responsavel Financeiro, 3=Funcionario (generico),
   4=Professor (admin filtrado), 5=Coordenador (admin academico),
   6=Secretaria (admin operacional), 8=Administrador (super admin).';

COMMIT;