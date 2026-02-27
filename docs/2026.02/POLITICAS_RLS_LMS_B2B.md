# Políticas RLS Detalhadas - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (não implementado)  
**Base:** SCHEMA_TABELAS_LMS_B2B.md + FUNCOES_TRIGGERS_LMS_B2B.md

---

## 1. Convenções

### Habilitação RLS

```sql
ALTER TABLE [nome_tabela] ENABLE ROW LEVEL SECURITY;
```

### Políticas DEFAULT DENY

Por padrão, **nenhum acesso** é permitido. Policies liberam acesso específico.

```sql
-- Bloqueia tudo por padrão
ALTER TABLE [nome_tabela] FORCE ROW LEVEL SECURITY;
```

---

## 2. Tabela: `empresas`

### Habilitar RLS

```sql
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Admin interno vê todas

```sql
CREATE POLICY pol_empresas_select_admin
ON empresas
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### SELECT: Gestor RH vê apenas sua empresa

```sql
CREATE POLICY pol_empresas_select_gestor
ON empresas
FOR SELECT
TO authenticated
USING (
    id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(id)
);
```

#### SELECT: Aluno vê apenas status e nome da própria empresa

```sql
CREATE POLICY pol_empresas_select_aluno
ON empresas
FOR SELECT
TO authenticated
USING (
    id = get_empresa_id_do_usuario(auth.uid())
);
```

#### INSERT: Apenas admin interno

```sql
CREATE POLICY pol_empresas_insert_admin
ON empresas
FOR INSERT
TO authenticated
WITH CHECK (is_admin_interno());
```

#### UPDATE: Admin interno atualiza qualquer

```sql
CREATE POLICY pol_empresas_update_admin
ON empresas
FOR UPDATE
TO authenticated
USING (is_admin_interno())
WITH CHECK (is_admin_interno());
```

#### UPDATE: Gestor RH atualiza apenas campos permitidos da própria empresa

```sql
CREATE POLICY pol_empresas_update_gestor
ON empresas
FOR UPDATE
TO authenticated
USING (
    id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(id)
)
WITH CHECK (
    id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(id)
    -- Implementar validação de campos permitidos via trigger
);
```

#### DELETE: Apenas admin interno (soft delete)

```sql
CREATE POLICY pol_empresas_delete_admin
ON empresas
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 3. Tabela: `empresa_usuarios`

### Habilitar RLS

```sql
ALTER TABLE empresa_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresa_usuarios FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Admin interno vê todos

```sql
CREATE POLICY pol_empresa_usuarios_select_admin
ON empresa_usuarios
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### SELECT: Gestor RH vê apenas da própria empresa

```sql
CREATE POLICY pol_empresa_usuarios_select_gestor
ON empresa_usuarios
FOR SELECT
TO authenticated
USING (
    empresa_id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(empresa_id)
);
```

#### SELECT: Aluno vê apenas seu próprio vínculo

```sql
CREATE POLICY pol_empresa_usuarios_select_aluno
ON empresa_usuarios
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### INSERT: Admin interno ou Gestor RH da empresa

```sql
CREATE POLICY pol_empresa_usuarios_insert_gestores
ON empresa_usuarios
FOR INSERT
TO authenticated
WITH CHECK (
    is_admin_interno()
    OR is_gestor_rh_da_empresa(empresa_id)
);
```

#### UPDATE: Admin interno ou Gestor RH da empresa

```sql
CREATE POLICY pol_empresa_usuarios_update_gestores
ON empresa_usuarios
FOR UPDATE
TO authenticated
USING (
    is_admin_interno()
    OR is_gestor_rh_da_empresa(empresa_id)
)
WITH CHECK (
    is_admin_interno()
    OR is_gestor_rh_da_empresa(empresa_id)
);
```

#### DELETE: Apenas admin interno

```sql
CREATE POLICY pol_empresa_usuarios_delete_admin
ON empresa_usuarios
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 4. Tabela: `sessoes_ativas`

### Habilitar RLS

```sql
ALTER TABLE sessoes_ativas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessoes_ativas FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Admin interno vê todas

```sql
CREATE POLICY pol_sessoes_ativas_select_admin
ON sessoes_ativas
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### SELECT: Gestor RH vê apenas da própria empresa

```sql
CREATE POLICY pol_sessoes_ativas_select_gestor
ON sessoes_ativas
FOR SELECT
TO authenticated
USING (
    empresa_id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(empresa_id)
);
```

#### SELECT: Aluno vê apenas suas próprias sessões

```sql
CREATE POLICY pol_sessoes_ativas_select_aluno
ON sessoes_ativas
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### INSERT: Via RPC `rpc_validar_acesso_simultaneo` (SECURITY DEFINER)

