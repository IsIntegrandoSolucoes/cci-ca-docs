# Schema de Tabelas - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (não implementado)  
**Decisões aplicadas:** Usuários simultâneos + Sequencial + Bunny.net

---

## 1. Empresas e Controle de Acesso

### `empresas`

Tabela principal para multi-tenancy B2B.

```sql
CREATE TABLE empresas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    razao_social VARCHAR(255),
    cnpj VARCHAR(18) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa', 'suspensa', 'expirada')),
    data_validade DATE,
    logo_url TEXT,
    contato_email VARCHAR(255),
    contato_telefone VARCHAR(20),
    limite_usuarios_simultaneos INTEGER DEFAULT 10 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_empresas_status ON empresas(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_empresas_validade ON empresas(data_validade) WHERE deleted_at IS NULL;
```

**Regras:**

- `status = 'ativa'`: empresa em operação normal
- `status = 'suspensa'`: bloqueio manual (inadimplência, etc)
- `status = 'expirada'`: data_validade vencida (verificação automática)
- `limite_usuarios_simultaneos`: quantos podem estar logados ao mesmo tempo

---

### `empresa_usuarios`

Vínculo entre usuários (auth.users) e empresas (tenancy).

```sql
CREATE TABLE empresa_usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    perfil VARCHAR(50) NOT NULL DEFAULT 'aluno' CHECK (perfil IN ('gestor_rh', 'aluno')),
    setor VARCHAR(100),
    cargo VARCHAR(100),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(empresa_id, usuario_id)
);

CREATE INDEX idx_empresa_usuarios_empresa ON empresa_usuarios(empresa_id) WHERE ativo = true;
CREATE INDEX idx_empresa_usuarios_usuario ON empresa_usuarios(usuario_id);
CREATE INDEX idx_empresa_usuarios_perfil ON empresa_usuarios(perfil, empresa_id);
```

---

### `sessoes_ativas`

Registro de sessões ativas para controle de concorrência.

```sql
CREATE TABLE sessoes_ativas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    curso_id UUID REFERENCES cursos(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL UNIQUE,
    ip_address INET,
    user_agent TEXT,
    ultimo_heartbeat TIMESTAMPTZ DEFAULT NOW(),
    iniciada_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(usuario_id, curso_id)
);

CREATE INDEX idx_sessoes_empresa ON sessoes_ativas(empresa_id);
CREATE INDEX idx_sessoes_usuario ON sessoes_ativas(usuario_id);
CREATE INDEX idx_sessoes_heartbeat ON sessoes_ativas(ultimo_heartbeat);
```

**Regras:**

- Heartbeat a cada 30s para manter sessão viva
- Timeout automático: 5 minutos sem heartbeat = sessão expira
- `UNIQUE(usuario_id, curso_id)`: um usuário só pode ter 1 sessão ativa por curso

---

## 2. Catálogo LMS

### `cursos`

Catálogo de cursos oferecidos.

```sql
CREATE TABLE cursos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    capa_url TEXT,
    carga_horaria INTEGER, -- minutos totais
    publico VARCHAR(20) DEFAULT 'b2b' CHECK (publico IN ('b2b', 'b2c', 'ambos')),
    nivel VARCHAR(50) CHECK (nivel IN ('iniciante', 'intermediario', 'avancado')),
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    deletado_em TIMESTAMPTZ
);

CREATE INDEX idx_cursos_professor ON cursos(professor_id) WHERE deletado_em IS NULL;
CREATE INDEX idx_cursos_publico ON cursos(publico, ativo) WHERE deletado_em IS NULL;
```

---

### `modulos`

Módulos de curso (agrupamento de aulas).

```sql
CREATE TABLE modulos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    curso_id UUID NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    ordem INTEGER NOT NULL,
    duracao_estimada INTEGER, -- minutos
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(curso_id, ordem)
);

CREATE INDEX idx_modulos_curso ON modulos(curso_id, ordem);
```

---

### `aulas`

Aulas individuais com conteúdo.

```sql
CREATE TABLE aulas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modulo_id UUID NOT NULL REFERENCES modulos(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    ordem INTEGER NOT NULL,
    tipo_conteudo VARCHAR(50) NOT NULL CHECK (tipo_conteudo IN ('video', 'pdf', 'link', 'texto')),

    -- Bunny.net Video
    bunny_video_id VARCHAR(255),
    bunny_library_id VARCHAR(255),
    bunny_status VARCHAR(50), -- 'processing', 'ready', 'failed'
    duracao_segundos INTEGER,

    -- Outros tipos
    conteudo_url TEXT,
    conteudo_texto TEXT,

    obrigatoria BOOLEAN DEFAULT true,
    janela_acesso_dias INTEGER, -- dias após matrícula para expirar (NULL = sem limite)

    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(modulo_id, ordem)
);

CREATE INDEX idx_aulas_modulo ON aulas(modulo_id, ordem);
CREATE INDEX idx_aulas_bunny ON aulas(bunny_video_id) WHERE bunny_video_id IS NOT NULL;
```

