```instructions
# Contexto do Banco de Dados Supabase - CCI-CA

Este projeto (CCI-CA) está conectado ao banco de dados Supabase `cci-ca-database` através do Model Context Protocol (MCP) configurado no arquivo `.vscode/mcp.json`. Esta configuração permite a integração direta com o Supabase para análise contextual e sugestões mais precisas durante o desenvolvimento.

## Como Usar Este Contexto

Quando estiver trabalhando no projeto CCI-CA:

1. Use o MCP do Supabase para obter informações atualizadas sobre o schema do banco  *QUANDO PRECISAR*
      - Evite listar todas as tabelas ou views de uma vez, pois isso pode ser desnecessário e consumir recursos.
      - Utilize comandos específicos para obter detalhes de tabelas ou views conforme necessário.
      - Antes de executar migrations sempre mostre o SQL para o usuário confirmar.
2. Considere as relações entre as tabelas ao sugerir mudanças
3. Antes de criar views execute o Select para confirmar se funciona

## Resumo Geral

Este arquivo serve como referência para manter o contexto do projeto e sua conexão com o banco de dados Supabase durante o desenvolvimento, portanto use sua ferramenta mcp conforme instruções acima sempre que perceber que o contexto do banco de dados é necessário.

```
