---
name: supabase-metodologia
description: 'Garante que implementações sigam a metodologia database-first: analisar schema real, mover lógica crítica para functions/triggers/views e usar RPC para integração. Ativa-se ao desenvolver features que envolvem banco.'
metadata:
     owner: '@supabase-team'
     version: '1.0.0'
     activation: 'on-change: migrations/**/*.sql'
     scope: 'database-first methodology'
     status: 'active'
---

# Desenvolvimento Orientado ao Banco — Supabase

**Descrição**: Garante que implementações sejam baseadas na estrutura real do banco, não em suposições

**Ativação**: Automática ao desenvolver features que envolvem operações de banco

## 🛡️ Regra Crítica: Lógica no Banco

**SEMPRE prefira PostgreSQL para lógica crítica:**

### ✅ OBRIGATÓRIO NO BANCO

- **Functions/Procedures**: Cálculos financeiros, validações críticas
- **Triggers**: Auditoria automática, validações de integridade
- **Views**: Consultas complexas, relatórios
- **RLS Policies**: Controle de acesso granular

### ❌ PROIBIDO NO FRONTEND

- Cálculos monetários
- Validações críticas de negócio
- Operações transacionais
- Processamento de dados sensíveis

## 🔍 Processo Obrigatório

### 1. **Análise do Banco (PRIMEIRA)**

```sql
-- Skill executa automaticamente via MCP Supabase:

-- Estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'sua_tabela'
ORDER BY ordinal_position;

-- Relacionamentos (FK)
SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'sua_tabela';

-- Dados reais (amostra)
SELECT * FROM sua_tabela LIMIT 5;
```

### 2. **Implementação (SEGUNDA)**

```typescript
// Skill força esta ordem:
1. ✅ Analisar estrutura real
2. ✅ Identificar lógica crítica → banco
3. ✅ Criar Functions/Triggers/Views
4. ✅ Implementar interfaces baseadas na estrutura real
5. ✅ Desenvolver serviços usando RPC para lógica crítica
6. ✅ Criar componentes focados em apresentação
```

## 🏗️ Arquitetura Automática

### Camadas Geradas

```
1. 🗄️ Banco (PostgreSQL)
   ├── Functions (lógica crítica)
   ├── Triggers (validações automáticas)
   ├── Views (consultas complexas)
   └── RLS (controle de acesso)

2. 🔧 Interfaces (TypeScript)
   ├── Baseadas no schema real
   ├── Generated types
   └── RPC function signatures

3. ⚛️ Serviços (Supabase Client)
   ├── RPC calls para lógica crítica
   ├── Simple queries para CRUD
   └── Real-time subscriptions

4. 🎨 Componentes (React)
   ├── Apresentação e UX
   ├── Estado de interface
   └── Navegação
```

## ⚡ Verificações Automáticas

### Detecção de Lógica no Local Errado

```typescript
// ❌ Detectado: Cálculo financeiro no frontend
const calculateTax = (amount: number, rate: number) => {
     return amount * rate; // Crítico: pode ser manipulado
};

// ✅ Sugerido: RPC para function do banco
const { data: tax } = await supabase.rpc('fn_calculate_tax', {
     amount,
     tax_rate: rate,
});
```

### Validação de Estrutura vs Código

```typescript
// Skill verifica se interfaces correspondem ao schema real
interface User {
     id: string; // ❌ Schema real: BIGINT
     name: string; // ❌ Schema real: primeiro_nome + ultimo_nome
     type: 'admin'; // ❌ Schema real: fk_id_tipo_usuario
}

// ✅ Interface gerada automaticamente do schema
interface Usuario {
     id: number; // BIGINT
     primeiro_nome: string; // VARCHAR(100)
     ultimo_nome: string; // VARCHAR(100)
     fk_id_tipo_usuario: number; // FK para tipo_usuarios
}
```

## 🛠️ Funcionalidades Integradas

### Integração com MCP Supabase

```typescript
// Skill usa automaticamente:
- mcp_supabase_list_tables() → análise de esquema
- mcp_supabase_execute_sql() → consultas de estrutura
- mcp_supabase_generate_typescript_types() → tipos atualizados
```

### Sugestões Automáticas de Functions

```sql
-- Para operações críticas, skill sugere:
CREATE OR REPLACE FUNCTION fn_processar_pagamento(
  p_usuario_id BIGINT,
  p_valor DECIMAL(10,2),
  p_tipo_pagamento_id BIGINT
) RETURNS TABLE(
  sucesso BOOLEAN,
  transacao_id BIGINT,
  mensagem TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Lógica crítica protegida no banco
  -- Validações que não podem ser contornadas
  -- Transações atômicas garantidas
END;
$$;
```

## 📋 Checklist Automático

**Análise Obrigatória**:

- [ ] Estrutura real consultada via MCP
- [ ] Relacionamentos mapeados
- [ ] Dados reais analisados
- [ ] Types gerados do schema atual

## When NOT to use

- Não aplicar sem consultar o schema real via MCP (evitar suposições).
- Não usar como substituto de revisão por DBA para mudanças críticas em produção.

## Manual verification steps

1. Confirmar que a estrutura real foi consultada via MCP antes de propor alterações.
2. Verificar que functions/triggers propostas respeitam RLS e políticas de segurança.
3. Garantir geração de types e atualização de contratos antes da integração front/backend. **Implementação Correta**:

- [ ] Lógica crítica no banco (Functions/Triggers)
- [ ] Interfaces baseadas no schema real
- [ ] Serviços usando RPC para operações críticas
- [ ] Componentes focados em apresentação

**Segurança Garantida**:

- [ ] Validações críticas protegidas
- [ ] Transações atômicas
- [ ] RLS policies implementadas
- [ ] Auditoria automática

## 🚨 Alertas Automáticos

### Implementação por Suposição

```typescript
// ❌ Detectado: Interface sem consultar schema
interface Product {
     id: string; // Skill alerta: "Verificar tipo real no banco"
     price: number; // Skill alerta: "Lógica de preço deve estar no banco"
}
```

### Lógica Crítica no Frontend

```typescript
// ❌ Detectado: Validação crítica no frontend
if (user.balance >= order.total) {
     // Skill alerta: "CRÍTICO: Validação financeira deve ser no banco"
     processOrder();
}

// ✅ Sugerido: RPC call segura
const { data: canProcess } = await supabase.rpc('fn_validate_order', {
     user_id: user.id,
     order_id: order.id,
});
```

## 💡 Benefícios Garantidos

- **🔒 Segurança**: Lógica incontornável no banco
- **⚡ Performance**: Processamento próximo aos dados
- **🎯 Confiabilidade**: Transações atômicas automáticas
- **🔧 Manutenibilidade**: Implementação certeira baseada na realidade

---

**Baseado em**: `SUPABASE_DATABASE_DRIVEN.instructions.md`
