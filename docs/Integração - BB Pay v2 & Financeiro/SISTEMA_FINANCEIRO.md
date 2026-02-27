# 💰 Sistema Financeiro - CCI-CA

## 📋 Visão Geral

O Sistema Financeiro do CCI-CA gerencia toda a operação de pagamentos e repasses da plataforma, incluindo aulas avulsas, contratos mensais e distribuição de valores entre empresa e professores.

---

## 🎯 Funcionalidades Principais

### 1. **Pagamentos PIX Instantâneos**

**Modalidades:**

-    Aulas Particulares (CA-AP)
-    Aulas em Grupo (CA-AG)
-    Cursos Pré-Prova (CA-PP)

**Características:**

-    Geração automática de QR Code PIX
-    Confirmação via webhook em tempo real
-    Sistema de reserva temporária (15 minutos)
-    Conciliação automática de pagamentos

### 2. **Gestão de Contratos Mensais**

**Tipos de Contrato:**

-    Contrato Mensal (CA-CM)
-    Turma Vestibular (CA-TV)
-    Turma Mentoria (CA-TM)

**Recursos:**

-    Geração automática de 12 parcelas mensais
-    Sistema de descontos (vencimento, especial, P3, P5)
-    Controle de inadimplência
-    Gestão de matrículas pagas/não pagas

### 3. **Sistema de Repasses (Splits)**

**Definição:** Divisão automática de valores recebidos entre empresa (convênio) e professores participantes.

**Regras de Negócio:**

-    Configuração por modalidade de aula
-    Suporte a múltiplos recebedores (N participantes)
-    Percentuais configuráveis
-    Validação automática (soma = 100%)

**Exemplo:**

```
Aula Particular R$ 100,00:
- Convênio (empresa): 15%
- Professor: 85%
```

---

## 🏗️ Arquitetura

### Backend (cci-ca-api)

**Serviços Implementados:**

-    `RecebedoresConfigService` - Gestão de recebedores
-    `RepasseCalculatorService` - Cálculo de splits
-    `CobrancaIntegracaoService` - Integração PIX

**Endpoints Principais:**

```
GET  /api/configuracao-taxas/modalidades
PUT  /api/configuracao-taxas/modalidade/:id
GET  /api/configuracao-taxas/recebedores/modalidade/:id
PUT  /api/configuracao-taxas/recebedores/modalidade/:id
DELETE /api/configuracao-taxas/recebedores/:id
```

### Frontend (cci-ca-admin)

**Páginas:**

-    `ConfiguracaoTaxasPage` - Configuração de splits
-    `MatriculasPagas` - Gestão de matrículas quitadas
-    `MatriculasNaoPagas` - Controle de inadimplência
-    `ParcelasGeradas` - Monitoramento de parcelas

**Hooks:**

-    `useRecebedores` - Gestão de recebedores
-    `useConfiguracaoTaxas` - Configuração de taxas

### Banco de Dados (Supabase)

**Tabelas Principais:**

```
configuracao_taxas_modalidade  - Configurações por modalidade
configuracao_recebedores       - Múltiplos recebedores
contrato_ano_pessoa            - Parcelas de contratos
pagamentos                     - Conciliação PIX
auditoria                      - Log de operações
```

**Funções SQL:**

-    `buscar_recebedores_modalidade` - Busca recebedores ativos
-    Triggers de validação de percentuais

---

## 📊 Fluxos de Operação

### Fluxo de Pagamento PIX

1. **Aluno agenda aula** no Portal do Aluno
2. **Sistema gera PIX** via CCI-CA API → IS Cobrança API → BB Pay
3. **Aluno paga** via aplicativo bancário
4. **BB Pay notifica** IS Cobrança API (webhook)
5. **IS Cobrança atualiza** Supabase
6. **Status muda** de 'agendado' para 'confirmado'
7. **Agendamento liberado** automaticamente

### Fluxo de Geração de Parcelas

1. **Aluno paga matrícula** (via portal ou presencial)
2. **Admin acessa** MatriculasPagas no portal admin
3. **Seleciona aluno** e abre GerarParcelasModal
4. **Configura:**
     - Data de vencimento das parcelas
     - Tipo de desconto (se houver)
     - Percentual de desconto
5. **Sistema gera** 12 parcelas automaticamente
6. **Parcelas aparecem** em ParcelasGeradas para acompanhamento

### Fluxo de Configuração de Repasses

1. **Admin acessa** ConfiguracaoTaxasPage
2. **Seleciona modalidade** (ex: Aulas Particulares)
3. **Define recebedores:**
     - Convênio (empresa): CPF/CNPJ + percentual
     - Professores: CPF + percentual
