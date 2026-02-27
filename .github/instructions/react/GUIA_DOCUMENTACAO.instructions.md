# Instruções para Desenvolvimento - IS Cantina Admin

## Estrutura de Documentação

Este projeto segue um padrão específico para documentação e changelog que deve ser seguido por todos os contribuidores.

### 📁 Organização da Documentação

```
docs/                     # Documentação técnica detalhada
├── changelog/           # Registro de mudanças por data
├── *.md                # Documentação geral do sistema

prompts/                 # Instruções de uso prático
├── como-usar-*.md      # Guias específicos de funcionalidades

.github/
└── instructions/       # Este arquivo - instruções para desenvolvimento
```

### 📋 Processo para Novas Features

Quando implementar uma nova feature ou fazer alterações significativas:

#### 1. Durante o Desenvolvimento

- Implemente as funcionalidades
- Teste thoroughly
- **NÃO crie documentação ainda**

#### 2. Após Aprovação ("está tudo ok")

Apenas quando autorizado, crie:

**a) Documentação Técnica (`/docs`)**

```
docs/nome-da-feature.md
```

- Explicação técnica detalhada
- Arquitetura e design decisions
- Sem exemplos de código (apenas conceitos)

**b) Changelog (`/docs/changelog`)**

```
docs/changelog/YYYY-MM-DD-nome-da-mudanca.md
```

- Formato: `2025-06-24-atualizacao-types-services.md`
- Lista completa das alterações
- Impacto e breaking changes
- Próximos passos

**c) Guia de Uso (`/prompts`)**

```
prompts/como-usar-nome-da-feature.md
```

- Exemplos práticos de código
- Padrões de uso
- Casos de uso comuns
- Troubleshooting

**d) Instruções GitHub (`/.github/instructions`)**

```
.github/instructions/nome-da-feature-dev-guide.md
```

- Processo de desenvolvimento específico
- Configurações necessárias
- Comandos importantes

## JSDoc e Documentação **NOS ARQUIVOS**

- Inicie cada arquivo com um bloco JSDoc contendo:
     ```tsx
     /**
      * @name NomeDoComponente
      * @author Gabriel M. Guimarães | gabrielmg7
      * @description [Breve descrição funcional]
      * @param {TipoProps} props - [Descrição]
      * @returns {JSX.Element} [Descrição do retorno]
      * @package [caminho/do/arquivo]
      */
     ```
     - Para componentes importantes, crie um README.md contendo:
     - Descrição do propósito
     - Tabela de props com tipos e descrições
     - Exemplo de uso com código