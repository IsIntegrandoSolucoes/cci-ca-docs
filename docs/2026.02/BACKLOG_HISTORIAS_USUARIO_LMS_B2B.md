# Backlog de Historias de Usuario - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento detalhado  
**Versao:** 1.0

---

## 1. Objetivo

Organizar o backlog inicial por fase de implementacao para o projeto LMS + B2B, com historias de usuario testaveis e criterios de aceite claros.

Referencias:

- [INDICE_DOCUMENTACAO_LMS_B2B.md](INDICE_DOCUMENTACAO_LMS_B2B.md)
- [ROADMAP_EXECUCAO_LMS_B2B.md](ROADMAP_EXECUCAO_LMS_B2B.md)
- [ENDPOINTS_API_LMS_B2B.md](ENDPOINTS_API_LMS_B2B.md)
- [MAPA_ROTAS_UI_LMS_B2B.md](MAPA_ROTAS_UI_LMS_B2B.md)

---

## 2. Convencoes

- Formato: `US-XXX`.
- Prioridade: `P0` (critica), `P1` (alta), `P2` (media).
- Estimativa: pontos de historia (SP).
- Perfis: `admin_interno`, `professor`, `gestor_rh`, `aluno`.

---

## 3. Fase 1 - Banco e Fundacao de Seguranca

## 3.1 US-001 - Criar estrutura base de empresas e usuarios

**Como** backend lead  
**Quero** criar as tabelas base de tenancy  
**Para** isolar dados por empresa e suportar operacao B2B

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** nenhuma

**Criterios de aceite:**

- Tabelas `empresas` e `empresa_usuarios` criadas com FKs validas.
- `limite_usuarios_simultaneos` presente em `empresas` com valor padrao.
- Indices de busca por `empresa_id` criados.
- Migration executa em ambiente limpo sem erro.

## 3.2 US-002 - Criar controle de sessoes simultaneas

**Como** sistema  
**Quero** registrar sessoes ativas por usuario e curso  
**Para** limitar acessos simultaneos por empresa

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-001

**Criterios de aceite:**

- Tabela `sessoes_ativas` criada com `ultimo_heartbeat`.
- Restricao `UNIQUE(usuario_id, curso_id)` aplicada.
- Index para limpeza por heartbeat criado.
- Consulta de sessoes ativas por empresa executa em tempo aceitavel.

## 3.3 US-003 - Implementar funcoes auxiliares de seguranca

**Como** backend lead  
**Quero** criar funcoes SQL de contexto de usuario e perfil  
**Para** reutilizar regras nas politicas RLS

**Prioridade:** P0  
**Estimativa:** 5 SP  
**Dependencias:** US-001

**Criterios de aceite:**

- Funcoes `auth_user_id`, `is_admin_interno`, `get_empresa_id_do_usuario` criadas.
- Funcoes criadas como `SECURITY DEFINER` quando necessario.
- `search_path` definido de forma segura.
- Testes SQL validam retorno correto por perfil.

## 3.4 US-004 - Ativar RLS nas tabelas criticas

**Como** tech lead  
**Quero** habilitar e aplicar politicas RLS  
**Para** garantir isolamento multi-tenant em nivel de banco

**Prioridade:** P0  
**Estimativa:** 13 SP  
**Dependencias:** US-003

**Criterios de aceite:**

- RLS habilitado em todas as tabelas do escopo LMS+B2B.
- Politicas SELECT/INSERT/UPDATE/DELETE aplicadas conforme perfil.
- Teste de acesso cruzado entre tenants retorna zero linhas.
- Tentativa de bypass sem permissao retorna erro de policy.

## 3.5 US-005 - Implementar RPC de validacao de acesso simultaneo

**Como** aluno  
**Quero** entrar no player somente quando houver vaga simultanea  
**Para** respeitar o limite contratado da empresa

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-002, US-004

**Criterios de aceite:**

- RPC `rpc_validar_acesso_simultaneo` retorna sucesso quando abaixo do limite.
- RPC retorna erro de limite quando `sessoes_ativas >= limite`.
- Registro em `sessoes_ativas` criado em caso de sucesso.
- RPC limpa sessoes expiradas antes da validacao.

---

## 4. Fase 2 - API e Integracoes

## 4.1 US-006 - Expor endpoint de validacao de sessao

**Como** frontend aluno  
**Quero** chamar um endpoint unico para validar sessao  
**Para** bloquear acesso no player quando o limite for atingido

**Prioridade:** P0  
**Estimativa:** 5 SP  
**Dependencias:** US-005

**Criterios de aceite:**

