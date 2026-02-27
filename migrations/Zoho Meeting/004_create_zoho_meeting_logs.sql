-- =====================================================
-- Migração: Criar tabela zoho_meeting_logs
-- Descrição: Log de auditoria para operações Zoho API
-- Data: 2025-10-08
-- Autor: Sistema CCI-CA
-- =====================================================
-- Criar tabela para logs de auditoria Zoho
CREATE TABLE IF NOT EXISTS public.zoho_meeting_logs (
     id BIGSERIAL PRIMARY KEY,
     -- Relacionamentos
     fk_id_espaco_aula INTEGER REFERENCES public.espacos_aula(id) ON DELETE
     SET
          NULL COMMENT 'Referência ao espaço de aula (se aplicável)',
          fk_id_usuario BIGINT REFERENCES public.pessoas(id) ON DELETE
     SET
          NULL COMMENT 'Usuário que executou a operação',
          -- Detalhes da operação
          tipo_operacao VARCHAR(50) NOT NULL CHECK (
               tipo_operacao IN (
                    'criar_reuniao',
                    'atualizar_reuniao',
                    'deletar_reuniao',
                    'buscar_reuniao',
                    'listar_reunioes',
                    'obter_participantes',
                    'oauth_token_refresh',
                    'oauth_authorize',
                    'webhook_recebido'
               )
          ) COMMENT 'Tipo de operação realizada na API Zoho',
          metodo_http VARCHAR(10) CHECK (
               metodo_http IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE')
          ) COMMENT 'Método HTTP utilizado',
          endpoint_api TEXT NOT NULL COMMENT 'Endpoint completo da API Zoho chamada',
          -- Request/Response
          request_payload JSONB COMMENT 'Payload enviado na requisição (sanitizado)',
          response_payload JSONB COMMENT 'Resposta recebida da API',
          http_status_code INTEGER COMMENT 'Código de status HTTP da resposta',
          -- Resultado
          sucesso BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Indica se a operação foi bem-sucedida',
          erro_mensagem TEXT COMMENT 'Mensagem de erro (se houver)',
          erro_codigo VARCHAR(50) COMMENT 'Código de erro da API Zoho',
          erro_detalhes JSONB COMMENT 'Detalhes técnicos do erro',
          -- Performance
          tempo_resposta_ms INTEGER COMMENT 'Tempo de resposta da API em milissegundos',
          -- Contexto técnico
          ip_origem INET COMMENT 'IP de origem da requisição',
          user_agent TEXT COMMENT 'User agent do cliente',
          -- Rate Limiting
          rate_limit_remaining INTEGER COMMENT 'Requisições restantes no rate limit',
          rate_limit_reset TIMESTAMP WITH TIME ZONE COMMENT 'Horário de reset do rate limit',
          -- Metadados
          metadados JSONB COMMENT 'Metadados adicionais da operação',
          -- Auditoria
          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance e análise
CREATE INDEX idx_zoho_logs_espaco_aula ON public.zoho_meeting_logs(fk_id_espaco_aula)
WHERE
     fk_id_espaco_aula IS NOT NULL;

CREATE INDEX idx_zoho_logs_usuario ON public.zoho_meeting_logs(fk_id_usuario)
WHERE
     fk_id_usuario IS NOT NULL;

CREATE INDEX idx_zoho_logs_tipo_operacao ON public.zoho_meeting_logs(tipo_operacao);

CREATE INDEX idx_zoho_logs_sucesso ON public.zoho_meeting_logs(sucesso)
WHERE
     sucesso = false;

CREATE INDEX idx_zoho_logs_created_at ON public.zoho_meeting_logs(created_at DESC);

CREATE INDEX idx_zoho_logs_request_payload ON public.zoho_meeting_logs USING GIN (request_payload);

CREATE INDEX idx_zoho_logs_response_payload ON public.zoho_meeting_logs USING GIN (response_payload);

-- Particionamento por data (opcional - para grandes volumes)
-- CREATE INDEX idx_zoho_logs_created_at_brin 
--     ON public.zoho_meeting_logs USING BRIN (created_at);
-- Comentário da tabela
COMMENT ON TABLE public.zoho_meeting_logs IS 'Log completo de auditoria para todas as operações realizadas via Zoho Meeting API';

-- View para análise de erros
CREATE
OR REPLACE VIEW public.view_zoho_erros_recentes AS
SELECT
     id,
     tipo_operacao,
     endpoint_api,
     erro_codigo,
     erro_mensagem,
     http_status_code,
     tempo_resposta_ms,
     created_at,
     fk_id_usuario,
     fk_id_espaco_aula
FROM
     public.zoho_meeting_logs
WHERE
     sucesso = false
ORDER BY
     created_at DESC
LIMIT
     100;

COMMENT ON VIEW public.view_zoho_erros_recentes IS 'Últimos 100 erros na integração Zoho Meeting para análise rápida';

-- View para análise de performance
CREATE
OR REPLACE VIEW public.view_zoho_performance AS
SELECT
     tipo_operacao,
     COUNT(*) AS total_requisicoes,
     AVG(tempo_resposta_ms) AS tempo_medio_ms,
     MIN(tempo_resposta_ms) AS tempo_minimo_ms,
     MAX(tempo_resposta_ms) AS tempo_maximo_ms,
     PERCENTILE_CONT(0.95) WITHIN GROUP (
          ORDER BY
               tempo_resposta_ms
     ) AS p95_ms,
     SUM(
          CASE
               WHEN sucesso THEN 1
               ELSE 0
          END
     ) AS total_sucesso,
     SUM(
          CASE
               WHEN NOT sucesso THEN 1
               ELSE 0
          END
     ) AS total_erros,
     ROUND(
          (
               SUM(
                    CASE
                         WHEN sucesso THEN 1
                         ELSE 0
                    END
               ) :: NUMERIC / COUNT(*)
          ) * 100,
          2
     ) AS taxa_sucesso_pct
FROM
     public.zoho_meeting_logs
GROUP BY
     tipo_operacao
ORDER BY
     total_requisicoes DESC;

COMMENT ON VIEW public.view_zoho_performance IS 'Estatísticas de performance das operações Zoho Meeting API';

-- Função para limpar logs antigos (manutenção)
CREATE
OR REPLACE FUNCTION limpar_zoho_logs_antigos(dias INTEGER DEFAULT 90) RETURNS INTEGER AS $ $ DECLARE linhas_deletadas INTEGER;

BEGIN
DELETE FROM
     public.zoho_meeting_logs
WHERE
     created_at < (CURRENT_TIMESTAMP - (dias || ' days') :: INTERVAL)
     AND sucesso = TRUE;

-- Mantém logs de erro por mais tempo
GET DIAGNOSTICS linhas_deletadas = ROW_COUNT;

RETURN linhas_deletadas;

END;

$ $ LANGUAGE plpgsql;

COMMENT ON FUNCTION limpar_zoho_logs_antigos(INTEGER) IS 'Remove logs de sucesso mais antigos que X dias (padrão 90). Mantém logs de erro.';

-- Auditoria
INSERT INTO
     public.auditoria (
          created_at,
          nome_tabela,
          observacao,
          dado_atual
     )
VALUES
     (
          CURRENT_TIMESTAMP,
          'zoho_meeting_logs',
          'Tabela de auditoria criada para operações Zoho Meeting API',
          'Estrutura com 20 campos, 2 views analíticas e função de limpeza automática'
     );

-- Log de sucesso
DO $ $ BEGIN RAISE NOTICE 'Migração 004_create_zoho_meeting_logs.sql executada com sucesso!';

RAISE NOTICE 'Criadas 2 views: view_zoho_erros_recentes, view_zoho_performance';

RAISE NOTICE 'Criada função: limpar_zoho_logs_antigos(dias)';

END $ $;