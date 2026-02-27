-- =====================================================
-- MASTER MIGRATION FILE - Zoho Meeting Integration
-- Descrição: Executa todas as migrações Zoho em ordem
-- Data: 2025-10-08
-- Autor: Sistema CCI-CA
-- =====================================================
-- ⚠️ ATENÇÃO: Este arquivo executa TODAS as migrações Zoho
-- Certifique-se de ter um backup antes de executar!
-- Iniciar transação para rollback em caso de erro
BEGIN;

DO $ $ BEGIN RAISE NOTICE '============================================';

RAISE NOTICE 'INICIANDO MIGRAÇÕES ZOHO MEETING';

RAISE NOTICE 'Data: %',
CURRENT_TIMESTAMP;

RAISE NOTICE 'Banco: %',
CURRENT_DATABASE();

RAISE NOTICE '============================================';

END $ $;

-- =====================================================
-- MIGRAÇÃO 1: Criar tabela zoho_config
-- =====================================================
\ echo 'Executando: 001_create_zoho_config_table.sql' \ i 001_create_zoho_config_table.sql -- =====================================================
-- MIGRAÇÃO 2: Adicionar campos Zoho em espacos_aula
-- =====================================================
\ echo 'Executando: 002_alter_espacos_aula_add_zoho_fields.sql' \ i 002_alter_espacos_aula_add_zoho_fields.sql -- =====================================================
-- MIGRAÇÃO 3: Criar tabela zoho_meeting_participantes
-- =====================================================
\ echo 'Executando: 003_create_zoho_meeting_participantes.sql' \ i 003_create_zoho_meeting_participantes.sql -- =====================================================
-- MIGRAÇÃO 4: Criar tabela zoho_meeting_logs
-- =====================================================
\ echo 'Executando: 004_create_zoho_meeting_logs.sql' \ i 004_create_zoho_meeting_logs.sql -- =====================================================
-- VALIDAÇÃO PÓS-MIGRAÇÃO
-- =====================================================
DO $ $ DECLARE tabelas_criadas INTEGER;

campos_espacos_aula INTEGER;

views_criadas INTEGER;

funcoes_criadas INTEGER;

BEGIN -- Contar tabelas Zoho criadas
SELECT
     COUNT(*) INTO tabelas_criadas
FROM
     information_schema.tables
WHERE
     table_schema = 'public'
     AND table_name IN (
          'zoho_config',
          'zoho_meeting_participantes',
          'zoho_meeting_logs'
     );

-- Contar campos Zoho adicionados em espacos_aula
SELECT
     COUNT(*) INTO campos_espacos_aula
FROM
     information_schema.columns
WHERE
     table_schema = 'public'
     AND table_name = 'espacos_aula'
     AND column_name LIKE '%zoho%';

-- Contar views criadas
SELECT
     COUNT(*) INTO views_criadas
FROM
     pg_views
WHERE
     schemaname = 'public'
     AND viewname LIKE '%zoho%';

-- Contar funções criadas
SELECT
     COUNT(*) INTO funcoes_criadas
FROM
     information_schema.routines
WHERE
     routine_schema = 'public'
     AND routine_name LIKE '%zoho%';

RAISE NOTICE '============================================';

RAISE NOTICE 'VALIDAÇÃO PÓS-MIGRAÇÃO';

RAISE NOTICE '============================================';

RAISE NOTICE 'Tabelas criadas: % (esperado: 3)',
tabelas_criadas;

RAISE NOTICE 'Campos em espacos_aula: % (esperado: 12)',
campos_espacos_aula;

RAISE NOTICE 'Views criadas: % (esperado: 2)',
views_criadas;

RAISE NOTICE 'Funções criadas: % (esperado: 3+)',
funcoes_criadas;

RAISE NOTICE '============================================';

-- Validar se tudo foi criado corretamente
IF tabelas_criadas != 3 THEN RAISE EXCEPTION 'Erro: Esperado 3 tabelas Zoho, encontrado %',
tabelas_criadas;

END IF;

IF campos_espacos_aula != 12 THEN RAISE EXCEPTION 'Erro: Esperado 12 campos Zoho em espacos_aula, encontrado %',
campos_espacos_aula;

END IF;

IF views_criadas != 2 THEN RAISE EXCEPTION 'Erro: Esperado 2 views, encontrado %',
views_criadas;

END IF;

RAISE NOTICE '✅ Todas as validações passaram com sucesso!';

END $ $;

-- =====================================================
-- COMMIT FINAL
-- =====================================================
COMMIT;

DO $ $ BEGIN RAISE NOTICE '============================================';

RAISE NOTICE '✅ MIGRAÇÕES ZOHO MEETING CONCLUÍDAS!';

RAISE NOTICE 'Tabelas criadas:';

RAISE NOTICE '  - zoho_config (18 campos)';

RAISE NOTICE '  - zoho_meeting_participantes (25 campos)';

RAISE NOTICE '  - zoho_meeting_logs (20 campos)';

RAISE NOTICE 'Tabelas modificadas:';

RAISE NOTICE '  - espacos_aula (+12 campos Zoho)';

RAISE NOTICE 'Views criadas:';

RAISE NOTICE '  - view_zoho_erros_recentes';

RAISE NOTICE '  - view_zoho_performance';

RAISE NOTICE 'Funções criadas:';

RAISE NOTICE '  - limpar_zoho_logs_antigos(dias)';

RAISE NOTICE '  - update_zoho_config_timestamp()';

RAISE NOTICE '  - update_zoho_participantes_timestamp()';

RAISE NOTICE '============================================';

RAISE NOTICE 'Próximos passos:';

RAISE NOTICE '1. Implementar serviços TypeScript';

RAISE NOTICE '2. Criar endpoints API';

RAISE NOTICE '3. Desenvolver componentes frontend';

RAISE NOTICE '4. Configurar políticas RLS';

RAISE NOTICE '============================================';

END $ $;