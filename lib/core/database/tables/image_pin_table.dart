import 'package:drift/drift.dart';

@DataClassName('ImagePinData')
class ImagePinTable extends Table {
  @override
  String get tableName => 'image_pins';

  TextColumn get id => text()();
  TextColumn get imageId => text()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}