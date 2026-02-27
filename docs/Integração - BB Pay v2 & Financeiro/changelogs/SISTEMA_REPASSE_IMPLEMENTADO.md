# 🔄 Sistema de Repasse CCI-CA API - Implementação Completa

**Data**: 09 de setembro de 2025  
**Status**: ✅ **IMPLEMENTADO**

---

## 🎯 Objetivo

Implementar sistema completo de cálculo de repasse na **CCI-CA API**, centralizando a lógica de divisão financeira que estava dispersa no frontend.

---

## ✅ Implementação Realizada

### **1. RepasseCalculatorService.ts** - Novo Serviço

-    ✅ **Localização**: `src/services/RepasseCalculatorService.ts`
-    ✅ **Responsabilidade**: Cálculo centralizado de repasse e divisão de recebedores
-    ✅ **Integração Supabase**: Busca modalidades e número do participante

#### **Funcionalidades Implementadas:**

```typescript
// Cálculo específico para contratos
calcularRepasseContrato(valor, tipoPagamento, professorId, isVencido, numeroConvenio);

// Cálculo específico para aulas
calcularRepasseAula(valor, tipoPagamento, modalidade, professorId, numeroConvenio);

// Busca número do participante via conta_bancaria → cnpj.fk_id_pessoa
buscarNumeroParticipante(professorId);

// Consulta modalidade da tabela modalidade_aula
consultarModalidade(modalidadeNome);
```

#### **Tipos Suportados:**

-    ✅ **PIX**: Taxa percentual (0.5% base + multiplicador por modalidade)
-    ✅ **BOLETO**: Taxa fixa (R$ 1,99 base + multiplicador por modalidade)
-    ❌ **Cartão**: Removido completamente

#### **Modalidades Baseadas em Supabase:**

-    `CONTRATO` - Contratos mensais
-    `AULA_PARTICULAR` - Aulas individuais
-    `AULA_GRUPO` - Aulas em grupo
-    `PRE_PROVA` - Cursos pré-prova
-    `REVISAO` - Aulas de revisão
-    `REFORCO` - Aulas de reforço

### **2. CobrancaIntegracaoService.ts** - Integração Completa

-    ✅ **Método `montarPayloadContrato()`**: Agora inclui cálculo de repasse automático
-    ✅ **Método `montarPayloadAulaParticular()`**: Agora inclui cálculo de repasse automático
-    ✅ **Integração**: Utiliza `RepasseCalculatorService` para todos os cálculos

#### **Fluxo Implementado:**

```typescript
// Para Contratos
const repasse = await this.repasseCalculator.calcularRepasseContrato(
     valorFinal,
     'PIX', // ou 'BOLETO'
     dados.fk_id_turma,
     false, // não vencido
);

// Para Aulas Particulares
const repasse = await this.repasseCalculator.calcularRepasseAula(dados.valor_aula, 'PIX', dados.agendamento.modalidade.nome, dados.fk_id_agendamento_professor);
```

---

## 🔧 Especificações Técnicas

### **Configuração de Taxas por Modalidade:**

| Modalidade      | PIX (Base) | Multiplicador | BOLETO  |
| --------------- | ---------- | ------------- | ------- |
| CONTRATO        | 0.5%       | 1.0x          | R$ 1,99 |
| AULA_PARTICULAR | 0.5%       | 1.2x = 0.6%   | R$ 1,99 |
| AULA_GRUPO      | 0.5%       | 0.8x = 0.4%   | R$ 1,99 |
| PRE_PROVA       | 0.5%       | 1.1x = 0.55%  | R$ 1,99 |
| REVISAO         | 0.5%       | 1.0x          | R$ 1,99 |
| REFORCO         | 0.5%       | 1.0x          | R$ 1,99 |

### **Estrutura de Retorno (IRepasse):**

```typescript
{
    tipoValorRepasse: 'Percentual',
    recebedores: [
        {
            identificadorRecebedor: "125530", // Convênio
            tipoRecebedor: 'Convenio',
            valorRepasse: 0.5 // Percentual para convênio
        },
        {
            identificadorRecebedor: "789", // Professor via conta_bancaria
            tipoRecebedor: 'Participante',
            valorRepasse: 99.5 // Percentual para professor
        }
    ]
}
```

