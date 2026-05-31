import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// 🚀 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class MarketHeatmap extends StatelessWidget {
  final List<CategoryUiModel> categories;

  // 🚀 注入歷史資料庫接口，用以向下傳遞給二級導頁
  final CategoryHistoryRepository historyRepository;

  const MarketHeatmap({
    super.key,
    required this.categories,
    required this.historyRepository, // ⚡ 納入必要參數
  });

  Color _color(double score) {
    if (score >= 80) {
      return Colors.red;
    }

    if (score >= 50) {
      return Colors.orange;
    }

    if (score >= 20) {
      return Colors.green;
    }

    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final topCategories = [...categories]
      ..sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '市場熱區',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topCategories.length > 12 ? 12 : topCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final e = topCategories[index];

            return GestureDetector(
              onTap: () {
                // 🚀 【完美修復點】：精確傳入三個參數，完成依賴穿透鏈結
                CategoryNavigation.openCategory(context, e, historyRepository);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color(e.hotScore),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      e.hotLevel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '熱度 ${e.hotScore.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
