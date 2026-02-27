# Plano de Kickoff e Governanca - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento executivo  
**Versao:** 1.0

---

## 1. Objetivo

Definir o plano operacional para iniciar a implementacao do LMS + B2B com governanca, responsabilidades, ritos, criterios de aceite e controle de riscos.

Este documento complementa:

- [INDICE_DOCUMENTACAO_LMS_B2B.md](INDICE_DOCUMENTACAO_LMS_B2B.md)
- [ROADMAP_EXECUCAO_LMS_B2B.md](ROADMAP_EXECUCAO_LMS_B2B.md)
- [PLANO_MIGRATIONS_SQL_LMS_B2B.md](PLANO_MIGRATIONS_SQL_LMS_B2B.md)

---

## 2. Escopo do Kickoff

### 2.1 Inclui

- Alinhamento funcional e tecnico entre produto, backend, frontend e dados.
- Definicao de donos por modulo (API, banco, admin, aluno).
- Definicao de criterios de entrada e saida de cada fase.
- Definicao de ritos de acompanhamento e gestao de risco.

### 2.2 Nao inclui

- Execucao de migrations.
- Desenvolvimento de endpoints ou telas.
- Deploy em ambientes.

---

## 3. Estrutura de Governanca

### 3.1 Papeis

- `Product Owner (PO)`: priorizacao, validacao de escopo e aceite funcional.
- `Tech Lead`: direcao tecnica, decisao arquitetural e desbloqueios.
- `Backend Lead`: ownership de API, funcoes RPC, triggers e RLS.
- `Frontend Lead Admin/Professor`: ownership de rotas e fluxos `cci-ca-admin`.
- `Frontend Lead Aluno/RH`: ownership de rotas e fluxos `cci-ca-aluno`.
- `QA Lead`: estrategia de teste, criterio de qualidade e regressao.
- `DevOps/Infra`: CI/CD, ambientes e monitoracao.

### 3.2 Matriz RACI (macro)

| Entregavel                     | PO  | Tech Lead | Backend | Front Admin | Front Aluno | QA  | DevOps |
| ------------------------------ | --- | --------- | ------- | ----------- | ----------- | --- | ------ |
| Modelo de dados e migrations   | A   | C         | R       | I           | I           | C   | C      |
| Politicas RLS e RBAC           | C   | A         | R       | I           | I           | C   | I      |
| Endpoints API                  | C   | A         | R       | I           | I           | C   | I      |
| Rotas e guards Admin/Professor | C   | C         | I       | R           | I           | C   | I      |
| Rotas e guards Aluno/RH        | C   | C         | I       | I           | R           | C   | I      |
| Testes E2E e carga             | I   | C         | C       | C           | C           | A/R | I      |
| CI/CD e observabilidade        | I   | C         | I       | I           | I           | C   | A/R    |

Legenda:

- `R`: Responsible
- `A`: Accountable
- `C`: Consulted
- `I`: Informed

---

## 4. Cadencia de Trabalho

### 4.1 Ritos obrigatorios

- `Kickoff geral` (1 vez): alinhamento completo de escopo e responsabilidades.
- `Daily tecnica` (15 min): bloqueios e progresso por frente.
- `Sync Backend + Front` (3x semana): contratos de API e ajustes de payload.
- `Refinamento funcional` (2x semana): detalhamento de regras de negocio.
- `Review de fase` (ao final de cada fase): validacao de "Pronto quando".
- `Retrospectiva` (ao final de cada fase): melhoria continua.

### 4.2 SLAs internos

- Duvida de regra de negocio: resposta em ate 1 dia util.
- Duvida de contrato API: resposta em ate 4 horas uteis.
- Bloqueio critico de ambiente: triagem em ate 2 horas uteis.

---

## 5. Criterios de Entrada e Saida por Fase

## 5.1 Fase 1 - Banco e Backend base

**Entrada:**

- Escopo de schema aprovado em [SCHEMA_TABELAS_LMS_B2B.md](SCHEMA_TABELAS_LMS_B2B.md).
- Estrategia de RLS aprovada em [POLITICAS_RLS_LMS_B2B.md](POLITICAS_RLS_LMS_B2B.md).

**Saida:**

- Tabelas, funcoes e politicas criadas em ambiente dev.
- Testes de isolamento tenant aprovados.
- RPCs criticas validadas: `rpc_validar_acesso_simultaneo`, `rpc_iniciar_aula`, `rpc_matricular_lote_b2b`.

## 5.2 Fase 2 - API e integracoes

**Entrada:**

