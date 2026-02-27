
- LEIA COM CUIDADO o guia de conciliação bancária, pois existem detalhes importantes
- Se precisar, use os servidores MCP que estão rodando para ter mais contexto.
   - ref-tools
   - mui-mcp
   - supabase-mcp

este projeto precisa de ajustes:

o cci-ca-admin precisa de uma tela para controlar a divisão de lucros do objeto repasse.recebedores.

precisamos dessa configuração de forma especifica por modalidade:

- GUIA_CONCILIACAO_BANCARIA.instructions.md possui algumas informações relevantes.

- o objeto repasse.recebedores deve ser configurado por modalidade (aulas particulares, aulas em grupo, cursos pré-prova, contratos mensais, turmas vestibular, turmas mentoria).

- Verifique o cci-ca-api para ver como está a situação atual do projeto neste contexto.

- o cci-ca-admin deve permitir que o admin configure os recebedores e suas porcentagens por modalidade.
- o cci-ca-admin deve permitir que o admin veja um resumo dos repasses feitos por modalidade, com filtros por data, modalidade, professor, etc.
- o cci-ca-admin deve permitir que o admin edite os recebedores e suas porcentagens, mas deve manter um histórico de mudanças para auditoria.
- o cci-ca-admin deve validar que a soma das porcentagens dos recebedores para cada modalidade seja exatamente 100%.
- o cci-ca-admin deve permitir que o admin veja um relatório detalhado dos repasses feitos, incluindo datas, valores, modalidades e recebedores.
- o cci-ca-admin deve permitir que o admin exporte os relatórios de repasses em formatos como CSV ou PDF.
- o cci-ca-admin deve ter uma seção de ajuda ou FAQ para auxiliar o admin na configuração e uso do sistema de repasses.
- o cci-ca-admin deve ter uma interface amigável e intuitiva para facilitar a configuração e o monitoramento dos repasses.
- o cci-ca-admin deve ter permissões de acesso adequadas para garantir que apenas usuários autorizados possam configurar e visualizar os repasses. O usuário deve ser do tipo pessoas.fk_id_tipo_pessoa = 8.

- se a resposta estiver muito longa, divida em partes, para que eu possa ir autorizando a continuação...