- Endpoint `POST /api/v1/sessoes/validar` implementado.
- Retorna `200` com token de sessao em sucesso.
- Retorna `429` com payload padrao quando limite atingido.
- Logs registram `empresa_id`, `curso_id` e resultado.

## 4.2 US-007 - Expor endpoint de heartbeat

**Como** frontend aluno  
**Quero** atualizar heartbeat periodicamente  
**Para** manter sessao ativa durante reproducao

**Prioridade:** P0  
**Estimativa:** 3 SP  
**Dependencias:** US-006

**Criterios de aceite:**

- Endpoint `PUT /api/v1/sessoes/:token/heartbeat` implementado.
- Atualiza `ultimo_heartbeat` da sessao correspondente.
- Token invalido retorna `404`.
- Token expirado retorna `410` (ou codigo definido no padrao do modulo).

## 4.3 US-008 - Implementar matricula individual

**Como** gestor_rh  
**Quero** matricular um colaborador em um curso  
**Para** disponibilizar trilhas de aprendizagem sem consumo por matricula

**Prioridade:** P0  
**Estimativa:** 5 SP  
**Dependencias:** US-004

**Criterios de aceite:**

- Endpoint `POST /api/v1/matriculas` implementado.
- Cria registro em `usuario_curso` quando nao existir matricula.
- Retorna `409` em tentativa de matricula duplicada.
- Nao altera contador de licenca por consumo.

## 4.4 US-009 - Implementar matricula em lote via CSV

**Como** gestor_rh  
**Quero** subir um CSV de colaboradores  
**Para** matricular em massa com retorno de erros por linha

**Prioridade:** P1  
**Estimativa:** 8 SP  
**Dependencias:** US-008

**Criterios de aceite:**

- Endpoint `POST /api/v1/matriculas/lote` implementado.
- Arquivo CSV validado (cabecalho, formato e colunas obrigatorias).
- Retorno com totais de sucesso e falha por linha.
- Operacao idempotente para registros ja existentes.

## 4.5 US-010 - Integrar token de video Bunny.net

**Como** aluno  
**Quero** receber token temporario para reproduzir video privado  
**Para** acessar conteudo com seguranca

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-006

**Criterios de aceite:**

- Gera token de video com TTL definido.
- Token vinculado ao contexto de aula/usuario.
- Falha de geracao retorna erro padronizado.
- Endpoint registra telemetria minima da requisicao.

---

## 5. Fase 3 - Frontend Admin e Professor

## 5.1 US-011 - CRUD de empresas no painel admin

**Como** admin_interno  
**Quero** criar e editar empresas B2B  
**Para** configurar limite simultaneo e status contratual

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-001, US-006

**Criterios de aceite:**

- Tela lista empresas com filtros por status.
- Formulario cria/edita `limite_usuarios_simultaneos`.
- Validacao de campos obrigatorios no frontend e backend.
- Operacoes respeitam permissoes de `admin_interno`.

## 5.2 US-012 - Criacao de curso por professor

**Como** professor  
**Quero** criar curso com modulos e aulas ordenadas  
**Para** publicar conteudo didatico estruturado

**Prioridade:** P0  
**Estimativa:** 13 SP  
**Dependencias:** US-004

**Criterios de aceite:**

- Professor cria curso com dados basicos.
- Professor cria modulos e aulas com campo `ordem`.
- Reordenacao preserva unicidade por modulo/curso.
- Interface bloqueia inconsistencia de ordenacao.

## 5.3 US-013 - Upload de video no fluxo de aula

**Como** professor  
**Quero** anexar video da aula  
**Para** disponibilizar conteudo no player do aluno

**Prioridade:** P1  
**Estimativa:** 8 SP  
**Dependencias:** US-010, US-012

**Criterios de aceite:**

- Upload inicia e retorna status de processamento.
- `bunny_video_id` gravado na aula apos processamento.
- Mensagem de erro clara em falha de upload.
- Professor visualiza indicador de estado do video.

---

## 6. Fase 4 - Frontend Aluno e RH

## 6.1 US-014 - SessionGuard no player

**Como** aluno  
**Quero** que o player valide sessao antes de carregar video  
**Para** receber feedback imediato quando nao houver vaga simultanea

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-006, US-007

**Criterios de aceite:**

- `SessionGuard` executa validacao antes do render do player.
- Em erro `429`, usuario e redirecionado para tela orientativa.
- Em sucesso, token de sessao e armazenado para heartbeat.
- Encerramento de sessao no `beforeunload` (best effort).

## 6.2 US-015 - Progressao sequencial obrigatoria

