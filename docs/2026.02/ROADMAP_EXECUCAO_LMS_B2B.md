# Roadmap de Execucao - LMS + B2B

Data: 2026-02-27
Status: Planejamento (sem implementacao)
Base: mudancas.md + decisoes A/A/C + plano RLS

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

## 4. Riscos Tecnicos e Dependencias

Dependencias:
- Credenciais e zona de storage Bunny.net
- Definicao final de payload CSV de matricula em lote
- Definicao de politica de devolucao de licenca

Riscos:
- RLS incompleta em views de relatorio
- Regras de progressao duplicadas entre frontend e banco
- Token de video com TTL inadequado (curto demais ou longo demais)

Mitigacoes:
- Testes de RLS por perfil/tenant antes de cada release
- Regra canonica sempre no banco (RPC)
- Parametrizacao de TTL e monitoramento de falhas de player

---

## 5. Criterios de Go/No-Go por Fase

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

## 6. Delta Executado em 2026-02-27

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
