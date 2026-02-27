````instructions
# GitHub Copilot Prompt

## Objetivo

Este projeto utiliza **TypeScript**, **React**, **MUI v5** e **Supabase**. O objetivo deste prompt é orientar o GitHub Copilot a seguir boas práticas de desenvolvimento, garantindo código limpo, seguro e eficiente.

## Regras Gerais

-    Utilize **TypeScript** para tipagem forte.
-    Prefira **Componentes Funcionais** sobre Classes.
-    Utilize **React Hooks** para gerenciamento de estado e efeitos colaterais.
-    Sempre use **ESLint e Prettier** para garantir qualidade de código.
-    **Não remova código existente que não foi solicitado.**
-    **As melhorias (alterações) devem otimizar e reduzir redundâncias sem afetar o funcionamento do código.**
-    **Verifique se funções utilitárias ou hooks já existem antes de criar novas implementações.**
-    Nunca utilizar zero para definir valores padrão de chaves primárias ou estrangeiras, sempre utilizar null ou undefined.

## Estrutura do Projeto

-    Siga a organização de arquivos existente:

     ```
     src/
     ├── assets/                                  # Imagens, fontes e ícones
     ├── auth/                                    # Autenticação e autorização
     ├── components/
     │   ├── buttons/                             # Componentes de botão
     │   ├── common/                              # Componentes reutilizáveis
     │   ├── layouts/                             # Componentes de layout
     │   ├── modals/                              # Componentes de modal reutilizáveis
     │   └── pages/                               # Componentes por funcionalidade
     ├── contexts/                                # Contextos React
     │   ├── AlertContext.tsx                     # Contexto de alertas/notificações
     │   ├── UserContext/                         # Contexto de controle de usuário logado
     │   │    └── UserContextType.ts              # Tipos do contexto de usuário
     │   │    └── UserContext.tsx                 # Contexto de controle de usuário logado
     │   │    └── useUserContext.tsx              # Hook para acessar o contexto de usuário
     ├── hooks/                                   # Hooks personalizados
     │   ├── useFormatValidation.tsx              # Formatação e validação de dados
     ├── routes/                                  # Rotas com react-router-dom
          ├── AppRoutes.tsx                       # Rotas principais do aplicativo
          ├── UserRoutes.tsx                      # Rotas específicas para usuários
          ├──  UnauthenticatedRoutes.tsx          # Rotas para usuários não autenticados
     ├── services/                                # Serviços de API's
     │   ├── supabase/                            # Serviços para integração com Supabase
     │   │   ├── tables/                          # Serviços para tabelas do banco de dados
     │   │   │    ├── [recurso]Service.ts         # Serviço para cada recurso
     │   │   ├── views/                           # Serviços para views do banco de dados
     │   │   │    ├── view[recurso]Service.ts     # Serviço para cada view
     ├── themes/                                  # Configurações de tema
     │   ├── ICustomTheme.ts                      # Interface para tema customizado
     │   ├── theme.d.ts                           # Tipos de tema
     │   ├── ThemeContext.tsx                     # Contexto de tema
     │   ├── ThemeOptions.tsx                     # Opções de tema (Dark/light mode)
     │   ├── ThemeProviderWrapper.tsx             # Wrapper para o ThemeProvider
     │   └── useThemeContext.tsx                  # Hook para acessar o contexto de tema
     ├── utils/                                   # Funções utilitárias
     └── types/                                   # Interfaces e tipos
          └── database/                           # Interfaces que representam as tabelas do banco de dados
               └── views/                         # Interfaces que representam as views do banco de dados
     ```

## Estrutura de arquivos

-    Use extensão `.tsx` para componentes React com TypeScript
-    Estruture os componentes seguindo a hierarquia do projeto:
     ```
     src/components/
     └── pages/              # Componentes específicos de páginas
         └── [Feature]/      # Agrupados por feature
             ├── [Feature].tsx            # Componente principal
             ├── [Feature]Form.tsx        # Formulários
             └── use[Feature].ts          # Hook específico da feature
     ```
-    Separe hooks personalizados em arquivos `use[Nome].ts` ou `use[Nome].tsx`
-    Mantenha interfaces e tipos na mesma pasta do componente, a menos que sejam compartilhados entre múltiplos componentes, aí teriam que ser movidos para a pasta `types`.

## Separação de Responsabilidades

A arquitetura segue um padrão de separação de responsabilidades que facilita a manutenção e escalabilidade:

