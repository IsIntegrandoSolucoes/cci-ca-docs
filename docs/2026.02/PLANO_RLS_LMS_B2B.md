# Plano de Seguranca (RLS) - LMS + B2B

Data: 2026-02-27
Origem: docs/2026.02/mudancas.md
Decisoes fechadas:
- Controle por usuarios simultaneos ativos (sem consumo por matricula)
- Navegacao sequencial obrigatoria (2.A)
- Video com Bunny.net (3.C)

---

## 1. Objetivo

Definir o modelo de seguranca de dados para o novo escopo LMS + B2B, garantindo:
- Isolamento por tenant (empresa)
- Menor privilegio por perfil
- Bloqueio imediato por contrato/limite de sessoes
- Protecao de midia (Bunny.net) por token temporario
- Controle de sessoes simultaneas ativas por empresa/curso

---

## 2. Perfis de Acesso

Perfis funcionais:
- admin_interno: equipe CCI-CA com visao operacional completa
- professor: dono do curso e de seus conteudos
- gestor_rh: administra colaboradores da propria empresa
- aluno: acesso somente ao que esta matriculado

Funcoes auxiliares previstas no banco:
- auth_user_id() -> uuid
- is_admin_interno() -> boolean
- get_empresa_id_do_usuario(usuario_id uuid) -> uuid
- is_gestor_rh_da_empresa(empresa_id uuid) -> boolean
- is_professor_do_curso(curso_id uuid) -> boolean
- empresa_status_ativo(empresa_id uuid) -> boolean

Observacao:
- Funcoes de apoio sensiveis devem ser SECURITY DEFINER com `SET search_path = public`.

---

## 3. Matriz de Permissoes (Resumo)

### 3.1 Empresas e Licencas

Tabela `empresas`:
- admin_interno: select/insert/update/delete
- gestor_rh: select/update apenas da propria empresa
- aluno: select apenas da propria empresa (status)

Tabela `empresa_usuarios`:
- admin_interno: all
- gestor_rh: select/insert/update/delete apenas usuarios da propria empresa
- aluno: select apenas do proprio vinculo

Tabela `empresa_licencas`:
- admin_interno: all
- gestor_rh: select da propria empresa
- aluno: sem acesso direto

### 3.2 Catalogo LMS

Tabela `cursos`:
- admin_interno: all
- professor: all somente dos cursos proprios
- gestor_rh/aluno: select apenas de cursos permitidos ao tenant

Tabela `modulos`, `aulas`:
- admin_interno: all
- professor: all apenas do proprio curso
- aluno/gestor_rh: select condicionado a matricula ativa e empresa ativa

### 3.3 Matricula e Progresso

Tabela `usuario_curso`:
- admin_interno: all
- gestor_rh: select de usuarios da propria empresa
- professor: select dos cursos de sua autoria
- aluno: select/update parcial do proprio registro (ex.: preferencias)

Tabela `usuario_aula_progresso`:
- admin_interno: all
- aluno: select/insert/update apenas do proprio progresso
- professor/gestor_rh: select agregado (via view), sem acesso bruto irrestrito

### 3.4 Interatividade (LXP)

Tabela `mapas_mentais`:
- professor: all (somente das proprias aulas)
- aluno: select quando matriculado no curso

Tabela `anotacoes_aluno`:
- aluno: all somente das proprias anotacoes
- demais perfis: sem leitura direta

Tabela `exercicios`:
- professor: all nos cursos proprios
- aluno: select quando aula liberada

Tabela `usuario_exercicio_resposta`:
- aluno: insert/select das proprias respostas
- professor: select das respostas das proprias questoes
- professor: update apenas campos de correcao manual/feedback

Tabela `flashcards_revisao`:
- aluno: all apenas dos proprios flashcards
- professor/gestor_rh: sem acesso direto ao conteudo individual

### 3.5 Certificacao

Tabela `certificados`:
- aluno: select dos proprios certificados
- gestor_rh: select de colaboradores da propria empresa
- admin_interno: all

---

## 4. Politicas Criticas (Nao Negociaveis)

1) Bloqueio por status da empresa:
- Se `empresas.status in ('suspensa','expirada')`, negar acesso a aulas, progresso e exercicios.

2) Licenca obrigatoria na matricula:
- Matricula so ocorre por RPC transacional que valida saldo e incrementa consumo.

3) Navegacao sequencial obrigatoria:
- Entrega de token/url de video so via RPC que valida conclusao da aula anterior.

4) Midia protegida:
- Nao expor URL final de video em tabela publica.
- Gerar assinatura temporaria no backend (TTL curto).

5) Restricao por tenant em relatorios:
- Views de RH sempre filtradas por `empresa_id` do usuario logado.

---

## 5. RPCs e Triggers Planejadas (Seguranca + Regra)

RPCs:
- `rpc_matricular_usuario_no_curso(empresa_id, usuario_id, curso_id)`
- `rpc_matricular_lote_b2b(empresa_id, curso_id, usuarios[])`
- `rpc_iniciar_aula(aula_id)`
- `rpc_obter_proxima_aula(curso_id)`

Triggers:
- `trg_atualizar_progresso_curso` em `usuario_aula_progresso`
- `trg_gerar_flashcard_apos_erro` em `usuario_exercicio_resposta`
- `trg_emitir_certificado` ao concluir curso (quando criterios forem atendidos)

---

## 6. Checklist de Validacao de RLS

Casos positivos:
- Aluno acessa somente cursos matriculados e empresa ativa
- Gestor RH enxerga somente colaboradores do proprio tenant
- Professor enxerga somente respostas de exercicios dos cursos proprios

Casos negativos:
- Aluno de empresa A nao le dados da empresa B
- Gestor RH nao altera licenca diretamente por tabela
- Usuario sem matricula nao consegue obter token de video
- Empresa expirada perde acesso imediatamente (sem dependencia de cache no frontend)

Auditoria:
- Registrar tentativas negadas de RPC sensivel (matricula, iniciar aula)
- Registrar consumo de licenca com timestamp e ator

---

## 7. Ordem Recomendada de Entrega

Fase 1 (base segura):
- Tabelas de empresas/licencas/matricula + RLS minima
- RPC de matricula com consumo de licenca

Fase 2 (consumo LMS):
- Catalogo de cursos/modulos/aulas
- Progressao sequencial + RPC iniciar aula

Fase 3 (LXP e avaliacao):
- Exercicios, flashcards, mapas mentais, anotacoes
- Certificados e visoes de relatorio por tenant

---

## 8. Riscos e Mitigacoes

Risco: bypass via consulta direta em tabelas de aula.
Mitigacao: policy + RPC para acesso ao token de video.

Risco: funcao SECURITY DEFINER sem search_path controlado.
Mitigacao: sempre declarar `SET search_path = public`.

Risco: regressao de isolamento multi-tenant em views de relatorio.
Mitigacao: testes automatizados de RLS por papel e por tenant.

---

## 9. Pronto para Implementar

Criterios para iniciar codigo SQL:
- Confirmar nomes finais das tabelas (convencao do projeto)
- Confirmar campos obrigatorios por entidade
- Confirmar se gestor RH podera matricular/reativar em lote
- Confirmar se devolucao de licenca em cancelamento sera imediata ou por politica
