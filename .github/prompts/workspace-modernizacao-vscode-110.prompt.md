# Prompt: Modernização Completa de Workspace (VS Code Insiders 1.110)

## Objetivo

Você é um agente de engenharia focado em modernizar workspaces para máxima produtividade no VS Code Insiders 1.110, com ênfase em IA, multi-agente, padronização, qualidade de código e onboarding de equipe.

Aplique melhorias reais no código e na configuração, sem apenas sugerir. Trabalhe de forma incremental, validando cada etapa.

## Escopo de Modernização

1. **Workspace Multi-root**
     - Revisar/ajustar arquivo `.code-workspace`.
     - Garantir visibilidade da pasta raiz e das pastas de projeto.
     - Ajustar configurações de editor, Git, TypeScript, busca e performance para times.

2. **Tasks e Debug**
     - Separar tasks por projeto em `.vscode/tasks.json` quando apropriado.
     - Manter tasks compostas no workspace (ex.: `Dev All`, `Lint All`) para orquestração.
     - Configurar `launch.json` para debug de frontend/backend conforme stack.

3. **Padronização de Qualidade**
     - Configurar/revisar ESLint, Prettier e EditorConfig.
     - Garantir `.gitignore` e `.gitattributes` consistentes (incluindo EOL).
     - Configurar Husky + lint-staged no nível correto (mono/polirepo).

4. **Fluxo Git para Equipe**
     - Configurar template de commit (`.gitmessage`) em pt-BR.
     - Configurar hook `commit-msg` para validar padrão Conventional Commits.
     - Assegurar que regras e exemplos estejam documentados no README.

5. **Onboarding Seguro de Novos Desenvolvedores**
     - Documentar setup em novo computador usando **conta GitHub e chaves próprias**.
     - Instruir uso de `.env.example` -> `.env` sem vazar segredos.
     - Garantir instruções de acesso a org/repo e autenticação (HTTPS/SSH).

6. **Uso de IA no VS Code Insiders 1.110**
     - Organizar e reforçar uso de:
          - `copilot-instructions.md`
          - pasta `.github/instructions/`
          - pasta `.github/skills/`
          - prompts reutilizáveis em `.github/prompts/`
     - Padronizar como o time deve acionar prompts, skills e agents para tarefas recorrentes.

## Estrutura de Skills (Obrigatória)

Para cada skill em `.github/skills/<nome-da-skill>/`, aplicar a estrutura abaixo:

1. **`EXECUTABLE_SKILL.yaml` (camada executável)**
     - Descrever: `name`, `description`, `capabilities`, `inputs`, `outputs`, `entrypoint`.
     - Exigir saída estruturada e validável para automações (preferencialmente JSON).
     - Usar para tarefas com variáveis explícitas (ex.: changelog, validações, classificação).

2. **`SKILL.md` (camada normativa)**
     - Definir regras oficiais: objetivo, escopo, when-not-to-use, checklist e critérios de qualidade.
     - Esta é a fonte de verdade da skill para comportamento esperado no projeto.

3. **`RESIDUAL_MARKDOWN_SKILL.md` (camada de apoio)**
     - Manter exemplos ricos, anti-padrões, explicações e contexto arquitetural.
     - Não duplicar regras conflitantes com `SKILL.md`.

### Ordem de Prioridade de Leitura

- `EXECUTABLE_SKILL.yaml` (quando aplicável)
- `SKILL.md`
- `RESIDUAL_MARKDOWN_SKILL.md`

### Regras de Consistência entre Arquivos

- Nome da skill deve ser consistente entre os 3 arquivos.
- `description` e `scope` devem refletir o mesmo domínio.
- Categorias/termos usados no YAML devem bater com a terminologia do `SKILL.md`.
- Se houver conflito, atualizar os 3 arquivos no mesmo PR.

### Critério de Aceite para Skills

- A skill pode ser acionada por nome de forma previsível.
- Possui exemplos mínimos de entrada/saída.
- Inclui seção clara de “when not to use”.
- Produz resultado útil para revisão humana e automação.

7. **README e Documentação Operacional**
     - Atualizar README com:
          - setup rápido
          - comandos essenciais
          - tasks/debug
          - convenções de commit
          - onboarding de colegas
     - Evitar documentos redundantes; centralizar instruções principais.

## Regras de Execução

- Fazer mudanças pequenas e objetivas, mantendo estilo do projeto.
- Não introduzir ferramentas desnecessárias.
- Não quebrar compatibilidade existente.
- Não expor segredos no repositório.
- Preferir automação reprodutível sobre ajustes manuais.
- Em caso de ambiguidade, escolher a opção mais simples e sustentável.

## Checklist de Entrega

- [ ] Workspace organizado e funcional para multi-root.
- [ ] Tasks e debug funcionando por projeto e em modo composto.
- [ ] Lint/format/hooks consistentes.
- [ ] Commit em pt-BR padronizado e validado.
- [ ] README atualizado com onboarding de colega (conta/chaves próprias).
- [ ] Prompt reutilizável e instruções de IA consolidadas.

## Formato da Resposta Esperada do Agente

1. **Resumo do que foi alterado** (curto)
2. **Arquivos modificados** (lista clara)
3. **Validação executada** (lint/build/test/status)
4. **Próximos passos recomendados** (máx. 5 itens)

---

## Exemplo de Comando para uso interno do time

> “Modernize este workspace para VS Code Insiders 1.110 com foco em produtividade de equipe, IA (skills/instructions/agents), tasks/debug, qualidade de código e onboarding seguro de novos devs usando credenciais próprias.”
