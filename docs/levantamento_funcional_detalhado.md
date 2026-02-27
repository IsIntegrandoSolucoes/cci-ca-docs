# 📄 Levantamento Funcional Detalhado: Ecossistema CCI-CA

Este documento detalha as funcionalidades implementadas nos módulos **Administrativo** e **Portal do Aluno**, com foco em regras de negócio, fluxos operacionais e lógica de integração.

---

## 🏛️ 1. Módulo Administrativo (`cci-ca-admin`)

Responsável pela orquestração pedagógica, financeira e operacional da instituição.

### **1.1. Inteligência de Agenda e Escala**
*   **Motor de Escala (Templates de Recorrência):**
    *   Configuração de "Semana Padrão" por professor, definindo horários de início, fim e modalidade permitida.
    *   Geração massiva de horários para o semestre com base no template.
    *   Detecção de conflitos de espaço físico (sala) no momento da geração.
*   **Gestão Dinâmica de Disponibilidade:**
    *   **Bloqueios Pontuais:** Interface para remover horários específicos da grade (ex: ausência médica).
    *   **Bloqueios de Calendário:** Configuração de feriados e recessos que suspendem toda a grade automaticamente.
    *   **Reservas Temporárias:** Monitoramento de horários "congelados" por processos de pagamento em andamento (vaga pré-ocupada).
*   **Painel de Monitoramento (Agenda Diária):**
    *   Visão consolidada por Professor ou por Espaço (Sala).
    *   Status visual de cada horário: Disponível, Reservado (Pagamento pendente) ou Confirmado.

### **1.2. Módulo Acadêmico de Desempenho**
*   **Simulados e Provas:**
    *   Cadastro de Disciplinas, Tipos de Prova e Provas (período, link, etc.).
    *   **Motor de Gabarito:** Cadastro de respostas corretas por prova.
    *   **Digitação de Respostas:** Interface para o administrativo transcrever as respostas dos alunos.
    *   **Análise de Erros/Acertos:** Comparação automática item a item entre a digitação e o gabarito oficial.
*   **Módulo de Redação (Avaliação Qualitativa):**
    *   Cadastro de Temas e bibliografia de suporte.
    *   **Matriz de Competências:** Lançamento de notas fragmentadas por competência (Critérios técnicos), gerando a média final ponderada.
    *   Feedback descritivo para o aluno em cada redação.

### **1.3. Engenharia Financeira e Regras de Negócio**
*   **Split de Pagamentos (Múltiplos Recebedores):**
    *   **Configuração de Taxas:** Definição de custos fixos ou percentuais por modalidade (PIX/Boleto).
    *   **Repasse Automático:** Regras para divisão do valor recebido entre a Sede (Convênio) e o Professor/Parceiro (Participante).
    *   **Gestão de Contas Bancárias:** Vínculo de CNPJ/CPF de professores para destinação dos repasses.
*   **Faturamento e Documentação:**
    *   **Faturamento:** Geração automática de mensalidades e taxas de matrícula/contrato.
    *   **Fiscal:** Módulo de emissão de NF-e (Nota Fiscal de Serviço) integrada.
    *   **Documentos Oficiais:** Geração de PDFs com dados protegidos (Matrícula, Quitação de Débitos, Declaração de IR).
*   **Gestão de Contratos:**
    *   Fluxos de status: Vigente, Encerrado, Cancelado.
    *   Histórico de aditivos e renegociações de parcelas.

---

## 🎓 2. Módulo Portal do Aluno (`cci-ca-aluno`)

Focado na autonomia, transparência financeira e acesso ao conteúdo.

### **2.1. Jornada de Agendamentos (Self-Service)**
*   **Reserva Inteligente:**
    *   Visualização de horários livres em formato de grade ou lista.
    *   Filtro por Professor, Disciplina ou Modalidade (Particular, Grupo, Pré-Prova).
    *   Reserva imediata com geração de PIX dinâmico (Banco do Brasil).
*   **Gestão de Vagas:**
    *   Retenção de vaga durante o tempo de validade do PIX.
    *   Confirmação automática da aula assim que o banco liquida o pagamento (Webhooks).
*   **Reagendamento:**
    *   Interface para solicitar troca de horário de aulas já pagas (respeitando limites de antecedência e disponibilidade).

### **2.2. Gestão de Vida Escolar**
*   **Inscrição em Turmas:**
    *   Manifestação de interesse em turmas abertas.
    *   Acompanhamento do status da solicitação (Pendente → Inscrito → Matriculado).
    *   Bloqueio automático de novas inscrições caso haja pendência financeira impeditiva.
*   **Acesso Acadêmico:**
    *   Visualização de links para aulas remotas configuradas (Zoho Meeting).
    *   Consulta de desempenho em simulados e notas de redação detalhadas.
    *   Acesso aos documentos emitidos e contratos assinados.

### **2.3. Autogestão Financeira**
*   **Painel de Débitos:**
    *   Visão clara de parcelas vencidas e a vencer.
    *   Geração manual de novos meios de pagamento para parcelas em atraso sem necessidade de contactar a secretaria.
*   **Histórico de Transações:** Extrato completo de agendamentos pagos e mensalidades quitadas.

---

## 🔄 3. Integrações e Fluxos Transversais

*   **Banco do Brasil (API de Cobrança):** Fluxo de ida (geração de cobrança) e volta (confirmação instantânea de status).
*   **Zoho Meeting:** Automação de criação de salas e distribuição de links para aulas online.
*   **Supabase Database-Driven:** Toda a lógica de vagas e saldos de aula reside em triggers e funções de banco de dados, garantindo consistência mesmo em acessos simultâneos.
*   **Calculadora de Repasse:** Sistema que traduz o pagamento bruto do aluno em distribuições líquidas para o administrativo e corpo docente.
