# Roadmap de Execucao - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (sem implementacao)  
**Base:** mudancas.md + decisoes A/A/C + plano RLS

---

## 1. Escopo Fechado

Regras de negocio fechadas:
- Controle por usuarios simultaneos ativos (sem consumo por matricula)
- Progressao sequencial obrigatoria
- Video privado com Bunny.net

Repositorios impactados:
- cci-ca-admin
- cci-ca-aluno
- cci-ca-api
- cci-ca-docs

---

## 2. Fases e Entregas

### Fase 0 - Preparacao e Contratos de API

Objetivo:
- Definir contratos de dados, payloads e codigos de erro antes de codar telas

Entregas:
- Dicionario de entidades (empresa, licenca, curso, modulo, aula, matricula, progresso)
- Contratos de API/RPC para matricula, progresso, iniciar aula
- Padrao de mensagens para bloqueio por contrato/licenca

Pronto quando:
- Admin, Aluno e API usam os mesmos nomes e status

### Fase 1 - Core B2B + Matricula Segura

Objetivo:
- Colocar de pe o tenant corporativo com controle de sessoes simultaneas

Entregas backend (cci-ca-api + banco):
- Tabelas de empresas, usuarios da empresa, licencas (limite simultaneo), matriculas
- Tabela de sessoes_ativas com registro de login/logout
- RPC transacional de matricula (sem consumo de licenca)
- RPC de validacao de acesso simultaneo
- RLS minima por tenant e perfil

Entregas frontend admin (cci-ca-admin):
- Telas: Empresas, Licencas (limite simultaneo), Matricula em lote
- Painel de sessoes ativas em tempo real
- Erros de negocio claros (limite simultaneo atingido, empresa suspensa/expirada)

Entregas frontend aluno (cci-ca-aluno):
- Tela Meus Cursos com status bloqueado por contrato
- Mensagem clara ao atingir limite de sessoes

Pronto quando:
- RH consegue matricular colaboradores ilimitados
- Sistema bloqueia novo login ao atingir limite simultaneo
- Dashboard mostra sessões ativas vs limite contratado

### Fase 2 - Catalogo LMS + Progressao Sequencial

Objetivo:
- Disponibilizar cursos com trilha obrigatoria

Entregas backend:
- Tabelas de cursos/modulos/aulas com campo ordem
- Tabela de progresso por aula
- Trigger para atualizar progresso do curso
- RPC para obter proxima aula liberada

Entregas admin:
- CRUD de cursos/modulos/aulas
- Configuracao de aula obrigatoria

Entregas aluno:
- Player com trilha e bloqueio de aulas futuras
- Persistencia de progresso (last_position)

Pronto quando:
- Aluno nao consegue pular modulo pela URL

### Fase 3 - Video Seguro (Bunny.net)

Objetivo:
- Viabilizar upload e playback seguro de videos

Entregas backend:
- Integracao de upload com Bunny.net (TUS/resumable)
- Geracao de token de reproducao com TTL curto
- Auditoria de inicio de reproducao

Entregas admin:
- Upload de video por aula
- Estado de processamento/publicacao do video

Entregas aluno:
- Player com token temporario
- Tratamento de token expirado com renovacao controlada

Pronto quando:
- URL final do video nao fica exposta em tabela publica

### Fase 4 - LXP (Mapas Mentais, Exercicios, Flashcards)

Objetivo:
- Aumentar retencao e personalizacao do estudo

Entregas backend:
- Mapas mentais por aula
- Respostas de exercicios e correcao
- Trigger de flashcard a partir de erro

Entregas admin:
- Criador de mapa mental por aula
- Criador de exercicios (objetiva/dissertativa)

Entregas aluno:
- Caderno inteligente (texto e audio transcrito)
- Resolucao de exercicios
- Tela de flashcards de revisao

Pronto quando:
- Erros em exercicios geram trilha de revisao automatica

### Fase 5 - Certificados e Relatorios RH

Objetivo:
- Fechar o ciclo corporativo com evidencia e governanca

Entregas backend:
- Regras de conclusao (nota minima + obrigatorias)
- Emissao de certificado com codigo e QR
- Views de relatorio por tenant

