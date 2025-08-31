# Terra Allwert App

## Sistema de Breakpoints Responsivos

O projeto utiliza breakpoints padronizados mundialmente (baseados em Tailwind CSS e Bootstrap):

| Breakpoint | Prefix | Minimum width | CSS equivalent                  | Uso típico           |
|------------|--------|---------------|--------------------------------|----------------------|
| Extra Small | xs    | 0px          | @media (width >= 0px)          | Mobile pequeno       |
| Small      | sm     | 640px        | @media (width >= 40rem)        | Mobile grande        |
| Medium     | md     | 768px        | @media (width >= 48rem)        | Tablet               |
| Large      | lg     | 1024px       | @media (width >= 64rem)        | Desktop              |
| Extra Large| xl     | 1280px       | @media (width >= 80rem)        | Desktop grande       |
| 2XL        | xxl    | 1536px       | @media (width >= 96rem)        | Desktop muito grande |

### Como usar os breakpoints:

```dart
// Usando a extension no contexto
final isMobile = context.isMobile; // < 768px
final isTablet = context.isTablet; // 768px - 1024px
final isDesktop = context.isDesktop; // >= 1024px

// Valores responsivos
final padding = context.responsive<double>(
  xs: 16,
  sm: 20,
  md: 24,
  lg: 32,
  xl: 40,
  xxl: 48,
);

// ResponsiveBuilder widget
ResponsiveBuilder(
  xs: MobileWidget(),
  md: TabletWidget(),
  lg: DesktopWidget(),
);
```

### Diretrizes de Design Responsivo:

1. **Mobile First**: Sempre comece pelo design mobile (xs) e adicione melhorias progressivas
2. **Conteúdo Fluido**: Use larguras máximas responsivas ao invés de valores fixos
3. **Tipografia Escalável**: Ajuste tamanhos de fonte baseados no breakpoint
4. **Espaçamento Adaptativo**: Aumente padding/margin em telas maiores
5. **Layout Flexível**: Mude de coluna única (mobile) para múltiplas colunas (desktop)

## Objetivo do Projeto

Aplicação multiplataforma (Web, iOS, Android, Desktop) para visualização e gerenciamento de torres residenciais e comerciais. Interface moderna e responsiva para consultores imobiliários apresentarem apartamentos aos clientes, com suporte offline.

## Tecnologias Principais

- **Flutter 3.x**: Framework multiplataforma
- **Dart 3.x**: Linguagem de programação
- **FVM**: Gerenciador de versões Flutter
- **Provider/Riverpod**: Gerenciamento de estado
- **GraphQL Client**: Comunicação com API
- **Hive/Isar**: Banco de dados local
- **Cached Network Image**: Cache de imagens
- **GetIt**: Injeção de dependências

## Estrutura do Projeto

```
app/
├── lib/
│   ├── core/
│   │   ├── constants/     # Constantes da aplicação
│   │   ├── themes/        # Temas e estilos
│   │   ├── utils/         # Utilitários
│   │   └── errors/        # Tratamento de erros
│   ├── data/
│   │   ├── datasources/   # Fontes de dados (API, Local)
│   │   ├── models/        # Modelos de dados
│   │   └── repositories/  # Implementação dos repositórios
│   ├── domain/
│   │   ├── entities/      # Entidades de negócio
│   │   ├── repositories/  # Contratos dos repositórios
│   │   └── usecases/      # Casos de uso
│   ├── presentation/
│   │   ├── providers/     # Providers/State management
│   │   ├── screens/       # Telas da aplicação
│   │   ├── widgets/       # Widgets reutilizáveis
│   │   └── router/        # Navegação
│   └── main.dart
├── assets/               # Imagens, fontes, etc
├── test/                 # Testes
└── web/                  # Configurações web
```

## Funcionalidades Principais

### Autenticação
- Login com email/senha
- Biometria (mobile)
- Persistência de sessão
- Auto-logout por inatividade

### Navegação de Torres
- Lista de torres com filtros
- Busca por nome/localização
- Visualização em mapa
- Informações detalhadas

### Visualização de Apartamentos
- Grid/Lista de apartamentos
- Filtros avançados (preço, quartos, área)
- Comparação lado a lado
- Favoritos

### Recursos Multimídia
- Galeria de imagens com zoom
- Player de vídeo integrado
- Tour virtual 360°
- Download para visualização offline

### Modo Offline
- Sincronização automática
- Cache inteligente de dados
- Queue de ações offline
- Indicador de status de conexão

### Apresentação para Clientes
- Modo apresentação fullscreen
- Slideshow automático
- Anotações e marcações
- Compartilhamento de materiais

