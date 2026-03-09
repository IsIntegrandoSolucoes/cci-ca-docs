### 1. Pré-requisitos

| Ferramenta           | Versão                                               |
| -------------------- | ---------------------------------------------------- |
| **Node.js**          | v24+ (recomendado v24.11.0 LTS)                      |
| **npm**              | v10+                                                 |
| **Git**              | Qualquer versão recente                              |
| **Netlify CLI**      | `npm install -g netlify-cli`                         |
| **VS Code Insiders** | Versão 1.109+ (para suporte a Agent Skills/Toolsets) |

---

### 2. Clonar Repositórios

Criar uma pasta raiz (ex: `Workspace - CCI - Consultório de Aprendizagem`) e clonar os 5 repos dentro dela:

```powershell
mkdir "Workspace - CCI - Consultório de Aprendizagem"
cd "Workspace - CCI - Consultório de Aprendizagem"

git clone https://github.com/IsIntegrandoSolucoes/cci-ca-docs.git
git clone https://github.com/gabrielmg7/cci-ca-admin.git
git clone https://github.com/gabrielmg7/cci-ca-aluno.git
git clone https://github.com/gabrielmg7/cci-ca-api.git
git clone https://github.com/gabrielmg7/cci-ca-declaracoes-api.git
```

---

### 3. Criar arquivos de configuração do Workspace Raiz

Na pasta raiz, criar 3 arquivos:

**`Consultório de Aprendizagem.code-workspace`** — copiar do repositório ou usar o conteúdo do workspace file existente (contém as 6 pastas: root, docs, admin, aluno, api, declaracoes-api, mais settings, tasks e extensões).

**package.json**:

```json
{
  "name": "cci-ca-monorepo",
  "private": true,
  "description": "Workspace Root para CCI-CA",
  "scripts": {
    "prepare": "husky"
  },
  "devDependencies": {
    "husky": "^9.1.5",
    "lint-staged": "^15.2.10",
    "prettier": "^3.3.3"
  },
  "lint-staged": {
    "**/*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
    "**/*.{json,md,yml,yaml}": ["prettier --write"]
  }
}
```

**prettier.config.js**:

```javascript
export default {
  semi: false,
  singleQuote: true,
  trailingComma: 'es5',
  printWidth: 100,
  tabWidth: 2,
}
```

---

### 4. Instalar Dependências

```powershell
# Raiz (husky + prettier + lint-staged)
npm install

# Cada subprojeto
cd cci-ca-admin;   npm install; cd ..
cd cci-ca-aluno;   npm install; cd ..
cd cci-ca-api;     npm install; cd ..
cd cci-ca-declaracoes-api; npm install; cd ..
```

---

### 5. Configurar Variáveis de Ambiente

#### **.env**

```env
VITE_DATABASE_API_URL=<supabase-url-do-projeto-cci-ca>
VITE_DATABASE_API_SERVICE_KEY=<supabase-service-role-key>
VITE_DATABASE_COBRANCA_API_URL=<supabase-url-do-projeto-cobranca>
VITE_DATABASE_COBRANCA_API_ANON_KEY=<supabase-anon-key-cobranca>
VITE_DATABASE_COBRANCA_API_ROLE_KEY=<supabase-service-role-key-cobranca>
VITE_COBRANCA_API_PROD_URL=<url-da-api-de-cobranca>
```

#### **.env**

```env
VITE_SUPABASE_URL=<supabase-url-do-projeto-cci-ca>
VITE_SUPABASE_ANON_KEY=<supabase-anon-key>
VITE_SUPABASE_PROJECT_ID=<supabase-project-id>
VITE_API_ADMIN_TOKEN=<token-de-admin-da-api>
VITE_CCI_CA_API_URL=<url-da-cci-ca-api, ex: http://localhost:3002 ou produção>
```

#### **.env**

