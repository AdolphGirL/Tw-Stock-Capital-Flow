import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/services/live_bootstrap_data.dart';

/// 大類板塊列表。以 [market] 為準訂閱 [LiveBootstrapData]，隨資料更新即時反映，
/// 不再持有進入頁面當下的靜態快照——這條 Navigator.push 出去的鑽入路徑，
/// 過去因為以建構子傳入固定的 categories 清單，會在資料背景更新後依然停留在舊值。
class MainCategoryPage extends StatefulWidget {
  final MarketType market;
  final String title;
  final CategoryHistoryRepository historyRepository;

  const MainCategoryPage({
    super.key,
    required this.market,
    required this.title,
    required this.historyRepository,
  });

  @override
  State<MainCategoryPage> createState() => _MainCategoryPageState();
}

class _MainCategoryPageState extends State<MainCategoryPage> {
  // 用來儲存從本地 SQLite 撈出來的各板塊歷史資金流趨勢 Map <板塊名稱, 歷史分數列表>
  final Map<String, List<double>> _dbTrendCache = {};
  final Set<String> _historyLoadedFor = {};
  bool _isLoadingDbData = true;
  bool _isFetchingHistory = false;
  List<CategoryUiModel> _lastKnownCategories = const [];

  @override
  void initState() {
    super.initState();
    final initial = _lookupCategories(LiveBootstrapData.notifier.value);
    _loadHistoricalTrends(initial);
  }

  /// 依 market 從全域最新資料中查找對應的板塊清單；資料尚未就緒時沿用上次已知的清單。
  List<CategoryUiModel> _lookupCategories(AppBootstrapResult? result) {
    if (result == null) return _lastKnownCategories;
    final list = widget.market == MarketType.listed
        ? result.listedCategories
        : result.otcCategories;
    _lastKnownCategories = list;
    return list;
  }

  /// 🚀 穿透查詢：從 SQLite 撈取真實的歷史走勢，只針對尚未查過的板塊名稱補查，
  /// 避免資料每次刷新都重複打 SQLite。
  Future<void> _loadHistoricalTrends(List<CategoryUiModel> categories) async {
    final toLoad =
        categories.where((c) => !_historyLoadedFor.contains(c.name)).toList();
    if (toLoad.isEmpty) {
      if (mounted && _isLoadingDbData) {
        setState(() => _isLoadingDbData = false);
      }
      return;
    }
    if (_isFetchingHistory) return;
    _isFetchingHistory = true;
    try {
      for (final category in toLoad) {
        final historyRecords = await widget.historyRepository.getCategoryTrend(
          category.name,
          limit: 7,
        );
        if (historyRecords.isNotEmpty) {
          final scores =
              historyRecords.reversed.map((data) => data.score).toList();
          _dbTrendCache[category.name] = scores;
        }
        _historyLoadedFor.add(category.name);
      }
    } catch (_) {
    } finally {
      _isFetchingHistory = false;
      if (mounted) {
        setState(() => _isLoadingDbData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppBootstrapResult?>(
      valueListenable: LiveBootstrapData.notifier,
      builder: (context, result, _) {
        final categories = _lookupCategories(result);

        final hasUnloaded =
            categories.any((c) => !_historyLoadedFor.contains(c.name));
        if (hasUnloaded && !_isFetchingHistory) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadHistoricalTrends(categories));
        }

        if (categories.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: const Center(child: Text('暫無相關板塊數據')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoryPage(
                          market: widget.market,
                          mainCategoryName: category.name,
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
      },
    );
  }
}
