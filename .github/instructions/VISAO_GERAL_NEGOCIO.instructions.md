# 🎓 Consultório de Aprendizagem CCI-CA - Visão Geral do Negócio

O **Consultório de Aprendizagem CCI-CA** é uma plataforma completa de gestão educacional que revoluciona a forma como instituições de ensino organizam aulas particulares, turmas regulares e cursos especializados. A solução integra desde o agendamento de aulas até a gestão financeira.

### Principais Diferenciais

-    **Automatização Completa**: Desde agendamentos até pagamentos via PIX
-    **Multi-Modalidade**: Aulas particulares, em grupo, pré-prova e turmas mensais
-    **Gestão Financeira Integrada**: Contratos anuais com parcelas mensais automáticas
-    **Dashboard Executivo**: Métricas em tempo real para tomada de decisão
-    **Painel Administrativo Multi-Perfil**: Interfaces específicas para cada tipo de usuário

---

## 💼 Modelo de Negócio

### Tipos de Serviços Oferecidos

### 🎯 **Aulas Particulares** ✅ **IMPLEMENTADO**

-    ✅ Agendamento flexível por demanda (Portal Aluno)
-    ✅ Pagamento por aula individual via PIX (IS Cobrança API)
-    ✅ Confirmação automática de pagamento (Webhook BB Pay)
-    ✅ Escolha livre de professor e disciplina (Sistema completo)
-    ✅ **Sistema de reservas temporárias** (15 minutos para pagamento)

### 👥 **Aulas em Grupo** ✅ **IMPLEMENTADO**

-    ✅ Vagas limitadas por sessão (Configurável via admin)
-    ✅ Sistema de ocupação de vagas em tempo real
-    ✅ Pagamento individual por participante
-    ✅ Formação automática de grupos por slot

### 📚 **Cursos Pré-Prova** ✅ **IMPLEMENTADO**

-    ✅ Modalidade específica implementada
-    ✅ Configuração de duração diferenciada (2h)
-    ✅ Valor específico por modalidade
-    ✅ Sistema de agendamento dedicado

### 🗓️ **Turmas Mensais/Contratos** ✅ **IMPLEMENTADO**

-    ✅ **Sistema completo de contratos** (Portal Admin)
-    ✅ **Gestão de matrículas pagas/não pagas**
-    ✅ **Geração automática de parcelas**
-    ✅ **Sistema de descontos** (vencimento, especial, P3, P5)
-    ✅ **Controle de inadimplência**
-    ✅ **Documentos PDF** com assinatura digital

---

## 🏗️ Módulos e Funcionalidades

### 📱 **Portal do Aluno (cci-ca-aluno)** ✅ **COMPLETO**

**Tecnologia**: React 19 + TypeScript + MUI v6 + Supabase  
**Status**: Sistema completo de agendamentos implementado

**Funcionalidades Implementadas**:

-    ✅ **Dashboard Personalizado**: Cards de estatísticas, próximas aulas, atalhos rápidos
-    ✅ **Sistema COMPLETO de Agendamentos**:
     -    **AgendaDisponivelPage**: Interface completa para criação de agendamentos
     -    **AgendamentosPage**: Listagem e gestão de agendamentos existentes
     -    **Sistema de reservas temporárias**: 15 minutos para confirmar pagamento
-    ✅ **Pagamento PIX Integrado**: QR Code + confirmação automática via webhook
-    ✅ **Serviço Híbrido**: Supabase Direct + API REST para performance otimizada
-    ✅ **Histórico Completo**: Aulas realizadas, canceladas, reagendadas
-    ✅ **Arquitetura**: 546 linhas em AgendaDisponivelPage, 449 linhas no service híbrido

### 👨‍🏫 **Módulo de Professores (cci-ca-admin)** ✅ **OPERACIONAL**

**Tecnologia**: React 18 + TypeScript + MUI v5 + Supabase  
**Status**: Sistema completo de acesso filtrado para professores

**Funcionalidades Implementadas**:

-    ✅ **Sistema de Autenticação**: Identificação automática por tipo_pessoa = 4
-    ✅ **Roteamento Condicional**: Rotas exclusivas para professores (ProfessorFilterRoutes)
-    ✅ **Contexto de Filtros**: ProfessorFilterContext com permissões automáticas
-    ✅ **Hooks de Query**: useProfessorQuery e useConditionalProfessorQuery
-    ✅ **Gestão de Agendamentos**: Visualização filtrada por disciplinas
-    ✅ **Gestão de Alunos**: Acesso apenas aos alunos de suas turmas
-    ✅ **Espaços de Aula**: Criação e gerenciamento completo
-    ✅ **Filtros Automáticos**: Por disciplinas e turmas do professor

