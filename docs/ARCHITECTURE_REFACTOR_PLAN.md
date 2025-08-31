# Plano de Refatoração Arquitetural

## Clean Architecture + Feature First

### Estrutura Proposta

```
lib/
├── core/                          # Shared/Cross-cutting concerns
│   ├── presentation/             # UI comum a todas features
│   │   ├── design_system/        # Design System (cores, tipografia, spacing)
│   │   ├── components/           # Atomic Design components
│   │   │   ├── atoms/           # Button, Input, Icon, etc.
│   │   │   ├── molecules/       # FormFields, Cards, etc.
│   │   │   ├── organisms/       # Forms, Lists, etc.
│   │   │   └── templates/       # Layout templates
│   │   ├── theme/               # App Theme
│   │   └── responsive/          # Responsive system
│   ├── domain/                   # Business rules shared
│   │   ├── entities/            # Core entities
│   │   ├── failures/            # Error types
│   │   └── validators/          # Business validation rules
│   ├── infra/                    # External integrations
│   │   ├── platform/            # Platform services
│   │   ├── network/             # HTTP client, GraphQL
│   │   ├── storage/             # Local storage
│   │   ├── cache/               # Cache management
│   │   └── external_apis/       # Third-party APIs
│   └── data/                     # Data access shared
│       ├── datasources/         # Remote/Local data sources
│       ├── models/              # Data models (DTOs)
│       └── repositories/        # Repository implementations
├── features/                     # Feature modules
│   ├── auth/
│   │   ├── presentation/        # UI layer
│   │   │   ├── pages/          # Screens
│   │   │   ├── widgets/        # Feature-specific widgets
│   │   │   └── providers/      # State management
│   │   ├── domain/             # Business logic
│   │   │   ├── entities/       # Auth entities
│   │   │   ├── repositories/   # Repository contracts
│   │   │   └── usecases/       # Use cases
│   │   ├── infra/              # External integrations
│   │   └── data/               # Data layer
│   │       ├── datasources/    # Auth API calls
│   │       ├── models/         # Auth DTOs
│   │       └── repositories/   # Repository implementation
│   ├── towers/
│   └── apartments/
└── shared/                       # Legacy compatibility (será removido)
```

### Mapeamento de Migração

#### Core atual → Nova estrutura:

- `core/theme/` → `core/presentation/design_system/`
- `core/responsive/` → `core/presentation/responsive/`
- `core/widgets/` → `core/presentation/components/`
- `core/validators/` → `core/domain/validators/`
- `core/errors/` → `core/domain/failures/`
- `core/network/` → `core/infra/network/`
- `core/storage/` → `core/infra/storage/`
- `core/cache/` → `core/infra/cache/`
- `core/platform/` → `core/infra/platform/`

#### Features já estão corretas, apenas reorganizar camadas internas

### Benefícios da Nova Arquitetura

1. **Separação Clara de Responsabilidades**
   - Presentation: UI/UX
   - Domain: Business Logic
   - Infra: External integrations  
   - Data: Data access

2. **Testabilidade**
   - Cada camada pode ser testada independentemente
   - Mocks bem definidos
   - Business logic isolada

3. **Manutenibilidade**
   - Código organizado por contexto
   - Dependencies bem definidas
   - Single Responsibility Principle

4. **Escalabilidade**
   - Fácil adicionar novas features
   - Reutilização de componentes core
   - Team scaling ready

### Regras de Dependência

- `presentation` → `domain`
- `data` → `domain` 
- `infra` → `domain`
- `domain` → nada (business rules puras)

### Próximos Passos

1. Criar nova estrutura de pastas
2. Migrar widgets para components com Atomic Design
3. Migrar theme para design_system
4. Reorganizar network, storage, cache para infra
5. Atualizar imports
6. Testar build
7. Commit refatoração