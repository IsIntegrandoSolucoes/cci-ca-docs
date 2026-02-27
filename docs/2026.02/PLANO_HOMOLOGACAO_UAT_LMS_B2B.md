# Plano de Homologacao (UAT) - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento de validacao funcional  
**Versao:** 1.0

---

## 1. Objetivo

Definir o plano de homologacao funcional (UAT) por perfil para validar os fluxos criticos do LMS + B2B antes de go-live.

Referencias:

- [INDICE_DOCUMENTACAO_LMS_B2B.md](INDICE_DOCUMENTACAO_LMS_B2B.md)
- [MATRIZ_RBAC_LMS_B2B.md](MATRIZ_RBAC_LMS_B2B.md)
- [MAPA_ROTAS_UI_LMS_B2B.md](MAPA_ROTAS_UI_LMS_B2B.md)
- [ENDPOINTS_API_LMS_B2B.md](ENDPOINTS_API_LMS_B2B.md)

---

## 2. Escopo de Homologacao

Inclui:

- Fluxos principais por perfil (`admin_interno`, `professor`, `gestor_rh`, `aluno`).
- Regras criticas de negocio (simultaneidade, progressao sequencial, matricula sem consumo).
- Validacao de permissoes e isolamento multi-tenant.
- Emissao e validacao de certificado.

Nao inclui:

- Testes de carga extensivos (fora do UAT funcional).
- Testes de seguranca ofensiva aprofundados.

---

## 3. Criterios de Entrada e Saida

## 3.1 Entrada

- Ambientes de homologacao configurados.
- Massa de dados por tenant disponivel.
- Endpoints e fluxos principais implementados.
- RLS e RBAC ativados em homologacao.

## 3.2 Saida

- 100% dos cenarios P0 aprovados.
- Minimo de 95% de cenarios P1 aprovados.
- Defeitos criticos bloqueadores resolvidos.
- Termo de aceite funcional assinado pelo PO.

---

## 4. Massa de Dados Minima

- 2 empresas (`empresa_a`, `empresa_b`) com limites distintos.
- 1 admin interno.
- 2 professores (um por tenant quando aplicavel).
- 2 gestores RH (um por empresa).
- 20 alunos por empresa.
- 2 cursos por empresa, cada um com no minimo 5 aulas sequenciais.
- Exercicios cadastrados em ao menos 3 aulas por curso.

---

## 5. Cenarios UAT por Perfil

## 5.1 Admin Interno

### UAT-ADM-001 - Criar empresa com limite simultaneo

**Prioridade:** P0  
**Pre-condicao:** Usuario admin autenticado

**Passos:**

1. Acessar modulo de empresas.
2. Criar nova empresa com `limite_usuarios_simultaneos = 30`.
3. Salvar e reabrir cadastro.

**Resultado esperado:**

- Empresa criada com sucesso.
- Limite gravado e exibido corretamente.

**Evidencia:**

- Print da listagem e do detalhe da empresa.

### UAT-ADM-002 - Alterar status de empresa

**Prioridade:** P1

**Passos:**

1. Alterar empresa para status inativo/expirada.
2. Tentar login de usuario vinculado.

**Resultado esperado:**

- Fluxo bloqueia novo acesso conforme regra de status.

---

## 5.2 Professor

### UAT-PROF-001 - Criar curso com modulos e aulas em ordem

**Prioridade:** P0  
**Pre-condicao:** Professor com permissao de edicao

**Passos:**

1. Criar curso novo.
2. Adicionar 1 modulo e 5 aulas com ordem crescente.
3. Publicar curso.

**Resultado esperado:**

- Curso publicado com estrutura sequencial valida.
- Ordens sem duplicidade no modulo.

### UAT-PROF-002 - Vincular video em aula

**Prioridade:** P1

**Passos:**

1. Enviar video para aula.
2. Aguardar processamento.

**Resultado esperado:**

- Aula recebe identificador de video.
- Estado de processamento exibido corretamente.

---

## 5.3 Gestor RH

### UAT-RH-001 - Matricula individual sem consumo

**Prioridade:** P0  
**Pre-condicao:** Colaborador ativo na empresa

**Passos:**

1. Acessar tela de matriculas.
2. Matricular colaborador em curso.
3. Conferir listagem de matriculas e painel de licencas.

**Resultado esperado:**

