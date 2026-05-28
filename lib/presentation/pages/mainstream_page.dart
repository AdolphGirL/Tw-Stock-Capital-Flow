import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';

import 'package:tw_stock_capital_flow/presentation/widgets/mainstream_card.dart';

class MainstreamPage extends StatelessWidget {
  final List<MainstreamResult> mainstreams;

  const MainstreamPage({super.key, required this.mainstreams});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '市場主流',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: mainstreams.length,

        itemBuilder: (_, index) {
          final item = mainstreams[index];

          return MainstreamCard(rank: index + 1, result: item);
        },
      ),
    );
  }
}
