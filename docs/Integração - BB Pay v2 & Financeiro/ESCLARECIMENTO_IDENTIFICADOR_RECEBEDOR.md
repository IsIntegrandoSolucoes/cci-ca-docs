# Esclarecimento: Identificador do Recebedor

**Data:** 13 de Janeiro de 2025  
**Contexto:** Sistema de Múltiplos Recebedores v2.0

---

## 🎯 Conceito Fundamental

### O identificador do recebedor é SEMPRE o `numero_participante` da tabela `conta_bancaria`

Este é um número **numérico** registrado no Banco do Brasil que identifica uma conta de participante do convênio.

---

## 🗄️ Estrutura de Dados

### Tabelas Envolvidas:

```
conta_bancaria
├── id (PK)
├── numero_participante ← ESTE É O IDENTIFICADOR
├── agencia
├── numero_conta
└── ...

cnpj
├── id (PK)
├── fk_id_conta_bancaria (FK → conta_bancaria.id)
├── numero
└── ...

turmas
├── id (PK)
├── fk_id_cnpj (FK → cnpj.id)
├── descricao
└── ...
```

### Fluxo de Resolução:

```
turmas.fk_id_cnpj
  → cnpj.id
    → cnpj.fk_id_conta_bancaria
      → conta_bancaria.id
        → conta_bancaria.numero_participante ✅
```

---

## 🔢 Tipos de Identificador

### 1. Convenio (Fixo)

**Tipo:** `Convenio`  
**Identificador:** Número do participante conveniado (fixo)  
**Exemplo:** `125530`

**Uso:**

```typescript
{
     tipo_recebedor: 'Convenio',
     identificador_recebedor: '125530', // numero_participante da conta do convênio
     percentual: 80.00
}
```

**Onde vem:**

-    Configurado manualmente
-    É o `numero_participante` da conta bancária do convênio no Banco do Brasil
-    Valor fixo e conhecido

---

### 2. Participante (Fixo)

**Tipo:** `Participante`  
**Identificador:** Número do participante específico (fixo)  
**Exemplo:** `19`, `20`, `21`

**Uso:**

```typescript
{
     tipo_recebedor: 'Participante',
     identificador_recebedor: '19', // numero_participante de um professor específico
     percentual: 20.00
}
```

**Onde vem:**

-    Configurado manualmente
-    É o `numero_participante` da conta bancária de um professor específico
-    Usado quando se quer direcionar para um professor fixo, independente da turma

---

### 3. Participante (DINAMICO)

**Tipo:** `Participante`  
**Identificador:** `"DINAMICO"` (placeholder)  
**Resolve para:** `numero_participante` do professor da turma

**Uso:**

```typescript
{
     tipo_recebedor: 'Participante',
     identificador_recebedor: 'DINAMICO', // será resolvido em tempo de execução
     percentual: 20.00
}
```

**Como funciona:**

1. **Configuração:** Admin configura com `"DINAMICO"`
2. **Armazenamento:** Salvo como string `"DINAMICO"` no banco
3. **Resolução:** Quando um pagamento é processado:

     ```typescript
     // RepasseCalculatorService.resolverIdentificadorDinamico()

     // 1. Busca turma do contrato/agendamento
     const turma = await buscarTurma(turmaId);

     // 2. Busca CNPJ vinculado
     const cnpj = await buscarCNPJ(turma.fk_id_cnpj);

     // 3. Busca conta bancária
     const contaBancaria = await buscarContaBancaria(cnpj.fk_id_conta_bancaria);

     // 4. Retorna numero_participante
     return contaBancaria.numero_participante; // Ex: "19"
     ```

4. **Envio para BB:** O valor resolvido (`"19"`) é enviado para a API do Banco do Brasil

**Vantagem:**

-    Não precisa reconfigurar quando o professor da turma mudar
-    O repasse sempre vai para o professor atual da turma
-    Flexibilidade para turmas com professores rotativos

---

## 📋 Exemplos Práticos

### Exemplo 1: Convenio Fixo + Professor Fixo

```typescript
// Modalidade: Aulas Particulares
recebedores: [
     {
          tipo_recebedor: 'Convenio',
          identificador_recebedor: '125530', // Convênio CCI-CA
          percentual: 80.0,
     },
     {
          tipo_recebedor: 'Participante',
          identificador_recebedor: '19', // Professor João (numero_participante fixo)
          percentual: 20.0,
     },
];

// Resultado: Sempre repassa 20% para conta do participante 19
```

### Exemplo 2: Convenio Fixo + Professor Dinâmico

