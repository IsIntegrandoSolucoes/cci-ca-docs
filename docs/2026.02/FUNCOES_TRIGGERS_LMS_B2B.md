# Funções e Triggers - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (não implementado)  
**Base:** SCHEMA_TABELAS_LMS_B2B.md

---

## 1. Funções de Apoio (Security Definer)

### `auth_user_id()`

Retorna o ID do usuário autenticado.

```sql
CREATE OR REPLACE FUNCTION auth_user_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT auth.uid();
$$;
```

---

### `is_admin_interno()`

Verifica se o usuário é admin interno (equipe CCI-CA).

```sql
CREATE OR REPLACE FUNCTION is_admin_interno()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM auth.users u
        WHERE u.id = auth.uid()
        AND raw_user_meta_data->>'perfil' = 'admin_interno'
    );
$$;
```

---

### `get_empresa_id_do_usuario(p_usuario_id UUID)`

Retorna o ID da empresa do usuário.

```sql
CREATE OR REPLACE FUNCTION get_empresa_id_do_usuario(p_usuario_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT empresa_id
    FROM empresa_usuarios
    WHERE usuario_id = p_usuario_id
    AND ativo = true
    LIMIT 1;
$$;
```

---

### `is_gestor_rh_da_empresa(p_empresa_id UUID)`

Verifica se o usuário atual é gestor RH da empresa especificada.

```sql
CREATE OR REPLACE FUNCTION is_gestor_rh_da_empresa(p_empresa_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM empresa_usuarios
        WHERE usuario_id = auth.uid()
        AND empresa_id = p_empresa_id
        AND perfil = 'gestor_rh'
        AND ativo = true
    );
$$;
```

---

### `is_professor_do_curso(p_curso_id UUID)`

Verifica se o usuário atual é professor do curso especificado.

```sql
CREATE OR REPLACE FUNCTION is_professor_do_curso(p_curso_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM cursos
        WHERE id = p_curso_id
        AND professor_id = auth.uid()
        AND deletado_em IS NULL
    );
$$;
```

---

### `empresa_status_ativo(p_empresa_id UUID)`

Verifica se a empresa está ativa (não suspensa/expirada).

```sql
CREATE OR REPLACE FUNCTION empresa_status_ativo(p_empresa_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM empresas
        WHERE id = p_empresa_id
        AND status = 'ativa'
        AND (data_validade IS NULL OR data_validade >= CURRENT_DATE)
        AND deleted_at IS NULL
    );
$$;
```

---

## 2. RPCs Transacionais (Matrícula e Sessões)

### `rpc_matricular_usuario_no_curso()`

Matricula um usuário no curso (sem consumir licença).

```sql
CREATE OR REPLACE FUNCTION rpc_matricular_usuario_no_curso(
    p_empresa_id UUID,
    p_usuario_id UUID,
    p_curso_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_ativa BOOLEAN;
    v_ja_matriculado BOOLEAN;
BEGIN
    -- Validar empresa ativa
    SELECT empresa_status_ativo(p_empresa_id) INTO v_empresa_ativa;

    IF NOT v_empresa_ativa THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'empresa_inativa',
            'mensagem', 'Empresa suspensa ou expirada. Contate o administrador.'
        );
    END IF;

    -- Verificar se já está matriculado
    SELECT EXISTS (
        SELECT 1
        FROM usuario_curso
        WHERE usuario_id = p_usuario_id
        AND curso_id = p_curso_id
    ) INTO v_ja_matriculado;

    IF v_ja_matriculado THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'ja_matriculado',
            'mensagem', 'Usuário já está matriculado neste curso.'
        );
    END IF;

    -- Criar matrícula (SEM consumir licença)
    INSERT INTO usuario_curso (
        empresa_id,
        usuario_id,
        curso_id,
        status,
        data_matricula
    ) VALUES (
        p_empresa_id,
        p_usuario_id,
        p_curso_id,
        'matriculado',
        NOW()
    );

    -- Gerar log de auditoria
    INSERT INTO auditoria (
        tabela,
        operacao,
        registro_id,
        usuario_id,
        detalhes
    ) VALUES (
        'usuario_curso',
        'INSERT',
        p_usuario_id,
        auth.uid(),
        jsonb_build_object(
            'empresa_id', p_empresa_id,
            'curso_id', p_curso_id,
            'tipo', 'matricula_manual'
        )
    );

    RETURN jsonb_build_object(
        'sucesso', true,
        'mensagem', 'Matrícula realizada com sucesso.'
    );
END;
$$;
```

