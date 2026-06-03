import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
// 🚀 修正路由對接：根據您的描述，點擊後應導向 SubCategoryPage，而非直接到 StockListPage
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
// 引入我們的歷史資料庫 Repository
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class MainCategoryPage extends StatefulWidget {
  final List<CategoryUiModel> categories;
  final String title;
  final CategoryHistoryRepository historyRepository; // 注入歷史資料庫接口

  const MainCategoryPage({
    super.key,
    required this.categories,
    required this.title,
    required this.historyRepository,
  });

  @override
  State<MainCategoryPage> createState() => _MainCategoryPageState();
}

class _MainCategoryPageState extends State<MainCategoryPage> {
  // 用來儲存從本地 SQLite 撈出來的各板塊歷史資金流趨勢 Map <板塊名稱, 歷史分數列表>
  final Map<String, List<double>> _dbTrendCache = {};
  bool _isLoadingDbData = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalTrends();
  }

  /// 🚀 穿透查詢：從 SQLite 撈取該類別真實的歷史走勢
  Future<void> _loadHistoricalTrends() async {
    try {
      for (final category in widget.categories) {
        // 從我們在資料庫設計的 category_history 表中，撈取過去 7 天的 snapshot 數據
        final historyRecords = await widget.historyRepository.getCategoryTrend(
          category.name,
          limit: 7,
        );

        if (historyRecords.isNotEmpty) {
          // 資料庫存儲通常是最新日期在最前(desc)，繪製畫布需要正序(由舊到新)，故使用 reversed
          final scores = historyRecords.reversed
              .map((data) => data.score)
              .toList();
          _dbTrendCache[category.name] = scores;
        }
      }
    } catch (e) {
      debugPrint('撈取本地歷史數據失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDbData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('暫無相關板塊數據')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        // scrollCacheExtent: const ScrollCacheExtent.dynamic(300.0)
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];

          // 💡 防禦機制與完美對接：
          // 如果資料庫有豐富的歷史紀錄(大於4天)，優先採用資料庫的真實長週期數據
          // 如果資料庫尚無數據(新開榜)，無縫降級採用原有的 4 點記憶體模型數據
          List<double> finalTrendValues = [
            category.day3Score,
            category.day2Score,
            category.day1Score,
            category.score,
          ];

          if (!_isLoadingDbData && _dbTrendCache.containsKey(category.name)) {
            finalTrendValues = _dbTrendCache[category.name]!;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoryCard(
              key: ValueKey('main_cat_${category.name}_$index'),
              title: category.name,
              totalCount: category.totalCount,
              riseCount: category.riseCount,
              fallCount: category.fallCount,
              score: category.score,
              persistence: category.persistence,
              trendValues: finalTrendValues, // 灌入優化後的真實歷史趨勢
              onTap: () {
                // 🚀 修正錯誤 2：將命名參數名稱對齊，精確傳入 categories 與必要的 historyRepository
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubCategoryPage(
                      categories: category
                          .children, // 💡 確保參數名稱對齊您的 SubCategoryPage 欄位定義
                      title: '${category.name} - 子板塊',
                      historyRepository: widget.historyRepository,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
