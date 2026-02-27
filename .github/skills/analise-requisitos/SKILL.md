---
name: analise-requisitos
description: Guia para padronizar análise e escrita de requisitos em formato de história de usuário com foco em testabilidade, regras de negócio, permissões e validações.
---

# Skill de Análise de Requisitos

Esta skill padroniza a **análise e escrita de requisitos** em formato de **história de usuário**, facilitando a compreensão, validação e implementação com qualidade.

## 📖 Instrução Detalhada

Para a estrutura completa, template oficial e exemplos práticos, consulte: **[`analise-requisito.instructions.md`](../../instructions/analise-requisito.instructions.md)**

## 🎯 Quando usar

- Ao receber um novo requisito funcional para análise.
- Ao detalhar regras de negócio, permissões e validações.
- Ao preparar critérios de aceitação testáveis.
- Ao quebrar features grandes em histórias menores.

## 📋 Elementos-chave de uma boa análise

```
✅ Ator/perfil (quem usa)
✅ Ação desejada (verbo no infinitivo)
✅ Benefício/resultado esperado
✅ Contexto/Problema (cenário atual)
✅ Escopo (o que inclui e exclui)
✅ Regras de negócio (limites, datas, estados)
✅ Permissões (RBAC/quem pode)
✅ Dados/Campos (tipos, validações, origem)
✅ Estados e Mensagens (sucesso, erro)
✅ Critérios de Aceitação (testáveis, em Dado/Quando/Então)
✅ Dependências (tabelas, views, endpoints, impactos)
✅ DoD (Definition of Done)
```

## 🏗️ Template Padrão

Utilize o template abaixo como referência rápida. **Para a versão completa com exemplos, veja a instrução.**

```
Nome: [Nome curto e específico do requisito]

Como um: [tipo de usuário/ator relevante]

Eu quero: [ação desejada, em verbo no infinitivo]

Para que eu possa: [benefício/resultado esperado]

Contexto/Problema:
- [1-3 bullets com o cenário atual e a dor]

Escopo:
- Inclui: [o que está dentro]
- Não inclui: [o que está fora]

Regras de Negócio:
1. [regra objetiva e verificável]
2. [regra objetiva e verificável]

Permissões:
- [quem pode fazer o quê; considerar perfis/RBAC quando aplicável]

Campos/Dados (se aplicável):
- [campo] — [tipo] — [obrigatório?] — [validação] — [origem]

Estados e Mensagens (se aplicável):
- Sucesso: [o que o usuário vê/recebe]
- Erro: [principais erros e mensagens/ações]

Critérios de Aceitação:
1. Dado que [pré-condição], quando [ação], então [resultado observável].
2. Dado que [pré-condição], quando [ação], então [resultado observável].
3. [cobrir validações obrigatórias]
4. [cobrir permissão/negativa de acesso]
5. [cobrir caso de erro e recuperação]

Observações/Dependências:
- [integrações, tabelas/views, endpoints, telas relacionadas, migrações, etc.]

Definição de Pronto (DoD):
- [critérios mínimos: teste, type-check, atualização de docs/prints se necessário]
```

## 💡 Diretrizes Rápidas

| Fazer ✅ | Evitar ❌ |
|---------|---------|
| "O sistema exibe mensagem X" | "É feito um aviso" |
| "Salva o registro com status Y" | "Tudo funciona bem" |
| "Apenas perfil Admin pode deletar" | "Só admin mexe" |
| "Mínimo 3 caracteres, máximo 50" | "Validação básica" |
| "Campos obrigatórios: nome, email" | "Campos importantes" |

**Critérios de Aceitação devem ser:**
- ✅ **Testáveis** (evite "deve ser fácil/rápido/bonito")
- ✅ **Observáveis** (UI, dados persistidos, logs/auditoria, retorno de API)
- ✅ **Em formato Dado/Quando/Então** (BDD)

**Sempre cobrir:**
- ✅ Caso feliz (happy path)
- ✅ Validações de dados
- ✅ Permissão/negativa de acesso
- ✅ Pelo menos 1 caso de erro e recovery

## 📝 Exemplos de Solicitação

### Exemplo 1: Cadastro Simples

```
Crie uma história de usuário para o seguinte requisito funcional.

Contexto:
- Sistema web
- Perfil: Atendente

Requisito:
- Cadastro de Cliente: permitir cadastrar novos clientes com nome, endereço, 
  telefone e e-mail.

Regras/validações:
- Nome é obrigatório (mínimo 3 caracteres)
- E-mail deve ser válido
- Telefone deve aceitar DDD

Permissões:
- Apenas perfil Atendente e Admin

Saída:
- Escreva seguindo o template e inclua critérios de aceitação em Dado/Quando/Então.
```

### Exemplo 2: Relatório com Filtros e Exportação

```
Crie uma história de usuário para o requisito funcional abaixo e explicite 
regras de negócio, permissões, campos/filtros e mensagens.

Requisito:
- Emissão de Relatórios: gerar relatórios mensais de vendas com total de vendas, 
  produtos mais vendidos e desempenho por região.

Detalhes:
- Filtros: mês/ano (obrigatório), região (opcional), categoria (opcional)
- Exportação: PDF e CSV
- Performance: deve carregar em até 5s para até 50 mil registros

Permissões:
- Financeiro pode visualizar e exportar
- Vendas pode visualizar, mas não exportar

Saída:
- Use o template completo e inclua pelo menos 6 critérios de aceitação.
```

### Exemplo 3: Mudança Controlada

```
Refine o requisito abaixo em UMA história de usuário, destacando o que muda, 
o que não muda e impactos.

Mudança solicitada:
- Ao editar um cliente, não permitir alterar o e-mail se já existir pedido 
  associado ao cliente.

Contexto:
- Existe tela "Editar Cliente"
- Existe entidade "Pedido" relacionada ao cliente

Saída:
- Use o template e inclua mensagens de erro e recovery.
```

## 🚫 O que NÃO fazer

- ❌ Requisitos vagos ("fazer funcionar", "melhorar fluxo")
- ❌ Critérios não observáveis ("usuário fica feliz")
- ❌ Esquecer permissões e validações
- ❌ Misturar UI com lógica de negócio
- ❌ Stories muito grandes (quebrar em histórias menores)

## ✅ Checklist para Revisão

Antes de marcar uma análise como pronta, valide:

- [ ] Tem ator/perfil claro?
- [ ] Benefício (para que) está explícito?
- [ ] Todas as validações listadas?
- [ ] Permissões citadas (quem pode/não pode)?
- [ ] Impactos em tabelas/endpoints identificados?
- [ ] Tem critérios em formato Dado/Quando/Então?
- [ ] Tem caso feliz + validação + erro + recovery?
- [ ] Mensagens de erro/sucesso estão descritas?
- [ ] Dependências identificadas?

## 📚 Recursos Relacionados

- **Instruction:** [`analise-requisito.instructions.md`](../../instructions/analise-requisito.instructions.md)
- **Keep a Changelog:** [`atualizar-changelog`](../atualizar-changelog/SKILL.md)
- **MCP Supabase:** [`MCP_SUPABASE.instructions.md`](../../instructions/MCP_SUPABASE.instructions.md)
- **Padrões React:** [`PADROES_NOMENCLATURA_REACT.instructions.md`](../../instructions/PADROES_NOMENCLATURA_REACT.instructions.md)
