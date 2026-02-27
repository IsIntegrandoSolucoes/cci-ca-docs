-- Migração: Inserir configurações padrão de taxas por modalidade
-- Data: 2025-01-10
-- Descrição: Migra as configurações hardcoded para o banco de dados
-- Inserir configurações padrão de taxas por modalidade
INSERT INTO
     configuracao_taxas_modalidade (
          modalidade_id,
          taxa_recebedor_pix,
          taxa_plataforma_pix,
          taxa_recebedor_conta,
          taxa_plataforma_conta
     )
VALUES
     (1, 0.85, 0.15, 0.90, 0.10),
     -- Aula Particular
     (2, 0.80, 0.20, 0.85, 0.15),
     -- Aula em Grupo  
     (3, 0.75, 0.25, 0.80, 0.20),
     -- Curso Pré-Prova
     (4, 0.90, 0.10, 0.95, 0.05),
     -- Contrato Mensal
     (5, 0.90, 0.10, 0.95, 0.05),
     -- Turma Vestibular
     (6, 0.85, 0.15, 0.90, 0.10);

-- Turma Mentoria
-- Verificar se os dados foram inseridos corretamente
SELECT
     modalidade_id,
     taxa_recebedor_pix * 100 || '% / ' || taxa_plataforma_pix * 100 || '%' AS "PIX (Recebedor/Plataforma)",
     taxa_recebedor_conta * 100 || '% / ' || taxa_plataforma_conta * 100 || '%' AS "Conta (Recebedor/Plataforma)",
     ativo,
     created_at
FROM
     configuracao_taxas_modalidade
ORDER BY
     modalidade_id;