```
src/
├── components/
│   └── pages/
│       └── [Módulo]/
│           └── [Recurso]/
│               ├── Listar[Recursos]/
│               │   ├── Listar[Recursos].tsx
│               │   ├── Listar[Recursos]DataGrid.tsx
│               │   ├── Listar[Recursos]ActionsCell.tsx
│               │   ├── Listar[Recursos]CustomToolbar.tsx
│               │   └── useListar[Recursos].ts
│               └── Manter[Recurso]/
│                   ├── Manter[Recurso].tsx
│                   ├── Manter[Recurso]Form.tsx
│                   └── useManter[Recurso].ts
├── types/
│   └── database/
│       ├── ITipo.ts (interface base)
│       └── I[Recurso].ts
├── services/
│   └── supabase/
│       └── tables/
│           └── [recurso]Service.ts
└── contexts/
    └── AlertContext.tsx
```

## Regras de Implementação para Hooks Locais (de Feature):

1. **Arquitetura de Três Camadas:**

     ```
     [Feature].tsx (Contenedor) → use[Feature].ts (Lógica) → [Feature]Form.tsx (Apresentação)
     ```

2. **Responsabilidades do Hook Local:**

     - **Estado:** Gerenciar todos os estados relacionados à feature
     - **Efeitos:** Carregar dados iniciais e configurar o ambiente
     - **Handlers:** Processar eventos de UI e chamadas à API
     - **Metadados:** Fornecer títulos, subtítulos e outras informações contextuais
     - **Validações:** Implementar regras de validação de formulários

3. **Integração com Contextos Globais:**

     - **AlertContext:** Use `setAlert` para notificações
     - **UserContext:** Use `userData` para informações do usuário logado no sistema
     - **ThemeContext:** Use `theme` para configuração visual do tema customizado

4. **Padrão de Formulários:**
     - Estado inicial vazio ou preenchido em caso de edição
     - Validação em tempo real ou no submit
     - Manipuladores individuais para cada campo (`handle[Campo]Change`) com createHandleChange
     - Método de submit único (`handleSubmit`)

## Utilitários Disponíveis

-    **Use os utilitários existentes ao invés de reimplementar a mesma funcionalidade:**

     1. `saudacao.ts` - Gera saudações personalizadas com base no gênero e horário:

          ```typescript
          import { saudacao } from '../utils/saudacao';

          // Uso: saudação simples por gênero ou com horário do dia
          const mensagem = saudacao(false); // Retorna apenas "Bem-vindo", "Bem-vinda", etc.
          const mensagemCompleta = saudacao(true); // Inclui "Bom dia", "Boa tarde", etc.
          ```

     2. `monthNames.ts` - Lista de nomes dos meses em português:

          ```typescript
          import { monthNames } from '../utils/monthNames';

          // Uso: obter nome do mês
          const nomeMes = monthNames[new Date().getMonth()];
          ```

     3. `getPrimeiroNome.ts` - Extrai o primeiro nome:

          ```typescript
          import { getPrimeiroNome } from '../utils/getPrimeiroNome';

          // Uso: extrair primeiro nome
          const primeiroNome = getPrimeiroNome(nomeCompleto);
          ```

     4. `exportUtils.ts` - Exportação para CSV e Excel:

          ```typescript
          import { exportCsv, exportXlsx } from '../utils/exportUtils';

          // Uso: exportar dados
          const handleExportCsv = () => exportCsv(dados, 'arquivo.csv');
          const handleExportExcel = () => exportXlsx(dados, 'arquivo.xlsx', 'Planilha1');
          ```

## JSDoc e Documentação

-    Inicie cada arquivo com um bloco JSDoc contendo:
     ```tsx
     /**
      * @name NomeDoComponente
      * @author Gabriel M. Guimarães | gabrielmg7
      * @description [Breve descrição funcional]
      * @param {TipoProps} props - [Descrição]
      * @returns {JSX.Element} [Descrição do retorno]
      * @package [caminho/do/arquivo]
      */
     ```
     -    Para componentes importantes, crie um README.md contendo:
     -    Descrição do propósito
     -    Tabela de props com tipos e descrições
     -    Exemplo de uso com código

## TypeScript

-    Sempre defina tipos e evite `any`.
-    Utilize `interface` para props e modelos de dados.
-    Nomeie interfaces de props como `[ComponentName]Props`.
-    Defina estados com tipagem explícita:

```tsx
// Correto
const [area, setArea] = useState<IAreaClube>(initialAreaClube);
const [nome, setNome] = useState<string>('');
// Evite
const [data, setData] = useState(null);
```

## React e Hooks

-    Use hooks customizados (prefixo `use`) para encapsular lógica de negócio:

     ```tsx
     // Exemplo do projeto
     const useManterEntidade = () => {
          const { setAlert } = useAlertContext();

          // Estados e lógica...

          return {
               estados,
               handlers,
               metadados,
          };
     };
     ```

