# Database Design

Database:

```text
SQLite
+
Drift
```

Database File:

```text
capital_flow.db
```

---

# Table : category_history

用途：

保存每日產業快照

```sql
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

Primary Key：

```text
tradeDate
categoryName
```

---

# Table : mainstream_history

用途：

保存每日主流排行

```sql
tradeDate

categoryName

rankNo

score
```

---

# Table : lifecycle_history

用途：

保存每日生命週期

```sql
tradeDate

categoryName

stage
```

---

# Table : rotation_history

用途：

保存每日輪動

```sql
tradeDate

fromCategory

toCategory

score
```

---

# Version Plan

Version 1

- category_history

Version 2

- mainstream_history

Version 3

- lifecycle_history

Version 4

- rotation_history