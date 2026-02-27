# Mapa de Rotas e Telas - LMS + B2B

**Data:** 2026-02-27  
**Status:** Planejamento (não implementado)  
**Base:** MATRIZ_RBAC_LMS_B2B.md

---

## 1. Aplicação Admin (cci-ca-admin)

### Base URL: `/admin`

#### 1.1 Dashboard

| Rota               | Componente       | Perfis        | Descrição                                                              |
| ------------------ | ---------------- | ------------- | ---------------------------------------------------------------------- |
| `/admin/dashboard` | `DashboardAdmin` | admin_interno | Visão geral global: empresas ativas, cursos publicados, sessões ativas |

**Props/Context:**

- `empresasAtivas: number`
- `cursosPublicados: number`
- `sessoesAtivasGlobal: number`
- `licencasContratadas: number`

**Queries:**

```typescript
// Dashboard metrics
const { data: metrics } = useQuery({
  queryKey: ['admin-dashboard-metrics'],
  queryFn: () => supabase.rpc('rpc_obter_metricas_dashboard_admin'),
})
```

---

#### 1.2 Gestão de Empresas

| Rota                                | Componente             | Perfis        | Descrição                                                                           |
| ----------------------------------- | ---------------------- | ------------- | ----------------------------------------------------------------------------------- |
| `/admin/empresas`                   | `ListarEmpresas`       | admin_interno | Listagem com filtros (status, plano, validade)                                      |
| `/admin/empresas/novo`              | `CriarEmpresa`         | admin_interno | Formulário de cadastro de empresa                                                   |
| `/admin/empresas/:id`               | `DetalhesEmpresa`      | admin_interno | Visão geral da empresa (tabs: geral, colaboradores, licenças, sessões, faturamento) |
| `/admin/empresas/:id/editar`        | `EditarEmpresa`        | admin_interno | Formulário de edição                                                                |
| `/admin/empresas/:id/colaboradores` | `ColaboradoresEmpresa` | admin_interno | Lista de colaboradores com ações (editar, desativar)                                |
| `/admin/empresas/:id/licencas`      | `LicencasEmpresa`      | admin_interno | Configuração de limites simultâneos, histórico de alterações                        |
| `/admin/empresas/:id/sessoes`       | `SessoesEmpresa`       | admin_interno | Painel de sessões ativas em tempo real                                              |

**Componentes Relacionados:**

- `CardEmpresa` (lista)
- `FormEmpresa` (criar/editar)
- `ModalSuspenderEmpresa`
- `ModalConfigurarLimite`
- `TabelaSessoesAtivas`

**Estados Principais:**

```typescript
interface Empresa {
  id: string
  razao_social: string
  cnpj: string
  status: 'ativa' | 'suspensa' | 'expirada'
  limite_usuarios_simultaneos: number
  data_validade: string | null
  plano_contratado: string
}
```

---

#### 1.3 Gestão de Cursos (Admin View)

| Rota                           | Componente             | Perfis        | Descrição                                             |
| ------------------------------ | ---------------------- | ------------- | ----------------------------------------------------- |
| `/admin/cursos`                | `ListarCursosAdmin`    | admin_interno | Todos os cursos (qualquer professor, qualquer status) |
| `/admin/cursos/:id`            | `DetalhesCursoAdmin`   | admin_interno | Detalhes completos com opções de edição/exclusão      |
| `/admin/cursos/:id/editar`     | `EditarCursoAdmin`     | admin_interno | Edição de qualquer curso                              |
| `/admin/cursos/:id/matriculas` | `MatriculasCursoAdmin` | admin_interno | Empresas/alunos matriculados globalmente              |

---

## 2. Aplicação Professor (cci-ca-admin - módulo professor)

### Base URL: `/professor`

#### 2.1 Dashboard Professor

| Rota                   | Componente           | Perfis    | Descrição                                           |
| ---------------------- | -------------------- | --------- | --------------------------------------------------- |
| `/professor/dashboard` | `DashboardProfessor` | professor | Cursos publicados, alunos ativos, taxa de conclusão |

**Queries:**

