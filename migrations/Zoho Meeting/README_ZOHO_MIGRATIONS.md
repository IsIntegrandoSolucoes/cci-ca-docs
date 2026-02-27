# 📋 Migrações SQL - Integração Zoho Meeting

## Visão Geral

Este diretório contém as migrações SQL para integrar o **Zoho Meeting** ao sistema CCI-CA, permitindo videoconferências nos espaços de aula.

---

## 🗂️ Arquivos de Migração

### **001_create_zoho_config_table.sql**

**Descrição**: Cria tabela para armazenar credenciais OAuth do Zoho Meeting

**Estrutura**:

-    18 campos incluindo credenciais criptografadas
-    Suporte a múltiplos data centers (US, EU, IN, AU, CN)
-    Sistema de refresh token automático
-    Constraint de configuração única ativa

**Campos principais**:

-    `client_id_encrypted`: Client ID criptografado (AES-256)
-    `client_secret_encrypted`: Client Secret criptografado (AES-256)
-    `access_token_encrypted`: Token de acesso atual
-    `refresh_token_encrypted`: Token para renovação
-    `token_expira_em`: Expiração do token
-    `data_center`: Data center Zoho (US, EU, IN, AU, CN)

**Segurança**: ✅ Todas as credenciais armazenadas com **criptografia AES-256**

---

### **002_alter_espacos_aula_add_zoho_fields.sql**

**Descrição**: Adiciona 12 campos Zoho Meeting na tabela `espacos_aula`

**Campos adicionados**:

```sql
- zoho_meeting_key         -- Session Key único da reunião
- zoho_meeting_url         -- URL para o anfitrião
- zoho_join_url            -- URL para participantes
- zoho_meeting_id          -- ID numérico da reunião
- zoho_meeting_status      -- Status: nao_criado, agendado, em_andamento, finalizado, cancelado
- zoho_data_hora_inicio    -- Data/hora de início
- zoho_data_hora_fim       -- Data/hora de término
- zoho_duracao_minutos     -- Duração planejada
- zoho_senha_reuniao       -- Senha opcional
- zoho_permite_gravacao    -- Flag de gravação
- zoho_ultimo_sincronismo  -- Timestamp da última sync
- zoho_erro_ultimo_sincronismo -- Mensagem de erro (se houver)
```

**Índices criados**:

-    `idx_espacos_aula_zoho_meeting_key` (único, não nulo)
-    `idx_espacos_aula_zoho_meeting_status`
-    `idx_espacos_aula_zoho_data_inicio`

---

### **003_create_zoho_meeting_participantes.sql**

**Descrição**: Cria tabela para relatórios de participantes das reuniões

**Estrutura**:

-    25 campos incluindo dados de presença e interação
-    Relacionamento com `espacos_aula` e `pessoas`
-    Suporte a dados RAW da API (JSONB)

**Dados armazenados**:

-    **Presença**: horário entrada/saída, duração
-    **Interações**: áudio, vídeo, compartilhamento de tela, chat
-    **Qualidade**: status de conexão, navegador, dispositivo
-    **Raw API**: resposta completa da API para auditoria

**Exemplo de uso**:

```sql
-- Buscar participantes de uma aula específica
SELECT
    nome_participante,
    horario_entrada,
    duracao_minutos,
    usou_video,
    total_mensagens_chat
FROM zoho_meeting_participantes
WHERE fk_id_espaco_aula = 123
ORDER BY horario_entrada;
```

---

### **004_create_zoho_meeting_logs.sql**

**Descrição**: Cria sistema completo de auditoria para operações Zoho API

**Estrutura**:

-    20 campos incluindo request/response, performance, rate limiting
-    2 views analíticas (`view_zoho_erros_recentes`, `view_zoho_performance`)
-    Função de limpeza automática de logs antigos

**Tipos de operação registrados**:

```typescript
-criar_reuniao - atualizar_reuniao - deletar_reuniao - buscar_reuniao - listar_reunioes - obter_participantes - oauth_token_refresh - oauth_authorize - webhook_recebido;
```

**Views disponíveis**:

**1. `view_zoho_erros_recentes`**

```sql
-- Últimos 100 erros para análise
SELECT * FROM view_zoho_erros_recentes;
```

**2. `view_zoho_performance`**

```sql
-- Estatísticas de performance por operação
SELECT
    tipo_operacao,
    total_requisicoes,
    tempo_medio_ms,
    taxa_sucesso_pct
FROM view_zoho_performance;
```

**Função de manutenção**:

```sql
-- Limpar logs de sucesso com mais de 90 dias
SELECT limpar_zoho_logs_antigos(90);
```

---

## 🚀 Como Executar as Migrações

### **Opção 1: Via Supabase Dashboard**

1. Acesse o [Supabase Dashboard](https://supabase.com/dashboard)
2. Vá em **SQL Editor**
3. Copie e cole o conteúdo de cada arquivo `.sql` em ordem
4. Execute clicando em **Run**

### **Opção 2: Via API Supabase (MCP)**

```typescript
import { mcp_supabase_apply_migration } from '@supabase/mcp';

// Exemplo de aplicação via código
await mcp_supabase_apply_migration({
     project_id: 'dvkpysaaejmdpstapboj',
     name: 'create_zoho_config_table',
     query: fs.readFileSync('./migrations/001_create_zoho_config_table.sql', 'utf8'),
});
```

### **Opção 3: Via Terminal (psql)**

```bash
# Conectar ao banco
psql -h db.dvkpysaaejmdpstapboj.supabase.co -U postgres -d postgres

# Executar migrações em ordem
\i migrations/001_create_zoho_config_table.sql
\i migrations/002_alter_espacos_aula_add_zoho_fields.sql
\i migrations/003_create_zoho_meeting_participantes.sql
\i migrations/004_create_zoho_meeting_logs.sql
```

---

## ✅ Verificação Pós-Migração

Execute os seguintes comandos para validar:

```sql
-- 1. Verificar tabelas criadas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%zoho%';

-- Resultado esperado:
-- zoho_config
-- zoho_meeting_participantes
-- zoho_meeting_logs

-- 2. Verificar campos adicionados em espacos_aula
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'espacos_aula'
  AND column_name LIKE '%zoho%';

-- Resultado esperado: 12 campos

-- 3. Verificar views criadas
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE '%zoho%';

-- Resultado esperado:
-- view_zoho_erros_recentes
-- view_zoho_performance

-- 4. Verificar função de limpeza
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%zoho%';

-- Resultado esperado:
-- limpar_zoho_logs_antigos
```

---

## 📊 Estrutura de Dados Final

### **Diagrama de Relacionamentos**

```
┌─────────────────────┐
│   zoho_config       │
│  (Credenciais OAuth)│
└─────────────────────┘
          │
          │ (uso global)
          │
┌─────────▼─────────────┐       ┌──────────────────────────┐
│  espacos_aula         │◄──────│ zoho_meeting_participantes│
│  (+ 12 campos Zoho)   │       │  (Relatório de presença)  │
└───────────────────────┘       └──────────────────────────┘
          │
          │
          ▼
┌─────────────────────┐
│ zoho_meeting_logs   │
│  (Auditoria API)    │
└─────────────────────┘
```

### **Tabelas e seus propósitos**

| Tabela                       | Registros Esperados | Propósito                      |
| ---------------------------- | ------------------- | ------------------------------ |
| `zoho_config`                | 1-3                 | Credenciais OAuth por ambiente |
| `espacos_aula`               | 35+                 | Espaços de aula com meetings   |
| `zoho_meeting_participantes` | Milhares            | Histórico de participação      |
| `zoho_meeting_logs`          | Dezenas de milhares | Auditoria completa             |

---

## 🔐 Segurança

### **Criptografia**

-    ✅ Credenciais OAuth criptografadas com **AES-256**
-    ✅ Tokens de acesso nunca armazenados em texto plano
-    ✅ Logs sanitizados (sem dados sensíveis)

### **RLS (Row Level Security)**

-    ⚠️ **IMPORTANTE**: Habilitar RLS nas tabelas Zoho em produção
-    📋 **TODO**: Implementar políticas RLS por perfil de usuário

```sql
-- Exemplo de políticas RLS (implementar futuramente)
ALTER TABLE public.zoho_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Apenas admins podem ver configurações Zoho"
ON public.zoho_config
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM pessoas p
    WHERE p.id = auth.uid()::bigint
      AND p.fk_id_tipo_pessoa = 1 -- Admin
  )
);
```

---

## 📈 Monitoramento

### **Queries úteis para monitoramento**

```sql
-- 1. Taxa de sucesso das operações Zoho (últimas 24h)
SELECT
    COUNT(*) FILTER (WHERE sucesso) as sucessos,
    COUNT(*) FILTER (WHERE NOT sucesso) as erros,
    ROUND(
        (COUNT(*) FILTER (WHERE sucesso)::NUMERIC / COUNT(*)) * 100,
        2
    ) as taxa_sucesso_pct
FROM zoho_meeting_logs
WHERE created_at > NOW() - INTERVAL '24 hours';

-- 2. Reuniões ativas no momento
SELECT
    ea.id,
    ea.titulo_espaco,
    ea.zoho_meeting_status,
    ea.zoho_data_hora_inicio,
    ea.zoho_data_hora_fim,
    COUNT(zmp.id) as total_participantes
FROM espacos_aula ea
LEFT JOIN zoho_meeting_participantes zmp ON zmp.fk_id_espaco_aula = ea.id
WHERE ea.zoho_meeting_status = 'em_andamento'
GROUP BY ea.id, ea.titulo_espaco, ea.zoho_meeting_status,
         ea.zoho_data_hora_inicio, ea.zoho_data_hora_fim;

-- 3. Performance média por operação (última semana)
SELECT * FROM view_zoho_performance;

-- 4. Erros recentes que precisam atenção
SELECT * FROM view_zoho_erros_recentes
WHERE created_at > NOW() - INTERVAL '1 hour';
```

---

## 🧹 Manutenção

### **Limpeza automática de logs**

```sql
-- Executar mensalmente via cron job
SELECT limpar_zoho_logs_antigos(90); -- Mantém 90 dias de logs de sucesso
```

### **Backup antes de executar migrações**

```bash
# Backup via pg_dump
pg_dump -h db.dvkpysaaejmdpstapboj.supabase.co \
        -U postgres \
        -d postgres \
        --table=espacos_aula \
        --table=pessoas \
        > backup_pre_zoho_$(date +%Y%m%d).sql
```

---

## 📚 Referências

-    [Zoho Meeting API Documentation](https://www.zoho.com/meeting/api/)
-    [OAuth 2.0 Flow - Zoho](https://www.zoho.com/meeting/api/oauth-overview.html)
-    [Supabase PostgreSQL Documentation](https://supabase.com/docs/guides/database)

---

## 🎯 Próximos Passos

Após executar as migrações, prosseguir com:

1. ✅ **Criar serviços TypeScript** (`ZohoAuthService`, `ZohoMeetingService`)
2. ✅ **Implementar endpoints API** (`/api/zoho/*`)
3. ✅ **Desenvolver componentes frontend** (Admin e Aluno)
4. 📋 **Implementar políticas RLS** para segurança adicional
5. 📋 **Configurar webhooks Zoho** para sincronização em tempo real

---

**Data de criação**: 08/10/2025  
**Versão**: 1.0.0  
**Autor**: Sistema CCI-CA  
**Status**: ✅ Pronto para execução
