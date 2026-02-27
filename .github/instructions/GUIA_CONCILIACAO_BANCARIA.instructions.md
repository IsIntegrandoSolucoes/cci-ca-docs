# 🏦 Sistema de Conciliação Bancária - CCI-CA API

**Versão:** 1.0  
**Data:** 01 de agosto de 2025  
**Status:** 📋 Especificação Técnica - Adaptação IS Cantina

---

## 🎯 Visão Geral

O sistema de conciliação bancária do CCI-CA gerencia o **fluxo completo** de pagamentos educacionais, vinculando:

-    **🎓 Slots Avulsos** → **💳 Solicitações** → **✅ Pagamentos**
-    **🎓 Contratos** → **💳 Solicitações** → **✅ Pagamentos**
-    **👥 Pessoas** → **🔖 Código único** → **🔍 Rastreabilidade**
-    **⚙️ Sistema origem ID 7** → **📊 Auditoria** → **🔗 Conciliação**

---

## 🏗️ Arquitetura CCI-CA

### 📦 **Sistema Integrado (TypeScript)**

```
cci-ca-api/             # 💳 API serverless
cci-ca-admin/           # 🖥️ Painel administrativo
cci-ca-aluno/           # 🎓 Portal do aluno
``` 

---

### 🔗 **Integração Central**

-    **Hub de Pagamentos**: `is-cobranca-database` (centralizador)
-    **Sistema Local**: `cci-ca-database` (dados educacionais)

---

### 🗂️ **Tabelas Principais**
-    `pessoas` - Dados de todas as pessoas
-    `tipo_pessoa` - Tipos (aluno, responsável, professor, etc)
-    `turmas` - Informações sobre turmas
-    `aluno_turmas` - Inscrições em turmas (não pagos)
-    `alunos_contrato_turmas` - Vínculos contratuais
-    `contrato_ano_pessoa` - Parcelas individuais
-    `auditoria` - Registro de operações
-    `solicitacoes` - Solicitações de pagamento
-    `pagamentos` - Registros de pagamentos
-    `agendamentos_alunos` - Slots avulsos agendados
-    `agendamentos_professores` - Slots avulsos dos professores
-    `modalidade_aula` - Tipos de aulas (particular, grupo, pré-prova, etc)
-    `conta_bancaria` - Contas bancárias vinculadas
-    `cnpj` - Dados de CNPJ

-    Views otimizadas para consultas financeiras

### Functions Supabase

- buscar_configuracao_taxa() - Busca taxa de serviço por modalidade 

**Lógica:**

1. **🎯 Primeira Prioridade**: Busca configuração específica do participante
     - Verifica se está dentro do período de vigência (`data_inicio` ≤ hoje ≤ `data_fim`)
     - Verifica se está ativa e não deletada
2. **📋 Segunda Prioridade**: Se não encontrar, busca configuração padrão da modalidade
3. **❌ Fallback**: Se não encontrar nenhuma, retorna erro

## 🔖 Sistema de Identificação

### **Tipos de Código de Conciliação:**

Padrão: CA-XX-{ID_INTERNO}-{TIMESTAMP}

-    `CA-AP-####-XXXXX`: Aulas Particulares -> agendamentos_alunos / agendamentos_professores
-    `CA-AG-####-XXXXX`: Aulas em Grupo -> agendamentos_alunos / agendamentos_professores
-    `CA-PP-####-XXXXX`: Cursos Pré-Prova -> agendamentos_alunos / agendamentos_professores
-    `CA-CT-####-XXXXX`: Contratos Mensais -> contrato_ano_pessoa / alunos_contrato_turmas / aluno_turmas
-    `CA-TV-####-XXXXX`: Turmas Vestibular -> contrato_ano_pessoa / alunos_contrato_turmas / aluno_turmas
-    `CA-TM-####-XXXXX`: Turmas Mentoria -> contrato_ano_pessoa / alunos_contrato_turmas / aluno_turmas

Exemplos:

