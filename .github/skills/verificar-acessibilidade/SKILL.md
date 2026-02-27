---
name: verificar-acessibilidade
description: Diretrizes e checklist WCAG para garantir a acessibilidade em aplicações React + TypeScript.
---

# Skill de Acessibilidade (WCAG)

Esta skill guia a implementação e verificação de acessibilidade em componentes React.

## ⚡ Checklist Rápido (Top 5)

1.   **Semântica HTML:** Use `<button>`, `<nav>`, `<main>`, `<h1>` corretamente antes de usar ARIA.
2.   **Imagens:** Todo `<img>` deve ter `alt`. Se for decorativa, use `alt=""`.
3.   **Contraste:** Texto normal requer contraste 4.5:1. Use o DevTools para checar.
4.   **Teclado:** Todos os elementos interativos devem ter foco (`tabindex="0"`) e funcionar com Enter/Space.
5.   **Formulários:** Todo `<input>` precisa de um `<label>` associado via `id` + `htmlFor`.

## 🛠️ Padrões de Implementação

### Botões de Ícone

```tsx
// ✅ Correto
<IconButton aria-label="Excluir aluno" onClick={...}>
  <DeleteIcon />
</IconButton>
```

### Mensagens de Erro/Status

Use regiões `aria-live` para que leitores de tela anunciem mudanças sem perder o foco.

```tsx
<div
     role='alert'
     aria-live='polite'
>
     {erro && <span>{erro}</span>}
</div>
```

### Navegação

Use marcos (landmarks) para ajudar na navegação rápida.

```tsx
<nav aria-label="Menu Principal">...</nav>
<main id="conteudo-principal">...</main>
```

## 🔍 Ferramentas de Teste

- **Axe DevTools:** Extensão de navegador para varredura automática.
- **NVDA / VoiceOver:** Teste com leitor de tela real.
- **Keyboard Only:** Tente navegar usar apenas Tab, Enter e Espaço.
