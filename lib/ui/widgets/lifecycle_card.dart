import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/core/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/core/models/lifecycle_result.dart';

class LifecycleCard extends StatelessWidget {
  final LifecycleResult result;

  const LifecycleCard({super.key, required this.result});

  String get stageName {
    switch (result.stage) {
      case LifecycleStage.ignition:
        return '點火';

      case LifecycleStage.expansion:
        return '擴散';

      case LifecycleStage.markup:
        return '主升';

      case LifecycleStage.euphoric:
        return '市場狂熱';

      case LifecycleStage.distribution:
        return '高檔出貨';

      case LifecycleStage.decline:
        return '退潮';

      case LifecycleStage.dead:
        return '死亡';
    }
  }

  Color get color {
    switch (result.stage) {
      case LifecycleStage.ignition:
        return Colors.blue;

      case LifecycleStage.expansion:
        return Colors.teal;

      case LifecycleStage.markup:
        return Colors.orange;

      case LifecycleStage.euphoric:
        return Colors.red;

      case LifecycleStage.distribution:
        return Colors.purple;

      case LifecycleStage.decline:
        return Colors.grey;

      case LifecycleStage.dead:
        return Colors.black87;
    }
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
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.category,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Text(
                  stageName,

                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LinearProgressIndicator(
            value: result.strength / 100,

            borderRadius: BorderRadius.circular(999),

            minHeight: 12,

            backgroundColor: Colors.grey.shade200,

            valueColor: AlwaysStoppedAnimation(color),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _Metric(title: '加速度', value: result.acceleration),
              ),

              Expanded(
                child: _Metric(title: '持續性', value: result.persistence),
              ),

              Expanded(
                child: _Metric(title: '擴散', value: result.diffusion),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;

  final double value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),

          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        Text(title, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