Entregas admin:
- Painel de conclusao/desempenho por empresa

Entregas aluno:
- Download do certificado
- Visualizacao de historico de conclusoes

Pronto quando:
- RH enxerga apenas dados do proprio tenant

---

## 3. Ordem de Implementacao por Repositorio

1. cci-ca-api
- Primeiro banco + RPC + RLS

2. cci-ca-admin
- Depois telas operacionais de cadastro e matricula

3. cci-ca-aluno
- Em seguida consumo de trilha, player e progresso

4. cci-ca-docs
- Atualizacao continua de contratos e regras

---

## 4. Sequencia de Migrations

### 4.1 Convencao de Arquivos

Formato: `YYYYMMDDHHMMSS_descricao.sql`

Ordem de aplicacao:
1. Base multi-tenant e licencas
2. Catalogo LMS
3. Matricula e progresso
4. LXP (exercicios, flashcards, anotacoes)
5. Certificados
6. Politicas RLS finais e views de relatorio

### 4.2 Migrations

| # | Arquivo | Cria | Aceite |
|---|---------|------|--------|
| 01 | `20260227100000_b2b_empresas_licencas_base.sql` | `empresas`, `empresa_usuarios`, `empresa_licencas`, `sessoes_ativas` + indices por `empresa_id`, `status`, `data_validade`, `usuario_id`, `curso_id` | Cadastro e consulta por tenant funcionando |
| 02 | `20260227101000_lms_catalogo_cursos_modulos_aulas.sql` | `cursos`, `modulos`, `aulas` + campo `ordem`, unicidade por escopo, campos de video (`bunny_video_id`, `bunny_status`) | Trilha de curso navegavel por ordem |
| 03 | `20260227102000_matricula_progresso_rpc_core.sql` | `usuario_curso`, `usuario_aula_progresso` + RPCs (`rpc_matricular_usuario_no_curso`, `rpc_matricular_lote_b2b`, `rpc_validar_acesso_simultaneo`) + trigger `trg_atualizar_progresso_curso` | Matricula nao consome licenca; login bloqueia ao atingir limite; progresso atualiza automaticamente |
| 04 | `20260227103000_lxp_exercicios_flashcards_anotacoes.sql` | `mapas_mentais`, `anotacoes_aluno`, `exercicios`, `usuario_exercicio_resposta`, `flashcards_revisao` + trigger `trg_gerar_flashcard_apos_erro` | Resposta errada gera flashcard automaticamente |
| 05 | `20260227104000_certificados_conclusao.sql` | `certificados` + trigger `trg_emitir_certificado` + regra de conclusao (nota minima + obrigatorias) | Curso concluido gera certificado com codigo unico |
| 06 | `20260227105000_rls_policies_lms_b2b.sql` | Enable RLS + policies por perfil + restricoes por status da empresa | Isolamento total entre tenants validado |
| 07 | `20260227106000_views_relatorios_rh.sql` | Views de progresso corporativo e desempenho + filtros por tenant | RH nao enxerga dados de outra empresa |

### 4.3 Testes Minimos por Migration

Para cada migration:
- Teste de subida/rollback
- Teste de permissao positiva por papel
- Teste de negacao por papel/tenant

Casos obrigatorios:
- Aluno sem matricula nao acessa aula
- Empresa suspensa nao acessa player/exercicios
- Aluno bloqueado quando limite simultaneo atingido
- Gestor RH nao altera limite simultaneo direto em tabela
- Professor nao enxerga respostas de curso alheio

### 4.4 Dependencias e Checklist

Dependencias:
- Definir pasta oficial de migrations (api ou raiz)
- Definir naming padrao final de tabelas
- Definir contrato de erros para RPCs
- Definir politica de timeout de sessao (inatividade)
- Definir heartbeat para manter sessao ativa

Checklist pre-implementacao:
- [ ] Nomes finais das entidades aprovados
- [ ] Ordem das migrations validada
- [ ] Matriz de RLS aprovada
- [ ] Cenarios de teste acordados
- [ ] Credenciais Bunny.net disponiveis para homologacao

---

## 5. Governanca e Cadencia

### 5.1 Papeis

