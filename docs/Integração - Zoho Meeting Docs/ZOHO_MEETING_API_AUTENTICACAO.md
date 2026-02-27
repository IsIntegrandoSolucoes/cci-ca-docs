# Zoho Meeting API - Guia de Autenticação OAuth 2.0

## Visão Geral

A API do Zoho Meeting utiliza OAuth 2.0 para autenticação e autorização. Este guia detalha o processo de configuração e obtenção de tokens de acesso.

## Pré-requisitos

1. Conta no Zoho Meeting
2. Aplicação registrada no Zoho API Console
3. Client ID e Client Secret

## Fluxo OAuth 2.0

### 1. Registrar Aplicação

1. Acesse [Zoho API Console](https://api-console.zoho.com/)
2. Clique em "Add Client"
3. Selecione o tipo de cliente (Server-based, Client-based, etc.)
4. Preencha os detalhes da aplicação:
     - Client Name
     - Homepage URL
     - Authorized Redirect URIs

### 2. Obter Credenciais

Após registrar a aplicação, você receberá:

-    **Client ID**: Identificador único da sua aplicação
-    **Client Secret**: Chave secreta (mantenha segura!)

## Processo de Autorização

### Passo 1: Gerar URL de Autorização

Redirecione o usuário para a URL de autorização do Zoho:

```
https://accounts.zoho.com/oauth/v2/auth?
  scope={scopes}&
  client_id={client_id}&
  response_type=code&
  access_type=offline&
  redirect_uri={redirect_uri}
```

#### Parâmetros:

| Parâmetro     | Descrição                                         |
| ------------- | ------------------------------------------------- |
| scope         | Escopos OAuth necessários (separados por vírgula) |
| client_id     | Seu Client ID                                     |
| response_type | Sempre "code" para authorization code grant       |
| access_type   | "offline" para obter refresh token                |
| redirect_uri  | URL de callback registrada                        |

#### Exemplo de URL:

```
https://accounts.zoho.com/oauth/v2/auth?
  scope=ZohoMeeting.meeting.CREATE,ZohoMeeting.meeting.READ,ZohoMeeting.meeting.UPDATE,ZohoMeeting.meeting.DELETE&
  client_id=1000.XXXXXXXXXX&
  response_type=code&
  access_type=offline&
  redirect_uri=https://sua-aplicacao.com/callback
```

### Passo 2: Usuário Autoriza Aplicação

O usuário será redirecionado para a página de login do Zoho e solicitado a autorizar sua aplicação.

### Passo 3: Receber Authorization Code

Após autorização, o usuário é redirecionado de volta para sua `redirect_uri` com um código:

```
https://sua-aplicacao.com/callback?code=1000.xxxxxxxxxxxxx&location=us&accounts-server=https://accounts.zoho.com
```

### Passo 4: Trocar Code por Access Token

Faça uma requisição POST para obter o access token:

```http
POST https://accounts.zoho.com/oauth/v2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
client_id={client_id}&
client_secret={client_secret}&
redirect_uri={redirect_uri}&
code={authorization_code}
```

#### Exemplo com cURL:

```bash
curl -X POST https://accounts.zoho.com/oauth/v2/token \
  -d "grant_type=authorization_code" \
  -d "client_id=1000.XXXXXXXXXX" \
  -d "client_secret=xxxxxxxxxxxxxxxxxx" \
  -d "redirect_uri=https://sua-aplicacao.com/callback" \
  -d "code=1000.xxxxxxxxxxxxx"
```

#### Resposta:

```json
{
     "access_token": "1000.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
     "refresh_token": "1000.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy",
     "token_type": "Bearer",
     "expires_in": 3600
}
```

## Utilizar Access Token

Inclua o access token no header de todas as requisições à API:

```http
GET https://meeting.zoho.com/api/v2/{zsoid}/sessions.json
Authorization: Zoho-oauthtoken 1000.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Refresh Token

### Quando Usar

-    Access tokens expiram após 1 hora (3600 segundos)
-    Use o refresh token para obter um novo access token sem re-autenticação do usuário

### Como Renovar

```http
POST https://accounts.zoho.com/oauth/v2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&
client_id={client_id}&
client_secret={client_secret}&
refresh_token={refresh_token}
```

#### Exemplo com cURL:

```bash
curl -X POST https://accounts.zoho.com/oauth/v2/token \
  -d "grant_type=refresh_token" \
  -d "client_id=1000.XXXXXXXXXX" \
  -d "client_secret=xxxxxxxxxxxxxxxxxx" \
  -d "refresh_token=1000.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
```

#### Resposta:

```json
{
     "access_token": "1000.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
     "token_type": "Bearer",
     "expires_in": 3600
}
```

## Escopos OAuth

| Escopo                       | Permissão                        |
| ---------------------------- | -------------------------------- |
| `ZohoMeeting.meeting.CREATE` | Criar reuniões                   |
| `ZohoMeeting.meeting.READ`   | Ler/listar reuniões e relatórios |
| `ZohoMeeting.meeting.UPDATE` | Atualizar reuniões existentes    |
| `ZohoMeeting.meeting.DELETE` | Deletar reuniões                 |
| `ZohoMeeting.meeting.ALL`    | Todas as permissões acima        |

## Exemplo de Implementação (TypeScript/JavaScript)

### Configuração

```typescript
interface ZohoConfig {
     clientId: string;
     clientSecret: string;
     redirectUri: string;
     scope: string;
}

const config: ZohoConfig = {
     clientId: '1000.XXXXXXXXXX',
     clientSecret: 'xxxxxxxxxxxxxxxxxx',
     redirectUri: 'https://sua-aplicacao.com/callback',
     scope: 'ZohoMeeting.meeting.ALL',
};
```

### Gerar URL de Autorização

```typescript
function getAuthorizationUrl(config: ZohoConfig): string {
     const params = new URLSearchParams({
          scope: config.scope,
          client_id: config.clientId,
          response_type: 'code',
          access_type: 'offline',
          redirect_uri: config.redirectUri,
     });

     return `https://accounts.zoho.com/oauth/v2/auth?${params.toString()}`;
}
```

### Trocar Code por Token

```typescript
async function exchangeCodeForToken(config: ZohoConfig, code: string): Promise<TokenResponse> {
     const params = new URLSearchParams({
          grant_type: 'authorization_code',
          client_id: config.clientId,
          client_secret: config.clientSecret,
          redirect_uri: config.redirectUri,
          code: code,
     });

     const response = await fetch('https://accounts.zoho.com/oauth/v2/token', {
          method: 'POST',
          headers: {
               'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: params.toString(),
     });

     return await response.json();
}
```

### Renovar Access Token

```typescript
async function refreshAccessToken(config: ZohoConfig, refreshToken: string): Promise<TokenResponse> {
     const params = new URLSearchParams({
          grant_type: 'refresh_token',
          client_id: config.clientId,
          client_secret: config.clientSecret,
          refresh_token: refreshToken,
     });

     const response = await fetch('https://accounts.zoho.com/oauth/v2/token', {
          method: 'POST',
          headers: {
               'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: params.toString(),
     });

     return await response.json();
}
```

### Fazer Requisições Autenticadas

```typescript
async function makeAuthenticatedRequest(endpoint: string, accessToken: string, method: string = 'GET', body?: any): Promise<any> {
     const options: RequestInit = {
          method,
          headers: {
               Authorization: `Zoho-oauthtoken ${accessToken}`,
               'Content-Type': 'application/json',
          },
     };

     if (body) {
          options.body = JSON.stringify(body);
     }

     const response = await fetch(endpoint, options);
     return await response.json();
}
```

## Data Centers

O Zoho opera em múltiplos data centers. Certifique-se de usar o correto:

| Região | Authorization URL    | Token URL            | API URL             |
| ------ | -------------------- | -------------------- | ------------------- |
| US     | accounts.zoho.com    | accounts.zoho.com    | meeting.zoho.com    |
| EU     | accounts.zoho.eu     | accounts.zoho.eu     | meeting.zoho.eu     |
| IN     | accounts.zoho.in     | accounts.zoho.in     | meeting.zoho.in     |
| AU     | accounts.zoho.com.au | accounts.zoho.com.au | meeting.zoho.com.au |
| CN     | accounts.zoho.com.cn | accounts.zoho.com.cn | meeting.zoho.com.cn |

## Boas Práticas

1. **Segurança**:

     - Nunca exponha Client Secret no frontend
     - Armazene tokens de forma segura
     - Use HTTPS para todas as comunicações

2. **Gerenciamento de Tokens**:

     - Implemente lógica de renovação automática antes da expiração
     - Armazene refresh token de forma segura e persistente
     - Trate erros de token expirado adequadamente

3. **Tratamento de Erros**:

     - Implemente retry logic para falhas temporárias
     - Trate diferentes códigos de erro apropriadamente
     - Registre falhas de autenticação para debugging

4. **Performance**:
     - Cache access tokens enquanto válidos
     - Minimize requisições de renovação
     - Use connection pooling quando possível

## Possíveis Erros

### Invalid Client

```json
{
     "error": "invalid_client"
}
```

**Causa**: Client ID ou Client Secret inválidos  
**Solução**: Verifique as credenciais no Zoho API Console

### Invalid Grant

```json
{
     "error": "invalid_grant"
}
```

**Causa**: Authorization code expirado ou já utilizado  
**Solução**: Gere um novo authorization code

### Invalid Token

```json
{
     "error": "invalid_token"
}
```

**Causa**: Access token expirado ou inválido  
**Solução**: Renove o token usando refresh token

## Recursos Adicionais

-    [Zoho OAuth 2.0 Documentation](https://www.zoho.com/accounts/protocol/oauth.html)
-    [Zoho API Console](https://api-console.zoho.com/)
-    [Zoho Meeting API Overview](ZOHO_MEETING_API_OVERVIEW.md)

## Data de Atualização

Documentação criada em: 08 de outubro de 2025

---

© 2025, Zoho Corporation Pvt. Ltd. All Rights Reserved.
