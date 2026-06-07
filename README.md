# Tw-Stock-Capital-Flow 專案核心分析報告 (2026/06/06)

本報告針對 `@lib` 目錄下的所有代碼進行深度解析，包含功能用途、核心演算法推導、優化建議以及程式碼清理建議。

---

## 1. 專案功能與實務用途分析

本專案是一個專門針對台灣股市（上市、上櫃）設計的**資金流向監控與決策系統**。其核心目標是透過數據分析，辨識市場當前的「主流板塊」、資金的「輪動路徑」以及各產業的「生命週期位置」。

### 分層架構與功能描述：

#### A. Core 層 (基礎設施)
- **實務用途**：提供全域常數、日期處理工具、市場類型轉換擴充，以及導航封裝。
- **關鍵功能**：
    - `CategoryNavigation`: 統一處理板塊進入、個股清單彈窗與外部連結（Yahoo 股市）跳轉。
    - `ListExtension`: 提供列表平均值計算。

#### B. Data 層 (數據存取與同步)
- **實務用途**：負責從開放 API (TWSE/TPEX) 抓取資料，進行格式轉換、本地化儲存 (Drift/SQLite) 以及快取管理。
- **關鍵功能**：
    - `StockService`: 串接開放 API，並透過 `stock_mapping.txt` 進行產業分類對應。
    - `SyncManager`: 協調數據同步流程，包含日期檢查與本地快照儲存。
    - `AnalysisCacheService`: 對複雜的計算結果進行 JSON 快取，提升開屏載入速度。
    - `AppDatabase`: 基於 Drift 的持久化層，記錄產業歷史分數。

#### C. Domain 層 (核心邏輯引擎)
- **實務用途**：本專案的大腦，將原始股票數據轉化為具備交易價值的指標。
- **關鍵功能**：
    - **多維度引擎**：包含資金流、主流板塊、生命週期、輪動路徑、市場情緒五大引擎。
    - **策略評估**：透過 `MomentumStrategy` 提供買進、續抱、賣出的量化建議。
    - **領先指標**：利用輪動路徑預測尚未噴出的潛力板塊。

#### D. Presentation 層 (UI 呈現)
- **實務用途**：提供數據視覺化介面，包含熱圖、折線圖、圓餅圖與策略看板。
- **關鍵功能**：
    - `MainNavigationContainer`: 核心導航外殼，使用 `IndexedStack` 維持狀態。
    - `CustomPainter`: 大量自繪圖表（Sparkline, Pie, Trend），追求極致性能。

---

## 2. 核心演算法推導與列舉

### I. 個股資金流分數 (Capital Flow Score)
推導自 `CapitalFlowEngine`:
$$Score = (VolumeRatio \times 0.35) + (MomentumScore \times 0.40) + (PersistenceScore \times 0.25)$$
- `VolumeRatio`: 今日成交值 / 歷史平均成交值。
- `MomentumScore`: $(漲跌幅\% \times 0.7) + (波動率 \times 0.3)$。
- `PersistenceScore`: 近期上漲天數比例之加權。

### II. 主流板塊強度 (Mainstream Score)
推導自 `MainstreamEngine`:
$$Score = (FlowScore \times 0.35) + (PersistenceScore \times 0.30) + (DiffusionScore \times 0.20) + (LeaderScore \times 0.15)$$
- `FlowScore`: 板塊內個股漲跌與成交金額之乘積平均。
- `PersistenceScore`: 過去三日分數之加權 ($0.5, 0.3, 0.2$)。
- `DiffusionScore`: 板塊內上漲個股比例（擴散度）。
- `LeaderScore`: 領頭羊個股的強度貢獻。

### III. 輪動淨動能 (Net Rotation Momentum, RNM)
推導自 `RotationLeadingAnalyser`:
$$RNM = \sum InflowScores - \sum OutflowScores$$
- 用途：當 $RNM$ 極大且股價未噴發時，視為「強烈暗中吸籌」。

### IV. 生命週期階段判定 (Lifecycle Stage)
基於 `TrendMetricsEngine` 提供的一階導數（斜率）與二階導數（加速度）：
- **點火期 (Ignition)**: 加速度 $> 0$ 且熱錢流入。
- **主升期 (Markup)**: 分數 $> 60$、斜率 $> 20$ 且穩定度高。
- **出貨期 (Distribution)**: 分數高但加速度為負，且波動率劇增。

---

## 3. 優化與升級路線圖

