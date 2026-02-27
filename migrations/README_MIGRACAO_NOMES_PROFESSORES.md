# 🔄 Migração: Sistema de Exibição de Nomes de Professores

**Data:** 13 de outubro de 2025  
**Autor:** Gabriel M. Guimarães  
**Versão:** 1.0

## 📋 Resumo

Implementação completa para exibir nomes dos professores no sistema de configuração de recebedores, incluindo:

-    View SQL para listar professores com conta bancária
-    Funções SQL auxiliares
-    Service e hook frontend
-    Componentes atualizados

## 🎯 Objetivos

1. Facilitar identificação de professores no formulário de recebedores
2. Validar automaticamente se professor tem conta bancária
3. Melhorar UX com nomes ao invés de números
4. Preparar base para funcionalidades futuras (autocomplete, validações)

## 📁 Arquivos Criados/Modificados

### **Backend (SQL)**

#### Criados:

```
migrations/
└── 20251013_view_professores_com_conta_bancaria.sql
```

**Conteúdo:**

-    View `view_professores_com_conta_bancaria`
-    Função `buscar_professor_por_numero_participante()`
-    Função `professor_tem_conta_bancaria()`
-    Estatísticas e validações

### **Frontend (cci-ca-admin)**

#### Criados:

```
src/
├── types/database/
│   └── IProfessorContaBancaria.ts
├── services/api/
│   └── professoresApiService.ts
├── hooks/
│   └── useProfessoresComContaBancaria.ts
└── components/pages/Financeiro/ConfiguracaoTaxas/
    └── README_NOMES_PROFESSORES.md
```

#### Modificados:

```
src/components/pages/Financeiro/ConfiguracaoTaxas/
├── CardModalidade.tsx
├── ItemRecebedor.tsx
└── ModalEditarRecebedores.tsx
```

## 🚀 Passo a Passo da Migração

### **Passo 1: Executar Migration SQL**

```bash
# Conectar ao Supabase
psql -h <seu-host> -U postgres -d postgres

# Executar migration
\i migrations/20251013_view_professores_com_conta_bancaria.sql
```

**Verificações:**

```sql
-- Ver professores cadastrados
SELECT * FROM view_professores_com_conta_bancaria;

-- Testar função de busca
SELECT * FROM buscar_professor_por_numero_participante('19');

-- Testar validação
SELECT professor_tem_conta_bancaria(123);
```

### **Passo 2: Criar Endpoints na API (cci-ca-api)**

Criar arquivo `src/routes/professores.routes.ts`:

```typescript
import { Router } from 'express';
import { supabaseClient } from '../config/supabaseConfig';

const router = Router();

/**
 * GET /api/professores/com-conta-bancaria
 * Lista professores com conta bancária configurada
 */
router.get('/com-conta-bancaria', async (req, res) => {
     try {
          const { data, error } = await supabaseClient.from('view_professores_com_conta_bancaria').select('*').order('professor_nome');

          if (error) throw error;

          return res.json({
               success: true,
               message: 'Professores carregados com sucesso',
               data: data || [],
          });
     } catch (error: any) {
          console.error('[ProfessoresRoutes] Erro ao listar:', error);
          return res.status(500).json({
               success: false,
               message: error.message,
               data: [],
          });
     }
});

/**
 * GET /api/professores/por-numero-participante/:numero
 * Busca professor por número de participante
 */
router.get('/por-numero-participante/:numero', async (req, res) => {
     try {
          const { numero } = req.params;

          const { data, error } = await supabaseClient.rpc('buscar_professor_por_numero_participante', { p_numero_participante: numero });

          if (error) throw error;

          return res.json({
               success: true,
               message: data && data.length > 0 ? 'Professor encontrado' : 'Professor não encontrado',
               data: data && data.length > 0 ? data[0] : null,
          });
     } catch (error: any) {
          console.error('[ProfessoresRoutes] Erro ao buscar professor:', error);
          return res.status(500).json({
               success: false,
               message: error.message,
               data: null,
          });
     }
});

/**
 * GET /api/professores/:id/tem-conta-bancaria
 * Valida se professor tem conta bancária
 */
router.get('/:id/tem-conta-bancaria', async (req, res) => {
     try {
          const { id } = req.params;

          const { data, error } = await supabaseClient.rpc('professor_tem_conta_bancaria', {
               p_professor_id: parseInt(id),
          });

          if (error) throw error;

          return res.json({
               success: true,
               data: data || false,
          });
     } catch (error: any) {
          console.error('[ProfessoresRoutes] Erro ao validar professor:', error);
          return res.status(500).json({
               success: false,
               data: false,
          });
     }
});

export default router;
```