```sql
-- Nenhuma policy direta de INSERT para usuários
-- Apenas funções SECURITY DEFINER podem inserir
```

#### UPDATE: Apenas função de heartbeat

```sql
-- Policy para permitir heartbeat do próprio usuário
CREATE POLICY pol_sessoes_ativas_update_heartbeat
ON sessoes_ativas
FOR UPDATE
TO authenticated
USING (usuario_id = auth.uid())
WITH CHECK (usuario_id = auth.uid());
```

#### DELETE: Via RPC de logout ou limpeza automática

```sql
-- Aluno pode deletar sua própria sessão (logout)
CREATE POLICY pol_sessoes_ativas_delete_aluno
ON sessoes_ativas
FOR DELETE
TO authenticated
USING (usuario_id = auth.uid());
```

---

## 5. Tabela: `cursos`

### Habilitar RLS

```sql
ALTER TABLE cursos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cursos FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Todos autenticados veem cursos publicados

```sql
CREATE POLICY pol_cursos_select_todos
ON cursos
FOR SELECT
TO authenticated
USING (
    status = 'publicado'
    AND deletado_em IS NULL
);
```

#### SELECT: Professor vê seus próprios cursos (qualquer status)

```sql
CREATE POLICY pol_cursos_select_professor
ON cursos
FOR SELECT
TO authenticated
USING (professor_id = auth.uid());
```

#### SELECT: Admin interno vê todos

```sql
CREATE POLICY pol_cursos_select_admin
ON cursos
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### INSERT: Apenas professor pode criar curso

```sql
CREATE POLICY pol_cursos_insert_professor
ON cursos
FOR INSERT
TO authenticated
WITH CHECK (professor_id = auth.uid());
```

#### UPDATE: Professor atualiza apenas seus cursos

```sql
CREATE POLICY pol_cursos_update_professor
ON cursos
FOR UPDATE
TO authenticated
USING (professor_id = auth.uid())
WITH CHECK (professor_id = auth.uid());
```

#### UPDATE: Admin interno atualiza qualquer

```sql
CREATE POLICY pol_cursos_update_admin
ON cursos
FOR UPDATE
TO authenticated
USING (is_admin_interno())
WITH CHECK (is_admin_interno());
```

#### DELETE: Apenas admin interno (soft delete)

```sql
CREATE POLICY pol_cursos_delete_admin
ON cursos
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 6. Tabela: `modulos`

### Habilitar RLS

```sql
ALTER TABLE modulos ENABLE ROW LEVEL SECURITY;
ALTER TABLE modulos FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno matriculado no curso vê módulos

```sql
CREATE POLICY pol_modulos_select_aluno
ON modulos
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM usuario_curso uc
        WHERE uc.usuario_id = auth.uid()
        AND uc.curso_id = modulos.curso_id
        AND uc.status NOT IN ('bloqueado', 'expirado')
    )
);
```

#### SELECT: Professor do curso vê módulos

```sql
CREATE POLICY pol_modulos_select_professor
ON modulos
FOR SELECT
TO authenticated
USING (is_professor_do_curso(curso_id));
```

#### SELECT: Admin interno vê todos

```sql
CREATE POLICY pol_modulos_select_admin
ON modulos
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### INSERT: Professor do curso

```sql
CREATE POLICY pol_modulos_insert_professor
ON modulos
FOR INSERT
TO authenticated
WITH CHECK (is_professor_do_curso(curso_id));
```

#### UPDATE: Professor do curso

```sql
CREATE POLICY pol_modulos_update_professor
ON modulos
FOR UPDATE
TO authenticated
USING (is_professor_do_curso(curso_id))
WITH CHECK (is_professor_do_curso(curso_id));
```

#### DELETE: Admin interno ou professor do curso

```sql
CREATE POLICY pol_modulos_delete_professor
ON modulos
FOR DELETE
TO authenticated
USING (
    is_admin_interno()
    OR is_professor_do_curso(curso_id)
);
```

---

## 7. Tabela: `aulas`

### Habilitar RLS

```sql
ALTER TABLE aulas ENABLE ROW LEVEL SECURITY;
ALTER TABLE aulas FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno matriculado vê aulas

```sql
CREATE POLICY pol_aulas_select_aluno
ON aulas
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM modulos m
        JOIN usuario_curso uc ON uc.curso_id = m.curso_id
        WHERE m.id = aulas.modulo_id
        AND uc.usuario_id = auth.uid()
        AND uc.status NOT IN ('bloqueado', 'expirado')
    )
);
```

