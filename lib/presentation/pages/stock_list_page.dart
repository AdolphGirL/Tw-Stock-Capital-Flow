import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/presentation/widgets/stock_tile.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

class StockListPage extends StatelessWidget {
  final String title;

  final List<StockUiModel> stocks;

  const StockListPage({super.key, required this.title, required this.stocks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: stocks.length,

        separatorBuilder: (_, _) => const SizedBox(height: 10),

        itemBuilder: (_, index) {
          final item = stocks[index];

          return StockTile(stock: item.stock, score: item.score);
        },
      ),
    );
  }
}
