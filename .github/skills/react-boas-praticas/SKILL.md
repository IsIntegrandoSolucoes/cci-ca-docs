---
name: react-boas-praticas
description: Automatiza validações de boas práticas React, hooks e performance.
---

# Boas Práticas — React (CCI-CA)

## Objetivo

Padronizar a escrita de componentes funcionais, garantindo performance, manutenibilidade e uso correto de Hooks conforme as diretrizes do React moderno e do projeto.

## Escopo Normativo

### Estrutura de Componentes

- **Componentes Funcionais**: Use sempre componentes funcionais com `const`.
- **Tipagem**: Props devem ser tipadas com `interface` ou `type`.
- **Fragmentos**: Use `<></>` quando não precisar de um wrapper DOM.

### Hooks

- **Dependências**: Sempre declare todas as dependências no `useEffect`, `useMemo` e `useCallback`.
- **Cleanup**: Efeitos que criam subscriptions ou timers DEVEM ter função de cleanup.
- **Hooks Customizados**: Extraia lógica complexa para hooks `use...`.

### Performance

- **Memoização**: Aplique `memo` em componentes que recebem props complexas ou estão em listas grandes.
- **Renderização Condicional**: Evite curto-circuito com `&&` para números (`{count && ...}` renderiza 0). Prefira ternários ou `!!count`.

## When NOT to use

- Não forçar `memo` em componentes extremamente simples (overkill).
- Não refatorar componentes de bibliotecas externas.

## Checklist de Qualidade

- [ ] Componente é funcional?
- [ ] Props estão tipadas?
- [ ] Hooks possuem dependências completas?
- [ ] Há cleanup onde necessário?
- [ ] Listas possuem `key` estáveis (IDs)?

            fetchData().then(setData);
       }, []); // ✅ Array vazio para executar uma vez

       return data.map((item) => (
            <div key={item.id}>{item.name}</div> // ✅ Key única
       ));

  });

```

## When NOT to use

- Não usar quando a análise é puramente conceitual e não está implementada no código (documentar como orientação no instruction associado).
- Não aplicar automáticamente em refactors que mudem a lógica sem revisão de performance.

## Manual verification steps

1. Revisar PRs com mudanças em componentes React e confirmar que hooks seguem regras (dependências, cleanups).
2. Executar testes de unidade e validar que componentes memoizados não regrediram (snapshot/benchmarks).
3. Revisar casos de uso em Storybook para confirmar comportamento visual e performance.

---

**Baseado em**: `REACT_BOAS_PRATICAS.instructions.md`
```
