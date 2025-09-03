import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class SQLiteAdapter {
  static Database? _database;
  static const String _databaseName = 'terra_allwert.db';
  static const int _databaseVersion = 1;
  
  SQLiteAdapter._();
  
  static SQLiteAdapter? _instance;
  
  static Future<SQLiteAdapter> getInstance() async {
    if (_instance == null) {
      _instance = SQLiteAdapter._();
      await _instance!._initializeDatabase();
    }
    return _instance!;
  }
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }
  
  Future<Database> _initializeDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create tables for relational data
    
    // Sync relationships table
    await db.execute('''
      CREATE TABLE sync_relationships (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        local_id TEXT NOT NULL,
        remote_id TEXT,
        parent_local_id TEXT,
        parent_remote_id TEXT,
        relationship_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(entity_type, local_id, relationship_type)
      )
    ''');
    
    // Entity versions table for conflict resolution
    await db.execute('''
      CREATE TABLE entity_versions (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        version_number INTEGER NOT NULL,
        data_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(entity_type, entity_id, version_number)
      )
    ''');
    
    // Sync conflicts table
    await db.execute('''
      CREATE TABLE sync_conflicts (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_version INTEGER NOT NULL,
        remote_version INTEGER NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        resolved_at INTEGER,
        resolution_strategy TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // File relationships for offline files
    await db.execute('''
      CREATE TABLE file_relationships (
        id TEXT PRIMARY KEY,
        file_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        field_name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER,
        local_path TEXT,
        download_status TEXT NOT NULL DEFAULT 'pending',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(entity_type, entity_id, field_name, file_id)
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sync_relationships_entity ON sync_relationships(entity_type, local_id)');
    await db.execute('CREATE INDEX idx_sync_relationships_parent ON sync_relationships(parent_local_id)');
    await db.execute('CREATE INDEX idx_entity_versions_entity ON entity_versions(entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_sync_conflicts_entity ON sync_conflicts(entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_sync_conflicts_status ON sync_conflicts(status)');
    await db.execute('CREATE INDEX idx_file_relationships_entity ON file_relationships(entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_file_relationships_status ON file_relationships(download_status)');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }
  
  // ===== Sync Relationships Operations =====
  
  Future<void> saveSyncRelationship({
    required String id,
    required String entityType,
    required String localId,
    String? remoteId,
    String? parentLocalId,
    String? parentRemoteId,
    required String relationshipType,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'sync_relationships',
      {
        'id': id,
        'entity_type': entityType,
        'local_id': localId,
        'remote_id': remoteId,
        'parent_local_id': parentLocalId,
        'parent_remote_id': parentRemoteId,
        'relationship_type': relationshipType,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Map<String, dynamic>>> getSyncRelationships({
    String? entityType,
    String? localId,
    String? parentLocalId,
    String? relationshipType,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (entityType != null) {
      where += 'entity_type = ?';
      whereArgs.add(entityType);
    }
    
    if (localId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'local_id = ?';
      whereArgs.add(localId);
    }
    
    if (parentLocalId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'parent_local_id = ?';
      whereArgs.add(parentLocalId);
    }
    
    if (relationshipType != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'relationship_type = ?';
      whereArgs.add(relationshipType);
    }
    
    return await db.query(
      'sync_relationships',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );
  }
  
  Future<void> deleteSyncRelationship(String id) async {
    final db = await database;
    await db.delete('sync_relationships', where: 'id = ?', whereArgs: [id]);
  }
  
  // ===== Entity Versions Operations =====
  
  Future<void> saveEntityVersion({
    required String id,
    required String entityType,
    required String entityId,
    required int versionNumber,
    required String dataHash,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'entity_versions',
      {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'version_number': versionNumber,
        'data_hash': dataHash,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Map<String, dynamic>>> getEntityVersions({
    required String entityType,
    required String entityId,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      'entity_versions',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
      orderBy: 'version_number DESC',
      limit: limit,
    );
  }
  
  Future<Map<String, dynamic>?> getLatestEntityVersion({
    required String entityType,
    required String entityId,
  }) async {
    final versions = await getEntityVersions(
      entityType: entityType,
      entityId: entityId,
      limit: 1,
    );
    return versions.isNotEmpty ? versions.first : null;
  }
  
  // ===== Sync Conflicts Operations =====
  
  Future<void> saveSyncConflict({
    required String id,
    required String entityType,
    required String entityId,
    required int localVersion,
    required int remoteVersion,
    required String localData,
    required String remoteData,
    required String conflictType,
    String status = 'pending',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'sync_conflicts',
      {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'local_version': localVersion,
        'remote_version': remoteVersion,
        'local_data': localData,
        'remote_data': remoteData,
        'conflict_type': conflictType,
        'status': status,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Map<String, dynamic>>> getSyncConflicts({
    String? entityType,
    String? entityId,
    String? status,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (entityType != null) {
      where += 'entity_type = ?';
      whereArgs.add(entityType);
    }
    
    if (entityId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'entity_id = ?';
      whereArgs.add(entityId);
    }
    
    if (status != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'status = ?';
      whereArgs.add(status);
    }
    
    return await db.query(
      'sync_conflicts',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );
  }
  
  Future<void> updateConflictStatus({
    required String id,
    required String status,
    String? resolutionStrategy,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'sync_conflicts',
      {
        'status': status,
        'resolved_at': now,
        'resolution_strategy': resolutionStrategy,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ===== File Relationships Operations =====
  
  Future<void> saveFileRelationship({
    required String id,
    required String fileId,
    required String entityType,
    required String entityId,
    required String fieldName,
    required String fileType,
    int? fileSize,
    String? localPath,
    String downloadStatus = 'pending',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'file_relationships',
      {
        'id': id,
        'file_id': fileId,
        'entity_type': entityType,
        'entity_id': entityId,
        'field_name': fieldName,
        'file_type': fileType,
        'file_size': fileSize,
        'local_path': localPath,
        'download_status': downloadStatus,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Map<String, dynamic>>> getFileRelationships({
    String? entityType,
    String? entityId,
    String? downloadStatus,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (entityType != null) {
      where += 'entity_type = ?';
      whereArgs.add(entityType);
    }
    
    if (entityId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'entity_id = ?';
      whereArgs.add(entityId);
    }
    
    if (downloadStatus != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'download_status = ?';
      whereArgs.add(downloadStatus);
    }
    
    return await db.query(
      'file_relationships',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );
  }
  
  Future<void> updateFileDownloadStatus({
    required String id,
    required String downloadStatus,
    String? localPath,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'file_relationships',
      {
        'download_status': downloadStatus,
        'local_path': localPath,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ===== General Operations =====
  
  Future<void> clearAllTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sync_relationships');
      await txn.delete('entity_versions');
      await txn.delete('sync_conflicts');
      await txn.delete('file_relationships');
    });
  }
  
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}