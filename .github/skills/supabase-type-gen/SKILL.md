---
name: supabase-type-gen
description: Instruções para gerar, atualizar e utilizar Types do Supabase. Use quando houver mudanças no banco de dados ou erros de tipagem.
---

# Skill de Types do Supabase

Esta skill orienta o processo correto de atualização e uso dos types TypeScript gerados automaticamente a partir do schema do Supabase.

## 🎯 Quando usar

- Após criar, alterar ou deletar tabelas/colunas no Supabase.
- Quando encontrar erros de tipagem relacionados a propriedades do banco.
- Ao criar novas features que dependem de dados do banco.

## ⚡ Comandos Rápidos

| Ação                | Comando                  |
| :------------------ | :----------------------- |
| **Atualizar Types** | `npm run types:generate` |
| **Validar Types**   | `npm run type-check`     |
| **Modo Watch**      | `npm run types:watch`    |

## 📦 Como Importar

Sempre importe do index principal `@/types` ou de subpastas específicas se necessário, mas evite importar de `supabase.ts` diretamente.

```typescript
// ✅ Recomendado: Import unificado
import { IPessoas, IProdutos } from '@/types';

// ✅ Específico (útil para evitar ciclos)
import { IPessoas } from '@/types/tables/IPessoas';
```

## 🏗️ Types Customizados (Features)

Para queries complexas com `.select()` (joins/relacionamentos), os types automáticos não bastam. Crie types específicos na pasta `features`:

**Caminho:** `src/types/features/[modulo]/[arquivo].ts`

```typescript
// Exemplo: src/types/features/aluno/cadastro.ts
export type AlunoComEndereco = {
     entidade: number;
     nome: string;
     cidades: {
          nome: string;
          estados: {
               sigla: string;
          };
     };
};

// Uso
const { data } = await supabase.from('alunos').select('*, cidades(nome, estados(sigla))').maybeSingle<AlunoComEndereco>();
```

## 🚫 O que NÃO Fazer

1.   ❌ **NUNCA edite manualmente** arquivos em `src/types/tables/` ou `src/types/views/`. Eles são sobrescritos.
2.   ❌ **NUNCA commite** código com erros de type-check.
3.   ❌ **NUNCA duplique** definições de tabela manualmente. Use `Pick<IPessoas, 'nome' | 'email'>` se precisar de parciais.

## 🔍 Troubleshooting

**Erro:** Propriedade nova do banco não aparece no autocomplete. **Solução:** Rode `npm run types:generate`. Se não resolver, verifique se salvou a alteração no Supabase Dashboard.
