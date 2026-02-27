-- Migration: Corrigir políticas RLS para sistema de anotações
-- Data: 2025-09-24
-- Descrição: Ajustar políticas RLS para funcionar sem autenticação JWT do Supabase Auth
-- Remover políticas existentes
DROP POLICY IF EXISTS "usuarios_acessam_proprias_anotacoes" ON anotacoes_aula;

DROP POLICY IF EXISTS "usuarios_acessam_proprios_audios" ON audio_aula;

DROP POLICY IF EXISTS "admins_visualizam_anotacoes" ON anotacoes_aula;

DROP POLICY IF EXISTS "admins_visualizam_audios" ON audio_aula;

-- Desabilitar RLS temporariamente para permitir operações até implementar autenticação adequada
ALTER TABLE
     anotacoes_aula DISABLE ROW LEVEL SECURITY;

ALTER TABLE
     audio_aula DISABLE ROW LEVEL SECURITY;

-- Comentário explicativo
COMMENT ON TABLE anotacoes_aula IS 'RLS desabilitado temporariamente - implementar autenticação adequada no futuro';

COMMENT ON TABLE audio_aula IS 'RLS desabilitado temporariamente - implementar autenticação adequada no futuro';