# Sistema de Filtro para Professores - CCI CA Admin

## 📋 Visão Geral

Este documento apresenta uma solução completa para implementar um sistema de filtro que permita aos professores logados no sistema administrativo acessar apenas dados relacionados às suas disciplinas e turmas específicas.

## 🎯 Objetivo

Criar um filtro baseado no tipo de usuário (`fk_id_tipo_pessoa = 4`) que restrinja o acesso dos professores somente aos dados das disciplinas e turmas que lecionam, mantendo a segurança e integridade dos dados.

## 📊 Análise da Estrutura Atual

### Base de Dados Consultada

Com base na análise do Supabase, identificamos a seguinte estrutura relevante:

#### Tipos de Pessoa

```sql
-- Tipos existentes no sistema
1 - Aluno(a)
2 - Responsável Financeiro
3 - Funcionário
4 - Professor(a)  ← Foco da solução
8 - Administrador
```

#### Relacionamentos Identificados

-    `pessoas.fk_id_tipo_pessoa = 4` → Identifica professores
-    `disciplinas.fk_id_professor` → Vincula disciplina ao professor
-    `turmas.fk_id_disciplina` → Vincula turma à disciplina
-    `agendamentos_professores.fk_id_professor` → Agendamentos do professor
-    `alunos_contrato_turmas.fk_id_turma` → Alunos matriculados por turma

## 🔧 Arquitetura da Solução

### 1. Context Provider para Filtro de Professor

Criar um contexto específico para gerenciar o filtro de professor:

```typescript
// src/contexts/ProfessorFilterContext/ProfessorFilterContext.tsx

import React, { createContext, useContext, useEffect, useState } from 'react';
import { useUserContext } from '../UserContext/useUserContext';
import { supabase } from '../../config/supabaseConfig';

interface ProfessorData {
     id: number;
     nome: string;
     email: string;
     disciplinas: Array<{
          id: number;
          nome: string;
          turmas: Array<{
               id: number;
               descricao: string;
          }>;
     }>;
}

interface ProfessorFilterContextType {
     isProfessor: boolean;
     professorData: ProfessorData | null;
     disciplinasPermitidas: number[];
     turmasPermitidas: number[];
     loading: boolean;
     error: string | null;
}

const ProfessorFilterContext = createContext<ProfessorFilterContextType | undefined>(undefined);

export const ProfessorFilterProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
     const { userData } = useUserContext();
     const [isProfessor, setIsProfessor] = useState(false);
     const [professorData, setProfessorData] = useState<ProfessorData | null>(null);
     const [disciplinasPermitidas, setDisciplinasPermitidas] = useState<number[]>([]);
     const [turmasPermitidas, setTurmasPermitidas] = useState<number[]>([]);
     const [loading, setLoading] = useState(false);
     const [error, setError] = useState<string | null>(null);

     useEffect(() => {
          const verificarTipoProfessor = async () => {
               if (!userData?.id) return;

               setLoading(true);
               setError(null);

               try {
                    // Verificar se é professor (tipo_pessoa = 4)
                    const { data: pessoa, error: pessoaError } = await supabase.from('pessoas').select('id, nome, email, fk_id_tipo_pessoa').eq('id', userData.id).single();

                    if (pessoaError) throw pessoaError;

                    const ehProfessor = pessoa?.fk_id_tipo_pessoa === 4;
                    setIsProfessor(ehProfessor);

                    if (ehProfessor) {
                         // Buscar disciplinas e turmas do professor
                         const { data: disciplinasData, error: disciplinasError } = await supabase
                              .from('disciplinas')
                              .select(
                                   `
              id,
              nome,
              turmas:turmas!fk_id_disciplina(
                id,
                descricao
              )
            `,
                              )
                              .eq('fk_id_professor', pessoa.id)
                              .eq('deleted_at', null);

                         if (disciplinasError) throw disciplinasError;

                         const disciplinasIds = disciplinasData?.map((d) => d.id) || [];
                         const turmasIds = disciplinasData?.flatMap((d) => d.turmas?.map((t) => t.id) || []) || [];

                         setDisciplinasPermitidas(disciplinasIds);
                         setTurmasPermitidas(turmasIds);
                         setProfessorData({
                              id: pessoa.id,
                              nome: pessoa.nome,
                              email: pessoa.email,
                              disciplinas: disciplinasData || [],
                         });
                    }
               } catch (err) {
                    console.error('Erro ao verificar tipo professor:', err);
                    setError('Erro ao verificar permissões de professor');
               } finally {
                    setLoading(false);
               }
          };

          verificarTipoProfessor();
     }, [userData?.id]);

     return (
          <ProfessorFilterContext.Provider
               value={{
                    isProfessor,
                    professorData,
                    disciplinasPermitidas,
                    turmasPermitidas,
                    loading,
                    error,
               }}
          >
               {children}
          </ProfessorFilterContext.Provider>
     );
};

export const useProfessorFilter = () => {
     const context = useContext(ProfessorFilterContext);
     if (!context) {
          throw new Error('useProfessorFilter deve ser usado dentro de ProfessorFilterProvider');
     }
     return context;
};
```

