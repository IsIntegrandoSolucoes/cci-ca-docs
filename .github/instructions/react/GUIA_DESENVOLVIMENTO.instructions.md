# 📖 Guia de Desenvolvimento - CCI-CA

## 🎯 Visão Geral

### Stack Tecnológico

-    **Frontend**: React 18 + TypeScript + Vite
-    **UI Framework**: Material-UI (MUI) v5
-    **Estado Global**: React Context API
-    **Backend**: Supabase (Auth + Database + Storage)
-    **Roteamento**: React Router DOM v7
-    **Autenticação**: Supabase Auth com JWT Claims
-    **Styling**: Emotion + Material-UI Theme System

## 🏗️ Estrutura de Pastas

```
src/
├── 🧩 components/               # Componentes React organizados por contexto
│   ├── common/                  # Componentes reutilizáveis
│   │   ├── dashboard/           # Sistema de dashboard padronizado
│   │   ├── alerts/              # Sistema de alertas
│   │   ├── buttons/             # Botões reutilizáveis
│   │   ├── cards/               # Cards padronizados
│   │   ├── fields/              # Campos de formulário customizados
│   │   ├── loaders/             # Componentes de loading
│   │   └── ...                  # Outros componentes comuns
│   ├── layouts/                 # Componentes de layout
│   │   ├── GridLayout/          # Layout principal em grid
│   │   ├── PageHeader/          # Cabeçalho de páginas
│   │   └── Sidebar/             # Menu lateral
│   └── pages/                   # Componentes específicos de páginas
│       ├── Acessos/             # Gestão de acessos e ingressos
│       ├── Areas/               # Áreas do clube
│       ├── Descontos/           # Sistema de descontos
│       ├── Financeiro/          # Módulo financeiro completo
│       ├── Pessoas/             # Gestão de pessoas (sócios, visitantes)
│       ├── Planos/              # Planos de associação
│       ├── Usuario/             # Perfil e configurações do usuário
│       └── [Feature]/           # Outras funcionalidades
├── 🔧 contexts/                 # Contextos React para estado global
│   ├── AlertContext/            # Alertas globais
│   ├── LoadingContext/          # Estados de carregamento
│   └── UserContext/             # Autenticação e dados do usuário
├──  hooks/                    # Hooks personalizados reutilizáveis
├──  routes/                   # Configuração de rotas por tipo de usuário
│   ├── AppRoutes.tsx            # Roteador principal
│   ├── ManagerRoutes.tsx        # Rotas para gestores/admins
│   ├── EmployeeRoutes.tsx       # Rotas para funcionários
│   └── UnauthenticatedRoutes.tsx # Rotas para não autenticados
├──  services/                 # Camada de serviços para API
│   ├── supabase/                # Integração com Supabase
│   │   ├── base/                # Classes base (BaseDataGridService)
│   │   ├── tables/              # Serviços para tabelas
│   │   ├── views/               # Serviços para views
│   │   └── functions/           # RPC functions
│   └── viaCEP/                  # Integração ViaCEP
├── 🎨 themes/                   # Sistema de temas customizável
├── 📄 types/                    # Interfaces e tipos TypeScript
│   ├── tables/                  # Interfaces para tabelas
│   └── views/                   # Interfaces para views
└── � utils/                    # Funções utilitárias
```

## 🔐 Sistema de Autenticação e Permissões

O CCI-CA implementa um sistema robusto de autenticação baseado em **Supabase Auth** com **JWT Claims** e **Row Level Security (RLS)**.

```

## 📋 Regras Gerais de Desenvolvimento

### Princípios Fundamentais

1. **🗄️ Metodologia Database-Driven**: SEMPRE analise o banco de dados antes de implementar qualquer funcionalidade
2. **🔧 TypeScript First**: Utilize tipagem forte em todos os componentes e funções
3. **⚛️ React Hooks**: Use hooks customizados para encapsular lógica de negócio
4. **🎨 Material-UI**: Siga o design system do MUI v5 para consistência visual
5. **🔐 Segurança**: Mantenha lógica crítica no banco de dados (PostgreSQL Functions)

### Convenções Obrigatórias

-    **Não remova código existente** que não foi solicitado
-    **Sempre verifique** se hooks ou utilitários já existem antes de criar novos
-    **Use `null` ou `undefined`** para chaves estrangeiras, nunca `0`
-    **Implemente JSDoc** em todos os componentes e funções
-    **Valide formulários** no submit com feedback específico (não desabilite botões)
-    **Use ESLint e Prettier** para manter qualidade de código

## TypeScript

-    Sempre defina tipos e evite `any`.
-    Utilize `interface` para props e modelos de dados.
-    Nomeie interfaces de props como `[ComponentName]Props`.
-    Defina estados com tipagem explícita:



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

# Otimização de Desempenho

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

## Fluxo de Dados:

```
                        ┌─────────────────────┐
                        │ Contextos Globais   │
                        │ (Alert, Loading...) │
                        └─────────┬───────────┘
                                  │
                                  ▼
┌────────────────┐      ┌─────────────────────┐      ┌────────────────┐
│  API Services  │◄────►│   Hook da Feature   │─────►│ Props          │
└────────────────┘      │  (use[Feature].ts)  │      └────────┬───────┘
                        └─────────────────────┘               │
                                  ▲                           │
                                  │                           ▼
                        ┌─────────┴───────────┐      ┌────────────────┐
                        │ Componente Principal│─────►│ Formulário     │
                        │  ([Feature].tsx)    │      │ ([Feature]Form)│
                        └─────────────────────┘      └────────────────┘
```

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

-    Hook centraliza processamento de dados e filtros
-    Componentes especializados para cada tipo de visualização
-    Memoização para evitar recálculos desnecessários
-    Export/import centralizado via `index.ts`

### 4. Componentes de Fluxo/Wizard

Para processos multi-etapas ou fluxos complexos:

```tsx
const useFluxoComplexo = () => {
     const [etapaAtual, setEtapaAtual] = useState(0);
     const [dadosFluxo, setDadosFluxo] = useState({});

     const proximaEtapa = useCallback(() => {
          setEtapaAtual((prev) => prev + 1);
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
