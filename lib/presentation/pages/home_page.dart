import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';

import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

import 'package:tw_stock_capital_flow/presentation/widgets/home_section_card.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_summary_card.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/top_hot_categories.dart';

import 'package:tw_stock_capital_flow/presentation/pages/mainstream_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/lifecycle_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/main_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/market_sentiment_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/rotation_page.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_heatmap.dart';

// 🚀 引入資料庫與 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class HomePage extends StatelessWidget {
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final double listedScore;
  final int otcRiseCount;
  final int otcFallCount;
  final double otcScore;
  final List<RotationResult> rotations;
  final List<MainstreamResult> mainstreams;
  final List<LifecycleResult> lifecycles;
  final MarketSentimentResult? sentiment;

  // 🚀 注入歷史資料庫接口
  final CategoryHistoryRepository historyRepository;

  const HomePage({
    super.key,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
    required this.rotations,
    required this.mainstreams,
    required this.lifecycles,
    required this.sentiment,
    required this.historyRepository, // ⚡ 納入必要參數
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildMarketSection(context),
            const SizedBox(height: 32),
            _buildHeatMap(), // ⚡ 呼叫封裝方法
            const SizedBox(height: 32),
            _buildMainstreamSection(context),
            const SizedBox(height: 24),
            _buildLifecycleSection(context),
            const SizedBox(height: 24),
            _buildSentimentSection(context),
            const SizedBox(height: 24),
            _buildRotationSection(context),
            const SizedBox(height: 32),

            // 🔥 精確檢查點：此處必須完整帶上具名參數標籤 `categories:`
            // 🔥 修正後：補上對應的 historyRepository 具名參數
            TopHotCategories(
              categories: [...listedCategories, ...otcCategories],
              historyRepository: historyRepository, // 👈 補上這一行
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '台股資金流',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '市場主流・資金輪動・情緒週期',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMarketSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainCategoryPage(
                  title: '上市市場板塊',
                  categories: listedCategories,
                  historyRepository: historyRepository,
                ),
              ),
            );
          },
          child: MarketSummaryCard(
            title: '上市市場',
            riseCount: listedRiseCount,
            fallCount: listedFallCount,
            score: listedScore,
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainCategoryPage(
                  title: '上櫃市場板塊',
                  categories: otcCategories,
                  historyRepository: historyRepository,
                ),
              ),
            );
          },
          child: MarketSummaryCard(
            title: '上櫃市場',
            riseCount: otcRiseCount,
            fallCount: otcFallCount,
            score: otcScore,
          ),
        ),
      ],
    );
  }

  // 🔥 精確檢查點：確保返回的是標準實例化的 Widget，且參數都有加上具名標籤
  Widget _buildHeatMap() {
    return MarketHeatmap(
      categories: [...listedCategories, ...otcCategories], // 👈 必須有標籤
      historyRepository: historyRepository, // 👈 必須有標籤
    );
  }

  Widget _buildMainstreamSection(BuildContext context) {
    final top = mainstreams.isEmpty ? null : mainstreams.first;

    return HomeSectionCard(
      title: '市場主流',
      subtitle: top == null ? '-' : top.category,
      description: '追蹤市場最強主流方向',
      gradient: const [Color(0xff1e3c72), Color(0xff2a5298)],
      icon: Icons.auto_graph,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainstreamPage(mainstreams: mainstreams),
          ),
        );
      },
    );
  }

  Widget _buildLifecycleSection(BuildContext context) {
    final top = lifecycles.isEmpty ? null : lifecycles.first;

    return HomeSectionCard(
      title: '主流生命週期',
      subtitle: top == null ? '-' : top.category,
      description: top == null ? '-' : top.stage.name,
      gradient: const [Color(0xff614385), Color(0xff516395)],
      icon: Icons.timeline,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LifecyclePage(lifecycles: lifecycles),
          ),
        );
      },
    );
  }

  Widget _buildSentimentSection(BuildContext context) {
    return HomeSectionCard(
      title: '市場情緒',
      subtitle: sentiment == null ? '-' : sentiment!.level.name,
      description: sentiment == null
          ? '-'
          : '熱錢強度 ${sentiment!.hotMoneyStrength.toStringAsFixed(1)}',
      gradient: const [Color(0xff134e5e), Color(0xff71b280)],
      icon: Icons.psychology,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketSentimentPage(result: sentiment!),
          ),
        );
      },
    );
  }

  Widget _buildRotationSection(BuildContext context) {
    final top = rotations.isEmpty ? null : rotations.first;

    return HomeSectionCard(
      title: '資金輪動',
      subtitle: top == null ? '-' : top.toCategory,
      description: top == null ? '-' : '輪動分數 ${top.score.toStringAsFixed(1)}',
      gradient: const [Color(0xff42275a), Color(0xff734b6d)],
      icon: Icons.sync_alt,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RotationPage(rotations: rotations)),
        );
      },
    );
  }
}
