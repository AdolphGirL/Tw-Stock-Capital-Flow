import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

/// 今日全市場訊號快照：一眼掌握 BUY/HOLD/SELL 分佈 + 點火板塊 + 風險警示
class MarketSignalSummary extends StatelessWidget {
  final List<LifecycleResult> lifecycles;
  final String tradeDate;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final CategoryHistoryRepository historyRepository;

  const MarketSignalSummary({
    super.key,
    required this.lifecycles,
    required this.tradeDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.historyRepository,
  });

  // ── 資料計算 ──────────────────────────────────────────────────────────────

  List<StrategySignal> _computeSignals() {
    final strategy = MomentumStrategy();
    return lifecycles
        .map((lc) => strategy.evaluate(lc, dateKey: tradeDate))
        .toList();
  }

  CategoryUiModel? _findCategory(String name) {
    final all = [...listedCategories, ...otcCategories];
    try {
      return all.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  // ── 主建構 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final signals = _computeSignals();

    final buyList = signals
        .where((s) => s.action == StrategyAction.buy)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final holdList = signals.where((s) => s.action == StrategyAction.hold).toList();
    final sellList = signals
        .where((s) => s.action == StrategyAction.sell)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final neutralList = signals.where((s) => s.action == StrategyAction.neutral).toList();

    // 點火期（無論最終訊號，只要 stage == ignition 都特別標出）
    final ignitionList = lifecycles
        .where((lc) => lc.stage == LifecycleStage.ignition)
        .toList()
      ..sort((a, b) => b.strength.compareTo(a.strength));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 標題列 ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.traffic_rounded, size: 18, color: Color(0xFF37474F)),
              const SizedBox(width: 6),
              const Text(
                '今日訊號快照',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '共 ${signals.length} 個板塊',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),

        // ── 1. 訊號分佈計數器 ─────────────────────────────────────────────
        _buildDistributionRow(
          buyList.length,
          holdList.length,
          sellList.length,
          neutralList.length,
        ),
        const SizedBox(height: 14),

        // ── 2. 點火期板塊（最高優先關注） ────────────────────────────────
        if (ignitionList.isNotEmpty) ...[
          _buildSectionLabel('🔥 點火期板塊（早鳥機會）', const Color(0xFFE65100)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ignitionList
                .take(6)
                .map((lc) => _buildCategoryChip(
                      context,
                      lc.category,
                      const Color(0xFFE65100),
                      const Color(0xFFFFF3E0),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // ── 3. 買進訊號（前 4 名） ────────────────────────────────────────
        if (buyList.isNotEmpty) ...[
          _buildSectionLabel('🟢 今日買進訊號', const Color(0xFF1B5E20)),
          const SizedBox(height: 6),
          ...buyList.take(4).map((s) => _buildSignalTile(
                context,
                s,
                const Color(0xFF2E7D32),
                const Color(0xFFE8F5E9),
              )),
          const SizedBox(height: 12),
        ],

        // ── 4. 出清警示（前 4 名） ────────────────────────────────────────
        if (sellList.isNotEmpty) ...[
          _buildSectionLabel('🔴 風控警示板塊', const Color(0xFFC62828)),
          const SizedBox(height: 6),
          ...sellList.take(4).map((s) => _buildSignalTile(
                context,
                s,
                const Color(0xFFC62828),
                const Color(0xFFFFEBEE),
              )),
        ],
      ],
    );
  }

  // ── 子 Widget ─────────────────────────────────────────────────────────────

  Widget _buildDistributionRow(int buy, int hold, int sell, int neutral) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCountBadge('買進', buy, const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
          _buildDivider(),
          _buildCountBadge('續抱', hold, const Color(0xFFF9A825), const Color(0xFFFFF9C4)),
          _buildDivider(),
          _buildCountBadge('出清', sell, const Color(0xFFC62828), const Color(0xFFFFEBEE)),
          _buildDivider(),
          _buildCountBadge('觀望', neutral, const Color(0xFF616161), const Color(0xFFF5F5F5)),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color textColor, Color bgColor) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFFEEEEEE));
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  /// 可點擊的板塊名稱 Chip（點火列表用）
  Widget _buildCategoryChip(
    BuildContext context,
    String categoryName,
    Color textColor,
    Color bgColor,
  ) {
    final cat = _findCategory(categoryName);
    return GestureDetector(
      onTap: cat != null
          ? () => CategoryNavigation.openCategory(context, cat, historyRepository)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (cat != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 13, color: textColor),
            ],
          ],
        ),
      ),
    );
  }

  /// 訊號卡片 tile（買進/出清列表用）
  Widget _buildSignalTile(
    BuildContext context,
    StrategySignal signal,
    Color accentColor,
    Color bgColor,
  ) {
    final cat = _findCategory(signal.category);
    // 裁剪 reason：去掉開頭的 emoji 標籤行，保留核心說明文字
    final shortReason = _trimReason(signal.reason);

    return GestureDetector(
      onTap: cat != null
          ? () => CategoryNavigation.openCategory(context, cat, historyRepository)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signal.category,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortReason,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF555555),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '強度 ${signal.score.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (cat != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.arrow_forward_ios, size: 10, color: accentColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // reason 字串第一個【...】之後的文字作為摘要
  String _trimReason(String reason) {
    final match = RegExp(r'】(.+)').firstMatch(reason);
    if (match != null) return match.group(1)!.trim();
    return reason.replaceAll(RegExp(r'^[🟢🔴🟡⚪🟠]+'), '').trim();
  }
}
