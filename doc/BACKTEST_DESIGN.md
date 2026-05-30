# Backtest Design

## Goal

驗證資金流策略是否有效

---

# Input

History Database

包含：

- Category History
- Mainstream History
- Lifecycle History
- Rotation History

---

# Strategy

範例：

```dart
Lifecycle == Emerging

&&

Persistence > 60

&&

TrendStrength > 80
```

---

# Trade Flow

```text
Signal
 ↓
Open Position
 ↓
Hold
 ↓
Close Position
 ↓
Statistics
```

---

# Core Models

## Strategy

```dart
abstract class Strategy
```

---

## Signal

```dart
Buy
Sell
Hold
```

---

## Position

```dart
stockCode

entryDate

entryPrice

exitDate

exitPrice
```

---

## TradeRecord

```dart
profit

holdingDays
```

---

## BacktestResult

```dart
winRate

avgProfit

maxDrawdown

annualReturn

sharpeRatio

profitFactor
```

---

# Future

Version 2

支援：

- 多策略比較
- 參數優化
- Walk Forward Test