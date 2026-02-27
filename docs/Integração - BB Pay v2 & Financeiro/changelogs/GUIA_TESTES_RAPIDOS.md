# 🧪 Guia Rápido de Testes - Sistema de Múltiplos Recebedores

**Status**: ✅ Migration executada com sucesso  
**Próximo Passo**: Testar endpoints da API

---

## 🚀 Como Testar

### **Pré-requisito**: API rodando

```bash
# No terminal, na pasta cci-ca-api
npm run dev

# Deve estar rodando em http://localhost:3002
```

---

## 1️⃣ Teste Básico - Listar Recebedores

### **GET**: Listar recebedores da Aula Particular

```bash
GET http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1
```

**Usando cURL:**

```bash
curl -X GET http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1
```

**Usando PowerShell:**

```powershell
Invoke-RestMethod -Uri "http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1" -Method Get
```

**Resposta Esperada:**

```json
{
     "success": true,
     "data": [
          {
               "id": 1,
               "tipo_recebedor": "Convenio",
               "identificador_recebedor": "125530",
               "percentual": "15.00",
               "ordem": 1
          },
          {
               "id": 2,
               "tipo_recebedor": "Participante",
               "identificador_recebedor": "DINAMICO",
               "percentual": "85.00",
               "ordem": 2
          }
     ]
}
```

---

## 2️⃣ Teste Intermediário - Atualizar Recebedores

### **PUT**: Adicionar um terceiro professor

```bash
PUT http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1
Content-Type: application/json

{
  "recebedores": [
    {
      "tipo_recebedor": "Convenio",
      "identificador_recebedor": "125530",
      "percentual": 20,
      "ordem": 1
    },
    {
      "tipo_recebedor": "Participante",
      "identificador_recebedor": "DINAMICO",
      "percentual": 60,
      "ordem": 2
    },
    {
      "tipo_recebedor": "Participante",
      "identificador_recebedor": "456",
      "percentual": 20,
      "ordem": 3
    }
  ]
}
```

**Usando cURL:**

```bash
curl -X PUT http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1 \
  -H "Content-Type: application/json" \
  -d '{
    "recebedores": [
      {"tipo_recebedor": "Convenio", "identificador_recebedor": "125530", "percentual": 20, "ordem": 1},
      {"tipo_recebedor": "Participante", "identificador_recebedor": "DINAMICO", "percentual": 60, "ordem": 2},
      {"tipo_recebedor": "Participante", "identificador_recebedor": "456", "percentual": 20, "ordem": 3}
    ]
  }'
```

**Usando PowerShell:**

```powershell
$body = @{
    recebedores = @(
        @{tipo_recebedor="Convenio"; identificador_recebedor="125530"; percentual=20; ordem=1},
        @{tipo_recebedor="Participante"; identificador_recebedor="DINAMICO"; percentual=60; ordem=2},
        @{tipo_recebedor="Participante"; identificador_recebedor="456"; percentual=20; ordem=3}
    )
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1" -Method Put -Body $body -ContentType "application/json"
```

**Resposta Esperada:**

```json
{
     "success": true,
     "message": "Recebedores atualizados com sucesso"
}
```

### **Verificar mudança:**

```bash
GET http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1
```

**Agora deve retornar 3 recebedores!**

---

## 3️⃣ Teste de Validação - Soma > 100% (Deve Falhar)

### **PUT**: Tentar criar configuração inválida

```bash
PUT http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1
Content-Type: application/json

{
  "recebedores": [
    {
      "tipo_recebedor": "Convenio",
      "identificador_recebedor": "125530",
      "percentual": 50,
      "ordem": 1
    },
    {
      "tipo_recebedor": "Participante",
      "identificador_recebedor": "DINAMICO",
      "percentual": 60,
      "ordem": 2
    }
  ]
}
```

**Resposta Esperada (ERRO):**

```json
{
     "success": false,
     "error": "Erro ao atualizar recebedores",
     "message": "A soma dos percentuais deve ser exatamente 100%. Soma atual: 110%"
}
```

✅ **Se recebeu esse erro, a validação está funcionando!**

---

## 4️⃣ Teste Avançado - Remover Recebedor

### **DELETE**: Remover um recebedor específico

Primeiro, pegue o ID de um recebedor:

```bash
GET http://localhost:3002/api/configuracao-taxas/recebedores/modalidade/1
```

Depois, remova (exemplo com ID 3):

```bash
DELETE http://localhost:3002/api/configuracao-taxas/recebedores/3
```

**Usando cURL:**

