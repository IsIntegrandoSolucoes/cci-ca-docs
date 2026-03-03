-- ============================================================================
-- MIGRATION: Expandir Perfis de lms_empresa_usuarios
-- Data: 2026-03-03
-- Etapa 3 de 5 — Multi-tenant Admin Panel
-- Contexto: lms_empresa_usuarios.perfil था ('gestor_rh', 'colaborador').
--   Adiciona: 'admin_curso' e 'professor' (perfis B2B).
--   Coordenador/Secretaria são perfis do sistema ESCOLAR (tipo_pessoa 5/6),
--   não são perfis de empresa B2B — portanto NÃO entram aqui.
-- Depende de:
--   - 20260227100000_b2b_empresas_licencas_base.sql (lms_empresa_usuarios existente)
--   - 20260303_normalizar_tipo_pessoa.sql (fn_lms_is_professor usa tipo_pessoa=4)
-- ============================================================================
BEGIN;

-- ============================================================================
-- 1. EXPANDIR CHECK CONSTRAINT DE perfil
--    O CHECK inline na criação da tabela não recebeu nome explícito.
--    Usamos DO block para encontrar e dropar pelo catálogo do pg.
-- ============================================================================
DO $ $ DECLARE v_constraint_name TEXT;

BEGIN
SELECT
  conname INTO v_constraint_name
FROM
  pg_constraint
WHERE
  conrelid = 'lms_empresa_usuarios' :: regclass
  AND contype = 'c'
  AND pg_get_constraintdef(oid) ILIKE '%perfil%';

IF v_constraint_name IS NOT NULL THEN EXECUTE 'ALTER TABLE lms_empresa_usuarios DROP CONSTRAINT ' || quote_ident(v_constraint_name);

RAISE NOTICE 'Constraint "%" removida de lms_empresa_usuarios.',
v_constraint_name;

ELSE RAISE NOTICE 'Nenhuma constraint de perfil encontrada — pode já ter sido atualizada.';

END IF;

END;

$ $;

-- Adiciona constraint nomeada com os valores expandidos
ALTER TABLE
  lms_empresa_usuarios
ADD
  CONSTRAINT ck_lms_empresa_usuarios_perfil CHECK (
    perfil IN (
      'gestor_rh',
      'admin_curso',
      'professor',
      'colaborador'
    )
  );

COMMENT ON COLUMN lms_empresa_usuarios.perfil IS 'Perfil do usuário dentro da empresa B2B:
   gestor_rh    — Pode convidar/desativar colaboradores e ver relatórios RH.
   admin_curso  — Gerencia catálogo de cursos da empresa.
   professor    — Ministra cursos vinculados à empresa.
   colaborador  — Funcionário/aluno padrão.
   Coordenador/Secretaria são papéis do sistema escolar (tipo_pessoa 5/6).';

-- ============================================================================
-- 2. CORRIGIR BUG: rpc_validar_acesso_simultaneo usava ativo=TRUE
--    A tabela lms_empresa_usuarios usa status VARCHAR('ativo','inativo'),
--    não existe coluna booleana ativo.
-- ============================================================================
CREATE
OR REPLACE FUNCTION rpc_validar_acesso_simultaneo(
  p_pessoa_id BIGINT,
  p_curso_id BIGINT,
  p_session_token TEXT,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_empresa_id BIGINT;

v_limite_simultaneo INTEGER;

v_sessoes_ativas INTEGER;

BEGIN -- Obter empresa do usuário (status='ativo', sem soft-delete)
SELECT
  fk_id_empresa INTO v_empresa_id
FROM
  lms_empresa_usuarios
WHERE
  fk_id_pessoa = p_pessoa_id
  AND STATUS = 'ativo'
  AND deleted_at IS NULL
LIMIT
  1;

IF v_empresa_id IS NULL THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'sem_empresa',
  'mensagem',
  'Usuário não está vinculado a nenhuma empresa ativa.'
);

END IF;

-- Validar status da empresa
IF NOT fn_lms_empresa_status_ativo(v_empresa_id) THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'empresa_inativa',
  'mensagem',
  'Empresa sem licença ativa no momento.'
);

END IF;

-- Obter limite de sessões simultâneas da empresa
SELECT
  limite_usuarios_simultaneos INTO v_limite_simultaneo
FROM
  lms_empresas
WHERE
  id = v_empresa_id;

v_limite_simultaneo := COALESCE(v_limite_simultaneo, 10);

