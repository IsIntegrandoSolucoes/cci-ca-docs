-- =====================================================
-- Migration: LMS B2B - Fase 4: LXP (Exercícios, Flashcards, Anotações)
-- Data: 2026-03-02
-- Descrição: Mapas mentais, caderno inteligente, exercícios com auto-correção,
--   flashcards de revisão com spaced repetition, trigger de erro → flashcard
-- Convenções: supabase-convencoes (BIGINT, fk_id_*, fn_*, tr_*, pol_*)
-- =====================================================
-- =====================================================
-- 1. TABELA: mapas_mentais
-- =====================================================
CREATE TABLE IF NOT EXISTS mapas_mentais (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_aula BIGINT NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
  fk_id_professor BIGINT NOT NULL REFERENCES pessoas(id),
  titulo TEXT NOT NULL,
  conteudo_json JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_mapas_mentais_aula ON mapas_mentais(fk_id_aula)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mapas_mentais_professor ON mapas_mentais(fk_id_professor)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE mapas_mentais IS 'Mapas mentais visuais criados pelo professor, vinculados a aulas';

COMMENT ON COLUMN mapas_mentais.conteudo_json IS 'Estrutura JSON do mapa mental (nós, conexões, posições)';

-- RLS
ALTER TABLE
  mapas_mentais ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  mapas_mentais FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_mapas_mentais_select_admin ON mapas_mentais FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_mapas_mentais_select_professor ON mapas_mentais FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = mapas_mentais.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_mapas_mentais_select_matriculado ON mapas_mentais FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
        JOIN usuario_curso uc ON uc.fk_id_curso = m.fk_id_curso
      WHERE
        a.id = mapas_mentais.fk_id_aula
        AND uc.fk_id_pessoa = fn_get_pessoa_id_from_uid()
        AND uc.status NOT IN ('bloqueado', 'expirado')
        AND uc.deleted_at IS NULL
    )
  );

CREATE POLICY pol_mapas_mentais_insert_professor ON mapas_mentais FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = mapas_mentais.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_mapas_mentais_update_professor ON mapas_mentais FOR
UPDATE
  TO authenticated USING (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = mapas_mentais.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  ) WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = mapas_mentais.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_mapas_mentais_delete ON mapas_mentais FOR DELETE TO authenticated USING (
  fn_is_admin_interno()
  OR EXISTS (
    SELECT
      1
    FROM
      aulas a
      JOIN modulos m ON m.id = a.fk_id_modulo
    WHERE
      a.id = mapas_mentais.fk_id_aula
      AND fn_is_professor_do_curso(m.fk_id_curso)
  )
);

-- =====================================================
-- 2. TABELA: anotacoes_aluno
-- =====================================================
CREATE TABLE IF NOT EXISTS anotacoes_aluno (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
  fk_id_aula BIGINT NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
  fk_id_mapa_mental BIGINT REFERENCES mapas_mentais(id) ON DELETE
  SET
    NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('texto', 'audio_transcrito')),
    conteudo TEXT NOT NULL,
    posicao_video_segundos INTEGER,
    audio_url TEXT
);

CREATE INDEX IF NOT EXISTS idx_anotacoes_aluno_pessoa ON anotacoes_aluno(fk_id_pessoa)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_anotacoes_aluno_aula ON anotacoes_aluno(fk_id_aula)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE anotacoes_aluno IS 'Caderno inteligente: anotações texto ou áudio transcrito por aula';

COMMENT ON COLUMN anotacoes_aluno.posicao_video_segundos IS 'Posição do vídeo no momento da anotação';

COMMENT ON COLUMN anotacoes_aluno.audio_url IS 'URL do áudio original (antes da transcrição)';

-- RLS
ALTER TABLE
  anotacoes_aluno ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  anotacoes_aluno FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_anotacoes_aluno_select_admin ON anotacoes_aluno FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_anotacoes_aluno_select_proprio ON anotacoes_aluno FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_anotacoes_aluno_insert_proprio ON anotacoes_aluno FOR