```typescript
const { data: metricas } = useQuery({
  queryKey: ['professor-dashboard', professorId],
  queryFn: () => supabase.rpc('rpc_obter_metricas_professor', { p_professor_id: professorId }),
})
```

---

#### 2.2 Gestão de Cursos (Professor)

| Rota                                             | Componente            | Perfis    | Descrição                                                         |
| ------------------------------------------------ | --------------------- | --------- | ----------------------------------------------------------------- |
| `/professor/cursos`                              | `MeusCursos`          | professor | Cursos criados pelo professor (rascunho, publicado, despublicado) |
| `/professor/cursos/novo`                         | `CriarCurso`          | professor | Formulário de criação de curso                                    |
| `/professor/cursos/:id`                          | `DetalhesCurso`       | professor | Visão geral (tabs: info, estrutura, alunos, relatórios)           |
| `/professor/cursos/:id/editar`                   | `EditarCurso`         | professor | Editar informações gerais do curso                                |
| `/professor/cursos/:id/estrutura`                | `EstruturaCurso`      | professor | Gerenciar módulos e aulas (drag-and-drop)                         |
| `/professor/cursos/:id/modulos/novo`             | `CriarModulo`         | professor | Adicionar módulo ao curso                                         |
| `/professor/cursos/:id/modulos/:moduloId/editar` | `EditarModulo`        | professor | Editar módulo                                                     |
| `/professor/cursos/:id/aulas/novo`               | `CriarAula`           | professor | Adicionar aula a um módulo                                        |
| `/professor/cursos/:id/aulas/:aulaId/editar`     | `EditarAula`          | professor | Editar aula (título, descrição, tipo de conteúdo)                 |
| `/professor/cursos/:id/aulas/:aulaId/video`      | `UploadVideoAula`     | professor | Upload de vídeo para Bunny.net                                    |
| `/professor/cursos/:id/aulas/:aulaId/mapa`       | `GerenciarMapaMental` | professor | Criar/editar mapa mental da aula                                  |
| `/professor/cursos/:id/aulas/:aulaId/exercicios` | `GerenciarExercicios` | professor | CRUD de exercícios                                                |
| `/professor/cursos/:id/alunos`                   | `AlunosCurso`         | professor | Lista de alunos matriculados com progresso                        |
| `/professor/cursos/:id/relatorios`               | `RelatoriosCurso`     | professor | Métricas detalhadas (conclusão, tempo médio, exercícios)          |

**Componentes Relacionados:**

- `CardCurso` (lista)
- `FormCurso` (criar/editar)
- `ArvoreModulosAulas` (drag-and-drop)
- `FormModulo`
- `FormAula`
- `UploaderVideoBunny`
- `EditorMapaMental` (integração com biblioteca de mapas)
- `FormExercicio` (múltipla escolha, verdadeiro/falso, dissertativa)
- `TabelaProgresosAlunos`
- `GraficosRelatorios` (conclusão, engajamento, desempenho)

---

## 3. Aplicação Portal Aluno (cci-ca-aluno)

### Base URL: `/app`

#### 3.1 Dashboard Aluno

| Rota             | Componente       | Perfis | Descrição                                       |
| ---------------- | ---------------- | ------ | ----------------------------------------------- |
| `/app/dashboard` | `DashboardAluno` | aluno  | Cursos em andamento, próxima aula, certificados |

**Props/Context:**

```typescript
interface DashboardData {
  cursosEmAndamento: CursoProgresso[]
  proximasAulas: Aula[]
  certificadosRecebidos: number
  horasEstudadas: number
  flashcardsPendentes: number
}
```

---

#### 3.2 Catálogo e Matrículas

| Rota                | Componente       | Perfis           | Descrição                                               |
| ------------------- | ---------------- | ---------------- | ------------------------------------------------------- |
| `/app/catalogo`     | `CatalogoCursos` | aluno, gestor_rh | Cursos disponíveis (filtros: categoria, nível, duração) |
| `/app/catalogo/:id` | `PreviewCurso`   | aluno, gestor_rh | Prévia do curso (estrutura, professor, carga horária)   |
| `/app/meus-cursos`  | `MeusCursos`     | aluno            | Cursos matriculados (em andamento, concluídos)          |

**Componentes:**