### 階段一：性能性能優化與資料防禦 (短期)
1.  **計算異步化** ✅ **已完成 (2026/06/07)**：依引擎依賴圖將五大引擎升級為兩階段並行 Isolate 執行。
    -   **Phase 1（並行）**：`CapitalFlowAnalyzer`、`MainstreamEngine`、`RotationEngine` 三者互不依賴，同時各自跑在獨立 Isolate 中。
    -   **Phase 2（並行）**：`LifecycleEngine`、`MarketSentimentEngine` 皆依賴 Phase 1 產出的 `mainstreams`，Phase 1 完成後同時啟動。
    -   新增 `BootstrapAnalyzer.analyzeAsync()`（Dart 3 Record `.wait` 語法協調）取代原先的單一 `compute(BootstrapAnalyzer.analyze, snapshots)` 呼叫。
    -   涉及檔案：`lib/domain/usecases/bootstrap_analyzer.dart`、`lib/main.dart`。
2.  **本地儲存分級保留清理** ✅ **已完成 (2026/06/07)**：防止原始 JSON 快照與 SQLite 歷史數據無限累積。
    -   **成長根因**：原始快照每天 ~500KB–1MB，若不清理，1 年約產生 125–250 MB；核心運算只需最近 5 天快照。
    -   **三層策略**：
        -   **Layer 1（原始快照）**：每次新交易日存入後，`SyncManager` 自動呼叫 `StorageService.pruneOldSnapshots(keepCount: 7)`，只保留最近 7 天，固定佔用 ~3.5–7 MB。
        -   **Layer 2（SQLite 歷史）**：每次新交易日存入後，`main.dart` 呼叫 `CategoryHistoryRepository.pruneOldHistory(keepDays: 365)`，四張表（category / mainstream / lifecycle / rotation history）同在一個事務內刪除 365 天前的舊紀錄，固定上限約 40–80 MB。
        -   **Layer 3（分析快取）**：分析結果存入後，`main.dart` 呼叫 `StorageService.pruneOldBootstrapCaches(keepCount: 3)`，保留最近 3 份快取，固定佔用 ~150–300 KB。
    -   **不影響核心邏輯**：計算引擎需要 5 天（保留 7 天）；圖表最多拉 15 天 SQLite（保留 365 天）；離線模式需 1 份快取（保留 3 份）。
    -   涉及檔案：`lib/data/services/storage_service.dart`、`lib/data/history/repositories/category_history_repository.dart`、`lib/data/managers/sync_manager.dart`、`lib/main.dart`。
3.  **數據校驗優化**：加強上市與上櫃資料日期不一致時的自動對齊邏輯。
4.  **DB 索引優化**：在 `category_history` 表的 `trade_date` 與 `category_name` 加上複合索引。

### 階段二：分析深度與技術指標整合 (中期)
1.  **引入量價關係**：加入「量價背離」檢測演算法。
2.  **技術指標融合**：將 RSI、MACD 或布林通道加入個股評分權重。
3.  **多空情緒細分**：區分「投機熱錢」與「法人穩健資金」。

### 階段三：智慧決策與自動化架構 (長期)
1.  **狀態管理重構**：隨著專案變大，引入 `Riverpod` 或 `Bloc` 取代目前的 Prop-Drilling 模式。
2.  **機器學習介入**：利用歷史生命週期數據訓練模型，預測板塊切換到下一階段的機率。
3.  **自訂回測系統**：提供 `MomentumStrategy` 的歷史回測績效數據展示。

---

## 4. 未使用/冗餘程式碼清單

建議檢查以下程式碼是否仍需保留，如無需使用可進行移除：

1.  **`lib/domain/engines/abnormal_money_engine.dart`**
    - **原因**：目前在 `AppBootstrapper` 與 `main.dart` 中皆未見其調用，疑似為舊版殘留。
2.  **`lib/domain/models/abnormal_money_result.dart`**
    - **原因**：伴隨上述引擎的數據模型。
3.  **`lib/data/models/stock_score.dart`**
    - **原因**：`CapitalFlowAnalyzer` 使用 `double` 作為分數，而非此 `StockScore` 類別實體。
4.  **`lib/presentation/pages/rotation_page.dart`**
    - **原因**：主導航已切換至 `LeadingIndicatorPage`，此舊版分頁似已無入口。
5.  **`lib/presentation/widgets/empty_view.dart`**
    - **原因**：內容為空。

---

**報告結語**：專案具備極高的工程完成度，特別是在數據引擎的數學模型與 UI 自繪性能上表現優異。未來的優化應著重於架構的可擴展性與更深層次的數據挖掘。
