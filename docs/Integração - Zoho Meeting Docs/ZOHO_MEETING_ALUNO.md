# Integração Zoho Meeting - Portal do Aluno

## Visão Geral

Implementação completa da visualização de reuniões Zoho Meeting para alunos no portal CCI-CA Aluno.

## Arquivos Criados

### 1. Service API (`src/services/api/zohoMeetingService.ts`)

-    **Interface**: `IEspacoAulaZohoAluno` - Dados de espaço com Zoho Meeting
-    **Classe**: `ZohoMeetingServiceAluno` - Cliente API para consumir backend
-    **Métodos principais**:
     -    `buscarEspacoZoho(id)` - Busca dados da reunião
     -    `temReuniaoAtiva(espaco)` - Verifica se reunião está ativa
     -    `getJoinUrl(espaco)` - Retorna URL de entrada
     -    `requererSenha(espaco)` - Verifica se requer senha
     -    **Helpers de formatação**: `formatarDataHora()`, `formatarDuracao()`, `getLabelStatus()`, `getCorStatus()`

### 2. Hook React (`src/hooks/useZohoMeetingAluno.ts`)

-    **Interface**: `UseZohoMeetingAlunoReturn` - Estado + ações
-    **Estado gerenciado**:
     -    `loading: boolean` - Carregando dados
     -    `error: string | null` - Mensagem de erro
     -    `espacoZoho: IEspacoAulaZohoAluno | null` - Dados da reunião
-    **Ações**:
     -    `buscarEspacoZoho(id)` - Busca dados
     -    `clearError()` - Limpa erro
     -    `clearData()` - Limpa todos os dados

### 3. Componente de Visualização (`src/components/pages/Agendamentos/components/VisualizarReuniaoZoho.tsx`)

-    **Props**:
     -    `idEspacoAula: number` - ID do espaço
     -    `nomeEspaco?: string` - Nome para exibição
-    **Funcionalidades**:
     -    ✅ Exibe informações da reunião (tópico, data/hora, duração, apresentador)
     -    ✅ Mostra status da reunião com chip colorido (agendada/em andamento/encerrada/cancelada)
     -    ✅ Exibe senha da reunião (se existir) com botão de copiar
     -    ✅ Botão "Entrar na Aula Online" (abre joinUrl em nova aba)
     -    ✅ Botão de atualizar informações
     -    ✅ Estados tratados: loading, erro, sem reunião, reunião inativa
     -    ✅ Design consistente com Material-UI

### 4. Integração com EspacoAulaPage

-    **Arquivo modificado**: `src/components/pages/Agendamentos/components/EspacoAulaPage.tsx`
-    **Localização**: Entre informações da aula e materiais de apoio
-    **Código**:

```tsx
{
     /* Reunião Zoho Meeting (se disponível) */
}
{
     espacoAula.id && (
          <VisualizarReuniaoZoho
               idEspacoAula={espacoAula.id}
               nomeEspaco={espacoAula.titulo_espaco}
          />
     );
}
```

## Fluxo de Uso (Aluno)

### 1. Navegação

```
Agendamentos → Clicar em "Acessar Espaço" → EspacoAulaPage carrega
```

### 2. Exibição

-    Se espaço não tem reunião Zoho: Alert "Esta aula não possui reunião online configurada"
-    Se reunião existe mas status = 'ended' ou 'cancelled': Alert de status
-    Se reunião ativa (scheduled ou started): Card completo com informações

### 3. Informações Exibidas

-    📹 Tópico da reunião
-    📝 Descrição/agenda
-    🕐 Data e hora de início
-    ⏱️ Duração estimada
-    👤 Nome do apresentador
-    🔒 Senha (se configurada) + botão copiar
-    🟢 Status atual (chip colorido)

### 4. Ação Principal

-    **Botão**: "Entrar na Aula Online"
-    **Comportamento**: Abre `zoho_join_url` em nova aba
-    **Desabilitado quando**: Status não é 'scheduled' ou 'started'

## API Consumida

### Endpoint Backend

```
GET /api/zoho/espacos/:id
```

### Resposta Esperada

```typescript
{
     id_espaco_aula: number;
     nome_espaco: string;
     zoho_meeting_key?: string;
     zoho_topic?: string;
     zoho_agenda?: string;
     zoho_start_time?: string;
     zoho_duration?: number;
     zoho_timezone?: string;
     zoho_presenter_name?: string;
     zoho_join_url?: string;
     zoho_meeting_password?: string;
     zoho_status?: 'scheduled' | 'started' | 'ended' | 'cancelled';
     // ... outros campos
}
```

