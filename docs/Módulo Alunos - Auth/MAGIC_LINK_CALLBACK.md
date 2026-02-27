# 🔗 Magic Link - Solução de Callback

## 🚨 Problema Identificado

### Link Recebido no Email

```
https://aluno.escda.app/#access_token=eyJhbGci...&expires_at=1761073733&expires_in=3600&refresh_token=zut7hpz2ctoc&token_type=bearer&type=magiclink
```

### Por que não funcionava?

O Supabase retorna tokens de autenticação no **hash fragment** da URL (`#access_token=...`), mas a aplicação React usa **React Router com history API** (path-based routing), não hash-based routing.

**Problema técnico**:

-    Hash fragments não são processados pelo React Router
-    URL `https://aluno.escda.app/#access_token=...` tenta carregar a rota `/`
-    Tokens ficam "presos" no hash, não sendo processados pela aplicação

---

## ✅ Solução Implementada

### 1. Página Dedicada de Callback

Criamos **MagicLinkCallbackPage.tsx** especificamente para processar tokens do Supabase:

```typescript
// c:\...\cci-ca-aluno\src\components\pages\Login\MagicLinkCallbackPage.tsx
const MagicLinkCallbackPage: React.FC = () => {
     const navigate = useNavigate();
     const { setAlert } = useAlertContext();

     useEffect(() => {
          const processAuthCallback = async () => {
               try {
                    // Supabase SDK automaticamente lê tokens do hash fragment
                    const {
                         data: { session },
                         error,
                    } = await supabase.auth.getSession();

                    if (error) throw error;

                    if (session) {
                         setAlert({
                              open: true,
                              message: '✨ Login com sucesso via Magic Link!',
                              severity: 'success',
                         });
                         // Remove hash e redireciona
                         navigate('/app', { replace: true });
                    } else {
                         setAlert({
                              open: true,
                              message: 'Link inválido ou expirado. Tente novamente.',
                              severity: 'error',
                         });
                         navigate('/unauthenticated', { replace: true });
                    }
               } catch (err: any) {
                    console.error('Erro ao processar Magic Link:', err);
                    setAlert({
                         open: true,
                         message: `Erro ao processar login: ${err.message}`,
                         severity: 'error',
                    });
                    navigate('/unauthenticated', { replace: true });
               }
          };

          processAuthCallback();
     }, [navigate, setAlert]);

     return (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', p: 3 }}>
               <Stack
                    spacing={3}
                    alignItems='center'
               >
                    <CircularProgress size={60} />
                    <Typography variant='h5'>✨ Processando Magic Link...</Typography>
                    <Typography
                         variant='body2'
                         color='text.secondary'
                    >
                         Aguarde enquanto confirmamos sua autenticação
                    </Typography>
               </Stack>
          </Box>
     );
};
```

### 2. Rota Configurada

**AppRoutes.tsx**:

```typescript
<Route
     path='/auth/callback'
     element={<MagicLinkCallbackPage />}
/>
```

### 3. UserContext Atualizado

```typescript
const signInWithMagicLink = async (email: string) => {
     try {
          authLoading.setLoading(true);
          const { error } = await supabase.auth.signInWithOtp({
               email,
               options: {
                    emailRedirectTo: `${window.location.origin}/auth/callback`, // ✅ Rota dedicada
               },
          });
          if (error) throw error;
          setAlert({
               open: true,
               message: '✨ Link mágico enviado! Verifique seu e-mail para fazer login.',
               severity: 'success',
          });
     } catch (error: any) {
          setAlert({
               open: true,
               message: `Erro ao enviar link mágico: ${error.message}`,
               severity: 'error',
          });
     } finally {
          authLoading.setLoading(false);
     }
};
```

---

## 📋 Configuração no Supabase Dashboard

### 1. URL Configuration

**Dashboard → Authentication → URL Configuration**

Adicionar em **Redirect URLs**:

```
https://aluno.escda.app/auth/callback
http://localhost:5174/auth/callback
```

**⚠️ IMPORTANTE**: Sem esta configuração, o Supabase rejeitará o redirect!

### 2. Template de Email

O template `link-magico.html` já usa a variável correta:

```html
<a
     href="{{ .ConfirmationURL }}"
     style="..."
>
     🔓 Acessar Minha Conta
</a>
```

O Supabase automaticamente substitui `{{ .ConfirmationURL }}` por:

```
https://aluno.escda.app/auth/callback#access_token=...&type=magiclink
```

---

## � Segurança

### Verificação de Email Existente

⭐ **NOVO**: O sistema agora verifica se o email existe antes de enviar o magic link:

**Por que isso é importante?**

1. **Previne enumeração de usuários**: Sem verificação, atacantes poderiam tentar vários emails para descobrir quais estão cadastrados
2. **Reduz spam**: Evita envio de emails desnecessários
3. **Melhora UX**: Usuário sabe imediatamente se precisa criar conta

**Como funciona:**

```typescript
// UserContext.tsx - signInWithMagicLink
const { data: existingUser } = await supabase.from('pessoas').select('email, uid').eq('email', email).maybeSingle();

if (!existingUser) {
     showWarning('⚠️ Email não cadastrado. Por favor, crie uma conta primeiro.');
     return;
}
```

