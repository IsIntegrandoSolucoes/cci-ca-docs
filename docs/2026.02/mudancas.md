Professores poderão se cadastrar avulsamente sem curso, e depois associar seus cursos a um plano de assinatura, ou seja, o professor pode criar um curso e depois escolher um plano de assinatura para ele. O professor pode escolher entre os seguintes planos de assinatura:

1. VIDEO AULAS GRAVADAS - SAAS
   1. pacotes de assinatura em que o professor pode escolher ENTRE fazer upload de video para execução exclusiva e privada (mais caro) - BUNNY.NET
   2. pacotes de assinatura em que o professor pode escolher ENTRE fazer upload de video para execução exclusiva e privada (mais barato) - YOUTUBE

2. ALUNOS LOGADOS NO SISTEMA SIMULTANEAMENTE
   1. pacotes com X alunos logados simultaneamente (ex: 100, 200, 500, 1000, etc)

3. AULAS AO VIVO - SAAS
   1. pacotes de assinatura em que o professor pode escolher ENTRE fazer transmissão ao vivo para execução exclusiva e privada (mais caro) - ZOHO MEETING

---

# MODULO ALUNOS + ADMIN - NOVA FEATURE: Anotações com Mapa Mental

- o professor pode criar um mapa mental para cada aula, e os alunos podem acessar esse mapa mental para fazer anotações durante a aula. O mapa mental pode ser acessado durante a aula ao vivo ou durante a visualização das videoaulas gravadas. O mapa mental pode ser exportado em formato PDF ou imagem para que os alunos possam salvar suas anotações.
- as anotações podem ser gravadas com microfone pelos alunos usando reconhecimento de fala para transcrever as anotações em texto, ou os alunos podem digitar suas anotações manualmente.

# MODULO ALUNOS + ADMIN - NOVA FEATURE: Exercícios da Aula

- o professor pode criar exercícios para cada aula, e os alunos podem acessar esses exercícios para praticar o conteúdo da aula. O professor tem total acesso ao form dos exercícios. Os exercícios podem ser de múltipla escolha, verdadeiro ou falso, ou dissertativos. Os alunos podem enviar suas respostas e o sistema corrige com base no gabarito que o professor vai criar para cada exercício. O professor pode escolher se os exercícios são obrigatórios ou opcionais para os alunos, e o sistema pode gerar relatórios de desempenho dos alunos com base nas respostas dos exercícios.

- O que o aluno errar será transformado em flash card para exibir ao aluno posteriormente. E com isso, o sistema pode criar um plano de estudo personalizado para cada aluno com base nas suas dificuldades, e o aluno pode acessar esse plano de estudo para revisar os conteúdos que ele tem mais dificuldade. O sistema pode enviar notificações para os alunos para lembrá-los de revisar os conteúdos que eles têm mais dificuldade, e o professor pode acompanhar o progresso dos alunos com base nos exercícios e no plano de estudo personalizado.

1. O que entra no ADMIN (novo “LMS + B2B”)
   1.1. Cadastro de Empresas Cliente (B2B)

Menu: Comercial ▸ Empresas

Telas

Listar empresas (status: ativa/suspensa/expirada)

Criar/editar empresa

Contatos + dados fiscais

Plano (limite usuários / validade / features)

Regras

Empresa expirada = bloqueia acesso de todos os usuários daquele tenant (sem conversa).

Empresa suspensa = idem.

1.2. Gestão de Licenças (quantidade de acessos simultâneos por curso)

Menu: Comercial ▸ Licenças

Telas

Vincular empresa/professor → curso → limite simultâneo → validade

Ver “limite simultâneo vs sessões ativas vs disponível”

Histórico (auditável)

Regras críticas

Licença não consome por matrícula. O controle é por sessões simultâneas ativas.

Se atingiu o limite simultâneo, novo login/acesso é bloqueado até liberar uma sessão.

1.3. Catálogo de Cursos (LMS)

Menu: Acadêmico ▸ Cursos Online

Telas

CRUD Curso (título, descrição, carga horária, público B2B/B2C)

CRUD Módulos do curso (ordem)

