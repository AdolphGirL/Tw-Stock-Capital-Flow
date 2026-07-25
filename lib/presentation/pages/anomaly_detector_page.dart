import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// ── 資料模型 ────────────────────────────────────────────────────────────────

class _Anomaly {
  final CategoryUiModel category;
  final double todayScore;
  final double historicalMean;
  final double zScore;
  final int historyDays;

  const _Anomaly({
    required this.category,
    required this.todayScore,
    required this.historicalMean,
    required this.zScore,
    required this.historyDays,
  });

  /// 百分比偏差，用於 UI 顯示
  double get deviationPercent {
    final denom = historicalMean.abs().clamp(0.5, double.infinity);
    return (todayScore - historicalMean) / denom * 100;
  }

  bool get isInflow => zScore > 0;
}

// ── Page ────────────────────────────────────────────────────────────────────

class AnomalyDetectorPage extends StatefulWidget {
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final CategoryHistoryRepository historyRepository;
  final String listedDate; // TWSE 上市交易日
  final String otcDate;    // TPEX 上櫃交易日

  const AnomalyDetectorPage({
    super.key,
    required this.listedCategories,
    required this.otcCategories,
    required this.historyRepository,
    required this.listedDate,
    required this.otcDate,
  });

  @override
  State<AnomalyDetectorPage> createState() => _AnomalyDetectorPageState();
}

class _AnomalyDetectorPageState extends State<AnomalyDetectorPage> {
  // 上市異常清單
  List<_Anomaly> _listedInflows  = [];
  List<_Anomaly> _listedOutflows = [];
  // 上櫃異常清單
  List<_Anomaly> _otcInflows  = [];
  List<_Anomaly> _otcOutflows = [];

  bool _isLoading = true;
  bool _hasEnoughHistory = false;
  int _totalAnalyzed = 0;
  int _historyDaysAvailable = 0;
  int _daysAccumulated = 0; // 實際已累積天數（含未達門檻者），供倒數顯示

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