**Regras:**

- `ordem` define sequência obrigatória (aula N+1 só libera após concluir N)
- `bunny_video_id`: ID do vídeo no Bunny.net (não expor URL direta)
- `janela_acesso_dias`: materializa regra de expiração (ex: 30 dias após matrícula)

---

## 3. Matrícula e Progresso

### `usuario_curso`

Matrícula do usuário no curso.

```sql
CREATE TABLE usuario_curso (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    curso_id UUID NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'matriculado' CHECK (status IN ('matriculado', 'em_andamento', 'concluido', 'bloqueado', 'expirado')),
    progresso_percentual DECIMAL(5,2) DEFAULT 0.00,
    data_matricula TIMESTAMPTZ DEFAULT NOW(),
    data_inicio TIMESTAMPTZ,
    data_conclusao TIMESTAMPTZ,
    nota_final DECIMAL(5,2),
    observacoes TEXT,
    UNIQUE(usuario_id, curso_id)
);

CREATE INDEX idx_usuario_curso_usuario ON usuario_curso(usuario_id);
CREATE INDEX idx_usuario_curso_empresa ON usuario_curso(empresa_id);
CREATE INDEX idx_usuario_curso_curso ON usuario_curso(curso_id);
CREATE INDEX idx_usuario_curso_status ON usuario_curso(status);
```

**Status:**

- `matriculado`: vínculo criado, ainda não iniciou
- `em_andamento`: iniciou ao menos 1 aula
- `concluido`: 100% + critérios de certificação
- `bloqueado`: empresa suspensa/expirada
- `expirado`: ultrapassou janela de acesso

---

### `usuario_aula_progresso`

Progresso individual por aula.

```sql
CREATE TABLE usuario_aula_progresso (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    aula_id UUID NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
    percentual_assistido DECIMAL(5,2) DEFAULT 0.00,
    ultima_posicao_segundos INTEGER DEFAULT 0,
    concluida BOOLEAN DEFAULT false,
    data_inicio TIMESTAMPTZ,
    data_conclusao TIMESTAMPTZ,
    tentativas INTEGER DEFAULT 0,
    UNIQUE(usuario_id, aula_id)
);

CREATE INDEX idx_progresso_usuario ON usuario_aula_progresso(usuario_id);
CREATE INDEX idx_progresso_aula ON usuario_aula_progresso(aula_id);
CREATE INDEX idx_progresso_concluida ON usuario_aula_progresso(concluida);
```

**Trigger associado:** `trg_atualizar_progresso_curso` (atualiza `usuario_curso.progresso_percentual`)

---

## 4. LXP - Interatividade e Aprendizagem

### `mapas_mentais`

Mapas mentais criados por professores para aulas.

```sql
CREATE TABLE mapas_mentais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aula_id UUID NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
    professor_id UUID NOT NULL REFERENCES auth.users(id),
    titulo VARCHAR(255) NOT NULL,
    conteudo_json JSONB NOT NULL, -- estrutura do mapa mental
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mapas_aula ON mapas_mentais(aula_id);
```

---

### `anotacoes_aluno`

Anotações privadas do aluno (texto ou transcrição de áudio).

```sql
CREATE TABLE anotacoes_aluno (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    aula_id UUID NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
    mapa_mental_id UUID REFERENCES mapas_mentais(id) ON DELETE SET NULL,
    tipo VARCHAR(50) CHECK (tipo IN ('texto', 'audio_transcrito')),
    conteudo TEXT NOT NULL,
    posicao_video_segundos INTEGER,
    audio_url TEXT, -- URL do áudio original (se tipo = 'audio_transcrito')
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_anotacoes_usuario ON anotacoes_aluno(usuario_id);
CREATE INDEX idx_anotacoes_aula ON anotacoes_aluno(aula_id);
```

---

### `exercicios`

Exercícios criados por professores para aulas.

