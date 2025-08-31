# 🔐 Padrão de Autenticação - Terra Allwert API

## ✅ Padronização Implementada

### **Identificador Único: EMAIL**

A API agora utiliza **email** como identificador único para autenticação, seguindo as melhores práticas modernas:

#### **Antes (Inconsistente):**
- Campo: `username` 
- Valor: `admin`
- Problemas: Ambiguidade entre username/email

#### **Depois (Padronizado):**
- Campo: `email`
- Valor: `admin@terraallwert.com`
- Benefícios: Único, profissional, validável

---

## 🔧 Alterações Técnicas Implementadas

### 1. **GraphQL Schema**
```graphql
# ANTES
input LoginInput {
  username: String!  # ❌ Ambíguo
  password: String!
}

# DEPOIS  
input LoginInput {
  email: String!     # ✅ Claro e único
  password: String!
}
```

### 2. **Domain Entities**
```go
// ANTES
type LoginRequest struct {
    Username string `json:"username" validate:"required"`
    Password string `json:"password" validate:"required"`
}

// DEPOIS
type LoginRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required"`
}
```

### 3. **Auth Service**
```go
// ANTES
user, err := s.userRepo.GetByUsername(ctx, request.Username)

// DEPOIS  
user, err := s.userRepo.GetByEmail(ctx, request.Email)
```

### 4. **GraphQL Resolvers**
```go
// ANTES
loginRequest := &entities.LoginRequest{
    Username: input.Username,
    Password: input.Password,
}

// DEPOIS
loginRequest := &entities.LoginRequest{
    Email:    input.Email,
    Password: input.Password,
}
```

---

## 📋 Credenciais Atualizadas

### **Seeds de Desenvolvimento**
```
ADMIN:   admin@terraallwert.com / admin123
VIEWER:  viewer@terraallwert.com / viewer123  
ADMIN:   admin2@terraallwert.com / admin123
VIEWER:  demo@terraallwert.com / demo123
```

### **Exemplo de Login**
```graphql
mutation Login($input: LoginInput!) {
  login(input: $input) {
    token
    refreshToken
    user {
      id
      username
      email
      role
    }
  }
}
```

**Variáveis:**
```json
{
  "input": {
    "email": "admin@terraallwert.com",
    "password": "admin123"
  }
}
```

---

## 🛡️ Benefícios da Padronização

### **✅ Segurança**
- **Validação de email** integrada
- **Unicidade garantida** por domínio
- **Menos ataques de força bruta** (emails são mais únicos)

### **✅ Usabilidade**
- **Familiar** para usuários (padrão web)
- **Memorável** (email é conhecido)
- **Recuperação de senha** facilitada

### **✅ Manutenibilidade**
- **Código mais claro** (email vs username)
- **Validação consistente** em toda API
- **Integração** com sistemas externos facilitada

### **✅ Escalabilidade**
- **Multi-tenant ready** (emails por domínio)
- **Integração OAuth** facilitada
- **APIs externas** compatíveis

---

## 🔄 Migração e Compatibilidade

### **Quebra de Compatibilidade**
⚠️ **BREAKING CHANGE**: Clientes existentes precisam atualizar de `username` para `email`

### **Checklist de Migração para Clientes**

#### **1. Frontend/Mobile Apps**
- [ ] Alterar campo de login: `username` → `email`
- [ ] Atualizar validação de formulário
- [ ] Atualizar labels de interface (Username → Email)
- [ ] Testar fluxo completo de login

#### **2. Scripts/Automações**
- [ ] Atualizar requests GraphQL/REST
- [ ] Alterar variáveis de ambiente
- [ ] Atualizar documentação interna
- [ ] Testar scripts de deployment

#### **3. Testes Automatizados**
- [ ] Atualizar casos de teste
- [ ] Modificar fixtures de teste
- [ ] Executar suite completa de testes
- [ ] Validar integração contínua

---

## 📚 Documentação Atualizada

### **Arquivos Atualizados:**
- ✅ `docs/AUTHENTICATION.md` - Guia de autenticação
- ✅ `scripts/test_auth.sh` - Script de testes
- ✅ `src/infra/database/seeds.go` - Seeds de desenvolvimento
- ✅ Schema GraphQL e resolvers

### **Exemplos Atualizados:**
- ✅ cURL commands
- ✅ JavaScript/TypeScript examples
- ✅ GraphQL Playground queries
- ✅ Postman collections (se existirem)

---

## 🧪 Testes e Validação

### **Como Testar:**

#### **1. Compilar e Executar**
```bash
cd src
go build -o ../bin/api .
../bin/api
```

#### **2. Executar Suite de Testes**
```bash
./scripts/test_auth.sh
```

#### **3. Teste Manual via GraphQL Playground**
```
http://localhost:8080/graphql
```

#### **4. Teste de Login**
```bash
curl -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation Login($input: LoginInput!) { login(input: $input) { token user { email role } } }",
    "variables": {
      "input": {
        "email": "admin@terraallwert.com",
        "password": "admin123"
      }
    }
  }'
```

---

## 🎯 Próximos Passos

### **Implementações Futuras:**
1. **Recuperação de senha** via email
2. **Verificação de email** para novos usuários
3. **OAuth2 integration** (Google, Microsoft)
4. **Rate limiting** por email
5. **Auditoria de login** por email

### **Melhorias de Segurança:**
1. **Validação de domínio** de email
2. **Whitelist/Blacklist** de domínios
3. **2FA** via email
4. **Notificação de login** suspeito

---

**✅ Padronização concluída com sucesso!**  
**🚀 A API está pronta para uso com autenticação via email!**