---

### `rpc_matricular_lote_b2b()`

Matricula múltiplos usuários em um curso (importação CSV).

```sql
CREATE OR REPLACE FUNCTION rpc_matricular_lote_b2b(
    p_empresa_id UUID,
    p_curso_id UUID,
    p_usuarios_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_ativa BOOLEAN;
    v_usuario_id UUID;
    v_sucesso INTEGER := 0;
    v_falhas INTEGER := 0;
    v_ja_matriculados INTEGER := 0;
BEGIN
    -- Validar empresa ativa
    SELECT empresa_status_ativo(p_empresa_id) INTO v_empresa_ativa;

    IF NOT v_empresa_ativa THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'empresa_inativa',
            'mensagem', 'Empresa suspensa ou expirada. Contate o administrador.'
        );
    END IF;

    -- Loop pelos usuários
    FOREACH v_usuario_id IN ARRAY p_usuarios_ids
    LOOP
        -- Verificar se já matriculado
        IF EXISTS (
            SELECT 1
            FROM usuario_curso
            WHERE usuario_id = v_usuario_id
            AND curso_id = p_curso_id
        ) THEN
            v_ja_matriculados := v_ja_matriculados + 1;
            CONTINUE;
        END IF;

        BEGIN
            INSERT INTO usuario_curso (
                empresa_id,
                usuario_id,
                curso_id,
                status,
                data_matricula
            ) VALUES (
                p_empresa_id,
                v_usuario_id,
                p_curso_id,
                'matriculado',
                NOW()
            );

            v_sucesso := v_sucesso + 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_falhas := v_falhas + 1;
        END;
    END LOOP;

    -- Log de auditoria
    INSERT INTO auditoria (
        tabela,
        operacao,
        registro_id,
        usuario_id,
        detalhes
    ) VALUES (
        'usuario_curso',
        'INSERT_LOTE',
        p_empresa_id,
        auth.uid(),
        jsonb_build_object(
            'curso_id', p_curso_id,
            'total', array_length(p_usuarios_ids, 1),
            'sucesso', v_sucesso,
            'falhas', v_falhas,
            'ja_matriculados', v_ja_matriculados
        )
    );

    RETURN jsonb_build_object(
        'sucesso', true,
        'matriculados', v_sucesso,
        'falhas', v_falhas,
        'ja_matriculados', v_ja_matriculados,
        'total', array_length(p_usuarios_ids, 1)
    );
END;
$$;
```

---

### `rpc_validar_acesso_simultaneo()`

Valida e registra acesso simultâneo ao curso.