```typescript
// Modalidade: Turma Vestibular
recebedores: [
     {
          tipo_recebedor: 'Convenio',
          identificador_recebedor: '125530', // Convênio CCI-CA
          percentual: 70.0,
     },
     {
          tipo_recebedor: 'Participante',
          identificador_recebedor: 'DINAMICO', // Professor da turma
          percentual: 30.0,
     },
];

// Resultado:
// - Aluno da Turma A (professor Maria, participante 20) → repassa 30% para 20
// - Aluno da Turma B (professor João, participante 19) → repassa 30% para 19
```

### Exemplo 3: Múltiplos Professores + Convenio

```typescript
// Modalidade: Aulas em Grupo (2 professores)
recebedores: [
     {
          tipo_recebedor: 'Convenio',
          identificador_recebedor: '125530',
          percentual: 60.0,
     },
     {
          tipo_recebedor: 'Participante',
          identificador_recebedor: '19', // Professor João
          percentual: 20.0,
     },
     {
          tipo_recebedor: 'Participante',
          identificador_recebedor: '20', // Professora Maria
          percentual: 20.0,
     },
];

// Resultado: Repassa 20% para cada professor fixo
```

---

## 🔍 Validações

### Backend (SQL)

```sql
-- Validação de soma = 100%
CREATE OR REPLACE FUNCTION validar_soma_percentuais()
RETURNS TRIGGER AS $$
BEGIN
     -- Valida que soma dos percentuais = 100%
     IF (SELECT SUM(percentual) FROM configuracao_recebedores
         WHERE fk_id_configuracao_modalidade = NEW.fk_id_configuracao_modalidade) <> 100 THEN
          RAISE EXCEPTION 'Soma dos percentuais deve ser 100%%';
     END IF;
     RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Backend (TypeScript)

```typescript
// RepasseCalculatorService
async resolverIdentificadorDinamico(identificador: string, turmaId?: number): Promise<string> {
     if (identificador !== 'DINAMICO') {
          return identificador; // Já é numero_participante fixo
     }

     if (!turmaId) {
          throw new Error('turmaId necessário para resolver DINAMICO');
     }

     // Busca numero_participante via turma → cnpj → conta_bancaria
     const { data, error } = await supabase
          .from('turmas')
          .select(`
               fk_id_cnpj,
               cnpj:fk_id_cnpj (
                    fk_id_conta_bancaria,
                    conta_bancaria:fk_id_conta_bancaria (
                         numero_participante
                    )
               )
          `)
          .eq('id', turmaId)
          .single();

     if (error || !data) {
          throw new Error('Turma não encontrada ou sem CNPJ vinculado');
     }

     return data.cnpj.conta_bancaria.numero_participante;
}
```

### Frontend

```typescript
// Validação no ItemRecebedor.tsx
<TextField
     label='Número do Participante (conta_bancaria)'
     placeholder='Ex: DINAMICO ou 19, 20, 21...'
     helperText='DINAMICO = resolve via turma → CNPJ → conta_bancaria.numero_participante | Ou número fixo'
/>
```

---

## 🎨 Interface do Usuário

### Card da Modalidade:

```
┌─────────────────────────────────────┐
│ Aulas Particulares          [CA-AP] │
├─────────────────────────────────────┤
│ 👥 Recebedores (2)                  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Convenio]                      │ │
│ │ Participante 125530        80%  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Participante]                  │ │
│ │ Professor da Turma         20%  │ │
│ │ (resolvido dinamicamente)       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Editar Recebedores]                │
└─────────────────────────────────────┘
```

### Modal de Edição:

```
┌─────────────────────────────────────────────────────────┐
│ Editar Recebedores - Aulas Particulares           [X]  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Tipo: [Convenio ▼]                                  │ │
│ │ Número do Participante: [125530________________]    │ │
│ │ numero_participante da conta conveniada no BB       │ │
│ │ Percentual: [80.00] %                          [X]  │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Tipo: [Participante ▼]                              │ │
│ │ Número do Participante: [DINAMICO______________]    │ │
│ │ DINAMICO = resolve via turma → CNPJ → conta         │ │
│ │ Percentual: [20.00] %                          [X]  │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ [+ Adicionar Recebedor]                                 │
│                                                         │
│ ✅ Soma dos percentuais: 100.00%                        │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                        [Cancelar]  [Salvar]             │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Fluxo Completo: Pagamento → Repasse

### 1. Configuração (Admin)

```typescript
// Admin configura recebedores para "Turma Vestibular"
PUT / api / configuracao - taxas / recebedores / modalidade / 7;
{
     recebedores: [
          {
               tipo_recebedor: 'Convenio',
               identificador_recebedor: '125530',
               percentual: 70.0,
               ordem: 1,
          },
          {
               tipo_recebedor: 'Participante',
               identificador_recebedor: 'DINAMICO',
               percentual: 30.0,
               ordem: 2,
          },
     ];
}
```

