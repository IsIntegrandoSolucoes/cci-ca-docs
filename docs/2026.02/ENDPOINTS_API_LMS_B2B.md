# Endpoints da API - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (não implementado)  
**Base:** FUNCOES_TRIGGERS_LMS_B2B.md + MATRIZ_RBAC_LMS_B2B.md

---

## 1. Convenções Gerais

### 1.1 Base URLs

- **Admin/Professor API:** Netlify Functions em `cci-ca-admin`
- **Aluno/RH API:** Netlify Functions em `cci-ca-aluno`
- **Supabase REST API:** Acesso direto via cliente JS (queries filtradas por RLS)

### 1.2 Autenticação

**Header Obrigatório:**

```http
Authorization: Bearer <supabase_access_token>
```

### 1.3 Formato de Resposta

**Sucesso:**

```json
{
    "sucesso": true,
    "dados": { ... },
    "mensagem": "Operação realizada com sucesso."
}
```

**Erro:**

```json
{
    "sucesso": false,
    "erro": "codigo_erro",
    "mensagem": "Descrição do erro.",
    "detalhes": { ... }
}
```

### 1.4 Códigos de Status HTTP

| Código | Descrição                             |
| ------ | ------------------------------------- |
| 200    | Sucesso (GET, PUT, PATCH)             |
| 201    | Criado (POST)                         |
| 204    | Sem conteúdo (DELETE)                 |
| 400    | Requisição inválida                   |
| 401    | Não autenticado                       |
| 403    | Não autorizado (sem permissão)        |
| 404    | Recurso não encontrado                |
| 409    | Conflito (registro duplicado)         |
| 429    | Limite atingido (sessões simultâneas) |
| 500    | Erro interno do servidor              |

---

## 2. Módulo: Empresas

### 2.1 Listar Empresas

**Endpoint:** `GET /api/v1/empresas`

**Perfis:** `admin_interno`

**Query Params:**

```typescript
{
    status?: 'ativa' | 'suspensa' | 'expirada';
    plano?: string;
    busca?: string; // razão social ou CNPJ
    pagina?: number;
    limite?: number;
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "empresas": [
      {
        "id": "uuid",
        "razao_social": "Empresa XYZ Ltda",
        "cnpj": "12345678000190",
        "status": "ativa",
        "plano_contratado": "premium",
        "limite_usuarios_simultaneos": 30,
        "data_validade": "2027-12-31",
        "criada_em": "2026-01-15T10:00:00Z"
      }
    ],
    "total": 120,
    "pagina": 1,
    "limite": 20
  }
}
```

---

### 2.2 Obter Empresa por ID

**Endpoint:** `GET /api/v1/empresas/:id`

