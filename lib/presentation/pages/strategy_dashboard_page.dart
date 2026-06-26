import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_history_summary.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/watchlist_button.dart';

class StrategyDashboardPage extends StatelessWidget {
  final List<LifecycleResult> lifecycles;
  final String tradeDate;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final CategoryHistoryRepository historyRepository;
  final WatchlistRepository watchlistRepository;
  final MomentumStrategy _strategy = MomentumStrategy();

  StrategyDashboardPage({
    super.key,
    required this.lifecycles,
    required this.tradeDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.historyRepository,
    required this.watchlistRepository,
  });

  @override
  Widget build(BuildContext context) {
    final List<StrategySignalWithSource> evaluated = lifecycles.map((item) {
      final signal = _strategy.evaluate(item, dateKey: tradeDate);
      return StrategySignalWithSource(signal: signal, source: item);
    }).toList();

    final buys = evaluated.where((e) => e.signal.action == StrategyAction.buy).toList();
    final holds = evaluated.where((e) => e.signal.action == StrategyAction.hold).toList();
    final sells = evaluated.where((e) => e.signal.action == StrategyAction.sell).toList();
    final neutrals = evaluated.where((e) => e.signal.action == StrategyAction.neutral).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        title: const Text(
          '板塊動量續航決策系統',
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
            _buildInfoCard(),
            const SizedBox(height: 20),

            if (buys.isNotEmpty) ...[
              _buildSectionTitle('🟢 機構動能突破區 (建議買進/加碼)', Colors.green.shade800),
              ...buys.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            if (holds.isNotEmpty) ...[
              _buildSectionTitle('🟡 趨勢鎖籌續航區 (建議持股續抱)', Colors.amber.shade900),
              ...holds.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            if (sells.isNotEmpty) ...[
              _buildSectionTitle('🔴 資金竭盡風控區 (建議減碼/出清)', Colors.red.shade800),
              ...sells.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            if (neutrals.isNotEmpty) ...[
              _buildSectionTitle('⚪ 資金冬眠盤整區 (建議空倉觀望)', Colors.grey.shade700),
              ...neutrals.map((e) => _buildSignalCard(context, e)),
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

  bool _hasDivergence(String categoryName) {
    final cat = _findCategory(categoryName);
    return cat != null && cat.trendStrength > 20;
  }

  String _stageLabel(LifecycleStage stage) {
    switch (stage) {
      case LifecycleStage.ignition: return '點火期';
      case LifecycleStage.expansion: return '擴散期';
      case LifecycleStage.markup: return '主升期';
      case LifecycleStage.euphoric: return '狂熱期';
      case LifecycleStage.distribution: return '出貨期';
      case LifecycleStage.decline: return '退潮期';
      case LifecycleStage.dead: return '死亡期';
      case LifecycleStage.consolidation: return '盤整期';
    }
  }

  // 加速度 → 方向文字與顏色
  ({String label, Color color}) _accelInfo(double accel) {
    if (accel > 5) return (label: '↑↑ 急速拉升', color: const Color(0xFF1B5E20));
    if (accel > 1) return (label: '↑ 動能上升', color: const Color(0xFF2E7D32));
    if (accel > -1) return (label: '→ 橫盤震盪', color: const Color(0xFF757575));
    if (accel > -5) return (label: '↓ 動能下滑', color: const Color(0xFFE65100));
    return (label: '↓↓ 急速崩跌', color: const Color(0xFFC62828));
  }

  // 延續力 → 文字描述與顏色
  ({String label, Color color}) _persistInfo(double persist) {
    if (persist > 5) return (label: '主力鎖籌', color: const Color(0xFF1B5E20));
    if (persist > 1) return (label: '穩定持有', color: const Color(0xFF2E7D32));
    if (persist > -1) return (label: '盤整震盪', color: const Color(0xFF757575));
    if (persist > -5) return (label: '動能衰退', color: const Color(0xFFE65100));
    return (label: '拋壓嚴重', color: const Color(0xFFC62828));
  }

  // 擴散度 → 文字描述
  String _diffusionLabel(double diff) {
    if (diff >= 70) return '雞犬升天';
    if (diff >= 50) return '多股共振';
    if (diff >= 40) return '溫和擴散';
    return '少數個股';
  }

  // ── widgets ────────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '七期動量續航策略指南',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '系統依據熱錢實質流入(HotMoney)、板塊擴散共振度(Diffusion)、主力買盤延續力(Persistence)與7大生命週期，自動將台股板塊歸類，協助您進行汰弱留強。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildSignalCard(BuildContext context, StrategySignalWithSource item) {
    final signal = item.signal;
    final source = item.source;

    Color indicatorColor = Colors.grey;
    IconData actionIcon = Icons.remove_circle_outline;
    if (signal.action == StrategyAction.buy) {
      indicatorColor = const Color(0xff2e7d32);
      actionIcon = Icons.add_shopping_cart;
    } else if (signal.action == StrategyAction.hold) {
      indicatorColor = const Color(0xffef6c00);
      actionIcon = Icons.pan_tool;
    } else if (signal.action == StrategyAction.sell) {
      indicatorColor = const Color(0xffc62828);
      actionIcon = Icons.warning_amber_rounded;
    }

    final isSell = signal.action == StrategyAction.sell;
    final showDivergence = isSell && _hasDivergence(signal.category);
    final category = _findCategory(signal.category);

    // vs 昨日（來自 CapitalFlowAnalyzer 的三日記錄，不需異步）
    final double? vsYesterday = category != null
        ? category.day1Score - category.day2Score
        : null;
    final bool trend3Up = category?.isStrengthening ?? false;
    final bool trend3Down = category?.isWeakening ?? false;

    final accel = _accelInfo(source.acceleration);
    final persist = _persistInfo(source.persistence);
    final diffLabel = _diffusionLabel(source.diffusion);

    return GestureDetector(
      onTap: category != null
          ? () => CategoryNavigation.openCategory(context, category, historyRepository)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: indicatorColor, width: 6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1：板塊名稱 + 生命週期標籤 + 收藏 ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        signal.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: indicatorColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _stageLabel(source.stage),
                        style: TextStyle(
                          fontSize: 11,
                          color: indicatorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    WatchlistButton(
                      repository: watchlistRepository,
                      categoryName: signal.category,
                    ),
                  ],
                ),

                // ── Row 2：vs 昨日 + 3日趨勢（同步資料，即時顯示）─────────
                if (vsYesterday != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _inlineChip(
                        vsYesterday >= 0
                            ? '▲ 較昨日 +${vsYesterday.toStringAsFixed(2)}'
                            : '▼ 較昨日 ${vsYesterday.toStringAsFixed(2)}',
                        vsYesterday >= 0
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFC62828),
                        vsYesterday >= 0
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                      ),
                      if (trend3Up)
                        _inlineChip('連3日走強 ↑', const Color(0xFF1B5E20), const Color(0xFFE8F5E9)),
                      if (trend3Down)
                        _inlineChip('連3日走弱 ↓', const Color(0xFFC62828), const Color(0xFFFFEBEE)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // ── Row 3：四個語意化指標徽章 ───────────────────────────────
                Row(
                  children: [
                    Expanded(child: _buildMetricChip(
                      '動能強度',
                      source.strength.toStringAsFixed(1),
                      Colors.blueGrey.shade700,
                      Colors.blueGrey.shade50,
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMetricChip(
                      '趨勢動能',
                      accel.label,
                      accel.color,
                      accel.color.withValues(alpha: 0.06),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMetricChip(
                      '延續力',
                      persist.label,
                      persist.color,
                      persist.color.withValues(alpha: 0.06),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMetricChip(
                      '熱錢',
                      source.hotMoneyIn ? '🔥 流入' : '❄️ 未見',
                      source.hotMoneyIn
                          ? const Color(0xFFE65100)
                          : const Color(0xFF546E7A),
                      source.hotMoneyIn
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFECEFF1),
                    )),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Row 4：擴散度進度條 + 語意標籤 ────────────────────────
                Row(
                  children: [
                    Text(
                      '擴散度',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: source.diffusion / 100.0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            indicatorColor.withValues(alpha: 0.7),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${source.diffusion.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      diffLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: indicatorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // ── Row 5：SQLite 歷史比較（異步載入，不影響卡片主渲染）───
                CategoryHistorySummary(
                  historyRepository: historyRepository,
                  categoryName: signal.category,
                ),

                const Divider(height: 20),

                // ── Row 6：資金背離警告（SELL 卡片專屬）───────────────────
                if (showDivergence) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFD600), width: 1),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_rounded, size: 15, color: Color(0xFF856404)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '⚠️ 資金背離警告：資金熱區仍顯示此板塊有資金流入，但動量結構已惡化。此現象常見於「主力出貨、散戶追進」的危險格局，請特別留意。',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF856404),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Row 7：操盤白話指南 ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(actionIcon, size: 16, color: indicatorColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        signal.reason,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 語意化指標徽章
  Widget _buildMetricChip(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 小型行內標籤
  Widget _inlineChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StrategySignalWithSource {
  final StrategySignal signal;
  final LifecycleResult source;
  StrategySignalWithSource({required this.signal, required this.source});
}
