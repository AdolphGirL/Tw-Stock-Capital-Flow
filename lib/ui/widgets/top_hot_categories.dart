import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';

class TopHotCategories extends StatelessWidget {
  final List<CategoryUiModel> categories;

  const TopHotCategories({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final top = [...categories];

    top.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    final top5 = top.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          '今日主流類股',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 18),

        ...top5.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 14),

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
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
                        e.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '資金流 ${e.score.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,

                    borderRadius: BorderRadius.circular(999),
                  ),

                  child: Text(
                    e.trendStrength.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
