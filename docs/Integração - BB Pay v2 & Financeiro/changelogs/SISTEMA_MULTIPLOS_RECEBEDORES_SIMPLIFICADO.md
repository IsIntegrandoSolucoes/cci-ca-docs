# 🔄 Sistema de Múltiplos Recebedores - Versão Simplificada

**Data**: 13 de outubro de 2025  
**Versão**: 2.0 (Simplificada)  
**Status**: ✅ **IMPLEMENTADO**

---

## 🎯 Objetivo

Permitir configurar **N recebedores** por modalidade, ao invés de apenas 2 fixos (Convênio + Professor).

### Exemplo Real:

**Antes:**

```typescript
// Sistema hardcoded
recebedores: [
     { identificadorRecebedor: '125530', tipoRecebedor: 'Convenio', valorRepasse: 15 },
     { identificadorRecebedor: '789', tipoRecebedor: 'Participante', valorRepasse: 85 },
];
```

**Agora:**

```typescript
// Sistema configurável
recebedores: [
     { identificadorRecebedor: 'DINAMICO', tipoRecebedor: 'Participante', valorRepasse: 60 },
     { identificadorRecebedor: '456', tipoRecebedor: 'Participante', valorRepasse: 10 },
     { identificadorRecebedor: '125530', tipoRecebedor: 'Convenio', valorRepasse: 20 },
     { identificadorRecebedor: '789', tipoRecebedor: 'Participante', valorRepasse: 10 },
];
```

---

## 📊 Estrutura do Banco de Dados

### 1. **Tabela `configuracao_taxas_modalidade` (MODIFICADA)**

**Colunas Removidas:**

-    ❌ `pix_tipo`
-    ❌ `pix_valor`
-    ❌ `boleto_tipo`
-    ❌ `boleto_valor`

**Motivo:** Essas colunas só suportavam 2 recebedores fixos.

**Estrutura Atual:**

```sql
CREATE TABLE configuracao_taxas_modalidade (
    id SERIAL PRIMARY KEY,
    fk_id_modalidade_aula INT NOT NULL,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    deleted_by BIGINT
);
```

### 2. **Tabela `configuracao_recebedores` (NOVA)**

```sql
CREATE TABLE configuracao_recebedores (
    id SERIAL PRIMARY KEY,

    -- FK para configuração da modalidade (1:N)
    fk_id_configuracao_modalidade INT NOT NULL,

    -- RECEBEDOR
    tipo_recebedor VARCHAR(20) CHECK (tipo_recebedor IN ('Convenio', 'Participante')),
    identificador_recebedor VARCHAR(100) NOT NULL,

    -- VALOR (sempre percentual 0-100)
    percentual NUMERIC(5,2) CHECK (percentual >= 0 AND percentual <= 100),

    -- ORDENAÇÃO
    ordem INT DEFAULT 1,

    -- AUDITORIA
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    deleted_by BIGINT,

    FOREIGN KEY (fk_id_configuracao_modalidade)
        REFERENCES configuracao_taxas_modalidade(id) ON DELETE CASCADE
);
```

**Vantagens:**

-    ✅ **1:N** - Uma modalidade pode ter N recebedores
-    ✅ **Mesma config PIX/BOLETO** - Sem duplicação
-    ✅ **Tipos simples** - Apenas `Convenio` e `Participante`
-    ✅ **Percentual** - Sempre 0-100% (sem valor fixo)

---

## 🔧 Funcionalidades SQL

### 1. **Função: `buscar_recebedores_modalidade`**

Busca todos os recebedores ativos de uma modalidade:

```sql
SELECT * FROM buscar_recebedores_modalidade(1); -- modalidade_id = 1
```

**Retorno:**

```sql
 id | tipo_recebedor | identificador_recebedor | percentual | ordem
----+----------------+-------------------------+------------+-------
  1 | Convenio       | 125530                  |      20.00 |     1
  2 | Participante   | DINAMICO                |      60.00 |     2
  3 | Participante   | 456                     |      10.00 |     3
  4 | Participante   | 789                     |      10.00 |     4
```

### 2. **Trigger: `validar_soma_percentuais`**

Valida automaticamente que a soma dos percentuais = 100%:

```sql
-- ✅ SUCESSO: soma = 100%
INSERT INTO configuracao_recebedores VALUES
  (1, 'Convenio', '125530', 30, 1),
  (1, 'Participante', 'DINAMICO', 70, 2);

-- ❌ ERRO: soma = 110%
INSERT INTO configuracao_recebedores VALUES
  (1, 'Convenio', '125530', 30, 1),
  (1, 'Participante', 'DINAMICO', 80, 2);
-- ERROR: Soma dos percentuais não pode exceder 100%. Soma atual: 110%
```

---

## 💻 Integração Backend

### 1. **Identificador `DINAMICO`**

O identificador especial `"DINAMICO"` é resolvido **no momento do pagamento** usando:

```typescript
// Fluxo de resolução:
turmas.fk_id_cnpj → cnpj.fk_id_conta_bancaria → conta_bancaria.numero_participante
```

**Query SQL:**

```sql
SELECT cb.numero_participante
FROM turmas t
JOIN cnpj c ON c.id = t.fk_id_cnpj
JOIN conta_bancaria cb ON cb.id = c.fk_id_conta_bancaria
WHERE t.id = ?;
```

### 2. **Service: `RepasseCalculatorService`**

```typescript
async calcularRepasseModalidade(
  valor: number,
  modalidadeId: number,
  turmaId?: number
): Promise<IRepasse> {
  // 1. Busca recebedores da modalidade
  const recebedores = await this.buscarRecebedoresModalidade(modalidadeId);

  // 2. Resolve identificadores dinâmicos
  const recebedoresResolvidos = await Promise.all(
    recebedores.map(async (rec) => {
      if (rec.identificador_recebedor === 'DINAMICO' && turmaId) {
        const numeroParticipante = await this.resolverNumeroParticipante(turmaId);
        return { ...rec, identificador_recebedor: numeroParticipante };
      }
      return rec;
    })
  );

  // 3. Retorna repasse formatado para BB Pay
  return {
    tipoValorRepasse: 'Percentual',
    recebedores: recebedoresResolvidos.map(r => ({
      identificadorRecebedor: r.identificador_recebedor,
      tipoRecebedor: r.tipo_recebedor,
      valorRepasse: r.percentual
    }))
  };
}

private async resolverNumeroParticipante(turmaId: number): Promise<string> {
  const { data } = await supabase
    .from('turmas')
    .select(`
      fk_id_cnpj,
      cnpj!inner(fk_id_conta_bancaria),
      conta_bancaria!inner(numero_participante)
    `)
    .eq('id', turmaId)
    .single();

  return data?.conta_bancaria?.numero_participante || '0';
}

private async buscarRecebedoresModalidade(modalidadeId: number) {
  const { data } = await supabase.rpc('buscar_recebedores_modalidade', {
    p_id_modalidade_aula: modalidadeId
  });
  return data || [];
}
```

### 3. **Atualização: `CobrancaIntegracaoService`**

```typescript
// Antes (hardcoded)
repasse: {
  tipoValorRepasse: 'Percentual',
  recebedores: [
    { identificadorRecebedor: "125530", tipoRecebedor: 'Convenio', valorRepasse: 15 },
    { identificadorRecebedor: "789", tipoRecebedor: 'Participante', valorRepasse: 85 }
  ]
}

// Agora (dinâmico)
const repasse = await this.repasseCalculator.calcularRepasseModalidade(
  valor,
  modalidadeId,
  turmaId
);

repasse: repasse
```

---

## 🧪 Como Testar

### 1. **Executar Migration**

```bash
# Via Supabase SQL Editor
# Copiar e colar: migrations/20251013_multiplos_recebedores_simplificado.sql
```

### 2. **Verificar Migração**

```sql
-- Ver recebedores migrados
SELECT
  ma.nome as modalidade,
  r.tipo_recebedor,
  r.identificador_recebedor,
  r.percentual,
  r.ordem
FROM configuracao_recebedores r
JOIN configuracao_taxas_modalidade ctm ON ctm.id = r.fk_id_configuracao_modalidade
JOIN modalidade_aula ma ON ma.id = ctm.fk_id_modalidade_aula
WHERE r.deleted_at IS NULL
ORDER BY ma.nome, r.ordem;
```

**Resultado Esperado:**

```
    modalidade     | tipo_recebedor | identificador_recebedor | percentual | ordem
-------------------+----------------+-------------------------+------------+-------
 Aula Particular   | Convenio       | 125530                  |      15.00 |     1
 Aula Particular   | Participante   | DINAMICO                |      85.00 |     2
 Aula em Grupo     | Convenio       | 125530                  |      20.00 |     1
 Aula em Grupo     | Participante   | DINAMICO                |      80.00 |     2
 Pré-Prova         | Convenio       | 125530                  |      25.00 |     1
 Pré-Prova         | Participante   | DINAMICO                |      75.00 |     2
```

