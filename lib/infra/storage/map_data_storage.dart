import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/map_pin.dart';

/// Service para armazenamento local dos dados do mapa interativo
/// Funciona em web (SharedPreferences) e mobile/desktop (arquivos)
class MapDataStorage {
  static const String _fileName = 'interactive_map_data.json';
  static const String _webStoragePrefix = 'map_data_';
  
  /// Salva os dados do mapa interativo no storage local
  Future<void> saveMapData(InteractiveMapData mapData) async {
    try {
      final jsonData = mapData.toJson();
      final jsonString = jsonEncode(jsonData);
      
      if (kIsWeb) {
        // Web: usa SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final key = '$_webStoragePrefix${mapData.routeId}';
        await prefs.setString(key, jsonString);
      } else {
        // Mobile/Desktop: usa arquivos
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${mapData.routeId}_$_fileName');
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      throw Exception('Erro ao salvar dados do mapa: $e');
    }
  }
  
  /// Carrega os dados do mapa interativo do storage local
  Future<InteractiveMapData?> loadMapData(String routeId) async {
    try {
      String? jsonString;
      
      if (kIsWeb) {
        // Web: usa SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final key = '$_webStoragePrefix$routeId';
        jsonString = prefs.getString(key);
        
        if (jsonString == null) {
          return null;
        }
      } else {
        // Mobile/Desktop: usa arquivos
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${routeId}_$_fileName');
        
        if (!await file.exists()) {
          return null;
        }
        
        jsonString = await file.readAsString();
      }
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return InteractiveMapData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Erro ao carregar dados do mapa: $e');
    }
  }
  
  /// Exclui os dados do mapa interativo
  Future<void> deleteMapData(String routeId) async {
    try {
      if (kIsWeb) {
        // Web: usa SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final key = '$_webStoragePrefix$routeId';
        await prefs.remove(key);
      } else {
        // Mobile/Desktop: usa arquivos
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${routeId}_$_fileName');
        
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      throw Exception('Erro ao excluir dados do mapa: $e');
    }
  }
  
  /// Lista todas as rotas que possuem dados de mapa salvos
  Future<List<String>> getAvailableRoutes() async {
    try {
      final routes = <String>[];
      
      if (kIsWeb) {
        // Web: lista chaves do SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        
        for (final key in keys) {
          if (key.startsWith(_webStoragePrefix)) {
            final routeId = key.replaceFirst(_webStoragePrefix, '');
            routes.add(routeId);
          }
        }
      } else {
        // Mobile/Desktop: lista arquivos
        final directory = await getApplicationDocumentsDirectory();
        final directoryFiles = directory.listSync();
        
        for (final file in directoryFiles) {
          if (file is File && file.path.endsWith(_fileName)) {
            final fileName = file.path.split('/').last;
            final routeId = fileName.replaceAll('_$_fileName', '');
            routes.add(routeId);
          }
        }
      }
      
      return routes;
    } catch (e) {
      throw Exception('Erro ao listar rotas disponíveis: $e');
    }
  }
  
  /// Salva uma imagem localmente e retorna o path
  /// Na web, retorna a URL original (não faz download local)
  Future<String> saveImageLocally(String imageUrl, String fileName) async {
    try {
      if (kIsWeb) {
        // Web: não salva localmente, retorna URL original
        return imageUrl;
      } else {
        // Mobile/Desktop: salva no sistema de arquivos
        final directory = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${directory.path}/map_images');
        
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        
        final response = await HttpClient().getUrl(Uri.parse(imageUrl));
        final httpResponse = await response.close();
        
        final file = File('${imagesDir.path}/$fileName');
        await httpResponse.pipe(file.openWrite());
        
        return file.path;
      }
    } catch (e) {
      throw Exception('Erro ao salvar imagem localmente: $e');
    }
  }
  
  /// Remove uma imagem local
  /// Na web, não faz nada (não há arquivos locais para remover)
  Future<void> removeLocalImage(String imagePath) async {
    try {
      if (kIsWeb) {
        // Web: não há arquivos locais para remover
        return;
      } else {
        // Mobile/Desktop: remove arquivo do sistema
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      throw Exception('Erro ao remover imagem local: $e');
    }
  }
}