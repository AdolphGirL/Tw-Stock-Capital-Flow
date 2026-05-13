import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/ui/widgets/category_card.dart';
import 'sub_category_page.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';

class MainCategoryPage extends StatelessWidget {
  final List<CategoryUiModel> categories;

  const MainCategoryPage({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主類股')),

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
                  builder: (_) => SubCategoryPage(
                    categories: item.children,
                    title: item.name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
