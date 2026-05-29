import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class StockListPage extends StatelessWidget {
  final List<StockUiModel> stocks;
  final String categoryName;

  const StockListPage({
    super.key,
    required this.stocks,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('$categoryName 個股行情')),
        body: const Center(child: Text('此板塊目前無個股數據')),
      );
    }

    // 依據漲跌幅從大到小排序個股
    final sortedStocks = List<StockUiModel>.from(stocks)
      ..sort((a, b) => b.stock.changePercent.compareTo(a.stock.changePercent));

    return Scaffold(
      appBar: AppBar(title: Text('$categoryName 個股行情 (${stocks.length})')),
      body: ListView.builder(
        // 🚀 視窗滾動優化：固定列表項高度以提高滾動計算效能
        itemExtent: 88,
        cacheExtent: 400,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedStocks.length,
        itemBuilder: (context, index) {
          final stockUi = sortedStocks[index];
          final StockData stock = stockUi.stock; // 🚀 正確取出底層實體

          final isPositive = stock.changePercent >= 0;

          return Card(
            key: ValueKey('stock_list_${stock.code}_$index'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(
                stock.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  stock.code, // 🚀 100% 精確：使用專案真實定義的 stock.code
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    stock.close.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.redAccent : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 76,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isPositive ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.redAccent : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
