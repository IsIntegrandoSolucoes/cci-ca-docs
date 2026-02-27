---
name: javascript-async-errors
description: 'Assincronia e erros em JavaScript: Promise combinators, filas de tarefas, erros customizados e rethrow.'
metadata:
  owner: '@javascript'
  version: '1.0.0'
  scope: 'asynchrony and error handling'
  status: 'active'
---

# JavaScript Async + Errors (Guia Conceitual)

Objetivo: orientar escolha correta de combinadores de Promise, evitar memory leaks comuns e tratar excecoes com contexto.

## 1. Estados de Promise e encadeamento

Uma Promise possui 3 estados:

- `pending`
- `fulfilled`
- `rejected`

`then` processa sucesso, `catch` processa falhas e `finally` roda em ambos os cenarios.

```js
fetchData()
  .then((data) => transform(data))
  .catch((err) => handle(err))
  .finally(() => cleanup())
```

## 2. `Promise.all` vs `Promise.race` vs `Promise.allSettled`

- `Promise.all(iterable)`:
  - resolve com array de resultados quando todas resolvem
  - rejeita na primeira falha (fail-fast)
- `Promise.race(iterable)`:
  - resolve/rejeita com a primeira que terminar
  - util para timeout competitivo
- `Promise.allSettled(iterable)`:
  - sempre resolve com status de todas (`fulfilled`/`rejected`)
  - util para cenarios parciais

```js
const tasks = [fetchA(), fetchB(), fetchC()]

await Promise.all(tasks) // falha se uma falhar
await Promise.race(tasks) // pega a primeira que concluir
await Promise.allSettled(tasks) // recebe tudo, inclusive falhas
```

## 3. `async/await`: sequencial vs paralelo

`await` sequencial em operacoes independentes cria waterfall.
Para paralelizar, dispare primeiro e aguarde com `Promise.all`.

```js
// Sequencial (mais lento)
const a = await fetchA()
const b = await fetchB()

// Paralelo (mais rapido quando independentes)
const [pa, pb] = await Promise.all([fetchA(), fetchB()])
```

## 4. `setTimeout(fn, 0)` e ordem no event loop

`setTimeout(fn, 0)` nao ignora a fila. Ele agenda macrotask para proximo ciclo.
Antes de macrotask rodar, microtasks pendentes sao executadas.

```js
setTimeout(() => console.log('timeout 0'), 0)
Promise.resolve().then(() => console.log('promise then'))
console.log('sync')
// sync -> promise then -> timeout 0
```

## 5. Garbage collection e alcancabilidade

Modelo mental:

- Objetos alcancaveis por uma raiz (global, stack ativa, etc.) permanecem vivos.
- Objetos inalcancaveis viram candidatos a coleta.

Engines modernas usam estrategias baseadas em mark-and-sweep.
GC automatico nao elimina leaks causados por referencias mantidas sem necessidade.

## 6. 3 memory leaks comuns e como evitar

1. Listeners nao removidos

- Problema: `addEventListener` sem `removeEventListener`
- Mitigacao: cleanup explicito

2. Timers/intervals sem cancelamento

- Problema: `setInterval` ativo apos descarte do contexto
- Mitigacao: `clearInterval`/`clearTimeout`

3. Referencias longas para objetos grandes

- Problema: caches/globais retendo dados inutilizados
- Mitigacao: invalidacao de cache, escopo menor, WeakMap quando aplicavel

```js
function start() {
  const onResize = () => {}
  window.addEventListener('resize', onResize)

  const id = setInterval(() => {}, 1000)

  return () => {
    window.removeEventListener('resize', onResize)
    clearInterval(id)
  }
}
```

## 7. Erros customizados e quando relancar

Crie classes para diferenciar categoria de erro sem perder stack.
Relance (`throw`) quando a camada atual nao consegue resolver e a superior precisa decidir.

```js
class ValidationError extends Error {
  constructor(message, details) {
    super(message)
    this.name = 'ValidationError'
    this.details = details
  }
}

async function processOrder(input) {
  try {
    validate(input)
    return await save(input)
  } catch (err) {
    if (err instanceof ValidationError) {
      throw err // relanca com contexto de dominio
    }

    throw new Error(`Falha ao processar pedido: ${err.message}`)
  }
}
```

Regra pratica:

- Trate localmente quando ha acao de recuperacao.
- Relance quando a camada atual so tem contexto parcial.

Evite:

- "engolir" erro em `catch` vazio.
- retornar em `finally` (pode sobrescrever fluxo de retorno/erro).

## Checklist de revisao

- [ ] Combinador de Promise escolhido pelo comportamento esperado.
- [ ] Fluxo depende de primeira resposta? usar `race` com criterio claro.
- [ ] Fluxo precisa tolerar falhas parciais? usar `allSettled`.
- [ ] Listeners e timers tem cleanup garantido.
- [ ] Erros customizados carregam contexto util.
- [ ] Excecoes sao relancadas somente quando a camada superior deve decidir.

## When NOT to use

- Nao usar `Promise.race` sem estrategia de cancelamento/timeout clara.
- Nao encapsular todo erro em tipo generico perdendo causa original.

## Manual verification steps

1. Testar cenarios de sucesso parcial e falha total para combinadores.
2. Revisar ciclo de vida de listeners/timers com testes automatizados.
3. Verificar logs para garantir stack trace e contexto de erro preservados.
