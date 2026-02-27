# 📧 Guia de Configuração de Email - Supabase CCI-CA

## 📋 Sumário

1. [Visão Geral](#visão-geral)
2. [Configuração do SMTP](#configuração-do-smtp)
3. [Templates de Email Customizados](#templates-de-email-customizados)
4. [URLs de Redirecionamento](#urls-de-redirecionamento)
5. [Testando as Configurações](#testando-as-configurações)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

O CCI-CA utiliza templates de email personalizados em PT-BR com a identidade visual institucional para todas as comunicações de autenticação via Supabase.

### Templates Implementados:

-    ✅ **Confirmação de Cadastro** (`confirmar-cadastro.html`)
-    ✅ **Redefinição de Senha** (`resetar-senha.html`)
-    ✅ **Link Mágico** (`link-magico.html`)
-    ✅ **Mudança de Email** (`mudar-email.html`)
-    ✅ **Reautenticação** (`reautenticacao.html`)
-    ✅ **Convite de Usuário** (`convidar-usuario.html`)

---

## 🔧 Configuração do SMTP

### 1. Acessar Dashboard do Supabase

1. Acesse [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecione o projeto: `dvkpysaaejmdpstapboj`
3. Vá para **Settings** → **Authentication**

### 2. Configurar SMTP Customizado

No menu lateral, clique em **SMTP Settings**:

```
SMTP Host: smtp.seuservidor.com
SMTP Port: 587 (TLS) ou 465 (SSL)
SMTP Username: noreply@cci-ca.com.br
SMTP Password: [sua senha SMTP]
Sender Email: noreply@cci-ca.com.br
Sender Name: Consultório de Aprendizagem CCI-CA
```

**Importante:**

-    ✅ Use TLS (porta 587) para melhor compatibilidade
-    ✅ Configure SPF, DKIM e DMARC no seu domínio
-    ✅ Teste o SMTP com o botão "Send test email"

---

## 🎨 Templates de Email Customizados

### 1. Acessar Editor de Templates

**Settings** → **Authentication** → **Email Templates**

### 2. Configurar Cada Template

#### 📝 Template: Confirm Signup (Confirmação de Cadastro)

**Subject:**

```
Confirme seu cadastro - CCI-CA
```

**Body (HTML):** Copie o conteúdo completo de:

```
cci-ca-docs/docs/Módulo Alunos - Auth/Configuração Email SMTP/confirmar-cadastro.html
```

---

#### 🔐 Template: Reset Password (Redefinir Senha)

**Subject:**

```
Redefinir sua senha - CCI-CA
```

**Body (HTML):** Copie o conteúdo de:

```
resetar-senha.html
```

---

#### ✨ Template: Magic Link (Link Mágico)

**Subject:**

```
Seu link de acesso - CCI-CA
```

**Body (HTML):** Copie o conteúdo de:

```
link-magico.html
```

---

#### 📧 Template: Change Email Address (Mudança de Email)

**Subject:**

```
Confirme a alteração de e-mail - CCI-CA
```

**Body (HTML):** Copie o conteúdo de:

```
mudar-email.html
```

---

#### 🔑 Template: Reauthentication (Reautenticação)

**Subject:**

```
Código de segurança - CCI-CA
```

**Body (HTML):** Copie o conteúdo de:

```
reautenticacao.html
```

---

#### 🎉 Template: Invite User (Convite de Usuário)

**Subject:**

```
Você foi convidado para o CCI-CA!
```

**Body (HTML):** Copie o conteúdo de:

```
convidar-usuario.html
```

---

## 🔗 URLs de Redirecionamento

### Configurar no Dashboard

**Settings** → **Authentication** → **URL Configuration**

### URLs de Produção (Netlify):

```
Site URL: https://cci-ca-aluno.netlify.app
Redirect URLs:
  - https://cci-ca-aluno.netlify.app/unauthenticated/redefinir-senha
  - https://cci-ca-aluno.netlify.app/confirmar-email
  - https://cci-ca-aluno.netlify.app/app
  - http://localhost:5174/** (para desenvolvimento)
```

### URLs Configuradas no Código:

#### UserContext.tsx - resetPassword:

```typescript
const { error } = await supabase.auth.resetPasswordForEmail(email, {
     redirectTo: `${window.location.origin}/unauthenticated/redefinir-senha`,
});
```

#### Confirmação de Email (automática):

O Supabase redireciona automaticamente para `/confirmar-email` após processar o hash da URL.

---

## ✅ Testando as Configurações

### 1. Teste de Cadastro

```bash
1. Acessar: https://cci-ca-aluno.netlify.app/cadastro-inicial
2. Preencher dados e criar conta
3. Verificar email de confirmação
4. Clicar no botão "Confirmar Cadastro"
5. Deve redirecionar para /confirmar-email → /app
```

### 2. Teste de Redefinição de Senha

```bash
1. Acessar: /unauthenticated/esqueci-minha-senha
2. Informar email
3. Verificar email de redefinição
4. Clicar em "Redefinir Senha"
5. Deve redirecionar para /unauthenticated/redefinir-senha
6. Criar nova senha
7. Deve redirecionar para /unauthenticated (login)
```

### 3. Teste de Magic Link

```bash
1. Acessar página de login
2. Clicar em "Receber link mágico"
3. Informar email
4. Verificar email
5. Clicar em "Acessar Minha Conta"
6. Deve fazer login automaticamente → /app
```

---

## 🐛 Troubleshooting

### ❌ Emails não estão sendo enviados

**Verificar:**

1. ✅ SMTP configurado corretamente
2. ✅ Credenciais válidas
3. ✅ Porta SMTP aberta no firewall
4. ✅ Logs do Supabase: **Settings** → **Logs** → **Auth**

**Solução:**

```bash
# Testar SMTP manualmente
curl -v smtp://smtp.seuservidor.com:587 \
  --mail-from noreply@cci-ca.com.br \
  --mail-rcpt destino@teste.com
```

---

### ❌ Template não está renderizando

**Verificar:**

1. ✅ HTML copiado completamente
2. ✅ Variáveis Supabase presentes: `{{ .ConfirmationURL }}`, `{{ .Token }}`, etc.
3. ✅ Sem erros de sintaxe HTML

**Solução:**

-    Use o editor de templates do Supabase
-    Preview antes de salvar
-    Teste em diferentes clientes de email

---

### ❌ Redirecionamento não funciona

**Verificar:**

1. ✅ URL adicionada em **Redirect URLs**
2. ✅ Protocolo correto (https)
3. ✅ URL exatamente igual (case-sensitive)

**Solução:**

```typescript
// Usar origin dinâmico
redirectTo: `${window.location.origin}/rota-desejada`;

// OU configurar manualmente
redirectTo: 'https://cci-ca-aluno.netlify.app/rota-desejada';
```

---

### ❌ Link de confirmação expirado

**Configuração de Expiração:**

-    **Settings** → **Authentication** → **Email**
-    **Confirm Email Token Lifetime**: 86400 (24 horas)
-    **Reset Password Token Lifetime**: 3600 (1 hora)

---

### ❌ Emails vão para spam

**Soluções:**

1. ✅ Configurar SPF no DNS:

```
v=spf1 include:_spf.google.com ~all
```

2. ✅ Configurar DKIM
3. ✅ Configurar DMARC:

```
v=DMARC1; p=none; rua=mailto:dmarc@cci-ca.com.br
```

4. ✅ Usar domínio verificado
5. ✅ Warming up do domínio (enviar emails gradualmente)

---

## 🔐 Segurança

### Boas Práticas:

-    ✅ Usar HTTPS em todos os redirects
-    ✅ Validar tokens no backend
-    ✅ Expiração curta para tokens sensíveis (1h para reset)
-    ✅ Rate limiting no envio de emails
-    ✅ Não expor informações sensíveis nos templates

### Variáveis Disponíveis nos Templates:

-    `{{ .ConfirmationURL }}` - URL de confirmação completa
-    `{{ .Token }}` - Código/token de verificação
-    `{{ .Email }}` - Email atual
-    `{{ .NewEmail }}` - Novo email (mudança de email)
-    `{{ .Year }}` - Ano atual (para copyright)

---

## 📚 Recursos Adicionais

### Documentação Oficial:

-    [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
-    [Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates)
-    [SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)

### Arquivos do Projeto:

```
cci-ca-docs/docs/Módulo Alunos - Auth/Configuração Email SMTP/
├── confirmar-cadastro.html
├── resetar-senha.html
├── link-magico.html
├── mudar-email.html
├── reautenticacao.html
└── convidar-usuario.html
```

### Código de Implementação:

```
cci-ca-aluno/src/
├── components/pages/Login/
│   ├── LoginPage.tsx
│   ├── ForgotPasswordPage.tsx
│   ├── PasswordResetPage.tsx
│   └── EmailConfirmationPage.tsx
└── contexts/UserContext/
    └── UserContext.tsx
```

---

## ✨ Checklist de Implementação

-    [ ] SMTP configurado e testado
-    [ ] Todos os 6 templates copiados e salvos
-    [ ] URLs de redirect adicionadas
-    [ ] SPF/DKIM/DMARC configurados
-    [ ] Teste de cadastro realizado
-    [ ] Teste de reset de senha realizado
-    [ ] Teste de magic link realizado
-    [ ] Emails não vão para spam
-    [ ] Redirecionamentos funcionando
-    [ ] Templates renderizando corretamente em diferentes clientes

---

**Última Atualização:** 21/10/2025  
**Responsável:** Gabriel M. Guimarães | gabrielmg7  
**Projeto:** CCI-CA Portal Aluno
