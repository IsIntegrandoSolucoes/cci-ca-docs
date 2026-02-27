# 🗄️ Metodologia Database-Driven

## 📋 Princípio Fundamental

**SEMPRE ANALISE O BANCO DE DADOS ANTES DE IMPLEMENTAR QUALQUER FUNCIONALIDADE**

Esta metodologia garante que toda implementação seja baseada na estrutura real do banco, não em suposições.

### 🛡️ **Regra Crítica: Lógica no Banco**

**SEMPRE prefira PostgreSQL Functions, Triggers e Views para lógica crítica:**

-    ✅ **Functions/Procedures** - Cálculos, validações e processos críticos
-    ✅ **Triggers** - Validações automáticas e auditoria
-    ✅ **Views** - Consultas complexas e relatórios
-    ❌ **Frontend** - Apenas apresentação e interação

## 🔍 Processo Obrigatório

### 1. **Análise do Banco (PRIMEIRA)**

```sql
-- Estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'sua_tabela' ORDER BY ordinal_position;

-- Relacionamentos
SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'sua_tabela';

-- Dados reais
SELECT * FROM sua_tabela LIMIT 5;
```

### 2. **Implementação (SEGUNDA)**

1. ✅ Identifique lógica crítica → banco
2. ✅ Crie Functions/Triggers/Views
3. ✅ Implemente interfaces baseadas na estrutura real
4. ✅ Desenvolva serviços usando RPC para lógica crítica
5. ✅ Crie componentes focados em apresentação

## 🎯 Onde Implementar

### **🗄️ OBRIGATÓRIO NO BANCO**

-    Cálculos financeiros e monetários
-    Validações críticas de negócio
-    Operações transacionais
-    Processamento automático
-    Relatórios complexos
-    Auditoria e logs
-    Controle de acesso
-    Conciliação de dados

### **⚛️ PERMITIDO NO FRONTEND**

-    Apresentação e formatação
-    Validação básica de UX
-    Navegação e roteamento
-    Estado da interface
-    Comunicação com APIs
-    Manipulação de eventos

## 🏗️ Arquitetura

**Camadas (de baixo para cima):**

1. **Banco** - Estrutura, lógica crítica, validações
2. **Interfaces** - Baseadas na estrutura real
3. **Serviços** - RPC para crítico, queries para CRUD
4. **Componentes** - Apresentação e UX

## 📝 Checklist

**Análise:**

-    [ ] Estrutura real da tabela analisada
-    [ ] Relacionamentos identificados
-    [ ] Dados reais consultados

**Implementação:**

-    [ ] Lógica crítica implementada no banco
-    [ ] Interfaces baseadas na estrutura real
-    [ ] Serviços usando RPC para operações críticas
-    [ ] Componentes focados em apresentação

## 🚨 Consequências de Não Seguir

**Lógica no Frontend:**

-    Vulnerabilidades de segurança
-    Inconsistência de dados
-    Performance degradada
-    Impossibilidade de auditoria

**Implementação por Suposição:**

-    Retrabalho total
-    Bugs em produção
-    Perda de tempo
-    Incompatibilidade com dados reais

## 💡 Benefícios

**Segurança:** Lógica protegida e incontornável **Performance:** Processamento otimizado próximo aos dados **Confiabilidade:** Transações atômicas e validações automáticas **Manutenibilidade:** Implementação certeira e evolução centralizada

---

**O banco de dados é a fonte da verdade e o guardião da lógica crítica.**