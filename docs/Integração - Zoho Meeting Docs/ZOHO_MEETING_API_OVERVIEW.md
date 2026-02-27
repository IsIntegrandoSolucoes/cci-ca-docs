# Zoho Meeting API - Visão Geral

## Introdução

A API do Zoho Meeting permite integrar o Zoho Meeting com aplicações e websites de terceiros. Baseada em REST API, as requisições para URIs de recursos resultarão em respostas JSON. Usando este framework programático, você pode desenvolver aplicações customizadas ou integrar o Zoho Meeting com
websites existentes.

## Características Principais

-    **API baseada em HTTP**: Pode ser integrada com uma ampla gama de clientes HTTP
-    **Respostas em JSON**: Todas as respostas são retornadas no formato JSON
-    **REST API**: Segue os princípios REST para operações em recursos
-    **OAuth 2.0**: Autenticação através do protocolo OAuth 2.0

## API Root Endpoint

```
https://meeting.zoho.com/api/v2/
```

## Estrutura Base das URLs

Cada recurso é exposto como uma URL. A URL de cada recurso pode ser obtida acessando o API Root Endpoint.

## Escopos OAuth Necessários

Dependendo da operação que você deseja realizar, diferentes escopos OAuth são necessários:

| Escopo OAuth                 | Descrição                        |
| ---------------------------- | -------------------------------- |
| `ZohoMeeting.meeting.CREATE` | Criar reuniões                   |
| `ZohoMeeting.meeting.READ`   | Ler/listar reuniões e relatórios |
| `ZohoMeeting.meeting.UPDATE` | Atualizar reuniões existentes    |
| `ZohoMeeting.meeting.DELETE` | Deletar reuniões                 |

## Endpoints Disponíveis

### Operações de Reunião (Meeting)

1. **[Criar Reunião](ZOHO_MEETING_API_ENDPOINTS.md#criar-reunião)** - Criar uma nova reunião
2. **[Listar Reuniões](ZOHO_MEETING_API_ENDPOINTS.md#listar-reuniões)** - Obter lista de reuniões
3. **[Obter Reunião](ZOHO_MEETING_API_ENDPOINTS.md#obter-reunião)** - Obter detalhes de uma reunião específica
4. **[Editar Reunião](ZOHO_MEETING_API_ENDPOINTS.md#editar-reunião)** - Editar uma reunião existente
5. **[Deletar Reunião](ZOHO_MEETING_API_ENDPOINTS.md#deletar-reunião)** - Deletar uma reunião
6. **[Relatório de Participantes](ZOHO_MEETING_API_ENDPOINTS.md#relatório-de-participantes)** - Obter relatório detalhado de participantes

## Formato de Requisição

Todas as requisições devem incluir:

-    **Authorization Header**: Token OAuth 2.0
-    **Content-Type**: `application/json` (para requisições POST/PUT)

## Formato de Resposta

Todas as respostas são retornadas no formato JSON e incluem:

-    Código de status HTTP
-    Corpo da resposta com os dados solicitados ou mensagem de erro

## Tratamento de Erros

A API retorna códigos HTTP padrão para indicar sucesso ou falha:

-    `200 OK`: Requisição bem-sucedida
-    `400 Bad Request`: Requisição inválida ou parâmetros incorretos
-    `401 Unauthorized`: Falha na autenticação ou token inválido
-    `404 Not Found`: Recurso não encontrado
-    `500 Internal Server Error`: Erro no servidor

## Links Úteis

-    [Documentação Oficial](https://www.zoho.com/meeting/api-integration.html)
-    [Detalhes dos Endpoints](ZOHO_MEETING_API_ENDPOINTS.md)

## Data de Atualização

Documentação extraída em: 08 de outubro de 2025

---

© 2025, Zoho Corporation Pvt. Ltd. All Rights Reserved.
