import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../logging/app_logger.dart';

/// Serviço de métricas de uso offline vs online
class UsageMetrics {
  static const String _keyMetricsData = 'usage_metrics_data';
  static const String _keySessionStart = 'current_session_start';
  
  final Connectivity _connectivity = Connectivity();
  final Completer<SharedPreferences> _prefsCompleter = Completer();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _sessionTimer;
  Timer? _metricsFlushTimer;
  
  // Estado atual
  bool _isOnline = true;
  DateTime? _sessionStart;
  DateTime? _lastConnectivityChange;
  final Map<String, int> _currentSessionMetrics = {};
  
  UsageMetrics() {
    _initialize();
  }
  
  /// Inicializa o serviço de métricas
  Future<void> _initialize() async {
    try {
      // Inicializar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (!_prefsCompleter.isCompleted) {
        _prefsCompleter.complete(prefs);
      }
      
      // Verificar conectividade inicial
      final connectivityResults = await _connectivity.checkConnectivity();
      _isOnline = !connectivityResults.contains(ConnectivityResult.none);
      
      // Começar sessão
      await _startSession();
      
      // Escutar mudanças de conectividade
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
      
      // Timer para flush periódico de métricas
      _metricsFlushTimer = Timer.periodic(Duration(minutes: 5), (_) => _flushMetrics());
      
      AppLogger.info('Usage metrics service initialized (${_isOnline ? 'online' : 'offline'})', tag: 'UsageMetrics');
      
    } catch (e) {
      AppLogger.error('Failed to initialize usage metrics: $e', tag: 'UsageMetrics');
    }
  }
  
  /// Inicia nova sessão de uso
  Future<void> _startSession() async {
    _sessionStart = DateTime.now();
    _lastConnectivityChange = _sessionStart;
    
    final prefs = await _prefsCompleter.future;
    await prefs.setString(_keySessionStart, _sessionStart!.toIso8601String());
    
    // Inicializar métricas da sessão
    _currentSessionMetrics.clear();
    _currentSessionMetrics.addAll({
      'session_duration_minutes': 0,
      'time_online_minutes': 0,
      'time_offline_minutes': 0,
      'connectivity_changes': 0,
      'files_accessed_online': 0,
      'files_accessed_offline': 0,
      'cache_hits': 0,
      'cache_misses': 0,
      'uploads_attempted': 0,
      'uploads_succeeded': 0,
      'uploads_failed': 0,
      'downloads_attempted': 0,
      'downloads_succeeded': 0,
      'downloads_failed': 0,
      'sync_operations': 0,
      'batch_operations': 0,
    });
    
    // Timer para atualizar duração da sessão
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(minutes: 1), (_) => _updateSessionDuration());
    
    AppLogger.debug('Started new usage session', tag: 'UsageMetrics');
  }
  
  /// Lida com mudanças de conectividade
  void _onConnectivityChanged(List<ConnectivityResult> connectivityResults) {
    final wasOnline = _isOnline;
    final isOnlineNow = !connectivityResults.contains(ConnectivityResult.none);
    
    if (wasOnline != isOnlineNow) {
      _isOnline = isOnlineNow;
      final now = DateTime.now();
      
      // Calcular tempo no estado anterior
      if (_lastConnectivityChange != null) {
        final duration = now.difference(_lastConnectivityChange!);
        final key = wasOnline ? 'time_online_minutes' : 'time_offline_minutes';
        _currentSessionMetrics[key] = _currentSessionMetrics[key]! + duration.inMinutes;
      }
      
      _lastConnectivityChange = now;
      _currentSessionMetrics['connectivity_changes'] = _currentSessionMetrics['connectivity_changes']! + 1;
      
      AppLogger.info('Connectivity changed: ${wasOnline ? 'online' : 'offline'} → ${isOnlineNow ? 'online' : 'offline'}', tag: 'UsageMetrics');
    }
  }
  
  /// Atualiza duração da sessão
  void _updateSessionDuration() {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!);
      _currentSessionMetrics['session_duration_minutes'] = duration.inMinutes;
      
      // Atualizar tempo no estado atual
      if (_lastConnectivityChange != null) {
        final stateDuration = DateTime.now().difference(_lastConnectivityChange!);
        final key = _isOnline ? 'time_online_minutes' : 'time_offline_minutes';
        final baseTime = _currentSessionMetrics[key]!;
        _currentSessionMetrics[key] = baseTime + stateDuration.inMinutes;
      }
    }
  }
  
  /// Registra acesso a arquivo
  void recordFileAccess({
    required String fileId,
    required bool wasFromCache,
    String? fileType,
    int? fileSize,
  }) {
    final key = _isOnline ? 'files_accessed_online' : 'files_accessed_offline';
    _currentSessionMetrics[key] = _currentSessionMetrics[key]! + 1;
    
    final cacheKey = wasFromCache ? 'cache_hits' : 'cache_misses';
    _currentSessionMetrics[cacheKey] = _currentSessionMetrics[cacheKey]! + 1;
    
    AppLogger.debug('File access recorded: $fileId (${_isOnline ? 'online' : 'offline'}, ${wasFromCache ? 'cache hit' : 'cache miss'})', tag: 'UsageMetrics');
  }
  
  /// Registra operação de upload
  void recordUpload({
    required bool attempted,
    required bool succeeded,
    String? fileId,
    int? fileSize,
    Duration? duration,
  }) {
    if (attempted) {
      _currentSessionMetrics['uploads_attempted'] = _currentSessionMetrics['uploads_attempted']! + 1;
    }
    
    if (succeeded) {
      _currentSessionMetrics['uploads_succeeded'] = _currentSessionMetrics['uploads_succeeded']! + 1;
    } else if (attempted) {
      _currentSessionMetrics['uploads_failed'] = _currentSessionMetrics['uploads_failed']! + 1;
    }
    
    AppLogger.debug('Upload recorded: attempted=$attempted, succeeded=$succeeded', tag: 'UsageMetrics');
  }
  
  /// Registra operação de download
  void recordDownload({
    required bool attempted,
    required bool succeeded,
    String? fileId,
    int? fileSize,
    Duration? duration,
  }) {
    if (attempted) {
      _currentSessionMetrics['downloads_attempted'] = _currentSessionMetrics['downloads_attempted']! + 1;
    }
    
    if (succeeded) {
      _currentSessionMetrics['downloads_succeeded'] = _currentSessionMetrics['downloads_succeeded']! + 1;
    } else if (attempted) {
      _currentSessionMetrics['downloads_failed'] = _currentSessionMetrics['downloads_failed']! + 1;
    }
    
    AppLogger.debug('Download recorded: attempted=$attempted, succeeded=$succeeded', tag: 'UsageMetrics');
  }
  
  /// Registra operação de sincronização
  void recordSyncOperation({
    required int filesProcessed,
    required bool succeeded,
    Duration? duration,
  }) {
    _currentSessionMetrics['sync_operations'] = _currentSessionMetrics['sync_operations']! + 1;
    
    AppLogger.debug('Sync operation recorded: $filesProcessed files, succeeded=$succeeded', tag: 'UsageMetrics');
  }
  
  /// Registra operação batch
  void recordBatchOperation({
    required int filesProcessed,
    required int succeeded,
    required int failed,
    Duration? duration,
  }) {
    _currentSessionMetrics['batch_operations'] = _currentSessionMetrics['batch_operations']! + 1;
    
    AppLogger.debug('Batch operation recorded: $filesProcessed files ($succeeded succeeded, $failed failed)', tag: 'UsageMetrics');
  }
  
  /// Força flush das métricas atuais
  Future<void> _flushMetrics() async {
    try {
      _updateSessionDuration();
      
      final prefs = await _prefsCompleter.future;
      final existingData = prefs.getString(_keyMetricsData);
      
      Map<String, dynamic> metricsData;
      if (existingData != null) {
        metricsData = jsonDecode(existingData);
      } else {
        metricsData = {
          'sessions': <Map<String, dynamic>>[],
          'total_metrics': <String, int>{},
        };
      }
      
      // Adicionar sessão atual se houver dados significativos
      if (_currentSessionMetrics['session_duration_minutes']! > 0) {
        final sessionData = Map<String, dynamic>.from(_currentSessionMetrics);
        sessionData['session_start'] = _sessionStart?.toIso8601String();
        sessionData['session_end'] = DateTime.now().toIso8601String();
        sessionData['platform'] = kIsWeb ? 'web' : Platform.operatingSystem;
        
        final sessions = List<Map<String, dynamic>>.from(metricsData['sessions']);
        sessions.add(sessionData);
        
        // Manter apenas as últimas 100 sessões
        if (sessions.length > 100) {
          sessions.removeRange(0, sessions.length - 100);
        }
        
        metricsData['sessions'] = sessions;
        
        // Atualizar métricas totais
        final totalMetrics = Map<String, int>.from(metricsData['total_metrics']);
        for (final entry in _currentSessionMetrics.entries) {
          totalMetrics[entry.key] = (totalMetrics[entry.key] ?? 0) + entry.value;
        }
        metricsData['total_metrics'] = totalMetrics;
        
        // Salvar
        await prefs.setString(_keyMetricsData, jsonEncode(metricsData));
        
        AppLogger.debug('Metrics flushed to storage', tag: 'UsageMetrics');
      }
    } catch (e) {
      AppLogger.error('Failed to flush metrics: $e', tag: 'UsageMetrics');
    }
  }
  
  /// Obtém métricas da sessão atual
  UsageSessionMetrics getCurrentSessionMetrics() {
    _updateSessionDuration();
    
    return UsageSessionMetrics(
      sessionStart: _sessionStart ?? DateTime.now(),
      sessionDuration: Duration(minutes: _currentSessionMetrics['session_duration_minutes']!),
      timeOnline: Duration(minutes: _currentSessionMetrics['time_online_minutes']!),
      timeOffline: Duration(minutes: _currentSessionMetrics['time_offline_minutes']!),
      connectivityChanges: _currentSessionMetrics['connectivity_changes']!,
      filesAccessedOnline: _currentSessionMetrics['files_accessed_online']!,
      filesAccessedOffline: _currentSessionMetrics['files_accessed_offline']!,
      cacheHits: _currentSessionMetrics['cache_hits']!,
      cacheMisses: _currentSessionMetrics['cache_misses']!,
      uploadsAttempted: _currentSessionMetrics['uploads_attempted']!,
      uploadsSucceeded: _currentSessionMetrics['uploads_succeeded']!,
      uploadsFailed: _currentSessionMetrics['uploads_failed']!,
      downloadsAttempted: _currentSessionMetrics['downloads_attempted']!,
      downloadsSucceeded: _currentSessionMetrics['downloads_succeeded']!,
      downloadsFailed: _currentSessionMetrics['downloads_failed']!,
      syncOperations: _currentSessionMetrics['sync_operations']!,
      batchOperations: _currentSessionMetrics['batch_operations']!,
      isCurrentlyOnline: _isOnline,
    );
  }
  
  /// Obtém métricas históricas
  Future<UsageHistoryMetrics> getHistoryMetrics() async {
    try {
      final prefs = await _prefsCompleter.future;
      final data = prefs.getString(_keyMetricsData);
      
      if (data == null) {
        return UsageHistoryMetrics.empty();
      }
      
      final metricsData = jsonDecode(data);
      final sessions = List<Map<String, dynamic>>.from(metricsData['sessions'] ?? []);
      final totalMetrics = Map<String, int>.from(metricsData['total_metrics'] ?? {});
      
      // Calcular estatísticas agregadas
      final now = DateTime.now();
      final last7Days = sessions.where((s) {
        final sessionStart = DateTime.parse(s['session_start']);
        return now.difference(sessionStart).inDays <= 7;
      }).toList();
      
      final last30Days = sessions.where((s) {
        final sessionStart = DateTime.parse(s['session_start']);
        return now.difference(sessionStart).inDays <= 30;
      }).toList();
      
      return UsageHistoryMetrics(
        totalSessions: sessions.length,
        totalTimeOnline: Duration(minutes: totalMetrics['time_online_minutes'] ?? 0),
        totalTimeOffline: Duration(minutes: totalMetrics['time_offline_minutes'] ?? 0),
        totalFilesAccessed: (totalMetrics['files_accessed_online'] ?? 0) + (totalMetrics['files_accessed_offline'] ?? 0),
        totalCacheHits: totalMetrics['cache_hits'] ?? 0,
        totalCacheMisses: totalMetrics['cache_misses'] ?? 0,
        totalUploads: totalMetrics['uploads_succeeded'] ?? 0,
        totalDownloads: totalMetrics['downloads_succeeded'] ?? 0,
        uploadSuccessRate: _calculateSuccessRate(
          totalMetrics['uploads_attempted'] ?? 0,
          totalMetrics['uploads_succeeded'] ?? 0,
        ),
        downloadSuccessRate: _calculateSuccessRate(
          totalMetrics['downloads_attempted'] ?? 0,
          totalMetrics['downloads_succeeded'] ?? 0,
        ),
        cacheHitRate: _calculateHitRate(
          totalMetrics['cache_hits'] ?? 0,
          totalMetrics['cache_misses'] ?? 0,
        ),
        last7DaysSessions: last7Days.length,
        last30DaysSessions: last30Days.length,
        offlineUsagePercentage: _calculateOfflinePercentage(totalMetrics),
      );
    } catch (e) {
      AppLogger.error('Failed to get history metrics: $e', tag: 'UsageMetrics');
      return UsageHistoryMetrics.empty();
    }
  }
  
  /// Calcula taxa de sucesso
  double _calculateSuccessRate(int attempted, int succeeded) {
    if (attempted == 0) return 0.0;
    return (succeeded / attempted) * 100;
  }
  
  /// Calcula taxa de hit do cache
  double _calculateHitRate(int hits, int misses) {
    final total = hits + misses;
    if (total == 0) return 0.0;
    return (hits / total) * 100;
  }
  
  /// Calcula porcentagem de uso offline
  double _calculateOfflinePercentage(Map<String, int> metrics) {
    final onlineTime = metrics['time_online_minutes'] ?? 0;
    final offlineTime = metrics['time_offline_minutes'] ?? 0;
    final totalTime = onlineTime + offlineTime;
    
    if (totalTime == 0) return 0.0;
    return (offlineTime / totalTime) * 100;
  }
  
  /// Limpa métricas antigas
  Future<void> clearOldMetrics({Duration? olderThan}) async {
    try {
      final cutoff = DateTime.now().subtract(olderThan ?? Duration(days: 90));
      final prefs = await _prefsCompleter.future;
      final data = prefs.getString(_keyMetricsData);
      
      if (data == null) return;
      
      final metricsData = jsonDecode(data);
      final sessions = List<Map<String, dynamic>>.from(metricsData['sessions'] ?? []);
      
      final filteredSessions = sessions.where((s) {
        final sessionStart = DateTime.parse(s['session_start']);
        return sessionStart.isAfter(cutoff);
      }).toList();
      
      if (filteredSessions.length != sessions.length) {
        metricsData['sessions'] = filteredSessions;
        await prefs.setString(_keyMetricsData, jsonEncode(metricsData));
        
        AppLogger.info('Cleaned ${sessions.length - filteredSessions.length} old metric sessions', tag: 'UsageMetrics');
      }
    } catch (e) {
      AppLogger.error('Failed to clear old metrics: $e', tag: 'UsageMetrics');
    }
  }
  
  /// Finaliza sessão e salva métricas
  Future<void> endSession() async {
    try {
      await _flushMetrics();
      _sessionTimer?.cancel();
      AppLogger.info('Usage session ended', tag: 'UsageMetrics');
    } catch (e) {
      AppLogger.error('Failed to end session: $e', tag: 'UsageMetrics');
    }
  }
  
  /// Dispose de recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _sessionTimer?.cancel();
    _metricsFlushTimer?.cancel();
  }
}