```sql
CREATE OR REPLACE FUNCTION rpc_validar_acesso_simultaneo(
    p_usuario_id UUID,
    p_curso_id UUID,
    p_session_token TEXT,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id UUID;
    v_limite_simultaneo INTEGER;
    v_sessoes_ativas INTEGER;
    v_empresa_ativa BOOLEAN;
BEGIN
    -- Obter empresa do usuário
    SELECT empresa_id INTO v_empresa_id
    FROM empresa_usuarios
    WHERE usuario_id = p_usuario_id AND ativo = true
    LIMIT 1;

    IF v_empresa_id IS NULL THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'sem_empresa',
            'mensagem', 'Usuário não está vinculado a nenhuma empresa.'
        );
    END IF;

    -- Validar status da empresa
    SELECT empresa_status_ativo(v_empresa_id) INTO v_empresa_ativa;

    IF NOT v_empresa_ativa THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'empresa_inativa',
            'mensagem', 'Acesso encerrado. Empresa suspensa ou contrato expirado.'
        );
    END IF;

    -- Obter limite de usuários simultâneos
    SELECT limite_usuarios_simultaneos INTO v_limite_simultaneo
    FROM empresas
    WHERE id = v_empresa_id;

    -- Limpar sessões expiradas (> 5 minutos sem heartbeat)
    DELETE FROM sessoes_ativas
    WHERE empresa_id = v_empresa_id
    AND ultimo_heartbeat < NOW() - INTERVAL '5 minutes';

    -- Contar sessões ativas atuais
    SELECT COUNT(*) INTO v_sessoes_ativas
    FROM sessoes_ativas
    WHERE empresa_id = v_empresa_id;

    -- Verificar se usuário já tem sessão ativa neste curso
    IF EXISTS (
        SELECT 1
        FROM sessoes_ativas
        WHERE usuario_id = p_usuario_id
        AND curso_id = p_curso_id
    ) THEN
        -- Atualizar heartbeat da sessão existente
        UPDATE sessoes_ativas
        SET ultimo_heartbeat = NOW()
        WHERE usuario_id = p_usuario_id
        AND curso_id = p_curso_id;

        RETURN jsonb_build_object(
            'sucesso', true,
            'mensagem', 'Sessão ativa renovada.',
            'sessoes_ativas', v_sessoes_ativas,
            'limite', v_limite_simultaneo
        );
    END IF;

    -- Validar limite de sessões simultâneas
    IF v_sessoes_ativas >= v_limite_simultaneo THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'limite_atingido',
            'mensagem', 'Limite de acessos simultâneos atingido. Aguarde ou contate o administrador.',
            'sessoes_ativas', v_sessoes_ativas,
            'limite', v_limite_simultaneo
        );
    END IF;

    -- Criar nova sessão
    INSERT INTO sessoes_ativas (
        empresa_id,
        usuario_id,
        curso_id,
        session_token,
        ip_address,
        user_agent,
        ultimo_heartbeat,
        iniciada_em
    ) VALUES (
        v_empresa_id,
        p_usuario_id,
        p_curso_id,
        p_session_token,
        p_ip_address,
        p_user_agent,
        NOW(),
        NOW()
    );

    RETURN jsonb_build_object(
        'sucesso', true,
        'mensagem', 'Acesso liberado.',
        'sessoes_ativas', v_sessoes_ativas + 1,
        'limite', v_limite_simultaneo
    );
END;
$$;
```

---

### `rpc_encerrar_sessao()`

Encerra sessão ativa (logout).

```sql
CREATE OR REPLACE FUNCTION rpc_encerrar_sessao(
    p_session_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM sessoes_ativas
    WHERE session_token = p_session_token;

    IF FOUND THEN
        RETURN jsonb_build_object('sucesso', true, 'mensagem', 'Sessão encerrada.');
    ELSE
        RETURN jsonb_build_object('sucesso', false, 'mensagem', 'Sessão não encontrada.');
    END IF;
END;
$$;
```

---

## 3. RPCs de Navegação e Progresso

### `rpc_iniciar_aula()`

Inicia uma aula e retorna token de vídeo (se aplicável).