**Perfis:** `admin_interno`, `gestor_rh` (somente própria empresa)

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "razao_social": "Empresa XYZ Ltda",
    "cnpj": "12345678000190",
    "status": "ativa",
    "plano_contratado": "premium",
    "limite_usuarios_simultaneos": 30,
    "data_validade": "2027-12-31",
    "endereco": {
      "logradouro": "Rua ABC",
      "numero": "123",
      "cidade": "São Paulo",
      "uf": "SP",
      "cep": "01234-567"
    },
    "contato": {
      "responsavel": "João Silva",
      "email": "joao@empresa.com",
      "telefone": "(11) 98765-4321"
    },
    "criada_em": "2026-01-15T10:00:00Z",
    "atualizada_em": "2026-02-20T14:30:00Z"
  }
}
```

**Erro 403:**

```json
{
  "sucesso": false,
  "erro": "acesso_negado",
  "mensagem": "Você não tem permissão para acessar esta empresa."
}
```

---

### 2.3 Criar Empresa

**Endpoint:** `POST /api/v1/empresas`

**Perfis:** `admin_interno`

**Request Body:**

```json
{
  "razao_social": "Empresa XYZ Ltda",
  "cnpj": "12345678000190",
  "plano_contratado": "premium",
  "limite_usuarios_simultaneos": 30,
  "data_validade": "2027-12-31",
  "endereco": {
    "logradouro": "Rua ABC",
    "numero": "123",
    "cidade": "São Paulo",
    "uf": "SP",
    "cep": "01234-567"
  },
  "contato": {
    "responsavel": "João Silva",
    "email": "joao@empresa.com",
    "telefone": "(11) 98765-4321"
  }
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "razao_social": "Empresa XYZ Ltda",
    "status": "ativa"
  },
  "mensagem": "Empresa criada com sucesso."
}
```

**Erro 409:**

```json
{
  "sucesso": false,
  "erro": "cnpj_duplicado",
  "mensagem": "CNPJ já cadastrado no sistema."
}
```

---

### 2.4 Atualizar Empresa

**Endpoint:** `PATCH /api/v1/empresas/:id`

**Perfis:** `admin_interno`, `gestor_rh` (campos limitados)

**Request Body (admin_interno):**

```json
{
  "razao_social": "Empresa XYZ S.A.",
  "status": "suspensa",
  "limite_usuarios_simultaneos": 50,
  "data_validade": "2028-12-31"
}
```

**Request Body (gestor_rh):**

```json
{
  "contato": {
    "responsavel": "Maria Santos",
    "email": "maria@empresa.com",
    "telefone": "(11) 99999-9999"
  }
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Empresa atualizada com sucesso."
}
```

---

### 2.5 Excluir Empresa (Soft Delete)

**Endpoint:** `DELETE /api/v1/empresas/:id`

**Perfis:** `admin_interno`

**Resposta 204:** (sem conteúdo)

---

## 3. Módulo: Colaboradores

### 3.1 Listar Colaboradores da Empresa

**Endpoint:** `GET /api/v1/empresas/:empresaId/colaboradores`

**Perfis:** `admin_interno`, `gestor_rh`

**Query Params:**

```typescript
{
    status?: 'ativo' | 'inativo';
    busca?: string; // nome ou email
    cargo?: string;
    departamento?: string;
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "colaboradores": [
      {
        "id": "uuid",
        "nome": "Maria Santos",
        "email": "maria@empresa.com",
        "cargo": "Analista",
        "departamento": "TI",
        "perfil": "aluno",
        "ativo": true,
        "criado_em": "2026-01-20T09:00:00Z"
      }
    ],
    "total": 45
  }
}
```

---

### 3.2 Convidar Colaborador

**Endpoint:** `POST /api/v1/empresas/:empresaId/colaboradores`

**Perfis:** `admin_interno`, `gestor_rh`

**Request Body:**

```json
{
  "nome": "Pedro Oliveira",
  "email": "pedro@empresa.com",
  "cargo": "Desenvolvedor",
  "departamento": "TI",
  "perfil": "aluno"
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "nome": "Pedro Oliveira",
    "email": "pedro@empresa.com",
    "convite_enviado": true
  },
  "mensagem": "Convite enviado com sucesso."
}
```

**Erro 409:**

```json
{
  "sucesso": false,
  "erro": "email_duplicado",
  "mensagem": "Email já cadastrado na empresa."
}
```

---

### 3.3 Editar Colaborador

**Endpoint:** `PATCH /api/v1/colaboradores/:id`

**Perfis:** `admin_interno`, `gestor_rh`

**Request Body:**

```json
{
  "cargo": "Analista Sênior",
  "departamento": "Operações"
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Colaborador atualizado com sucesso."
}
```

---

### 3.4 Desativar Colaborador

**Endpoint:** `PATCH /api/v1/colaboradores/:id/desativar`

**Perfis:** `admin_interno`, `gestor_rh`

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Colaborador desativado. Sessões ativas foram encerradas."
}
```

---

## 4. Módulo: Cursos

### 4.1 Listar Cursos (Catálogo Público)

**Endpoint:** `GET /api/v1/cursos`

**Perfis:** todos autenticados

**Query Params:**