### 2. Hook para Aplicar Filtros de Professor

```typescript
// src/hooks/useProfessorQuery.ts

import { useMemo } from 'react';
import { useProfessorFilter } from '../contexts/ProfessorFilterContext/ProfessorFilterContext';
import { PostgrestFilterBuilder } from '@supabase/postgrest-js';

interface UseProfessorQueryOptions {
     aplicarFiltro?: boolean;
     tabela?: 'agendamentos' | 'disciplinas' | 'turmas' | 'alunos_matriculados';
}

export const useProfessorQuery = (options: UseProfessorQueryOptions = {}) => {
     const { isProfessor, disciplinasPermitidas, turmasPermitidas } = useProfessorFilter();
     const { aplicarFiltro = true, tabela } = options;

     const aplicarFiltroQuery = useMemo(() => {
          return <T>(query: PostgrestFilterBuilder<any, any, any, any, T>) => {
               // Se não é professor ou não deve aplicar filtro, retorna query original
               if (!isProfessor || !aplicarFiltro) {
                    return query;
               }

               // Aplicar filtros baseado na tabela
               switch (tabela) {
                    case 'agendamentos':
                         // Filtrar agendamentos por professor
                         return query.in('fk_id_disciplina', disciplinasPermitidas);

                    case 'disciplinas':
                         // Filtrar apenas disciplinas do professor
                         return query.in('id', disciplinasPermitidas);

                    case 'turmas':
                         // Filtrar apenas turmas das disciplinas do professor
                         return query.in('fk_id_disciplina', disciplinasPermitidas);

                    case 'alunos_matriculados':
                         // Filtrar alunos matriculados apenas nas turmas do professor
                         return query.in('fk_id_turma', turmasPermitidas);

                    default:
                         return query;
               }
          };
     }, [isProfessor, aplicarFiltro, disciplinasPermitidas, turmasPermitidas, tabela]);

     return {
          isProfessor,
          disciplinasPermitidas,
          turmasPermitidas,
          aplicarFiltroQuery,
          temPermissao: isProfessor ? disciplinasPermitidas.length > 0 : true,
     };
};
```

### 3. Componente de Layout para Professores

```typescript
// src/components/layouts/ProfessorLayout/ProfessorLayout.tsx

import { Alert, AlertTitle, Box, Typography } from '@mui/material';
import React from 'react';
import { useProfessorFilter } from '../../../contexts/ProfessorFilterContext/ProfessorFilterContext';

interface ProfessorLayoutProps {
     children: React.ReactNode;
     showWelcome?: boolean;
}

export const ProfessorLayout: React.FC<ProfessorLayoutProps> = ({ children, showWelcome = true }) => {
     const { isProfessor, professorData, loading, error } = useProfessorFilter();

     if (loading) {
          return (
               <Box sx={{ p: 3 }}>
                    <Typography>Carregando informações do professor...</Typography>
               </Box>
          );
     }

     if (error) {
          return (
               <Alert
                    severity='error'
                    sx={{ m: 3 }}
               >
                    <AlertTitle>Erro de Permissões</AlertTitle>
                    {error}
               </Alert>
          );
     }

     return (
          <Box>
               {isProfessor && showWelcome && (
                    <Alert
                         severity='info'
                         sx={{ mb: 3 }}
                    >
                         <AlertTitle>Área do Professor</AlertTitle>
                         Bem-vindo(a), <strong>{professorData?.nome}</strong>! Você está visualizando apenas dados das suas disciplinas e turmas.
                         <br />
                         <strong>Disciplinas:</strong> {professorData?.disciplinas.map((d) => d.nome).join(', ')}
                    </Alert>
               )}
               {children}
          </Box>
     );
};
```

