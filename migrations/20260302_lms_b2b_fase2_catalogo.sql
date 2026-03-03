-- =====================================================
-- Migration: LMS B2B - Fase 1 RPCs + Fase 2 Catálogo
-- Data: 2026-03-02
-- Descrição: RPCs sessões + catálogo LMS + matrícula + progresso
-- Convenções: supabase-convencoes (BIGINT, fk_id_*, fn_*, tr_*)
-- =====================================================
-- =====================================================
-- 1. RPCs TRANSACIONAIS - Controle de Sessões
-- =====================================================
-- RPC: Validar e registrar acesso simultâneo
CREATE
OR REPLACE FUNCTION fn_validar_acesso_simultaneo(
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

v_empresa_ativa BOOLEAN;

BEGIN -- Obter empresa do usuário
SELECT
  eu.fk_id_empresa INTO v_empresa_id
FROM
  lms_empresa_usuarios eu
WHERE
  eu.fk_id_pessoa = p_pessoa_id
  AND eu.status = 'ativo'
  AND eu.deleted_at IS NULL
LIMIT
  1;

IF v_empresa_id IS NULL THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'sem_empresa',
  'mensagem',
  'Usuário não está vinculado a nenhuma empresa.'
);

END IF;

-- Validar status da empresa
v_empresa_ativa := fn_empresa_status_ativo(v_empresa_id);

IF NOT v_empresa_ativa THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'empresa_inativa',
  'mensagem',
  'Acesso encerrado. Empresa suspensa ou contrato expirado.'
);

END IF;

-- Obter limite de usuários simultâneos
SELECT
  e.limite_usuarios_simultaneos INTO v_limite_simultaneo
FROM
  lms_empresas e
WHERE
  e.id = v_empresa_id;

-- Limpar sessões expiradas (> 5 minutos sem heartbeat)
DELETE FROM
  lms_sessoes_ativas
WHERE
  fk_id_empresa = v_empresa_id
  AND ultimo_heartbeat < NOW() - INTERVAL '5 minutes';

-- Contar sessões ativas atuais
SELECT
  COUNT(*) INTO v_sessoes_ativas
FROM
  lms_sessoes_ativas
WHERE
  fk_id_empresa = v_empresa_id;

-- Verificar se usuário já tem sessão ativa neste curso
IF EXISTS (
  SELECT
    1
  FROM
    lms_sessoes_ativas
  WHERE
    fk_id_pessoa = p_pessoa_id
    AND fk_id_curso = p_curso_id
) THEN -- Atualizar heartbeat da sessão existente
UPDATE
  lms_sessoes_ativas
SET
  ultimo_heartbeat = NOW()
WHERE
  fk_id_pessoa = p_pessoa_id
  AND fk_id_curso = p_curso_id;

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'mensagem',
  'Sessão ativa renovada.',
  'sessoes_ativas',
  v_sessoes_ativas,
  'limite',
  v_limite_simultaneo
);

END IF;

-- Validar limite de sessões simultâneas
IF v_sessoes_ativas >= v_limite_simultaneo THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'limite_atingido',
  'mensagem',
  'Limite de acessos simultâneos atingido. Aguarde ou contate o administrador.',
  'sessoes_ativas',
  v_sessoes_ativas,
  'limite',
  v_limite_simultaneo
);

END IF;

-- Criar nova sessão
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
  );

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'mensagem',
  'Acesso liberado.',
  'sessoes_ativas',
  v_sessoes_ativas + 1,
  'limite',
  v_limite_simultaneo
);

END;

$ $;

COMMENT ON FUNCTION fn_validar_acesso_simultaneo(BIGINT, BIGINT, TEXT, INET, TEXT) IS 'Valida e registra acesso simultâneo ao curso, respeitando limite da empresa';

-- RPC: Encerrar sessão ativa (logout)
CREATE
OR REPLACE FUNCTION fn_encerrar_sessao(p_session_token TEXT) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ BEGIN
DELETE FROM
  lms_sessoes_ativas
WHERE
  session_token = p_session_token;

IF FOUND THEN RETURN jsonb_build_object('sucesso', TRUE, 'mensagem', 'Sessão encerrada.');

