import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// 🚀 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class TopHotCategories extends StatelessWidget {
  final List<CategoryUiModel> categories;
  final Function(CategoryUiModel)? onCategoryTap; // 可選：點擊回調

  // 🚀 注入歷史資料庫接口，用以向下傳遞給二級導頁
  final CategoryHistoryRepository historyRepository;

  const TopHotCategories({
    super.key,
    required this.categories,
    required this.historyRepository, // ⚡ 納入必要參數
    this.onCategoryTap, // 可選參數
  });

  @override
  Widget build(BuildContext context) {
    final top = [...categories];
    top.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    final top5 = top.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '今日主流類股',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 18),

        ...top5.map(
          (e) => GestureDetector(
            onTap: () {
              // 🚀 如果有外部自訂的回調就執行
              if (onCategoryTap != null) {
                onCategoryTap!(e);
              }
              // 🚀 【完美修復點】：精確傳入三個參數，完成歷史走勢依賴的無縫穿透
              CategoryNavigation.openCategory(context, e, historyRepository);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '資金流 ${e.score.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      e.trendStrength.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
