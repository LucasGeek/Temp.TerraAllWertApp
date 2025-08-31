import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/floor_plan_data.dart';

/// Service para armazenamento local dos dados de plantas de pavimento
class FloorPlanStorage {
  static const String _fileName = 'floor_plan_data.json';
  
  /// Salva os dados da planta no storage local
  Future<void> saveFloorPlanData(FloorPlanData floorPlanData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${floorPlanData.routeId}_$_fileName');
      
      final jsonData = floorPlanData.toJson();
      final jsonString = jsonEncode(jsonData);
      
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Erro ao salvar dados da planta: $e');
    }
  }
  
  /// Carrega os dados da planta do storage local
  Future<FloorPlanData?> loadFloorPlanData(String routeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${routeId}_$_fileName');
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return FloorPlanData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Erro ao carregar dados da planta: $e');
    }
  }
  
  /// Exclui os dados da planta
  Future<void> deleteFloorPlanData(String routeId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${routeId}_$_fileName');
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao excluir dados da planta: $e');
    }
  }
  
  /// Lista todas as rotas que possuem dados de planta salvos
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
      final imagesDir = Directory('${directory.path}/floor_plan_images');
      
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
  
  /// Salva um PDF localmente e retorna o path
  Future<String> savePdfLocally(String pdfUrl, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfsDir = Directory('${directory.path}/floor_plan_pdfs');
      
      if (!await pdfsDir.exists()) {
        await pdfsDir.create(recursive: true);
      }
      
      final response = await HttpClient().getUrl(Uri.parse(pdfUrl));
      final httpResponse = await response.close();
      
      final file = File('${pdfsDir.path}/$fileName');
      await httpResponse.pipe(file.openWrite());
      
      return file.path;
    } catch (e) {
      throw Exception('Erro ao salvar PDF localmente: $e');
    }
  }
  
  /// Remove um arquivo local
  Future<void> removeLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao remover arquivo local: $e');
    }
  }
}