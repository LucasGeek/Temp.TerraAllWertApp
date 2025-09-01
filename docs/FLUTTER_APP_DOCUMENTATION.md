# 📱 Flutter App Documentation - Terra Allwert
## Arquitetura Moderna com Go+GraphQL Integration

**Data:** 31 de Agosto de 2025  
**Versão:** 2.0  
**Tecnologias:** Flutter + GraphQL + MinIO Direct Upload + Offline-First  

---

## 🎯 Objetivos da Nova Arquitetura Flutter

### 1.1 Equivalência com Sistema Legado
Manter **100% das funcionalidades** da aplicação Flutter original:
- ✅ Navegação hierárquica por towers e seções
- ✅ Visualização interativa de plantas baixas
- ✅ Sistema de busca avançada de apartmentss
- ✅ Galeria de imagens com marcadores (pins)
- ✅ Sistema de upload de mídias (admin)
- ✅ Interface otimizada para tablets (landscape)

### 1.2 Melhorias Arquiteturais Críticas

#### 🚫 **NUNCA ENVIAR ARQUIVOS PARA API**
- **Upload Direto**: App conecta diretamente ao MinIO via signed URLs
- **Zero API Bottleneck**: Arquivos nunca passam pela API Go
- **Gestão de Metadados**: API apenas gerencia informações dos arquivos
- **Bulk Downloads**: Downloads automáticos de .zip files via URLs assinadas

#### 📱 **Arquitetura Offline-First**
- **Cache Local Robusto**: Todos os dados persistidos localmente
- **Sincronização Inteligente**: Sync em background quando online
- **Interface Adaptativa**: UI se adapta ao status de conectividade
- **Operações Offline**: Funcionalidade completa sem internet

#### 🔄 **GraphQL Integration**
- **Single Queries**: Uma query para múltiplos recursos relacionados
- **Type Safety**: Schemas gerados automaticamente
- **Optimistic Updates**: Updates otimistas com rollback automático
- **Real-time Updates**: Subscriptions para mudanças em tempo real

---

## 🏗️ Arquitetura da Nova Aplicação Flutter

### 2.1 Stack Tecnológica

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Frontend                         │
│  • GraphQL Client (graphql_flutter)                         │
│  • Offline Storage (drift + hive)                           │
│  • State Management (riverpod)                              │
│  • File Caching (cached_network_image)                      │
└─────────────────────┬───────────────────────────────────────┘
                      │ GraphQL Queries/Subscriptions
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 Go + GraphQL API                            │
│         (Apenas metadados e lógica de negócio)              │
└─────────────────────┬───────────────────────────────────────┘
                      │ Signed URLs Generation
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      MinIO                                   │
│  • Upload/Download direto do Flutter                        │
│  • Sem processamento pela API                               │
│  • Bulk downloads automatizados                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Estrutura de Pastas (Sugestão, mas de preferencia ao feature fist e apenas implemente melhorias)

```
lib/
├── main.dart                           # Entry point
├── app/
│   ├── app.dart                       # App configuration
│   ├── router.dart                    # Navigation router
│   └── themes/
│       ├── app_theme.dart             # Theme definition
│       └── colors.dart                # Color palette
├── core/
│   ├── config/
│   │   ├── app_config.dart            # Environment config
│   │   ├── graphql_config.dart        # GraphQL client setup
│   │   └── storage_config.dart        # Local storage setup
│   ├── constants/
│   │   ├── api_constants.dart         # API endpoints
│   │   ├── app_constants.dart         # App constants
│   │   └── storage_keys.dart          # Storage key definitions
│   ├── errors/
│   │   ├── app_exceptions.dart        # Custom exceptions
│   │   └── error_handler.dart         # Global error handling
│   ├── network/
│   │   ├── connectivity_service.dart  # Network monitoring
│   │   ├── graphql_client.dart        # GraphQL client wrapper
│   │   └── sync_service.dart          # Offline/Online sync
│   ├── storage/
│   │   ├── database/
│   │   │   ├── app_database.dart      # Drift database
│   │   │   ├── dao/                   # Data Access Objects
│   │   │   └── entities/              # Database entities
│   │   ├── cache/
│   │   │   ├── image_cache.dart       # Image cache manager
│   │   │   ├── query_cache.dart       # GraphQL query cache
│   │   │   └── file_cache.dart        # File cache manager
│   │   └── preferences/
│   │       └── app_preferences.dart   # SharedPreferences wrapper
│   └── utils/
│       ├── extensions/
│       │   ├── context_extensions.dart
│       │   ├── string_extensions.dart
│       │   └── widget_extensions.dart
│       ├── helpers/
│       │   ├── file_helper.dart       # File operations
│       │   ├── url_helper.dart        # URL utilities
│       │   └── validation_helper.dart # Input validation
│       └── formatters/
│           ├── currency_formatter.dart
│           └── date_formatter.dart
├── data/
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── graphql/
│   │   │   │   ├── queries/           # GraphQL queries
│   │   │   │   ├── mutations/         # GraphQL mutations
│   │   │   │   ├── subscriptions/     # GraphQL subscriptions
│   │   │   │   └── fragments/         # GraphQL fragments
│   │   │   ├── tower_remote_datasource.dart
│   │   │   ├── apartments_remote_datasource.dart
│   │   │   └── gallery_remote_datasource.dart
│   │   ├── local/
│   │   │   ├── tower_local_datasource.dart
│   │   │   ├── apartments_local_datasource.dart
│   │   │   └── gallery_local_datasource.dart
│   │   └── minio/
│   │       ├── minio_datasource.dart  # Direct MinIO operations
│   │       └── signed_url_service.dart
│   ├── models/
│   │   ├── dto/                       # Data Transfer Objects
│   │   │   ├── tower_dto.dart
│   │   │   ├── apartments_dto.dart
│   │   │   └── gallery_dto.dart
│   │   ├── entities/                  # Domain entities
│   │   │   ├── tower_entity.dart
│   │   │   └── apartments_entity.dart
│   │   └── mappers/                   # DTO <-> Entity mappers
│   │       ├── tower_mapper.dart
│   │       └── apartments_mapper.dart
│   └── repositories/
│       ├── tower_repository_impl.dart
│       ├── apartments_repository_impl.dart
│       ├── gallery_repository_impl.dart
│       └── sync_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── tower.dart
│   │   ├── pavimento.dart
│   │   ├── apartments.dart
│   │   ├── gallery_image.dart
│   │   ├── image_pin.dart
│   │   └── bulk_download.dart
│   ├── repositories/                   # Abstract repositories
│   │   ├── tower_repository.dart
│   │   ├── apartments_repository.dart
│   │   ├── gallery_repository.dart
│   │   └── sync_repository.dart
│   └── usecases/
│       ├── tower/
│       │   ├── get_towers_usecase.dart
│       │   ├── create_tower_usecase.dart
│       │   └── sync_towers_usecase.dart
│       ├── apartments/
│       │   ├── search_apartmentss_usecase.dart
│       │   ├── get_apartments_details_usecase.dart
│       │   └── update_apartment_usecase.dart       # atualizar apartments
│       ├── gallery/                        # casos de uso de galeria
│       │   ├── get_gallery_images_usecase.dart     # obter imagens da galeria
│       │   ├── upload_image_usecase.dart           # upload de imagem
│       │   └── create_image_pin_usecase.dart       # criar marcador de imagem
│       └── sync/                           # casos de uso de sincronização
│           ├── sync_all_data_usecase.dart          # sincronizar todos os dados
│           ├── sync_tower_data_usecase.dart        # sincronizar dados da tower
│           └── bulk_download_usecase.dart          # download em lote
├── presentation/
│   ├── providers/                          # provedores Riverpod
│   │   ├── auth_provider.dart              # provedor de autenticação
│   │   ├── connectivity_provider.dart      # provedor de conectividade
│   │   ├── tower_provider.dart             # provedor de towers
│   │   ├── apartment_provider.dart         # provedor de apartmentss
│   │   ├── gallery_provider.dart           # provedor de galeria
│   │   └── sync_provider.dart              # provedor de sincronização
│   ├── screens/
│   │   ├── splash/
│   │   │   ├── splash_screen.dart
│   │   │   └── splash_controller.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── login_controller.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── home_controller.dart
│   │   │   └── widgets/
│   │   │       ├── menu_drawer.dart
│   │   │       ├── status_bar.dart
│   │   │       └── sync_indicator.dart
│   │   ├── towers/                         # telas de towers
│   │   │   ├── towers_list_screen.dart     # tela de lista de towers
│   │   │   ├── tower_detail_screen.dart    # tela de detalhes da tower
│   │   │   └── widgets/
│   │   │       ├── tower_card.dart         # card da tower
│   │   │       └── floor_list.dart         # lista de pavimentos
│   │   ├── floors/                         # telas de pavimentos
│   │   │   ├── floor_screen.dart           # tela do pavimento
│   │   │   ├── floor_controller.dart       # controlador do pavimento
│   │   │   └── widgets/
│   │   │       ├── floor_plan_viewer.dart  # visualizador de planta baixa
│   │   │       ├── apartment_pin.dart      # marcador de apartments
│   │   │       └── apartment_details_modal.dart # modal de detalhes
│   │   ├── apartments/                     # telas de apartmentss
│   │   │   ├── apartment_search_screen.dart    # tela de busca de apartmentss
│   │   │   ├── apartment_detail_screen.dart    # tela de detalhes do apartments
│   │   │   ├── search_controller.dart          # controlador de busca
│   │   │   └── widgets/
│   │   │       ├── search_filters.dart         # filtros de busca
│   │   │       ├── apartment_card.dart         # card do apartments
│   │   │       └── apartment_gallery.dart      # galeria do apartments
│   │   ├── gallery/
│   │   │   ├── gallery_screen.dart
│   │   │   ├── gallery_controller.dart
│   │   │   └── widgets/
│   │   │       ├── image_slider.dart
│   │   │       ├── image_pin_overlay.dart
│   │   │       └── image_upload_widget.dart
│   │   ├── admin/
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── content_management_screen.dart
│   │   │   └── sync_management_screen.dart
│   │   └── offline/
│   │       ├── offline_indicator_screen.dart
│   │       └── sync_progress_screen.dart
│   └── widgets/
│       ├── common/
│       │   ├── app_loading_indicator.dart
│       │   ├── app_error_widget.dart
│       │   ├── app_empty_state.dart
│       │   └── app_dialog.dart
│       ├── images/
│       │   ├── cached_network_image_widget.dart
│       │   ├── image_viewer.dart
│       │   └── image_upload_button.dart
│       ├── forms/
│       │   ├── app_text_field.dart
│       │   ├── app_dropdown.dart
│       │   └── app_checkbox.dart
│       └── navigation/
│           ├── app_navigation_rail.dart
│           ├── responsive_navigation.dart
│           └── breadcrumb_navigation.dart
├── generated/
│   ├── graphql/                        # Generated GraphQL code
│   │   ├── queries.dart
│   │   ├── mutations.dart
│   │   └── subscriptions.dart
│   └── intl/                          # Internationalization
│       ├── messages_en.dart
│       └── messages_pt.dart
└── assets/
    ├── fonts/
    ├── icons/
    ├── images/
    └── lottie/
```

