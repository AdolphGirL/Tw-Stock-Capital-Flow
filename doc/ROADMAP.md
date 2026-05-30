# Tw Stock Capital Flow v2 Roadmap

> 台股資金流分析平台

---

# 專案願景

建立一套以「資金流分析」為核心的台股分析平台。

不同於傳統看漲跌幅或成交量，

系統聚焦於：

- 主流族群
- 主流生命週期
- 資金輪動
- 市場情緒
- 歷史演化
- 策略回測
- 主流延續率
- 主流預測

---

# 核心分析架構

```text
股票資料
    ↓
Category Engine
    ↓
Category Score
    ↓
┌─────────────────────┐
│ Mainstream Engine   │
│ Lifecycle Engine    │
│ Rotation Engine     │
│ Sentiment Engine    │
└─────────────────────┘
    ↓
History Database
    ↓
Backtest Engine
    ↓
Analytics Engine
    ↓
Prediction Engine
```

---

# 已完成模組

## Category Aggregation

### 功能

將個股資料聚合成產業資料

### 狀態

✅ Completed

---

## CategoryUiModel

### 欄位

```dart
name

totalCount

riseCount

fallCount

score

day1Score
day2Score
day3Score

hotScore

persistence

trendStrength
```

---

### Derived Metrics

#### trendStrength

```dart
weighted =
(day1Score * 0.5)
+
(day2Score * 0.3)
+
(day3Score * 0.2)

+
acceleration
```

---

#### isStrengthening

```dart
day1 > day2
&&
day2 > day3
```

---

#### isWeakening

```dart
day1 < day2
&&
day2 < day3
```

---

#### hotLevel

```text
爆發
強勢
偏強
整理
退潮
```

---

# Mainstream Engine

### 功能

市場主流排行

### 輸出

```dart
MainstreamResult
```

### 狀態

✅ Completed

---

# Lifecycle Engine

### 功能

主流生命週期分析

### 輸出

```dart
LifecycleResult
```

### Stages

```text
Emerging
Expanding
Climax
Declining
```

### 狀態

✅ Completed

---

# Rotation Engine

### 功能

資金輪動分析

### 輸出

```dart
RotationResult
```

### 狀態

✅ Completed

---

# Market Sentiment Engine

### 功能

市場情緒分析

### 輸出

```dart
MarketSentimentResult
```

### 狀態

✅ Completed

---

# UI Layer

## HomePage

已完成：

- 市場總覽
- 上市市場
- 上櫃市場
- 市場主流
- 主流生命週期
- 市場情緒
- 資金輪動
- 熱門族群

### 狀態

✅ Completed

---

# Market Heatmap

目前版本：

```text
Grid Layout
```

### 決議

暫不使用：

```text
Syncfusion Treemap
```

### 原因

優先完成：

- History
- Backtest
- Analytics

### 狀態

⚠ Pending Upgrade

---

# 已取消架構

## JSON Snapshot

取消：

```text
MarketSnapshot
CategorySnapshot
SnapshotRepository
LocalSnapshotRepository
```

### 原因

後續需要：

- 回測
- 歷史查詢
- 統計分析

JSON 不適合作為正式資料來源

---

# 技術選型

## Database

採用：

```text
Drift
+
SQLite
```

---

# 資料庫規劃

---

# Phase 1

## Database Foundation

### AppDatabase

位置：

```text
lib/data/database
```

---

## category_history

### 目的

保存每日產業快照

---

### 欄位

```dart
tradeDate

categoryName

score

hotScore

persistence

trendStrength

riseCount

fallCount

totalCount
```

---

### Composite Primary Key

```dart
@override
Set<Column> get primaryKey => {
  tradeDate,
  categoryName,
};
```

---

### Repository

```dart
CategoryHistoryRepository
```

---

### Function

```dart
saveDailySnapshot()
```

---

### 寫入策略

```dart
insertOnConflictUpdate()
```

---

### 狀態

🚧 In Progress

---

# Phase 2

## Category History Query

### Repository

```dart
getCategoryHistory(
  String category,
)
```

---

### 用途

查詢：

```text
AI伺服器

最近30天
最近90天
最近180天
```

---

### 回傳

```dart
List<CategoryHistory>
```

---

### 狀態