```env
PORT=3002
SUPABASE_URL=<supabase-url-do-projeto-cci-ca>
SUPABASE_SERVICE_ROLE_KEY=<supabase-service-role-key>
SUPABASE_KEY=<supabase-anon-key-fallback>
API_ADMIN_TOKEN=<token-admin>
COBRANCA_API_URL=<url-api-cobranca>
BB_PAY_CONVENIO=<numero-convenio-bbpay>
BASE_URL_PROD=<url-producao>
BASE_URL_DEV=http://localhost:3002
SISTEMA_ORIGEM_ID=7
BUNNY_PULL_ZONE_URL=<bunny-pull-zone>
BUNNY_STORAGE_ZONE=<bunny-storage-zone>
BUNNY_STORAGE_API_KEY=<bunny-storage-key>
BUNNY_STREAM_API_KEY=<bunny-stream-key>
BUNNY_STREAM_LIBRARY_ID=<bunny-library-id>
```

#### **.env**

```env
SUPABASE_URL=<supabase-url-do-projeto-cci-ca>
SUPABASE_SERVICE_KEY=<supabase-service-role-key>
```

---

### 6. Portas dos Servidores de Desenvolvimento

| Projeto                    | Porta  | Comando                                       |
| -------------------------- | ------ | --------------------------------------------- |
| **cci-ca-admin**           | `3000` | `npm run dev` (Vite)                          |
| **cci-ca-aluno**           | `3001` | `npm run dev` (Vite, com proxy `/api` → 3002) |
| **cci-ca-api**             | `3002` | `npm run dev` (nodemon + ts-node)             |
| **cci-ca-declaracoes-api** | `3003` | `npm run dev` (netlify dev)                   |

O workspace tem uma task `🚀 Dev: All` que inicia todos em paralelo.

---

### 7. Extensões VS Code Recomendadas

Instalar as extensões necessárias para o Copilot com Agent Skills:

- **GitHub Copilot** + **GitHub Copilot Chat**
- **vscode-styled-components** (para autocomplete em styled-components)
- **ESLint**
- **Prettier - Code formatter**
- **EditorConfig for VS Code**

---

### 8. Configurar Git

```powershell
git config --global commit.template .gitmessage
git config --global core.autocrlf input
```

O projeto usa **Husky** para git hooks (lint-staged no pre-commit). Após `npm install` na raiz e em cada subprojeto, o hook é configurado automaticamente via `prepare`.

---

### 9. Abrir o Workspace

```powershell
code-insiders "Consultório de Aprendizagem.code-workspace"
```

---

### 10. Verificar Setup

```powershell
# Em cada subprojeto, rodar lint para validar:
cd cci-ca-admin; npm run lint
cd cci-ca-aluno; npm run lint
cd cci-ca-api;   npm run lint
cd cci-ca-declaracoes-api; npm run lint
```

Ou usar a task do workspace: **🔍 Lint: All**

---

### Resumo de URLs dos Repositórios

| Projeto                    | URL                                                      |
| -------------------------- | -------------------------------------------------------- |
| **cci-ca-docs**            | https://github.com/IsIntegrandoSolucoes/cci-ca-docs.git  |
| **cci-ca-admin**           | https://github.com/gabrielmg7/cci-ca-admin.git           |
| **cci-ca-aluno**           | https://github.com/gabrielmg7/cci-ca-aluno.git           |
| **cci-ca-api**             | https://github.com/gabrielmg7/cci-ca-api.git             |
| **cci-ca-declaracoes-api** | https://github.com/gabrielmg7/cci-ca-declaracoes-api.git |

### Stack Tecnológica

| Camada              | Tecnologia                                                   |
| ------------------- | ------------------------------------------------------------ |
| **Frontend Admin**  | React 18 + Vite 5 + MUI 5 + styled-components 6 + TypeScript |
| **Frontend Aluno**  | React 19 + Vite 7 + MUI 6 + styled-components 6 + TypeScript |
| **API Principal**   | Express 4 + TypeScript + Serverless (Netlify Functions)      |
| **API Declarações** | Netlify Functions + pdf-lib + TypeScript                     |
| **Banco de Dados**  | Supabase (PostgreSQL)                                        |
| **Deploy**          | Netlify (todos os projetos)                                  |
| **Armazenamento**   | Bunny.net (Storage + Stream/LMS)                             |
| **Pagamentos**      | BB Pay (via API de Cobrança externa)                         |