```typescript
{
    status?: 'publicado';
    categoria?: string;
    nivel?: 'iniciante' | 'intermediario' | 'avancado';
    busca?: string;
    professor_id?: string;
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "cursos": [
      {
        "id": "uuid",
        "titulo": "Fundamentos de TypeScript",
        "descricao": "Aprenda TypeScript do zero.",
        "thumbnail_url": "https://...",
        "professor": {
          "id": "uuid",
          "nome": "Prof. João Silva",
          "avatar_url": "https://..."
        },
        "nivel": "iniciante",
        "carga_horaria": 20,
        "total_modulos": 5,
        "total_aulas": 30,
        "nivel": "iniciante",
        "status": "publicado",
        "criado_em": "2026-01-10T10:00:00Z"
      }
    ],
    "total": 50
  }
}
```

---

### 4.2 Obter Detalhes do Curso

**Endpoint:** `GET /api/v1/cursos/:id`

**Perfis:** todos autenticados

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "titulo": "Fundamentos de TypeScript",
    "descricao": "Aprenda TypeScript do zero.",
    "thumbnail_url": "https://...",
    "professor": {
      "id": "uuid",
      "nome": "Prof. João Silva",
      "avatar_url": "https://...",
      "bio": "Professor com 10 anos de experiência."
    },
    "nivel": "iniciante",
    "carga_horaria": 20,
    "status": "publicado",
    "modulos": [
      {
        "id": "uuid",
        "titulo": "Introdução",
        "ordem": 1,
        "aulas_count": 5
      }
    ],
    "total_alunos": 1250,
    "avaliacao_media": 4.8,
    "criado_em": "2026-01-10T10:00:00Z"
  }
}
```

---

### 4.3 Criar Curso

**Endpoint:** `POST /api/v1/cursos`

**Perfis:** `professor`, `admin_interno`

**Request Body:**

```json
{
  "titulo": "Fundamentos de React",
  "descricao": "Aprenda React do zero.",
  "thumbnail_url": "https://...",
  "nivel": "iniciante",
  "carga_horaria": 30,
  "categoria": "Programação",
  "status": "rascunho"
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "titulo": "Fundamentos de React",
    "status": "rascunho"
  },
  "mensagem": "Curso criado com sucesso."
}
```

---

### 4.4 Atualizar Curso

**Endpoint:** `PATCH /api/v1/cursos/:id`

**Perfis:** `professor` (próprio curso), `admin_interno`

**Request Body:**

```json
{
  "titulo": "Fundamentos de React - Atualizado",
  "status": "publicado"
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Curso atualizado com sucesso."
}
```

**Erro 403:**

```json
{
  "sucesso": false,
  "erro": "acesso_negado",
  "mensagem": "Você não tem permissão para editar este curso."
}
```

---

## 5. Módulo: Módulos e Aulas

### 5.1 Criar Módulo

**Endpoint:** `POST /api/v1/cursos/:cursoId/modulos`

**Perfis:** `professor` (próprio curso), `admin_interno`

**Request Body:**

```json
{
  "titulo": "Introdução ao TypeScript",
  "descricao": "Primeiros passos.",
  "ordem": 1
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "titulo": "Introdução ao TypeScript",
    "ordem": 1
  },
  "mensagem": "Módulo criado com sucesso."
}
```

---

### 5.2 Criar Aula

**Endpoint:** `POST /api/v1/modulos/:moduloId/aulas`

**Perfis:** `professor` (próprio curso), `admin_interno`

**Request Body:**

```json
{
  "titulo": "O que é TypeScript?",
  "descricao": "Introdução ao TypeScript.",
  "tipo_conteudo": "video",
  "bunny_video_id": "abc123",
  "duracao_segundos": 600,
  "ordem": 1,
  "obrigatoria": true
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "titulo": "O que é TypeScript?",
    "ordem": 1
  },
  "mensagem": "Aula criada com sucesso."
}
```

---

### 5.3 Upload de Vídeo (Bunny.net)

**Endpoint:** `POST /api/v1/aulas/:aulaId/video`

**Perfis:** `professor` (próprio curso), `admin_interno`

**Request Body (multipart/form-data):**

```
video: <arquivo_video>
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "bunny_video_id": "abc123",
    "status": "processing",
    "thumbnail_url": "https://..."
  },
  "mensagem": "Vídeo enviado para processamento."
}
```

**Nota:** Integração com Bunny.net API para upload e processamento.

---

## 6. Módulo: Matrículas

### 6.1 Matricular Aluno Individualmente

**Endpoint:** `POST /api/v1/matriculas`

**Perfis:** `admin_interno`, `gestor_rh`

**Request Body:**

```json
{
  "empresa_id": "uuid",
  "usuario_id": "uuid",
  "curso_id": "uuid"
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "matricula_id": "uuid",
    "usuario": {
      "id": "uuid",
      "nome": "Maria Santos"
    },
    "curso": {
      "id": "uuid",
      "titulo": "Fundamentos de TypeScript"
    },
    "data_matricula": "2026-02-27T10:00:00Z"
  },
  "mensagem": "Matrícula realizada com sucesso."
}
```

**Erro 409:**

```json
{
  "sucesso": false,
  "erro": "ja_matriculado",
  "mensagem": "Usuário já está matriculado neste curso."
}
```

---

### 6.2 Matricular em Lote (CSV)

**Endpoint:** `POST /api/v1/matriculas/lote`

**Perfis:** `admin_interno`, `gestor_rh`

**Request Body (multipart/form-data):**

```
arquivo: <csv_file>
empresa_id: uuid
curso_id: uuid
```

**Formato CSV:**

```csv
email,nome
maria@empresa.com,Maria Santos
joao@empresa.com,João Silva
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "total": 50,
    "matriculados": 45,
    "falhas": 3,
    "ja_matriculados": 2,
    "erros": [
      {
        "linha": 10,
        "email": "invalido@",
        "erro": "Email inválido"
      }
    ]
  },
  "mensagem": "Processamento concluído."
}
```

---

### 6.3 Cancelar Matrícula

**Endpoint:** `DELETE /api/v1/matriculas/:id`

**Perfis:** `admin_interno`, `gestor_rh`

**Resposta 204:** (sem conteúdo)

---

## 7. Módulo: Sessões Ativas

### 7.1 Validar Acesso Simultâneo

**Endpoint:** `POST /api/v1/sessoes/validar`

**Perfis:** todos autenticados

**Request Body:**

```json
{
  "curso_id": "uuid",
  "session_token": "token_gerado_frontend",
  "ip_address": "192.168.0.1",
  "user_agent": "Mozilla/5.0..."
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "sessao_id": "uuid",
    "sessoes_ativas": 25,
    "limite": 30,
    "disponivel": 5
  },
  "mensagem": "Acesso liberado."
}
```

**Erro 429:**

```json
{
  "sucesso": false,
  "erro": "limite_atingido",
  "mensagem": "Limite de acessos simultâneos atingido. Aguarde ou contate o administrador.",
  "detalhes": {
    "sessoes_ativas": 30,
    "limite": 30
  }
}
```

---

### 7.2 Heartbeat (Manter Sessão Ativa)

**Endpoint:** `PUT /api/v1/sessoes/:sessionToken/heartbeat`

**Perfis:** todos autenticados

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Sessão renovada."
}
```

