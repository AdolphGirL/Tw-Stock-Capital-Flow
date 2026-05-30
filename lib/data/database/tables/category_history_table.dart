import 'package:drift/drift.dart';

class CategoryHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get tradeDate => dateTime()();

  TextColumn get categoryName => text()();

  RealColumn get score => real()();

  RealColumn get hotScore => real()();

  RealColumn get persistence => real()();

  RealColumn get trendStrength => real()();

  IntColumn get riseCount => integer()();

  IntColumn get fallCount => integer()();

  IntColumn get totalCount => integer()();

  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}
