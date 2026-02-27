---
description:
     'Guia interativo para configurar um workspace VS Code Insiders 1.109+ do zero ou modernizar um existente. Cobre os 3 cenários de topologia (single-root, monorepo e polyrepo) e adapta multi-root, Git hooks, qualidade de código, skills, instructions, prompts, toolsets e MCPs conforme o caso.'
---

# Guia de Configuração de Workspace (VS Code Insiders 1.109+)

Você é um agente especializado em configuração de workspaces para VS Code Insiders 1.109+.

Antes de começar, **leia os arquivos existentes** do projeto para entender o estado atual e evitar sobrescrever o que já está correto. Trabalhe de forma incremental, validando cada etapa.

---

## 1. Diagnóstico Inicial

Faça as seguintes perguntas ao usuário (ou deduza pelo contexto):

1. O workspace é **novo** (do zero) ou **existente** (já em uso com versão anterior)?
2. Qual é a **topologia** do projeto? _(ver seção 1.1)_
3. Qual é a **stack**? (ex.: React + TypeScript + Vite, Express, Next.js, etc.)
4. O repositório já tem **Git configurado**? Já tem Husky?
5. Já existe alguma estrutura de IA (`.github/instructions/`, skills, `copilot-instructions.md`)?
6. Quais **MCPs** o time usa ou quer usar? (Supabase, Playwright, MUI, RefTools...)

Com base nas respostas, pule etapas já concluídas e adapte as seções seguintes à topologia identificada.

### 1.1 Topologias Suportadas

| Topologia       | Descrição                                                | Exemplo típico                                |
| --------------- | -------------------------------------------------------- | --------------------------------------------- |
| **Single-root** | Um único projeto em um único repositório                 | Landing page, API standalone                  |
| **Monorepo**    | Múltiplos projetos em um único repositório Git           | Frontend + Backend + Docs no mesmo repo       |
| **Polyrepo**    | Múltiplos repositórios abertos juntos no mesmo workspace | Microsserviços com repositórios independentes |

**O que muda por topologia:**

- **Single-root:** o `.code-workspace` pode ser substituído por `.vscode/settings.json`; tasks simples sem `${workspaceFolder:<Nome>}`; lint-staged e Husky na raiz do único projeto.
- **Monorepo:** `.code-workspace` com `"folders"` listando todas as subpastas; tasks compostas `Dev All`/`Lint All`; Husky e lint-staged na raiz do repo; `git.openRepositoryInParentFolders: "always"` obrigatório.
- **Polyrepo:** `.code-workspace` com caminhos absolutos para cada repositório; **cada repo tem seu próprio** Husky, lint-staged e Git hooks; o `.code-workspace` **não** deve ser versionado (fica apenas local ou em um repo de meta-workspace dedicado); MCPs e settings de IA ficam nas User Settings do
  VS Code.

---

## 2. Estrutura de Pastas

Adapte a estrutura conforme a topologia identificada na seção 1.1.

### Single-root

```
📁 projeto/
├── 📄 .gitmessage
├── 📄 .editorconfig
├── 📄 .gitignore
├── 📄 README.md
├── 📁 .vscode/
│   └── settings.json          ← substitui o .code-workspace
├── 📁 .husky/
│   ├── commit-msg
│   └── pre-commit
└── 📁 .github/
    ├── copilot-instructions.md
    ├── instructions/
    ├── skills/
    ├── prompts/
    └── toolsets/
```

### Monorepo

```
📁 raiz/
├── 📄 <NomeDoProjeto>.code-workspace   ← workspace multi-root
├── 📄 .gitmessage
├── 📄 .editorconfig
├── 📄 .gitignore
├── 📄 README.md
├── 📁 .husky/                           ← único, na raiz do repo
│   ├── commit-msg
│   └── pre-commit
├── 📁 <subprojeto-a>/
├── 📁 <subprojeto-b>/
└── 📁 <pasta-docs>/
    └── .github/
        ├── copilot-instructions.md
        ├── instructions/
        ├── skills/
        ├── prompts/
        └── toolsets/
```