#### SELECT: Professor do curso vê aulas

```sql
CREATE POLICY pol_aulas_select_professor
ON aulas
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM modulos m
        WHERE m.id = aulas.modulo_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### SELECT: Admin interno vê todas

```sql
CREATE POLICY pol_aulas_select_admin
ON aulas
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### INSERT: Professor do curso

```sql
CREATE POLICY pol_aulas_insert_professor
ON aulas
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM modulos m
        WHERE m.id = aulas.modulo_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### UPDATE: Professor do curso

```sql
CREATE POLICY pol_aulas_update_professor
ON aulas
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM modulos m
        WHERE m.id = aulas.modulo_id
        AND is_professor_do_curso(m.curso_id)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM modulos m
        WHERE m.id = aulas.modulo_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### DELETE: Admin interno ou professor do curso

```sql
CREATE POLICY pol_aulas_delete_professor
ON aulas
FOR DELETE
TO authenticated
USING (
    is_admin_interno()
    OR EXISTS (
        SELECT 1
        FROM modulos m
        WHERE m.id = aulas.modulo_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

---

## 8. Tabela: `usuario_curso`

### Habilitar RLS

```sql
ALTER TABLE usuario_curso ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_curso FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Admin interno vê todos

```sql
CREATE POLICY pol_usuario_curso_select_admin
ON usuario_curso
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### SELECT: Gestor RH vê apenas da própria empresa

```sql
CREATE POLICY pol_usuario_curso_select_gestor
ON usuario_curso
FOR SELECT
TO authenticated
USING (
    empresa_id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(empresa_id)
);
```

#### SELECT: Professor vê matrículas do seu curso

```sql
CREATE POLICY pol_usuario_curso_select_professor
ON usuario_curso
FOR SELECT
TO authenticated
USING (is_professor_do_curso(curso_id));
```

#### SELECT: Aluno vê suas próprias matrículas

```sql
CREATE POLICY pol_usuario_curso_select_aluno
ON usuario_curso
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### INSERT: Via RPC `rpc_matricular_usuario_no_curso` (SECURITY DEFINER)

```sql
-- Nenhuma policy direta de INSERT
-- Apenas via RPC controlado
```

#### UPDATE: Admin interno ou Gestor RH

```sql
CREATE POLICY pol_usuario_curso_update_gestores
ON usuario_curso
FOR UPDATE
TO authenticated
USING (
    is_admin_interno()
    OR is_gestor_rh_da_empresa(empresa_id)
)
WITH CHECK (
    is_admin_interno()
    OR is_gestor_rh_da_empresa(empresa_id)
);
```

#### DELETE: Apenas admin interno

```sql
CREATE POLICY pol_usuario_curso_delete_admin
ON usuario_curso
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 9. Tabela: `usuario_aula_progresso`

### Habilitar RLS

```sql
ALTER TABLE usuario_aula_progresso ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_aula_progresso FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno vê apenas seu progresso

```sql
CREATE POLICY pol_progresso_select_aluno
ON usuario_aula_progresso
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### SELECT: Professor vê progresso de alunos matriculados no seu curso

```sql
CREATE POLICY pol_progresso_select_professor
ON usuario_aula_progresso
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = usuario_aula_progresso.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### SELECT: Gestor RH vê progresso dos colaboradores da empresa

```sql
CREATE POLICY pol_progresso_select_gestor
ON usuario_aula_progresso
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM empresa_usuarios eu
        WHERE eu.usuario_id = usuario_aula_progresso.usuario_id
        AND eu.empresa_id = get_empresa_id_do_usuario(auth.uid())
        AND is_gestor_rh_da_empresa(eu.empresa_id)
    )
);
```

#### SELECT: Admin interno vê todos

```sql
CREATE POLICY pol_progresso_select_admin
ON usuario_aula_progresso
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### INSERT: Via RPC `rpc_iniciar_aula` ou heartbeat

```sql
-- Aluno pode inserir/atualizar seu próprio progresso
CREATE POLICY pol_progresso_insert_aluno
ON usuario_aula_progresso
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());
```

#### UPDATE: Aluno atualiza apenas seu progresso

```sql
CREATE POLICY pol_progresso_update_aluno
ON usuario_aula_progresso
FOR UPDATE
TO authenticated
USING (usuario_id = auth.uid())
WITH CHECK (usuario_id = auth.uid());
```

#### DELETE: Apenas admin interno

```sql
CREATE POLICY pol_progresso_delete_admin
ON usuario_aula_progresso
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 10. Tabela: `mapas_mentais`

### Habilitar RLS

