import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/models/leading_indicator_result.dart';
import 'package:tw_stock_capital_flow/domain/analysers/rotation_leading_analyser.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_history_summary.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/watchlist_button.dart';

class LeadingIndicatorPage extends StatelessWidget {
  final List<RotationResult> rotations;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final CategoryHistoryRepository historyRepository;
  final WatchlistRepository watchlistRepository;
  final RotationLeadingAnalyser _analyser = RotationLeadingAnalyser();

  LeadingIndicatorPage({
    super.key,
    required this.rotations,
    required this.listedCategories,
    required this.otcCategories,
    required this.historyRepository,
    required this.watchlistRepository,
  });

  @override
  Widget build(BuildContext context) {
    final indicators = _analyser.calculateLeadingIndicators(rotations);

    final leaders = indicators.where((e) => e.netRotationScore > 0).toList();
    final laggards = indicators.where((e) => e.netRotationScore <= 0).toList();
    laggards.sort((a, b) => a.netRotationScore.compareTo(b.netRotationScore));

    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        title: const Text(
          '資金輪動領先指標雷達',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildConceptCard(),
            const SizedBox(height: 20),

            if (leaders.isNotEmpty) ...[
              _buildSectionHeader(
                '🔥 領先吸籌板塊 (資金正灌入充電)',
                Colors.green.shade800,
                Icons.bolt,
              ),
              ...leaders.map((e) => _buildIndicatorCard(context, e)),
              const SizedBox(height: 20),
            ],

            if (laggards.isNotEmpty) ...[
              _buildSectionHeader(
                '⚠️ 領先失血板塊 (資金正被當提款機)',
                Colors.red.shade800,
                Icons.money_off,
              ),
              ...laggards.map((e) => _buildIndicatorCard(context, e)),
            ],
          ],
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  CategoryUiModel? _findCategory(String name) {
    final all = [...listedCategories, ...otcCategories];
    try {
      return all.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  // LeadingSignalType → 顯示標籤和顏色
  ({String label, String emoji, Color color, Color bg}) _signalInfo(LeadingSignalType signal) {
    switch (signal) {
      case LeadingSignalType.strongAccumulation:
        return (
          label: '強力吸籌',
          emoji: '🟢',
          color: const Color(0xFF1B5E20),
          bg: const Color(0xFFE8F5E9),
        );
      case LeadingSignalType.mildInflow:
        return (
          label: '溫和流入',
          emoji: '🍏',
          color: const Color(0xFF2E7D32),
          bg: const Color(0xFFF1F8E9),
        );
      case LeadingSignalType.neutral:
        return (
          label: '中性觀望',
          emoji: '⚪',
          color: const Color(0xFF616161),
          bg: const Color(0xFFF5F5F5),
        );
      case LeadingSignalType.distributionRisk:
        return (
          label: '派發風險',
          emoji: '🟠',
          color: const Color(0xFFE65100),
          bg: const Color(0xFFFFF3E0),
        );
      case LeadingSignalType.strongDrain:
        return (
          label: '大量出逃',
          emoji: '🔴',
          color: const Color(0xFFC62828),
          bg: const Color(0xFFFFEBEE),
        );
    }
  }

  // ── widgets ────────────────────────────────────────────────────────────────

  Widget _buildConceptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff11998e), Color(0xff38ef7d)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                '什麼是輪動領先指標？',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '本雷達透過解構全市場主力搬錢軌跡，計算出產業的『輪動淨動能 (RNM)』。當某產業股價還在底部，但指標顯著大於零，代表主力正在悄悄建倉，能幫助您領先大盤提早埋伏飆股！',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(BuildContext context, LeadingIndicatorResult item) {
    final isPositive = item.netRotationScore > 0;
    final themeColor = isPositive
        ? const Color(0xff2e7d32)
        : const Color(0xffc62828);
    final category = _findCategory(item.category);
    final sigInfo = _signalInfo(item.signal);

    // vs 昨日（同步，CapitalFlow 三日記錄）
    final double? vsYesterday = category != null
        ? category.day1Score - category.day2Score
        : null;

    return GestureDetector(
      onTap: category != null
          ? () => CategoryNavigation.openCategory(context, category, historyRepository)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1：板塊名稱 + 訊號評級徽章 ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // 訊號評級徽章（取代原本的純數字）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sigInfo.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sigInfo.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${sigInfo.emoji} ${sigInfo.label}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: sigInfo.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                WatchlistButton(
                  repository: watchlistRepository,
                  categoryName: item.category,
                ),
              ],
            ),

            // ── Row 1.5：淨動能數字 + vs 昨日 ──────────────────────────────
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '淨動能 RNM: ${isPositive ? "+" : ""}${item.netRotationScore.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: themeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (vsYesterday != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: vsYesterday >= 0
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      vsYesterday >= 0
                          ? '▲ 資金流+${vsYesterday.toStringAsFixed(2)}'
                          : '▼ 資金流${vsYesterday.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: vsYesterday >= 0
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Row 2：流入/流出能量條 ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: item.totalInflowScore.round().abs() + 1,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF66BB6A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: item.totalOutflowScore.round().abs() + 1,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF9A9A),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Row 3：能量條說明（語意化描述）──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '🟢 ${item.inflowFeederCount} 個板塊輸血流入  +${item.totalInflowScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ),
                Text(
                  '🔴 流出 -${item.totalOutflowScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),

            // ── Row 4：SQLite 歷史比較（異步）─────────────────────────────
            CategoryHistorySummary(
              historyRepository: historyRepository,
              categoryName: item.category,
            ),

            const Divider(height: 24),

            // ── Row 5：操盤指南 ────────────────────────────────────────────
            Text(
              item.textGuidance,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF424242),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
