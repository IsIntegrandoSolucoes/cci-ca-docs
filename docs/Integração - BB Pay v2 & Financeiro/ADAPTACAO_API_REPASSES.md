# 🔧 Adaptação da API para Sistema de Repasses

## 📋 Objetivo

Adaptar o endpoint `POST /solicitacoes/solicitar` para respeitar o novo sistema de repasses com:

-    **Convênio fixo**: 125530 (empresa)
-    **Professor dinâmico**: Buscar do agendamento

---

## 🎯 Mudanças Necessárias

### 1. Buscar Configuração de Recebedores

Adicionar query para buscar os recebedores configurados para a modalidade:

```typescript
// Em solicitacoesService.ts

private async buscarRecebedoresPorModalidade(modalidadeId: number) {
  const { data, error } = await supabase
    .from('configuracao_recebedores')
    .select(`
      *,
      configuracao_taxas_modalidade!inner(
        fk_id_modalidade_aula
      )
    `)
    .eq('configuracao_taxas_modalidade.fk_id_modalidade_aula', modalidadeId)
    .eq('ativo', true)
    .eq('configuracao_taxas_modalidade.ativo', true)
    .order('ordem');

  if (error) {
    logger.error('[SolicitacoesService]: Erro ao buscar recebedores', { error, modalidadeId });
    throw new Error('Erro ao buscar configuração de recebedores');
  }

  if (!data || data.length === 0) {
    throw new Error(`Nenhum recebedor configurado para modalidade ${modalidadeId}`);
  }

  return data;
}
```

### 2. Buscar Número do Professor

Adicionar query para buscar o número de participante do professor:

```typescript
private async buscarNumeroProfessor(professorId: number): Promise<string> {
  const { data, error } = await supabase
    .from('pessoas')
    .select(`
      id,
      nome,
      sobrenome,
      conta_bancaria!inner(
        numero_participante
      )
    `)
    .eq('id', professorId)
    .eq('conta_bancaria.deleted_at', null)
    .single();

  if (error || !data) {
    throw new Error(`Professor ${professorId} não possui conta bancária configurada`);
  }

  if (!data.conta_bancaria[0]?.numero_participante) {
    throw new Error(`Professor ${data.nome} não possui número de participante configurado`);
  }

  return data.conta_bancaria[0].numero_participante;
}
```

### 3. Processar Splits Dinâmicos

Adicionar lógica para processar os recebedores e gerar splits:

```typescript
private async processarSplits(
  recebedores: any[],
  professorId: number,
  valorTotal: number
) {
  const splits = [];

  for (const recebedor of recebedores) {
    let numeroParticipante: string;

    if (recebedor.tipo_recebedor === 'Convenio') {
      // Convênio: usar identificador fixo
      numeroParticipante = recebedor.identificador_recebedor; // Ex: "125530"

      logger.info('[SolicitacoesService]: Split Convênio', {
        numeroParticipante,
        percentual: recebedor.percentual,
        tipo: 'Convenio'
      });

    } else if (recebedor.tipo_recebedor === 'Participante') {

      if (recebedor.identificador_recebedor === 'DINAMICO') {
        // Professor dinâmico: buscar do agendamento
        numeroParticipante = await this.buscarNumeroProfessor(professorId);

        logger.info('[SolicitacoesService]: Split Professor Dinâmico', {
          professorId,
          numeroParticipante,
          percentual: recebedor.percentual,
          tipo: 'Participante DINAMICO'
        });

      } else {
        // Participante fixo: usar identificador cadastrado
        numeroParticipante = recebedor.identificador_recebedor;

        logger.info('[SolicitacoesService]: Split Participante Fixo', {
          numeroParticipante,
          percentual: recebedor.percentual,
          tipo: 'Participante FIXO'
        });
      }

    } else {
      throw new Error(`Tipo de recebedor desconhecido: ${recebedor.tipo_recebedor}`);
    }

    // Validar número de participante
    if (!numeroParticipante || numeroParticipante === 'DINAMICO') {
      throw new Error('Número de participante inválido para split');
    }

    const valorParticipacao = (valorTotal * parseFloat(recebedor.percentual)) / 100;

    splits.push({
      numeroParticipante,
      percentualParticipacao: parseFloat(recebedor.percentual),
      valorParticipacao,
      ordem: recebedor.ordem,
      tipo: recebedor.tipo_recebedor
    });
  }

  // Validar soma dos percentuais
  const somaPercentuais = splits.reduce((acc, s) => acc + s.percentualParticipacao, 0);
  if (Math.abs(somaPercentuais - 100) > 0.01) {
    throw new Error(`Soma dos percentuais deve ser 100%. Atual: ${somaPercentuais}%`);
  }

  return splits;
}
```