## Plataformas Suportadas

### Web
- Chrome, Firefox, Safari, Edge
- Responsivo (mobile, tablet, desktop)
- PWA com instalação

### Mobile
- iOS 12+
- Android 6.0+ (API 23)
- Tablets otimizados

### Desktop
- macOS 10.14+
- Windows 10+
- Linux (Ubuntu 18.04+)

## Comandos Úteis

```bash
# Desenvolvimento
fvm flutter run

# Build Web
fvm flutter build web

# Build iOS
fvm flutter build ios

# Build Android
fvm flutter build apk

# Build macOS
fvm flutter build macos

# Testes
fvm flutter test

# Análise de código
fvm flutter analyze

# Formatação
fvm flutter format .
```

## Configuração de Ambiente

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String graphqlEndpoint = '/graphql';
  static const String wsEndpoint = 'ws://localhost:8080/ws';
}
```

## Features Offline

### Sincronização de Dados
1. Torres e estrutura básica
2. Imagens em baixa resolução
3. Plantas e documentos essenciais
4. Informações de apartamentos

### Armazenamento Local
- Hive para dados estruturados
- Cache de imagens otimizado
- Compressão de dados
- Limpeza automática de cache antigo

### Conflitos de Sincronização
- Última alteração prevalece
- Log de conflitos
- Opção de merge manual
- Backup antes de sync

## Melhorias Planejadas

1. **Performance**: Lazy loading e virtualização de listas grandes
2. **UX**: Animações e transições suaves
3. **Acessibilidade**: Suporte completo a screen readers
4. **Internacionalização**: Suporte multi-idioma
5. **Analytics**: Integração com Firebase Analytics
6. **Push Notifications**: Notificações de novos apartamentos
7. **Realidade Aumentada**: Visualização AR de plantas

## Problemas Conhecidos do Projeto Legado

- URLs hardcoded para localhost
- Credenciais MinIO expostas no código
- Função de autenticação mock
- Dependências desatualizadas
- Ausência de cache para imagens
- Rebuilds desnecessários
- Falta de testes unitários

## Design System

### Cores Principais
- Primary: #2E7D32 (Verde)
- Secondary: #FFA726 (Laranja)
- Background: #F5F5F5
- Surface: #FFFFFF
- Error: #D32F2F

### Tipografia
- Headlines: Roboto Bold
- Body: Roboto Regular
- Captions: Roboto Light

### Componentes Customizados
- Cards de apartamento
- Slider de preços
- Image carousel
- Floor selector
- Status badges

## Testes

### Cobertura Alvo
- Unit tests: 80%
- Widget tests: 60%
- Integration tests: Core flows

### Estratégia de Testes
1. Testes unitários para lógica de negócio
2. Widget tests para componentes críticos
3. Integration tests para fluxos principais
4. Golden tests para regressão visual

## Contato

Para dúvidas ou sugestões sobre este projeto, consulte a documentação completa em `/docs` ou entre em contato com a equipe de desenvolvimento.

# Anti-Over-engineering - Checklist

## Antes de Implementar Qualquer Feature
- [ ] Esta funcionalidade está na lista de essenciais do MVP?
- [ ] Esta é a solução mais simples que resolve o problema?
- [ ] Esta abstração é realmente necessária agora?
- [ ] Este padrão de design agrega valor imediato?

## RED FLAGS - Pare e Reconsidere
- Criar interfaces quando uma implementação concreta resolve
- Usar design patterns complexos sem necessidade clara
- Otimizar performance antes de medir gargalos reais
- Adicionar dependências para funcionalidades simples
- Implementar configurações complexas "para o futuro"


## Processo de Commit

1. **Questionar se quer realizar o commit**
2. **Adicionar alterações**: `git add .`
3. **Commit padronizado**: `git commit -m "tipo: descrição resumida"`

## Conventional Commits (PT-BR)

### Tipos principais:
- `feat`: nova funcionalidade
- `fix`: correção de bug
- `docs`: alterações na documentação
- `style`: formatação, sem mudança de lógica
- `refactor`: refatoração sem nova funcionalidade ou fix
- `test`: adição ou correção de testes
- `chore`: tarefas de manutenção

### Formato:
```
tipo: descrição resumida em português
```

### Exemplos:
```bash
git commit -m "feat: adiciona entrada na fila via QR code"
git commit -m "fix: corrige posição na fila em tempo real"
git commit -m "docs: atualiza README com instruções de setup"
git commit -m "refactor: simplifica lógica de notificações"
git commit -m "style: aplica formatação Elixir padrão"
git commit -m "test: adiciona testes para contexto de filas"
git commit -m "chore: atualiza dependências do Phoenix"
```

## Diretrizes para Mensagens

- **Resumido**: máximo 50 caracteres
- **Imperativo**: "adiciona" ao invés de "adicionado"
- **Português brasileiro**: linguagem clara e direta
- **Foco no valor**: o que foi implementado/corrigido
- **Sem pontuação final**: não usar ponto no final

## Commits Compostos (quando necessário)

Para mudanças maiores, usar corpo do commit:
```bash
git commit -m "feat: implementa sistema de notificações