> **Regra monorepo:** exponha sempre a raiz (`.`) como primeira pasta de `"folders"` para que `.gitmessage`, `.husky/` e o `.code-workspace` fiquem visíveis no Explorer.

### Polyrepo

```
📄 <NomeDoProjeto>.code-workspace        ← NÃO versionado (local apenas)

📁 /caminho/repo-a/                      ← repositório independente
├── .gitmessage
├── .husky/                              ← hooks próprios deste repo
└── .github/

📁 /caminho/repo-b/                      ← repositório independente
├── .gitmessage
├── .husky/
└── .github/
```

> **Regra polyrepo:** o `.code-workspace` usa caminhos absolutos e **não deve ser commitado** em nenhum repo. Skills e instructions compartilhadas podem ficar em um repo de documentação dedicado, referenciado via `chat.agentSkillsLocations` nas User Settings.

---

## 3. Arquivo `.code-workspace`

### 3.1 Folders

**Monorepo** — caminhos relativos, raiz exposta primeiro:

```jsonc
"folders": [
  { "name": "🏠 Workspace", "path": "." },
  { "name": "<emoji> <Subprojeto A>", "path": "caminho/subprojeto-a" },
  { "name": "<emoji> <Subprojeto B>", "path": "caminho/subprojeto-b" }
]
```

**Polyrepo** — caminhos absolutos, sem raiz central:

```jsonc
"folders": [
  { "name": "<emoji> Repo A", "path": "C:/caminho/absoluto/repo-a" },
  { "name": "<emoji> Repo B", "path": "C:/caminho/absoluto/repo-b" }
]
```

**Single-root** — use `.vscode/settings.json` no lugar do `.code-workspace`. Se ainda quiser `.code-workspace`:

```jsonc
"folders": [
  { "path": "." }
]
```

### 3.2 Settings obrigatórias

Inclua **todas** as settings abaixo no bloco `"settings"` do `.code-workspace`.

```jsonc
// ── Editor ──────────────────────────────────────────────────────────────────
"editor.formatOnSave": true,
"editor.tabSize": 2,
"editor.insertSpaces": true,
"editor.detectIndentation": false,
"files.autoSave": "afterDelay",
"editor.suggest.preview": true,
"editor.inlineSuggest.enabled": true,
"editor.quickSuggestions": { "other": true, "comments": true, "strings": true },

// ── Multi-root ───────────────────────────────────────────────────────────────
"workbench.editor.labelFormat": "short",
"breadcrumbs.enabled": true,
"search.useGlobalIgnoreFiles": true,
"search.followSymlinks": false,
"search.smartCase": true,
"search.exclude": {
  "**/node_modules": true, "**/dist": true, "**/build": true,
  "**/.git": true, "**/.next": true, "**/coverage": true
},

// ── Terminal ─────────────────────────────────────────────────────────────────
"terminal.integrated.cwd": "${workspaceFolder}",
"terminal.integrated.defaultProfile.windows": "PowerShell",
"terminal.integrated.profiles.windows": {
  "PowerShell": {
    "source": "PowerShell",
    "args": ["-NoExit", "-Command", "Write-Host '<NomeDoProjeto>' -ForegroundColor Cyan"]
  }
},
"terminal.integrated.stickyScroll.ignoredCommands": ["clear", "cls", "copilot", "claude", "codex", "gemini"],

// ── Git ──────────────────────────────────────────────────────────────────────
"git.enableSmartCommit": true,
"git.autofetch": true,
"git.confirmSync": false,
"git.openRepositoryInParentFolders": "always",
"git.blame.ignoreWhitespace": true,
"git.blame.editorDecoration.hoverEnabled": false,

// ── TypeScript/JavaScript — namespace unificado (VS Code 1.109+) ─────────────
// IMPORTANTE: NÃO use typescript.suggest.* ou javascript.suggest.* (deprecados)
"js/ts.preferences.includePackageJsonAutoImports": "auto",
"js/ts.suggest.autoImports": true,
"js/ts.suggest.enabled": true,
"js/ts.suggest.paths": true,
"js/ts.suggest.completeFunctionCalls": true,
"js/ts.inlayHints.parameterNames.enabled": "literals",
"js/ts.inlayHints.functionLikeReturnTypes.enabled": true,
"typescript.updateImportsOnFileMove.enabled": "always",
"javascript.updateImportsOnFileMove.enabled": "always",

// ── Browser integrado (VS Code 1.109+) ───────────────────────────────────────
"simpleBrowser.useIntegratedBrowser": true,
"workbench.browser.openLocalhostLinks": true,

// ── Tasks / Experiments ──────────────────────────────────────────────────────
"task.allowAutomaticTasks": "on",
"workbench.enableExperiments": true,
"update.mode": "start",
```

