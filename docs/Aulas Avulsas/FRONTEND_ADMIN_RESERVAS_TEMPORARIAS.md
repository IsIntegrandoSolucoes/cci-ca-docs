# 🔧 Portal Administrativo - Sistema de Reservas Temporárias

## Visão Geral

O portal administrativo foi atualizado para gerenciar o novo sistema de reservas temporárias, onde múltiplos alunos podem agendar a mesma vaga, mas apenas quem pagar primeiro garante a reserva.

## 📊 Componentes Implementados

### 1. `useReservasTemporariasAdmin.ts`

Hook especializado para administradores monitorarem reservas temporárias.

**Funcionalidades:**

-    📋 Lista todas as reservas com status 'agendado'
-    ⏱️ Calcula tempo restante em tempo real
-    📈 Estatísticas de conversão (24h)
-    🧹 Limpeza forçada de reservas expiradas
-    ❌ Cancelamento manual de reservas

**Uso Básico:**

```tsx
const { reservasTemporarias, estatisticas, cancelarReserva, forcarLimpezaExpiradas } = useReservasTemporariasAdmin();
```

### 2. `useAgendamentosAdmin.ts`

Hook principal para gerenciar todos os agendamentos do sistema.

**Funcionalidades:**

-    🔍 Visualização de todos os agendamentos
-    🎛️ Filtros avançados (status, data, professor, aluno)
-    ✅ Confirmação manual de pagamentos
-    ❌ Cancelamento com motivo
-    🔄 Auto-atualização para reservas temporárias

**Filtros Disponíveis:**

```tsx
const filtros = {
     status: ['agendado', 'confirmado'],
     dataInicio: '2024-01-01',
     dataFim: '2024-12-31',
     professorId: 123,
     alunoId: 456,
};

await carregarAgendamentos(filtros);
```

### 3. `ReservasTemporariasDataGrid.tsx`

DataGrid especializado para monitorar reservas temporárias ativas.

**Características:**

-    ⏰ Contador de tempo restante em tempo real
-    🎨 Cores baseadas na urgência (verde → amarelo → vermelho)
-    📊 Estatísticas de conversão
-    🗑️ Limpeza automática de expiradas
-    ❌ Cancelamento individual

**Colunas Principais:**

-    Aluno (nome + email)
-    Aula (título + disciplina + professor)
-    Data da aula
-    Valor da vaga
-    Tempo restante (com cores de urgência)
-    Ações administrativas

### 4. `AgendamentosAdminDataGrid.tsx`

DataGrid completo para gerenciar todos os agendamentos.

**Funcionalidades:**

-    📈 Estatísticas rápidas por status
-    🎛️ Filtros avançados integrados
-    🔄 Ações contextuais por status
-    💳 Confirmação manual de pagamentos
-    ❌ Cancelamento com motivo

**Status e Ações:**

-    **Agendado**: Confirmar pagamento | Cancelar reserva
-    **Confirmado**: Cancelar agendamento
-    **Cancelado**: Apenas visualização
-    **Realizado**: Apenas visualização

### 5. `AgendamentosAdminPage.tsx`

Página completa integrando todos os componentes.

**Estrutura:**

-    **Aba 1**: Todos os Agendamentos (visão geral)
-    **Aba 2**: Reservas Temporárias (monitoramento ativo)
-    📊 Estatísticas unificadas
-    🎯 Ações centralizadas

## 🚀 Como Integrar

### 1. Importar na Aplicação

```tsx
// App.tsx ou Routes
import { AgendamentosAdminPage } from './components/pages/AgendamentosAdminPage';

// Adicionar à rota
<Route
     path='/admin/agendamentos'
     element={<AgendamentosAdminPage />}
/>;
```

### 2. Usar Componentes Separadamente

```tsx
// Para usar apenas o DataGrid de reservas
import { ReservasTemporariasDataGrid } from './components/grids/ReservasTemporariasDataGrid';

<ReservasTemporariasDataGrid
     onReservaCancel={(id) => console.log('Cancelada:', id)}
     showStatistics={true}
/>;
```

