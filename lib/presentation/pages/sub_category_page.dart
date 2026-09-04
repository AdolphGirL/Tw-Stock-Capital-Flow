import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/enums/category_sort_type.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';
import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_trend_chart.dart';
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/services/live_bootstrap_data.dart';

/// 細類板塊列表。以 [market] + [mainCategoryName] 為準訂閱 [LiveBootstrapData]，
/// 隨資料更新即時反映最新個股明細（漲跌、成交量、成交值等），不再持有進入頁面
/// 當下的靜態快照。
class SubCategoryPage extends StatefulWidget {
  final MarketType market;
  final String mainCategoryName;
  final String title;
  final CategoryHistoryRepository historyRepository;

  const SubCategoryPage({
    super.key,
    required this.market,
    required this.mainCategoryName,
    required this.title,
    required this.historyRepository,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  CategorySortType sortType = CategorySortType.score;
  List<CategoryUiModel> _lastKnownChildren = const [];

  // 🚀 Phase 5 變數：儲存調取出來的歷史看盤數據與載入狀態
  List<CategoryHistoryData> _historyRecords = [];
  bool _isLoadingHistory = true;
  bool _hasFetchedHistory = false;

  // 🚀 數據統計防線：當無歷史資料時，計算今日大板塊內細分產業股票的加總分佈
  int _totalRiseCount = 0;
  int _totalFallCount = 0;
  int _totalStockCount = 0;

  @override
  void initState() {
    super.initState();
    // 🚀 初始化時，立刻向本地 SQLite 發起歷史數據穿透回溯（只查一次，不隨個股資料刷新重查）
    _fetchHistoryData();
  }

  /// 依 market + mainCategoryName 從全域最新資料中查找對應的子板塊清單；
  /// 資料尚未就緒或名稱一時查無（極端邊界）時，沿用上次已知的清單。
  List<CategoryUiModel> _lookupChildren(AppBootstrapResult? result) {
    if (result == null) return _lastKnownChildren;
    final marketCategories = widget.market == MarketType.listed
        ? result.listedCategories
        : result.otcCategories;
    CategoryUiModel? mainCat;
    try {
      mainCat = marketCategories.firstWhere((c) => c.name == widget.mainCategoryName);
    } catch (_) {
      mainCat = null;
    }
    if (mainCat == null) return _lastKnownChildren;
    _lastKnownChildren = mainCat.children;
    return mainCat.children;
  }

  /// 依 [widget.market] 取出這份成分股清單實際對應的資料日期（民國年 YYYMMDD → MM/DD），
  /// 讓使用者能在成分股清單上直接核對「現在看到的到底是不是今天的資料」。
  String? _dataDateLabel(AppBootstrapResult? result) {
    if (result == null) return null;
    final roc = widget.market == MarketType.listed ? result.listedDate : result.otcDate;
    if (roc.length != 7) return null;
    final month = roc.substring(3, 5);
    final day = roc.substring(5, 7);
    final marketLabel = widget.market == MarketType.listed ? '上市' : '上櫃';
    return '$marketLabel $month/$day';
  }

  /// 計算今日即時分布狀態（直接寫入 state 欄位，由呼叫端的 build 同步顯示）
  void _calculateLiveDistribution(List<CategoryUiModel> categories) {
    _totalRiseCount = 0;
    _totalFallCount = 0;
    _totalStockCount = 0;
    for (final cat in categories) {
      _totalRiseCount += cat.riseCount;
      _totalFallCount += cat.fallCount;
      _totalStockCount += cat.totalCount;
    }
  }

  // 🚀 Phase 5 方法：實作非同步歷史軌跡回溯
  Future<void> _fetchHistoryData() async {
    if (_hasFetchedHistory) return;
    _hasFetchedHistory = true;
    setState(() => _isLoadingHistory = true);
    try {
      // 💡 精確對接專案原始代碼：呼叫 getCategoryTrend 取得 15 天歷史
      final records = await widget.historyRepository.getCategoryTrend(
        widget.title,
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _historyRecords = records;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  List<CategoryUiModel> _applySort(List<CategoryUiModel> raw) {
    final list = [...raw];
    switch (sortType) {
      case CategorySortType.score:
        list.sort((a, b) => b.score.compareTo(a.score));
        break;
      case CategorySortType.riseCount:
        list.sort((a, b) => b.riseCount.compareTo(a.riseCount));
        break;
      case CategorySortType.fallCount:
        list.sort((a, b) => b.fallCount.compareTo(a.fallCount));
        break;
      case CategorySortType.totalCount:
        list.sort((a, b) => b.totalCount.compareTo(a.totalCount));
        break;
      case CategorySortType.threeDayTrend:
        list.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppBootstrapResult?>(
      valueListenable: LiveBootstrapData.notifier,
      builder: (context, result, _) {
        final rawChildren = _lookupChildren(result);
        _calculateLiveDistribution(rawChildren);
        final categories = _applySort(rawChildren);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              PopupMenuButton<CategorySortType>(
                onSelected: (value) => setState(() => sortType = value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: CategorySortType.score,
                    child: Text('資金流優先'),
                  ),
                  const PopupMenuItem(
                    value: CategorySortType.threeDayTrend,
                    child: Text('三日強度排序'),
                  ),
                  const PopupMenuItem(
                    value: CategorySortType.riseCount,
                    child: Text('上漲家數多'),
                  ),
                  const PopupMenuItem(
                    value: CategorySortType.fallCount,
                    child: Text('下跌家數多'),
                  ),
                  const PopupMenuItem(
                    value: CategorySortType.totalCount,
                    child: Text('股票數量規模'),
                  ),
                ],
              ),
            ],
          ),
          // 🚀【升級核心】：將原本的 body: ListView 改用 CustomScrollView
          // 如此一來才能在同一個滾動視窗中，完美結合「頂部歷史趨勢面板」與「下方細分類卡片列表」
          body: CustomScrollView(
            slivers: [
              // 🚀 1. 頂部組件：歷史看盤面板外殼
              SliverToBoxAdapter(child: _buildHistoryTrendHeader()),

              // 🚀 1.5 板塊強勢個股排行
              SliverToBoxAdapter(child: _buildTopStocksSection(context, rawChildren)),

              // 🚀 2. 分隔小標題
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                  child: Text(
                    '包含細分板塊 (${categories.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              // 🚀 3. 下方列表：將舊的 ListView 完美轉換為高級的 SliverList
              SliverPadding(
                // 🟢 修正點：使用 EdgeInsets.only 精確定義上下左右的間距
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = categories[index];

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ), // 替代原本 ListView 的間距效果
                      child: CategoryCard(
                        key: ValueKey('sub_cat_${item.name}_$index'),
                        title: item.name,
                        totalCount: item.totalCount,
                        riseCount: item.riseCount,
                        fallCount: item.fallCount,
                        score: item.score,
                        trendValues: [
                          item.day3Score,
                          item.day2Score,
                          item.day1Score,
                          item.score,
                        ],
                        persistence: item.persistence,
                        onTap: () {
                          CategoryNavigation.showStockListSheet(
                            context: context,
                            categoryName: item.name,
                            uiStocks: item.stocks,
                            dataDateLabel: _dataDateLabel(result),
                          );
                        },
                      ),
                    );
                  }, childCount: categories.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 板塊強勢個股排行 ＋ 個股掃描器 ─────────────────────────────────────────

  /// 掃描器準則：changePercent > 0，收盤位置(closePosition) >= 0.7，日內漲(close > open)
  bool _passesScanner(StockUiModel s) {
    final st = s.stock;
    if (st.changePercent <= 0) return false;
    final range = st.high - st.low;
    final closePos = range > 0 ? (st.close - st.low) / range : 0.5;
    final intradayUp = st.close > st.open;
    return closePos >= 0.7 && intradayUp;
  }

  Widget _buildTopStocksSection(BuildContext context, List<CategoryUiModel> children) {
    // 聚合並去重
    final allStocks = <StockUiModel>[];
    final seenCodes = <String>{};
    for (final child in children) {
      for (final s in child.stocks) {
        if (seenCodes.add(s.stock.code)) {
          allStocks.add(s);
        }
      }
    }

    if (allStocks.isEmpty) return const SizedBox.shrink();

    // 強勢股：changePercent > 0，依 score 降序，取前 8
    final risers = allStocks
        .where((s) => s.stock.changePercent > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final topRisers = risers.take(8).toList();

    // 風控股：changePercent < 0，依 changePercent 升序（最大跌幅優先），取前 3
    final fallers = allStocks
        .where((s) => s.stock.changePercent < 0)
        .toList()
      ..sort((a, b) => a.stock.changePercent.compareTo(b.stock.changePercent));
    final topFallers = fallers.take(3).toList();

    if (topRisers.isEmpty && topFallers.isEmpty) return const SizedBox.shrink();

    // 掃描器命中數
    final scannerHits = topRisers.where(_passesScanner).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF37474F)),
              const SizedBox(width: 6),
              const Text(
                '板塊個股排行',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (scannerHits > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '掃描命中 $scannerHits 檔',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '共 ${allStocks.length} 檔',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 強勢區
          if (topRisers.isNotEmpty) ...[
            _buildRankSectionLabel(
              '今日強勢',
              const Color(0xFFC62828),
              Icons.trending_up_rounded,
            ),
            const SizedBox(height: 8),
            ...topRisers.map((s) => _buildStockRankTile(context, s, isRiser: true)),
          ],

          // 風控區
          if (topFallers.isNotEmpty) ...[
            if (topRisers.isNotEmpty) const SizedBox(height: 12),
            _buildRankSectionLabel(
              '風控注意',
              const Color(0xFF2E7D32),
              Icons.trending_down_rounded,
            ),
            const SizedBox(height: 8),
            ...topFallers.map((s) => _buildStockRankTile(context, s, isRiser: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildRankSectionLabel(String title, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildStockRankTile(
    BuildContext context,
    StockUiModel s, {
    required bool isRiser,
  }) {
    final stock = s.stock;
    // 台灣股市慣例：漲紅跌綠
    final themeColor = isRiser ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bgColor = isRiser ? const Color(0xFFFFF5F5) : const Color(0xFFF1F8F4);
    final changeStr =
        '${isRiser ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%';
    final valueInYi = (stock.value / 100000000.0).toStringAsFixed(2);
    final marketLabel = stock.market == MarketType.listed ? '上市' : '上櫃';

    // 掃描器指標（僅強勢股有意義）
    final range = stock.high - stock.low;
    final closePos = range > 0 ? (stock.close - stock.low) / range : 0.5;
    final intradayReturn = stock.open > 0
        ? (stock.close - stock.open) / stock.open * 100
        : 0.0;
    final strongClose = closePos >= 0.7;
    final intradayUp = intradayReturn > 0;
    final scannerPass = isRiser && strongClose && intradayUp;

    return GestureDetector(
      onTap: () => CategoryNavigation.openStockUrl(stock),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: scannerPass
              ? Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.4), width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 左：股名 + 代碼 / 市場 / 成交值
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              stock.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (scannerPass) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '掃描命中',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stock.code} · $marketLabel · 成交值 $valueInYi 億',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 右：漲跌幅徽章
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    changeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.open_in_new_rounded, size: 12, color: Colors.grey.shade400),
              ],
            ),
            // 掃描器指標列（僅強勢股顯示）
            if (isRiser) ...[
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                children: [
                  _scannerChip(
                    strongClose ? '強收 ${(closePos * 100).toStringAsFixed(0)}%' : '弱收 ${(closePos * 100).toStringAsFixed(0)}%',
                    strongClose ? const Color(0xFFC62828) : Colors.grey.shade500,
                    strongClose ? const Color(0xFFFFEBEE) : Colors.grey.shade100,
                  ),
                  _scannerChip(
                    intradayUp
                        ? '日內 +${intradayReturn.toStringAsFixed(1)}%'
                        : '日內 ${intradayReturn.toStringAsFixed(1)}%',
                    intradayUp ? const Color(0xFFC62828) : Colors.grey.shade500,
                    intradayUp ? const Color(0xFFFFEBEE) : Colors.grey.shade100,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scannerChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.5, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 🚀 Phase 5 核心自繪組件：打造高階趨勢看盤圖表面板外殼
  Widget _buildHistoryTrendHeader() {
    // 💡 判斷是否具備大於 1 筆的歷史資料，若目前尚無資料，則觸發「今日盤態雷達分佈」
    final bool hasHistory = _historyRecords.length > 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasHistory
                    ? '${widget.title}  近30日走勢'
                    : '${widget.title} 今日盤態雷達',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasHistory
                      ? Colors.blueAccent.withValues(alpha: 0.08)
                      : Colors.orangeAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasHistory ? '近30日互動圖' : '即時多空分佈',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasHistory
                        ? Colors.blueAccent
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingHistory)
            const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (hasHistory)
            CategoryTrendChart(history: _historyRecords)
          else
            SizedBox(height: 140, child: _buildLiveDistributionRadar()),
        ],
      ),
    );
  }

  /// 📊 即時雷達防線（無歷史資料時使用）：今日細成份股多空漲跌分佈圓餅圖
  /// 🟢 安全完全體：移除了所有致命的內部 SliverToBoxAdapter，改用純粹的標準佈局組件
  Widget _buildLiveDistributionRadar() {
    final double riseRatio = _totalStockCount > 0
        ? _totalRiseCount / _totalStockCount
        : 0.0;
    final double fallRatio = _totalStockCount > 0
        ? _totalFallCount / _totalStockCount
        : 0.0;
    final double keepRatio = 1.0 - riseRatio - fallRatio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🟢 100% 安全：使用固定寬高 SizedBox 包裹自繪甜甜圈圓餅圖，絕不卡死或死循環
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: DistributionPiePainter(
              riseRatio: riseRatio,
              fallRatio: fallRatio,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 右側：高階數據指標對照表
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRadarLabel(
                '上漲家數',
                '$_totalRiseCount 檔',
                '${(riseRatio * 100).toStringAsFixed(1)}%',
                const Color(0xffc62828),
              ),
              const SizedBox(height: 6),
              _buildRadarLabel(
                '下跌家數',
                '$_totalFallCount 檔',
                '${(fallRatio * 100).toStringAsFixed(1)}%',
                const Color(0xff2e7d32),
              ),
              const SizedBox(height: 6),
              _buildRadarLabel(
                '平盤/其他',
                '${_totalStockCount - _totalRiseCount - _totalFallCount} 檔',
                '${(keepRatio * 100).toStringAsFixed(1)}%',
                Colors.grey.shade400,
              ),
              const Divider(height: 12),
              Text(
                '板塊個股總計: $_totalStockCount 檔',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadarLabel(
    String label,
    String count,
    String percent,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Text(
          percent,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🎨 底層自繪引擎：今日多空分佈圓餅圖 (DistributionPiePainter)
// ==========================================
class DistributionPiePainter extends CustomPainter {
  final double riseRatio;
  final double fallRatio;

  DistributionPiePainter({required this.riseRatio, required this.fallRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint risePaint = Paint()
      ..color = const Color(0xffc62828)
      ..style = PaintingStyle.fill;
    final Paint fallPaint = Paint()
      ..color = const Color(0xff2e7d32)
      ..style = PaintingStyle.fill;
    final Paint keepPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    double startAngle = -3.1415926 / 2; // 從 12 點鐘方向順時針繪製

    // 1. 繪製上漲區塊
    if (riseRatio > 0) {
      final double sweepAngle = riseRatio * 2 * 3.1415926;
      canvas.drawArc(rect, startAngle, sweepAngle, true, risePaint);
      startAngle += sweepAngle;
    }

    // 2. 繪製下跌區塊
    if (fallRatio > 0) {
      final double sweepAngle = fallRatio * 2 * 3.1415926;
      canvas.drawArc(rect, startAngle, sweepAngle, true, fallPaint);
      startAngle += sweepAngle;
    }

    // 3. 繪製平盤區塊
    final double keepRatio = 1.0 - riseRatio - fallRatio;
    if (keepRatio > 0) {
      final double sweepAngle = keepRatio * 2 * 3.1415926;
      canvas.drawArc(rect, startAngle, sweepAngle, true, keepPaint);
    }

    // 4. 中心挖空成甜甜圈圖（Donut Chart）
    final Paint centerHolePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, centerHolePaint);
  }

  @override
  bool shouldRepaint(covariant DistributionPiePainter oldDelegate) =>
      oldDelegate.riseRatio != riseRatio || oldDelegate.fallRatio != fallRatio;
}
