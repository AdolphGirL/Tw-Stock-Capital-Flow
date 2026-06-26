import 'package:drift/drift.dart';

@DataClassName('WatchlistEntry')
class WatchlistTable extends Table {
  @override
  String get tableName => 'watchlist';

  TextColumn get categoryName => text()();
  TextColumn get addedAt => text()(); // YYYYMMDD

  @override
  Set<Column> get primaryKey => {categoryName};
}
