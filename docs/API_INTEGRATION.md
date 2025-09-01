# API Integration - Sistema Offline-First

Este documento define as mutations e queries GraphQL necessárias para integração completa do sistema offline-first de gerenciamento de arquivos e regras de negócio da aplicação Terra Allwert.

## Visão Geral da Arquitetura

O sistema funciona com estratégia por plataforma:
- **Web**: Usa apenas URLs fornecidas pela API GraphQL
- **Mobile/Desktop**: Usa URLs da API quando online, fallback para arquivos ZIP quando offline

## 🔄 Mutations para Upload de Arquivos

### 1. Get Signed Upload URL

Obtém URL assinada para upload direto ao MinIO.

```graphql
mutation GetSignedUploadUrl($input: SignedUploadUrlInput!) {
  getSignedUploadUrl(input: $input) {
    uploadUrl
    minioPath
    expiresAt
    fileId
  }
}

input SignedUploadUrlInput {
  fileName: String!
  fileType: String!        # 'image', 'video', 'document', 'floorplan'
  contentType: String!     # 'image/jpeg', 'video/mp4', etc.
  routeId: String!
  context: FileContextInput!
}

input FileContextInput {
  # Para PinMapPresentation
  pinId: String
  coordinates: CoordinatesInput
  
  # Para FloorPlanPresentation  
  floorId: String
  floorNumber: String
  isReference: Boolean
  
  # Para ImageCarouselPresentation
  carouselId: String
  order: Int
  
  # Metadados comuns
  title: String
  description: String
  tags: [String!]
}

input CoordinatesInput {
  latitude: Float!
  longitude: Float!
}

type SignedUploadUrlResponse {
  uploadUrl: String!       # URL assinada para upload
  minioPath: String!       # Caminho final no MinIO
  expiresAt: DateTime!     # Expiração da URL
  fileId: String!          # ID único do arquivo
}
```

**TODO App Integration:**
- Implementar em `MinIOUploadService.getSignedUploadUrl()`
- Usar em `PinCacheAdapter._startBackgroundUpload()`
- Usar em `FloorPlanCacheAdapter._startBackgroundUpload()`
- Usar em `ImageCarouselCacheAdapter._startBackgroundUpload()`

### 2. Confirm File Upload

Confirma que o upload foi realizado com sucesso e salva metadados.

```graphql
mutation ConfirmFileUpload($input: ConfirmFileUploadInput!) {
  confirmFileUpload(input: $input) {
    success
    fileMetadata {
      id
      url
      downloadUrl
      thumbnailUrl
      metadata
    }
  }
}

input ConfirmFileUploadInput {
  fileId: String!
  minioPath: String!
  routeId: String!
  originalFileName: String!
  fileSize: Int!
  checksum: String!        # SHA256 checksum
  context: FileContextInput!
}

type FileMetadata {
  id: String!
  url: String!             # URL pública do arquivo
  downloadUrl: String      # URL de download (pode ser signed)
  thumbnailUrl: String     # URL da thumbnail (se aplicável)
  metadata: JSON           # Metadados específicos (dimensões, duração, etc.)
}
```

**TODO App Integration:**
- Implementar em `MinIOUploadService.confirmUpload()`
- Chamar após upload bem-sucedido em todos os cache adapters

## 📥 Queries para Download de Arquivos

### 3. Get File Download URLs

Obtém URLs de download para múltiplos arquivos.

```graphql
query GetSignedDownloadUrls($input: SignedDownloadUrlsInput!) {
  getSignedDownloadUrls(input: $input) {
    urls {
      fileId
      downloadUrl
      expiresAt
    }
  }
}

input SignedDownloadUrlsInput {
  routeId: String!
  fileIds: [String!]!
  expirationMinutes: Int = 60
}

type FileDownloadUrl {
  fileId: String!
  downloadUrl: String!
  expiresAt: DateTime!
}

type SignedDownloadUrlsResponse {
  urls: [FileDownloadUrl!]!
}
```

**TODO App Integration:**
- Implementar em `OfflineSyncService._getApiUrl()`
- Implementar em `OfflineSyncService._getBatchApiUrls()`
- Usar cache com expiração de 1 hora

