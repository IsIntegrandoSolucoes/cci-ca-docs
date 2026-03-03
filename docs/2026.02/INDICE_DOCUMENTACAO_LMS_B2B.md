# LMS + B2B - Índice de Documentação Técnica

**Data:** 2026-02-27  
**Atualizado em:** 2026-03-03  
**Status:** Implementação avançada  
**Versão:** 1.1

---

## 1. Visão Geral

Este índice organiza toda a documentação técnica da expansão LMS + B2B do sistema CCI-CA. Os documentos estão organizados por categoria e incluem ordem de leitura sugerida.

**Modelo de Licenciamento:** Controle por usuários simultâneos ativos (sem consumo por matrícula)  
**Progressão:** Sequencial obrigatória (uma aula por vez)  
**Vídeos:** Bunny.net (opção C) com tokens temporários  
**Arquitetura:** Database-driven com RLS multi-tenant  
**Monetização:** Assinatura mensal (SaaS) + split de pagamento sobre recebimentos dos alunos

---

## 2. Documentos por Categoria

### 2.1 📋 Requisitos e Planejamento

| Documento                                                  | Descrição                                                                                        | Última Atualização |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------ |
| [mudancas.md](mudancas.md)                                 | Documento mestre de requisitos e decisões técnicas                                                | 2026-02-27         |
| [ROADMAP_EXECUCAO_LMS_B2B.md](ROADMAP_EXECUCAO_LMS_B2B.md) | Roadmap, migrations, governança (RACI), backlog (US-001→US-021), UAT e riscos                    | 2026-02-27         |

**Leitura Recomendada:**

1. mudancas.md (entender requisitos e decisões)
2. ROADMAP_EXECUCAO_LMS_B2B.md (fases, migrations, sprints, governança, UAT)

---

### 2.2 🗄️ Banco de Dados e Estrutura

| Documento                                                  | Descrição                                                 | Última Atualização |
| ---------------------------------------------------------- | --------------------------------------------------------- | ------------------ |
| [SCHEMA_TABELAS_LMS_B2B.md](SCHEMA_TABELAS_LMS_B2B.md)     | Schema completo: 15 tabelas com DDL, constraints, índices | 2026-02-27         |
| [FUNCOES_TRIGGERS_LMS_B2B.md](FUNCOES_TRIGGERS_LMS_B2B.md) | Funções RPC, triggers automáticos, jobs agendados         | 2026-02-27         |
| [POLITICAS_RLS_LMS_B2B.md](POLITICAS_RLS_LMS_B2B.md)       | Políticas Row-Level Security para multi-tenancy           | 2026-02-27         |

**Ordem de Implementação:**

1. SCHEMA_TABELAS_LMS_B2B.md → Criar tabelas
2. FUNCOES_TRIGGERS_LMS_B2B.md (Seção 1) → Criar funções de apoio
3. POLITICAS_RLS_LMS_B2B.md → Habilitar RLS e criar políticas
4. FUNCOES_TRIGGERS_LMS_B2B.md (Seções 2-4) → Criar RPCs e triggers
5. FUNCOES_TRIGGERS_LMS_B2B.md (Seção 5) → Jobs agendados

---

### 2.3 🔐 Segurança e Permissões

| Documento                                            | Descrição                                                                     | Última Atualização |
| ---------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------ |
| [MATRIZ_RBAC_LMS_B2B.md](MATRIZ_RBAC_LMS_B2B.md)     | Matriz completa de permissões por perfil (admin, professor, gestor_rh, aluno) | 2026-02-27         |
| [POLITICAS_RLS_LMS_B2B.md](POLITICAS_RLS_LMS_B2B.md) | Políticas SQL detalhadas por tabela                                           | 2026-02-27         |

**Perfis do Sistema:**

- `admin_interno` - Equipe CCI-CA (acesso global)
- `professor` - Criadores de conteúdo (multi-tenant)
- `gestor_rh` - Gestores de empresas (tenant-specific)
- `aluno` - Colaboradores/estudantes (tenant-specific)

---

### 2.4 🎨 Interface e Rotas

| Documento                                            | Descrição                                        | Última Atualização |
| ---------------------------------------------------- | ------------------------------------------------ | ------------------ |
| [MAPA_ROTAS_UI_LMS_B2B.md](MAPA_ROTAS_UI_LMS_B2B.md) | Rotas completas com guards, layouts, componentes | 2026-02-27         |
| [mapa_telas_modulos.md](../mapa_telas_modulos.md)    | Inventário de telas existentes no sistema        | 2026-02-27         |

