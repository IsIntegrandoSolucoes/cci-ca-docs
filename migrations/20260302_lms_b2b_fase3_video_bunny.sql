-- =====================================================
-- Migration: LMS B2B - Fase 3: Vídeo Seguro (Bunny.net)
-- Data: 2026-03-02
-- Descrição: Tokens de reprodução com TTL, auditoria de vídeo,
--   progressão sequencial, webhook Bunny.net, renovação de token
-- Convenções: supabase-convencoes (BIGINT, fk_id_*, fn_*, pol_*)
-- =====================================================
-- =====================================================
-- 1. TABELA: video_tokens
-- Tokens temporários de reprodução com TTL
-- =====================================================
CREATE TABLE IF NOT EXISTS video_tokens (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  fk_id_aula BIGINT NOT NULL REFERENCES aulas(id),
  token TEXT NOT NULL UNIQUE,
  expira_em TIMESTAMPTZ NOT NULL,
  ip_address INET,
  user_agent TEXT,
  utilizado BOOLEAN NOT NULL DEFAULT false,
  CONSTRAINT chk_video_tokens_expiracao CHECK (expira_em > created_at)
);

CREATE INDEX IF NOT EXISTS idx_video_tokens_pessoa ON video_tokens(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_video_tokens_aula ON video_tokens(fk_id_aula);

CREATE INDEX IF NOT EXISTS idx_video_tokens_token ON video_tokens(token);

CREATE INDEX IF NOT EXISTS idx_video_tokens_expira ON video_tokens(expira_em)
WHERE
  utilizado = false;

COMMENT ON TABLE video_tokens IS 'Tokens temporários de reprodução de vídeo Bunny.net com TTL';

COMMENT ON COLUMN video_tokens.token IS 'Token hex de 64 caracteres gerado com gen_random_bytes(32)';

COMMENT ON COLUMN video_tokens.expira_em IS 'Timestamp de expiração (created_at + TTL)';

COMMENT ON COLUMN video_tokens.utilizado IS 'Marca se o token já foi consumido para reprodução';

-- RLS
ALTER TABLE
  video_tokens ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  video_tokens FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_video_tokens_select_admin ON video_tokens FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_video_tokens_select_proprio ON video_tokens FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_video_tokens_insert_sistema ON video_tokens FOR
INSERT
  TO authenticated WITH CHECK (
    fk_id_pessoa = fn_get_pessoa_id_from_uid()
    OR fn_is_admin_interno()
  );

CREATE POLICY pol_video_tokens_delete_admin ON video_tokens FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- =====================================================
-- 2. TABELA: auditoria_video
-- Log de reproduções de vídeo
-- =====================================================
CREATE TABLE IF NOT EXISTS auditoria_video (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  fk_id_aula BIGINT NOT NULL REFERENCES aulas(id),
  fk_id_video_token BIGINT REFERENCES video_tokens(id),
  evento TEXT NOT NULL CHECK (
    evento IN (
      'inicio',
      'retomada',
      'token_renovado',
      'token_expirado'
    )
  ),
  bunny_video_id TEXT,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_auditoria_video_pessoa ON auditoria_video(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_auditoria_video_aula ON auditoria_video(fk_id_aula);

CREATE INDEX IF NOT EXISTS idx_auditoria_video_evento ON auditoria_video(evento, created_at);

CREATE INDEX IF NOT EXISTS idx_auditoria_video_bunny ON auditoria_video(bunny_video_id)
WHERE
  bunny_video_id IS NOT NULL;

COMMENT ON TABLE auditoria_video IS 'Auditoria de reproduções de vídeo para telemetria e segurança';

COMMENT ON COLUMN auditoria_video.evento IS 'inicio: primeira vez, retomada: voltou ao vídeo, token_renovado: TTL renovado';

COMMENT ON COLUMN auditoria_video.metadata IS 'Dados extras: posição do vídeo, resolução, etc';

-- RLS
ALTER TABLE
  auditoria_video ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  auditoria_video FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_auditoria_video_select_admin ON auditoria_video FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_auditoria_video_select_professor ON auditoria_video FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
        JOIN cursos c ON c.id = m.fk_id_curso
      WHERE
        a.id = auditoria_video.fk_id_aula
        AND c.fk_id_professor = fn_get_pessoa_id_from_uid()
    )
  );

CREATE POLICY pol_auditoria_video_select_gestor ON auditoria_video FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        empresa_usuarios eu
      WHERE
        eu.fk_id_pessoa = auditoria_video.fk_id_pessoa
        AND eu.fk_id_empresa = fn_get_empresa_id_do_usuario()
        AND fn_is_gestor_rh_da_empresa(eu.fk_id_empresa)
    )
  );