```sql
ALTER TABLE mapas_mentais ENABLE ROW LEVEL SECURITY;
ALTER TABLE mapas_mentais FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno matriculado vê mapas da aula

```sql
CREATE POLICY pol_mapas_select_aluno
ON mapas_mentais
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        JOIN usuario_curso uc ON uc.curso_id = m.curso_id
        WHERE a.id = mapas_mentais.aula_id
        AND uc.usuario_id = auth.uid()
        AND uc.status NOT IN ('bloqueado', 'expirado')
    )
);
```

#### SELECT: Professor do curso vê mapas

```sql
CREATE POLICY pol_mapas_select_professor
ON mapas_mentais
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = mapas_mentais.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### INSERT: Professor do curso

```sql
CREATE POLICY pol_mapas_insert_professor
ON mapas_mentais
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = mapas_mentais.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### UPDATE: Professor do curso

```sql
CREATE POLICY pol_mapas_update_professor
ON mapas_mentais
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = mapas_mentais.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = mapas_mentais.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### DELETE: Professor do curso ou admin

```sql
CREATE POLICY pol_mapas_delete_professor
ON mapas_mentais
FOR DELETE
TO authenticated
USING (
    is_admin_interno()
    OR EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = mapas_mentais.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

---

## 11. Tabela: `anotacoes_aluno`

### Habilitar RLS

```sql
ALTER TABLE anotacoes_aluno ENABLE ROW LEVEL SECURITY;
ALTER TABLE anotacoes_aluno FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Apenas próprio aluno vê suas anotações

```sql
CREATE POLICY pol_anotacoes_select_aluno
ON anotacoes_aluno
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### INSERT: Aluno cria suas anotações

```sql
CREATE POLICY pol_anotacoes_insert_aluno
ON anotacoes_aluno
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());
```

#### UPDATE: Aluno atualiza suas anotações

```sql
CREATE POLICY pol_anotacoes_update_aluno
ON anotacoes_aluno
FOR UPDATE
TO authenticated
USING (usuario_id = auth.uid())
WITH CHECK (usuario_id = auth.uid());
```

#### DELETE: Aluno deleta suas anotações

```sql
CREATE POLICY pol_anotacoes_delete_aluno
ON anotacoes_aluno
FOR DELETE
TO authenticated
USING (usuario_id = auth.uid());
```

---

## 12. Tabela: `exercicios`

### Habilitar RLS

```sql
ALTER TABLE exercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercicios FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno matriculado vê exercícios

```sql
CREATE POLICY pol_exercicios_select_aluno
ON exercicios
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        JOIN usuario_curso uc ON uc.curso_id = m.curso_id
        WHERE a.id = exercicios.aula_id
        AND uc.usuario_id = auth.uid()
        AND uc.status NOT IN ('bloqueado', 'expirado')
    )
);
```

#### SELECT: Professor do curso vê exercícios

```sql
CREATE POLICY pol_exercicios_select_professor
ON exercicios
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = exercicios.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### INSERT: Professor do curso

```sql
CREATE POLICY pol_exercicios_insert_professor
ON exercicios
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = exercicios.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### UPDATE: Professor do curso