CRUD Aulas/Conteúdos (ordem, tipo: vídeo/pdf/link)

Upload de material (PDF, anexos)

Definir se aula é obrigatória

Pré-requisitos (libera módulo 2 só após concluir módulo 1)

Regras

Ordem obrigatória (se você quiser trilha): aula N só libera após concluir N-1.

Conteúdo pode ter “janela de acesso” (ex.: 30 dias após matrícula).

1.4. Avaliações e Atividades

Menu: Acadêmico ▸ Avaliações

Telas

Criar avaliação por curso/módulo/aula

Banco de questões (objetiva, múltipla, dissertativa)

Configurar nota mínima + tentativas + tempo

Correção automática (objetivas)

Correção manual (dissertativas) com feedback

Regras

Tentativas controladas

Nota mínima para liberar certificado / concluir curso

1.5. Matrículas corporativas (turma/curso)

Menu: Operação ▸ Matrículas (Corporativo)

Telas

Importar lista (CSV) de colaboradores

Matricular em lote (empresa X → curso Y)

Remover matrícula (sem impacto no limite simultâneo já que o controle é por sessão ativa)

Status por aluno: matriculado / em andamento / concluído / bloqueado

Regras

Bloqueio por expiração do contrato/licença

Consistência com “sessões ativas” e “limite simultâneo disponível”

1.6. Relatórios corporativos (RH)

Menu: Relatórios ▸ Corporativo

Telas

Progresso por empresa / setor / usuário

Conclusões, notas, tentativas

Exportar Excel/PDF

Ranking / pendências

Regras

Gestor RH só enxerga dados do tenant dele (RLS + views)

1.7. Certificados

Menu: Acadêmico ▸ Certificados

Telas

Template do certificado (logo empresa, texto padrão)

Emissão automática ao concluir (nota mínima + 100% aulas obrigatórias)

Validador público por código/QR

Regras

Certificado só emite se regras cumpridas

QR aponta pra página pública “validar”

2. O que entra no PORTAL DO ALUNO (colaborador)

Aqui é onde o usuário final vive. Tem que ser simples.

2.1. “Meus Cursos”

Menu: Cursos ▸ Meus Cursos

Telas

Lista dos cursos matriculados (progresso %)

Status: em andamento / concluído / expirado

CTA: Continuar

Regras

Se empresa expirar → mostrar “Acesso encerrado pelo contrato” (sem travar UI com erro feio)

Se curso expirou → bloqueia player/atividades

2.2. Player de Aulas (Vídeo + materiais)

Tela do curso

Estrutura em árvore: Módulos → Aulas

Player de vídeo

Download de materiais

Marcar como concluída (ou concluir automático ao terminar vídeo)

Regras

Progresso salva a cada X segundos / ao final

Se trilha obrigatória, bloqueia aulas futuras

2.3. Atividades e Provas

Tela

Iniciar avaliação

Cronômetro (se tiver)

Enviar respostas

Mostrar resultado (se permitido)

Mostrar feedback do corretor (dissertativa)

Regras

Tentativas

Nota mínima

Lock após envio (evitar fraude simples)

2.4. Certificado

Tela

Botão “Baixar Certificado”

Código de validação + QR

2.5. Acesso controlado / Sessão

Tela

Mensagem clara quando:

Limite de acessos simultâneos atingido

Contrato expirou

Usuário desativado

Nada de “erro 401” na cara do aluno.

3. Regras de Banco (Supabase) que você vai precisar acrescentar

Se você já usa lógica em triggers/funções, beleza. Agora precisa acrescentar as regras do LMS:

3.1. Controle de matrícula e sessões simultâneas

Função: matricular_usuario_no_curso(tenant_id, user_id, curso_id)

valida contrato/empresa

valida elegibilidade de matrícula (sem consumo de licença)

não consome licença na matrícula

cria registro em usuario_curso

Função: validar_acesso_simultaneo(tenant_id, user_id, curso_id)

valida limite simultâneo contratado para empresa/professor

contabiliza sessão ativa no login/acesso

libera sessão no logout/timeout

3.2. Progresso

Tabela usuario_aula_progresso (assistiu %, concluído, last_position)

