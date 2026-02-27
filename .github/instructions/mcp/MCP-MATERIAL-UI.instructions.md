# MCP (Model Context Protocol) - MUI Integration

## O que é o MCP do MUI?

O Model Context Protocol (MCP) do MUI é um protocolo que permite que assistentes de IA (como o GitHub Copilot) acessem documentação oficial e exemplos de código do Material-UI de forma confiável e atualizada.

> **Objetivo**: Quando for necessário sugerir ideias de layout, componentes ou boas práticas usando o **Material UI** (MUI), o Copilot deve buscar informações no **MUI MCP**.

### Como o Copilot deve agir
1. **Quando** houver solicitação de:
   - Sugestões de design de interface
   - Exemplos de componentes MUI
   - Boas práticas de uso do MUI
   - Atualizações ou recursos da versão atual do projeto
2. **Então** o Copilot deve:
   - Consultar o **MUI MCP**.
   - Garantir que os exemplos estejam **compatíveis com a versão** de MUI utilizada no projeto.
   - Utilizar **React com TypeScript** e **styled-components no MUI** (seguindo o padrão do projeto).

### Observações
- Evitar código com CSS separado — usar `sx` ou `styled` do MUI.
- Priorizar **componentes nativos do MUI** antes de sugerir bibliotecas externas.
- Explicar resumidamente as vantagens de cada abordagem sugerida.

## Configuração Realizada

### 1. Settings.json (Já configurado)

```json
"chat.mcp.enabled": true,
"chat.mcp.discovery.enabled": true
```

### 2. Arquivo MCP (.vscode/mcp.json)

```json
{
     "servers": {
          "supabase": {
               "command": "cmd",
               "args": ["/c", "npx", "-y", "@supabase/mcp-server-supabase@latest"],
               "env": {
                    "SUPABASE_ACCESS_TOKEN": "seu token"
               }
          },
          "mui-mcp": {
               "command": "npx",
               "args": ["-y", "@mui/mcp@latest"],
               "env": {}
          }
     }
}
```

## Como Usar o MCP do MUI com Copilot

### 1. Reinicie o VS Code

Após a configuração, reinicie o VS Code para que o MCP seja carregado.

### 2. Use o Chat do Copilot

Quando você fizer perguntas sobre MUI/Material-UI no chat do Copilot, ele agora terá acesso a:

-    **Documentação oficial atualizada**
-    **Exemplos de código reais**
-    **Links funcionais** (sem 404s)
-    **Citações diretas das fontes**

### 3. Exemplos de Perguntas que Funcionam Melhor

#### Componentes Específicos:

```
Como usar o DataGrid do MUI com paginação server-side?
```

#### Customização:

```
Como customizar o tema do DatePicker do MUI?
```

#### Integração:

```
Como integrar o TreeView do MUI com dados do Supabase?
```

#### Troubleshooting:

```
Por que meu DataGrid não está mostrando os dados corretamente?
```

