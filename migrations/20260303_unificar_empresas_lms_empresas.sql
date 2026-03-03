-- =====================================================
-- Migration: Unificação empresas → lms_empresas
-- Data: 2026-03-03
-- Descrição: Unifica tabelas duplicadas. Adota lms_empresas como source of truth.
--            A tabela "empresas" (fase1_core) nunca foi aplicada no banco;
--            o código vivo (controllers, services, frontend) já usa lms_empresas.
--            Esta migração garante que as funções fn_* (sem prefixo lms)
--            apontem para as tabelas lms_* existentes.
-- =====================================================
BEGIN;

-- =====================================================
-- 1. DROP da tabela "empresas" (se existir) e dependentes
--    Estas tabelas foram planejadas mas nunca criadas no banco.
--    Se por acaso existirem, removemos para evitar conflito.
-- =====================================================
-- Remover políticas RLS (se existirem)
DROP POLICY IF EXISTS pol_empresas_select_admin ON empresas;

DROP POLICY IF EXISTS pol_empresas_select_gestor ON empresas;

DROP POLICY IF EXISTS pol_empresas_select_aluno ON empresas;

DROP POLICY IF EXISTS pol_empresas_insert_admin ON empresas;

DROP POLICY IF EXISTS pol_empresas_update_admin ON empresas;

DROP POLICY IF EXISTS pol_empresas_update_gestor ON empresas;

DROP POLICY IF EXISTS pol_empresas_delete_admin ON empresas;

DROP POLICY IF EXISTS pol_empresa_usuarios_select_admin ON empresa_usuarios;

DROP POLICY IF EXISTS pol_empresa_usuarios_select_gestor ON empresa_usuarios;

DROP POLICY IF EXISTS pol_empresa_usuarios_select_proprio ON empresa_usuarios;

DROP POLICY IF EXISTS pol_empresa_usuarios_insert_gestores ON empresa_usuarios;

DROP POLICY IF EXISTS pol_empresa_usuarios_update_gestores ON empresa_usuarios;

DROP POLICY IF EXISTS pol_empresa_usuarios_delete_admin ON empresa_usuarios;

DROP POLICY IF EXISTS pol_sessoes_ativas_select_admin ON sessoes_ativas;

DROP POLICY IF EXISTS pol_sessoes_ativas_select_gestor ON sessoes_ativas;

DROP POLICY IF EXISTS pol_sessoes_ativas_select_proprio ON sessoes_ativas;

DROP POLICY IF EXISTS pol_sessoes_ativas_insert_admin ON sessoes_ativas;

DROP POLICY IF EXISTS pol_sessoes_ativas_update_admin ON sessoes_ativas;

DROP POLICY IF EXISTS pol_sessoes_ativas_delete_admin ON sessoes_ativas;

-- Remover tabelas duplicadas (ordem: dependentes primeiro)
DROP TABLE IF EXISTS sessoes_ativas CASCADE;

DROP TABLE IF EXISTS empresa_usuarios CASCADE;

DROP TABLE IF EXISTS empresas CASCADE;

-- =====================================================
-- 2. ADICIONAR COLUNAS FALTANTES em lms_empresas
--    A tabela empresas (plano) tinha campos extras úteis.
-- =====================================================
-- limite_usuarios_simultaneos (do plano fase1_core)
ALTER TABLE
  lms_empresas
ADD
  COLUMN IF NOT EXISTS limite_usuarios_simultaneos INTEGER NOT NULL DEFAULT 10;

COMMENT ON COLUMN lms_empresas.limite_usuarios_simultaneos IS 'Quantidade máxima de usuários logados ao mesmo tempo';

-- =====================================================
-- 3. ADICIONAR COLUNAS FALTANTES em lms_empresa_usuarios
--    Campos que existiam no plano e são úteis.
-- =====================================================
ALTER TABLE
  lms_empresa_usuarios
ADD
  COLUMN IF NOT EXISTS departamento TEXT,
ADD
  COLUMN IF NOT EXISTS cargo TEXT,
ADD
  COLUMN IF NOT EXISTS matricula_rh TEXT,
ADD
  COLUMN IF NOT EXISTS data_convite TIMESTAMPTZ,
ADD
  COLUMN IF NOT EXISTS data_aceite TIMESTAMPTZ;

