# 🔍 Análise: Turmas 9, 11 e 12 com Chave Estrangeira para CNPJ

## 📊 Situação Atual

As turmas **9 (Revisão FPS)**, **11 (turma teste 1)** e **12 (Química Rev Particulares)** estão vinculadas ao CNPJ da empresa **IS-INTEGRANDO SOLUÇÕES LTDA** através da coluna `fk_id_cnpj`.

### Dados do CNPJ

```
CNPJ ID: 1
Descrição: 17.721.034/0001-78
Nome Empresa: IS-INTEGRANDO SOLUCOES LTDA
Pessoa: Gustavo Holanda (ID: 1)
Conta Bancária ID: 1
Número Participante: 19
Chave PIX: 17721034000178
Conta: 33448-5
Agência: 0001
```

## ⚠️ O QUE ESTÁ FALTANDO

### 1. **Configuração do Recebedor "Convênio"**

Todas as modalidades estão configuradas com:

-    **Recebedor 1**: Convênio (identificador: 125530) - 10% a 25%
-    **Recebedor 2**: Participante DINAMICO - 75% a 90%

❌ **PROBLEMA**: O identificador do convênio é **125530**, mas deveria ser **19** (número do participante do CNPJ da turma).

### 2. **Inconsistência entre Turmas e Configuração de Taxas**

As turmas estão vinculadas ao CNPJ, mas as configurações de taxas **não estão usando o número de participante correto** do CNPJ dessas turmas.

### 3. **Fluxo Esperado vs Fluxo Atual**

#### ✅ Fluxo Esperado:

```
Turma 9/11/12 → fk_id_cnpj = 1
             ↓
CNPJ 1 → fk_id_conta_bancaria = 1
       ↓
Conta Bancária 1 → numero_participante = "19"
                 ↓
Configuração de Recebedores → identificador_recebedor = "19"
```

#### ❌ Fluxo Atual:

```
Turma 9/11/12 → fk_id_cnpj = 1 ✅
             ↓
CNPJ 1 → numero_participante = "19" ✅
       ↓
Configuração de Recebedores → identificador_recebedor = "125530" ❌ ERRADO!
```

## 🔧 SOLUÇÃO

### Opção 1: Corrigir Configurações Existentes (RECOMENDADO)

Atualizar todas as configurações de recebedores tipo "Convênio" para usar o número de participante correto:

```sql
-- Atualizar recebedores tipo Convênio para usar o número participante do CNPJ
UPDATE configuracao_recebedores
SET identificador_recebedor = '19'  -- número do participante do CNPJ
WHERE tipo_recebedor = 'Convenio'
  AND identificador_recebedor = '125530'
  AND ativo = true;
```

### Opção 2: Criar Nova Configuração

Se quiser manter as configurações antigas, desative-as e crie novas:

```sql
-- 1. Desativar configurações antigas
UPDATE configuracao_taxas_modalidade
SET ativo = false
WHERE id IN (7, 8, 9, 10, 11, 12);  -- IDs das configs atuais

-- 2. Criar novas configurações com o número participante correto
-- Exemplo para Aula Particular (modalidade 1):
INSERT INTO configuracao_taxas_modalidade (fk_id_modalidade_aula, ativo)
VALUES (1, true)
RETURNING id;  -- Usar este ID para o próximo INSERT

-- 3. Criar recebedores com o número correto
INSERT INTO configuracao_recebedores (
    fk_id_configuracao_modalidade,
    tipo_recebedor,
    identificador_recebedor,
    percentual,
    ordem,
    ativo
) VALUES
-- Convênio (IS-INTEGRANDO)
(<ID_DA_CONFIG>, 'Convenio', '19', 15.00, 1, true),
-- Professor dinâmico
(<ID_DA_CONFIG>, 'Participante', 'DINAMICO', 85.00, 2, true);
```

## 📋 CHECKLIST DE CORREÇÃO

-    [ ] Verificar qual número de participante correto usar (19 ou 125530)
-    [ ] Decidir entre Opção 1 (corrigir) ou Opção 2 (criar novo)
-    [ ] Atualizar configurações de recebedores
-    [ ] Testar pagamentos para essas modalidades
-    [ ] Verificar se split está sendo feito corretamente
-    [ ] Validar relatórios de repasse

## 🎯 IMPACTO

### Sem Correção:

-    ❌ Pagamentos podem ser enviados para número de participante errado
-    ❌ Empresa IS-INTEGRANDO pode não receber sua parte
-    ❌ Conciliação bancária ficará incorreta

### Com Correção:

-    ✅ Pagamentos corretos para convênio (número 19)
-    ✅ Pagamentos corretos para professores (dinâmico)
-    ✅ Conciliação bancária funcionando
-    ✅ Relatórios de repasse corretos

## 🔍 COMO VERIFICAR SE ESTÁ CORRETO

```sql
-- Query para validar configuração
SELECT
    ma.nome AS modalidade,
    t.descricao AS turma,
    c.nome_empresa,
    cb.numero_participante AS num_participante_cnpj,
    cr.tipo_recebedor,
    cr.identificador_recebedor,
    cr.percentual,
    CASE
        WHEN cr.tipo_recebedor = 'Convenio'
             AND cr.identificador_recebedor = cb.numero_participante
        THEN '✅ OK'
        WHEN cr.tipo_recebedor = 'Convenio'
             AND cr.identificador_recebedor != cb.numero_participante
        THEN '❌ ERRADO'
        ELSE '⚠️ VERIFICAR'
    END AS status
FROM modalidade_aula ma
INNER JOIN configuracao_taxas_modalidade ctm ON ma.id = ctm.fk_id_modalidade_aula
INNER JOIN configuracao_recebedores cr ON ctm.id = cr.fk_id_configuracao_modalidade
INNER JOIN agendamentos_professores ap ON ma.id = ap.fk_id_modalidade_aula
INNER JOIN turmas t ON t.id IN (9, 11, 12)
INNER JOIN cnpj c ON t.fk_id_cnpj = c.id
INNER JOIN conta_bancaria cb ON c.fk_id_conta_bancaria = cb.id
WHERE ctm.ativo = true
  AND cr.ativo = true
ORDER BY ma.id, cr.ordem;
```

## 📝 NOTAS IMPORTANTES

1. **Número de Participante 125530**: Pode ser um número antigo ou de teste
2. **Número de Participante 19**: É o número atual vinculado ao CNPJ no banco
3. **Todas as turmas 9, 11, 12**: Compartilham o mesmo CNPJ (ID: 1)
4. **Modalidades configuradas**: 6 de 8 têm configuração ativa

## ⏭️ PRÓXIMOS PASSOS

1. **Confirmar com o cliente**: Qual número participante usar (19 ou 125530)?
2. **Backup**: Fazer backup das configurações atuais
3. **Executar correção**: Usar Opção 1 ou 2 conforme decisão
4. **Testar**: Criar agendamento de teste e verificar split
5. **Monitorar**: Acompanhar primeiros pagamentos após correção

---

**Última atualização**: 13/01/2025 **Status**: ⚠️ AGUARDANDO DECISÃO