---

## 🔌 GraphQL Integration

### 3.1 GraphQL Client Setup

**GraphQL Client Configuration:**
```dart
// lib/core/config/graphql_config.dart
class GraphQLConfig {
  static GraphQLClient createClient({
    required String httpUrl,
    required String wsUrl,
    String? authToken,
  }) {
    final httpLink = HttpLink(httpUrl);
    final wsLink = WebSocketLink(wsUrl);
    
    final authLink = AuthLink(
      getToken: () async => 'Bearer $authToken',
    );
    
    final splitLink = Link.split(
      (request) => request.isSubscription,
      wsLink,
      httpLink,
    );
    
    final link = authLink.concat(splitLink);
    
    return GraphQLClient(
      cache: GraphQLCache(
        store: HiveStore(),
      ),
      link: link,
      defaultPolicies: DefaultPolicies(
        watchQuery: Policies(
          fetchPolicy: FetchPolicy.cacheAndNetwork,
          cacheRereadPolicy: CacheRereadPolicy.mergeOptimistic,
        ),
        query: Policies(
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      ),
    );
  }
}
```

**Riverpod GraphQL Provider:**
```dart
// lib/presentation/providers/graphql_provider.dart
final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final authState = ref.watch(authProvider);
  final connectivityState = ref.watch(connectivityProvider);
  
  return GraphQLConfig.createClient(
    httpUrl: AppConstants.graphqlHttpUrl,
    wsUrl: AppConstants.graphqlWsUrl,
    authToken: authState.token,
  );
});

final graphqlProvider = Provider<GraphQLService>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return GraphQLService(client);
});
```

### 3.2 Generated GraphQL Operations

**Generated Queries:**
```dart
// generated/graphql/queries.dart (auto-generated by build_runner)
class TowersQuery extends Query<TowersQueryData, TowersQueryVariables> {
  static const document = r'''
    query Towers {
      towers {
        id
        name                 # nome da tower
        description          # descrição
        totalApartments      # total de apartmentss
        floors {
          id
          number             # número do pavimento
          bannerUrl          # URL do banner
          totalApartments    # total de apartmentss no pavimento
        }
      }
    }
  ''';
  
  @override
  TowersQueryData parse(Map<String, dynamic> json) => TowersQueryData.fromJson(json);
}

class ApartmentSearchQuery extends Query<ApartmentSearchQueryData, ApartmentSearchQueryVariables> {
  static const document = r'''
    query SearchApartments($input: ApartmentSearchInput!) {
      searchApartments(input: $input) {
        id
        number               # número do apartments
        area                 # área
        suites               # suítes
        bedrooms             # dormitórios
        parkingSpots         # vagas
        status               # status
        price                # preço
        available            # disponível
        solarPosition        # posição solar
        mainImageUrl         # imagem principal
        floorPlanUrl         # planta baixa
        floor {
          id
          number             # número do pavimento
          tower {
            id
            name             # nome da tower
          }
        }
      }
    }
  ''';
}
```

**Generated Mutations:**
```dart
// generated/graphql/mutations.dart
class CreateApartmentMutation extends Mutation<CreateApartmentMutationData, CreateApartmentMutationVariables> {
  static const document = r'''
    mutation CreateApartment($input: CreateApartmentInput!) {
      createApartment(input: $input) {
        id
        number               # número do apartments
        area                 # área
        suites               # suítes
        status               # status
        price                # preço
        floor {
          id
          tower {
            name             # nome da tower
          }
        }
      }
    }
  ''';
}
```

### 3.3 GraphQL Service Layer

```dart
// lib/data/datasources/remote/graphql_service.dart
class GraphQLService {
  final GraphQLClient _client;
  
  GraphQLService(this._client);
  
  Future<List<Tower>> getTowers() async {
    final options = QueryOptions(
      document: TowersQuery.document,
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );
    
    final result = await _client.query(options);
    
    if (result.hasException) {
      throw GraphQLException(result.exception!);
    }
    
    final data = TowersQueryData.fromJson(result.data!);
    return data.towers.map((dto) => TowerMapper.fromDto(dto)).toList();
  }
  
  Stream<List<tower>> watchtowers() {
    final options = WatchQueryOptions(
      document: towersQuery.document,
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );
    
    return _client.watchQuery(options).stream
        .where((result) => !result.isLoading && result.data != null)
        .map((result) {
          final data = towersQueryData.fromJson(result.data!);
          return data.towers.map((dto) => towerMapper.fromDto(dto)).toList();
        });
  }
  
  Future<List<apartments>> searchapartmentss(apartmentsSearchInput input) async {
    final options = QueryOptions(
      document: apartmentsSearchQuery.document,
      variables: {'input': input.toJson()},
    );
    
    final result = await _client.query(options);
    
    if (result.hasException) {
      throw GraphQLException(result.exception!);
    }
    
    final data = apartmentsSearchQueryData.fromJson(result.data!);
    return data.searchapartmentss
        .map((dto) => apartmentsMapper.fromDto(dto))
        .toList();
  }
}
```

---

## 💾 Offline-First Architecture

### 4.1 Local Database (Drift)