## 📦 Mutations para Sincronização Offline

### 4. Request Full Sync (ZIP Download)

Solicita criação de arquivo ZIP com todos os arquivos de uma rota.

```graphql
mutation RequestFullSync($input: FullSyncInput!) {
  requestFullSync(input: $input) {
    zipUrl
    expiresAt
    totalFiles
    estimatedSize
    syncId
  }
}

input FullSyncInput {
  routeId: String!
  includeTypes: [String!]  # ['image', 'video', 'document', 'floorplan']
  compressionLevel: Int = 6
  maxFileSize: Int         # Tamanho máximo em bytes
}

type FullSyncResponse {
  zipUrl: String!          # URL para download do ZIP
  expiresAt: DateTime!     # Expiração da URL
  totalFiles: Int!         # Total de arquivos no ZIP
  estimatedSize: Int!      # Tamanho estimado em bytes
  syncId: String!          # ID da sincronização para tracking
}
```

**TODO App Integration:**
- Implementar em `OfflineSyncService.downloadAndExtractZip()`
- Implementar callback de progresso
- Armazenar ZIP em cache local para extração

### 5. Get Sync Status

Verifica status da criação do ZIP.

```graphql
query GetSyncStatus($syncId: String!) {
  getSyncStatus(syncId: $syncId) {
    status
    progress
    zipUrl
    error
    completedAt
  }
}

enum SyncStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  FAILED
  EXPIRED
}

type SyncStatusResponse {
  status: SyncStatus!
  progress: Float          # 0.0 a 1.0
  zipUrl: String          # Disponível quando COMPLETED
  error: String           # Mensagem de erro se FAILED
  completedAt: DateTime   # Timestamp de conclusão
}
```

**TODO App Integration:**
- Usar para monitorar progresso da criação do ZIP
- Implementar polling ou subscription para updates em tempo real

## 📊 Queries para Regras de Negócio

### 6. Get Route Business Data

Obtém regras de negócio e configurações de uma rota para sincronização.

```graphql
query GetRouteBusinessData($routeId: String!) {
  getRouteBusinessData(routeId: $routeId) {
    route {
      id
      name
      description
      settings
      lastModified
    }
    floors {
      id
      number
      name
      planUrl
      markers {
        id
        type
        coordinates
        data
      }
    }
    apartments {
      id
      number
      floor
      status
      specifications
      images
      videos
    }
    carousels {
      id
      title
      description
      items {
        id
        type
        url
        order
        metadata
      }
    }
    businessRules {
      pricing
      availability
      restrictions
      customFields
    }
  }
}
```

**TODO App Integration:**
- Usar para sincronização inicial de dados
- Implementar em providers Riverpod para cada feature
- Cache local com timestamp de última modificação

### 7. Update Route Business Data

Atualiza regras de negócio e configurações.

```graphql
mutation UpdateRouteBusinessData($input: RouteBusinessDataInput!) {
  updateRouteBusinessData(input: $input) {
    success
    lastModified
    conflicts {
      field
      serverValue
      clientValue
      resolution
    }
  }
}

input RouteBusinessDataInput {
  routeId: String!
  lastModified: DateTime!  # Para controle de conflitos
  
  # Dados específicos por feature
  floors: [FloorInput!]
  apartments: [ApartmentInput!]
  carousels: [CarouselInput!]
  businessRules: BusinessRulesInput
}
```

**TODO App Integration:**
- Implementar resolução de conflitos
- Usar em todos os providers para persistir mudanças
- Implementar queue offline para sincronização posterior

## 🔧 Configuração e Metadados

### 8. Get Cache Configuration

Obtém configurações de cache e limites.

```graphql
query GetCacheConfiguration {
  getCacheConfiguration {
    maxFileSize
    allowedTypes
    compressionEnabled
    thumbnailSizes
    cacheExpiration
    syncIntervals
  }
}
```

### 9. Update Sync Metadata

Atualiza timestamps e versões de sincronização.

```graphql
mutation UpdateSyncMetadata($input: SyncMetadataInput!) {
  updateSyncMetadata(input: $input) {
    success
    serverTimestamp
  }
}

input SyncMetadataInput {
  routeId: String!
  clientTimestamp: DateTime!
  syncedFiles: [String!]!
  version: String!
}
```

