import '../entities/tower.dart';

abstract class TowerRepository {
  Future<List<Tower>> getTowers();
  Future<Tower?> getTowerById(String id);
  Future<Tower> createTower(Tower tower);
  Future<Tower> updateTower(Tower tower);
  Future<void> deleteTower(String id);
  Future<List<Tower>> searchTowers(String query);
  Future<void> syncTowers();
  Stream<List<Tower>> watchTowers();
  Stream<Tower?> watchTowerById(String id);
}