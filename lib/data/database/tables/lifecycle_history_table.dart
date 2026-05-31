import 'package:drift/drift.dart';

@DataClassName('LifecycleHistoryData')
class LifecycleHistoryTable extends Table {
  @override
  String get tableName => 'lifecycle_history';

  // 複合主鍵之一：交易日期
  TextColumn get tradeDate => text()();

  // 複合主鍵之二：產業名稱
  TextColumn get categoryName => text()();

  // 生命週期階段 (例如: Emerging, Expanding, Climax, Declining)
  TextColumn get stage => text()();

  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}
