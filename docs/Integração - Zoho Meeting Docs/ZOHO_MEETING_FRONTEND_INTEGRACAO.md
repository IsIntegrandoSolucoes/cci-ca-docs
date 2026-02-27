# 🎥 Integração Zoho Meeting - Frontend Admin

## ✅ Implementação Completa

**Data**: 08 de outubro de 2025  
**Status**: Frontend pronto para integração

---

## 📦 Arquivos Criados

### 1️⃣ Service Layer

📁 `src/services/api/zohoMeetingApiService.ts` (290 linhas)

-    Cliente Axios configurado
-    8 métodos de API
-    Tipos TypeScript completos
-    Tratamento de erros robusto

### 2️⃣ Hook Customizado

📁 `src/hooks/useZohoMeeting.ts` (240 linhas)

-    Gerenciamento de estado
-    10 métodos de ação
-    Loading/error handling
-    Callbacks otimizados

### 3️⃣ Componente Principal

📁 `src/components/pages/Academico/EspacoAula/GerenciarReuniaoZoho/GerenciarReuniaoZoho.tsx` (550 linhas)

-    Interface completa de gestão
-    Criar/Editar/Deletar reunião
-    Copiar links (professor/alunos)
-    Visualização de status e dados

---

## 🔌 Como Integrar no ManterEspacoAula

### Passo 1: Importar o Componente

No arquivo `ManterEspacoAula.tsx`, adicione o import:

```tsx
import GerenciarReuniaoZoho from '../GerenciarReuniaoZoho/GerenciarReuniaoZoho';
```

### Passo 2: Adicionar ao Layout

Insira o componente no lugar adequado do formulário (sugiro após os dados principais do espaço):

```tsx
{/* Dados básicos do espaço */}
<TextField label="Nome" {...} />
<TextField label="Capacidade" {...} />

{/* ===== INTEGRAÇÃO ZOHO MEETING ===== */}
{id && (  // Só mostrar se o espaço já foi salvo
  <Box sx={{ mt: 3 }}>
    <GerenciarReuniaoZoho
      idEspacoAula={Number(id)}
      nomeEspaco={formData.nome || ''}
      onSuccess={() => {
        // Opcional: atualizar dados do formulário
        console.log('Reunião Zoho atualizada!');
      }}
    />
  </Box>
)}
```

### Passo 3: Exemplo Completo de Integração

```tsx
// ManterEspacoAula.tsx
import React from 'react';
import { Box, Grid, TextField } from '@mui/material';
import GerenciarReuniaoZoho from '../GerenciarReuniaoZoho/GerenciarReuniaoZoho';

export const ManterEspacoAula: React.FC = () => {
  const { id } = useParams(); // ID do espaço (se estiver editando)
  const [formData, setFormData] = useState({...});

  return (
    <Box>
      <Grid container spacing={2}>
        {/* Campos do formulário principal */}
        <Grid item xs={12}>
          <TextField label="Nome do Espaço" {...} />
        </Grid>
        <Grid item xs={12} sm={6}>
          <TextField label="Capacidade Máxima" {...} />
        </Grid>
        {/* ... outros campos ... */}

        {/* INTEGRAÇÃO ZOHO MEETING */}
        {id && (
          <Grid item xs={12}>
            <GerenciarReuniaoZoho
              idEspacoAula={Number(id)}
              nomeEspaco={formData.nome || ''}
              onSuccess={() => {
                // Callback opcional após sucesso
                alert('Reunião Zoho atualizada!');
              }}
            />
          </Grid>
        )}

        {/* Botões de ação (Salvar, Cancelar) */}
        <Grid item xs={12}>
          <Button type="submit">Salvar Espaço</Button>
        </Grid>
      </Grid>
    </Box>
  );
};
```

---

## 🎨 Funcionalidades do Componente

### 📊 Visualização de Dados

Quando há uma reunião vinculada, o componente mostra:

-    **Status**: Badge colorido (Agendada/Em Andamento/Finalizada)
-    **Datas**: Início e duração
-    **Link Organizador**: Para o professor iniciar a reunião
-    **Link Participantes**: Para os alunos entrarem
-    **Senha**: Se configurada
-    **Gravação**: Se está habilitada
-    **Último Sincronismo**: Timestamp da última atualização

