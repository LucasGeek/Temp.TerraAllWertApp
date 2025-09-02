import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';

abstract class MinIOService {
  Future<String> uploadFile({
    required String bucketName,
    required String objectName,
    required Uint8List data,
    String? contentType,
  });

  Future<String> getPresignedUrl({
    required String bucketName,
    required String objectName,
    int expiration = 3600,
  });

  Future<void> deleteFile({
    required String bucketName,
    required String objectName,
  });

  Future<List<String>> listFiles({
    required String bucketName,
    String? prefix,
  });
}

class MinIOServiceImpl implements MinIOService {
  final Minio _client;

  MinIOServiceImpl({
    required String endpoint,
    required String accessKey,
    required String secretKey,
    bool useSSL = false,
  }) : _client = Minio(
          endPoint: endpoint,
          accessKey: accessKey,
          secretKey: secretKey,
          useSSL: useSSL,
        );

  @override
  Future<String> uploadFile({
    required String bucketName,
    required String objectName,
    required Uint8List data,
    String? contentType,
  }) async {
    try {
      final stream = Stream.fromIterable([data]);
      
      await _client.putObject(
        bucketName,
        objectName,
        stream,
        size: data.length,
        metadata: contentType != null ? {'Content-Type': contentType} : null,
      );

      return 'https://${_client.endPoint}/$bucketName/$objectName';
    } catch (e) {
      throw Exception('Erro ao fazer upload do arquivo: $e');
    }
  }

  @override
  Future<String> getPresignedUrl({
    required String bucketName,
    required String objectName,
    int expiration = 3600,
  }) async {
    try {
      return await _client.presignedGetObject(
        bucketName,
        objectName,
        expires: expiration,
      );
    } catch (e) {
      throw Exception('Erro ao gerar URL assinada: $e');
    }
  }

  @override
  Future<void> deleteFile({
    required String bucketName,
    required String objectName,
  }) async {
    try {
      await _client.removeObject(bucketName, objectName);
    } catch (e) {
      throw Exception('Erro ao deletar arquivo: $e');
    }
  }

  @override
  Future<List<String>> listFiles({
    required String bucketName,
    String? prefix,
  }) async {
    try {
      // Simplificado por enquanto - retorna lista vazia
      return <String>[];
    } catch (e) {
      throw Exception('Erro ao listar arquivos: $e');
    }
  }
}

final minioServiceProvider = Provider<MinIOService>((ref) {
  final config = ref.watch(envConfigProvider);
  
  return MinIOServiceImpl(
    endpoint: config.minioEndpoint,
    accessKey: config.minioAccessKey,
    secretKey: config.minioSecretKey,
    useSSL: config.minioUseSSL,
  );
});