```sql
CREATE OR REPLACE FUNCTION rpc_iniciar_aula(
    p_aula_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_usuario_id UUID := auth.uid();
    v_aula RECORD;
    v_modulo_id UUID;
    v_curso_id UUID;
    v_matriculado BOOLEAN;
    v_aula_anterior_concluida BOOLEAN := true;
    v_empresa_ativa BOOLEAN;
    v_empresa_id UUID;
BEGIN
    -- Obter dados da aula
    SELECT a.*, m.curso_id, m.id as modulo_id
    INTO v_aula
    FROM aulas a
    JOIN modulos m ON m.id = a.modulo_id
    WHERE a.id = p_aula_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('sucesso', false, 'erro', 'aula_nao_encontrada');
    END IF;

    v_modulo_id := v_aula.modulo_id;
    v_curso_id := v_aula.curso_id;

    -- Verificar matrícula
    SELECT EXISTS (
        SELECT 1
        FROM usuario_curso
        WHERE usuario_id = v_usuario_id
        AND curso_id = v_curso_id
        AND status NOT IN ('bloqueado', 'expirado')
    ) INTO v_matriculado;

    IF NOT v_matriculado THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'sem_matricula',
            'mensagem', 'Você não está matriculado neste curso.'
        );
    END IF;

    -- Obter empresa e validar status
    SELECT empresa_id INTO v_empresa_id
    FROM usuario_curso
    WHERE usuario_id = v_usuario_id AND curso_id = v_curso_id;

    SELECT empresa_status_ativo(v_empresa_id) INTO v_empresa_ativa;

    IF NOT v_empresa_ativa THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'erro', 'empresa_inativa',
            'mensagem', 'Acesso encerrado pelo contrato.'
        );
    END IF;

    -- Validar progressão sequencial (aula anterior deve estar concluída)
    IF v_aula.ordem > 1 THEN
        SELECT COALESCE(
            (
                SELECT uap.concluida
                FROM aulas a_anterior
                LEFT JOIN usuario_aula_progresso uap
                    ON uap.aula_id = a_anterior.id
                    AND uap.usuario_id = v_usuario_id
                WHERE a_anterior.modulo_id = v_modulo_id
                AND a_anterior.ordem = v_aula.ordem - 1
                LIMIT 1
            ),
            false
        ) INTO v_aula_anterior_concluida;

        IF NOT v_aula_anterior_concluida THEN
            RETURN jsonb_build_object(
                'sucesso', false,
                'erro', 'aula_bloqueada',
                'mensagem', 'Complete a aula anterior para desbloquear esta.'
            );
        END IF;
    END IF;

    -- Criar ou atualizar progresso
    INSERT INTO usuario_aula_progresso (
        usuario_id,
        aula_id,
        data_inicio
    ) VALUES (
        v_usuario_id,
        p_aula_id,
        NOW()
    )
    ON CONFLICT (usuario_id, aula_id)
    DO UPDATE SET data_inicio = COALESCE(usuario_aula_progresso.data_inicio, NOW());

    -- Atualizar status do curso para 'em_andamento'
    UPDATE usuario_curso
    SET status = 'em_andamento',
        data_inicio = COALESCE(data_inicio, NOW())
    WHERE usuario_id = v_usuario_id
    AND curso_id = v_curso_id
    AND status = 'matriculado';

    -- Se for vídeo, gerar token Bunny.net (implementação simplificada)
    IF v_aula.tipo_conteudo = 'video' AND v_aula.bunny_video_id IS NOT NULL THEN
        -- Token temporário com TTL de 1 hora
        -- Implementação real deve chamar API do Bunny.net
        RETURN jsonb_build_object(
            'sucesso', true,
            'tipo', 'video',
            'video_token', encode(gen_random_bytes(32), 'hex'),
            'bunny_video_id', v_aula.bunny_video_id,
            'duracao_segundos', v_aula.duracao_segundos,
            'ttl_segundos', 3600
        );
    ELSE
        RETURN jsonb_build_object(
            'sucesso', true,
            'tipo', v_aula.tipo_conteudo,
            'conteudo_url', v_aula.conteudo_url,
            'conteudo_texto', v_aula.conteudo_texto
        );
    END IF;
END;
$$;
```

---

### `rpc_obter_proxima_aula()`

Retorna a próxima aula disponível do curso.

