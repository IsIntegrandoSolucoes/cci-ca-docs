# Onboarding CCI-CA — Configuração de Workspace

Este guia ajuda a configurar seu ambiente de desenvolvimento conforme os padrões modernos do projeto.

## 1. Pré-requisitos

- **VS Code Insiders 1.110+**
- **Node.js 20+**
- **Git** configurado com seu e-mail pessoal/profissional.

## 2. Setup do Workspace

1. Clone os repositórios necessários para a pasta raiz `Workspace - CCI - CA`.
2. Abra o arquivo `Consultório de Aprendizagem.code-workspace` no VS Code.
3. Se solicitado, instale as extensões recomendadas.

## 3. Autenticação Segura

- **NUNCA** commite arquivos `.env`. Use o `.env.example` de cada projeto como base.
- Use chaves SSH para interagir com o GitHub.
- Configurações de MCPs (Supabase, etc) devem ficar nas suas **User Settings** locais do VS Code, nunca no workspace versionado.

## 4. Fluxo de Trabalho e IA

- **Commits**: Siga o padrão Conventional Commits em pt-BR. O Husky validará sua mensagem.
- **IA**: Use o Copilot Chat e aproveite as **Skills** em `.github/skills/` e **Prompts** em `.github/prompts/`.
- **Toolsets**: Use o Tools Picker para acessar ferramentas de banco de dados, testes e frontend.

## 5. Comandos Úteis

- `Dev: All`: Inicia Admin, Aluno e API simultaneamente.
- `npm run lint`: Executa validação de código em cada projeto.
