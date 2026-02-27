# 🔄 Sistema de Repasses: Convênio vs Professor

## 📊 Fluxo Correto de Repasses

### 🏢 Convênio (Empresa)

```
Tipo: "Convenio"
Identificador: 125530 (fixo)
Destino: Conta corrente do CNPJ (IS-INTEGRANDO SOLUÇÕES)
Percentual: 10% a 25% (conforme modalidade)
```

### 👨‍🏫 Professor (Dinâmico)

```
Tipo: "Participante"
Identificador: DINAMICO (buscar do agendamento)
Destino: Conta bancária do professor específico da aula
Percentual: 75% a 90% (conforme modalidade)
```

---

## 🎯 Entendendo o Sistema

### CNPJ da Empresa

```
CNPJ: 17.721.034/0001-78
Empresa: IS-INTEGRANDO SOLUÇÕES LTDA
Pessoa: Gustavo Holanda (ID: 1)
Número Participante (identificação): 19
Número Convênio (recebimento): 125530 ← USAR ESTE!
```

### Turmas Vinculadas ao CNPJ

-    Turma 9: Revisão FPS
-    Turma 11: turma teste 1
-    Turma 12: Química Rev Particulares

---

## 🔧 Lógica de Repasse na API

### 1. Ao Criar Solicitação de Pagamento

```typescript
// Buscar configuração de recebedores da modalidade
const { data: recebedores } = await supabase
     .from('configuracao_recebedores')
     .select(
          `
    *,
    configuracao_taxas_modalidade!inner(
      fk_id_modalidade_aula
    )
  `,
     )
     .eq('configuracao_taxas_modalidade.fk_id_modalidade_aula', modalidadeId)
     .eq('ativo', true)
     .order('ordem');

// Processar cada recebedor
const splits = recebedores.map((rec) => {
     let numeroParticipante: string;

     if (rec.tipo_recebedor === 'Convenio') {
          // Convênio: usar identificador fixo cadastrado
          numeroParticipante = rec.identificador_recebedor; // Ex: "125530"
     } else if (rec.tipo_recebedor === 'Participante' && rec.identificador_recebedor === 'DINAMICO') {
          // Professor: buscar do agendamento
          numeroParticipante = agendamento.professor_numero_participante;
     } else {
          // Participante fixo: usar identificador cadastrado
          numeroParticipante = rec.identificador_recebedor;
     }

     return {
          numeroParticipante,
          percentual: rec.percentual,
          ordem: rec.ordem,
     };
});
```

### 2. Estrutura do Split para BB

```json
{
     "numeroConvenio": "3128651",
     "participantes": [
          {
               "numeroParticipante": "125530",
               "percentualParticipacao": 15.0
          },
          {
               "numeroParticipante": "54321",
               "percentualParticipacao": 85.0
          }
     ]
}
```

---

## 📝 Exemplo Prático

### Cenário: Aula Particular com Professor João

**Dados:**

-    Modalidade: Aula Particular (ID: 1)
-    Professor: João Silva (número participante: 54321)
-    Valor: R$ 100,00
-    Turma: 12 (Química Rev Particulares) → CNPJ ID: 1

**Configuração de Recebedores:**

1. Convênio (ordem 1): 125530 → 15%
2. Participante DINAMICO (ordem 2): Professor da aula → 85%

**Splits Gerados:**

```json
{
     "participantes": [
          {
               "numeroParticipante": "125530",
               "percentualParticipacao": 15.0,
               "valorParticipacao": 15.0
          },
          {
               "numeroParticipante": "54321",
               "percentualParticipacao": 85.0,
               "valorParticipacao": 85.0
          }
     ]
}
```

**Resultado:**

-    ✅ R$ 15,00 → Conta do CNPJ (convênio 125530)
-    ✅ R$ 85,00 → Conta do Professor João (participante 54321)

---

## 🗄️ Estrutura no Banco de Dados

### Tabela: `configuracao_recebedores`

```sql
id | tipo_recebedor | identificador_recebedor | percentual | ordem
---|----------------|-------------------------|------------|------
1  | Convenio       | 125530                 | 15.00      | 1
2  | Participante   | DINAMICO               | 85.00      | 2
```

### Interpretação:

-    **Linha 1**: Convênio fixo (sempre 125530)
-    **Linha 2**: Professor dinâmico (buscar do agendamento)

---

## 🔍 Queries Necessárias

### 1. Buscar Número do Professor da Aula

```sql
SELECT
    p.nome,
    p.sobrenome,
    cb.numero_participante
FROM agendamentos_professores ap
INNER JOIN pessoas p ON ap.fk_id_professor = p.id
INNER JOIN conta_bancaria cb ON p.id = cb.fk_id_pessoa
WHERE ap.id = :agendamento_id
  AND cb.deleted_at IS NULL
  AND p.deleted_at IS NULL;
```

### 2. Buscar Configuração de Recebedores