```sql
CREATE OR REPLACE FUNCTION rpc_obter_proxima_aula(
    p_curso_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_usuario_id UUID := auth.uid();
    v_proxima_aula RECORD;
BEGIN
    -- Buscar primeira aula não concluída (order by módulo.ordem, aula.ordem)
    SELECT a.id, a.titulo, a.tipo_conteudo, m.titulo as modulo_titulo
    INTO v_proxima_aula
    FROM aulas a
    JOIN modulos m ON m.id = a.modulo_id
    LEFT JOIN usuario_aula_progresso uap
        ON uap.aula_id = a.id
        AND uap.usuario_id = v_usuario_id
    WHERE m.curso_id = p_curso_id
    AND (uap.concluida IS NULL OR uap.concluida = false)
    ORDER BY m.ordem, a.ordem
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'sucesso', true,
            'aula_id', v_proxima_aula.id,
            'titulo', v_proxima_aula.titulo,
            'modulo', v_proxima_aula.modulo_titulo,
            'tipo', v_proxima_aula.tipo_conteudo
        );
    ELSE
        RETURN jsonb_build_object(
            'sucesso', true,
            'mensagem', 'Curso concluído.',
            'aula_id', NULL
        );
    END IF;
END;
$$;
```

---

## 4. Triggers

### `trg_atualizar_progresso_curso`

Atualiza o progresso percentual do curso quando progresso de aula muda.

```sql
CREATE OR REPLACE FUNCTION fn_atualizar_progresso_curso()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_curso_id UUID;
    v_total_aulas INTEGER;
    v_aulas_concluidas INTEGER;
    v_progresso DECIMAL(5,2);
BEGIN
    -- Obter curso_id da aula
    SELECT m.curso_id INTO v_curso_id
    FROM aulas a
    JOIN modulos m ON m.id = a.modulo_id
    WHERE a.id = NEW.aula_id;

    -- Contar total de aulas obrigatórias
    SELECT COUNT(*) INTO v_total_aulas
    FROM aulas a
    JOIN modulos m ON m.id = a.modulo_id
    WHERE m.curso_id = v_curso_id
    AND a.obrigatoria = true;

    -- Contar aulas concluídas
    SELECT COUNT(*) INTO v_aulas_concluidas
    FROM usuario_aula_progresso uap
    JOIN aulas a ON a.id = uap.aula_id
    JOIN modulos m ON m.id = a.modulo_id
    WHERE m.curso_id = v_curso_id
    AND uap.usuario_id = NEW.usuario_id
    AND uap.concluida = true
    AND a.obrigatoria = true;

    -- Calcular progresso
    IF v_total_aulas > 0 THEN
        v_progresso := (v_aulas_concluidas::DECIMAL / v_total_aulas::DECIMAL) * 100.00;
    ELSE
        v_progresso := 0.00;
    END IF;

    -- Atualizar usuario_curso
    UPDATE usuario_curso
    SET progresso_percentual = v_progresso,
        status = CASE
            WHEN v_progresso >= 100.00 THEN 'concluido'
            WHEN v_progresso > 0 THEN 'em_andamento'
            ELSE status
        END,
        data_conclusao = CASE
            WHEN v_progresso >= 100.00 AND data_conclusao IS NULL THEN NOW()
            ELSE data_conclusao
        END
    WHERE usuario_id = NEW.usuario_id
    AND curso_id = v_curso_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_atualizar_progresso_curso
AFTER INSERT OR UPDATE OF concluida ON usuario_aula_progresso
FOR EACH ROW
WHEN (NEW.concluida = true)
EXECUTE FUNCTION fn_atualizar_progresso_curso();
```

---

### `trg_gerar_flashcard_apos_erro`

Gera flashcard automaticamente quando aluno erra exercício.

```sql
CREATE OR REPLACE FUNCTION fn_gerar_flashcard_apos_erro()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_exercicio RECORD;
BEGIN
    IF NEW.correta = false THEN
        -- Obter dados do exercício
        SELECT e.*, a.titulo as aula_titulo
        INTO v_exercicio
        FROM exercicios e
        JOIN aulas a ON a.id = e.aula_id
        WHERE e.id = NEW.exercicio_id;

        -- Criar flashcard
        INSERT INTO flashcards_revisao (
            usuario_id,
            exercicio_id,
            resposta_id,
            frente,
            verso,
            dificuldade,
            proxima_revisao
        ) VALUES (
            NEW.usuario_id,
            NEW.exercicio_id,
            NEW.id,
            v_exercicio.enunciado,
            v_exercicio.explicacao_gabarito,
            'media',
            CURRENT_DATE + INTERVAL '1 day'
        )
        ON CONFLICT (usuario_id, exercicio_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_gerar_flashcard_apos_erro
AFTER INSERT OR UPDATE OF correta ON usuario_exercicio_resposta
FOR EACH ROW
WHEN (NEW.correta = false)
EXECUTE FUNCTION fn_gerar_flashcard_apos_erro();
```

