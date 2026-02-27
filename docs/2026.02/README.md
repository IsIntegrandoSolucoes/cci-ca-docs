# LMS + B2B - Planejamento Técnico Completo

> **Status:** ✅ Planejamento finalizado  
> **Data:** 27 de fevereiro de 2026  
> **Versão:** 1.0

---

## 🎯 Objetivo

Documentação técnica completa para implementação da expansão **LMS + B2B** no sistema CCI-CA (Consultório de Aprendizagem).

**Principais Features:**

- ✅ Controle de usuários simultâneos (não consumo por matrícula)
- ✅ Progressão sequencial obrigatória
- ✅ Streaming privado via Bunny.net
- ✅ Multi-tenancy com RLS
- ✅ Matrículas em lote (CSV)
- ✅ Certificados automáticos com QR Code
- ✅ Flashcards com repetição espaçada
- ✅ Player com anotações timestamped

---

## 📚 Documentos (Ordem de Leitura)

### 1️⃣ Comece Aqui

**[INDICE_DOCUMENTACAO_LMS_B2B.md](INDICE_DOCUMENTACAO_LMS_B2B.md)** ⭐  
_Índice completo com fluxos, guia de implementação e referências rápidas._

---

### 2️⃣ Requisitos e Decisões

**[mudancas.md](mudancas.md)**  
Documento mestre com requisitos funcionais, regras de negócio e decisões técnicas.

**Principais Decisões:**

- Progressão: Sequencial obrigatória (opção A)
- Vídeos: Bunny.net com tokens temporários (opção C)
- Licenciamento: Controle por usuários simultâneos ativos

---

### 3️⃣ Banco de Dados

**[SCHEMA_TABELAS_LMS_B2B.md](SCHEMA_TABELAS_LMS_B2B.md)**  
_15 tabelas com DDL completo, constraints, índices e regras de negócio._

**Tabelas Críticas:**

- `sessoes_ativas` - Controle de acessos simultâneos
- `usuario_curso` - Matrículas sem consumo
- `usuario_aula_progresso` - Heartbeat e progresso individual
- `certificados` - Emissão automática com QR Code

**[FUNCOES_TRIGGERS_LMS_B2B.md](FUNCOES_TRIGGERS_LMS_B2B.md)**  
_Funções RPC, triggers e jobs agendados._

**Principais RPCs:**

- `rpc_validar_acesso_simultaneo()` - Valida limite e cria sessão
- `rpc_matricular_lote_b2b()` - Matrícula em massa
- `rpc_iniciar_aula()` - Valida progressão e retorna token

**Principais Triggers:**

- `trg_atualizar_progresso_curso` - Calcula % de conclusão
- `trg_gerar_flashcard_apos_erro` - Cria flashcard automático
- `trg_emitir_certificado` - Emite certificado ao concluir

---

### 4️⃣ Segurança

**[POLITICAS_RLS_LMS_B2B.md](POLITICAS_RLS_LMS_B2B.md)**  
_Políticas Row-Level Security detalhadas para 15 tabelas._

**Isolamento:**

- Multi-tenant por `empresa_id`
- Validação de sessão ativa (heartbeat < 5min)
- Progressão sequencial obrigatória

**[MATRIZ_RBAC_LMS_B2B.md](MATRIZ_RBAC_LMS_B2B.md)**  
_Matriz de permissões por perfil._

**Perfis:**

- `admin_interno` - Acesso global
- `professor` - Criação de conteúdo
- `gestor_rh` - Gestão de colaboradores
- `aluno` - Consumo de conteúdo

---

### 5️⃣ Interface

**[MAPA_ROTAS_UI_LMS_B2B.md](MAPA_ROTAS_UI_LMS_B2B.md)**  
_Rotas completas com componentes, guards e layouts._

**Aplicações:**

- `cci-ca-admin` - Admin interno + Professor
- `cci-ca-aluno` - Aluno + Gestor RH

**Guards:**

- `AuthGuard` - Requer autenticação
- `RoleGuard` - Valida perfil
- `SessionGuard` - Valida simultaneidade

---