**Aplicações:**

- `cci-ca-admin` - Admin interno + Professor
- `cci-ca-aluno` - Aluno + Gestor RH

**Guards Implementados:**

- AuthGuard (requer autenticação)
- RoleGuard (valida perfil)
- SessionGuard (valida simultaneidade)

---

### 2.5 🔌 API e Integrações

| Documento                                            | Descrição                                | Última Atualização |
| ---------------------------------------------------- | ---------------------------------------- | ------------------ |
| [ENDPOINTS_API_LMS_B2B.md](ENDPOINTS_API_LMS_B2B.md) | Especificação completa de endpoints REST | 2026-02-27         |

**Módulos de API:**

1. Empresas (CRUD + licenças)
2. Colaboradores (convites + gestão)
3. Cursos (criação + edição)
4. Módulos e Aulas (estrutura + vídeos)
5. Matrículas (individual + lote)
6. Sessões Ativas (validação + heartbeat)
7. Progresso (iniciar + concluir aulas)
8. Exercícios (responder + feedback)
9. Flashcards (revisão espaçada)
10. Certificados (emissão + validação)
11. Relatórios (progresso + conclusão)
12. Anotações (timestamped)
13. Webhooks (Bunny.net)

---

## 3. Fluxos Principais

### 3.1 Fluxo: Matrícula de Colaborador

```mermaid
graph TD
    A[Gestor RH] --> B[Acessar /app/rh/matriculas/nova]
    B --> C[Selecionar colaborador + curso]
    C --> D[POST /api/v1/matriculas]
    D --> E{Já matriculado?}
    E -->|Não| F[Inserir usuario_curso]
    E -->|Sim| G[Retornar erro 409]
    F --> H[Enviar notificação ao aluno]
    H --> I[Matrícula concluída]
```

**Documentos Relacionados:**

- ENDPOINTS_API_LMS_B2B.md → Seção 6.1
- FUNCOES_TRIGGERS_LMS_B2B.md → `rpc_matricular_usuario_no_curso`
- MATRIZ_RBAC_LMS_B2B.md → Seção 2.9

---

### 3.2 Fluxo: Acesso Simultâneo (Player de Aula)

```mermaid
graph TD
    A[Aluno] --> B[Acessar /app/player/:cursoId/:aulaId]
    B --> C[SessionGuard: POST /api/v1/sessoes/validar]
    C --> D{Limite atingido?}
    D -->|Sim| E[Retornar erro 429]
    D -->|Não| F[Criar sessao_ativa]
    F --> G[Retornar video_token]
    G --> H[Renderizar player]
    H --> I[Heartbeat a cada 30s]
    I --> J{Heartbeat ativo?}
    J -->|Sim| I
    J -->|Não > 5min| K[Limpar sessao_ativa]
```

**Documentos Relacionados:**

- MAPA_ROTAS_UI_LMS_B2B.md → Seção 3.3 (Player)
- ENDPOINTS_API_LMS_B2B.md → Seções 7.1, 7.2
- FUNCOES_TRIGGERS_LMS_B2B.md → `rpc_validar_acesso_simultaneo`
- SCHEMA_TABELAS_LMS_B2B.md → Tabela `sessoes_ativas`

---

### 3.3 Fluxo: Emissão Automática de Certificado

```mermaid
graph TD
    A[Aluno] --> B[Concluir última aula obrigatória]
    B --> C[Trigger: trg_atualizar_progresso_curso]
    C --> D[UPDATE usuario_curso SET progresso = 100%]
    D --> E[Trigger: trg_emitir_certificado]
    E --> F{Critérios atendidos?}
    F -->|Sim| G[INSERT certificados]
    F -->|Não| H[Aguardar]
    G --> I[Enfileirar geração PDF]
    I --> J[Edge function gera PDF]
    J --> K[Certificado disponível]
```

**Documentos Relacionados:**

- FUNCOES_TRIGGERS_LMS_B2B.md → `trg_emitir_certificado`
- SCHEMA_TABELAS_LMS_B2B.md → Tabela `certificados`
- ENDPOINTS_API_LMS_B2B.md → Seção 11

---

### 3.4 Fluxo: Progressão Sequencial (Aula Bloqueada)

