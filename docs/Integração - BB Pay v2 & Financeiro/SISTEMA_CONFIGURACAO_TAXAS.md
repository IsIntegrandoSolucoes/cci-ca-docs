# 🏦 Sistema de Configuração de Taxas - CCI-CA API v2.0 (Simplificado)

**Versão:** 2.0 - Sistema Simplificado  
**Data:** 13 de outubro de 2025  
**Status:** ✅ Produção

> ⚠️ **IMPORTANTE:** Este sistema foi simplificado. Configurações são feitas **APENAS por modalidade**.  
> O sistema de configuração por participante/professor foi removido para reduzir complexidade.

## 📊 Modalidades Mapeadas

| ID  | Modalidade       | Código | Taxa PIX Padrão | Taxa Boleto Padrão | Tipo Pagamento |
| --- | ---------------- | ------ | --------------- | ------------------ | -------------- |
| 1   | Aula Particular  | CA-AP  | 85% / 15%       | 90% / 10%          | Sob Demanda    |
| 2   | Aula em Grupo    | CA-AG  | 80% / 20%       | 85% / 15%          | Sob Demanda    |
| 3   | Pré-Prova        | CA-PP  | 75% / 25%       | 80% / 20%          | Sob Demanda    |
| 6   | Contrato Mensal  | CA-CT  | 90% / 10%       | 95% / 5%           | Mensalidade    |
| 7   | Turma Vestibular | CA-TV  | 90% / 10%       | 95% / 5%           | Mensalidade    |
| 8   | Turma Mentoria   | CA-TM  | 85% / 15%       | 90% / 10%          | Mensalidade    |

**Legenda de Códigos de Conciliação:**

-    **CA-AP**: Aulas Particulares → `agendamentos_alunos` / `agendamentos_professores`
-    **CA-AG**: Aulas em Grupo → `agendamentos_alunos` / `agendamentos_professores`
-    **CA-PP**: Cursos Pré-Prova → `agendamentos_alunos` / `agendamentos_professores`
-    **CA-CT**: Contratos Mensais → `contrato_ano_pessoa` / `alunos_contrato_turmas`
-    **CA-TV**: Turmas Vestibular → `contrato_ano_pessoa` / `alunos_contrato_turmas`
-    **CA-TM**: Turmas Mentoria → `contrato_ano_pessoa` / `alunos_contrato_turmas`o Geral

O sistema de configuração de taxas foi migrado de **configurações hardcoded** para um **sistema flexível baseado em banco de dados** que permite:

-    ✅ **Configurações por modalidade** (configuracao_taxas_modalidade)
-    ✅ **API de gerenciamento** para interfaces administrativas
-    ✅ **Cálculo automático de repasses** baseado em configurações ativas
-    ✅ **Sistema simplificado** - Todos os professores da mesma modalidade recebem a mesma taxa

---

## 🗃️ Estrutura de Dados

### Tabela: `configuracao_taxas_modalidade`

Configurações padrão por modalidade de ensino:

```sql
CREATE TABLE configuracao_taxas_modalidade (
    id SERIAL PRIMARY KEY,
    modalidade_id INTEGER NOT NULL,
    taxa_recebedor_pix DECIMAL(5,4) NOT NULL,
    taxa_plataforma_pix DECIMAL(5,4) NOT NULL,
    taxa_recebedor_conta DECIMAL(5,4) NOT NULL,
    taxa_plataforma_conta DECIMAL(5,4) NOT NULL,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔍 Modalidades Mapeadas

| ID  | Modalidade       | Taxa PIX Padrão | Taxa Conta Padrão |
| --- | ---------------- | --------------- | ----------------- |
| 1   | Aula Particular  | 85% / 15%       | 90% / 10%         |
| 2   | Aula em Grupo    | 80% / 20%       | 85% / 15%         |
| 3   | Curso Pré-Prova  | 75% / 25%       | 80% / 20%         |
| 4   | Contrato Mensal  | 90% / 10%       | 95% / 5%          |
| 5   | Turma Vestibular | 90% / 10%       | 95% / 5%          |
| 6   | Turma Mentoria   | 85% / 15%       | 90% / 10%         |

---

---

## 🚀 API Endpoints (v2.0 - Simplificado)

### 📋 Configurações por Modalidade

```http
# Listar todas as configurações por modalidade
GET /api/configuracao-taxas/modalidades

