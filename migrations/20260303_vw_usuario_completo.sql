-- ============================================================================
-- MIGRATION: vw_usuario_completo + RPC fn_get_usuario_completo
-- Data: 2026-03-03
-- Etapa 5 de 5 — Multi-tenant Admin Panel
-- Contexto: View que consolida pessoas + tipo_pessoa + lms_empresa_usuarios
--   em um único registro por usuário, com campo perfil_admin pronto para
--   ser usado como chave na tabela perfil_permissoes.
-- Depende de:
--   - 20260303_normalizar_tipo_pessoa.sql       (tipo_pessoa canônico)
--   - 20260303_expandir_perfil_empresa_usuarios (lms_empresa_usuarios.perfil expandido)
--   - 20260303_perfil_permissoes.sql            (tabela perfil_permissoes + seed)
-- Uso no frontend (UserContext):
--   supabase.from('vw_usuario_completo').select('*').eq('uid', userId).single()
--   Ou: supabase.rpc('fn_get_usuario_completo', { p_uid: userId })
-- ============================================================================
BEGIN;

-- ============================================================================
-- 1. VIEW vw_usuario_completo
--    Retorna um registro por pessoa ativa.
--    Múltiplos vínculos B2B: usa LATERAL para empresa principal (mais recente ativa)
--    e array_agg para todas as empresa_ids ativas do usuário.
-- ============================================================================
CREATE
OR REPLACE VIEW vw_usuario_completo AS
SELECT
  -- -------------------------------------------------------
  -- Campos da tabela pessoas (compatibilidade com IUser.ts)
  -- -------------------------------------------------------
  p.id,
  p.uid,
  p.nome,
  p.primeiro_nome,
  p.sobrenome,
  p.email,
  p.telefone,
  p.data_nascimento,
  p.genero,
  p.cpf,
  p.fk_id_tipo_pessoa,
  p.created_at,
  p.updated_at,
  -- -------------------------------------------------------
  -- Tipo de pessoa
  -- -------------------------------------------------------
  tp.descricao AS tipo_pessoa_descricao,
  -- -------------------------------------------------------
  -- Perfil do sistema escolar (derivado de tipo_pessoa)
  --   8 → super_admin  |  5 → coordenador  |  6 → secretaria
  --   4 → professor    |  demais → NULL
  -- -------------------------------------------------------
  CASE
    p.fk_id_tipo_pessoa
    WHEN 8 THEN 'super_admin'
    WHEN 5 THEN 'coordenador'
    WHEN 6 THEN 'secretaria'
    WHEN 4 THEN 'professor'
    ELSE NULL
  END :: VARCHAR AS perfil_sistema,
  -- -------------------------------------------------------
  -- Vínculo B2B principal (empresa mais recente com status ativo)
  -- -------------------------------------------------------
  eu.fk_id_empresa AS empresa_id_principal,
  eu.perfil AS lms_perfil,
  eu.status AS lms_status,
  -- -------------------------------------------------------
  -- perfil_admin: chave usada para buscar em perfil_permissoes
  --   Prioridade: perfil_sistema (escola) > lms_perfil (B2B gestor/admin)
  --   professor B2B também usa 'professor' do tipo_pessoa
  --   colaborador B2B não acessa o painel admin → NULL
  -- -------------------------------------------------------
  COALESCE(
    CASE
      p.fk_id_tipo_pessoa
      WHEN 8 THEN 'super_admin'
      WHEN 5 THEN 'coordenador'
      WHEN 6 THEN 'secretaria'
      WHEN 4 THEN 'professor'
      ELSE NULL
    END,
    CASE
      WHEN eu.perfil IN ('gestor_rh', 'admin_curso') THEN eu.perfil
      ELSE NULL
    END
  ) :: VARCHAR AS perfil_admin,
  -- -------------------------------------------------------
  -- Todas as empresa_ids ativas do usuário (para multi-empresa)
  -- -------------------------------------------------------
  COALESCE(
    (
      SELECT
        ARRAY_AGG(
          eu2.fk_id_empresa
          ORDER BY
            eu2.data_vinculo DESC
        )
      FROM
        lms_empresa_usuarios eu2
      WHERE
        eu2.fk_id_pessoa = p.id
        AND eu2.status = 'ativo'
        AND eu2.deleted_at IS NULL
    ),
    ARRAY [] :: BIGINT []
  ) AS empresa_ids
FROM
  pessoas p
  LEFT JOIN tipo_pessoa tp ON tp.id = p.fk_id_tipo_pessoa
  AND tp.deleted_at IS NULL -- Vínculo B2B ativo mais recente (LATERAL = um registro por pessoa)
  LEFT JOIN LATERAL (
    SELECT
      eu2.fk_id_empresa,
      eu2.perfil,
      eu2.status
    FROM
      lms_empresa_usuarios eu2
    WHERE
      eu2.fk_id_pessoa = p.id
      AND eu2.status = 'ativo'
      AND eu2.deleted_at IS NULL
    ORDER BY
      eu2.data_vinculo DESC
    LIMIT
      1
  ) eu ON TRUE
WHERE
  p.deleted_at IS NULL;