```sql
CREATE POLICY pol_exercicios_update_professor
ON exercicios
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = exercicios.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = exercicios.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### DELETE: Professor do curso ou admin

```sql
CREATE POLICY pol_exercicios_delete_professor
ON exercicios
FOR DELETE
TO authenticated
USING (
    is_admin_interno()
    OR EXISTS (
        SELECT 1
        FROM aulas a
        JOIN modulos m ON m.id = a.modulo_id
        WHERE a.id = exercicios.aula_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

---

## 13. Tabela: `usuario_exercicio_resposta`

### Habilitar RLS

```sql
ALTER TABLE usuario_exercicio_resposta ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_exercicio_resposta FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno vê apenas suas respostas

```sql
CREATE POLICY pol_respostas_select_aluno
ON usuario_exercicio_resposta
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### SELECT: Professor vê respostas dos alunos no seu curso

```sql
CREATE POLICY pol_respostas_select_professor
ON usuario_exercicio_resposta
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM exercicios e
        JOIN aulas a ON a.id = e.aula_id
        JOIN modulos m ON m.id = a.modulo_id
        WHERE e.id = usuario_exercicio_resposta.exercicio_id
        AND is_professor_do_curso(m.curso_id)
    )
);
```

#### INSERT: Aluno insere suas respostas

```sql
CREATE POLICY pol_respostas_insert_aluno
ON usuario_exercicio_resposta
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());
```

#### UPDATE: Aluno não pode atualizar respostas (apenas INSERT)

```sql
-- Sem policy de UPDATE (respostas são imutáveis)
```

#### DELETE: Apenas admin interno

```sql
CREATE POLICY pol_respostas_delete_admin
ON usuario_exercicio_resposta
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 14. Tabela: `flashcards_revisao`

### Habilitar RLS

```sql
ALTER TABLE flashcards_revisao ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards_revisao FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno vê apenas seus flashcards

```sql
CREATE POLICY pol_flashcards_select_aluno
ON flashcards_revisao
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### INSERT: Via trigger automático

```sql
-- Aluno pode criar flashcards manualmente também
CREATE POLICY pol_flashcards_insert_aluno
ON flashcards_revisao
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());
```

#### UPDATE: Aluno atualiza apenas seus flashcards

```sql
CREATE POLICY pol_flashcards_update_aluno
ON flashcards_revisao
FOR UPDATE
TO authenticated
USING (usuario_id = auth.uid())
WITH CHECK (usuario_id = auth.uid());
```

#### DELETE: Aluno deleta seus flashcards

```sql
CREATE POLICY pol_flashcards_delete_aluno
ON flashcards_revisao
FOR DELETE
TO authenticated
USING (usuario_id = auth.uid());
```

---

## 15. Tabela: `certificados`

### Habilitar RLS

```sql
ALTER TABLE certificados ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificados FORCE ROW LEVEL SECURITY;
```

### Políticas

#### SELECT: Aluno vê apenas seus certificados

```sql
CREATE POLICY pol_certificados_select_aluno
ON certificados
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());
```

#### SELECT: Professor vê certificados do seu curso

```sql
CREATE POLICY pol_certificados_select_professor
ON certificados
FOR SELECT
TO authenticated
USING (is_professor_do_curso(curso_id));
```

#### SELECT: Gestor RH vê certificados da empresa

```sql
CREATE POLICY pol_certificados_select_gestor
ON certificados
FOR SELECT
TO authenticated
USING (
    empresa_id = get_empresa_id_do_usuario(auth.uid())
    AND is_gestor_rh_da_empresa(empresa_id)
);
```

#### SELECT: Admin interno vê todos

```sql
CREATE POLICY pol_certificados_select_admin
ON certificados
FOR SELECT
TO authenticated
USING (is_admin_interno());
```

#### INSERT: Via trigger automático

```sql
-- Nenhuma policy direta
-- Apenas trigger pode criar certificados
```

#### UPDATE: Apenas admin interno

```sql
CREATE POLICY pol_certificados_update_admin
ON certificados
FOR UPDATE
TO authenticated
USING (is_admin_interno())
WITH CHECK (is_admin_interno());
```

#### DELETE: Apenas admin interno

```sql
CREATE POLICY pol_certificados_delete_admin
ON certificados
FOR DELETE
TO authenticated
USING (is_admin_interno());
```

---

## 16. Script de Implantação

Execute na seguinte ordem:

1. Criar funções de apoio (FUNCOES_TRIGGERS_LMS_B2B.md seção 1)
2. Criar RPCs transacionais (seção 2)
3. Habilitar RLS em todas as tabelas (este documento)
4. Criar triggers (FUNCOES_TRIGGERS_LMS_B2B.md seção 4)
5. Criar índices de performance (seção 6)

---

## 17. Testes Sugeridos

### Teste 1: Isolamento de Tenant

```sql
-- Como aluno da empresa A, tentar acessar sessões da empresa B
SELECT * FROM sessoes_ativas; -- Deve retornar apenas da própria empresa
```

### Teste 2: Validação de Sessão Simultânea

```sql
-- Login de 11º usuário quando limite é 10
SELECT rpc_validar_acesso_simultaneo(
    'user_id_11',
    'curso_id_x',
    'token_11'
);
-- Deve retornar sucesso: false, erro: 'limite_atingido'
```

### Teste 3: Progressão Sequencial

```sql
-- Tentar acessar aula 5 sem concluir aula 4
SELECT rpc_iniciar_aula('aula_5_id');
-- Deve retornar sucesso: false, erro: 'aula_bloqueada'
```

### Teste 4: Permissões de Professor

```sql
-- Como professor  X, tentar editar curso do professor Y
UPDATE cursos SET titulo = 'Hackeado' WHERE id = 'curso_professor_y';
-- Deve falhar (0 rows affected)
```

---

## 18. Próximos Passos

- [ ] Implementar matriz RBAC (perfis vs permissões de UI)
- [ ] Criar views otimizadas para relatórios
- [ ] Implementar auditoria de acessos críticos
- [ ] Validar testes de RLS com dados reais