- Adiciona worker para processar mensagens WhatsApp
- Integra RabbitMQ para fila de mensagens
- Implementa templates de notificação"
```

## Evitar

- Mensagens vagas: "atualiza código", "corrige bugs"
- Misturar tipos diferentes numa mesma alteração
- Commits muito grandes (quebrar em commits menores)
- Usar português misturado com inglês
- Ao realizar não adicionar:

`
🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: default avatarClaude <noreply@anthropic.com>
`

## Regras Freezed
SEMPRE que usar "@freezed" e "with _$" sempre use como ABSTRACT class:
- ❌ `class Tower with _$Tower {`
- ✅ `abstract class Tower with _$Tower {`

Exemplo correto:
```dart
@freezed
abstract class Tower with _$Tower {
  const factory Tower({
    required String id,
    // ...
  }) = _Tower;
  
  factory Tower.fromJson(Map<String, dynamic> json) => _$TowerFromJson(json);
}
```

## Diretrizes de Layout e Widgets

### RenderFlex e Constraints - Regras Críticas

**NUNCA faça:**
```dart
// ❌ ERRO: Expanded dentro de ScrollView
ScrollView(
  child: Column(
    children: [
      Expanded(child: widget), // RenderFlex unbounded height error
    ],
  ),
)

// ❌ ERRO: Flex sem mainAxisSize definido
Column(
  children: [...], // Vai tentar expandir infinitamente
)
```

**SEMPRE faça:**
```dart
// ✅ CORRETO: Column com mainAxisSize.min
ScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min, // Essencial!
    children: [
      widget1,
      widget2,
      // Use Flexible se precisar de comportamento flex
      Flexible(child: widget3),
    ],
  ),
)

// ✅ CORRETO: SingleChildScrollView com Column
SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: widgets,
  ),
)
```

### Sistema de Breakpoints Responsivos

Usar breakpoints mundiais padrão (Tailwind/Bootstrap):
```dart
// Breakpoints (px)
xs: 0-639     // Mobile pequeno
sm: 640-767   // Mobile grande  
md: 768-1023  // Tablet
lg: 1024-1279 // Desktop
xl: 1280-1535 // Desktop grande
xxl: 1536+    // Desktop muito grande

// Uso com context.responsive()
final padding = context.responsive<double>(
  xs: 16,
  sm: 20,
  md: 24,
  lg: 32,
  xl: 40,
  xxl: 48,
);
```

### Layouts Responsivos - Proporções

#### Telas de Autenticação
- **XS/SM**: 100% content (mobile)
- **MD**: 60% content / 40% imagem (tablet)
- **LG**: 45% content / 55% imagem (desktop)
- **XL**: 40% content / 60% imagem (desktop grande)
- **XXL**: 35% content / 65% imagem (desktop muito grande)

#### Container com Largura Máxima
```dart
// Usar ResponsiveContainer ou definir manualmente
Container(
  constraints: BoxConstraints(
    maxWidth: context.responsive<double>(
      xs: double.infinity,
      sm: 540,
      md: 720,
      lg: 960,
      xl: 1140,
      xxl: 1320,
    ),
  ),
  child: content,
)
```

### Checklist de Layout

Antes de criar qualquer layout:
- [ ] Column tem `mainAxisSize: MainAxisSize.min`?
- [ ] Não uso Expanded dentro de ScrollView?
- [ ] Layout é responsivo para todos breakpoints?
- [ ] Testei overflow em telas pequenas?
- [ ] Constraints estão bem definidos?

### Padrões de ScrollView

```dart
// ✅ Padrão correto para forms
SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min, // CRÍTICO!
        crossAxisAlignment: CrossAxisAlignment.start,
        children: formWidgets,
      ),
    ),
  ),
)

// ✅ Para listas grandes - usar ListView
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => itemWidget,
)

// ✅ Para grids - usar GridView
GridView.builder(
  gridDelegate: SliverGridDelegateWithResponsiveCrossAxisCount(),
  itemBuilder: (context, index) => itemWidget,
)
```
```