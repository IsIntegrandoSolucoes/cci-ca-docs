# 🧪 Guia de Testes - Sistema de Splits Dinâmicos

## ✅ Implementação Completa

### Arquivos Modificados/Criados:

1. **src/types/configuracaoRecebedores.ts** (NOVO)

     - Interface `IConfiguracaoRecebedor`
     - Interface `ISplitProcessado`

2. **src/types/ISolicitacaoCobranca.ts** (MODIFICADO)

     - Adicionado `fk_id_agendamento_professor?: number`
     - Adicionado `fk_id_contrato_ano_pessoa?: number`

3. **src/entity/Solicitacoes/solicitacoesService.ts** (MODIFICADO)
     - Adicionado import de tipos
     - Adicionado método `buscarRecebedoresPorModalidade()`
     - Adicionado método `buscarNumeroProfessor()`
     - Adicionado método `processarSplits()`
     - Modificado `criarSolicitacao()` para processar splits dinâmicos

---

## 🎯 Cenários de Teste

### Cenário 1: Aula Particular com Split Convênio + Professor

**Setup:**

-    Professor ID: 1 (João Silva)
-    Número participante professor: "54321"
-    Modalidade: Aula Particular (ID: 1)
-    Configuração:
     -    Convênio 125530: 15%
     -    Professor DINAMICO: 85%

**Request:**

```json
POST http://localhost:3002/api/solicitacoes/solicitar

{
  "sistemaOrigemId": 7,
  "geral": {
    "numeroConvenio": 125530,
    "timestampLimiteSolicitacao": "2025-10-20T23:59:59Z",
    "pagamentoUnico": true,
    "valorSolicitacao": 100.00,
    "descricaoSolicitacao": "Aula Particular - Matemática",
    "codigoConciliacaoSolicitacao": "CA-AG-123",
    "urlCallback": "https://cci-ca-api.netlify.app/api/webhooks/pagamentos"
  },
  "devedor": {
    "tipoDocumento": 1,
    "numeroDocumento": "12345678900",
    "email": "aluno@example.com"
  },
  "vencimento": {
    "data": "2025-10-20",
    "multaPercentual": 0,
    "jurosPercentual": 0
  },
  "formasPagamento": [
    {
      "codigoTipoPagamento": "PIX"
    }
  ],
  "fk_id_agendamento_professor": 123
}
```

**Expected Response:**

```json
{
     "success": true,
     "data": {
          "numeroSolicitacao": 789456123,
          "urlSolicitacao": "https://cobranca.bb.com.br/...",
          "informacoesPIX": {
               "txId": "xxx",
               "textoQrCode": "00020126580014..."
          }
     }
}
```

**Expected Logs:**

```
[SolicitacoesService]: Agendamento encontrado para splits
  agendamentoId: 123
  professorId: 1
  modalidadeId: 1

[SolicitacoesService]: Buscando recebedores da modalidade
  modalidadeId: 1

[SolicitacoesService]: Recebedores encontrados
  modalidadeId: 1
  quantidade: 2
  recebedores: [
    { tipo: 'Convenio', identificador: '125530', percentual: '15.00' },
    { tipo: 'Participante', identificador: 'DINAMICO', percentual: '85.00' }
  ]

[SolicitacoesService]: Split Convênio
  identificador: '125530'
  percentual: '15.00'
  tipo: 'Convenio'

[SolicitacoesService]: Buscando número do professor
  professorId: 1

[SolicitacoesService]: Número do professor encontrado
  professorId: 1
  nome: 'João Silva'
  numeroParticipante: '54321'

[SolicitacoesService]: Split Professor Dinâmico
  professorId: 1
  identificador: '54321'
  percentual: '85.00'
  tipo: 'Participante DINAMICO'

[SolicitacoesService]: Splits processados com sucesso
  splits: [
    { identificador: '125530', tipo: 'Convenio', percentual: 15 },
    { identificador: '54321', tipo: 'Participante', percentual: 85 }
  ]

[SolicitacoesService]: Splits dinâmicos aplicados
  agendamentoId: 123
  splits: [...]
```

**Payload Enviado ao Banco do Brasil:**

