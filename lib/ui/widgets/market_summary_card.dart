import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

class MarketSummaryCard extends StatelessWidget {
  final String title;

  final int riseCount;

  final int fallCount;

  final double score;

  const MarketSummaryCard({
    super.key,
    required this.title,
    required this.riseCount,
    required this.fallCount,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildInfo('上漲', riseCount, Colors.redAccent)),
                Expanded(
                  child: _buildInfo('下跌', fallCount, Colors.greenAccent),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text('資金流分數', style: TextStyle(color: Colors.grey.shade400)),

            const SizedBox(height: 6),

            AnimatedFlipCounter(
              value: score,
              fractionDigits: 2,
              textStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String title, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
