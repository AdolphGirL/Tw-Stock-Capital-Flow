import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

// 🚀 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class CategoryNavigation {
  static void openCategory(
    BuildContext context,
    CategoryUiModel category,
    CategoryHistoryRepository historyRepository, // 🚀 補上必要參數，用以傳遞資料庫接口
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubCategoryPage(
          title: category.name,
          categories: category.children,
          // 🚀 【完美修復點】：將 required 的 historyRepository 參數精確傳遞下去
          historyRepository: historyRepository,
        ),
      ),
    );
  }
}