### 4. Hooks Modificados com Filtro de Professor

#### 4.1. Hook de Agendamentos Filtrado

```typescript
// src/hooks/useAgendamentosAdminProfessor.ts

import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../config/supabaseConfig';
import { useProfessorQuery } from './useProfessorQuery';

// ... interface AgendamentoAluno (mesmo do arquivo original)

export const useAgendamentosAdminProfessor = () => {
     const [agendamentos, setAgendamentos] = useState<AgendamentoAluno[]>([]);
     const [loading, setLoading] = useState(false);
     const [error, setError] = useState<string | null>(null);
     const [totalRegistros, setTotalRegistros] = useState(0);

     const { aplicarFiltroQuery, isProfessor } = useProfessorQuery({
          tabela: 'agendamentos',
     });

     const carregarAgendamentos = useCallback(
          async (filtros: FiltrosAgendamento = {}) => {
               setLoading(true);
               setError(null);

               try {
                    let query = supabase.from('agendamentos_alunos').select(
                         `
          *,
          agendamento_professor:fk_id_agendamento_professor (
            titulo,
            valor_por_vaga,
            fk_id_disciplina,
            disciplina:fk_id_disciplina (
              id,
              nome
            ),
            professor:fk_id_professor (
              id,
              nome,
              email
            )
          ),
          aluno:fk_id_aluno (
            id,
            nome,
            email
          )
        `,
                         { count: 'exact' },
                    );

                    // Aplicar filtro de professor se necessário
                    query = aplicarFiltroQuery(query);

                    // Aplicar outros filtros... (resto da implementação igual)

                    const { data, error: queryError, count } = await query;

                    if (queryError) throw queryError;

                    setAgendamentos(data || []);
                    setTotalRegistros(count || 0);
               } catch (err) {
                    console.error('Erro ao carregar agendamentos:', err);
                    setError('Erro ao carregar agendamentos');
               } finally {
                    setLoading(false);
               }
          },
          [aplicarFiltroQuery],
     );

     // ... resto dos métodos (atualizarStatus, cancelar, confirmar)

     return {
          agendamentos,
          loading,
          error,
          totalRegistros,
          carregarAgendamentos,
          atualizarStatusAgendamento,
          cancelarAgendamento,
          confirmarAgendamento,
          recarregarDados: carregarAgendamentos,
          isProfessor, // Expor se é professor para ajustar UI
     };
};
```

#### 4.2. Hook para Alunos Matriculados

```typescript
// src/hooks/useAlunosMatriculados.ts

import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../config/supabaseConfig';
import { useProfessorQuery } from './useProfessorQuery';

interface AlunoMatriculado {
     id: number;
     nome: string;
     email: string;
     turma_id: number;
     turma_descricao: string;
     disciplina_nome: string;
     professor_nome: string;
     data_matricula: string;
     status_contrato: string;
}

export const useAlunosMatriculados = () => {
     const [alunos, setAlunos] = useState<AlunoMatriculado[]>([]);
     const [loading, setLoading] = useState(false);
     const [error, setError] = useState<string | null>(null);

     const { aplicarFiltroQuery, isProfessor, turmasPermitidas } = useProfessorQuery({
          tabela: 'alunos_matriculados',
     });

     const carregarAlunos = useCallback(async () => {
          setLoading(true);
          setError(null);

          try {
               let query = supabase
                    .from('alunos_contrato_turmas')
                    .select(
                         `
          id,
          fk_id_aluno,
          fk_id_turma,
          created_at,
          data_cancelamento,
          aluno:fk_id_aluno (
            id,
            nome,
            email
          ),
          turma:fk_id_turma (
            id,
            descricao,
            disciplina:fk_id_disciplina (
              nome,
              professor:fk_id_professor (
                nome
              )
            )
          )
        `,
                    )
                    .is('deleted_at', null);

               // Aplicar filtro de professor
               if (isProfessor) {
                    query = query.in('fk_id_turma', turmasPermitidas);
               }

               const { data, error: queryError } = await query;

               if (queryError) throw queryError;

               const alunosFormatados =
                    data?.map((item) => ({
                         id: item.aluno?.id || 0,
                         nome: item.aluno?.nome || '',
                         email: item.aluno?.email || '',
                         turma_id: item.turma?.id || 0,
                         turma_descricao: item.turma?.descricao || '',
                         disciplina_nome: item.turma?.disciplina?.nome || '',
                         professor_nome: item.turma?.disciplina?.professor?.nome || '',
                         data_matricula: item.created_at,
                         status_contrato: item.data_cancelamento ? 'Cancelado' : 'Ativo',
                    })) || [];

               setAlunos(alunosFormatados);
          } catch (err) {
               console.error('Erro ao carregar alunos matriculados:', err);
               setError('Erro ao carregar alunos matriculados');
          } finally {
               setLoading(false);
          }
     }, [aplicarFiltroQuery, isProfessor, turmasPermitidas]);

     useEffect(() => {
          carregarAlunos();
     }, [carregarAlunos]);

     return {
          alunos,
          loading,
          error,
          recarregar: carregarAlunos,
          isProfessor,
     };
};
```

