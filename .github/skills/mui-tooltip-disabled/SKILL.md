---
name: mui-tooltip-disabled
description: Garante que `Tooltip` do MUI seja usado corretamente com elementos desabilitados, evitando warnings e melhorando a acessibilidade.
metadata:
     owner: '@mui'
     version: '1.0.0'
     activation: 'on-save:**/*.tsx'
     scope: 'mui best-practices'
     status: 'active'
---

# Skill: MUI Tooltip with Disabled Elements

Resumo: Detecta usos de `Tooltip` envolvendo elementos com `disabled={true}` sem wrapper e sugere o padrão correto (envolver em `<span>` ou `display: inline-flex` para layout). Baseado em `GUIA_MUI_TOOLTIP_DISABLED.md`.

When to activate:
- Ativa-se ao salvar arquivos `.tsx` que utilizem `Tooltip` com `Button`, `IconButton` ou elementos HTML/React que possam estar `disabled`.
- Também ativa quando há alterações na documentação de boas práticas `pob-docs/src/Boas Práticas React/`.

Automated actions / Suggestions:
- Detectar `Tooltip` cujo filho é um elemento com `disabled` e recomendar envolver o filho em `<span>`.
- Sugerir títulos dinâmicos para estados habilitado/desabilitado (ex.: `title={isEnabled ? 'Salvar' : 'Preencha os campos'}`).
- Recomendar estilos `display: inline-block`/`inline-flex` quando necessário para layout (ex.: `fullWidth`).

Manual verification steps:
1. Verificar que elementos desabilitados usados dentro de `Tooltip` estão envolvidos por wrapper leve (`<span>`).
2. Testar se o `Tooltip` aparece nos estados habilitado/desabilitado e que não há warnings no console.
3. Confirmar que o wrapper não contém handlers ou props `disabled` indevidos.

Examples (quick fixes):
- Transformar `
  <Tooltip title="Salvar">
    <Button disabled>Salvar</Button>
  </Tooltip>
  `
  em
  `
  <Tooltip title={isValid ? 'Salvar' : 'Complete os campos'}>
    <span style={{ display: 'inline-block' }}>
      <Button disabled={!isValid}>Salvar</Button>
    </span>
  </Tooltip>
  `

Testing guidance:
- Adicionar testes que renderizem componentes com `Tooltip` e elementos `disabled` e assertem ausência de warnings e comportamento esperado (tooltip visível via events when wrapped).

References:
- `pob-docs/src/Boas Práticas React/GUIA_MUI_TOOLTIP_DISABLED.md`
- https://mui.com/material-ui/react-tooltip/#disabled-elements

Notes:
- Skill sugere correções e exemplos; não altera código automaticamente. Reforça acessibilidade e evita warnings do MUI.
