import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/cache/file_lifecycle_manager.dart';

/// Provider para o FileLifecycleManager
final fileLifecycleManagerProvider = Provider<FileLifecycleManager>((ref) {
  // Configuração de retenção personalizada
  const config = RetentionConfiguration(
    defaultRetentionPeriod: Duration(days: 30), // 30 dias padrão
    minimumAccessCount: 3, // Mínimo 3 acessos para manter
    maxCacheSizeBytes: 500 * 1024 * 1024, // 500MB
    cleanupInterval: Duration(hours: 24), // Limpeza diária
    recentUsagePeriod: Duration(days: 7), // Considerar recente até 7 dias
  );
  
  final manager = FileLifecycleManager(config: config);
  
  // Inicializar automaticamente
  manager.initialize();
  
  return manager;
});

/// Provider para estatísticas do cache
final cacheStatisticsProvider = Provider<CacheStatistics>((ref) {
  final manager = ref.watch(fileLifecycleManagerProvider);
  return manager.getStatistics();
});

/// Provider para executar limpeza manual
final manualCleanupProvider = FutureProvider.family<CleanupResult, bool>((ref, force) async {
  final manager = ref.read(fileLifecycleManagerProvider);
  return await manager.performCleanup(force: force);
});

/// Provider para arquivos de uma entidade específica
final entityFilesProvider = Provider.family<List<FileLifecycleMetadata>, EntityFilter>((ref, filter) {
  final manager = ref.watch(fileLifecycleManagerProvider);
  return manager.getEntityFiles(filter.entityId, filter.entityType);
});

/// Filtro para buscar arquivos por entidade
class EntityFilter {
  final String entityId;
  final String entityType;

  const EntityFilter({
    required this.entityId,
    required this.entityType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityFilter &&
          runtimeType == other.runtimeType &&
          entityId == other.entityId &&
          entityType == other.entityType;

  @override
  int get hashCode => entityId.hashCode ^ entityType.hashCode;
}