# Atualizar configuração de uma modalidade
PUT /api/configuracao-taxas/modalidade/:id
Content-Type: application/json
{
  "pix_tipo": "Percentual",
  "pix_valor": 85,
  "boleto_tipo": "Percentual",
  "boleto_valor": 90
}
```

### � Relatórios de Repasse

```http
# Buscar relatórios de repasse com filtros
GET /api/relatorios/repasses?dataInicio=2025-01-01&dataFim=2025-12-31

# Buscar estatísticas de repasse
GET /api/relatorios/repasses/estatisticas?modalidadeId=1
```

---

### Regras de Cálculo - ATUALIZADAS

**Valor Fixo:**

-    Participante recebe **exatamente** o valor configurado
-    Convênio recebe o **resto** (valorTotal - valorParticipante)
-    `tipoValorRepasse: 'Fixo'`

**Valor Percentual:**

-    Participante recebe o **percentual configurado**
-    Convênio recebe o **percentual complementar** (100% - participante%)
-    **Total sempre = 100%**
-    `tipoValorRepasse: 'Percentual'`

---

## 🎯 Casos de Uso

### 🏫 Administração Geral

-    Definir taxas por modalidade de ensino
-    Configurar taxas diferenciadas para PIX vs BOLETO
-    Gerenciar taxas de repasse da plataforma
-    Garantir política uniforme por modalidade

### 💰 Cálculo de Repasses

-    Calcular automaticamente valor do professor e da plataforma
-    Aplicar configuração da modalidade
-    Garantir transparência e consistência nos cálculos financeiros
-    Todos os professores da mesma modalidade recebem a mesma taxa

---

## 🔧 Migração Realizada

### ❌ Antes (Hardcoded)

```typescript
const CONFIGURACOES_TAXA_POR_MODALIDADE = {
  1: { taxa_recebedor_pix: 0.85, taxa_plataforma_pix: 0.15, ... },
  2: { taxa_recebedor_pix: 0.80, taxa_plataforma_pix: 0.20, ... },
  // ...
};
```

### ✅ Depois (Database)

```typescript
// Consulta dinâmica com priorização
async buscarConfiguracaoTaxa(professorId: number, modalidadeId: number) {
  const { data } = await supabase.rpc('buscar_configuracao_taxa', {
    p_professor_id: professorId,
    p_modalidade_id: modalidadeId
  });
  return data[0];
}
```

---

## 🧪 Teste do Sistema

Execute o teste de integração:

```bash
cd cci-ca-api
npx ts-node tests/teste-configuracao-taxas.ts
```

O teste verifica:

-    ✅ Busca de configurações padrão
-    ✅ Busca de configurações específicas
-    ✅ Cálculo de repasse com novas configurações

---

## 📈 Vantagens do Sistema v2.0 Simplificado

| Aspecto           | Antes (v1.0)           | Depois (v2.0)              |
| ----------------- | ---------------------- | -------------------------- |
| **Flexibilidade** | ❌ Hardcoded           | ✅ Configurável via admin  |
| **Complexidade**  | ❌ 2 tabelas + função  | ✅ 1 tabela simples        |
| **Manutenção**    | ❌ Redeploy necessário | ✅ Alteração em tempo real |
| **Consistência**  | ❌ Taxas divergentes   | ✅ Política uniforme       |
| **Performance**   | ❌ Queries complexas   | ✅ Busca direta rápida     |

---

**🎓 Sistema implementado para CCI-CA API - Versão 2.0**