- `CardCursoCatalogo`
- `FiltrosCatalogo`
- `PreviewCursoDetalhes`
- `ListaCursosMatriculados`

**Nota:** Matrícula não é feita pelo aluno diretamente, apenas pelo gestor RH.

---

#### 3.3 Player de Aula

| Rota                           | Componente    | Perfis | Descrição                                             |
| ------------------------------ | ------------- | ------ | ----------------------------------------------------- |
| `/app/player/:cursoId`         | `CursoPlayer` | aluno  | Layout com sidebar (módulos/aulas) e área de conteúdo |
| `/app/player/:cursoId/:aulaId` | `AulaPlayer`  | aluno  | Player de vídeo/conteúdo com controles de progresso   |

**Componentes do Player:**

- `SidebarCurso` (lista de módulos/aulas com indicadores de progresso)
- `VideoPlayer` (integração Bunny.net com token temporário)
- `ConteudoTexto` (para aulas texto)
- `PainelAnotacoes` (lateral direita, retrátil)
- `MapaMentalViewer` (modal ou aba)
- `ListaExercicios` (modal ou seção abaixo do vídeo)
- `BotaoProximaAula`
- `IndicadorProgresso` (barra de progresso global do curso)
- `TimerHeartbeat` (envia heartbeat a cada 30s)

**Queries:**

```typescript
// Validar acesso simultâneo ao iniciar aula
const { mutate: iniciarAula } = useMutation({
  mutationFn: ({ aulaId, sessionToken }) => supabase.rpc('rpc_iniciar_aula', { p_aula_id: aulaId }),
  onSuccess: (data) => {
    if (data.sucesso && data.tipo === 'video') {
      setVideoToken(data.video_token)
      setBunnyVideoId(data.bunny_video_id)
    }
  },
})

// Heartbeat a cada 30 segundos
useInterval(() => {
  supabase
    .from('usuario_aula_progresso')
    .update({
      ultimo_acesso: new Date().toISOString(),
      tempo_assistido_segundos: tempoAssistido,
    })
    .eq('usuario_id', userId)
    .eq('aula_id', aulaId)
}, 30000)
```

**Estados do Player:**

```typescript
interface PlayerState {
  cursoId: string
  aulaId: string
  videoToken: string | null
  bunnyVideoId: string | null
  tempoAssistido: number // em segundos
  aulas: Aula[]
  aulaAtual: Aula
  proximaAula: Aula | null
  progresso: number // percentual do curso
  sessionToken: string
}
```

---

#### 3.4 Exercícios

| Rota                                                             | Componente            | Perfis | Descrição                                                    |
| ---------------------------------------------------------------- | --------------------- | ------ | ------------------------------------------------------------ |
| `/app/player/:cursoId/:aulaId/exercicios`                        | `ListaExerciciosAula` | aluno  | Lista de exercícios da aula                                  |
| `/app/player/:cursoId/:aulaId/exercicios/:exercicioId`           | `ResolverExercicio`   | aluno  | Interface de resolução (múltipla escolha, V/F, dissertativa) |
| `/app/player/:cursoId/:aulaId/exercicios/:exercicioId/resultado` | `ResultadoExercicio`  | aluno  | Feedback (correto/incorreto, explicação, flashcard gerado)   |

**Componentes:**

- `CardExercicio`
- `FormRespostaMultiplaEscolha`
- `FormRespostaVerdadeiroFalso`
- `FormRespostaDissertativa`
- `FeedbackResposta` (com animação de acerto/erro)
- `ModalFlashcardGerado`

---

#### 3.5 Flashcards de Revisão

| Rota                      | Componente          | Perfis | Descrição                                                |
| ------------------------- | ------------------- | ------ | -------------------------------------------------------- |
| `/app/flashcards`         | `MeusFlashcards`    | aluno  | Lista de flashcards (tabs: hoje, vencidos, todos)        |
| `/app/flashcards/revisar` | `RevisarFlashcards` | aluno  | Interface de revisão com algoritmo de repetição espaçada |
| `/app/flashcards/novo`    | `CriarFlashcard`    | aluno  | Criar flashcard manual (frente, verso, curso/aula)       |

**Componentes:**

