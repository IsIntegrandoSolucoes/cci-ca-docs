# Zoho Meeting API - Exemplos Práticos

Este documento contém exemplos práticos de integração com a API do Zoho Meeting em diferentes cenários.

## Índice

1. [Criar e Agendar Reunião Simples](#criar-e-agendar-reunião-simples)
2. [Listar Próximas Reuniões](#listar-próximas-reuniões)
3. [Reagendar Reunião](#reagendar-reunião)
4. [Cancelar Reunião](#cancelar-reunião)
5. [Obter Relatório de Participantes](#obter-relatório-de-participantes)
6. [Integração Completa com Aplicação](#integração-completa-com-aplicação)

---

## Criar e Agendar Reunião Simples

### Cenário

Criar uma reunião para daqui a 2 dias, às 14:00, com duração de 1 hora.

### TypeScript/JavaScript

```typescript
interface Meeting {
     topic: string;
     agenda: string;
     presenter: string;
     start_time: string;
     duration: number;
     timezone: string;
     participants: string[];
}

async function createMeeting(zsoid: string, accessToken: string): Promise<any> {
     // Calcular data/hora: daqui a 2 dias às 14:00
     const startDate = new Date();
     startDate.setDate(startDate.getDate() + 2);
     startDate.setHours(14, 0, 0, 0);

     const meeting: Meeting = {
          topic: 'Reunião de Alinhamento Semanal',
          agenda: 'Revisar progresso dos projetos e definir prioridades',
          presenter: 'gerente@empresa.com',
          start_time: startDate.toISOString(),
          duration: 60,
          timezone: 'America/Sao_Paulo',
          participants: ['joao@empresa.com', 'maria@empresa.com', 'pedro@empresa.com'],
     };

     const response = await fetch(`https://meeting.zoho.com/api/v2/${zsoid}/sessions.json`, {
          method: 'POST',
          headers: {
               Authorization: `Zoho-oauthtoken ${accessToken}`,
               'Content-Type': 'application/json',
          },
          body: JSON.stringify({ session: meeting }),
     });

     if (!response.ok) {
          throw new Error(`Erro ao criar reunião: ${response.statusText}`);
     }

     const data = await response.json();
     console.log('Reunião criada com sucesso!');
     console.log('Link do apresentador:', data.session.meetingUrl);
     console.log('Link dos participantes:', data.session.joinUrl);

     return data;
}

// Uso
const zsoid = 'seu-organization-id';
const accessToken = 'seu-access-token';

createMeeting(zsoid, accessToken)
     .then((meeting) => console.log('Meeting Key:', meeting.session.sessionKey))
     .catch((error) => console.error('Erro:', error));
```

### Python

```python
import requests
from datetime import datetime, timedelta
import json

def create_meeting(zsoid: str, access_token: str) -> dict:
    # Calcular data/hora: daqui a 2 dias às 14:00
    start_date = datetime.now() + timedelta(days=2)
    start_date = start_date.replace(hour=14, minute=0, second=0, microsecond=0)

    meeting = {
        "session": {
            "topic": "Reunião de Alinhamento Semanal",
            "agenda": "Revisar progresso dos projetos e definir prioridades",
            "presenter": "gerente@empresa.com",
            "start_time": start_date.isoformat(),
            "duration": 60,
            "timezone": "America/Sao_Paulo",
            "participants": [
                "joao@empresa.com",
                "maria@empresa.com",
                "pedro@empresa.com"
            ]
        }
    }

    url = f"https://meeting.zoho.com/api/v2/{zsoid}/sessions.json"
    headers = {
        "Authorization": f"Zoho-oauthtoken {access_token}",
        "Content-Type": "application/json"
    }

    response = requests.post(url, headers=headers, json=meeting)
    response.raise_for_status()

    data = response.json()
    print("Reunião criada com sucesso!")
    print(f"Link do apresentador: {data['session']['meetingUrl']}")
    print(f"Link dos participantes: {data['session']['joinUrl']}")

    return data

# Uso
zsoid = "seu-organization-id"
access_token = "seu-access-token"

meeting = create_meeting(zsoid, access_token)
print(f"Meeting Key: {meeting['session']['sessionKey']}")
```

---

## Listar Próximas Reuniões

### Cenário

Listar todas as reuniões agendadas para o futuro (upcoming).

### TypeScript/JavaScript

```typescript
interface MeetingListParams {
     listtype: 'all' | 'past' | 'today' | 'upcoming';
     index: number;
     count: number;
}

async function listUpcomingMeetings(zsoid: string, accessToken: string): Promise<any[]> {
     const params: MeetingListParams = {
          listtype: 'upcoming',
          index: 0,
          count: 50,
     };

     const queryString = new URLSearchParams(params as any).toString();
     const url = `https://meeting.zoho.com/api/v2/${zsoid}/sessions.json?${queryString}`;

     const response = await fetch(url, {
          method: 'GET',
          headers: {
               Authorization: `Zoho-oauthtoken ${accessToken}`,
          },
     });

     if (!response.ok) {
          throw new Error(`Erro ao listar reuniões: ${response.statusText}`);
     }

     const data = await response.json();

     console.log(`Total de reuniões futuras: ${data.totalRecords}`);

     data.sessions.forEach((session: any, index: number) => {
          console.log(`\n${index + 1}. ${session.topic}`);
          console.log(`   Data/Hora: ${new Date(session.start_time).toLocaleString('pt-BR')}`);
          console.log(`   Duração: ${session.duration} minutos`);
          console.log(`   Status: ${session.status}`);
     });

     return data.sessions;
}

// Uso
listUpcomingMeetings(zsoid, accessToken)
     .then((meetings) => console.log(`\nTotal encontrado: ${meetings.length}`))
     .catch((error) => console.error('Erro:', error));
```

### Python

```python
from typing import List, Dict

def list_upcoming_meetings(zsoid: str, access_token: str) -> List[Dict]:
    params = {
        "listtype": "upcoming",
        "index": 0,
        "count": 50
    }

    url = f"https://meeting.zoho.com/api/v2/{zsoid}/sessions.json"
    headers = {
        "Authorization": f"Zoho-oauthtoken {access_token}"
    }

    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()

    data = response.json()

    print(f"Total de reuniões futuras: {data['totalRecords']}")

    for index, session in enumerate(data['sessions'], 1):
        print(f"\n{index}. {session['topic']}")
        print(f"   Data/Hora: {session['start_time']}")
        print(f"   Duração: {session['duration']} minutos")
        print(f"   Status: {session['status']}")

    return data['sessions']

# Uso
meetings = list_upcoming_meetings(zsoid, access_token)
print(f"\nTotal encontrado: {len(meetings)}")
```

---

## Reagendar Reunião

### Cenário

Alterar a data/hora de uma reunião existente e aumentar a duração.

### TypeScript/JavaScript

```typescript
async function rescheduleMeeting(zsoid: string, sessionKey: string, accessToken: string, newStartTime: Date, newDuration: number): Promise<any> {
     const updates = {
          session: {
               start_time: newStartTime.toISOString(),
               duration: newDuration,
          },
     };

     const url = `https://meeting.zoho.com/api/v2/${zsoid}/sessions/${sessionKey}.json`;

     const response = await fetch(url, {
          method: 'PUT',
          headers: {
               Authorization: `Zoho-oauthtoken ${accessToken}`,
               'Content-Type': 'application/json',
          },
          body: JSON.stringify(updates),
     });

     if (!response.ok) {
          throw new Error(`Erro ao reagendar reunião: ${response.statusText}`);
     }

     const data = await response.json();
     console.log('Reunião reagendada com sucesso!');
     console.log('Nova data/hora:', new Date(data.session.start_time).toLocaleString('pt-BR'));
     console.log('Nova duração:', data.session.duration, 'minutos');

     return data;
}

// Uso
const sessionKey = '1234567890';
const newDate = new Date();
newDate.setDate(newDate.getDate() + 3); // Mover para daqui a 3 dias
newDate.setHours(15, 30, 0, 0); // Às 15:30

rescheduleMeeting(zsoid, sessionKey, accessToken, newDate, 90).catch((error) => console.error('Erro:', error));
```

### Python

```python
from datetime import datetime

def reschedule_meeting(
    zsoid: str,
    session_key: str,
    access_token: str,
    new_start_time: datetime,
    new_duration: int
) -> dict:
    updates = {
        "session": {
            "start_time": new_start_time.isoformat(),
            "duration": new_duration
        }
    }

    url = f"https://meeting.zoho.com/api/v2/{zsoid}/sessions/{session_key}.json"
    headers = {
        "Authorization": f"Zoho-oauthtoken {access_token}",
        "Content-Type": "application/json"
    }

    response = requests.put(url, headers=headers, json=updates)
    response.raise_for_status()

    data = response.json()
    print("Reunião reagendada com sucesso!")
    print(f"Nova data/hora: {data['session']['start_time']}")
    print(f"Nova duração: {data['session']['duration']} minutos")

    return data

# Uso
session_key = "1234567890"
new_date = datetime.now() + timedelta(days=3)
new_date = new_date.replace(hour=15, minute=30, second=0, microsecond=0)

reschedule_meeting(zsoid, session_key, access_token, new_date, 90)
```

---

## Cancelar Reunião

### Cenário

Deletar uma reunião que não será mais necessária.

### TypeScript/JavaScript

```typescript
async function cancelMeeting(zsoid: string, sessionKey: string, accessToken: string): Promise<void> {
     const url = `https://meeting.zoho.com/api/v2/${zsoid}/sessions/${sessionKey}.json`;

     const response = await fetch(url, {
          method: 'DELETE',
          headers: {
               Authorization: `Zoho-oauthtoken ${accessToken}`,
          },
     });

     if (!response.ok) {
          throw new Error(`Erro ao cancelar reunião: ${response.statusText}`);
     }

     console.log('Reunião cancelada com sucesso!');
}

// Uso com confirmação
async function cancelMeetingWithConfirmation(zsoid: string, sessionKey: string, accessToken: string): Promise<void> {
     // Primeiro, buscar detalhes da reunião
     const meetingUrl = `https://meeting.zoho.com/api/v2/${zsoid}/sessions/${sessionKey}.json`;
     const getResponse = await fetch(meetingUrl, {
          headers: { Authorization: `Zoho-oauthtoken ${accessToken}` },
     });

     if (!getResponse.ok) {
          throw new Error('Reunião não encontrada');
     }

     const meeting = await getResponse.json();

     console.log('Confirmando cancelamento da reunião:');
     console.log(`Tópico: ${meeting.session.topic}`);
     console.log(`Data/Hora: ${new Date(meeting.session.start_time).toLocaleString('pt-BR')}`);

     // Aqui você pode adicionar lógica de confirmação do usuário
     // Por exemplo, usando readline no Node.js ou prompt no browser

     await cancelMeeting(zsoid, sessionKey, accessToken);
}

// Uso
cancelMeetingWithConfirmation(zsoid, sessionKey, accessToken).catch((error) => console.error('Erro:', error));
```

---

## Obter Relatório de Participantes

### Cenário

Após uma reunião, obter relatório detalhado de quem participou, por quanto tempo, etc.

### TypeScript/JavaScript

```typescript
interface Participant {
     name: string;
     email: string;
     joinTime: string;
     leaveTime: string;
     duration: number;
     role: string;
}

async function getParticipantReport(zsoid: string, meetingKey: string, accessToken: string): Promise<Participant[]> {
     const allParticipants: Participant[] = [];
     let index = 0;
     const count = 50;
     let hasMore = true;

     // Paginar através de todos os participantes
     while (hasMore) {
          const params = new URLSearchParams({
               index: index.toString(),
               count: count.toString(),
          });

          const url = `https://meeting.zoho.com/api/v2/${zsoid}/participant/${meetingKey}.json?${params}`;

          const response = await fetch(url, {
               method: 'GET',
               headers: {
                    Authorization: `Zoho-oauthtoken ${accessToken}`,
               },
          });

          if (!response.ok) {
               throw new Error(`Erro ao obter relatório: ${response.statusText}`);
          }

          const data = await response.json();
          allParticipants.push(...data.participants);

          hasMore = index + count < data.totalParticipants;
          index += count;
     }

     // Exibir relatório formatado
     console.log(`\n=== Relatório de Participantes ===`);
     console.log(`Total de participantes: ${allParticipants.length}\n`);

     allParticipants.forEach((participant, idx) => {
          console.log(`${idx + 1}. ${participant.name} (${participant.email})`);
          console.log(`   Papel: ${participant.role}`);
          console.log(`   Entrada: ${new Date(participant.joinTime).toLocaleTimeString('pt-BR')}`);
          console.log(`   Saída: ${new Date(participant.leaveTime).toLocaleTimeString('pt-BR')}`);
          console.log(`   Tempo na reunião: ${participant.duration} minutos\n`);
     });

     // Calcular estatísticas
     const avgDuration = allParticipants.reduce((sum, p) => sum + p.duration, 0) / allParticipants.length;
     console.log(`Tempo médio de participação: ${avgDuration.toFixed(2)} minutos`);

     return allParticipants;
}

// Uso
getParticipantReport(zsoid, meetingKey, accessToken).catch((error) => console.error('Erro:', error));
```

---

## Integração Completa com Aplicação

### Cenário

Classe completa para gerenciar reuniões em uma aplicação.

### TypeScript

```typescript
class ZohoMeetingClient {
     private zsoid: string;
     private accessToken: string;
     private baseUrl: string;

     constructor(zsoid: string, accessToken: string, region: string = 'com') {
          this.zsoid = zsoid;
          this.accessToken = accessToken;
          this.baseUrl = `https://meeting.zoho.${region}/api/v2`;
     }

     private async request(endpoint: string, method: string = 'GET', body?: any): Promise<any> {
          const options: RequestInit = {
               method,
               headers: {
                    Authorization: `Zoho-oauthtoken ${this.accessToken}`,
                    'Content-Type': 'application/json',
               },
          };

          if (body) {
               options.body = JSON.stringify(body);
          }

          const response = await fetch(`${this.baseUrl}/${this.zsoid}${endpoint}`, options);

          if (!response.ok) {
               const error = await response.json().catch(() => ({}));
               throw new Error(`API Error: ${response.status} - ${JSON.stringify(error)}`);
          }

          return await response.json();
     }

     async createMeeting(meeting: Partial<Meeting>): Promise<any> {
          return await this.request('/sessions.json', 'POST', { session: meeting });
     }

     async listMeetings(listtype: 'all' | 'past' | 'today' | 'upcoming' = 'upcoming', index: number = 0, count: number = 50): Promise<any> {
          const params = new URLSearchParams({ listtype, index: index.toString(), count: count.toString() });
          return await this.request(`/sessions.json?${params}`);
     }

     async getMeeting(sessionKey: string): Promise<any> {
          return await this.request(`/sessions/${sessionKey}.json`);
     }

     async updateMeeting(sessionKey: string, updates: Partial<Meeting>): Promise<any> {
          return await this.request(`/sessions/${sessionKey}.json`, 'PUT', { session: updates });
     }

     async deleteMeeting(sessionKey: string): Promise<void> {
          await this.request(`/sessions/${sessionKey}.json`, 'DELETE');
     }

     async getParticipantReport(meetingKey: string, index: number = 0, count: number = 50): Promise<any> {
          const params = new URLSearchParams({ index: index.toString(), count: count.toString() });
          return await this.request(`/participant/${meetingKey}.json?${params}`);
     }

     setAccessToken(newToken: string): void {
          this.accessToken = newToken;
     }
}

// Uso da classe
const client = new ZohoMeetingClient('seu-organization-id', 'seu-access-token');

// Criar reunião
const meeting = await client.createMeeting({
     topic: 'Reunião de Projeto',
     start_time: new Date(Date.now() + 86400000).toISOString(), // Amanhã
     duration: 60,
     timezone: 'America/Sao_Paulo',
     presenter: 'user@empresa.com',
});

// Listar reuniões futuras
const upcomingMeetings = await client.listMeetings('upcoming');

// Atualizar reunião
await client.updateMeeting(meeting.session.sessionKey, {
     duration: 90,
});

// Deletar reunião
await client.deleteMeeting(meeting.session.sessionKey);
```

---

## Tratamento de Erros Robusto

```typescript
class ZohoMeetingError extends Error {
     constructor(message: string, public statusCode?: number, public response?: any) {
          super(message);
          this.name = 'ZohoMeetingError';
     }
}

async function safeApiCall<T>(apiFunction: () => Promise<T>, retries: number = 3): Promise<T> {
     for (let attempt = 1; attempt <= retries; attempt++) {
          try {
               return await apiFunction();
          } catch (error: any) {
               if (attempt === retries) {
                    throw error;
               }

               // Retry apenas para erros temporários
               if (error.statusCode && error.statusCode >= 500) {
                    console.log(`Tentativa ${attempt} falhou. Tentando novamente...`);
                    await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
               } else {
                    throw error;
               }
          }
     }

     throw new Error('Max retries exceeded');
}

// Uso
try {
     const meeting = await safeApiCall(() =>
          client.createMeeting({
               topic: 'Reunião Importante',
               start_time: new Date().toISOString(),
               duration: 60,
          }),
     );
     console.log('Reunião criada:', meeting);
} catch (error) {
     if (error instanceof ZohoMeetingError) {
          console.error(`Erro da API Zoho (${error.statusCode}):`, error.message);
     } else {
          console.error('Erro desconhecido:', error);
     }
}
```

## Data de Atualização

Documentação criada em: 08 de outubro de 2025

---

© 2025, Zoho Corporation Pvt. Ltd. All Rights Reserved.
