# 💰 Sistema Financeiro e de Contratos - Portal Administrativo

**Versão:** 1.0  
**Módulo:** cci-ca-admin  
**Última Atualização:** 21/08/2025

## 📋 Visão Geral

O Portal Administrativo integra um sistema completo de gestão financeira e contratual, responsável pelo controle de matrículas, geração de contratos, criação de parcelas e acompanhamento de pagamentos.

O Sistema de Configuração de Taxas é sobre REPASSE FINANCEIRO:

Por Modalidade: "Quanto os professores ganham nesta modalidade?" (padrão)
Por Participante: "Quanto ESTE professor específico ganha?" (exceção)
Relatórios: "Quanto foi repassado para cada professor?" (visualização)

## 🏗️ Arquitetura do Sistema

### **Módulos Principais**

O sistema é organizado em 7 módulos especializados:

1. **Gestão de Matrículas Pagas**
2. **Gestão de Matrículas Não Pagas**
3. **Geração de Contratos**
4. **Listagem e Manutenção de Contratos**
5. **Gestão de Contratos PDF**
6. **Gestão de Parcelas Geradas**
7. **Sistema de Auditoria Financeira**

### **Integração de Dados**

**Tabelas Principais:**

-    `alunos_contrato_turmas` - Vínculos contratuais
-    `contrato_ano_pessoa` - Parcelas individuais
-    `auditoria` - Registro de operações
-    Views otimizadas para consultas financeiras

## 📋 Funcionalidades por Módulo

### **1. Gestão de Matrículas Pagas**

**Objetivo:** Administrar alunos que quitaram a matrícula e necessitam geração de parcelas subsequentes.

**Funcionalidades:**

-    Listagem hierárquica por aluno e turma
-    Visualização de valores pagos e descontos aplicados
-    Status automatizado de pagamentos
-    Integração com sistema de geração de parcelas

**Componentes:**

-    Interface de listagem com DataGrid especializado
-    Sistema de filtros e busca
-    Indicadores visuais de status
-    Ações contextuais por registro

### **2. Gestão de Matrículas Não Pagas**

**Objetivo:** Controlar pendências de matrícula e processos de cobrança.

**Funcionalidades:**

-    Identificação automática de inadimplência
-    Cálculo de juros e multas
-    Gestão de prazos e vencimentos
-    Notificações automatizadas

### **3. Sistema de Geração de Parcelas**

**Objetivo:** Automatizar a criação de parcelas mensais baseadas em contratos de matrícula.

**Funcionalidades Técnicas:**

-    **Cálculo Automático:** Baseado em valor de mensalidade e descontos
-    **Configuração de Vencimentos:** Dia personalizável por contrato
-    **Sistema de Descontos:** Múltiplas categorias (vencimento, especial, P3, P5)
-    **Validação de Dados:** Integridade referencial e regras de negócio
-    **Transações ACID:** Operações atômicas com rollback automático

**Tipos de Desconto:**

-    **Desconto por Vencimento:** Pagamento antecipado
-    **Desconto Especial:** Promocional ou negociado
-    **Desconto P3:** Para pagamento em 3 parcelas
-    **Desconto P5:** Para pagamento em 5 parcelas
-    **Desconto Personalizado:** Valor livre definido pelo operador

**Processo de Geração:**

1. Validação de elegibilidade do contrato
2. Cálculo de parcelas baseado em parâmetros da turma
3. Aplicação de descontos conforme política comercial
4. Criação de registros em tabelas de controle
5. Vinculação com contrato principal
6. Registro de auditoria para rastreabilidade

### **4. Gestão de Contratos**

**Objetivo:** Administrar o ciclo de vida completo dos contratos educacionais.

**Funcionalidades:**

-    **Criação de Contratos:** Wizard com validações automatizadas
-    **Listagem e Busca:** Interface otimizada para consultas
-    **Manutenção:** Edição de dados contratuais
-    **Versionamento:** Controle de alterações e histórico

### **5. Gestão de Documentos PDF**

**Objetivo:** Controlar a geração, assinatura e arquivamento de contratos em PDF.

**Funcionalidades:**

-    Geração automática de documentos
-    Controle de status de assinatura
-    Armazenamento seguro de arquivos
-    Rastreabilidade de versões

### **6. Gestão de Parcelas Geradas**

**Objetivo:** Administrar parcelas criadas, controlar pagamentos e inadimplência.

**Funcionalidades:**

-    Listagem completa de parcelas por período
-    Controle de status de pagamento
-    Cálculo automático de juros e multas
-    Relatórios financeiros especializados

## 🔄 Fluxos Operacionais

### **Fluxo 1: Matrícula para Parcelas**

1. Aluno efetua pagamento de matrícula
2. Sistema identifica matrícula paga sem parcelas
3. Operador acessa módulo de matrículas pagas
4. Sistema exibe interface de geração de parcelas
5. Configuração de descontos e vencimentos
6. Geração automática de parcelas subsequentes
7. Registro de auditoria e notificações

### **Fluxo 2: Gestão de Inadimplência**

1. Sistema identifica vencimentos em atraso
2. Cálculo automático de juros e multas
3. Atualização de status para inadimplente
4. Geração de relatórios de cobrança
5. Ações de cobrança automatizadas

### **Fluxo 3: Controle Contratual**

1. Criação de contrato via wizard
2. Vinculação com dados do aluno e turma
3. Geração de documento PDF
4. Processo de assinatura digital
5. Ativação do contrato e geração de parcelas

## ⚙️ Configurações do Sistema

### **Parâmetros por Turma**

-    Valor base da mensalidade
-    Percentuais de desconto por categoria
-    Dia padrão de vencimento
-    Políticas de juros e multa

### **Configurações Globais**

-    Regras de cálculo de inadimplência
-    Prazos para notificações
-    Templates de documentos
-    Integrações bancárias

## 🔒 Controles de Segurança

### **Auditoria Completa**

-    Registro de todas as operações financeiras
-    Identificação do usuário responsável
-    Timestamp de operações
-    Backup de dados anteriores

### **Validações de Integridade**

-    Verificação de dados obrigatórios
-    Validação de valores e datas
-    Controle de duplicidades
-    Verificação de dependências

### **Controle de Acesso**

-    Permissões por módulo
-    Aprovações para operações críticas
-    Log de acessos e operações
-    Rastreabilidade de alterações

## 📊 Indicadores e Relatórios

### **Dashboards Financeiros**

-    Receita realizada vs. projetada
-    Taxa de inadimplência por turma
-    Análise de descontos aplicados
-    Fluxo de caixa por período

### **Relatórios Operacionais**

-    Contratos vencendo no período
-    Parcelas em atraso por aluno
-    Efetividade de políticas de desconto
-    Performance de cobrança


