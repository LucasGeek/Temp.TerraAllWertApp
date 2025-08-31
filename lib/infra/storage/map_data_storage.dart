import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/map_pin.dart';

/// Service para armazenamento local dos dados do mapa interativo
class MapDataStorage {
  static const String _fileName = 'interactive_map_data.json';
  
  /// Salva os dados do mapa interativo no storage local
  Future<void> saveMapData(InteractiveMapData mapData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${mapData.routeId}_$_fileName');
      
      final jsonData = mapData.toJson();
      final jsonString = jsonEncode(jsonData);
      
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Erro ao salvar dados do mapa: $e');
    }
  }
  
  /// Carrega os dados do mapa interativo do storage local
  Future<InteractiveMapData?> loadMapData(String routeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${routeId}_$_fileName');
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return InteractiveMapData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Erro ao carregar dados do mapa: $e');
    }
  }
  
  /// Exclui os dados do mapa interativo
  Future<void> deleteMapData(String routeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${routeId}_$_fileName');
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao excluir dados do mapa: $e');
    }
  }
  
  /// Lista todas as rotas que possuem dados de mapa salvos
  Future<List<String>> getAvailableRoutes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final directoryFiles = directory.listSync();
      
      final routes = <String>[];
      
      for (final file in directoryFiles) {
        if (file is File && file.path.endsWith(_fileName)) {
          final fileName = file.path.split('/').last;
          final routeId = fileName.replaceAll('_$_fileName', '');
          routes.add(routeId);
        }
      }
      
      return routes;
    } catch (e) {
      throw Exception('Erro ao listar rotas disponíveis: $e');
    }
  }
  
  /// Salva uma imagem localmente e retorna o path
  Future<String> saveImageLocally(String imageUrl, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final response = await HttpClient().getUrl(Uri.parse(imageUrl));
      final httpResponse = await response.close();
      
      final file = File('${imagesDir.path}/$fileName');
      await httpResponse.pipe(file.openWrite());
      
      return file.path;
    } catch (e) {
      throw Exception('Erro ao salvar imagem localmente: $e');
    }
  }
  
  /// Remove uma imagem local
  Future<void> removeLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao remover imagem local: $e');
    }
  }
}