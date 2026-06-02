// lib/core/navigation/category_navigation.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart'; // 保持引入基礎資料模型

// 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class CategoryNavigation {
  /// 🚀 動作 A：主分類 -> 進入細分類全螢幕頁面 (SubCategoryPage)
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

  /// 🚀 動作 B：細分類 -> 彈出成分股清單半窗抽屜 (BottomSheet)
  static void showStockListSheet({
    required BuildContext context,
    required String categoryName,
    required List<StockUiModel>
    uiStocks, // 🟢 修正點 1：將型態精確對接為 UI 層的 List<StockUiModel>
  }) {
    // 自動過濾出屬於該細分類（或主分類）的個股，並依成交值 (value) 由大到小排序
    // 💡 透過 s.stock.value 進行解包與降序排序
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
                  // 頂部滑動小灰條
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // 標頭區段
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '# $categoryName 成分股排行',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '共 ${filteredUiStocks.length} 檔',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // 個股清單
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
                              final uiStock = filteredUiStocks[index];
                              // 🟢 修正點 2：直接傳遞 uiStock 物件給小卡片元件
                              return _buildStockListTile(context, uiStock);
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

  /// 打造抽屜內部的個股細項 ListTile 元件
  static Widget _buildStockListTile(
    BuildContext context,
    StockUiModel uiStock,
  ) {
    // 💡 從 uiStock 提煉出底層的基礎 stock 資料
    final stock = uiStock.stock;

    final isUp = stock.changePercent >= 0;
    final themeColor = isUp
        ? const Color(0xffc62828)
        : const Color(0xff2e7d32); // 台股紅漲綠跌

    // 計算億元級成交值
    final double valueInMillions = stock.value / 100000000.0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      title: Row(
        children: [
          Text(
            stock.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            stock.code,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stock.market == MarketType.listed ? '上市' : '上櫃',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '成交值: ${valueInMillions.toStringAsFixed(2)} 億 | 量: ${(stock.volume / 1000).toStringAsFixed(0)} 張',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ],
      ),
      onTap: () => _launchYahooFinance(stock),
    );
  }

  /// 精準對接外部網頁
  static Future<void> _launchYahooFinance(StockData stock) async {
    final String suffix = (stock.market == MarketType.listed) ? 'TW' : 'TWO';
    final String urlString =
        'https://tw.stock.yahoo.com/quote/${stock.code}.$suffix';

    final Uri url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('無法開啟網頁連結: $urlString');
      }
    } catch (e) {
      debugPrint('網頁穿透發生異常: $e');
    }
  }
}
