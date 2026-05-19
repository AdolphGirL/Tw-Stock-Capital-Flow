import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/models/category_ui_model.dart';

class MarketHeatmap extends StatelessWidget {
  final List<CategoryUiModel> categories;

  const MarketHeatmap({super.key, required this.categories});

  Color _color(double score) {
    if (score >= 60) {
      return Colors.deepOrange;
    }

    if (score >= 30) {
      return Colors.orange;
    }

    if (score >= 0) {
      return Colors.blueGrey;
    }

    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,

      children: categories.take(12).map((e) {
        final size = (100 + (e.totalCount * 2)).clamp(110, 180);

        return Container(
          width: size.toDouble(),

          height: size.toDouble(),

          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: _color(e.hotScore),

            borderRadius: BorderRadius.circular(22),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisAlignment: MainAxisAlignment.end,

            children: [
              Text(
                e.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                e.score.toStringAsFixed(1),

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
