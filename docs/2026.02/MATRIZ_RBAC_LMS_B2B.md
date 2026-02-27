# Matriz RBAC - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (não implementado)  
**Base:** SCHEMA_TABELAS_LMS_B2B.md + POLITICAS_RLS_LMS_B2B.md

---

## 1. Perfis do Sistema

| Perfil          | Descrição                                            | Contexto        |
| --------------- | ---------------------------------------------------- | --------------- |
| `admin_interno` | Equipe CCI-CA (suporte, financeiro, desenvolvimento) | Global          |
| `professor`     | Professores autônomos criadores de conteúdo          | Multi-tenant    |
| `gestor_rh`     | Gestor RH da empresa contratante                     | Tenant-specific |
| `aluno`         | Colaborador da empresa (estudante)                   | Tenant-specific |

---

## 2. Módulos e Funcionalidades

### 2.1 Módulo: Gestão de Empresas

| Funcionalidade                            | Admin Interno | Professor | Gestor RH     | Aluno            |
| ----------------------------------------- | ------------- | --------- | ------------- | ---------------- |
| Listar todas empresas                     | ✅            | ❌        | ❌            | ❌               |
| Ver dados da própria empresa              | ✅            | ❌        | ✅ (readonly) | ✅ (nome/status) |
| Criar empresa                             | ✅            | ❌        | ❌            | ❌               |
| Editar empresa (dados gerais)             | ✅            | ❌        | ❌            | ❌               |
| Editar empresa (configurações RH)         | ✅            | ❌        | ✅ (limitado) | ❌               |
| Configurar limite de usuários simultâneos | ✅            | ❌        | ❌            | ❌               |
| Suspender/reativar empresa                | ✅            | ❌        | ❌            | ❌               |
| Excluir empresa (soft delete)             | ✅            | ❌        | ❌            | ❌               |

**Routes:**

- `/admin/empresas` → Admin interno
- `/app/empresa/perfil` → Gestor RH (readonly)

---

### 2.2 Módulo: Gestão de Usuários/Colaboradores

| Funcionalidade                        | Admin Interno | Professor          | Gestor RH | Aluno |
| ------------------------------------- | ------------- | ------------------ | --------- | ----- |
| Listar todos usuários (global)        | ✅            | ❌                 | ❌        | ❌    |
| Listar colaboradores da empresa       | ✅            | ❌                 | ✅        | ❌    |
| Convidar colaborador                  | ✅            | ❌                 | ✅        | ❌    |
| Editar perfil de colaborador          | ✅            | ❌                 | ✅        | ❌    |
| Desativar colaborador                 | ✅            | ❌                 | ✅        | ❌    |
| Ver relatório de progresso individual | ✅            | ✅ (próprio curso) | ✅        | ❌    |
| Ver certificados de colaborador       | ✅            | ✅ (próprio curso) | ✅        | ❌    |
| Editar próprio perfil                 | ✅            | ✅                 | ✅        | ✅    |

**Routes:**

- `/admin/empresas/:id/colaboradores` → Admin interno
- `/app/rh/colaboradores` → Gestor RH
- `/app/perfil` → Aluno

---

### 2.3 Módulo: Gestão de Cursos

| Funcionalidade                      | Admin Interno | Professor        | Gestor RH | Aluno |
| ----------------------------------- | ------------- | ---------------- | --------- | ----- |
| Listar todos cursos                 | ✅            | ❌               | ❌        | ❌    |
| Listar cursos publicados (catálogo) | ✅            | ✅               | ✅        | ✅    |
| Ver detalhes de qualquer curso      | ✅            | ❌               | ❌        | ❌    |
| Ver detalhes cursos próprios        | ✅            | ✅               | ❌        | ❌    |
| Ver detalhes curso matriculado      | ✅            | ✅ (se for dele) | ❌        | ✅    |
| Criar curso                         | ✅            | ✅               | ❌        | ❌    |
| Editar curso próprio                | ✅            | ✅               | ❌        | ❌    |
| Editar qualquer curso               | ✅            | ❌               | ❌        | ❌    |
| Publicar/despublicar curso          | ✅            | ✅ (próprio)     | ❌        | ❌    |
| Excluir curso                       | ✅            | ❌               | ❌        | ❌    |
| Duplicar curso                      | ✅            | ✅ (próprio)     | ❌        | ❌    |

**Routes:**