- `CardFlashcard` (flip animation)
- `BotoesAvaliacao` (fácil, médio, difícil)
- `FormFlashcard`
- `EstatisticasRevisao` (taxa de acerto, próximas revisões)

**Lógica de Repetição Espaçada:**

```typescript
const calcularProximaRevisao = (dificuldade: 'facil' | 'media' | 'dificil') => {
  const intervalos = {
    facil: 7, // dias
    media: 3,
    dificil: 1,
  }
  return addDays(new Date(), intervalos[dificuldade])
}

// Ao responder flashcard
await supabase
  .from('flashcards_revisao')
  .update({
    dificuldade,
    ultima_revisao: new Date(),
    proxima_revisao: calcularProximaRevisao(dificuldade),
    vezes_revisado: sql`vezes_revisado + 1`,
  })
  .eq('id', flashcardId)
```

---

#### 3.6 Anotações

| Rota             | Componente        | Perfis | Descrição                                                  |
| ---------------- | ----------------- | ------ | ---------------------------------------------------------- |
| `/app/anotacoes` | `MinhasAnotacoes` | aluno  | Lista de todas as anotações (busca, filtro por curso/aula) |

**Componentes:**

- `PainelAnotacoes` (inside player, lateral direita)
- `FormAnotacao`
- `ListaAnotacoes` (com timestamp clicável para vídeo)
- `BuscaAnotacoes`

**Features:**

```typescript
// Anotação com timestamp de vídeo
interface Anotacao {
  id: string
  usuario_id: string
  aula_id: string
  conteudo: string
  timestamp_video_segundos: number | null // para vídeos
  criada_em: string
}

// Clicar em anotação pula para timestamp no vídeo
const handleClickAnotacao = (anotacao: Anotacao) => {
  if (anotacao.timestamp_video_segundos && videoRef.current) {
    videoRef.current.currentTime = anotacao.timestamp_video_segundos
    videoRef.current.play()
  }
}
```

---

#### 3.7 Certificados

| Rota                    | Componente              | Perfis | Descrição                                         |
| ----------------------- | ----------------------- | ------ | ------------------------------------------------- |
| `/app/certificados`     | `MeusCertificados`      | aluno  | Lista de certificados emitidos                    |
| `/app/certificados/:id` | `VisualizarCertificado` | aluno  | Prévia do certificado (PDF) com botão de download |

**Componentes:**

- `CardCertificado`
- `PreviewCertificadoPDF`
- `BotaoBaixarCertificado`
- `BotaoCompartilhar` (LinkedIn)

---

#### 3.8 Perfil

| Rota                       | Componente           | Perfis                      | Descrição                                           |
| -------------------------- | -------------------- | --------------------------- | --------------------------------------------------- |
| `/app/perfil`              | `MeuPerfil`          | aluno, gestor_rh, professor | Editar dados pessoais, foto, senha                  |
| `/app/perfil/estatisticas` | `MinhasEstatisticas` | aluno                       | Horas estudadas, cursos concluídos, taxa de acertos |

---

## 4. Portal RH (cci-ca-aluno - módulo RH)

### Base URL: `/app/rh`

#### 4.1 Dashboard RH

| Rota                | Componente    | Perfis    | Descrição                                                     |
| ------------------- | ------------- | --------- | ------------------------------------------------------------- |
| `/app/rh/dashboard` | `DashboardRH` | gestor_rh | Visão geral: colaboradores ativos, matrículas, sessões ativas |

**Métricas:**

```typescript
interface DashboardRH {
  colaboradores_ativos: number
  matriculas_ativas: number
  sessoes_ativas: number
  limite_simultaneo: number
  cursos_disponiveis: number
  certificados_emitidos_mes: number
}
```

---

#### 4.2 Gestão de Colaboradores

| Rota                               | Componente               | Perfis    | Descrição                                                |
| ---------------------------------- | ------------------------ | --------- | -------------------------------------------------------- |
| `/app/rh/colaboradores`            | `GerenciarColaboradores` | gestor_rh | Lista com filtros (status, cargo, departamento)          |
| `/app/rh/colaboradores/convidar`   | `ConvidarColaborador`    | gestor_rh | Formulário de convite (nome, email, cargo)               |
| `/app/rh/colaboradores/:id`        | `DetalhesColaborador`    | gestor_rh | Perfil do colaborador (tabs: info, cursos, certificados) |
| `/app/rh/colaboradores/:id/editar` | `EditarColaborador`      | gestor_rh | Editar dados do colaborador                              |

