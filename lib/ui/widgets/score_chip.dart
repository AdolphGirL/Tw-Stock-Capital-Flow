import 'package:flutter/material.dart';

class ScoreChip extends StatelessWidget {
  final double score;

  const ScoreChip({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final positive = score >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // 修正處：將 .withOpacity(0.12) 改為 .withValues(alpha: 0.12)
        color: positive
            ? Colors.red.withValues(alpha: 0.12)
            : Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        score.toStringAsFixed(2),
        style: TextStyle(
          color: positive ? Colors.redAccent : Colors.greenAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
