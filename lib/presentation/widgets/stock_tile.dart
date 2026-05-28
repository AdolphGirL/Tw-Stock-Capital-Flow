import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class StockTile extends StatelessWidget {
  final StockData stock;

  final double score;

  const StockTile({super.key, required this.stock, required this.score});

  Future<void> _openYahooPage() async {
    try {
      final suffix = stock.market == MarketType.listed ? 'TW' : 'TWO';

      final uri = Uri.parse(
        'https://tw.stock.yahoo.com/quote/${stock.code}.$suffix/technical-analysis',
      );

      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        return;
      }

      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: _openYahooPage,

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

        trailing: Text(
          score.toStringAsFixed(2),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
