import 'package:flutter/material.dart';

import 'score_chip.dart';

class CategoryCard extends StatelessWidget {
  final String title;

  final int totalCount;

  final int riseCount;

  final int fallCount;

  final double score;

  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.totalCount,
    required this.riseCount,
    required this.fallCount,
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      children: [
                        Text('總數 $totalCount'),

                        Text(
                          '▲ $riseCount',
                          style: const TextStyle(color: Colors.redAccent),
                        ),

                        Text(
                          '▼ $fallCount',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              ScoreChip(score: score),
            ],
          ),
        ),
      ),
    );
  }
}