### ⚙️ Ações Disponíveis

1. **Criar Reunião** (se não existe)

     - Modal com formulário completo
     - Campos: Tópico, Agenda, Data/Hora, Duração, Senha, Gravação

2. **Editar Reunião** (se existe)

     - Abre modal com dados preenchidos
     - Atualiza via API

3. **Deletar Reunião** (se existe)

     - Confirmação antes de deletar
     - Limpa dados do banco

4. **Copiar Links**

     - Botão para copiar link do organizador
     - Botão para copiar link dos alunos
     - Feedback visual

5. **Atualizar Dados**
     - Botão para recarregar do backend
     - Sincroniza status atualizado

---

## 🧪 Como Testar

### 1. Ambiente de Desenvolvimento

```bash
cd cci-ca-admin
npm run dev
```

### 2. Navegue para um Espaço de Aula

```
http://localhost:5173/academico/espacos-aula/1
```

(Substitua `1` pelo ID de um espaço existente)

### 3. Teste o Fluxo Completo

#### Criar Reunião

1. Clique em "Criar Reunião Online"
2. Preencha:
     - **Tópico**: "Aula de Teste"
     - **Data/Hora**: Amanhã às 14:00
     - **Duração**: 60 minutos
     - **Senha**: "teste123"
3. Clique em "Criar Reunião"
4. Aguarde o card aparecer com os links

#### Copiar Links

1. Clique no ícone de cópia ao lado do "Link do Organizador"
2. Cole em nova aba para verificar
3. Faça o mesmo com "Link para Participantes"

#### Editar Reunião

1. Clique em "Editar Reunião"
2. Altere a duração para 90 minutos
3. Salve e verifique atualização

#### Deletar Reunião

1. Clique em "Deletar Reunião"
2. Confirme a ação
3. Verifique que o card volta ao estado inicial

---

## 🎯 Estados Visuais

### Sem Reunião

```
┌─────────────────────────────────────────┐
│ 🎥 Reunião Zoho Meeting                 │
├─────────────────────────────────────────┤
│                                         │
│  Nenhuma reunião Zoho Meeting          │
│  vinculada a este espaço.              │
│                                         │
│     [Criar Reunião Online]             │
│                                         │
└─────────────────────────────────────────┘
```

### Com Reunião Agendada

```
┌─────────────────────────────────────────┐
│ 🎥 Reunião Zoho Meeting      [Atualizar]│
├─────────────────────────────────────────┤
│ Status: [Agendada] 🔵                   │
│                                         │
│ Início: 20/10/2025 14:00               │
│ Duração: 60 minutos                    │
│                                         │
│ Link Organizador:                      │
│ [https://meeting.zoho.com...] [📋] [🔗]│
│                                         │
│ Link Participantes:                    │
│ [https://meeting.zoho.com...] [📋]     │
│                                         │
│ Senha: teste123                        │
│ Gravação: Sim                          │
│                                         │
│ [Editar]  [Deletar]                    │
└─────────────────────────────────────────┘
```

### Com Erro

```
┌─────────────────────────────────────────┐
│ 🎥 Reunião Zoho Meeting      [Atualizar]│
├─────────────────────────────────────────┤
│ ⚠️ Erro ao buscar dados Zoho           │
│    Token expirado ou inválido          │
│                                         │
│    [×] Fechar                          │
└─────────────────────────────────────────┘
```

---

## 🔧 Configuração Adicional

### Variável de Ambiente

Certifique-se de que o `.env` tem a URL da API:

```bash
# .env ou .env.local
VITE_CCI_CA_API_URL=https://cci-ca-api.netlify.app
```

### Tipos TypeScript

Os tipos já estão definidos em `zohoMeetingApiService.ts`, mas se precisar exportar para outros componentes:

```tsx
import type { IZohoMeetingResponse, IZohoParticipantResponse, IEspacoAulaZoho } from '../services/api/zohoMeetingApiService';
```

---

## 📊 Dashboard de Participantes (Próximo)