### 6️⃣ API

**[ENDPOINTS_API_LMS_B2B.md](ENDPOINTS_API_LMS_B2B.md)**  
_Especificação completa de endpoints REST._

**Módulos:**

- Empresas, Colaboradores, Cursos, Matrículas
- Sessões Ativas, Progresso, Exercícios
- Flashcards, Certificados, Relatórios
- Webhooks (Bunny.net)

---

### 7️⃣ Roadmap

**[ROADMAP_EXECUCAO_LMS_B2B.md](ROADMAP_EXECUCAO_LMS_B2B.md)**  
_Fases de implementação com "Pronto quando"._

**Fases:**

1. Banco de Dados (2-3 semanas)
2. API e Integrações (2-3 semanas)
3. Frontend Admin/Professor (3-4 semanas)
4. Frontend Aluno/RH (3-4 semanas)
5. Relatórios e Certificados (1-2 semanas)
6. Testes e Ajustes (1-2 semanas)

**Total Estimado:** 11-18 semanas

**[PLANO_MIGRATIONS_SQL_LMS_B2B.md](PLANO_MIGRATIONS_SQL_LMS_B2B.md)**  
_Sequência de migrações SQL com testes._

---

## 🚀 Quick Start (Implementação)

### Passo 1: Banco de Dados

```bash
# 1. Criar tabelas
psql -f SCHEMA_TABELAS_LMS_B2B.sql

# 2. Criar funções de apoio
psql -f funcoes_apoio_rls.sql

# 3. Habilitar RLS
psql -f politicas_rls.sql

# 4. Criar RPCs e triggers
psql -f funcoes_triggers.sql

# 5. Criar índices
psql -f indices_performance.sql
```

### Passo 2: Validar RLS

```bash
# Testar isolamento multi-tenant
npm run test:rls
```

### Passo 3: API

```bash
# cci-ca-api
npm run dev

# Testar endpoints
npm run test:api
```

### Passo 4: Frontend

```bash
# cci-ca-admin
cd cci-ca-admin
npm run dev

# cci-ca-aluno
cd cci-ca-aluno
npm run dev
```

---

## 📊 Arquitetura

```
┌─────────────────────────────────────────────────┐
│                  Frontend                        │
├───────────────────┬─────────────────────────────┤
│   cci-ca-admin    │      cci-ca-aluno           │
│  (Admin/Prof)     │      (Aluno/RH)             │
└─────────┬─────────┴─────────┬───────────────────┘
          │                   │
          ▼                   ▼
┌─────────────────────────────────────────────────┐
│            Netlify Functions (API)              │
│  ┌─────────────────────────────────────────┐   │
│  │  Auth, RBAC, Validação                  │   │
│  └─────────────────────────────────────────┘   │
└─────────┬───────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────┐
│          Supabase (PostgreSQL)                  │
│  ┌─────────────────────────────────────────┐   │
│  │  RLS Policies (Multi-tenant)            │   │
│  │  Functions/Triggers (Business Logic)    │   │
│  │  Realtime (Sessões Ativas)              │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────┐
│              Integrações                        │
│  • Bunny.net (vídeos)                           │
│  • Zoho Meeting (aulas ao vivo - futuro)        │
└─────────────────────────────────────────────────┘
```

---

## 🔑 Conceitos-Chave

### Sessão Ativa

Conexão validada de um aluno em um curso, mantida por heartbeat a cada 30s. Expira após 5min de inatividade.

**Fluxo:**

1. Aluno acessa player → `POST /api/v1/sessoes/validar`
2. Sistema valida limite simultâneo
3. Se OK, cria registro em `sessoes_ativas`
4. Frontend envia heartbeat a cada 30s → `PUT /api/v1/sessoes/:token/heartbeat`
5. Job agendado limpa sessões expiradas (> 5min sem heartbeat)

### Progressão Sequencial

Aluno deve concluir aulas em ordem. Não pode pular.

**Validação:**