/// Métricas da sessão atual
class UsageSessionMetrics {
  final DateTime sessionStart;
  final Duration sessionDuration;
  final Duration timeOnline;
  final Duration timeOffline;
  final int connectivityChanges;
  final int filesAccessedOnline;
  final int filesAccessedOffline;
  final int cacheHits;
  final int cacheMisses;
  final int uploadsAttempted;
  final int uploadsSucceeded;
  final int uploadsFailed;
  final int downloadsAttempted;
  final int downloadsSucceeded;
  final int downloadsFailed;
  final int syncOperations;
  final int batchOperations;
  final bool isCurrentlyOnline;
  
  UsageSessionMetrics({
    required this.sessionStart,
    required this.sessionDuration,
    required this.timeOnline,
    required this.timeOffline,
    required this.connectivityChanges,
    required this.filesAccessedOnline,
    required this.filesAccessedOffline,
    required this.cacheHits,
    required this.cacheMisses,
    required this.uploadsAttempted,
    required this.uploadsSucceeded,
    required this.uploadsFailed,
    required this.downloadsAttempted,
    required this.downloadsSucceeded,
    required this.downloadsFailed,
    required this.syncOperations,
    required this.batchOperations,
    required this.isCurrentlyOnline,
  });
  
  /// Taxa de hit do cache
  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    if (total == 0) return 0.0;
    return (cacheHits / total) * 100;
  }
  
  /// Porcentagem de tempo offline
  double get offlinePercentage {
    final total = timeOnline + timeOffline;
    if (total.inMinutes == 0) return 0.0;
    return (timeOffline.inMinutes / total.inMinutes) * 100;
  }
  
  /// Taxa de sucesso de uploads
  double get uploadSuccessRate {
    if (uploadsAttempted == 0) return 0.0;
    return (uploadsSucceeded / uploadsAttempted) * 100;
  }
  
  /// Taxa de sucesso de downloads
  double get downloadSuccessRate {
    if (downloadsAttempted == 0) return 0.0;
    return (downloadsSucceeded / downloadsAttempted) * 100;
  }
}