## 📝 Mutations para Cadastro de Presentations

### 10. Cadastro de Menus (Navigation)

Gerencia menus e navegação principal da aplicação.

```graphql
mutation CreateMenu($input: CreateMenuInput!) {
  createMenu(input: $input) {
    menu {
      id
      title
      type
      route
      icon
      order
      isActive
      permissions
      children {
        id
        title
        route
      }
    }
  }
}

mutation UpdateMenu($input: UpdateMenuInput!) {
  updateMenu(input: $input) {
    menu {
      id
      title
      type
      route
      order
      isActive
    }
  }
}

mutation DeleteMenu($menuId: String!) {
  deleteMenu(menuId: $menuId) {
    success
  }
}

input CreateMenuInput {
  title: String!
  type: MenuType!          # MAIN, SUB, ACTION
  route: String!
  icon: String
  parentId: String         # Para submenus
  order: Int!
  permissions: [String!]   # Roles que podem acessar
  metadata: JSON
}

input UpdateMenuInput {
  menuId: String!
  title: String
  route: String
  icon: String
  order: Int
  isActive: Boolean
  permissions: [String!]
  metadata: JSON
}

enum MenuType {
  MAIN          # Menu principal
  SUB           # Submenu
  ACTION        # Ação/botão
  DIVIDER       # Separador
}

query GetMenus($routeId: String!) {
  getMenus(routeId: $routeId) {
    menus {
      id
      title
      type
      route
      icon
      order
      isActive
      permissions
      children {
        id
        title
        route
        icon
        order
      }
    }
  }
}
```

**TODO App Integration:**
- Implementar provider para gerenciamento de menus
- Cache local de estrutura de navegação
- Sincronização de permissões por usuário
- Update dinâmico de menus baseado em roles

### 11. Cadastro de ImageCarouselPresentation

Gerencia carrosséis de imagens com suporte a vídeos e mapas.

```graphql
mutation CreateImageCarousel($input: CreateImageCarouselInput!) {
  createImageCarousel(input: $input) {
    carousel {
      id
      title
      description
      route
      items {
        id
        type
        url
        order
        caption
      }
      settings
      createdAt
      updatedAt
    }
  }
}

mutation UpdateImageCarousel($input: UpdateImageCarouselInput!) {
  updateImageCarousel(input: $input) {
    carousel {
      id
      title
      items {
        id
        type
        url
        order
      }
    }
  }
}

mutation AddCarouselItem($input: AddCarouselItemInput!) {
  addCarouselItem(input: $input) {
    item {
      id
      type
      url
      order
      metadata
    }
  }
}

mutation RemoveCarouselItem($carouselId: String!, $itemId: String!) {
  removeCarouselItem(carouselId: $carouselId, itemId: $itemId) {
    success
  }
}

mutation ReorderCarouselItems($input: ReorderCarouselItemsInput!) {
  reorderCarouselItems(input: $input) {
    success
    items {
      id
      order
    }
  }
}

input CreateImageCarouselInput {
  title: String!
  route: String!
  description: String
  items: [CarouselItemInput!]
  settings: CarouselSettingsInput
}

input UpdateImageCarouselInput {
  carouselId: String!
  title: String
  description: String
  settings: CarouselSettingsInput
}

input AddCarouselItemInput {
  carouselId: String!
  type: CarouselItemType!    # IMAGE, VIDEO, MAP
  fileId: String              # Para arquivos já enviados
  url: String                 # Para URLs externas
  caption: String
  order: Int!
  metadata: CarouselItemMetadataInput
}

input CarouselItemMetadataInput {
  # Para imagens
  width: Int
  height: Int
  thumbnailUrl: String
  
  # Para vídeos
  duration: Int
  posterUrl: String
  
  # Para mapas
  latitude: Float
  longitude: Float
  zoom: Int
  mapType: String           # satellite, street, hybrid
  
  # Texto overlay
  overlayText: String
  overlayPosition: String   # top-left, center, bottom-right
}

input CarouselSettingsInput {
  autoPlay: Boolean
  autoPlayInterval: Int     # em segundos
  showIndicators: Boolean
  showControls: Boolean
  enableZoom: Boolean
  enableFullscreen: Boolean
  transition: String        # slide, fade, zoom
  aspectRatio: String       # 16:9, 4:3, 1:1, etc
}

input ReorderCarouselItemsInput {
  carouselId: String!
  itemOrders: [ItemOrderInput!]!
}

input ItemOrderInput {
  itemId: String!
  order: Int!
}

enum CarouselItemType {
  IMAGE
  VIDEO
  MAP
  TEXT_OVERLAY
}

query GetImageCarousel($carouselId: String!) {
  getImageCarousel(carouselId: $carouselId) {
    carousel {
      id
      title
      description
      route
      items {
        id
        type
        url
        order
        caption
        metadata
      }
      settings
    }
  }
}
```