**Como** aluno  
**Quero** abrir apenas a proxima aula liberada  
**Para** seguir a trilha definida pelo curso

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-005, US-012

**Criterios de aceite:**

- Aulas bloqueadas exibem estado visual de indisponivel.
- Tentativa direta de URL bloqueada retorna erro de negocio.
- Concluir aula N libera aula N+1.
- Progresso percentual atualizado no dashboard.

## 6.3 US-016 - Painel RH de sessoes ativas

**Como** gestor_rh  
**Quero** ver colaboradores ativos em tempo real  
**Para** acompanhar utilizacao do limite simultaneo

**Prioridade:** P1  
**Estimativa:** 5 SP  
**Dependencias:** US-006, US-007

**Criterios de aceite:**

- Tela lista sessoes ativas da empresa logada.
- Atualizacao em tempo real com Supabase Realtime (ou polling definido).
- Indicador mostra `sessoes_ativas / limite`.
- Acao de encerramento forçado disponivel conforme permissao.

## 6.4 US-017 - Matricula em lote no portal RH

**Como** gestor_rh  
**Quero** importar CSV no portal RH  
**Para** acelerar distribuicao de cursos

**Prioridade:** P1  
**Estimativa:** 5 SP  
**Dependencias:** US-009

**Criterios de aceite:**

- Upload de CSV com preview de validacao.
- Resultado final com linhas aprovadas/rejeitadas.
- Exportacao de erros para ajuste.
- Feedback de operacao concluida.

---

## 7. Fase 5 - Certificados e Relatorios

## 7.1 US-018 - Emissao automatica de certificado

**Como** aluno  
**Quero** receber certificado ao concluir o curso  
**Para** comprovar minha certificacao

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-015

**Criterios de aceite:**

- Trigger emite certificado ao atingir criterios de conclusao.
- Documento inclui codigo unico de validacao.
- Certificado disponivel na area do aluno.
- Endpoint de validacao publica retorna dados corretos.

## 7.2 US-019 - Relatorio de progresso por empresa

**Como** gestor_rh  
**Quero** extrair relatorio de progresso dos colaboradores  
**Para** acompanhar adesao e conclusao dos cursos

**Prioridade:** P1  
**Estimativa:** 5 SP  
**Dependencias:** US-016

**Criterios de aceite:**

- Relatorio filtravel por curso, periodo e colaborador.
- Exportacao CSV disponivel.
- Dados respeitam isolamento por `empresa_id`.
- KPI minimo: matriculados, ativos, concluidos, taxa de conclusao.

---

## 8. Fase 6 - Qualidade e Go-Live

## 8.1 US-020 - Cobertura E2E dos fluxos criticos

**Como** QA lead  
**Quero** automatizar os fluxos principais em E2E  
**Para** reduzir regressao antes do go-live

**Prioridade:** P0  
**Estimativa:** 8 SP  
**Dependencias:** US-014, US-015, US-018

**Criterios de aceite:**

- Cenarios E2E dos perfis `aluno`, `gestor_rh`, `professor` implementados.
- Fluxo de bloqueio por simultaneidade coberto.
- Fluxo de progressao sequencial coberto.
- Pipeline executa suite E2E e publica resultado.

## 8.2 US-021 - Teste de carga do limite simultaneo

**Como** tech lead  
**Quero** validar comportamento sob concorrencia alta  
**Para** garantir estabilidade do controle de sessoes

**Prioridade:** P0  
**Estimativa:** 5 SP  
**Dependencias:** US-006, US-007

**Criterios de aceite:**

- Cenarios com limite e acima do limite executados.
- Sistema retorna `429` de forma consistente acima do limite.
- Nao ha crescimento indevido de sessoes fantasmas.
- Relatorio de carga documentado com recomendacoes.

---

## 9. Priorizacao Inicial Sugerida

## 9.1 Sprint 1 (fundacao)

- US-001, US-002, US-003, US-004

## 9.2 Sprint 2 (acesso e matricula)

- US-005, US-006, US-007, US-008

## 9.3 Sprint 3 (frontend critico)

- US-011, US-012, US-014, US-015

## 9.4 Sprint 4 (escala e certificacao)

- US-009, US-016, US-018, US-020, US-021

---

## 10. Definicao de Pronto (DoD) para Historias

Uma historia so pode ser considerada concluida quando:

- Codigo revisado e aprovado.
- Testes unitarios/integracao da historia aprovados.
- Criterios de aceite funcionais validados.
- Telemetria/logs minimos implementados quando aplicavel.
- Documentacao tecnica atualizada (se houver impacto).