- `/admin/cursos` → Admin interno
- `/professor/cursos` → Professor
- `/app/catalogo` → Gestor RH, Aluno
- `/app/meus-cursos` → Aluno (matriculado)

---

### 2.4 Módulo: Gestão de Conteúdo (Módulos/Aulas)

| Funcionalidade                    | Admin Interno | Professor          | Gestor RH | Aluno            |
| --------------------------------- | ------------- | ------------------ | --------- | ---------------- |
| Ver estrutura de módulos/aulas    | ✅            | ✅ (próprio curso) | ❌        | ✅ (matriculado) |
| Criar módulo                      | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Editar módulo                     | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Reordenar módulos                 | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Excluir módulo                    | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Criar aula                        | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Editar aula                       | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Upload de vídeo (Bunny.net)       | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Reordenar aulas                   | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Marcar aula como obrigatória      | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Excluir aula                      | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Acessar conteúdo da aula (player) | ✅            | ✅ (preview)       | ❌        | ✅ (liberada)    |

**Routes:**

- `/professor/cursos/:id/modulos` → Professor
- `/app/player/:cursoId/:aulaId` → Aluno

---

### 2.5 Módulo: Mapas Mentais

| Funcionalidade               | Admin Interno | Professor          | Gestor RH | Aluno            |
| ---------------------------- | ------------- | ------------------ | --------- | ---------------- |
| Ver mapas mentais de aula    | ✅            | ✅ (próprio curso) | ❌        | ✅ (matriculado) |
| Criar mapa mental            | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Editar mapa mental           | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Excluir mapa mental          | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Baixar mapa mental (PDF/PNG) | ✅            | ✅                 | ❌        | ✅               |

**Routes:**

- `/app/player/:cursoId/:aulaId/mapa` → Aluno
- `/professor/cursos/:id/aulas/:aulaId/mapa` → Professor

---

### 2.6 Módulo: Exercícios

| Funcionalidade                         | Admin Interno | Professor          | Gestor RH | Aluno            |
| -------------------------------------- | ------------- | ------------------ | --------- | ---------------- |
| Ver exercícios de aula                 | ✅            | ✅ (próprio curso) | ❌        | ✅ (matriculado) |
| Criar exercício                        | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Editar exercício                       | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Excluir exercício                      | ✅            | ✅ (próprio curso) | ❌        | ❌               |
| Responder exercício                    | ✅ (teste)    | ✅ (teste)         | ❌        | ✅               |
| Ver gabarito (após responder)          | ✅            | ✅                 | ❌        | ✅               |
| Ver estatísticas de exercícios (curso) | ✅            | ✅ (próprio curso) | ✅        | ❌               |

**Routes:**

- `/app/player/:cursoId/:aulaId/exercicios` → Aluno
- `/professor/cursos/:id/aulas/:aulaId/exercicios` → Professor

---

### 2.7 Módulo: Flashcards de Revisão

| Funcionalidade                | Admin Interno | Professor | Gestor RH | Aluno        |
| ----------------------------- | ------------- | --------- | --------- | ------------ |
| Ver flashcards próprios       | ✅            | ✅        | ❌        | ✅           |
| Criar flashcard manual        | ✅            | ✅        | ❌        | ✅           |
| Editar flashcard              | ✅            | ✅        | ❌        | ✅ (próprio) |
| Excluir flashcard             | ✅            | ✅        | ❌        | ✅ (próprio) |
| Sistema de repetição espaçada | ✅            | ✅        | ❌        | ✅           |
| Ver estatísticas de revisão   | ✅            | ✅        | ❌        | ✅           |

**Routes:**

- `/app/flashcards` → Aluno
- `/app/flashcards/revisar` → Aluno

---

### 2.8 Módulo: Anotações

| Funcionalidade                       | Admin Interno | Professor | Gestor RH | Aluno        |
| ------------------------------------ | ------------- | --------- | --------- | ------------ |
| Ver anotações próprias               | ✅            | ✅        | ❌        | ✅           |
| Criar anotação em aula               | ✅            | ✅        | ❌        | ✅           |
| Criar anotação com timestamp (vídeo) | ✅            | ✅        | ❌        | ✅           |
| Editar anotação                      | ✅            | ✅        | ❌        | ✅ (própria) |
| Excluir anotação                     | ✅            | ✅        | ❌        | ✅ (própria) |
| Buscar em anotações                  | ✅            | ✅        | ❌        | ✅           |

**Routes:**