**TODO App Integration:**
- Integrar com `ImageCarouselCacheAdapter` para upload de mídia
- Implementar reordenação drag-and-drop
- Cache de thumbnails e posters de vídeo
- Sincronização de settings por dispositivo

### 12. Cadastro de FloorPlanPresentation

Gerencia plantas de pavimentos com marcadores e apartamentos.

```graphql
mutation CreateFloorPlan($input: CreateFloorPlanInput!) {
  createFloorPlan(input: $input) {
    floorPlan {
      id
      title
      route
      floorNumber
      description
      planImageUrl
      floors {
        id
        number
        name
        imageUrl
      }
      markers {
        id
        type
        position
      }
    }
  }
}

mutation UpdateFloorPlan($input: UpdateFloorPlanInput!) {
  updateFloorPlan(input: $input) {
    floorPlan {
      id
      title
      floors {
        id
        number
        name
      }
    }
  }
}

mutation AddFloor($input: AddFloorInput!) {
  addFloor(input: $input) {
    floor {
      id
      number
      name
      planImageUrl
      referenceImages
      apartments {
        id
        number
        status
      }
    }
  }
}

mutation AddFloorMarker($input: AddFloorMarkerInput!) {
  addFloorMarker(input: $input) {
    marker {
      id
      type
      position
      apartmentId
      metadata
    }
  }
}

mutation UpdateApartmentStatus($input: UpdateApartmentStatusInput!) {
  updateApartmentStatus(input: $input) {
    apartment {
      id
      status
      updatedAt
    }
  }
}

input CreateFloorPlanInput {
  title: String!
  route: String!
  floorNumber: String
  description: String
  floors: [FloorInput!]
}

input UpdateFloorPlanInput {
  floorPlanId: String!
  title: String
  description: String
}

input AddFloorInput {
  floorPlanId: String!
  number: String!
  name: String!
  planImageFileId: String    # ID do arquivo enviado
  referenceImageIds: [String!]
  apartments: [ApartmentInput!]
}

input ApartmentInput {
  number: String!
  status: ApartmentStatus!   # AVAILABLE, SOLD, RESERVED, BLOCKED
  area: Float
  bedrooms: Int
  bathrooms: Int
  price: Float
  sunPosition: SunPosition   # MORNING, AFTERNOON, ALL_DAY
  features: [String!]
  customFields: JSON
}

input AddFloorMarkerInput {
  floorId: String!
  type: MarkerType!          # APARTMENT, ELEVATOR, STAIRS, EMERGENCY
  position: PositionInput!
  apartmentId: String
  label: String
  color: String
  metadata: JSON
}

input PositionInput {
  x: Float!                  # Percentual da largura
  y: Float!                  # Percentual da altura
}

input UpdateApartmentStatusInput {
  apartmentId: String!
  status: ApartmentStatus!
  reason: String
  effectiveDate: DateTime
}

enum ApartmentStatus {
  AVAILABLE
  SOLD
  RESERVED
  BLOCKED
  UNDER_NEGOTIATION
}

enum MarkerType {
  APARTMENT
  ELEVATOR
  STAIRS
  EMERGENCY_EXIT
  BATHROOM
  UTILITY
  CUSTOM
}

enum SunPosition {
  NORTH
  SOUTH
  EAST
  WEST
  NORTHEAST
  NORTHWEST
  SOUTHEAST
  SOUTHWEST
  ALL_DAY
}

query GetFloorPlan($floorPlanId: String!) {
  getFloorPlan(floorPlanId: $floorPlanId) {
    floorPlan {
      id
      title
      route
      description
      floors {
        id
        number
        name
        planImageUrl
        referenceImages
        markers {
          id
          type
          position
          apartmentId
          metadata
        }
        apartments {
          id
          number
          status
          area
          bedrooms
          bathrooms
          price
          sunPosition
          features
        }
      }
    }
  }
}

query GetApartmentAvailability($floorPlanId: String!) {
  getApartmentAvailability(floorPlanId: $floorPlanId) {
    summary {
      total
      available
      sold
      reserved
      blocked
    }
    apartments {
      id
      number
      floor
      status
      lastStatusChange
    }
  }
}
```

