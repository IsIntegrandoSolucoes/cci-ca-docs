# 🎯 Como Usar - API Agenda Diária

**Data**: 6 de agosto de 2025  
**Autor**: Gabriel M. Guimarães | gabrielmg7  
**Público**: Desenvolvedores Frontend e Integradores

## 🚀 **Guia Rápido de Uso**

Este guia prático mostra como integrar e usar a nova **API de Agenda Diária** do CCI-CA.

## 📋 **Pré-requisitos**

-    ✅ **CCI-CA API** rodando em `http://localhost:3000`
-    ✅ **Database** com schema de agenda atualizado
-    ✅ **Professor cadastrado** no sistema (ID conhecido)

## 🔧 **Configuração Inicial**

### **1. Verificar se API está funcionando**

```bash
curl -X GET http://localhost:3002/api/agenda/professores
```

**Resposta esperada:**

```json
{
     "success": true,
     "data": [
          {
               "id": 1,
               "nome": "Professor Teste",
               "templatesAtivos": 0,
               "proximasAulas": 0
          }
     ]
}
```

## 📅 **Fluxo Básico de Uso**

### **Passo 1: Criar Template Recorrente**

Crie um template para aulas semanais:

```javascript
const template = {
     fkIdProfessor: 1,
     fkIdDisciplina: 1,
     fkIdModalidadeAula: 1,
     tituloTemplate: 'Matemática - Segunda-feira',
     descricaoTemplate: 'Aulas regulares de matemática',
     diaSemana: 1, // 1 = Segunda-feira
     horarioInicio: '08:00',
     horarioFim: '09:00',
     vagasPorSessao: 5,
     valorPorVaga: 75.0,
     aceitaGrupo: true,
     dataInicio: '2025-08-01',
     dataFim: '2025-12-31',
     ativo: true,
     pausado: false,
};

const response = await fetch('http://localhost:3002/api/agenda/templates', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify(template),
});

const resultado = await response.json();
console.log('Template criado:', resultado.data.id);
```

### **Passo 2: Gerar Agenda Automática**

Use um template para gerar agendamentos (o serviço resolve o professor a partir do template e delega à função SQL):

```javascript
const gerarAgenda = {
     templateId: 10,
     dataInicio: '2025-08-01',
     dataFim: '2025-08-31',
     // Compatibilidade: ambos aceitos
     sobrescrever: false,
     sobrescreverExistentes: false,
};

const response = await fetch('http://localhost:3002/api/agenda/gerar', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify(gerarAgenda),
});

const resultado = await response.json();
console.log(`${resultado.agendamentosCriados} agendamentos criados!`);
```

### **Passo 3: Consultar Agenda Diária**

Veja a agenda de um dia específico:

```javascript
const professorId = 1;
const data = '2025-08-05'; // Segunda-feira

const response = await fetch(`http://localhost:3000/api/agenda/diaria/${professorId}/${data}`);
const agenda = await response.json();

console.log(`Agenda do dia ${data}:`);
agenda.data.forEach((slot) => {
     console.log(`${slot.slotHorarioInicio}-${slot.slotHorarioFim}: ${slot.status}`);
     const vagasTotal = (slot.vagasDisponiveis ?? 0) + (slot.vagasOcupadas ?? 0);
     console.log(`  Vagas: ${slot.vagasDisponiveis}/${vagasTotal}`);
});
```

## 🚫 **Gerenciando Exceções**

### **Bloquear Feriado**

```javascript
const feriado = {
     fkIdProfessor: 1,
     dataInicio: '2025-09-07', // Independência
     dataFim: '2025-09-07',
     horarioInicio: '00:00',
     horarioFim: '23:59',
     tipoExcecao: 'feriado',
     motivo: 'Dia da Independência',
     bloqueiaAgendamentos: true,
};

await fetch('http://localhost:3000/api/agenda/excecoes', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify(feriado),
});
```

### **Bloquear Férias**

```javascript
const ferias = {
     fkIdProfessor: 1,
     dataInicio: '2025-12-20',
     dataFim: '2026-01-15',
     tipoExcecao: 'ferias',
     motivo: 'Férias de fim de ano',
     bloqueiaAgendamentos: true,
};

await fetch('http://localhost:3000/api/agenda/excecoes', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify(ferias),
});
```

## 📊 **Obtendo Estatísticas**

```javascript
const response = await fetch(`http://localhost:3000/api/agenda/estatisticas/1`);
const stats = await response.json();

