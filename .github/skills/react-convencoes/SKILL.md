---
name: react-convencoes
description: Valida e sugere nomes seguindo os padrões de nomenclatura e arquitetura do projeto.
---

# Convenções de Nomenclatura — React (CCI-CA)

## Objetivo

Padronizar a organização de arquivos, nomes de componentes e a estrutura de pastas para garantir uma base de código previsível e escalável.

## Escopo Normativo

### Nomenclatura de Arquivos e Símbolos

- **Componentes**: `PascalCase.tsx` (ex: `UserProfile.tsx`).
- **Hooks**: `useCamelCase.ts` (ex: `useAuthSettings.ts`).
- **Serviços**: `nomeService.ts` (ex: `alunoService.ts`).
- **Interfaces/Tipos**: `I` + `PascalCase.ts` (ex: `IAluno.ts`).
- **Constants/Enums**: `PascalCase.ts` (ex: `StatusAlunos.ts`).

### Estrutura de Feature (3 Camadas)

Feature complexas devem ser divididas em:

1. **Container (`[Nome].tsx`)**: Orquestrador, injeta o hook.
2. **Hook (`use[Nome].ts`)**: Lógica, estado, handlers e metadados.
3. **View/Form (`[Nome]Form.tsx`)**: Apresentação pura (Dumb Component).

### Organização de Pastas

- `src/components/shared/`: Componentes reutilizáveis globalmente.
- `src/components/pages/[Modulo]/[Feature]/`: Componentes específicos de uma tela.
- `src/services/`: Lógica de comunicação com API/Supabase.
- `src/hooks/`: Hooks de utilidade global.

## When NOT to use

- Não forçar 3 camadas em componentes triviais (ex: um botão customizado).
- Não obrigar prefixo `I` em tipos vindos de bibliotecas externas (ex: `MuiProps`).

## Checklist de Validação

- [ ] O nome do arquivo bate com o export principal?
- [ ] Componentes começam com Maiúscula?
- [ ] Hooks começam com `use`?
- [ ] A lógica de negócio está no hook ou vazou para o componente?

**Quando usar**: Lógica específica de uma entidade/feature

**Exemplos**:

- `useManterUsuario.ts` - CRUD de usuário
- `useListarUsuarios.ts` - Listagem com filtros

## ⚡ Gatilhos de Ativação

- Criação de novos arquivos `.tsx`, `.ts`
- Renomeação de componentes ou hooks
- Detecção de estrutura inadequada
- Movimentação de arquivos entre diretórios

## 🛠️ Sugestões Automáticas

### Ao criar arquivo

```typescript
// Detecta: userProfile.tsx
// Sugere: UserProfile.tsx

// Detecta: UseProfile.ts
// Sugere: useProfile.ts (se for hook) ou IProfile.ts (se for tipo)
```

### Ao organizar features

```typescript
// Detecta: Hook de negócio em src/hooks/
// Sugere: Mover para src/components/pages/[Feature]/

// Detecta: Hook reutilizável em feature
// Sugere: Mover para src/hooks/
```

## 📋 Validações de Estrutura

**3 Camadas Obrigatórias**:

- [ ] Container existe e usa hook
- [ ] Hook encapsula toda lógica
- [ ] Form recebe props e renderiza UI

**Organização de Hooks**:

- [ ] Hooks globais são reutilizáveis
- [ ] Hooks de feature são específicos
- [ ] Sem mistura de responsabilidades

## When NOT to use

- Não usar para regras de negócio; apenas para convenções de arquivo/nome.
- Não aplicar automaticamente quando houver dependências históricas que exigem migração coordenada.

## Manual verification steps

1. Conferir PRs de criação/renomeação de arquivos e confirmar que os nomes seguem o padrão.
2. Testar builds e imports para evitar regressões após renomeações.
3. Notificar owner (`@frontend`) quando regras de naming causarem impacto em múltiplos pacotes.

---

**Baseado em**: `REACT_CONVENCOES_NOMENCLATURA.instructions.md`