CREATE POLICY pol_auditoria_video_select_proprio ON auditoria_video FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_auditoria_video_insert_sistema ON auditoria_video FOR
INSERT
  TO authenticated WITH CHECK (
    fk_id_pessoa = fn_get_pessoa_id_from_uid()
    OR fn_is_admin_interno()
  );

CREATE POLICY pol_auditoria_video_delete_admin ON auditoria_video FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- =====================================================
-- 3. RPC: Iniciar aula (progressão sequencial + token vídeo)
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_iniciar_aula(
  p_aula_id BIGINT,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_aula RECORD;

v_modulo_id BIGINT;

v_curso_id BIGINT;

v_matriculado BOOLEAN;

v_aula_anterior_concluida BOOLEAN := TRUE;

v_empresa_ativa BOOLEAN;

v_empresa_id BIGINT;

v_token TEXT;

v_token_id BIGINT;

v_ttl_segundos INTEGER := 3600;

-- 1 hora
v_evento TEXT;

BEGIN v_pessoa_id := fn_get_pessoa_id_from_uid();

IF v_pessoa_id IS NULL THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'sem_pessoa',
  'mensagem',
  'Usuário não encontrado.'
);

END IF;

-- Obter dados da aula com módulo e curso
SELECT
  a.*,
  m.fk_id_curso,
  m.id AS modulo_id_val INTO v_aula
FROM
  aulas a
  JOIN modulos m ON m.id = a.fk_id_modulo
WHERE
  a.id = p_aula_id
  AND a.deleted_at IS NULL;

IF NOT FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'aula_nao_encontrada',
  'mensagem',
  'Aula não encontrada.'
);

END IF;

v_modulo_id := v_aula.modulo_id_val;

v_curso_id := v_aula.fk_id_curso;

-- Verificar matrícula ativa
SELECT
  EXISTS (
    SELECT
      1
    FROM
      usuario_curso
    WHERE
      fk_id_pessoa = v_pessoa_id
      AND fk_id_curso = v_curso_id
      AND STATUS NOT IN ('bloqueado', 'expirado')
      AND deleted_at IS NULL
  ) INTO v_matriculado;

IF NOT v_matriculado THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'sem_matricula',
  'mensagem',
  'Você não está matriculado neste curso.'
);

END IF;

-- Obter empresa e validar status
SELECT
  fk_id_empresa INTO v_empresa_id
FROM
  usuario_curso
WHERE
  fk_id_pessoa = v_pessoa_id
  AND fk_id_curso = v_curso_id
  AND deleted_at IS NULL;

v_empresa_ativa := fn_empresa_status_ativo(v_empresa_id);

IF NOT v_empresa_ativa THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'empresa_inativa',
  'mensagem',
  'Acesso encerrado pelo contrato da empresa.'
);

END IF;

-- Validar progressão sequencial (aula anterior deve estar concluída)
IF v_aula.ordem > 1 THEN
SELECT
  COALESCE(
    (
      SELECT
        uap.concluida
      FROM
        aulas a_anterior
        LEFT JOIN usuario_aula_progresso uap ON uap.fk_id_aula = a_anterior.id
        AND uap.fk_id_pessoa = v_pessoa_id
      WHERE
        a_anterior.fk_id_modulo = v_modulo_id
        AND a_anterior.ordem = v_aula.ordem - 1
        AND a_anterior.deleted_at IS NULL
      LIMIT
        1
    ), false
  ) INTO v_aula_anterior_concluida;

