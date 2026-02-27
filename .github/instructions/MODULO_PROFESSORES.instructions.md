# 👨‍🏫 Instruções para Desenvolvimento - Módulo de Professores

## 📋 Contexto

O **Módulo de Professores** implementa controle de acesso e filtragem de dados para usuários do tipo Professor (`tipo_pessoa = 4`) no Portal Administrativo CCI-CA. Professores têm acesso restrito apenas aos dados de suas disciplinas e turmas.

---

## 🎯 Regras de Implementação

### **1. Identificação de Professores**

```typescript
// ✅ CORRETO: Verificar tipo_pessoa
const isProfessor = userData?.fk_id_tipo_pessoa === 4;

// ❌ ERRADO: Não verificar ou usar outro campo
const isProfessor = userData?.cargo === 'professor'; // Campo não existe
```

### **2. Uso de Contextos**

```typescript
// ✅ CORRETO: Usar hook específico do contexto
import { useProfessorFilter } from '../contexts/ProfessorFilterContext';

const { isProfessor, disciplinasPermitidas, turmasPermitidas } = useProfessorFilter();

// ❌ ERRADO: Acessar contexto diretamente sem hook
const context = useContext(ProfessorFilterContext); // Não fazer
```

### **3. Aplicação de Filtros em Queries**

```typescript
// ✅ CORRETO: Usar hook apropriado baseado no contexto

// OPÇÃO 1: Dentro de ProfessorFilterRoutes (contexto garantido)
import { useProfessorQuery } from '../../hooks/useProfessorQuery';

const { aplicarFiltroQuery } = useProfessorQuery({ tabela: 'agendamentos' });
let query = supabase.from('agendamentos_alunos').select('*');
query = aplicarFiltroQuery(query);

// OPÇÃO 2: Fora de ProfessorFilterRoutes (contexto opcional)
import { useConditionalProfessorQuery } from '../../hooks/useConditionalProfessorQuery';

const { aplicarFiltroQuery, hasContext } = useConditionalProfessorQuery({ 
     tabela: 'agendamentos' 
});
let query = supabase.from('agendamentos_alunos').select('*');
query = aplicarFiltroQuery(query); // Se sem contexto, age como admin

// ❌ ERRADO: Fazer filtro manual
if (isProfessor) {
     query = query.in('fk_id_disciplina', disciplinasPermitidas); // Não fazer
}
```

### **4. Roteamento Condicional**

```typescript
// ✅ CORRETO: Usar estrutura condicional no UserRoutes
{isProfessor ? (
     <ProfessorFilterRoutes />
) : (
     <Routes>
          {/* Rotas administrativas */}
     </Routes>
)}

// ❌ ERRADO: Misturar rotas de professor com rotas administrativas
<Routes>
     {isProfessor ? <Route path="..." /> : <Route path="..." />}
     {/* Confuso e difícil de manter */}
</Routes>
```

### **5. Validação de Permissões**

```typescript
// ✅ CORRETO: Validar permissões antes de renderizar
const { temPermissao } = useProfessorQuery({ tabela: 'agendamentos' });

if (!temPermissao) {
     return (
          <Alert severity="warning">
               Você não possui permissão para acessar esta página.
          </Alert>
     );
}

// ❌ ERRADO: Não validar permissões
return (
     <Container>
          {/* Renderiza componente sem verificar */}
     </Container>
);
```

---

## 🛠️ Padrões de Código

### **Estrutura de Componente com Filtros**

```typescript
import React, { useEffect, useState } from 'react';
import { Alert, Container } from '@mui/material';
import { supabase } from '../config/supabaseConfig';
import { useProfessorQuery } from '../hooks/useProfessorQuery';

const MeuComponente = () => {
     const { 
          aplicarFiltroQuery, 
          isProfessor, 
          disciplinasPermitidas,
          temPermissao 
     } = useProfessorQuery({ tabela: 'agendamentos' });
     
     const [dados, setDados] = useState([]);
     const [loading, setLoading] = useState(false);
     
     useEffect(() => {
          carregarDados();
     }, [disciplinasPermitidas]); // Recarregar se disciplinas mudarem
     
     const carregarDados = async () => {
          try {
               setLoading(true);
               
               let query = supabase
                    .from('tabela')
                    .select('*')
                    .order('created_at', { ascending: false });
               
               // Aplicar filtro automático
               query = aplicarFiltroQuery(query);
               
               const { data, error } = await query;
               
               if (error) throw error;
               setDados(data || []);
               
               // Log informativo
               console.log(
                    isProfessor 
                         ? `📚 Carregados ${data?.length || 0} registros (disciplinas: ${disciplinasPermitidas.join(', ')})`
                         : `📚 Carregados ${data?.length || 0} registros (admin)`
               );
          } catch (error) {
               console.error('Erro ao carregar dados:', error);
          } finally {
               setLoading(false);
          }
     };
     
     // Validação de permissões
     if (!temPermissao) {
          return (
               <Alert severity="warning">
                    Você não possui disciplinas cadastradas. Contate o administrador.
               </Alert>
          );
     }
     
     return (
          <Container>
               {/* Indicador visual para professores */}
               {isProfessor && (
                    <Alert severity="info" sx={{ mb: 2 }}>
                         Visualizando dados das suas disciplinas: {disciplinasPermitidas.join(', ')}
                    </Alert>
               )}
               
               {/* Resto do componente */}
               {loading ? <p>Carregando...</p> : <p>Dados: {dados.length}</p>}
          </Container>
     );
};

export default MeuComponente;
```

