# Exemplos de Arquitetura — React Convenções

## Padrão de Feature (3 Camadas)

A arquitetura do CCI-CA separa responsabilidades em 3 camadas claras para cada feature complexa:

### 1. Camada de Orquestração (Container)

`src/components/pages/Alunos/ManterAluno/ManterAluno.tsx`

```tsx
export const ManterAluno = () => {
  const hook = useManterAluno() // Instancia o hook
  return <ManterAlunoForm {...hook} /> // Repassa props
}
```

### 2. Camada de Lógica (Custom Hook)

`src/components/pages/Alunos/ManterAluno/useManterAluno.ts`

```ts
export const useManterAluno = () => {
  const [aluno, setAluno] = useState<IAluno | null>(null)
  const handleSave = async () => {
    /* ... */
  }
  return { aluno, handleSave, isLoading: false }
}
```

### 3. Camada de Apresentação (View/Form)

`src/components/pages/Alunos/ManterAluno/ManterAlunoForm.tsx`

```tsx
export const ManterAlunoForm = ({ aluno, handleSave, isLoading }: IManterAlunoProps) => {
  return (
    <form onSubmit={handleSave}>
      <TextField value={aluno?.nome} disabled={isLoading} />
    </form>
  )
}
```

## Anti-padrões e Correções

- **Misturar lógica no Container:** Extraia para o hook.
- **Componentes com mais de 250 linhas:** Quebre em sub-componentes ou mova lógica para handlers.
- **Nomes em minúsculo para componentes:** Vercel e outros ambientes de build podem falhar; use sempre PascalCase.
