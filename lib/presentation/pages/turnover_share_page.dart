import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/data/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';

// ── 資料模型 ────────────────────────────────────────────────────────────────

/// 一個板塊「今日成交值佔大盤/櫃買比重」相對過去均值的偏移。
class _ShareShift {
  final CategoryUiModel category;
  final double todayWeightPct;   // 今日成交值佔該市場總成交值的比重（%）
  final double avgWeightPct;     // 過去 N 個交易日的平均比重（%）
  final int sampleDays;          // 平均用了幾天算出

  const _ShareShift({
    required this.category,
    required this.todayWeightPct,
    required this.avgWeightPct,
    required this.sampleDays,
  });

  /// 百分點差（非相對百分比）：今日比重 − 過去均值比重
  double get deviation => todayWeightPct - avgWeightPct;

  bool get isGaining => deviation > 0;
}

// ── Page ────────────────────────────────────────────────────────────────────

/// 板塊資金佔比異動：計算每個大類股「今日成交值佔大盤/櫃買總成交值的比重」，
/// 與過去最多 5 個交易日的平均比重相比，偏移達門檻（百分點）即標註。
/// 取代原本以 trendStrength 做 Z-score 統計的「異常資金偵測器」——
/// 直接反映「今天錢實際往哪個板塊集中」，對散戶更直覺。
class TurnoverSharePage extends StatefulWidget {
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final CategoryHistoryRepository historyRepository;
  final StorageService storageService;
  final String listedDate; // TWSE 上市交易日
  final String otcDate;    // TPEX 上櫃交易日

  const TurnoverSharePage({
    super.key,
    required this.listedCategories,
    required this.otcCategories,
    required this.historyRepository,
    required this.storageService,
    required this.listedDate,
    required this.otcDate,
  });

  @override
  State<TurnoverSharePage> createState() => _TurnoverSharePageState();
}

class _TurnoverSharePageState extends State<TurnoverSharePage> {
  static const double _thresholdPoints = 5.0; // 偏移門檻：5 個百分點
  static const int _minSampleDays = 3;        // 至少要有 3 天歷史樣本才列入比較
  static const int _targetHistoryDays = 6;    // 今日 + 最多 5 天歷史

  List<_ShareShift> _listedGaining = [];
  List<_ShareShift> _listedLosing = [];
  List<_ShareShift> _otcGaining = [];
  List<_ShareShift> _otcLosing = [];

  int _listedAnalyzed = 0;
  int _otcAnalyzed = 0;
  double _listedTotalValueYi = 0;
  double _otcTotalValueYi = 0;

  bool _isLoading = true;
  bool _hasEnoughHistory = false;
  int _daysAccumulated = 0; // 實際可用的歷史天數（不含今日），供倒數顯示

