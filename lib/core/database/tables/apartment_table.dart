import 'package:drift/drift.dart';

@DataClassName('ApartmentData')
class ApartmentTable extends Table {
  @override
  String get tableName => 'apartments';

  TextColumn get id => text()();
  TextColumn get pavimentoId => text()();
  TextColumn get towerId => text()();
  TextColumn get number => text()();
  TextColumn get typeId => text()();
  RealColumn get area => real()();
  IntColumn get bedrooms => integer()();
  IntColumn get bathrooms => integer()();
  RealColumn get price => real().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrls => text().nullable()(); // JSON array as string
  TextColumn get coordinates => text().nullable()(); // JSON object as string
  BoolColumn get isAvailable => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}