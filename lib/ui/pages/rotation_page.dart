import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/models/rotation_result.dart';

class RotationPage extends StatelessWidget {
  final List<RotationResult> rotations;

  const RotationPage({super.key, required this.rotations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '資金輪動',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: rotations.length,

        itemBuilder: (_, index) {
          final item = rotations[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),

            padding: const EdgeInsets.all(22),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item.toCategory,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _RotationMetric(
                        title: '輪動分數',

                        value: item.score.toStringAsFixed(1),
                      ),
                    ),

                    Expanded(
                      child: _RotationMetric(
                        title: '流入強度',

                        value: item.inflowStrength.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RotationMetric extends StatelessWidget {
  final String title;

  final String value;

  const _RotationMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,

          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(title, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
