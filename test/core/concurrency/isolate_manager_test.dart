import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/core/concurrency/isolate_manager.dart';

// Test functions to be run in isolates/compute
int addNumbers(int a) => a + 10;
String reverseString(String input) => input.split('').reversed.join('');
int multiply(int a) => a * 2;
List<int> processNumbers(List<int> numbers) {
  return numbers.map((n) => n * 2).toList();
}

void main() {
  group('IsolateTask', () {
    test('should create isolate task with required fields', () {
      final task = IsolateTask<int>(
        id: '1',
        function: addNumbers,
        data: 5,
        completer: Completer<int>(),
      );

      expect(task.id, equals('1'));
      expect(task.function, equals(addNumbers));
      expect(task.data, equals(5));
      expect(task.priority, equals(TaskPriority.normal));
      expect(task.createdAt, isA<DateTime>());
    });

    test('should create task with custom priority', () {
      final task = IsolateTask<int>(
        id: '1',
        function: addNumbers,
        priority: TaskPriority.high,
        completer: Completer<int>(),
      );

      expect(task.priority, equals(TaskPriority.high));
    });
  });

  group('TaskPriority', () {
    test('should have correct priority ordering', () {
      expect(TaskPriority.low.index, lessThan(TaskPriority.normal.index));
      expect(TaskPriority.normal.index, lessThan(TaskPriority.high.index));
    });
  });

  group('IsolateManagerImpl', () {
    late ConcurrencyManager manager;

    setUp(() {
      manager = IsolateManagerImpl();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('should initialize successfully', () async {
      expect(manager, isNotNull);
      expect(manager.activeTasksCount, equals(0));
      expect(manager.queuedTasksCount, equals(0));
    });

    test('should dispose cleanly', () async {
      await manager.dispose();
      expect(manager.activeTasksCount, equals(0));
      expect(manager.queuedTasksCount, equals(0));
    });
  }, skip: 'Complex isolate communication needs proper mock setup');

  group('WebWorkerManagerImpl', () {
    late ConcurrencyManager manager;

    setUp(() {
      manager = WebWorkerManagerImpl();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('should initialize successfully', () async {
      await manager.initialize();
      expect(manager, isNotNull);
    });

    test('should run computation task', () async {
      await manager.initialize();
      
      final result = await manager.runTask<int>(addNumbers, data: 10);
      expect(result, equals(20));
    });

    test('should run parallel tasks', () async {
      await manager.initialize();
      
      final functions = [
        (int data) => addNumbers(data),
        (int data) => multiply(data),
      ];
      
      final results = await manager.runParallelTasks<int>(functions, data: 3);
      
      expect(results, hasLength(2));
      expect(results[0], equals(13)); // 3 + 10
      expect(results[1], equals(6));  // 3 * 2
    });
  });

  group('ConcurrencyHelpers', () {
    test('should process list in parallel', () async {
      final items = [1, 2, 3, 4, 5];
      
      final results = await ConcurrencyHelpers.processListInParallel<int, int>(
        items,
        (item) => item * 2,
        batchSize: 2,
      );
      
      expect(results, equals([2, 4, 6, 8, 10]));
    });

    test('should run task with timeout', () async {
      final result = await ConcurrencyHelpers.runWithTimeout<int>(
        () async {
          await Future.delayed(Duration(milliseconds: 100));
          return 42;
        },
        Duration(seconds: 1),
      );
      
      expect(result, equals(42));
    });

    test('should handle timeout exception', () async {
      expect(
        () => ConcurrencyHelpers.runWithTimeout<int>(
          () async {
            await Future.delayed(Duration(seconds: 2));
            return 42;
          },
          Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should run safely with fallback', () async {
      final result = await ConcurrencyHelpers.runSafely<int>(
        () async => throw Exception('Test error'),
        fallback: 999,
      );
      
      expect(result, equals(999));
    });

    test('should run safely and call error handler', () async {
      dynamic capturedError;
      
      final result = await ConcurrencyHelpers.runSafely<int>(
        () async => throw Exception('Test error'),
        fallback: 123,
        onError: (error) => capturedError = error,
      );
      
      expect(result, equals(123));
      expect(capturedError, isA<Exception>());
    });
  });
}