import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../cache/cache_manager.dart';
import 'domain/entities/sync_status.dart';
import '../../features/towers/domain/repositories/tower_repository.dart';
import '../../features/apartments/domain/repositories/apartment_repository.dart';
import '../../features/gallery/domain/repositories/gallery_repository.dart';

abstract class SyncService {
  Future<void> initialize();
  Future<void> syncAll();
  Future<void> syncTowers();
  Future<void> syncApartments();
  Future<void> syncGallery();
  Future<void> schedulePendingSync();
  Stream<SyncStatus> watchSyncStatus();
  Future<void> dispose();
}

class SyncServiceImpl implements SyncService {
  final TowerRepository _towerRepository;
  final ApartmentRepository _apartmentRepository;
  final GalleryRepository _galleryRepository;
  final CacheManager _cacheManager;
  final Connectivity _connectivity;

  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  SyncStatus _currentStatus = SyncStatus(
    isConnected: false,
    isSyncing: false,
    lastSync: DateTime.now().subtract(const Duration(days: 1)),
  );

  SyncServiceImpl({
    required TowerRepository towerRepository,
    required ApartmentRepository apartmentRepository,
    required GalleryRepository galleryRepository,
    required CacheManager cacheManager,
    required Connectivity connectivity,
  })  : _towerRepository = towerRepository,
        _apartmentRepository = apartmentRepository,
        _galleryRepository = galleryRepository,
        _cacheManager = cacheManager,
        _connectivity = connectivity;

  @override
  Future<void> initialize() async {
    // Inicializa cache manager
    await _cacheManager.initialize();
    
    // Verifica conectividade inicial
    final connectivityResult = await _connectivity.checkConnectivity();
    _currentStatus = _currentStatus.copyWith(
      isConnected: !connectivityResult.contains(ConnectivityResult.none),
    );

    // Escuta mudanças de conectividade
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Configura sincronização periódica (a cada 5 minutos quando online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentStatus.isConnected && !_currentStatus.isSyncing) {
        syncAll();
      }
    });

    _syncStatusController.add(_currentStatus);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasConnected = _currentStatus.isConnected;
    final isConnected = !results.contains(ConnectivityResult.none);

    _currentStatus = _currentStatus.copyWith(isConnected: isConnected);
    _syncStatusController.add(_currentStatus);

    // Se voltou a ter conexão, faz sync automático
    if (!wasConnected && isConnected && !_currentStatus.isSyncing) {
      await Future.delayed(const Duration(seconds: 2)); // Aguarda estabilização
      await syncAll();
    }
  }

  @override
  Future<void> syncAll() async {
    if (_currentStatus.isSyncing) return;

    try {
      _currentStatus = _currentStatus.copyWith(isSyncing: true);
      _syncStatusController.add(_currentStatus);

      await Future.wait([
        syncTowers(),
        syncApartments(),
        syncGallery(),
      ]);

      _currentStatus = _currentStatus.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
        lastSyncByModule: {
          'towers': DateTime.now(),
          'apartments': DateTime.now(),
          'gallery': DateTime.now(),
        },
        failedSyncs: null,
        errorMessage: null,
      );
    } catch (error) {
      _currentStatus = _currentStatus.copyWith(
        isSyncing: false,
        failedSyncs: ['all'],
        errorMessage: error.toString(),
      );
    } finally {
      _syncStatusController.add(_currentStatus);
    }
  }

  @override
  Future<void> syncTowers() async {
    if (!_currentStatus.isConnected) {
      await schedulePendingSync();
      return;
    }

    try {
      await _towerRepository.syncTowers();
      
      // Atualiza status específico do módulo
      final newModuleSync = Map<String, DateTime>.from(_currentStatus.lastSyncByModule ?? {});
      newModuleSync['towers'] = DateTime.now();
      
      _currentStatus = _currentStatus.copyWith(lastSyncByModule: newModuleSync);
    } catch (error) {
      final failedSyncs = List<String>.from(_currentStatus.failedSyncs ?? []);
      if (!failedSyncs.contains('towers')) {
        failedSyncs.add('towers');
      }
      
      _currentStatus = _currentStatus.copyWith(
        failedSyncs: failedSyncs,
        errorMessage: 'Erro ao sincronizar towers: $error',
      );
    }
  }

  @override
  Future<void> syncApartments() async {
    if (!_currentStatus.isConnected) {
      await schedulePendingSync();
      return;
    }

    try {
      await _apartmentRepository.syncApartments();
      
      final newModuleSync = Map<String, DateTime>.from(_currentStatus.lastSyncByModule ?? {});
      newModuleSync['apartments'] = DateTime.now();
      
      _currentStatus = _currentStatus.copyWith(lastSyncByModule: newModuleSync);
    } catch (error) {
      final failedSyncs = List<String>.from(_currentStatus.failedSyncs ?? []);
      if (!failedSyncs.contains('apartments')) {
        failedSyncs.add('apartments');
      }
      
      _currentStatus = _currentStatus.copyWith(
        failedSyncs: failedSyncs,
        errorMessage: 'Erro ao sincronizar apartments: $error',
      );
    }
  }

  @override
  Future<void> syncGallery() async {
    if (!_currentStatus.isConnected) {
      await schedulePendingSync();
      return;
    }

    try {
      await _galleryRepository.syncImages();
      
      final newModuleSync = Map<String, DateTime>.from(_currentStatus.lastSyncByModule ?? {});
      newModuleSync['gallery'] = DateTime.now();
      
      _currentStatus = _currentStatus.copyWith(lastSyncByModule: newModuleSync);
    } catch (error) {
      final failedSyncs = List<String>.from(_currentStatus.failedSyncs ?? []);
      if (!failedSyncs.contains('gallery')) {
        failedSyncs.add('gallery');
      }
      
      _currentStatus = _currentStatus.copyWith(
        failedSyncs: failedSyncs,
        errorMessage: 'Erro ao sincronizar gallery: $error',
      );
    }
  }

  @override
  Future<void> schedulePendingSync() async {
    // Salva no cache que há sincronização pendente
    await _cacheManager.cacheData('pending_sync', {
      'scheduledAt': DateTime.now().millisecondsSinceEpoch,
      'modules': ['towers', 'apartments', 'gallery'],
    });
  }

  @override
  Stream<SyncStatus> watchSyncStatus() {
    return _syncStatusController.stream;
  }

  @override
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    await _syncStatusController.close();
  }
}

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final syncServiceProvider = Provider<SyncService>((ref) {
  final towerRepository = ref.watch(towerRepositoryProvider);
  final apartmentRepository = ref.watch(apartmentRepositoryProvider);
  final galleryRepository = ref.watch(galleryRepositoryProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  final connectivity = ref.watch(connectivityProvider);

  return SyncServiceImpl(
    towerRepository: towerRepository,
    apartmentRepository: apartmentRepository,
    galleryRepository: galleryRepository,
    cacheManager: cacheManager,
    connectivity: connectivity,
  );
});

final syncServiceInitProvider = FutureProvider<void>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  await syncService.initialize();
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.watchSyncStatus();
});

// Providers fictícios para compilar - devem ser implementados depois
final towerRepositoryProvider = Provider<TowerRepository>((ref) => throw UnimplementedError());
final apartmentRepositoryProvider = Provider<ApartmentRepository>((ref) => throw UnimplementedError());
final galleryRepositoryProvider = Provider<GalleryRepository>((ref) => throw UnimplementedError());