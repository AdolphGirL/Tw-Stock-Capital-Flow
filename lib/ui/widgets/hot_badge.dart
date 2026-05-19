import 'package:flutter/material.dart';

class HotBadge extends StatelessWidget {
  final double score;

  const HotBadge({super.key, required this.score});

  String get label {
    if (score >= 80) {
      return '爆發';
    }

    if (score >= 50) {
      return '強勢';
    }

    if (score >= 20) {
      return '偏強';
    }

    if (score >= 0) {
      return '整理';
    }

    return '退潮';
  }

  Color get color {
    if (score >= 80) {
      return Colors.deepOrange;
    }

    if (score >= 50) {
      return Colors.orange;
    }

    if (score >= 20) {
      return Colors.amber;
    }

    if (score >= 0) {
      return Colors.blueGrey;
    }

    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(0.12),

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
