import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

import 'package:tw_stock_capital_flow/presentation/widgets/home_section_card.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_summary_card.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_signal_summary.dart';

import 'package:tw_stock_capital_flow/presentation/pages/mainstream_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/main_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/market_sentiment_page.dart';

// 🚀 引入本地 SQLite 歷史紀錄 Repository
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/watchlist_button.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

class HomePage extends StatelessWidget {
  final String tradeDate;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final double listedScore;
  final int otcRiseCount;
  final int otcFallCount;
  final double otcScore;
  final List<RotationResult> rotations;
  final List<MainstreamResult> mainstreams;
  final List<LifecycleResult> lifecycles;
  final MarketSentimentResult? sentiment;

  final CategoryHistoryRepository historyRepository;
  final WatchlistRepository watchlistRepository;

  const HomePage({
    super.key,
    required this.tradeDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
    required this.rotations,
    required this.mainstreams,
    required this.lifecycles,
    required this.sentiment,
    required this.historyRepository,
    required this.watchlistRepository,
  });

  /// 將資料庫的 YYYYMMDD 轉化為交易者易讀的 YYYY-MM-DD
  String _formatTradeDate(String rawDate) {
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
            const SizedBox(height: 24),

            // 🌊 2. 市場主流大方向（點擊直接穿透）
            _buildMainstreamSection(context),
            const SizedBox(height: 20),

            // 🧠 3. 市場熱錢情緒與心理週期（保留，提供綜合風控決策層面）
            _buildSentimentSection(context),
            const SizedBox(height: 20),

            // 💡 提示性微卡片：引導用戶切換底部頁籤看深度策略
            _buildNavigationHintCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 🟢 修正：恢復標準的具名參數賦值
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
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 12,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTradeDate(tradeDate),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
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
            riseCount: otcRiseCount,
            fallCount: otcFallCount,
            score: otcScore,
          ),
        ),
      ],
    );
  }

  Widget _buildMainstreamSection(BuildContext context) {
    final top = mainstreams.isEmpty ? null : mainstreams.first;

    return HomeSectionCard(
      title: '市場最強主流',
      subtitle: top == null ? '-' : top.category,
      description: '點擊深入追蹤多週期資金強勁凝聚方向',
      gradient: const [Color(0xff1e3c72), Color(0xff2a5298)],
      icon: Icons.auto_graph,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainstreamPage(mainstreams: mainstreams),
          ),
        );
      },
    );
  }

  Widget _buildSentimentSection(BuildContext context) {
    return HomeSectionCard(
      title: '市場熱錢情緒',
      subtitle: sentiment == null ? '-' : sentiment!.level.name,
      description: sentiment == null
          ? '-'
          : '熱錢湧入強度達 ${sentiment!.hotMoneyStrength.toStringAsFixed(1)}，注意水位風控',
      gradient: const [Color(0xff134e5e), Color(0xff71b280)],
      icon: Icons.psychology,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketSentimentPage(result: sentiment!),
          ),
        );
      },
    );
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