### 5. Componente de DataGrid Filtrado

```typescript
// src/components/grids/AlunosMatriculadosDataGrid.tsx

import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { Alert, AlertTitle, Box, Card, CardContent, Typography } from '@mui/material';
import React from 'react';
import { useAlunosMatriculados } from '../../hooks/useAlunosMatriculados';
import { ProfessorLayout } from '../layouts/ProfessorLayout/ProfessorLayout';

export const AlunosMatriculadosDataGrid: React.FC = () => {
     const { alunos, loading, error, isProfessor } = useAlunosMatriculados();

     const columns: GridColDef[] = [
          { field: 'nome', headerName: 'Nome do Aluno', width: 200 },
          { field: 'email', headerName: 'Email', width: 250 },
          { field: 'turma_descricao', headerName: 'Turma', width: 180 },
          { field: 'disciplina_nome', headerName: 'Disciplina', width: 150 },
          ...(isProfessor ? [] : [{ field: 'professor_nome', headerName: 'Professor', width: 150 }]),
          {
               field: 'status_contrato',
               headerName: 'Status',
               width: 100,
               renderCell: (params) => (
                    <Chip
                         label={params.value}
                         color={params.value === 'Ativo' ? 'success' : 'error'}
                         size='small'
                    />
               ),
          },
          {
               field: 'data_matricula',
               headerName: 'Data Matrícula',
               width: 130,
               valueFormatter: (params) => new Date(params.value).toLocaleDateString('pt-BR'),
          },
     ];

     if (error) {
          return (
               <Alert severity='error'>
                    <AlertTitle>Erro</AlertTitle>
                    {error}
               </Alert>
          );
     }

     return (
          <ProfessorLayout>
               <Card>
                    <CardContent>
                         <Box sx={{ mb: 2 }}>
                              <Typography
                                   variant='h6'
                                   component='h2'
                              >
                                   Alunos Matriculados
                                   {isProfessor && ' (Suas Turmas)'}
                              </Typography>
                              <Typography
                                   variant='body2'
                                   color='text.secondary'
                              >
                                   Total: {alunos.length} aluno(s)
                              </Typography>
                         </Box>

                         <DataGrid
                              rows={alunos}
                              columns={columns}
                              loading={loading}
                              autoHeight
                              disableRowSelectionOnClick
                              initialState={{
                                   pagination: {
                                        paginationModel: { pageSize: 10 },
                                   },
                              }}
                              pageSizeOptions={[5, 10, 25]}
                         />
                    </CardContent>
               </Card>
          </ProfessorLayout>
     );
};
```

### 6. Rotas Condicionais para Professor

