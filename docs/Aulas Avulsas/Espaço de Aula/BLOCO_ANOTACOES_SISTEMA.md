# 📝 Sistema de Anotações e Gravações - "Bloco de Anotações"

## Visão Geral

O Sistema de Anotações permite que os alunos façam anotações em texto rico (RichText) e gravem áudios durante as aulas no espaço educacional. Os administradores podem visualizar essas anotações e gravações para fins pedagógicos.

## Funcionalidades Implementadas

### 🎯 Para Alunos (Portal do Aluno)

#### 📄 Editor RichText

-    **Formatação completa**: Negrito, itálico, listas, títulos, citações, códigos
-    **Funcionalidades avançadas**: Links, tabelas, blocos de código com destaque
-    **Salvamento automático**: Anotações são salvas automaticamente a cada 2 segundos
-    **Sincronização**: Indicadores visuais de status (salvando, salvo, erro)
-    **Atalhos de teclado**: Comandos rápidos para formatação

#### 🎙️ Gravação de Áudio

-    **Interface intuitiva**: Botão central de gravação similar ao WhatsApp
-    **Visualização em tempo real**: Barras de áudio animadas durante gravação
-    **Controles avançados**: Play, pause, stop, excluir
-    **Metadados**: Título, descrição, duração, tamanho do arquivo
-    **Limitações configuráveis**: Máximo 5 minutos e 10MB por gravação
-    **Preview antes de salvar**: Permite testar a gravação antes de confirmar

#### 💾 Gerenciamento de Dados

-    **Privacidade garantida**: Apenas o próprio aluno vê suas anotações e áudios
-    **Organização por aula**: Cada agendamento tem seu próprio bloco de anotações
-    **Histórico completo**: Lista de todas as gravações anteriores
-    **Backup offline**: Suporte para trabalhar offline com sincronização posterior

### 👨‍💼 Para Administradores (Portal Admin)

#### 📊 Dashboard de Anotações

-    **Estatísticas em tempo real**: Total de anotações, áudios, usuários ativos
-    **Filtros avançados**: Por data, professor, disciplina, aluno, texto
-    **Visualização organizada**: Tabs separadas para anotações e áudios
-    **Busca inteligente**: Pesquisa no conteúdo das anotações e metadados dos áudios

#### 🔍 Visualização Detalhada

-    **Anotações completas**: Visualização do conteúdo formatado
-    **Player de áudio integrado**: Reprodução direta no navegador
-    **Contexto educacional**: Informações sobre aula, professor, disciplina
-    **Interface read-only**: Visualização respeitando a privacidade dos alunos

## Estrutura Técnica

### 🗄️ Banco de Dados

#### Tabela `anotacoes_aula`

```sql
- id (PRIMARY KEY)
- fk_id_agendamento_professor (FOREIGN KEY)
- fk_id_usuario (FOREIGN KEY)
- conteudo_anotacao (TEXT)
- formato_conteudo (VARCHAR) - richtext, markdown, plain
- versao_editor (VARCHAR)
- ultima_edicao (TIMESTAMPTZ)
- sincronizado (BOOLEAN)
- backup_local (TEXT)
- data_criacao/atualizacao (TIMESTAMPTZ)
- criado_por/atualizado_por (FOREIGN KEY)
```

#### Tabela `audio_aula`

```sql
- id (PRIMARY KEY)
- fk_id_agendamento_professor (FOREIGN KEY)
- fk_id_usuario (FOREIGN KEY)
- nome_arquivo, caminho_storage (VARCHAR/TEXT)
- bucket_name (VARCHAR)
- tamanho_bytes, duracao_segundos (NUMERIC)
- formato_audio (VARCHAR) - webm, mp3, wav, ogg
- qualidade_audio, taxa_amostragem (VARCHAR/INTEGER)
- titulo, descricao, transcricao (VARCHAR/TEXT)
- status_upload (VARCHAR) - pending, uploading, completed, failed
- progresso_upload (INTEGER)
- data_criacao/atualizacao (TIMESTAMPTZ)
```

### 🔒 Segurança e Privacidade

#### Row Level Security (RLS)

-    **Anotações**: Usuários só acessam suas próprias anotações
-    **Áudios**: Usuários só acessam seus próprios áudios
-    **Administradores**: Acesso read-only para fins pedagógicos
-    **Políticas granulares**: Controle específico por tipo de operação

#### Armazenamento Seguro

-    **Supabase Storage**: Arquivos de áudio armazenados com segurança
-    **Bucket dedicado**: `audio-anotacoes` com políticas específicas
-    **URLs temporárias**: Links de acesso com expiração automática

### 🛠️ APIs e Endpoints

#### Endpoints Principais

```
GET /api/anotacoes - Busca anotações com filtros
GET /api/anotacoes/audios - Busca áudios com filtros
GET /api/anotacoes/estatisticas - Estatísticas gerais
GET /api/anotacoes/opcoes-filter - Opções para filtros
GET /api/anotacoes/audios/:id/url - URL pública do áudio
PUT /api/anotacoes/audios/:id - Atualiza metadados do áudio
```

