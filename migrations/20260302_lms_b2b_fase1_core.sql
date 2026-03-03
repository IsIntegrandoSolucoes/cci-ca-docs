-- =====================================================
-- Migration: LMS B2B - Fase 1 Core
-- Data: 2026-03-02
-- Descrição: Tabelas base para multi-tenancy B2B
-- Convenções: supabase-convencoes (BIGINT, fk_id_*, snake_case)
-- =====================================================
-- =====================================================
-- 1. TABELAS
-- =====================================================
-- Tabela: empresas
-- Empresas clientes B2B para módulo LMS
CREATE TABLE IF NOT EXISTS empresas (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  -- Dados da empresa
  razao_social TEXT NOT NULL,
  nome_fantasia TEXT,
  cnpj TEXT NOT NULL UNIQUE,
  -- Contrato
  STATUS TEXT NOT NULL DEFAULT 'ativa' CHECK (STATUS IN ('ativa', 'suspensa', 'expirada')),
  data_contrato DATE NOT NULL DEFAULT CURRENT_DATE,
  data_validade DATE NOT NULL,
  limite_usuarios_simultaneos INTEGER NOT NULL DEFAULT 10,
  -- Contato
  email_contato TEXT,
  telefone_contato TEXT,
  -- Observações
  observacoes TEXT
);

CREATE INDEX IF NOT EXISTS idx_empresas_status ON empresas(STATUS)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_empresas_validade ON empresas(data_validade)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_empresas_cnpj ON empresas(cnpj);

COMMENT ON TABLE empresas IS 'Empresas clientes B2B para módulo LMS';

COMMENT ON COLUMN empresas.limite_usuarios_simultaneos IS 'Quantidade máxima de usuários logados ao mesmo tempo';

COMMENT ON COLUMN empresas.status IS 'ativa: operação normal, suspensa: bloqueio manual, expirada: validade vencida';

-- Tabela: empresa_usuarios
-- Vínculo entre pessoas (auth.users via uid) e empresas
CREATE TABLE IF NOT EXISTS empresa_usuarios (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  -- Vínculos
  fk_id_empresa BIGINT NOT NULL REFERENCES empresas(id),
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  -- Perfil na empresa
  perfil TEXT NOT NULL DEFAULT 'aluno' CHECK (perfil IN ('gestor_rh', 'aluno')),
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  -- Dados do colaborador
  departamento TEXT,
  cargo TEXT,
  matricula_rh TEXT,
  -- Auditoria de convite
  data_convite TIMESTAMPTZ,
  data_aceite TIMESTAMPTZ,
  -- Constraint de unicidade
  CONSTRAINT unq_empresa_usuarios_empresa_pessoa UNIQUE (fk_id_empresa, fk_id_pessoa)
);

CREATE INDEX IF NOT EXISTS idx_empresa_usuarios_empresa ON empresa_usuarios(fk_id_empresa)
WHERE
  ativo = TRUE
  AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_empresa_usuarios_pessoa ON empresa_usuarios(fk_id_pessoa)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_empresa_usuarios_perfil ON empresa_usuarios(perfil, fk_id_empresa)
WHERE
  ativo = TRUE
  AND deleted_at IS NULL;

COMMENT ON TABLE empresa_usuarios IS 'Vínculo entre pessoas e empresas B2B (multi-tenancy)';

COMMENT ON COLUMN empresa_usuarios.perfil IS 'gestor_rh: gerencia colaboradores, aluno: acessa cursos';

-- Tabela: sessoes_ativas
-- Controle de usuários simultâneos por empresa
CREATE TABLE IF NOT EXISTS sessoes_ativas (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  -- Vínculos
  fk_id_empresa BIGINT NOT NULL REFERENCES empresas(id),
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  fk_id_curso BIGINT,
  -- Será preenchido quando tabela cursos existir
  -- Controle de sessão
  session_token TEXT NOT NULL UNIQUE,
  ip_address INET,
  user_agent TEXT,
  -- Heartbeat (mantém sessão viva)
  ultimo_heartbeat TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Constraint: um usuário só pode ter 1 sessão ativa por curso
  CONSTRAINT unq_sessoes_ativas_pessoa_curso UNIQUE (fk_id_pessoa, fk_id_curso)
);