```typescript
// src/routes/ProfessorRoutes.tsx

import { Route } from 'react-router-dom';
import { AgendamentosAdminPage } from '../components/pages/AgendamentosAdminPage';
import { AlunosMatriculadosDataGrid } from '../components/grids/AlunosMatriculadosDataGrid';
import { ProfessorFilterProvider } from '../contexts/ProfessorFilterContext/ProfessorFilterContext';

const ProfessorRoutes = () => (
     <ProfessorFilterProvider>
          <>
               {/* Agenda dos Professores */}
               <Route
                    path='agendamentos'
                    element={<AgendamentosAdminPage />}
               />

               {/* Gerenciar Agendamentos */}
               <Route
                    path='agendamentos/gerenciar'
                    element={<AgendamentosAdminPage />}
               />

               {/* Agendamentos Confirmados */}
               <Route
                    path='agendamentos/confirmados'
                    element={<AgendamentosAdminPage />}
               />

               {/* Reservas Temporárias */}
               <Route
                    path='agendamentos/reservas-temporarias'
                    element={<AgendamentosAdminPage />}
               />

               {/* Alunos Matriculados */}
               <Route
                    path='alunos/matriculados'
                    element={<AlunosMatriculadosDataGrid />}
               />
          </>
     </ProfessorFilterProvider>
);

export default ProfessorRoutes;
```

### 7. Integração no Sistema Principal

```typescript
// src/routes/UserRoutes.tsx (Modificação)

import { Routes } from 'react-router-dom';
import UserLayout from '../components/layouts/UserLayout/UserLayout';
import { useUserContext } from '../contexts/UserContext/useUserContext';
import ProfessorRoutes from './ProfessorRoutes';
// ... outras importações

const UserRoutes = () => {
     const { userData } = useUserContext();

     return (
          <UserLayout title=''>
               <Routes>
                    {/* Rotas condicionais baseadas no tipo de usuário */}
                    {userData?.fk_id_tipo_pessoa === 4 ? (
                         // Se é professor, usar rotas filtradas
                         ProfessorRoutes()
                    ) : (
                         // Se não é professor, usar todas as rotas
                         <>
                              {UtilRoutes()}
                              {EstruturaRoutes()}
                              {AlunoRoutes()}
                              {ContratoRoutes()}
                              {MaterialRoutes()}
                              {ProfessorRoutes()}
                              {RelatorioRoutes()}
                              {AcademicoRoutes()}
                              {AgendamentosRoutes()}
                         </>
                    )}
               </Routes>
          </UserLayout>
     );
};
```

## 🔒 Segurança e RLS (Row Level Security)

### Políticas de Segurança no Supabase

Implementar RLS no Supabase para garantir segurança a nível de banco:

```sql
-- Política para agendamentos_professores
CREATE POLICY "Professores veem apenas seus agendamentos" ON agendamentos_professores
  FOR SELECT
  USING (
    fk_id_professor = (
      SELECT id FROM pessoas
      WHERE uid = auth.uid() AND fk_id_tipo_pessoa = 4
    )
  );

-- Política para agendamentos_alunos
CREATE POLICY "Professores veem agendamentos de suas disciplinas" ON agendamentos_alunos
  FOR SELECT
  USING (
    fk_id_agendamento_professor IN (
      SELECT ap.id FROM agendamentos_professores ap
      INNER JOIN pessoas p ON ap.fk_id_professor = p.id
      WHERE p.uid = auth.uid() AND p.fk_id_tipo_pessoa = 4
    )
  );

-- Política para disciplinas
CREATE POLICY "Professores veem apenas suas disciplinas" ON disciplinas
  FOR SELECT
  USING (
    fk_id_professor = (
      SELECT id FROM pessoas
      WHERE uid = auth.uid() AND fk_id_tipo_pessoa = 4
    )
  );

-- Política para turmas
CREATE POLICY "Professores veem turmas de suas disciplinas" ON turmas
  FOR SELECT
  USING (
    fk_id_disciplina IN (
      SELECT d.id FROM disciplinas d
      INNER JOIN pessoas p ON d.fk_id_professor = p.id
      WHERE p.uid = auth.uid() AND p.fk_id_tipo_pessoa = 4
    )
  );

-- Política para alunos_contrato_turmas
CREATE POLICY "Professores veem alunos de suas turmas" ON alunos_contrato_turmas
  FOR SELECT
  USING (
    fk_id_turma IN (
      SELECT t.id FROM turmas t
      INNER JOIN disciplinas d ON t.fk_id_disciplina = d.id
      INNER JOIN pessoas p ON d.fk_id_professor = p.id
      WHERE p.uid = auth.uid() AND p.fk_id_tipo_pessoa = 4
    )
  );
```

## 🎨 Interface do Usuário

### Menu Condicional