**Componentes:**

- `TabelaColaboradores` (com ações: editar, desativar, matricular)
- `FormConviteColaborador`
- `ModalMatricularColaborador` (selecionar curso)

---

#### 4.3 Matrículas

| Rota                      | Componente            | Perfis    | Descrição                                                    |
| ------------------------- | --------------------- | --------- | ------------------------------------------------------------ |
| `/app/rh/matriculas`      | `GerenciarMatriculas` | gestor_rh | Lista de matrículas ativas (filtros: curso, status, período) |
| `/app/rh/matriculas/nova` | `NovaMatricula`       | gestor_rh | Matricular colaborador individualmente                       |
| `/app/rh/matriculas/lote` | `MatriculaEmLote`     | gestor_rh | Upload CSV para matrícula em massa                           |

**Componentes:**

- `FormMatriculaIndividual`
- `UploaderCSVMatriculas`
- `TabelaMatriculas` (com filtros e ações: cancelar)
- `ModalCancelarMatricula`

**Formato CSV:**

```csv
email,curso_id
joao@empresa.com,uuid-curso-1
maria@empresa.com,uuid-curso-1
```

---

#### 4.4 Gestão de Licenças

| Rota               | Componente           | Perfis    | Descrição                                           |
| ------------------ | -------------------- | --------- | --------------------------------------------------- |
| `/app/rh/licencas` | `VisualizarLicencas` | gestor_rh | Painel de licenças (limite, sessões ativas, status) |

**Componentes:**

- `CardLimiteSimultaneo` (readonly, exibe limite contratado)
- `TabelaSessoesAtivas` (em tempo real)
- `GraficoUsoLicencas` (histórico de pico de sessões)

**Nota:** Apenas admin interno pode alterar limite simultâneo.

---

#### 4.5 Sessões Ativas

| Rota                     | Componente         | Perfis    | Descrição                                      |
| ------------------------ | ------------------ | --------- | ---------------------------------------------- |
| `/app/rh/sessoes-ativas` | `MonitorarSessoes` | gestor_rh | Painel em tempo real com ação de forçar logout |

**Componentes:**

- `TabelaSessoesAtivasRealTime` (atualização a cada 10s)
- `BotaoForcarLogout`
- `ModalConfirmarLogout`
- `AlertaLimiteAtingido` (quando sessões_ativas >= limite)

**Realtime Subscription:**

```typescript
useEffect(() => {
  const subscription = supabase
    .channel('sessoes_ativas')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'sessoes_ativas',
        filter: `empresa_id=eq.${empresaId}`,
      },
      (payload) => {
        refetch()
      }
    )
    .subscribe()

  return () => subscription.unsubscribe()
}, [empresaId])
```

---

#### 4.6 Relatórios

| Rota                             | Componente             | Perfis    | Descrição                                        |
| -------------------------------- | ---------------------- | --------- | ------------------------------------------------ |
| `/app/rh/relatorios`             | `RelatoriosRH`         | gestor_rh | Relatórios de progresso, conclusão, certificados |
| `/app/rh/relatorios/progresso`   | `RelatorioProgresso`   | gestor_rh | Progresso geral dos colaboradores por curso      |
| `/app/rh/relatorios/conclusao`   | `RelatorioConclusao`   | gestor_rh | Taxa de conclusão, tempo médio, certificados     |
| `/app/rh/relatorios/engajamento` | `RelatorioEngajamento` | gestor_rh | Horas estudadas, última atividade, sessões       |

**Componentes:**

- `FiltrosRelatorio` (período, curso, departamento)
- `GraficoProgressoGeral`
- `TabelaProgressoColaboradores`
- `BotaoExportarCSV`
- `BotaoExportarPDF`

---

#### 4.7 Certificados (RH)

