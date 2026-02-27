# 🔑 Credenciais Zoho Meeting - Guia Completo

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Como Obter as Credenciais](#como-obter-as-credenciais)
3. [Configuração no Banco de Dados](#configuração-no-banco-de-dados)
4. [Variáveis de Ambiente](#variáveis-de-ambiente)
5. [Fluxo OAuth Completo](#fluxo-oauth-completo)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Para a integração Zoho Meeting funcionar, você precisa de **4 credenciais principais**:

| Credencial      | Onde Obter          | Onde Usar                       |
| --------------- | ------------------- | ------------------------------- |
| `client_id`     | Zoho API Console    | Tabela `zoho_config`            |
| `client_secret` | Zoho API Console    | Tabela `zoho_config`            |
| `redirect_uri`  | Você define         | Tabela `zoho_config` + App Zoho |
| `refresh_token` | Fluxo OAuth inicial | Tabela `zoho_config`            |

**Tempo estimado de configuração**: 15-30 minutos

---

## 🏗️ Como Obter as Credenciais

### Passo 1: Criar Aplicação no Zoho API Console

1. **Acesse**: [https://api-console.zoho.com/](https://api-console.zoho.com/)

2. **Login**: Use sua conta Zoho (ou crie uma)

3. **Clique**: "Add Client" (Adicionar Cliente)

4. **Escolha**: "Server-based Applications"

5. **Preencha o formulário**:

     ```
     Client Name:        CCI-CA Meeting Integration
     Homepage URL:       https://admin.cci-ca.com.br
     Authorized Redirect URIs:
                         https://admin.cci-ca.com.br/zoho/callback
                         http://localhost:3000/zoho/callback  (para dev)
     ```

6. **Clique**: "Create"

7. **Copie as credenciais exibidas**:
     - ✅ **Client ID** (exemplo: `1000.XXXXXXXXXXXXXXXXX`)
     - ✅ **Client Secret** (exemplo: `abcd1234efgh5678ijkl9012mnop3456qrst7890`)

---

### Passo 2: Definir Redirect URI

A `redirect_uri` é a URL para onde o Zoho redireciona após autenticação.

**Produção**:

```
https://admin.cci-ca.com.br/zoho/callback
```

**Desenvolvimento**:

```
http://localhost:3000/zoho/callback
```

⚠️ **IMPORTANTE**: Essa URL deve estar **exatamente igual** no Zoho Console e no banco `zoho_config`.

---

### Passo 3: Obter Refresh Token (Fluxo OAuth Inicial)

O `refresh_token` é obtido através de um fluxo OAuth 2.0 que você faz **uma única vez**.

#### Opção A: Via Browser (Manual)

1. **Monte a URL de autorização**:

```
https://accounts.zoho.com/oauth/v2/auth?
    scope=ZohoMeeting.meeting.ALL
    &client_id=SEU_CLIENT_ID
    &response_type=code
    &access_type=offline
    &redirect_uri=SUA_REDIRECT_URI
```

**Exemplo real**:

```
https://accounts.zoho.com/oauth/v2/auth?scope=ZohoMeeting.meeting.ALL&client_id=1000.XXXXXXXXX&response_type=code&access_type=offline&redirect_uri=https://admin.cci-ca.com.br/zoho/callback
```

2. **Abra no browser**: Cole a URL completa

3. **Autorize**: Login na conta Zoho → Permitir acesso

4. **Copie o código**: Você será redirecionado para:

```
https://admin.cci-ca.com.br/zoho/callback?code=1000.abcd1234...
```

5. **Troque o código por tokens**:

```bash
curl -X POST "https://accounts.zoho.com/oauth/v2/token" \
  -d "code=1000.abcd1234..." \
  -d "client_id=SEU_CLIENT_ID" \
  -d "client_secret=SEU_CLIENT_SECRET" \
  -d "redirect_uri=SUA_REDIRECT_URI" \
  -d "grant_type=authorization_code"
```

6. **Resposta** (salve o `refresh_token`):

```json
{
     "access_token": "1000.xyz...",
     "refresh_token": "1000.abc...",
     "expires_in": 3600,
     "token_type": "Bearer"
}
```

#### Opção B: Via Script Node.js (Recomendado)

Crie um script `generate-zoho-token.js`:

```javascript
const axios = require('axios');
const readline = require('readline');

const CLIENT_ID = 'SEU_CLIENT_ID';
const CLIENT_SECRET = 'SEU_CLIENT_SECRET';
const REDIRECT_URI = 'SUA_REDIRECT_URI';
const SCOPE = 'ZohoMeeting.meeting.ALL';

// Passo 1: Exibir URL de autorização
const authUrl = `https://accounts.zoho.com/oauth/v2/auth?scope=${SCOPE}&client_id=${CLIENT_ID}&response_type=code&access_type=offline&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;

console.log('\n🔗 1. Abra esta URL no navegador:\n');
console.log(authUrl);
console.log('\n2. Autorize a aplicação');
console.log('3. Copie o código da URL de redirecionamento\n');

// Passo 2: Ler código do usuário
const rl = readline.createInterface({
     input: process.stdin,
     output: process.stdout,
});

rl.question('Cole o código aqui: ', async (code) => {
     try {
          // Passo 3: Trocar código por tokens
          const response = await axios.post('https://accounts.zoho.com/oauth/v2/token', null, {
               params: {
                    code: code.trim(),
                    client_id: CLIENT_ID,
                    client_secret: CLIENT_SECRET,
                    redirect_uri: REDIRECT_URI,
                    grant_type: 'authorization_code',
               },
          });

          console.log('\n✅ Tokens gerados com sucesso!\n');
          console.log('📝 Salve estas informações:\n');
          console.log('ACCESS_TOKEN:', response.data.access_token);
          console.log('REFRESH_TOKEN:', response.data.refresh_token);
          console.log('EXPIRES_IN:', response.data.expires_in, 'segundos');

          // Calcular data de expiração
          const expiryDate = new Date(Date.now() + response.data.expires_in * 1000);
          console.log('TOKEN_EXPIRACAO:', expiryDate.toISOString());
     } catch (error) {
          console.error('❌ Erro ao obter tokens:', error.response?.data || error.message);
     } finally {
          rl.close();
     }
});
```

**Execute**:

```bash
node generate-zoho-token.js
```

---

## 💾 Configuração no Banco de Dados

### Tabela: `zoho_config`

Estrutura (criada pela migration 001):

```sql
CREATE TABLE zoho_config (
    id SERIAL PRIMARY KEY,
    client_id VARCHAR(255) NOT NULL,
    client_secret VARCHAR(255) NOT NULL,
    redirect_uri VARCHAR(512) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    token_expiracao TIMESTAMPTZ,
    data_center VARCHAR(10) DEFAULT 'com',
    ativo BOOLEAN DEFAULT true,
    ambiente VARCHAR(20) DEFAULT 'producao',
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);
```

### Inserir Credenciais (Produção)

```sql
INSERT INTO zoho_config (
    client_id,
    client_secret,
    redirect_uri,
    access_token,
    refresh_token,
    token_expiracao,
    data_center,
    ativo,
    ambiente
) VALUES (
    '1000.XXXXXXXXXXXXXXXXX',           -- Client ID do Zoho Console
    'abcd1234efgh5678ijkl9012mnop3456', -- Client Secret do Zoho Console
    'https://admin.cci-ca.com.br/zoho/callback', -- Redirect URI
    '1000.xyz...',                      -- Access Token inicial (do fluxo OAuth)
    '1000.abc...',                      -- Refresh Token (do fluxo OAuth)
    '2025-10-08 15:30:00-03:00',       -- Data de expiração do access_token
    'com',                              -- Data center (com, eu, in, com.au, jp)
    true,                               -- Ativo
    'producao'                          -- Ambiente
);
```

### Inserir Credenciais (Desenvolvimento)

```sql
INSERT INTO zoho_config (
    client_id,
    client_secret,
    redirect_uri,
    access_token,
    refresh_token,
    token_expiracao,
    data_center,
    ativo,
    ambiente
) VALUES (
    '1000.DEVXXXXXXXXXX',
    'dev_secret_1234',
    'http://localhost:3000/zoho/callback',
    '1000.dev_access...',
    '1000.dev_refresh...',
    '2025-10-08 15:30:00-03:00',
    'com',
    true,
    'desenvolvimento'
);
```

### Query de Verificação

```sql
-- Ver configuração ativa
SELECT
    id,
    client_id,
    redirect_uri,
    data_center,
    ativo,
    ambiente,
    token_expiracao,
    atualizado_em
FROM zoho_config
WHERE ativo = true
  AND ambiente = 'producao'; -- ou 'desenvolvimento'
```

---

## 🌍 Variáveis de Ambiente

### Backend (cci-ca-api)

**NÃO precisa** de variáveis de ambiente para Zoho!  
Tudo é carregado do banco `zoho_config`.

Mas você precisa das vars do Supabase:

```env
# .env ou Netlify Environment Variables
VITE_SUPABASE_URL=https://dvkpysaaejmdpstapboj.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
NODE_ENV=production  # ou development
```

### Frontend Admin (cci-ca-admin)

```env
# .env.production
VITE_CCI_CA_API_URL_PROD=https://cci-ca-api.netlify.app
```

### Frontend Aluno (cci-ca-aluno)

```env
# .env.production
VITE_CCI_CA_API_URL_PROD=https://cci-ca-api.netlify.app
```

---

## 🔄 Fluxo OAuth Completo

### Diagrama de Sequência

```
┌──────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│  Admin   │    │  CCI-CA API  │    │   Supabase  │    │  Zoho API    │
│  (User)  │    │  (Backend)   │    │     DB      │    │              │
└────┬─────┘    └──────┬───────┘    └──────┬──────┘    └──────┬───────┘
     │                 │                    │                  │
     │ 1. Criar reunião│                    │                  │
     ├────────────────>│                    │                  │
     │                 │                    │                  │
     │                 │ 2. Carregar config │                  │
     │                 ├───────────────────>│                  │
     │                 │<───────────────────┤                  │
     │                 │   (client_id, refresh_token)          │
     │                 │                    │                  │
     │                 │ 3. Verificar token │                  │
     │                 │    expirado?       │                  │
     │                 │    ├─ SIM ─┐       │                  │
     │                 │            │       │                  │
     │                 │ 4. Refresh token   │                  │
     │                 ├───────────────────────────────────────>│
     │                 │<───────────────────────────────────────┤
     │                 │   (novo access_token)                  │
     │                 │                    │                  │
     │                 │ 5. Salvar novo token                  │
     │                 ├───────────────────>│                  │
     │                 │                    │                  │
     │                 │ 6. Criar reunião   │                  │
     │                 ├───────────────────────────────────────>│
     │                 │<───────────────────────────────────────┤
     │                 │   (meeting_key, join_url, etc)         │
     │                 │                    │                  │
     │                 │ 7. Salvar em espacos_aula             │
     │                 ├───────────────────>│                  │
     │                 │                    │                  │
     │                 │ 8. Log auditoria   │                  │
     │                 ├───────────────────>│                  │
     │                 │   (zoho_meeting_logs)                 │
     │                 │                    │                  │
     │<────────────────┤                    │                  │
     │  Reunião criada │                    │                  │
     │                 │                    │                  │
```

### Ciclo de Vida do Token

1. **Criação Inicial** (fluxo OAuth manual):

     - Usuário autoriza aplicação no browser
     - Recebe `access_token` (válido 1 hora) + `refresh_token` (válido por tempo indeterminado)
     - Salva ambos em `zoho_config`

2. **Uso Normal**:

     - Backend carrega `access_token` do banco
     - Faz requisição à API Zoho
     - Se resposta = 401 (não autorizado) → vai para passo 3

3. **Renovação Automática**:

     - Backend detecta token expirado (5min antes da expiração)
     - Usa `refresh_token` para obter novo `access_token`
     - Atualiza `zoho_config` com novo token + nova data de expiração
     - Refaz requisição original

4. **Persistência**:
     - Novo `access_token` fica válido por mais 1 hora
     - Processo se repete automaticamente
     - `refresh_token` nunca expira (a menos que você revogue manualmente)

---

## 🔍 Data Centers Zoho

O Zoho Meeting tem diferentes data centers dependendo da sua região:

| Data Center | Domínio              | Região    |
| ----------- | -------------------- | --------- |
| `com`       | accounts.zoho.com    | EUA       |
| `eu`        | accounts.zoho.eu     | Europa    |
| `in`        | accounts.zoho.in     | Índia     |
| `com.au`    | accounts.zoho.com.au | Austrália |
| `jp`        | accounts.zoho.jp     | Japão     |
| `com.cn`    | accounts.zoho.com.cn | China     |

**Para Brasil**: Use `com` (padrão)

Se sua conta Zoho foi criada em outro data center, ajuste as URLs:

**OAuth URL**:

```
https://accounts.zoho.{DATA_CENTER}/oauth/v2/auth
https://accounts.zoho.{DATA_CENTER}/oauth/v2/token
```

**API URL**:

```
https://meeting.zoho.{DATA_CENTER}/api/v2
```

---

## 🛠️ Troubleshooting

### Problema 1: "Configuração OAuth Zoho não encontrada"

**Causa**: Não há registro ativo em `zoho_config`

**Solução**:

```sql
-- Verificar se existe
SELECT * FROM zoho_config WHERE ativo = true;

-- Se vazio, inserir conforme seção "Configuração no Banco de Dados"
```

---

### Problema 2: "Token de acesso não disponível"

**Causa**: `access_token` está NULL ou vazio

**Solução**:

1. Refazer fluxo OAuth inicial
2. Atualizar registro com tokens válidos:

```sql
UPDATE zoho_config
SET
    access_token = '1000.xyz...',
    refresh_token = '1000.abc...',
    token_expiracao = NOW() + INTERVAL '1 hour'
WHERE id = 1;
```

---

### Problema 3: "invalid_client" ao fazer OAuth

**Causa**: `client_id` ou `client_secret` incorretos

**Solução**:

1. Verificar credenciais no Zoho API Console
2. Copiar novamente (sem espaços extras)
3. Atualizar banco:

```sql
UPDATE zoho_config
SET
    client_id = 'NOVO_CLIENT_ID',
    client_secret = 'NOVO_CLIENT_SECRET'
WHERE id = 1;
```

---

### Problema 4: "redirect_uri_mismatch"

**Causa**: `redirect_uri` no banco ≠ `redirect_uri` no Zoho Console

**Solução**:

1. Zoho Console → Client → Edit
2. Adicionar/verificar URI em "Authorized Redirect URIs"
3. Deve ser **exatamente igual** (incluindo http/https, porta, path)
4. Atualizar banco se necessário:

```sql
UPDATE zoho_config
SET redirect_uri = 'https://admin.cci-ca.com.br/zoho/callback'
WHERE id = 1;
```

---

### Problema 5: "invalid_code" ao trocar código por token

**Causa**: Código de autorização já foi usado ou expirou (válido por 1 minuto)

**Solução**:

1. Gerar novo código (refazer passo 1 do fluxo OAuth)
2. Trocar imediatamente (< 1 minuto)

---

### Problema 6: Token não renova automaticamente

**Causa**: `refresh_token` inválido ou expirado

**Solução**:

1. Verificar se `refresh_token` está no banco:

```sql
SELECT refresh_token FROM zoho_config WHERE id = 1;
```

2. Se NULL ou inválido, refazer fluxo OAuth completo

3. Se válido mas não funciona, revogar e criar novo:
     - Zoho Console → Client → Revoke Access
     - Refazer fluxo OAuth

---

### Problema 7: "CORS error" no frontend

**Causa**: Frontend tentando chamar API Zoho diretamente

**Solução**:

-    ❌ **NUNCA** chame API Zoho do frontend
-    ✅ Sempre use backend (cci-ca-api) como proxy
-    Endpoints: `/api/zoho/*`

---

### Problema 8: Ambiente errado carregado

**Causa**: `NODE_ENV` não configurado ou incorreto

**Solução**:

```bash
# Verificar variável
echo $NODE_ENV  # deve ser 'production' ou 'development'

# Configurar no Netlify
# Site Settings → Environment Variables → NODE_ENV=production
```

---

## ✅ Checklist de Configuração

### Passo a Passo Final

-    [ ] 1. Criar conta no Zoho (se não tiver)
-    [ ] 2. Acessar [Zoho API Console](https://api-console.zoho.com/)
-    [ ] 3. Criar "Server-based Application"
-    [ ] 4. Copiar `client_id` e `client_secret`
-    [ ] 5. Configurar `redirect_uri` no Zoho Console
-    [ ] 6. Executar fluxo OAuth inicial (browser ou script)
-    [ ] 7. Obter `access_token` e `refresh_token`
-    [ ] 8. Inserir credenciais em `zoho_config` (Supabase)
-    [ ] 9. Verificar `ativo = true` e `ambiente` correto
-    [ ] 10.  Testar criação de reunião via API
-    [ ] 11.  Verificar logs em `zoho_meeting_logs`
-    [ ] 12.  Confirmar renovação automática de token

---

## 📚 Recursos Adicionais

### Links Úteis

-    **Zoho API Console**: https://api-console.zoho.com/
-    **Zoho Meeting API Docs**: https://www.zoho.com/meeting/api/v2/
-    **OAuth 2.0 Guide**: https://www.zoho.com/accounts/protocol/oauth/web-server-applications.html
-    **Scopes**: https://www.zoho.com/meeting/api/v2/scopes.html

### Scopes Necessários

Para a integração completa, use:

```
ZohoMeeting.meeting.ALL
```

Isso inclui:

-    `ZohoMeeting.meeting.CREATE`
-    `ZohoMeeting.meeting.READ`
-    `ZohoMeeting.meeting.UPDATE`
-    `ZohoMeeting.meeting.DELETE`

### Suporte

-    **Backend**: Ver `cci-ca-api/docs/Zoho Meeting/ZOHO_MEETING_INTEGRACAO.md`
-    **Frontend**: Ver `cci-ca-admin/docs/ZOHO_MEETING_FRONTEND_INTEGRACAO.md`
-    **Documentação completa**: Ver `markdown/docs/ZOHO_MEETING_FULL_STACK.md`

---

**Última atualização**: 08 de outubro de 2025  
**Versão**: 1.0.0  
**Status**: ✅ Documentação completa