### 2. Pagamento (Aluno)

```typescript
// Aluno João cria contrato na Turma A (professor Maria, participante 20)
const contrato = {
     fk_id_turma: 15, // Turma A
     valor_parcela: 1000.0,
};
```

### 3. Geração de Solicitação (Backend)

```typescript
// CobrancaIntegracaoService.gerarSolicitacaoContrato()
const repasse = await repasseCalculator.calcularRepasseContrato(
     1000.0, // valor
     'PIX', // tipoPagamento
     15, // turmaId
     false, // isVencido
);

// RepasseCalculatorService.calcularRepasseComMultiplosRecebedores()
// 1. Busca recebedores da modalidade 7
// 2. Encontra DINAMICO no recebedor 2
// 3. Resolve: turma 15 → cnpj.fk_id_conta_bancaria → conta_bancaria.numero_participante
// 4. Retorna: "20" (numero_participante da professora Maria)

// Resultado:
repasse = {
     tipoValorRepasse: 'Percentual',
     recebedores: [
          {
               identificadorRecebedor: '125530', // Convenio
               tipoRecebedor: 'Convenio',
               valorRepasse: 70,
          },
          {
               identificadorRecebedor: '20', // Maria (DINAMICO resolvido!)
               tipoRecebedor: 'Participante',
               valorRepasse: 30,
          },
     ],
};
```

### 4. Envio para Banco do Brasil

```json
POST https://cobranca.bb.com.br/cobrancas/v2/solicitacao
{
     "geral": {
          "valorSolicitacao": 1000.00,
          ...
     },
     "repasse": {
          "tipoValorRepasse": "Percentual",
          "recebedores": [
               {
                    "identificadorRecebedor": "125530",
                    "tipoRecebedor": "Convenio",
                    "valorRepasse": 70
               },
               {
                    "identificadorRecebedor": "20",
                    "tipoRecebedor": "Participante",
                    "valorRepasse": 30
               }
          ]
     }
}
```

### 5. Confirmação (Webhook)

```typescript
// Banco do Brasil confirma pagamento
// Repasse é processado automaticamente:
// - R$ 700,00 → Conta do participante 125530 (Convenio)
// - R$ 300,00 → Conta do participante 20 (Maria)
```

---

## 🔑 Pontos Importantes

### ✅ O que é armazenado no banco:

```sql
SELECT * FROM configuracao_recebedores;
```

| id  | modalidade | tipo         | identificador | percentual |
| --- | ---------- | ------------ | ------------- | ---------- |
| 1   | 1          | Convenio     | 125530        | 80.00      |
| 2   | 1          | Participante | DINAMICO      | 20.00      |
| 3   | 2          | Convenio     | 125530        | 70.00      |
| 4   | 2          | Participante | 19            | 30.00      |

### ✅ O que é enviado para o Banco do Brasil:

```json
{
     "recebedores": [
          {
               "identificadorRecebedor": "125530", // numero_participante
               "valorRepasse": 80
          },
          {
               "identificadorRecebedor": "19", // numero_participante (resolvido)
               "valorRepasse": 20
          }
     ]
}
```

### ⚠️ IMPORTANTE:

1. **DINAMICO é apenas um placeholder** usado na configuração
2. **Sempre resolve para numero_participante** antes de enviar para o BB
3. **Banco do Brasil recebe apenas números** de participantes válidos
4. **conta_bancaria.numero_participante** é a fonte única de verdade

---

## 📚 Referências

### Tabelas:

-    `conta_bancaria` - Armazena `numero_participante`
-    `cnpj` - Relaciona com `conta_bancaria`
-    `turmas` - Relaciona com `cnpj`
-    `configuracao_recebedores` - Armazena configuração (pode ter "DINAMICO")

### Serviços:

-    `RepasseCalculatorService.resolverIdentificadorDinamico()`
-    `RepasseCalculatorService.calcularRepasseComMultiplosRecebedores()`
-    `CobrancaIntegracaoService.gerarSolicitacao()`

### Documentos:

-    `GUIA_COMPLETO_MULTIPLOS_RECEBEDORES.md`
-    `IMPLEMENTACAO_COMPLETA_MULTIPLOS_RECEBEDORES.md`

---

**Data:** 13 de Janeiro de 2025  
**Autor:** Gabriel M. Guimarães | gabrielmg7  
**Versão:** 1.0  
**Status:** ✅ Esclarecimento Oficial
