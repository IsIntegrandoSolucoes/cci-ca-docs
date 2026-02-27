# Como Usar HandleChange - Guia Prático

## 🚀 Uso Rápido

### 1. Import Básico

```typescript
import { createHandleChange, trimTextParser } from '@/utils/handleChange';
```

### 2. Handler Simples

```typescript
const handleChange = createHandleChange(setState);
```

### 3. Handler com Parser (Recomendado)

```typescript
const handleNameChange = useCallback(createHandleChange(setName, trimTextParser), [setName]);
```

### 4. Para Estados Complexos

```typescript
const handleTitleChange = useCallback(
     createHandleChange((title: string) => setData((prev) => ({ ...prev, title })), trimTextParser),
     [setData],
);
```

## 📋 Parsers Mais Usados

-    **`trimTextParser`** - Remove espaços extras
-    **`phoneParser`** - Formata telefone (11) 9 9999-9999
-    **`cepParser`** - Formata CEP 12345-678
-    **`upperCaseParser`** - Converte para maiúsculo
-    **`integerParser`** - Converte para número

## 💰 Campos Monetários

```typescript
// Para valores monetários, use:
const { numeric } = currencyFormatterParser(e.target.value);
setValue(numeric);
```

## 📱 Exemplo: Formulário Pessoa

```typescript
const [person, setPerson] = useState({ name: '', phone: '', email: '' });

const handleNameChange = useCallback(
     createHandleChange((name: string) => setPerson((prev) => ({ ...prev, name })), trimTextParser),
     [setPerson],
);

const handlePhoneChange = useCallback(
     createHandleChange((phone: string) => setPerson((prev) => ({ ...prev, phone })), phoneParser),
     [setPerson],
);

return (
     <>
          <TextField
               value={person.name}
               onChange={handleNameChange}
          />
          <TextField
               value={person.phone}
               onChange={handlePhoneChange}
          />
     </>
);
```

## ⚡ Dicas Performance

1. **Sempre use `useCallback`** para memoizar handlers
2. **Prefira parsers específicos** ao invés de lógica inline
3. **Crie componentes especializados** para casos complexos

## 🔧 Parser Customizado

```typescript
const myParser = (value: string): string => {
     // Sua lógica aqui
     return value.toUpperCase().trim();
};

const handleChange = createHandleChange(setState, myParser);
```

---

**Guia Rápido**: HandleChange v1.0