- `Product Owner (PO)`: priorizacao, validacao de escopo e aceite funcional.
- `Tech Lead`: direcao tecnica, decisao arquitetural e desbloqueios.
- `Backend Lead`: ownership de API, funcoes RPC, triggers e RLS.
- `Frontend Lead Admin/Professor`: ownership de rotas e fluxos `cci-ca-admin`.
- `Frontend Lead Aluno/RH`: ownership de rotas e fluxos `cci-ca-aluno`.
- `QA Lead`: estrategia de teste, criterio de qualidade e regressao.
- `DevOps/Infra`: CI/CD, ambientes e monitoracao.

### 5.2 Matriz RACI

| Entregavel                     | PO  | Tech Lead | Backend | Front Admin | Front Aluno | QA  | DevOps |
| ------------------------------ | --- | --------- | ------- | ----------- | ----------- | --- | ------ |
| Modelo de dados e migrations   | A   | C         | R       | I           | I           | C   | C      |
| Politicas RLS e RBAC           | C   | A         | R       | I           | I           | C   | I      |
| Endpoints API                  | C   | A         | R       | I           | I           | C   | I      |
| Rotas e guards Admin/Professor | C   | C         | I       | R           | I           | C   | I      |
| Rotas e guards Aluno/RH        | C   | C         | I       | I           | R           | C   | I      |
| Testes E2E e carga             | I   | C         | C       | C           | C           | A/R | I      |
| CI/CD e observabilidade        | I   | C         | I       | I           | I           | C   | A/R    |

Legenda: `R` Responsible · `A` Accountable · `C` Consulted · `I` Informed

### 5.3 Ritos Obrigatorios

- `Kickoff geral` (1 vez): alinhamento completo de escopo e responsabilidades.
- `Daily tecnica` (15 min): bloqueios e progresso por frente.
- `Sync Backend + Front` (3x semana): contratos de API e ajustes de payload.
- `Refinamento funcional` (2x semana): detalhamento de regras de negocio.
- `Review de fase` (ao final de cada fase): validacao de "Pronto quando".
- `Retrospectiva` (ao final de cada fase): melhoria continua.

### 5.4 SLAs Internos

- Duvida de regra de negocio: resposta em ate 1 dia util.
- Duvida de contrato API: resposta em ate 4 horas uteis.
- Bloqueio critico de ambiente: triagem em ate 2 horas uteis.

### 5.5 Criterios de Entrada e Saida por Fase

**Fase 1 - Banco e Backend base**

Entrada:
- Escopo de schema aprovado em SCHEMA_TABELAS_LMS_B2B.md
- Estrategia de RLS aprovada em POLITICAS_RLS_LMS_B2B.md

Saida:
- Tabelas, funcoes e politicas criadas em ambiente dev
- Testes de isolamento tenant aprovados
- RPCs criticas validadas: `rpc_validar_acesso_simultaneo`, `rpc_iniciar_aula`, `rpc_matricular_lote_b2b`

**Fase 2 - API e integracoes**

Entrada:
- Fase 1 concluida e sem bloqueios criticos
- Contratos definidos em ENDPOINTS_API_LMS_B2B.md

Saida:
- Endpoints prioritarios implementados e testados
- Fluxo Bunny.net validado (upload, token temporario, webhook)
- Erros de negocio padronizados (`400`, `403`, `409`, `429`)

**Fase 3 e 4 - Frontends**

Entrada:
- Endpoints necessarios das trilhas priorizadas disponiveis
- Permissoes definidas em MATRIZ_RBAC_LMS_B2B.md

Saida:
- Fluxos fim a fim validados por perfil
- `SessionGuard` e heartbeat validados no player
- Rotas publicadas conforme MAPA_ROTAS_UI_LMS_B2B.md

**Fase 5 e 6 - Certificados e qualidade**

Entrada:
- Progresso de curso e emissao automatica estabilizados

Saida:
- Certificado PDF + validacao publica operacionais
- Testes E2E e de carga com metas atingidas
- Aprovacao final de release

### 5.6 Backlog de Sprint 0