**TODO App Integration:**
- Integrar com `FloorPlanCacheAdapter` para upload de plantas
- Implementar sistema de coordenadas para marcadores
- Cache de status de apartamentos com sync em tempo real
- Histórico de mudanças de status

### 13. Cadastro de PinMapPresentation

Gerencia mapas com pins e anotações.

```graphql
mutation CreatePinMap($input: CreatePinMapInput!) {
  createPinMap(input: $input) {
    pinMap {
      id
      title
      route
      backgroundImageUrl
      pins {
        id
        type
        position
        label
      }
    }
  }
}

mutation UpdatePinMap($input: UpdatePinMapInput!) {
  updatePinMap(input: $input) {
    pinMap {
      id
      title
      backgroundImageUrl
    }
  }
}

mutation AddPin($input: AddPinInput!) {
  addPin(input: $input) {
    pin {
      id
      type
      position
      label
      icon
      color
      metadata
    }
  }
}

mutation UpdatePin($input: UpdatePinInput!) {
  updatePin(input: $input) {
    pin {
      id
      position
      label
      metadata
    }
  }
}

mutation RemovePin($pinMapId: String!, $pinId: String!) {
  removePin(pinMapId: $pinMapId, pinId: $pinId) {
    success
  }
}

mutation AddPinAnnotation($input: AddPinAnnotationInput!) {
  addPinAnnotation(input: $input) {
    annotation {
      id
      pinId
      type
      content
      createdAt
      author
    }
  }
}

input CreatePinMapInput {
  title: String!
  route: String!
  description: String
  backgroundImageId: String   # ID do arquivo enviado
  initialZoom: Float
  centerPosition: PositionInput
  pins: [PinInput!]
}

input UpdatePinMapInput {
  pinMapId: String!
  title: String
  description: String
  backgroundImageId: String
  zoom: Float
  centerPosition: PositionInput
}

input AddPinInput {
  pinMapId: String!
  type: PinType!             # LOCATION, INFO, WARNING, CUSTOM
  position: PositionInput!
  label: String!
  description: String
  icon: String               # Nome do ícone ou emoji
  color: String              # Cor hex
  size: PinSize              # SMALL, MEDIUM, LARGE
  metadata: PinMetadataInput
}

input UpdatePinInput {
  pinId: String!
  position: PositionInput
  label: String
  description: String
  icon: String
  color: String
  size: PinSize
  metadata: PinMetadataInput
}

input PinMetadataInput {
  # Mídia anexada
  imageIds: [String!]
  videoId: String
  
  # Informações adicionais
  category: String
  tags: [String!]
  customFields: JSON
  
  # Interatividade
  clickAction: String        # URL ou ação
  tooltip: String
  infoWindow: InfoWindowInput
}

input InfoWindowInput {
  title: String
  content: String
  imageUrl: String
  actions: [ActionButtonInput!]
}

input ActionButtonInput {
  label: String!
  action: String!            # URL ou comando
  style: String              # primary, secondary, danger
}

input AddPinAnnotationInput {
  pinId: String!
  type: AnnotationType!      # TEXT, IMAGE, VIDEO, AUDIO
  content: String!           # Texto ou ID do arquivo
  visibility: Visibility     # PUBLIC, PRIVATE, TEAM
}

enum PinType {
  LOCATION
  INFO
  WARNING
  HIGHLIGHT
  CUSTOM
}

enum PinSize {
  SMALL
  MEDIUM
  LARGE
  EXTRA_LARGE
}

enum AnnotationType {
  TEXT
  IMAGE
  VIDEO
  AUDIO
  LINK
}

enum Visibility {
  PUBLIC
  PRIVATE
  TEAM
  RESTRICTED
}

query GetPinMap($pinMapId: String!) {
  getPinMap(pinMapId: $pinMapId) {
    pinMap {
      id
      title
      route
      description
      backgroundImageUrl
      zoom
      centerPosition
      pins {
        id
        type
        position
        label
        description
        icon
        color
        size
        metadata
        annotations {
          id
          type
          content
          createdAt
          author
        }
      }
    }
  }
}

query SearchPins($input: SearchPinsInput!) {
  searchPins(input: $input) {
    pins {
      id
      label
      description
      position
      pinMapId
      pinMapTitle
    }
  }
}

input SearchPinsInput {
  query: String!
  pinMapId: String
  types: [PinType!]
  tags: [String!]
  limit: Int = 20
}
```

