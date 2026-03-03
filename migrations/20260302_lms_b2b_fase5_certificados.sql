-- =====================================================
-- Migration: LMS B2B - Fase 5 Certificados e Relatórios RH
-- Data: 2026-03-02
-- Descrição: Certificados automáticos, validação pública, views e relatório RH
-- Convenções: supabase-convencoes (BIGINT, fk_id_*, fn_*, tr_*, pol_*)
-- =====================================================
-- =====================================================
-- 1. TABELA: certificados
-- =====================================================
CREATE TABLE IF NOT EXISTS certificados (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_by BIGINT,
  updated_at TIMESTAMPTZ,
  updated_by BIGINT,
  deleted_at TIMESTAMPTZ,
  deleted_by BIGINT,
  fk_id_pessoa BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
  fk_id_curso BIGINT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
  fk_id_empresa BIGINT REFERENCES lms_empresas(id) ON DELETE
  SET
    NULL,
    codigo_validacao VARCHAR(50) UNIQUE NOT NULL,
    nota_final DECIMAL(5, 2) NOT NULL,
    carga_horaria INTEGER NOT NULL,
    data_emissao TIMESTAMPTZ DEFAULT NOW(),
    pdf_url TEXT,
    qr_code_url TEXT,
    template_usado VARCHAR(100),
    CONSTRAINT unq_certificados_pessoa_curso UNIQUE (fk_id_pessoa, fk_id_curso)
);

CREATE INDEX IF NOT EXISTS idx_certificados_pessoa ON certificados(fk_id_pessoa)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_certificados_codigo ON certificados(codigo_validacao);

CREATE INDEX IF NOT EXISTS idx_certificados_empresa ON certificados(fk_id_empresa)
WHERE
  deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_certificados_curso ON certificados(fk_id_curso)
WHERE
  deleted_at IS NULL;

COMMENT ON TABLE certificados IS 'Certificados emitidos automaticamente ao concluir curso LMS';

COMMENT ON COLUMN certificados.codigo_validacao IS 'Código único para validação pública (ex: CRT-ABC123)';

COMMENT ON COLUMN certificados.carga_horaria IS 'Carga horária em minutos, copiada do curso na emissão';

-- =====================================================
-- 2. RLS: certificados
-- =====================================================
ALTER TABLE
  certificados ENABLE ROW LEVEL SECURITY;

ALTER TABLE
  certificados FORCE ROW LEVEL SECURITY;

-- SELECT: Aluno vê apenas seus certificados
CREATE POLICY pol_certificados_select_aluno ON certificados FOR
SELECT
  TO authenticated USING (fk_id_pessoa = fn_get_pessoa_id_from_uid());

-- SELECT: Professor vê certificados do seu curso
CREATE POLICY pol_certificados_select_professor ON certificados FOR
SELECT
  TO authenticated USING (fn_is_professor_do_curso(fk_id_curso));

-- SELECT: Gestor RH vê certificados da empresa
CREATE POLICY pol_certificados_select_gestor ON certificados FOR
SELECT
  TO authenticated USING (
    fk_id_empresa = fn_get_empresa_id_do_usuario(fn_get_pessoa_id_from_uid())
    AND fn_is_gestor_rh_da_empresa(fk_id_empresa)
  );

-- SELECT: Admin interno vê todos
CREATE POLICY pol_certificados_select_admin ON certificados FOR
SELECT
  TO authenticated USING (fn_is_admin_interno());

-- UPDATE: Apenas admin interno (para atualizar pdf_url, qr_code_url)
CREATE POLICY pol_certificados_update_admin ON certificados FOR
UPDATE
  TO authenticated USING (fn_is_admin_interno()) WITH CHECK (fn_is_admin_interno());

-- DELETE: Apenas admin interno
CREATE POLICY pol_certificados_delete_admin ON certificados FOR DELETE TO authenticated USING (fn_is_admin_interno());

-- =====================================================
-- 3. TRIGGER: Emissão automática de certificado
-- Dispara ao UPDATE de usuario_curso para status 'concluido'
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_trg_emitir_certificado() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_nota_minima DECIMAL(5, 2) := 70.00;

v_carga_horaria INTEGER;

v_codigo_validacao VARCHAR(50);

BEGIN -- Só emitir se status for 'concluido' e progresso >= 100%
IF NEW.status = 'concluido'
AND NEW.progresso_percentual >= 100.00
AND (
  NEW.nota_final IS NULL
  OR NEW.nota_final >= v_nota_minima
)
AND NOT EXISTS (
  SELECT
    1
  FROM
    certificados
  WHERE
    fk_id_pessoa = NEW.fk_id_pessoa
    AND fk_id_curso = NEW.fk_id_curso
) THEN -- Obter carga horária do curso
SELECT
  c.carga_horaria INTO v_carga_horaria
FROM
  cursos c
WHERE
  c.id = NEW.fk_id_curso;

-- Gerar código único de validação
v_codigo_validacao := 'CRT-' || UPPER(encode(gen_random_bytes(6), 'hex'));