### 3. **Adicionar Novo Recebedor**

```sql
-- Adicionar professor específico (10%) na Aula Particular
INSERT INTO configuracao_recebedores (
  fk_id_configuracao_modalidade,
  tipo_recebedor,
  identificador_recebedor,
  percentual,
  ordem
) VALUES (
  (SELECT id FROM configuracao_taxas_modalidade WHERE fk_id_modalidade_aula = 1 LIMIT 1),
  'Participante',
  '456', -- Número do participante específico
  10,
  3
);

-- Ajustar percentual do professor dinâmico (85% → 75%)
UPDATE configuracao_recebedores
SET percentual = 75
WHERE fk_id_configuracao_modalidade = (
  SELECT id FROM configuracao_taxas_modalidade WHERE fk_id_modalidade_aula = 1 LIMIT 1
)
AND identificador_recebedor = 'DINAMICO';
```

**Resultado:**

```
Aula Particular:
  - Convênio 125530: 15%
  - Professor dinâmico: 75%
  - Professor 456: 10%
  TOTAL: 100% ✅
```

### 4. **Testar Validação (Deve Falhar)**

```sql
-- Tentar adicionar recebedor que ultrapassa 100%
INSERT INTO configuracao_recebedores (
  fk_id_configuracao_modalidade,
  tipo_recebedor,
  identificador_recebedor,
  percentual,
  ordem
) VALUES (
  (SELECT id FROM configuracao_taxas_modalidade WHERE fk_id_modalidade_aula = 1 LIMIT 1),
  'Participante',
  '999',
  20, -- Excede 100%
  4
);
```

**Resultado Esperado:**

```
ERROR: Soma dos percentuais não pode exceder 100%. Soma atual: 120%
```

---

## 📋 Cenários de Uso

### **Cenário 1: Aula com 2 Professores**

```json
{
     "modalidade": "Aula Particular",
     "recebedores": [
          { "tipo": "Participante", "identificador": "DINAMICO", "percentual": 60 },
          { "tipo": "Participante", "identificador": "456", "percentual": 10 },
          { "tipo": "Convenio", "identificador": "125530", "percentual": 30 }
     ]
}
```

**Pagamento de R$ 150,00:**

-    Professor principal (via turma): R$ 90,00 (60%)
-    Professor secundário (456): R$ 15,00 (10%)
-    Convênio (125530): R$ 45,00 (30%)

### **Cenário 2: Aula com 3 Professores + Terceiro**

```json
{
     "modalidade": "Turma Vestibular",
     "recebedores": [
          { "tipo": "Participante", "identificador": "DINAMICO", "percentual": 50 },
          { "tipo": "Participante", "identificador": "111", "percentual": 20 },
          { "tipo": "Participante", "identificador": "222", "percentual": 10 },
          { "tipo": "Convenio", "identificador": "125530", "percentual": 20 }
     ]
}
```

**Pagamento de R$ 200,00:**

-    Professor principal: R$ 100,00 (50%)
-    Professor 111: R$ 40,00 (20%)
-    Professor 222: R$ 20,00 (10%)
-    Convênio: R$ 40,00 (20%)

---

## 🎨 Frontend (A Implementar - Opcional)

### **Componentes Sugeridos:**