/// Métricas históricas
class UsageHistoryMetrics {
  final int totalSessions;
  final Duration totalTimeOnline;
  final Duration totalTimeOffline;
  final int totalFilesAccessed;
  final int totalCacheHits;
  final int totalCacheMisses;
  final int totalUploads;
  final int totalDownloads;
  final double uploadSuccessRate;
  final double downloadSuccessRate;
  final double cacheHitRate;
  final int last7DaysSessions;
  final int last30DaysSessions;
  final double offlineUsagePercentage;
  
  UsageHistoryMetrics({
    required this.totalSessions,
    required this.totalTimeOnline,
    required this.totalTimeOffline,
    required this.totalFilesAccessed,
    required this.totalCacheHits,
    required this.totalCacheMisses,
    required this.totalUploads,
    required this.totalDownloads,
    required this.uploadSuccessRate,
    required this.downloadSuccessRate,
    required this.cacheHitRate,
    required this.last7DaysSessions,
    required this.last30DaysSessions,
    required this.offlineUsagePercentage,
  });
  
  factory UsageHistoryMetrics.empty() => UsageHistoryMetrics(
    totalSessions: 0,
    totalTimeOnline: Duration.zero,
    totalTimeOffline: Duration.zero,
    totalFilesAccessed: 0,
    totalCacheHits: 0,
    totalCacheMisses: 0,
    totalUploads: 0,
    totalDownloads: 0,
    uploadSuccessRate: 0.0,
    downloadSuccessRate: 0.0,
    cacheHitRate: 0.0,
    last7DaysSessions: 0,
    last30DaysSessions: 0,
    offlineUsagePercentage: 0.0,
  );
}