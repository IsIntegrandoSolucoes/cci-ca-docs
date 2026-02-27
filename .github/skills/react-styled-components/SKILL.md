---
name: react-styled-components
description: 'Otimiza performance e padrões de CSS-in-JS para projetos que usam styled-components (attrs, theme, memoização). Ativa-se ao editar arquivos com styled-components.'
metadata:
     owner: '@frontend'
     version: '1.0.0'
     activation: 'on-save: src/**/*.{ts,tsx}'
     scope: 'styled-components performance'
     status: 'active'
---

# Desempenho — Styled Components

**Descrição**: Otimiza performance e padrões de CSS-in-JS com styled-components

**Ativação**: Automática ao editar arquivos com styled-components

## 🎯 Otimizações Automáticas

### Padrões de Performance

- ✅ **attrs()**: Para props usadas frequentemente
- ✅ **CSS prop**: Para estilização condicional simples
- ✅ **Theme consistency**: Uso do ThemeProvider global
- ✅ **Memoização**: Componentes estilizados caros

### Anti-padrões Detectados

- ❌ Props inline que causam re-renders
- ❌ Styled components criados dentro de componentes
- ❌ Uso de funções complexas em template literals
- ❌ Estilos inline misturados com styled-components

## 🛠️ Verificações Automáticas

### Uso Otimizado do attrs()

```typescript
// ❌ Detectado: Props repetitivas
const Button = styled.button<{ variant: 'primary' | 'secondary' }>`
     background: ${(props) => (props.variant === 'primary' ? 'blue' : 'gray')};
     padding: ${(props) => (props.variant === 'primary' ? '12px' : '8px')};
`;

// ✅ Sugerido: Use attrs para otimizar
const Button = styled.button.attrs<{ variant: 'primary' | 'secondary' }>(({ variant }) => ({
     'data-variant': variant,
}))<{ variant: 'primary' | 'secondary' }>`
     background: ${({ theme, variant }) => theme.colors[variant]};
     padding: ${({ theme, variant }) => theme.spacing[variant]};
`;
```

### Integração com Tema

```typescript
// ❌ Detectado: Valores hardcoded
const Card = styled.div`
     background: #ffffff;
     border: 1px solid #e0e0e0;
     border-radius: 8px;
     padding: 16px;
`;

// ✅ Sugerido: Uso do tema
const Card = styled.div`
     background: ${({ theme }) => theme.colors.background.paper};
     border: 1px solid ${({ theme }) => theme.colors.border.light};
     border-radius: ${({ theme }) => theme.spacing.borderRadius.md};
     padding: ${({ theme }) => theme.spacing.padding.md};
`;
```

## 📋 Convenções de Nomenclatura

### Styled Components

```typescript
// ✅ Padrão: [Entity]Styled[Component]
const UserProfileStyledCard = styled.div``;
const ProductStyledButton = styled.button``;
const NavigationStyledList = styled.ul``;
```

### Organização em Arquivos

```typescript
// ✅ Estrutura recomendada
src/components/UserProfile/
├── UserProfile.tsx                    // Componente principal
├── UserProfileForm.tsx               // Form component
├── UserProfile.styles.ts             // Styled components
└── useUserProfile.ts                 // Hook de lógica
```

## ⚡ Otimizações de Performance

### Memoização de Componentes

```typescript
// Skill detecta componentes caros e sugere:
const ExpensiveStyledComponent = memo(styled.div<{ complexProp: any }>`
     /* estilos complexos que dependem de cálculos */
     transform: ${({ complexProp }) => calculateTransform(complexProp)};
`);
```

### CSS Prop para Casos Simples

```typescript
// ❌ Detectado: Styled component para algo simples
const SimpleWrapper = styled.div<{ isVisible: boolean }>`
  display: ${props => props.isVisible ? 'block' : 'none'};
`;

// ✅ Sugerido: CSS prop
<div css={css`display: ${isVisible ? 'block' : 'none'};`}>
  {children}
</div>
```

## 🎨 Theme System

### Validação de Tema

```typescript
// Skill verifica se propriedades do tema existem
const Component = styled.div`
     color: ${({ theme }) => theme.colors.nonExistent}; // ❌ Alerta
     background: ${({ theme }) => theme.colors.primary}; // ✅ Válido
`;
```

### Integração com TypeScript

```typescript
// Skill gera/valida interfaces de tema
interface ThemeType {
     colors: {
          primary: string;
          secondary: string;
          background: {
               paper: string;
               default: string;
          };
     };
     spacing: {
          xs: string;
          sm: string;
          md: string;
          lg: string;
     };
}
```

## 🔧 Development Tools

### Debugging Enhancement

```typescript
// Skill sugere styled-components/macro para melhor debugging
import styled from 'styled-components/macro';

// Nomes de classe mais legíveis em desenvolvimento
const Button = styled.button`
     /* UserProfile__Button-sc-123abc */
`;
```

### Otimização do Hot Reload

```typescript
// Evita recriação desnecessária de styled components
const useStyledComponents = () => {
     return useMemo(
          () => ({
               StyledButton: styled.button`
                    /* estilos */
               `,
               StyledCard: styled.div`
                    /* estilos */
               `,
          }),
          [],
     );
};
```

## 📱 Responsive Patterns

### Abordagem Mobile-First

```typescript
// Skill sugere padrões responsivos
const ResponsiveGrid = styled.div`
     display: grid;
     grid-template-columns: 1fr;
     gap: ${({ theme }) => theme.spacing.sm};

     ${({ theme }) => theme.breakpoints.up('md')} {
          grid-template-columns: repeat(2, 1fr);
          gap: ${({ theme }) => theme.spacing.md};
     }

     ${({ theme }) => theme.breakpoints.up('lg')} {
          grid-template-columns: repeat(3, 1fr);
          gap: ${({ theme }) => theme.spacing.lg};
     }
`;
```

## 🚫 Anti-padrões Evitados

### Criação Dinâmica

```typescript
// ❌ Detectado: Styled component criado no render
function Component() {
  const DynamicStyled = styled.div`
    color: ${props.color}; // Recriado a cada render
  `;

  return <DynamicStyled />;
}

// ✅ Sugerido: Componente estático com props
const StaticStyled = styled.div<{ color: string }>`
  color: ${props => props.color};
`;
```

## When NOT to use

- Não usar para regras de design que precisam de aprovação do time de UX (abranger com owner antes de aplicar correções automáticas).
- Não aplicar automaticamente em componentes simples que não exigem styled-components (usar CSS prop em casos simples).

## Manual verification steps

1. Verificar se styled components não são gerados dentro de funções/componentes que causem re-criação a cada render.
2. Validar uso do tema e propriedades no `ThemeProvider`.
3. Rodar testes visuais (quando disponíveis) e performance de renderização.

---

**Baseado em**: `REACT_STYLED_COMPONENTS.instructions.md`
