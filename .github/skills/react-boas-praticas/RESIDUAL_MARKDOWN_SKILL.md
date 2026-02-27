# Exemplos de Otimização — React Boas Práticas

## Comparativo: Refatoração de Hook e Performance

**Antes (Anti-padrão)**:

```tsx
const Component = () => {
  const [data, setData] = useState([])

  useEffect(() => {
    fetchData().then(setData)
  }) // ❌ Dependências faltando

  return data.map((item) => <div>{item.name}</div>) // ❌ Key faltando
}
```

**Depois (Otimizado)**:

```tsx
const Component = memo(() => {
  const [data, setData] = useState<Item[]>([])

  useEffect(() => {
    let isMounted = true
    fetchData().then((res) => {
      if (isMounted) setData(res)
    })
    return () => {
      isMounted = false
    } // ✅ Cleanup
  }, []) // ✅ Dependência vazia se for apenas no mount

  return (
    <ul>
      {data.map((item) => (
        <li key={item.id}>{item.name}</li> // ✅ Key estável
      ))}
    </ul>
  )
})
```

## Integração com React Compiler

A skill utiliza diagnósticos compatíveis com o React Compiler para detectar componentes que podem ser auto-memoizados.

- Verifique sempre se as dependências do `useMemo` e `useCallback` são mínimas e estáveis.
