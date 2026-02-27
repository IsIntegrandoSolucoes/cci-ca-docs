# 🖼️ Mapa de Telas: Ecossistema CCI-CA

Este documento apresenta a listagem de todas as telas identificadas nos módulos **Administrativo** e **Portal do Aluno**, acompanhadas de um resumo de sua finalidade principal.

---

## 🏛️ 1. Módulo Administrativo (`cci-ca-admin`)

Organizado por áreas de atuação da secretaria e coordenação.

### **1.1. Gestão Acadêmica de Aulas e Espaços**

- **Agenda Diária:** Painel visual para monitoramento e gestão de horários de professores e ocupação de salas.
- **Gerenciar Agendamentos:** Listagem mestre de todos os agendamentos realizados, com filtros avançados de status e período.
- **Agendamentos Confirmados:** Fila de aulas com pagamento validado, pronta para execução.
- **Agendamentos por Professor:** Visão específica da carga horária e compromissos de um docente selecionável.
- **Espaços de Aula:** Cadastro e manutenção física das salas de aula e laboratórios.
- **Abertura de Sala:** Tela operacional para registro de início de atividades presenciais.

### **1.2. Avaliações e Resultados**

- **Tipos de Prova:** Parametrização de categorias (ex: Simulado, Regular, Substitutiva).
- **Gestão de Provas:** Cadastro dos exames, vinculando disciplinas e datas de aplicação.
- **Disciplinas de Simulado:** Configuração de matérias que compõem o currículo de avaliações.
- **Digitação de Respostas:** Interface produtiva para transcrição das escolhas dos alunos.
- **Visualizar Gabarito:** Consulta comparativa entre o desempenho do aluno e as respostas corretas.
- **Visão Geral de Simulados:** Dashboard de desempenho acadêmico consolidado por aluno.

### **1.3. Gestão de Redação**

- **Listar Redações:** Painel de controle de entregas dos alunos.
- **Manter Redação:** Cadastro de temas, propostas e bibliografia.
- **Competências de Redação:** Configuração dos critérios técnicos de avaliação (ex: gramática, coerência).
- **Lançar Notas:** Interface de correção pedagógica com atribuição de pontuação por competência.

### **1.4. Controle de Alunos**

- **Listar Todos os Alunos:** Base de dados central de cadastros.
- **Alunos Inscritos / Matriculados:** Telas segmentadas por estágio no funil de recepção.
- **Novo Aluno / Editar Aluno:** Formulário completo de dados individuais e documentos.
- **Alunos em Atraso:** Painel de inadimplência e pendências administrativas.
- **Alterar Turmas / Mentorias:** Ajustes de grade e modalidade de ensino para alunos ativos.
- **Reset de Cadastro:** Ferramenta para limpeza e reativação de acessos do aluno.

### **1.5. Contratos e Documentação**

- **Gestão de Contratos:** Listagem e filtros por status (Vigentes, Cancelados, Encerrados).
- **Contratos em PDF:** Repositório visual dos documentos gerados.
- **Gerar Contrato / Parcelas:** Automatização de criação de documentos e faturas a partir da matrícula.
- **Listagem de Declarações:** Central de emissão de certificados, declarações de matrícula e de Imposto de Renda.

### **1.6. Financeiro e Faturamento**

- **Matrículas Pagas / Não Pagas:** Controle de entrada de novos alunos.
- **Parcelas Geradas (Painel Financeiro):** Visão macro das contas a receber da instituição.
- **Manter Parcelas Aluno:** Gestão individual financeira por estudante (ajustes, descontos).
- **Baixa de Pagamento:** Conciliação manual para casos não detectados automaticamente.
- **Nota Fiscal / Lotes NFe:** Interface de integração com órgãos fiscais para faturamento.
- **Configuração de Taxas:** Gestão das regras de split de pagamento por modalidade.
- **Relatórios de Repasse:** Painel de apuração de valores devidos a professores e parceiros.

### **1.7. Estrutura e Apoio**

- **Anos Letivos:** Configuração de períodos escolares.
- **Disciplinas e Turmas:** Gestão da grade curricular e agrupamentos de alunos.
- **Professores:** Cadastro e gestão do corpo docente.
- **Home / Dashboard Admin:** Resumo estatístico de operações do dia.

### **1.8. Comercial e B2B (SaaS)**

- **Gestão de Empresas:** Lista de clientes corporativos, status (Ativa, Suspensa, Expirada) e dados fiscais.
- **Gestão de Licenças:** Configuração de limite de usuários simultâneos por empresa/curso e painel de sessões ativas vs contratado.
- **Matrículas em Lote:** Interface para upload de CSV e matrícula massiva de colaboradores (sem limite de matrículas, apenas de acessos simultâneos).
- **Dashboard de Engajamento (RH):** Visão exclusiva para gestores acompanharem o progresso de seus colaboradores e monitoramento de sessões ativas.

### **1.9. Estúdio de Criação (LMS)**

- **Meus Cursos:** CRUD principal do curso (Título, Descrição, Capa, Carga Horária).
- **Construtor de Trilha:** Interface visual para criar Módulos e Aulas, definindo a ordem de navegação.
- **Editor de Aula:** Upload de mídia (Bunny.net), PDFs, criação de Mapas Mentais e cadastro de Exercícios.

---

## 🎓 2. Módulo Portal do Aluno (`cci-ca-aluno`)

Interface simplificada e focada na experiência do usuário.

### **2.1. Central do Aluno**

- **Dashboard Aluno:** Tela principal com resumo de próximas aulas, status financeiro e novidades.
- **Perfil:** Gestão de dados pessoais e foto do perfil institucional.
- **Home:** Área de boas-vindas e acesso rápido.

### **2.2. Acadêmico e Agendamentos**

- **Agenda Disponível:** Calendário interativo para reserva de horários (Particular, Grupo, etc.).
- **Meus Agendamentos:** Listagem cronológica das aulas marcadas pelo aluno.
- **Minhas Turmas:** Painel de acompanhamento das turmas de longo prazo e acesso a contratos.

### **2.3. Financeiro**

- **Financeiro Portal:** Tela de consulta de parcelas e geração de meios de pagamento (PIX).

### **2.4. Acesso e Entrada**

- **Login / Esqueci Minha Senha:** Portas de acesso ao sistema.
- **Cadastro Inicial:** Fluxo de boas-vindas para novos alunos (onboarding).
- **Confirmação de E-mail / Redefinir Senha:** Gestão de segurança e identidade.

### **2.5. Experiência de Aprendizagem (LXP)**

- **Meus Cursos (Vitrine):** Cards dos cursos matriculados com barra de progresso e status de bloqueio B2B.
- **Sala de Aula Virtual (Player LXP):** Player de vídeo seguro (Bunny.net), trilha de navegação sequencial e Caderno Inteligente (Mapas Mentais e anotações em áudio/texto).
- **Área de Exercícios:** Tela focada para responder questões da aula com feedback imediato.
- **Plano de Estudos (Flashcards):** Interface de revisão espaçada gerada automaticamente a partir de erros em exercícios.
- **Meus Certificados:** Lista de cursos concluídos com download de PDF e validação via QR Code.
