// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package:tw_stock_capital_flow/data/database/app_database.dart';

// ignore_for_file: type=lint
class $CategoryHistoryTableTable extends CategoryHistoryTable
    with TableInfo<$CategoryHistoryTableTable, CategoryHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<DateTime> tradeDate = GeneratedColumn<DateTime>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hotScoreMeta = const VerificationMeta(
    'hotScore',
  );
  @override
  late final GeneratedColumn<double> hotScore = GeneratedColumn<double>(
    'hot_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _persistenceMeta = const VerificationMeta(
    'persistence',
  );
  @override
  late final GeneratedColumn<double> persistence = GeneratedColumn<double>(
    'persistence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trendStrengthMeta = const VerificationMeta(
    'trendStrength',
  );
  @override
  late final GeneratedColumn<double> trendStrength = GeneratedColumn<double>(
    'trend_strength',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riseCountMeta = const VerificationMeta(
    'riseCount',
  );
  @override
  late final GeneratedColumn<int> riseCount = GeneratedColumn<int>(
    'rise_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fallCountMeta = const VerificationMeta(
    'fallCount',
  );
  @override
  late final GeneratedColumn<int> fallCount = GeneratedColumn<int>(
    'fall_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCountMeta = const VerificationMeta(
    'totalCount',
  );
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
    'total_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tradeDate,
    categoryName,
    score,
    hotScore,
    persistence,
    trendStrength,
    riseCount,
    fallCount,
    totalCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_history_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryHistoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('hot_score')) {
      context.handle(
        _hotScoreMeta,
        hotScore.isAcceptableOrUnknown(data['hot_score']!, _hotScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_hotScoreMeta);
    }
    if (data.containsKey('persistence')) {
      context.handle(
        _persistenceMeta,
        persistence.isAcceptableOrUnknown(
          data['persistence']!,
          _persistenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_persistenceMeta);
    }
    if (data.containsKey('trend_strength')) {
      context.handle(
        _trendStrengthMeta,
        trendStrength.isAcceptableOrUnknown(
          data['trend_strength']!,
          _trendStrengthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trendStrengthMeta);
    }
    if (data.containsKey('rise_count')) {
      context.handle(
        _riseCountMeta,
        riseCount.isAcceptableOrUnknown(data['rise_count']!, _riseCountMeta),
      );
    } else if (isInserting) {
      context.missing(_riseCountMeta);
    }
    if (data.containsKey('fall_count')) {
      context.handle(
        _fallCountMeta,
        fallCount.isAcceptableOrUnknown(data['fall_count']!, _fallCountMeta),
      );
    } else if (isInserting) {
      context.missing(_fallCountMeta);
    }
    if (data.containsKey('total_count')) {
      context.handle(
        _totalCountMeta,
        totalCount.isAcceptableOrUnknown(data['total_count']!, _totalCountMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryHistoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryHistoryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trade_date'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      hotScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hot_score'],
      )!,
      persistence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}persistence'],
      )!,
      trendStrength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}trend_strength'],
      )!,
      riseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rise_count'],
      )!,
      fallCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fall_count'],
      )!,
      totalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_count'],
      )!,
    );
  }

  @override
  $CategoryHistoryTableTable createAlias(String alias) {
    return $CategoryHistoryTableTable(attachedDatabase, alias);
  }
}