```mermaid
graph TD
    A[Aluno] --> B[Clicar em Aula 5]
    B --> C[POST /api/v1/aulas/:id/iniciar]
    C --> D{Aula 4 concluída?}
    D -->|Não| E[Retornar erro 403: aula_bloqueada]
    D -->|Sim| F[Validar sessão simultânea]
    F --> G[Retornar video_token]
    G --> H[Player carrega vídeo]
```

**Documentos Relacionados:**

- FUNCOES_TRIGGERS_LMS_B2B.md → `rpc_iniciar_aula`
- mudancas.md → Seção 2.3 (Decisão: Progressão sequencial)
- MAPA_ROTAS_UI_LMS_B2B.md → Seção 3.3

---

## 4. Guia de Implementação

### Fase 1: Banco de Dados e Backend

**Duração Estimada:** 2-3 semanas

**Checklist:**

- [x] Criar tabelas (SCHEMA_TABELAS_LMS_B2B.md) — 15 tabelas criadas
- [x] Criar funções de apoio RLS (FUNCOES_TRIGGERS_LMS_B2B.md - Seção 1)
- [x] Habilitar RLS e criar políticas (POLITICAS_RLS_LMS_B2B.md)
- [x] Criar RPCs transacionais (FUNCOES_TRIGGERS_LMS_B2B.md - Seções 2-3) — 22 RPCs
- [x] Criar triggers (FUNCOES_TRIGGERS_LMS_B2B.md - Seção 4) — 19 triggers
- [x] Criar índices de performance (FUNCOES_TRIGGERS_LMS_B2B.md - Seção 6)
- [x] Testes de RLS (POLITICAS_RLS_LMS_B2B.md - Seção 17)

**Status: ✅ Concluída** — 8 migrations aplicadas, 15 tabelas, 22 RPCs, 19 triggers, 5 views, RLS ativo

---

### Fase 2: API e Integrações

**Duração Estimada:** 2-3 semanas

**Checklist:**

- [x] Implementar endpoints de empresas (ENDPOINTS_API_LMS_B2B.md - Seção 2)
- [x] Implementar endpoints de colaboradores (Seção 3)
- [x] Implementar endpoints de cursos (Seção 4)
- [x] Implementar endpoints de matrículas (Seção 6)
- [x] Implementar endpoints de sessões (Seção 7)
- [x] Implementar endpoints de progresso (Seção 8)
- [x] Implementar endpoints de exercícios (Seção 9)
- [x] Implementar endpoints de flashcards (Seção 10)
- [x] Implementar endpoints de certificados (Seção 11)
- [x] Implementar endpoints de relatórios (Seção 12)
- [ ] Integração Bunny.net (upload + webhook) (Seção 14) — requer credenciais externas
- [ ] Testes de integração por endpoint

**Status: 🔄 10/12 itens concluídos** — LmsController com 40+ métodos, 47+ rotas. Pendente: Bunny.net e testes

---

### Fase 3: Frontend - Admin e Professor

**Duração Estimada:** 3-4 semanas

**Checklist:**

- [x] Implementar dashboard admin (MAPA_ROTAS_UI_LMS_B2B.md - Seção 1)
- [x] Implementar CRUD de empresas (Seção 1.2) — ListarEmpresas
- [x] Implementar dashboard professor (Seção 2.1) — DashboardProfessor + KPIs + tabela cursos
- [x] Implementar CRUD de cursos (Seção 2.2) — ListarCursos
- [x] Implementar gerenciamento de módulos/aulas — ListarModulos, ListarAulas
- [ ] Implementar uploader Bunny.net — requer credenciais externas
- [x] Implementar editor de mapas mentais — ListarMapasMentais
- [x] Implementar CRUD de exercícios — ListarExercicios
- [x] Implementar guards (Auth, Role) (Seção 9)
- [x] Implementar layouts (Admin, Professor) (Seção 8)

**Status: 🔄 9/10 itens concluídos** — Pendente: uploader Bunny.net (requer credenciais)

---

### Fase 4: Frontend - Aluno e RH

**Duração Estimada:** 3-4 semanas

**Checklist:**