**Database Definition:**
```dart
// lib/core/storage/database/app_database.dart
@DriftDatabase(
  tables: [
    Towers,               # tabela de towers
    Floors,               # tabela de pavimentos
    Apartments,           # tabela de apartmentss
    GalleryImages,        # tabela de imagens da galeria
    ImagePins,            # tabela de marcadores
    SyncMetadata,         # tabela de metadados de sinc
  ],
  daos: [
    TowerDao,             # DAO de towers
    ApartmentDao,         # DAO de apartmentss
    GalleryDao,           # DAO de galeria
    SyncDao,              # DAO de sincronização
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Migration logic from v1 to v2 (lógica de migração)
        await m.addColumn(apartments, apartments.available);
      }
    },
  );
}

// Database tables (tabelas do banco de dados)
@DataClassName('TowerData')
class Towers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();        // nome da tower
  TextColumn get description => text().nullable()();                    // descrição da tower
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();               // sincronizado em
}

@DataClassName('FloorData')
class Floors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().withLength(min: 1, max: 50)();        // número do pavimento
  IntColumn get towerId => integer().references(Towers, #id)();         // ID da tower
  TextColumn get bannerUrl => text().nullable()();                     // URL do banner
  TextColumn get bannerLocalPath => text().nullable()();               // caminho local do banner
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

@DataClassName('ApartmentData')
class Apartments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().withLength(min: 1, max: 50)();        // número do apartments
  IntColumn get floorId => integer().references(Floors, #id)();         // ID do pavimento
  TextColumn get area => text().nullable()();                          // área do apartments
  IntColumn get suites => integer().withDefault(const Constant(0))();   // quantidade de suítes
  IntColumn get bedrooms => integer().withDefault(const Constant(0))(); // quantidade de dormitórios
  IntColumn get parkingSpots => integer().withDefault(const Constant(0))(); // quantidade de vagas
  TextColumn get status => textEnum<ApartmentStatus>()
      .withDefault(Constant(ApartmentStatus.available.name))();        // status do apartments
  TextColumn get solarPosition => text().nullable()();                 // posição solar
  RealColumn get price => real().nullable()();                         // preço
  BoolColumn get available => boolean().withDefault(const Constant(true))(); // disponível?
  TextColumn get mainImageUrl => text().nullable()();                  // URL da imagem principal
  TextColumn get mainImageLocalPath => text().nullable()();            // caminho local da imagem principal
  TextColumn get floorPlanUrl => text().nullable()();                  // URL da planta baixa
  TextColumn get floorPlanLocalPath => text().nullable()();            // caminho local da planta baixa
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
```

**Data Access Objects (DAOs):**
```dart
// lib/core/storage/database/dao/tower_dao.dart
@DriftAccessor(tables: [Towers, Floors])
class TowerDao extends DatabaseAccessor<AppDatabase> with _$TowerDaoMixin {
  TowerDao(AppDatabase db) : super(db);
  
  Future<List<TowerData>> getAllTowers() {                             // obter todas as towers
    return select(towers).get();
  }
  
  Future<TowerData?> getTowerById(int id) {                            // obter tower por ID
    return (select(towers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
  
  Future<TowerData> insertTower(TowersCompanion tower) {               // inserir tower
    return into(towers).insertReturning(tower);
  }
  
  Future<void> updateTower(TowerData tower) {                          // atualizar tower
    return update(towers).replace(tower);
  }
  
  Future<void> deleteTower(int id) {                                   // deletar tower
    return (delete(towers)..where((t) => t.id.equals(id))).go();
  }
  
  Stream<List<TowerData>> watchAllTowers() {                           // observar mudanças nas towers
    return select(towers).watch();
  }
  
  Future<List<TowerWithFloors>> getTowersWithFloors() {                // obter towers com pavimentos
    return (select(towers)
      .join([
        leftOuterJoin(floors, floors.towerId.equalsExp(towers.id)),
      ])
      .map((row) {
        return towerWithPavimentos(
          tower: row.readTable(towers),
          pavimentos: row.readTableOrNull(pavimentos),
        );
      })).get();
  }
}
```

### 4.2 Cache Management

**Image Cache Service:**
```dart
// lib/core/storage/cache/image_cache.dart
class ImageCacheService {
  static const String _cacheKey = 'terra_allwert_images';
  late final DefaultCacheManager _cacheManager;
  
  ImageCacheService() {
    _cacheManager = DefaultCacheManager(
      Config(
        _cacheKey,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 1000,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
  }
  
  Future<File?> getCachedImage(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      return null;
    }
  }
  
  Future<File> downloadAndCache(String url) async {
    return await _cacheManager.getSingleFile(url);
  }
  
  Future<void> preloadImages(List<String> urls) async {
    final futures = urls.map((url) => _cacheManager.downloadFile(url));
    await Future.wait(futures);
  }
  
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
  
  Future<int> getCacheSize() async {
    final cacheDir = await _cacheManager.store.retrieveCacheData();
    return cacheDir?.fold<int>(0, (sum, info) => sum + (info.length ?? 0)) ?? 0;
  }
}
```

**Query Cache Service:**
```dart
// lib/core/storage/cache/query_cache.dart
class QueryCacheService {
  final HiveInterface _hive;
  late final Box<String> _queryCache;
  
  QueryCacheService(this._hive);
  
  Future<void> initialize() async {
    _queryCache = await _hive.openBox<String>('query_cache');
  }
  
  Future<void> cacheQuery(String queryKey, Map<String, dynamic> data) async {
    await _queryCache.put(queryKey, jsonEncode(data));
  }
  
  Future<Map<String, dynamic>?> getCachedQuery(String queryKey) async {
    final cached = _queryCache.get(queryKey);
    if (cached == null) return null;
    
    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (e) {
      // Invalid cached data, remove it
      await _queryCache.delete(queryKey);
      return null;
    }
  }
  
  Future<void> clearQueryCache() async {
    await _queryCache.clear();
  }
  
  String generateQueryKey(String query, Map<String, dynamic>? variables) {
    final combined = '$query${variables != null ? jsonEncode(variables) : ''}';
    return crypto.sha256.convert(utf8.encode(combined)).toString();
  }
}
```

### 4.3 Synchronization Service

```dart
// lib/core/network/sync_service.dart
class SyncService {
  final GraphQLService _graphqlService;
  final AppDatabase _database;
  final ConnectivityService _connectivityService;
  final ImageCacheService _imageCacheService;
  
  SyncService({
    required GraphQLService graphqlService,
    required AppDatabase database,
    required ConnectivityService connectivityService,
    required ImageCacheService imageCacheService,
  })  : _graphqlService = graphqlService,
        _database = database,
        _connectivityService = connectivityService,
        _imageCacheService = imageCacheService;
  
  Future<SyncResult> syncAllData() async {
    if (!await _connectivityService.hasConnection()) {
      throw NoConnectionException();
    }
    
    final startTime = DateTime.now();
    final syncResult = SyncResult();
    
    try {
      // Sync towers
      await _synctowers(syncResult);
      
      // Sync pavimentos and apartmentss
      await _syncPavimentosAndapartmentss(syncResult);
      
      // Sync gallery images
      await _syncGalleryImages(syncResult);
      
      // Preload critical images
      await _preloadCriticalImages(syncResult);
      
      syncResult.duration = DateTime.now().difference(startTime);
      syncResult.success = true;
      
      // Update sync metadata
      await _database.syncDao.updateLastSyncTime(DateTime.now());
      
    } catch (e, stackTrace) {
      syncResult.success = false;
      syncResult.error = e.toString();
      syncResult.stackTrace = stackTrace.toString();
    }
    
    return syncResult;
  }
  
  Future<void> _synctowers(SyncResult syncResult) async {
    final remotetowers = await _graphqlService.gettowers();
    final localtowers = await _database.towerDao.getAlltowers();
    
    for (final remotetower in remotetowers) {
      final localtower = localtowers
          .where((t) => t.id == remotetower.id)
          .firstOrNull;
      
      if (localtower == null) {
        // Insert new tower
        await _database.towerDao.inserttower(
          towersCompanion.insert(
            nome: remotetower.nome,
            descricao: Value(remotetower.descricao),
            createdAt: Value(remotetower.createdAt),
            syncedAt: Value(DateTime.now()),
          ),
        );
        syncResult.inserted++;
      } else if (remotetower.updatedAt.isAfter(localtower.syncedAt ?? DateTime.fromMillisecondsSinceEpoch(0))) {
        // Update existing tower
        await _database.towerDao.updatetower(localtower.copyWith(
          nome: remotetower.nome,
          descricao: remotetower.descricao,
          updatedAt: remotetower.updatedAt,
          syncedAt: DateTime.now(),
        ));
        syncResult.updated++;
      }
    }
    
    // Handle deleted towers
    final remoteIds = remotetowers.map((t) => t.id).toSet();
    final deletedtowers = localtowers.where((t) => !remoteIds.contains(t.id));
    
    for (final deletedtower in deletedtowers) {
      await _database.towerDao.deletetower(deletedtower.id);
      syncResult.deleted++;
    }
  }
  
  Future<void> _preloadCriticalImages(SyncResult syncResult) async {
    // Get main images of available apartmentss
    final apartmentss = await _database.apartmentsDao
        .getapartmentss(disponivel: true);
    
    final criticalImages = apartmentss
        .where((a) => a.mainImageUrl != null)
        .map((a) => a.mainImageUrl!)
        .take(50) // Limit to first 50 for initial load
        .toList();
    
    await _imageCacheService.preloadImages(criticalImages);
    syncResult.imagesPreloaded = criticalImages.length;
  }
  
  Stream<SyncProgress> synctowerData(int towerId) async* {
    yield SyncProgress(status: SyncStatus.started, progress: 0.0);
    
    try {
      // Sync tower basic data
      yield SyncProgress(status: SyncStatus.syncingBasicData, progress: 0.1);
      await _syncSpecifictower(towerId);
      
      // Sync pavimentos
      yield SyncProgress(status: SyncStatus.syncingPavimentos, progress: 0.3);
      await _synctowerPavimentos(towerId);
      
      // Sync apartmentss
      yield SyncProgress(status: SyncStatus.syncingapartmentss, progress: 0.6);
      await _synctowerapartmentss(towerId);
      
      // Preload images
      yield SyncProgress(status: SyncStatus.downloadingImages, progress: 0.8);
      await _preloadtowerImages(towerId);
      
      yield SyncProgress(status: SyncStatus.completed, progress: 1.0);
      
    } catch (e) {
      yield SyncProgress(
        status: SyncStatus.failed,
        progress: 0.0,
        error: e.toString(),
      );
    }
  }
}

class SyncResult {
  bool success = false;
  int inserted = 0;
  int updated = 0;
  int deleted = 0;
  int imagesPreloaded = 0;
  Duration? duration;
  String? error;
  String? stackTrace;
}

enum SyncStatus {
  started,
  syncingBasicData,
  syncingPavimentos,
  syncingapartmentss,
  downloadingImages,
  completed,
  failed,
}

class SyncProgress {
  final SyncStatus status;
  final double progress;
  final String? error;
  final String? message;
  
  SyncProgress({
    required this.status,
    required this.progress,
    this.error,
    this.message,
  });
}
```

