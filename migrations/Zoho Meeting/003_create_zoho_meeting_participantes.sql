-- =====================================================
-- Migração: Criar tabela zoho_meeting_participantes
-- Descrição: Armazena relatório de participantes das reuniões
-- Data: 2025-10-08
-- Autor: Sistema CCI-CA
-- =====================================================
-- Criar tabela para participantes das reuniões Zoho
CREATE TABLE IF NOT EXISTS public.zoho_meeting_participantes (
     id BIGSERIAL PRIMARY KEY,
     -- Relacionamentos
     fk_id_espaco_aula INTEGER NOT NULL REFERENCES public.espacos_aula(id) ON DELETE CASCADE COMMENT 'Referência ao espaço de aula associado',
     fk_id_aluno BIGINT REFERENCES public.pessoas(id) ON DELETE
     SET
          NULL COMMENT 'Referência ao aluno (se identificado)',
          -- Dados do participante (vindos da API Zoho)
          zoho_participante_id VARCHAR(100) COMMENT 'ID do participante no Zoho Meeting',
          nome_participante VARCHAR(255) NOT NULL COMMENT 'Nome do participante na reunião',
          email_participante VARCHAR(255) COMMENT 'Email do participante (se fornecido)',
          -- Dados de presença
          horario_entrada TIMESTAMP WITH TIME ZONE NOT NULL COMMENT 'Horário de entrada na reunião',
          horario_saida TIMESTAMP WITH TIME ZONE COMMENT 'Horário de saída da reunião',
          duracao_minutos INTEGER COMMENT 'Duração da participação em minutos',
          -- Tipo de participação
          tipo_participante VARCHAR(20) DEFAULT 'convidado' CHECK (
               tipo_participante IN (
                    'organizador',
                    'apresentador',
                    'convidado',
                    'ouvinte'
               )
          ) COMMENT 'Tipo de participante: organizador, apresentador, convidado, ouvinte',
          -- Dados técnicos
          ip_participante INET COMMENT 'Endereço IP do participante',
          navegador VARCHAR(100) COMMENT 'Navegador utilizado',
          dispositivo VARCHAR(50) COMMENT 'Tipo de dispositivo (desktop, mobile, tablet)',
          sistema_operacional VARCHAR(50) COMMENT 'Sistema operacional do participante',
          -- Status e qualidade
          status_conexao VARCHAR(20) DEFAULT 'boa' CHECK (
               status_conexao IN ('excelente', 'boa', 'regular', 'ruim')
          ) COMMENT 'Qualidade da conexão reportada',
          -- Interações durante a reunião
          usou_audio BOOLEAN DEFAULT false COMMENT 'Participante utilizou áudio',
          usou_video BOOLEAN DEFAULT false COMMENT 'Participante utilizou vídeo',
          compartilhou_tela BOOLEAN DEFAULT false COMMENT 'Participante compartilhou tela',
          total_mensagens_chat INTEGER DEFAULT 0 COMMENT 'Total de mensagens enviadas no chat',
          -- Dados RAW da API
          dados_brutos_api JSONB COMMENT 'Resposta completa da API Zoho para referência futura',
          -- Auditoria
          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          sincronizado_em TIMESTAMP WITH TIME ZONE COMMENT 'Data/hora da última sincronização com Zoho API'
);

-- Índices para performance
CREATE INDEX idx_zoho_participantes_espaco_aula ON public.zoho_meeting_participantes(fk_id_espaco_aula);

CREATE INDEX idx_zoho_participantes_aluno ON public.zoho_meeting_participantes(fk_id_aluno)
WHERE
     fk_id_aluno IS NOT NULL;

CREATE INDEX idx_zoho_participantes_email ON public.zoho_meeting_participantes(email_participante)
WHERE
     email_participante IS NOT NULL;

CREATE INDEX idx_zoho_participantes_entrada ON public.zoho_meeting_participantes(horario_entrada);

CREATE INDEX idx_zoho_participantes_dados_brutos ON public.zoho_meeting_participantes USING GIN (dados_brutos_api);

-- Comentário da tabela
COMMENT ON TABLE public.zoho_meeting_participantes IS 'Relatório detalhado de participantes das reuniões Zoho Meeting com dados de presença e interação';

-- Trigger para atualizar updated_at
CREATE
OR REPLACE FUNCTION update_zoho_participantes_timestamp() RETURNS TRIGGER AS $ $ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;

RETURN NEW;

END;

$ $ LANGUAGE plpgsql;

CREATE TRIGGER trigger_zoho_participantes_updated_at BEFORE
UPDATE
     ON public.zoho_meeting_participantes FOR EACH ROW EXECUTE FUNCTION update_zoho_participantes_timestamp();

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
          'zoho_meeting_participantes',
          'Tabela criada para armazenar participantes de reuniões Zoho Meeting',
          'Estrutura inicial com 25 campos incluindo dados de presença, interações e qualidade de conexão'
     );

-- Log de sucesso
DO $ $ BEGIN RAISE NOTICE 'Migração 003_create_zoho_meeting_participantes.sql executada com sucesso!';

END $ $;