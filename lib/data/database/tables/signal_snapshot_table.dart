import 'package:drift/drift.dart';

/// 儲存每個板塊最近一次記錄的訊號，供下次啟動比對是否異動。
/// 以 categoryName 為 PK（每板塊一筆），每次啟動 upsert 覆蓋。
@DataClassName('SignalSnapshotData')
class SignalSnapshotTable extends Table {
  @override
  String get tableName => 'signal_snapshot';

  TextColumn get categoryName => text()();
  TextColumn get action => text()(); // 'buy' | 'hold' | 'sell' | 'neutral'
  TextColumn get dateKey => text()(); // YYYYMMDD，記錄此訊號是哪天算出來的

  @override
  Set<Column> get primaryKey => {categoryName};
}
