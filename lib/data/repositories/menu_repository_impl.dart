import '../../domain/entities/menu.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/local/menu_local_datasource.dart';
import '../datasources/remote/menu_remote_datasource.dart';
import '../models/menu_dto.dart';
import 'package:uuid/uuid.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuLocalDataSource _localDataSource;
  final MenuRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  MenuRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<Menu> create(Menu menu) async {
    try {
      // Offline-first: create locally first
      final localMenu = menu.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localMenu);
      
      // Try to sync with remote
      try {
        final dto = localMenu.toDto();
        final remoteDto = await _remoteDataSource.create(dto);
        
        // Update with remote ID and mark as synced
        final syncedMenu = localMenu.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        
        await _localDataSource.save(syncedMenu);
        return syncedMenu;
      } catch (e) {
        // Keep local copy for later sync
        return localMenu;
      }
    } catch (e) {
      throw Exception('Failed to create menu: ${e.toString()}');
    }
  }
  
  @override
  Future<Menu> update(Menu menu) async {
    try {
      // Update locally first
      final updatedMenu = menu.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedMenu);
      
      // Try to sync with remote if has remote ID
      if (menu.remoteId != null) {
        try {
          final dto = updatedMenu.toDto();
          await _remoteDataSource.update(menu.remoteId!, dto);
          
          // Mark as synced
          final syncedMenu = updatedMenu.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.save(syncedMenu);
          return syncedMenu;
        } catch (e) {
          // Keep local copy for later sync
          return updatedMenu;
        }
      }
      
      return updatedMenu;
    } catch (e) {
      throw Exception('Failed to update menu: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final menu = await _localDataSource.getById(localId);
      if (menu == null) return;
      
      // Soft delete locally
      final deletedMenu = menu.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedMenu);
      
      // Try to delete from remote if has remote ID
      if (menu.remoteId != null) {
        try {
          await _remoteDataSource.delete(menu.remoteId!);
          // Hard delete from local after successful remote deletion
          await _localDataSource.delete(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete menu: ${e.toString()}');
    }
  }
  
  @override
  Future<Menu?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get menu by id: ${e.toString()}');
    }
  }
  
  Future<List<Menu>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all menus: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Menu>> getByEnterpriseId(String enterpriseId) async {
    try {
      return await _localDataSource.getByEnterpriseId(enterpriseId);
    } catch (e) {
      throw Exception('Failed to get menus by enterprise: ${e.toString()}');
    }
  }
  
  Future<List<Menu>> getActive() async {
    try {
      final menus = await _localDataSource.getAll();
      return menus.where((menu) => menu.isActive && menu.deletedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get active menus: ${e.toString()}');
    }
  }
  
  Future<void> syncFromRemote(String enterpriseId) async {
    try {
      final remoteDtos = await _remoteDataSource.getByEnterpriseId(enterpriseId);
      final localMenus = <Menu>[];
      
      for (final dto in remoteDtos) {
        final localMenu = dto.toEntity(_uuid.v7());
        localMenus.add(localMenu);
      }
      
      await _localDataSource.saveAll(localMenus);
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  Future<void> syncToRemote() async {
    try {
      final modifiedMenus = await _localDataSource.getModified();
      
      for (final menu in modifiedMenus) {
        try {
          final dto = menu.toDto();
          
          if (menu.remoteId == null) {
            // Create new
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(menu.localId, remoteDto.id);
          } else {
            // Update existing
            await _remoteDataSource.update(menu.remoteId!, dto);
            await _localDataSource.updateSyncStatus(menu.localId, menu.remoteId!);
          }
        } catch (e) {
          // Continue with next item if one fails
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }

  // Remote operations
  @override
  Future<List<Menu>> getHierarchy(String enterpriseId) async {
    try {
      final remoteDtos = await _remoteDataSource.getHierarchy(enterpriseId);
      final localMenus = <Menu>[];
      
      for (final dto in remoteDtos) {
        final localMenu = dto.toEntity(_uuid.v7());
        localMenus.add(localMenu);
      }
      
      return localMenus;
    } catch (e) {
      // Fallback to local hierarchy if remote fails
      try {
        return await buildHierarchy(enterpriseId);
      } catch (localError) {
        throw Exception('Failed to get hierarchy: ${e.toString()}');
      }
    }
  }

  @override
  Future<void> updatePosition(String id, int position) async {
    try {
      // Update locally first
      final menu = await _localDataSource.getById(id);
      if (menu != null) {
        await _localDataSource.updatePosition(id, position);
        
        // Try to sync with remote if has remote ID
        if (menu.remoteId != null) {
          try {
            await _remoteDataSource.updatePosition(menu.remoteId!, position);
          } catch (e) {
            // Keep local change for later sync
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update position: ${e.toString()}');
    }
  }

  // Local operations
  @override
  Future<List<Menu>> getByEnterpriseIdLocal(String enterpriseLocalId) async {
    try {
      return await _localDataSource.getByEnterpriseId(enterpriseLocalId);
    } catch (e) {
      throw Exception('Failed to get menus by enterprise locally: ${e.toString()}');
    }
  }

  @override
  Future<List<Menu>> getChildrenLocal(String parentMenuLocalId) async {
    try {
      return await _localDataSource.getChildren(parentMenuLocalId);
    } catch (e) {
      throw Exception('Failed to get children locally: ${e.toString()}');
    }
  }

  @override
  Future<Menu?> getByIdLocal(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get menu by local id: ${e.toString()}');
    }
  }

  @override
  Future<void> saveLocal(Menu menu) async {
    try {
      await _localDataSource.save(menu);
    } catch (e) {
      throw Exception('Failed to save menu locally: ${e.toString()}');
    }
  }

  @override
  Future<void> saveAllLocal(List<Menu> menus) async {
    try {
      await _localDataSource.saveAll(menus);
    } catch (e) {
      throw Exception('Failed to save all menus locally: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete menu locally: ${e.toString()}');
    }
  }

  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local menus: ${e.toString()}');
    }
  }

  // Navigation
  @override
  Future<List<Menu>> buildHierarchy(String enterpriseLocalId) async {
    try {
      final allMenus = await _localDataSource.getByEnterpriseId(enterpriseLocalId);
      
      // Filter out deleted and inactive menus
      final activeMenus = allMenus
          .where((menu) => menu.deletedAt == null && menu.isActive)
          .toList();

      // Build hierarchy by finding root menus and their children
      final rootMenus = activeMenus
          .where((menu) => menu.parentMenuLocalId == null)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      final hierarchyMenus = <Menu>[];

      void addMenuWithChildren(Menu parentMenu, int depth) {
        // Update depth level and path hierarchy
        final updatedMenu = parentMenu.copyWith(
          depthLevel: depth,
          pathHierarchy: _buildPath(parentMenu, activeMenus),
        );
        hierarchyMenus.add(updatedMenu);

        // Find and add children
        final children = activeMenus
            .where((menu) => menu.parentMenuLocalId == parentMenu.localId)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

        for (final child in children) {
          addMenuWithChildren(child, depth + 1);
        }
      }

      // Build complete hierarchy
      for (final rootMenu in rootMenus) {
        addMenuWithChildren(rootMenu, 0);
      }

      return hierarchyMenus;
    } catch (e) {
      throw Exception('Failed to build hierarchy: ${e.toString()}');
    }
  }

  @override
  Future<List<Menu>> getVisibleMenus(String enterpriseLocalId) async {
    try {
      final hierarchyMenus = await buildHierarchy(enterpriseLocalId);
      
      return hierarchyMenus
          .where((menu) => menu.isVisible && menu.isActive)
          .toList();
    } catch (e) {
      throw Exception('Failed to get visible menus: ${e.toString()}');
    }
  }

  // Sync operations
  @override
  Future<void> syncWithRemote(String enterpriseId) async {
    try {
      // First, sync from remote to get latest data
      await syncFromRemote(enterpriseId);
      
      // Then, sync local changes to remote
      await syncToRemote();
    } catch (e) {
      throw Exception('Failed to sync with remote: ${e.toString()}');
    }
  }

  @override
  Stream<List<Menu>> watchByEnterpriseId(String enterpriseLocalId) {
    // Note: This is a simple implementation returning a periodic stream
    // In a real app, you might want to use a more sophisticated approach
    // like listening to storage changes or using a database with reactive queries
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => getByEnterpriseIdLocal(enterpriseLocalId),
    ).asyncMap((future) => future);
  }

  // Helper methods
  String _buildPath(Menu menu, List<Menu> allMenus) {
    if (menu.parentMenuLocalId == null) {
      return menu.slug;
    }

    Menu? parent;
    try {
      parent = allMenus
          .where((m) => m.localId == menu.parentMenuLocalId)
          .first;
    } catch (_) {
      parent = null;
    }
    
    if (parent != null) {
      return '${_buildPath(parent, allMenus)}/${menu.slug}';
    }
    
    return menu.slug;
  }
}