ELSE RETURN jsonb_build_object(
  'sucesso',
  false,
  'mensagem',
  'Sessão não encontrada.'
);

END IF;

END;

$ $;

COMMENT ON FUNCTION fn_encerrar_sessao(TEXT) IS 'Encerra sessão ativa por token (logout)';

-- RPC: Heartbeat para manter sessão viva
CREATE
OR REPLACE FUNCTION fn_heartbeat_sessao(p_session_token TEXT) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ BEGIN
UPDATE
  sessoes_ativas
SET
  ultimo_heartbeat = NOW()
WHERE
  session_token = p_session_token;

IF FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'mensagem',
  'Heartbeat registrado.'
);

ELSE RETURN jsonb_build_object(
  'sucesso',
  false,
  'mensagem',
  'Sessão não encontrada ou expirada.'
);

END IF;

END;

$ $;

COMMENT ON FUNCTION fn_heartbeat_sessao(TEXT) IS 'Atualiza heartbeat da sessão. Chamar a cada 30s do frontend';

-- Job: Limpar sessões expiradas (> 5 min sem heartbeat)
CREATE
OR REPLACE FUNCTION fn_limpar_sessoes_expiradas() RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_removidas INTEGER;

BEGIN
DELETE FROM
  sessoes_ativas
WHERE
  ultimo_heartbeat < NOW() - INTERVAL '5 minutes';

GET DIAGNOSTICS v_removidas = ROW_COUNT;

RETURN v_removidas;

END;

$ $;

COMMENT ON FUNCTION fn_limpar_sessoes_expiradas() IS 'Remove sessões com heartbeat > 5 min. Executar via pg_cron ou edge function periódica';