```sql
-- Em rpc_iniciar_aula()
IF v_aula.ordem > 1 THEN
    SELECT uap.concluida INTO v_aula_anterior_concluida
    FROM aulas a_anterior
    LEFT JOIN usuario_aula_progresso uap
        ON uap.aula_id = a_anterior.id
        AND uap.usuario_id = v_usuario_id
    WHERE a_anterior.modulo_id = v_modulo_id
    AND a_anterior.ordem = v_aula.ordem - 1;

    IF NOT v_aula_anterior_concluida THEN
        RETURN jsonb_build_object('sucesso', false, 'erro', 'aula_bloqueada');
    END IF;
END IF;
```

### Matrícula sem Consumo

Matrícula não consome licença. Licença controla **acessos simultâneos** apenas.

**Tabelas:**

- `empresas.limite_usuarios_simultaneos` - Limite contratado (ex: 30)
- `sessoes_ativas` - Sessões ativas no momento (ex: 25)
- `usuario_curso` - Matrículas (sem limite, pode ter 1000 matrículas)

**Validação no Login:**

```typescript
if (sessoes_ativas_count >= limite_usuarios_simultaneos) {
  return { erro: 'limite_atingido', status: 429 }
}
```

---

## 🧪 Testes

### RLS (Row-Level Security)

```sql
-- Como aluno da empresa A, tentar acessar sessões da empresa B
SET ROLE aluno_empresa_a;
SELECT * FROM sessoes_ativas; -- Deve retornar apenas da empresa A
```

### Simultaneidade

```bash
# Simular 31 logins simultâneos quando limite é 30
npm run test:concorrencia -- --users=31 --limit=30
# Espera: 30 sucessos, 1 erro 429
```

### Progressão

```bash
# Tentar acessar aula 5 sem concluir aula 4
curl -X POST /api/v1/aulas/:aula5/iniciar
# Espera: 403 Forbidden, erro='aula_bloqueada'
```

---

## 📈 Métricas de Sucesso

| Métrica                                | Meta               |
| -------------------------------------- | ------------------ |
| Taxa de conclusão de cursos            | >= 70%             |
| Tempo médio de resposta (p95)          | < 500ms            |
| Uptime                                 | >= 99.5%           |
| Erro de RLS bypass                     | 0 (zero tolerance) |
| Taxa de bloqueio por limite simultâneo | < 5% dos acessos   |
| Satisfação de professores (NPS)        | >= 8/10            |
| Satisfação de alunos (NPS)             | >= 8/10            |

---

## 🐛 Troubleshooting

### Problema: Sessão não expira

**Causa:** Heartbeat continua sendo enviado após fechar aba.

**Solução:**

```typescript
// Adicionar listener de beforeunload
window.addEventListener('beforeunload', () => {
  fetch('/api/v1/sessoes/:token', { method: 'DELETE', keepalive: true })
})
```

### Problema: Erro 429 mesmo com limite disponível

**Causa:** Sessões expiradas não foram limpas.

**Solução:**

```sql
-- Forçar limpeza manual
DELETE FROM sessoes_ativas
WHERE ultimo_heartbeat < NOW() - INTERVAL '5 minutes';

-- Verificar job agendado
SELECT * FROM cron.job WHERE jobname = 'limpar_sessoes_expiradas';
```

### Problema: Certificado não é emitido

**Causa:** Trigger não disparou ou critérios não atendidos.

**Verificar:**

```sql
-- Progresso do curso
SELECT progresso_percentual, nota_final, status
FROM usuario_curso
WHERE usuario_id = :user_id AND curso_id = :curso_id;

-- Deve ser: progresso_percentual >= 100, status = 'concluido'
```

---

## 📞 Suporte

**Dúvidas sobre planejamento:**  
Consulte [INDICE_DOCUMENTACAO_LMS_B2B.md](INDICE_DOCUMENTACAO_LMS_B2B.md) para referências rápidas.

**Dúvidas técnicas:**  
Verifique o documento específico do seu módulo (ver índice).

**Issues:**  
Reporte problemas na implementação através dos canais da equipe.

---

## 📝 Licença

© 2026 CCI-CA (Consultório de Aprendizagem AEMASUL)  
Documentação técnica interna - Todos os direitos reservados.