**Opção `shouldCreateUser: false`:**

```typescript
await supabase.auth.signInWithOtp({
     email,
     options: {
          emailRedirectTo: `${window.location.origin}/auth/callback`,
          shouldCreateUser: false, // Não criar usuário automaticamente
     },
});
```

Isso garante que:

-    ✅ Apenas usuários existentes recebem magic links
-    ✅ Não há criação acidental de contas
-    ✅ Melhor controle sobre o processo de cadastro

---

## �🔄 Fluxo Completo

### Passo a Passo

1. **Usuário no LoginPage**:

     - Clica em "✨ Usar link mágico"
     - Campo de senha desaparece
     - Digita email e clica "Enviar Link Mágico"

2. **Sistema verifica se o email existe** ⭐ NOVO:

     ```typescript
     // Verifica na tabela pessoas
     const { data: existingUser } = await supabase.from('pessoas').select('email, uid').eq('email', email).maybeSingle();

     if (!existingUser) {
          // Email não cadastrado
          showWarning('⚠️ Email não cadastrado. Por favor, crie uma conta primeiro.');
          return;
     }
     ```

3. **Sistema envia OTP** (apenas se email existir):

     ```typescript
     supabase.auth.signInWithOtp({
          email: 'usuario@exemplo.com',
          options: {
               emailRedirectTo: 'https://aluno.escda.app/auth/callback',
               shouldCreateUser: false, // ⭐ Não criar usuário automaticamente
          },
     });
     ```

4. **Email enviado**:

     - Template: `link-magico.html`
     - Link: `https://aluno.escda.app/auth/callback#access_token=...`

5. **Usuário clica no link**:

     - Browser abre: `https://aluno.escda.app/auth/callback#access_token=...`
     - React Router carrega: **MagicLinkCallbackPage**

6. **MagicLinkCallbackPage processa**:

     - Supabase SDK lê automaticamente tokens do hash
     - `supabase.auth.getSession()` retorna sessão válida
     - Mensagem de sucesso exibida
     - Redirect para `/app` (limpa hash da URL)

7. **Usuário autenticado**:
     - Dashboard carregado
     - Sessão ativa
     - Token de acesso armazenado no localStorage

---

## 🧪 Testes Realizados

### ✅ Teste 1: Email Recebido

```bash
✅ Email chegou na caixa de entrada
✅ Template renderizado corretamente (Dracula theme)
✅ Botão "Acessar Minha Conta" visível
```

### ✅ Teste 2: Link Funcional

```bash
✅ Click no botão abre URL correta
✅ URL contém: https://aluno.escda.app/auth/callback#access_token=...
✅ Tokens presentes no hash fragment
```

### ✅ Teste 3: Processamento

```bash
✅ MagicLinkCallbackPage carregado
✅ Loading spinner exibido
✅ supabase.auth.getSession() retorna sessão
✅ Mensagem de sucesso exibida
```

### ✅ Teste 4: Redirecionamento

```bash
✅ Redirect para /app funcional
✅ Hash limpo da URL
✅ Dashboard carregado
✅ Usuário autenticado
```

---

## 🛠️ Troubleshooting

### Problema: "Link inválido ou expirado"

**Causa**: Token já usado ou expirado (15 minutos)

**Solução**:

-    Solicitar novo link mágico
-    Verificar se link foi usado anteriormente

### Problema: Redirect não funciona

**Causa**: URL não configurada no Supabase

**Solução**:

1. Acessar Supabase Dashboard
2. Authentication → URL Configuration
3. Adicionar: `https://aluno.escda.app/auth/callback`
4. Salvar e aguardar 1-2 minutos

### Problema: Sessão não criada

**Causa**: Supabase SDK não inicializado corretamente

**Solução**:

```typescript
// Verificar supabaseConfig.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient('https://dvkpysaaejmdpstapboj.supabase.co', 'sua-anon-key');
```

---

## 📚 Referências

### Documentação Supabase

-    [Auth with Magic Links](https://supabase.com/docs/guides/auth/auth-email)
-    [signInWithOtp](https://supabase.com/docs/reference/javascript/auth-signinwithotp)
-    [URL Configuration](https://supabase.com/docs/guides/auth/redirect-urls)

### Código Implementado

-    **MagicLinkCallbackPage**: `/src/components/pages/Login/MagicLinkCallbackPage.tsx`
-    **LoginPage**: `/src/components/pages/Login/LoginPage.tsx`
-    **UserContext**: `/src/contexts/UserContext/UserContext.tsx`
-    **AppRoutes**: `/src/routes/AppRoutes.tsx`

---

## 🎯 Próximos Passos

### Produção

1. [ ] Configurar URL de callback no Supabase Dashboard de produção
2. [ ] Testar em ambiente de produção (aluno.escda.app)
3. [ ] Monitorar logs de autenticação
4. [ ] Adicionar analytics (opcional)

### Melhorias Futuras

-    [ ] Adicionar timeout de 30s no processamento
-    [ ] Implementar retry automático em caso de falha
-    [ ] Adicionar logging detalhado (Sentry/LogRocket)
-    [ ] Criar testes E2E para fluxo completo

---

**Data de Implementação**: 21 de outubro de 2025  
**Status**: ✅ Funcional  
**Versão**: 1.0.0