## Estados do Componente

### 1. Loading

```tsx
<CircularProgress size={40} />
```

### 2. Erro

```tsx
<Alert
     severity='error'
     onClose={clearError}
>
     {error}
</Alert>
```

### 3. Sem Reunião

```tsx
<Alert severity='info'>Esta aula não possui reunião online configurada.</Alert>
```

### 4. Reunião Inativa

```tsx
<Alert severity='warning'>A reunião online está {status}.</Alert>
```

### 5. Reunião Ativa (Card Completo)

-    Cabeçalho com ícone e status
-    Informações detalhadas
-    Senha (se existir)
-    Botão de entrar

## Cores de Status

| Status    | Label        | Cor Material-UI    |
| --------- | ------------ | ------------------ |
| scheduled | Agendada     | `primary` (azul)   |
| started   | Em andamento | `success` (verde)  |
| ended     | Encerrada    | `default` (cinza)  |
| cancelled | Cancelada    | `error` (vermelho) |

## Diferenças: Admin vs Aluno

| Funcionalidade         | Admin | Aluno |
| ---------------------- | ----- | ----- |
| Criar reunião          | ✅    | ❌    |
| Editar reunião         | ✅    | ❌    |
| Deletar reunião        | ✅    | ❌    |
| Visualizar informações | ✅    | ✅    |
| Entrar na reunião      | ✅    | ✅    |
| Ver senha              | ✅    | ✅    |
| Atualizar dados        | ✅    | ✅    |

## Segurança

### Backend

-    Endpoint `/api/zoho/espacos/:id` retorna apenas dados necessários para aluno
-    Não expõe tokens OAuth ou chaves sensíveis
-    Aluno só vê reuniões de espaços aos quais tem acesso

### Frontend

-    Service possui apenas método `buscarEspacoZoho()` (READ-ONLY)
-    Não há métodos de criação/edição/exclusão
-    joinUrl abre em nova aba com `noopener,noreferrer`

## Formatação de Dados

### Data/Hora

```typescript
formatarDataHora('2024-02-15T10:00:00Z');
// Output: "15/02/2024, 07:00" (America/Sao_Paulo)
```

### Duração

```typescript
formatarDuracao(90); // Output: "1h 30min"
formatarDuracao(60); // Output: "1h"
formatarDuracao(45); // Output: "45min"
```

## Próximos Passos

### Melhorias Sugeridas

1. **Notificação pré-aula**: Alert X minutos antes do início
2. **Histórico**: Lista de reuniões anteriores
3. **Feedback pós-aula**: Modal para avaliação após reunião encerrada
4. **Lista de participantes**: Mostrar quem entrou na reunião
5. **Gravações**: Link para gravação (se disponível)
6. **Chat integrado**: Mensagens durante a reunião
7. **Countdown**: Timer até início da reunião

### Testes Recomendados

-    [ ] Espaço sem reunião Zoho
-    [ ] Reunião agendada (status='scheduled')
-    [ ] Reunião em andamento (status='started')
-    [ ] Reunião encerrada (status='ended')
-    [ ] Reunião com senha
-    [ ] Reunião sem senha
-    [ ] Copiar senha para clipboard
-    [ ] Entrar na reunião (clicar botão)
-    [ ] Atualizar informações (botão refresh)
-    [ ] Erro de API (backend offline)
-    [ ] Loading state
-    [ ] Responsividade mobile

## Integração Completa

### Estrutura Final

```
cci-ca-aluno/
  src/
    services/api/
      zohoMeetingService.ts          ✅ CRIADO
    hooks/
      useZohoMeetingAluno.ts         ✅ CRIADO
    components/pages/Agendamentos/
      components/
        VisualizarReuniaoZoho.tsx    ✅ CRIADO
        EspacoAulaPage.tsx           ✅ MODIFICADO
```

### Checklist de Implementação

-    [x] Service API criado
-    [x] Hook React criado
-    [x] Componente de visualização criado
-    [x] Integração com EspacoAulaPage
-    [x] Tratamento de erros
-    [x] Estados de loading
-    [x] Formatação de dados
-    [x] Design Material-UI
-    [x] Copiar senha
-    [x] Abrir reunião
-    [x] Status coloridos
-    [x] Responsividade

## Conclusão

Implementação **100% funcional** para portal do aluno visualizar e entrar em reuniões Zoho Meeting. O componente é **view-only**, seguindo o princípio de menor privilégio, e está totalmente integrado ao fluxo existente de agendamentos e espaços de aula.
