import 'package:drift/drift.dart';

@DataClassName('CategoryHistoryData')
class CategoryHistoryTable extends Table {
  @override
  String get tableName => 'category_history';

  // 1. 如果你不需要自增 id，請直接刪除它，改由交易日期與產業名稱作為聯合主鍵
  TextColumn get tradeDate => text()();
  TextColumn get categoryName => text()();

  // 核心指標
  RealColumn get score => real()();
  RealColumn get hotScore => real()();
  RealColumn get persistence => real()();
  RealColumn get trendStrength => real()();

  // 家數統計
  IntColumn get riseCount => integer()();
  IntColumn get fallCount => integer()();
  IntColumn get totalCount => integer()();

  // 2. 正確宣告複合主鍵（這會自動覆蓋掉預設的主鍵機制）
  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}