- Matricula criada em `usuario_curso`.
- Nao ha decremento de "saldo" por matricula.
- Limite simultaneo permanece inalterado.

### UAT-RH-002 - Matricula em lote por CSV

**Prioridade:** P1

**Passos:**

1. Importar CSV com registros validos e invalidos.
2. Executar processamento.

**Resultado esperado:**

- Retorno com resumo por linha (sucesso/falha).
- Erros com motivo claro.

### UAT-RH-003 - Monitorar sessoes ativas

**Prioridade:** P1

**Passos:**

1. Abrir painel de sessoes ativas.
2. Solicitar acessos simultaneos com usuarios da empresa.

**Resultado esperado:**

- Contador `sessoes_ativas / limite` atualizado.
- Lista mostra apenas usuarios da propria empresa.

---

## 5.4 Aluno

### UAT-ALN-001 - Bloqueio por progressao sequencial

**Prioridade:** P0

**Passos:**

1. Tentar abrir aula 3 sem concluir aula 2.

**Resultado esperado:**

- Sistema bloqueia acesso e informa regra de progressao.

### UAT-ALN-002 - Validacao de simultaneidade no player

**Prioridade:** P0

**Passos:**

1. Preencher o limite de sessoes da empresa com outros usuarios.
2. Tentar entrar no player com mais um usuario.

**Resultado esperado:**

- Retorno de bloqueio com mensagem de limite atingido.
- Status HTTP de referencia mapeado no contrato da API.

### UAT-ALN-003 - Heartbeat e expiracao de sessao

**Prioridade:** P0

**Passos:**

1. Iniciar aula e manter player aberto.
2. Verificar atualizacoes de heartbeat.
3. Fechar aba sem logout e aguardar janela de expiracao.

**Resultado esperado:**

- Sessao mantida enquanto heartbeat ativo.
- Sessao removida apos timeout sem heartbeat.

### UAT-ALN-004 - Emissao de certificado ao concluir curso

**Prioridade:** P0

**Passos:**

1. Concluir todas as aulas obrigatorias.
2. Acessar area de certificados.
3. Validar certificado pelo codigo publico.

**Resultado esperado:**

- Certificado disponivel para download.
- Validacao publica retorna dados corretos.

---

## 6. Cenarios de Seguranca Funcional (UAT)

### UAT-SEC-001 - Isolamento multi-tenant na interface RH

**Prioridade:** P0

**Passos:**

1. Logar como `gestor_rh` da empresa A.
2. Tentar acessar colaborador/sessao da empresa B por URL direta.

**Resultado esperado:**

- Acesso negado ou recurso inexistente no contexto do tenant.

### UAT-SEC-002 - Restricao por perfil

**Prioridade:** P0

**Passos:**

1. Logar como `aluno`.
2. Tentar abrir rota administrativa.

**Resultado esperado:**

- Redirecionamento para rota permitida ou tela de acesso negado.

---

## 7. Registro de Defeitos

Campos obrigatorios por defeito:

- ID
- Severidade (`bloqueador`, `alto`, `medio`, `baixo`)
- Cenario UAT relacionado
- Passos para reproduzir
- Resultado esperado x obtido
- Evidencia (print/video/log)
- Status (`aberto`, `em correcao`, `validando`, `resolvido`)

Regras:

- Defeito bloqueador em cenario P0 impede aceite de fase.
- Defeito alto em cenario P0 exige plano de correcao aprovado pelo PO.

---

## 8. Checklist de Aceite Final

- [ ] Cenarios P0 aprovados integralmente.
- [ ] Cenarios P1 aprovados no percentual minimo.
- [ ] Defeitos bloqueadores zerados.
- [ ] Evidencias de UAT organizadas e rastreaveis.
- [ ] PO assinou aceite funcional.

---

## 9. Responsabilidades no UAT

- `PO`: aprovar escopo de UAT e aceite final.
- `QA Lead`: conduzir execucao e consolidar resultado.
- `Tech Lead`: priorizar correcao de defeitos criticos.
- `Leads de frente`: corrigir defeitos e apoiar retestes.

---

## 10. Evidencias Esperadas

- Planilha de execucao UAT com status por cenario.
- Capturas de tela dos fluxos P0 aprovados.
- Logs de API para cenarios de simultaneidade e bloqueio.
- Registro final de defeitos e resolucoes.