| Rota                   | Componente            | Perfis    | Descrição                                         |
| ---------------------- | --------------------- | --------- | ------------------------------------------------- |
| `/app/rh/certificados` | `CertificadosEmpresa` | gestor_rh | Lista de certificados emitidos para colaboradores |

**Componentes:**

- `TabelaCertificados` (colaborador, curso, data de emissão, nota)
- `BotaoBaixarCertificado`

---

## 5. Páginas Públicas

### Base URL: `/`

| Rota               | Componente           | Perfis  | Descrição                            |
| ------------------ | -------------------- | ------- | ------------------------------------ |
| `/`                | `HomePage`           | público | Landing page                         |
| `/validar/:codigo` | `ValidarCertificado` | público | Validação de certificado via QR Code |
| `/login`           | `Login`              | público | Página de login                      |
| `/cadastro`        | `Cadastro`           | público | Cadastro de professor (B2C)          |
| `/recuperar-senha` | `RecuperarSenha`     | público | Recuperação de senha                 |

**Componentes:**

- `FormLogin`
- `FormCadastroProfessor`
- `FormRecuperarSenha`
- `CardValidacaoCertificado` (mostra dados do certificado válido)

---

## 6. Rotas de Erro

| Rota   | Componente            | Perfis           | Descrição                              |
| ------ | --------------------- | ---------------- | -------------------------------------- |
| `/403` | `AcessoNegado`        | todos            | Erro de permissão                      |
| `/404` | `PaginaNaoEncontrada` | todos            | Página não existe                      |
| `/429` | `LimiteAtingido`      | aluno            | Limite de sessões simultâneas atingido |
| `/503` | `EmpresaSuspensa`     | aluno, gestor_rh | Empresa suspensa/expirada              |

---

## 7. Estrutura de Navegação

### 7.1 Admin Interno (cci-ca-admin)

```
Sidebar Principal:
- Dashboard
- Empresas
  - Listar
  - Adicionar
- Cursos
  - Listar todos
- Relatórios
- Configurações
```

### 7.2 Professor (cci-ca-admin)

```
Sidebar Principal:
- Dashboard
- Meus Cursos
  - Listar
  - Criar Novo
- Alunos
- Relatórios
- Perfil
```

### 7.3 Aluno (cci-ca-aluno)

```
Sidebar Principal:
- Dashboard
- Meus Cursos
- Catálogo
- Flashcards
- Anotações
- Certificados
- Perfil
```

### 7.4 Gestor RH (cci-ca-aluno)

```
Sidebar Principal:
- Dashboard
- Colaboradores
  - Listar
  - Convidar
- Matrículas
  - Nova
  - Em Lote
- Licenças e Sessões
- Relatórios
  - Progresso
  - Conclusão
  - Engajamento
- Certificados
- Perfil da Empresa
```

---

## 8. Layouts e Templates

### 8.1 Layout Padrão (Authenticated)

```typescript
interface LayoutAutenticadoProps {
  children: ReactNode
  sidebar?: ReactNode
  header?: ReactNode
}

// Componentes:
// - HeaderGlobal (logo, busca, notificações, menu usuário)
// - SidebarNavegacao (menu principal por perfil)
// - ConteudoPrincipal (área de renderização das rotas)
```

### 8.2 Layout Player

```typescript
interface LayoutPlayerProps {
  cursoId: string
  children: ReactNode
}

// Componentes:
// - HeaderMini (breadcrumb, título do curso, botão sair)
// - SidebarCurso (módulos/aulas, progresso)
// - AreaConteudo (player de vídeo/texto)
// - PainelAnotacoes (lateral direita, retrátil)
```

### 8.3 Layout RH

```typescript
// Baseado em LayoutAutenticado com sidebar específica de RH
```

---

## 9. Guards e Middlewares

### 9.1 AuthGuard

```typescript
// Protege rotas autenticadas
const AuthGuard = ({ children }) => {
    const { session, loading } = useAuth();

    if (loading) return <LoadingScreen />;
    if (!session) return <Navigate to="/login" />;

    return children;
};
```

### 9.2 RoleGuard

```typescript
// Protege rotas por perfil
const RoleGuard = ({ perfisPermitidos, children }) => {
    const { user } = useAuth();
    const perfil = user?.user_metadata?.perfil;

    if (!perfisPermitidos.includes(perfil)) {
        return <Navigate to="/403" />;
    }

    return children;
};
```

