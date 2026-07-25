import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

import 'package:tw_stock_capital_flow/domain/enums/sentiment_level.dart';
import 'package:tw_stock_capital_flow/domain/models/institutional_flow_result.dart';
import 'package:tw_stock_capital_flow/data/services/institutional_flow_service.dart';
import 'package:tw_stock_capital_flow/data/services/institutional_flow_history_service.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_summary_card.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_signal_summary.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/institutional_flow_chart.dart';

import 'package:tw_stock_capital_flow/presentation/pages/main_category_page.dart';

// 🚀 引入本地 SQLite 歷史紀錄 Repository
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/watchlist_button.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

class HomePage extends StatefulWidget {
  final String listedDate; // TWSE 上市交易日
  final String otcDate;    // TPEX 上櫃交易日
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final double listedScore;
  final int otcRiseCount;
  final int otcFallCount;
  final double otcScore;
  final List<LifecycleResult> lifecycles;
  final MarketSentimentResult? sentiment;

  final CategoryHistoryRepository historyRepository;
  final WatchlistRepository watchlistRepository;
  final StorageService storageService;
  final Future<void> Function()? onRefresh;

  const HomePage({
    super.key,
    required this.listedDate,
    required this.otcDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
    required this.lifecycles,
    required this.sentiment,
    required this.historyRepository,
    required this.watchlistRepository,
    required this.storageService,
    this.onRefresh,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String get listedDate => widget.listedDate;
  String get otcDate    => widget.otcDate;
  // 三大法人 / watchlist signal 等仍需一個統一日期：取較新者
  String get tradeDate  => listedDate.compareTo(otcDate) >= 0 ? listedDate : otcDate;
  List<CategoryUiModel> get listedCategories => widget.listedCategories;
  List<CategoryUiModel> get otcCategories => widget.otcCategories;
  int get listedRiseCount => widget.listedRiseCount;
  int get listedFallCount => widget.listedFallCount;
  double get listedScore => widget.listedScore;
  int get otcRiseCount => widget.otcRiseCount;
  int get otcFallCount => widget.otcFallCount;
  double get otcScore => widget.otcScore;
  List<LifecycleResult> get lifecycles => widget.lifecycles;
  MarketSentimentResult? get sentiment => widget.sentiment;
  CategoryHistoryRepository get historyRepository => widget.historyRepository;
  WatchlistRepository get watchlistRepository => widget.watchlistRepository;
  StorageService get storageService => widget.storageService;

  InstitutionalFlowResult? _institutionalFlow;
  List<InstitutionalFlowResult> _flowHistory = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchFlow();
    _loadFlowHistory();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listedDate != widget.listedDate ||
        oldWidget.otcDate != widget.otcDate) {
      _fetchFlow();
    }
  }

  /// 民國年 YYYMMDD → 西元年 YYYYMMDD；已是 8 碼則直接回傳。
  String _toGregorianKey(String raw) {
    if (raw.length == 8) return raw;
    if (raw.length == 7) {
      final rocYear = int.tryParse(raw.substring(0, 3));
      if (rocYear != null) return '${rocYear + 1911}${raw.substring(3)}';
    }
    return raw;
  }