- Fase 1 concluida e sem bloqueios criticos.
- Contratos definidos em [ENDPOINTS_API_LMS_B2B.md](ENDPOINTS_API_LMS_B2B.md).

**Saida:**

- Endpoints prioritarios implementados e testados.
- Fluxo Bunny.net validado (upload, token temporario, webhook).
- Erros de negocio padronizados (`400`, `403`, `409`, `429`).

## 5.3 Fase 3 e 4 - Frontends

**Entrada:**

- Endpoints necessarios das trilhas priorizadas disponiveis.
- Permissoes definidas em [MATRIZ_RBAC_LMS_B2B.md](MATRIZ_RBAC_LMS_B2B.md).

**Saida:**

- Fluxos fim a fim validados por perfil.
- `SessionGuard` e heartbeat validados no player.
- Rotas publicadas conforme [MAPA_ROTAS_UI_LMS_B2B.md](MAPA_ROTAS_UI_LMS_B2B.md).

## 5.4 Fase 5 e 6 - Certificados e qualidade

**Entrada:**

- Progresso de curso e emissao automatica estabilizados.

**Saida:**

- Certificado PDF + validacao publica operacionais.
- Testes E2E e de carga com metas atingidas.
- Aprovacao final de release.

---

## 6. Backlog Inicial (Sprint 0)

- Validar o pacote de docs com PO e Tech Lead.
- Congelar versao 1.0 do planejamento em `docs/2026.02`.
- Definir dono de cada modulo de API e UI.
- Definir template de historias e criterios de aceite.
- Definir estrategia de versionamento de migrations.
- Definir estrategia de dados de teste por tenant.
- Definir dashboard de acompanhamento (status por fase).

---

## 7. Riscos e Mitigacoes

| Risco                                             | Impacto | Probabilidade | Mitigacao                                           |
| ------------------------------------------------- | ------- | ------------- | --------------------------------------------------- |
| Divergencia entre regra de negocio e contrato API | Alto    | Medio         | Sync PO + Backend 3x semana e checklist de contrato |
| Regressao em RLS ao evoluir schema                | Alto    | Medio         | Suite de teste RLS obrigatoria por migration        |
| Gargalo no controle de sessoes simultaneas        | Alto    | Medio         | Teste de carga antecipado na Fase 2                 |
| Dependencia externa Bunny.net                     | Medio   | Medio         | Fallback de fila e retentativa para webhook         |
| Acoplamento excessivo front-back                  | Medio   | Alto          | Contratos versionados e mock de API no frontend     |

---

## 8. Indicadores de Acompanhamento

- `% de entrega por fase`.
- `% de criterios "Pronto quando" aprovados`.
- `Lead time` por historia.
- `Taxa de retrabalho` por modulo.
- `Taxa de sucesso` dos testes E2E.
- `Tempo medio de resolucao` de bloqueios criticos.

---

## 9. Checklist de Aprovacao do Kickoff

- [ ] PO aprovou escopo funcional macro.
- [ ] Tech Lead aprovou arquitetura e limites tecnicos.
- [ ] Backend validou schema, RLS e RPCs criticas.
- [ ] Frontend validou mapa de rotas e guards.
- [ ] QA validou estrategia de testes por fase.
- [ ] DevOps validou estrategia de ambientes e CI/CD.
- [ ] Cronograma de 12-16 semanas aceito.

---

## 10. Referencias

- [INDICE_DOCUMENTACAO_LMS_B2B.md](INDICE_DOCUMENTACAO_LMS_B2B.md)
- [ROADMAP_EXECUCAO_LMS_B2B.md](ROADMAP_EXECUCAO_LMS_B2B.md)
- [SCHEMA_TABELAS_LMS_B2B.md](SCHEMA_TABELAS_LMS_B2B.md)
- [FUNCOES_TRIGGERS_LMS_B2B.md](FUNCOES_TRIGGERS_LMS_B2B.md)
- [POLITICAS_RLS_LMS_B2B.md](POLITICAS_RLS_LMS_B2B.md)
- [MATRIZ_RBAC_LMS_B2B.md](MATRIZ_RBAC_LMS_B2B.md)
- [MAPA_ROTAS_UI_LMS_B2B.md](MAPA_ROTAS_UI_LMS_B2B.md)
- [ENDPOINTS_API_LMS_B2B.md](ENDPOINTS_API_LMS_B2B.md)
- [PLANO_MIGRATIONS_SQL_LMS_B2B.md](PLANO_MIGRATIONS_SQL_LMS_B2B.md)
