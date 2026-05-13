import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'score_chip.dart';

class StockTile extends StatelessWidget {
  final StockData stock;

  final double score;

  const StockTile({super.key, required this.stock, required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () async {
          final uri = Uri.parse(
            'https://tw.stock.yahoo.com/quote/${stock.code}.TW/technical-analysis',
          );

          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },

        title: Text('${stock.code} ${stock.name}'),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            children: [
              Text(
                '${stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: stock.changePercent >= 0
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
              ),

              Text('成交額 ${(stock.value / 100000000).toStringAsFixed(2)}億'),
            ],
          ),
        ),

        trailing: ScoreChip(score: score),
      ),
    );
  }
}
