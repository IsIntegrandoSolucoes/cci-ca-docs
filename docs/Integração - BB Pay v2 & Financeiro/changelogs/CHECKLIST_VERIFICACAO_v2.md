# ✅ Checklist de Verificação - Sistema de Taxas v2.0

## 📋 Status: Migration Executada | Aguardando Testes

---

## 🔴 ALTA PRIORIDADE (Fazer Hoje)

### Backend (cci-ca-api)

-    [ ] **Testar Endpoint GET** `/api/configuracao-taxas/modalidades`

     ```bash
     curl http://localhost:3002/api/configuracao-taxas/modalidades
     ```

     -    Deve retornar: 6 configurações de modalidade
     -    Deve incluir: id, fk_id_modalidade_aula, pix_tipo, pix_valor, boleto_tipo, boleto_valor

-    [ ] **Testar Endpoint PUT** `/api/configuracao-taxas/modalidade/:id`

     ```bash
     curl -X PUT http://localhost:3002/api/configuracao-taxas/modalidade/1 \
       -H "Content-Type: application/json" \
       -d '{"pix_tipo": "Percentual", "pix_valor": 5.5}'
     ```

     -    Deve atualizar: configuração com sucesso
     -    Deve retornar: objeto atualizado

-    [ ] **Testar Relatório de Repasse**
     ```bash
     curl "http://localhost:3002/api/relatorios-repasse?data_inicio=2025-10-01&data_fim=2025-10-31"
     ```
     -    Deve calcular: taxas baseadas APENAS em modalidade
     -    Deve retornar: valores corretos de repasse

### Frontend (cci-ca-admin)

-    [ ] **Acessar Página Principal** `http://localhost:5173/financeiro/configuracao-taxas`

     -    Deve carregar: lista de 6-8 modalidades
     -    Deve mostrar: botão "Editar" para cada modalidade
     -    NÃO deve mostrar: opção "Configurações por Participante"

-    [ ] **Verificar Menu**

     -    Deve ter: "Financeiro" → "Configuração de Taxas"
     -    Deve ter: "Financeiro" → "Relatórios de Repasse"
     -    NÃO deve ter: "Configurações por Participante"

-    [ ] **Testar Edição**
     -    Clicar em "Editar" em uma modalidade
     -    Alterar valor PIX ou Boleto
     -    Salvar
     -    Verificar: mensagem de sucesso
     -    Recarregar: verificar se mudança persistiu

### Database (Supabase)

-    [ ] **Verificar Configurações Ativas**

     ```sql
     SELECT COUNT(*) FROM configuracao_taxas_modalidade WHERE deleted_at IS NULL;
     ```

     -    Deve retornar: 6 ou mais

-    [ ] **Confirmar Remoções**

     ```sql
     -- Deve retornar 0
     SELECT COUNT(*) FROM information_schema.tables
     WHERE table_name = 'configuracao_taxas_participante';

     -- Deve retornar 0
     SELECT COUNT(*) FROM information_schema.routines
     WHERE routine_name = 'buscar_configuracao_taxa';
     ```

---

## 🟡 MÉDIA PRIORIDADE (Fazer Esta Semana)

### Testes de Integração

-    [ ] **Simular Pagamento Completo**

     1.   Criar agendamento de aula
     2.   Gerar solicitação de pagamento
     3.   Confirmar pagamento via webhook
     4.   Verificar: cálculo de repasse no relatório
     5.   Confirmar: valor correto baseado na modalidade

-    [ ] **Testar Diferentes Modalidades**

     -    [ ] Aula Particular (1 aluno)
     -    [ ] Aula em Grupo (2-4 alunos)
     -    [ ] Aula Pré-Prova (específica)
     -    [ ] Contrato Mensal
     -    Verificar: cada uma calcula taxa corretamente

-    [ ] **Testar PIX e Boleto**
     -    [ ] Pagamento PIX: aplicar taxa PIX configurada
     -    [ ] Pagamento Boleto: aplicar taxa Boleto configurada
     -    Verificar: cálculos independentes e corretos

### Logs e Monitoramento

-    [ ] **Verificar Console do Browser**

     -    Abrir: DevTools (F12)
     -    Navegar: páginas de configuração
     -    Verificar: 0 erros no console
     -    Verificar: 0 warnings relacionados a taxas

-    [ ] **Verificar Logs da API**

     ```bash
     # Se usando PM2
     pm2 logs cci-ca-api

     # Se usando terminal direto
     # Verificar output do servidor
     ```

     -    Procurar: erros relacionados a `configuracao_taxas`
     -    Procurar: erros de `buscar_configuracao_taxa`
     -    Deve ter: 0 erros

-    [ ] **Verificar Logs do Supabase**
     -    Acessar: Dashboard Supabase → Logs
     -    Filtrar: queries com `configuracao_taxas`
     -    Verificar: nenhuma query falhou

### Documentação

