# 💼 Requisitos: Sistema de Repasses e Splits

## 📋 Visão Geral

Documento de requisitos para o sistema de distribuição automática de valores entre empresa e professores.

---

## 🎯 Requisitos Funcionais

### RF001 - Configuração de Recebedores por Modalidade

**Descrição:**  
O sistema deve permitir configurar múltiplos recebedores para cada modalidade de aula.

**Atores:** Administrador

**Regras de Negócio:**

-    Cada modalidade pode ter N recebedores (mínimo 1)
-    A soma dos percentuais deve ser exatamente 100%
-    Cada recebedor deve ter identificador único (CPF/CNPJ)
-    Recebedores podem ser do tipo "Convênio" ou "Participante"
-    Sistema deve permitir definir ordem de exibição

**Critérios de Aceite:**

-    [ ] Interface permite adicionar/remover recebedores
-    [ ] Sistema valida soma de percentuais em tempo real
-    [ ] Validação de CPF/CNPJ implementada
-    [ ] Não permite duplicação de identificadores
-    [ ] Alterações são auditadas

**Status:** ✅ Implementado

---

### RF002 - Cálculo Automático de Splits

**Descrição:**  
O sistema deve calcular automaticamente a divisão de valores quando um pagamento é confirmado.

**Atores:** Sistema (automático)

**Regras de Negócio:**

-    Cálculo baseado na configuração da modalidade
-    Arredondamento de centavos para o primeiro recebedor
-    Valores devem somar exatamente o valor total da transação
-    Cálculo aplicado apenas em pagamentos confirmados

**Exemplo:**

```
Valor Total: R$ 100,00
Recebedor 1 (Convênio): 15% = R$ 15,00
Recebedor 2 (Professor): 85% = R$ 85,00
Total: R$ 100,00 ✓
```

**Critérios de Aceite:**

-    [ ] Splits calculados automaticamente no pagamento
-    [ ] Soma dos valores = valor total (sem diferença)
-    [ ] Arredondamento tratado corretamente
-    [ ] Logs detalhados de cada cálculo

**Status:** ✅ Implementado

---

### RF003 - Resolução de Recebedor "DINAMICO"

**Descrição:**  
Quando um recebedor tem identificador "DINAMICO", o sistema deve buscar automaticamente o CPF do professor responsável pela aula.

**Atores:** Sistema (automático)

**Regras de Negócio:**

-    "DINAMICO" é substituído pelo CPF do professor
-    Professor deve ter CPF cadastrado na base
-    Se CPF não existir, transação deve falhar com erro claro
-    Substituição ocorre antes do envio para gateway de pagamento

**Fluxo:**

```
1. Sistema identifica recebedor "DINAMICO"
2. Busca professor_id do agendamento
3. Consulta CPF na tabela pessoas
4. Valida CPF encontrado
5. Substitui "DINAMICO" pelo CPF real
6. Prossegue com pagamento
```

**Critérios de Aceite:**

-    [ ] Substituição automática funcionando
-    [ ] Erro claro se professor sem CPF
-    [ ] Logs registram CPF original e substituído
-    [ ] Não permite "DINAMICO" em pagamento final

**Status:** ✅ Implementado

---

### RF004 - Visualização de Configurações

**Descrição:**  
Administradores devem visualizar facilmente as configurações de repasse de todas as modalidades.

**Atores:** Administrador

**Interface Esperada:**

-    Cards por modalidade com cores distintas
-    Lista de recebedores com percentuais
-    Indicadores visuais de status (ativo/inativo)
-    Totais calculados automaticamente

**Critérios de Aceite:**

-    [ ] Interface responsiva e intuitiva
-    [ ] Cards organizados por modalidade
-    [ ] Percentuais somados visualmente
-    [ ] Alertas para configurações inválidas

**Status:** ✅ Implementado

---

### RF005 - Edição de Configurações

**Descrição:**  
Sistema deve permitir edição fácil de configurações existentes.

**Atores:** Administrador

**Ações Permitidas:**

-    Adicionar novo recebedor
-    Remover recebedor existente
-    Alterar percentuais
-    Reordenar recebedores
-    Ativar/desativar recebedores

**Critérios de Aceite:**

-    [ ] Modal de edição funcional
-    [ ] Validações em tempo real
-    [ ] Confirmação antes de salvar
-    [ ] Rollback em caso de erro
-    [ ] Feedback visual de sucesso/erro

**Status:** ✅ Implementado

---

### RF006 - Histórico de Repasses

**Descrição:**  
Sistema deve manter histórico completo de todos os repasses realizados.

**Atores:** Administrador, Financeiro

**Informações Registradas:**

-    Data/hora do repasse
-    Modalidade da aula
-    Valor total
-    Valores por recebedor
-    Status da transação
-    Código de conciliação

**Critérios de Aceite:**

-    [ ] Tabela de auditoria implementada
-    [ ] Registros imutáveis
-    [ ] Filtros por data, modalidade, recebedor
-    [ ] Exportação para relatórios

**Status:** ⏳ Parcialmente Implementado

---

## 🔒 Requisitos Não Funcionais

### RNF001 - Performance

**Requisito:**  
Cálculo de splits deve ocorrer em menos de 1 segundo.

**Métricas:**

-    Tempo de resposta < 1s para cálculo
-    Consulta de configurações < 500ms
-    Suporte a 1000 transações/minuto

**Status:** ✅ Atendido

---

### RNF002 - Confiabilidade