```sql
CREATE TABLE exercicios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aula_id UUID NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
    professor_id UUID NOT NULL REFERENCES auth.users(id),
    titulo VARCHAR(255) NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('objetiva', 'multipla_escolha', 'verdadeiro_falso', 'dissertativa')),
    enunciado TEXT NOT NULL,
    opcoes JSONB, -- array de opções para objetiva/múltipla
    gabarito JSONB NOT NULL, -- resposta(s) correta(s)
    explicacao_gabarito TEXT,
    nota_minima DECIMAL(5,2) DEFAULT 0.00,
    tentativas_permitidas INTEGER DEFAULT 3,
    tempo_limite_minutos INTEGER,
    obrigatorio BOOLEAN DEFAULT false,
    ordem INTEGER,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_exercicios_aula ON exercicios(aula_id, ordem);
CREATE INDEX idx_exercicios_professor ON exercicios(professor_id);
```

---

### `usuario_exercicio_resposta`

Respostas dos alunos aos exercícios.

```sql
CREATE TABLE usuario_exercicio_resposta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercicio_id UUID NOT NULL REFERENCES exercicios(id) ON DELETE CASCADE,
    resposta JSONB NOT NULL,
    correta BOOLEAN,
    nota DECIMAL(5,2),
    tentativa INTEGER DEFAULT 1,
    tempo_gasto_segundos INTEGER,
    feedback_professor TEXT,
    corrigido_em TIMESTAMPTZ,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_resposta_usuario ON usuario_exercicio_resposta(usuario_id);
CREATE INDEX idx_resposta_exercicio ON usuario_exercicio_resposta(exercicio_id);
CREATE INDEX idx_resposta_correta ON usuario_exercicio_resposta(correta);
```

**Trigger associado:** `trg_gerar_flashcard_apos_erro` (quando `correta = false`)

---

### `flashcards_revisao`

Flashcards gerados automaticamente a partir de erros em exercícios.

```sql
CREATE TABLE flashcards_revisao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercicio_id UUID NOT NULL REFERENCES exercicios(id) ON DELETE CASCADE,
    resposta_id UUID REFERENCES usuario_exercicio_resposta(id) ON DELETE CASCADE,
    frente TEXT NOT NULL, -- pergunta/conceito
    verso TEXT NOT NULL, -- resposta correta
    dificuldade VARCHAR(50) DEFAULT 'media' CHECK (dificuldade IN ('facil', 'media', 'dificil')),
    revisoes INTEGER DEFAULT 0,
    proxima_revisao DATE,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_flashcards_usuario ON flashcards_revisao(usuario_id);
CREATE INDEX idx_flashcards_revisao ON flashcards_revisao(proxima_revisao, usuario_id);
```

---

## 5. Certificação

### `certificados`

Certificados emitidos automaticamente.

```sql
CREATE TABLE certificados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    curso_id UUID NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    empresa_id UUID REFERENCES empresas(id) ON DELETE SET NULL,
    codigo_validacao VARCHAR(50) UNIQUE NOT NULL,
    nota_final DECIMAL(5,2) NOT NULL,
    carga_horaria INTEGER NOT NULL,
    data_emissao TIMESTAMPTZ DEFAULT NOW(),
    pdf_url TEXT,
    qr_code_url TEXT,
    template_usado VARCHAR(100),
    UNIQUE(usuario_id, curso_id)
);

CREATE INDEX idx_certificados_usuario ON certificados(usuario_id);
CREATE INDEX idx_certificados_codigo ON certificados(codigo_validacao);
CREATE INDEX idx_certificados_empresa ON certificados(empresa_id);
```

**Trigger associado:** `trg_emitir_certificado` (ao concluir curso com critérios atendidos)

---

## 6. Resumo de Constraints Críticas

1. **Isolamento por tenant:**
   - Todas as queries de RLS filtram por `empresa_id` quando aplicável

2. **Unicidade de matrícula:**
   - `UNIQUE(usuario_id, curso_id)` em `usuario_curso`

3. **Sessões simultâneas:**
   - `UNIQUE(usuario_id, curso_id)` em `sessoes_ativas`
   - Validação em RPC: `COUNT(*) <= empresa.limite_usuarios_simultaneos`

4. **Ordem sequencial:**
   - `UNIQUE(modulo_id, ordem)` em `aulas`
   - `UNIQUE(curso_id, ordem)` em `modulos`

5. **Integridade referencial:**
   - `ON DELETE CASCADE` em relações owned
   - `ON DELETE SET NULL` em relações opcionais

---

## 7. Próximos Passos

- [ ] Validar nomenclatura de tabelas com padrões do projeto
- [ ] Definir policies RLS (próximo documento)
- [ ] Implementar funções/triggers (próximo documento)
- [ ] Criar migrations SQL (seguir ordem do PLANO_MIGRATIONS)