- Validar o pacote de docs com PO e Tech Lead.
- Congelar versao 1.0 do planejamento em `docs/2026.02`.
- Definir dono de cada modulo de API e UI.
- Definir template de historias e criterios de aceite.
- Definir estrategia de versionamento de migrations.
- Definir estrategia de dados de teste por tenant.
- Definir dashboard de acompanhamento (status por fase).

### 5.7 Indicadores de Acompanhamento

- `% de entrega por fase`
- `% de criterios "Pronto quando" aprovados`
- `Lead time` por historia
- `Taxa de retrabalho` por modulo
- `Taxa de sucesso` dos testes E2E
- `Tempo medio de resolucao` de bloqueios criticos

### 5.8 Checklist de Aprovacao do Kickoff

- [ ] PO aprovou escopo funcional macro.
- [ ] Tech Lead aprovou arquitetura e limites tecnicos.
- [ ] Backend validou schema, RLS e RPCs criticas.
- [ ] Frontend validou mapa de rotas e guards.
- [ ] QA validou estrategia de testes por fase.
- [ ] DevOps validou estrategia de ambientes e CI/CD.
- [ ] Cronograma de 12-16 semanas aceito.

---

## 6. Backlog de Historias de Usuario

### 6.1 Convencoes

- Formato: `US-XXX`
- Prioridade: `P0` (critica), `P1` (alta), `P2` (media)
- Estimativa: pontos de historia (SP)
- Perfis: `admin_interno`, `professor`, `gestor_rh`, `aluno`

### 6.2 Fase 1 - Banco e Fundacao de Seguranca

**US-001 - Criar estrutura base de empresas e usuarios** · P0 · 8 SP  
Como backend lead, quero criar as tabelas base de tenancy para isolar dados por empresa.  
Aceite: Tabelas `empresas`/`empresa_usuarios` com FKs validas; `limite_usuarios_simultaneos` presente; indices por `empresa_id`; migration sem erro.

**US-002 - Criar controle de sessoes simultaneas** · P0 · 8 SP · Dep: US-001  
Como sistema, quero registrar sessoes ativas por usuario e curso para limitar acessos simultaneos.  
Aceite: Tabela `sessoes_ativas` com `ultimo_heartbeat`; `UNIQUE(usuario_id, curso_id)`; index para limpeza; consulta por empresa performatica.

**US-003 - Implementar funcoes auxiliares de seguranca** · P0 · 5 SP · Dep: US-001  
Como backend lead, quero funcoes SQL de contexto para reutilizar nas politicas RLS.  
Aceite: `auth_user_id`, `is_admin_interno`, `get_empresa_id_do_usuario` criadas como `SECURITY DEFINER`; `search_path` seguro; testes por perfil.

**US-004 - Ativar RLS nas tabelas criticas** · P0 · 13 SP · Dep: US-003  
Como tech lead, quero RLS habilitado para garantir isolamento multi-tenant.  
Aceite: RLS em todas tabelas LMS+B2B; policies SELECT/INSERT/UPDATE/DELETE por perfil; acesso cruzado retorna zero; bypass sem permissao retorna erro.

**US-005 - Implementar RPC de validacao de acesso simultaneo** · P0 · 8 SP · Dep: US-002, US-004  
Como aluno, quero entrar no player somente quando houver vaga para respeitar o limite da empresa.  
Aceite: `rpc_validar_acesso_simultaneo` retorna sucesso abaixo do limite, erro acima; registro em `sessoes_ativas` em sucesso; limpa sessoes expiradas antes.

### 6.3 Fase 2 - API e Integracoes

**US-006 - Expor endpoint de validacao de sessao** · P0 · 5 SP · Dep: US-005  
Aceite: `POST /api/v1/sessoes/validar` retorna `200` com token ou `429` com payload padrao; logs com `empresa_id`, `curso_id`, resultado.

**US-007 - Expor endpoint de heartbeat** · P0 · 3 SP · Dep: US-006  
Aceite: `PUT /api/v1/sessoes/:token/heartbeat` atualiza `ultimo_heartbeat`; token invalido `404`; expirado `410`.

**US-008 - Implementar matricula individual** · P0 · 5 SP · Dep: US-004  
Aceite: `POST /api/v1/matriculas` cria `usuario_curso`; duplicada `409`; sem decremento de licenca.