**Componentes Principais**:

-    ✅ **GerenciarAgendamentos**: Interface para agendamentos filtrados
-    ✅ **AgendamentosConfirmados**: Visualização de aulas confirmadas
-    ✅ **ListarAlunosProfessor**: Lista de alunos das turmas do professor
-    ✅ **ListarEspacosAula**: Gestão de espaços de aula
-    ✅ **ManterAluno**: Visualização de dados de alunos (somente leitura)
-    ✅ **ManterParcelas**: Visualização de parcelas de alunos

**Segurança**:

-    ✅ Filtros aplicados automaticamente nas queries Supabase
-    ✅ Validação de permissões no frontend
-    📋 Políticas RLS recomendadas (a implementar no backend)

### 🏢 **Portal Administrativo (cci-ca-admin)** ✅ **OPERACIONAL**

**Tecnologia**: React 18 + TypeScript + MUI v5 + Supabase  
**Status**: Sistema administrativo completo

**Módulos Implementados**:

-    ✅ **Sistema de Agenda Diária** (7 componentes + hook de 679 linhas):
     -    **GerenciarAgendamentos**: Interface principal de gestão
     -    **TemplatesRecorrencia**: Criação de horários automáticos
     -    **GeracaoAutomatica**: Geração em lote de agendamentos
     -    **ExcecoesModal**: Gestão de feriados, férias, bloqueios
-    ✅ **Sistema Financeiro/Contratos**:
     -    **MatriculasPagas**: Gestão de matrículas quitadas
     -    **MatriculasNaoPagas**: Controle de inadimplência
     -    **GerarParcelasModal**: Criação automática de parcelas
     -    **ListarContratos**: CRUD completo de contratos
     -    **ParcelasGeradas**: Monitoramento de pagamentos
-    ✅ **Gestão Acadêmica**: Alunos, professores, disciplinas, turmas
-    ✅ **Sistema de Relatórios**: Declarações, notas fiscais

### 🛠️ **CCI-CA API** ✅ **BACKEND COMPLETO**

**Tecnologia**: Node.js + TypeScript + Express + Supabase  
**Deploy**: Netlify Functions (serverless-http)  
**Status**: 30+ endpoints ativos

**Módulos Implementados**:

-    ✅ **Agendamentos** (12 endpoints): CRUD completo, calendário, estatísticas
-    ✅ **Agenda Diária Avançada**: Templates, exceções, geração automática
-    ✅ **Sistema de Reagendamento**: Para aulas já pagas
-    ✅ **Pagamentos**: Integração PIX via IS Cobrança API
-    ✅ **Contratos**: Gestão completa de contratos e parcelas
-    ✅ **Admin Auth**: Criação de usuários Supabase

### 💰 **Sistema Financeiro Independente (cci-ca-financeiro)** ⚠️ **SEPARADO**

**Tecnologia**: React 18 + TypeScript + MUI v5  
**Status**: Sistema funcional independente (será migrado)

**Funcionalidades**:

-    ✅ **Checkout PIX**: Sistema de pagamento completo
-    ✅ **Dashboard Financeiro**: Métricas e contratos
-    ✅ **Gestão de Contratos**: Interface administrativa

**Nota**: Sistema separado do portal do aluno. Funcionalidades serão migradas para unificação.

---

## 🔄 Fluxos Operacionais

### 🎯 **Fluxo de Agendamento de Aula Particular (IMPLEMENTADO)**

1. **Busca e Seleção (AgendaDisponivelPage - 546 linhas)**
     - Aluno acessa `/app/agenda` no portal
     - Filtra por modalidade, professor, disciplina, data
     - Sistema consulta `view_calendario_agendamentos` via service híbrido
     - Visualização em cards com horário, professor, valor
2. **Confirmação e Pagamento (PixPagamentoDialog)**
     - Seleção do slot disponível + ResumoAgendamentoDialog
     - Sistema cria agendamento com status 'agendado' (reserva 15min)
     - Geração automática de PIX via CCI-CA API → IS Cobrança API
     - QR Code + código PIX para pagamento instantâneo
3. **Confirmação Automática (Webhook)**
     - BB Pay notifica IS Cobrança API → atualiza Supabase
     - IS Cobrança notifica CCI-CA API → muda status para 'confirmado'
     - Agendamento aparece automaticamente na view confirmados
4. **Gestão (AgendamentosPage - 222 linhas)**
     - Aluno visualiza em `/app/agendamentos`
     - Lista completa com status, possibilidade de cancelamento
     - Histórico completo de transações

