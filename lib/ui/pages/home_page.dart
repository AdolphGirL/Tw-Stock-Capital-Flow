import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/ui/widgets/market_summary_card.dart';
import 'main_category_page.dart';

class HomePage extends StatelessWidget {
  final List<CategoryUiModel> listedCategories;

  final List<CategoryUiModel> otcCategories;

  final int listedRiseCount;

  final int listedFallCount;

  final double listedScore;

  final int otcRiseCount;

  final int otcFallCount;

  final double otcScore;

  const HomePage({
    super.key,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('台股資金流')),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MainCategoryPage(categories: listedCategories),
                ),
              );
            },

            child: MarketSummaryCard(
              title: '上市資金流',

              riseCount: listedRiseCount,

              fallCount: listedFallCount,

              score: listedScore,
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MainCategoryPage(categories: otcCategories),
                ),
              );
            },

            child: MarketSummaryCard(
              title: '上櫃資金流',

              riseCount: otcRiseCount,

              fallCount: otcFallCount,

              score: otcScore,
            ),
          ),
        ],
      ),
    );
  }
}