  /// 民國年 YYYMMDD (7碼) 或西元年 YYYYMMDD (8碼) → 帶分隔符顯示字串
  String _formatDate(String raw) {
    if (raw.length == 7) {
      return '${raw.substring(0, 3)}-${raw.substring(3, 5)}-${raw.substring(5, 7)}';
    }
    if (raw.length == 8) {
      return '${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6, 8)}';
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void didUpdateWidget(TurnoverSharePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listedDate != widget.listedDate ||
        oldWidget.otcDate != widget.otcDate) {
      _compute();
    }
  }

  Future<void> _compute() async {
    final historyRepo = HistoryRepository(storageService: widget.storageService);
    final snapshots = await historyRepo.loadRecentSnapshots(_targetHistoryDays);

    if (snapshots.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasEnoughHistory = false;
          _daysAccumulated = 0;
        });
      }
      return;
    }

    final today = snapshots.first;
    final priorDays = snapshots.skip(1).toList();

    final listedResult = _computeForMarket(
      market: MarketType.listed,
      categories: widget.listedCategories,
      today: today,
      priorDays: priorDays,
    );
    final otcResult = _computeForMarket(
      market: MarketType.otc,
      categories: widget.otcCategories,
      today: today,
      priorDays: priorDays,
    );

    if (!mounted) return;
    setState(() {
      _listedGaining = listedResult.gaining;
      _listedLosing = listedResult.losing;
      _otcGaining = otcResult.gaining;
      _otcLosing = otcResult.losing;
      _listedAnalyzed = listedResult.analyzed;
      _otcAnalyzed = otcResult.analyzed;
      _listedTotalValueYi = listedResult.totalValueYi;
      _otcTotalValueYi = otcResult.totalValueYi;
      _daysAccumulated = priorDays.length;
      // 至少要有 _minSampleDays 天歷史才有意義；raw 快照最多只保留 7 天，
      // 不強求一定要湊滿 5 天。
      _hasEnoughHistory = priorDays.length >= _minSampleDays;
      _isLoading = false;
    });
  }

  ({
    List<_ShareShift> gaining,
    List<_ShareShift> losing,
    int analyzed,
    double totalValueYi,
  }) _computeForMarket({
    required MarketType market,
    required List<CategoryUiModel> categories,
    required StockDaySnapshot today,
    required List<StockDaySnapshot> priorDays,
  }) {
    final todayStocks = today.stocks.where((s) => s.market == market).toList();
    final todayTotal = todayStocks.fold<int>(0, (sum, s) => sum + s.value);

    if (todayTotal == 0) {
      return (gaining: <_ShareShift>[], losing: <_ShareShift>[], analyzed: 0, totalValueYi: 0);
    }

    final Map<String, int> todayCategoryValue = {};
    for (final s in todayStocks) {
      todayCategoryValue.update(s.mainCategory, (v) => v + s.value, ifAbsent: () => s.value);
    }

    // 逐日計算歷史比重，同板塊累積成一個樣本清單再取平均
    final Map<String, List<double>> historicalWeights = {};
    for (final day in priorDays) {
      final dayStocks = day.stocks.where((s) => s.market == market).toList();
      final dayTotal = dayStocks.fold<int>(0, (sum, s) => sum + s.value);
      if (dayTotal == 0) continue;

      final Map<String, int> dayCategoryValue = {};
      for (final s in dayStocks) {
        dayCategoryValue.update(s.mainCategory, (v) => v + s.value, ifAbsent: () => s.value);
      }
      dayCategoryValue.forEach((name, value) {
        historicalWeights.putIfAbsent(name, () => []).add(value / dayTotal * 100);
      });
    }

    final shifts = <_ShareShift>[];
    for (final cat in categories) {
      final todayValue = todayCategoryValue[cat.name];
      if (todayValue == null) continue;

      final hist = historicalWeights[cat.name];
      if (hist == null || hist.length < _minSampleDays) continue;

      final todayWeight = todayValue / todayTotal * 100;
      final avgWeight = hist.reduce((a, b) => a + b) / hist.length;

      shifts.add(_ShareShift(
        category: cat,
        todayWeightPct: todayWeight,
        avgWeightPct: avgWeight,
        sampleDays: hist.length,
      ));
    }

    final gaining = shifts.where((s) => s.deviation >= _thresholdPoints).toList()
      ..sort((a, b) => b.deviation.compareTo(a.deviation));
    final losing = shifts.where((s) => s.deviation <= -_thresholdPoints).toList()
      ..sort((a, b) => a.deviation.compareTo(b.deviation));

    return (
      gaining: gaining,
      losing: losing,
      analyzed: shifts.length,
      totalValueYi: todayTotal / 100000000.0,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        appBar: AppBar(
          title: const Text(
            '板塊資金佔比異動',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF00695C),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF00695C),
            tabs: [
              Tab(text: '上市'),
              Tab(text: '上櫃'),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_hasEnoughHistory
                  ? _buildNoHistoryState()
                  : TabBarView(
                      children: [
                        _buildMarketContent(
                          gaining: _listedGaining,
                          losing: _listedLosing,
                          date: widget.listedDate,
                          marketLabel: '上市',
                          market: MarketType.listed,
                          analyzed: _listedAnalyzed,
                          totalValueYi: _listedTotalValueYi,
                        ),
                        _buildMarketContent(
                          gaining: _otcGaining,
                          losing: _otcLosing,
                          date: widget.otcDate,
                          marketLabel: '上櫃',
                          market: MarketType.otc,
                          analyzed: _otcAnalyzed,
                          totalValueYi: _otcTotalValueYi,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildMarketContent({
    required List<_ShareShift> gaining,
    required List<_ShareShift> losing,
    required String date,
    required String marketLabel,
    required MarketType market,
    required int analyzed,
    required double totalValueYi,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(
          date: date,
          marketLabel: marketLabel,
          analyzed: analyzed,
          totalValueYi: totalValueYi,
          shiftCount: gaining.length + losing.length,
        ),
        const SizedBox(height: 16),

        if (gaining.isNotEmpty) ...[
          _buildSectionHeader(
            '佔比顯著上升',
            '今日成交值比重明顯高於過去均值，資金集中度上升',
            const Color(0xFFC62828),
            Icons.trending_up_rounded,
          ),
          ...gaining.map((s) => Builder(
              builder: (ctx) => _buildShiftCard(ctx, s, market))),
          const SizedBox(height: 16),
        ],

        if (losing.isNotEmpty) ...[
          _buildSectionHeader(
            '佔比顯著下降',
            '今日成交值比重明顯低於過去均值，資金關注度降溫',
            const Color(0xFF2E7D32),
            Icons.trending_down_rounded,
          ),
          ...losing.map((s) => Builder(
              builder: (ctx) => _buildShiftCard(ctx, s, market))),
        ],

        if (gaining.isEmpty && losing.isEmpty) _buildNoShiftCard(),

        const SizedBox(height: 20),
      ],
    );
  }

  // ── 摘要卡 ─────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard({
    required String date,
    required String marketLabel,
    required int analyzed,
    required double totalValueYi,
    required int shiftCount,
  }) {
    final dateLabel = _formatDate(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '$marketLabel · $dateLabel',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip('分析板塊', '$analyzed 個'),
              const SizedBox(width: 12),
              _buildStatChip('今日總成交值', '${totalValueYi.toStringAsFixed(0)} 億'),
              const SizedBox(width: 12),
              _buildStatChip('異動訊號', '$shiftCount 個'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '計算各板塊今日成交值佔$marketLabel總成交值的比重，'
            '與過去 $_daysAccumulated 個交易日的平均比重相比。\n'
            '偏移達 ±${_thresholdPoints.toStringAsFixed(0)} 個百分點即標註，代表資金集中度出現明顯變化。',
            style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── 段落標題 ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
      String title, String subtitle, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── 異動板塊卡片 ───────────────────────────────────────────────────────────

  Widget _buildShiftCard(BuildContext context, _ShareShift shift, MarketType market) {
    final isGaining = shift.isGaining;
    final accentColor =
        isGaining ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bgColor =
        isGaining ? const Color(0xFFFFF5F5) : const Color(0xFFF1F8E9);

    final devLabel = isGaining
        ? '+${shift.deviation.toStringAsFixed(1)}pt'
        : '${shift.deviation.toStringAsFixed(1)}pt';

    // 偏差條：最大寬度對應 15 個百分點
    final barFill = (shift.deviation.abs() / 15.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => CategoryNavigation.openCategory(
        context,
        market,
        shift.category,
        widget.historyRepository,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shift.category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    devLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '過去均值 ${shift.avgWeightPct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Icon(
                  isGaining ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 12,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日 ${shift.todayWeightPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor),
                ),
                const Spacer(),
                Text(
                  '${shift.sampleDays} 日均',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: barFill,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    accentColor.withValues(alpha: 0.7)),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 空態 ───────────────────────────────────────────────────────────────────

  Widget _buildNoHistoryState() {
    final stillNeeded = (_minSampleDays - _daysAccumulated).clamp(0, _minSampleDays);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  '歷史資料累積中',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_minSampleDays, (i) {
                    final filled = i < _daysAccumulated;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: filled
                            ? const Color(0xFF00695C)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: filled ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  stillNeeded > 0
                      ? '已累積 $_daysAccumulated 個交易日，還需 $stillNeeded 天即可解鎖'
                      : '資料已準備完成，請稍後重新整理',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00695C)),
                ),
                const SizedBox(height: 8),
                Text(
                  '需要至少 $_minSampleDays 個交易日的成交值歷史才能算出穩定均值，\n'
                  '系統每日開盤後自動記錄，無需手動操作。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShiftCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 36, color: Colors.green.shade400),
          const SizedBox(height: 12),
          const Text(
            '今日資金分布正常，無明顯集中度異動',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            '所有板塊今日成交值佔比與過去均值相差在 ±${_thresholdPoints.toStringAsFixed(0)} 個百分點以內。',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}