Registrar rotas em `src/app.ts`:

```typescript
import professoresRoutes from './routes/professores.routes';

// ... outras rotas

app.use('/api/professores', professoresRoutes);
```

### **Passo 3: Frontend - Arquivos Já Criados**

Os arquivos do frontend já foram criados:

-    ✅ `IProfessorContaBancaria.ts`
-    ✅ `professoresApiService.ts`
-    ✅ `useProfessoresComContaBancaria.ts`
-    ✅ Componentes atualizados

**Nenhuma ação adicional necessária no frontend.**

### **Passo 4: Testes**

#### Backend:

```bash
# Testar endpoint de listagem
curl http://localhost:3002/api/professores/com-conta-bancaria

# Testar busca por número
curl http://localhost:3002/api/professores/por-numero-participante/19

# Testar validação
curl http://localhost:3002/api/professores/123/tem-conta-bancaria
```

#### Frontend:

```bash
# Iniciar servidor de desenvolvimento
cd cci-ca-admin
npm run dev

# Acessar página de configuração
# http://localhost:5173/financeiro/configuracao-taxas

# Testar:
# 1. Cards exibem nomes dos professores
# 2. Modal de edição exibe nomes
# 3. Badge "DINAMICO" aparece corretamente
# 4. Não quebra se professor não encontrado
```

## 🔍 Verificação de Integridade

### **SQL:**

```sql
-- Verificar view
SELECT COUNT(*) FROM view_professores_com_conta_bancaria;

-- Verificar professores sem conta (alerta!)
SELECT
    p.id,
    p.nome,
    p.email
FROM pessoas p
WHERE p.fk_id_tipo_pessoa = 2
    AND p.deleted_at IS NULL
    AND p.ativo = TRUE
    AND NOT EXISTS (
        SELECT 1
        FROM view_professores_com_conta_bancaria v
        WHERE v.professor_id = p.id
    );
```

### **API:**

```bash
# Deve retornar lista de professores
curl -X GET http://localhost:3002/api/professores/com-conta-bancaria \
  -H "Content-Type: application/json"

# Response esperado:
{
  "success": true,
  "message": "Professores carregados com sucesso",
  "data": [
    {
      "professor_id": 123,
      "professor_nome": "João Silva",
      "numero_participante": "19",
      ...
    }
  ]
}
```

### **Frontend:**

1. Abrir DevTools → Network
2. Acessar página de configuração
3. Verificar chamada: `GET /api/professores/com-conta-bancaria`
4. Verificar console: sem erros
5. UI: nomes de professores aparecem

## 🐛 Troubleshooting

### **Problema 1: View não retorna dados**

```sql
-- Verificar se há professores com conta bancária
SELECT
    p.id,
    p.nome,
    c.cpf_cnpj,
    cb.numero_participante
FROM pessoas p
JOIN cnpj c ON c.fk_id_pessoa = p.id
JOIN conta_bancaria cb ON cb.fk_id_cnpj = c.id
WHERE p.fk_id_tipo_pessoa = 2
    AND p.deleted_at IS NULL
    AND cb.deleted_at IS NULL
    AND cb.numero_participante IS NOT NULL;
```

**Solução:** Se vazio, cadastrar conta bancária para professores.

### **Problema 2: API retorna erro 500**

```bash
# Ver logs da API
npm run dev
# Verificar console para erros
```

**Possíveis causas:**

