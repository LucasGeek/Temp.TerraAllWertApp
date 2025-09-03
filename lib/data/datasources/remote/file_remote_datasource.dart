import '../../../infra/http/rest_client.dart';
import '../../models/file_dto.dart';
import '../../models/file_variant_dto.dart';
import 'package:dio/dio.dart';

abstract class FileRemoteDataSource {
  // File operations
  Future<FileDto> uploadFile(String filePath, String fileName);
  Future<FileDto> uploadOptimized(String filePath, Map<String, dynamic> options);
  Future<String> createMultipartUpload(String fileName, int fileSize);
  Future<void> completeMultipartUpload(String fileId, List<String> etags);
  Future<void> abortMultipartUpload(String uploadId);
  Future<FileDto> getFileById(String id);
  Future<String> getDownloadUrl(String id);
  Future<void> deleteFile(String id);
  
  // File variant operations
  Future<List<FileVariantDto>> getFileVariants(String fileId);
  Future<FileVariantDto> getFileVariant(String fileId, String variantName);
  Future<FileVariantDto> createFileVariant(FileVariantDto variant);
  Future<String> getVariantDownloadUrl(String variantId);
  Future<String> getVariantUploadUrl(String variantId);
  Future<void> deleteFileVariant(String id);
  
  // Upload progress
  Future<Map<String, dynamic>> getUploadProgress(String uploadId);
}

class FileRemoteDataSourceImpl implements FileRemoteDataSource {
  final RestClient _client;
  
  FileRemoteDataSourceImpl(this._client);
  
  @override
  Future<FileDto> uploadFile(String filePath, String fileName) async {
    try {
      // Simple file upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'fileName': fileName,
      });
      
      final response = await _client.post('/files', data: formData);
      return FileDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }
  
  @override
  Future<FileDto> uploadOptimized(String filePath, Map<String, dynamic> options) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        ...options,
      });
      
      final response = await _client.post('/files/optimized-upload', data: formData);
      return FileDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload optimized file: ${e.toString()}');
    }
  }
  
  @override
  Future<String> createMultipartUpload(String fileName, int fileSize) async {
    try {
      final response = await _client.post(
        '/files/multipart-upload',
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
        },
      );
      return response.data['uploadId'];
    } catch (e) {
      throw Exception('Failed to create multipart upload: ${e.toString()}');
    }
  }
  
  @override
  Future<void> completeMultipartUpload(String fileId, List<String> etags) async {
    try {
      await _client.post(
        '/files/$fileId/complete-multipart',
        data: {'etags': etags},
      );
    } catch (e) {
      throw Exception('Failed to complete multipart upload: ${e.toString()}');
    }
  }
  
  @override
  Future<void> abortMultipartUpload(String uploadId) async {
    try {
      await _client.delete('/files/optimized-upload/$uploadId/abort');
    } catch (e) {
      throw Exception('Failed to abort multipart upload: ${e.toString()}');
    }
  }
  
  @override
  Future<FileDto> getFileById(String id) async {
    try {
      final response = await _client.get('/files/$id');
      return FileDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get file: ${e.toString()}');
    }
  }
  
  @override
  Future<String> getDownloadUrl(String id) async {
    try {
      final response = await _client.get('/files/$id/download-url');
      return response.data['url'];
    } catch (e) {
      throw Exception('Failed to get download URL: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteFile(String id) async {
    try {
      await _client.delete('/files/$id');
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }
  
  // ===== File Variant Operations =====
  
  @override
  Future<List<FileVariantDto>> getFileVariants(String fileId) async {
    try {
      final response = await _client.get('/files/$fileId/variants');
      final List<dynamic> data = response.data;
      return data.map((json) => FileVariantDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get file variants: ${e.toString()}');
    }
  }
  
  @override
  Future<FileVariantDto> getFileVariant(String fileId, String variantName) async {
    try {
      final response = await _client.get('/files/$fileId/variants/$variantName');
      return FileVariantDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get file variant: ${e.toString()}');
    }
  }
  
  @override
  Future<FileVariantDto> createFileVariant(FileVariantDto variant) async {
    try {
      final response = await _client.post(
        '/file-variants',
        data: variant.toJson(),
      );
      return FileVariantDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create file variant: ${e.toString()}');
    }
  }
  
  @override
  Future<String> getVariantDownloadUrl(String variantId) async {
    try {
      final response = await _client.get('/file-variants/$variantId/download-url');
      return response.data['url'];
    } catch (e) {
      throw Exception('Failed to get variant download URL: ${e.toString()}');
    }
  }
  
  @override
  Future<String> getVariantUploadUrl(String variantId) async {
    try {
      final response = await _client.get('/file-variants/$variantId/upload-url');
      return response.data['url'];
    } catch (e) {
      throw Exception('Failed to get variant upload URL: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteFileVariant(String id) async {
    try {
      await _client.delete('/file-variants/$id');
    } catch (e) {
      throw Exception('Failed to delete file variant: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getUploadProgress(String uploadId) async {
    try {
      final response = await _client.get('/files/upload-progress/$uploadId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get upload progress: ${e.toString()}');
    }
  }
}