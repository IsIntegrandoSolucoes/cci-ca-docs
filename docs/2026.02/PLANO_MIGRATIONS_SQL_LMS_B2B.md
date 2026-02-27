# Plano de Migrations SQL - LMS + B2B

Data: 2026-02-27
Status: Planejado (nao implementado)

---

## 1. Convencao de Arquivos

Formato sugerido:
- `YYYYMMDDHHMMSS_descricao.sql`

Ordem de aplicacao:
1. Base multi-tenant e licencas
2. Catalogo LMS
3. Matricula e progresso
4. LXP (exercicios, flashcards, anotacoes)
5. Certificados
6. Politicas RLS finais e views de relatorio

---

## 2. Sequencia Proposta

### 01 - `20260227100000_b2b_empresas_licencas_base.sql`

Cria:
- `empresas`
- `empresa_usuarios`
- `empresa_licencas` (controle de limite simultaneo)
- `sessoes_ativas` (registro de logins ativos)

Inclui:
- indices por `empresa_id`, `status`, `data_validade`
- indices por `usuario_id`, `curso_id`, `sessao_ativa`
- constraints de consistencia (`limite_simultaneo >= sessoes_ativas_count`)

Aceite:
- cadastro e consulta por tenant funcionando

### 02 - `20260227101000_lms_catalogo_cursos_modulos_aulas.sql`

Cria:
- `cursos`
- `modulos`
- `aulas`

Inclui:
- campo `ordem` em modulos e aulas
- unicidade de ordem por escopo (`curso_id + ordem`, `modulo_id + ordem`)
- campos de video (`bunny_video_id`, `bunny_status`)

Aceite:
- trilha de curso navegavel por ordem

### 03 - `20260227102000_matricula_progresso_rpc_core.sql`

Cria:
- `usuario_curso`
- `usuario_aula_progresso`

Implementa:
- `rpc_matricular_usuario_no_curso(...)` (sem consumo de licenca)
- `rpc_matricular_lote_b2b(...)`
- `rpc_validar_acesso_simultaneo(...)` (verifica e registra sessao)
- trigger `trg_atualizar_progresso_curso`

Aceite:
- matrícula não consome licença
- login bloqueia quando atingir limite simultaneo
- progresso percentual do curso atualiza automaticamente

### 04 - `20260227103000_lxp_exercicios_flashcards_anotacoes.sql`

Cria:
- `mapas_mentais`
- `anotacoes_aluno`
- `exercicios`
- `usuario_exercicio_resposta`
- `flashcards_revisao`

Implementa:
- trigger `trg_gerar_flashcard_apos_erro`

Aceite:
- resposta errada gera flashcard automaticamente

### 05 - `20260227104000_certificados_conclusao.sql`

Cria:
- `certificados`

Implementa:
- trigger `trg_emitir_certificado`
- regra de conclusao (nota minima + obrigatorias)

Aceite:
- curso concluido gera certificado com codigo unico

### 06 - `20260227105000_rls_policies_lms_b2b.sql`

Implementa:
- enable RLS em tabelas novas
- policies por perfil (admin, professor, gestor_rh, aluno)
- restricoes por status da empresa

Aceite:
- isolamento total entre tenants validado

### 07 - `20260227106000_views_relatorios_rh.sql`

Cria:
- views de progresso corporativo
- views de desempenho por curso/empresa

Inclui:
- filtros obrigatorios por tenant
- acesso apenas para gestor_rh da propria empresa e admin

Aceite:
- RH nao enxerga dados de outra empresa

---

## 3. Testes Minimos por Migration

Para cada migration:
- teste de subida/rollback
- teste de permissao positiva por papel
- teste de negacao por papel/tenant

Casos obrigatorios:
- aluno sem matricula nao acessa aula
- empresa suspensa nao acessa player/exercicios
- aluno bloqueado quando limite simultaneo atingido
- gestor_rh nao altera limite simultaneo direto em tabela
- professor nao enxerga respostas de curso alheio

---

## 4. Dependencias de Implementacao

- Definir pasta oficial de migrations (api ou raiz)
- Definir naming padrao final de tabelas
- Definir contrato de erros para RPCs
- Definir politica de timeout de sessao (inatividade)
- Definir heartbeat para manter sessao ativa

---

## 5. Checkpoint Antes de Codar

Checklist:
- [ ] Nomes finais das entidades aprovados
- [ ] Ordem das migrations validada
- [ ] Matriz de RLS aprovada
- [ ] Cenarios de teste acordados
- [ ] Credenciais Bunny.net disponiveis para homologacao
