---
name: react-acessibilidade
description: 'Verifica conformidade WCAG (A/AA) e sugere correções automáticas para elementos semânticos, ARIA, contraste e navegação por teclado. Ativa-se ao salvar componentes React com elementos interativos.'
metadata:
     owner: '@a11y-team'
     version: '1.0.0'
     activation: 'on-save: src/**/*.tsx'
     scope: 'component accessibility checks'
     status: 'active'
---

# Acessibilidade — React

**Descrição**: Verifica conformidade WCAG e sugere melhorias de acessibilidade automaticamente

**Ativação**: Automática ao salvar componentes React com elementos interativos

## 🎯 Verificações Automáticas

### Elementos Semânticos

- ✅ **Headers**: Hierarquia correta (h1 → h2 → h3)
- ✅ **Landmarks**: `<main>`, `<nav>`, `<section>`, `<aside>`
- ✅ **Forms**: Labels associados com `htmlFor`/`id`
- ✅ **Buttons**: Uso correto vs `<div>` com `onClick`

### Atributos ARIA

- ✅ **aria-label**: Botões de ícone sem texto
- ✅ **aria-labelledby**: Associações complexas
- ✅ **aria-expanded**: Estados de dropdown/accordion
- ✅ **aria-current**: Página/item ativo
- ✅ **aria-live**: Atualizações dinâmicas
- ✅ **aria-hidden**: Elementos decorativos

### Navegação por Teclado

- ✅ **tabindex**: Uso correto (`0`, `-1`)
- ✅ **Focus trap**: Em modais e popups
- ✅ **Skip links**: Para navegação rápida
- ✅ **Ordem de foco**: Lógica e sequencial

## 🔍 Detecções Automáticas

### Problemas Críticos

```tsx
// ❌ Detectado: Botão sem rótulo
<button onClick={handleClick}>
  <Icon name="save" />
</button>

// ✅ Sugerido: Botão acessível
<button onClick={handleClick} aria-label="Salvar documento">
  <Icon name="save" />
</button>
```

### Contraste de Cores

```tsx
// ❌ Detectado: Contraste insuficiente
<Text color="#999" backgroundColor="#ccc">
  Texto difícil de ler
</Text>

// ✅ Sugerido: Contraste adequado (4.5:1)
<Text color="#333" backgroundColor="#fff">
  Texto legível
</Text>
```

### Imagens sem Alt

```tsx
// ❌ Detectado: Imagem sem texto alternativo
<img src="chart.png" />

// ✅ Sugerido: Imagem acessível
<img src="chart.png" alt="Gráfico de vendas do último trimestre" />
```

## 🛠️ Verificações por Categoria

### Formulários Acessíveis

```tsx
// Validação automática de:
- Labels associados aos inputs
- Mensagens de erro com aria-live
- Fieldsets para grupos relacionados
- Instruções claras para campos obrigatórios
```

### Modais e Diálogos

```tsx
// Verificações automáticas:
- role="dialog" ou role="alertdialog"
- aria-modal="true"
- Foco gerenciado (foco inicial + trap)
- Fechamento com ESC
```

### Tabelas de Dados

```tsx
// Validações de estrutura:
- <thead>, <tbody>, <th> adequados
- scope="col" | "row" em headers
- caption ou aria-label para contexto
```

## 📱 Responsividade e Movimento

### Sensibilidade ao Movimento

```css
/* Detecção automática de: */
@media (prefers-reduced-motion: reduce) {
     /* Animações reduzidas para usuários sensíveis */
     .animation {
          animation: none;
     }
}
```

### Zoom e Redimensionamento

- ✅ **200% zoom**: Layout não quebra
- ✅ **Touch targets**: Mínimo 44px
- ✅ **Orientação**: Funciona landscape/portrait

## ⚡ Gatilhos de Ativação

- Elementos `<button>`, `<a>`, `<input>` sem labels
- Elementos com `onClick` mas sem semântica
- Imagens sem atributo `alt`
- Contraste de cores insuficiente
- Hierarquia de headers quebrada
- Elementos interativos sem foco visível

## 🧪 Ferramentas Integradas

### Integração com axe-core

```typescript
// Executa automaticamente verificações
axe.run(component) → accessibilityIssues[]
```

### Screen Reader Simulation

```typescript
// Simula leitura por screen readers
simulateScreenReader(element) → readingOrder[]
```

## 📋 Checklist WCAG 2.1 AA

**Nível A (Crítico)**:

- [ ] Imagens com texto alternativo
- [ ] Vídeos com legendas
- [ ] Conteúdo acessível por teclado
- [ ] Sem flashing perigoso

**Nível AA (Recomendado)**:

- [ ] Contraste 4.5:1 (texto normal)
- [ ] Contraste 3:1 (texto grande)
- [ ] Redimensionamento até 200%
- [ ] Múltiplas formas de navegação

## 🎯 Exemplos de Correções

### Navegação Acessível

```tsx
// Antes
<div onClick={() => navigate('/home')}>Home</div>

// Depois - Skill sugere automaticamente
<button
  onClick={() => navigate('/home')}
  aria-current={location.pathname === '/home' ? 'page' : undefined}
>
  Home
</button>
```

### Modal Acessível

```tsx
// Skill gera automaticamente
<div
     role='dialog'
     aria-modal='true'
     aria-labelledby='modal-title'
     onKeyDown={handleKeyDown} // ESC para fechar
>
     <h2 id='modal-title'>Título do Modal</h2>
     {/* Conteúdo */}
</div>
```

## When NOT to use

- Não usar para regras de design que precisam de aprovação do time de UX (abranger com owner antes de aplicar correções automáticas).
- Não aplicar em componentes puramente decorativos sem interação.

## Manual verification steps

1. Executar varredura com axe-core e documentar as issues críticas.
2. Testar navegação por teclado em casos de uso importantes (modais, formulários, dropdowns).
3. Validar leitura com NVDA/VoiceOver em páginas principais e registrar evidências.

---

**Baseado em**: `REACT_ACESSIBILIDADE.instructions.md`