```typescript
// src/components/layouts/UserLayout/Sidebar.tsx (Modificação)

import { useProfessorFilter } from '../../../contexts/ProfessorFilterContext/ProfessorFilterContext';

const Sidebar: React.FC = () => {
  const { isProfessor } = useProfessorFilter();

  const menuItems = isProfessor ? [
    // Menu restrito para professores
    {
      title: 'Aulas',
      items: [
        { label: 'Agenda dos Professores', path: '/user/agendamentos' },
        { label: 'Gerenciar Agendamentos', path: '/user/agendamentos/gerenciar' },
        { label: 'Agendamentos Confirmados', path: '/user/agendamentos/confirmados' },
        { label: 'Reservas Temporárias', path: '/user/agendamentos/reservas-temporarias' }
      ]
    },
    {
      title: 'Alunos',
      items: [
        { label: 'Alunos Matriculados', path: '/user/alunos/matriculados' }
      ]
    }
  ] : [
    // Menu completo para administradores
    // ... menu completo atual
  ];

  return (
    // ... renderizar menu baseado em menuItems
  );
};
```

## 🚀 Implementação Step-by-Step

### Passo 1: Contexto e Provider

1. Criar `ProfessorFilterContext.tsx`
2. Adicionar provider no `App.tsx` ou `UserRoutes.tsx`

### Passo 2: Hooks Utilitários

1. Implementar `useProfessorQuery.ts`
2. Modificar hooks existentes para usar filtros

### Passo 3: Componentes UI

1. Criar `ProfessorLayout.tsx`
2. Modificar DataGrids para usar layout

### Passo 4: Rotas Condicionais

1. Criar `ProfessorRoutes.tsx`
2. Modificar `UserRoutes.tsx`

### Passo 5: Segurança (RLS)

1. Implementar políticas no Supabase
2. Testar com usuários professor

### Passo 6: Interface

1. Modificar menu lateral
2. Ajustar breadcrumbs e navegação

## 🧪 Testes Necessários

### Cenários de Teste

1. **Login como Professor**

     - Verificar se apenas disciplinas próprias aparecem
     - Verificar se apenas turmas próprias aparecem
     - Verificar se apenas agendamentos próprios aparecem

2. **Login como Administrador**

     - Verificar se todos os dados aparecem normalmente
     - Verificar se não há filtros aplicados

3. **Segurança**

     - Tentar acessar dados de outros professores via API
     - Verificar se RLS está funcionando

4. **Performance**
     - Verificar se queries estão otimizadas
     - Verificar tempo de carregamento

## ⚠️ Considerações Importantes

### Limitações

-    Professores não terão acesso a relatórios gerais
-    Não poderão visualizar dados de outros professores
-    Funcionalidades administrativas ficam restritas

### Benefícios

-    Maior segurança dos dados
-    Interface mais limpa e focada
-    Melhor performance (menos dados carregados)
-    Conformidade com LGPD

### Manutenção

-    Ao adicionar novas funcionalidades, verificar se precisam de filtro
-    Manter sincronização entre filtros de frontend e RLS
-    Documentar sempre que criar novos relacionamentos

## 📋 Checklist de Implementação

-    [ ] Criar contexto ProfessorFilterContext
-    [ ] Implementar hook useProfessorQuery
-    [ ] Modificar hooks existentes (useAgendamentosAdmin, etc.)
-    [ ] Criar layout ProfessorLayout
-    [ ] Modificar componentes DataGrid
-    [ ] Implementar rotas condicionais
-    [ ] Configurar RLS no Supabase
-    [ ] Modificar menu lateral
-    [ ] Testar com usuário professor
-    [ ] Testar com usuário administrador
-    [ ] Validar segurança
-    [ ] Documentar mudanças

## 🎯 Resultado Esperado

Após a implementação, quando um professor fizer login:

1. **Verá apenas suas disciplinas** nas listagens
2. **Verá apenas suas turmas** nos filtros e dados
3. **Verá apenas seus agendamentos** na agenda
4. **Verá apenas alunos matriculados** em suas turmas
5. **Terá menu simplificado** com apenas as opções relevantes
6. **Receberá feedback visual** indicando que está em modo professor

O sistema manterá total compatibilidade com administradores, que continuarão vendo todos os dados sem restrições.