---

## 📤 MinIO Direct Upload Integration

### 5.1 Signed URL Service

```dart
// lib/data/datasources/minio/signed_url_service.dart
class SignedUrlService {
  final GraphQLService _graphqlService;
  
  SignedUrlService(this._graphqlService);
  
  Future<SignedUploadUrl> generateSignedUploadUrl({
    required String fileName,
    required String contentType,
    required String folder,
  }) async {
    final result = await _graphqlService.generateSignedUploadUrl(
      fileName: fileName,
      contentType: contentType,
      folder: folder,
    );
    
    return SignedUploadUrl(
      uploadUrl: result.uploadUrl,
      accessUrl: result.accessUrl,
      expiresIn: result.expiresIn,
      fields: result.fields,
    );
  }
  
  Future<BulkDownload> generateBulkDownload({int? towerId}) async {
    return await _graphqlService.generateBulkDownload(towerId: towerId);
  }
}
```

### 5.2 Direct Upload Service

```dart
// lib/data/datasources/minio/minio_upload_service.dart
class MinIOUploadService {
  final http.Client _httpClient;
  final SignedUrlService _signedUrlService;
  
  MinIOUploadService(this._httpClient, this._signedUrlService);
  
  Future<UploadResult> uploadFile({
    required File file,
    required String folder,
    String? customFileName,
    void Function(double progress)? onProgress,
  }) async {
    // Generate unique filename if not provided
    final fileName = customFileName ?? 
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    
    // Detect content type
    final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';
    
    // Get signed URL
    final signedUrl = await _signedUrlService.generateSignedUploadUrl(
      fileName: fileName,
      contentType: contentType,
      folder: folder,
    );
    
    // Prepare multipart request
    final request = http.MultipartRequest('POST', Uri.parse(signedUrl.uploadUrl));
    
    // Add form fields from signed URL
    signedUrl.fields?.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    // Add file
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType.parse(contentType),
    );
    request.files.add(multipartFile);
    
    // Upload with progress tracking
    final streamedResponse = await _httpClient.send(request);
    
    if (onProgress != null) {
      final totalBytes = multipartFile.length;
      var uploadedBytes = 0;
      
      streamedResponse.stream.listen(
        (chunk) {
          uploadedBytes += chunk.length;
          onProgress(uploadedBytes / totalBytes);
        },
      );
    }
    
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return UploadResult(
        success: true,
        accessUrl: signedUrl.accessUrl,
        fileName: fileName,
        fileSize: file.lengthSync(),
        contentType: contentType,
      );
    } else {
      return UploadResult(
        success: false,
        error: 'Upload failed: ${response.statusCode} ${response.reasonPhrase}',
        errorCode: response.statusCode,
      );
    }
  }
  
  Future<UploadResult> uploadMultipleFiles({
    required List<File> files,
    required String folder,
    void Function(String fileName, double progress)? onFileProgress,
    void Function(double totalProgress)? onTotalProgress,
  }) async {
    final results = <UploadResult>[];
    var completedFiles = 0;
    
    for (final file in files) {
      final fileName = path.basename(file.path);
      
      try {
        final result = await uploadFile(
          file: file,
          folder: folder,
          onProgress: (progress) {
            onFileProgress?.call(fileName, progress);
          },
        );
        
        results.add(result);
        completedFiles++;
        onTotalProgress?.call(completedFiles / files.length);
        
      } catch (e) {
        results.add(UploadResult(
          success: false,
          error: e.toString(),
          fileName: fileName,
        ));
      }
    }
    
    final successCount = results.where((r) => r.success).length;
    return UploadResult(
      success: successCount == files.length,
      message: '$successCount of ${files.length} files uploaded successfully',
      batchResults: results,
    );
  }
}

class UploadResult {
  final bool success;
  final String? accessUrl;
  final String? fileName;
  final int? fileSize;
  final String? contentType;
  final String? error;
  final int? errorCode;
  final String? message;
  final List<UploadResult>? batchResults;
  
  UploadResult({
    required this.success,
    this.accessUrl,
    this.fileName,
    this.fileSize,
    this.contentType,
    this.error,
    this.errorCode,
    this.message,
    this.batchResults,
  });
}
```

### 5.3 Image Upload Widget

```dart
// lib/presentation/widgets/images/image_upload_widget.dart
class ImageUploadWidget extends ConsumerStatefulWidget {
  final String folder;
  final String? existingImageUrl;
  final void Function(UploadResult result)? onUploadComplete;
  final void Function(String error)? onUploadError;
  final bool allowMultiple;
  final List<String> allowedExtensions;
  
  const ImageUploadWidget({
    Key? key,
    required this.folder,
    this.existingImageUrl,
    this.onUploadComplete,
    this.onUploadError,
    this.allowMultiple = false,
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'webp'],
  }) : super(key: key);
  
  @override
  ConsumerState<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends ConsumerState<ImageUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _currentFileName;
  
  Future<void> _pickAndUploadImages() async {
    final picker = ImagePicker();
    
    try {
      List<XFile> selectedFiles;
      
      if (widget.allowMultiple) {
        selectedFiles = await picker.pickMultiImage();
      } else {
        final file = await picker.pickImage(source: ImageSource.gallery);
        selectedFiles = file != null ? [file] : [];
      }
      
      if (selectedFiles.isEmpty) return;
      
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      
      final uploadService = ref.read(minioUploadServiceProvider);
      final files = selectedFiles.map((xFile) => File(xFile.path)).toList();
      
      if (files.length == 1) {
        // Single file upload
        final result = await uploadService.uploadFile(
          file: files.first,
          folder: widget.folder,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
        
        if (result.success) {
          widget.onUploadComplete?.call(result);
        } else {
          widget.onUploadError?.call(result.error ?? 'Upload failed');
        }
      } else {
        // Multiple files upload
        final result = await uploadService.uploadMultipleFiles(
          files: files,
          folder: widget.folder,
          onFileProgress: (fileName, progress) {
            setState(() {
              _currentFileName = fileName;
              _uploadProgress = progress;
            });
          },
          onTotalProgress: (totalProgress) {
            setState(() {
              _uploadProgress = totalProgress;
            });
          },
        );
        
        if (result.success) {
          widget.onUploadComplete?.call(result);
        } else {
          widget.onUploadError?.call(result.error ?? 'Upload failed');
        }
      }
      
    } catch (e) {
      widget.onUploadError?.call(e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _currentFileName = null;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Existing image preview
        if (widget.existingImageUrl != null)
          CachedNetworkImageWidget(
            imageUrl: widget.existingImageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        
        const SizedBox(height: 16),
        
        // Upload button or progress indicator
        if (_isUploading)
          Column(
            children: [
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              if (_currentFileName != null)
                Text(
                  'Uploading $_currentFileName...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: _pickAndUploadImages,
            icon: const Icon(Icons.cloud_upload),
            label: Text(widget.allowMultiple ? 'Upload Images' : 'Upload Image'),
          ),
      ],
    );
  }
}
```

---

## 🎨 State Management (Riverpod)

### 6.1 Core Providers

