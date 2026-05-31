import 'package:drift/drift.dart';

@DataClassName('MainstreamHistoryData')
class MainstreamHistoryTable extends Table {
  @override
  String get tableName => 'mainstream_history';

  // 複合主鍵之一：交易日期
  TextColumn get tradeDate => text()();

  // 複合主鍵之二：產業名稱
  TextColumn get categoryName => text()();

  // 排名
  IntColumn get rankNo => integer()();

  // 分數
  RealColumn get score => real()();

  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}
