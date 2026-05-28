import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';

class RotationFlowCard extends StatelessWidget {
  final RotationResult result;

  const RotationFlowCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  result.fromCategory,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.arrow_forward, color: Colors.orange),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        result.toCategory,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              color: Colors.orange.shade50,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                Text(
                  result.inflowStrength.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '輪動強度',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