-- =====================================================
-- 2. TABELAS DO CATÁLOGO LMS (Fase 2)
-- =====================================================
-- Tabela: cursos
CREATE TABLE IF NOT EXISTS cursos (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_professor BIGINT REFERENCES pessoas(id),
  titulo TEXT NOT NULL,
  descricao TEXT,
  capa_url TEXT,
  carga_horaria INTEGER,
  publico TEXT NOT NULL DEFAULT 'b2b' CHECK (publico IN ('b2b', 'b2c', 'ambos')),
  nivel TEXT CHECK (
    nivel IN ('iniciante', 'intermediario', 'avancado')
  ),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_cursos_professor ON cursos(fk_id_professor)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_cursos_publico ON cursos(publico, ativo)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_cursos_ativo ON cursos(ativo)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE cursos IS 'Catálogo de cursos LMS (online)';

COMMENT ON COLUMN cursos.fk_id_professor IS 'Pessoa com tipo_pessoa = 4 (Professor)';

COMMENT ON COLUMN cursos.publico IS 'b2b: empresas, b2c: alunos diretos, ambos: todos';

COMMENT ON COLUMN cursos.carga_horaria IS 'Duração total em minutos';

-- Tabela: modulos
CREATE TABLE IF NOT EXISTS modulos (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_curso BIGINT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  descricao TEXT,
  ordem INTEGER NOT NULL,
  duracao_estimada INTEGER,
  CONSTRAINT unq_modulos_curso_ordem UNIQUE (fk_id_curso, ordem)
);

CREATE INDEX IF NOT EXISTS idx_modulos_curso ON modulos(fk_id_curso, ordem)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE modulos IS 'Módulos de curso (agrupamento de aulas)';

COMMENT ON COLUMN modulos.ordem IS 'Ordem sequencial dentro do curso';

-- Tabela: aulas
CREATE TABLE IF NOT EXISTS aulas (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_modulo BIGINT NOT NULL REFERENCES modulos(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  descricao TEXT,
  ordem INTEGER NOT NULL,
  tipo_conteudo TEXT NOT NULL CHECK (
    tipo_conteudo IN ('video', 'pdf', 'link', 'texto')
  ),
  bunny_video_id TEXT,
  bunny_library_id TEXT,
  bunny_status TEXT CHECK (
    bunny_status IN ('processing', 'ready', 'failed')
  ),
  duracao_segundos INTEGER,
  conteudo_url TEXT,
  conteudo_texto TEXT,
  obrigatoria BOOLEAN NOT NULL DEFAULT TRUE,
  janela_acesso_dias INTEGER,
  CONSTRAINT unq_aulas_modulo_ordem UNIQUE (fk_id_modulo, ordem)
);

CREATE INDEX IF NOT EXISTS idx_aulas_modulo ON aulas(fk_id_modulo, ordem)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_aulas_bunny ON aulas(bunny_video_id)
WHERE
  bunny_video_id IS NOT NULL;

COMMENT ON TABLE aulas IS 'Aulas individuais com conteúdo';

COMMENT ON COLUMN aulas.ordem IS 'Sequência obrigatória: aula N+1 só libera após concluir N';

COMMENT ON COLUMN aulas.bunny_video_id IS 'ID do vídeo no Bunny.net (não expor URL direta)';

COMMENT ON COLUMN aulas.janela_acesso_dias IS 'Dias após matrícula para expirar. NULL = sem limite';

-- Vincular FK de cursos em sessoes_ativas
ALTER TABLE
  lms_sessoes_ativas
ADD
  CONSTRAINT fk_lms_sessoes_ativas_curso FOREIGN KEY (fk_id_curso) REFERENCES cursos(id);

-- =====================================================
-- 3. TABELAS DE MATRÍCULA E PROGRESSO
-- =====================================================
-- Tabela: usuario_curso (matrícula)
CREATE TABLE IF NOT EXISTS usuario_curso (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_empresa BIGINT NOT NULL REFERENCES lms_empresas(id),
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  fk_id_curso BIGINT NOT NULL REFERENCES cursos(id),
  STATUS TEXT NOT NULL DEFAULT 'matriculado' CHECK (
    STATUS IN (
      'matriculado',
      'em_andamento',
      'concluido',
      'bloqueado',
      'expirado'
    )
  ),
  progresso_percentual DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  data_matricula TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data_inicio TIMESTAMPTZ,
  data_conclusao TIMESTAMPTZ,
  nota_final DECIMAL(5, 2),
  observacoes TEXT,
  CONSTRAINT unq_usuario_curso_pessoa_curso UNIQUE (fk_id_pessoa, fk_id_curso)
);

CREATE INDEX IF NOT EXISTS idx_usuario_curso_pessoa ON usuario_curso(fk_id_pessoa)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_usuario_curso_empresa ON usuario_curso(fk_id_empresa)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_usuario_curso_curso ON usuario_curso(fk_id_curso)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_usuario_curso_status ON usuario_curso(STATUS)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE usuario_curso IS 'Matrícula do usuário no curso LMS';

COMMENT ON COLUMN usuario_curso.status IS 'matriculado → em_andamento → concluido | bloqueado | expirado';

-- Tabela: usuario_aula_progresso
CREATE TABLE IF NOT EXISTS usuario_aula_progresso (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id),
  fk_id_aula BIGINT NOT NULL REFERENCES aulas(id),
  percentual_assistido DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  ultima_posicao_segundos INTEGER NOT NULL DEFAULT 0,
  concluida BOOLEAN NOT NULL DEFAULT false,
  data_inicio TIMESTAMPTZ,
  data_conclusao TIMESTAMPTZ,
  tentativas INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT unq_usuario_aula_progresso_pessoa_aula UNIQUE (fk_id_pessoa, fk_id_aula)
);

CREATE INDEX IF NOT EXISTS idx_progresso_pessoa ON usuario_aula_progresso(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_progresso_aula ON usuario_aula_progresso(fk_id_aula);

CREATE INDEX IF NOT EXISTS idx_progresso_concluida ON usuario_aula_progresso(concluida)
WHERE
  concluida = TRUE;

COMMENT ON TABLE usuario_aula_progresso IS 'Progresso individual por aula';

COMMENT ON COLUMN usuario_aula_progresso.ultima_posicao_segundos IS 'Última posição do vídeo para retomar';

-- =====================================================
-- 4. FUNÇÕES AUXILIARES (Fase 2)
-- =====================================================
-- Verifica se o usuário é professor do curso
CREATE
OR REPLACE FUNCTION fn_is_professor_do_curso(p_curso_id BIGINT) RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
SET
  search_path = public AS $ $
SELECT
  EXISTS (
    SELECT
      1
    FROM
      cursos
    WHERE
      id = p_curso_id
      AND fk_id_professor = fn_get_pessoa_id_from_uid()
      AND deleted_at IS NULL
  );

$ $;

COMMENT ON FUNCTION fn_is_professor_do_curso(BIGINT) IS 'Verifica se o usuário autenticado é professor do curso';

-- Verifica se o usuário é professor (tipo_pessoa = 4)
CREATE
OR REPLACE FUNCTION fn_is_professor() RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER
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

COMMENT ON FUNCTION fn_is_professor() IS 'Verifica se o usuário autenticado é professor';

-- =====================================================
-- 5. POLÍTICAS RLS (Fase 2)
-- =====================================================
-- ----- TABELA: cursos -----
ALTER TABLE
  cursos ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  cursos FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_cursos_select_admin ON cursos FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_cursos_select_professor ON cursos FOR
SELECT
  TO authenticated USING (fk_id_professor = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_cursos_select_matriculado ON cursos FOR
SELECT
  TO authenticated USING (
    ativo = TRUE
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT
        1
      FROM
        usuario_curso uc
      WHERE
        uc.fk_id_curso = cursos.id
        AND uc.fk_id_pessoa = fn_get_pessoa_id_from_uid()
        AND uc.deleted_at IS NULL
    )
  );

CREATE POLICY pol_cursos_insert_professor ON cursos FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR fn_is_professor()
  );

CREATE POLICY pol_cursos_update_admin ON cursos FOR
UPDATE
  TO authenticated USING (fn_is_admin_interno()) WITH CHECK (fn_is_admin_interno());

CREATE POLICY pol_cursos_update_professor ON cursos FOR
UPDATE
  TO authenticated USING (fk_id_professor = fn_get_pessoa_id_from_uid()) WITH CHECK (fk_id_professor = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_cursos_delete_admin ON cursos FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- ----- TABELA: modulos -----
ALTER TABLE
  modulos ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  modulos FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_modulos_select_admin ON modulos FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_modulos_select_professor ON modulos FOR
SELECT
  TO authenticated USING (fn_is_professor_do_curso(fk_id_curso));

CREATE POLICY pol_modulos_select_matriculado ON modulos FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        usuario_curso uc
      WHERE
        uc.fk_id_curso = modulos.fk_id_curso
        AND uc.fk_id_pessoa = fn_get_pessoa_id_from_uid()
        AND uc.deleted_at IS NULL
    )
  );

