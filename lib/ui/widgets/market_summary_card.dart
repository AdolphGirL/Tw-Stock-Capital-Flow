import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

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
    final positive = score >= 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: positive
              ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),

        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),

          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),

                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: _buildMarketInfo(
                        '上漲',

                        riseCount.toString(),

                        Colors.redAccent,
                      ),
                    ),

                    Expanded(
                      child: _buildMarketInfo(
                        '下跌',

                        fallCount.toString(),

                        Colors.greenAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  '資金流強度',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 8),

                AnimatedFlipCounter(
                  value: score,

                  fractionDigits: 2,

                  textStyle: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketInfo(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),

        const SizedBox(height: 8),

        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
