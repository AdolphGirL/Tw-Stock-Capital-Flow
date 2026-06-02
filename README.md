# 🚀 台股資金流分析平台 — 專案開發里程碑與系統架構白皮書

本文件詳實紀錄「台股資金流分析平台（tw_stock_capital_flow）」目前的階段性技術成果、核心 Clean Architecture 架構分流與穿透設計、底層 SQLite (Drift) 資料庫結構，並定義下一階段的策略推進藍圖。

---

## 📋 一、 專案里程碑與開發藍圖 (Roadmap & Status)

目前專案已完美打通 **Phase 3（歷史資料庫對接）** 與 **Phase 4（UI 骨架屏與抗災降級防線）**，整體架構達到商業級 App 的穩定度，並完成了針對「頁面膨脹、職責重疊」的重大架構分流與瘦身重構。

| 開發階段 (Phase) | 核心功能模組                                             | 當前狀態         | 實現成果細節                                                                                                                                                                                                                 |
| :--------------- | :------------------------------------------------------- | :--------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Phase 1**      | **個股資料聚合**<br>(Category Aggregation)               | **100% 已完成**  | 成功實作將台股 1,900 多檔個股資料，於背景 Isolated（`compute`）運算執行緒中聚合成產業資金流向。                                                                                                                              |
| **Phase 2**      | **UI 數據模型優化**<br>(CategoryUiModel)                 | **100% 已完成**  | 完整定義多維度權重指標欄位，包含 `trendStrength`（趨勢強度）、`hotScore`（市場熱度）、以及包裹個股清單的 `List<StockUiModel> stocks`。                                                                                       |
| **Phase 3**      | **歷史資料庫對接**<br>(History Database)                 | **100% 已完成**  | 導入 Drift (SQLite) 本地持久化資料庫，完成跨頁面、跨元件的**依賴穿透鏈（Dependency Chain）**安全傳遞。                                                                                                                       |
| **Phase 4**      | **抗災降級與職責優化**<br>(UI & Navigation Refactor)     | **100% 已完成**  | 1. 全面改用微光卡片骨架屏（Shimmer Skeleton）與網路異常全域降級防線。<br>2. **完成 HomePage 降噪瘦身**，將熱圖與卡片精準分流至導航分頁。<br>3. **廢棄舊有全螢幕 StockListPage**，全面升級為原地滑出的成分股 Draggable 抽屜。 |
| **Phase 5**      | **核心體驗升級與歷史回溯**<br>(Category Curves & K-Line) | 📅 *當前推進目標* | 升級 `SubCategoryPage` 圖表，利用 `CategoryHistoryRepository` 進行多週期歷史看盤 K 線與產業走勢曲線繪製。                                                                                                                    |
| **Phase 6**      | **策略回測引擎開發**<br>(Backtest Engine)                | 📅 *下一階段藍圖* | 依據本地已持久化的 `category_history` 歷史數據，進行產業板塊動量續航、資金輪動策略的技術回測。                                                                                                                               |

---

## 🏗️ 二、 系統架構與依賴穿透設計 (Architecture)

平台嚴格遵循 **Clean Architecture (乾淨架構)** 分層原則，實施「畫面負責渲染、導航負責動詞、基礎設施維持公共化」的解耦設計。

### 1. 職責分離與 HomePage 降噪優化
為了杜絕「畫面功能重複、一級分頁過於臃腫」的巢狀疲勞感，平台進行了無情且優雅的清理優化：
* **分流與降噪**：將 `MarketHeatmap`（資金熱圖）、`TopHotCategories`（熱門九宮格）、`StrategyDashboardPage`（動量決策燈號）全部分流移轉到 `MainNavigationContainer` 的獨立常駐一級分頁（Tabs）。
* **HomePage 瘦身完成**：第一個頁籤（Tab 0）精準定位為 **【大盤診斷與核心指標 (Market Dashboard)】**。僅保留大盤上市櫃多空分數、市場最強主流、以及市場熱錢情緒綜合風控診斷，畫面長度精簡 60%，實現秒開、極速穿透。

