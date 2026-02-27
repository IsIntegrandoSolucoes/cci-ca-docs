# 🗺️ Mapa Rápido de Navegação - Documentação Financeira

> Guia visual para encontrar documentos rapidamente

---

## 🎯 Por Necessidade

### "Preciso entender o sistema como um todo"

📄 `SISTEMA_FINANCEIRO.md` - Comece aqui!

### "Preciso ver os requisitos funcionais"

📄 `REQUISITOS_SISTEMA_REPASSES.md`

### "Preciso configurar taxas hoje"

📄 `GUIA_RAPIDO_SISTEMA_TAXAS_v2.md`

### "Preciso configurar múltiplos recebedores"

📄 `GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md`

### "Preciso fazer conciliação bancária"

📄 `ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md`

### "Preciso entender as regras de repasse"

📄 `FLUXO_REPASSES_CONVENIO_PROFESSOR.md`

### "Preciso ver o fluxo da API"

📄 `API_FLUXO_CONFIGURACAO_TAXAS_COMPLETO.md`

### "Preciso entender identificadores de recebedores"

📄 `ESCLARECIMENTO_IDENTIFICADOR_RECEBEDOR.md`

### "Preciso ver histórico de implementações"

📁 `changelogs/` - Pasta completa

---

## 👤 Por Perfil

### 👨‍💼 Gestor / Product Owner

```
1. SISTEMA_FINANCEIRO.md
2. changelogs/RESUMO_EXECUTIVO_FINAL.md
3. REQUISITOS_SISTEMA_REPASSES.md
```

### 👨‍💻 Desenvolvedor Backend

```
1. SISTEMA_FINANCEIRO.md (seção Arquitetura)
2. REQUISITOS_SISTEMA_REPASSES.md
3. ADAPTACAO_API_REPASSES.md
4. API_FLUXO_CONFIGURACAO_TAXAS_COMPLETO.md
```

### 👨‍💻 Desenvolvedor Frontend

```
1. SISTEMA_FINANCEIRO.md (seção Funcionalidades)
2. REQUISITOS_SISTEMA_REPASSES.md (seção RUI)
3. GUIA_RAPIDO_SISTEMA_TAXAS_v2.md
```

### 💼 Administrador

```
1. GUIA_RAPIDO_SISTEMA_TAXAS_v2.md
2. GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md
3. ADMIN.FINANCEIRO.md
```

### 💰 Financeiro

```
1. ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md
2. SISTEMA_FINANCEIRO.md (seção Pagamentos)
3. ADMIN.FINANCEIRO.md
```

---

## 🔍 Por Tópico

### Pagamentos PIX

```
SISTEMA_FINANCEIRO.md → Seção "Integração Bancária"
ADAPTACAO_API_REPASSES.md → Integração técnica
```

### Contratos e Parcelas

```
SISTEMA_FINANCEIRO.md → Seção "Gestão de Contratos"
ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md → Operacional
```

### Splits e Repasses

```
REQUISITOS_SISTEMA_REPASSES.md → Requisitos
FLUXO_REPASSES_CONVENIO_PROFESSOR.md → Regras de negócio
ADAPTACAO_API_REPASSES.md → Implementação
```

### Configuração de Taxas

```
SISTEMA_CONFIGURACAO_TAXAS.md → Especificação
GUIA_RAPIDO_SISTEMA_TAXAS_v2.md → Uso prático
changelogs/CHANGELOG_SIMPLIFICACAO_TAXAS_v2.md → Histórico
```

### Múltiplos Recebedores

```
GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md → Configuração
changelogs/SISTEMA_MULTIPLOS_RECEBEDORES_SIMPLIFICADO.md → Arquitetura
changelogs/IMPLEMENTACAO_COMPLETA_MULTIPLOS_RECEBEDORES.md → Implementação
```

### Endpoints da API

```
API_FLUXO_CONFIGURACAO_TAXAS_COMPLETO.md → Fluxo completo
SISTEMA_FINANCEIRO.md → Resumo de endpoints
```

### Troubleshooting

```
SISTEMA_FINANCEIRO.md → Seção "Troubleshooting"
changelogs/GUIA_TESTES_RAPIDOS.md → Testes e validações
```

---

## 📊 Por Tipo de Informação

### Conceitos e Visão Geral

-    `SISTEMA_FINANCEIRO.md`
-    `FLUXO_REPASSES_CONVENIO_PROFESSOR.md`
-    `ESCLARECIMENTO_IDENTIFICADOR_RECEBEDOR.md`