CREATE INDEX IF NOT EXISTS idx_sessoes_ativas_empresa ON sessoes_ativas(fk_id_empresa);

CREATE INDEX IF NOT EXISTS idx_sessoes_ativas_pessoa ON sessoes_ativas(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_sessoes_ativas_heartbeat ON sessoes_ativas(ultimo_heartbeat);

CREATE INDEX IF NOT EXISTS idx_sessoes_ativas_token ON sessoes_ativas(session_token);

COMMENT ON TABLE sessoes_ativas IS 'Registro de sessões ativas para controle de concorrência';

COMMENT ON COLUMN sessoes_ativas.ultimo_heartbeat IS 'Heartbeat a cada 30s. Timeout: 5 min sem heartbeat = sessão expira';

COMMENT ON COLUMN sessoes_ativas.session_token IS 'Token único da sessão para validação';

-- =====================================================
-- 2. FUNÇÕES DE SUPORTE (SECURITY DEFINER)
-- =====================================================
-- Retorna o ID da pessoa a partir do UID do auth.users
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

COMMENT ON FUNCTION fn_get_pessoa_id_from_uid() IS 'Retorna o ID da pessoa vinculada ao usuário autenticado';

-- Verifica se o usuário é admin interno (tipo_pessoa = 8)
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

COMMENT ON FUNCTION fn_is_admin_interno() IS 'Verifica se o usuário autenticado é administrador interno (equipe CCI-CA)';

-- Retorna o ID da empresa do usuário
CREATE
OR REPLACE FUNCTION fn_get_empresa_id_do_usuario(p_pessoa_id BIGINT DEFAULT NULL) RETURNS BIGINT LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  eu.fk_id_empresa
FROM
  empresa_usuarios eu
WHERE
  eu.fk_id_pessoa = COALESCE(p_pessoa_id, fn_get_pessoa_id_from_uid())
  AND eu.ativo = TRUE
  AND eu.deleted_at IS NULL
LIMIT
  1;

$ $;

COMMENT ON FUNCTION fn_get_empresa_id_do_usuario(BIGINT) IS 'Retorna o ID da empresa do usuário especificado ou do usuário autenticado';

-- Verifica se o usuário é gestor RH da empresa especificada
CREATE
OR REPLACE FUNCTION fn_is_gestor_rh_da_empresa(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      empresa_usuarios eu
    WHERE
      eu.fk_id_empresa = p_empresa_id
      AND eu.fk_id_pessoa = fn_get_pessoa_id_from_uid()
      AND eu.perfil = 'gestor_rh'
      AND eu.ativo = TRUE
      AND eu.deleted_at IS NULL
  );

$ $;

COMMENT ON FUNCTION fn_is_gestor_rh_da_empresa(BIGINT) IS 'Verifica se o usuário autenticado é gestor RH da empresa especificada';

-- Verifica se a empresa está ativa (não suspensa/expirada)
CREATE
OR REPLACE FUNCTION fn_empresa_status_ativo(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      empresas
    WHERE
      id = p_empresa_id
      AND STATUS = 'ativa'
      AND data_validade >= CURRENT_DATE
      AND deleted_at IS NULL
  );

$ $;

COMMENT ON FUNCTION fn_empresa_status_ativo(BIGINT) IS 'Verifica se a empresa está ativa e dentro da validade';

-- =====================================================
-- 3. POLÍTICAS RLS
-- =====================================================
-- ----- TABELA: empresas -----
ALTER TABLE
  empresas ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  empresas FORCE ROW LEVEL SECURITY;

-- SELECT: Admin interno vê todas
CREATE POLICY pol_empresas_select_admin ON empresas FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

-- SELECT: Gestor RH vê apenas sua empresa
CREATE POLICY pol_empresas_select_gestor ON empresas FOR
SELECT
  TO authenticated USING (
    id = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(id)
  );

-- SELECT: Aluno vê apenas sua própria empresa (dados limitados via view)
CREATE POLICY pol_empresas_select_aluno ON empresas FOR
SELECT
  TO authenticated USING (id = fn_get_empresa_id_do_usuario());

-- INSERT: Apenas admin interno
CREATE POLICY pol_empresas_insert_admin ON empresas FOR
INSERT
  TO authenticated WITH CHECK (fn_is_admin_interno());

-- UPDATE: Admin interno atualiza qualquer
CREATE POLICY pol_empresas_update_admin ON empresas FOR
UPDATE
  TO authenticated USING (fn_is_admin_interno()) WITH CHECK (fn_is_admin_interno());

-- UPDATE: Gestor RH atualiza campos limitados da própria empresa
CREATE POLICY pol_empresas_update_gestor ON empresas FOR
UPDATE
  TO authenticated USING (
    id = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(id)
  ) WITH CHECK (
    id = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(id)
  );

-- DELETE: Apenas admin interno (soft delete)
CREATE POLICY pol_empresas_delete_admin ON empresas FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- ----- TABELA: empresa_usuarios -----
ALTER TABLE
  empresa_usuarios ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  empresa_usuarios FORCE ROW LEVEL SECURITY;

-- SELECT: Admin interno vê todos
CREATE POLICY pol_empresa_usuarios_select_admin ON empresa_usuarios FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

-- SELECT: Gestor RH vê apenas da própria empresa
CREATE POLICY pol_empresa_usuarios_select_gestor ON empresa_usuarios FOR
SELECT
  TO authenticated USING (
    fk_id_empresa = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

-- SELECT: Aluno vê apenas seu próprio vínculo
CREATE POLICY pol_empresa_usuarios_select_proprio ON empresa_usuarios FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

-- INSERT: Admin interno ou Gestor RH da empresa
CREATE POLICY pol_empresa_usuarios_insert_gestores ON empresa_usuarios FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

-- UPDATE: Admin interno ou Gestor RH da empresa
CREATE POLICY pol_empresa_usuarios_update_gestores ON empresa_usuarios FOR
UPDATE
  TO authenticated USING (
    fn_is_admin_interno()
    OR fn_is_gestor_rh_da_empresa(fk_id_empresa)
  ) WITH CHECK (
    fn_is_admin_interno()
    OR fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

-- DELETE: Apenas admin interno
CREATE POLICY pol_empresa_usuarios_delete_admin ON empresa_usuarios FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- ----- TABELA: sessoes_ativas -----
ALTER TABLE
  sessoes_ativas ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  sessoes_ativas FORCE ROW LEVEL SECURITY;

-- SELECT: Admin interno vê todas
CREATE POLICY pol_sessoes_ativas_select_admin ON sessoes_ativas FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

-- SELECT: Gestor RH vê sessões da própria empresa
CREATE POLICY pol_sessoes_ativas_select_gestor ON sessoes_ativas FOR
SELECT
  TO authenticated USING (
    fk_id_empresa = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

-- SELECT: Usuário vê apenas suas próprias sessões
CREATE POLICY pol_sessoes_ativas_select_proprio ON sessoes_ativas FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

-- INSERT/UPDATE/DELETE: Apenas via RPC (controle transacional)
CREATE POLICY pol_sessoes_ativas_insert_admin ON sessoes_ativas FOR
INSERT
  TO authenticated WITH CHECK (fn_is_admin_interno());

CREATE POLICY pol_sessoes_ativas_update_admin ON sessoes_ativas FOR
UPDATE
  TO authenticated USING (fn_is_admin_interno()) WITH CHECK (fn_is_admin_interno());

CREATE POLICY pol_sessoes_ativas_delete_admin ON sessoes_ativas FOR DELETE TO authenticated USING (fn_is_admin_interno());