```dart
// lib/presentation/providers/core_providers.dart

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Connectivity provider
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    graphqlService: ref.read(graphqlProvider),
    database: ref.read(databaseProvider),
    connectivityService: ref.read(connectivityServiceProvider),
    imageCacheService: ref.read(imageCacheServiceProvider),
  );
});

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

### 6.2 tower Providers

```dart
// lib/presentation/providers/tower_provider.dart
final towersProvider = StreamProvider<List<tower>>((ref) {
  final database = ref.watch(databaseProvider);
  final connectivityState = ref.watch(connectivityProvider);
  
  // Watch local database changes
  final localStream = database.towerDao.watchAlltowers()
      .map((towersData) => towersData
          .map((data) => tower.fromDriftData(data))
          .toList());
  
  // Trigger sync if online and data is stale
  ref.listen<ConnectivityState>(connectivityProvider, (previous, next) {
    if (next.isConnected && (previous?.isConnected != true)) {
      // Connection restored, trigger background sync
      ref.read(syncServiceProvider).syncAllData().catchError((error) {
        // Log error but don't throw - offline data is still valid
        print('Background sync failed: $error');
      });
    }
  });
  
  return localStream;
});

final towerProvider = Provider.family<AsyncValue<tower?>, int>((ref, towerId) {
  final database = ref.watch(databaseProvider);
  
  return ref.watch(
    StreamProvider<tower?>((ref) {
      return database.towerDao.watchtowerById(towerId)
          .map((data) => data != null ? tower.fromDriftData(data) : null);
    }).future,
  );
});

final towerPavimentosProvider = Provider.family<AsyncValue<List<Pavimento>>, int>((ref, towerId) {
  final database = ref.watch(databaseProvider);
  
  return ref.watch(
    StreamProvider<List<Pavimento>>((ref) {
      return database.pavimentoDao.watchPavimentosBytower(towerId)
          .map((pavimentosData) => pavimentosData
              .map((data) => Pavimento.fromDriftData(data))
              .toList());
    }).future,
  );
});
```

### 6.3 apartments Search Provider

```dart
// lib/presentation/providers/apartments_search_provider.dart
@freezed
class apartmentsSearchState with _$apartmentsSearchState {
  const factory apartmentsSearchState({
    @Default([]) List<apartments> results,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int totalResults,
    String? error,
    apartmentsSearchFilters? lastFilters,
  }) = _apartmentsSearchState;
}

@freezed
class apartmentsSearchFilters with _$apartmentsSearchFilters {
  const factory apartmentsSearchFilters({
    String? numero,
    int? suites,
    int? dormitorios,
    int? vagas,
    String? posicaoSolar,
    int? towerId,
    int? pavimentoId,
    double? precoMin,
    double? precoMax,
    String? areaMin,
    String? areaMax,
    apartmentsStatus? status,
    bool? disponivel,
    @Default(20) int limit,
    @Default(0) int offset,
  }) = _apartmentsSearchFilters;
}

class apartmentsSearchNotifier extends StateNotifier<apartmentsSearchState> {
  final AppDatabase _database;
  final GraphQLService _graphqlService;
  final ConnectivityService _connectivityService;
  
  apartmentsSearchNotifier({
    required AppDatabase database,
    required GraphQLService graphqlService,
    required ConnectivityService connectivityService,
  })  : _database = database,
        _graphqlService = graphqlService,
        _connectivityService = connectivityService,
        super(const apartmentsSearchState());
  
  Future<void> search(apartmentsSearchFilters filters) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      List<apartments> results;
      
      if (await _connectivityService.hasConnection()) {
        // Online search via GraphQL
        results = await _searchOnline(filters);
        
        // Cache results locally for offline access
        await _cacheSearchResults(results, filters);
      } else {
        // Offline search from local database
        results = await _searchOffline(filters);
      }
      
