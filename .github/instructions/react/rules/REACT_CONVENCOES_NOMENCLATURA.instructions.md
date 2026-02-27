## 🎯 Convenções de Nomenclatura

### Arquivos:

-    **Componentes**: `PascalCase.tsx`
-    **Hooks**: `use[Nome].ts`
-    **Serviços**: `[entidade]Service.ts`
-    **Tipos**: `I[Nome].ts`

### Estrutura de Features:

-    **Container**: `[Feature].tsx`
-    **Form**: `[Feature]Form.tsx`
-    **Hook**: `use[Feature].ts`
-    **DataGrid**: `[Feature]DataGrid.tsx`

## 🎣 Organização de Hooks

### Hooks Globais (`src/hooks/`)

-    **Funcionalidade**: Reutilizáveis em toda aplicação
-    **Escopo**: Sem lógica de negócio específica
-    **Exemplos**: `useDebounce`, `useDeviceDetect`, `useFormatValidation`

### Hooks de Feature (`src/components/pages/[Feature]/`)

-    **Funcionalidade**: Lógica específica de uma feature
-    **Escopo**: Estados e operações de uma entidade
-    **Exemplos**: `useManterEntidade`, `useListarEntidades`

### Organização por Feature

```
src/components/pages/
└── [Modulo]/                    # Ex: Financeiro, Pessoas, Planos
    ├── Listar[Entidades]/       # Ex: ListarPlanos/
    │   ├── Listar[Entidades].tsx            # Componente container
    │   ├── Listar[Entidades]DataGrid.tsx    # DataGrid com MUI
    │   ├── Listar[Entidades]ActionsCell.tsx # Ações da linha
    │   ├── Listar[Entidades]CustomToolbar.tsx # Toolbar customizada
    │   └── useListar[Entidades].ts          # Hook da listagem
    └── Manter[Entidade]/        # Ex: ManterPlano/
        ├── Manter[Entidade].tsx             # Componente container
        ├── Manter[Entidade]Form.tsx         # Formulário de apresentação
        ├── Manter[Entidade]Modal.tsx        # Modal alternativo
        └── useManter[Entidade].ts           # Hook do formulário
```

### Separação de Responsabilidades

**🎯 Arquitetura em 3 Camadas:**

```
[Feature].tsx (Container) → use[Feature].ts (Lógica) → [Feature]Form.tsx (UI)
```

1. **Container Component**: Instancia o hook e fornece layout
2. **Custom Hook**: Encapsula toda a lógica de negócio
3. **Form Component**: Recebe props e foca apenas na apresentação

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