IF NOT v_aula_anterior_concluida THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'aula_bloqueada',
  'mensagem',
  'Complete a aula anterior para desbloquear esta.'
);

END IF;

END IF;

-- Determinar evento de auditoria
IF EXISTS (
  SELECT
    1
  FROM
    usuario_aula_progresso
  WHERE
    fk_id_pessoa = v_pessoa_id
    AND fk_id_aula = p_aula_id
    AND data_inicio IS NOT NULL
) THEN v_evento := 'retomada';

ELSE v_evento := 'inicio';

END IF;

-- Criar ou atualizar progresso
INSERT INTO
  usuario_aula_progresso (
    fk_id_pessoa,
    fk_id_aula,
    data_inicio
  )
VALUES
  (
    v_pessoa_id,
    p_aula_id,
    NOW()
  ) ON CONFLICT (fk_id_pessoa, fk_id_aula) DO
UPDATE
SET
  data_inicio = COALESCE(usuario_aula_progresso.data_inicio, NOW()),
  tentativas = usuario_aula_progresso.tentativas + 1,
  updated_at = NOW();

-- Atualizar status do curso para 'em_andamento' se estava apenas matriculado
UPDATE
  usuario_curso
SET
  STATUS = 'em_andamento',
  data_inicio = COALESCE(data_inicio, NOW()),
  updated_at = NOW()
WHERE
  fk_id_pessoa = v_pessoa_id
  AND fk_id_curso = v_curso_id
  AND STATUS = 'matriculado'
  AND deleted_at IS NULL;

-- Se for vídeo, gerar token de reprodução
IF v_aula.tipo_conteudo = 'video'
AND v_aula.bunny_video_id IS NOT NULL THEN v_token := encode(gen_random_bytes(32), 'hex');

INSERT INTO
  video_tokens (
    fk_id_pessoa,
    fk_id_aula,
    token,
    expira_em,
    ip_address,
    user_agent
  )
VALUES
  (
    v_pessoa_id,
    p_aula_id,
    v_token,
    NOW() + (v_ttl_segundos || ' seconds') :: INTERVAL,
    p_ip_address,
    p_user_agent
  ) RETURNING id INTO v_token_id;

-- Auditoria
INSERT INTO
  auditoria_video (
    fk_id_pessoa,
    fk_id_aula,
    fk_id_video_token,
    evento,
    bunny_video_id,
    ip_address,
    user_agent,
    metadata
  )
VALUES
  (
    v_pessoa_id,
    p_aula_id,
    v_token_id,
    v_evento,
    v_aula.bunny_video_id,
    p_ip_address,
    p_user_agent,
    jsonb_build_object(
      'ttl_segundos',
      v_ttl_segundos,
      'bunny_library_id',
      v_aula.bunny_library_id,
      'duracao_segundos',
      v_aula.duracao_segundos
    )
  );

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'tipo',
  'video',
  'video_token',
  v_token,
  'bunny_video_id',
  v_aula.bunny_video_id,
  'bunny_library_id',
  v_aula.bunny_library_id,
  'duracao_segundos',
  v_aula.duracao_segundos,
  'ttl_segundos',
  v_ttl_segundos,
  'token_expira_em',
  (NOW() + (v_ttl_segundos || ' seconds') :: INTERVAL)
);

ELSE -- Conteúdo não-vídeo (pdf, link, texto)
RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'tipo',
  v_aula.tipo_conteudo,
  'conteudo_url',
  v_aula.conteudo_url,
  'conteudo_texto',
  v_aula.conteudo_texto
);

END IF;

END;

$ $;

