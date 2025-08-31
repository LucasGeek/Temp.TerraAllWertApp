import 'package:drift/drift.dart';

@DataClassName('ApartmentTypeData')
class ApartmentTypeTable extends Table {
  @override
  String get tableName => 'apartment_types';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  TextColumn get description => text().nullable()();
  RealColumn get minArea => real().withDefault(const Constant(0.0))();
  RealColumn get maxArea => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}