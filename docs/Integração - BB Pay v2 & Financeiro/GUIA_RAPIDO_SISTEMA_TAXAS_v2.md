# 🚀 Guia Rápido - Sistema de Taxas v2.0

## ⚡ TL;DR (Para Quem Tem Pressa)

**O que mudou?**

-    ❌ Removido: Configuração de taxas por professor/participante
-    ✅ Mantido: Configuração de taxas por modalidade de aula

**Por que mudou?**

-    Sistema mais simples (60% menos complexidade)
-    Mesma funcionalidade essencial
-    Menos bugs, mais fácil de manter

**O que eu preciso fazer?**

-    **Desenvolvedor:** Usar novos endpoints (veja abaixo)
-    **Admin Sistema:** Interface mais simples, mesma tarefa
-    **Professor:** Nada! Funciona igual para você
-    **Financeiro:** Relatórios funcionam exatamente igual

---

## 👨‍💻 Para Desenvolvedores

### Endpoints que MUDARAM

#### ❌ REMOVIDOS (não usar mais)

```typescript
// NÃO FUNCIONAM MAIS:
GET    /api/configuracao-taxas/participantes
POST   /api/configuracao-taxas/participante
PUT    /api/configuracao-taxas/participante/:id
DELETE /api/configuracao-taxas/participante/:id
GET    /api/configuracao-taxas/efetiva/:professorId/:modalidadeId
```

#### ✅ USAR AGORA

```typescript
// ENDPOINTS ATIVOS:
GET /api/configuracao-taxas/modalidades
// Retorna todas as configurações por modalidade

PUT /api/configuracao-taxas/modalidade/:id
// Atualiza configuração de uma modalidade específica
```

### Como Buscar Taxa de um Pagamento

#### ❌ ANTES (v1.0 - Complexo)

```typescript
// Buscar por professor primeiro
const configParticipante = await fetch(`/api/configuracao-taxas/efetiva/${professorId}/${modalidadeId}`);

// Se não encontrar, buscar por modalidade
if (!configParticipante) {
     const configModalidade = await fetch(`/api/configuracao-taxas/modalidades`);
}
```

#### ✅ AGORA (v2.0 - Simples)

```typescript
// Buscar DIRETO por modalidade
const config = await supabase.from('configuracao_taxas_modalidade').select('*').eq('fk_id_modalidade_aula', modalidadeId).eq('ativo', true).single();

// Calcular taxa
const taxa = pagamento.tipo_pagamento === 'PIX' ? config.pix_valor : config.boleto_valor;
```

### Tipos TypeScript Atualizados

#### ❌ REMOVIDOS

```typescript
interface IConfiguracaoTaxaParticipante { ... }
interface ICreateConfiguracaoParticipanteRequest { ... }
interface IUpdateConfiguracaoParticipanteRequest { ... }
```

#### ✅ USAR AGORA

```typescript
// Apenas estas interfaces existem:
interface IConfiguracaoTaxaModalidade {
     id: number;
     fk_id_modalidade_aula: number;
     pix_tipo: 'Percentual' | 'Fixo';
     pix_valor: number;
     boleto_tipo: 'Percentual' | 'Fixo';
     boleto_valor: number;
     ativo: boolean;
     created_at: string;
     updated_at: string;
}

interface IUpdateConfiguracaoModalidadeRequest {
     pix_tipo?: 'Percentual' | 'Fixo';
     pix_valor?: number;
     boleto_tipo?: 'Percentual' | 'Fixo';
     boleto_valor?: number;
     ativo?: boolean;
}
```

---

## 👔 Para Administradores do Sistema

### Interface Simplificada

#### Menu de Navegação

```
Financeiro
  ├── Configuração de Taxas ✅ (página única)
  └── Relatórios de Repasse ✅
```

**Removido:**

-    ❌ "Configurações por Participante"

### Como Configurar Taxas Agora

1. **Acesse:** Financeiro → Configuração de Taxas
2. **Veja:** Lista de todas as modalidades
3. **Para editar:**
     - Clique em "Editar" na modalidade desejada
     - Altere taxa PIX ou Boleto
     - Escolha: Percentual (%) ou Fixo (R$)
     - Salve
4. **Pronto!** Todos os professores dessa modalidade usarão essa taxa

### Perguntas Comuns

**P: E se eu quiser taxa diferente para um professor específico?** **R:** Crie uma modalidade dedicada para ele. Exemplo:

-    Crie: "Aula Particular - Professor VIP"
-    Configure: taxa especial
-    Atribua: esse professor trabalha nessa modalidade

**P: Como voltar ao sistema antigo?** **R:** Entre em contato com o desenvolvedor. Rollback leva ~2 horas.

**P: Os relatórios funcionam igual?** **R:** Sim! Exatamente da mesma forma. Apenas usam modalidade ao invés de buscar por professor.

---

## 👨‍🏫 Para Professores

