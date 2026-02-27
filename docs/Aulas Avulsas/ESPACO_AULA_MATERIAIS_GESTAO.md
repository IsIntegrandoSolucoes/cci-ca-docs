# 📁 Gestão Completa de Materiais no Espaço de Aula

## 🎯 Funcionalidades Implementadas

A seção **📁 Materiais de Aula** no `ManterEspacoAula` agora possui funcionalidade completa para:

### ✅ Controle de Pastas (Assuntos e Materiais)

-    **Criar novo assunto** na disciplina
-    **Editar assunto** existente
-    **Criar nova pasta** (material) dentro de um assunto
-    **Editar pasta** (material) existente

### ✅ Gestão de Conteúdos

-    **Criar novo conteúdo** diretamente vinculado a um material
-    **Editar conteúdo** existente
-    **Vincular conteúdos** existentes a um material
-    **Desvincular conteúdos** de um material

---

## 🏗️ Arquitetura

### Componentes Envolvidos

1. **EspacoAulaHierarquiaMateriais** (principal)

     - Renderiza hierarquia de materiais
     - Gerencia estados dos modais
     - Coordena ações de CRUD

2. **Modais Integrados**:
     - `ManterAssuntoModal` - Criar/editar assuntos
     - `ManterMaterialModal` - Criar/editar materiais (pastas)
     - `ManterConteudoModal` - Criar/editar conteúdos
     - `AdicionarConteudoModal` - Escolher entre criar novo ou vincular existente
     - `VincularConteudosModal` - Vincular/desvincular conteúdos existentes

---

## 🎨 Interface do Usuário

### Botões de Ação por Nível

#### 📚 **Disciplina (Nível 1)**

-    **[+]** Adicionar Assunto
     -    Aparece ao hover
     -    Cor: Primary

#### 📂 **Assunto (Nível 2)**

-    **[+]** Adicionar Pasta (Material)
-    **[✏️]** Editar Assunto
     -    Aparecem ao hover
     -    Cor: Primary (adicionar) / Secondary (editar)

#### 📁 **Material/Pasta (Nível 3)**

-    **[+]** Adicionar Conteúdo
-    **[✏️]** Editar Pasta
-    **[🗑️]** Desvincular (se já vinculado ao espaço)
     -    Aparecem ao hover
     -    Cor: Primary (adicionar) / Secondary (editar) / Error (remover)

#### 📄 **Conteúdo (Nível 4)**

-    **[✏️]** Editar Conteúdo
     -    Aparece ao hover
     -    Cor: Secondary

---

## 🔄 Fluxo de Uso

### Criar Novo Assunto

1. Hover sobre a disciplina
2. Clicar no botão **[+]**
3. Modal `ManterAssuntoModal` abre
4. Preencher formulário
5. Salvar → Hierarquia recarrega automaticamente

### Criar Nova Pasta (Material)

1. Hover sobre o assunto
2. Clicar no botão **[+]**
3. Modal `ManterMaterialModal` abre com assunto pré-selecionado
4. Preencher formulário
5. Salvar → Hierarquia recarrega automaticamente

### Adicionar Conteúdo a uma Pasta

1. Hover sobre o material
2. Clicar no botão **[+]**
3. Modal `AdicionarConteudoModal` abre com 2 opções:
     - **Criar Novo** → Abre `ManterConteudoModal` com contexto pré-preenchido
     - **Vincular Existente** → Abre `VincularConteudosModal`
4. Concluir ação → Hierarquia recarrega automaticamente

### Editar Conteúdo

1. Hover sobre o conteúdo
2. Clicar no botão **[✏️]**
3. Modal `ManterConteudoModal` abre com dados carregados
4. Editar e salvar → Hierarquia recarrega automaticamente

---

## 🔧 Implementação Técnica

### Estados dos Modais

```typescript
const [modalManterAssunto, setModalManterAssunto] = useState<{
     open: boolean;
     assuntoId?: number;
     disciplinaId?: number;
}>({ open: false });

const [modalManterMaterial, setModalManterMaterial] = useState<{
     open: boolean;
     materialId?: number;
     assuntoId?: number;
}>({ open: false });

const [modalManterConteudo, setModalManterConteudo] = useState<{
     open: boolean;
     conteudoId?: number;
     contextInfo?: any;
}>({ open: false });

const [modalAdicionarConteudo, setModalManterConteudo] = useState<{
     open: boolean;
     materialId?: number;
}>({ open: false });

const [modalVincularConteudos, setModalVincularConteudos] = useState<{
     open: boolean;
     materialId?: number;
}>({ open: false });
```

### Integração com HierarquiaMateriaisContext

```typescript
const { refresh } = useHierarquiaMateriaisContext();

const handleModalSuccess = useCallback(() => {
     refresh(); // Recarrega hierarquia após qualquer alteração
}, [refresh]);
```

### Propagação de Contexto

Ao criar/editar conteúdo, o contexto completo é passado:

```typescript
contextInfo: {
  materialId: number,
  materialNome: string,
  assuntoId: number,
  assuntoNome: string,
  disciplinaId: number,
  disciplinaNome: string
}
```

---

## 🎯 Benefícios

✅ **Gestão Unificada**: Tudo em um único lugar  
✅ **Contexto Automático**: Hierarquia sempre preservada  
✅ **UX Intuitiva**: Botões aparecem apenas ao hover  
✅ **Feedback Imediato**: Recarregamento automático após alterações  
✅ **Reutilização**: Usa os mesmos modais da hierarquia principal  
✅ **Consistência**: Mesma experiência em todo o sistema

---

## 🚀 Próximos Passos (Opcional)

-    [ ] Drag & drop para reordenar materiais
-    [ ] Preview de conteúdos ao clicar
-    [ ] Filtros avançados na hierarquia
-    [ ] Estatísticas de uso de materiais
-    [ ] Exportar/importar estrutura de materiais

---

## 📝 Notas Técnicas

-    Todos os modais são renderizados ao final do componente
-    Estados são gerenciados localmente no `EspacoAulaHierarquiaMateriais`
-    A função `refresh()` do contexto é chamada após qualquer operação de sucesso
-    Botões de ação usam `opacity: 0` com `transition` para efeito suave ao hover
-    `stopPropagation()` é usado em todos os event handlers dos botões para evitar expandir/colapsar nós

---

**Autor**: Gabriel M. Guimarães | gabrielmg7  
**Data**: 06/10/2025  
**Versão**: 1.0