-    Separe componentes em:
     -    Componente Principal (contenedor): Instancia o hook
     -    Componente Filho: Recebe props do hook e renderiza a UI
-    Para componentes de formulário:
     -    Divida em componente contenedor e componente de formulário
     -    Mantenha a lógica no hook customizado
     -    Passe props do hook para o componente de formulário
-    Para hooks customizados:
     -    Use o prefixo `use` (ex: `useManterEntidade`)
     -    Retorne um objeto com estados e handlers
     -    Documente todas as propriedades retornadas

## Padrões de estado e comunicação

-    Use o padrão de hooks customizados para encapsular lógica de negócio
-    Sempre implemente tratamento de erros nos serviços
-    Utilize `useAlertContext` para feedback ao usuário
-    Siga o fluxo:
     ```
     Componente Principal → Hook Personalizado → Componente de UI
     ```

## Estilo de código e UI

-    Utilize componentes do Material UI para interface
-    Para layouts responsivos, use o Grid do Material UI:
     ```tsx
     <Grid
          container
          direction={'column'}
          gap={2}
          padding={1}
     >
          {/* Conteúdo */}
     </Grid>
     ```
-    Siga o padrão de 5 espaços para indentação
-    Use camelCase para funções, variáveis e props
-    Use PascalCase para componentes e interfaces
-    Prefixe manipuladores de eventos com `handle` (ex: `handleSubmit`)
-    Para botões de ação, utilize os componentes padronizados:
     ```tsx
     <BackButton />
     <SaveButton
          type="submit"
          disabled={loading || !isFormValid}
     />
     ```

## Otimização de Desempenho

-    Utilize técnicas de memoização para evitar re-renderizações desnecessárias:

     ```tsx
     // Memoização de componentes
     const MeuComponente = memo(({ props }) => {
          // Renderização
     });

     // Memoização de valores computados
     const valorCalculado = useMemo(() => {
          // Cálculo complexo
          return resultado;
     }, [dependencias]);

     // Memoização de funções
     const handleClick = useCallback(() => {
          // Ação do handler
     }, [dependencias]);
     ```

-    Otimize efeitos colaterais:

     ```tsx
     // Carregamento eficiente de dados
     useEffect(() => {
          const fetchData = async () => {
               setLoading(true);
               try {
                    const [dados1, dados2] = await Promise.all([servico1.getDados(), servico2.getDados()]);

                    // Processamento...
               } catch (error) {
                    // Tratamento de erro...
               } finally {
                    setLoading(false);
               }
          };

          fetchData();
     }, [dependencias]); // Mantenha dependências mínimas
     ```

-    Evite atualizações de estado desnecessárias:

     ```tsx
     // Antes de atualizar o estado, verifique se houve mudança real
     if (JSON.stringify(estadoAtual) !== JSON.stringify(novoEstado)) {
          setEstado(novoEstado);
     }
     ```

-    Utilize `React.lazy()` para carregamento preguiçoso:

     ```tsx
     // Carregamento preguiçoso de componentes grandes
     const ComponenteGrande = React.lazy(() => import('./ComponenteGrande'));

     // Uso
     <Suspense fallback={<Loading />}>
          <ComponenteGrande />
     </Suspense>;
     ```

## Gerenciamento de Estado Global

-    **Quando usar Context API vs. Props Drilling:**

     -    Use Context para dados que precisam ser acessados por muitos componentes em diferentes níveis
     -    Mantenha dados de formulário localizados no hook da feature
     -    Divida contextos por domínio para evitar re-renderizações desnecessárias

-    **Padrão de Consumo de Contexto:**
-    Utilize os contextos existentes:

     ```tsx
     const { setAlert } = useAlert();
     const { userData } = useUserContext();
     const { theme } = useThemeContext();
     ```

## Formulários e Validação

-    Implemente validação de formulários:

     ```tsx
     // Validação básica
     const isValid = nome.trim() !== '' && descricao !== '';

     // Desabilite botões baseado na validação
     <SaveButton disabled={loading || !isValid} />;
     ```

-    Documente a finalidade e validações de cada campo.

## Componentes e Padrões de Implementação

### 1. Componentes de Listagem (DataGrid)

-    Use o padrão `useListar[Entidade]` para encapsular a lógica de listagem:

     ```tsx
     const useListarEntidade = () => {
          const [rows, setRows] = useState<Partial<IEntidade>[]>([]);
          const [totalRows, setTotalRows] = useState(0);
          const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
               page: 0,
               pageSize: 50,
          });
          const [sortModel, setSortModel] = useState<GridSortModel>([]);
          const [filterModel, setFilterModel] = useState<GridFilterModel>({ items: [] });

          return {
               rows,
               columns,
               totalRows,
               paginationModel,
               setPaginationModel,
               sortModel,
               setSortModel,
               filterModel,
               setFilterModel,
          };
     };
     ```