### **Integração com Supabase:**

#### **Busca de Número do Participante:**

```sql
SELECT
    professores.id,
    professores.nome,
    cnpj.conta_bancaria.numero_participante
FROM professores
JOIN cnpj ON cnpj.fk_id_pessoa = professores.id
JOIN conta_bancaria ON conta_bancaria.cnpj_id = cnpj.id
WHERE professores.id = ?
```

#### **Consulta de Modalidades:**

```sql
SELECT nome, descricao
FROM modalidade_aula
WHERE nome ILIKE '%{modalidade}%'
```

---

## 🔄 Fluxo Operacional

### **1. Criação de Solicitação de Contrato:**

1. `gerarSolicitacaoContrato()` é chamado
2. `RepasseCalculatorService.calcularRepasseContrato()` executa:
     - Busca número do participante via Supabase
     - Calcula taxa baseada em PIX/BOLETO
     - Gera array de recebedores
3. `montarPayloadContrato()` inclui repasse no payload
4. Solicitação enviada para `is-cobranca-api` com repasse calculado

### **2. Criação de Solicitação de Aula:**

1. `gerarSolicitacaoAulaParticular()` é chamado
2. `RepasseCalculatorService.calcularRepasseAula()` executa:
     - Consulta modalidade na tabela `modalidade_aula`
     - Busca número do participante via Supabase
     - Aplica multiplicador específico da modalidade
     - Gera array de recebedores
3. `montarPayloadAulaParticular()` inclui repasse no payload
4. Solicitação enviada para `is-cobranca-api` com repasse calculado

---

## 🧪 Validação e Testes

### **Casos de Teste Sugeridos:**

#### **Contrato PIX (R$ 150,00):**

```typescript
// Input
valorTotal: 150.00
tipoPagamento: 'PIX'
modalidade: 'CONTRATO'

// Expected Output
convenio: 0.5% = R$ 0,75 (0.5%)
professor: 99.5% = R$ 149,25 (99.5%)
```

#### **Aula Particular BOLETO (R$ 80,00):**

```typescript
// Input
valorTotal: 80.00
tipoPagamento: 'BOLETO'
modalidade: 'AULA_PARTICULAR'

// Expected Output
convenio: R$ 1,99 (2.49%)
professor: R$ 78,01 (97.51%)
```

---

## 🔒 Benefícios da Implementação

### **1. Centralização:**

-    ✅ **Lógica única** na API ao invés de duplicada no frontend
-    ✅ **Fonte da verdade** para cálculos financeiros
-    ✅ **Consistency** entre diferentes clientes (admin, aluno, professor)

### **2. Flexibilidade:**

-    ✅ **Configuração dinâmica** via tabelas Supabase
-    ✅ **Suporte a múltiplas modalidades** automaticamente
-    ✅ **Taxas personalizáveis** por modalidade e tipo de pagamento

### **3. Manutenibilidade:**

-    ✅ **Mudanças centralizadas** na API
-    ✅ **Frontend simplificado** (apenas consome API)
-    ✅ **Logs detalhados** para debugging
-    ✅ **Fallbacks** para casos de erro

### **4. Integração:**

-    ✅ **Consulta direta** ao Supabase para dados atualizados
-    ✅ **Compatibilidade** com estrutura existente
-    ✅ **Async/await** para performance otimizada

---

## 📋 Próximos Passos

1. **✅ Implementação Completa** - Sistema de repasse funcional na API
2. **🔄 Simplificar Frontend** - Remover hook `useRepasseCalculator` do admin
3. **🧪 Testes Integrados** - Validar cálculos com dados reais
4. **📊 Monitoramento** - Logs para acompanhar cálculos em produção
5. **⚙️ Configuração** - Painel admin para ajustar taxas dinamicamente

---

_Sistema implementado seguindo especificações do cliente - CCI-CA API v1.0_
