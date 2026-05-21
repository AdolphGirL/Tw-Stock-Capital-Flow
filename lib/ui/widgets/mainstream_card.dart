import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/core/models/mainstream_result.dart';

class MainstreamCard extends StatelessWidget {
  final int rank;

  final MainstreamResult result;

  const MainstreamCard({super.key, required this.rank, required this.result});

  Color get trendColor {
    if (result.mainstreamScore >= 80) {
      return Colors.deepOrange;
    }

    if (result.mainstreamScore >= 60) {
      return Colors.orange;
    }

    if (result.mainstreamScore >= 40) {
      return Colors.amber;
    }

    return Colors.blueGrey;
  }

  String get status {
    if (result.strengthening) {
      return '資金增強';
    }

    if (result.weakening) {
      return '資金退潮';
    }

    return '整理';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.12),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Text(
                  '$rank',

                  style: TextStyle(
                    color: trendColor,

                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      result.category,

                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(status, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.12),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Column(
                  children: [
                    Text(
                      result.mainstreamScore.toStringAsFixed(1),

                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '主流分數',

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: '資金流',
                  value: result.flowScore,
                  icon: Icons.water_drop,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _MetricCard(
                  title: '持續性',
                  value: result.persistenceScore,
                  icon: Icons.timeline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: '擴散度',
                  value: result.diffusionScore,
                  icon: Icons.hub,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _MetricCard(
                  title: '領頭羊',
                  value: result.leaderScore,
                  icon: Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;

  final double value;

  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xfff7f9fc),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Icon(icon, color: Colors.blueGrey),

          const SizedBox(height: 10),

          Text(
            value.toStringAsFixed(1),

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            title,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
