import 'package:drift/drift.dart';

@DataClassName('RotationHistoryData')
class RotationHistoryTable extends Table {
  @override
  String get tableName => 'rotation_history';

  // 交易日期
  TextColumn get tradeDate => text()();

  // 資金流出產業
  TextColumn get fromCategory => text()();

  // 資金流入產業
  TextColumn get toCategory => text()();

  // 輪動強度分數
  RealColumn get score => real()();

  // 自訂複合主鍵
  @override
  Set<Column> get primaryKey => {tradeDate, fromCategory, toCategory};
}
