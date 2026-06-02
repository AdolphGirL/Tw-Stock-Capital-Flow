import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/analysis_snapshot.dart';
import 'package:drift/drift.dart';

class CategoryHistoryRepository {
  final AppDatabase db;

  CategoryHistoryRepository(this.db);

  /// 🚀 Phase 5 修正升級：從本地 SQLite 撈取特定產業過去 N 天的歷史紀錄
  /// 💡 加上 .reversed.toList() 將資料改為「由舊到新」排序，以完美對接 fl_chart 圖表繪製需求
  Future<List<CategoryHistoryData>> getCategoryTrend(
    String categoryName, {
    int limit = 15, // 調整預設抓取 15 天或 20 天，讓看盤圖更精確
  }) async {
    final results =
        await (db.select(db.categoryHistoryTable)
              ..where((t) => t.categoryName.equals(categoryName))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.tradeDate,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();

    // 💡 降序拿出來後反轉，使陣列最左邊是舊資料，最右邊是最新資料
    return results.reversed.toList();
  }

  /// 儲存每日完整的資金流 analysis 快照
  Future<void> saveDailySnapshot({
    required List<CategoryUiModel> categories,
    required AnalysisSnapshot snapshot,
  }) async {
    final String dateStr = snapshot.date;

    await db.transaction(() async {
      // 1. 儲存產業今日快照 (category_history)
      for (final category in categories) {
        await db
            .into(db.categoryHistoryTable)
            .insertOnConflictUpdate(
              CategoryHistoryTableCompanion.insert(
                tradeDate: dateStr,
                categoryName: category.name,
                score: category.score,
                hotScore: category.hotScore,
                persistence: category.persistence,
                trendStrength: category.trendStrength,
                riseCount: category.riseCount,
                fallCount: category.fallCount,
                totalCount: category.totalCount,
              ),
            );
      }

      // 2. 儲存主流排行 (mainstream_history)
      for (int i = 0; i < snapshot.mainstreams.length; i++) {
        final ms = snapshot.mainstreams[i];
        await db
            .into(db.mainstreamHistoryTable)
            .insertOnConflictUpdate(
              MainstreamHistoryTableCompanion.insert(
                tradeDate: dateStr,
                categoryName: ms.categoryName ?? ms.name ?? '',
                rankNo: i + 1,
                score: (ms.score as num).toDouble(),
              ),
            );
      }

      // 3. 儲存生命週期 (lifecycle_history)
      for (final lc in snapshot.lifecycles) {
        await db
            .into(db.lifecycleHistoryTable)
            .insertOnConflictUpdate(
              LifecycleHistoryTableCompanion.insert(
                tradeDate: dateStr,
                categoryName: lc.categoryName ?? lc.name ?? '',
                stage: lc.stage.toString(),
              ),
            );
      }

      // 4. 儲存資金輪動 (rotation_history)
      for (final rt in snapshot.rotations) {
        await db
            .into(db.rotationHistoryTable)
            .insertOnConflictUpdate(
              RotationHistoryTableCompanion.insert(
                tradeDate: dateStr,
                fromCategory: rt.fromCategory.toString(),
                toCategory: rt.toCategory.toString(),
                score: (rt.score as num).toDouble(),
              ),
            );
      }
    });
  }
}