- [x] Implementar dashboard aluno (MAPA_ROTAS_UI_LMS_B2B.md - Seção 3.1) — DashboardAlunoPage
- [x] Implementar catálogo de cursos (Seção 3.2) — MeusCursosPage
- [x] Implementar player de aula com controles (Seção 3.3) — AulaDetalhePage
- [x] Implementar SessionGuard (validação simultaneidade) (Seção 9.3) — useSessionGuard hook
- [x] Implementar heartbeat a cada 30s — integrado ao useSessionGuard
- [x] Implementar sistema de exercícios (Seção 3.4) — ExerciciosPage
- [x] Implementar flashcards com repetição espaçada (Seção 3.5) — FlashcardsPage
- [x] Implementar anotações timestamped (Seção 3.6) — AnotacoesPage + caderno global
- [x] Implementar visualização de certificados (Seção 3.7) — CertificadosPage
- [x] Implementar dashboard RH (Seção 4.1) — PainelRH (admin)
- [x] Implementar gestão de colaboradores (Seção 4.2) — ListarMatriculas (admin)
- [x] Implementar matrículas (individual + lote) (Seção 4.3)
- [x] Implementar painel de sessões ativas (realtime) (Seção 4.5) — ListarSessoesAtivas (admin)

**Status: ✅ Concluída** — Bloqueio de progressão sequencial + SessionGuard + heartbeat implementados

---

### Fase 5: Relatórios e Certificados

**Duração Estimada:** 1-2 semanas

**Checklist:**

- [x] Implementar relatórios de progresso (ENDPOINTS_API_LMS_B2B.md - Seção 12)
- [x] Implementar exportação CSV/PDF — Botão "Exportar CSV" no Painel RH (exportUtils.ts)
- [x] Implementar geração de PDF de certificado — certificadoPdfService.ts com pdf-lib
- [x] Implementar validação pública de certificado (QR Code)
- [x] Implementar trigger de emissão automática — trg_emitir_certificado
- [ ] Testes de emissão de certificados

**Status: 🔄 5/6 itens concluídos** — Pendente: testes de certificados

---

### Fase 6: Testes e Ajustes

**Duração Estimada:** 1-2 semanas

**Checklist:**

- [ ] Testes E2E completos por perfil (Playwright)
- [ ] Testes de carga (sessões simultâneas)
- [ ] Testes de segurança (RLS bypass attempts)
- [ ] Ajustes de performance (índices, queries)
- [ ] Documentação de API (Swagger)
- [ ] Guia de onboarding para usuários

**Pronto quando:**

- Taxa de sucesso E2E >= 95%
- Tempo de resposta p95 < 500ms
- Nenhum bypass de RLS encontrado
- Documentação completa e revisada

---

## 5. Dependências Técnicas

### 5.1 Tecnologias

| Tecnologia        | Versão | Uso                      |
| ----------------- | ------ | ------------------------ |
| PostgreSQL        | 15+    | Banco de dados principal |
| Supabase          | Latest | Auth + RLS + Realtime    |
| React             | 18/19  | Frontend (admin/aluno)   |
| TypeScript        | 5+     | Tipagem                  |
| MUI               | v5/v6  | Componentes UI           |
| React Router      | v6     | Navegação                |
| TanStack Query    | v5     | Cache + queries          |
| Zod               | Latest | Validação de schemas     |
| Bunny.net         | -      | Streaming de vídeos      |
| Netlify Functions | -      | Serverless backend       |

### 5.2 Integrações Externas

| Serviço         | Propósito                                 | Documentação                          |
| --------------- | ----------------------------------------- | ------------------------------------- |
| Bunny.net Video | Hospedagem e streaming de vídeos privados | https://docs.bunny.net/docs/stream    |
| Zoho Meeting    | Aulas ao vivo (futuro)                    | https://www.zoho.com/meeting/api.html |

---

## 6. Glossário

| Termo                                | Definição                                                                           |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| **Sessão Ativa**                     | Conexão ativa de um aluno em um curso específico, validada por heartbeat a cada 30s |
| **Limite Simultâneo**                | Número máximo de alunos que podem estar logados simultaneamente na empresa          |
| **Heartbeat**                        | Requisição periódica (30s) que mantém a sessão ativa e atualiza `ultimo_heartbeat`  |
| **Progressão Sequencial**            | Modelo em que aulas devem ser concluídas em ordem (não pode pular)                  |
| **RLS (Row-Level Security)**         | Políticas PostgreSQL que filtram dados por tenant/usuário automaticamente           |
| **RBAC (Role-Based Access Control)** | Controle de acesso baseado em perfis (admin, professor, gestor_rh, aluno)           |
| **Multi-tenant**                     | Arquitetura que isola dados de múltiplas empresas no mesmo banco                    |
| **Flashcard**                        | Cartão de revisão gerado automaticamente ao errar exercício                         |
| **Split de Pagamento**               | Divisão automática do pagamento do aluno entre a plataforma e o professor/empresa   |
| **Contrato Anual (B2B)**             | Contrato entre a empresa/curso e o aluno; a plataforma não é parte desse contrato   |
| **Bunny Video ID**                   | Identificador único do vídeo no Bunny.net                                           |
| **Video Token**                      | Token temporário (TTL 1h) para acesso ao vídeo privado                              |

