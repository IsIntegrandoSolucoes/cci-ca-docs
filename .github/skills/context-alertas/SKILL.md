---
name: context-alertas
description: Guia de uso do AlertContext (setAlert e severidades).
---

# Skill de AlertContext

Esta skill orienta o uso do `AlertContext` para mensagens globais de sucesso, erro, info e warning.

## 🎯 Quando usar

- Feedback global de ações (ex: salvar, excluir, erro de API).

## 🧭 Passo a Passo

1. **Acesse o contexto**

```tsx
const { alert, setAlert } = useAlertContext();
```

2. **Dispare um alerta**

```tsx
setAlert({
     open: true,
     message: 'Operação realizada com sucesso',
     severity: 'success',
});
```

## ✅ Checklist

- Use `severity` adequado: `success`, `error`, `info`, `warning`.
- Mensagens curtas e claras.
- Evite múltiplos alerts concorrentes para a mesma ação.