---

## 📚 Tabelas e Filtros Disponíveis

| Tabela                | Hook Option           | Campo Filtrado                         | Lógica                                |
|-----------------------|-----------------------|----------------------------------------|---------------------------------------|
| `agendamentos_alunos` | `tabela: 'agendamentos'` | `agendamento_professor.fk_id_disciplina` | IN (disciplinas_do_professor)         |
| `disciplinas`         | `tabela: 'disciplinas'`  | `id`                                   | IN (disciplinas_do_professor)         |
| `turmas`              | `tabela: 'turmas'`       | `fk_id_disciplina`                     | IN (disciplinas_do_professor)         |
| `alunos_matriculados` | `tabela: 'alunos_matriculados'` | `fk_id_turma`               | IN (turmas_do_professor)              |

---

## 🔒 Considerações de Segurança

### **Frontend (Implementado)**

✅ Filtros aplicados automaticamente nas queries  
✅ Validação de permissões antes de renderizar  
✅ Logs informativos para debugging  
✅ Tratamento de casos sem permissão

### **Backend (Recomendado - A Implementar)**

📋 Implementar Row Level Security (RLS) no Supabase:

```sql
-- Política para agendamentos
CREATE POLICY "professores_ver_seus_agendamentos" 
ON agendamentos_alunos FOR SELECT
USING (
     fk_id_disciplina IN (
          SELECT id FROM disciplinas 
          WHERE fk_id_professor = auth.uid()
     )
);

-- Política para alunos matriculados
CREATE POLICY "professores_ver_seus_alunos" 
ON alunos_matriculados FOR SELECT
USING (
     fk_id_turma IN (
          SELECT t.id FROM turmas t
          JOIN disciplinas d ON t.fk_id_disciplina = d.id
          WHERE d.fk_id_professor = auth.uid()
     )
);
```

---

## 🧪 Testes e Debugging

### **Verificar Dados do Professor**

```typescript
// No componente, adicionar logs temporários
console.log('👤 Dados do Professor:', {
     isProfessor,
     disciplinasPermitidas,
     turmasPermitidas,
     professorData
});
```

### **Verificar Aplicação de Filtros**

```typescript
// Antes do filtro
console.log('🔍 Query antes do filtro:', query);

// Aplicar filtro
query = aplicarFiltroQuery(query);

// Depois do filtro
console.log('✅ Query após filtro:', query);
```

### **Testar Cenários**

1. **Teste como Admin**:
   - Login com tipo_pessoa = 1 ou 2
   - Deve ver TODOS os dados

2. **Teste como Professor COM disciplinas**:
   - Login com tipo_pessoa = 4
   - Deve ver apenas dados das disciplinas associadas

3. **Teste como Professor SEM disciplinas**:
   - Login com tipo_pessoa = 4 sem disciplinas cadastradas
   - Deve ver mensagem de "sem permissão"

---

## 📖 Documentação Relacionada

- **Documentação Completa**: `docs/MODULO_PROFESSORES.md`
- **Contexto**: `src/contexts/ProfessorFilterContext/`
- **Hooks**: `src/hooks/useProfessorQuery.ts` e `src/hooks/useConditionalProfessorQuery.ts`
- **Rotas**: `src/routes/ProfessorFilterRoutes.tsx`

---

## 🚨 Erros Comuns

### **1. "Cannot read property 'isProfessor' of undefined"**

**Causa**: Hook usado fora do ProfessorFilterProvider  
**Solução**: Usar `useConditionalProfessorQuery` ou garantir que componente está dentro do provider

### **2. "Professor não vê seus agendamentos"**

**Causa**: Professor sem disciplinas cadastradas no banco  
**Solução**: Cadastrar disciplinas na tabela `disciplinas` com `fk_id_professor` correto

### **3. "Filtros não aplicados em queries"**

**Causa**: Esquecer de chamar `aplicarFiltroQuery(query)`  
**Solução**: Sempre aplicar o filtro antes de executar a query

### **4. "Arrays de disciplinas/turmas vazios"**

**Causa**: Dados não carregados ou erro no carregamento  
**Solução**: Verificar console para erros, validar estrutura do banco

---

## ✅ Checklist de Implementação

Ao adicionar nova funcionalidade para professores:

- [ ] Identificar qual tabela será consultada
- [ ] Escolher hook apropriado (`useProfessorQuery` ou `useConditionalProfessorQuery`)
- [ ] Definir opção de `tabela` no hook
- [ ] Aplicar `aplicarFiltroQuery()` na query Supabase
- [ ] Validar `temPermissao` antes de renderizar
- [ ] Adicionar indicador visual se `isProfessor`
- [ ] Testar com usuário admin e professor
- [ ] Verificar logs no console
- [ ] Documentar comportamento esperado

---

**Conclusão**: Sempre usar os hooks fornecidos para garantir segurança e consistência no controle de acesso de professores. Nunca implementar filtros manualmente.
