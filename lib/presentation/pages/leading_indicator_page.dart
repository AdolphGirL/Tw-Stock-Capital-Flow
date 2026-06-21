import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/models/leading_indicator_result.dart';
import 'package:tw_stock_capital_flow/domain/analysers/rotation_leading_analyser.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

class LeadingIndicatorPage extends StatelessWidget {
  final List<RotationResult> rotations;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final CategoryHistoryRepository historyRepository;
  final RotationLeadingAnalyser _analyser = RotationLeadingAnalyser();

  LeadingIndicatorPage({
    super.key,
    required this.rotations,
    required this.listedCategories,
    required this.otcCategories,
    required this.historyRepository,
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
          Row(
            children: [
              const Icon(Icons.radar, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70, // ← 修改重點
              height: 1.4,
            ),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  CategoryUiModel? _findCategory(String name) {
    final all = [...listedCategories, ...otcCategories];
    try {
      return all.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  Widget _buildIndicatorCard(BuildContext context, LeadingIndicatorResult item) {
    final isPositive = item.netRotationScore > 0;
    final themeColor = isPositive
        ? const Color(0xff2e7d32)
        : const Color(0xffc62828);
    final category = _findCategory(item.category);

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
        boxShadow: [
          BoxShadow(
            color: const Color(0x03000000), // Colors.black.withOpacity(0.02)
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                item.category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C), // black87
                ),
              ),
              Text(
                '淨動能: ${isPositive ? "+" : ""}${item.netRotationScore.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 能量條
          Row(
            children: [
              Expanded(
                flex: item.totalInflowScore.round().abs() + 1,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A), // green.shade400
                    borderRadius: const BorderRadius.only(
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF9A9A), // red.shade300
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 能量條下方文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '流入總分: +${item.totalInflowScore.toStringAsFixed(0)} (源自 ${item.inflowFeederCount} 個產業)',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575), // grey.shade600
                ),
              ),
              Text(
                '流出總分: -${item.totalOutflowScore.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575), // grey.shade600
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // 操盤指南
          Text(
            item.textGuidance,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF424242), // grey.shade800
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
