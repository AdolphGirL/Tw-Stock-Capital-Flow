import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/ui/enums/category_sort_type.dart';
import 'package:tw_stock_capital_flow/ui/widgets/category_card.dart';
import 'stock_list_page.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';

class SubCategoryPage extends StatefulWidget {
  final String title;

  final List<CategoryUiModel> categories;

  const SubCategoryPage({
    super.key,
    required this.title,
    required this.categories,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  late List<CategoryUiModel> categories;

  CategorySortType sortType = CategorySortType.score;

  @override
  void initState() {
    super.initState();

    categories = [...widget.categories];

    applySort();
  }

  void applySort() {
    switch (sortType) {
      case CategorySortType.score:
        categories.sort((a, b) => b.score.compareTo(a.score));
        break;

      case CategorySortType.riseCount:
        categories.sort((a, b) => b.riseCount.compareTo(a.riseCount));
        break;

      case CategorySortType.fallCount:
        categories.sort((a, b) => b.fallCount.compareTo(a.fallCount));
        break;

      case CategorySortType.totalCount:
        categories.sort((a, b) => b.totalCount.compareTo(a.totalCount));
        break;

      case CategorySortType.threeDayTrend:
        categories.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));
        break;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),

        actions: [
          PopupMenuButton<CategorySortType>(
            onSelected: (value) {
              sortType = value;

              applySort();
            },

            itemBuilder: (_) => [
              const PopupMenuItem(
                value: CategorySortType.score,
                child: Text('資金流'),
              ),

              const PopupMenuItem(
                value: CategorySortType.threeDayTrend,
                child: Text('三日強度'),
              ),

              const PopupMenuItem(
                value: CategorySortType.riseCount,
                child: Text('上漲家數'),
              ),

              const PopupMenuItem(
                value: CategorySortType.fallCount,
                child: Text('下跌家數'),
              ),

              const PopupMenuItem(
                value: CategorySortType.totalCount,
                child: Text('股票數量'),
              ),
            ],
          ),
        ],
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: categories.length,

        separatorBuilder: (_, _) => const SizedBox(height: 14),

        itemBuilder: (_, index) {
          final item = categories[index];

          return CategoryCard(
            title: item.name,

            totalCount: item.totalCount,

            riseCount: item.riseCount,

            fallCount: item.fallCount,

            score: item.score,

            trendValues: [item.day3Score, item.day2Score, item.day1Score],

            persistence: item.persistence,

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