CREATE POLICY pol_modulos_insert ON modulos FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR fn_is_professor_do_curso(fk_id_curso)
  );

CREATE POLICY pol_modulos_update ON modulos FOR
UPDATE
  TO authenticated USING (
    fn_is_admin_interno()
    OR fn_is_professor_do_curso(fk_id_curso)
  ) WITH CHECK (
    fn_is_admin_interno()
    OR fn_is_professor_do_curso(fk_id_curso)
  );

CREATE POLICY pol_modulos_delete_admin ON modulos FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- ----- TABELA: aulas -----
ALTER TABLE
  aulas ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  aulas FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_aulas_select_admin ON aulas FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_aulas_select_professor ON aulas FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        modulos m
        JOIN cursos c ON c.id = m.fk_id_curso
      WHERE
        m.id = aulas.fk_id_modulo
        AND c.fk_id_professor = fn_get_pessoa_id_from_uid()
    )
  );

CREATE POLICY pol_aulas_select_matriculado ON aulas FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        modulos m
        JOIN usuario_curso uc ON uc.fk_id_curso = m.fk_id_curso
      WHERE
        m.id = aulas.fk_id_modulo
        AND uc.fk_id_pessoa = fn_get_pessoa_id_from_uid()
        AND uc.deleted_at IS NULL
    )
  );

CREATE POLICY pol_aulas_insert ON aulas FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        modulos m
        JOIN cursos c ON c.id = m.fk_id_curso
      WHERE
        m.id = aulas.fk_id_modulo
        AND c.fk_id_professor = fn_get_pessoa_id_from_uid()
    )
  );

CREATE POLICY pol_aulas_update ON aulas FOR
UPDATE
  TO authenticated USING (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        modulos m
        JOIN cursos c ON c.id = m.fk_id_curso
      WHERE
        m.id = aulas.fk_id_modulo
        AND c.fk_id_professor = fn_get_pessoa_id_from_uid()
    )
  ) WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        modulos m
        JOIN cursos c ON c.id = m.fk_id_curso
      WHERE
        m.id = aulas.fk_id_modulo
        AND c.fk_id_professor = fn_get_pessoa_id_from_uid()
    )
  );

