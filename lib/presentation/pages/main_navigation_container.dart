import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
// 引入各分流頁面
import 'package:tw_stock_capital_flow/presentation/pages/home_page.dart'; // 瘦身後的首頁
import 'package:tw_stock_capital_flow/presentation/pages/strategy_dashboard_page.dart'; // 策略看板
import 'package:tw_stock_capital_flow/presentation/pages/leading_indicator_page.dart'; // 領先指標
import 'package:tw_stock_capital_flow/presentation/pages/anomaly_detector_page.dart';

class MainNavigationContainer extends StatefulWidget {
  final String listedDate; // TWSE 上市交易日
  final String otcDate;    // TPEX 上櫃交易日
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final double listedScore;
  final int otcRiseCount;
  final int otcFallCount;
  final double otcScore;
  final List<RotationResult> listedRotations; // 上市市場獨立輪動
  final List<RotationResult> otcRotations;    // 上櫃市場獨立輪動
  final List<MainstreamResult> mainstreams;
  final List<LifecycleResult> lifecycles;
  final List<LifecycleResult> listedLifecycles; // 上市獨立週期
  final List<LifecycleResult> otcLifecycles;    // 上櫃獨立週期
  final MarketSentimentResult? sentiment;
  final CategoryHistoryRepository historyRepository;
  final WatchlistRepository watchlistRepository;
  final StorageService storageService;
  final Future<void> Function()? onRefresh;

  const MainNavigationContainer({
    super.key,
    required this.listedDate,
    required this.otcDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
    required this.listedRotations,
    required this.otcRotations,
    required this.mainstreams,
    required this.lifecycles,
    required this.listedLifecycles,
    required this.otcLifecycles,
    required this.sentiment,
    required this.historyRepository,
    required this.watchlistRepository,
    required this.storageService,
    this.onRefresh,
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
                  listedDate: widget.listedDate,
                  otcDate: widget.otcDate,
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  listedRiseCount: widget.listedRiseCount,
                  listedFallCount: widget.listedFallCount,
                  listedScore: widget.listedScore,
                  otcRiseCount: widget.otcRiseCount,
                  otcFallCount: widget.otcFallCount,
                  otcScore: widget.otcScore,
                  lifecycles: widget.lifecycles,
                  sentiment: widget.sentiment,
                  historyRepository: widget.historyRepository,
                  watchlistRepository: widget.watchlistRepository,
                  storageService: widget.storageService,
                  onRefresh: widget.onRefresh,
                ),

                // 📊 Tab 1: 異常資金偵測器
                AnomalyDetectorPage(
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  historyRepository: widget.historyRepository,
                  listedDate: widget.listedDate,
                  otcDate: widget.otcDate,
                ),

                // ⚡ Tab 2: 機構動量策略
                StrategyDashboardPage(
                  listedLifecycles: widget.listedLifecycles,
                  otcLifecycles: widget.otcLifecycles,
                  listedDate: widget.listedDate,
                  otcDate: widget.otcDate,
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  historyRepository: widget.historyRepository,
                  watchlistRepository: widget.watchlistRepository,
                ),

                // 📡 Tab 3: 輪動領先雷達
                LeadingIndicatorPage(
                  listedRotations: widget.listedRotations,
                  otcRotations: widget.otcRotations,
                  listedDate: widget.listedDate,
                  otcDate: widget.otcDate,
                  listedCategories: widget.listedCategories,
                  otcCategories: widget.otcCategories,
                  historyRepository: widget.historyRepository,
                  watchlistRepository: widget.watchlistRepository,
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
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: '異常偵測'),
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

}