-- Contar sessões ativas atuais da empresa (excluindo a própria sessão do usuário)
SELECT
  COUNT(*) INTO v_sessoes_ativas
FROM
  lms_sessoes_ativas
WHERE
  fk_id_empresa = v_empresa_id
  AND fk_id_pessoa <> p_pessoa_id
  AND ultimo_heartbeat > NOW() - INTERVAL '15 minutes';

IF v_sessoes_ativas >= v_limite_simultaneo THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'limite_atingido',
  'mensagem',
  'Limite de usuários simultâneos da empresa atingido.',
  'limite',
  v_limite_simultaneo,
  'ativas',
  v_sessoes_ativas
);

END IF;

-- Registrar / atualizar sessão ativa
INSERT INTO
  lms_sessoes_ativas (
    fk_id_empresa,
    fk_id_pessoa,
    fk_id_curso,
    session_token,
    ip_address,
    user_agent,
    ultimo_heartbeat
  )
VALUES
  (
    v_empresa_id,
    p_pessoa_id,
    p_curso_id,
    p_session_token,
    p_ip_address,
    p_user_agent,
    NOW()
  ) ON CONFLICT (fk_id_pessoa, fk_id_curso) DO
UPDATE
SET
  session_token = EXCLUDED.session_token,
  ip_address = EXCLUDED.ip_address,
  user_agent = EXCLUDED.user_agent,
  ultimo_heartbeat = NOW();

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'empresa_id',
  v_empresa_id,
  'sessoes_ativas',
  v_sessoes_ativas + 1
);

END;

$ $;

-- ============================================================================
-- 3. FUNÇÕES RLS AUXILIARES — Perfis B2B
--    Usadas em RLS policies e guards de rota da API.
-- ============================================================================
-- Verifica se o usuário logado é gestor_rh em uma empresa específica
CREATE
OR REPLACE FUNCTION fn_lms_is_gestor_rh(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      lms_empresa_usuarios eu
    WHERE
      eu.fk_id_pessoa = fn_get_pessoa_id_from_uid(auth.uid())
      AND eu.fk_id_empresa = p_empresa_id
      AND eu.perfil = 'gestor_rh'
      AND eu.status = 'ativo'
      AND eu.deleted_at IS NULL
  );

$ $;

-- Verifica se o usuário logado é admin_curso em uma empresa específica
CREATE
OR REPLACE FUNCTION fn_lms_is_admin_curso(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      lms_empresa_usuarios eu
    WHERE
      eu.fk_id_pessoa = fn_get_pessoa_id_from_uid(auth.uid())
      AND eu.fk_id_empresa = p_empresa_id
      AND eu.perfil = 'admin_curso'
      AND eu.status = 'ativo'
      AND eu.deleted_at IS NULL
  );

$ $;

-- Verifica se o usuário logado é professor vinculado a uma empresa
CREATE
OR REPLACE FUNCTION fn_lms_is_professor_empresa(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      lms_empresa_usuarios eu
    WHERE
      eu.fk_id_pessoa = fn_get_pessoa_id_from_uid(auth.uid())
      AND eu.fk_id_empresa = p_empresa_id
      AND eu.perfil = 'professor'
      AND eu.status = 'ativo'
      AND eu.deleted_at IS NULL
  );

$ $;

-- Verifica se o usuário logado tem QUALQUER perfil de gestão em uma empresa
-- (gestor_rh ou admin_curso — exclui professor e colaborador)
CREATE
OR REPLACE FUNCTION fn_lms_is_gestor_empresa(p_empresa_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      lms_empresa_usuarios eu
    WHERE
      eu.fk_id_pessoa = fn_get_pessoa_id_from_uid(auth.uid())
      AND eu.fk_id_empresa = p_empresa_id
      AND eu.perfil IN ('gestor_rh', 'admin_curso')
      AND eu.status = 'ativo'
      AND eu.deleted_at IS NULL
  );

$ $;

-- Retorna o perfil B2B do usuário logado em uma empresa (NULL se não vinculado)
CREATE
OR REPLACE FUNCTION fn_lms_get_perfil_empresa(p_empresa_id BIGINT) RETURNS VARCHAR LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  eu.perfil
FROM
  lms_empresa_usuarios eu
WHERE
  eu.fk_id_pessoa = fn_get_pessoa_id_from_uid(auth.uid())
  AND eu.fk_id_empresa = p_empresa_id
  AND eu.status = 'ativo'
  AND eu.deleted_at IS NULL
LIMIT
  1;

$ $;

COMMIT;