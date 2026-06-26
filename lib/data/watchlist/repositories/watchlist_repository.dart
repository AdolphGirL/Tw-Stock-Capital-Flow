import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/data/signal/repositories/signal_snapshot_repository.dart';

class WatchlistRepository {
  final AppDatabase db;
  late final SignalSnapshotRepository _snapshotRepo;

  WatchlistRepository(this.db) {
    _snapshotRepo = SignalSnapshotRepository(db);
  }

  /// 即時串流：UI 可直接用 StreamBuilder 訂閱，新增/刪除自動推播
  Stream<List<WatchlistEntry>> watchAll() =>
      db.select(db.watchlistTable).watch();

  /// 單一板塊的響應式收藏狀態串流
  /// WatchlistButton 使用此 stream，保證跨 widget 即時同步
  Stream<bool> watchIsWatched(String categoryName) =>
      (db.select(db.watchlistTable)
            ..where((t) => t.categoryName.equals(categoryName)))
          .watch()
          .map((rows) => rows.isNotEmpty);

  Future<List<WatchlistEntry>> getAll() =>
      db.select(db.watchlistTable).get();

  Future<bool> isWatched(String categoryName) async {
    final rows = await (db.select(db.watchlistTable)
          ..where((t) => t.categoryName.equals(categoryName)))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> add(String categoryName) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    await db.into(db.watchlistTable).insertOnConflictUpdate(
          WatchlistTableCompanion.insert(
            categoryName: categoryName,
            addedAt: dateKey,
          ),
        );
  }

  Future<void> remove(String categoryName) async {
    await (db.delete(db.watchlistTable)
          ..where((t) => t.categoryName.equals(categoryName)))
        .go();
    // 同步清除訊號歷史，確保重新加入時不會出現舊訊號的誤比對
    await _snapshotRepo.deleteForCategory(categoryName);
  }

  Future<void> toggle(String categoryName) async {
    if (await isWatched(categoryName)) {
      await remove(categoryName);
    } else {
      await add(categoryName);
    }
  }
}
