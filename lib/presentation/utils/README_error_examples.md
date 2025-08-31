# Exemplos de Tratamento de Erros - ErrorHandler

## Cenários de Erro de Autenticação

### Erros de Conexão
**Erro técnico:**
```
OperationException(linkException: ServerException(originalException: ClientException: Failed to fetch, uri=http://localhost:3000/graphql))
```
**Mensagem amigável:**
```
"Não foi possível conectar ao servidor. Verifique sua conexão com a internet."
```

### Credenciais Inválidas
**Erro técnico:**
```
GraphQL error: Invalid credentials
```
**Mensagem amigável:**
```
"Email ou senha incorretos. Verifique suas credenciais e tente novamente."
```

### Usuário Não Encontrado
**Erro técnico:**
```
GraphQL error: User not found
```
**Mensagem amigável:**
```
"Usuário não encontrado. Verifique o email digitado."
```

### Muitas Tentativas (Rate Limiting)
**Erro técnico:**
```
HTTP 429: Too many requests
```
**Mensagem amigável:**
```
"Muitas tentativas de login. Aguarde alguns minutos e tente novamente."
```

### Erro de Servidor
**Erro técnico:**
```
HTTP 500: Internal Server Error
```
**Mensagem amigável:**
```
"Erro interno do servidor. Tente novamente em alguns instantes."
```

### Conta Desabilitada
**Erro técnico:**
```
GraphQL error: Account disabled
```
**Mensagem amigável:**
```
"Sua conta está desabilitada. Entre em contato com o suporte."
```

## Como Testar

1. **Teste de Conexão:**
   - Desconecte da internet
   - Tente fazer login
   - Deve mostrar: "Não foi possível conectar ao servidor..."

2. **Teste de Credenciais:**
   - Use email/senha errados
   - Deve mostrar: "Email ou senha incorretos..."

3. **Teste de Servidor Offline:**
   - Pare o servidor backend
   - Tente fazer login
   - Deve mostrar: "Não foi possível conectar ao servidor..."

## Fallback
Se nenhum padrão for reconhecido, a mensagem padrão será:
```
"Erro ao fazer login. Verifique suas credenciais e tente novamente."
```