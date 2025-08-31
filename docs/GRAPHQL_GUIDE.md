# Guia de Uso da API GraphQL - Terra Allwert

## 📖 Índice

1. [Introdução](#introdução)
2. [Configuração Inicial](#configuração-inicial)
3. [Autenticação](#autenticação)
4. [Operações Básicas](#operações-básicas)
5. [Gestão de Torres](#gestão-de-torres)
6. [Gestão de Apartamentos](#gestão-de-apartamentos)
7. [Galeria de Imagens](#galeria-de-imagens)
8. [Upload de Arquivos](#upload-de-arquivos)
9. [Exemplos Práticos](#exemplos-práticos)
10. [Ferramentas Recomendadas](#ferramentas-recomendadas)
11. [Tratamento de Erros](#tratamento-de-erros)

---

## 🚀 Introdução

A Terra Allwert API oferece uma interface GraphQL completa para gerenciar torres residenciais e comerciais. Este guia fornece instruções detalhadas sobre como comunicar-se com a API.

### Endpoint
```
POST http://localhost:3000/graphql
```

### GraphQL Playground
```
http://localhost:3000/graphql
```

---

## ⚙️ Configuração Inicial

### 1. Verificar se a API está rodando
```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { name } } }"}'
```

### 2. Headers obrigatórios
```
Content-Type: application/json
```

### 3. Headers de autenticação (quando necessário)
```
Authorization: Bearer <jwt_token>
```

---

## 🔐 Autenticação

### Login
```graphql
mutation Login($input: LoginInput!) {
  login(input: $input) {
    token
    refreshToken
    expiresAt
    user {
      id
      email
      name
      role
      active
      lastLogin
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

**cURL Example:**
```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation Login($input: LoginInput!) { login(input: $input) { token refreshToken user { email name role } } }",
    "variables": {
      "input": {
        "email": "admin@terraallwert.com",
        "password": "admin123"
      }
    }
  }'
```

### Refresh Token
```graphql
mutation RefreshToken($refreshToken: String!) {
  refreshToken(refreshToken: $refreshToken) {
    token
    refreshToken
    expiresAt
    user {
      email
      name
      role
    }
  }
}
```

### Obter dados do usuário logado
```graphql
query Me {
  me {
    id
    email
    name
    role
    active
    lastLogin
    createdAt
    updatedAt
  }
}
```

---

## 🏢 Operações Básicas

### Listar Torres (Público)
```graphql
query GetTowers {
  towers {
    id
    name
    description
    totalApartments
    createdAt
    updatedAt
    floors {
      id
      number
      totalApartments
    }
  }
}
```

### Buscar Torre por ID
```graphql
query GetTower($id: ID!) {
  tower(id: $id) {
    id
    name
    description
    floors {
      id
      number
      apartments {
        id
        number
        status
        available
      }
    }
  }
}
```

### Listar Apartamentos
```graphql
query GetApartments($floorId: ID) {
  apartments(floorId: $floorId) {
    id
    number
    area
    bedrooms
    suites
    parkingSpots
    status
    solarPosition
    price
    available
    floor {
      number
      tower {
        name
      }
    }
  }
}
```

### Buscar Apartamentos com Filtros
```graphql
query SearchApartments($input: ApartmentSearchInput!) {
  searchApartments(input: $input) {
    id
    number
    area
    bedrooms
    suites
    price
    status
    available
    solarPosition
    floor {
      number
      tower {
        name
      }
    }
  }
}
```

**Exemplo de filtro:**
```json
{
  "input": {
    "bedrooms": 2,
    "status": "AVAILABLE",
    "priceMin": 300000,
    "priceMax": 500000,
    "limit": 10
  }
}
```

---

## 🏗️ Gestão de Torres (ADMIN apenas)

### Criar Torre
```graphql
mutation CreateTower($input: CreateTowerInput!) {
  createTower(input: $input) {
    id
    name
    description
    createdAt
  }
}
```

**Variáveis:**
```json
{
  "input": {
    "name": "Torre Executiva D",
    "description": "Torre comercial moderna com 30 andares"
  }
}
```

### Atualizar Torre
```graphql
mutation UpdateTower($input: UpdateTowerInput!) {
  updateTower(input: $input) {
    id
    name
    description
    updatedAt
  }
}
```

### Deletar Torre
```graphql
mutation DeleteTower($id: ID!) {
  deleteTower(id: $id)
}
```

### Criar Pavimento
```graphql
mutation CreateFloor($input: CreateFloorInput!) {
  createFloor(input: $input) {
    id
    number
    towerId
    createdAt
  }
}
```

**Variáveis:**
```json
{
  "input": {
    "number": "15",
    "towerId": "uuid-da-torre"
  }
}
```

---

## 🏠 Gestão de Apartamentos (ADMIN apenas)

### Criar Apartamento
```graphql
mutation CreateApartment($input: CreateApartmentInput!) {
  createApartment(input: $input) {
    id
    number
    area
    bedrooms
    suites
    parkingSpots
    status
    price
    available
  }
}
```

**Variáveis:**
```json
{
  "input": {
    "number": "D1501",
    "floorId": "uuid-do-pavimento",
    "area": "85m²",
    "bedrooms": 2,
    "suites": 1,
    "parkingSpots": 2,
    "status": "AVAILABLE",
    "solarPosition": "Norte",
    "price": 450000,
    "available": true
  }
}
```

### Atualizar Apartamento
```graphql
mutation UpdateApartment($input: UpdateApartmentInput!) {
  updateApartment(input: $input) {
    id
    number
    price
    status
    available
  }
}
```

### Status de Apartamentos
Os status disponíveis são:
- `AVAILABLE` - Disponível
- `RESERVED` - Reservado  
- `SOLD` - Vendido
- `MAINTENANCE` - Em manutenção

---

## 🖼️ Galeria de Imagens

### Listar Imagens por Rota
```graphql
query GetGalleryImages($route: String) {
  galleryImages(route: $route) {
    id
    imageUrl
    thumbnailUrl
    title
    description
    displayOrder
    route
    imageMetadata {
      fileName
      fileSize
      contentType
      width
      height
    }
    pins {
      id
      xCoord
      yCoord
      title
      description
      apartment {
        number
        status
      }
    }
  }
}
```

### Rotas Disponíveis
```graphql
query GetGalleryRoutes {
  galleryRoutes
}
```

### Criar Imagem na Galeria (ADMIN)
```graphql
mutation CreateGalleryImage($input: CreateGalleryImageInput!) {
  createGalleryImage(input: $input) {
    id
    route
    title
    description
    displayOrder
  }
}
```

### Criar Marcador Interativo (ADMIN)
```graphql
mutation CreateImagePin($input: CreateImagePinInput!) {
  createImagePin(input: $input) {
    id
    xCoord
    yCoord
    title
    description
    apartmentId
  }
}
```

**Variáveis:**
```json
{
  "input": {
    "galleryImageId": "uuid-da-imagem",
    "xCoord": 45.5,
    "yCoord": 32.8,
    "title": "Apartamento A301",
    "description": "Apartamento de 3 quartos com vista para o mar",
    "apartmentId": "uuid-do-apartamento"
  }
}
```

---

## 📁 Upload de Arquivos

### Gerar URL Assinada para Upload (ADMIN)
```graphql
query GenerateUploadUrl($fileName: String!, $contentType: String!, $folder: String!) {
  generateSignedUploadUrl(fileName: $fileName, contentType: $contentType, folder: $folder) {
    uploadUrl
    accessUrl
    expiresIn
    fields
  }
}
```

**Variáveis:**
```json
{
  "fileName": "apartamento-a301.jpg",
  "contentType": "image/jpeg", 
  "folder": "apartments"
}
```

### Fazer Upload para URL Assinada
```bash
# 1. Obter URL assinada via GraphQL
# 2. Fazer upload direto para MinIO
curl -X PUT "URL_ASSINADA" \
  -H "Content-Type: image/jpeg" \
  --data-binary @apartamento-a301.jpg
```

### Download em Lote (ADMIN)
```graphql
query GenerateBulkDownload($towerId: ID) {
  generateBulkDownload(towerId: $towerId) {
    downloadUrl
    fileName
    fileSize
    expiresIn
    createdAt
  }
}
```

---

## 👥 Gestão de Usuários (ADMIN apenas)

### Listar Usuários
```graphql
query GetUsers {
  users {
    id
    email
    name
    role
    active
    lastLogin
    createdAt
  }
}
```

### Criar Usuário
```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    id
    email
    name
    role
    active
    createdAt
  }
}
```

**Variáveis:**
```json
{
  "input": {
    "name": "Novo Usuário",
    "email": "novo@terraallwert.com",
    "password": "senha123",
    "role": "VIEWER",
    "active": true
  }
}
```

### Alterar Senha
```graphql
mutation ChangePassword($input: ChangePasswordInput!) {
  changePassword(input: $input)
}
```

---

## 💡 Exemplos Práticos

### 1. Fluxo Completo de Autenticação (JavaScript)

```javascript
class TerraAllwertAPI {
  constructor(baseUrl = 'http://localhost:3000/graphql') {
    this.baseUrl = baseUrl;
    this.token = null;
    this.refreshToken = null;
  }

  async request(query, variables = {}, requiresAuth = false) {
    const headers = {
      'Content-Type': 'application/json'
    };

    if (requiresAuth && this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        query,
        variables
      })
    });

    const result = await response.json();
    
    if (result.errors) {
      throw new Error(result.errors[0].message);
    }

    return result.data;
  }

  async login(email, password) {
    const query = `
      mutation Login($input: LoginInput!) {
        login(input: $input) {
          token
          refreshToken
          expiresAt
          user {
            id
            email
            name
            role
          }
        }
      }
    `;

    const data = await this.request(query, {
      input: { email, password }
    });

    this.token = data.login.token;
    this.refreshToken = data.login.refreshToken;
    
    return data.login;
  }

  async getTowers() {
    const query = `
      query GetTowers {
        towers {
          id
          name
          description
          totalApartments
          floors {
            id
            number
            totalApartments
          }
        }
      }
    `;

    return this.request(query);
  }

  async searchApartments(filters) {
    const query = `
      query SearchApartments($input: ApartmentSearchInput!) {
        searchApartments(input: $input) {
          id
          number
          area
          bedrooms
          price
          status
          floor {
            number
            tower {
              name
            }
          }
        }
      }
    `;

    return this.request(query, { input: filters });
  }

  async createTower(name, description) {
    const query = `
      mutation CreateTower($input: CreateTowerInput!) {
        createTower(input: $input) {
          id
          name
          description
        }
      }
    `;

    return this.request(query, {
      input: { name, description }
    }, true);
  }
}

// Uso
const api = new TerraAllwertAPI();

async function example() {
  try {
    // 1. Login
    const loginResult = await api.login('admin@terraallwert.com', 'admin123');
    console.log('Logged in as:', loginResult.user.email);

    // 2. Listar torres (público)
    const towers = await api.getTowers();
    console.log('Torres:', towers.towers);

    // 3. Buscar apartamentos
    const apartments = await api.searchApartments({
      bedrooms: 2,
      status: 'AVAILABLE',
      limit: 5
    });
    console.log('Apartamentos:', apartments.searchApartments);

    // 4. Criar nova torre (admin)
    const newTower = await api.createTower(
      'Torre Nova', 
      'Torre residencial moderna'
    );
    console.log('Nova torre:', newTower.createTower);

  } catch (error) {
    console.error('Erro:', error.message);
  }
}

example();
```

### 2. Busca Avançada de Apartamentos

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query SearchApartments($input: ApartmentSearchInput!) { searchApartments(input: $input) { id number area bedrooms suites price status solarPosition floor { number tower { name } } } }",
    "variables": {
      "input": {
        "bedrooms": 3,
        "suites": 2,
        "priceMin": 400000,
        "priceMax": 600000,
        "solarPosition": "Norte",
        "status": "AVAILABLE",
        "limit": 10,
        "offset": 0
      }
    }
  }'
```

### 3. Upload e Associação de Imagem

```bash
# 1. Gerar URL de upload
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "query": "query GenerateUploadUrl($fileName: String!, $contentType: String!, $folder: String!) { generateSignedUploadUrl(fileName: $fileName, contentType: $contentType, folder: $folder) { uploadUrl accessUrl expiresIn } }",
    "variables": {
      "fileName": "fachada-principal.jpg",
      "contentType": "image/jpeg",
      "folder": "gallery"
    }
  }'

# 2. Upload da imagem
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --data-binary @fachada-principal.jpg

# 3. Registrar na galeria
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "query": "mutation CreateGalleryImage($input: CreateGalleryImageInput!) { createGalleryImage(input: $input) { id route title } }",
    "variables": {
      "input": {
        "route": "home",
        "title": "Fachada Principal",
        "description": "Vista frontal do empreendimento",
        "displayOrder": 1
      }
    }
  }'
```

---

## 🛠️ Ferramentas Recomendadas

### 1. GraphQL Playground
- **URL**: `http://localhost:3000/graphql`
- Interface web para explorar a API
- Auto-complete e validação
- Documentação interativa

### 2. Postman/Insomnia
- Coleções de requests organizadas
- Ambientes para dev/prod
- Testes automatizados

### 3. cURL
```bash
# Template básico
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query": "QUERY_HERE", "variables": {}}'
```

### 4. Clientes GraphQL

#### Apollo Client (React/JavaScript)
```javascript
import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';

const httpLink = createHttpLink({
  uri: 'http://localhost:3000/graphql',
});

const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem('token');
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : "",
    }
  }
});

const client = new ApolloClient({
  link: authLink.concat(httpLink),
  cache: new InMemoryCache()
});
```

#### GraphQL Request (Node.js)
```javascript
import { GraphQLClient } from 'graphql-request';

const client = new GraphQLClient('http://localhost:3000/graphql', {
  headers: {
    authorization: `Bearer ${token}`,
  },
});

const query = `
  query GetTowers {
    towers {
      id
      name
      totalApartments
    }
  }
`;

const data = await client.request(query);
```

---

## ❌ Tratamento de Erros

### Tipos de Erro Comuns

#### 1. Erro de Autenticação (401)
```json
{
  "errors": [
    {
      "message": "authentication required",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ]
}
```

**Solução**: Fazer login e obter novo token.

#### 2. Erro de Autorização (403)
```json
{
  "errors": [
    {
      "message": "admin access required",
      "extensions": {
        "code": "FORBIDDEN"
      }
    }
  ]
}
```

**Solução**: Verificar se o usuário tem role ADMIN.

#### 3. Erro de Validação
```json
{
  "errors": [
    {
      "message": "Variable \"$input\" got invalid value...",
      "extensions": {
        "code": "BAD_USER_INPUT"
      }
    }
  ]
}
```

**Solução**: Verificar tipos e campos obrigatórios.

#### 4. Erro de Recurso Não Encontrado
```json
{
  "errors": [
    {
      "message": "tower not found",
      "path": ["tower"]
    }
  ]
}
```

**Solução**: Verificar se o ID existe.

### Tratamento em JavaScript
```javascript
async function handleGraphQLRequest(query, variables) {
  try {
    const response = await fetch('/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ query, variables })
    });

    const result = await response.json();

    if (result.errors) {
      // Tratar erros específicos
      for (const error of result.errors) {
        switch (error.extensions?.code) {
          case 'UNAUTHENTICATED':
            // Redirecionar para login
            window.location.href = '/login';
            break;
          case 'FORBIDDEN':
            alert('Acesso negado. Permissões insuficientes.');
            break;
          case 'BAD_USER_INPUT':
            console.error('Erro de validação:', error.message);
            break;
          default:
            console.error('Erro GraphQL:', error.message);
        }
      }
      throw new Error(result.errors[0].message);
    }

    return result.data;
  } catch (error) {
    console.error('Erro na requisição:', error);
    throw error;
  }
}
```

---

## 📋 Resumo dos Endpoints

### 🔓 Públicos (Sem autenticação)
- `towers`, `tower` - Listar/buscar torres
- `floors`, `floor` - Listar/buscar pavimentos  
- `apartments`, `apartment`, `searchApartments` - Apartamentos
- `galleryImages`, `galleryRoutes` - Galeria
- `appConfig` - Configurações
- `login`, `refreshToken` - Autenticação

### 🔒 Autenticados (Token obrigatório)
- `me` - Dados do usuário logado
- `logout` - Logout

### 👑 Apenas ADMIN (Token + role ADMIN)
- **Usuários**: `users`, `user`, `createUser`, `updateUser`, `deleteUser`, `changePassword`
- **Torres**: `createTower`, `updateTower`, `deleteTower`
- **Pavimentos**: `createFloor`, `updateFloor`, `deleteFloor`
- **Apartamentos**: `createApartment`, `updateApartment`, `deleteApartment`
- **Galeria**: `createGalleryImage`, `updateGalleryImage`, `deleteGalleryImage`
- **Uploads**: `generateSignedUploadUrl`, `generateBulkDownload`
- **Configurações**: `updateAppConfig`