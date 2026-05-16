import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/ui/widgets/market_summary_card.dart';
import 'main_category_page.dart';
import 'package:tw_stock_capital_flow/ui/widgets/top_hot_categories.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            const Text(
              '台股資金流',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              '追蹤市場主流資金輪動',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),

            const SizedBox(height: 28),

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
                title: '上市市場',

                riseCount: listedRiseCount,

                fallCount: listedFallCount,

                score: listedScore,
              ),
            ),

            const SizedBox(height: 20),

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
                title: '上櫃市場',

                riseCount: otcRiseCount,

                fallCount: otcFallCount,

                score: otcScore,
              ),
            ),

            const SizedBox(height: 36),

            TopHotCategories(
              categories: [...listedCategories, ...otcCategories],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
