import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tower_table.dart';
import 'tables/pavimento_table.dart';
import 'tables/apartment_table.dart';
import 'tables/apartment_type_table.dart';
import 'tables/gallery_image_table.dart';
import 'tables/image_pin_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  TowerTable,
  PavimentoTable,
  ApartmentTable,
  ApartmentTypeTable,
  GalleryImageTable,
  ImagePinTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'terra_allwert.db'));
    return NativeDatabase.createInBackground(file);
  });
}