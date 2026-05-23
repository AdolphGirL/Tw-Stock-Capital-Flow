import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/core/models/market_sentiment_result.dart';

class MarketSentimentPage extends StatelessWidget {
  final MarketSentimentResult result;

  const MarketSentimentPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '市場情緒',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(28),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff134e5e), Color(0xff71b280)],
                ),

                borderRadius: BorderRadius.circular(30),
              ),

              child: Column(
                children: [
                  const Text(
                    '市場情緒狀態',

                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    result.level.name,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '情緒分數 ${result.score.toStringAsFixed(1)}',

                    style: TextStyle(color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _Metric(title: '上漲家數', value: result.riseCount.toString()),

            _Metric(title: '下跌家數', value: result.fallCount.toString()),

            _Metric(
              title: '熱錢強度',
              value: result.hotMoneyStrength.toStringAsFixed(1),
            ),

            _Metric(
              title: '主流平均強度',
              value: result.mainstreamAverage.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;

  final String value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          Text(
            value,

            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