-    Supabase client não configurado
-    View não existe no banco
-    Permissões RLS bloqueando acesso

**Solução:**

```typescript
// Verificar supabaseClient em src/config/supabaseConfig.ts
// Testar conexão direta:
const { data, error } = await supabaseClient.from('view_professores_com_conta_bancaria').select('*').limit(1);

console.log('Teste view:', data, error);
```

### **Problema 3: Frontend não exibe nomes**

**Debug:**

```typescript
// Adicionar logs no hook
const { professoresSimplificados, buscarNomeProfessor } = useProfessoresComContaBancaria();

console.log('Professores carregados:', professoresSimplificados);

const nome = buscarNomeProfessor('19');
console.log('Nome encontrado para 19:', nome);
```

**Possíveis causas:**

-    API não retornou dados
-    Números não correspondem (ex: "19" vs 19)
-    Cache não foi atualizado

**Solução:**

-    Verificar Network → Resposta da API
-    Verificar tipos (string vs number)
-    Recarregar página

## 📊 Impacto e Benefícios

### **Performance:**

-    ✅ Carregamento único no mount
-    ✅ Buscas locais (sem HTTP)
-    ✅ Lista simplificada (cache)
-    ⚠️ View não materializada (considerar futuro)

### **UX:**

-    ✅ Nomes ao invés de números
-    ✅ Identificação visual clara
-    ✅ Badge para DINAMICO
-    ✅ Tooltips informativos

### **Manutenibilidade:**

-    ✅ Código modular (hook, service)
-    ✅ Interfaces TypeScript
-    ✅ Documentação completa
-    ✅ Fácil extensão futura

## 🔄 Rollback (se necessário)

### **Backend:**

```sql
-- Remover view e funções
DROP VIEW IF EXISTS view_professores_com_conta_bancaria CASCADE;
DROP FUNCTION IF EXISTS buscar_professor_por_numero_participante;
DROP FUNCTION IF EXISTS professor_tem_conta_bancaria;
```

### **API:**

```bash
# Remover arquivo
rm src/routes/professores.routes.ts

# Remover registro em app.ts
# Comentar: app.use('/api/professores', professoresRoutes);
```

### **Frontend:**

```bash
# Remover arquivos criados
rm src/types/database/IProfessorContaBancaria.ts
rm src/services/api/professoresApiService.ts
rm src/hooks/useProfessoresComContaBancaria.ts

# Reverter componentes (git)
git checkout src/components/pages/Financeiro/ConfiguracaoTaxas/CardModalidade.tsx
git checkout src/components/pages/Financeiro/ConfiguracaoTaxas/ItemRecebedor.tsx
git checkout src/components/pages/Financeiro/ConfiguracaoTaxas/ModalEditarRecebedores.tsx
```

## 📚 Documentação Adicional

-    [README do Sistema](../cci-ca-admin/src/components/pages/Financeiro/ConfiguracaoTaxas/README_NOMES_PROFESSORES.md)
-    [Guia de Database Driven](./instructions/GUIA_DATABASE_DRIVEN.instructions.md)
-    [Sistema de Múltiplos Recebedores](./docs/IMPLEMENTACAO_COMPLETA_MULTIPLOS_RECEBEDORES.md)

## ✅ Checklist de Migração

-    [ ] Executar migration SQL no Supabase
-    [ ] Verificar view criada: `SELECT * FROM view_professores_com_conta_bancaria`
-    [ ] Criar endpoints na API (professores.routes.ts)
-    [ ] Registrar rotas em app.ts
-    [ ] Testar endpoints via curl/Postman
-    [ ] Verificar frontend carrega professores (DevTools → Network)
-    [ ] Testar exibição de nomes nos cards
-    [ ] Testar exibição de nomes no modal
-    [ ] Testar badge DINAMICO
-    [ ] Validar comportamento sem nome (null)
-    [ ] Documentar em CHANGELOG
-    [ ] Commit e push das alterações

---

**Status:** ✅ Pronto para deploy  
**Última atualização:** 13/10/2025
