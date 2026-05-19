import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'trend_sparkline.dart';
import 'hot_badge.dart';

class CategoryCard extends StatelessWidget {
  final String title;

  final int totalCount;

  final int riseCount;

  final int fallCount;

  final double score;

  final VoidCallback onTap;

  final List<double> trendValues;

  final double persistence;

  const CategoryCard({
    super.key,
    required this.title,
    required this.totalCount,
    required this.riseCount,
    required this.fallCount,
    required this.score,
    required this.onTap,
    required this.trendValues,
    required this.persistence,
  });

  @override
  Widget build(BuildContext context) {
    final positive = score >= 0;

    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(28),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                gradient: LinearGradient(
                  colors: positive
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                      : [const Color(0xFF00C9A7), const Color(0xFF00B894)],
                ),
              ),

              child: const Icon(Icons.candlestick_chart, color: Colors.white),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 10,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      HotBadge(score: score),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '持續性 ${persistence.toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                TrendSparkline(values: trendValues),
                const SizedBox(height: 10),
                Text(
                  score.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,

                    color: positive ? Colors.redAccent : Colors.green,
                  ),
                ),

                const SizedBox(height: 6),

                Text('三日資金流', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12, end: 0);
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),

        borderRadius: BorderRadius.circular(999),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),

          const SizedBox(width: 4),

          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