console.log('Estatísticas do Professor:');
console.log(`- Total de slots: ${stats.data.totalSlots}`);
console.log(`- Slots ativos: ${stats.data.slotsAtivos}`);
console.log(`- Agendamentos hoje: ${stats.data.agendamentosHoje}`);
console.log(`- Templates ativos: ${stats.data.templatesAtivos}`);
console.log(`- Receita estimada: R$ ${stats.data.receitaEstimada}`);
```

## 🔄 **Casos de Uso Comuns**

### **Calendário Semanal**

```javascript
async function obterSemanaProfessor(professorId, dataInicio) {
     const semana = [];

     for (let i = 0; i < 7; i++) {
          const data = new Date(dataInicio);
          data.setDate(data.getDate() + i);

          const dataStr = data.toISOString().split('T')[0];
          const response = await fetch(`http://localhost:3000/api/agenda/diaria/${professorId}/${dataStr}`);
          const agenda = await response.json();

          semana.push({
               data: dataStr,
               slots: agenda.data,
          });
     }

     return semana;
}
```

### **Filtrar Slots Disponíveis**

```javascript
async function slotsDisponiveis(professorId, data) {
     const response = await fetch(`http://localhost:3000/api/agenda/diaria/${professorId}/${data}`);
     const agenda = await response.json();
     return agenda.data.filter((slot) => slot.vagasLivres > 0);
}
```

### **Pausar Template Temporariamente**

```javascript
// Primeiro, obter templates
const response = await fetch(`http://localhost:3000/api/agenda/templates/1`);
const templates = await response.json();

// Encontrar template e pausar
const template = templates.data.find((t) => t.tituloTemplate.includes('Segunda'));
if (template) {
     await fetch(`http://localhost:3000/api/agenda/templates/${template.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...template, pausado: true }),
     });
}
```

## 🎨 **Integração com Frontend**

### **React Hook Exemplo**

```typescript
import { useState, useEffect } from 'react';

interface AgendaSlot {
     id: number;
     slotHorarioInicio: string;
     slotHorarioFim: string;
     status: string;
     vagasDisponiveis: number;
     vagasOcupadas: number;
}

export function useAgendaProfessor(professorId: number, data: string) {
     const [agenda, setAgenda] = useState<AgendaSlot[]>([]);
     const [loading, setLoading] = useState(true);

     useEffect(() => {
          async function carregarAgenda() {
               try {
                    const response = await fetch(`/api/agenda/diaria/${professorId}/${data}`);
                    const result = await response.json();
                    setAgenda(result.data);
               } finally {
                    setLoading(false);
               }
          }

          carregarAgenda();
     }, [professorId, data]);

     return { agenda, loading };
}
```

### **Componente Calendário**

```typescript
function CalendarioAgenda({ professorId }: { professorId: number }) {
     const hoje = new Date().toISOString().split('T')[0];
     const { agenda, loading } = useAgendaProfessor(professorId, hoje);

     if (loading) return <div>Carregando...</div>;

     return (
          <div className='calendario'>
               {agenda.map((slot) => (
                    <div
                         key={slot.id}
                         className={`slot ${slot.status}`}
                    >
                         <span>
                              {slot.slotHorarioInicio} - {slot.slotHorarioFim}
                         </span>
                         <span>
                              {slot.vagasDisponiveis}/{slot.vagasDisponiveis + slot.vagasOcupadas} vagas
                         </span>
                    </div>
               ))}
          </div>
     );
}
```

## 🔍 **Debugging e Troubleshooting**

### **Verificar Logs de Erro**

```javascript
try {
     const response = await fetch('/api/agenda/templates', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(template),
     });

     if (!response.ok) {
          const error = await response.json();
          console.error('Erro na API:', error);
     }
} catch (error) {
     console.error('Erro de rede:', error);
}
```

### **Validar Dados Antes de Enviar**

```javascript
function validarTemplate(template) {
     const erros = [];

     if (!template.fkIdProfessor) erros.push('Professor é obrigatório');
     if (!template.horarioInicio) erros.push('Horário início é obrigatório');
     if (template.vagasPorSessao < 1) erros.push('Vagas deve ser >= 1');

     if (erros.length > 0) {
          throw new Error(`Validação falhou: ${erros.join(', ')}`);
     }
}
```

## 🚀 **Dicas de Performance**

### **1. Cache Local**

-    Use cache para dados que não mudam frequentemente
-    Templates e configurações podem ser cachados por 1 hora

### **2. Paginação**

-    Para períodos longos, consulte por semana/mês
-    Use filtros para reduzir dados desnecessários

### **3. Batch Operations**

-    Agrupe criação de templates similares
-    Use geração automática para períodos longos

---

## 📞 **Suporte**

**Dúvidas?** Consulte:

-    📖 `docs/API_AGENDA_DIARIA.md` - Documentação completa
-    🧪 `debug/test-agenda-api.js` - Exemplos funcionais
-    📋 `docs/changelog/2025-08-06-implementacao-api-agenda-diaria.md` - Detalhes técnicos

---

🎯 **Happy Coding!** ✨