**US-009 - Implementar matricula em lote via CSV** · P1 · 8 SP · Dep: US-008  
Aceite: `POST /api/v1/matriculas/lote` com validacao de CSV; retorno com totais por linha; idempotente.

**US-010 - Integrar token de video Bunny.net** · P0 · 8 SP · Dep: US-006  
Aceite: Token com TTL definido vinculado a aula/usuario; falha retorna erro padronizado; telemetria minima.

### 6.4 Fase 3 - Frontend Admin e Professor

**US-011 - CRUD de empresas no painel admin** · P0 · 8 SP · Dep: US-001, US-006  
Aceite: Listagem com filtros; formulario de `limite_usuarios_simultaneos`; validacao frontend+backend; respeita permissoes `admin_interno`.

**US-012 - Criacao de curso por professor** · P0 · 13 SP · Dep: US-004  
Aceite: Criar curso + modulos + aulas com campo `ordem`; reordenacao preserva unicidade; interface bloqueia inconsistencia.

**US-013 - Upload de video no fluxo de aula** · P1 · 8 SP · Dep: US-010, US-012  
Aceite: Upload retorna status de processamento; `bunny_video_id` gravado; erro claro; indicador de estado visivel.

### 6.5 Fase 4 - Frontend Aluno e RH

**US-014 - SessionGuard no player** · P0 · 8 SP · Dep: US-006, US-007  
Aceite: Validacao antes do render; erro `429` redireciona para tela orientativa; token armazenado para heartbeat; encerramento no `beforeunload`.

**US-015 - Progressao sequencial obrigatoria** · P0 · 8 SP · Dep: US-005, US-012  
Aceite: Aulas bloqueadas com estado visual; URL direta bloqueada; concluir N libera N+1; progresso percentual atualizado.

**US-016 - Painel RH de sessoes ativas** · P1 · 5 SP · Dep: US-006, US-007  
Aceite: Lista sessoes ativas da empresa; atualiza em tempo real; indicador `ativas / limite`; encerramento forcado conforme permissao.

**US-017 - Matricula em lote no portal RH** · P1 · 5 SP · Dep: US-009  
Aceite: Upload CSV com preview; resultado aprovadas/rejeitadas; exportacao de erros; feedback de conclusao.

### 6.6 Fase 5 - Certificados e Relatorios

**US-018 - Emissao automatica de certificado** · P0 · 8 SP · Dep: US-015  
Aceite: Trigger emite ao atingir criterios; codigo unico de validacao; disponivel na area do aluno; validacao publica retorna dados corretos.

**US-019 - Relatorio de progresso por empresa** · P1 · 5 SP · Dep: US-016  
Aceite: Filtravel por curso/periodo/colaborador; exportacao CSV; isolamento por `empresa_id`; KPIs: matriculados, ativos, concluidos, taxa de conclusao.

### 6.7 Fase 6 - Qualidade e Go-Live

**US-020 - Cobertura E2E dos fluxos criticos** · P0 · 8 SP · Dep: US-014, US-015, US-018  
Aceite: E2E dos perfis `aluno`, `gestor_rh`, `professor`; fluxo de simultaneidade coberto; progressao coberta; pipeline publica resultado.

**US-021 - Teste de carga do limite simultaneo** · P0 · 5 SP · Dep: US-006, US-007  
Aceite: Cenarios com limite e acima executados; `429` consistente acima; sem sessoes fantasmas; relatorio documentado.

### 6.8 Priorizacao por Sprint

| Sprint | Historias |
|--------|-----------|
| Sprint 1 (fundacao) | US-001, US-002, US-003, US-004 |
| Sprint 2 (acesso e matricula) | US-005, US-006, US-007, US-008 |
| Sprint 3 (frontend critico) | US-011, US-012, US-014, US-015 |
| Sprint 4 (escala e certificacao) | US-009, US-016, US-018, US-020, US-021 |

### 6.9 Definicao de Pronto (DoD)

Uma historia so pode ser considerada concluida quando:
- Codigo revisado e aprovado
- Testes unitarios/integracao da historia aprovados
- Criterios de aceite funcionais validados
- Telemetria/logs minimos implementados quando aplicavel
- Documentacao tecnica atualizada (se houver impacto)