### Requisitos

-    `REQUISITOS_SISTEMA_REPASSES.md`
-    `ANALISE_TURMAS_CNPJ.md`

### Especificações Técnicas

-    `SISTEMA_CONFIGURACAO_TAXAS.md`
-    `API_FLUXO_CONFIGURACAO_TAXAS_COMPLETO.md`
-    `ADAPTACAO_API_REPASSES.md`

### Guias Práticos

-    `GUIA_RAPIDO_SISTEMA_TAXAS_v2.md`
-    `GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md`
-    `ADMIN.FINANCEIRO.md`
-    `ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md`

### Histórico

-    `changelogs/` (26 documentos)

---

## 🚀 Início Rápido por Tarefa

### Configurar nova modalidade

```
1. SISTEMA_CONFIGURACAO_TAXAS.md (entender estrutura)
2. GUIA_RAPIDO_SISTEMA_TAXAS_v2.md (seguir passo a passo)
3. Acessar Portal Admin → Configuração de Taxas
```

### Adicionar novo recebedor

```
1. GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md (passo a passo)
2. Acessar Portal Admin → Configuração de Taxas
3. Selecionar modalidade → Editar Recebedores
```

### Conciliar pagamentos

```
1. ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md (procedimento)
2. Acessar Portal Admin → Financeiro → Conciliação
3. Seguir checklist do documento
```

### Gerar parcelas de contrato

```
1. SISTEMA_FINANCEIRO.md → Fluxo de Geração de Parcelas
2. Acessar Portal Admin → MatriculasPagas
3. Selecionar aluno → Gerar Parcelas
```

### Implementar nova feature

```
1. REQUISITOS_SISTEMA_REPASSES.md (requisitos)
2. ADAPTACAO_API_REPASSES.md (arquitetura)
3. changelogs/ (exemplos de implementação)
4. Criar branch e implementar
```

### Debugar problema

```
1. SISTEMA_FINANCEIRO.md → Troubleshooting
2. Verificar logs no Supabase
3. changelogs/GUIA_TESTES_RAPIDOS.md (cenários)
4. Consultar documentação técnica específica
```

---

## 📱 Acesso Rápido

### Links do Sistema

-    Portal Admin: https://admin.cci-ca.com.br
-    Portal Aluno: https://aluno.cci-ca.com.br
-    Supabase: https://app.supabase.com
-    IS Cobrança API: https://iscobranca.cci-ca.com.br

### Contatos

-    **Técnico:** Gabriel M. Guimarães (@gabrielmg7)
-    **Suporte:** Segunda a Sexta, 9h-18h BRT

---

## 🎓 Dicas de Navegação

### ✅ Faça

-    Comece sempre pelo `README.md` principal
-    Use `CTRL+F` para buscar termos específicos
-    Consulte changelogs para contexto histórico
-    Siga o guia por perfil se for novo no projeto

### ❌ Evite

-    Ler documentos técnicos sem contexto
-    Ignorar requisitos antes de implementar
-    Pular guias rápidos ao usar o sistema
-    Modificar sem consultar documentação

---

## 📦 Estrutura de Arquivos

```
Financeiro/
├── 📄 README.md ← COMECE AQUI
├── 📄 SISTEMA_FINANCEIRO.md ← VISÃO GERAL
├── 📄 REQUISITOS_SISTEMA_REPASSES.md
├── 📄 GUIA_RAPIDO_SISTEMA_TAXAS_v2.md
├── 📄 GUIA_RAPIDO_MULTIPLOS_RECEBEDORES.md
├── 📄 ADMIN.FINANCEIRO.md
├── 📄 ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md
├── 📄 FLUXO_REPASSES_CONVENIO_PROFESSOR.md
├── 📄 ADAPTACAO_API_REPASSES.md
├── 📄 SISTEMA_CONFIGURACAO_TAXAS.md
├── 📄 API_FLUXO_CONFIGURACAO_TAXAS_COMPLETO.md
├── 📄 ESCLARECIMENTO_IDENTIFICADOR_RECEBEDOR.md
├── 📄 ANALISE_TURMAS_CNPJ.md
├── 📄 RELATORIO_REORGANIZACAO.md
├── 📄 MAPA_NAVEGACAO.md ← VOCÊ ESTÁ AQUI
└── 📁 changelogs/ (26 arquivos históricos)
```

---

**Atualizado:** 21/10/2025  
**Versão:** 1.0  
**Mantenedor:** Gabriel M. Guimarães
