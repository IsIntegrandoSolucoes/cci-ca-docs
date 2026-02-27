## Prompt para Implementação de Anotações RichText e Gravação de Áudio no Espaço de Aula - "Bloco de Anotações"

### Contexto Atual

O sistema já possui um espaço de aula funcional no portal do aluno (`EspacoAulaPage`) que exibe materiais didáticos e informações da aula. Os alunos acessam este espaço através de seus agendamentos confirmados. O portal admin já gerencia os espaços de aula através da gestão de agendamentos.

### Funcionalidades Solicitadas

**1. Campo RichText para Anotações (Estilo Notion)**

-    Implementar um editor de texto rico no espaço de aula onde o aluno pode escrever resumos e anotações sobre a aula
-    O editor deve permitir formatação básica como títulos, listas, negrito, itálico, links e blocos de código
-    As anotações devem ser salvas automaticamente enquanto o aluno digita
-    Persistir as anotações no banco de dados vinculadas ao agendamento específico do aluno **2. Sistema de Gravação de Áudio**
-    Adicionar funcionalidade de gravação de áudio diretamente no navegador usando Web Audio API
-    Interface similar ao WhatsApp: botão de gravação, indicador visual durante gravação, prévia antes de salvar
-    Integração com Supabase Storage para armazenar os arquivos de áudio
-    Organizar áudios por agendamento e aluno no storage
-    Controles para reproduzir, pausar e excluir gravações **3. Estrutura de Dados**
-    Criar tabela para armazenar anotações de texto (vinculada a agendamento + aluno)
-    Criar tabela para referenciar arquivos de áudio no storage (com metadados como duração, timestamp)
-    Implementar políticas RLS no Supabase para garantir que alunos só acessem suas próprias anotações **4. Interface no Portal do Aluno**
-    Adicionar seção de anotações abaixo dos materiais no espaço de aula
-    Layout responsivo com editor RichText ocupando área principal
-    Painel lateral ou inferior para controles de áudio
-    Listagem de gravações anteriores com player integrado
-    Estados de loading durante operações de salvamento e upload **5. Visualização no Portal Admin**
-    Criar nova seção no sistema administrativo para visualizar anotações e áudios dos alunos
-    Busca e filtros por aluno, data, disciplina ou professor
-    Interface read-only para administradores consultarem o conteúdo
-    Respeitar privacidade: acesso apenas para fins pedagógicos e administrativos necessários **6. Considerações Técnicas**
-    Usar biblioteca RichText compatível com React (como Draft.js, Slate.js ou TipTap)
-    Implementar debounce para salvamento automático das anotações
-    Limitar tamanho e duração dos áudios gravados
-    Compressão de áudio para otimizar storage
-    Estados de sincronização offline/online
-    Tratamento de erros e feedback visual apropriado **7. Experiência do Usuário**
-    Interface intuitiva que não interfira no estudo
-    Atalhos de teclado para formatação rápida
-    Indicadores visuais de status (salvando, salvo, erro)
-    Possibilidade de exportar anotações
-    Organização cronológica das gravações de áudio
