---
name: javascript-core-runtime
description: 'Fundamentos de runtime JavaScript: hoisting, TDZ, escopo, closures e event loop.'
metadata:
  owner: '@javascript'
  version: '1.0.0'
  scope: 'javascript language and runtime fundamentals'
  status: 'active'
---

# JavaScript Core Runtime (Guia Conceitual)

Objetivo: explicar e revisar fundamentos que causam bugs reais em qualquer projeto JavaScript/TypeScript.

## Pergunta classica de entrevista

"Por que este codigo imprime `undefined` sem erro?"

```js
console.log(nome)
var nome = 'Gabriel'
```

Resposta curta:

- `var` sofre hoisting com inicializacao implicita em `undefined`.
- A declaracao sobe para o topo do escopo.
- A atribuicao permanece na linha original.

## 1. `var`, `let`, `const`: hoisting e TDZ

Regra prática:

- `var`: sofre hoisting e inicia como `undefined`.
- `let` e `const`: sofrem hoisting, mas ficam inacessiveis ate a inicializacao (Temporal Dead Zone).
- `const`: exige inicializacao e nao permite reatribuicao da referencia.

```js
console.log(a) // undefined
var a = 1

console.log(b) // ReferenceError (TDZ)
let b = 2
```

## 2. Hoisting de funcoes: declaracao vs expressao

Funcoes declaradas com `function` sobem com nome e corpo.
Expressoes de funcao seguem as regras da variavel que as recebe.

```js
sayHi() // ok
function sayHi() {
  console.log('oi')
}

sayBye() // TypeError: sayBye is not a function
var sayBye = function () {
  console.log('tchau')
}
```

## 3. Escopo e scope chain

Tipos de escopo:

- Global: acessivel em todo o programa.
- Funcao: visivel apenas dentro da funcao.
- Bloco: visivel apenas dentro de `{}`.

Regra pratica:

- `var` respeita escopo de funcao e ignora bloco.
- `let` e `const` respeitam bloco.

Scope chain:

- O JavaScript procura a variavel no escopo atual.
- Se nao encontra, sobe para o escopo pai, e assim por diante.

## 4. Bug classico do `for` com `var`

Com `var`, existe um unico binding compartilhado no loop.
Com `let`, existe um binding por iteracao.

```js
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log('var', i), 0) // 3, 3, 3
}

for (let j = 0; j < 3; j++) {
  setTimeout(() => console.log('let', j), 0) // 0, 1, 2
}
```

## 5. Closures, dados privados e factory functions

Closure: funcao interna que preserva acesso ao escopo lexico externo.

```js
function createCounter() {
  let count = 0 // dado privado

  return {
    inc() {
      count += 1
      return count
    },
    get() {
      return count
    },
  }
}

const counter = createCounter()
counter.inc() // 1
counter.get() // 1
```

Use closure para encapsulamento leve sem classe.

Risco comum:

- Um closure pode reter referencias grandes sem necessidade.
- Extraia apenas o valor necessario para evitar retencao desnecessaria em memoria.

## 6. Event loop: call stack, Web APIs e filas

`setTimeout` agenda a callback na fila de macrotasks. O callback so roda quando:

1. call stack estiver vazia
2. microtasks tiverem sido drenadas

Por isso, costuma executar "por ultimo" em relacao a codigo sincronico e microtasks pendentes.

## 7. Microtasks vs Macrotasks

Microtasks (prioridade alta no fim do tick atual):

- `Promise.then/catch/finally`
- `queueMicrotask`
- `MutationObserver`

Macrotasks:

- `setTimeout`, `setInterval`
- I/O callbacks
- UI events

```js
setTimeout(() => console.log('macrotask'), 0)
Promise.resolve().then(() => console.log('microtask'))
console.log('sync')
// Ordem: sync -> microtask -> macrotask
```

Importante:

- Se o codigo sincrono bloquear a thread, o event loop nao progride.
- Em browser, tarefas pesadas devem ir para Web Workers quando aplicavel.

## Checklist de revisao

- [ ] Evitar `var` em codigo novo.
- [ ] Revisar loops assincronos para garantir escopo por iteracao.
- [ ] Validar uso intencional de closure para encapsulamento.
- [ ] Entender fila de tarefas antes de depurar ordem de execucao.

## When NOT to use

- Nao usar para discutir detalhes de runtime especificos de engine sem necessidade.
- Nao aplicar regra de estilo onde existe padrao oficial de lint mais restritivo.

## Manual verification steps

1. Executar snippets pequenos em Node/Browser para confirmar a ordem real de execucao.
2. Cobrir casos de `for` assincrono com testes unitarios.
3. Verificar se nao existe dependencia em comportamento de `var` legado.
