---
name: context-loaders
description: Guia de uso do LoadingContext (withLoading, setLoadingState, createLoadingHandler).
---

# Skill de LoadingContext

Esta skill orienta o uso do `LoadingContext` para controlar estados de carregamento por chave, incluindo wrappers assíncronos.

## 🎯 Quando usar

- Operações assíncronas que precisam de loading por ação.
- Estados de carregamento simultâneos por chave.

## 🧭 Passo a Passo

1. **Acesse o contexto**

```tsx
const loading = useLoadingContext();
```

2. **Marque loading manual**

```tsx
loading.setLoadingState('operacao', true);
loading.setLoadingState('operacao', false);
```

3. **Use o wrapper `withLoading`**

```tsx
await loading.withLoading('operacao', async () => {
     // operação assíncrona
});
```

4. **Use handler específico (quando disponível)**

```tsx
const handler = loading.createLoadingHandler('minha-operacao');
handler.setLoading(true);
const isLoading = handler.isLoading;
```

## ✅ Checklist

- A chave (`key`) é única e descritiva.
- Use `withLoading` para fluxos assíncronos.
- Evite estados globais de loading para ações locais.