### 4. Integrar no Método criarSolicitacao

Modificar o método `criarSolicitacao` para incluir os splits:

```typescript
async criarSolicitacao(data: any): Promise<ISolicitacaoCobrancaResponse> {
  try {
    logger.info('[SolicitacoesService]: Criando nova solicitação', { data });

    // ... código existente de validações ...

    // NOVO: Se houver agendamento, buscar splits dinâmicos
    let participantes: any[] | undefined = undefined;

    if (data.fk_id_agendamento_professor) {
      // Buscar agendamento para obter modalidade e professor
      const { data: agendamento } = await supabase
        .from('agendamentos_professores')
        .select('id, fk_id_professor, fk_id_modalidade_aula')
        .eq('id', data.fk_id_agendamento_professor)
        .single();

      if (!agendamento) {
        throw new Error('Agendamento não encontrado');
      }

      // Buscar configuração de recebedores
      const recebedores = await this.buscarRecebedoresPorModalidade(
        agendamento.fk_id_modalidade_aula
      );

      // Processar splits
      const splits = await this.processarSplits(
        recebedores,
        agendamento.fk_id_professor,
        data.valor
      );

      // Converter para formato do BB
      participantes = splits.map(s => ({
        numeroParticipante: s.numeroParticipante,
        percentualParticipacao: s.percentualParticipacao
      }));

      logger.info('[SolicitacoesService]: Splits gerados', {
        agendamentoId: agendamento.id,
        splits: participantes
      });
    }

    // Montar payload para o BB
    const payload: ISolicitacaoCobrancaPayload = {
      geral: {
        // ... dados gerais ...
        valorSolicitacao: data.valor
      },
      // ... outros campos ...

      // NOVO: Incluir participantes no payload
      ...(participantes && { participantes })
    };

    // Enviar para serviço de cobrança
    const response = await this.cobrancaIntegracaoService.criarSolicitacao(payload);

    // Salvar no banco com splits
    await this.solicitacoesRepository.criar({
      numero_solicitacao: response.numeroSolicitacao,
      descricao_solicitacao: data.descricao,
      valor_solicitacao: data.valor,
      url_solicitacao: response.urlSolicitacao,
      fk_id_agendamento_aluno: data.fk_id_agendamento_aluno,
      // NOVO: Salvar informações dos splits
      metadata: {
        splits: participantes,
        modalidade_id: agendamento?.fk_id_modalidade_aula,
        professor_id: agendamento?.fk_id_professor
      }
    });

    return response;

  } catch (error) {
    logger.error('[SolicitacoesService]: Erro ao criar solicitação', { error });
    throw error;
  }
}
```

---

## 🗄️ Alteração no Schema (Opcional)

Para auditoria, adicionar coluna JSON para armazenar os splits:

```sql
-- Adicionar coluna para armazenar splits (opcional, para auditoria)
ALTER TABLE solicitacoes
ADD COLUMN splits_aplicados JSONB;

COMMENT ON COLUMN solicitacoes.splits_aplicados IS
'JSON contendo os splits aplicados na solicitação: [{ numeroParticipante, percentual, tipo }]';
```

---

## 📊 Exemplo de Uso

### Request:

```json
POST /solicitacoes/solicitar

{
  "descricao": "Aula Particular - Matemática",
  "valor": 100.00,
  "fk_id_agendamento_professor": 123,
  "fk_id_agendamento_aluno": 456,
  "dados_devedor": {
    "tipoDocumento": 1,
    "numeroDocumento": "12345678900",
    "email": "aluno@example.com"
  },
  "formasPagamento": ["PIX"]
}
```

### Processing:

```typescript
1. Buscar agendamento 123 → Professor ID: 789, Modalidade: 1 (Aula Particular)
2. Buscar recebedores da modalidade 1:
   - Convênio: 125530 (15%)
   - Participante DINAMICO (85%)
3. Buscar número do professor 789 → "54321"
4. Gerar splits:
   - 125530: R$ 15,00 (15%)
   - 54321: R$ 85,00 (85%)
```

### Response:

```json
{
     "success": true,
     "data": {
          "numeroSolicitacao": 789456123,
          "urlSolicitacao": "https://cobranca.bb.com.br/...",
          "qrCode": "00020126580014...",
          "splits": [
               {
                    "numeroParticipante": "125530",
                    "percentualParticipacao": 15.0,
                    "valorParticipacao": 15.0,
                    "tipo": "Convenio"
               },
               {
                    "numeroParticipante": "54321",
                    "percentualParticipacao": 85.0,
                    "valorParticipacao": 85.0,
                    "tipo": "Participante"
               }
          ]
     }
}
```

---

## ✅ Validações a Implementar

```typescript
// 1. Validar professor tem conta bancária
if (!professorNumero) {
     throw new Error('Professor não possui conta bancária configurada');
}

// 2. Validar soma de percentuais = 100%
const soma = splits.reduce((acc, s) => acc + s.percentual, 0);
if (Math.abs(soma - 100) > 0.01) {
     throw new Error('Soma dos percentuais deve ser 100%');
}

// 3. Validar número de participante válido
if (!numeroParticipante || numeroParticipante === 'DINAMICO') {
     throw new Error('Número de participante inválido');
}

// 4. Validar modalidade tem configuração ativa
if (!recebedores || recebedores.length === 0) {
     throw new Error('Modalidade sem configuração de recebedores');
}
```

---

## 🧪 Testes

```typescript
describe('Splits de Repasse', () => {
     it('Deve gerar split com convênio fixo e professor dinâmico', async () => {
          const splits = await service.processarSplits(recebedores, professorId, 100);

          expect(splits).toHaveLength(2);
          expect(splits[0].numeroParticipante).toBe('125530');
          expect(splits[0].percentualParticipacao).toBe(15);
          expect(splits[1].numeroParticipante).toBe('54321');
          expect(splits[1].percentualParticipacao).toBe(85);
     });

     it('Deve falhar se professor não tem conta bancária', async () => {
          await expect(service.buscarNumeroProfessor(999)).rejects.toThrow('não possui conta bancária');
     });

     it('Deve falhar se soma de percentuais != 100%', async () => {
          const recebedoresInvalidos = [{ percentual: 40 }, { percentual: 50 }];

          await expect(service.processarSplits(recebedoresInvalidos, 1, 100)).rejects.toThrow('Soma dos percentuais deve ser 100%');
     });
});
```

---

## 📈 Logs e Monitoramento

```typescript
// Adicionar logs detalhados para auditoria
logger.info('[SolicitacoesService]: Splits processados', {
     agendamentoId,
     modalidadeId,
     professorId,
     valorTotal,
     splits: splits.map((s) => ({
          participante: s.numeroParticipante,
          percentual: s.percentualParticipacao,
          valor: s.valorParticipacao,
          tipo: s.tipo,
     })),
});
```

---

## 🔐 Segurança

1. **Validar acesso**: Usuário pode criar solicitação para este agendamento?
2. **Audit log**: Registrar quem criou e quando
3. **Idempotência**: Evitar duplicação de solicitações
4. **Rate limiting**: Limitar requisições por usuário/IP

---

**Status**: 📝 PROPOSTA DE IMPLEMENTAÇÃO  
**Próximo passo**: Implementar e testar