---

## 7. Referências Rápidas

### 7.1 Tabelas Principais

| Tabela                   | Propósito                                     | Documento                 |
| ------------------------ | --------------------------------------------- | ------------------------- |
| `empresas`               | Dados das empresas B2B + limite simultâneo    | SCHEMA_TABELAS_LMS_B2B.md |
| `sessoes_ativas`         | Controle de acessos simultâneos em tempo real | SCHEMA_TABELAS_LMS_B2B.md |
| `usuario_curso`          | Matrículas (sem consumo de licença)           | SCHEMA_TABELAS_LMS_B2B.md |
| `usuario_aula_progresso` | Progresso detalhado por aula + heartbeat      | SCHEMA_TABELAS_LMS_B2B.md |
| `certificados`           | Certificados emitidos com QR Code             | SCHEMA_TABELAS_LMS_B2B.md |

### 7.2 RPCs Críticos

| RPC                               | Propósito                               | Documento                   |
| --------------------------------- | --------------------------------------- | --------------------------- |
| `rpc_validar_acesso_simultaneo`   | Valida limite e cria sessão ativa       | FUNCOES_TRIGGERS_LMS_B2B.md |
| `rpc_matricular_usuario_no_curso` | Matrícula individual sem consumo        | FUNCOES_TRIGGERS_LMS_B2B.md |
| `rpc_matricular_lote_b2b`         | Matrícula em massa via CSV              | FUNCOES_TRIGGERS_LMS_B2B.md |
| `rpc_iniciar_aula`                | Valida progressão e retorna token vídeo | FUNCOES_TRIGGERS_LMS_B2B.md |
| `rpc_obter_proxima_aula`          | Retorna próxima aula não concluída      | FUNCOES_TRIGGERS_LMS_B2B.md |

### 7.3 Endpoints Críticos

| Endpoint                                   | Propósito                           | Documento                |
| ------------------------------------------ | ----------------------------------- | ------------------------ |
| `POST /api/v1/sessoes/validar`             | Validar acesso simultâneo ao player | ENDPOINTS_API_LMS_B2B.md |
| `POST /api/v1/matriculas`                  | Matricular aluno individualmente    | ENDPOINTS_API_LMS_B2B.md |
| `POST /api/v1/matriculas/lote`             | Matricular via CSV                  | ENDPOINTS_API_LMS_B2B.md |
| `POST /api/v1/aulas/:id/iniciar`           | Iniciar aula com validações         | ENDPOINTS_API_LMS_B2B.md |
| `PUT /api/v1/sessoes/:token/heartbeat`     | Manter sessão ativa                 | ENDPOINTS_API_LMS_B2B.md |
| `GET /api/v1/certificados/validar/:codigo` | Validar certificado (público)       | ENDPOINTS_API_LMS_B2B.md |

---

## 8. Contatos e Suporte

**Equipe Técnica:**

- Backend/Database: [Contato]
- Frontend Admin: [Contato]
- Frontend Aluno: [Contato]
- Integrações: [Contato]

**Stakeholders:**

- Product Owner: [Contato]
- Gestor de Projeto: [Contato]

---

## 9. Histórico de Versões

| Versão | Data       | Autor          | Alterações                              |
| ------ | ---------- | -------------- | --------------------------------------- |
| 1.0    | 2026-02-27 | Equipe Técnica | Versão inicial completa do planejamento |
| 1.1    | 2026-03-03 | Equipe Técnica | Status de fases atualizado; modelo de monetização e split de pagamento documentado |

---

## 10. Próximos Passos

- [ ] Validar planejamento com stakeholders
- [ ] Priorizar fases com Product Owner
- [ ] Definir sprints e alocação de equipe
- [ ] Iniciar Fase 1: Banco de Dados e Backend
- [ ] Configurar ambientes (dev, staging, prod)
- [ ] Configurar CI/CD para migrações SQL
