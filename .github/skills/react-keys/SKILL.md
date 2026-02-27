---
name: react-keys
description: Valida o uso de `key` em listas React e sugere correções (IDs estáveis, Fragment keys, evitar índices).
metadata:
     owner: '@react'
     version: '1.0.0'
     activation: 'on-save:**/*.tsx'
     scope: 'react best-practices'
     status: 'active'
---

# Skill: React Keys (Boas Práticas)

Resumo: Detecta padrões problemáticos relacionados a `key` em listas React e recomenda correções baseadas no guia `GUIA_REACT_KEYS.md`.

When to activate:
- Ativa-se ao salvar arquivos `.tsx` que contenham renderização de listas.
- Também ativa quando há alterações nos arquivos de boas práticas em `pob-docs/src/Boas Práticas React/`.

Automated actions / Suggestions:
- Avisar quando listas são renderizadas sem `key`.
- Sugerir uso de IDs estáveis (ex.: `id`, `uuid`) em vez de índice do array.
- Detectar `Fragment` sem `key` em mapeamentos e recomendar `Fragment key={...}`.
- Sugerir `getRowId` quando DataGrid é usado sem especificar `getRowId`.

Manual verification steps:
1. Verificar que cada lista renderizada tem `key` única e estável.
2. Confirmar que não há uso de `index` como `key` em listas dinâmicas.
3. Verificar Fragments e listas aninhadas para `key` em cada nível.
4. Atualizar exemplos e tests quando necessário.

Examples (quick fixes):
- Substituir `key={index}` por `key={item.id}` quando possível.
- Envolver múltiplos elementos com `<Fragment key={item.id}>`.
- Para MUI `DataGrid`, adicionar `getRowId={(row) => row.id}`.

Testing guidance:
- Adicionar testes que renderizem listas e assertem que não há warnings no console durante render (`expect(console.warn).not.toHaveBeenCalled()`).

References:
- `pob-docs/src/Boas Práticas React/GUIA_REACT_KEYS.md`
- https://react.dev/learn/rendering-lists

Notes:
- Esta skill não modifica código automaticamente; sugere correções e exemplos aplicáveis conforme as convenções do projeto.