**Nota:** Deve ser chamado a cada 30 segundos pelo frontend.

---

### 7.3 Encerrar Sessão (Logout)

**Endpoint:** `DELETE /api/v1/sessoes/:sessionToken`

**Perfis:** todos autenticados

**Resposta 204:** (sem conteúdo)

---

### 7.4 Listar Sessões Ativas (Empresa)

**Endpoint:** `GET /api/v1/empresas/:empresaId/sessoes`

**Perfis:** `admin_interno`, `gestor_rh`

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "sessoes_ativas": [
      {
        "id": "uuid",
        "usuario": {
          "id": "uuid",
          "nome": "Maria Santos",
          "email": "maria@empresa.com"
        },
        "curso": {
          "id": "uuid",
          "titulo": "Fundamentos de TypeScript"
        },
        "iniciada_em": "2026-02-27T10:00:00Z",
        "ultimo_heartbeat": "2026-02-27T10:15:30Z",
        "ip_address": "192.168.0.1"
      }
    ],
    "total": 25,
    "limite": 30
  }
}
```

---

### 7.5 Forçar Logout

**Endpoint:** `DELETE /api/v1/sessoes/:id/forcar`

**Perfis:** `admin_interno`, `gestor_rh`

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Sessão encerrada com sucesso."
}
```