### 3.3 Settings do GitHub Copilot (obrigatórias)

```jsonc
// ── Copilot básico ────────────────────────────────────────────────────────────
"github.copilot.enable": { "*": true, "yaml": true, "plaintext": true, "markdown": true },
"github.copilot.conversation.localeOverride": "pt-BR",
"github.copilot.chat.agent.runTasks": true,
"github.copilot.chat.agent.thinkingTool": true,
"github.copilot.chat.organizationInstructions.enabled": true,
"github.copilot.chat.searchSubagent.enabled": true,

// ── Agentes e Skills (VS Code 1.109+) ────────────────────────────────────────
"chat.useAgentSkills": true,
"chat.agentSkillsLocations": {
  // ajuste os caminhos para onde ficam suas skills no repositório
  ".github/skills": true
},
"chat.agentFilesLocations": {
  ".github/agents": true
},
"chat.requestQueuing.enabled": true,
"chat.requestQueuing.defaultAction": "steer",
"chat.askQuestions.enabled": true,
"chat.hooks.enabled": true,
"chat.customAgentInSubagent.enabled": true,
"chat.restoreLastPanelSession": false,
"workbench.startupEditor": "agentSessionsWelcomePage",
```

> **Atenção sobre namespace depreciado:** Settings como `typescript.suggest.*`, `typescript.inlayHints.*` e `javascript.suggest.*` foram **deprecadas** no VS Code 1.109 em favor do namespace `js/ts.*`. Ao encontrá-las no workspace, migre-as conforme a tabela abaixo.

| Depreciado                                              | Substituto                                         |
| ------------------------------------------------------- | -------------------------------------------------- |
| `typescript.suggest.autoImports`                        | `js/ts.suggest.autoImports`                        |
| `typescript.suggest.enabled`                            | `js/ts.suggest.enabled`                            |
| `typescript.suggest.paths`                              | `js/ts.suggest.paths`                              |
| `typescript.suggest.completeFunctionCalls`              | `js/ts.suggest.completeFunctionCalls`              |
| `typescript.preferences.includePackageJsonAutoImports`  | `js/ts.preferences.includePackageJsonAutoImports`  |
| `typescript.inlayHints.parameterNames.enabled`          | `js/ts.inlayHints.parameterNames.enabled`          |
| `typescript.inlayHints.functionLikeReturnTypes.enabled` | `js/ts.inlayHints.functionLikeReturnTypes.enabled` |
| `javascript.suggest.autoImports`                        | `js/ts.suggest.autoImports`                        |

---

## 4. Git — Template de Commit e Hooks

> **Polyrepo:** execute os passos abaixo em **cada repositório** separadamente. Cada repo tem seu próprio Husky, `.gitmessage` e `package.json`.
>
> **Monorepo / Single-root:** execute uma única vez na raiz.

### 4.1 Template pt-BR (`.gitmessage`)

Crie na raiz do repositório:

```
# <tipo>: <descrição curta em português> (máx. 72 chars)
#
# Tipos permitidos:
#   feat | fix | chore | refactor | style | docs | test | perf | ci | revert
#
# Corpo (opcional) — descreva o QUÊ e POR QUÊ:
#
# Rodapé (opcional):
# BREAKING CHANGE: <descrição>
# Refs: #<issue>
```