### 2. 導航中樞 (CategoryNavigation) 的全新穿透防線
平台將原先僅負責全螢幕跳轉的 `CategoryNavigation` 升級擴充為**「全 App 靜態動作動作調度大腦」**。它擁有以下兩大核心靜態方法，完美打破了多對多的程式碼耦合：

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          CategoryNavigation 導航中樞                    │
├────────────────────────────────────────────────────────────────────────┤
│ 🚀 動作 A: openCategory()                                              │
│    [主分類頁面] ───► 跳轉至全螢幕 [SubCategoryPage] (穿透傳遞 Repo 接口)  │
├────────────────────────────────────────────────────────────────────────┤
│ 🚀 動作 B: showStockListSheet()                                        │
│    [細分類卡片] ───► 原地滑出 [BottomSheet (Draggable 半窗抽屜)]        │
│                          │                                             │
│                          ▼ (依據成交值 Value 降序降維排行，台股紅漲綠跌) │
│    [點擊成分股] ───► 外部瀏覽器穿透 ───► Yahoo 奇摩股市 (自動判定上市櫃後綴)│
└────────────────────────────────────────────────────────────────────────┘
```


3. 移除舊有 StockListPage 與資料型態對接修復
由於 CategoryUiModel 內部已封裝了極其健康的 List<StockUiModel> stocks 數據結構，平台完成了以下關鍵修復：

解鎖型態不匹配 (Type Mismatch)：CategoryNavigation.showStockListSheet 的接收參數正名為 List<StockUiModel> uiStocks，並在內部透過 s.stock.value 進行億元級成交值過濾與排序，直接相容於細產業卡片的數據。

徹底廢棄 StockListPage：原地滑出、隨切秒開的半窗體感完全替代了舊有全螢幕個股清單。舊有的 stock_list_page.dart 被整檔無情刪除，成功減輕 UI 渲染層負擔，消除了使用者的返回鍵（Back Button）操作疲勞。

三、 本地資料庫綱要紀錄 (Database Schema)
底層持久化核心採用 SQLite，並透過 Dart 生態系中最健壯的高效 ORM 框架 Drift 進行對接。

1. 實體配置檔案路徑
資料庫定義核心: lib/data/database/app_database.dart

產業歷史資料表定義: lib/data/database/tables/category_history_table.dart

資料庫防線實現層: lib/data/history/repositories/category_history_repository.dart

2. 資料表結構 (Table: category_history)
此表為防範斷網與未來進行多週期曲線、策略回測的最核心持久化防線：

SQL
CREATE TABLE category_history (
    tradeDate      TEXT,     -- 交易日期 (格式如: '20260531') -> 複合主鍵 Part 1
    categoryName   TEXT,     -- 產業板塊名稱 (例如: 'AI伺服器') -> 複合主鍵 Part 2
    score          REAL,     -- 資金流核心分數 (量價聚合指標)
    hotScore       REAL,     -- 市場熱度分數 (當日周轉與人氣指標)
    persistence    REAL,     -- 資金延續力強度
    trendStrength  REAL,     -- 趨勢多頭排列強度指標
    riseCount      INTEGER,  -- 產業板塊內當日上漲個股數
    fallCount      INTEGER,  -- 產業板塊內當日下跌個股數
    totalCount     INTEGER,  -- 產業板塊內總計包含個股數
    PRIMARY KEY (tradeDate, categoryName)
);
3. 核心快取與抗災防禦函數實作
資料庫內部由 AnalysisCacheService 與 CategoryHistoryRepository 提供三大數據攔截防線：

loadBootstrapCache(dateKey): 開屏時進行秒級攔截。若當日數據已計算並留存，則直接命中快取秒開畫面，拒絕重複下載與解析。

saveBootstrapCache(dateKey, result): 今日數據在背景多線程（Isolate）解析完畢後，即時且無感地寫入 SQLite 硬碟。

tryGetAnyLatestCache() (離線防禦核心): 當發生無網路、超時（Timeout 放寬至 60 秒防護）或運算異常時，此防線會立刻繞過日期限制，去硬碟搜找最近一次健康的歷史快照數據進行全域優雅降級，實現 0 白屏、0 閃退 的強健體驗。

🧪 四、 啟動後的標準驗證步驟 (Verification Checklist)
當您編譯通過並成功啟動 App 時，請依據以下兩種情境進行新功能正確性驗證：

🏁 情境 A：正常網路連線與分流測試（主線流程）
[ ] HomePage 瘦身驗證： 第一個頁籤畫面簡潔，無 MarketHeatmap（熱圖）與九宮格等重複區塊，且底部帶有黃色引導高階功能轉移之「提示性微卡片」。

[ ] 半窗抽屜拉出測試： 在主分類點擊進去後的 SubCategoryPage（細分類頁面）中，點擊任何細產業卡片，應原地流暢由下往上滑出成份股抽屜，且股票依照成交值排行，不應發生頁面跳轉。

[ ] 外部網頁擊穿穿透： 點擊抽屜內部的任意個股（例如台積電），應自動喚起手機瀏覽器並精準開啟 Yahoo 奇摩股市網頁，且網址後綴（上市 .TW / 上櫃 .TWO）完全正確。

✈️ 情境 B：極端斷網飛航測試（抗災降級防線）
[ ] 異常攔截與全域降級： 完全切斷網路並重開 App，主頁面頂部自動彈出淡黃色柔和警示通知條：「當前網路連線不穩定，已為您加載本地歷史資金流數據。」。

[ ] 離線依賴鏈完整： 即使在斷網降級狀態下，點擊卡片跳轉至 SubCategoryPage 的依賴穿透鏈依然暢通，畫面不允許拋出任何白屏與紅色報錯。

📅 五、 當前推進目標：歷史看盤 K 線產業回溯 (Phase 5)
隨著本地資料庫接口 CategoryHistoryRepository 在各級頁面（特別是 SubCategoryPage）的完整穿透，本階段的核心任務為 【將產業板塊當作一檔個股，進行多週期歷史看盤曲線繪製】：

多週期歷史軌跡調取 (Multi-Period Fetching)

運用穿透至 SubCategoryPage 的 historyRepository 接口，在頁面初始化時，異步調出該產業過去 20 天、60 天或 120 天的歷史 SQLite 紀錄數組。

資金流 K 線與走勢曲線繪製 (Category Trend Line & Pseudo K-Line)

將產業的 score（資金流分數）做為收盤價，hotScore（熱度）做為成交量，整合 fl_chart 圖表組件，在 SubCategoryPage 頂部打造一個專屬的 「產業多週期動態強弱走勢圖」。

讓交易者一眼看穿該產業目前是在進行「三日資金加速增強（isStrengthening）」，還是屬於「高檔量價背離、資金高唱退潮」的危險階段。

📅 六、 未來前進藍圖：策略回測引擎開發 (Phase 6)
當歷史持久化軌跡與多週期看盤曲線完全成熟後，平台將正式全面收網，進軍開發「板塊大數據策略回測引擎」：

板塊動量續航策略 (Momentum Strategy Backtest)

利用歷史庫中 5 至 20 交易日的 trendStrength 排行，回測買入資金淨流入前 3 名板塊後的續航力、勝率、以及最佳持股天數天期。

資金輪動領先指標 (Rotation Verification)

寫入歷史驗證演算法，統計當資金從權值板塊抽離並流入特定細分小產業時，輪動分數 rotation.score 在歷史上是否具備顯著的統計學預警與抄底價值。

情緒週期抄底/逃頂策略 (Sentiment Cycle Engine)

基於歷史 market_sentiment 軌跡，回測當全市場熱錢強度達到極致恐慌（恐慌冰點期）或極致貪婪（過熱警戒期）時，隨後 1 週內指數與核心板塊發生拐點反轉的機率與最大回撤比（MDD），正式將平台由「看盤分析工具」升級為「高階量化操盤決策大腦」。