---

## 8. Módulo: Progresso e Aulas

### 8.1 Iniciar Aula

**Endpoint:** `POST /api/v1/aulas/:aulaId/iniciar`

**Perfis:** `aluno`

**Resposta 200 (vídeo):**

```json
{
  "sucesso": true,
  "dados": {
    "tipo": "video",
    "video_token": "temp_token_bunny",
    "bunny_video_id": "abc123",
    "duracao_segundos": 600,
    "ttl_segundos": 3600,
    "thumbnail_url": "https://..."
  },
  "mensagem": "Aula iniciada."
}
```

**Resposta 200 (texto):**

```json
{
  "sucesso": true,
  "dados": {
    "tipo": "texto",
    "conteudo_texto": "<html>...</html>"
  }
}
```

**Erro 403:**

```json
{
  "sucesso": false,
  "erro": "aula_bloqueada",
  "mensagem": "Complete a aula anterior para desbloquear esta."
}
```

---

### 8.2 Marcar Aula como Concluída

**Endpoint:** `POST /api/v1/aulas/:aulaId/concluir`

**Perfis:** `aluno`

**Request Body:**

```json
{
  "tempo_assistido_segundos": 590,
  "nota_aula": 9.5
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "progresso_curso": 35.5,
    "proxima_aula": {
      "id": "uuid",
      "titulo": "Tipos Básicos"
    }
  },
  "mensagem": "Aula concluída."
}
```

---

### 8.3 Obter Próxima Aula

**Endpoint:** `GET /api/v1/cursos/:cursoId/proxima-aula`

**Perfis:** `aluno`

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "aula_id": "uuid",
    "titulo": "Interfaces",
    "modulo": "Fundamentos",
    "tipo": "video"
  }
}
```

**Resposta 200 (curso concluído):**

```json
{
  "sucesso": true,
  "dados": {
    "aula_id": null,
    "mensagem": "Curso concluído."
  }
}
```

---

## 9. Módulo: Exercícios

### 9.1 Listar Exercícios da Aula

**Endpoint:** `GET /api/v1/aulas/:aulaId/exercicios`

**Perfis:** `aluno`, `professor` (próprio curso)

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "exercicios": [
      {
        "id": "uuid",
        "enunciado": "Qual a diferença entre let e const?",
        "tipo": "multipla_escolha",
        "opcoes": [
          { "id": "a", "texto": "Let é mutável, const não" },
          { "id": "b", "texto": "Ambos são imutáveis" }
        ],
        "ordem": 1
      }
    ],
    "total": 5
  }
}
```

---

### 9.2 Responder Exercício

**Endpoint:** `POST /api/v1/exercicios/:exercicioId/responder`

**Perfis:** `aluno`

**Request Body:**

```json
{
  "resposta_selecionada": "a",
  "tempo_resposta_segundos": 45
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "correta": true,
    "explicacao_gabarito": "Correto! let permite reatribuição, const não.",
    "flashcard_gerado": false
  },
  "mensagem": "Resposta registrada."
}
```

**Resposta 200 (incorreta):**

