import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/platform_service.dart';

enum TaskPriority { low, normal, high }

class IsolateTask<T> {
  final String id;
  final Function function;
  final dynamic data;
  final TaskPriority priority;
  final Completer<T> completer;
  final DateTime createdAt;

  IsolateTask({
    required this.id,
    required this.function,
    this.data,
    this.priority = TaskPriority.normal,
    required this.completer,
  }) : createdAt = DateTime.now();
}

abstract class ConcurrencyManager {
  Future<void> initialize();
  Future<T> runTask<T>(Function function, {dynamic data, TaskPriority priority});
  Future<List<T>> runParallelTasks<T>(List<Function> functions, {dynamic data});
  Future<void> dispose();
  
  int get activeTasksCount;
  int get queuedTasksCount;
}

class IsolateManagerImpl implements ConcurrencyManager {
  final int _maxIsolates;
  final List<Isolate> _isolates = [];
  final List<IsolateTask> _taskQueue = [];
  final Map<String, IsolateTask> _activeTasks = {};
  
  bool _isInitialized = false;
  int _taskIdCounter = 0;

  IsolateManagerImpl({int? maxIsolates}) 
    : _maxIsolates = maxIsolates ?? (PlatformService.isMobile ? 2 : 4);

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (!PlatformService.supportsIsolates) {
      _isInitialized = true;
      return;
    }

    // Pré-cria isolates se não estivermos na web
    if (!kIsWeb) {
      for (int i = 0; i < _maxIsolates; i++) {
        await _createIsolate();
      }
    }
    
    _isInitialized = true;
  }

  Future<void> _createIsolate() async {
    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateEntryPoint,
        receivePort.sendPort,
      );
      
      _isolates.add(isolate);
      
      // Escuta respostas do isolate
      receivePort.listen((message) {
        _handleIsolateResponse(message);
      });
      
    } catch (e) {
      debugPrint('Erro ao criar isolate: $e');
    }
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((message) {
      _processTask(message, sendPort);
    });
  }

  static void _processTask(dynamic message, SendPort sendPort) {
    try {
      final taskData = message as Map<String, dynamic>;
      final taskId = taskData['id'] as String;
      final function = taskData['function'] as Function;
      final data = taskData['data'];
      
      final result = function(data);
      
      sendPort.send({
        'taskId': taskId,
        'result': result,
        'error': null,
      });
    } catch (error) {
      sendPort.send({
        'taskId': message['id'],
        'result': null,
        'error': error.toString(),
      });
    }
  }

  void _handleIsolateResponse(dynamic message) {
    final response = message as Map<String, dynamic>;
    final taskId = response['taskId'] as String;
    
    final task = _activeTasks[taskId];
    if (task != null) {
      if (response['error'] != null) {
        task.completer.completeError(Exception(response['error']));
      } else {
        task.completer.complete(response['result']);
      }
      
      _activeTasks.remove(taskId);
      _processQueue();
    }
  }

  @override
  Future<T> runTask<T>(Function function, {dynamic data, TaskPriority priority = TaskPriority.normal}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Se não suporta isolates ou é web, executa na thread principal
    if (!PlatformService.supportsIsolates || kIsWeb) {
      return await compute(function as T Function(dynamic), data);
    }

    final taskId = (_taskIdCounter++).toString();
    final completer = Completer<T>();
    
    final task = IsolateTask<T>(
      id: taskId,
      function: function,
      data: data,
      priority: priority,
      completer: completer,
    );

    if (_activeTasks.length < _maxIsolates) {
      _executeTask(task);
    } else {
      _queueTask(task);
    }

    return completer.future;
  }

  void _queueTask(IsolateTask task) {
    // Insere na posição correta baseado na prioridade
    int insertIndex = _taskQueue.length;
    
    for (int i = 0; i < _taskQueue.length; i++) {
      if (_taskQueue[i].priority.index < task.priority.index) {
        insertIndex = i;
        break;
      }
    }
    
    _taskQueue.insert(insertIndex, task);
  }

  void _executeTask(IsolateTask task) {
    _activeTasks[task.id] = task;
    
    // Simula envio para isolate
    // Na implementação real, enviaria para um isolate disponível
    Timer(Duration(milliseconds: 100), () {
      try {
        final result = task.function(task.data);
        task.completer.complete(result);
        _activeTasks.remove(task.id);
        _processQueue();
      } catch (error) {
        task.completer.completeError(error);
        _activeTasks.remove(task.id);
        _processQueue();
      }
    });
  }

  void _processQueue() {
    while (_taskQueue.isNotEmpty && _activeTasks.length < _maxIsolates) {
      final task = _taskQueue.removeAt(0);
      _executeTask(task);
    }
  }

  @override
  Future<List<T>> runParallelTasks<T>(List<Function> functions, {dynamic data}) async {
    final futures = functions.map((function) => runTask<T>(function, data: data)).toList();
    return await Future.wait(futures);
  }

  @override
  Future<void> dispose() async {
    // Cancela todas as tasks pendentes
    for (final task in _taskQueue) {
      task.completer.completeError(Exception('Manager disposed'));
    }
    _taskQueue.clear();
    
    for (final task in _activeTasks.values) {
      task.completer.completeError(Exception('Manager disposed'));
    }
    _activeTasks.clear();
    
    // Mata todos os isolates
    for (final isolate in _isolates) {
      isolate.kill();
    }
    _isolates.clear();
    
    _isInitialized = false;
  }

  @override
  int get activeTasksCount => _activeTasks.length;

  @override
  int get queuedTasksCount => _taskQueue.length;
}

