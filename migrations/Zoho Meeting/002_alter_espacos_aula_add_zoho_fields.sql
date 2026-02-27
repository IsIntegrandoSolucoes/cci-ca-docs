-- =====================================================
-- Migração: Adicionar campos Zoho Meeting em espacos_aula
-- Descrição: Integra meeting IDs e URLs do Zoho Meeting
-- Data: 2025-10-08
-- Autor: Sistema CCI-CA
-- =====================================================
-- Adicionar campos relacionados ao Zoho Meeting
ALTER TABLE
     public.espacos_aula
ADD
     COLUMN IF NOT EXISTS zoho_meeting_key VARCHAR(100) COMMENT 'Session Key único da reunião no Zoho Meeting',
ADD
     COLUMN IF NOT EXISTS zoho_meeting_url TEXT COMMENT 'URL da reunião no Zoho Meeting (para o anfitrião)',
ADD
     COLUMN IF NOT EXISTS zoho_join_url TEXT COMMENT 'URL de entrada para participantes da reunião',
ADD
     COLUMN IF NOT EXISTS zoho_meeting_id VARCHAR(50) COMMENT 'ID numérico da reunião no Zoho Meeting',
ADD
     COLUMN IF NOT EXISTS zoho_meeting_status VARCHAR(20) DEFAULT 'nao_criado' CHECK (
          zoho_meeting_status IN (
               'nao_criado',
               'agendado',
               'em_andamento',
               'finalizado',
               'cancelado'
          )
     ) COMMENT 'Status da reunião no Zoho: nao_criado, agendado, em_andamento, finalizado, cancelado',
ADD
     COLUMN IF NOT EXISTS zoho_data_hora_inicio TIMESTAMP WITH TIME ZONE COMMENT 'Data/hora de início da reunião no Zoho',
ADD
     COLUMN IF NOT EXISTS zoho_data_hora_fim TIMESTAMP WITH TIME ZONE COMMENT 'Data/hora de término da reunião no Zoho',
ADD
     COLUMN IF NOT EXISTS zoho_duracao_minutos INTEGER COMMENT 'Duração planejada da reunião em minutos',
ADD
     COLUMN IF NOT EXISTS zoho_senha_reuniao VARCHAR(50) COMMENT 'Senha opcional para proteger a reunião',
ADD
     COLUMN IF NOT EXISTS zoho_permite_gravacao BOOLEAN DEFAULT false COMMENT 'Indica se a gravação está habilitada para esta reunião',
ADD
     COLUMN IF NOT EXISTS zoho_ultimo_sincronismo TIMESTAMP WITH TIME ZONE COMMENT 'Data/hora da última sincronização com Zoho API',
ADD
     COLUMN IF NOT EXISTS zoho_erro_ultimo_sincronismo TEXT COMMENT 'Mensagem de erro da última tentativa de sincronização (se houver)';

-- Índices para otimizar consultas
CREATE INDEX IF NOT EXISTS idx_espacos_aula_zoho_meeting_key ON public.espacos_aula(zoho_meeting_key)
WHERE
     zoho_meeting_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_espacos_aula_zoho_meeting_status ON public.espacos_aula(zoho_meeting_status);

CREATE INDEX IF NOT EXISTS idx_espacos_aula_zoho_data_inicio ON public.espacos_aula(zoho_data_hora_inicio)
WHERE
     zoho_data_hora_inicio IS NOT NULL;

-- Constraint única para Meeting Key quando não nulo
CREATE UNIQUE INDEX IF NOT EXISTS idx_espacos_aula_zoho_meeting_key_unique ON public.espacos_aula(zoho_meeting_key)
WHERE
     zoho_meeting_key IS NOT NULL
     AND deleted_at IS NULL;

-- Comentário atualizado da tabela
COMMENT ON TABLE public.espacos_aula IS 'Hub centralizado para aulas não contratuais com links únicos, materiais de apoio e integração Zoho Meeting para videoconferências';

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
          'espacos_aula',
          'Adicionados 12 campos para integração Zoho Meeting',
          'Campos: zoho_meeting_key, zoho_meeting_url, zoho_join_url, zoho_meeting_id, zoho_meeting_status, zoho_data_hora_inicio, zoho_data_hora_fim, zoho_duracao_minutos, zoho_senha_reuniao, zoho_permite_gravacao, zoho_ultimo_sincronismo, zoho_erro_ultimo_sincronismo'
     );

-- Log de sucesso
DO $ $ BEGIN RAISE NOTICE 'Migração 002_alter_espacos_aula_add_zoho_fields.sql executada com sucesso!';

RAISE NOTICE 'Adicionados 12 campos Zoho Meeting à tabela espacos_aula';

END $ $;