-    [ ] **Atualizar README dos Projetos**

     -    [ ] cci-ca-api/README.md
     -    [ ] cci-ca-admin/README.md
     -    Adicionar: nota sobre simplificação v2.0

-    [ ] **Criar Guia Rápido para Usuários**
     -    Como configurar taxas por modalidade
     -    Como gerar relatórios de repasse
     -    FAQ: "E se eu quiser taxa diferente por professor?"

---

## 🟢 BAIXA PRIORIDADE (Fazer Próximo Mês)

### Otimizações

-    [ ] **Adicionar Índice no Database**

     ```sql
     CREATE INDEX idx_config_modalidade_ativa
     ON configuracao_taxas_modalidade(fk_id_modalidade_aula, ativo)
     WHERE deleted_at IS NULL;
     ```

-    [ ] **Cache de Configurações**
     -    Implementar: cache Redis para configurações
     -    Duração: 15 minutos
     -    Invalidar: ao atualizar configuração

### Melhorias UX

-    [ ] **Dashboard de Taxas**

     -    Criar: página visual com cards das modalidades
     -    Mostrar: taxas PIX e Boleto lado a lado
     -    Adicionar: gráfico de evolução das taxas

-    [ ] **Calculadora de Repasse**
     -    Criar: ferramenta interativa
     -    Input: valor da aula, modalidade, forma de pagamento
     -    Output: valor líquido para o professor

### Monitoramento

-    [ ] **Configurar Alertas**

     -    Alerta: taxa zerada ou negativa
     -    Alerta: mudança de taxa > 50%
     -    Alerta: erro ao calcular repasse

-    [ ] **Dashboard de Métricas**
     -    Tempo médio de resposta dos endpoints
     -    Quantidade de configurações por modalidade
     -    Erros por tipo de requisição

---

## 🚨 RED FLAGS (Abortar se encontrar)

### ⛔ PARE TUDO E INVESTIGUE SE:

-    [ ] ❌ **Erro 500** ao acessar configurações
-    [ ] ❌ **Relatórios não carregam** ou mostram valores zerados
-    [ ] ❌ **Professores reclamam** de valores incorretos
-    [ ] ❌ **Pagamentos não processam** após a migration
-    [ ] ❌ **Logs mostram** referências a `configuracao_taxas_participante`
-    [ ] ❌ **Console mostra** erro `buscar_configuracao_taxa is not defined`

### 🆘 ROLLBACK PLAN:

Se encontrar qualquer red flag crítico:

1. **Backup Imediato:**

     ```bash
     cd cci-ca-admin
     git stash
     git checkout [commit-anterior-a-simplificacao]
     ```

2. **Restaurar Database:**

     ```sql
     -- Executar backup do schema original (se disponível)
     \i backup_configuracao_participante_schema.sql
     ```

3. **Notificar:**

     - Time de desenvolvimento
     - Stakeholders
     - Usuários afetados

4. **Investigar:**
     - Coletar logs completos
     - Reproduzir erro em ambiente local
     - Documentar issue no GitHub

---

## 📊 Critérios de Sucesso

### ✅ Migration Considerada Bem-Sucedida Se:

**Semana 1:**

-    [ ] 0 bugs críticos relacionados a taxas
-    [ ] 0 erros em produção
-    [ ] 100% dos pagamentos processados corretamente
-    [ ] Todos os relatórios geram dados corretos

**Semana 2-4:**

-    [ ] 0 reclamações de professores sobre valores
-    [ ] Tempo de resposta API < 200ms (média)
-    [ ] Feedback positivo do financeiro
-    [ ] Nenhuma necessidade de configuração por professor

**Mês 1:**

-    [ ] Redução de 50% em bugs de configuração
-    [ ] Aumento de velocidade em features financeiras
-    [ ] Sistema estável sem necessidade de rollback

---

## 📝 Notas de Execução

### Data de Início: 13/10/2025

### Responsável: Gabriel M. Guimarães

**Progresso:**

-    [x] ✅ Migration database executada
-    [x] ✅ Documentação atualizada
-    [ ] ⏳ Testes backend iniciados
-    [ ] ⏳ Testes frontend iniciados
-    [ ] ⏳ Validação com stakeholders

**Observações:**

-    Migration executada via Supabase MCP às 19:45
-    Função tinha 3 parâmetros (não 2 como documentado)
-    Sistema v2.0 ativo com 6 configurações

**Próxima Revisão:** 14/10/2025 às 10:00

---

## 🔄 Histórico de Atualizações

| Data       | Hora  | Ação                | Status |
| ---------- | ----- | ------------------- | ------ |
| 13/10/2025 | 19:45 | Migration executada | ✅     |
| 13/10/2025 | 20:00 | Documentação criada | ✅     |
| 13/10/2025 | 20:15 | Checklist criado    | ✅     |

---

**Última Atualização:** 13/10/2025 às 20:15 BRT  
**Status:** 📋 AGUARDANDO TESTES  
**Próximo Passo:** Executar testes de alta prioridade