Trigger pra atualizar usuario_curso.progresso_percentual

3.3. Emissão de certificado

Trigger ao concluir curso:

valida nota mínima + aulas obrigatórias

gera registro certificado + código

gera PDF (edge function) e salva URL

4. O “mínimo viável” pra colocar de pé rápido (sem inventar moda)

Se você quiser botar isso no ar logo, eu faria em 3 entregas:

Entrega 1 (base)

Cursos/módulos/aulas

Meus cursos + player

Progresso

Matrícula manual pelo admin

Entrega 2 (B2B)

Empresas cliente

Licenças por curso

Matrícula em lote

Bloqueios por contrato/validade

Entrega 3 (avaliação + certificado + relatórios)

Provas/atividades

Correção

Certificado com QR

Relatórios RH

5. Perguntas iniciais (histórico, já respondidas)

Modelo de controle de licença:

- Limite de usuários simultâneos ativos (sem consumo por matrícula)

Curso libera em sequência obrigatória ou o aluno navega livre?

- A) sequencial

Pra vídeo você vai usar o quê?

- C) Bunny.net

---

# Decisões Fechadas (2026-02-27)

1. Modelo de licença:

- Controle por usuários simultâneos ativos (sem consumo por matrícula)

2. Curso libera em:

- A) sequência obrigatória

3. Provedor de vídeo:

- C) Bunny.net

Impactos diretos:

- Bloqueio de novo login/acesso quando atingir limite simultâneo.
- Necessidade de validação de progressão de aula anterior para liberar próxima aula.
- Reprodução de vídeo por token temporário no backend (sem exposição de URL final em tabela pública).

---

# Modelo de Negócio e Monetização (2026-03-03)

## Dois Públicos-Alvo

O sistema atende dois perfis distintos:

### 1. Professor Individual (B2C — SaaS)

- O professor se cadastra como pessoa física e assina um plano mensal de uso da plataforma.
- **Planos disponíveis:**
  - **Professor Starter** — R$ 97/mês (até 3 cursos, 50 alunos simultâneos, 5 GB)
  - **Professor Pro** — R$ 197/mês (até 10 cursos, 200 alunos simultâneos, 25 GB)
- O professor cria seus cursos, matricula alunos e recebe dos alunos **diretamente na sua conta bancária via split de pagamento**.
- A plataforma retém um percentual de cada pagamento do aluno (via split automático).

### 2. Empresa / Curso (B2B)

- A empresa (PJ) se cadastra e assina uma **mensalidade mensal** para uso da plataforma.
- A empresa cadastra múltiplos professores vinculados a ela.
- A empresa oferece cursos com **contratos anuais para seus alunos** (o contrato anual é entre a empresa/curso e o aluno, NÃO com a plataforma).
- A plataforma retém um **percentual de cada pagamento do aluno via split de pagamento**.
- **Preço: sob consulta** (depende de volume, licenças, etc.)

## Split de Pagamento

O split de pagamento é o mecanismo central de monetização e aplica-se a ambos os perfis:

- **Para o Professor:** O aluno paga pelo curso → a plataforma retém sua % → o professor recebe o restante diretamente na sua conta bancária.
- **Para a Empresa:** O aluno paga pelo curso/contrato anual → a plataforma retém sua % → a empresa recebe o restante diretamente na sua conta bancária.

## Resumo da Receita da Plataforma

| Fonte de Receita              | Professor Individual | Empresa B2B |
| ----------------------------- | -------------------- | ----------- |
| Assinatura mensal (SaaS)      | ✅ R$ 97 ou R$ 197   | ✅ Sob consulta |
| % sobre pagamento do aluno    | ✅ Via split          | ✅ Via split |
| Contrato anual com aluno      | ❌ Não se aplica      | ✅ Empresa ↔ Aluno |

Documentos de apoio atualizados:

- `docs/mapa_telas_modulos.md`
- `docs/2026.02/PLANO_RLS_LMS_B2B.md`
- `docs/2026.02/ROADMAP_EXECUCAO_LMS_B2B.md`
- `docs/2026.02/PLANO_MIGRATIONS_SQL_LMS_B2B.md`
