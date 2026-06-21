import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

// 引入各分流頁面
import 'package:tw_stock_capital_flow/presentation/pages/home_page.dart'; // 瘦身後的首頁
import 'package:tw_stock_capital_flow/presentation/pages/strategy_dashboard_page.dart'; // 策略看板
import 'package:tw_stock_capital_flow/presentation/pages/leading_indicator_page.dart'; // 領先指標
import 'package:tw_stock_capital_flow/presentation/widgets/market_heatmap.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/top_hot_categories.dart';

class MainNavigationContainer extends StatefulWidget {
  final String tradeDate;
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
  final CategoryHistoryRepository historyRepository;

  const MainNavigationContainer({
    super.key,
    required this.tradeDate,
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
    required this.historyRepository,
  });

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 🚀 使用 IndexedStack 的巨大好處：切換 Tab 時，頁面狀態不銷毀、不重繪、捲動位置不遺失
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // 🏠 Tab 0: 大盤診斷
                HomePage(
                  tradeDate: widget.tradeDate,
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  listedRiseCount: widget.listedRiseCount,
                  listedFallCount: widget.listedFallCount,
                  listedScore: widget.listedScore,
                  otcRiseCount: widget.otcRiseCount,
                  otcFallCount: widget.otcFallCount,
                  otcScore: widget.otcScore,
                  rotations: widget.rotations,
                  mainstreams: widget.mainstreams,
                  lifecycles: widget.lifecycles,
                  sentiment: widget.sentiment,
                  historyRepository: widget.historyRepository,
                ),

                // 📊 Tab 1: 資金熱圖中心
                _buildHeatmapTabScreen(),

                // ⚡ Tab 2: 機構動量策略
                StrategyDashboardPage(
                  lifecycles: widget.lifecycles,
                  tradeDate: widget.tradeDate,
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  historyRepository: widget.historyRepository,
                ),

                // 📡 Tab 3: 輪動領先雷達
                LeadingIndicatorPage(
                  rotations: widget.rotations,
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  historyRepository: widget.historyRepository,
                ),
              ],
            ),
          ),
          _buildDisclaimerBar(),
        ],
      ),

      // 📱 現代看盤風格的底部導航欄
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: '大盤診斷',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: '資金熱區'),
          BottomNavigationBarItem(
            icon: Icon(Icons.traffic_rounded),
            label: '動量決策',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar_rounded),
            label: '領先雷達',
          ),
        ],
      ),
    );
  }

  /// 全 Tab 共用的底部法律聲明欄（永遠顯示於 BottomNavigationBar 上方）
  Widget _buildDisclaimerBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Text(
        '數據來源：台灣證券交易所、證券櫃檯買賣中心。本 App 計算結果僅供參考，不構成任何投資建議。',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade400,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 建立獨立的熱圖與九宮格主畫面
  Widget _buildHeatmapTabScreen() {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        title: const Text(
          '全市場資金熱區雷達',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            MarketHeatmap(
              categories: [...widget.listedCategories, ...widget.otcCategories],
              historyRepository: widget.historyRepository,
            ),
            const SizedBox(height: 32),
            TopHotCategories(
              categories: [...widget.listedCategories, ...widget.otcCategories],
              historyRepository: widget.historyRepository,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
