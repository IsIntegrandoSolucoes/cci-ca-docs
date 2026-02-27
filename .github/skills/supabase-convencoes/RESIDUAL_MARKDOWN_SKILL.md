# Exemplos e Detalhes — Supabase Convencões

## Exemplos de Transformação

### Refatoração de Tabela

```sql
-- ❌ Incorreto
CREATE TABLE Usuario (
    ID UUID PRIMARY KEY,
    tipoUsuario VARCHAR(50),
    dataCreated TIMESTAMP
);

-- ✅ Correto
CREATE TABLE usuarios (
    id BIGINT PRIMARY KEY,
    fk_id_tipo_usuario BIGINT REFERENCES tipo_usuarios(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Estrutura de Auditoria Padrão

Sempre que uma tabela crítica for criada, a skill sugere a inclusão de:

```sql
ALTER TABLE [tabela] ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE [tabela] ADD COLUMN IF NOT EXISTS created_by BIGINT;
ALTER TABLE [tabela] ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
ALTER TABLE [tabela] ADD COLUMN IF NOT EXISTS updated_by BIGINT;
ALTER TABLE [tabela] ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE [tabela] ADD COLUMN IF NOT EXISTS deleted_by BIGINT;
```

## Anti-padrões (Evite)

- Usar nomes no singular para tabelas.
- Usar UUID como chave primária principal (preferir BIGINT com sequences).
- Omitir prefixos/sufixos funcionais (`fk_`, `data_`, `_ativo`).
