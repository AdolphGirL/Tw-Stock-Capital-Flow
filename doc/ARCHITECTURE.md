# Tw Stock Capital Flow Architecture

## Current Structure

```text
lib
│
├─ core
│  ├─ constants
│  ├─ extensions
│  ├─ navigation
│  └─ utils
│
├─ data
│  ├─ database
│  ├─ managers
│  ├─ models
│  ├─ repositories
│  └─ services
│
├─ domain
│  ├─ engines
│  ├─ enums
│  ├─ models
│  └─ usecases
│
└─ presentation
   ├─ pages
   ├─ widgets
   ├─ models
   ├─ theme
   └─ viewmodels
```

---

## Layer Responsibility

### core

通用功能

- Constants
- Extensions
- Utils
- Navigation

不得依賴其他 Layer

---

### data

資料來源

包含：

- Database
- API
- Cache
- Storage

負責：

- 讀取資料
- 保存資料

不負責商業邏輯

---

### domain

系統核心

目前：

```text
capital_flow_engine
mainstream_engine
lifecycle_engine
rotation_engine
market_sentiment_engine
```

未來新增：

```text
analytics
backtest
prediction
```

所有核心演算法放置於此

---

### presentation

UI 顯示

包含：

- Pages
- Widgets
- ViewModels

不得直接操作 Database