CREATE POLICY pol_aulas_delete_admin ON aulas FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- ----- TABELA: usuario_curso -----
ALTER TABLE
  usuario_curso ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  usuario_curso FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_usuario_curso_select_admin ON usuario_curso FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_usuario_curso_select_gestor ON usuario_curso FOR
SELECT
  TO authenticated USING (
    fk_id_empresa = fn_get_empresa_id_do_usuario()
    AND fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

CREATE POLICY pol_usuario_curso_select_professor ON usuario_curso FOR
SELECT
  TO authenticated USING (fn_is_professor_do_curso(fk_id_curso));

CREATE POLICY pol_usuario_curso_select_proprio ON usuario_curso FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_usuario_curso_insert_gestores ON usuario_curso FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

CREATE POLICY pol_usuario_curso_update_admin ON usuario_curso FOR
UPDATE
  TO authenticated USING (fn_is_admin_interno()) WITH CHECK (fn_is_admin_interno());

CREATE POLICY pol_usuario_curso_delete_admin ON usuario_curso FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- ----- TABELA: usuario_aula_progresso -----
ALTER TABLE
  usuario_aula_progresso ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  usuario_aula_progresso FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_progresso_select_admin ON usuario_aula_progresso FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_progresso_select_professor ON usuario_aula_progresso FOR
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
        a.id = usuario_aula_progresso.fk_id_aula
        AND c.fk_id_professor = fn_get_pessoa_id_from_uid()
    )
  );

CREATE POLICY pol_progresso_select_gestor ON usuario_aula_progresso FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        empresa_usuarios eu
      WHERE
        eu.fk_id_pessoa = usuario_aula_progresso.fk_id_pessoa
        AND eu.fk_id_empresa = fn_get_empresa_id_do_usuario()
        AND fn_is_gestor_rh_da_empresa(eu.fk_id_empresa)
    )
  );

CREATE POLICY pol_progresso_select_proprio ON usuario_aula_progresso FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_progresso_insert_proprio ON usuario_aula_progresso FOR
INSERT
  TO authenticated WITH CHECK (
    fk_id_pessoa = fn_get_pessoa_id_from_uid()
    OR fn_is_admin_interno()
  );

CREATE POLICY pol_progresso_update_proprio ON usuario_aula_progresso FOR
UPDATE
  TO authenticated USING (
    fk_id_pessoa = fn_get_pessoa_id_from_uid()
    OR fn_is_admin_interno()
  ) WITH CHECK (
    fk_id_pessoa = fn_get_pessoa_id_from_uid()
    OR fn_is_admin_interno()
  );

CREATE POLICY pol_progresso_delete_admin ON usuario_aula_progresso FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- =====================================================
-- 6. RPC MATRÍCULA
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_matricular_usuario_no_curso(
  p_empresa_id BIGINT,
  p_pessoa_id BIGINT,
  p_curso_id BIGINT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_empresa_ativa BOOLEAN;

v_ja_matriculado BOOLEAN;

BEGIN -- Validar empresa ativa
v_empresa_ativa := fn_empresa_status_ativo(p_empresa_id);

IF NOT v_empresa_ativa THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'empresa_inativa',
  'mensagem',
  'Empresa suspensa ou contrato expirado.'
);

END IF;

-- Verificar vínculo da pessoa com a empresa
IF NOT EXISTS (
  SELECT
    1
  FROM
    empresa_usuarios
  WHERE
    fk_id_empresa = p_empresa_id
    AND fk_id_pessoa = p_pessoa_id
    AND ativo = TRUE
    AND deleted_at IS NULL
) THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'sem_vinculo',
  'mensagem',
  'Usuário não está vinculado a esta empresa.'
);

END IF;

-- Verificar curso ativo
IF NOT EXISTS (
  SELECT
    1
  FROM
    cursos
  WHERE
    id = p_curso_id
    AND ativo = TRUE
    AND deleted_at IS NULL
) THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'curso_inativo',
  'mensagem',
  'Curso não encontrado ou inativo.'
);