INSERT
  TO authenticated WITH CHECK (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_anotacoes_aluno_update_proprio ON anotacoes_aluno FOR
UPDATE
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid()) WITH CHECK (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_anotacoes_aluno_delete_proprio ON anotacoes_aluno FOR DELETE TO authenticated USING (
  fk_id_pessoa = fn_get_pessoa_id_from_uid()
  OR fn_is_admin_interno()
);

-- =====================================================
-- 3. TABELA: exercicios
-- =====================================================
CREATE TABLE IF NOT EXISTS exercicios (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_aula BIGINT NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
  fk_id_professor BIGINT NOT NULL REFERENCES pessoas(id),
  titulo TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (
    tipo IN (
      'objetiva',
      'multipla_escolha',
      'verdadeiro_falso',
      'dissertativa'
    )
  ),
  enunciado TEXT NOT NULL,
  opcoes JSONB,
  gabarito JSONB NOT NULL,
  explicacao_gabarito TEXT,
  nota_minima DECIMAL(5, 2) DEFAULT 0.00,
  tentativas_permitidas INTEGER DEFAULT 3,
  tempo_limite_minutos INTEGER,
  obrigatorio BOOLEAN NOT NULL DEFAULT false,
  ordem INTEGER
);

CREATE INDEX IF NOT EXISTS idx_exercicios_aula ON exercicios(fk_id_aula, ordem)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_exercicios_professor ON exercicios(fk_id_professor)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE exercicios IS 'Exercícios por aula com gabarito e auto-correção';

COMMENT ON COLUMN exercicios.tipo IS 'objetiva: 1 resposta, multipla_escolha: N respostas, verdadeiro_falso, dissertativa: correção manual';

COMMENT ON COLUMN exercicios.opcoes IS 'Array JSON de alternativas [{id, texto}]';

COMMENT ON COLUMN exercicios.gabarito IS 'Resposta correta: {resposta: "a"} ou {respostas: ["a","c"]}';

COMMENT ON COLUMN exercicios.explicacao_gabarito IS 'Explicação exibida após resposta (vira verso do flashcard)';

-- RLS
ALTER TABLE
  exercicios ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  exercicios FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_exercicios_select_admin ON exercicios FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_exercicios_select_professor ON exercicios FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = exercicios.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_exercicios_select_matriculado ON exercicios FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
        JOIN usuario_curso uc ON uc.fk_id_curso = m.fk_id_curso
      WHERE
        a.id = exercicios.fk_id_aula
        AND uc.fk_id_pessoa = fn_get_pessoa_id_from_uid()
        AND uc.status NOT IN ('bloqueado', 'expirado')
        AND uc.deleted_at IS NULL
    )
  );

CREATE POLICY pol_exercicios_insert_professor ON exercicios FOR
INSERT
  TO authenticated WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = exercicios.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_exercicios_update_professor ON exercicios FOR
UPDATE
  TO authenticated USING (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = exercicios.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  ) WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        aulas a
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        a.id = exercicios.fk_id_aula
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_exercicios_delete ON exercicios FOR DELETE TO authenticated USING (
  fn_is_admin_interno()
  OR EXISTS (
    SELECT
      1
    FROM
      aulas a
      JOIN modulos m ON m.id = a.fk_id_modulo
    WHERE
      a.id = exercicios.fk_id_aula
      AND fn_is_professor_do_curso(m.fk_id_curso)
  )
);

