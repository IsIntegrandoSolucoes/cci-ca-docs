-- =====================================================
-- Migração: Criar tabela zoho_config
-- Descrição: Armazena credenciais OAuth do Zoho Meeting
-- Data: 2025-10-08
-- Autor: Sistema CCI-CA
-- =====================================================
-- Criar tabela para configurações do Zoho Meeting
CREATE TABLE IF NOT EXISTS public.zoho_config (
     id BIGSERIAL PRIMARY KEY,
     -- Identificação e controle
     descricao VARCHAR(255) NOT NULL COMMENT 'Descrição da configuração (ex: "Produção", "Homologação")',
     data_center VARCHAR(10) NOT NULL DEFAULT 'US' CHECK (data_center IN ('US', 'EU', 'IN', 'AU', 'CN')) COMMENT 'Data center do Zoho: US, EU, IN, AU, CN',
     -- Credenciais OAuth (CRIPTOGRAFADAS)
     client_id_encrypted TEXT NOT NULL COMMENT 'Client ID do Zoho OAuth criptografado com AES-256',
     client_secret_encrypted TEXT NOT NULL COMMENT 'Client Secret do Zoho OAuth criptografado com AES-256',
     -- Tokens OAuth
     access_token_encrypted TEXT COMMENT 'Access Token atual criptografado',
     refresh_token_encrypted TEXT COMMENT 'Refresh Token para renovação automática criptografado',
     token_expira_em TIMESTAMP WITH TIME ZONE COMMENT 'Data/hora de expiração do access_token',
     -- URLs de redirecionamento
     redirect_uri TEXT NOT NULL COMMENT 'URL de callback OAuth configurada no Zoho',
     -- Escopos OAuth
     scopes TEXT NOT NULL DEFAULT 'ZohoMeeting.meeting.CREATE,ZohoMeeting.meeting.READ,ZohoMeeting.meeting.UPDATE,ZohoMeeting.meeting.DELETE' COMMENT 'Escopos OAuth separados por vírgula',
     -- Status e controle
     ativo BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Indica se esta configuração está ativa',
     -- Auditoria
     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
     deleted_at TIMESTAMP WITH TIME ZONE,
     created_by BIGINT REFERENCES public.pessoas(id),
     updated_by BIGINT REFERENCES public.pessoas(id),
     -- Constraints
     CONSTRAINT zoho_config_unico_ativo UNIQUE (ativo)
     WHERE
          ativo = TRUE COMMENT 'Apenas uma configuração ativa por vez'
);

-- Índices para performance
CREATE INDEX idx_zoho_config_ativo ON public.zoho_config(ativo)
WHERE
     ativo = TRUE;

CREATE INDEX idx_zoho_config_data_center ON public.zoho_config(data_center);

-- Comentários da tabela
COMMENT ON TABLE public.zoho_config IS 'Configurações OAuth do Zoho Meeting com credenciais criptografadas';

-- Trigger para atualizar updated_at automaticamente
CREATE
OR REPLACE FUNCTION update_zoho_config_timestamp() RETURNS TRIGGER AS $ $ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;

RETURN NEW;

END;

$ $ LANGUAGE plpgsql;

CREATE TRIGGER trigger_zoho_config_updated_at BEFORE
UPDATE
     ON public.zoho_config FOR EACH ROW EXECUTE FUNCTION update_zoho_config_timestamp();

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
          'zoho_config',
          'Tabela criada para integração Zoho Meeting',
          'Estrutura inicial com 18 campos, suporte a OAuth 2.0 e criptografia AES-256'
     );

-- Log de sucesso
DO $ $ BEGIN RAISE NOTICE 'Migração 001_create_zoho_config_table.sql executada com sucesso!';

END $ $;