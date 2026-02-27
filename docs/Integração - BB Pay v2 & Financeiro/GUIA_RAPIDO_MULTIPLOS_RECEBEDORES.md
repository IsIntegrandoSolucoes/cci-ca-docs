# 🚀 Guia Rápido: Sistema de Múltiplos Recebedores

## ✅ O que foi implementado?

Agora você pode configurar **N recebedores** para cada transação, ao invés de apenas 2 (Convênio + Professor).

### Exemplo:

**Antes**: Só podia dividir entre Convênio e Professor  
**Agora**: Pode dividir entre quantos quiser:

-    Professor 1: 60%
-    Professor 2: 10%
-    Convênio: 20%
-    Outro: 10%

---

## 📋 Checklist de Implementação

### ✅ Backend (Completo)

-    [x] **Migration do banco de dados**

     -    Nova tabela `configuracao_recebedores`
     -    Função SQL `buscar_recebedores_configuracao`
     -    Trigger para validar soma de percentuais
     -    Migração automática dos dados existentes

-    [x] **Services**

     -    `RecebedoresConfigService`: Gerencia múltiplos recebedores
     -    `RepasseCalculatorService`: Atualizado para calcular com N recebedores

-    [x] **Controllers**

     -    `RecebedoresConfigController`: CRUD de recebedores

-    [x] **Rotas da API**
     -    `GET /api/configuracao-taxas/recebedores/modalidade/:modalidadeId`
     -    `GET /api/configuracao-taxas/recebedores/participante/:pessoaId/:modalidadeId`
     -    `GET /api/configuracao-taxas/recebedores/efetivos/:modalidadeId`
     -    `PUT /api/configuracao-taxas/recebedores/modalidade/:modalidadeId`
     -    `PUT /api/configuracao-taxas/recebedores/participante/:pessoaId/:modalidadeId`
     -    `DELETE /api/configuracao-taxas/recebedores/:recebedorId`

### ⏳ Frontend (A Implementar)

Falta apenas criar a interface no **cci-ca-admin** para:

-    [ ] Adicionar/remover recebedores dinamicamente
-    [ ] Validação em tempo real (soma = 100%)
-    [ ] Buscar professores para adicionar
-    [ ] Preview da divisão de valores

---

## 🎯 Como Usar

### 1. Executar a Migration

```bash
# No Supabase SQL Editor ou via psql
psql -h [host] -U [user] -d [database] -f migrations/20251013_multiplos_recebedores.sql
```

Ou copiar e colar o conteúdo de `migrations/20251013_multiplos_recebedores.sql` no Supabase SQL Editor.

### 2. Testar a API

#### Listar recebedores de uma modalidade:

```bash
curl http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1?tipoPagamento=PIX
```

#### Configurar múltiplos recebedores:

```bash
curl -X PUT http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1 \
  -H "Content-Type: application/json" \
  -d '{
    "tipoPagamento": "PIX",
    "recebedores": [
      {
        "identificador_recebedor": "125530",
        "tipo_recebedor": "Convenio",
        "tipo_pagamento": "PIX",
        "tipo_valor": "Percentual",
        "valor": 20,
        "ordem": 1,
        "descricao": "Convênio CCI-CA"
      },
      {
        "identificador_recebedor": "DINAMICO",
        "tipo_recebedor": "Participante",
        "tipo_pagamento": "PIX",
        "tipo_valor": "Percentual",
        "valor": 60,
        "ordem": 2,
        "descricao": "Professor Principal"
      },
      {
        "identificador_recebedor": "789",
        "tipo_recebedor": "Terceiro",
        "tipo_pagamento": "PIX",
        "tipo_valor": "Percentual",
        "valor": 10,
        "ordem": 3,
        "descricao": "Professor 2"
      },
      {
        "identificador_recebedor": "999",
        "tipo_recebedor": "Terceiro",
        "tipo_pagamento": "PIX",
        "tipo_valor": "Percentual",
        "valor": 10,
        "ordem": 4,
        "descricao": "Outro"
      }
    ]
  }'
```

### 3. Verificar Cálculo de Repasse

O cálculo de repasse agora usa automaticamente o novo sistema:

```typescript
// No código da API
const repasse = await repasseCalculator.calcularRepasse({
     valorTotal: 150.00,
     tipoPagamento: 'PIX',
     modalidade: 'AULA_PARTICULAR',
     identificadorParticipante: '123',
     numeroConvenio: 125530
});

// Resultado:
{
     tipoValorRepasse: 'Percentual',
     recebedores: [
          { identificadorRecebedor: '125530', tipoRecebedor: 'Convenio', valorRepasse: 20.00 },
          { identificadorRecebedor: '123', tipoRecebedor: 'Participante', valorRepasse: 60.00 },
          { identificadorRecebedor: '789', tipoRecebedor: 'Participante', valorRepasse: 10.00 },
          { identificadorRecebedor: '999', tipoRecebedor: 'Participante', valorRepasse: 10.00 }
     ]
}
```

---

## ⚠️ Validações Automáticas

### 1. Soma de Percentuais

```sql
-- Se tentar inserir percentuais que somem > 100%, o banco retorna erro:
ERROR: A soma dos percentuais não pode exceder 100%. Soma atual: 110%
```

### 2. Valores Fixos

```typescript
// Se soma dos valores fixos > valor total, a API retorna erro:
{
  "success": false,
  "error": "Soma dos valores fixos (R$ 200.00) não pode ser maior que o valor total (R$ 150.00)"
}
```

### 3. Tipo Consistente

```typescript
// Todos os recebedores devem usar o mesmo tipo (Percentual OU Fixo)
{
  "success": false,
  "error": "Todos os recebedores devem usar o mesmo tipo de valor (Percentual ou Fixo)"
}
```

---

## 🔍 Cenários de Teste

### Cenário 1: 4 Recebedores com PIX

```json
{
     "tipoPagamento": "PIX",
     "recebedores": [
          { "identificador_recebedor": "125530", "valor": 20, "descricao": "Convênio" },
          { "identificador_recebedor": "DINAMICO", "valor": 60, "descricao": "Prof. 1" },
          { "identificador_recebedor": "789", "valor": 10, "descricao": "Prof. 2" },
          { "identificador_recebedor": "999", "valor": 10, "descricao": "Outro" }
     ]
}
```

**Resultado**: ✅ Soma = 100%

### Cenário 2: Erro - Soma > 100%

```json
{
     "recebedores": [{ "valor": 60 }, { "valor": 50 }]
}
```

**Resultado**: ❌ Erro: "Soma atual: 110%"

### Cenário 3: Valores Fixos

```json
{
     "recebedores": [
          { "tipo_valor": "Fixo", "valor": 30 }, // R$ 30,00
          { "tipo_valor": "Fixo", "valor": 120 } // R$ 120,00
     ]
}
```

**Para valor total de R$ 150,00**: ✅ OK (soma = R$ 150,00)

---

## 🎨 Próximo Passo: Interface Admin

Para facilitar o uso, falta implementar a interface no **cci-ca-admin**:

### Componentes necessários:

1. **FormRecebedores.tsx**

     - Lista de recebedores
     - Botão "Adicionar Recebedor"
     - Input de percentual com validação
     - Busca de professores

2. **ItemRecebedor.tsx**

     - Card de recebedor
     - Inputs: identificador, tipo, percentual
     - Botão remover

3. **ValidadorPercentuais.tsx**

     - Mostra soma atual
     - Alerta se != 100%

4. **PreviewDivisao.tsx**
     - Mostra preview com valor exemplo
     - Calcula valores reais

Quer que eu implemente a interface agora?

---

## 📚 Documentação Completa

-    **Sistema Completo**: `/docs/Financeiro/SISTEMA_MULTIPLOS_RECEBEDORES.md`
-    **Migration**: `/migrations/20251013_multiplos_recebedores.sql`
-    **API Reference**: Veja endpoints acima

---

## ❓ FAQ

**P: Preciso migrar dados existentes?**  
R: Não, a migration já faz isso automaticamente.

**P: O sistema antigo ainda funciona?**  
R: Sim, há fallback automático se não houver recebedores configurados.

**P: Posso ter recebedores diferentes para PIX e BOLETO?**  
R: Sim, cada tipo de pagamento tem sua própria configuração.

**P: Como funciona o identificador "DINAMICO"?**  
R: É substituído automaticamente pelo ID do professor no momento do cálculo.

**P: Posso configurar recebedores específicos por professor?**  
R: Sim, usa a rota `/recebedores/participante/:pessoaId/:modalidadeId`.

---

_Dúvidas? Veja a documentação completa ou entre em contato._