❌ Not Started

---

# Phase 3

## Category History Chart

### Page

```text
CategoryHistoryPage
```

---

### 圖表

#### Hot Score Trend

```text
日期
↓
熱度
```

---

#### Trend Strength Trend

```text
日期
↓
趨勢強度
```

---

#### Persistence Trend

```text
日期
↓
持續性
```

---

### 狀態

❌ Not Started

---

# Phase 4

## Mainstream History

### Table

```text
mainstream_history
```

---

### 欄位

```dart
tradeDate

categoryName

rankNo

score
```

---

### Repository

```dart
MainstreamHistoryRepository
```

---

### 功能

歷史主流分析

---

### 範例

```text
2026-05-01

1 AI伺服器
2 CPO
3 PCB
```

---

### 狀態

❌ Not Started

---

# Phase 5

## Lifecycle History

### Table

```text
lifecycle_history
```

---

### 欄位

```dart
tradeDate

categoryName

stage
```

---

### Repository

```dart
LifecycleHistoryRepository
```

---

### 功能

生命週期歷史追蹤

---

### 範例

```text
AI伺服器

05/01 Emerging

05/03 Expanding

05/10 Climax

05/18 Declining
```

---

### 狀態

❌ Not Started

---

# Phase 6

## Rotation History

### Table

```text
rotation_history
```

---

### 欄位

```dart
tradeDate

fromCategory

toCategory

score
```

---

### Repository

```dart
RotationHistoryRepository
```

---

### 功能

歷史資金輪動分析

---

### 範例

```text
AI伺服器
↓
CPO

CPO
↓
CoWoS

CoWoS
↓
散熱
```

---

### 狀態

❌ Not Started

---

# Phase 7

## Analytics Engine

建立統計分析模組

位置：

```text
domain/analytics
```

---

### 功能

統計：

- 主流出現次數
- 主流持續天數
- 主流排名分布
- 主流轉換頻率
- 熱門族群排行

---

### 狀態

❌ Not Started

---

# Phase 8

## Backtest Engine

位置：

```text
domain/backtest
```

---

### 功能

策略驗證

---

### 範例策略

```dart
Lifecycle == Emerging

&&

Persistence > 60

&&

TrendStrength > 80
```

買進

---

### 輸出

```dart
BacktestResult
```

---

### 指標

```text
勝率

平均報酬

最大回撤

Sharpe Ratio

年化報酬率

Profit Factor
```

---

### 狀態

❌ Not Started

---

# Phase 9

## Mainstream Continuation Analysis

### 功能

分析主流延續率

---

### 範例

```text
AI伺服器

主流次數
40

隔日續強率
78%

三日續強率
72%

五日續強率
63%

十日續強率
51%
```

---

### Repository

```dart
MainstreamContinuationAnalyzer
```

---

### 狀態

❌ Not Started

---

# Phase 10

## Prediction Engine

位置：

```text
domain/prediction
```

---

### 依據

```text
Score

HotScore

TrendStrength

Persistence

Mainstream Rank

Lifecycle
```

---

### 輸出

```dart
PredictionResult
```

---

### 功能

預測：

```text
明日主流機率

未來三日主流機率

下一個接棒族群
```

---

### 範例

```text
AI伺服器

主流維持機率

89%
```

---

### 狀態

❌ Not Started

---

# 預計專案結構

```text
lib
│
├─ core
│
├─ data
│  ├─ database
│  ├─ repositories
│  └─ models
│
├─ domain
│  ├─ engines
│  ├─ analytics
│  ├─ backtest
│  └─ prediction
│
└─ presentation
   ├─ pages
   ├─ widgets
   └─ models
```

---

# Overall Progress

```text
Engine Layer
██████████ 100%

UI Layer
████████░░ 80%

Database Layer
██░░░░░░░░ 20%

History Layer
░░░░░░░░░░ 0%

Analytics Layer
░░░░░░░░░░ 0%

Backtest Layer
░░░░░░░░░░ 0%

Prediction Layer
░░░░░░░░░░ 0%
```

---

# Next Milestone

Phase 1 完成：

- AppDatabase
- Drift Setup
- category_history
- CategoryHistoryRepository

之後進入：

Phase 2

Category History Query

以及

Phase 3

Category History Chart