#### Parâmetros de Filtro

-    `page`, `pageSize` - Paginação
-    `dataInicio`, `dataFim` - Filtro por período
-    `professorId`, `disciplinaId`, `alunoId` - Filtros por entidade
-    `buscarTexto` - Busca textual no conteúdo

## Como Usar

### 👨‍🎓 Para Alunos

1. **Acesse o Espaço de Aula**:

     - Entre em um agendamento confirmado
     - Role até a seção "Bloco de Anotações"

2. **Faça Anotações**:

     - Use o editor RichText na aba "Anotações de Texto"
     - Digite normalmente - o salvamento é automático
     - Use a barra de ferramentas para formatação

3. **Grave Áudios**:
     - Clique na aba "Gravações de Áudio"
     - Permita acesso ao microfone quando solicitado
     - Clique no botão central para iniciar gravação
     - Clique novamente para parar
     - Adicione título e descrição antes de salvar

### 👨‍💼 Para Administradores

1. **Acesse o Dashboard**:

     - Vá para "Anotações e Áudios dos Alunos" no menu admin
     - Visualize as estatísticas gerais no topo

2. **Use os Filtros**:

     - Abra a seção "Filtros de Busca"
     - Escolha período, professor, disciplina ou aluno
     - Digite texto para busca específica

3. **Visualize o Conteúdo**:
     - Alterne entre as abas "Anotações" e "Áudios"
     - Clique no ícone de visualização para ver detalhes
     - Use o player integrado para reproduzir áudios

## Dependências Técnicas

### Portal do Aluno

```json
{
     "@tiptap/react": "Editor RichText",
     "@tiptap/starter-kit": "Funcionalidades básicas",
     "@tiptap/extension-link": "Suporte a links",
     "@tiptap/extension-table": "Tabelas",
     "recordrtc": "Gravação de áudio",
     "lowlight": "Destaque de código"
}
```

### Portal Admin

```json
{
     "@mui/x-date-pickers": "Seletores de data",
     "@mui/material": "Componentes de UI",
     "date-fns": "Manipulação de datas"
}
```

### API

```json
{
     "@supabase/supabase-js": "Cliente Supabase",
     "express": "Framework web",
     "cors": "CORS middleware"
}
```

## Considerações de Performance

### 🚀 Otimizações Implementadas

1. **Debounce no Salvamento**: Evita requests excessivos durante digitação
2. **Paginação**: Carregamento incremental de dados
3. **Índices de Banco**: Otimização para consultas frequentes
4. **Compressão de Áudio**: Formato WebM para menor tamanho
5. **Cache de URLs**: Reutilização de links de áudio gerados

### 📊 Limites e Restrições

-    **Duração máxima do áudio**: 5 minutos (300 segundos)
-    **Tamanho máximo do arquivo**: 10MB
-    **Formatos suportados**: WebM, MP3, WAV, OGG
-    **Sincronização automática**: A cada 2 segundos
-    **Retenção de dados**: Conforme política de privacidade

## Monitoramento e Logs

### 📈 Métricas Disponíveis

-    Total de anotações criadas
-    Total de áudios gravados
-    Anotações criadas nos últimos 7 dias
-    Áudios gravados nos últimos 7 dias
-    Usuários ativos nos últimos 30 dias

### 🔍 Logs de Sistema

-    Criação e edição de anotações
-    Upload e processamento de áudios
-    Acessos ao sistema de visualização admin
-    Erros de sincronização e upload

## Roadmap Futuro

### 🚧 Melhorias Planejadas

1. **Transcrição Automática**: IA para converter áudio em texto
2. **Exportação de Dados**: PDF, Word, Excel das anotações
3. **Colaboração**: Compartilhamento entre alunos da mesma turma
4. **Busca Avançada**: Filtros por tipo de conteúdo e tags
5. **Mobile App**: Aplicativo nativo para iOS e Android
6. **Integração com IA**: Resumos automáticos e sugestões
7. **Analytics Avançados**: Relatórios de engajamento e uso

### 🔧 Melhorias Técnicas

1. **PWA**: Funcionalidade offline completa
2. **WebRTC**: Gravação de áudio de alta qualidade
3. **CDN**: Distribuição global dos arquivos de áudio
4. **Backup Automático**: Sincronização com múltiplos storages
5. **Versionamento**: Histórico de mudanças nas anotações

## Suporte e Manutenção

### 🆘 Problemas Comuns

1. **Microfone não funciona**: Verificar permissões do navegador
2. **Salvamento falha**: Verificar conexão com internet
3. **Áudio não reproduz**: Verificar formato e tamanho do arquivo
4. **Sincronização lenta**: Verificar velocidade da conexão

### 🛠️ Manutenção Preventiva

-    Limpeza periódica de arquivos órfãos no storage
-    Monitoramento do uso de espaço em disco
-    Verificação da integridade dos dados
-    Atualizações de segurança regulares

---

**Desenvolvido com ❤️ para melhorar a experiência educacional dos alunos e facilitar o acompanhamento pedagógico dos professores.**
