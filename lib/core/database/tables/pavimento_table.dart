import 'package:drift/drift.dart';

@DataClassName('PavimentoData')
class PavimentoTable extends Table {
  @override
  String get tableName => 'pavimentos';

  TextColumn get id => text()();
  TextColumn get towerId => text()();
  TextColumn get name => text()();
  IntColumn get floor => integer()();
  TextColumn get floorPlanImageUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}