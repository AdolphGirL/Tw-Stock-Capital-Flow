import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
import 'package:tw_stock_capital_flow/presentation/pages/stock_list_page.dart';

class MainCategoryPage extends StatelessWidget {
  final List<CategoryUiModel> categories;
  final String title;

  const MainCategoryPage({
    super.key,
    required this.categories,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('暫無相關板塊數據')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        // 🚀 視窗滾動優化：設定預估項目高度與物理彈性
        itemExtent: 140,
        cacheExtent: 300,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoryCard(
              // 使用專一 Key 避免捲動時重複繪製
              key: ValueKey('main_cat_${category.name}_$index'),
              title: category.name,
              totalCount: category.totalCount,
              riseCount: category.riseCount,
              fallCount: category.fallCount,
              score: category.score,
              persistence: category.persistence,
              // 🚀 對齊底層模型：day3Score(前天)、day2Score(昨天)、day1Score(今天)、score(綜合)
              trendValues: [
                category.day3Score,
                category.day2Score,
                category.day1Score,
                category.score,
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockListPage(
                      stocks: category.stocks, // 傳入 List<StockUiModel>
                      categoryName: category.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
