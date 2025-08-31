import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/infra/downloads/download_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('DownloadTask', () {
    test('should create download task with required fields', () {
      const task = DownloadTask(
        id: '1',
        url: 'https://example.com/file.pdf',
        fileName: 'file.pdf',
        status: DownloadStatus.pending,
      );

      expect(task.id, equals('1'));
      expect(task.url, equals('https://example.com/file.pdf'));
      expect(task.fileName, equals('file.pdf'));
      expect(task.status, equals(DownloadStatus.pending));
      expect(task.downloadedBytes, equals(0));
      expect(task.progress, equals(0.0));
    });

    test('should copy task with updated values', () {
      const original = DownloadTask(
        id: '1',
        url: 'https://example.com/file.pdf',
        fileName: 'file.pdf',
        status: DownloadStatus.pending,
      );

      final updated = original.copyWith(
        status: DownloadStatus.downloading,
        downloadedBytes: 1024,
        progress: 0.5,
      );

      expect(updated.id, equals(original.id));
      expect(updated.url, equals(original.url));
      expect(updated.fileName, equals(original.fileName));
      expect(updated.status, equals(DownloadStatus.downloading));
      expect(updated.downloadedBytes, equals(1024));
      expect(updated.progress, equals(0.5));
    });
  });

  group('DownloadManagerImpl', () {
    late DownloadManager downloadManager;

    setUp(() {
      downloadManager = DownloadManagerImpl();
    });

    test('should initialize successfully', () {
      // Test initialization without file system access
      expect(downloadManager, isA<DownloadManager>());
    });

    test('should provide download directory interface', () {
      // Test that the method exists
      expect(downloadManager.downloadDirectory, isA<Future<String>>());
    }, skip: 'Requires platform plugins');

    test('should start with empty active downloads', () {
      expect(downloadManager.activeDownloads, isEmpty);
    });

    test('should provide download stream', () {
      expect(downloadManager.downloadStream, isA<Stream<DownloadTask>>());
    });

    test('should clear completed downloads', () async {
      await downloadManager.clearCompleted();
      expect(downloadManager.activeDownloads, isEmpty);
    });

    group('Download Status', () {
      test('should handle all download statuses', () {
        const statuses = DownloadStatus.values;
        expect(statuses, contains(DownloadStatus.pending));
        expect(statuses, contains(DownloadStatus.downloading));
        expect(statuses, contains(DownloadStatus.completed));
        expect(statuses, contains(DownloadStatus.failed));
        expect(statuses, contains(DownloadStatus.cancelled));
      });
    });

    // Note: Testing actual downloads would require mocking network calls
    // For now, we test the structure and basic functionality
  });
}