4. **Sistema valida** soma = 100%
5. **Configuração salva** no banco
6. **Pagamentos futuros** usam nova configuração automaticamente

---

## 🔐 Integração Bancária

### IS Cobrança API v2.0

**Papel:** Intermediário especializado para comunicação com Banco do Brasil

**Recursos:**

-    Geração de PIX instantâneo
-    Gestão de webhooks
-    Conciliação automática
-    Timeout otimizado (1800s)

**Fluxo Técnico:**

```
CCI-CA API → IS Cobrança API → BB Pay
           ← Webhook         ←
```

### Códigos de Conciliação

Sistema proprietário para rastrear transações:

| Código   | Modalidade      | Exemplo  |
| -------- | --------------- | -------- |
| AP-XXXXX | Aula Particular | AP-00123 |
| AG-XXXXX | Aula em Grupo   | AG-00045 |
| PP-XXXXX | Pré-Prova       | PP-00012 |
| CM-XXXXX | Contrato Mensal | CM-00089 |

---

## 📈 Relatórios e Auditoria

### Sistema de Auditoria

**Rastreamento:**

-    Todas as operações financeiras
-    Criação/edição de parcelas
-    Alterações em configurações
-    Pagamentos confirmados

**Campos Registrados:**

-    Timestamp da operação
-    Usuário responsável
-    Tipo de operação
-    Valores antes/depois

### Relatórios Disponíveis

**Portal Admin:**

-    Declarações de pagamento (PDF)
-    Relatórios de repasse
-    Estatísticas financeiras
-    Exportação CSV/Excel

---

## ⚙️ Configurações

### Configuração de Taxas por Modalidade

**Acesso:** Portal Admin → Financeiro → Configuração de Taxas

**Modalidades Configuráveis:**

1. Aulas Particulares (CA-AP)
2. Aulas em Grupo (CA-AG)
3. Pré-Prova (CA-PP)
4. Contrato Mensal (CA-CM)
5. Turma Vestibular (CA-TV)
6. Turma Mentoria (CA-TM)

**Para Cada Modalidade:**

-    Múltiplos recebedores (ilimitado)
-    Identificador (CPF/CNPJ)
-    Tipo (Convênio ou Participante)
-    Percentual (0-100%)
-    Ordem de exibição

### Sistema de Descontos

**Tipos Disponíveis:**

1. **Desconto de Vencimento** - Pontualidade
2. **Desconto Especial** - Promocional
3. **Desconto P3** - Pagamento de 3 mensalidades
4. **Desconto P5** - Pagamento de 5 mensalidades
5. **Desconto Personalizado** - Casos específicos

---

## 🔍 Troubleshooting

### Problemas Comuns

**Pagamento não confirmado:**

1. Verificar logs do webhook na IS Cobrança API
2. Checar status na tabela `pagamentos`
3. Confirmar código de conciliação

**Parcelas não geradas:**

1. Verificar se matrícula foi paga
2. Checar permissões do admin
3. Validar datas de vencimento

**Erro na configuração de taxas:**

1. Validar soma de percentuais = 100%
2. Verificar identificadores (CPF/CNPJ válidos)
3. Checar duplicação de recebedores

---

## 📚 Documentação Relacionada

### Especificações de Negócio

-    `FLUXO_REPASSES_CONVENIO_PROFESSOR.md` - Regras de repasse
-    `ADAPTACAO_API_REPASSES.md` - Integração técnica
-    `SISTEMA_CONFIGURACAO_TAXAS.md` - Configuração de taxas

### Histórico e Changelogs

Ver pasta `changelogs/` para:

-    Implementações realizadas
-    Migrations do banco
-    Testes e validações
-    Correções aplicadas

### Guias Rápidos

-    `GUIA_RAPIDO_SISTEMA_TAXAS_v2.md` - Uso diário
-    `GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md` - Múltiplos recebedores
-    `INDICE_DOCUMENTACAO_v2.md` - Índice completo

---

## 🎯 Próximas Evoluções

### Planejado

-    [ ] Dashboard financeiro em tempo real
-    [ ] Exportação automática para contabilidade
-    [ ] Integração com múltiplos bancos
-    [ ] Sistema de cashback para alunos
-    [ ] Previsão de receita por IA

### Em Análise

-    [ ] Pagamento via cartão de crédito
-    [ ] Parcelamento de aulas avulsas
-    [ ] Sistema de créditos pré-pagos
-    [ ] Programa de fidelidade

---

## 📞 Contato

**Responsável Técnico:** Gabriel M. Guimarães  
**GitHub:** @gabrielmg7

**Suporte:** Segunda a Sexta, 9h-18h (BRT)

---

**Última Atualização:** 21/10/2025  
**Versão:** 2.0 - Sistema de Múltiplos Recebedores
