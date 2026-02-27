# 🎣 Organização de Hooks - CCI-CA

**OBJETIVO**: Definir claramente onde e como organizar hooks no projeto.

## 📁 Estrutura de Hooks

### 🌐 Hooks Globais (`src/hooks/`)

**Contém apenas hooks reutilizáveis** em toda a aplicação, **SEM lógica de negócio específica**.

#### Hooks Disponíveis:

-    **`useDebounce`** - Controle de debounce para inputs
-    **`useDeviceDetect`** - Detecção de dispositivo móvel
-    **`useFileUpload`** - Upload de arquivos para o Supabase
-    **`useGetRoutePrefix`** - Gerenciamento de rotas baseado no tipo de usuário
-    **`usePageLoading`** - Loading de páginas

### 🎯 Hooks de Feature (`src/components/pages/[Feature]/`)

**Contém lógica de negócio específica** de uma feature e **devem ficar junto ao componente**.

#### Estrutura:

```
src/components/pages/Planos/
├── ListarPlanos/
│   ├── ListarPlanos.tsx
│   ├── ListarPlanosDataGrid.tsx
│   └── useListarPlanos.ts          # Hook específico
└── ManterPlano/
    ├── ManterPlano.tsx
    ├── ManterPlanoForm.tsx
    └── useManterPlano.ts            # Hook específico
```

## 🎯 Diretrizes de Uso

### ✅ Hook Global - Quando criar:

-    **Funcionalidade reutilizável** em múltiplos componentes
-    **Sem lógica de negócio** específica
-    **Utilitário genérico** (formatação, validação, etc.)
-    **Sem dependência** de entidades específicas

#### Exemplo de Hook Global:

```tsx
// src/hooks/useDebounce.ts
export function useDebounce<T>(value: T, delay: number): T {
     const [debouncedValue, setDebouncedValue] = useState<T>(value);

     useEffect(() => {
          const handler = setTimeout(() => {
               setDebouncedValue(value);
          }, delay);

          return () => clearTimeout(handler);
     }, [value, delay]);

     return debouncedValue;
}
```

### ✅ Hook de Feature - Quando criar:

-    **Lógica específica** de uma entidade/feature
-    **Estados complexos** relacionados ao CRUD
-    **Integração com serviços** específicos
-    **Validações de negócio** específicas


## 🚨 Regras de Organização

### ❌ NUNCA faça:

1. **Hook global com lógica específica** de entidade
2. **Hook de feature em `src/hooks/`**
3. **Import de hook de feature** em outras features
4. **Hooks sem documentação** adequada
5. **Duplicação de funcionalidades** entre hooks

### ✅ SEMPRE faça:

1. **Verifique hooks globais** antes de criar novo
2. **Mantenha hooks de feature** junto aos componentes
3. **Use nomenclatura consistente** (`use[Nome]`)
4. **Documente com JSDoc** todos os hooks
5. **Separe responsabilidades** claramente

## 📝 Template JSDoc para Hooks

### Hook Global:

```tsx
/**
 * @name useNomeHook
 * @description Breve descrição da funcionalidade
 * @author Gabriel M. Guimarães | gabrielmg7
 * @package hooks/useNomeHook
 * @example
 * const { valor, loading } = useNomeHook(parametro);
 */
```

### Hook de Feature:

```tsx
/**
 * @name useManterEntidade
 * @description Hook para gerenciar estado e lógica de manutenção de entidades
 * @author Gabriel M. Guimarães | gabrielmg7
 * @package pages/Entidades/ManterEntidade/useManterEntidade
 * @returns {Object} Props para o componente de formulário
 */
```

## 🔄 Fluxo de Decisão

```
Preciso criar um hook?
     ↓
É reutilizável em múltiplas features?
     ↓ SIM                    ↓ NÃO
Hook Global              Hook de Feature
(src/hooks/)            (junto ao componente)
     ↓                         ↓
Verificar se já existe    Criar na pasta da feature
```

