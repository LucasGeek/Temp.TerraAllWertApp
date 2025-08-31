import 'package:drift/drift.dart';

@DataClassName('GalleryImageData')
class GalleryImageTable extends Table {
  @override
  String get tableName => 'gallery_images';

  TextColumn get id => text()();
  TextColumn get apartmentId => text()();
  TextColumn get url => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get order => integer()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}