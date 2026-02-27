-- ====================================================================
-- Migration: Sistema de Múltiplos Recebedores
-- Data: 13/10/2025
-- Descrição: Permite configurar N recebedores por modalidade/participante
-- ====================================================================
-- 1. CRIAR TABELA DE RECEBEDORES
-- ====================================================================
CREATE TABLE IF NOT EXISTS configuracao_recebedores (
     id SERIAL PRIMARY KEY,
     -- Relacionamento com configuração de taxa
     fk_id_configuracao_modalidade INTEGER REFERENCES configuracao_taxas_modalidade(id),
     fk_id_configuracao_participante INTEGER REFERENCES configuracao_taxas_participante(id),
     -- Dados do recebedor
     identificador_recebedor VARCHAR(50) NOT NULL,
     tipo_recebedor VARCHAR(20) NOT NULL CHECK (
          tipo_recebedor IN ('Convenio', 'Participante', 'Terceiro')
     ),
     tipo_pagamento VARCHAR(10) NOT NULL CHECK (tipo_pagamento IN ('PIX', 'BOLETO')),
     -- Tipo de valor (Percentual ou Fixo)
     tipo_valor VARCHAR(15) NOT NULL CHECK (tipo_valor IN ('Percentual', 'Fixo')),
     valor DECIMAL(10, 2) NOT NULL,
     -- Ordem de exibição
     ordem INTEGER NOT NULL DEFAULT 0,
     -- Descrição/observações
     descricao VARCHAR(255),
     -- Controle
     ativo BOOLEAN DEFAULT TRUE,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     created_by INTEGER,
     updated_by INTEGER,
     deleted_at TIMESTAMP,
     deleted_by INTEGER,
     -- Constraints
     CONSTRAINT check_apenas_uma_configuracao CHECK (
          (
               fk_id_configuracao_modalidade IS NOT NULL
               AND fk_id_configuracao_participante IS NULL
          )
          OR (
               fk_id_configuracao_modalidade IS NULL
               AND fk_id_configuracao_participante IS NOT NULL
          )
     ),
     CONSTRAINT check_valor_positivo CHECK (valor > 0),
     CONSTRAINT check_percentual_valido CHECK (
          tipo_valor != 'Percentual'
          OR (
               valor >= 0
               AND valor <= 100
          )
     )
);

-- 2. CRIAR ÍNDICES
-- ====================================================================
CREATE INDEX idx_recebedores_modalidade ON configuracao_recebedores(fk_id_configuracao_modalidade);

CREATE INDEX idx_recebedores_participante ON configuracao_recebedores(fk_id_configuracao_participante);

CREATE INDEX idx_recebedores_tipo_pagamento ON configuracao_recebedores(tipo_pagamento);

CREATE INDEX idx_recebedores_ativo ON configuracao_recebedores(ativo);

-- 3. FUNÇÃO: BUSCAR RECEBEDORES POR CONFIGURAÇÃO
-- ====================================================================
CREATE
OR REPLACE FUNCTION buscar_recebedores_configuracao(
     p_id_modalidade_aula INTEGER,
     p_id_pessoa INTEGER DEFAULT NULL,
     p_tipo_pagamento VARCHAR(10) DEFAULT 'PIX'
) RETURNS TABLE(
     id INTEGER,
     identificador_recebedor VARCHAR(50),
     tipo_recebedor VARCHAR(20),
     tipo_valor VARCHAR(15),
     valor DECIMAL(10, 2),
     ordem INTEGER,
     descricao VARCHAR(255),
     fonte VARCHAR(50)
) AS $ $ BEGIN -- Prioridade 1: Configuração específica do participante
IF p_id_pessoa IS NOT NULL THEN RETURN QUERY
SELECT
     cr.id,
     cr.identificador_recebedor,
     cr.tipo_recebedor,
     cr.tipo_valor,
     cr.valor,
     cr.ordem,
     cr.descricao,
     'participante' :: VARCHAR(50) AS fonte
FROM
     configuracao_recebedores cr
     INNER JOIN configuracao_taxas_participante ctp ON cr.fk_id_configuracao_participante = ctp.id