```json
{
  "geral": {
    "numeroConvenio": 125530,
    "valorSolicitacao": 100.00,
    ...
  },
  "repasse": {
    "tipoValorRepasse": "Percentual",
    "recebedores": [
      {
        "identificadorRecebedor": "125530",
        "tipoRecebedor": "Convenio",
        "valorRepasse": 15,
        "ordem": 1
      },
      {
        "identificadorRecebedor": "54321",
        "tipoRecebedor": "Participante",
        "valorRepasse": 85,
        "ordem": 2
      }
    ]
  }
}
```

---

### Cenário 2: Aula em Grupo com Split 20% / 80%

**Setup:**

-    Professor ID: 2 (Maria Santos)
-    Número participante: "98765"
-    Modalidade: Aula em Grupo (ID: 2)
-    Configuração:
     -    Convênio 125530: 20%
     -    Professor DINAMICO: 80%

**Request:**

```json
{
  "geral": {
    "valorSolicitacao": 200.00,
    "descricaoSolicitacao": "Aula em Grupo - Física",
    ...
  },
  "fk_id_agendamento_professor": 456
}
```

**Expected Split:**

-    Convênio 125530: R$ 40,00 (20%)
-    Professor 98765: R$ 160,00 (80%)

---

### Cenário 3: Erro - Professor sem Conta Bancária

**Setup:**

-    Professor ID: 99 (sem conta bancária configurada)
-    Modalidade: Aula Particular

**Request:**

```json
{
     "fk_id_agendamento_professor": 789
}
```

**Expected Error:**

```json
{
     "error": "Professor 99 não possui conta bancária configurada"
}
```

**Expected Logs:**

```
[SolicitacoesService]: Professor não encontrado ou sem conta bancária
  error: {...}
  professorId: 99

[SolicitacoesService]: Erro ao processar splits dinâmicos, usando fallback
  error: 'Professor 99 não possui conta bancária configurada'
```

**Fallback Behavior:**

-    Sistema usa repasse padrão: 100% para convênio 125530

---

### Cenário 4: Erro - Modalidade sem Configuração

**Setup:**

-    Modalidade ID: 999 (sem recebedores configurados)

**Request:**

```json
{
     "fk_id_agendamento_professor": 111
}
```

**Expected Error:**

```json
{
     "error": "Nenhum recebedor configurado para modalidade 999"
}
```

**Expected Logs:**

```
[SolicitacoesService]: Nenhum recebedor configurado
  modalidadeId: 999

[SolicitacoesService]: Erro ao processar splits dinâmicos, usando fallback
```

**Fallback Behavior:**

-    Sistema usa repasse padrão: 100% para convênio

---

### Cenário 5: Erro - Soma de Percentuais != 100%

**Setup:**

-    Configuração inválida na base:
     -    Convênio: 40%
     -    Professor: 50%
     -    Total: 90% (ERRO!)

**Expected Error:**

```json
{
     "error": "Soma dos percentuais deve ser 100%. Atual: 90.00%"
}
```

**Expected Logs:**

```
[SolicitacoesService]: Soma de percentuais inválida
  somaPercentuais: 90
  esperado: 100
```

---

### Cenário 6: Payload Legado (sem fk_id_agendamento_professor)

**Request:**

```json
{
     "descricao": "Pagamento avulso",
     "valor": 50.0,
     "tipo": "AVULSO",
     "referenceId": 123
}
```

**Expected Behavior:**

-    Sistema NÃO processa splits dinâmicos
-    Usa repasse padrão: 100% para convênio
-    Mantém compatibilidade com sistema legado

---

## 🔍 Como Testar

### 1. Teste via Insomnia/Postman

1. Importe a collection do projeto
2. Configure a URL base: `http://localhost:3002`
3. Execute os cenários acima
4. Verifique logs no terminal da API

### 2. Teste via Frontend (cci-ca-aluno)

1. Acesse o portal do aluno
2. Crie um agendamento
3. Tente fazer o pagamento
4. Verifique no terminal da API os logs de splits
5. Confirme que o QR Code PIX foi gerado

### 3. Verificar Splits na Base de Dados