### 📝 **Fluxo de Criação de Contrato Anual (IMPLEMENTADO)**

1. **Configuração Inicial (Portal Admin)**
     - Admin acessa módulos de contrato (7 páginas implementadas)
     - Define turma via `ListarContratos` + disciplinas + professores
     - Estabelece valores e cronograma de pagamento
2. **Geração de Parcelas (GerarParcelasModal)**
     - Aluno paga matrícula → aparece em `MatriculasPagas`
     - Admin seleciona → configura vencimentos e descontos
     - Sistema gera automaticamente 12 parcelas em `contrato_ano_pessoa`
3. **Gestão Contínua (ParcelasGeradas)**
     - Monitoramento via `ParcelasGeradas` interface
     - Controle de inadimplência automático
     - Sistema de auditoria completo

### 🎯 **Fluxo de Geração Automática de Agenda (IMPLEMENTADO)**

1. **Configuração de Templates (AgendaDiariaService)**
     - Professor/Admin define templates via `TemplatesRecorrenciaModal`
     - Configura horários semanais recorrentes (`agenda_templates_recorrencia`)
     - Define valores por modalidade, capacidade, recursos
2. **Geração em Lote (Função PostgreSQL)**
     - Sistema usa `gerar_agendamentos_automaticos()` SQL
     - Processa templates para períodos via `GeracaoAutomaticaModal`
     - Cria centenas de slots automaticamente
     - Valida conflitos e exceções (`agenda_excecoes`)
3. **Publicação e Disponibilização**
     - Slots aparecem automaticamente em `view_calendario_agendamentos`
     - Disponíveis para agendamento instantâneo no portal aluno
     - Monitoramento em tempo real via admin

---

## 💳 Sistema de Pagamentos

### 🏦 **Integração Bancária PIX via IS Cobrança API**

**Arquitetura Real Implementada:**

-    **IS Cobrança API v2.0**: Intermediário especializado para Banco do Brasil
-    **cci-ca-api**: Backend principal que solicita PIX via IS Cobrança
-    **Webhook Automático**: BB Pay → IS Cobrança → CCI-CA API → Supabase
-    **Confirmação Instantânea**: Status atualizado em segundos após pagamento

**Características Técnicas:**

-    **Pagamento Instantâneo**: Confirmação automática via webhook
-    **Conciliação Automática**: Sistema próprio de códigos únicos
-    **Múltiplas APIs**: 30+ endpoints no IS Cobrança + integração CCI-CA
-    **Timeout Otimizado**: 1800s para funções Netlify serverless

**Tipos de Código de Conciliação Implementados:**

-    `AP-XXXXX`: Aulas Particulares (implementado)
-    `AG-XXXXX`: Aulas em Grupo (implementado)
-    `PP-XXXXX`: Cursos Pré-Prova (implementado)
-    `CM-XXXXX`: Contratos Mensais (implementado)

**Fluxo Real de Pagamento:**

1. Aluno agenda aula → CCI-CA API solicita PIX → IS Cobrança API
2. IS Cobrança comunica com BB Pay → QR Code gerado
3. Aluno paga via PIX → BB Pay notifica IS Cobrança (webhook)
4. IS Cobrança atualiza Supabase → CCI-CA API confirma agendamento
5. Status muda de 'agendado' para 'confirmado' automaticamente

### 💰 **Gestão de Contratos e Parcelas (Portal Admin)**

**Sistema Completo Implementado:**

**Tabelas Principais do Supabase:**

-    `alunos_contrato_turmas` - Vínculos contratuais aluno-turma
-    `contrato_ano_pessoa` - Parcelas individuais com descontos
-    `auditoria` - Log completo de operações

**Módulos Funcionais:**

-    ✅ **MatriculasPagas**: Interface para alunos com matrícula quitada
-    ✅ **GerarParcelasModal**: Geração automática de 12 parcelas mensais
-    ✅ **Sistema de Descontos**: 5 tipos (vencimento, especial, P3, P5, personalizado)
-    ✅ **ParcelasGeradas**: Monitoramento e controle de inadimplência

**Fluxo de Geração de Parcelas:**

1. Aluno paga matrícula → Aparece em "MatriculasPagas"
2. Admin seleciona → Abre "GerarParcelasModal"
3. Configura vencimentos e descontos → Sistema gera 12 parcelas
4. Parcelas aparecem em "ParcelasGeradas" para acompanhamento

**Modalidades de Pagamento:**