WHERE
     ctp.fk_id_pessoa = p_id_pessoa
     AND ctp.fk_id_modalidade_aula = p_id_modalidade_aula
     AND cr.tipo_pagamento = p_tipo_pagamento
     AND cr.ativo = TRUE
     AND ctp.ativo = TRUE
     AND (
          ctp.data_inicio IS NULL
          OR ctp.data_inicio <= CURRENT_DATE
     )
     AND (
          ctp.data_fim IS NULL
          OR ctp.data_fim >= CURRENT_DATE
     )
ORDER BY
     cr.ordem,
     cr.id;

IF FOUND THEN RETURN;

END IF;

END IF;

-- Prioridade 2: Configuração padrão da modalidade
RETURN QUERY
SELECT
     cr.id,
     cr.identificador_recebedor,
     cr.tipo_recebedor,
     cr.tipo_valor,
     cr.valor,
     cr.ordem,
     cr.descricao,
     'modalidade' :: VARCHAR(50) AS fonte
FROM
     configuracao_recebedores cr
     INNER JOIN configuracao_taxas_modalidade ctm ON cr.fk_id_configuracao_modalidade = ctm.id
WHERE
     ctm.fk_id_modalidade_aula = p_id_modalidade_aula
     AND cr.tipo_pagamento = p_tipo_pagamento
     AND cr.ativo = TRUE
     AND ctm.ativo = TRUE
ORDER BY
     cr.ordem,
     cr.id;

END;

$ $ LANGUAGE plpgsql;

-- 4. FUNÇÃO: VALIDAR SOMA DE PERCENTUAIS
-- ====================================================================
CREATE
OR REPLACE FUNCTION validar_soma_percentuais() RETURNS TRIGGER AS $ $ DECLARE soma_percentuais DECIMAL(10, 2);

id_config INTEGER;

BEGIN -- Determinar qual configuração usar
IF NEW.fk_id_configuracao_modalidade IS NOT NULL THEN id_config := NEW.fk_id_configuracao_modalidade;

SELECT
     COALESCE(SUM(valor), 0) INTO soma_percentuais
FROM
     configuracao_recebedores
WHERE
     fk_id_configuracao_modalidade = id_config
     AND tipo_pagamento = NEW.tipo_pagamento
     AND tipo_valor = 'Percentual'
     AND ativo = TRUE
     AND (
          TG_OP = 'INSERT'
          OR id != NEW.id
     );

ELSE id_config := NEW.fk_id_configuracao_participante;

SELECT
     COALESCE(SUM(valor), 0) INTO soma_percentuais
FROM
     configuracao_recebedores
WHERE
     fk_id_configuracao_participante = id_config
     AND tipo_pagamento = NEW.tipo_pagamento
     AND tipo_valor = 'Percentual'
     AND ativo = TRUE
     AND (
          TG_OP = 'INSERT'
          OR id != NEW.id
     );

END IF;

-- Adicionar novo valor se for percentual
IF NEW.tipo_valor = 'Percentual' THEN soma_percentuais := soma_percentuais + NEW.valor;

END IF;

-- Validar soma
IF NEW.tipo_valor = 'Percentual'
AND soma_percentuais > 100 THEN RAISE EXCEPTION 'A soma dos percentuais não pode exceder 100%%. Soma atual: %%',
soma_percentuais;

END IF;

RETURN NEW;

END;

$ $ LANGUAGE plpgsql;

-- Criar trigger
CREATE TRIGGER trigger_validar_soma_percentuais BEFORE
INSERT
     OR
UPDATE
     ON configuracao_recebedores FOR EACH ROW EXECUTE FUNCTION validar_soma_percentuais();

-- 5. MIGRAR DADOS EXISTENTES (CONFIGURAÇÕES PADRÃO)
-- ====================================================================
-- Para cada configuração de modalidade, criar recebedores baseados nos valores PIX/BOLETO
-- PIX - Convênio (valor da taxa da plataforma)
INSERT INTO
     configuracao_recebedores (
          fk_id_configuracao_modalidade,
          identificador_recebedor,
          tipo_recebedor,
          tipo_pagamento,
          tipo_valor,
          valor,
          ordem,
          descricao,
          ativo,
          created_by
     )