class CategoryHistoryTableData extends DataClass
    implements Insertable<CategoryHistoryTableData> {
  final int id;
  final DateTime tradeDate;
  final String categoryName;
  final double score;
  final double hotScore;
  final double persistence;
  final double trendStrength;
  final int riseCount;
  final int fallCount;
  final int totalCount;
  const CategoryHistoryTableData({
    required this.id,
    required this.tradeDate,
    required this.categoryName,
    required this.score,
    required this.hotScore,
    required this.persistence,
    required this.trendStrength,
    required this.riseCount,
    required this.fallCount,
    required this.totalCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trade_date'] = Variable<DateTime>(tradeDate);
    map['category_name'] = Variable<String>(categoryName);
    map['score'] = Variable<double>(score);
    map['hot_score'] = Variable<double>(hotScore);
    map['persistence'] = Variable<double>(persistence);
    map['trend_strength'] = Variable<double>(trendStrength);
    map['rise_count'] = Variable<int>(riseCount);
    map['fall_count'] = Variable<int>(fallCount);
    map['total_count'] = Variable<int>(totalCount);
    return map;
  }

  CategoryHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryHistoryTableCompanion(
      id: Value(id),
      tradeDate: Value(tradeDate),
      categoryName: Value(categoryName),
      score: Value(score),
      hotScore: Value(hotScore),
      persistence: Value(persistence),
      trendStrength: Value(trendStrength),
      riseCount: Value(riseCount),
      fallCount: Value(fallCount),
      totalCount: Value(totalCount),
    );
  }

  factory CategoryHistoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryHistoryTableData(
      id: serializer.fromJson<int>(json['id']),
      tradeDate: serializer.fromJson<DateTime>(json['tradeDate']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      score: serializer.fromJson<double>(json['score']),
      hotScore: serializer.fromJson<double>(json['hotScore']),
      persistence: serializer.fromJson<double>(json['persistence']),
      trendStrength: serializer.fromJson<double>(json['trendStrength']),
      riseCount: serializer.fromJson<int>(json['riseCount']),
      fallCount: serializer.fromJson<int>(json['fallCount']),
      totalCount: serializer.fromJson<int>(json['totalCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tradeDate': serializer.toJson<DateTime>(tradeDate),
      'categoryName': serializer.toJson<String>(categoryName),
      'score': serializer.toJson<double>(score),
      'hotScore': serializer.toJson<double>(hotScore),
      'persistence': serializer.toJson<double>(persistence),
      'trendStrength': serializer.toJson<double>(trendStrength),
      'riseCount': serializer.toJson<int>(riseCount),
      'fallCount': serializer.toJson<int>(fallCount),
      'totalCount': serializer.toJson<int>(totalCount),
    };
  }

  CategoryHistoryTableData copyWith({
    int? id,
    DateTime? tradeDate,
    String? categoryName,
    double? score,
    double? hotScore,
    double? persistence,
    double? trendStrength,
    int? riseCount,
    int? fallCount,
    int? totalCount,
  }) => CategoryHistoryTableData(
    id: id ?? this.id,
    tradeDate: tradeDate ?? this.tradeDate,
    categoryName: categoryName ?? this.categoryName,
    score: score ?? this.score,
    hotScore: hotScore ?? this.hotScore,
    persistence: persistence ?? this.persistence,
    trendStrength: trendStrength ?? this.trendStrength,
    riseCount: riseCount ?? this.riseCount,
    fallCount: fallCount ?? this.fallCount,
    totalCount: totalCount ?? this.totalCount,
  );
  CategoryHistoryTableData copyWithCompanion(
    CategoryHistoryTableCompanion data,
  ) {
    return CategoryHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      score: data.score.present ? data.score.value : this.score,
      hotScore: data.hotScore.present ? data.hotScore.value : this.hotScore,
      persistence: data.persistence.present
          ? data.persistence.value
          : this.persistence,
      trendStrength: data.trendStrength.present
          ? data.trendStrength.value
          : this.trendStrength,
      riseCount: data.riseCount.present ? data.riseCount.value : this.riseCount,
      fallCount: data.fallCount.present ? data.fallCount.value : this.fallCount,
      totalCount: data.totalCount.present
          ? data.totalCount.value
          : this.totalCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryHistoryTableData(')
          ..write('id: $id, ')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('score: $score, ')
          ..write('hotScore: $hotScore, ')
          ..write('persistence: $persistence, ')
          ..write('trendStrength: $trendStrength, ')
          ..write('riseCount: $riseCount, ')
          ..write('fallCount: $fallCount, ')
          ..write('totalCount: $totalCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tradeDate,
    categoryName,
    score,
    hotScore,
    persistence,
    trendStrength,
    riseCount,
    fallCount,
    totalCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryHistoryTableData &&
          other.id == this.id &&
          other.tradeDate == this.tradeDate &&
          other.categoryName == this.categoryName &&
          other.score == this.score &&
          other.hotScore == this.hotScore &&
          other.persistence == this.persistence &&
          other.trendStrength == this.trendStrength &&
          other.riseCount == this.riseCount &&
          other.fallCount == this.fallCount &&
          other.totalCount == this.totalCount);
}

class CategoryHistoryTableCompanion
    extends UpdateCompanion<CategoryHistoryTableData> {
  final Value<int> id;
  final Value<DateTime> tradeDate;
  final Value<String> categoryName;
  final Value<double> score;
  final Value<double> hotScore;
  final Value<double> persistence;
  final Value<double> trendStrength;
  final Value<int> riseCount;
  final Value<int> fallCount;
  final Value<int> totalCount;
  const CategoryHistoryTableCompanion({
    this.id = const Value.absent(),
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.score = const Value.absent(),
    this.hotScore = const Value.absent(),
    this.persistence = const Value.absent(),
    this.trendStrength = const Value.absent(),
    this.riseCount = const Value.absent(),
    this.fallCount = const Value.absent(),
    this.totalCount = const Value.absent(),
  });
  CategoryHistoryTableCompanion.insert({
    this.id = const Value.absent(),
    required DateTime tradeDate,
    required String categoryName,
    required double score,
    required double hotScore,
    required double persistence,
    required double trendStrength,
    required int riseCount,
    required int fallCount,
    required int totalCount,
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       score = Value(score),
       hotScore = Value(hotScore),
       persistence = Value(persistence),
       trendStrength = Value(trendStrength),
       riseCount = Value(riseCount),
       fallCount = Value(fallCount),
       totalCount = Value(totalCount);
  static Insertable<CategoryHistoryTableData> custom({
    Expression<int>? id,
    Expression<DateTime>? tradeDate,
    Expression<String>? categoryName,
    Expression<double>? score,
    Expression<double>? hotScore,
    Expression<double>? persistence,
    Expression<double>? trendStrength,
    Expression<int>? riseCount,
    Expression<int>? fallCount,
    Expression<int>? totalCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (score != null) 'score': score,
      if (hotScore != null) 'hot_score': hotScore,
      if (persistence != null) 'persistence': persistence,
      if (trendStrength != null) 'trend_strength': trendStrength,
      if (riseCount != null) 'rise_count': riseCount,
      if (fallCount != null) 'fall_count': fallCount,
      if (totalCount != null) 'total_count': totalCount,
    });
  }

  CategoryHistoryTableCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? tradeDate,
    Value<String>? categoryName,
    Value<double>? score,
    Value<double>? hotScore,
    Value<double>? persistence,
    Value<double>? trendStrength,
    Value<int>? riseCount,
    Value<int>? fallCount,
    Value<int>? totalCount,
  }) {
    return CategoryHistoryTableCompanion(
      id: id ?? this.id,
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      score: score ?? this.score,
      hotScore: hotScore ?? this.hotScore,
      persistence: persistence ?? this.persistence,
      trendStrength: trendStrength ?? this.trendStrength,
      riseCount: riseCount ?? this.riseCount,
      fallCount: fallCount ?? this.fallCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tradeDate.present) {
      map['trade_date'] = Variable<DateTime>(tradeDate.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (hotScore.present) {
      map['hot_score'] = Variable<double>(hotScore.value);
    }
    if (persistence.present) {
      map['persistence'] = Variable<double>(persistence.value);
    }
    if (trendStrength.present) {
      map['trend_strength'] = Variable<double>(trendStrength.value);
    }
    if (riseCount.present) {
      map['rise_count'] = Variable<int>(riseCount.value);
    }
    if (fallCount.present) {
      map['fall_count'] = Variable<int>(fallCount.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('score: $score, ')
          ..write('hotScore: $hotScore, ')
          ..write('persistence: $persistence, ')
          ..write('trendStrength: $trendStrength, ')
          ..write('riseCount: $riseCount, ')
          ..write('fallCount: $fallCount, ')
          ..write('totalCount: $totalCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoryHistoryTableTable categoryHistoryTable =
      $CategoryHistoryTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [categoryHistoryTable];
}

typedef $$CategoryHistoryTableTableCreateCompanionBuilder =
    CategoryHistoryTableCompanion Function({
      Value<int> id,
      required DateTime tradeDate,
      required String categoryName,
      required double score,
      required double hotScore,
      required double persistence,
      required double trendStrength,
      required int riseCount,
      required int fallCount,
      required int totalCount,
    });
typedef $$CategoryHistoryTableTableUpdateCompanionBuilder =
    CategoryHistoryTableCompanion Function({
      Value<int> id,
      Value<DateTime> tradeDate,
      Value<String> categoryName,
      Value<double> score,
      Value<double> hotScore,
      Value<double> persistence,
      Value<double> trendStrength,
      Value<int> riseCount,
      Value<int> fallCount,
      Value<int> totalCount,
    });

class $$CategoryHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryHistoryTableTable> {
  $$CategoryHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hotScore => $composableBuilder(
    column: $table.hotScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get persistence => $composableBuilder(
    column: $table.persistence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get trendStrength => $composableBuilder(
    column: $table.trendStrength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get riseCount => $composableBuilder(
    column: $table.riseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fallCount => $composableBuilder(
    column: $table.fallCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryHistoryTableTable> {
  $$CategoryHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hotScore => $composableBuilder(
    column: $table.hotScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get persistence => $composableBuilder(
    column: $table.persistence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get trendStrength => $composableBuilder(
    column: $table.trendStrength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get riseCount => $composableBuilder(
    column: $table.riseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fallCount => $composableBuilder(
    column: $table.fallCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryHistoryTableTable> {
  $$CategoryHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get hotScore =>
      $composableBuilder(column: $table.hotScore, builder: (column) => column);

  GeneratedColumn<double> get persistence => $composableBuilder(
    column: $table.persistence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get trendStrength => $composableBuilder(
    column: $table.trendStrength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get riseCount =>
      $composableBuilder(column: $table.riseCount, builder: (column) => column);

  GeneratedColumn<int> get fallCount =>
      $composableBuilder(column: $table.fallCount, builder: (column) => column);

  GeneratedColumn<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => column,
  );
}

class $$CategoryHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryHistoryTableTable,
          CategoryHistoryTableData,
          $$CategoryHistoryTableTableFilterComposer,
          $$CategoryHistoryTableTableOrderingComposer,
          $$CategoryHistoryTableTableAnnotationComposer,
          $$CategoryHistoryTableTableCreateCompanionBuilder,
          $$CategoryHistoryTableTableUpdateCompanionBuilder,
          (
            CategoryHistoryTableData,
            BaseReferences<
              _$AppDatabase,
              $CategoryHistoryTableTable,
              CategoryHistoryTableData
            >,
          ),
          CategoryHistoryTableData,
          PrefetchHooks Function()
        > {
  $$CategoryHistoryTableTableTableManager(
    _$AppDatabase db,
    $CategoryHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CategoryHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> hotScore = const Value.absent(),
                Value<double> persistence = const Value.absent(),
                Value<double> trendStrength = const Value.absent(),
                Value<int> riseCount = const Value.absent(),
                Value<int> fallCount = const Value.absent(),
                Value<int> totalCount = const Value.absent(),
              }) => CategoryHistoryTableCompanion(
                id: id,
                tradeDate: tradeDate,
                categoryName: categoryName,
                score: score,
                hotScore: hotScore,
                persistence: persistence,
                trendStrength: trendStrength,
                riseCount: riseCount,
                fallCount: fallCount,
                totalCount: totalCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime tradeDate,
                required String categoryName,
                required double score,
                required double hotScore,
                required double persistence,
                required double trendStrength,
                required int riseCount,
                required int fallCount,
                required int totalCount,
              }) => CategoryHistoryTableCompanion.insert(
                id: id,
                tradeDate: tradeDate,
                categoryName: categoryName,
                score: score,
                hotScore: hotScore,
                persistence: persistence,
                trendStrength: trendStrength,
                riseCount: riseCount,
                fallCount: fallCount,
                totalCount: totalCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryHistoryTableTable,
      CategoryHistoryTableData,
      $$CategoryHistoryTableTableFilterComposer,
      $$CategoryHistoryTableTableOrderingComposer,
      $$CategoryHistoryTableTableAnnotationComposer,
      $$CategoryHistoryTableTableCreateCompanionBuilder,
      $$CategoryHistoryTableTableUpdateCompanionBuilder,
      (
        CategoryHistoryTableData,
        BaseReferences<
          _$AppDatabase,
          $CategoryHistoryTableTable,
          CategoryHistoryTableData
        >,
      ),
      CategoryHistoryTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoryHistoryTableTableTableManager get categoryHistoryTable =>
      $$CategoryHistoryTableTableTableManager(_db, _db.categoryHistoryTable);
}