Registre:

```bash
git config commit.template .gitmessage
```

> Salve como **UTF-8 sem BOM** — BOM causa erros em `git rebase -i`.

### 4.2 Hook `commit-msg` (Conventional Commits)

Instale Husky v9:

```bash
npm install --save-dev husky
npx husky init
git config core.hooksPath .husky/_
```

Crie `.husky/commit-msg`:

```sh
#!/bin/sh
MSG=$(cat "$1")
if ! echo "$MSG" | grep -qE "^(feat|fix|chore|refactor|style|docs|test|perf|ci|revert)(\(.+\))?: .{1,}"; then
  echo ""
  echo "❌ Mensagem de commit inválida!"
  echo "   Formato: <tipo>: <descrição em português>"
  echo "   Tipos: feat | fix | chore | refactor | style | docs | test | perf | ci | revert"
  exit 1
fi
```

```bash
chmod +x .husky/commit-msg
```

### 4.3 Hook `pre-commit` (lint-staged)

Crie `.husky/pre-commit`:

```sh
#!/bin/sh
npx lint-staged
```

Configure no `package.json`:

```jsonc
"lint-staged": {
  "**/*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
  "**/*.{json,md,yml,yaml}": ["prettier --write"]
}
```

---

## 5. Qualidade de Código

### `.editorconfig`

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false
```

### `prettier.config.js`

```js
export default {
     semi: false,
     singleQuote: true,
     trailingComma: 'es5',
     printWidth: 100,
     tabWidth: 2,
};
```

---

## 6. GitHub Copilot e IA

### 6.1 `copilot-instructions.md`

Ponto de entrada global das instruções. Coloque em `.github/copilot-instructions.md`:

```markdown
# Copilot Instructions — <Nome do Projeto>

Você é um assistente especializado neste projeto. Responda sempre em pt-BR.

## Diretrizes Gerais

Siga [instructions/GENERAL.Diretrizes.instructions.md](instructions/GENERAL.Diretrizes.instructions.md).

## Frontend

- Padrões React: [instructions/FRONTEND.React.BoasPraticas.instructions.md](...)
- Nomenclatura: [instructions/FRONTEND.React.Nomenclatura.instructions.md](...)

## Backend

- Nomenclatura de banco: [instructions/BACKEND.Supabase.Nomenclatura.instructions.md](...)

## Skills disponíveis

[liste as skills do projeto com links para os SKILL.md]
```

> Mantenha este arquivo **enxuto** — é carregado em todo contexto de chat. Detalhes ficam nos arquivos de `instructions/`.

### 6.2 Instructions (`.github/instructions/`)

Carregadas automaticamente quando o `applyTo` bate com o arquivo aberto.

**Formato:**

```markdown
---
applyTo: '**/*.{ts,tsx}'
---

# Título da Instruction

