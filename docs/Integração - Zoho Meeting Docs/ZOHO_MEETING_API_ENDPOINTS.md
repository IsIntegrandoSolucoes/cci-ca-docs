# Zoho Meeting API - Endpoints Detalhados

## Índice

1. [Criar Reunião](#criar-reunião)
2. [Listar Reuniões](#listar-reuniões)
3. [Obter Reunião](#obter-reunião)
4. [Editar Reunião](#editar-reunião)
5. [Deletar Reunião](#deletar-reunião)
6. [Relatório de Participantes](#relatório-de-participantes)

---

## Criar Reunião

Permite criar uma reunião fornecendo os detalhes (título, data, hora e duração) no formulário de agendamento.

### Informações do Endpoint

-    **URL**: `https://meeting.zoho.com/api/v2/{zsoid}/sessions.json`
-    **Método**: `POST`
-    **OAuth Scope**: `ZohoMeeting.meeting.CREATE`

### Parâmetros

#### session (Objeto - Opcional)

Objeto contendo os detalhes da sessão/reunião a ser criada.

**Atributos do objeto session:**

| Campo        | Tipo    | Obrigatório | Descrição                                |
| ------------ | ------- | ----------- | ---------------------------------------- |
| topic        | string  | Sim         | Título/tópico da reunião                 |
| agenda       | string  | Não         | Agenda/descrição da reunião              |
| presenter    | string  | Sim         | Email do apresentador                    |
| start_time   | string  | Sim         | Data e hora de início (formato ISO 8601) |
| duration     | integer | Sim         | Duração em minutos                       |
| timezone     | string  | Sim         | Fuso horário (ex: "America/Sao_Paulo")   |
| participants | array   | Não         | Lista de emails dos participantes        |

### Exemplo de Requisição

```http
POST https://meeting.zoho.com/api/v2/{zsoid}/sessions.json
Authorization: Zoho-oauthtoken {access_token}
Content-Type: application/json
```

```json
{
     "session": {
          "topic": "Reunião de Planejamento",
          "agenda": "Discutir o planejamento do próximo trimestre",
          "presenter": "apresentador@empresa.com",
          "start_time": "2025-10-15T14:00:00-03:00",
          "duration": 60,
          "timezone": "America/Sao_Paulo",
          "participants": ["participante1@empresa.com", "participante2@empresa.com"]
     }
}
```

### Exemplo de Resposta

```json
{
     "session": {
          "sessionKey": "1234567890",
          "topic": "Reunião de Planejamento",
          "agenda": "Discutir o planejamento do próximo trimestre",
          "start_time": "2025-10-15T14:00:00-03:00",
          "duration": 60,
          "timezone": "America/Sao_Paulo",
          "meetingUrl": "https://meeting.zoho.com/meeting/presenter.do?key=1234567890",
          "joinUrl": "https://meeting.zoho.com/meeting/participant.do?key=1234567890"
     }
}
```

---

## Listar Reuniões

Permite obter a lista de reuniões baseada em critérios de filtro.

### Informações do Endpoint

-    **URL**: `https://meeting.zoho.com/api/v2/{zsoid}/sessions.json`
-    **Método**: `GET`
-    **OAuth Scope**: `ZohoMeeting.meeting.READ`

### Parâmetros

| Parâmetro | Tipo    | Obrigatório | Descrição                                         |
| --------- | ------- | ----------- | ------------------------------------------------- |
| listtype  | string  | Sim         | Tipo de lista: `all`, `past`, `today`, `upcoming` |
| index     | integer | Sim         | Índice do registro inicial (paginação)            |
| count     | integer | Sim         | Quantidade de registros a retornar                |

### Exemplo de Requisição

```http
GET https://meeting.zoho.com/api/v2/{zsoid}/sessions.json?listtype=upcoming&index=0&count=10
Authorization: Zoho-oauthtoken {access_token}
```

### Exemplo de Resposta

```json
{
     "sessions": [
          {
               "sessionKey": "1234567890",
               "topic": "Reunião de Planejamento",
               "start_time": "2025-10-15T14:00:00-03:00",
               "duration": 60,
               "status": "scheduled"
          },
          {
               "sessionKey": "0987654321",
               "topic": "Review Semanal",
               "start_time": "2025-10-16T10:00:00-03:00",
               "duration": 30,
               "status": "scheduled"
          }
     ],
     "totalRecords": 25,
     "index": 0,
     "count": 10
}
```

---

## Obter Reunião

Permite obter os detalhes de uma reunião específica.

### Informações do Endpoint

-    **URL**: `https://meeting.zoho.com/api/v2/{zsoid}/sessions/{sessionKey}.json`
-    **Método**: `GET`
-    **OAuth Scope**: `ZohoMeeting.meeting.READ`

### Parâmetros de URL

| Parâmetro  | Tipo   | Obrigatório | Descrição              |
| ---------- | ------ | ----------- | ---------------------- |
| sessionKey | string | Sim         | Chave única da reunião |

### Exemplo de Requisição

```http
GET https://meeting.zoho.com/api/v2/{zsoid}/sessions/1234567890.json
Authorization: Zoho-oauthtoken {access_token}
```

### Exemplo de Resposta

```json
{
     "session": {
          "sessionKey": "1234567890",
          "topic": "Reunião de Planejamento",
          "agenda": "Discutir o planejamento do próximo trimestre",
          "presenter": "apresentador@empresa.com",
          "start_time": "2025-10-15T14:00:00-03:00",
          "duration": 60,
          "timezone": "America/Sao_Paulo",
          "status": "scheduled",
          "meetingUrl": "https://meeting.zoho.com/meeting/presenter.do?key=1234567890",
          "joinUrl": "https://meeting.zoho.com/meeting/participant.do?key=1234567890",
          "participants": ["participante1@empresa.com", "participante2@empresa.com"]
     }
}
```

---

## Editar Reunião

Permite editar uma reunião existente. É possível alterar o tópico, agenda ou horário de uma reunião já agendada.

### Informações do Endpoint

-    **URL**: `https://meeting.zoho.com/api/v2/{zsoid}/sessions/{sessionKey}.json`
-    **Método**: `PUT`
-    **OAuth Scope**: `ZohoMeeting.meeting.UPDATE`

### Parâmetros de URL

| Parâmetro  | Tipo   | Obrigatório | Descrição                            |
| ---------- | ------ | ----------- | ------------------------------------ |
| sessionKey | string | Sim         | Chave única da reunião a ser editada |

### Parâmetros do Body

#### session (Objeto - Opcional)

Objeto contendo os detalhes a serem atualizados.

**Atributos do objeto session:**

| Campo        | Tipo    | Descrição                              |
| ------------ | ------- | -------------------------------------- |
| topic        | string  | Novo título/tópico da reunião          |
| agenda       | string  | Nova agenda/descrição da reunião       |
| start_time   | string  | Nova data e hora de início             |
| duration     | integer | Nova duração em minutos                |
| timezone     | string  | Novo fuso horário                      |
| participants | array   | Nova lista de emails dos participantes |

### Exemplo de Requisição

```http
PUT https://meeting.zoho.com/api/v2/{zsoid}/sessions/1234567890.json
Authorization: Zoho-oauthtoken {access_token}
Content-Type: application/json
```

```json
{
     "session": {
          "topic": "Reunião de Planejamento - Atualizado",
          "start_time": "2025-10-15T15:00:00-03:00",
          "duration": 90
     }
}
```

### Exemplo de Resposta

```json
{
     "session": {
          "sessionKey": "1234567890",
          "topic": "Reunião de Planejamento - Atualizado",
          "start_time": "2025-10-15T15:00:00-03:00",
          "duration": 90,
          "status": "updated"
     }
}
```

---

## Deletar Reunião

Permite deletar uma reunião. Uma vez deletada, a reunião não estará mais disponível para ser realizada.

### Informações do Endpoint

-    **URL**: `https://meeting.zoho.com/api/v2/{zsoid}/sessions/{sessionKey}.json`
-    **Método**: `DELETE`
-    **OAuth Scope**: `ZohoMeeting.meeting.DELETE`

### Parâmetros de URL

| Parâmetro  | Tipo   | Obrigatório | Descrição                             |
| ---------- | ------ | ----------- | ------------------------------------- |
| sessionKey | string | Sim         | Chave única da reunião a ser deletada |

### Exemplo de Requisição

```http
DELETE https://meeting.zoho.com/api/v2/{zsoid}/sessions/1234567890.json
Authorization: Zoho-oauthtoken {access_token}
```

### Exemplo de Resposta

```json
{
     "status": "success",
     "message": "Meeting deleted successfully"
}
```

---

## Relatório de Participantes

Permite obter relatório detalhado de participantes de uma reunião.

### Informações do Endpoint

-    **URL**: `https://meeting.zoho.com/api/v2/{zsoid}/participant/{meetingKey}.json`
-    **Método**: `GET`
-    **OAuth Scope**: `ZohoMeeting.meeting.READ`

### Parâmetros

| Parâmetro  | Tipo    | Obrigatório | Descrição                       |
| ---------- | ------- | ----------- | ------------------------------- |
| meetingKey | string  | Sim         | Chave da reunião (na URL)       |
| index      | integer | Sim         | Número da página                |
| count      | integer | Sim         | Número de relatórios por página |

### Exemplo de Requisição

```http
GET https://meeting.zoho.com/api/v2/{zsoid}/participant/1234567890.json?index=0&count=10
Authorization: Zoho-oauthtoken {access_token}
```

### Exemplo de Resposta

```json
{
     "participants": [
          {
               "name": "João Silva",
               "email": "joao@empresa.com",
               "joinTime": "2025-10-15T14:05:00-03:00",
               "leaveTime": "2025-10-15T15:00:00-03:00",
               "duration": 55,
               "role": "participant"
          },
          {
               "name": "Maria Santos",
               "email": "maria@empresa.com",
               "joinTime": "2025-10-15T14:00:00-03:00",
               "leaveTime": "2025-10-15T15:00:00-03:00",
               "duration": 60,
               "role": "presenter"
          }
     ],
     "totalParticipants": 15,
     "index": 0,
     "count": 10
}
```

### Possíveis Casos de Erro

#### 1. Token Inválido ou DC Inválido

-    **HTTP Code**: 400
-    **Mensagem**: "Invalid DC or Invalid token"
-    **Resolução**: Verifique se o DC (Data Center) está correto e se o token não expirou

#### 2. Chave de Reunião Inválida

-    **HTTP Code**: 400
-    **Mensagem**: "Invalid meeting key"
-    **Resolução**: Certifique-se de fornecer um ID de reunião válido

#### 3. ID de Organização Inválido

-    **HTTP Code**: 401
-    **Mensagem**: "Invalid organization Id"
-    **Resolução**: Certifique-se de fornecer um ID de organização válido

---

## Notas Importantes

1. **Formato de Data/Hora**: Utilize o formato ISO 8601 para todas as datas e horas
2. **Timezone**: Sempre especifique o timezone correto para evitar problemas de agendamento
3. **Paginação**: Utilize os parâmetros `index` e `count` para paginar resultados grandes
4. **Rate Limiting**: Consulte a documentação oficial para limites de taxa de requisições

## Data de Atualização

Documentação extraída em: 08 de outubro de 2025

---

© 2025, Zoho Corporation Pvt. Ltd. All Rights Reserved.