-- =====================================================
-- 4. SESSÕES ATIVAS — Criar apontando para lms_empresas
-- =====================================================
CREATE TABLE IF NOT EXISTS lms_sessoes_ativas (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  fk_id_empresa BIGINT NOT NULL REFERENCES lms_empresas(id),
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  fk_id_curso BIGINT,
  session_token TEXT NOT NULL UNIQUE,
  ip_address INET,
  user_agent TEXT,
  ultimo_heartbeat TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unq_lms_sessoes_pessoa_curso UNIQUE (fk_id_pessoa, fk_id_curso)
);

CREATE INDEX IF NOT EXISTS idx_lms_sessoes_empresa ON lms_sessoes_ativas(fk_id_empresa);

CREATE INDEX IF NOT EXISTS idx_lms_sessoes_pessoa ON lms_sessoes_ativas(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_lms_sessoes_heartbeat ON lms_sessoes_ativas(ultimo_heartbeat);

CREATE INDEX IF NOT EXISTS idx_lms_sessoes_token ON lms_sessoes_ativas(session_token);

COMMENT ON TABLE lms_sessoes_ativas IS 'Sessões ativas para controle de concorrência B2B';

COMMENT ON COLUMN lms_sessoes_ativas.ultimo_heartbeat IS 'Heartbeat a cada 30s. Timeout: 5 min = sessão expira';

-- =====================================================
-- 5. RECRIAR FUNÇÕES fn_* para apontar para lms_*
--    Mantém compatibilidade com código que usa fn_* sem prefixo
-- =====================================================
-- fn_get_pessoa_id_from_uid (sem mudanças, usa apenas "pessoas")
CREATE
OR REPLACE FUNCTION fn_get_pessoa_id_from_uid() RETURNS BIGINT LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  id
FROM
  pessoas
WHERE
  uid = auth.uid() :: text
  AND deleted_at IS NULL
LIMIT
  1;

$ $;

-- fn_is_admin_interno (sem mudanças, usa apenas "pessoas")
CREATE
OR REPLACE FUNCTION fn_is_admin_interno() RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
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

-- fn_get_empresa_id_do_usuario → aponta para lms_empresa_usuarios
CREATE
OR REPLACE FUNCTION fn_get_empresa_id_do_usuario(p_pessoa_id BIGINT DEFAULT NULL) RETURNS BIGINT LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  eu.fk_id_empresa
FROM
  lms_empresa_usuarios eu
WHERE
  eu.fk_id_pessoa = COALESCE(p_pessoa_id, fn_get_pessoa_id_from_uid())
  AND eu.status = 'ativo'
  AND eu.deleted_at IS NULL
LIMIT
  1;

$ $;

-- fn_is_gestor_rh_da_empresa → aponta para lms_empresa_usuarios
CREATE
OR REPLACE FUNCTION fn_is_gestor_rh_da_empresa(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      lms_empresa_usuarios eu
    WHERE
      eu.fk_id_empresa = p_empresa_id
      AND eu.fk_id_pessoa = fn_get_pessoa_id_from_uid()
      AND eu.perfil = 'gestor_rh'
      AND eu.status = 'ativo'
      AND eu.deleted_at IS NULL
  );

$ $;

-- fn_empresa_status_ativo → aponta para lms_empresas
CREATE
OR REPLACE FUNCTION fn_empresa_status_ativo(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      lms_empresas
    WHERE
      id = p_empresa_id
      AND STATUS = 'ativa'
      AND data_fim_contrato >= CURRENT_DATE
      AND deleted_at IS NULL
  );

$ $;

-- =====================================================
-- 6. RLS em lms_sessoes_ativas
-- =====================================================
ALTER TABLE
  lms_sessoes_ativas ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  lms_sessoes_ativas FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_lms_sessoes_select_admin ON lms_sessoes_ativas FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_lms_sessoes_select_gestor ON lms_sessoes_ativas FOR
SELECT
  TO authenticated USING (
    fk_id_empresa = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

CREATE POLICY pol_lms_sessoes_select_proprio ON lms_sessoes_ativas FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

-- INSERT/UPDATE/DELETE: Apenas via RPC ou admin
CREATE POLICY pol_lms_sessoes_insert_admin ON lms_sessoes_ativas FOR
INSERT
  TO authenticated WITH CHECK (fn_is_admin_interno());

CREATE POLICY pol_lms_sessoes_update_admin ON lms_sessoes_ativas FOR
UPDATE
  TO authenticated USING (fn_is_admin_interno()) WITH CHECK (fn_is_admin_interno());

CREATE POLICY pol_lms_sessoes_delete_admin ON lms_sessoes_ativas FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- trigger updated_at
DROP TRIGGER IF EXISTS trg_lms_sessoes_set_updated_at ON lms_sessoes_ativas;

COMMIT;