COMMENT ON FUNCTION fn_iniciar_aula(BIGINT, INET, TEXT) IS 'Inicia aula com progressão sequencial. Gera token Bunny.net para vídeo (TTL 1h)';

-- =====================================================
-- 4. RPC: Renovar token de vídeo
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_renovar_token_video(
  p_token_atual TEXT,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_token_atual RECORD;

v_novo_token TEXT;

v_novo_token_id BIGINT;

v_ttl_segundos INTEGER := 3600;

v_aula RECORD;

BEGIN v_pessoa_id := fn_get_pessoa_id_from_uid();

IF v_pessoa_id IS NULL THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'sem_pessoa',
  'mensagem',
  'Usuário não encontrado.'
);

END IF;

-- Buscar token atual
SELECT
  vt.*,
  a.bunny_video_id,
  a.bunny_library_id,
  a.duracao_segundos INTO v_token_atual
FROM
  video_tokens vt
  JOIN aulas a ON a.id = vt.fk_id_aula
WHERE
  vt.token = p_token_atual
  AND vt.fk_id_pessoa = v_pessoa_id;

IF NOT FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'token_nao_encontrado',
  'mensagem',
  'Token não encontrado ou não pertence ao usuário.'
);

END IF;

-- Permitir renovação até 30 minutos após expiração (janela de graça)
IF v_token_atual.expira_em < NOW() - INTERVAL '30 minutes' THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'token_expirado_definitivo',
  'mensagem',
  'Token expirado há mais de 30 minutos. Reinicie a aula.'
);

END IF;

-- Marcar token atual como utilizado
UPDATE
  video_tokens
SET
  utilizado = TRUE
WHERE
  id = v_token_atual.id;

-- Gerar novo token
v_novo_token := encode(gen_random_bytes(32), 'hex');

INSERT INTO
  video_tokens (
    fk_id_pessoa,
    fk_id_aula,
    token,
    expira_em,
    ip_address,
    user_agent
  )
VALUES
  (
    v_pessoa_id,
    v_token_atual.fk_id_aula,
    v_novo_token,
    NOW() + (v_ttl_segundos || ' seconds') :: INTERVAL,
    p_ip_address,
    p_user_agent
  ) RETURNING id INTO v_novo_token_id;

-- Auditoria
INSERT INTO
  auditoria_video (
    fk_id_pessoa,
    fk_id_aula,
    fk_id_video_token,
    evento,
    bunny_video_id,
    ip_address,
    user_agent,
    metadata
  )
VALUES
  (
    v_pessoa_id,
    v_token_atual.fk_id_aula,
    v_novo_token_id,
    'token_renovado',
    v_token_atual.bunny_video_id,
    p_ip_address,
    p_user_agent,
    jsonb_build_object(
      'token_anterior_id',
      v_token_atual.id,
      'ttl_segundos',
      v_ttl_segundos
    )
  );

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'video_token',
  v_novo_token,
  'bunny_video_id',
  v_token_atual.bunny_video_id,
  'bunny_library_id',
  v_token_atual.bunny_library_id,
  'duracao_segundos',
  v_token_atual.duracao_segundos,
  'ttl_segundos',
  v_ttl_segundos,
  'token_expira_em',
  (NOW() + (v_ttl_segundos || ' seconds') :: INTERVAL)
);

END;

$ $;

COMMENT ON FUNCTION fn_renovar_token_video(TEXT, INET, TEXT) IS 'Renova token de vídeo expirado (janela de graça de 30 min). Invalida o anterior';

-- =====================================================
-- 5. RPC: Obter próxima aula disponível
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_obter_proxima_aula(p_curso_id BIGINT) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_proxima_aula RECORD;

BEGIN v_pessoa_id := fn_get_pessoa_id_from_uid();

IF v_pessoa_id IS NULL THEN RETURN jsonb_build_object('sucesso', false, 'erro', 'sem_pessoa');

END IF;