---

## 7. Homologacao (UAT)

### 7.1 Escopo

Inclui:
- Fluxos principais por perfil (`admin_interno`, `professor`, `gestor_rh`, `aluno`)
- Regras criticas (simultaneidade, progressao sequencial, matricula sem consumo)
- Validacao de permissoes e isolamento multi-tenant
- Emissao e validacao de certificado

Nao inclui:
- Testes de carga extensivos (fora do UAT funcional)
- Testes de seguranca ofensiva aprofundados

### 7.2 Criterios de Entrada e Saida

Entrada:
- Ambientes de homologacao configurados
- Massa de dados por tenant disponivel
- Endpoints e fluxos principais implementados
- RLS e RBAC ativados em homologacao

Saida:
- 100% dos cenarios P0 aprovados
- Minimo de 95% de cenarios P1 aprovados
- Defeitos criticos bloqueadores resolvidos
- Termo de aceite funcional assinado pelo PO

### 7.3 Massa de Dados Minima

- 2 empresas (`empresa_a`, `empresa_b`) com limites distintos
- 1 admin interno
- 2 professores (um por tenant quando aplicavel)
- 2 gestores RH (um por empresa)
- 20 alunos por empresa
- 2 cursos por empresa, cada um com no minimo 5 aulas sequenciais
- Exercicios cadastrados em ao menos 3 aulas por curso

### 7.4 Cenarios UAT

**Admin Interno:**

| ID | Cenario | P | Resultado Esperado |
|----|---------|---|--------------------|
| UAT-ADM-001 | Criar empresa com `limite_usuarios_simultaneos = 30` | P0 | Empresa criada; limite gravado e exibido |
| UAT-ADM-002 | Alterar status de empresa para inativo/expirada | P1 | Login de usuario vinculado bloqueado |

**Professor:**

| ID | Cenario | P | Resultado Esperado |
|----|---------|---|--------------------|
| UAT-PROF-001 | Criar curso com 1 modulo e 5 aulas em ordem | P0 | Curso publicado; ordens sem duplicidade |
| UAT-PROF-002 | Enviar video para aula e aguardar processamento | P1 | Aula recebe ID de video; estado exibido |

**Gestor RH:**

| ID | Cenario | P | Resultado Esperado |
|----|---------|---|--------------------|
| UAT-RH-001 | Matricula individual sem consumo | P0 | `usuario_curso` criado; sem decremento de saldo; limite inalterado |
| UAT-RH-002 | Importar CSV com registros validos e invalidos | P1 | Resumo por linha (sucesso/falha); erros com motivo |
| UAT-RH-003 | Abrir painel de sessoes ativas | P1 | Contador `ativas / limite` atualizado; apenas propria empresa |

**Aluno:**

| ID | Cenario | P | Resultado Esperado |
|----|---------|---|--------------------|
| UAT-ALN-001 | Tentar abrir aula 3 sem concluir aula 2 | P0 | Acesso bloqueado com mensagem de progressao |
| UAT-ALN-002 | Tentar player com limite de sessoes cheio | P0 | Bloqueio com mensagem de limite atingido |
| UAT-ALN-003 | Heartbeat ativo e expiracao de sessao | P0 | Sessao mantida com heartbeat; removida apos timeout |
| UAT-ALN-004 | Concluir todas aulas e emitir certificado | P0 | Certificado disponivel para download; validacao publica OK |

**Seguranca Funcional:**

| ID | Cenario | P | Resultado Esperado |
|----|---------|---|--------------------|
| UAT-SEC-001 | Gestor RH empresa A tenta acessar dados empresa B | P0 | Acesso negado ou recurso inexistente |
| UAT-SEC-002 | Aluno tenta abrir rota administrativa | P0 | Redirecionamento ou tela de acesso negado |

### 7.5 Registro de Defeitos

Campos obrigatorios: ID, Severidade (`bloqueador`/`alto`/`medio`/`baixo`), Cenario UAT, Passos, Resultado esperado x obtido, Evidencia, Status (`aberto`/`em correcao`/`validando`/`resolvido`).