- `/app/anotacoes` → Aluno
- `/app/player/:cursoId/:aulaId` (painel lateral) → Aluno

---

### 2.9 Módulo: Matrículas e Licenças (B2B)

| Funcionalidade                             | Admin Interno | Professor          | Gestor RH | Aluno |
| ------------------------------------------ | ------------- | ------------------ | --------- | ----- |
| Ver licenças contratadas (empresa)         | ✅            | ❌                 | ✅        | ❌    |
| Configurar limite de usuários simultâneos  | ✅            | ❌                 | ❌        | ❌    |
| Matricular colaborador individualmente     | ✅            | ❌                 | ✅        | ❌    |
| Matricular colaboradores em lote (CSV)     | ✅            | ❌                 | ✅        | ❌    |
| Cancelar matrícula                         | ✅            | ❌                 | ✅        | ❌    |
| Ver relatório de matrículas ativas         | ✅            | ✅ (próprio curso) | ✅        | ❌    |
| Ver painel de sessões ativas em tempo real | ✅            | ❌                 | ✅        | ❌    |
| Forçar logout de sessão                    | ✅            | ❌                 | ✅        | ❌    |

**Routes:**

- `/admin/empresas/:id/licencas` → Admin interno
- `/app/rh/licencas` → Gestor RH
- `/app/rh/matriculas` → Gestor RH
- `/app/rh/sessoes-ativas` → Gestor RH

---

### 2.10 Módulo: Progresso e Relatórios

| Funcionalidade                          | Admin Interno | Professor          | Gestor RH | Aluno |
| --------------------------------------- | ------------- | ------------------ | --------- | ----- |
| Ver progresso próprio                   | ✅            | ✅                 | ✅        | ✅    |
| Ver progresso de colaborador específico | ✅            | ✅ (curso dele)    | ✅        | ❌    |
| Relatório geral de progresso da empresa | ✅            | ❌                 | ✅        | ❌    |
| Relatório de conclusão de curso         | ✅            | ✅ (próprio curso) | ✅        | ❌    |
| Exportar relatório (CSV/PDF)            | ✅            | ✅                 | ✅        | ❌    |
| Dashboard de métricas (empresa)         | ✅            | ❌                 | ✅        | ❌    |
| Dashboard de métricas (curso)           | ✅            | ✅ (próprio)       | ❌        | ❌    |

**Routes:**

- `/admin/relatorios` → Admin interno
- `/professor/cursos/:id/relatorios` → Professor
- `/app/rh/relatorios` → Gestor RH
- `/app/meus-cursos` (dashboard) → Aluno

---

### 2.11 Módulo: Certificados

| Funcionalidade                          | Admin Interno          | Professor       | Gestor RH | Aluno        |
| --------------------------------------- | ---------------------- | --------------- | --------- | ------------ |
| Ver certificados próprios               | ✅                     | ✅              | ✅        | ✅           |
| Ver certificados de colaborador         | ✅                     | ✅ (curso dele) | ✅        | ❌           |
| Baixar certificado (PDF)                | ✅                     | ✅              | ✅        | ✅ (próprio) |
| Reemitir certificado                    | ✅                     | ❌              | ❌        | ❌           |
| Validar certificado (QR Code)           | 🟡 (público, sem auth) | 🟡              | 🟡        | 🟡           |
| Ver histórico de certificados (empresa) | ✅                     | ❌              | ✅        | ❌           |

**Routes:**

- `/app/certificados` → Aluno
- `/app/rh/certificados` → Gestor RH
- `/validar/:codigo` → Público (sem autenticação)

---

### 2.12 Módulo: Sessões Ativas (Controle de Simultaneidade)

| Funcionalidade                | Admin Interno | Professor | Gestor RH | Aluno |
| ----------------------------- | ------------- | --------- | --------- | ----- |
| Ver sessões ativas da empresa | ✅            | ❌        | ✅        | ❌    |
| Ver sessões ativas globais    | ✅            | ❌        | ❌        | ❌    |
| Ver própria sessão ativa      | ✅            | ✅        | ✅        | ✅    |
| Forçar logout de sessão       | ✅            | ❌        | ✅        | ❌    |
| Ver histórico de acessos      | ✅            | ❌        | ✅        | ❌    |
| Alertas de limite atingido    | ✅            | ❌        | ✅        | ❌    |

**Routes:**

- `/admin/sessoes` → Admin interno
- `/app/rh/sessoes-ativas` → Gestor RH

