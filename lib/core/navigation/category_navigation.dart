import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class CategoryNavigation {
  /// 主分類 -> SubCategoryPage
  static void openCategory(
    BuildContext context,
    CategoryUiModel category,
    CategoryHistoryRepository historyRepository,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubCategoryPage(
          title: category.name,
          categories: category.children,
          historyRepository: historyRepository,
        ),
      ),
    );
  }

  /// 細分類 -> BottomSheet 成分股清單
  static void showStockListSheet({
    required BuildContext context,
    required String categoryName,
    required List<StockUiModel> uiStocks,
  }) {
    final filteredUiStocks =
        uiStocks
            .where(
              (s) =>
                  s.stock.subCategory == categoryName ||
                  s.stock.mainCategory == categoryName,
            )
            .toList()
          ..sort((a, b) => b.stock.value.compareTo(a.stock.value));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 拖曳條
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // 標題列
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // 左邊標題 - 可壓縮 + 省略號
                        Expanded(
                          child: Text(
                            '# $categoryName 成分股排行',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 右邊計數標籤
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '共 ${filteredUiStocks.length} 檔',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // 清單
                  Expanded(
                    child: filteredUiStocks.isEmpty
                        ? const Center(
                            child: Text(
                              '查無此產業成分股數據',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 20,
                            ),
                            itemCount: filteredUiStocks.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              return _buildStockListTile(
                                context,
                                filteredUiStocks[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 修正後的 ListTile
  static Widget _buildStockListTile(
    BuildContext context,
    StockUiModel uiStock,
  ) {
    final stock = uiStock.stock;
    final isUp = stock.changePercent >= 0;
    final themeColor = isUp ? const Color(0xffc62828) : const Color(0xff2e7d32);

    final double valueInMillions = stock.value / 100000000.0;

    return Material(
      color: Colors.white,
      child: ListTile(
        tileColor: Colors.white,
        splashColor: Colors.grey..withValues(alpha: 0.15),
        hoverColor: Colors.grey..withValues(alpha: 0.08),
        focusColor: Colors.grey..withValues(alpha: 0.08),

        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),

        title: Row(
          children: [
            Expanded(
              child: Text(
                stock.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              stock.code,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stock.market == MarketType.listed ? '上市' : '上櫃',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '成交值: ${valueInMillions.toStringAsFixed(2)} 億 | 量: ${(stock.volume / 1000).toStringAsFixed(0)} 張',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              stock.close.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${isUp ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ],
        ),

        onTap: () => _launchYahooFinance(stock),
      ),
    );
  }

  static Future<void> _launchYahooFinance(StockData stock) async {
    final String suffix = stock.market == MarketType.listed ? 'TW' : 'TWO';
    final url = Uri.parse(
      'https://tw.stock.yahoo.com/quote/${stock.code}.$suffix',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }
}
