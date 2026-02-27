---
name: testes-playwright
description: Guia para execução e criação de testes E2E com Playwright. Use para automatizar testes e interações no navegador.
---

# Skill de Testes E2E com Playwright

Esta skill orienta o uso do Playwright para testes End-to-End (E2E) e automação de navegador via MCP.

> ⚠️ **IMPORTANTE: NÃO INSTALE O PLAYWRIGHT** O Playwright já está configurado no projeto e via MCP. **NÃO execute** `npm install playwright` ou `npx playwright install` a menos que explicitamente solicitado após um erro de binário ausente. Use as ferramentas MCP (`browser_*`) ou os scripts definidos no `package.json`.

## 🛠️ Ferramentas MCP (Uso via Chat/Agente)

Use estas ferramentas para interagir com o navegador durante sua sessão de desenvolvimento ou para "testar manualmente" via IA.

- `browser_navigate`: Ir para URL (ex: `http://localhost:3000`).
- `browser_click` / `browser_fill_form`: Interagir com a página.
- `browser_screenshot`: Capturar tela para validar visualmente.
- `browser_snapshot`: **Melhor opção** para entender a acessibilidade e estrutura da página antes de interagir.

