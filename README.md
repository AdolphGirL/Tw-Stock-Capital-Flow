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
   - [三大法人籌碼與歷史流向圖](#三大法人籌碼與歷史流向圖)
   - [板塊走勢互動圖](#板塊走勢互動圖)
   - [多週期訊號確認](#多週期訊號確認)
   - [個股掃描器](#個股掃描器)
3. [鑽入導覽](#鑽入導覽drill-down)
4. [核心演算引擎](#核心演算引擎)
   - [CapitalFlowEngine](#1-capitalflowengine--個股資金流引擎)
   - [MainstreamEngine](#2-mainstreamengine--主流方向引擎)
   - [TrendMetricsEngine](#3-trendmetricsengine--趨勢指標引擎)
   - [LifecycleEngine](#4-lifecycleengine--生命週期引擎)
   - [MomentumStrategy](#5-momentumstrategy--動量決策策略)
   - [RotationEngine](#6-rotationengine--輪動引擎)
   - [RotationLeadingAnalyser](#7-rotationleadinganalyser--領先分析器)
   - [MarketSentimentEngine](#8-marketsentimentengine--市場情緒引擎)
   - [AnomalyDetector](#9-anomalydetector--異常偵測z-score)
   - [MultiTimeframeConfirmBadge](#10-multitimeframeconfigmbadge--多週期訊號確認演算)
   - [StockScanner](#11-stockscanner--個股掃描器演算)
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
- 三大法人今日買超還是賣超？近30日累積流向如何？
- 今日訊號與近週趨勢是否方向一致？

本 App 透過多個量化引擎，從多個維度同時計算，並以語意化標籤、顏色徽章、互動圖表呈現給一般受眾，取代讓人看不懂的裸數字。

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
- 詳見 [三大法人籌碼與歷史流向圖](#三大法人籌碼與歷史流向圖) 章節

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
| 🟢 BUY（買進） | 點火期+熱錢流入+正加速；或擴散/主升期+熱錢+高共振擴散度≥50% |
| 🟡 HOLD（續抱） | 熱錢仍在+延續力≥40，尚未達加碼條件 |
| 🔴 SELL（出清） | 結構性（出貨/退潮/死亡期）；或熱錢撤+延續力<40雙殺 |
| ⚪ 觀望 | 盤整期 / 訊號不明確 |

**每張卡片包含：**
- 板塊名稱 + 生命週期標籤 + ⭐ 星號收藏
- vs 昨日資金流比較徽章（▲/▼）、3日趨勢方向標記
- **多週期確認徽章**（✅ 週期確認 / ⚠️ 逆週線 / 週線降溫）
- 4個語意化指標徽章：趨勢動能 / 延續力 / 熱錢狀態 / 擴散度進度條
- SQLite 歷史比較徽章（▲/▼ 較昨日 / vs N日均 / 連升跌N日）
- ⚠️ 資金背離警告（SELL 訊號但資金熱區仍有流入）
- 白話操盤指南說明

---

### 領先雷達 (Tab 3)

透過輪動淨動能指數（RNM）辨識「股價還在底部、但主力已悄悄建倉」的潛力板塊。

**訊號評級**

| 評級 | RNM 條件 | 說明 |
|------|----------|------|
| 🟢 強力吸籌 | RNM ≥ 45 且流入來源板塊數 ≥ 2 | 多方資金同時灌入，高勝率埋伏點 |
| 🍏 溫和流入 | RNM > 15 | 資金穩步潛伏，可加入自選股關注 |
| ⚪ 中性觀望 | −15 ≤ RNM ≤ 15 | 無明顯資金搬移傾向 |
| 🟠 派發風險 | RNM < −15 | 主力高檔逐步派發籌碼 |
| 🔴 大量出逃 | RNM ≤ −45 | 資金不計成本被抽走，建議清倉 |

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

### 三大法人籌碼與歷史流向圖

首頁卡片，顯示三大法人（外資 / 投信 / 自營商）當日買賣超金額，以及最近 30 日的每日淨流向長條圖。

**資料來源**  
直接呼叫 TWSE 法人買賣超 API（`BFI82U`），不依賴第三方服務。

**分組規則**

| 分組 | 組成來源 |
|------|----------|
| 外資 | 外資及陸資（不含外資自營商）+ 外資自營商 |
| 投信 | 投信 |
| 自營商 | 自營商（自行買賣）+ 自營商（避險） |
| 三大合計 | API 合計行（與 TWSE 官方一致） |

**今日數字顯示**
- 三欄並排：名稱 + 差額（億元，**紅=買超 / 綠=賣超**）+ 買進億 + 賣出億
- 底部合計行：三大合計買超/賣超總額
- 卡片右上角顯示交易日期標籤

**30日歷史流向圖**
- 每次成功取得當日法人數據後，自動存入本地 JSON 歷史檔，最多保留 30 筆
- 歷史資料滿 2 筆後，在今日數字下方顯示互動長條圖
- 四個分頁切換：外資 / 投信 / 自營商 / 合計
- 長條顏色：正值（買超）紅色、負值（賣超）綠色（台股慣例）
- 右上角即時顯示所選期間累積買超金額
- 觸碰任意長條 → Tooltip 顯示日期與精確金額（億元）
- 累積走向圖亦可在板塊細類頁的走勢圖中查看

**技術設計**
- 歷史以 JSON 檔（`institutional_flow_history.json`）儲存於本地 daily 目錄，不受快照清理影響
- 民國年日期（`YYYMMDD`，7碼）自動轉換為西元年（`YYYYMMDD`，8碼）
- **Fallback 機制**：若當日無資料（非交易日 / 週末），自動往前找最多 5 個日曆日

---

### 板塊走勢互動圖

在任何細類板塊頁面（SubCategoryPage）頂部，顯示近30日互動折線圖。

**支援5種指標即時切換：**

| 指標 | 欄位 | 說明 |
|------|------|------|
| 趨勢強度 | `trendStrength` | 多日複合指標，反映板塊中期強弱 |
| 資金流分 | `score` | 當日資金流原始分數 |
| 持續力 | `persistence` | 主力持倉延續強度 |
| 上漲占比% | `riseCount/totalCount×100` | 板塊個股多空廣度 |
| 累積走向 | `Σ trendStrength` | trendStrength 的累積加總，觀察中期方向漂移 |

**互動功能：**
- 點觸折線任意點 → Tooltip 顯示月/日 + 精確數值
- 正值顯示紅線（台股慣例），負值顯示綠線
- 數值跨越正負時自動顯示零軸虛線參考
- 資料不足時降級顯示今日多空分佈圓餅圖

---

### 多週期訊號確認

整合在動量決策每張信號卡片中，以**非同步徽章**方式呈現。

**背景說明**

交易者常犯的錯誤是只看「今日」訊號就進場。多週期確認的目的，是要求「短周期訊號」與「中周期趨勢」方向一致，才算高勝率進場點。

| 訊號 | 顏色 | 意義 |
|------|------|------|
| ✅ 週期確認 | 綠色 | BUY 訊號 + 近週趨勢向上，雙週期共振，高勝率進場 |
| ⚠️ 逆週線 | 琥珀色 | BUY 訊號 + 近週趨勢仍在走弱，今日訊號可能為短線反彈 |
| 週線降溫 | 橘色 | HOLD 訊號 + 近週趨勢惡化，持股需注意中期趨勢在轉弱 |

演算細節見 [MultiTimeframeConfirmBadge 章節](#10-multitimeframeconfigmbadge--多週期訊號確認演算)。

---

### 個股掃描器

整合在細類板塊頁（SubCategoryPage）的**板塊個股排行**卡片內。

**掃描三重準則**

| 準則 | 判斷方式 | 意義 |
|------|---------|------|
| 今日上漲 | `changePercent > 0` | 當天方向向上 |
| 強收（收盤位置 ≥ 70%） | `(close − low) / (high − low) ≥ 0.7` | 收盤靠近當日高點，尾盤強勢買盤支撐 |
| 日內向上 | `close > open` | 盤中買方主導，非開高走低的陷阱型上漲 |

**顯示規則**
- 每支強勢股（changePercent > 0）下方顯示「強收/弱收 XX%」與「日內 ±XX%」兩個掃描指標
- 同時通過三重準則的個股：顯示綠色「掃描命中」標籤 + 綠色邊框
- 排行標題列顯示「掃描命中 N 檔」計數徽章

演算細節見 [StockScanner 章節](#11-stockscanner--個股掃描器演算)。

---

## 鑽入導覽（Drill-down）

```
大類股列表（MainCategoryPage）
    ↓ 點擊板塊
細類股列表（SubCategoryPage）
    ├── 頂部：30日互動走勢圖（fl_chart，5種指標）
    ├── 中段：板塊個股排行 + 個股掃描器
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

### 1. CapitalFlowEngine — 個股資金流引擎

計算每支個股的今日資金流分數，作為板塊層級計算的原子輸入。

**輸入**：最近 N 天個股快照（`List<StockDaySnapshot>`）  
**輸出**：`FlowSignal`（分數、量比、動能分、延續分、方向）

```
── 成交量比（volumeRatio）──────────────────────────────────────────
volumeRatio = today.value / avg(N-day value)

── 動能分數（momentumScore）────────────────────────────────────────
volatility   = (high − low) / close × 100        // 日內振幅
momentumScore = changePercent × 0.7 + volatility × 0.3

── 延續分數（persistenceScore）────────────────────────────────────
positiveDays  = 歷史中 changePercent > 0 的天數
persistenceScore = today.changePercent × (positiveDays / totalDays)

── 綜合資金流分數（flowScore）──────────────────────────────────────
flowScore = volumeRatio × 0.35
          + momentumScore × 0.40
          + persistenceScore × 0.25

── 流向判定 ───────────────────────────────────────────────────────
direction = flowScore > 1  → inflow
            flowScore < -1 → outflow
            else           → neutral
```

---

### 2. MainstreamEngine — 主流方向引擎

將個股資料聚合至**板塊層級**，計算板塊的主流資金強度分數。

**輸入**：最近 N 天快照（至少 3 天才計算延續力）  
**輸出**：`MainstreamResult`（主流分數、各子分、強弱趨勢）

```
── 資金流分（flowScore）—— 今日板塊加權平均 ──────────────────────
flowScore = mean( changePercent × value/億,  for each stock )

── 延續力分（persistenceScore）—— 近3日衰減加權 ───────────────────
day1_score = today board-level flowScore
day2_score = yesterday's
day3_score = day before yesterday's
persistenceScore = day1 × 0.5 + day2 × 0.3 + day3 × 0.2

── 擴散度（diffusionScore）────────────────────────────────────────
diffusionScore = riseCount / totalCount × 100   // 上漲家數佔比

── 龍頭股分（leaderScore）————成交值最大個股 ───────────────────────
leaderScore = leader.value/億 × 0.6 + leader.changePercent × 0.4

── 綜合主流分（mainstreamScore）────────────────────────────────────
mainstreamScore = flowScore × 0.35
                + persistenceScore × 0.30
                + diffusionScore × 0.20
                + leaderScore × 0.15

── 熱錢判定 ────────────────────────────────────────────────────────
hotMoneyIn = flowScore > 0 AND diffusionScore > 45
```

> `strengthening = persistenceScore > 0 AND flowScore > 0`  
> `weakening     = persistenceScore < 0 AND flowScore < 0`

---

### 3. TrendMetricsEngine — 趨勢指標引擎

對任意時序數列（分數序列、流量序列、擴散序列）計算四個趨勢特徵，供 LifecycleEngine 使用。

```
values = [v₀, v₁, ..., vₙ]  // 由舊到新

── 斜率（slope）= 頭尾差 ──────────────────────────────────────────
slope = vₙ − v₀

── 加速度（acceleration）= 後段加速 − 前段加速 ────────────────────
mid          = values[n ÷ 2]
acceleration = (vₙ − mid) − (mid − v₀)
  // 正值：加速上升；負值：加速下跌；近零：等速或盤整

── 波動度（volatility）= 平均絕對偏差 ─────────────────────────────
avg        = mean(values)
volatility = mean( |vᵢ − avg| )

── 穩定度（stability）= 波動度的反轉 ──────────────────────────────
stability = 100 − volatility
```

---

### 4. LifecycleEngine — 生命週期引擎

對每個板塊建立3條時間序列（分數/流量/擴散），再透過 TrendMetricsEngine 取得趨勢特徵，最後依規則判定所屬生命週期階段。

**8個階段的判斷優先序與閾值**（由高優先到低）：

| 優先 | 階段 | 判斷條件 |
|------|------|----------|
| 1 | 死亡 (Dead) | mainstreamScore < 10 AND scoreTrend.slope < 0 AND flowScore < 0 |
| 2 | 退潮 (Decline) | scoreTrend.slope < 0 AND acceleration < 0 AND flowScore < 0 |
| 3 | 出貨 (Distribution) | mainstreamScore > 70 AND acceleration < 0 AND volatility > 15 |
| 4 | 狂熱 (Euphoric) | mainstreamScore > 85 AND diffusion > 75 AND volatility > 20 |
| 5 | 主升 (Markup) | mainstreamScore > 60 AND slope > 20 AND stability > 70 AND volatility < 18 |
| 6 | 擴散 (Expansion) | diffusion > 45 AND slope > 10 AND flowTrend.slope > 0 |
| 7 | 點火 (Ignition) | acceleration > 5 OR flowTrend.acceleration > 0 |
| 8 | 盤整 (Consolidation) | （以上條件皆不符）|

> 注意：`acceleration` 與 `slope` 均來自 `scoreTrend`（分數時序），`flowTrend.slope` 來自流量時序。  
> `stability` 與 `volatility` 均來自 `scoreTrend`。

---

### 5. MomentumStrategy — 動量決策策略

對每個 `LifecycleResult` 依固定優先序評估，輸出 BUY / HOLD / SELL / NEUTRAL 四種訊號與白話說明。

```
① 結構性 SELL（最高優先，無條件出清）
   stage ∈ {distribution, decline, dead}

② BUY — 點火試單
   stage == ignition AND hotMoneyIn AND acceleration > 0

③ BUY — 主升全面加碼
   stage ∈ {expansion, markup} AND hotMoneyIn AND diffusion ≥ 50.0

④ HOLD — 鎖籌續抱
   hotMoneyIn AND persistence ≥ 40.0
   (狂熱期允許持股，但禁止追高)

⑤ SELL — 動能渙散（雙殺條件，避免過度敏感）
   !hotMoneyIn AND persistence < 40.0

⑥ NEUTRAL — 盤整觀望（以上條件皆不符）
```

> 關鍵設計原則：SELL 訊號需要**兩項指標同時惡化**（熱錢撤 + 延續力低），單純缺乏熱錢但延續力尚可，只觸發 NEUTRAL，避免在橫盤整理時誤殺部位。

---

### 6. RotationEngine — 輪動引擎

比較今日與昨日各板塊資金流分，計算資金在板塊間的搬移路徑，輸出輪動配對清單。

```
── 各板塊資金流分 ────────────────────────────────────────────────
categoryScore = mean( changePercent × value/億, for each stock )

── 資金增減 ───────────────────────────────────────────────────────
diff = todayScore − yesterdayScore
diff > 0 → 流入板塊 (increases)
diff < 0 → 流出板塊 (decreases)

── 輪動強度（rotationScore）────────────────────────────────────────
rotationScore = ( |outflow_diff| + |inflow_diff| ) / 2

輸出：流出板塊 → 流入板塊 的配對，附帶輪動強度與流入強度
```

---

### 7. RotationLeadingAnalyser — 領先分析器

彙總所有輪動路徑，計算每個板塊的**淨輪動動能（RNM）**，並輸出領先訊號評級。

```
── 累加每個板塊的流入 / 流出總量 ────────────────────────────────
inflowSum  = Σ rotationScore（此板塊為流入方的所有輪動）
outflowSum = Σ rotationScore（此板塊為流出方的所有輪動）
feederCount = 有多少個不同板塊正在向此板塊輸血

── 淨輪動動能 (Net Rotation Momentum, RNM) ─────────────────────
RNM = inflowSum − outflowSum

── 訊號評級閾值 ─────────────────────────────────────────────────
RNM ≥ 45 AND feederCount ≥ 2 → 🟢 強力吸籌（多源同時輸血）
RNM > 15                      → 🍏 溫和流入
−15 ≤ RNM ≤ 15               → ⚪ 中性觀望
RNM < −15                     → 🟠 派發風險
RNM ≤ −45                     → 🔴 大量出逃
```

> 強力吸籌需要 `feederCount ≥ 2` 的設計，是為了排除「單一大板塊資金搬移」造成的假訊號，確保是多源同時灌入的真實吸籌行為。

---

### 8. MarketSentimentEngine — 市場情緒引擎

從全市場個股計算熱錢強度，加上板塊層面的強弱計數，輸出綜合情緒分數與等級。

```
── 熱錢強度（hotMoneyStrength）────────────────────────────────────
hotMoneyStrength = mean( value/億 × changePercent, for each stock )

── 情緒分數（score）────────────────────────────────────────────────
score = riseRatio × 30
      + strongCategoryCount × 8       // mainstreamScore > 30 的板塊數
      + mainstreamAverage × 0.35
      + hotMoneyStrength × 0.25

── 情緒等級 ────────────────────────────────────────────────────────
score ≥ 85 → 過熱警惕 (Euphoric)
score ≥ 65 → 資金樂觀 (Optimistic)
score ≥ 40 → 中性觀望 (Neutral)
score ≥ 20 → 偏空悲觀 (Weak)
score < 20 → 市場恐慌 (Panic)
```

---

### 9. AnomalyDetector — 異常偵測（Z-score）

對每個板塊的 `trendStrength` 計算 Z-score，識別在歷史基準上統計顯著異常的板塊。

```
── 統計參數 ───────────────────────────────────────────────────────
μ = mean( trendStrength, 最近 N 天 )
σ = std( trendStrength, 最近 N 天 )

── Z-score ────────────────────────────────────────────────────────
Z = ( today_trendStrength − μ ) / σ

── 異常閾值 ───────────────────────────────────────────────────────
Z > +0.8  → 異常資金湧入（取前 8 名）
Z < −0.8  → 異常資金流出（取前 8 名）

最少樣本需求：≥ 5 天（不足則跳過該板塊）
最大回溯窗口：35 天
```

---

### 10. MultiTimeframeConfirmBadge — 多週期訊號確認演算

整合在每張動量決策信號卡片中，以非同步 `FutureBuilder` 載入資料後渲染。

**為什麼需要多週期確認？**

`MomentumStrategy` 的訊號是「今日截面」計算，只反映當天的動能狀態。若只看今日強，卻忽略近一週整體在走弱，進場勝率會大幅降低。多週期確認要求「短周期訊號」與「中周期趨勢」同向，才算高品質進場點。

**兩個週期的定義**

| 周期 | 資料 | 代表意義 |
|------|------|---------|
| 短周期（日線） | `StrategyAction`，今日 `MomentumStrategy.evaluate()` 結果 | 今天板塊資金動能狀態 |
| 中周期（週線） | 近 5 日 `trendStrength` 序列 | 近一週板塊健康度趨勢方向 |

**演算邏輯**

```
scores = getCategoryTrend(limit: 5)
         → List<trendStrength>，由舊到新，index 0 = 最舊

n = scores.length  （需 ≥ 4 才觸發，不足則不顯示徽章）

recentAvg = ( scores[n-1] + scores[n-2] ) / 2     // 最近 2 日均值
olderAvg  = mean( scores[0 .. n-3] )              // 較早各日均值

weeklyUp  = recentAvg > olderAvg                   // 近週方向向上？

── 徽章判斷 ────────────────────────────────────────────────────────
action == BUY  AND  weeklyUp   → ✅ 週期確認（雙週期共振，高勝率）
action == BUY  AND !weeklyUp   → ⚠️ 逆週線  （今日強，但近週仍弱）
action == HOLD AND !weeklyUp   → 週線降溫   （持股注意趨勢惡化）
action == HOLD AND  weeklyUp   → （不顯示，無需提醒）
action == SELL / NEUTRAL       → （不顯示）
```

**交易意義**

- `✅ 週期確認`：兩個周期同向，進場的結構最乾淨，相對安全
- `⚠️ 逆週線`：今日訊號可能只是短線技術反彈，或主力試探盤，風險較高，應降低倉位或等更多確認
- `週線降溫`：持股需提高警覺，中期趨勢在惡化，提前設好停損點

**當前侷限**

目前以「近 2 日均值 vs 較早均值」判斷週線方向，為滑動窗口近似，並非嚴格對齊交易週（週一到週五）。可後續優化的方向：加入最小差距門檻（如差距 < 1.0 視為無明確方向）、延長至 10/20 日做三重確認。

---

### 11. StockScanner — 個股掃描器演算

整合在細類板塊頁的個股排行卡片，以純日內資料（不需歷史快照）即時計算。

**為什麼用這三個準則？**

| 準則 | 數據 | 排除的假訊號 |
|------|------|------------|
| `changePercent > 0` | 今日漲跌幅 | 排除下跌日的虛假技術形態 |
| `closePosition ≥ 0.70` | 收盤在日內高低區間的位置 | 排除「開高走低」的上影線陷阱型個股 |
| `close > open` | 日內漲跌（盤中方向） | 排除「昨高今缺口低開」造成的假漲 |

**演算公式**

```
range         = high − low
closePosition = (close − low) / range       // 值域 0~1
intradayReturn = (close − open) / open × 100  // 日內漲跌%

掃描命中 = changePercent > 0
         AND closePosition ≥ 0.7
         AND intradayReturn > 0
```

**顯示邏輯**

- 每支強勢股下方顯示兩個掃描指標徽章：
  - `強收 XX%` / `弱收 XX%`：收盤位置，≥ 70% 為紅色，否則灰色
  - `日內 +XX%` / `日內 −XX%`：日內漲跌，正值紅色，負值灰色
- 同時通過三重準則：綠色「掃描命中」標籤 + 卡片綠色邊框
- 排行標題列同步顯示「掃描命中 N 檔」計數

**侷限與後續方向**

當前掃描器為純日內準則，無跨日比較。後續可加入：量比（今日成交量 / N日均量）作為第四條件，進一步篩選帶量突破的高動能個股。

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

**JSON 本地檔案（非 SQLite）：**

| 檔案 | 說明 | 保留筆數 |
|------|------|----------|
| `YYYYMMDD.json` | 每日個股快照（raw data） | 最近 7 天（自動清理） |
| `bootstrap_cache_YYYYMMDD.json` | 啟動分析結果快取（離線防禦） | 最近 3 份 |
| `institutional_flow_history.json` | 三大法人 30 日流向歷史 | 最近 30 筆 |

> `category_history` 同時作為異常偵測器的統計基礎，最多回溯 35 天歷史資料。

---

## 技術棧

| 類別 | 套件 / 技術 |
|------|-------------|
| 框架 | Flutter 3.x / Dart SDK ^3.11.5 |
| 本地資料庫 | Drift 2.28.1（SQLite ORM，響應式 Stream） |
| 圖表 | fl_chart 1.2.0（互動折線圖 + 長條圖） |
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
│   ├── history/repositories/   # CategoryHistoryRepository（SQLite）
│   ├── watchlist/repositories/ # WatchlistRepository（CRUD + Stream）
│   ├── signal/repositories/    # SignalSnapshotRepository（訊號異動比對）
│   ├── managers/               # SyncManager（資料同步排程）
│   ├── models/                 # 資料層模型
│   ├── repositories/           # HistoryRepository（本地 JSON 快照）
│   └── services/
│       ├── stock_service.dart
│       ├── storage_service.dart
│       ├── analysis_cache_service.dart
│       ├── institutional_flow_service.dart          # 三大法人 TWSE API
│       └── institutional_flow_history_service.dart  # 三大法人 30 日歷史 JSON
│
├── domain/
│   ├── engines/                # 八大演算引擎
│   │   ├── capital_flow_engine.dart      # 個股資金流引擎
│   │   ├── mainstream_engine.dart        # 主流方向引擎
│   │   ├── trend_metrics_engine.dart     # 趨勢指標引擎（slope/accel/stability）
│   │   ├── lifecycle_engine.dart         # 八期生命週期引擎
│   │   ├── rotation_engine.dart          # 板塊輪動引擎
│   │   └── market_sentiment_engine.dart  # 市場情緒引擎
│   ├── analysers/
│   │   └── rotation_leading_analyser.dart  # RNM 領先訊號分析器
│   ├── enums/                  # LifecycleStage / LeadingSignalType / SentimentLevel
│   ├── models/
│   │   ├── institutional_flow_result.dart  # 三大法人模型（含 toJson/fromJson）
│   │   └── ...其他領域模型
│   ├── services/               # SignalChangeDetector（純邏輯）
│   ├── strategies/
│   │   └── momentum_strategy.dart  # 動量決策策略（五級優先判斷樹）
│   └── usecases/               # BootstrapAnalyzer / AppBootstrapResult
│
└── presentation/
    ├── models/                 # CategoryUiModel / StockUiModel
    ├── pages/
    │   ├── home_page.dart                  # 大盤診斷（含三大法人 + 歷史流向圖）
    │   ├── main_navigation_container.dart  # 底部導覽殼層（IndexedStack）
    │   ├── anomaly_detector_page.dart      # 異常偵測器（Z-score 統計）
    │   ├── strategy_dashboard_page.dart    # 板塊動量決策（含多週期確認徽章）
    │   ├── leading_indicator_page.dart     # 輪動領先雷達
    │   ├── main_category_page.dart         # 大類板塊列表
    │   └── sub_category_page.dart          # 細類板塊 + 走勢圖 + 個股掃描器
    ├── theme/                  # AppTheme
    └── widgets/
        ├── category_card.dart
        ├── category_history_summary.dart       # 歷史比較徽章（較昨日/vs均值/連漲跌）
        ├── category_trend_chart.dart           # 30日 fl_chart 互動折線圖（5種指標）
        ├── institutional_flow_chart.dart       # 三大法人 30 日長條圖（4分頁）
        ├── market_heatmap.dart                 # 全市場資金熱力圖
        ├── market_signal_summary.dart          # 今日訊號快照面板
        ├── multi_timeframe_confirm_badge.dart  # 多週期訊號確認徽章
        ├── signal_change_dialog.dart           # 訊號異動通知 Dialog
        ├── trend_sparkline.dart                # 迷你 Sparkline
        └── watchlist_button.dart               # 星號收藏切換按鈕
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