```sql
SELECT
    cr.tipo_recebedor,
    cr.identificador_recebedor,
    cr.percentual,
    cr.ordem
FROM configuracao_recebedores cr
INNER JOIN configuracao_taxas_modalidade ctm
    ON cr.fk_id_configuracao_modalidade = ctm.id
WHERE ctm.fk_id_modalidade_aula = :modalidade_id
  AND ctm.ativo = true
  AND cr.ativo = true
ORDER BY cr.ordem;
```

---

## 🚀 Implementação na API

### Endpoint: `POST /solicitacoes/solicitar`

**Fluxo:**

1. **Receber dados do agendamento**

     ```typescript
     const { agendamentoId, valorTotal } = req.body;
     ```

2. **Buscar agendamento com professor**

     ```typescript
     const { data: agendamento } = await supabase
          .from('agendamentos_professores')
          .select(
               `
         *,
         pessoas!fk_id_professor(
           id,
           nome,
           conta_bancaria(numero_participante)
         )
       `,
          )
          .eq('id', agendamentoId)
          .single();
     ```

3. **Buscar configuração de recebedores**

     ```typescript
     const { data: recebedores } = await supabase
          .from('configuracao_recebedores')
          .select(
               `
         *,
         configuracao_taxas_modalidade!inner(
           fk_id_modalidade_aula
         )
       `,
          )
          .eq('configuracao_taxas_modalidade.fk_id_modalidade_aula', agendamento.fk_id_modalidade_aula)
          .eq('ativo', true)
          .order('ordem');
     ```

4. **Gerar splits**

     ```typescript
     const splits = recebedores.map((rec) => {
          let numeroParticipante: string;

          if (rec.tipo_recebedor === 'Convenio') {
               numeroParticipante = rec.identificador_recebedor;
          } else if (rec.identificador_recebedor === 'DINAMICO') {
               numeroParticipante = agendamento.pessoas.conta_bancaria[0].numero_participante;
          } else {
               numeroParticipante = rec.identificador_recebedor;
          }

          return {
               numeroParticipante,
               percentualParticipacao: parseFloat(rec.percentual),
          };
     });
     ```

5. **Enviar para Banco do Brasil**
     ```typescript
     const payload = {
          numeroConvenio: process.env.BB_NUMERO_CONVENIO,
          valorOriginal: valorTotal,
          participantes: splits,
     };
     ```

---

## ✅ Validações Necessárias

### 1. Validar Professor tem Conta Bancária

```typescript
if (rec.identificador_recebedor === 'DINAMICO') {
     if (!agendamento.pessoas?.conta_bancaria?.[0]?.numero_participante) {
          throw new Error('Professor não possui conta bancária configurada');
     }
}
```

### 2. Validar Soma dos Percentuais = 100%

```typescript
const somaPercentuais = recebedores.reduce((acc, rec) => acc + parseFloat(rec.percentual), 0);
if (Math.abs(somaPercentuais - 100) > 0.01) {
     throw new Error(`Soma dos percentuais deve ser 100%. Atual: ${somaPercentuais}%`);
}
```

### 3. Validar Número de Participante Válido

```typescript
if (!numeroParticipante || numeroParticipante === 'DINAMICO') {
     throw new Error('Número de participante inválido para split');
}
```

---

## 📊 Casos de Uso

### Caso 1: Aula Particular (2 recebedores)

```
Convênio: 125530 (15%) → R$ 15,00
Professor: 54321 (85%) → R$ 85,00
Total: R$ 100,00 ✅
```

### Caso 2: Aula em Grupo (2 recebedores)

```
Convênio: 125530 (20%) → R$ 20,00
Professor: 54321 (80%) → R$ 80,00
Total: R$ 100,00 ✅
```

### Caso 3: Contrato Mensal (2 recebedores)

```
Convênio: 125530 (10%) → R$ 50,00
Professor: 54321 (90%) → R$ 450,00
Total: R$ 500,00 ✅
```

---

## 🐛 Troubleshooting

### Erro: "Professor não possui conta bancária"

**Causa**: Professor não tem registro em `conta_bancaria`  
**Solução**: Cadastrar conta bancária do professor com `numero_participante`

### Erro: "Soma de percentuais diferente de 100%"

**Causa**: Configuração incorreta dos recebedores  
**Solução**: Ajustar percentuais para somar exatamente 100%

### Erro: "Número de participante DINAMICO no split"

**Causa**: DINAMICO não foi substituído pelo número real  
**Solução**: Verificar lógica de busca do número do professor

---

## 📈 Próximos Passos

1. ✅ Criar endpoint `POST /api/solicitacoes/solicitar` atualizado
2. ✅ Implementar lógica de substituição do DINAMICO
3. ✅ Adicionar validações de percentuais
4. ✅ Implementar testes unitários
5. ✅ Documentar exemplos de uso
6. ✅ Criar logs para auditoria de splits

---

**Última atualização**: 13/01/2025  
**Status**: ✅ FLUXO CORRETO DOCUMENTADO