```json
{
  "sucesso": true,
  "dados": {
    "correta": false,
    "resposta_correta": "a",
    "explicacao_gabarito": "Na verdade, let é mutável e const não.",
    "flashcard_gerado": true,
    "flashcard_id": "uuid"
  },
  "mensagem": "Resposta registrada. Flashcard criado para revisão."
}
```

---

## 10. Módulo: Flashcards

### 10.1 Listar Flashcards para Revisão

**Endpoint:** `GET /api/v1/flashcards`

**Perfis:** `aluno`

**Query Params:**

```typescript
{
    filtro?: 'hoje' | 'vencidos' | 'todos';
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "flashcards": [
      {
        "id": "uuid",
        "frente": "Qual a diferença entre let e const?",
        "verso": "let permite reatribuição, const não.",
        "dificuldade": "media",
        "proxima_revisao": "2026-02-27",
        "vezes_revisado": 3,
        "curso": {
          "id": "uuid",
          "titulo": "Fundamentos de TypeScript"
        }
      }
    ],
    "total": 15,
    "vencidos": 5
  }
}
```

---

### 10.2 Avaliar Flashcard (Repetição Espaçada)

**Endpoint:** `POST /api/v1/flashcards/:id/avaliar`

**Perfis:** `aluno`

**Request Body:**

```json
{
  "dificuldade": "facil"
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "proxima_revisao": "2026-03-06",
    "intervalo_dias": 7
  },
  "mensagem": "Flashcard avaliado."
}
```

---

## 11. Módulo: Certificados

### 11.1 Listar Certificados do Aluno

**Endpoint:** `GET /api/v1/certificados`

**Perfis:** `aluno`

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "certificados": [
      {
        "id": "uuid",
        "curso": {
          "id": "uuid",
          "titulo": "Fundamentos de TypeScript",
          "carga_horaria": 20
        },
        "codigo_validacao": "CRT-ABC123",
        "nota_final": 95.5,
        "data_emissao": "2026-02-25T10:00:00Z",
        "pdf_url": "https://..."
      }
    ],
    "total": 3
  }
}
```

---

### 11.2 Baixar Certificado (PDF)

**Endpoint:** `GET /api/v1/certificados/:id/download`

**Perfis:** `aluno` (próprio), `gestor_rh` (empresa), `admin_interno`

**Resposta 200:**

```
Content-Type: application/pdf
Content-Disposition: attachment; filename="certificado_abc123.pdf"

<binary_pdf_data>
```

---

### 11.3 Validar Certificado (Público)

**Endpoint:** `GET /api/v1/certificados/validar/:codigo`

**Perfis:** público (sem autenticação)

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "valido": true,
    "aluno": {
      "nome": "Maria Santos"
    },
    "curso": {
      "titulo": "Fundamentos de TypeScript",
      "carga_horaria": 20
    },
    "nota_final": 95.5,
    "data_emissao": "2026-02-25",
    "codigo_validacao": "CRT-ABC123"
  }
}
```

**Resposta 404:**

```json
{
  "sucesso": false,
  "erro": "certificado_nao_encontrado",
  "mensagem": "Código de validação inválido."
}
```

---

## 12. Módulo: Relatórios

### 12.1 Relatório de Progresso (RH)

**Endpoint:** `GET /api/v1/relatorios/progresso`

**Perfis:** `admin_interno`, `gestor_rh`

**Query Params:**

```typescript
{
    empresa_id: string;
    curso_id?: string;
    data_inicio?: string;
    data_fim?: string;
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "colaboradores": [
      {
        "usuario_id": "uuid",
        "nome": "Maria Santos",
        "email": "maria@empresa.com",
        "curso": "Fundamentos de TypeScript",
        "progresso_percentual": 75.5,
        "status": "em_andamento",
        "data_matricula": "2026-02-01",
        "ultima_atividade": "2026-02-27T09:30:00Z"
      }
    ],
    "metricas": {
      "total_colaboradores": 45,
      "em_andamento": 30,
      "concluidos": 10,
      "nao_iniciados": 5,
      "progresso_medio": 62.8
    }
  }
}
```

