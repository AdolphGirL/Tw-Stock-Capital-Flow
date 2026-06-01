import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

class StrategyDashboardPage extends StatelessWidget {
  final List<LifecycleResult> lifecycles;
  final String tradeDate;
  final MomentumStrategy _strategy = MomentumStrategy();

  StrategyDashboardPage({
    super.key,
    required this.lifecycles,
    required this.tradeDate,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 1. 將所有板塊透過動量策略引擎轉換為當前訊號
    final List<StrategySignalWithSource> evaluatResult = lifecycles.map((item) {
      final signal = _strategy.evaluate(item, dateKey: tradeDate);
      return StrategySignalWithSource(signal: signal, source: item);
    }).toList();

    // 🚀 2. 將訊號分類：買進放在最前面（最重要），其次續抱，最後出清
    final buys = evaluatResult
        .where((e) => e.signal.action == StrategyAction.buy)
        .toList();
    final holds = evaluatResult
        .where((e) => e.signal.action == StrategyAction.hold)
        .toList();
    final sells = evaluatResult
        .where((e) => e.signal.action == StrategyAction.sell)
        .toList();
    final neutrals = evaluatResult
        .where((e) => e.signal.action == StrategyAction.neutral)
        .toList();

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
            // 頂部策略說明卡片
            _buildInfoCard(),
            const SizedBox(height: 20),

            // 🟢 買進/加碼區段
            if (buys.isNotEmpty) ...[
              _buildSectionTitle('🟢 機構動能突破區 (建議買進/加碼)', Colors.green.shade800),
              ...buys.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            // 🟡 續抱/警戒區段
            if (holds.isNotEmpty) ...[
              _buildSectionTitle('🟡 趨勢鎖籌續航區 (建議持股續抱)', Colors.amber.shade900),
              ...holds.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            // 🔴 減碼/出清風控區段
            if (sells.isNotEmpty) ...[
              _buildSectionTitle('🔴 資金竭盡風控區 (建議減碼/出清)', Colors.red.shade800),
              ...sells.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            // ⚪ 觀望區
            if (neutrals.isNotEmpty) ...[
              _buildSectionTitle('⚪ 資金冬眠盤整區 (建議空倉觀望)', Colors.grey.shade700),
              ...neutrals.map((e) => _buildSignalCard(context, e)),
            ],
          ],
        ),
      ),
    );
  }

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
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSignalCard(BuildContext context, StrategySignalWithSource item) {
    final signal = item.signal;
    final source = item.source;

    // 依據 Action 給予顏色
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

    return Container(
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
          // border: Border(left: BorderSide(color: indicatorColor, width: 6)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: indicatorColor, width: 6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一排：產業名稱與生命週期狀態
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    signal.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: indicatorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${source.stage.name.toUpperCase()} 階段',
                      style: TextStyle(
                        fontSize: 11,
                        color: indicatorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二排：多維度硬核數據儀表
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniMetric('強度', source.strength.toStringAsFixed(1)),
                  _buildMiniMetric(
                    '加速度',
                    (source.acceleration >= 0 ? '+' : '') +
                        source.acceleration.toStringAsFixed(1),
                  ),
                  _buildMiniMetric(
                    '延續力',
                    '${source.persistence.toStringAsFixed(0)}%',
                  ),
                  _buildMiniMetric('熱錢', source.hotMoneyIn ? '🔥流入' : '❄️無'),
                ],
              ),
              const SizedBox(height: 12),

              // 擴散度進度條 (直觀看出是不是雞犬升天)
              Row(
                children: [
                  const Text(
                    '板塊擴散度: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 第三排：交易者的操作白話指南
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
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 內部黏合資料輔助類
class StrategySignalWithSource {
  final StrategySignal signal;
  final LifecycleResult source;
  StrategySignalWithSource({required this.signal, required this.source});
}
