import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/enums/category_sort_type.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// 🚀 Phase 5 核心引入：引入 Drift 的歷史數據實體模型以承接 SQLite 資料庫數據
import 'package:tw_stock_capital_flow/data/database/app_database.dart';

class SubCategoryPage extends StatefulWidget {
  final List<CategoryUiModel> categories;
  final String title;
  final CategoryHistoryRepository historyRepository;

  const SubCategoryPage({
    super.key,
    required this.categories,
    required this.title,
    required this.historyRepository,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  late List<CategoryUiModel> categories;
  CategorySortType sortType = CategorySortType.score;

  // 🚀 Phase 5 變數：儲存調取出來的歷史看盤數據與載入狀態
  List<CategoryHistoryData> _historyRecords = [];
  bool _isLoadingHistory = true;

  // 🚀 數據統計防線：當無歷史資料時，計算今日大板塊內細分產業股票的加總分佈
  int _totalRiseCount = 0;
  int _totalFallCount = 0;
  int _totalStockCount = 0;

  @override
  void initState() {
    super.initState();
    categories = [...widget.categories];
    applySort();

    // 💡 預先統計今日該板塊內所有個股的漲跌總數，提供雷達圓餅圖最精準的占比
    _calculateLiveDistribution();

    // 🚀 初始化時，立刻向本地 SQLite 發起歷史數據穿透回溯
    _fetchHistoryData();
  }

  /// 計算今日即時分布狀態
  void _calculateLiveDistribution() {
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
    setState(() => _isLoadingHistory = true);
    try {
      // 💡 精確對接專案原始代碼：呼叫 getCategoryTrend 取得 15 天歷史
      final records = await widget.historyRepository.getCategoryTrend(
        widget.title, // 傳入當前大分類板塊名稱
        limit: 15, // 拉取 15 天數據
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<CategorySortType>(
            onSelected: (value) {
              sortType = value;
              applySort();
            },
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
            color: Colors.black.withOpacity(0.01),
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
                    ? '${widget.title} 板塊歷史資金走勢'
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
                      ? Colors.blueAccent.withOpacity(0.08)
                      : Colors.orangeAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasHistory ? '歷史 K 線回溯' : '即時多空分佈',
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

          // 圖表渲染核心限制盒（固定高度 140）
          SizedBox(
            height: 140,
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : hasHistory
                ? _buildLineChart() // 📈 渲染歷史折線走勢圖
                : _buildLiveDistributionRadar(), // 📊 降級防線：即時多空比例圖
          ),
        ],
      ),
    );
  }

  /// 📈 核心圖表 A：自繪 15 日資金流分數走勢圖
  Widget _buildLineChart() {
    final scores = _historyRecords.map((e) => e.score).toList();
    final dates = _historyRecords
        .map(
          (e) =>
              e.tradeDate.length > 4 ? e.tradeDate.substring(4) : e.tradeDate,
        )
        .toList();

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: CategoryTrendPainter(scores: scores),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dates.first,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              dates[dates.length ~/ 2],
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              dates.last,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 核心圖表 B（即時雷達防線）：今日細成份股多空漲跌分佈圓餅圖
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
// 🎨 底層自繪引擎：趨勢折線圖畫布 (CategoryTrendPainter)
// ==========================================
class CategoryTrendPainter extends CustomPainter {
  final List<double> scores;
  CategoryTrendPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    double maxScore = scores.reduce((a, b) => a > b ? a : b);
    double minScore = scores.reduce((a, b) => a < b ? a : b);

    if ((maxScore - minScore).abs() < 0.1) {
      maxScore += 1.0;
      minScore -= 1.0;
    }

    maxScore += (maxScore - minScore) * 0.1;
    minScore -= (maxScore - minScore) * 0.1;

    final double range = maxScore - minScore;

    // 繪製零軸參考線
    if (maxScore > 0 && minScore < 0) {
      final double zeroY = height - ((0.0 - minScore) / range * height);
      final Paint zeroPaint = Paint()
        ..color = Colors.grey.shade200
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, zeroY), Offset(width, zeroY), zeroPaint);
    }

    // 建立折線點
    final double stepX = width / (scores.length - 1);
    final List<Offset> points = [];
    for (int i = 0; i < scores.length; i++) {
      final double x = i * stepX;
      final double y = height - ((scores[i] - minScore) / range * height);
      points.add(Offset(x, y));
    }

    // 繪製漸層陰影
    final Path shadowPath = Path()..moveTo(points.first.dx, height);
    for (var pt in points) {
      shadowPath.lineTo(pt.dx, pt.dy);
    }
    shadowPath.lineTo(points.last.dx, height);
    shadowPath.close();

    final Paint shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blueAccent.withOpacity(0.15),
          Colors.blueAccent.withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTRB(0, 0, width, height));
    canvas.drawPath(shadowPath, shadowPaint);

    // 繪製主趨勢折線
    final Paint linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // 繪製最新端點
    final Paint dotPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    // 🟢 修正點：使用相容性最高、最穩定的 withOpacity(0.2) 宣告光暈
    final Paint dotHalo = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(points.last, 7, dotHalo);
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CategoryTrendPainter oldDelegate) =>
      oldDelegate.scores != scores;
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