      state = state.copyWith(
        results: results,
        isLoading: false,
        totalResults: results.length,
        lastFilters: filters,
        hasMore: results.length >= filters.limit,
      );
      
    } catch (e) {
      // On error, try offline search as fallback
      try {
        final offlineResults = await _searchOffline(filters);
        state = state.copyWith(
          results: offlineResults,
          isLoading: false,
          error: 'Using offline data: ${e.toString()}',
          lastFilters: filters,
        );
      } catch (offlineError) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }
  
  Future<List<apartments>> _searchOnline(apartmentsSearchFilters filters) async {
    final searchInput = apartmentsSearchInput(
      numero: filters.numero,
      suites: filters.suites,
      dormitorios: filters.dormitorios,
      vagas: filters.vagas,
      posicaoSolar: filters.posicaoSolar,
      towerId: filters.towerId?.toString(),
      pavimentoId: filters.pavimentoId?.toString(),
      precoMin: filters.precoMin,
      precoMax: filters.precoMax,
      areaMin: filters.areaMin,
      areaMax: filters.areaMax,
      status: filters.status,
      disponivel: filters.disponivel,
      limit: filters.limit,
      offset: filters.offset,
    );
    
    return await _graphqlService.searchapartmentss(searchInput);
  }
  
  Future<List<apartments>> _searchOffline(apartmentsSearchFilters filters) async {
    final query = _database.apartmentsDao.buildSearchQuery(
      numero: filters.numero,
      suites: filters.suites,
      dormitorios: filters.dormitorios,
      vagas: filters.vagas,
      posicaoSolar: filters.posicaoSolar,
      towerId: filters.towerId,
      pavimentoId: filters.pavimentoId,
      precoMin: filters.precoMin,
      precoMax: filters.precoMax,
      status: filters.status,
      disponivel: filters.disponivel,
      limit: filters.limit,
      offset: filters.offset,
    );
    
    final results = await query.get();
    return results.map((data) => apartments.fromDriftData(data)).toList();
  }
  
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    
    final currentFilters = state.lastFilters;
    if (currentFilters == null) return;
    
    final nextFilters = currentFilters.copyWith(
      offset: state.results.length,
    );
    
    state = state.copyWith(isLoading: true);
    
    try {
      List<apartments> newResults;
      
      if (await _connectivityService.hasConnection()) {
        newResults = await _searchOnline(nextFilters);
      } else {
        newResults = await _searchOffline(nextFilters);
      }
      
      state = state.copyWith(
        results: [...state.results, ...newResults],
        isLoading: false,
        hasMore: newResults.length >= nextFilters.limit,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  void clearSearch() {
    state = const apartmentsSearchState();
  }
}

final apartmentsSearchProvider = StateNotifierProvider<apartmentsSearchNotifier, apartmentsSearchState>((ref) {
  return apartmentsSearchNotifier(
    database: ref.read(databaseProvider),
    graphqlService: ref.read(graphqlProvider),
    connectivityService: ref.read(connectivityServiceProvider),
  );
});
```

---

## 🖥️ UI Components & Screens

### 7.1 Responsive Navigation

```dart
// lib/presentation/widgets/navigation/responsive_navigation.dart
class ResponsiveNavigation extends ConsumerWidget {
  final Widget child;
  
  const ResponsiveNavigation({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 768;
    final isDesktop = screenSize.width > 1200;
    
    if (isDesktop) {
      return _DesktopLayout(child: child);
    } else if (isTablet) {
      return _TabletLayout(child: child);
    } else {
      return _MobileLayout(child: child);
    }
  }
}

class _TabletLayout extends ConsumerWidget {
  final Widget child;
  
  const _TabletLayout({required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation rail for tablet
          NavigationRail(
            extended: true,
            destinations: _buildNavigationDestinations(context, ref),
            selectedIndex: _getSelectedIndex(context, ref),
            onDestinationSelected: (index) => _navigateToIndex(context, ref, index),
          ),
          
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Status bar showing connectivity and sync status
                const ConnectivityStatusBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectivityStatusBar extends ConsumerWidget {
  const ConnectivityStatusBar({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncStatusProvider);
    
    return Container(
      height: 32,
      color: _getStatusBarColor(connectivityState, syncState),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(connectivityState, syncState),
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getStatusMessage(connectivityState, syncState),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (syncState.isInProgress)
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: syncState.progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: connectivityState.isConnected && !syncState.isInProgress
                  ? () => ref.read(syncServiceProvider).syncAllData()
                  : null,
              child: const Text(
                'Sync',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusBarColor(ConnectivityState connectivity, SyncState sync) {
    if (!connectivity.isConnected) return Colors.red;
    if (sync.isInProgress) return Colors.blue;
    if (sync.hasError) return Colors.orange;
    return Colors.green;
  }
  
  IconData _getStatusIcon(ConnectivityState connectivity, SyncState sync) {
    if (!connectivity.isConnected) return Icons.wifi_off;
    if (sync.isInProgress) return Icons.sync;
    if (sync.hasError) return Icons.warning;
    return Icons.wifi;
  }
  
  String _getStatusMessage(ConnectivityState connectivity, SyncState sync) {
    if (!connectivity.isConnected) {
      return 'Offline - Using cached data';
    }
    if (sync.isInProgress) {
      return 'Syncing data... ${(sync.progress * 100).toInt()}%';
    }
    if (sync.hasError) {
      return 'Sync error - Using cached data';
    }
    return 'Online - Data up to date';
  }
}
```

### 7.2 apartments Search Screen

```dart
// lib/presentation/screens/apartmentss/apartments_search_screen.dart
class apartmentsSearchScreen extends ConsumerStatefulWidget {
  const apartmentsSearchScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<apartmentsSearchScreen> createState() => _apartmentsSearchScreenState();
}

class _apartmentsSearchScreenState extends ConsumerState<apartmentsSearchScreen> {
  final _scrollController = ScrollController();
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    
    // Load more results when scrolling near the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(apartmentsSearchProvider.notifier).loadMore();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(apartmentsSearchProvider);
    final towers = ref.watch(towersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar apartmentss'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search filters
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters
                ? towers.when(
                    data: (towersList) => apartmentsSearchFilters(
                      towers: towersList,
                      onSearch: (filters) {
                        ref
                            .read(apartmentsSearchProvider.notifier)
                            .search(filters);
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Text('Error loading towers: $error'),
                  )
                : const SizedBox.shrink(),
          ),
          
          const Divider(height: 1),
          
          // Search results
          Expanded(
            child: _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults(apartmentsSearchState searchState) {
    if (searchState.results.isEmpty && !searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum apartments encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros de busca',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: searchState.results.length + 
          (searchState.isLoading ? 1 : 0) +
          (searchState.error != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Error message
        if (searchState.error != null && index == 0) {
          return Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      searchState.error!,
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Adjust index for error message
        final adjustedIndex = searchState.error != null ? index - 1 : index;
        
        // Loading indicator
        if (adjustedIndex >= searchState.results.length) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        // apartments card
        final apartments = searchState.results[adjustedIndex];
        return apartmentsCard(
          apartments: apartments,
          onTap: () => _navigateToapartmentsDetails(apartments),
        );
      },
    );
  }
  
  void _navigateToapartmentsDetails(apartments apartments) {
    context.push('/apartmentss/${apartments.id}');
  }
}
```

### 7.3 Cached Network Image Widget

```dart
// lib/presentation/widgets/images/cached_network_image_widget.dart
class CachedNetworkImageWidget extends ConsumerWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showOfflineIndicator;
  
  const CachedNetworkImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showOfflineIndicator = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
          errorWidget: (context, url, error) {
            // Try to get cached version first
            return FutureBuilder<File?>(
              future: ref.read(imageCacheServiceProvider).getCachedImage(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(
                    snapshot.data!,
                    width: width,
                    height: height,
                    fit: fit,
                  );
                }
                return errorWidget ?? _defaultErrorWidget(context);
              },
            );
          },
          cacheManager: ref.read(imageCacheServiceProvider).cacheManager,
        ),
        
        // Offline indicator
        if (!connectivityState.isConnected && showOfflineIndicator)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OFFLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Imagem não disponível',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔄 Background Sync & Data Management

### 8.1 Background Sync Service

```dart
// lib/core/network/background_sync_service.dart
class BackgroundSyncService {
  static const String _taskName = 'terra_allwert_sync';
  
  final SyncService _syncService;
  final AppDatabase _database;
  final NotificationService _notificationService;
  
  BackgroundSyncService({
    required SyncService syncService,
    required AppDatabase database,
    required NotificationService notificationService,
  })  : _syncService = syncService,
        _database = database,
        _notificationService = notificationService;
  
  Future<void> initialize() async {
    // Register periodic background sync
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Schedule periodic sync every 6 hours
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }
  
  Future<bool> executeBackgroundSync() async {
    try {
      final syncResult = await _syncService.syncAllData();
      
      if (syncResult.success) {
        // Show success notification if there were updates
        if (syncResult.updated > 0 || syncResult.inserted > 0) {
          await _notificationService.showNotification(
            title: 'Dados Atualizados',
            body: 'Novos dados foram sincronizados com sucesso.',
          );
        }
        return true;
      } else {
        // Log error but don't show notification (avoid spam)
        print('Background sync failed: ${syncResult.error}');
        return false;
      }
    } catch (e) {
      print('Background sync error: $e');
      return false;
    }
  }
  
  Future<void> cancelBackgroundSync() async {
    await Workmanager().cancelByUniqueName(_taskName);
  }
}

// Global callback dispatcher for background tasks
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize minimal services needed for sync
      final database = AppDatabase();
      final graphqlClient = GraphQLConfig.createClient(
        httpUrl: AppConstants.graphqlHttpUrl,
        wsUrl: AppConstants.graphqlWsUrl,
      );
      final graphqlService = GraphQLService(graphqlClient);
      final connectivityService = ConnectivityService();
      final imageCacheService = ImageCacheService();
      
      final syncService = SyncService(
        graphqlService: graphqlService,
        database: database,
        connectivityService: connectivityService,
        imageCacheService: imageCacheService,
      );
      
      final notificationService = NotificationService();
      
      final backgroundSync = BackgroundSyncService(
        syncService: syncService,
        database: database,
        notificationService: notificationService,
      );
      
      return await backgroundSync.executeBackgroundSync();
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}
```

### 8.2 Conflict Resolution

```dart
// lib/core/network/conflict_resolution_service.dart
enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
  askUser,
}

class ConflictResolutionService {
  final AppDatabase _database;
  
  ConflictResolutionService(this._database);
  
  Future<ConflictResolutionResult> resolveapartmentsConflict({
    required apartmentsData localData,
    required apartments remoteData,
    ConflictResolution strategy = ConflictResolution.askUser,
  }) async {
    final conflicts = _identifyConflicts(localData, remoteData);
    
    if (conflicts.isEmpty) {
      return ConflictResolutionResult(
        resolved: true,
        resolution: ConflictResolution.merge,
        resolvedData: remoteData,
      );
    }
    
    switch (strategy) {
      case ConflictResolution.useLocal:
        return ConflictResolutionResult(
          resolved: true,
          resolution: ConflictResolution.useLocal,
          resolvedData: apartments.fromDriftData(localData),
        );
        
      case ConflictResolution.useRemote:
        await _database.apartmentsDao.updateapartments(
          localData.copyWith(
            numero: remoteData.numero,
            area: remoteData.area,
            suites: remoteData.suites,
            dormitorios: remoteData.dormitorios,
            vagas: remoteData.vagas,
            status: remoteData.status.name,
            posicaoSolar: remoteData.posicaoSolar,
            preco: remoteData.preco,
            disponivel: remoteData.disponivel,
            updatedAt: remoteData.updatedAt,
            syncedAt: DateTime.now(),
          ),
        );
        return ConflictResolutionResult(
          resolved: true,
          resolution: ConflictResolution.useRemote,
          resolvedData: remoteData,
        );
        
      case ConflictResolution.merge:
        final mergedData = await _mergeapartmentsData(localData, remoteData);
        return ConflictResolutionResult(
          resolved: true,
          resolution: ConflictResolution.merge,
          resolvedData: mergedData,
        );
        
      case ConflictResolution.askUser:
        return ConflictResolutionResult(
          resolved: false,
          conflicts: conflicts,
          localData: apartments.fromDriftData(localData),
          remoteData: remoteData,
        );
    }
  }
  
  List<DataConflict> _identifyConflicts(apartmentsData local, apartments remote) {
    final conflicts = <DataConflict>[];
    
    if (local.numero != remote.numero) {
      conflicts.add(DataConflict(
        field: 'numero',
        localValue: local.numero,
        remoteValue: remote.numero,
      ));
    }
    
    if (local.area != remote.area) {
      conflicts.add(DataConflict(
        field: 'area',
        localValue: local.area,
        remoteValue: remote.area,
      ));
    }
    
    if (local.suites != remote.suites) {
      conflicts.add(DataConflict(
        field: 'suites',
        localValue: local.suites,
        remoteValue: remote.suites,
      ));
    }
    
    if (local.preco != remote.preco) {
      conflicts.add(DataConflict(
        field: 'preco',
        localValue: local.preco,
        remoteValue: remote.preco,
      ));
    }
    
    if (local.disponivel != remote.disponivel) {
      conflicts.add(DataConflict(
        field: 'disponivel',
        localValue: local.disponivel,
        remoteValue: remote.disponivel,
      ));
    }
    
    return conflicts;
  }
  
  Future<apartments> _mergeapartmentsData(apartmentsData local, apartments remote) async {
    // Merge strategy: prioritize non-null remote values, keep local changes for user-editable fields
    final mergedData = local.copyWith(
      // Always use remote for server-managed fields
      updatedAt: remote.updatedAt,
      syncedAt: DateTime.now(),
      
      // Use remote for these fields unless local has newer changes
      numero: remote.numero,
      area: remote.area,
      suites: remote.suites,
      dormitorios: remote.dormitorios,
      vagas: remote.vagas,
      posicaoSolar: remote.posicaoSolar,
      
      // For price and availability, use remote (business critical)
      preco: remote.preco,
      disponivel: remote.disponivel,
      status: remote.status.name,
      
      // Keep local image paths if they exist (offline images)
      mainImageUrl: remote.mainImageUrl,
      floorPlanUrl: remote.floorPlanUrl,
    );
    
    await _database.apartmentsDao.updateapartments(mergedData);
    return apartments.fromDriftData(mergedData);
  }
}

@freezed
class ConflictResolutionResult with _$ConflictResolutionResult {
  const factory ConflictResolutionResult({
    required bool resolved,
    ConflictResolution? resolution,
    apartments? resolvedData,
    apartments? localData,
    apartments? remoteData,
    List<DataConflict>? conflicts,
  }) = _ConflictResolutionResult;
}

@freezed
class DataConflict with _$DataConflict {
  const factory DataConflict({
    required String field,
    required dynamic localValue,
    required dynamic remoteValue,
  }) = _DataConflict;
}
```

---

## 🧪 Testing Strategy

### 9.1 Unit Tests

```dart
// test/data/repositories/tower_repository_test.dart
void main() {
  group('towerRepository', () {
    late towerRepositoryImpl repository;
    late MocktowerRemoteDataSource mockRemoteDataSource;
    late MocktowerLocalDataSource mockLocalDataSource;
    late MockConnectivityService mockConnectivityService;
    
    setUp(() {
      mockRemoteDataSource = MocktowerRemoteDataSource();
      mockLocalDataSource = MocktowerLocalDataSource();
      mockConnectivityService = MockConnectivityService();
      
      repository = towerRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        connectivityService: mockConnectivityService,
      );
    });
    
    group('gettowers', () {
      test('should return local data when offline', () async {
        // Arrange
        when(mockConnectivityService.hasConnection()).thenAnswer((_) async => false);
        final localtowers = [
          const tower(id: 1, nome: 'tower 1', descricao: 'Descrição 1'),
        ];
        when(mockLocalDataSource.gettowers()).thenAnswer((_) async => localtowers);
        
        // Act
        final result = await repository.gettowers();
        
        // Assert
        expect(result, equals(localtowers));
        verify(mockLocalDataSource.gettowers()).called(1);
        verifyNever(mockRemoteDataSource.gettowers());
      });
      
      test('should fetch remote data and cache locally when online', () async {
        // Arrange
        when(mockConnectivityService.hasConnection()).thenAnswer((_) async => true);
        final remotetowers = [
          const tower(id: 1, nome: 'tower 1', descricao: 'Descrição 1'),
          const tower(id: 2, nome: 'tower 2', descricao: 'Descrição 2'),
        ];
        when(mockRemoteDataSource.gettowers()).thenAnswer((_) async => remotetowers);
        when(mockLocalDataSource.cachetowers(any)).thenAnswer((_) async {});
        
        // Act
        final result = await repository.gettowers();
        
        // Assert
        expect(result, equals(remotetowers));
        verify(mockRemoteDataSource.gettowers()).called(1);
        verify(mockLocalDataSource.cachetowers(remotetowers)).called(1);
      });
      
      test('should fallback to local data when remote fails', () async {
        // Arrange
        when(mockConnectivityService.hasConnection()).thenAnswer((_) async => true);
        when(mockRemoteDataSource.gettowers()).thenThrow(Exception('Network error'));
        final localtowers = [
          const tower(id: 1, nome: 'tower 1', descricao: 'Descrição 1'),
        ];
        when(mockLocalDataSource.gettowers()).thenAnswer((_) async => localtowers);
        
        // Act
        final result = await repository.gettowers();
        
        // Assert
        expect(result, equals(localtowers));
        verify(mockRemoteDataSource.gettowers()).called(1);
        verify(mockLocalDataSource.gettowers()).called(1);
      });
    });
  });
}
```

### 9.2 Integration Tests

```dart
// integration_test/sync_flow_test.dart
void main() {
  group('Offline-First Sync Flow', () {
    late AppDatabase database;
    late GraphQLService graphqlService;
    late SyncService syncService;
    
    setUpAll(() async {
      // Initialize test database
      database = AppDatabase.forTesting();
      
      // Initialize GraphQL service with test client
      final testClient = GraphQLClient(
        cache: GraphQLCache(),
        link: HttpLink('http://127.0.0.1:3000/graphql'),
      );
      graphqlService = GraphQLService(testClient);
      
      // Initialize sync service
      syncService = SyncService(
        graphqlService: graphqlService,
        database: database,
        connectivityService: TestConnectivityService(),
        imageCacheService: TestImageCacheService(),
      );
    });
    
    testWidgets('should sync data from API to local database', (tester) async {
      // Arrange
      await database.towerDao.deleteAlltowers(); // Start with empty database
      
      // Act
      final syncResult = await syncService.syncAllData();
      
      // Assert
      expect(syncResult.success, isTrue);
      expect(syncResult.inserted, greaterThan(0));
      
      final localtowers = await database.towerDao.getAlltowers();
      expect(localtowers, isNotEmpty);
    });
    
    testWidgets('should work offline with cached data', (tester) async {
      // Arrange - ensure data is cached
      await syncService.syncAllData();
      
      // Simulate offline
      final offlineConnectivityService = TestConnectivityService(isConnected: false);
      final offlineRepository = towerRepositoryImpl(
        remoteDataSource: towerRemoteDataSource(graphqlService),
        localDataSource: towerLocalDataSource(database),
        connectivityService: offlineConnectivityService,
      );
      
      // Act
      final towers = await offlineRepository.gettowers();
      
      // Assert
      expect(towers, isNotEmpty);
    });
  });
}
```

### 9.3 Widget Tests

```dart
// test/presentation/screens/apartments_search_test.dart
void main() {
  group('apartmentsSearchScreen', () {
    testWidgets('should display search results', (tester) async {
      // Arrange
      final mockContainer = ProviderContainer(
        overrides: [
          apartmentsSearchProvider.overrideWith((ref) => MockapartmentsSearchNotifier()),
        ],
      );
      
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: mockContainer,
          child: MaterialApp(
            home: apartmentsSearchScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Buscar apartmentss'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });
    
    testWidgets('should show offline indicator when offline', (tester) async {
      // Arrange
      final mockContainer = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => 
            ConnectivityNotifier.offline()),
        ],
      );
      
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: mockContainer,
          child: MaterialApp(
            home: apartmentsSearchScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Offline - Using cached data'), findsOneWidget);
    });
  });
}
```

---

## 📱 Platform-Specific Implementations

### 10.1 iOS Background App Refresh

```dart
// lib/platform/ios/background_refresh_ios.dart
class IOSBackgroundRefresh {
  static const MethodChannel _channel = MethodChannel('terra_allwert/ios_background');
  
  static Future<void> enableBackgroundAppRefresh() async {
    try {
      await _channel.invokeMethod('enableBackgroundRefresh');
    } on PlatformException catch (e) {
      print('Failed to enable background refresh: ${e.message}');
    }
  }
  
  static Future<bool> isBackgroundAppRefreshEnabled() async {
    try {
      return await _channel.invokeMethod('isBackgroundRefreshEnabled');
    } on PlatformException catch (e) {
      print('Failed to check background refresh status: ${e.message}');
      return false;
    }
  }
  
  static Future<void> handleBackgroundRefresh() async {
    // Perform quick sync when app is backgrounded
    final syncService = GetIt.instance<SyncService>();
    
    try {
      await syncService.syncAllData().timeout(
        const Duration(seconds: 25), // iOS gives ~30 seconds
      );
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }
}
```

### 10.2 Android Work Manager

```dart
// lib/platform/android/work_manager_android.dart
class AndroidWorkManager {
  static const String SYNC_WORK_NAME = 'sync_work';
  
  static Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      SYNC_WORK_NAME,
      SYNC_WORK_NAME,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
  
  static Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(SYNC_WORK_NAME);
  }
  
  static Future<void> enqueueSyncWork() async {
    await Workmanager().registerOneOffTask(
      'one_off_sync',
      'sync_task',
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
```

---

## 🚀 Performance Optimization

### 11.1 Image Optimization

```dart
// lib/core/utils/image_optimizer.dart
class ImageOptimizer {
  static Future<File> optimizeImage(File originalImage, {
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    final img.Image? image = img.decodeImage(originalImage.readAsBytesSync());
    if (image == null) return originalImage;
    
    // Resize if needed
    img.Image resized = image;
    if (image.width > maxWidth || image.height > maxHeight) {
      resized = img.copyResize(
        image,
        width: image.width > maxWidth ? maxWidth : null,
        height: image.height > maxHeight ? maxHeight : null,
        interpolation: img.Interpolation.linear,
      );
    }
    
    // Compress
    final compressedBytes = img.encodeJpg(resized, quality: quality);
    
    // Save optimized image
    final optimizedFile = File('${originalImage.path}_optimized.jpg');
    await optimizedFile.writeAsBytes(compressedBytes);
    
    return optimizedFile;
  }
  
  static Future<File> generateThumbnail(File originalImage, {
    int size = 300,
  }) async {
    final img.Image? image = img.decodeImage(originalImage.readAsBytesSync());
    if (image == null) return originalImage;
    
    final thumbnail = img.copyResizeCropSquare(image, size: size);
    final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
    
    final thumbnailFile = File('${originalImage.path}_thumb.jpg');
    await thumbnailFile.writeAsBytes(thumbnailBytes);
    
    return thumbnailFile;
  }
}
```

### 11.2 Database Performance

```dart
// lib/core/storage/database/performance_optimized_dao.dart
mixin PerformanceOptimizedDao {
  // Batch operations for better performance
  Future<void> batchInsertapartmentss(List<apartmentsData> apartmentss) async {
    await batch((batch) {
      for (final apartments in apartmentss) {
        batch.insert(apartmentss, apartments);
      }
    });
  }
  
  // Paginated queries to reduce memory usage
  Future<List<apartmentsData>> getapartmentssPaginated({
    required int limit,
    required int offset,
  }) {
    return (select(apartmentss)
          ..limit(limit, offset: offset)
          ..orderBy([(a) => OrderingTerm.asc(a.numero)]))
        .get();
  }
  
  // Optimized search with indexes
  Future<List<apartmentsData>> searchapartmentssOptimized({
    String? numeroQuery,
    int? suitesFilter,
    int? towerIdFilter,
  }) {
    return customSelect('''
      SELECT a.* FROM apartmentss a
      JOIN pavimentos p ON p.id = a.pavimento_id
      WHERE (?1 IS NULL OR a.numero LIKE '%' || ?1 || '%')
        AND (?2 IS NULL OR a.suites = ?2)
        AND (?3 IS NULL OR p.tower_id = ?3)
      ORDER BY p.tower_id, a.numero
      LIMIT 100
    ''', variables: [
      Variable.withString(numeroQuery),
      Variable.withInt(suitesFilter),
      Variable.withInt(towerIdFilter),
    ]).asyncMap((row) => apartmentss.mapFromRow(row)).get();
  }
}
```

---

## 📊 Analytics & Monitoring

### 12.1 Usage Analytics

```dart
// lib/core/analytics/analytics_service.dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final List<AnalyticsEvent> _offlineEvents = [];
  
  Future<void> trackScreenView(String screenName) async {
    final event = AnalyticsEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName},
      timestamp: DateTime.now(),
    );
    
    if (await _isOnline()) {
      await _analytics.logScreenView(screenName: screenName);
    } else {
      _offlineEvents.add(event);
    }
  }
  
  Future<void> trackapartmentsSearch({
    required int resultsCount,
    required Map<String, dynamic> filters,
  }) async {
    final event = AnalyticsEvent(
      name: 'apartments_search',
      parameters: {
        'results_count': resultsCount,
        'filters_used': filters.keys.join(','),
        ...filters,
      },
      timestamp: DateTime.now(),
    );
    
    if (await _isOnline()) {
      await _analytics.logEvent(
        name: 'apartments_search',
        parameters: event.parameters,
      );
    } else {
      _offlineEvents.add(event);
    }
  }
  
  Future<void> trackImageView(String imageUrl) async {
    final event = AnalyticsEvent(
      name: 'image_view',
      parameters: {'image_url': imageUrl},
      timestamp: DateTime.now(),
    );
    
    if (await _isOnline()) {
      await _analytics.logEvent(
        name: 'image_view',
        parameters: event.parameters,
      );
    } else {
      _offlineEvents.add(event);
    }
  }
  
  Future<void> syncOfflineEvents() async {
    if (!await _isOnline() || _offlineEvents.isEmpty) return;
    
    try {
      for (final event in _offlineEvents) {
        await _analytics.logEvent(
          name: event.name,
          parameters: event.parameters,
        );
      }
      
      _offlineEvents.clear();
    } catch (e) {
      print('Failed to sync offline analytics events: $e');
    }
  }
  
  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  
  AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
}
```

### 12.2 Performance Monitoring

```dart
// lib/core/monitoring/performance_monitor.dart
class PerformanceMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final List<PerformanceMetric> _metrics = [];
  
  static void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }
  
  static void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime);
    _operationStartTimes.remove(operationName);
    
    final metric = PerformanceMetric(
      operation: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _metrics.add(metric);
    
    // Log slow operations
    if (duration.inMilliseconds > 1000) {
      print('SLOW OPERATION: $operationName took ${duration.inMilliseconds}ms');
    }
    
    // Keep only last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }
  }
  
  static List<PerformanceMetric> getSlowOperations({
    Duration threshold = const Duration(milliseconds: 500),
  }) {
    return _metrics
        .where((m) => m.duration >= threshold)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
  }
  
  static Map<String, Duration> getAverageOperationTimes() {
    final operationGroups = <String, List<Duration>>{};
    
    for (final metric in _metrics) {
      operationGroups[metric.operation] ??= [];
      operationGroups[metric.operation]!.add(metric.duration);
    }
    
    return operationGroups.map((operation, durations) {
      final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
      final averageMs = totalMs / durations.length;
      return MapEntry(operation, Duration(milliseconds: averageMs.round()));
    });
  }
}

class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

// Usage example
Future<List<tower>> gettowers() async {
  PerformanceMonitor.startOperation('get_towers');
  try {
    final towers = await repository.gettowers();
    PerformanceMonitor.endOperation('get_towers', metadata: {
      'count': towers.length,
      'source': 'cache',
    });
    return towers;
  } catch (e) {
    PerformanceMonitor.endOperation('get_towers', metadata: {
      'error': e.toString(),
    });
    rethrow;
  }
}
```

---

## 🎯 Conclusion & Migration Path

### 13.1 Migration Strategy

**Phase 1: Foundation (Weeks 1-2)**
- Setup new Flutter project structure
- Implement GraphQL integration
- Create local database (Drift)
- Basic offline storage setup

**Phase 2: Core Features (Weeks 3-4)**
- Implement towers and apartmentss screens
- Search functionality
- Direct MinIO upload integration
- Basic sync service

**Phase 3: Advanced Offline (Weeks 5-6)**
- Complete offline functionality
- Background sync
- Conflict resolution
- Image caching and optimization

**Phase 4: Polish & Testing (Weeks 7-8)**
- Performance optimization
- Comprehensive testing
- UI/UX improvements
- Analytics integration

### 13.2 Success Metrics

| Metric | Current | Target | Improvement |
|--------|---------|--------|-------------|
| **Offline Functionality** | 0% | 95% | Complete offline support |
| **App Launch Time** | 3-5s | <2s | 60% faster |
| **Search Response Time** | 500ms | <100ms | 80% faster |
| **Image Load Time** | 2-5s | <500ms | 85% faster |
| **Data Sync Success** | N/A | 99.9% | Robust sync system |
| **Storage Efficiency** | N/A | <500MB | Optimized caching |

### 13.3 Key Benefits

**✅ Offline-First Architecture:**
- Complete functionality without internet
- Intelligent sync when connection restored
- User can work anywhere, anytime

**✅ Performance Improvements:**
- Direct file uploads (no API bottleneck)
- Local database for instant access
- Image caching and optimization
- Background sync for seamless updates

**✅ Developer Experience:**
- Type-safe GraphQL integration
- Clean architecture with proper separation
- Comprehensive error handling
- Extensive testing coverage

**✅ User Experience:**
- Instant app responsiveness
- Visual feedback for connectivity status
- Seamless online/offline transitions
- Bulk download for complete offline access

This comprehensive Flutter app documentation provides a complete roadmap for migrating the Terra Allwert application to a modern, offline-first architecture that integrates seamlessly with the new Go+GraphQL backend while providing superior user experience and developer maintainability.