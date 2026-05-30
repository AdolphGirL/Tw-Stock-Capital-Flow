import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

class CategoryHistoryRepository {
  final AppDatabase db;

  CategoryHistoryRepository(this.db);

  Future<void> saveDailySnapshot(List<CategoryUiModel> categories) async {
    final today = DateTime.now();

    for (final category in categories) {
      await db
          .into(db.categoryHistoryTable)
          .insertOnConflictUpdate(
            CategoryHistoryTableCompanion.insert(
              tradeDate: today,
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
  }
}
