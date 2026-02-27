---
name: context-tema
description: Guia de uso do ThemeContext (useThemeContext, toggleTheme, paletas).
---

# Skill de ThemeContext

Esta skill orienta o uso do `ThemeContext` e a estrutura de temas em `src/themes`.

## 🎯 Quando usar

- Alternar tema claro/escuro.
- Consumir cores e tokens do tema em componentes.
- Adicionar novas paletas.

## 🧭 Passo a Passo

1. **Acesse o contexto**

```tsx
const { theme, toggleTheme } = useThemeContext();
```

2. **Use tokens do tema**

```tsx
<Box sx={{ backgroundColor: theme.palette.background.default }} />
```

3. **Troque o tema**

```tsx
toggleTheme();
```

4. **Adicione paletas**

- Crie arquivo em `palettes/`.
- Registre a nova paleta no provider.

## ✅ Checklist

- Use tokens do tema ao invés de valores fixos.
- Mantenha paletas centralizadas.
- Atualize `components/` para overrides quando necessário.