```typescript
// 1. Hook para gerenciar recebedores
const useRecebedoresConfig = (modalidadeId: number) => {
     const [recebedores, setRecebedores] = useState<IRecebedor[]>([]);

     const buscarRecebedores = async () => {
          const data = await api.get(`/recebedores/modalidade/${modalidadeId}`);
          setRecebedores(data);
     };

     const adicionarRecebedor = async (recebedor: INovoRecebedor) => {
          await api.post(`/recebedores/modalidade/${modalidadeId}`, recebedor);
          await buscarRecebedores();
     };

     const atualizarPercentual = async (recebedorId: number, percentual: number) => {
          await api.patch(`/recebedores/${recebedorId}`, { percentual });
          await buscarRecebedores();
     };

     const removerRecebedor = async (recebedorId: number) => {
          await api.delete(`/recebedores/${recebedorId}`);
          await buscarRecebedores();
     };

     const somaPercentuais = recebedores.reduce((sum, r) => sum + r.percentual, 0);
     const valido = somaPercentuais === 100;

     return {
          recebedores,
          adicionarRecebedor,
          atualizarPercentual,
          removerRecebedor,
          somaPercentuais,
          valido,
     };
};

// 2. Componente de Lista
const ListaRecebedores = ({ modalidadeId }: { modalidadeId: number }) => {
     const { recebedores, removerRecebedor, atualizarPercentual, somaPercentuais, valido } = useRecebedoresConfig(modalidadeId);

     return (
          <div>
               <h3>Recebedores</h3>
               {recebedores.map((rec) => (
                    <div key={rec.id}>
                         <span>
                              {rec.tipo_recebedor}: {rec.identificador_recebedor}
                         </span>
                         <input
                              type='number'
                              value={rec.percentual}
                              onChange={(e) => atualizarPercentual(rec.id, +e.target.value)}
                         />
                         <button onClick={() => removerRecebedor(rec.id)}>Remover</button>
                    </div>
               ))}

               <div style={{ color: valido ? 'green' : 'red' }}>
                    Soma: {somaPercentuais}% {valido ? '✅' : '❌ Deve ser 100%'}
               </div>
          </div>
     );
};
```

---

## 🔍 Comparação: Antes vs Agora

| Aspecto                        | Antes                               | Agora                            |
| ------------------------------ | ----------------------------------- | -------------------------------- |
| **Recebedores por modalidade** | 2 fixos                             | N configuráveis                  |
| **Tipos de recebedor**         | Hardcoded                           | Convenio, Participante           |
| **Config PIX/BOLETO**          | Separadas                           | Unificadas                       |
| **Identificação professor**    | `numero_participante` direto        | `DINAMICO` resolve via turma     |
| **Validação percentuais**      | Manual                              | Automática (trigger)             |
| **Tabelas necessárias**        | 1 (`configuracao_taxas_modalidade`) | 2 (`+ configuracao_recebedores`) |
| **Complexidade**               | Baixa                               | Baixa                            |
| **Flexibilidade**              | Baixa                               | Alta                             |

---

## ✅ Checklist de Implementação

### Backend

-    [x] Migration SQL criada
-    [x] Tabela `configuracao_recebedores` criada
-    [x] Função `buscar_recebedores_modalidade()` criada
-    [x] Trigger `validar_soma_percentuais` criado
-    [x] Dados migrados automaticamente
-    [ ] Service `RecebedoresConfigService` implementado
-    [ ] Controller `RecebedoresConfigController` implementado
-    [ ] Rotas da API adicionadas
-    [ ] `RepasseCalculatorService` atualizado
-    [ ] `CobrancaIntegracaoService` atualizado

### Frontend (Opcional)

-    [ ] Hook `useRecebedoresConfig` implementado
-    [ ] Componente `ListaRecebedores` implementado
-    [ ] Componente `FormNovoRecebedor` implementado
-    [ ] Validação visual (soma = 100%)
-    [ ] Preview de divisão de valores

---

## 🚀 Próximos Passos

1. **Executar Migration**

     ```bash
     # Via Supabase SQL Editor
     ```

2. **Atualizar Services Backend**

     - Implementar `RecebedoresConfigService`
     - Atualizar `RepasseCalculatorService`
     - Atualizar `CobrancaIntegracaoService`

3. **Criar Endpoints API**

     - `GET /recebedores/modalidade/:id`
     - `POST /recebedores/modalidade/:id`
     - `PATCH /recebedores/:id`
     - `DELETE /recebedores/:id`

4. **Implementar Frontend (Opcional)**
     - Tela de configuração de recebedores
     - Validação em tempo real
     - Preview de divisão

---

## 📚 Documentação Relacionada

-    [SISTEMA_REPASSE_IMPLEMENTADO.md](./SISTEMA_REPASSE_IMPLEMENTADO.md) - Sistema original
-    [SISTEMA_CONFIGURACAO_TAXAS.md](./SISTEMA_CONFIGURACAO_TAXAS.md) - Configuração de taxas v2.0
-    [ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md](./ADMIN.CONCILIACAO_BANCARIA_PARCELAS.md) - Conciliação bancária

---

**Autor:** Gabriel M. Guimarães  
**Data:** 13 de outubro de 2025  
**Versão:** 2.0 (Simplificada)