---

## 3. Matriz de Permissões por Tabela

### Legenda:

- ✅ = Full access (CRUD)
- 🔍 = Read-only
- 🔒 = Scoped (somente próprio registro)
- ❌ = No access

| Tabela                       | Admin | Professor       | Gestor RH            | Aluno              |
| ---------------------------- | ----- | --------------- | -------------------- | ------------------ |
| `empresas`                   | ✅    | ❌              | 🔍 (própria)         | 🔍 (nome/status)   |
| `empresa_usuarios`           | ✅    | ❌              | ✅ (própria empresa) | 🔍 (próprio)       |
| `sessoes_ativas`             | ✅    | ❌              | ✅ (própria empresa) | 🔒 (própria)       |
| `cursos`                     | ✅    | ✅ (próprios)   | 🔍 (catálogo)        | 🔍 (matriculado)   |
| `modulos`                    | ✅    | ✅ (curso dele) | ❌                   | 🔍 (matriculado)   |
| `aulas`                      | ✅    | ✅ (curso dele) | ❌                   | 🔍 (liberada)      |
| `usuario_curso`              | ✅    | 🔍 (curso dele) | ✅ (empresa)         | 🔍 (próprio)       |
| `usuario_aula_progresso`     | ✅    | 🔍 (curso dele) | 🔍 (empresa)         | 🔒 (próprio)       |
| `mapas_mentais`              | ✅    | ✅ (curso dele) | ❌                   | 🔍 (aula liberada) |
| `anotacoes_aluno`            | ✅    | ❌              | ❌                   | 🔒 (própria)       |
| `exercicios`                 | ✅    | ✅ (curso dele) | ❌                   | 🔍 (aula liberada) |
| `usuario_exercicio_resposta` | ✅    | 🔍 (curso dele) | ❌                   | 🔒 (própria)       |
| `flashcards_revisao`         | ✅    | ❌              | ❌                   | 🔒 (próprio)       |
| `certificados`               | ✅    | 🔍 (curso dele) | 🔍 (empresa)         | 🔍 (próprio)       |

---

## 4. Fluxo de Autenticação e Autorização

### 4.1 Login e Validação de Perfil

```typescript
// Após login via Supabase Auth
const session = await supabase.auth.getSession()
const user = session.data.user

// Obter perfil do usuário
const perfil = user.user_metadata?.perfil // 'admin_interno' | 'professor' | 'gestor_rh' | 'aluno'

// Se for tenant-specific, obter empresa
let empresa_id = null
if (['gestor_rh', 'aluno'].includes(perfil)) {
  const { data } = await supabase
    .from('empresa_usuarios')
    .select('empresa_id')
    .eq('usuario_id', user.id)
    .eq('ativo', true)
    .single()
  empresa_id = data?.empresa_id
}
```

### 4.2 Validação de Acesso a Rota

```typescript
// middleware/auth.ts
export function requiredPerfis(...perfis: string[]) {
  return (req, res, next) => {
    const userPerfil = req.user?.perfil
    if (!perfis.includes(userPerfil)) {
      return res.status(403).json({ erro: 'acesso_negado' })
    }
    next()
  }
}

// Uso em rota
app.get('/app/rh/licencas', requiredPerfis('gestor_rh', 'admin_interno'), listarLicencas)
```

### 4.3 Validação de Acesso Simultâneo (Aluno)

```typescript
// Ao acessar player de aula
const resultado = await supabase.rpc('rpc_validar_acesso_simultaneo', {
  p_usuario_id: user.id,
  p_curso_id: cursoId,
  p_session_token: sessionToken,
  p_ip_address: req.ip,
  p_user_agent: req.headers['user-agent'],
})

if (!resultado.data.sucesso) {
  if (resultado.data.erro === 'limite_atingido') {
    return res.status(429).json({
      erro: 'limite_simultaneo_atingido',
      mensagem: 'Limite de acessos simultâneos atingido. Aguarde ou contate o administrador.',
      sessoes_ativas: resultado.data.sessoes_ativas,
      limite: resultado.data.limite,
    })
  }
}
```

---

## 5. Componentes de UI com RBAC

### 5.1 Hook de Permissões

