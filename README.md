# 🚀 台股資金流分析平台 — 專案開發里程碑與系統架構白皮書

本文件詳實紀錄「台股資金流分析平台（tw_stock_capital_flow）」目前的階段性技術成果、核心 Clean Architecture 架構穿透設計、底層 SQLite (Drift) 資料庫結構，並定義下一階段（Phase 5）策略回測引擎的推進藍圖。

---

## 📋 一、 專案里程碑與開發藍圖 (Roadmap & Status)

目前專案已完美打通 **Phase 3（歷史資料庫對接）** 與 **Phase 4（UI 骨架屏與抗災降級防線）**，整體架構達到商業級 App 的穩定度，所有編譯鏈衝突已全面綠燈解鎖。

| 開發階段 (Phase) | 核心功能模組                                    | 當前狀態         | 實現成果細節                                                                                                                         |
| :--------------- | :---------------------------------------------- | :--------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| **Phase 1**      | **個股資料聚合**<br>(Category Aggregation)      | **100% 已完成**  | 成功實作將台股 1,900 多檔個股資料，於背景 Isolated（`compute`）運算執行緒中聚合成產業資金流向。                                      |
| **Phase 2**      | **UI 數據模型優化**<br>(CategoryUiModel)        | **100% 已完成**  | 完整定義多維度權重指標欄位，包含 `trendStrength`（趨勢強度）、`hotScore`（市場熱度）與延續力。                                       |
| **Phase 3**      | **歷史資料庫對接**<br>(History Database)        | **100% 已完成**  | 導入 Drift (SQLite) 本地持久化資料庫，完成跨頁面、跨元件的**依賴穿透鏈（Dependency Chain）**安全傳遞。                               |
| **Phase 4**      | **抗災降級與體驗優化**<br>(UI Recovery Defense) | **100% 已完成**  | 1. 移除簡陋轉圈圈，全面改用微光卡片骨架屏（Shimmer Skeleton）。<br>2. 實作**斷網離線歷史快照無縫降級機制**，搭配頂部優雅黃色警告條。 |
| **Phase 5**      | **策略回測引擎開發**<br>(Backtest Engine)       | 📅 *下一階段目標* | 依據本地已持久化的 `category_history` 歷史數據，進行產業板塊動量續航、資金輪動策略的技術回測。                                       |

---

## 🏗️ 二、 系統架構與依賴穿透設計 (Architecture)

平台嚴格遵循 **Clean Architecture (乾淨架構)** 分層原則，確保資料庫實例（Database Instance）在全域中保持單一實例（Singleton）安全，避免多線程同時寫入導致 SQLite Lock。

