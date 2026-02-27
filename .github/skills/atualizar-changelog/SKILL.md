---
name: atualizar-changelog
description: Guia de padrões para manter o changelog atualizado e organizado seguindo o formato Keep a Changelog.
---

# Skill de Atualização de Changelog

Esta skill define o padrão de formato e categorias para atualização dos arquivos de changelog nos projetos AEMASUL.

## 📝 Formato Padrão

Utilize sempre o padrão [Keep a Changelog](https://keepachangelog.com/pt-BR/). Comece sempre pelo topo (versões mais recentes).

```markdown
# Changelog

## [1.0.1] - 2025-XX-XX

### Added

- Nova funcionalidade X para professores.

### Changed

- Atualizado fluxo de matrícula para considerar novos descontos.

### Fixed

- Correção de erro ao calcular juros (Issue #123).
```

## 🏷️ Categorias

Use estas categorias para agrupar as mudanças:

- **Added**: para novas funcionalidades.
- **Changed**: para alterações em funcionalidades existentes.
- **Deprecated**: para funcionalidades que serão removidas em breve.
- **Removed**: para funcionalidades removidas agora.
- **Fixed**: para qualquer correção de bug.
- **Security**: para convidar usuários a atualizar em caso de vulnerabilidades.

## 💡 Dicas de Escrita

1.   **Foco no Usuário:** Escreva "Adicionado filtro de alunos" em vez de "Criado componente FilterButton".
2.   **Links:** Sempre que possível, linke os PRs ou Issues relacionados: `(PR #42)`.
3.   **Data:** Use o formato ISO `YYYY-MM-DD`.