  Future<void> _fetchFlow() async {
    final dateKey = _toGregorianKey(tradeDate);
    debugPrint('[法人籌碼] _fetchFlow 啟動: dateKey=$dateKey (原始: $tradeDate)');
    if (dateKey.length != 8) {
      debugPrint('[法人籌碼] _fetchFlow 跳過 — 日期格式錯誤');
      return;
    }
    try {
      // 先嘗試股票資料同一天，若非交易日最多往前找 5 個日曆日
      InstitutionalFlowResult? result =
          await InstitutionalFlowService.fetchForDate(dateKey);

      if (result == null) {
        final base = DateTime(
          int.parse(dateKey.substring(0, 4)),
          int.parse(dateKey.substring(4, 6)),
          int.parse(dateKey.substring(6, 8)),
        );
        for (int i = 1; i <= 5 && result == null; i++) {
          final prev = base.subtract(Duration(days: i));
          final prevKey =
              '${prev.year}${prev.month.toString().padLeft(2, '0')}${prev.day.toString().padLeft(2, '0')}';
          result = await InstitutionalFlowService.fetchForDate(prevKey);
        }
      }

      debugPrint('[法人籌碼] _fetchFlow 結果: ${result?.date ?? "null"}');
      if (result != null && mounted) {
        // 存入歷史後重新載入，確保圖表包含今日資料
        await InstitutionalFlowHistoryService.save(storageService, result);
        _loadFlowHistory();
        setState(() => _institutionalFlow = result);
      }
    } catch (e) {
      debugPrint('[法人籌碼] _fetchFlow 例外: $e');
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh!();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('重新整理失敗，請稍後再試'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadFlowHistory() async {
    final history = await InstitutionalFlowHistoryService.loadRecent(storageService);
    if (mounted) setState(() => _flowHistory = history);
  }

  /// 民國年 YYYMMDD (7碼) 或西元年 YYYYMMDD (8碼) → 帶分隔符顯示字串
  String _formatTradeDate(String rawDate) {
    if (rawDate.length == 7) {
      return '${rawDate.substring(0, 3)}-${rawDate.substring(3, 5)}-${rawDate.substring(5, 7)}';
    }
    if (rawDate.length == 8) {
      return '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}';
    }
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(), // 頂部動態日期與標題
            const SizedBox(height: 24),

            // 🚦 0. 今日全市場訊號快照
            _buildSignalSummaryCard(context),
            const SizedBox(height: 20),

            // ⭐ 0.5 觀察清單（有資料才顯示）
            _buildWatchlistSection(context),

            // 📊 1. 上市與上櫃多空家數診斷（保留作為一開屏的核心摘要）
            _buildMarketSection(context),
            const SizedBox(height: 20),

            // 🏦 2. 三大法人籌碼
            _buildInstitutionalSection(),

            // 🧠 3. 市場熱錢情緒（直接內嵌顯示）
            _buildSentimentSection(),
            const SizedBox(height: 20),

            // 💡 提示性微卡片：引導用戶切換底部頁籤看深度策略
            _buildNavigationHintCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final isBeforeCutoff = now.hour < 18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '大盤大數據',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '全市場多空診斷與核心指標',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // 刷新按鈕（日期 chip 已移入各市場卡片內）
            if (widget.onRefresh != null)
              GestureDetector(
                onTap: _isRefreshing ? null : _handleRefresh,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                    ),
                  ),
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blueAccent,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Colors.blueAccent,
                        ),
                ),
              ),
          ],
        ),
        if (isBeforeCutoff) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '收盤資料每日 18:00 後更新，目前顯示上一交易日數據',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMarketSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainCategoryPage(
                  title: '上市市場板塊',
                  categories: listedCategories,
                  historyRepository: historyRepository,
                ),
              ),
            );
          },
          child: MarketSummaryCard(
            title: '上市市場',
            dateLabel: _formatTradeDate(listedDate),
            riseCount: listedRiseCount,
            fallCount: listedFallCount,
            score: listedScore,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainCategoryPage(
                  title: '上櫃市場板塊',
                  categories: otcCategories,
                  historyRepository: historyRepository,
                ),
              ),
            );
          },
          child: MarketSummaryCard(
            title: '上櫃市場',
            dateLabel: _formatTradeDate(otcDate),
            riseCount: otcRiseCount,
            fallCount: otcFallCount,
            score: otcScore,
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentSection() {
    if (sentiment == null) return const SizedBox.shrink();
    final s = sentiment!;

    final ({String label, Color color, Color bg, Color barColor}) levelInfo;
    switch (s.level) {
      case SentimentLevel.euphoric:
        levelInfo = (
          label: '過熱警惕',
          color: const Color(0xFFF57F17),
          bg: const Color(0xFFFFF3E0),
          barColor: const Color(0xFFFF8F00),
        );
        break;
      case SentimentLevel.optimistic:
        levelInfo = (
          label: '資金樂觀',
          color: const Color(0xFF2E7D32),
          bg: const Color(0xFFE8F5E9),
          barColor: const Color(0xFF43A047),
        );
        break;
      case SentimentLevel.neutral:
        levelInfo = (
          label: '中性觀望',
          color: const Color(0xFF546E7A),
          bg: const Color(0xFFECEFF1),
          barColor: const Color(0xFF78909C),
        );
        break;
      case SentimentLevel.weak:
        levelInfo = (
          label: '偏空悲觀',
          color: const Color(0xFFE65100),
          bg: const Color(0xFFFFF3E0),
          barColor: const Color(0xFFFF6D00),
        );
        break;
      case SentimentLevel.panic:
        levelInfo = (
          label: '市場恐慌',
          color: const Color(0xFFC62828),
          bg: const Color(0xFFFFEBEE),
          barColor: const Color(0xFFEF5350),
        );
        break;
    }

    final barValue = (s.score / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列 + 情緒等級徽章
          Row(
            children: [
              const Icon(Icons.psychology, size: 18, color: Color(0xFF37474F)),
              const SizedBox(width: 6),
              const Text(
                '市場熱錢情緒',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelInfo.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: levelInfo.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  levelInfo.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: levelInfo.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 情緒分數進度條
          Row(
            children: [
              Text(
                '情緒分數',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                s.score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: levelInfo.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barValue,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(levelInfo.barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // 指標數字列
          Row(
            children: [
              _buildSentimentMetric('上漲', '${s.riseCount}', const Color(0xFF2E7D32)),
              _buildSentimentDivider(),
              _buildSentimentMetric('下跌', '${s.fallCount}', const Color(0xFFC62828)),
              _buildSentimentDivider(),
              _buildSentimentMetric(
                '熱錢強度',
                s.hotMoneyStrength.toStringAsFixed(1),
                levelInfo.color,
              ),
              _buildSentimentDivider(),
              _buildSentimentMetric(
                '主流均強',
                s.mainstreamAverage.toStringAsFixed(1),
                const Color(0xFF1565C0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFEEEEEE));
  }

  Widget _buildWatchlistSection(BuildContext context) {
    return StreamBuilder<List>(
      stream: watchlistRepository.watchAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final entries = snapshot.data!;
        final strategy = MomentumStrategy();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFF9C4)),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF9A825), size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    '我的觀察清單',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} 個板塊',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...entries.map((entry) {
                final name = (entry as dynamic).categoryName as String;
                final lcList = lifecycles.where((l) => l.category == name).toList();
                if (lcList.isEmpty) {
                  return _buildWatchlistEmptyTile(name);
                }
                final lc = lcList.first;
                final signal = strategy.evaluate(lc, dateKey: tradeDate);
                return _buildWatchlistTile(context, name, signal);
              }),
            ],
          ),
        );
      },
    );
  }

  /// 在上市 / 上櫃大板塊中尋找符合名稱的 CategoryUiModel（含子層搜尋）
  CategoryUiModel? _findCategory(String name) {
    for (final cat in listedCategories) {
      if (cat.name == name) return cat;
      for (final child in cat.children) {
        if (child.name == name) return child;
      }
    }
    for (final cat in otcCategories) {
      if (cat.name == name) return cat;
      for (final child in cat.children) {
        if (child.name == name) return child;
      }
    }
    return null;
  }

  Widget _buildWatchlistTile(BuildContext context, String name, StrategySignal signal) {
    Color accentColor;
    String actionLabel;
    Color bgColor;
    switch (signal.action) {
      case StrategyAction.buy:
        accentColor = const Color(0xFF2E7D32);
        actionLabel = '買進';
        bgColor = const Color(0xFFE8F5E9);
        break;
      case StrategyAction.hold:
        accentColor = const Color(0xFFF57F17);
        actionLabel = '續抱';
        bgColor = const Color(0xFFFFF9C4);
        break;
      case StrategyAction.sell:
        accentColor = const Color(0xFFC62828);
        actionLabel = '出清';
        bgColor = const Color(0xFFFFEBEE);
        break;
      case StrategyAction.neutral:
        accentColor = const Color(0xFF616161);
        actionLabel = '觀望';
        bgColor = const Color(0xFFF5F5F5);
        break;
    }

    final cat = _findCategory(name);
    return GestureDetector(
      onTap: cat == null
          ? null
          : () => CategoryNavigation.openCategory(context, cat, historyRepository),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            if (cat != null)
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            WatchlistButton(repository: watchlistRepository, categoryName: name, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistEmptyTile(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            ),
          ),
          const Text('暫無資料', style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
        ],
      ),
    );
  }

  Widget _buildSignalSummaryCard(BuildContext context) {
    if (lifecycles.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: MarketSignalSummary(
        lifecycles: lifecycles,
        tradeDate: tradeDate,
        listedCategories: listedCategories,
        otcCategories: otcCategories,
        historyRepository: historyRepository,
      ),
    );
  }

  // ── 三大法人籌碼 ───────────────────────────────────────────────────────────

  Widget _buildInstitutionalSection() {
    if (_institutionalFlow == null) return const SizedBox.shrink();
    final flow = _institutionalFlow!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.account_balance_rounded,
                    size: 17, color: Color(0xFF5C6BC0)),
                const SizedBox(width: 7),
                const Text(
                  '三大法人籌碼',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatTradeDate(flow.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── 外資 / 投信 / 自營商 三欄 ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              children: [
                _buildGroupCell(flow.foreign),
                _buildGroupVerticalDivider(),
                _buildGroupCell(flow.trust),
                _buildGroupVerticalDivider(),
                _buildGroupCell(flow.dealer),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── 三大合計 ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '三大合計',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '買 ${flow.total.buyLabel}  賣 ${flow.total.sellLabel}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                Text(
                  flow.total.netLabel,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: flow.total.isBuyNet
                        ? const Color(0xFFC62828)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),

          // ── 歷史流向圖（有歷史資料才顯示）──────────────────────────────
          if (_flowHistory.length >= 2) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_flowHistory.length} 日歷史流向',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InstitutionalFlowChart(history: _flowHistory),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupCell(InstitutionalGroup group) {
    final color = group.isBuyNet
        ? const Color(0xFFC62828)
        : const Color(0xFF2E7D32);

    return Expanded(
      child: Column(
        children: [
          Text(
            group.name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            group.netLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '買 ${group.buyLabel}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
          Text(
            '賣 ${group.sellLabel}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupVerticalDivider() {
    return Container(
      width: 1,
      height: 64,
      color: Colors.grey.shade100,
    );
  }

  // ── end 三大法人 ──────────────────────────────────────────────────────────

  /// 🌟 視覺化小彩蛋：引導用戶使用底部高階標籤頁
  Widget _buildNavigationHintCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '💡 深度雷達提示：更完整的「資金熱區熱圖」、「動量紅綠燈決策」與「主力輪動領先雷達」功能已轉移至底部頁籤，提供隨切秒開的跨分頁高效操盤體驗。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