**TODO App Integration:**
- Integrar com `PinCacheAdapter` para mídia dos pins
- Implementar drag-and-drop para reposicionamento
- Sistema de coordenadas relativas para responsividade
- Cache de anotações e sincronização em tempo real
- Busca e filtros avançados de pins

## 📱 Implementação por Plataforma

### Web Implementation TODOs:
- [ ] Implementar `OfflineSyncService._getApiUrl()` usando queries 3
- [ ] Nunca usar funcionalidades ZIP (queries 4-5)
- [ ] Cache URLs da API por 1 hora
- [ ] Fallback gracioso se API não disponível

### Mobile/Desktop Implementation TODOs:
- [ ] Implementar `OfflineSyncService._getApiUrl()` com fallback
- [ ] Implementar `OfflineSyncService.downloadAndExtractZip()` usando mutations 4
- [ ] Gerenciar estrutura de cache offline
- [ ] Implementar resolução de conflitos para dados de negócio
- [ ] Queue de sincronização para modo offline

## 🔒 Segurança e Validação

### Authentication TODOs:
- [ ] Todas as mutations/queries requerem usuário autenticado
- [ ] Validar permissões por rota (usuário tem acesso?)
- [ ] Rate limiting para uploads e downloads
- [ ] Validação de tipos de arquivo e tamanhos
- [ ] Sanitização de nomes de arquivo

### Validation TODOs:
- [ ] Checksum SHA256 obrigatório para uploads
- [ ] Validação de contexto (pinId existe? floorId válido?)
- [ ] Expiração de URLs assinadas (máximo 24h)
- [ ] Quota de storage por usuário/rota

## 🚀 Performance e Otimização

### Backend TODOs:
- [ ] Compressão de imagens automática
- [ ] Geração de thumbnails
- [ ] CDN para arquivos estáticos
- [ ] Cleanup de arquivos orfãos
- [ ] Monitoramento de uso de storage

### App TODOs:
- [ ] Implementar batch operations para múltiplos arquivos
- [ ] Progress tracking para uploads/downloads
- [ ] Retry logic com backoff exponencial
- [ ] Cleanup de cache local por idade/tamanho
- [ ] Métricas de uso offline vs online

## 📋 Status de Integração

### ✅ Implementado no App:
- Estrutura de cache local
- Adapters especializados por feature
- Contratos GraphQL definidos
- Sistema offline-first funcional

### 🔄 Pendente Backend:
- [ ] Implementar todas as mutations/queries listadas
- [ ] Sistema de signed URLs (MinIO/S3)
- [ ] Geração e delivery de arquivos ZIP
- [ ] Resolução de conflitos para dados de negócio
- [ ] Sistema de monitoramento e métricas

### 🧪 Testes Necessários:
- [ ] Upload completo Web
- [ ] Upload completo Mobile/Desktop
- [ ] Download ZIP e extração offline
- [ ] Sincronização de regras de negócio
- [ ] Resolução de conflitos
- [ ] Performance com arquivos grandes