SELECT
     id,
     '125530' AS identificador_recebedor,
     'Convenio' AS tipo_recebedor,
     'PIX' AS tipo_pagamento,
     pix_tipo AS tipo_valor,
     CASE
          WHEN pix_tipo = 'Percentual' THEN 100 - pix_valor
          ELSE pix_valor
     END AS valor,
     1 AS ordem,
     'Convênio CCI-CA' AS descricao,
     TRUE AS ativo,
     created_by
FROM
     configuracao_taxas_modalidade
WHERE
     ativo = TRUE;

-- PIX - Participante (professor)
INSERT INTO
     configuracao_recebedores (
          fk_id_configuracao_modalidade,
          identificador_recebedor,
          tipo_recebedor,
          tipo_pagamento,
          tipo_valor,
          valor,
          ordem,
          descricao,
          ativo,
          created_by
     )
SELECT
     id,
     'DINAMICO' AS identificador_recebedor,
     'Participante' AS tipo_recebedor,
     'PIX' AS tipo_pagamento,
     pix_tipo AS tipo_valor,
     pix_valor AS valor,
     2 AS ordem,
     'Professor' AS descricao,
     TRUE AS ativo,
     created_by
FROM
     configuracao_taxas_modalidade
WHERE
     ativo = TRUE;

-- BOLETO - Convênio
INSERT INTO
     configuracao_recebedores (
          fk_id_configuracao_modalidade,
          identificador_recebedor,
          tipo_recebedor,
          tipo_pagamento,
          tipo_valor,
          valor,
          ordem,
          descricao,
          ativo,
          created_by
     )
SELECT
     id,
     '125530' AS identificador_recebedor,
     'Convenio' AS tipo_recebedor,
     'BOLETO' AS tipo_pagamento,
     boleto_tipo AS tipo_valor,
     CASE
          WHEN boleto_tipo = 'Percentual' THEN 100 - boleto_valor
          ELSE boleto_valor
     END AS valor,
     1 AS ordem,
     'Convênio CCI-CA' AS descricao,
     TRUE AS ativo,
     created_by
FROM
     configuracao_taxas_modalidade
WHERE
     ativo = TRUE;

-- BOLETO - Participante
INSERT INTO
     configuracao_recebedores (
          fk_id_configuracao_modalidade,
          identificador_recebedor,
          tipo_recebedor,
          tipo_pagamento,
          tipo_valor,
          valor,
          ordem,
          descricao,
          ativo,
          created_by
     )
SELECT
     id,
     'DINAMICO' AS identificador_recebedor,
     'Participante' AS tipo_recebedor,
     'BOLETO' AS tipo_pagamento,
     boleto_tipo AS tipo_valor,
     boleto_valor AS valor,
     2 AS ordem,
     'Professor' AS descricao,
     TRUE AS ativo,
     created_by
FROM
     configuracao_taxas_modalidade
WHERE
     ativo = TRUE;

-- 6. COMENTÁRIOS E DOCUMENTAÇÃO
-- ====================================================================
COMMENT ON TABLE configuracao_recebedores IS 'Configuração de múltiplos recebedores por modalidade ou participante';

COMMENT ON COLUMN configuracao_recebedores.identificador_recebedor IS 'Número do participante ou convênio. DINAMICO para buscar do professor';

COMMENT ON COLUMN configuracao_recebedores.tipo_recebedor IS 'Convenio, Participante ou Terceiro';

COMMENT ON COLUMN configuracao_recebedores.tipo_valor IS 'Percentual (%) ou Fixo (R$)';

COMMENT ON COLUMN configuracao_recebedores.valor IS 'Percentual ou valor fixo a receber';

COMMENT ON COLUMN configuracao_recebedores.ordem IS 'Ordem de exibição dos recebedores';

-- ====================================================================
-- FIM DA MIGRATION
-- ====================================================================
-- Verificação dos dados migrados
SELECT
     ctm.id AS config_id,
     ma.nome AS modalidade,
     cr.tipo_pagamento,
     cr.tipo_recebedor,
     cr.tipo_valor,
     cr.valor,
     cr.ordem
FROM
     configuracao_recebedores cr
     INNER JOIN configuracao_taxas_modalidade ctm ON cr.fk_id_configuracao_modalidade = ctm.id
     INNER JOIN modalidade_aula ma ON ctm.fk_id_modalidade_aula = ma.id
WHERE
     cr.ativo = TRUE
ORDER BY
     ctm.id,
     cr.tipo_pagamento,
     cr.ordem;