### 1. 數據穿透與依賴關係鏈
數據權限與資料庫接口統一自應用程式開屏起點（Bootstrap）進行初始化，透過中央靜態導頁器（Navigation Router）一路向下無縫穿透至二級、三級子頁面：

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          Presentation Layer                            │
│                                                                        │
│         ┌────────────────────────────────────────────────────┐         │
│         │        BootstrapApp (main.dart / State 初始化)       │         │
│         └─────────────────────────┬──────────────────────────┘         │
│                                   │ (初始化並持有 Repository)             │
│                                   ▼                                    │
│         ┌────────────────────────────────────────────────────┐         │
│         │               HomePage (主頁面解包注入)              │         │
│         └───────────────┬────────────────────────────┬───────┘         │
│                         │ (具名參數 categories)       │ (具名參數)      │
│                         ▼                            ▼                 │
│         ┌──────────────────────────────┐┌────────────────────────────┐ │
│         │  MarketHeatmap (市場熱區九宮格) ││ TopHotCategories (今日主流) │ │
│         └───────────────┬──────────────┘└────────────┬───────────────┘ │
│                         │                            │                 │
│                         └──────────────┬─────────────┘                 │
│                                        │ (透過 CategoryNavigation 傳遞)  │
│                                        ▼                               │
│         ┌────────────────────────────────────────────────────┐         │
│         │    SubCategoryPage (二級子板塊頁面 — 成功取得 Repo)    │         │
│         └────────────────────────────────────────────────────┘         │
└────────────────────────────────────────────────────────────────────────┘
```


這裡為您從 「二、近期修正要點與命名衝突解決紀錄」 開始，整合原本的架構圖、資料庫資訊、驗證步驟以及下一階段目標，輸出為一份格式完全相連、沒有斷層的完整 Markdown 區塊：

Markdown
### 2. 近期修正要點與命名衝突解決紀錄
在 Phase 3 向 Phase 4 推進的過程中，專案解決了兩大核心 Dart 編譯衝突，這對於維持架構健壯性與資料向下穿透至關重要：
* **解鎖位置參數到具名參數的對齊 (Eliminated 'isn't a function' error)**：
  由於底層資料庫 `CategoryHistoryRepository` 需要向下穿透，`MarketHeatmap` 與 `TopHotCategories` 的建構子皆被重構為包含大括號 `{}` 的具名參數構造函數。外部呼叫端（如 `HomePage` 的 `_buildHeatMap()`）必須明確加上 `categories:` 與 `historyRepository:` 標籤，防止 Dart 編譯器將 Widget 類別誤判為普通函數呼叫。
* **解鎖跨檔案命名空間衝突 (Resolved Name Clash)**：
  修正了 `top_hot_categories.dart` 內部類別與建構子不小心誤植為 `MarketHeatmap` 的複寫問題。將其正名為 `TopHotCategories` 後，徹底移除了多程式庫同名衝突（*The name 'MarketHeatmap' is defined in the libraries...*），讓主頁面的組件樹（Widget Tree）回復清晰的單一職責原則。
* **靜態導頁器的穿透重構 (Navigation Refactor)**：
  `CategoryNavigation.openCategory` 的參數簽章擴充為三個位置參數：`(context, category, historyRepository)`。此舉強制所有觸發導頁的 UI 節點（熱區圖磚、主流列表）在跳轉時必須主動攜帶資料庫接口，完成了向二級子頁面 `SubCategoryPage` 傳遞歷史走勢數據的完整閉環。

---

## 💾 三、 本地資料庫綱要紀錄 (Database Schema)

底層持久化核心採用 **SQLite**，並透過 Dart 生態系中最健壯的高效 ORM 框架 **Drift** 進行對接。

### 1. 實體配置檔案路徑
* **資料庫定義核心**: `lib/data/database/app_database.dart`
* **產業歷史資料表定義**: `lib/data/database/tables/category_history_table.dart`
* **資料庫防線實現層**: `lib/data/history/repositories/category_history_repository.dart`

### 2. 資料表結構 (Table: `category_history`)
此表為防範斷網與未來進行策略回測的最核心持久化防線：

```sql
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
```

3. 核心快取與抗災防禦函數實作
資料庫內部由 `AnalysisCacheService` 與 `CategoryHistoryRepository` 提供三大數據攔截防線：
* **`loadBootstrapCache(dateKey)`**: 開屏時進行秒級攔截。若當日數據已計算並留存，則直接命中快取秒開畫面，拒絕重複下載與解析。
* **`saveBootstrapCache(dateKey, result)`**: 今日數據在背景多線程（Isolate）解析完畢後，即時且無感地寫入 SQLite 硬碟。
* **`tryGetAnyLatestCache()` (離線防禦核心)**: 當發生無網路、超時（Timeout 放寬至 60 秒防護，確保尖峰時刻 1,900 檔個股順利解析）或運算異常時，此防線會立刻繞過日期限制，去硬碟搜找**最近一次健康的歷史快照數據**進行全域優雅降級，實現 **0 白屏、0 閃退** 的強健體驗。

---

## 🧪 四、 啟動後的標準驗證步驟 (Verification Checklist)

當您編譯通過並成功啟動 App 時，請依據以下兩種情境進行功能正確性驗證：

### 🏁 情境 A：正常網路連線測試（主線流程）
- [ ] **骨架屏預期流暢：** 首次開屏時，畫面應顯示閃爍的 `MainSectionSkeleton`（微光產業卡片骨架屏排版），這代表 60 秒的放寬超時防線正在安全守護數據下載與 JSON 解析。
- [ ] **快取命中驗證：** 載入成功後，關閉 App 並重開，終端機（Console）必須明確印出：  
  `🚀 [Cache Hit] 命中今日數據快取`，且畫面應達到秒開、不再閃爍骨架屏。
- [ ] **依賴穿透測試：** 點擊「市場熱區」九宮格或「今日主流類股」列表，應能順暢跳轉至 `SubCategoryPage`，且二級頁面內功能無紅字報錯，歷史走勢圖表能正常載入。

### ✈️ 情境 B：極端斷網飛航測試（抗災降級防線）
- [ ] **異常攔截驗證：** 開啟手機/模擬器飛航模式（完全切斷網路）並重開 App，終端機必須印出：  
  `⚠️ [防禦機制觸發] 網路或計算異常: [Error Detail]，啟動本地全域降級防線...`。
- [ ] **降級 UI 展示：** 畫面不允許拋出白屏錯誤，主頁面頂部必須自動彈出淡黃色通知條（`Color(0xFFFFF3CD)` 柔和警示黃）：  
  *「當前網路連線不穩定，已為您加載本地歷史資金流數據。」*。
- [ ] **歷史數據接軌：** 畫面上應能流暢顯示硬碟中所存留的過去任意一天歷史資金流快照狀態，且不影響二級頁面的基本瀏覽。

---

## 📅 五、 下一階段前進藍圖 (Phase 5: Backtest Engine)

隨著本地資料庫接口與歷史持久化軌跡 `category_history` 的全面打通，下一階段我們將正式開發**「板塊策略回測引擎」**：

1. **板塊動量續航策略 (Momentum Strategy)**
   * 實作利用資料庫過往 5 至 20 交易日的 `trendStrength` 與 `score`，計算資金淨流入排行前 3 名板塊的後續 3~5 天波段漲幅續航力與勝率。
2. **資金輪動領先指標 (Rotation Backtest)**
   * 寫入回測演算法，驗證當資金從 A 產業（如半導體）抽離並流入 B 產業（如光電）時，其輪動分數 `rotation.score` 是否具備統計學上的實戰領先預警價值。
3. **情緒週期極值抄底/逃頂策略 (Sentiment Cycle)**
   * 基於歷史 `market_sentiment` 軌跡，回測當市場情緒達到極致恐慌（恐慌冰點期）或極致貪婪時，大盤與核心板塊在隨後 1 週內發生拐點反轉的機率與最大回撤比（MDD）。