COMMENT ON VIEW vw_usuario_completo IS 'View consolidada de usuário para o painel admin.
   Retorna dados de pessoas + tipo_pessoa + lms_empresa_usuarios em um registro.
   Campos chave:
     perfil_admin  → use como p_perfil em fn_get_permissoes_perfil()
     empresa_ids   → array de empresas B2B ativas do usuário
     lms_perfil    → perfil dentro da empresa principal
   Segurança: RLS das tabelas subjacentes (pessoas, lms_empresa_usuarios) é aplicada.
   Uso: supabase.from(''vw_usuario_completo'').select(''*'').eq(''uid'', userId).single()';

-- ============================================================================
-- 2. RPC fn_get_usuario_completo
--    Alternativa à query direta na view quando se usa SECURITY DEFINER.
--    Útil para evitar exposição da view via REST do PostgREST.
-- ============================================================================
CREATE
OR REPLACE FUNCTION fn_get_usuario_completo(p_uid TEXT) RETURNS TABLE (
  id BIGINT,
  uid TEXT,
  nome TEXT,
  primeiro_nome TEXT,
  sobrenome TEXT,
  email TEXT,
  telefone TEXT,
  data_nascimento TEXT,
  genero TEXT,
  cpf TEXT,
  fk_id_tipo_pessoa INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  tipo_pessoa_descricao TEXT,
  perfil_sistema VARCHAR,
  empresa_id_principal BIGINT,
  lms_perfil VARCHAR,
  lms_status VARCHAR,
  perfil_admin VARCHAR,
  empresa_ids BIGINT []
) LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  id,
  uid,
  nome,
  primeiro_nome,
  sobrenome,
  email,
  telefone,
  data_nascimento,
  genero,
  cpf,
  fk_id_tipo_pessoa,
  created_at,
  updated_at,
  tipo_pessoa_descricao,
  perfil_sistema,
  empresa_id_principal,
  lms_perfil,
  lms_status,
  perfil_admin,
  empresa_ids
FROM
  vw_usuario_completo
WHERE
  uid = p_uid
LIMIT
  1;

$ $;

COMMENT ON FUNCTION fn_get_usuario_completo(TEXT) IS 'Retorna o registro completo do usuário pelo uid do Supabase Auth.
   Use em vez de SELECT direta na view quando precisar de SECURITY DEFINER.
   Exemplo: SELECT * FROM fn_get_usuario_completo(auth.uid()::TEXT);';

-- ============================================================================
-- 3. RPC fn_get_usuario_com_permissoes
--    Carrega dados do usuário + permissões em uma única chamada.
--    Reduz round-trips no UserContext (1 chamada em vez de 2).
-- ============================================================================
CREATE
OR REPLACE FUNCTION fn_get_usuario_com_permissoes(p_uid TEXT) RETURNS JSONB LANGUAGE plpgsql STABLE SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_usuario RECORD;

v_perfil VARCHAR;

v_permissoes JSONB;

BEGIN -- Buscar dados do usuário
SELECT
  * INTO v_usuario
FROM
  vw_usuario_completo
WHERE
  uid = p_uid
LIMIT
  1;

IF NOT FOUND THEN RETURN jsonb_build_object('erro', 'usuario_nao_encontrado');

END IF;

v_perfil := v_usuario.perfil_admin;

-- Buscar permissões do perfil (NULL = sem acesso ao painel)
IF v_perfil IS NOT NULL THEN
SELECT
  jsonb_agg(
    jsonb_build_object(
      'menu_key',
      pp.menu_key,
      'pode_visualizar',
      pp.pode_visualizar,
      'pode_editar',
      pp.pode_editar,
      'pode_excluir',
      pp.pode_excluir
    )
    ORDER BY
      pp.menu_key
  ) INTO v_permissoes
FROM
  perfil_permissoes pp
WHERE
  pp.perfil = v_perfil
  AND pp.pode_visualizar = TRUE;

ELSE v_permissoes := '[]' :: JSONB;

END IF;

RETURN jsonb_build_object(
  'usuario',
  jsonb_build_object(
    'id',
    v_usuario.id,
    'uid',
    v_usuario.uid,
    'nome',
    v_usuario.nome,
    'primeiro_nome',
    v_usuario.primeiro_nome,
    'sobrenome',
    v_usuario.sobrenome,
    'email',
    v_usuario.email,
    'telefone',
    v_usuario.telefone,
    'data_nascimento',
    v_usuario.data_nascimento,
    'genero',
    v_usuario.genero,
    'cpf',
    v_usuario.cpf,
    'fk_id_tipo_pessoa',
    v_usuario.fk_id_tipo_pessoa,
    'tipo_pessoa_descricao',
    v_usuario.tipo_pessoa_descricao,
    'perfil_sistema',
    v_usuario.perfil_sistema,
    'perfil_admin',
    v_usuario.perfil_admin,
    'lms_perfil',
    v_usuario.lms_perfil,
    'empresa_id_principal',
    v_usuario.empresa_id_principal,
    'empresa_ids',
    v_usuario.empresa_ids
  ),
  'permissoes',
  COALESCE(v_permissoes, '[]' :: JSONB)
);

END;

$ $;

COMMENT ON FUNCTION fn_get_usuario_com_permissoes(TEXT) IS 'Retorna usuário completo + permissões do perfil em uma única chamada JSONB.
   Reduz round-trips no UserContext (substitui 2 queries separadas).
   Retorno:
     { usuario: { ...campos }, permissoes: [ { menu_key, pode_visualizar, pode_editar, pode_excluir } ] }
   Exemplo de uso no frontend:
     const { data } = await supabase.rpc("fn_get_usuario_com_permissoes", { p_uid: userId })';

COMMIT;