import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
// 引入您剛才貼給我的 AnalysisSnapshot 所在檔案路徑
import 'package:tw_stock_capital_flow/data/models/analysis_snapshot.dart';
import 'package:drift/drift.dart';

class CategoryHistoryRepository {
  final AppDatabase db;

  CategoryHistoryRepository(this.db);

  /// 🚀 修正錯誤 1：定義 UI 所需的 getCategoryTrend 接口
  /// 從本地 SQLite 的 category_history 表中撈取特定產業過去 N 天的歷史紀錄
  Future<List<CategoryHistoryData>> getCategoryTrend(
    String categoryName, {
    int limit = 7,
  }) async {
    return await (db.select(db.categoryHistoryTable)
          ..where((t) => t.categoryName.equals(categoryName))
          // 依交易日期降序排列（最新日期在最前），並限制讀取筆數
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.tradeDate, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  /// 儲存每日完整的資金流分析快照
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