-- Buscar primeira aula não concluída (order by módulo.ordem, aula.ordem)
SELECT
  a.id,
  a.titulo,
  a.tipo_conteudo,
  a.ordem AS aula_ordem,
  m.titulo AS modulo_titulo,
  m.ordem AS modulo_ordem INTO v_proxima_aula
FROM
  aulas a
  JOIN modulos m ON m.id = a.fk_id_modulo
  LEFT JOIN usuario_aula_progresso uap ON uap.fk_id_aula = a.id
  AND uap.fk_id_pessoa = v_pessoa_id
WHERE
  m.fk_id_curso = p_curso_id
  AND a.deleted_at IS NULL
  AND m.deleted_at IS NULL
  AND (
    uap.concluida IS NULL
    OR uap.concluida = false
  )
ORDER BY
  m.ordem,
  a.ordem
LIMIT
  1;

IF FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'aula_id',
  v_proxima_aula.id,
  'titulo',
  v_proxima_aula.titulo,
  'modulo',
  v_proxima_aula.modulo_titulo,
  'tipo',
  v_proxima_aula.tipo_conteudo,
  'modulo_ordem',
  v_proxima_aula.modulo_ordem,
  'aula_ordem',
  v_proxima_aula.aula_ordem
);

ELSE RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'mensagem',
  'Curso concluído.',
  'aula_id',
  NULL
);

END IF;

END;

$ $;

COMMENT ON FUNCTION fn_obter_proxima_aula(BIGINT) IS 'Retorna a próxima aula não concluída do curso, respeitando ordem de módulos e aulas';

-- =====================================================
-- 6. RPC: Processar webhook do Bunny.net
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_processar_webhook_bunny(
  p_video_id TEXT,
  p_status TEXT,
  p_metadata JSONB DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_status_valido TEXT;

v_aulas_atualizadas INTEGER;

BEGIN -- Mapear status do Bunny para status interno
v_status_valido := CASE
  p_status
  WHEN 'finished' THEN 'ready'
  WHEN 'ready' THEN 'ready'
  WHEN 'processing' THEN 'processing'
  WHEN 'encoding' THEN 'processing'
  WHEN 'failed' THEN 'failed'
  WHEN 'error' THEN 'failed'
  ELSE NULL
END;

IF v_status_valido IS NULL THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'status_invalido',
  'mensagem',
  'Status do Bunny não reconhecido: ' || p_status
);

END IF;

-- Atualizar todas as aulas que referenciam este vídeo
UPDATE
  aulas
SET
  bunny_status = v_status_valido,
  duracao_segundos = COALESCE(
    (p_metadata ->> 'length') :: INTEGER,
    duracao_segundos
  ),
  updated_at = NOW()
WHERE
  bunny_video_id = p_video_id
  AND deleted_at IS NULL;

GET DIAGNOSTICS v_aulas_atualizadas = ROW_COUNT;

IF v_aulas_atualizadas = 0 THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'video_nao_encontrado',
  'mensagem',
  'Nenhuma aula encontrada com bunny_video_id: ' || p_video_id
);

END IF;

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'mensagem',
  'Status atualizado para ' || v_status_valido,
  'aulas_atualizadas',
  v_aulas_atualizadas
);

END;

$ $;

COMMENT ON FUNCTION fn_processar_webhook_bunny(TEXT, TEXT, JSONB) IS 'Processa webhook do Bunny.net atualizando status de processamento do vídeo nas aulas';

-- =====================================================
-- 7. Job: Limpar tokens de vídeo expirados
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_limpar_tokens_expirados() RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_removidos INTEGER;

BEGIN -- Remove tokens expirados há mais de 24h (manter recentes para auditoria)
DELETE FROM
  video_tokens
WHERE
  expira_em < NOW() - INTERVAL '24 hours';

GET DIAGNOSTICS v_removidos = ROW_COUNT;

RETURN v_removidos;

END;

$ $;

COMMENT ON FUNCTION fn_limpar_tokens_expirados() IS 'Remove tokens de vídeo expirados há mais de 24h. Executar via pg_cron ou edge function';