-    `CA-AP-123-20250810` - Aula Particular ID 123 agendada em 10/08/2025
-    `CA-AG-321-20250815` - Aula em Grupo ID 321 agendada em 15/08/2025
-    `CA-PP-789-20250805` - Pré-Prova ID 789 agendada em 05/08/2025
-    `CA-CT-456-20250801` - Contrato ID 456 criado em 01/08/2025
-    `CA-TV-111-20250820` - Turma Vestibular ID 111 matriculada em 20/08/2025
-    `CA-TM-222-20250825` - Turma Mentoria ID 222 matriculada em 25/08/2025

### **Mapeamento para Tabelas do Banco de Dados:**

| Código             | Modalidade         | Tabela Principal      | Tabelas Relacionadas                       |
| ------------------ | ------------------ | --------------------- | ------------------------------------------ |
| `CA-AP-####-XXXXX` | Aulas Particulares | `agendamentos_alunos` | `agendamentos_professores`, `solicitacoes` |
| `CA-AG-####-XXXXX` | Aulas em Grupo     | `agendamentos_alunos` | `agendamentos_professores`, `solicitacoes` |
| `CA-PP-####-XXXXX` | Cursos Pré-Prova   | `agendamentos_alunos` | `agendamentos_professores`, `solicitacoes` |
| `CA-CT-####-XXXXX` | Contratos Mensais  | `contrato_ano_pessoa` | `alunos_contrato_turmas`, `aluno_turmas`   |
| `CA-TV-####-XXXXX` | Turmas Vestibular  | `contrato_ano_pessoa` | `alunos_contrato_turmas`, `aluno_turmas`   |
| `CA-TM-####-XXXXX` | Turmas Mentoria    | `contrato_ano_pessoa` | `alunos_contrato_turmas`, `aluno_turmas`   |

---

## 📊 Códigos de Estado - Banco do Brasil

### **💳 Estados do Pagamento (`codigo_estado_pagamento`)**

| Código | Status                            | Descrição                         | Ação Sistema CCI-CA               |
| ------ | --------------------------------- | --------------------------------- | --------------------------------- |
| `200`  | **Efetivado**                     | Pagamento confirmado e processado | ✅ Liberar acesso ao curso        |
| `201`  | **Iniciado**                      | Pagamento em processo inicial     | ⏳ Aguardar confirmação           |
| `202`  | **Agendado**                      | Agendado (ainda não disponível)   | ⏰ Aguardar data agendada         |
| `203`  | **Em processamento**              | Processando no banco              | ⏳ Aguardar finalização           |
| `205`  | **Pendente de assinatura**        | Aguarda assinatura digital        | 🖊️ Notificar aluno/responsável    |
| `206`  | **Cancelamento em processamento** | Cancelando transação              | ⚠️ Preparar estorno               |
| `207`  | **Cancelado**                     | Pagamento cancelado               | ❌ Bloquear acesso ao curso       |
| `208`  | **Abandonado**                    | Transação abandonada pelo usuário | ⏱️ Marcar matrícula como pendente |
| `209`  | **Não efetivado**                 | Falha no processamento            | ❌ Gerar nova solicitação         |
| `210`  | **Devolvido parcialmente**        | Estorno parcial realizado         | 💰 Processar devolução            |
| `211`  | **Devolvido totalmente**          | Estorno total realizado           | 💸 Cancelar matrícula             |

### **📋 Estados da Solicitação (`codigo_estado_solicitacao`)**

| Código | Status                   | Descrição                                         | Próxima Ação CCI-CA                       |
| ------ | ------------------------ | ------------------------------------------------- | ----------------------------------------- |
| `0`    | **Aguardando Pagamento** | Solicitação criada, aguardando pagamento          | 💳 Enviar link de pagamento para aluno    |
| `1`    | **Paga**                 | Pagamento confirmado (ou com pagamentos parciais) | ✅ Confirmar matrícula e liberar acesso   |
| `800`  | **Expirada**             | Prazo de pagamento expirado                       | ⏰ Notificar aluno para nova solicitação  |
| `850`  | **Abandonada**           | Solicitação abandonada pelo usuário               | 🚫 Manter matrícula pendente              |
| `900`  | **Excluída**             | Solicitação excluída administrativamente          | 🗑️ Cancelar matrícula (auditoria mantida) |


---


## ✅ Conclusão

O **código de conciliação** no formato `CA-{TIPO}-{ID}-{TIMESTAMP}` é a **chave mestra** que conecta todo o fluxo financeiro-educacional do sistema CCI-CA.

---