### O Que Muda Para Você?

**Resposta curta:** NADA! 🎉

Seu pagamento continua:

-    ✅ Baseado na modalidade que você ensina
-    ✅ Descontando taxa PIX ou Boleto
-    ✅ Aparecendo nos relatórios normalmente

A mudança foi apenas nos "bastidores" do sistema. Sua experiência é idêntica.

---

## 💰 Para Departamento Financeiro

### Relatórios de Repasse

**Funciona exatamente igual!** 🎯

1. Acesse: Financeiro → Relatórios de Repasse
2. Escolha: período (data início/fim)
3. Filtre: professor, modalidade, status
4. Gere: relatório PDF ou Excel

### Cálculo de Taxas

#### Antes e Depois (mesmo resultado)

**Exemplo:** Aula de R$ 100,00

**Configuração da Modalidade "Aula Particular":**

-    Taxa PIX: 5% (Percentual)
-    Taxa Boleto: 8% (Percentual)

**Pagamento via PIX:**

```
Valor Bruto:      R$ 100,00
Taxa (5%):        R$   5,00
Valor Professor:  R$  95,00 ✅
```

**Pagamento via Boleto:**

```
Valor Bruto:      R$ 100,00
Taxa (8%):        R$   8,00
Valor Professor:  R$  92,00 ✅
```

### Auditoria

-    ✅ Todos os cálculos rastreáveis
-    ✅ Histórico de mudanças preservado
-    ✅ Relatórios podem ser regenerados

---

## 🔍 Troubleshooting Rápido

### Erro: "Configuração não encontrada"

**Causa:** Modalidade sem configuração ativa

**Solução:**

1. Acesse: Configuração de Taxas
2. Encontre: a modalidade
3. Verifique: campo "Ativo" = SIM
4. Se não existir: crie nova configuração

### Erro: "Taxa inválida"

**Causa:** Valor negativo ou tipo inválido

**Solução:**

1. Taxa deve ser: ≥ 0
2. Tipo deve ser: "Percentual" ou "Fixo"
3. Percentual: 0-100 (representa %)
4. Fixo: valor em reais

### Relatório Mostra Valores Zerados

**Causa:** Período sem pagamentos confirmados

**Solução:**

1. Verifique: se há pagamentos no período
2. Verifique: status = "confirmado"
3. Verifique: modalidade tem configuração ativa

---

## 📱 Contatos e Suporte

### Para Dúvidas Técnicas

**Desenvolvedor:** Gabriel M. Guimarães  
**GitHub:** @gabrielmg7  
**Slack:** @gabrielmg7

### Para Reportar Bugs

1. Acesse: [GitHub Issues]
2. Título: "[Taxas v2.0] Descrição curta"
3. Inclua:
     - O que você tentou fazer
     - O que aconteceu
     - O que deveria acontecer
     - Prints de tela (se possível)

### Para Sugestões

**Canal:** #melhorias-sistema no Slack

---

## 🎓 Recursos de Aprendizado

### Documentação Completa

-    📄 `CHANGELOG_SIMPLIFICACAO_TAXAS_v2.md` - O que mudou
-    📋 `RESUMO_EXECUTIVO_SIMPLIFICACAO_v2.md` - Visão geral
-    ✅ `CHECKLIST_VERIFICACAO_v2.md` - Validação técnica

### Vídeos (Em Breve)

-    [ ] Como configurar taxas por modalidade (3min)
-    [ ] Como gerar relatórios de repasse (5min)
-    [ ] Perguntas frequentes (10min)

### Treinamento

**Próxima sessão:** A definir  
**Formato:** Online, 30 minutos  
**Público:** Admins e Financeiro

---

## ✅ Checklist Rápido

### Desenvolvedor

-    [ ] Atualizei código para usar novos endpoints
-    [ ] Removi referências a `configuracao_taxas_participante`
-    [ ] Testei fluxo completo de pagamento
-    [ ] Validei cálculos de taxa

### Admin Sistema

-    [ ] Acessei nova interface de configuração
-    [ ] Testei editar uma configuração
-    [ ] Verifiquei que salvou corretamente
-    [ ] Menu não mostra opção "Participantes"

### Financeiro

-    [ ] Gerei relatório de teste
-    [ ] Validei valores de repasse
-    [ ] Confirmei que dados batem com pagamentos
-    [ ] Entendi lógica de taxas por modalidade

---

## 🎉 Pronto Para Usar!

**Status:** ✅ Sistema v2.0 Ativo  
**Data:** 13/10/2025  
**Versão:** 2.0 - Simplificado

Se tiver qualquer dúvida, consulte a documentação completa ou entre em contato com o suporte técnico.

**Bom trabalho! 🚀**

---

**Última Atualização:** 13/10/2025 às 20:30 BRT  
**Autor:** Gabriel M. Guimarães  
**Versão do Guia:** 1.0
