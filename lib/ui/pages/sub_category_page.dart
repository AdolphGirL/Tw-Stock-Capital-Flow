import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/ui/widgets/category_card.dart';
import 'stock_list_page.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';

class SubCategoryPage extends StatelessWidget {
  final String title;

  final List<CategoryUiModel> categories;

  const SubCategoryPage({
    super.key,
    required this.title,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: categories.length,

        separatorBuilder: (_, __) => const SizedBox(height: 12),

        itemBuilder: (_, index) {
          final item = categories[index];

          return CategoryCard(
            title: item.name,

            totalCount: item.totalCount,

            riseCount: item.riseCount,

            fallCount: item.fallCount,

            score: item.score,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StockListPage(title: item.name, stocks: item.stocks),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