[regras para o Copilot seguir ao trabalhar com arquivos que batem com applyTo]
```

**Exemplos de `applyTo`:**

| Valor              | Quando aplica             |
| ------------------ | ------------------------- |
| `**/*.{ts,tsx}`    | Arquivos TypeScript/React |
| `**/migrations/**` | Migrations SQL            |
| `**/tests/**`      | Arquivos de teste         |
| `**`               | Todos (use com moderação) |

**Naming recomendado:** `<ESCOPO>.<Domínio>.<Subtítulo>.instructions.md`

- Ex.: `FRONTEND.React.BoasPraticas.instructions.md`, `BACKEND.Supabase.Nomenclatura.instructions.md`

### 6.3 Skills (`.github/skills/`)

Cada skill tem 3 camadas em `skills/<nome-da-skill>/`:

#### `SKILL.md` — camada normativa (obrigatória)

```markdown
---
name: nome-da-skill
description: descrição curta
---

# Nome da Skill

## Objetivo

## Escopo

## Quando NÃO usar

## Checklist
```

#### `EXECUTABLE_SKILL.yaml` — camada executável (quando aplicável)

```yaml
name: nome-da-skill
description: descrição curta
capabilities:
     - parse: ...
     - generate: ...
inputs:
     - name: campo
       description: descrição
       required: true
outputs:
     - name: saida
       format: markdown
entrypoint: SKILL.md
```

#### `RESIDUAL_MARKDOWN_SKILL.md` — camada de apoio

Exemplos, anti-padrões e contexto arquitetural. **Não duplicar** nem contradizer o `SKILL.md`.

**Ordem de prioridade:** `EXECUTABLE_SKILL.yaml` → `SKILL.md` → `RESIDUAL_MARKDOWN_SKILL.md`

**Como acionar:**

```
Aplique a skill `<nome-da-skill>` para esta tarefa: [contexto]
```

### 6.4 Prompts (`.github/prompts/`)

Tarefas reutilizáveis acionadas com `#<nome-do-arquivo>` no chat.

**Naming:** `<dominio>-<acao>.prompt.md`

**Formato:**

```markdown
---
mode: 'agent'
tools: ['read_file', 'create_file', 'run_in_terminal']
description: 'O que este prompt faz'
---

# Título do Prompt

[instrução detalhada para o agente]
```

### 6.5 Toolsets (`.github/toolsets/`)

Agrupam ferramentas MCP por domínio para uso no Tools Picker.

**Naming:** `<dominio>.toolsets.jsonc`

```jsonc
{
     "frontend": {
          "description": "Ferramentas para desenvolvimento React + MUI",
          "icon": "symbol-color",
          "tools": ["mcp_mui-mcp_useMuiDocs", "mcp_microsoft_pla_browser_snapshot", "mcp_ref-tools_ref_search_documentation", "vscode-websearchforcopilot_webSearch"],
     },
}
```

---

## 7. MCPs (Model Context Protocol)

Configure nas **User Settings** do VS Code (`Ctrl+Shift+P` → `Open User Settings JSON`) — **nunca** no `.code-workspace` versionado, pois podem conter credenciais.

### Supabase

```jsonc
"mcp": {
  "servers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest",
        "--supabase-url", "https://<PROJECT_REF>.supabase.co",
        "--service-role-key", "<SERVICE_ROLE_KEY>"]
    }
  }
}
```

Ferramentas: `execute_sql`, `apply_migration`, `generate_typescript_types`, `get_advisors`, `search_docs`.

### Playwright

```jsonc
"playwright": {
  "command": "npx",
  "args": ["-y", "@microsoft/playwright-mcp@latest"]
}
```

Ferramentas: navegação, snapshot de acessibilidade, screenshot, formulários, console, performance trace.

### MUI

```jsonc
"mui": {
  "command": "npx",
  "args": ["-y", "@mui/mcp@latest"]
}
```

Ferramentas: `useMuiDocs`, `fetchDocs`.

### Ref Tools

```jsonc
"ref-tools": {
  "command": "npx",
  "args": ["-y", "@ref-tools/mcp@latest"]
}
```

Ferramentas: `ref_search_documentation`, `ref_read_url`.

---

## 8. Tasks

### Single-root

Use `.vscode/tasks.json` com `${workspaceFolder}` sem qualificador:

```jsonc
{
     "version": "2.0.0",
     "tasks": [
          {
               "label": "Dev",
               "type": "shell",
               "command": "npm run dev",
               "isBackground": true,
               "problemMatcher": [],
               "group": "build",
          },
     ],
}
```

### Monorepo e Polyrepo

No bloco `"tasks"` do `.code-workspace`. Use `${workspaceFolder:<NomeDaPasta>}` onde `<NomeDaPasta>` é o valor de `"name"` declarado em `"folders"`:

```jsonc
"tasks": {
  "version": "2.0.0",
  "tasks": [
    {
      "label": "<Projeto>: Dev",
      "type": "shell",
      "command": "npm run dev",
      "options": { "cwd": "${workspaceFolder:<NomeDaPasta>}" },
      "isBackground": true,
      "problemMatcher": [],
      "group": "build"
    },
    {
      "label": "Dev All",
      "dependsOn": ["<Projeto A>: Dev", "<Projeto B>: Dev"],
      "dependsOrder": "parallel",
      "problemMatcher": []
    },
    {
      "label": "Lint All",
      "dependsOn": ["<Projeto A>: Lint", "<Projeto B>: Lint"],
      "dependsOrder": "parallel",
      "problemMatcher": [],
      "group": "test"
    }
  ]
}
```

---

## 9. Segurança

- **Nunca** versionar arquivos `.env` — apenas `.env.example` com valores fictícios.
- Credenciais de MCPs **somente** nas User Settings do VS Code.
- Tokens, chaves de acesso e service roles ficam **apenas** em `.env` local.

`.gitignore` mínimo:

```gitignore
node_modules/
dist/
build/
.next/
out/
coverage/
.env
.env.local
.env.*.local
*.log
.DS_Store
Thumbs.db
```

---

## 10. Para Workspaces Existentes — Roteiro de Migração

> **Identifique a topologia antes de começar** (seção 1.1). As etapas abaixo valem para todas as topologias; onde há diferença, está indicado.

Execute na ordem:

1. **Ler estado atual** — abrir `.code-workspace` (ou `.vscode/settings.json`) e verificar o que já existe.
2. **Migrar settings depreciadas** — substituir `typescript.*` e `javascript.*` pelo namespace `js/ts.*` (tabela na seção 3.2).
3. **Expor pasta raiz** _(monorepo)_ — adicionar `{ "name": "🏠 Workspace", "path": "." }` como primeira entrada de `"folders"`. _(polyrepo: não se aplica; single-root: não necessário)_
4. **SCM multi-root** _(monorepo/polyrepo)_ — adicionar `"git.openRepositoryInParentFolders": "always"`.
5. **Migrar Husky** — se for v8 ou não existir: `npm install --save-dev husky && npx husky init && git config core.hooksPath .husky/_`. _(polyrepo: repetir em cada repo)_
6. **Adicionar settings Copilot/Agents** — colar o bloco da seção 3.3. _(polyrepo: pode ir nas User Settings para ser global a todos os repos)_
7. **Criar estrutura de IA** — se não existir: `mkdir -p .github/instructions .github/skills .github/prompts .github/toolsets` + `copilot-instructions.md`. _(polyrepo: criar em um repo de docs dedicado e referenciar via `chat.agentSkillsLocations` nas User Settings)_
8. **Criar/migrar Skills** — uma pasta por domínio com as 3 camadas.
9. **Criar toolsets** — um arquivo por domínio agrupando as ferramentas MCP usadas.
10. **Validar** — `Developer: Reload Window` → confirmar zero warnings; fazer commit de teste para validar o hook.

---

## Checklist de Entrega

- [ ] `.code-workspace` com pasta raiz exposta e todas as settings aplicadas (zero warnings)
- [ ] Template de commit `.gitmessage` criado e `commit.template` configurado
- [ ] Hook `commit-msg` validando Conventional Commits pt-BR
- [ ] Hook `pre-commit` com lint-staged
- [ ] `.editorconfig` e `prettier.config.js` presentes
- [ ] `copilot-instructions.md` criado
- [ ] Pelo menos uma instruction com `applyTo`
- [ ] Pelo menos uma skill com as 3 camadas
- [ ] Tasks `Dev All` e `Lint All` funcionando
- [ ] MCPs configurados nas User Settings (não no `.code-workspace`)
- [ ] `.gitignore` cobre `.env`, `node_modules`, `dist`, logs
- [ ] Nenhuma credencial versionada

---

## Formato da Resposta do Agente

Ao concluir, reportar:

1. **O que foi feito** — lista dos arquivos criados/modificados
2. **O que foi ignorado** — etapas puladas e motivo (já existia e estava correto)
3. **Validação executada** — resultado de lint/build/reload
4. **Próximos passos** — máx. 3 itens pendentes para o time