Regras:
- Defeito bloqueador em cenario P0 impede aceite de fase
- Defeito alto em cenario P0 exige plano de correcao aprovado pelo PO

### 7.6 Checklist de Aceite Final

- [ ] Cenarios P0 aprovados integralmente
- [ ] Cenarios P1 aprovados no percentual minimo
- [ ] Defeitos bloqueadores zerados
- [ ] Evidencias de UAT organizadas e rastreaveis
- [ ] PO assinou aceite funcional

### 7.7 Responsabilidades no UAT

- `PO`: aprovar escopo de UAT e aceite final
- `QA Lead`: conduzir execucao e consolidar resultado
- `Tech Lead`: priorizar correcao de defeitos criticos
- `Leads de frente`: corrigir defeitos e apoiar retestes

---

## 8. Riscos Tecnicos e Dependencias

Dependencias:
- Credenciais e zona de storage Bunny.net
- Definicao final de payload CSV de matricula em lote
- Definicao de politica de devolucao de licenca

| Risco | Impacto | Prob. | Mitigacao |
|-------|---------|-------|-----------|
| RLS incompleta em views de relatorio | Alto | Medio | Testes de RLS por perfil/tenant antes de cada release |
| Regras de progressao duplicadas front/banco | Alto | Medio | Regra canonica sempre no banco (RPC) |
| Token de video com TTL inadequado | Medio | Medio | Parametrizacao de TTL e monitoramento de falhas |
| Divergencia regra de negocio vs contrato API | Alto | Medio | Sync PO + Backend 3x semana e checklist de contrato |
| Regressao em RLS ao evoluir schema | Alto | Medio | Suite de teste RLS obrigatoria por migration |
| Gargalo no controle de sessoes simultaneas | Alto | Medio | Teste de carga antecipado na Fase 2 |
| Dependencia externa Bunny.net | Medio | Medio | Fallback de fila e retentativa para webhook |
| Acoplamento excessivo front-back | Medio | Alto | Contratos versionados e mock de API no frontend |

---

## 9. Criterios de Go/No-Go por Fase

Go Fase 1:
- Matricula transacional aprovada
- Bloqueio por licenca validado

Go Fase 2:
- Sequencia obrigatoria validada por teste de API

Go Fase 3:
- Playback seguro sem leak de URL

Go Fase 4:
- Exercicios e flashcards em producao controlada

Go Fase 5:
- Certificado e relatorio por tenant auditados

---

## 10. Delta Executado em 2026-02-27

Arquivos de migration (DRAFT) criados em `cci-ca-api/migrations`:
- `20260227100000_b2b_empresas_licencas_base.sql`
- `20260227101000_lms_catalogo_cursos_modulos_aulas.sql`
- `20260227102000_matricula_progresso_rpc_core.sql`
- `20260227103000_lxp_exercicios_flashcards_anotacoes.sql`
- `20260227104000_certificados_conclusao.sql`
- `20260227105000_rls_policies_lms_b2b.sql`
- `20260227106000_views_relatorios_rh.sql`

Escopo do delta:
- Estrutura inicial de migrations criada sem DDL final executavel.
- Cada arquivo contem secoes TODO com regras e objetivo por fase.

Proximo checkpoint:
- Converter cada migration DRAFT para SQL definitivo iniciando pela Fase 1 (B2B base + matricula segura).

Status atual do checkpoint:
- `20260227100000_b2b_empresas_licencas_base.sql` convertido para SQL definitivo (READY).
- `20260227101000_lms_catalogo_cursos_modulos_aulas.sql` convertido para SQL definitivo (READY).
- `20260227102000_matricula_progresso_rpc_core.sql` convertido para SQL definitivo (READY).
- `20260227103000_lxp_exercicios_flashcards_anotacoes.sql` convertido para SQL definitivo (READY).
- `20260227104000_certificados_conclusao.sql` convertido para SQL definitivo (READY).
- `20260227105000_rls_policies_lms_b2b.sql` convertido para SQL definitivo (READY).
- `20260227106000_views_relatorios_rh.sql` convertido para SQL definitivo (READY).
- Nenhuma migration do plano permanece em DRAFT.