-- Inserir certificado
INSERT INTO
  certificados (
    fk_id_pessoa,
    fk_id_curso,
    fk_id_empresa,
    codigo_validacao,
    nota_final,
    carga_horaria,
    data_emissao
  )
VALUES
  (
    NEW.fk_id_pessoa,
    NEW.fk_id_curso,
    NEW.fk_id_empresa,
    v_codigo_validacao,
    COALESCE(NEW.nota_final, 100.00),
    COALESCE(v_carga_horaria, 0),
    NOW()
  );

END IF;

RETURN NEW;

END;

$ $;

CREATE TRIGGER tr_emitir_certificado
AFTER
UPDATE
  ON usuario_curso FOR EACH ROW
  WHEN (NEW.status = 'concluido') EXECUTE FUNCTION fn_trg_emitir_certificado();

-- =====================================================
-- 4. RPC: Validação pública de certificado
-- Retorna dados do certificado a partir do codigo_validacao
-- Sem autenticação necessária (SECURITY DEFINER)
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_validar_certificado(p_codigo_validacao TEXT) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_resultado JSONB;

BEGIN
SELECT
  jsonb_build_object(
    'valido',
    TRUE,
    'codigo',
    c.codigo_validacao,
    'aluno',
    p.nome,
    'curso',
    cu.titulo,
    'nota_final',
    c.nota_final,
    'carga_horaria',
    c.carga_horaria,
    'data_emissao',
    c.data_emissao,
    'empresa',
    e.razao_social
  ) INTO v_resultado
FROM
  certificados c
  JOIN pessoas p ON p.id = c.fk_id_pessoa
  JOIN cursos cu ON cu.id = c.fk_id_curso
  LEFT JOIN lms_empresas e ON e.id = c.fk_id_empresa
WHERE
  c.codigo_validacao = p_codigo_validacao
  AND c.deleted_at IS NULL;

IF v_resultado IS NULL THEN RETURN jsonb_build_object(
  'valido',
  FALSE,
  'mensagem',
  'Certificado não encontrado ou inválido.'
);

END IF;

RETURN v_resultado;

END;

$ $;

COMMENT ON FUNCTION fn_validar_certificado IS 'Validação pública de certificado por código (SECURITY DEFINER, sem RLS)';

-- =====================================================
-- 5. VIEW: Progresso por Empresa (relatório RH)
-- =====================================================
CREATE
OR REPLACE VIEW vw_progresso_por_empresa AS
SELECT
  e.id AS empresa_id,
  e.razao_social,
  cu.id AS curso_id,
  cu.titulo AS curso_titulo,
  COUNT(DISTINCT uc.fk_id_pessoa) AS total_matriculados,
  COUNT(
    DISTINCT CASE
      WHEN uc.status = 'em_andamento' THEN uc.fk_id_pessoa
    END
  ) AS ativos,
  COUNT(
    DISTINCT CASE
      WHEN uc.status = 'concluido' THEN uc.fk_id_pessoa
    END
  ) AS concluidos,
  ROUND(
    100.0 * COUNT(
      DISTINCT CASE
        WHEN uc.status = 'concluido' THEN uc.fk_id_pessoa
      END
    ) / NULLIF(COUNT(DISTINCT uc.fk_id_pessoa), 0),
    2
  ) AS taxa_conclusao_percentual
FROM
  lms_empresas e
  JOIN lms_empresa_usuarios eu ON eu.fk_id_empresa = e.id
  AND eu.deleted_at IS NULL
  AND eu.status = 'ativo'
  JOIN usuario_curso uc ON uc.fk_id_pessoa = eu.fk_id_pessoa
  AND uc.deleted_at IS NULL
  JOIN cursos cu ON cu.id = uc.fk_id_curso
  AND cu.deleted_at IS NULL
WHERE
  e.deleted_at IS NULL
GROUP BY
  e.id,
  e.razao_social,
  cu.id,
  cu.titulo;

COMMENT ON VIEW vw_progresso_por_empresa IS 'Relatório RH: progresso de colaboradores por empresa e curso';

-- =====================================================
-- 6. VIEW: Certificados emitidos por Empresa
-- =====================================================
CREATE
OR REPLACE VIEW vw_certificados_por_empresa AS
SELECT
  e.id AS empresa_id,
  e.razao_social,
  cert.id AS certificado_id,
  cert.codigo_validacao,
  p.nome AS aluno_nome,
  p.email AS aluno_email,
  cu.titulo AS curso_titulo,
  cert.nota_final,
  cert.carga_horaria,
  cert.data_emissao
FROM
  lms_empresas e
  JOIN lms_empresa_usuarios eu ON eu.fk_id_empresa = e.id
  AND eu.deleted_at IS NULL
  AND eu.status = 'ativo'
  JOIN pessoas p ON p.id = eu.fk_id_pessoa
  AND p.deleted_at IS NULL
  JOIN certificados cert ON cert.fk_id_pessoa = p.id
  AND cert.deleted_at IS NULL
  JOIN cursos cu ON cu.id = cert.fk_id_curso
  AND cu.deleted_at IS NULL