  Future<void> _compute() async {
    final historyMap =
        await widget.historyRepository.loadAllCategoriesHistory(days: 35);

    final allCategories = [
      ...widget.listedCategories,
      ...widget.otcCategories,
    ];

    final anomalies = <_Anomaly>[];
    const int minDays = 5;

    int maxDays = 0;
    int actualMaxDays = 0; // 不受 minDays 過濾，用於倒數計算

    for (final cat in allCategories) {
      final records = historyMap[cat.name] ?? <CategoryHistoryData>[];

      // 追蹤所有板塊的真實最大天數（用於計算還需幾天才能解鎖）
      if (records.length > actualMaxDays) actualMaxDays = records.length;

      if (records.length < minDays) continue;

      if (records.length > maxDays) maxDays = records.length;

      // 使用 trendStrength 做偏差計算——對資金動能變化最靈敏
      final values = records.map((r) => r.trendStrength).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              values.length;
      final stdDev = math.sqrt(variance);

      final zScore =
          stdDev > 0.01 ? (cat.trendStrength - mean) / stdDev : 0.0;

      anomalies.add(_Anomaly(
        category: cat,
        todayScore: cat.trendStrength,
        historicalMean: mean,
        zScore: zScore,
        historyDays: records.length,
      ));
    }

    // 依 zScore 排序
    final sorted = [...anomalies]..sort((a, b) => b.zScore.compareTo(a.zScore));
    final outflowsSorted = [...anomalies]..sort((a, b) => a.zScore.compareTo(b.zScore));

    // 全部異常清單
    final inflows  = sorted.where((a) => a.zScore > 0.8).take(8).toList();
    final outflows = outflowsSorted.where((a) => a.zScore < -0.8).take(8).toList();

    // 依市場分流（CategoryUiModel 沒有 override ==，用 object identity 精確區分
    // 上市和上櫃中同名板塊的不同實例，避免名稱重疊時歸類錯誤）
    final listedSet = widget.listedCategories.toSet();
    bool isListed(_Anomaly a) => listedSet.contains(a.category);

    if (mounted) {
      setState(() {
        _listedInflows  = inflows.where(isListed).toList();
        _listedOutflows = outflows.where(isListed).toList();
        _otcInflows     = inflows.where((a) => !isListed(a)).toList();
        _otcOutflows    = outflows.where((a) => !isListed(a)).toList();
        _hasEnoughHistory = anomalies.isNotEmpty;
        _totalAnalyzed = anomalies.length;
        _historyDaysAvailable = maxDays;
        _daysAccumulated = actualMaxDays;
        _isLoading = false;
      });
    }
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
            '異常資金偵測器',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF1A237E),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1A237E),
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
                          inflows: _listedInflows,
                          outflows: _listedOutflows,
                          date: widget.listedDate,
                          marketLabel: '上市',
                        ),
                        _buildMarketContent(
                          inflows: _otcInflows,
                          outflows: _otcOutflows,
                          date: widget.otcDate,
                          marketLabel: '上櫃',
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildMarketContent({
    required List<_Anomaly> inflows,
    required List<_Anomaly> outflows,
    required String date,
    required String marketLabel,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(date: date, marketLabel: marketLabel,
            inflows: inflows, outflows: outflows),
        const SizedBox(height: 16),

        if (inflows.isNotEmpty) ...[
          _buildSectionHeader(
            '異常資金湧入',
            '今日趨勢強度顯著高於歷史均值',
            const Color(0xFFC62828),
            Icons.trending_up_rounded,
          ),
          ...inflows.map((a) => Builder(
              builder: (ctx) => _buildAnomalyCard(ctx, a))),
          const SizedBox(height: 16),
        ],

        if (outflows.isNotEmpty) ...[
          _buildSectionHeader(
            '異常資金流出',
            '今日趨勢強度顯著低於歷史均值',
            const Color(0xFF2E7D32),
            Icons.trending_down_rounded,
          ),
          ...outflows.map((a) => Builder(
              builder: (ctx) => _buildAnomalyCard(ctx, a))),
        ],

        if (inflows.isEmpty && outflows.isEmpty) _buildNoAnomalyCard(),

        const SizedBox(height: 20),
      ],
    );
  }

  // ── 摘要卡 ─────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard({
    required String date,
    required String marketLabel,
    required List<_Anomaly> inflows,
    required List<_Anomaly> outflows,
  }) {
    final dateLabel = _formatDate(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
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
              const Icon(Icons.radar_rounded, color: Colors.white70, size: 16),
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
              _buildStatChip('分析板塊', '$_totalAnalyzed 個'),
              const SizedBox(width: 12),
              _buildStatChip('歷史基準', '$_historyDaysAvailable 日均值'),
              const SizedBox(width: 12),
              _buildStatChip('異常訊號',
                  '${inflows.length + outflows.length} 個'),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '以板塊自身近期趨勢強度做為基準，偵測今日顯著偏離歷史均值的板塊。\n偏離越大代表資金行為越異常，值得重點關注。',
            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
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

  // ── 異常板塊卡片 ───────────────────────────────────────────────────────────

  Widget _buildAnomalyCard(BuildContext context, _Anomaly anomaly) {
    final isInflow = anomaly.isInflow;
    final accentColor =
        isInflow ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bgColor =
        isInflow ? const Color(0xFFFFF5F5) : const Color(0xFFF1F8E9);

    final devPct = anomaly.deviationPercent;
    final devLabel = devPct >= 0
        ? '+${devPct.toStringAsFixed(0)}%'
        : '${devPct.toStringAsFixed(0)}%';
    final zLabel = 'z=${anomaly.zScore.toStringAsFixed(1)}';

    // 偏差條：最大寬度對應 z=3
    final barFill = (anomaly.zScore.abs() / 3.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => CategoryNavigation.openCategory(
        context,
        anomaly.category,
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
                // 板塊名稱
                Expanded(
                  child: Text(
                    anomaly.category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                // 偏差百分比
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
            // 均值 vs 今日
            Row(
              children: [
                Text(
                  '均值 ${anomaly.historicalMean.toStringAsFixed(1)}',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Icon(
                  isInflow ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 12,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日 ${anomaly.todayScore.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor),
                ),
                const Spacer(),
                Text(
                  zLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 偏差視覺條
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
    const int minDays = 5;
    final stillNeeded = (minDays - _daysAccumulated).clamp(0, minDays);

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
                // 進度指示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(minDays, (i) {
                    final filled = i < _daysAccumulated;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: filled
                            ? const Color(0xFF1A237E)
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
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A237E)),
                ),
                const SizedBox(height: 8),
                Text(
                  '異常偵測需要 $minDays 個交易日的歷史基準，\n系統每日開盤後自動記錄，無需手動操作。',
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

  Widget _buildNoAnomalyCard() {
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
            '今日市場正常，無明顯異常資金',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            '所有板塊的趨勢強度均在歷史正常範圍內（|z| ≤ 0.8），未偵測到顯著異常。',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}