-    **Pagamento sob demanda** (PIX instantâneo):
     -    Aulas Particulares
     -    Aulas Em Grupo
     -    Pré-Prova
-    **Mensalidade contratual** (parcelas):
     -    Turmas de Vestibular
     -    Turmas de Mentoria
     -    Contratos anuais

---

## 📊 Relatórios e Gestão

### 📈 **Dashboard Executivo em Tempo Real (IMPLEMENTADO)**

**Portal Admin - Métricas Operacionais:**

-    ✅ Taxa de ocupação via `view_calendario_agendamentos`
-    ✅ Receita por modalidade via sistema de contratos
-    ✅ Monitoramento de agendamentos confirmados vs pendentes
-    ✅ Estatísticas de templates de agenda via `AgendaDiariaService`

**Portal Admin - Métricas Financeiras:**

-    ✅ Gestão de parcelas via `ParcelasGeradas` (implementado)
-    ✅ Controle de inadimplência via `MatriculasNaoPagas`
-    ✅ Sistema de auditoria para rastreabilidade completa
-    ✅ Acompanhamento de pagamentos PIX em tempo real

**Portal Aluno - Dashboard Individual:**

-    ✅ Cards de estatísticas pessoais (próximas aulas, gastos)
-    ✅ Histórico completo via `AgendamentosPage`
-    ✅ Status de pagamentos e contratos

### 🏗️ **Infraestrutura de Banco de Dados (SUPABASE)**

**Tabelas Principais Implementadas:**

-    ✅ `agenda_templates_recorrencia` - Templates de horários
-    ✅ `agenda_excecoes` - Feriados, férias, bloqueios
-    ✅ `agendamentos_alunos` - Agendamentos com sistema de reservas
-    ✅ `alunos_contrato_turmas` - Vínculos contratuais
-    ✅ `contrato_ano_pessoa` - Sistema de parcelas
-    ✅ `pagamentos` - Conciliação PIX automática
-    ✅ `auditoria` - Log completo de operações

**Views Otimizadas:**

-    ✅ `view_calendario_agendamentos` - Consulta rápida de slots
-    ✅ `view_agendamentos_confirmados` - Admin de confirmados
-    ✅ Views financeiras para contratos e parcelas

**Funções PostgreSQL:**

-    ✅ `gerar_agendamentos_automaticos()` - Geração em lote
-    ✅ Triggers para gestão automática de vagas
-    ✅ Validações de integridade referencial

---

## 🎓 LMS + B2B — Modelo de Negócio e Monetização

### Dois Públicos-Alvo

O módulo LMS atende dois perfis distintos de clientes:

#### 1. Professor Individual (B2C — SaaS)

-    O professor se cadastra como pessoa física e assina um **plano mensal** de uso da plataforma.
-    **Planos disponíveis:**
     -    **Professor Starter** — R$ 97/mês (até 3 cursos, 50 alunos simultâneos, 5 GB)
     -    **Professor Pro** — R$ 197/mês (até 10 cursos, 200 alunos simultâneos, 25 GB)
-    O professor cria cursos, matricula alunos e **recebe diretamente na sua conta bancária via split de pagamento**.
-    A plataforma retém um percentual de cada pagamento do aluno (via split automático).

#### 2. Empresa / Curso (B2B)

-    A empresa (PJ) se cadastra e assina uma **mensalidade mensal** para uso da plataforma.
-    A empresa cadastra **múltiplos professores** vinculados a ela.
-    A empresa oferece cursos com **contratos anuais para seus alunos** (o contrato é entre a empresa e o aluno, NÃO com a plataforma).
-    A plataforma retém um **percentual de cada pagamento do aluno via split de pagamento**.
-    **Preço: sob consulta** (depende de volume, licenças, etc.)

### Split de Pagamento

O split é o mecanismo central de monetização e aplica-se a ambos os perfis:

-    **Para o Professor:** Aluno paga pelo curso → plataforma retém sua % → professor recebe o restante direto na conta bancária.
-    **Para a Empresa:** Aluno paga pelo curso/contrato anual → plataforma retém sua % → empresa recebe o restante direto na conta bancária.

### Resumo da Receita da Plataforma

| Fonte de Receita              | Professor Individual | Empresa B2B     |
| ----------------------------- | -------------------- | --------------- |
| Assinatura mensal (SaaS)      | ✅ R$ 97 ou R$ 197   | ✅ Sob consulta  |
| % sobre pagamento do aluno    | ✅ Via split          | ✅ Via split     |
| Contrato anual com aluno      | ❌ Não se aplica      | ✅ Empresa ↔ Aluno |
