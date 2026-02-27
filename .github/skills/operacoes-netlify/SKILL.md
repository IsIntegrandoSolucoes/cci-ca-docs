---
name: operacoes-netlify
description: Comandos e instruções para interagir com a Netlify (Deploy, Logs, Builds, Functions) via MCP.
---

# Skill de Operações Netlify

Esta skill fornece acesso e instruções para gerenciar projetos AEMASUL na Netlify usando ferramentas MCP.

## 🛠️ Ferramentas Disponíveis

| Tool               | Função                                               |
| :----------------- | :--------------------------------------------------- |
| `list_sites`       | Lista sites disponíveis (admin-web, alunos-web, etc) |
| `get_deploy`       | Verifica status de um deploy específico              |
| `get_build_log`    | 🚨 Essencial para debugar falhas de build/deploy     |
| `list_env_vars`    | Verifica configurações de ambiente                   |
| `get_function_log` | Logs de execução de Serverless Functions             |


## 🧪 Casos de Uso Comuns

### Debugar Falha de Build

1.   Use `list_deploys` para pegar o ID do último deploy falho.
2.   Use `get_build_log` com esse ID para ler o erro.
3.   Analise o erro e sugira correção.

### Verificar Variáveis de Ambiente

- "Quais variáveis estão no `aemapi`?" -> Use `list_env_vars`.

### Monitorar Funções em Produção

- "Por que a função de boleto falhou?" -> Use `list_functions` para achar o nome e `get_function_log` para ver os erros.

## ⚠️ Atenção

- Não use essas ferramentas para configurações locais (`localhost`). Elas interagem com a **produção** ou **preview** na nuvem.
