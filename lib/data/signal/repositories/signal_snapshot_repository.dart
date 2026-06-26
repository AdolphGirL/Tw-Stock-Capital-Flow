import 'package:tw_stock_capital_flow/data/database/app_database.dart';

class SignalSnapshotRepository {
  final AppDatabase db;

  SignalSnapshotRepository(this.db);

  /// 載入指定板塊最近一次記錄的訊號，回傳 {categoryName: action} Map
  Future<Map<String, String>> loadForCategories(List<String> names) async {
    if (names.isEmpty) return {};
    final rows = await (db.select(db.signalSnapshotTable)
          ..where((t) => t.categoryName.isIn(names)))
        .get();
    return {for (final r in rows) r.categoryName: r.action};
  }

  /// 儲存今日演算結果（只存有在 watchlist 中的板塊）
  Future<void> saveSignals(String dateKey, Map<String, String> signals) async {
    if (signals.isEmpty) return;
    await db.transaction(() async {
      for (final entry in signals.entries) {
        await db.into(db.signalSnapshotTable).insertOnConflictUpdate(
              SignalSnapshotTableCompanion.insert(
                categoryName: entry.key,
                action: entry.value,
                dateKey: dateKey,
              ),
            );
      }
    });
  }

  /// 移除特定板塊的歷史訊號（使用者取消關注時呼叫）
  Future<void> deleteForCategory(String categoryName) async {
    await (db.delete(db.signalSnapshotTable)
          ..where((t) => t.categoryName.equals(categoryName)))
        .go();
  }
}