-- =====================================================
-- 4. TABELA: usuario_exercicio_resposta
-- =====================================================
CREATE TABLE IF NOT EXISTS usuario_exercicio_resposta (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
  fk_id_exercicio BIGINT NOT NULL REFERENCES exercicios(id) ON DELETE CASCADE,
  resposta JSONB NOT NULL,
  correta BOOLEAN,
  nota DECIMAL(5, 2),
  tentativa INTEGER NOT NULL DEFAULT 1,
  tempo_gasto_segundos INTEGER,
  feedback_professor TEXT,
  corrigido_em TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_resposta_pessoa ON usuario_exercicio_resposta(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_resposta_exercicio ON usuario_exercicio_resposta(fk_id_exercicio);

CREATE INDEX IF NOT EXISTS idx_resposta_correta ON usuario_exercicio_resposta(correta)
WHERE
  correta = false;

COMMENT ON TABLE usuario_exercicio_resposta IS 'Respostas de exercícios (imutáveis após envio)';

COMMENT ON COLUMN usuario_exercicio_resposta.resposta IS 'Resposta do aluno: {resposta: "a"} ou {texto: "..."}';

COMMENT ON COLUMN usuario_exercicio_resposta.tentativa IS 'Número da tentativa (1, 2, 3...)';

COMMENT ON COLUMN usuario_exercicio_resposta.feedback_professor IS 'Feedback manual para exercícios dissertativos';

-- RLS
ALTER TABLE
  usuario_exercicio_resposta ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  usuario_exercicio_resposta FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_resposta_select_admin ON usuario_exercicio_resposta FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_resposta_select_proprio ON usuario_exercicio_resposta FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_resposta_select_professor ON usuario_exercicio_resposta FOR
SELECT
  TO authenticated USING (
    EXISTS (
      SELECT
        1
      FROM
        exercicios e
        JOIN aulas a ON a.id = e.fk_id_aula
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        e.id = usuario_exercicio_resposta.fk_id_exercicio
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_resposta_insert_proprio ON usuario_exercicio_resposta FOR
INSERT
  TO authenticated WITH CHECK (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_resposta_update_professor ON usuario_exercicio_resposta FOR
UPDATE
  TO authenticated USING (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        exercicios e
        JOIN aulas a ON a.id = e.fk_id_aula
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        e.id = usuario_exercicio_resposta.fk_id_exercicio
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  ) WITH CHECK (
    fn_is_admin_interno()
    OR EXISTS (
      SELECT
        1
      FROM
        exercicios e
        JOIN aulas a ON a.id = e.fk_id_aula
        JOIN modulos m ON m.id = a.fk_id_modulo
      WHERE
        e.id = usuario_exercicio_resposta.fk_id_exercicio
        AND fn_is_professor_do_curso(m.fk_id_curso)
    )
  );

CREATE POLICY pol_resposta_delete_admin ON usuario_exercicio_resposta FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- =====================================================
-- 5. TABELA: flashcards_revisao
-- =====================================================
CREATE TABLE IF NOT EXISTS flashcards_revisao (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
  fk_id_exercicio BIGINT NOT NULL REFERENCES exercicios(id) ON DELETE CASCADE,
  fk_id_resposta BIGINT REFERENCES usuario_exercicio_resposta(id) ON DELETE CASCADE,
  frente TEXT NOT NULL,
  verso TEXT NOT NULL,
  dificuldade TEXT NOT NULL DEFAULT 'media' CHECK (dificuldade IN ('facil', 'media', 'dificil')),
  revisoes INTEGER NOT NULL DEFAULT 0,
  proxima_revisao DATE,
  CONSTRAINT unq_flashcards_pessoa_exercicio UNIQUE (fk_id_pessoa, fk_id_exercicio)
);

CREATE INDEX IF NOT EXISTS idx_flashcards_pessoa ON flashcards_revisao(fk_id_pessoa);

CREATE INDEX IF NOT EXISTS idx_flashcards_proxima_revisao ON flashcards_revisao(fk_id_pessoa, proxima_revisao);

COMMENT ON TABLE flashcards_revisao IS 'Flashcards de revisão: gerados por erros em exercícios ou criados manualmente';

COMMENT ON COLUMN flashcards_revisao.frente IS 'Enunciado do exercício (ou pergunta customizada)';

COMMENT ON COLUMN flashcards_revisao.verso IS 'Explicação do gabarito (ou resposta customizada)';

COMMENT ON COLUMN flashcards_revisao.dificuldade IS 'Ajustável pelo aluno conforme revisão (spaced repetition)';

COMMENT ON COLUMN flashcards_revisao.proxima_revisao IS 'Data da próxima revisão (spaced repetition)';

-- RLS
ALTER TABLE
  flashcards_revisao ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  flashcards_revisao FORCE ROW LEVEL SECURITY;

CREATE POLICY pol_flashcards_select_admin ON flashcards_revisao FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

CREATE POLICY pol_flashcards_select_proprio ON flashcards_revisao FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_flashcards_insert_proprio ON flashcards_revisao FOR
INSERT
  TO authenticated WITH CHECK (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_flashcards_update_proprio ON flashcards_revisao FOR
UPDATE
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid()) WITH CHECK (fk_id_pessoa = fn_get_pessoa_id_from_uid());

CREATE POLICY pol_flashcards_delete_proprio ON flashcards_revisao FOR DELETE TO authenticated USING (
  fk_id_pessoa = fn_get_pessoa_id_from_uid()
  OR fn_is_admin_interno()
);

-- =====================================================
-- 6. TRIGGER: Gerar flashcard automaticamente após erro
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_trg_gerar_flashcard_apos_erro() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_exercicio RECORD;

BEGIN IF NEW.correta = false THEN
SELECT
  e.enunciado,
  e.explicacao_gabarito INTO v_exercicio
FROM
  exercicios e
WHERE
  e.id = NEW.fk_id_exercicio
  AND e.deleted_at IS NULL;

IF FOUND
AND v_exercicio.explicacao_gabarito IS NOT NULL THEN
INSERT INTO
  flashcards_revisao (
    fk_id_pessoa,
    fk_id_exercicio,
    fk_id_resposta,
    frente,
    verso,
    dificuldade,
    proxima_revisao
  )
VALUES
  (
    NEW.fk_id_pessoa,
    NEW.fk_id_exercicio,
    NEW.id,
    v_exercicio.enunciado,
    v_exercicio.explicacao_gabarito,
    'media',
    CURRENT_DATE + INTERVAL '1 day'
  ) ON CONFLICT (fk_id_pessoa, fk_id_exercicio) DO NOTHING;

END IF;

END IF;

RETURN NEW;

END;

$ $;

CREATE TRIGGER tr_gerar_flashcard_apos_erro
AFTER
INSERT
  ON usuario_exercicio_resposta FOR EACH ROW
  WHEN (NEW.correta = false) EXECUTE FUNCTION fn_trg_gerar_flashcard_apos_erro();

COMMENT ON FUNCTION fn_trg_gerar_flashcard_apos_erro() IS 'Gera flashcard de revisão automaticamente quando aluno erra exercício';

-- =====================================================
-- 7. RPC: Responder exercício (auto-correção)
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_responder_exercicio(
  p_exercicio_id BIGINT,
  p_resposta JSONB,
  p_tempo_gasto_segundos INTEGER DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_exercicio RECORD;

v_curso_id BIGINT;

v_matriculado BOOLEAN;

v_tentativa_atual INTEGER;

v_correta BOOLEAN := false;

v_nota DECIMAL(5, 2) := 0;

v_resposta_id BIGINT;

BEGIN v_pessoa_id := fn_get_pessoa_id_from_uid();

IF v_pessoa_id IS NULL THEN RETURN jsonb_build_object('sucesso', false, 'erro', 'sem_pessoa');

END IF;

-- Buscar exercício
SELECT
  e.*,
  m.fk_id_curso INTO v_exercicio
FROM
  exercicios e
  JOIN aulas a ON a.id = e.fk_id_aula
  JOIN modulos m ON m.id = a.fk_id_modulo
WHERE
  e.id = p_exercicio_id
  AND e.deleted_at IS NULL;

IF NOT FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'exercicio_nao_encontrado'
);

END IF;

v_curso_id := v_exercicio.fk_id_curso;

-- Verificar matrícula
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

IF NOT v_matriculado THEN RETURN jsonb_build_object('sucesso', false, 'erro', 'sem_matricula');

END IF;

-- Contar tentativas anteriores
SELECT
  COALESCE(MAX(tentativa), 0) INTO v_tentativa_atual
FROM
  usuario_exercicio_resposta
WHERE
  fk_id_pessoa = v_pessoa_id
  AND fk_id_exercicio = p_exercicio_id;

-- Verificar limite de tentativas
IF v_exercicio.tentativas_permitidas IS NOT NULL
AND v_tentativa_atual >= v_exercicio.tentativas_permitidas THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'tentativas_esgotadas',
  'mensagem',
  'Limite de tentativas atingido.',
  'tentativas_usadas',
  v_tentativa_atual,
  'tentativas_permitidas',
  v_exercicio.tentativas_permitidas
);

END IF;

-- Auto-correção para tipos objetivos
IF v_exercicio.tipo IN ('objetiva', 'verdadeiro_falso') THEN v_correta := (p_resposta ->> 'resposta') = (v_exercicio.gabarito ->> 'resposta');

v_nota := CASE
  WHEN v_correta THEN 100.00
  ELSE 0.00
END;

ELSIF v_exercicio.tipo = 'multipla_escolha' THEN v_correta := (
  SELECT
    p_resposta -> 'respostas' @ > v_exercicio.gabarito -> 'respostas'
    AND v_exercicio.gabarito -> 'respostas' @ > p_resposta -> 'respostas'
);

v_nota := CASE
  WHEN v_correta THEN 100.00
  ELSE 0.00
END;

ELSE -- Dissertativa: sem auto-correção
v_correta := NULL;

v_nota := NULL;

END IF;

-- Registrar resposta
INSERT INTO
  usuario_exercicio_resposta (
    fk_id_pessoa,
    fk_id_exercicio,
    resposta,
    correta,
    nota,
    tentativa,
    tempo_gasto_segundos
  )
VALUES
  (
    v_pessoa_id,
    p_exercicio_id,
    p_resposta,
    v_correta,
    v_nota,
    v_tentativa_atual + 1,
    p_tempo_gasto_segundos
  ) RETURNING id INTO v_resposta_id;

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'resposta_id',
  v_resposta_id,
  'correta',
  v_correta,
  'nota',
  v_nota,
  'tentativa',
  v_tentativa_atual + 1,
  'tentativas_restantes',
  CASE
    WHEN v_exercicio.tentativas_permitidas IS NULL THEN NULL
    ELSE v_exercicio.tentativas_permitidas - (v_tentativa_atual + 1)
  END,
  'explicacao_gabarito',
  CASE
    WHEN v_correta = false
    OR (v_tentativa_atual + 1) >= COALESCE(v_exercicio.tentativas_permitidas, 999) THEN v_exercicio.explicacao_gabarito
    ELSE NULL
  END,
  'aguardando_correcao',
  (v_exercicio.tipo = 'dissertativa')
);

END;

$ $;

COMMENT ON FUNCTION fn_responder_exercicio(BIGINT, JSONB, INTEGER) IS 'Submete resposta de exercício com auto-correção (objetiva/VF/ME) ou fila de correção (dissertativa)';

-- =====================================================
-- 8. RPC: Revisar flashcard (spaced repetition)
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_revisar_flashcard(
  p_flashcard_id BIGINT,
  p_dificuldade TEXT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_flashcard RECORD;

v_intervalo_dias INTEGER;

BEGIN v_pessoa_id := fn_get_pessoa_id_from_uid();

IF v_pessoa_id IS NULL THEN RETURN jsonb_build_object('sucesso', false, 'erro', 'sem_pessoa');

END IF;

SELECT
  * INTO v_flashcard
FROM
  flashcards_revisao
WHERE
  id = p_flashcard_id
  AND fk_id_pessoa = v_pessoa_id;

IF NOT FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'flashcard_nao_encontrado'
);

END IF;

-- Spaced repetition simplificado
v_intervalo_dias := CASE
  p_dificuldade
  WHEN 'facil' THEN GREATEST(3, COALESCE(v_flashcard.revisoes * 2.5, 3)) :: INTEGER
  WHEN 'media' THEN GREATEST(1, COALESCE(v_flashcard.revisoes * 1.5, 1)) :: INTEGER
  WHEN 'dificil' THEN 1
  ELSE 1
END;

UPDATE
  flashcards_revisao
SET
  dificuldade = p_dificuldade,
  revisoes = revisoes + 1,
  proxima_revisao = CURRENT_DATE + (v_intervalo_dias || ' days') :: INTERVAL,
  updated_at = NOW()
WHERE
  id = p_flashcard_id;

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'revisoes',
  v_flashcard.revisoes + 1,
  'proxima_revisao',
  CURRENT_DATE + (v_intervalo_dias || ' days') :: INTERVAL,
  'intervalo_dias',
  v_intervalo_dias
);

END;

$ $;

COMMENT ON FUNCTION fn_revisar_flashcard(BIGINT, TEXT) IS 'Registra revisão de flashcard com spaced repetition (fácil/média/difícil)';

-- =====================================================
-- 9. RPC: Corrigir exercício dissertativo (professor)
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_corrigir_exercicio_dissertativo(
  p_resposta_id BIGINT,
  p_nota DECIMAL(5, 2),
  p_feedback TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_resposta RECORD;

v_correta BOOLEAN;

BEGIN v_pessoa_id := fn_get_pessoa_id_from_uid();

SELECT
  uer.*,
  e.nota_minima,
  e.fk_id_aula,
  m.fk_id_curso INTO v_resposta
FROM
  usuario_exercicio_resposta uer
  JOIN exercicios e ON e.id = uer.fk_id_exercicio
  JOIN aulas a ON a.id = e.fk_id_aula
  JOIN modulos m ON m.id = a.fk_id_modulo
WHERE
  uer.id = p_resposta_id;

IF NOT FOUND THEN RETURN jsonb_build_object(
  'sucesso',
  false,
  'erro',
  'resposta_nao_encontrada'
);

END IF;

IF NOT fn_is_admin_interno()
AND NOT fn_is_professor_do_curso(v_resposta.fk_id_curso) THEN RETURN jsonb_build_object('sucesso', false, 'erro', 'sem_permissao');

END IF;

v_correta := p_nota >= COALESCE(v_resposta.nota_minima, 0);

UPDATE
  usuario_exercicio_resposta
SET
  nota = p_nota,
  correta = v_correta,
  feedback_professor = p_feedback,
  corrigido_em = NOW()
WHERE
  id = p_resposta_id;

RETURN jsonb_build_object(
  'sucesso',
  TRUE,
  'nota',
  p_nota,
  'correta',
  v_correta,
  'mensagem',
  'Exercício corrigido.'
);

END;

$ $;

COMMENT ON FUNCTION fn_corrigir_exercicio_dissertativo(BIGINT, DECIMAL, TEXT) IS 'Professor corrige exercício dissertativo com nota e feedback';