### 3. Integração com Menu

```tsx
// Adicionar ao menu administrativo
<MenuItem onClick={() => navigate('/admin/agendamentos')}>
     <ScheduleIcon />
     Gerenciar Agendamentos
</MenuItem>
```

## ⚡ Recursos em Tempo Real

### Auto-Atualização

-    **Reservas Temporárias**: Atualização a cada 30 segundos
-    **Contadores**: Atualização a cada 1 segundo
-    **Limpeza Automática**: Remove expiradas da visualização

### Notificações Visuais

-    **🟢 Verde**: Reserva com mais de 10 minutos
-    **🟡 Amarelo**: Reserva entre 5-10 minutos
-    **🔴 Vermelho**: Reserva com menos de 5 minutos

### Estatísticas Dinâmicas

```tsx
const estatisticas = {
     totalAgendados: 15, // Reservas ativas
     totalExpirados: 3, // Expiradas (24h)
     totalConfirmados: 45, // Pagamentos confirmados
     valorPendente: 2340.0, // Valor das reservas ativas
     tempoMedioConfirmacao: 8, // Minutos médios para pagar
};
```

## 🛠️ Ações Administrativas

### 1. Confirmar Pagamento Manualmente

```tsx
const sucesso = await confirmarAgendamento(agendamentoId);
if (sucesso) {
     // Agendamento passa de 'agendado' para 'confirmado'
     // Vaga fica definitivamente ocupada
}
```

### 2. Cancelar Reserva com Motivo

```tsx
const sucesso = await cancelarAgendamento(agendamentoId, 'Motivo do cancelamento');
if (sucesso) {
     // Agendamento passa para 'cancelado'
     // Vaga fica disponível novamente
}
```

### 3. Limpeza Forçada de Expiradas

```tsx
const quantidade = await forcarLimpezaExpiradas();
console.log(`${quantidade} reservas expiradas foram limpas`);
```

## 📋 Casos de Uso Administrativo

### 1. Monitoramento Ativo

-    Acompanhar reservas prestes a expirar
-    Identificar padrões de conversão
-    Detectar problemas de pagamento

### 2. Intervenção Manual

-    Confirmar pagamentos off-line
-    Cancelar reservas problemáticas
-    Fazer ajustes emergenciais

### 3. Análise Operacional

-    Tempo médio de conversão
-    Taxa de abandono por horário
-    Performance por professor/disciplina

### 4. Limpeza de Dados

-    Remover reservas orfãs
-    Consolidar estatísticas
-    Manter integridade do sistema

## 🔗 Integração com Sistema Existente

O sistema funciona perfeitamente com a infraestrutura existente:

-    ✅ **Triggers do Banco**: Mantém contadores de vagas
-    ✅ **Payments API**: Conciliação automática via PIX
-    ✅ **Notificações**: Sistemas de email/SMS existentes
-    ✅ **Logs**: Rastreamento de ações administrativas

## 📈 Métricas de Sucesso

### KPIs Principais

-    **Taxa de Conversão**: % de reservas que viram pagamentos
-    **Tempo Médio**: Minutos entre reserva e pagamento
-    **Taxa de Expiração**: % de reservas que expiram
-    **Valor Capturado**: Total convertido vs. valor potencial

### Alertas Sugeridos

-    🚨 Muitas reservas expirando (> 30% em 1 hora)
-    ⚠️ Tempo médio de conversão aumentando
-    📊 Queda na taxa de conversão por período
-    💰 Valor pendente muito alto (risco de perda)

---

## 🎯 Próximos Passos

1. **Integrar** os componentes nas rotas administrativas
2. **Configurar** notificações para administradores
3. **Implementar** relatórios de performance
4. **Adicionar** logs de auditoria para ações manuais
5. **Criar** dashboards executivos com métricas avançadas
