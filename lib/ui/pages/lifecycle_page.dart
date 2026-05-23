import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/core/models/lifecycle_result.dart';

import 'package:tw_stock_capital_flow/ui/widgets/lifecycle_card.dart';

class LifecyclePage extends StatelessWidget {
  final List<LifecycleResult> lifecycles;

  const LifecyclePage({super.key, required this.lifecycles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '主流生命週期',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: lifecycles.length,

        itemBuilder: (_, index) {
          final item = lifecycles[index];

          return LifecycleCard(result: item);
        },
      ),
    );
  }
}
