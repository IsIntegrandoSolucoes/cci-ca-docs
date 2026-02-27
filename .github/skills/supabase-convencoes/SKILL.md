---
name: supabase-convencoes
description: Valida e sugere convenções de nomenclatura para objetos do banco de dados.
---

# Convenções de Nomenclatura — Supabase (CCI-CA)

## Objetivo

Garantir que todos os objetos do banco de dados sigam o padrão de nomenclatura unificado do projeto para facilitar manutenção e automação via PostgREST.

## Escopo Normativo

### Tabelas

- **Entidades**: Plural, snake_case (`alunos`, `matriculas`).
- **Classificação**: Prefixo `tipo_` (`tipo_pagamento`).
- **Junção**: Compostos no plural (`alunos_cursos`).
- **Suporte**: Prefixos `tmp_` (temp), `hist_` (histórico), `bkp_` (backup).

### Colunas

- **Chave primária**: Sempre `id` (BIGINT).
- **Chave estrangeira**: Formato `fk_id_entidade`.
- **Datas**: Prefixo `data_` ou campos `created_at`, `updated_at`, `deleted_at`.
- **Booleanos**: Sufixo `_ativo`.
- **Monetários**: Sufixo `_valor`.

### Outros Objetos

- **Índices**: `idx_tabela_colunas`.
- **Constraints**: `unq_` (UNIQUE), `chk_` (CHECK), `fk_` (Foreign Key).
- **Lógica**: `tr_` (Trigger), `fn_` (Function), `sp_` (Procedure).
- **Views**: `vw_descricao`.

## When NOT to use

- Não aplicar em tabelas de schemas de terceiros (ex.: `auth`, `storage`, `internal`).
- Não forçar mudança em objetos legados sem um plano de migração aprovado.

## Checklist de Validação

- [ ] O nome é snake_case?
- [ ] Tabelas estão no plural?
- [ ] Chave primária é `id` BIGINT?
- [ ] Foreign Keys seguem o padrão `fk_id_...`?
- [ ] Constraints e índices possuem os prefixos corretos?

## 🔍 Detecções Automáticas

### Problemas de Nomenclatura

## When NOT to use

- Não usar quando houver necessidade de adaptação para sistemas legados sem migração coordenada.

## Manual verification steps

1. Validar nomes de novos objetos em uma checklist antes de aplicar migration.
2. Conferir índices e constraints com o DBA ou owner do schema.
3. Documentar alterações no changelog de migrations.

### Problemas de Nomenclatura

```sql
-- ❌ Detectado: Nomes incorretos
CREATE TABLE Usuario (          -- Deveria ser 'usuarios'
    ID UUID PRIMARY KEY,       -- Deveria ser 'id BIGINT'
    tipoUsuario VARCHAR(50),   -- Deveria ser FK para 'tipo_usuarios'
    dataCreated TIMESTAMP      -- Deveria ser 'created_at'
);

-- ✅ Sugerido: Nomenclatura correta
CREATE TABLE usuarios (
    id BIGINT PRIMARY KEY,
    fk_id_tipo_usuario BIGINT REFERENCES tipo_usuarios(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Estrutura de Auditoria

```sql
-- Skill sugere automaticamente para tabelas críticas:
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS created_by BIGINT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS updated_by BIGINT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS deleted_by BIGINT;
```

## 🛠️ Verificações por Tipo

### Chaves e Relacionamentos

```sql
-- Valida padrões de FK
❌ user_id → ✅ fk_id_usuario
❌ courseType → ✅ fk_id_tipo_curso
❌ UUID keys → ✅ BIGINT keys
```

### Tipos de Dados

```sql
-- Detecta tipos inadequados
❌ TIMESTAMPZ → ✅ TIMESTAMP
❌ VARCHAR sem limite → ✅ VARCHAR(255)
❌ TEXT para enum → ✅ FK para tabela tipo_*
```

### Convenções Específicas

```sql
-- Status e Tipos como FK (não ENUM)
❌ status VARCHAR(20) → ✅ fk_id_status_pagamento BIGINT
❌ tipo VARCHAR(30) → ✅ fk_id_tipo_usuario BIGINT
```

## 📋 Validações por Schema

### Schema `public` (Principal)

- Tabelas de entidades principais
- Convenções de auditoria obrigatórias
- Relacionamentos bem definidos

### Schema `bb_pay_v2` (Específico)

- Prefixos específicos do módulo
- Integração com sistema externo
- Convenções adaptadas ao contexto

### Schema `restaurante` (Específico)

- Entidades do domínio restaurante
- Relacionamentos com schema principal
- Convenções do módulo

## ⚡ Gatilhos de Ativação

- Criação de migrations (`.sql`)
- Comandos `CREATE TABLE`
- Comandos `ALTER TABLE`
- Definição de constraints e índices
- Criação de functions/triggers

## 🎯 Exemplos de Correções

### Tabela de Entidade

```sql
-- Antes (Detectado)
CREATE TABLE User (
    userID UUID PRIMARY KEY,
    firstName VARCHAR,
    userType VARCHAR(20),
    isActive BOOLEAN
);

-- Depois (Sugerido)
CREATE TABLE usuarios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    primeiro_nome VARCHAR(100) NOT NULL,
    fk_id_tipo_usuario BIGINT REFERENCES tipo_usuarios(id),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_at TIMESTAMP,
    updated_by BIGINT
);
```

### Índices e Constraints

```sql
-- Skill sugere automaticamente
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE UNIQUE INDEX unq_usuarios_cpf ON usuarios(cpf);
ALTER TABLE usuarios ADD CONSTRAINT chk_usuarios_idade
    CHECK (idade >= 0 AND idade <= 120);
```

## 🗂️ Organização de Schemas

```
public/               -- Entidades principais
├── usuarios
├── tipo_usuarios
└── permissoes

bb_pay_v2/           -- Integração bancária
├── solicitacoes
├── pagamentos
└── webhooks

restaurante/         -- Módulo específico
├── cardapios
├── pedidos
└── tipo_pratos
```

---

**Baseado em**: `SUPABASE_CONVENCOES_NOMENCLATURA.instructions.md`