```sql
-- Ver configuração de recebedores de uma modalidade
SELECT
    cr.id,
    cr.tipo_recebedor,
    cr.identificador_recebedor,
    cr.percentual,
    cr.ordem,
    ma.nome as modalidade
FROM configuracao_recebedores cr
JOIN configuracao_taxas_modalidade ctm ON cr.fk_id_configuracao_taxa = ctm.id
JOIN modalidade_aula ma ON ctm.fk_id_modalidade_aula = ma.id
WHERE ma.id = 1
  AND cr.ativo = true
  AND ctm.ativo = true
ORDER BY cr.ordem;

-- Ver número de participante de um professor
SELECT
    p.id,
    p.nome,
    p.sobrenome,
    cb.numero_participante
FROM pessoas p
JOIN conta_bancaria cb ON p.id = cb.fk_id_pessoa
WHERE p.fk_id_tipo_pessoa = 3
  AND cb.deleted_at IS NULL
  AND p.id = 1;
```

### 4. Verificar Logs da API

```bash
# Terminal onde a API está rodando
# Buscar por linhas contendo:
grep "Splits processados" logs.txt
grep "Split Convênio" logs.txt
grep "Split Professor Dinâmico" logs.txt
grep "Erro ao processar splits" logs.txt
```

---

## 📊 Checklist de Validação

-    [ ] **Splits Dinâmicos Gerados**

     -    [ ] Convênio fixo (125530) está presente
     -    [ ] Professor dinâmico foi resolvido corretamente
     -    [ ] Soma dos percentuais = 100%
     -    [ ] Ordem dos recebedores respeitada

-    [ ] **Logs Detalhados**

     -    [ ] Log de agendamento encontrado
     -    [ ] Log de recebedores buscados
     -    [ ] Log de cada split processado
     -    [ ] Log de splits aplicados

-    [ ] **Tratamento de Erros**

     -    [ ] Professor sem conta bancária → Fallback
     -    [ ] Modalidade sem configuração → Fallback
     -    [ ] Soma de percentuais inválida → Erro claro
     -    [ ] Agendamento não encontrado → Fallback

-    [ ] **Compatibilidade**

     -    [ ] Payload completo funciona
     -    [ ] Payload legado funciona
     -    [ ] Sem agendamento vinculado → 100% convênio

-    [ ] **Integração Banco do Brasil**
     -    [ ] Payload enviado está correto
     -    [ ] Repasse no formato esperado
     -    [ ] PIX gerado com sucesso
     -    [ ] QR Code retornado

---

## 🐛 Troubleshooting

### Problema: "Professor X não possui conta bancária"

**Solução:**

```sql
-- Verificar se professor tem conta bancária ativa
SELECT * FROM conta_bancaria
WHERE fk_id_pessoa = X
  AND deleted_at IS NULL;

-- Se não tiver, criar uma
INSERT INTO conta_bancaria (
    fk_id_pessoa,
    fk_id_banco,
    agencia,
    numero_conta,
    numero_participante
) VALUES (
    X,  -- ID do professor
    1,  -- Banco do Brasil
    '1234',
    '56789-0',
    '12345'  -- Número de participante único
);
```

### Problema: "Nenhum recebedor configurado"

**Solução:**

```sql
-- Verificar configuração da modalidade
SELECT * FROM configuracao_taxas_modalidade
WHERE fk_id_modalidade_aula = Y
  AND ativo = true;

SELECT * FROM configuracao_recebedores
WHERE fk_id_configuracao_taxa = Z
  AND ativo = true;

-- Se não existir, criar configuração
-- Ver script em: migrations/configuracao_recebedores_exemplo.sql
```

### Problema: "Soma dos percentuais deve ser 100%"

**Solução:**

```sql
-- Corrigir percentuais na base
UPDATE configuracao_recebedores
SET percentual = 15.00
WHERE id = A;  -- Convênio

UPDATE configuracao_recebedores
SET percentual = 85.00
WHERE id = B;  -- Professor

-- Verificar
SELECT SUM(percentual) as total
FROM configuracao_recebedores
WHERE fk_id_configuracao_taxa = Z
  AND ativo = true;
-- Deve retornar exatamente 100.00
```

---

## 📝 Próximos Passos

1. ✅ Implementação completa do sistema de splits
2. ✅ Validações e tratamento de erros
3. ✅ Logs detalhados para debugging
4. ⏳ Testes manuais com dados reais
5. ⏳ Testes end-to-end no ambiente de staging
6. ⏳ Deploy em produção
7. ⏳ Monitoramento de logs em produção
8. ⏳ Análise de performance e otimizações

---

**Última atualização**: 13/10/2025  
**Status**: ✅ IMPLEMENTADO - PRONTO PARA TESTES