**Requisito:**  
Sistema deve garantir integridade financeira em 100% das transações.

**Garantias:**

-    Soma de splits sempre = valor total (zero diferença)
-    Transações atômicas (tudo ou nada)
-    Logs completos de todas as operações
-    Backup automático de configurações

**Status:** ✅ Atendido

---

### RNF003 - Segurança

**Requisito:**  
Apenas administradores autorizados podem alterar configurações financeiras.

**Controles:**

-    Autenticação obrigatória
-    Controle de permissões (RLS)
-    Auditoria de todas as alterações
-    Logs de acesso

**Status:** ⚠️ RLS pendente no backend

---

### RNF004 - Auditabilidade

**Requisito:**  
Todas as operações financeiras devem ser rastreáveis.

**Registros:**

-    Quem fez a alteração
-    Quando foi feita
-    O que foi alterado (antes/depois)
-    Motivo da alteração (opcional)

**Status:** ✅ Implementado

---

### RNF005 - Disponibilidade

**Requisito:**  
Sistema deve estar disponível 99.5% do tempo.

**Tolerâncias:**

-    Downtime máximo: 3.6 horas/mês
-    Manutenções programadas notificadas
-    Backup automático diário
-    Recuperação de desastres < 1 hora

**Status:** ✅ Infraestrutura Supabase

---

## 🎨 Requisitos de Interface

### RUI001 - Usabilidade

**Requisitos:**

-    Interface intuitiva sem necessidade de treinamento
-    Feedback visual imediato de ações
-    Validações em tempo real
-    Mensagens de erro claras e acionáveis

**Status:** ✅ Implementado

---

### RUI002 - Responsividade

**Requisitos:**

-    Interface funcional em desktop (1920x1080)
-    Interface funcional em tablet (1024x768)
-    Interface funcional em mobile (375x667)

**Status:** ⏳ Desktop completo, mobile pendente

---

### RUI003 - Acessibilidade

**Requisitos:**

-    Contraste mínimo WCAG AA
-    Navegação por teclado completa
-    Labels descritivos para screen readers
-    Feedback sonoro opcional

**Status:** ⏳ Em desenvolvimento

---

## 📊 Requisitos de Integração

### RI001 - Integração com Gateway de Pagamento

**Requisito:**  
Sistema deve enviar splits corretos para IS Cobrança API.

**Formato Esperado:**

```json
{
     "splits": [
          {
               "numeroParticipante": "12345678900",
               "percentualParticipacao": 15.0
          },
          {
               "numeroParticipante": "98765432100",
               "percentualParticipacao": 85.0
          }
     ]
}
```

**Validações:**

-    Soma de percentuais = 100%
-    CPF/CNPJ válidos
-    Formato correto

**Status:** ✅ Implementado

---

### RI002 - Integração com Sistema de Pagamentos

**Requisito:**  
Splits devem ser calculados automaticamente quando pagamento for confirmado via webhook.

**Fluxo:**

1. Webhook recebe confirmação de pagamento
2. Sistema busca configuração da modalidade
3. Calcula splits
4. Registra na auditoria
5. Atualiza status do agendamento

**Status:** ✅ Implementado

---

## 🧪 Requisitos de Testes

### RT001 - Testes Unitários

**Cobertura Esperada:** > 80%

**Áreas Críticas:**

-    Cálculo de percentuais
-    Validação de soma = 100%
-    Substituição de "DINAMICO"
-    Arredondamento de valores

**Status:** ⏳ Parcialmente implementado

---

### RT002 - Testes de Integração

**Cenários Obrigatórios:**

-    Fluxo completo de pagamento
-    Webhook + cálculo de splits
-    Alteração de configuração + novo pagamento
-    Falha em pagamento + rollback

**Status:** ⏳ Pendente

---

## 📈 Requisitos de Monitoramento

### RM001 - Métricas

**KPIs a Monitorar:**

-    Total de splits calculados/dia
-    Tempo médio de cálculo
-    Taxa de erro em splits
-    Discrepâncias de valores

**Status:** ⏳ Pendente

---

### RM002 - Alertas

**Alertas Críticos:**

-    Erro em cálculo de split
-    Soma de percentuais ≠ 100%
-    Falha na integração com gateway
-    Professor sem CPF

**Status:** ⏳ Pendente

---

## 🚀 Roadmap de Implementação

### Fase 1 - Core (Completo) ✅

-    [x] Configuração por modalidade
-    [x] Cálculo de splits
-    [x] Interface de edição
-    [x] Validações básicas

### Fase 2 - Melhorias (Atual) ⏳

-    [ ] Testes automatizados
-    [ ] Dashboard de monitoramento
-    [ ] Relatórios avançados
-    [ ] RLS no backend

### Fase 3 - Avançado (Futuro) 📋

-    [ ] IA para sugestão de splits
-    [ ] Simulador de cenários
-    [ ] Integração com contabilidade
-    [ ] App mobile nativo

---

## 📝 Notas Técnicas

### Limitações Conhecidas

1. **Substituição de DINAMICO:** Apenas 1 recebedor dinâmico por modalidade
2. **Arredondamento:** Diferenças de centavos sempre para o primeiro recebedor
3. **Histórico:** Limitado a 12 meses na interface (dados mantidos permanentemente)

### Dependências Externas

-    IS Cobrança API (gateway)
-    Supabase (banco de dados)
-    Banco do Brasil (PIX)

---

**Última Atualização:** 21/10/2025  
**Versão:** 1.0  
**Status Geral:** 85% Completo
