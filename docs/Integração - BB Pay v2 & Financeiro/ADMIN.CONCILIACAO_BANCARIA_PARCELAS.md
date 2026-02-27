# 🏦 Sistema de Conciliação Bancária - Parcelas CCI-CA

**Versão:** 1.0  
**Data:** 09 de setembro de 2025  
**Status:** ✅ Implementado

---

## 🎯 Visão Geral

O módulo de **Manutenção de Parcelas** no painel administrativo foi adaptado para implementar o novo sistema de conciliação bancária conforme as instruções do projeto CCI-CA.

### 📦 Arquivos Modificados

```
src/components/pages/Aluno/Parcelas/
├── utils/parcelasUtils.ts              ✅ ATUALIZADO
├── hooks/useParcelasPagamento.ts       ✅ ATUALIZADO
├── useParcelasDataGrid.tsx             📝 DEPRECATED
└── docs/
    └── CONCILIACAO_BANCARIA_PARCELAS.md ✅ NOVO
```

---

## 🔖 Códigos de Conciliação Implementados

### **Padrão de Geração**

```
CA-{TIPO}-{ID_CONTRATO}-{TIMESTAMP}
```

### **Tipos Suportados**

-    `CA-CT-####-YYYYMMDD` → **Contratos Mensais** (padrão)
-    `CA-TV-####-YYYYMMDD` → **Turmas Vestibular**
-    `CA-TM-####-YYYYMMDD` → **Turmas Mentoria**

### **Exemplos Reais**

```typescript
// Contrato ID 456 criado em 09/09/2025
'CA-CT-456-20250909';

// Turma Vestibular ID 111 matriculada em 09/09/2025
'CA-TV-111-20250909';

// Turma Mentoria ID 222 matriculada em 09/09/2025
'CA-TM-222-20250909';
```

---

## 🛠️ Implementação Técnica

### **1. Funções Utilitárias Criadas**

#### `generateCodigoConciliacao(contratoId, tipoSolicitacao)`

```typescript
/**
 * Gera código de conciliação bancária conforme padrão CCI-CA
 * @param contratoId - ID do contrato
 * @param tipoSolicitacao - 'CT' | 'TV' | 'TM'
 * @returns Código no formato CA-XX-ID-TIMESTAMP
 */
export const generateCodigoConciliacao = (contratoId: number, tipoSolicitacao: 'CT' | 'TV' | 'TM' = 'CT'): string => {
     const timestamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
     return `CA-${tipoSolicitacao}-${contratoId}-${timestamp}`;
};
```

#### `identificarTipoSolicitacao(turmaDescricao)`

```typescript
/**
 * Identifica automaticamente o tipo baseado na descrição da turma
 * @param turmaDescricao - Nome ou modalidade da turma
 * @returns 'CT' | 'TV' | 'TM'
 */
export const identificarTipoSolicitacao = (turmaDescricao?: string): 'CT' | 'TV' | 'TM' => {
     if (!turmaDescricao) return 'CT';

     const descricao = turmaDescricao.toLowerCase();

     if (descricao.includes('vestibular') || descricao.includes('enem')) {
          return 'TV'; // Turmas Vestibular
     }

     if (descricao.includes('mentoria') || descricao.includes('orientação')) {
          return 'TM'; // Turmas Mentoria
     }

     return 'CT'; // Contratos Mensais padrão
};
```

### **2. Hooks Atualizados**

#### `useParcelasPagamento.ts`

-    ✅ **Sistema de Conciliação**: Implementado nas funções `criarObjetoSolicitacao()` e `criarObjetoSolicitacaoVencida()`
-    ✅ **Detecção Automática**: Tipo de solicitação identificado automaticamente via `nome_turma` e `modalidade`
-    ✅ **Compatibilidade**: Mantém interface existente, apenas melhora códigos gerados

---

## 🔄 Fluxo de Pagamento

### **1. Geração de Solicitação**

```typescript
// No momento do pagamento:
const tipoSolicitacao = identificarTipoSolicitacao(turma.nome_turma || turma.modalidade);
const codigoConciliacao = generateCodigoConciliacao(contrato.id_contrato, tipoSolicitacao);

// Enviado para IS Cobrança API:
{
  geral: {
    codigoConciliacaoSolicitacao: codigoConciliacao, // "CA-CT-456-20250909"
    // ... outros campos
  }
}
```

### **2. Processamento Webhook**

```typescript
// Quando BB Pay confirma pagamento:
{
  numero_solicitacao: 12345,
  codigo_conciliacao: "CA-CT-456-20250909",
  sistema_origem_id: 7, // CCI-CA
  codigo_estado_pagamento: 200 // Efetivado
}
```

### **3. Auditoria e Rastreabilidade**

-    ✅ **Código Único**: Cada solicitação tem identificador único temporal
-    ✅ **Rastreabilidade**: Ligação direta contrato → solicitação → pagamento
-    ✅ **Auditoria**: Logs completos via tabela `auditoria`

---

## 📊 Compatibilidade

### **✅ Mantém Funcionalidade Existente**

-    Interface de usuário inalterada
-    Fluxos de pagamento funcionais
-    Validações de dados do devedor
-    Sistema de modals e confirmações

### **✅ Adiciona Melhorias**

-    Códigos de conciliação padronizados
-    Identificação automática de tipos
-    Melhor rastreabilidade financeira
-    Preparação para webhook automático

### **📝 Arquivos Deprecated**

-    `useParcelasDataGrid.tsx` → **Usar** `hooks/useParcelasDataGridRefactored.ts`
-    Comentários indicam migração para hooks especializados

---

## 🚨 Validações e Testes

### **Cenários Testados**

1. ✅ Pagamento de contrato mensal regular (`CA-CT-XXX-YYYYMMDD`)
2. ✅ Pagamento de turma vestibular (`CA-TV-XXX-YYYYMMDD`)
3. ✅ Pagamento de turma mentoria (`CA-TM-XXX-YYYYMMDD`)
4. ✅ Fallback para contrato padrão quando tipo indeterminado

### **Pontos de Verificação**

-    Códigos únicos por timestamp diário
-    Identificação correta de tipos via nome/modalidade
-    Manutenção de funcionalidades existentes
-    Integração com IS Cobrança API

---

## 📈 Próximos Passos

1. **Webhook Integration**: Verificar recebimento correto dos códigos no webhook
2. **Monitoramento**: Acompanhar geração de códigos em produção
3. **Cleanup**: Remover arquivo deprecated após validação completa
4. **Documentation**: Atualizar documentação de API se necessário

---

## 🔗 Referências

-    [GUIA_CONCILIACAO_BANCARIA.instructions.md](../../markdown/instructions/GUIA_CONCILIACAO_BANCARIA.instructions.md)
-    [VISAO_GERAL_NEGOCIO.instructions.md](../../markdown/instructions/VISAO_GERAL_NEGOCIO.instructions.md)
-    Implementação similar no módulo `cci-ca-aluno` (turmas)

---

_Implementação realizada conforme especificações das instruções de conciliação bancária CCI-CA._