```bash
curl -X DELETE http://localhost:3002/api/configuracao-taxas/recebedores/3
```

**Resposta Esperada:**

```json
{
     "success": true,
     "message": "Recebedor removido com sucesso"
}
```

---

## 5️⃣ Teste de Integração - Criar Cobrança

### **Verificar como o RepasseCalculatorService está funcionando**

Crie um arquivo de teste temporário:

```typescript
// test-repasse.ts
import { RepasseCalculatorService } from './src/services/RepasseCalculatorService';

async function testar() {
     const calculator = new RepasseCalculatorService(125530);

     const repasse = await calculator.calcularRepasseComMultiplosRecebedores({
          valorTotal: 150.0,
          tipoPagamento: 'PIX',
          modalidade: 'AULA_PARTICULAR',
          identificadorParticipante: '789',
          numeroConvenio: 125530,
          isVencido: false,
     });

     console.log('Repasse calculado:');
     console.log(JSON.stringify(repasse, null, 2));
}

testar();
```

**Executar:**

```bash
npx ts-node test-repasse.ts
```

**Resultado Esperado:**

```json
{
     "tipoValorRepasse": "Percentual",
     "recebedores": [
          {
               "identificadorRecebedor": "125530",
               "tipoRecebedor": "Convenio",
               "valorRepasse": 20
          },
          {
               "identificadorRecebedor": "789",
               "tipoRecebedor": "Participante",
               "valorRepasse": 60
          },
          {
               "identificadorRecebedor": "456",
               "tipoRecebedor": "Participante",
               "valorRepasse": 20
          }
     ]
}
```

---

## 📊 Todas as Modalidades Disponíveis

| ID  | Modalidade       | Percentual Atual             |
| --- | ---------------- | ---------------------------- |
| 1   | Aula Particular  | Convênio 15% + Professor 85% |
| 2   | Aula em Grupo    | Convênio 20% + Professor 80% |
| 3   | Pré-Prova        | Convênio 25% + Professor 75% |
| 6   | Contrato         | Convênio 10% + Professor 90% |
| 7   | Turma Vestibular | Convênio 10% + Professor 90% |
| 8   | Turma Mentoria   | Convênio 15% + Professor 85% |

**Você pode testar qualquer uma dessas!**

---

## 🔍 Verificação no Banco de Dados

### **Consulta SQL direta no Supabase:**

```sql
-- Ver todos os recebedores
SELECT
  ma.nome as modalidade,
  r.tipo_recebedor,
  r.identificador_recebedor,
  r.percentual,
  r.ordem
FROM configuracao_recebedores r
JOIN configuracao_taxas_modalidade ctm ON ctm.id = r.fk_id_configuracao_modalidade
JOIN modalidade_aula ma ON ma.id = ctm.fk_id_modalidade_aula
WHERE r.deleted_at IS NULL
ORDER BY ma.nome, r.ordem;
```

---

## ✅ Checklist de Testes

-    [ ] **Teste 1**: Listar recebedores (GET)
-    [ ] **Teste 2**: Atualizar recebedores (PUT) - adicionar terceiro
-    [ ] **Teste 3**: Validação (PUT) - soma > 100% deve falhar
-    [ ] **Teste 4**: Remover recebedor (DELETE)
-    [ ] **Teste 5**: Calcular repasse com múltiplos recebedores
-    [ ] **Teste 6**: Verificar no banco de dados

---

## 🚨 Troubleshooting

### **Erro: Connection refused**

```
Certifique-se de que a API está rodando:
cd cci-ca-api
npm run dev
```

### **Erro: 404 Not Found**

```
Verifique se as rotas estão registradas em:
src/routes/configuracaoTaxasRoutes.ts
```

### **Erro: Soma dos percentuais...**

```
✅ ESTÁ FUNCIONANDO! A validação está ativa.
Ajuste os percentuais para somar exatamente 100%.
```

---

## 🎯 Próximo Passo Após Testes

Uma vez que todos os testes passarem, atualizar o `CobrancaIntegracaoService.ts`:

```typescript
// Localização: src/services/CobrancaIntegracaoService.ts

// Substituir código hardcoded por:
const repasse = await this.repasseCalculator.calcularRepasseComMultiplosRecebedores({
     valorTotal: parcela.valor,
     tipoPagamento: tipoPagamento,
     modalidade: modalidade,
     identificadorParticipante: numeroParticipante,
     numeroConvenio: 125530,
});

// Usar no payload:
repasse: repasse;
```

---

**Boa sorte nos testes! 🚀**

Se algum teste falhar, verifique os logs do servidor e o console do terminal.