// Implementação alternativa para Web usando Web Workers (conceitual)
class WebWorkerManagerImpl implements ConcurrencyManager {
  bool _isInitialized = false;
  final List<IsolateTask> _taskQueue = [];
  int _activeTasks = 0;
  int _taskIdCounter = 0;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<T> runTask<T>(Function function, {dynamic data, TaskPriority priority = TaskPriority.normal}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Para web, usa compute do Flutter que gerencia a execução
    return await compute(function as T Function(dynamic), data);
  }

  @override
  Future<List<T>> runParallelTasks<T>(List<Function> functions, {dynamic data}) async {
    final futures = functions.map((function) => runTask<T>(function, data: data)).toList();
    return await Future.wait(futures);
  }

  @override
  Future<void> dispose() async {
    _taskQueue.clear();
    _activeTasks = 0;
    _isInitialized = false;
  }

  @override
  int get activeTasksCount => _activeTasks;

  @override
  int get queuedTasksCount => _taskQueue.length;
}

final concurrencyManagerProvider = Provider<ConcurrencyManager>((ref) {
  if (PlatformService.isWeb) {
    return WebWorkerManagerImpl();
  }
  return IsolateManagerImpl();
});

final concurrencyManagerInitProvider = FutureProvider<void>((ref) async {
  final manager = ref.watch(concurrencyManagerProvider);
  await manager.initialize();
});

// Funções utilitárias para tarefas comuns
class ConcurrencyHelpers {
  static Future<List<T>> processListInParallel<T, R>(
    List<T> items,
    R Function(T item) processor,
    {int? batchSize}
  ) async {
    final effectiveBatchSize = batchSize ?? (PlatformService.isMobile ? 5 : 10);
    final results = <R>[];
    
    for (int i = 0; i < items.length; i += effectiveBatchSize) {
      final batch = items.skip(i).take(effectiveBatchSize);
      final batchFutures = batch.map((item) => compute(processor, item));
      final batchResults = await Future.wait(batchFutures);
      results.addAll(batchResults);
    }
    
    return results.cast<T>();
  }

  static Future<T> runWithTimeout<T>(
    Future<T> Function() task,
    Duration timeout,
  ) async {
    return await task().timeout(timeout);
  }

  static Future<T?> runSafely<T>(
    Future<T> Function() task, {
    T? fallback,
    void Function(dynamic error)? onError,
  }) async {
    try {
      return await task();
    } catch (error) {
      onError?.call(error);
      return fallback;
    }
  }
}