---

### 12.2 Exportar Relatório (CSV)

**Endpoint:** `GET /api/v1/relatorios/exportar`

**Perfis:** `admin_interno`, `gestor_rh`

**Query Params:** (mesmos do relatório de progresso)

**Resposta 200:**

```
Content-Type: text/csv
Content-Disposition: attachment; filename="relatorio_progresso.csv"

nome,email,curso,progresso,status,data_matricula
Maria Santos,maria@empresa.com,Fundamentos de TypeScript,75.5,em_andamento,2026-02-01
```

---

## 13. Módulo: Anotações

### 13.1 Criar Anotação

**Endpoint:** `POST /api/v1/anotacoes`

**Perfis:** `aluno`

**Request Body:**

```json
{
  "aula_id": "uuid",
  "conteudo": "Importante lembrar: let vs const",
  "timestamp_video_segundos": 120
}
```

**Resposta 201:**

```json
{
  "sucesso": true,
  "dados": {
    "id": "uuid",
    "conteudo": "Importante lembrar: let vs const",
    "timestamp_video_segundos": 120,
    "criada_em": "2026-02-27T10:30:00Z"
  },
  "mensagem": "Anotação criada."
}
```

---

### 13.2 Listar Anotações

**Endpoint:** `GET /api/v1/anotacoes`

**Perfis:** `aluno`

**Query Params:**

```typescript
{
    aula_id?: string;
    curso_id?: string;
    busca?: string;
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "dados": {
    "anotacoes": [
      {
        "id": "uuid",
        "conteudo": "Importante lembrar: let vs const",
        "aula": {
          "id": "uuid",
          "titulo": "Variáveis em TypeScript"
        },
        "timestamp_video_segundos": 120,
        "criada_em": "2026-02-27T10:30:00Z"
      }
    ],
    "total": 10
  }
}
```

---

## 14. Webhooks e Eventos

### 14.1 Webhook Bunny.net (Vídeo Processado)

**Endpoint:** `POST /api/webhooks/bunny/video-processed`

**Autenticação:** Bunny.net Webhook Secret

**Payload:**

```json
{
  "videoId": "abc123",
  "status": "ready",
  "thumbnailUrl": "https://...",
  "duration": 600
}
```

**Resposta 200:**

```json
{
  "sucesso": true,
  "mensagem": "Webhook processado."
}
```

---

## 15. Checklist de Implementação

- [ ] Criar Netlify Functions para cada endpoint
- [ ] Implementar validação de schemas (Zod)
- [ ] Implementar middlewares de autenticação/autorização
- [ ] Criar handlers de erro padronizados
- [ ] Implementar rate limiting
- [ ] Documentar endpoints com OpenAPI/Swagger
- [ ] Criar testes de integração
- [ ] Implementar logging estruturado (Winston/Pino)
- [ ] Configurar CORS adequadamente
- [ ] Implementar cache (Redis) para endpoints críticos

---

## 16. Segurança

### 16.1 Rate Limiting

```typescript
// Limite de requisições por endpoint
const rateLimits = {
  '/api/v1/sessoes/validar': '10/minuto',
  '/api/v1/matriculas/lote': '5/hora',
  '/api/v1/aulas/:id/iniciar': '30/minuto',
}
```

### 16.2 Validação de Input

```typescript
// Usar Zod para validação
const schemaCriarEmpresa = z.object({
  razao_social: z.string().min(3).max(100),
  cnpj: z.string().regex(/^\d{14}$/),
  limite_usuarios_simultaneos: z.number().min(1).max(1000),
})
```

### 16.3 Headers de Segurança

```typescript
// Helmet.js para headers de segurança
app.use(helmet())
```

---

## 17. Próximos Passos

- [ ] Criar collection do Postman/Insomnia
- [ ] Implementar documentação interativa (Swagger UI)
- [ ] Criar guia de integração para desenvolvedores
- [ ] Validar contratos de API com stakeholders