### 9.3 SessionGuard

```typescript
// Valida sessão simultânea ao acessar player
const SessionGuard = ({ cursoId, children }) => {
    const { mutate: validarSessao, data, isLoading } = useMutation({
        mutationFn: ({ sessionToken }) =>
            supabase.rpc('rpc_validar_acesso_simultaneo', {
                p_usuario_id: user.id,
                p_curso_id: cursoId,
                p_session_token: sessionToken
            })
    });

    useEffect(() => {
        const token = generateSessionToken();
        validarSessao({ sessionToken: token });
    }, []);

    if (isLoading) return <LoadingScreen />;
    if (!data?.sucesso) {
        if (data?.erro === 'limite_atingido') {
            return <Navigate to="/429" />;
        }
        return <Navigate to="/503" />;
    }

    return children;
};
```

---

## 10. Navegação com React Router

### 10.1 Estrutura de Rotas (cci-ca-admin)

```typescript
<Routes>
    <Route path="/login" element={<Login />} />

    {/* Admin */}
    <Route element={<AuthGuard />}>
        <Route element={<RoleGuard perfisPermitidos={['admin_interno']} />}>
            <Route path="/admin" element={<LayoutAdmin />}>
                <Route path="dashboard" element={<DashboardAdmin />} />
                <Route path="empresas" element={<ListarEmpresas />} />
                <Route path="empresas/novo" element={<CriarEmpresa />} />
                <Route path="empresas/:id" element={<DetalhesEmpresa />} />
                {/* ... */}
            </Route>
        </Route>

        {/* Professor */}
        <Route element={<RoleGuard perfisPermitidos={['professor']} />}>
            <Route path="/professor" element={<LayoutProfessor />}>
                <Route path="dashboard" element={<DashboardProfessor />} />
                <Route path="cursos" element={<MeusCursos />} />
                {/* ... */}
            </Route>
        </Route>
    </Route>
</Routes>
```

### 10.2 Estrutura de Rotas (cci-ca-aluno)

```typescript
<Routes>
    <Route path="/login" element={<Login />} />
    <Route path="/validar/:codigo" element={<ValidarCertificado />} />

    {/* Aluno */}
    <Route element={<AuthGuard />}>
        <Route element={<RoleGuard perfisPermitidos={['aluno']} />}>
            <Route path="/app" element={<LayoutAluno />}>
                <Route path="dashboard" element={<DashboardAluno />} />
                <Route path="meus-cursos" element={<MeusCursos />} />
                <Route path="catalogo" element={<CatalogoCursos />} />
                {/* ... */}
            </Route>

            {/* Player com guard de sessão */}
            <Route path="/app/player/:cursoId" element={<LayoutPlayer />}>
                <Route element={<SessionGuard />}>
                    <Route index element={<CursoPlayer />} />
                    <Route path=":aulaId" element={<AulaPlayer />} />
                </Route>
            </Route>
        </Route>

        {/* Gestor RH */}
        <Route element={<RoleGuard perfisPermitidos={['gestor_rh']} />}>
            <Route path="/app/rh" element={<LayoutRH />}>
                <Route path="dashboard" element={<DashboardRH />} />
                <Route path="colaboradores" element={<GerenciarColaboradores />} />
                {/* ... */}
            </Route>
        </Route>
    </Route>
</Routes>
```

---

## 11. Checklist de Implementação

- [ ] Criar layouts base (Authenticated, Player, Public)
- [ ] Implementar guards (Auth, Role, Session)
- [ ] Criar estrutura de rotas no React Router
- [ ] Implementar sidebar por perfil
- [ ] Criar breadcrumbs dinâmicos
- [ ] Implementar sistema de notificações (limite atingido, sessão expirada)
- [ ] Implementar realtime para sessões ativas
- [ ] Testes E2E de navegação por perfil

---

## 12. Próximos Passos

- [ ] Criar documento de especificação de endpoints da API
- [ ] Definir contratos de request/response
- [ ] Validar fluxo completo de matrícula e acesso simultâneo