```typescript
// hooks/usePermissoes.ts
export const usePermissoes = () => {
  const { user } = useAuth()
  const perfil = user?.user_metadata?.perfil

  const pode = (acao: string, contexto?: any) => {
    // Implementar lógica de verificação baseada em matriz RBAC
    const regras = {
      'empresas.criar': ['admin_interno'],
      'empresas.editar': ['admin_interno'],
      'empresas.ver_propria': ['admin_interno', 'gestor_rh', 'aluno'],
      'colaboradores.listar': ['admin_interno', 'gestor_rh'],
      'colaboradores.convidar': ['admin_interno', 'gestor_rh'],
      'cursos.criar': ['admin_interno', 'professor'],
      'cursos.editar_proprio': ['admin_interno', 'professor'],
      'cursos.ver_catalogovale': ['admin_interno', 'professor', 'gestor_rh', 'aluno'],
      'matriculas.criar': ['admin_interno', 'gestor_rh'],
      'sessoes.forcar_logout': ['admin_interno', 'gestor_rh'],
      'certificados.reemitir': ['admin_interno'],
    }

    return regras[acao]?.includes(perfil) || false
  }

  return { pode, perfil }
}
```

### 5.2 Componente Protegido

```typescript
// components/ProtectedRoute.tsx
export const ProtectedRoute = ({ perfisPermitidos, children }) => {
    const { perfil } = usePermissoes();

    if (!perfisPermitidos.includes(perfil)) {
        return <Navigate to="/acesso-negado" />;
    }

    return children;
};

// Uso
<ProtectedRoute perfisPermitidos={['admin_interno', 'gestor_rh']}>
    <GerenciarColaboradores />
</ProtectedRoute>
```

### 5.3 Renderização Condicional

```typescript
// Exemplo: Botão de forçar logout (apenas admin e gestor RH)
const { pode } = usePermissoes();

return (
    <div>
        {pode('sessoes.forcar_logout') && (
            <Button onClick={forcarLogout}>
                Forçar Logout
            </Button>
        )}
    </div>
);
```

---

## 6. Endpoints da API com RBAC

### 6.1 Convenções de Nomenclatura

```
GET    /api/v1/empresas                    → Listar empresas (admin)
GET    /api/v1/empresas/:id                → Ver empresa (admin, gestor_rh da empresa)
POST   /api/v1/empresas                    → Criar empresa (admin)
PATCH  /api/v1/empresas/:id                → Editar empresa (admin)
DELETE /api/v1/empresas/:id                → Deletar empresa (admin)

GET    /api/v1/empresas/:id/colaboradores  → Listar colaboradores (admin, gestor_rh)
POST   /api/v1/empresas/:id/colaboradores  → Convidar colaborador (admin, gestor_rh)

POST   /api/v1/matriculas                  → Matricular aluno (admin, gestor_rh)
POST   /api/v1/matriculas/lote             → Matricular lote (admin, gestor_rh)

GET    /api/v1/sessoes/ativas              → Listar sessões (admin, gestor_rh)
POST   /api/v1/sessoes/validar             → Validar simultaneidade (todos autenticados)
DELETE /api/v1/sessoes/:id                 → Encerrar sessão (admin, gestor_rh, próprio aluno)
```

### 6.2 Exemplo de Endpoint Protegido

```typescript
// routes/empresas.ts
router.get(
  '/:id/licencas',
  authenticate,
  requiredPerfis('admin_interno', 'gestor_rh'),
  validarAcessoEmpresa,
  async (req, res) => {
    const { id } = req.params

    // RLS do Supabase já filtra por empresa
    const { data } = await supabase
      .from('empresas')
      .select('limite_usuarios_simultaneos, sessoes_ativas_count')
      .eq('id', id)
      .single()

    res.json(data)
  }
)
```

---

## 7. Checklist de Implementação

- [ ] Criar user_metadata com campo `perfil` no Supabase Auth
- [ ] Implementar hook `usePermissoes`
- [ ] Criar componente `ProtectedRoute`
- [ ] Criar middleware de autenticação/autorização
- [ ] Mapear todas as rotas com perfis permitidos
- [ ] Implementar validação de acesso em cada endpoint da API
- [ ] Testes automatizados de RBAC (cada perfil)
- [ ] Documentar matriz de permissões para usuários finais

---

## 8. Próximos Passos

- [ ] Criar mapa de telas e rotas (MAPA_ROTAS_UI.md)
- [ ] Especificar endpoints da API (ENDPOINTS_API_LMS_B2B.md)
- [ ] Implementar testes E2E de fluxos por perfil
- [ ] Criar guia de onboarding para cada perfil
