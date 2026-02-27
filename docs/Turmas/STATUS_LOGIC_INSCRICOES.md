/\*\*

-    @name Status Logic Fix: "Minhas Inscrições"
-    @author Gabriel M. Guimarães | gabrielmg7
-    @description Correção da lógica de status em "Minhas Inscrições"
-    @package docs/STATUS_LOGIC_INSCRICOES.md \*/

# 🎯 Status Logic: "Minhas Inscrições"

## 📋 Problema Reportado

O usuário está vendo status **"matriculado"** em "Minhas Inscrições" quando deveria ver **"inscrito"**.

## 🔍 Análise dos Status

### 📊 **Fluxo Atual do Aluno**

```
1. Aluno se inscreve → Status: "inscrito" (tabela: aluno_turmas)
2. Aluno solicita matrícula → Status: "matriculado" (tabela: contrato_ano_pessoa, parcela 1)
3. Aluno paga matrícula → Não aparece em "Minhas Inscrições" (vai para "Meus Contratos")
```

### 🎯 **Status Definitions**

-    "inscrito": Aluno se inscreveu mas ainda não tem parcela 1 criada OU parcela 1 não foi paga
-    "matriculado": Aluno tem parcela 1 paga (com valor_pago e data_pagamento)
-    Não aparece em "Minhas Inscrições": Quando está realmente matriculado (vai para "Meus Contratos")

| Status            | Significado                                                        | Tabela de Origem                     | Ação Disponível                  |
| ----------------- | ------------------------------------------------------------------ | ------------------------------------ | -------------------------------- |
| **`inscrito`**    | Aluno se inscreveu, mas ainda não solicitou pagamento de matrícula | `aluno_turmas`/`contrato_ano_pessoa` | "Pagar Matrícula" (cria parcela) |
| **`matriculado`** | Aluno tem parcela 1 paga (com valor_pago e data_pagamento)         | `contrato_ano_pessoa` (parcela 1)    | "Pagar Matrícula" (paga parcela) |

## 🤔 Análise do Caso

### ✅ **Se o comportamento atual ESTÁ CORRETO:**

-    O aluno já **solicitou a matrícula** (existe parcela 1 em `contrato_ano_pessoa`)
-    Status "matriculado" é **apropriado** pois ele passou da fase de inscrição
-    A ação "Pagar Matrícula" deve pagar a parcela já criada

### ❌ **Se o comportamento atual ESTÁ INCORRETO:**

Duas possibilidades:

1. **Filtro muito restritivo**: A query não está pegando apenas parcelas realmente não pagas
2. **Regra de negócio errada**: Talvez devesse mostrar "inscrito" até o pagamento ser efetivado

## 🛠️ Correção Aplicada

### 📝 **Query Anterior**

```sql
.or('data_pagamento.is.null,valor_pago.is.null')
```

**Problema**: Retorna registros onde OU data_pagamento OU valor_pago é null

### ✅ **Query Corrigida**

```sql
.is('data_pagamento', null)
.is('valor_pago', null)
```

**Solução**: Retorna apenas registros onde AMBOS os campos são null

## 🧪 Teste Necessário

Para confirmar a correção, verificar:

1. **Aluno apenas inscrito** → Deve aparecer como "inscrito"
2. **Aluno que solicitou matrícula mas não pagou** → Deve aparecer como "matriculado"
3. **Aluno que pagou matrícula** → NÃO deve aparecer em "Minhas Inscrições"

## 📋 Próximos Passos

1. ✅ **Aplicada**: Correção da query para usar AND em vez de OR
2. 🔄 **Aguardando**: Teste do usuário para confirmar se a correção resolve o problema
3. 📝 **Se ainda incorreto**: Revisar regra de negócio sobre quando mostrar "inscrito" vs "matriculado"

---

**Observação**: A correção foca em garantir que apenas parcelas **realmente não pagas** sejam consideradas para o status "matriculado". Se ainda estiver aparecendo incorretamente, pode ser necessário revisar a regra de negócio completa.