---

### `trg_emitir_certificado`

Emite certificado automaticamente ao concluir curso com critérios.

```sql
CREATE OR REPLACE FUNCTION fn_emitir_certificado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_nota_minima DECIMAL(5,2) := 70.00; -- Nota mínima configurável
    v_carga_horaria INTEGER;
    v_codigo_validacao VARCHAR(50);
    v_empresa_id UUID;
BEGIN
    -- Só emitir se status for 'concluido' e ainda não tiver certificado
    IF NEW.status = 'concluido'
       AND NEW.progresso_percentual >= 100.00
       AND (NEW.nota_final IS NULL OR NEW.nota_final >= v_nota_minima)
       AND NOT EXISTS (
           SELECT 1 FROM certificados
           WHERE usuario_id = NEW.usuario_id
           AND curso_id = NEW.curso_id
       )
    THEN
        -- Obter carga horária do curso
        SELECT carga_horaria INTO v_carga_horaria
        FROM cursos
        WHERE id = NEW.curso_id;

        -- Gerar código único de validação
        v_codigo_validacao := 'CRT-' || UPPER(encode(gen_random_bytes(6), 'hex'));

        -- Inserir certificado
        INSERT INTO certificados (
            usuario_id,
            curso_id,
            empresa_id,
            codigo_validacao,
            nota_final,
            carga_horaria,
            data_emissao
        ) VALUES (
            NEW.usuario_id,
            NEW.curso_id,
            NEW.empresa_id,
            v_codigo_validacao,
            COALESCE(NEW.nota_final, 100.00),
            v_carga_horaria,
            NOW()
        );

        -- TODO: Enfileirar geração de PDF via edge function
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_emitir_certificado
AFTER UPDATE ON usuario_curso
FOR EACH ROW
WHEN (NEW.status = 'concluido')
EXECUTE FUNCTION fn_emitir_certificado();
```

---

## 5. Jobs Agendados (pg_cron ou similar)

### Limpeza de sessões expiradas

```sql
-- Executar a cada 5 minutos
SELECT cron.schedule(
    'limpar_sessoes_expiradas',
    '*/5 * * * *',
    $$
    DELETE FROM sessoes_ativas
    WHERE ultimo_heartbeat < NOW() - INTERVAL '5 minutes';
    $$
);
```

---

### Atualização de status de empresas expiradas

```sql
-- Executar diariamente às 00:00
SELECT cron.schedule(
    'atualizar_empresas_expiradas',
    '0 0 * * *',
    $$
    UPDATE empresas
    SET status = 'expirada'
    WHERE status = 'ativa'
    AND data_validade < CURRENT_DATE;
    $$
);
```

---

## 6. Índices de Performance

```sql
-- Índices para consultas frequentes
CREATE INDEX CONCURRENTLY idx_usuario_curso_lookup
ON usuario_curso(usuario_id, curso_id, status)
WHERE status NOT IN ('bloqueado', 'expirado');

CREATE INDEX CONCURRENTLY idx_sessoes_heartbeat_cleanup
ON sessoes_ativas(ultimo_heartbeat)
WHERE ultimo_heartbeat < NOW() - INTERVAL '5 minutes';

CREATE INDEX CONCURRENTLY idx_flashcards_revisao_agendada
ON flashcards_revisao(usuario_id, proxima_revisao)
WHERE proxima_revisao <= CURRENT_DATE;
```

---

## 7. Próximos Passos

- [ ] Implementar geração de token real do Bunny.net
- [ ] Implementar edge function para geração de PDF de certificados
- [ ] Criar views otimizadas para relatórios RH
- [ ] Implementar políticas RLS (documento separado)
- [ ] Testes unitários das funções críticas