END IF;

-- Verificar matrícula existente
SELECT
  EXISTS (
    SELECT
      1
    FROM
      usuario_curso
    WHERE
      fk_id_pessoa = p_pessoa_id
      AND fk_id_curso = p_curso_id
      AND deleted_at IS NULL
  ) INTO v_ja_matriculado;

IF v_ja_matriculado THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'ja_matriculado',
  'mensagem',
  'Usuário já está matriculado neste curso.'
);

END IF;

-- Criar matrícula (sem consumir licença — controle é por sessões)
INSERT INTO
  usuario_curso (
    fk_id_empresa,
    fk_id_pessoa,
    fk_id_curso,
    STATUS,
    data_matricula,
    created_by
  )
VALUES
  (
    p_empresa_id,
    p_pessoa_id,
    p_curso_id,
    'matriculado',
    NOW(),
    fn_get_pessoa_id_from_uid()
  );

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'mensagem',
  'Matrícula realizada com sucesso.'
);

END;

$ $;

COMMENT ON FUNCTION fn_matricular_usuario_no_curso(BIGINT, BIGINT, BIGINT) IS 'Matricula usuário no curso (sem consumo de licença)';

-- =====================================================
-- 7. TRIGGER - Progresso automático
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_trg_atualizar_progresso_curso() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_curso_id BIGINT;

v_total_aulas INTEGER;

v_concluidas INTEGER;

v_percentual DECIMAL(5, 2);

BEGIN -- Obter curso_id via aula → módulo → curso
SELECT
  c.id INTO v_curso_id
FROM
  aulas a
  JOIN modulos m ON m.id = a.fk_id_modulo
  JOIN cursos c ON c.id = m.fk_id_curso
WHERE
  a.id = NEW.fk_id_aula;

IF v_curso_id IS NULL THEN RETURN NEW;

END IF;

-- Contar total de aulas obrigatórias do curso
SELECT
  COUNT(*) INTO v_total_aulas
FROM
  aulas a
  JOIN modulos m ON m.id = a.fk_id_modulo
WHERE
  m.fk_id_curso = v_curso_id
  AND a.obrigatoria = TRUE
  AND a.deleted_at IS NULL;

-- Contar aulas concluídas pelo aluno
SELECT
  COUNT(*) INTO v_concluidas
FROM
  usuario_aula_progresso uap
  JOIN aulas a ON a.id = uap.fk_id_aula
  JOIN modulos m ON m.id = a.fk_id_modulo
WHERE
  m.fk_id_curso = v_curso_id
  AND uap.fk_id_pessoa = NEW.fk_id_pessoa
  AND uap.concluida = TRUE
  AND a.obrigatoria = TRUE;

-- Calcular percentual
IF v_total_aulas > 0 THEN v_percentual := (v_concluidas :: DECIMAL / v_total_aulas) * 100;

ELSE v_percentual := 0;

END IF;

-- Atualizar progresso no usuario_curso
UPDATE
  usuario_curso
SET
  progresso_percentual = v_percentual,
  STATUS = CASE
    WHEN v_percentual >= 100 THEN 'concluido'
    WHEN v_percentual > 0 THEN 'em_andamento'
    ELSE STATUS
  END,
  data_inicio = CASE
    WHEN data_inicio IS NULL
    AND v_percentual > 0 THEN NOW()
    ELSE data_inicio
  END,
  data_conclusao = CASE
    WHEN v_percentual >= 100
    AND data_conclusao IS NULL THEN NOW()
    ELSE data_conclusao
  END,
  updated_at = NOW()
WHERE
  fk_id_pessoa = NEW.fk_id_pessoa
  AND fk_id_curso = v_curso_id
  AND deleted_at IS NULL;

RETURN NEW;

END;

$ $;

CREATE TRIGGER tr_atualizar_progresso_curso
AFTER
INSERT
  OR
UPDATE
  OF concluida ON usuario_aula_progresso FOR EACH ROW
  WHEN (NEW.concluida = TRUE) EXECUTE FUNCTION fn_trg_atualizar_progresso_curso();

COMMENT ON FUNCTION fn_trg_atualizar_progresso_curso() IS 'Recalcula progresso do curso quando aluno conclui aula';