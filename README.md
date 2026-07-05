# 台股資金流向分析系統
### Tw Stock Capital Flow — 板塊輪動追蹤與動量決策工具

> 資料來源：臺灣證券交易所（TWSE）/ 證券櫃檯買賣中心（TPEX）開放資料  
> 平台：iOS / Android（Flutter）  
> 版本：1.0.0

---

## 目錄

1. [專案簡介](#專案簡介)
2. [功能總覽](#功能總覽)
   - [大盤診斷](#大盤診斷-tab-0)
   - [異常偵測器](#異常偵測器-tab-1)
   - [動量決策](#動量決策-tab-2)
   - [領先雷達](#領先雷達-tab-3)
   - [觀察清單](#觀察清單watchlist)
   - [訊號異動通知](#訊號異動通知)
   - [三大法人籌碼](#三大法人籌碼)
   - [30日互動走勢圖](#30日互動走勢圖)
3. [鑽入導覽](#鑽入導覽drill-down)
4. [核心演算引擎](#核心演算引擎)
5. [資料庫設計](#資料庫設計)
6. [技術棧](#技術棧)
7. [專案結構](#專案結構)
8. [安裝與執行](#安裝與執行)
9. [免責聲明](#免責聲明)

---

## 專案簡介

本 App 是一套專為台灣股市一般投資人設計的**板塊資金流向監控與量化決策系統**。

傳統看盤工具只告訴你今天哪支股票漲最多，但無法回答：

- 主力資金正在往哪個板塊集中？
- 這個板塊的上漲是剛開始（點火）還是快結束（出貨）？
- 哪些板塊股價還在底部，但主力已悄悄在進場建倉？
- 今天哪個板塊的資金動向在統計上「異常顯著」？
- 三大法人今日買超還是賣超？

本 App 透過五大量化引擎，從多個維度同時計算，並以語意化標籤、顏色徽章、互動圖表呈現給一般受眾，取代讓人看不懂的裸數字。

---

## 功能總覽

### 大盤診斷 (Tab 0)

**今日訊號快照**
- 全市場 BUY / HOLD / SELL / 觀望 板塊數量計數圓圈
- 今日點火期板塊清單（最值得關注的早鳥機會，可點擊鑽入）
- 今日最強買進訊號前4名 + 風控警示前4名（含強度評分、操盤摘要）

**個人觀察清單**（有星號收藏時才顯示）
- 即時顯示關注板塊的當前訊號（BUY / HOLD / SELL / 觀望）
- StreamBuilder 即時更新，新增/移除板塊後自動重繪
- 可直接在清單中點擊星號快速取消收藏

**大盤多空診斷**
- 上市 / 上櫃市場今日上漲、下跌家數與資金流向分數
- 點擊進入各市場的完整板塊列表

**三大法人籌碼**
- 外資 / 投信 / 自營商三欄並排顯示差額（億元）
- 底部合計行顯示三大法人總買賣超
- 詳見 [三大法人籌碼](#三大法人籌碼) 章節

**市場熱錢情緒**
- 情緒等級徽章（過熱警惕 / 資金樂觀 / 中性觀望 / 偏空悲觀 / 市場恐慌）
- 情緒分數進度條、上漲家數、下跌家數、熱錢強度、主流均強四指標

---

### 異常偵測器 (Tab 1)

以 **Z-score 統計分析**識別今日資金動向在歷史基準上「顯著異常」的板塊，從海量板塊中篩出真正值得關注的異動信號。

**運算邏輯**
- 載入最近 35 天歷史快照，至少需 5 天才分析
- 以每個板塊的 `trendStrength`（趨勢強度）計算歷史均值與標準差
- Z-score = (今日強度 − 歷史均值) / 標準差
- **異常資金湧入**：Z > 0.8，取前 8 名（按 Z 值降序）
- **異常資金流出**：Z < −0.8，取前 8 名（按 Z 值升序）

**每張卡片包含：**
- 板塊名稱 + 市場標籤（上市 / 上櫃）
- Z-score 數值 + 正負色塊（紅=湧入 / 綠=流出）
- 今日趨勢強度 vs 歷史均值 + 百分比偏差
- 歷史樣本天數標注
- 點擊可鑽入板塊細目

**摘要卡片：**
- 分析板塊總數、可用歷史天數、異常湧入/流出計數

---

### 動量決策 (Tab 2)

依據「七期生命週期理論」將每個板塊自動分類，並給出量化決策訊號。

**訊號分類**

| 訊號 | 觸發條件 |
|------|----------|
| 🟢 BUY（買進） | 點火期+熱錢流入+正加速；或擴散/主升期+高共振擴散度 |
| 🟡 HOLD（續抱） | 熱錢仍在+延續力≥40，尚未達加碼條件 |
| 🔴 SELL（出清） | 結構性（出貨/退潮/死亡期）；或熱錢撤+延續力<40雙殺 |
| ⚪ 觀望 | 盤整期 / 訊號不明確 |

**每張卡片包含：**
- 板塊名稱 + 生命週期標籤 + ⭐ 星號收藏
- vs 昨日資金流比較徽章（▲/▼）、3日趨勢方向標記
- 4個語意化指標徽章：趨勢動能 / 延續力 / 熱錢狀態 / 擴散度進度條
- SQLite 歷史比較徽章（▲/▼ 較昨日 / vs N日均 / 連升跌N日）
- ⚠️ 資金背離警告（SELL 訊號但資金熱區仍有流入）
- 白話操盤指南說明

---

### 領先雷達 (Tab 3)

透過輪動淨動能指數（RNM）辨識「股價還在底部、但主力已悄悄建倉」的潛力板塊。

**訊號評級**

| 評級 | 說明 |
|------|------|
| 🟢 強力吸籌 | RNM 強勁正值，多個板塊資金輸血 |
| 🍏 溫和流入 | 資金小幅淨流入 |
| ⚪ 中性觀望 | 資金無明顯方向 |
| 🟠 派發風險 | 資金開始淨流出 |
| 🔴 大量出逃 | RNM 強勁負值，建議迴避 |

**每張卡片包含：**
- 板塊名稱 + 訊號評級徽章 + ⭐ 星號收藏
- 淨動能 RNM 數值 + vs 昨日資金流比較
- 流入/流出能量條視覺化（輸血板塊數 + 總量）
- SQLite 歷史比較徽章
- 輪動操盤指南說明

---

### 觀察清單（Watchlist）

- 在動量決策或領先雷達的任何板塊卡片右上角點擊 ⭐ 加入收藏
- 首頁「我的觀察清單」區塊即時反映所有關注板塊的當前訊號
- 取消收藏時，自動清除該板塊的訊號歷史快照
- 持久化儲存於 SQLite `watchlist` 表，App 重啟後保留

---

### 訊號異動通知

每次開啟 App 完成演算後自動執行，**同時觸發 App 內 Dialog 與系統本地推播通知**：

1. 讀取個人觀察清單
2. **若清單為空，完全跳過（零額外運算）**
3. 若有關注板塊：
   - 載入 `signal_snapshot` 表的上次訊號記錄
   - 重新計算今日訊號
   - 偵測升級（觀望→買進）或降級（持股→出清）
   - 儲存今日訊號作為下次比對基準
4. 若偵測到異動：
   - 渲染完成後彈出 **App 內 Dialog**
   - 同步推送 **系統本地通知**（iOS / Android），App 在背景也可接收

**Dialog / 通知內容：** ✅ 訊號升級（排最前）/ ⚠️ 訊號降級 / 🆕 首次記錄  
**取消機制：** 移除收藏 → 同步刪除快照 → 下次不再追蹤

---

### 三大法人籌碼

首頁卡片，即時顯示三大法人（外資 / 投信 / 自營商）當日買賣超金額。

**資料來源**  
直接呼叫 TWSE 法人買賣超 API（`BFI82U`），不依賴第三方服務。

**分組規則**

| 分組 | 組成來源 |
|------|----------|
| 外資 | 外資及陸資（不含外資自營商）+ 外資自營商 |
| 投信 | 投信 |
| 自營商 | 自營商（自行買賣）+ 自營商（避險） |
| 三大合計 | API 合計行（與 TWSE 官方一致） |

**顯示內容**
- 三欄並排：名稱 + 差額（億元，**紅=買超 / 綠=賣超**）+ 買進億 + 賣出億
- 底部合計行：三大合計買超/賣超總額
- 卡片右上角顯示交易日期標籤

**技術設計**
- `HomePage` 在 `initState` 以 `widget.tradeDate` 自行發起非阻塞 HTTP 請求，與主流程完全解耦
- 民國年日期（`YYYMMDD`，7碼）自動轉換為西元年（`YYYYMMDD`，8碼），相容 App 內部日期系統
- **Fallback 機制**：若當日無資料（非交易日 / 週末），自動往前找最多 5 個日曆日，確保資料顯示
- 解析失敗或網路錯誤時靜默忽略，不影響主流程

---

### 30日互動走勢圖

在任何細類板塊頁面（SubCategoryPage）頂部，顯示近30日互動折線圖。

**支援4種指標即時切換：**

| 指標 | 欄位 | 說明 |
|------|------|------|
| 趨勢強度 | `trendStrength` | 多日複合指標，反映板塊中期強弱 |
| 資金流分 | `score` | 當日資金流原始分數 |
| 持續力 | `persistence` | 主力持倉延續強度 |
| 上漲占比% | `riseCount/totalCount×100` | 板塊個股多空廣度 |

**互動功能：**
- 點觸折線任意點 → Tooltip 顯示月/日 + 精確數值
- 正值顯示紅線（台股慣例），負值顯示綠線
- 數值跨越正負時自動顯示零軸虛線參考
- 資料不足時降級顯示今日多空分佈圓餅圖

---

## 鑽入導覽（Drill-down）

```
大類股列表（MainCategoryPage）
    ↓ 點擊板塊
細類股列表（SubCategoryPage）
    ├── 頂部：30日互動走勢圖（fl_chart）
    └── 下方：細類股卡片列表
         ↓ 點擊細類股
成分股清單（Bottom Sheet）
    ↓ 點擊個股
Yahoo 股市個股頁面（外部瀏覽器）
```

動量決策與領先雷達的卡片點擊後，也走相同的鑽入路徑。  
異常偵測器的卡片點擊後同樣直接鑽入對應板塊細目。

---

## 核心演算引擎

### 1. CapitalFlowEngine — 資金流引擎

計算每支個股的今日資金流分數，加權匯總至板塊層級：

```
個股分數 = (成交量比 × 0.35) + (動量分數 × 0.40) + (持續力分數 × 0.25)
板塊分數 = Σ(個股分數 × 市值權重)
```

### 2. MainstreamEngine — 主流方向引擎

多週期加權（近1日/3日/5日），找出最具資金凝聚力的主流板塊。

### 3. LifecycleEngine + TrendMetricsEngine — 生命週期引擎

將板塊劃分為8個生命週期階段：

| 階段 | 特徵 |
|------|------|
| 點火 (Ignition) | 熱錢開始進場，正加速 |
| 擴散 (Expansion) | 資金擴散至板塊內多支個股 |
| 主升 (Markup) | 全面上攻，擴散度高 |
| 狂熱 (Euphoric) | 市場過熱，情緒頂峰 |
| 出貨 (Distribution) | 主力高檔派發籌碼 |
| 退潮 (Decline) | 資金加速撤出 |
| 死亡 (Dead) | 資金潰散 |
| 盤整 (Consolidation) | 無明確方向，觀望 |

### 4. MomentumStrategy — 動量決策策略

```
決策優先順序：
① 結構性 SELL（出貨/退潮/死亡 → 無條件出清）
② BUY（點火+熱錢+正加速；或擴散/主升+高共振≥50%）
③ HOLD（熱錢在+延續力≥40）
④ 疲竭 SELL（熱錢撤且延續力<40，雙指標惡化）
⑤ NEUTRAL（盤整或訊號不明確）
```

### 5. RotationEngine + RotationLeadingAnalyser — 輪動領先引擎

計算板塊間資金輪動路徑與淨動能（RNM），輸出五級訊號評級。

### 6. AnomalyDetector — 異常偵測（Z-score）

```
歷史均值 μ = mean(trendStrength, N days)
標準差 σ = std(trendStrength, N days)
Z-score = (today − μ) / σ

湧入閾值：Z > 0.8
流出閾值：Z < −0.8
樣本需求：≥ 5 天
```

---

## 資料庫設計

使用 **Drift（SQLite ORM）** 持久化，共 **6 張表**，Schema V5：

| 表名 | 說明 | 主鍵 | 保留期限 |
|------|------|------|----------|
| `category_history` | 每日板塊歷史快照（trendStrength / score / persistence 等） | `(tradeDate, categoryName)` | 365天 |
| `mainstream_history` | 每日主流排行 | `(tradeDate, categoryName)` | 365天 |
| `lifecycle_history` | 每日生命週期階段 | `(tradeDate, categoryName)` | 365天 |
| `rotation_history` | 每日輪動路徑 | `(tradeDate, fromCategory, toCategory)` | 365天 |
| `watchlist` | 個人觀察清單 | `categoryName` | 永久 |
| `signal_snapshot` | 最近一次訊號快照（異動比對用） | `categoryName` | 隨收藏移除 |

> `category_history` 同時作為異常偵測器的統計基礎，最多回溯 35 天歷史資料。

---

## 技術棧

| 類別 | 套件 / 技術 |
|------|-------------|
| 框架 | Flutter 3.x / Dart SDK ^3.11.5 |
| 本地資料庫 | Drift 2.28.1（SQLite ORM，響應式 Stream） |
| 圖表 | fl_chart 1.2.0（互動折線圖） |
| 動畫 | flutter_animate 4.5.0 / animations 2.0.11 |
| 字型 | google_fonts 8.1.0 |
| 外部連結 | url_launcher 6.3.1 |
| 快取 | shared_preferences（分析結果 JSON 快取） |
| 網路 | http 1.2.0（TWSE / TPEX 開放 API） |
| 推播通知 | flutter_local_notifications 17.2.4（iOS + Android 系統通知） |
| Code Gen | drift_dev + build_runner |
| 自訂圖表 | CustomPainter（Sparkline、多空分佈圓餅圖） |

---

## 專案結構

```
lib/
├── core/
│   ├── constants/              # 全域常數（API endpoint、分析參數）
│   ├── extensions/             # List 擴充方法
│   ├── navigation/             # CategoryNavigation（板塊鑽入、個股清單、Yahoo Finance）
│   ├── services/
│   │   └── notification_service.dart  # 本地推播通知（iOS / Android）
│   └── utils/                  # 日期工具
│
├── data/
│   ├── database/
│   │   ├── app_database.dart   # Drift AppDatabase（Schema V5）
│   │   └── tables/             # 6張 Table 定義
│   ├── history/repositories/   # CategoryHistoryRepository
│   ├── watchlist/repositories/ # WatchlistRepository（CRUD + Stream）
│   ├── signal/repositories/    # SignalSnapshotRepository（訊號異動比對）
│   ├── managers/               # SyncManager（資料同步排程）
│   ├── models/                 # 資料層模型
│   ├── repositories/           # HistoryRepository（本地 JSON 快照）
│   └── services/
│       ├── stock_service.dart
│       ├── storage_service.dart
│       ├── analysis_cache_service.dart
│       └── institutional_flow_service.dart  # 三大法人 TWSE API
│
├── domain/
│   ├── engines/                # 六大演算引擎（含 AnomalyDetector）
│   ├── analysers/              # RotationLeadingAnalyser
│   ├── enums/                  # LifecycleStage / LeadingSignalType / SentimentLevel
│   ├── models/
│   │   ├── institutional_flow_result.dart  # InstitutionalFlowResult / InstitutionalGroup
│   │   └── ...其他領域模型
│   ├── services/               # SignalChangeDetector（純邏輯）
│   ├── strategies/             # MomentumStrategy
│   └── usecases/               # BootstrapAnalyzer / AppBootstrapResult
│
└── presentation/
    ├── models/                 # CategoryUiModel
    ├── pages/
    │   ├── home_page.dart                  # 大盤診斷（含三大法人籌碼）
    │   ├── main_navigation_container.dart  # 底部導覽殼層（IndexedStack）
    │   ├── anomaly_detector_page.dart      # 異常偵測器（Z-score 統計）
    │   ├── strategy_dashboard_page.dart    # 板塊動量決策
    │   ├── leading_indicator_page.dart     # 輪動領先雷達
    │   ├── main_category_page.dart         # 大類板塊列表
    │   └── sub_category_page.dart          # 細類板塊 + 30日互動圖
    ├── theme/                  # AppTheme
    └── widgets/
        ├── category_card.dart
        ├── category_history_summary.dart  # 歷史比較徽章
        ├── category_trend_chart.dart      # 30日 fl_chart 互動折線圖
        ├── market_heatmap.dart            # 全市場資金熱力圖
        ├── market_signal_summary.dart     # 今日訊號快照面板
        ├── signal_change_dialog.dart      # 訊號異動通知 Dialog
        ├── trend_sparkline.dart           # 迷你 Sparkline
        └── watchlist_button.dart          # 星號收藏切換按鈕
```

---

## 安裝與執行

### 前置需求

- Flutter SDK ≥ 3.11.5
- Dart SDK ≥ 3.0.0
- Android Studio / Xcode（依目標平台）

### 步驟

```bash
# 1. 安裝套件
flutter pub get

# 2. 產生 Drift 程式碼（首次或修改 Table 後需執行）
dart run build_runner build

# 3. 執行
flutter run
```

> **注意**：首次啟動需要網路連線，App 會自動從 TWSE / TPEX 同步最新交易日資料。同步完成後可離線使用快取資料。  
> 三大法人籌碼每次啟動時即時抓取，離線時不顯示此卡片。

### 推播通知權限

- **iOS**：首次啟動時系統彈窗請求通知權限（`requestAlertPermission / requestBadgePermission / requestSoundPermission`）
- **Android**：無需額外設定，透過 `signal_changes_v1` 通知頻道發送

### 更新 Drift Schema

新增 Table 或修改欄位後：

```bash
dart run build_runner build --delete-conflicting-outputs
```

同步更新 `AppDatabase.schemaVersion` 並在 `onUpgrade` 中加入對應 migration。

---

## 免責聲明

本 App 所有計算結果與訊號，**僅供參考，不構成任何投資建議**。

所有數據來源自臺灣證券交易所及證券櫃檯買賣中心官方開放資料，由設備本地端運算，不上傳任何個人資料至任何伺服器。

投資涉及風險，請依自身財務狀況與判斷審慎操作，本 App 開發者不負擔任何因使用本工具而導致之投資損失責任。

---

*使用 [Flutter](https://flutter.dev) 開發 ・ 資料來源 [TWSE 開放資料](https://opendata.twse.com.tw) / [TPEX 開放資料](https://www.tpex.org.tw/openapi)*