Componente sugerido para próxima fase:

```tsx
// RelatorioParticipantesZoho.tsx
<Box>
     <Typography variant='h6'>Relatório de Participantes</Typography>
     <DataGrid
          columns={[
               { field: 'name', headerName: 'Nome', width: 200 },
               { field: 'email', headerName: 'E-mail', width: 250 },
               { field: 'duration', headerName: 'Tempo (min)', width: 120 },
               { field: 'attentiveness', headerName: 'Atenção (%)', width: 120 },
               { field: 'videoUsed', headerName: 'Câmera', width: 100 },
          ]}
          rows={participantes}
     />
     <Button onClick={exportarExcel}>Exportar Excel</Button>
</Box>
```

---

## 🚀 Próximos Passos

### Funcionalidades Adicionais Sugeridas

1. **Sincronização Automática**

     ```tsx
     // Atualizar status a cada 30 segundos durante a reunião
     useEffect(() => {
          if (espacoZoho?.zoho_meeting_status === 'started') {
               const interval = setInterval(() => {
                    buscarEspacoZoho(idEspacoAula);
               }, 30000);
               return () => clearInterval(interval);
          }
     }, [espacoZoho?.zoho_meeting_status]);
     ```

2. **Notificações Push**

     ```tsx
     // Notificar quando reunião iniciar
     if (espacoZoho?.zoho_meeting_status === 'started') {
          new Notification('Reunião Iniciada!', {
               body: `A reunião ${espacoZoho.nome} começou`,
          });
     }
     ```

3. **Integração com Calendário**
     ```tsx
     // Botão para adicionar ao Google Calendar
     const addToCalendar = () => {
          const url = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(espacoZoho.nome)}&dates=${startDate}/${endDate}`;
          window.open(url, '_blank');
     };
     ```

---

## 🎓 Exemplos de Uso Real

### Cenário 1: Professor Cria Aula Online

1. Professor acessa "Gerenciar Espaço de Aula"
2. Clica em "Criar Reunião Online"
3. Preenche dados da aula
4. Sistema cria reunião na Zoho API
5. Professor copia "Link do Organizador"
6. Compartilha "Link para Participantes" com alunos via sistema de mensagens

### Cenário 2: Aluno Entra na Aula

1. Aluno recebe notificação com link da aula
2. Clica no "Link para Participantes"
3. É redirecionado para Zoho Meeting
4. Entra com senha (se necessária)
5. Participa da aula

### Cenário 3: Admin Verifica Presença

1. Admin acessa espaço de aula
2. Clica em "Atualizar" para sincronizar
3. Vê status "Em Andamento" ou "Finalizada"
4. (Futuro) Clica em "Ver Participantes"
5. Exporta relatório de presença

---

## 📝 Checklist de Integração

### Backend

-    [x] API endpoints funcionando
-    [x] OAuth configurado
-    [x] Banco de dados sincronizado

### Frontend

-    [x] Service criado (`zohoMeetingApiService.ts`)
-    [x] Hook customizado (`useZohoMeeting.ts`)
-    [x] Componente principal (`GerenciarReuniaoZoho.tsx`)
-    [ ] Integrado em `ManterEspacoAula.tsx` (aguardando)
-    [ ] Testado em ambiente de dev

### Documentação

-    [x] README de integração (este arquivo)
-    [x] Exemplos de código
-    [x] Guia de testes

---

## 🆘 Troubleshooting

### Erro: "Token expirado ou inválido"

**Solução**: Execute no backend:

```bash
curl -X POST https://cci-ca-api.netlify.app/api/zoho/oauth/refresh
```

### Erro: "Erro ao criar reunião"

**Causa**: Credenciais OAuth inválidas **Solução**: Verificar `zoho_config` no banco de dados

### Componente não aparece

**Causa**: ID do espaço não disponível **Solução**: Garantir que `id` existe antes de renderizar:

```tsx
{
     id && <GerenciarReuniaoZoho idEspacoAula={Number(id)} />;
}
```

---

**Status**: ✅ **PRONTO PARA INTEGRAÇÃO**  
**Última Atualização**: 08 de outubro de 2025