-    Separe a definição de colunas em um memo para evitar re-renderizações:
     ```tsx
     const columns: GridColDef[] = useMemo(
          () => [
               {
                    field: 'id',
                    headerName: 'ID',
                    minWidth: 100,
                    flex: 0.5,
               },
               // Outras colunas
          ],
          [dependências],
     );
     ```

### 2. Componentes de Formulário

-    Defina interfaces de props explicitamente e detalhe cada propriedade:

     ```tsx
     interface EntidadeFormProps {
          // Dados de formulário
          campo1: string;
          campo2: string;

          // Manipuladores de eventos
          handleCampo1Change: (e: React.ChangeEvent<HTMLInputElement>) => void;
          handleCampo2Change: (e: React.ChangeEvent<HTMLInputElement>) => void;
          handleSubmit: (e: React.FormEvent) => void;

          // Estados
          loading: boolean;

          // Metadados
          entidade: IEntidade;
          theme: Theme;
     }
     ```

-    Implemente campos de formulário com validação:
     ```tsx
     <TextField
          label='Campo obrigatório'
          value={value}
          onChange={handleChange}
          fullWidth
          required
          error={value.trim() === '' && touched}
          helperText={value.trim() === '' && touched ? 'Campo obrigatório' : ''}
          size='small'
     />
     ```

### 3. Componentes de Visualização/Dashboard

Para componentes que exibem dados complexos (relatórios, dashboards, visualizações):

```
VisualizacaoCompleta/
├── VisualizacaoCompleta.tsx        # Componente principal
├── useVisualizacao.ts              # Hook com lógica de dados
├── VisualizacaoHeader.tsx          # Filtros e exportação
├── VisualizacaoStats.tsx           # Estatísticas/KPIs
├── VisualizacaoChart.tsx           # Gráficos/charts
├── VisualizacaoTable.tsx           # Tabelas de dados
└── VisualizacaoCard.tsx            # Cards individuais
```

**Características:**
- Hook centraliza processamento de dados e filtros
- Componentes especializados para cada tipo de visualização
- Memoização para evitar recálculos desnecessários
- Export/import centralizado via `index.ts`

### 4. Componentes de Fluxo/Wizard

Para processos multi-etapas ou fluxos complexos:

```tsx
const useFluxoComplexo = () => {
     const [etapaAtual, setEtapaAtual] = useState(0);
     const [dadosFluxo, setDadosFluxo] = useState({});

     const proximaEtapa = useCallback(() => {
          setEtapaAtual(prev => prev + 1);
     }, []);

     return { etapaAtual, dadosFluxo, proximaEtapa };
};
```

6. ❌ **Componentes Monolíticos:**
     ```tsx
     // NÃO FAÇA ISSO - Componente com múltiplas responsabilidades
     const ComponenteGigante = () => {
          // 500+ linhas misturando UI, lógica, estado, APIs...
          return <div>{/* código complexo demais */}</div>;
     };
     ```

## Indicadores de Qualidade de Código

### ✅ Componente Bem Estruturado:
- Máximo 150 linhas por arquivo
- Responsabilidade única e clara
- Props tipadas com interfaces
- Hooks customizados para lógica complexa
- Memoização adequada (useMemo/useCallback)
- JSDoc documentado

### ⚠️ Componente Precisa de Refatoração:
- Mais de 300 linhas em um arquivo
- Múltiplas responsabilidades misturadas
- Estados locais complexos sem hook customizado
- Funções recriadas a cada renderização
- Lógica de negócio misturada com UI

### 🚨 Componente Problemático:
- Mais de 500 linhas
- Uso excessivo de `any`
- Estados não tipados
- Chamadas de API diretas no componente
- Ausência de memoização
- Código duplicado

### Como Refatorar
-    **Divida componentes grandes em menores**: Separe lógica de UI, estado e efeitos colaterais.
-    **Crie hooks customizados**: Encapsule lógica complexa em hooks reutilizáveis.
-    **Use memoização**: Aplique `useMemo` e `useCallback` para otimizar re-renderizações.
-    **Documente com JSDoc**: Adicione comentários explicativos para cada função e componente.
-    **Remova código duplicado**: Centralize lógica comum em utilitários ou hooks.
-   **Alterações Estruturais**: Refatorar componentes grandes devem ser alterações meramente estruturais, ou seja, não devem alterar o funcionamento do código, apenas melhorar a legibilidade e organização.

````