WHERE
  e.deleted_at IS NULL;

COMMENT ON VIEW vw_certificados_por_empresa IS 'Relatório RH: certificados emitidos por empresa com dados do aluno';

-- =====================================================
-- 7. RPC: Relatório detalhado de progresso por empresa
-- Acessível apenas por Gestor RH ou Admin
-- =====================================================
CREATE
OR REPLACE FUNCTION fn_relatorio_progresso_empresa(
  p_empresa_id BIGINT,
  p_curso_id BIGINT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET
  search_path = public AS $ $ DECLARE v_pessoa_id BIGINT;

v_resultado JSONB;

BEGIN -- Obter pessoa autenticada
SELECT
  id INTO v_pessoa_id
FROM
  pessoas
WHERE
  uid = auth.uid() :: TEXT
  AND deleted_at IS NULL
LIMIT
  1;

IF v_pessoa_id IS NULL THEN RETURN jsonb_build_object('sucesso', FALSE, 'erro', 'nao_autenticado');

END IF;

-- Verificar permissão: admin interno OU gestor RH da empresa solicitada
IF NOT fn_is_admin_interno()
AND NOT fn_is_gestor_rh_da_empresa(p_empresa_id) THEN RETURN jsonb_build_object('sucesso', FALSE, 'erro', 'sem_permissao');

END IF;

-- Montar relatório
SELECT
  jsonb_build_object(
    'sucesso',
    TRUE,
    'empresa_id',
    p_empresa_id,
    'resumo',
    (
      SELECT
        jsonb_build_object(
          'total_colaboradores',
          COUNT(DISTINCT eu.fk_id_pessoa),
          'total_matriculados',
          COUNT(DISTINCT uc.fk_id_pessoa),
          'total_concluidos',
          COUNT(
            DISTINCT CASE
              WHEN uc.status = 'concluido' THEN uc.fk_id_pessoa
            END
          ),
          'taxa_conclusao',
          ROUND(
            100.0 * COUNT(
              DISTINCT CASE
                WHEN uc.status = 'concluido' THEN uc.fk_id_pessoa
              END
            ) / NULLIF(COUNT(DISTINCT uc.fk_id_pessoa), 0),
            2
          ),
          'total_certificados',
          (
            SELECT
              COUNT(*)
            FROM
              certificados cert
            WHERE
              cert.fk_id_empresa = p_empresa_id
              AND cert.deleted_at IS NULL
          )
        )
      FROM
        lms_empresa_usuarios eu
        LEFT JOIN usuario_curso uc ON uc.fk_id_pessoa = eu.fk_id_pessoa
        AND uc.deleted_at IS NULL
        AND (
          p_curso_id IS NULL
          OR uc.fk_id_curso = p_curso_id
        )
      WHERE
        eu.fk_id_empresa = p_empresa_id
        AND eu.deleted_at IS NULL
        AND eu.status = 'ativo'
    ),
    'colaboradores',
    (
      SELECT
        COALESCE(
          jsonb_agg(
            jsonb_build_object(
              'pessoa_id',
              p.id,
              'nome',
              p.nome,
              'email',
              p.email,
              'cursos',
              (
                SELECT
                  COALESCE(
                    jsonb_agg(
                      jsonb_build_object(
                        'curso_id',
                        uc2.fk_id_curso,
                        'titulo',
                        cu2.titulo,
                        'status',
                        uc2.status,
                        'progresso',
                        uc2.progresso_percentual,
                        'nota_final',
                        uc2.nota_final,
                        'data_matricula',
                        uc2.data_matricula,
                        'data_conclusao',
                        uc2.data_conclusao,
                        'certificado_codigo',
                        cert2.codigo_validacao
                      )
                    ),
                    '[]' :: JSONB
                  )
                FROM
                  usuario_curso uc2
                  JOIN cursos cu2 ON cu2.id = uc2.fk_id_curso
                  LEFT JOIN certificados cert2 ON cert2.fk_id_pessoa = uc2.fk_id_pessoa
                  AND cert2.fk_id_curso = uc2.fk_id_curso
                  AND cert2.deleted_at IS NULL
                WHERE
                  uc2.fk_id_pessoa = p.id
                  AND uc2.deleted_at IS NULL
                  AND (
                    p_curso_id IS NULL
                    OR uc2.fk_id_curso = p_curso_id
                  )
              )
            )
          ),
          '[]' :: JSONB
        )
      FROM
        lms_empresa_usuarios eu2
        JOIN pessoas p ON p.id = eu2.fk_id_pessoa
        AND p.deleted_at IS NULL
      WHERE
        eu2.fk_id_empresa = p_empresa_id
        AND eu2.deleted_at IS NULL
        AND eu2.status = 'ativo'
    )
  ) INTO v_resultado;

RETURN v_resultado;

END;

$ $;

COMMENT ON FUNCTION fn_relatorio_progresso_empresa IS 'Relatório detalhado de progresso por empresa, acessível por gestor RH ou admin';