---
name: condicionais-operadores-ternarios
description: Evita a renderização acidental de "0" ou valores falsy indesejados em condicionais React. Use ao criar ou refatorar componentes com renderização condicional.
---

# Skill de Renderização Segura no React

Esta skill orienta o uso de padrões seguros de renderização condicional no React para evitar o problema de "vazamento de valores falsy" (ex: renderizar o número "0" na interface).

## O Problema

Em JavaScript/TypeScript, `0` é considerado um valor "falsy". Ao usar o operador lógico AND (`&&`) para renderização condicional, se a condição for avaliada como `0`, o React renderiza o número `0` na tela ao invés de não renderizar nada.

**❌ Padrão Ruim:**

```tsx
{
     count && <DisplayContador valor={count} />;
}
// Se count for 0, isso renderiza "0" na tela ao invés de nada.
```

**❌ Padrão Ruim:**

```tsx
{
     items.length && <Lista items={items} />;
}
// Se items.length for 0, renderiza "0".
```

## A Solução

Use um dos seguintes padrões seguros para garantir que apenas elementos válidos ou `null` sejam renderizados.

### 1. Operador Ternário (Recomendado)

Trate explicitamente os casos verdadeiro e falso. Esta é a abordagem mais robusta e legível para valores numéricos.

**✅ Padrão Bom:**

```tsx
{
     count > 0 ? <DisplayContador valor={count} /> : null;
}
```

**✅ Padrão Bom:**

```tsx
{
     items.length > 0 ? <Lista items={items} /> : null;
}
```

### 2. Conversão Booleana ou Comparação Estrita

Force a condição a ser estritamente booleana antes de usar `&&`.

**✅ Padrão Bom:**

```tsx
{
     !!count && <DisplayContador valor={count} />;
}
```

**✅ Padrão Bom:**

```tsx
{
     items.length > 0 && <Lista items={items} />;
}
```

## Checklist antes de gerar código

1.   **Verifique o tipo da condição:** É um número? Uma string? Pode ser `0` ou string vazia `""`?
2.   **Evite uso direto de variáveis numéricas em condições `&&`**.
3.   **Prefira Ternário (`? : null`)** para condições numéricas, deixando explícito o retorno `null` quando a condição falha.

## Exemplos

### Cenário: Exibindo um desconto

**❌ Evite:**

```tsx
{
     desconto && <BadgeDesconto valor={desconto} />;
}
```

**✅ Use:**

```tsx
{
     desconto ? <BadgeDesconto valor={desconto} /> : null;
}
```

Ou verifique o intervalo válido:

```tsx
{
     desconto > 0 ? <BadgeDesconto valor={desconto} /> : null;
}
```

### Cenário: Renderização de Lista

**❌ Evite:**

```tsx
{
     dados.total && <Sumario total={dados.total} />;
}
```

**✅ Use:**

```tsx
{
     dados.total > 0 ? <Sumario total={dados.total} /> : null;
}
```
