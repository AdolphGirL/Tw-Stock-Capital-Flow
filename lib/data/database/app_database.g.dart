// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoryHistoryTableTable extends CategoryHistoryTable
    with TableInfo<$CategoryHistoryTableTable, CategoryHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const String $name = 'category_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
  Set<GeneratedColumn> get $primaryKey => {tradeDate, categoryName};
  @override
  CategoryHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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

class CategoryHistoryData extends DataClass
    implements Insertable<CategoryHistoryData> {
  final String tradeDate;
  final String categoryName;
  final double score;
  final double hotScore;
  final double persistence;
  final double trendStrength;
  final int riseCount;
  final int fallCount;
  final int totalCount;
  const CategoryHistoryData({
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
    map['trade_date'] = Variable<String>(tradeDate);
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

  factory CategoryHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
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
      'tradeDate': serializer.toJson<String>(tradeDate),
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

  CategoryHistoryData copyWith({
    String? tradeDate,
    String? categoryName,
    double? score,
    double? hotScore,
    double? persistence,
    double? trendStrength,
    int? riseCount,
    int? fallCount,
    int? totalCount,
  }) => CategoryHistoryData(
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
  CategoryHistoryData copyWithCompanion(CategoryHistoryTableCompanion data) {
    return CategoryHistoryData(
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
    return (StringBuffer('CategoryHistoryData(')
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
      (other is CategoryHistoryData &&
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
    extends UpdateCompanion<CategoryHistoryData> {
  final Value<String> tradeDate;
  final Value<String> categoryName;
  final Value<double> score;
  final Value<double> hotScore;
  final Value<double> persistence;
  final Value<double> trendStrength;
  final Value<int> riseCount;
  final Value<int> fallCount;
  final Value<int> totalCount;
  final Value<int> rowid;
  const CategoryHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.score = const Value.absent(),
    this.hotScore = const Value.absent(),
    this.persistence = const Value.absent(),
    this.trendStrength = const Value.absent(),
    this.riseCount = const Value.absent(),
    this.fallCount = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryHistoryTableCompanion.insert({
    required String tradeDate,
    required String categoryName,
    required double score,
    required double hotScore,
    required double persistence,
    required double trendStrength,
    required int riseCount,
    required int fallCount,
    required int totalCount,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       score = Value(score),
       hotScore = Value(hotScore),
       persistence = Value(persistence),
       trendStrength = Value(trendStrength),
       riseCount = Value(riseCount),
       fallCount = Value(fallCount),
       totalCount = Value(totalCount);
  static Insertable<CategoryHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? categoryName,
    Expression<double>? score,
    Expression<double>? hotScore,
    Expression<double>? persistence,
    Expression<double>? trendStrength,
    Expression<int>? riseCount,
    Expression<int>? fallCount,
    Expression<int>? totalCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (score != null) 'score': score,
      if (hotScore != null) 'hot_score': hotScore,
      if (persistence != null) 'persistence': persistence,
      if (trendStrength != null) 'trend_strength': trendStrength,
      if (riseCount != null) 'rise_count': riseCount,
      if (fallCount != null) 'fall_count': fallCount,
      if (totalCount != null) 'total_count': totalCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? categoryName,
    Value<double>? score,
    Value<double>? hotScore,
    Value<double>? persistence,
    Value<double>? trendStrength,
    Value<int>? riseCount,
    Value<int>? fallCount,
    Value<int>? totalCount,
    Value<int>? rowid,
  }) {
    return CategoryHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      score: score ?? this.score,
      hotScore: hotScore ?? this.hotScore,
      persistence: persistence ?? this.persistence,
      trendStrength: trendStrength ?? this.trendStrength,
      riseCount: riseCount ?? this.riseCount,
      fallCount: fallCount ?? this.fallCount,
      totalCount: totalCount ?? this.totalCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('score: $score, ')
          ..write('hotScore: $hotScore, ')
          ..write('persistence: $persistence, ')
          ..write('trendStrength: $trendStrength, ')
          ..write('riseCount: $riseCount, ')
          ..write('fallCount: $fallCount, ')
          ..write('totalCount: $totalCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MainstreamHistoryTableTable extends MainstreamHistoryTable
    with TableInfo<$MainstreamHistoryTableTable, MainstreamHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MainstreamHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _rankNoMeta = const VerificationMeta('rankNo');
  @override
  late final GeneratedColumn<int> rankNo = GeneratedColumn<int>(
    'rank_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    tradeDate,
    categoryName,
    rankNo,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mainstream_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<MainstreamHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('rank_no')) {
      context.handle(
        _rankNoMeta,
        rankNo.isAcceptableOrUnknown(data['rank_no']!, _rankNoMeta),
      );
    } else if (isInserting) {
      context.missing(_rankNoMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, categoryName};
  @override
  MainstreamHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MainstreamHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      rankNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank_no'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $MainstreamHistoryTableTable createAlias(String alias) {
    return $MainstreamHistoryTableTable(attachedDatabase, alias);
  }
}

class MainstreamHistoryData extends DataClass
    implements Insertable<MainstreamHistoryData> {
  final String tradeDate;
  final String categoryName;
  final int rankNo;
  final double score;
  const MainstreamHistoryData({
    required this.tradeDate,
    required this.categoryName,
    required this.rankNo,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['category_name'] = Variable<String>(categoryName);
    map['rank_no'] = Variable<int>(rankNo);
    map['score'] = Variable<double>(score);
    return map;
  }

  MainstreamHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return MainstreamHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      categoryName: Value(categoryName),
      rankNo: Value(rankNo),
      score: Value(score),
    );
  }

  factory MainstreamHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MainstreamHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      rankNo: serializer.fromJson<int>(json['rankNo']),
      score: serializer.fromJson<double>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'categoryName': serializer.toJson<String>(categoryName),
      'rankNo': serializer.toJson<int>(rankNo),
      'score': serializer.toJson<double>(score),
    };
  }

  MainstreamHistoryData copyWith({
    String? tradeDate,
    String? categoryName,
    int? rankNo,
    double? score,
  }) => MainstreamHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    categoryName: categoryName ?? this.categoryName,
    rankNo: rankNo ?? this.rankNo,
    score: score ?? this.score,
  );
  MainstreamHistoryData copyWithCompanion(
    MainstreamHistoryTableCompanion data,
  ) {
    return MainstreamHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      rankNo: data.rankNo.present ? data.rankNo.value : this.rankNo,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MainstreamHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('rankNo: $rankNo, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tradeDate, categoryName, rankNo, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MainstreamHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.categoryName == this.categoryName &&
          other.rankNo == this.rankNo &&
          other.score == this.score);
}

class MainstreamHistoryTableCompanion
    extends UpdateCompanion<MainstreamHistoryData> {
  final Value<String> tradeDate;
  final Value<String> categoryName;
  final Value<int> rankNo;
  final Value<double> score;
  final Value<int> rowid;
  const MainstreamHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.rankNo = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MainstreamHistoryTableCompanion.insert({
    required String tradeDate,
    required String categoryName,
    required int rankNo,
    required double score,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       rankNo = Value(rankNo),
       score = Value(score);
  static Insertable<MainstreamHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? categoryName,
    Expression<int>? rankNo,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (rankNo != null) 'rank_no': rankNo,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MainstreamHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? categoryName,
    Value<int>? rankNo,
    Value<double>? score,
    Value<int>? rowid,
  }) {
    return MainstreamHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      rankNo: rankNo ?? this.rankNo,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (rankNo.present) {
      map['rank_no'] = Variable<int>(rankNo.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MainstreamHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('rankNo: $rankNo, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifecycleHistoryTableTable extends LifecycleHistoryTable
    with TableInfo<$LifecycleHistoryTableTable, LifecycleHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifecycleHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tradeDate, categoryName, stage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lifecycle_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifecycleHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, categoryName};
  @override
  LifecycleHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifecycleHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
    );
  }

  @override
  $LifecycleHistoryTableTable createAlias(String alias) {
    return $LifecycleHistoryTableTable(attachedDatabase, alias);
  }
}

class LifecycleHistoryData extends DataClass
    implements Insertable<LifecycleHistoryData> {
  final String tradeDate;
  final String categoryName;
  final String stage;
  const LifecycleHistoryData({
    required this.tradeDate,
    required this.categoryName,
    required this.stage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['category_name'] = Variable<String>(categoryName);
    map['stage'] = Variable<String>(stage);
    return map;
  }

  LifecycleHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return LifecycleHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      categoryName: Value(categoryName),
      stage: Value(stage),
    );
  }

  factory LifecycleHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifecycleHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      stage: serializer.fromJson<String>(json['stage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'categoryName': serializer.toJson<String>(categoryName),
      'stage': serializer.toJson<String>(stage),
    };
  }

  LifecycleHistoryData copyWith({
    String? tradeDate,
    String? categoryName,
    String? stage,
  }) => LifecycleHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    categoryName: categoryName ?? this.categoryName,
    stage: stage ?? this.stage,
  );
  LifecycleHistoryData copyWithCompanion(LifecycleHistoryTableCompanion data) {
    return LifecycleHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      stage: data.stage.present ? data.stage.value : this.stage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifecycleHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('stage: $stage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tradeDate, categoryName, stage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifecycleHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.categoryName == this.categoryName &&
          other.stage == this.stage);
}

class LifecycleHistoryTableCompanion
    extends UpdateCompanion<LifecycleHistoryData> {
  final Value<String> tradeDate;
  final Value<String> categoryName;
  final Value<String> stage;
  final Value<int> rowid;
  const LifecycleHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.stage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifecycleHistoryTableCompanion.insert({
    required String tradeDate,
    required String categoryName,
    required String stage,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       stage = Value(stage);
  static Insertable<LifecycleHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? categoryName,
    Expression<String>? stage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (stage != null) 'stage': stage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifecycleHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? categoryName,
    Value<String>? stage,
    Value<int>? rowid,
  }) {
    return LifecycleHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      stage: stage ?? this.stage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifecycleHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('stage: $stage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RotationHistoryTableTable extends RotationHistoryTable
    with TableInfo<$RotationHistoryTableTable, RotationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RotationHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromCategoryMeta = const VerificationMeta(
    'fromCategory',
  );
  @override
  late final GeneratedColumn<String> fromCategory = GeneratedColumn<String>(
    'from_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toCategoryMeta = const VerificationMeta(
    'toCategory',
  );
  @override
  late final GeneratedColumn<String> toCategory = GeneratedColumn<String>(
    'to_category',
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
  @override
  List<GeneratedColumn> get $columns => [
    tradeDate,
    fromCategory,
    toCategory,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rotation_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<RotationHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('from_category')) {
      context.handle(
        _fromCategoryMeta,
        fromCategory.isAcceptableOrUnknown(
          data['from_category']!,
          _fromCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCategoryMeta);
    }
    if (data.containsKey('to_category')) {
      context.handle(
        _toCategoryMeta,
        toCategory.isAcceptableOrUnknown(data['to_category']!, _toCategoryMeta),
      );
    } else if (isInserting) {
      context.missing(_toCategoryMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, fromCategory, toCategory};
  @override
  RotationHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RotationHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      fromCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_category'],
      )!,
      toCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_category'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $RotationHistoryTableTable createAlias(String alias) {
    return $RotationHistoryTableTable(attachedDatabase, alias);
  }
}

class RotationHistoryData extends DataClass
    implements Insertable<RotationHistoryData> {
  final String tradeDate;
  final String fromCategory;
  final String toCategory;
  final double score;
  const RotationHistoryData({
    required this.tradeDate,
    required this.fromCategory,
    required this.toCategory,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['from_category'] = Variable<String>(fromCategory);
    map['to_category'] = Variable<String>(toCategory);
    map['score'] = Variable<double>(score);
    return map;
  }

  RotationHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return RotationHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      fromCategory: Value(fromCategory),
      toCategory: Value(toCategory),
      score: Value(score),
    );
  }

  factory RotationHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RotationHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      fromCategory: serializer.fromJson<String>(json['fromCategory']),
      toCategory: serializer.fromJson<String>(json['toCategory']),
      score: serializer.fromJson<double>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'fromCategory': serializer.toJson<String>(fromCategory),
      'toCategory': serializer.toJson<String>(toCategory),
      'score': serializer.toJson<double>(score),
    };
  }

  RotationHistoryData copyWith({
    String? tradeDate,
    String? fromCategory,
    String? toCategory,
    double? score,
  }) => RotationHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    fromCategory: fromCategory ?? this.fromCategory,
    toCategory: toCategory ?? this.toCategory,
    score: score ?? this.score,
  );
  RotationHistoryData copyWithCompanion(RotationHistoryTableCompanion data) {
    return RotationHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      fromCategory: data.fromCategory.present
          ? data.fromCategory.value
          : this.fromCategory,
      toCategory: data.toCategory.present
          ? data.toCategory.value
          : this.toCategory,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RotationHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('fromCategory: $fromCategory, ')
          ..write('toCategory: $toCategory, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tradeDate, fromCategory, toCategory, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RotationHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.fromCategory == this.fromCategory &&
          other.toCategory == this.toCategory &&
          other.score == this.score);
}

class RotationHistoryTableCompanion
    extends UpdateCompanion<RotationHistoryData> {
  final Value<String> tradeDate;
  final Value<String> fromCategory;
  final Value<String> toCategory;
  final Value<double> score;
  final Value<int> rowid;
  const RotationHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.fromCategory = const Value.absent(),
    this.toCategory = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RotationHistoryTableCompanion.insert({
    required String tradeDate,
    required String fromCategory,
    required String toCategory,
    required double score,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       fromCategory = Value(fromCategory),
       toCategory = Value(toCategory),
       score = Value(score);
  static Insertable<RotationHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? fromCategory,
    Expression<String>? toCategory,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (fromCategory != null) 'from_category': fromCategory,
      if (toCategory != null) 'to_category': toCategory,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RotationHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? fromCategory,
    Value<String>? toCategory,
    Value<double>? score,
    Value<int>? rowid,
  }) {
    return RotationHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      fromCategory: fromCategory ?? this.fromCategory,
      toCategory: toCategory ?? this.toCategory,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (fromCategory.present) {
      map['from_category'] = Variable<String>(fromCategory.value);
    }
    if (toCategory.present) {
      map['to_category'] = Variable<String>(toCategory.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RotationHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('fromCategory: $fromCategory, ')
          ..write('toCategory: $toCategory, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoryHistoryTableTable categoryHistoryTable =
      $CategoryHistoryTableTable(this);
  late final $MainstreamHistoryTableTable mainstreamHistoryTable =
      $MainstreamHistoryTableTable(this);
  late final $LifecycleHistoryTableTable lifecycleHistoryTable =
      $LifecycleHistoryTableTable(this);
  late final $RotationHistoryTableTable rotationHistoryTable =
      $RotationHistoryTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categoryHistoryTable,
    mainstreamHistoryTable,
    lifecycleHistoryTable,
    rotationHistoryTable,
  ];
}

typedef $$CategoryHistoryTableTableCreateCompanionBuilder =
    CategoryHistoryTableCompanion Function({
      required String tradeDate,
      required String categoryName,
      required double score,
      required double hotScore,
      required double persistence,
      required double trendStrength,
      required int riseCount,
      required int fallCount,
      required int totalCount,
      Value<int> rowid,
    });
typedef $$CategoryHistoryTableTableUpdateCompanionBuilder =
    CategoryHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> categoryName,
      Value<double> score,
      Value<double> hotScore,
      Value<double> persistence,
      Value<double> trendStrength,
      Value<int> riseCount,
      Value<int> fallCount,
      Value<int> totalCount,
      Value<int> rowid,
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
  ColumnFilters<String> get tradeDate => $composableBuilder(
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
  ColumnOrderings<String> get tradeDate => $composableBuilder(
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
  GeneratedColumn<String> get tradeDate =>
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
          CategoryHistoryData,
          $$CategoryHistoryTableTableFilterComposer,
          $$CategoryHistoryTableTableOrderingComposer,
          $$CategoryHistoryTableTableAnnotationComposer,
          $$CategoryHistoryTableTableCreateCompanionBuilder,
          $$CategoryHistoryTableTableUpdateCompanionBuilder,
          (
            CategoryHistoryData,
            BaseReferences<
              _$AppDatabase,
              $CategoryHistoryTableTable,
              CategoryHistoryData
            >,
          ),
          CategoryHistoryData,
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
                Value<String> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> hotScore = const Value.absent(),
                Value<double> persistence = const Value.absent(),
                Value<double> trendStrength = const Value.absent(),
                Value<int> riseCount = const Value.absent(),
                Value<int> fallCount = const Value.absent(),
                Value<int> totalCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryHistoryTableCompanion(
                tradeDate: tradeDate,
                categoryName: categoryName,
                score: score,
                hotScore: hotScore,
                persistence: persistence,
                trendStrength: trendStrength,
                riseCount: riseCount,
                fallCount: fallCount,
                totalCount: totalCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String categoryName,
                required double score,
                required double hotScore,
                required double persistence,
                required double trendStrength,
                required int riseCount,
                required int fallCount,
                required int totalCount,
                Value<int> rowid = const Value.absent(),
              }) => CategoryHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                categoryName: categoryName,
                score: score,
                hotScore: hotScore,
                persistence: persistence,
                trendStrength: trendStrength,
                riseCount: riseCount,
                fallCount: fallCount,
                totalCount: totalCount,
                rowid: rowid,
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
      CategoryHistoryData,
      $$CategoryHistoryTableTableFilterComposer,
      $$CategoryHistoryTableTableOrderingComposer,
      $$CategoryHistoryTableTableAnnotationComposer,
      $$CategoryHistoryTableTableCreateCompanionBuilder,
      $$CategoryHistoryTableTableUpdateCompanionBuilder,
      (
        CategoryHistoryData,
        BaseReferences<
          _$AppDatabase,
          $CategoryHistoryTableTable,
          CategoryHistoryData
        >,
      ),
      CategoryHistoryData,
      PrefetchHooks Function()
    >;
typedef $$MainstreamHistoryTableTableCreateCompanionBuilder =
    MainstreamHistoryTableCompanion Function({
      required String tradeDate,
      required String categoryName,
      required int rankNo,
      required double score,
      Value<int> rowid,
    });
typedef $$MainstreamHistoryTableTableUpdateCompanionBuilder =
    MainstreamHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> categoryName,
      Value<int> rankNo,
      Value<double> score,
      Value<int> rowid,
    });

class $$MainstreamHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $MainstreamHistoryTableTable> {
  $$MainstreamHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rankNo => $composableBuilder(
    column: $table.rankNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MainstreamHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MainstreamHistoryTableTable> {
  $$MainstreamHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rankNo => $composableBuilder(
    column: $table.rankNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MainstreamHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MainstreamHistoryTableTable> {
  $$MainstreamHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rankNo =>
      $composableBuilder(column: $table.rankNo, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$MainstreamHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MainstreamHistoryTableTable,
          MainstreamHistoryData,
          $$MainstreamHistoryTableTableFilterComposer,
          $$MainstreamHistoryTableTableOrderingComposer,
          $$MainstreamHistoryTableTableAnnotationComposer,
          $$MainstreamHistoryTableTableCreateCompanionBuilder,
          $$MainstreamHistoryTableTableUpdateCompanionBuilder,
          (
            MainstreamHistoryData,
            BaseReferences<
              _$AppDatabase,
              $MainstreamHistoryTableTable,
              MainstreamHistoryData
            >,
          ),
          MainstreamHistoryData,
          PrefetchHooks Function()
        > {
  $$MainstreamHistoryTableTableTableManager(
    _$AppDatabase db,
    $MainstreamHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MainstreamHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MainstreamHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MainstreamHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<int> rankNo = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MainstreamHistoryTableCompanion(
                tradeDate: tradeDate,
                categoryName: categoryName,
                rankNo: rankNo,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String categoryName,
                required int rankNo,
                required double score,
                Value<int> rowid = const Value.absent(),
              }) => MainstreamHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                categoryName: categoryName,
                rankNo: rankNo,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MainstreamHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MainstreamHistoryTableTable,
      MainstreamHistoryData,
      $$MainstreamHistoryTableTableFilterComposer,
      $$MainstreamHistoryTableTableOrderingComposer,
      $$MainstreamHistoryTableTableAnnotationComposer,
      $$MainstreamHistoryTableTableCreateCompanionBuilder,
      $$MainstreamHistoryTableTableUpdateCompanionBuilder,
      (
        MainstreamHistoryData,
        BaseReferences<
          _$AppDatabase,
          $MainstreamHistoryTableTable,
          MainstreamHistoryData
        >,
      ),
      MainstreamHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LifecycleHistoryTableTableCreateCompanionBuilder =
    LifecycleHistoryTableCompanion Function({
      required String tradeDate,
      required String categoryName,
      required String stage,
      Value<int> rowid,
    });
typedef $$LifecycleHistoryTableTableUpdateCompanionBuilder =
    LifecycleHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> categoryName,
      Value<String> stage,
      Value<int> rowid,
    });

class $$LifecycleHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $LifecycleHistoryTableTable> {
  $$LifecycleHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LifecycleHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LifecycleHistoryTableTable> {
  $$LifecycleHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LifecycleHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifecycleHistoryTableTable> {
  $$LifecycleHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);
}

class $$LifecycleHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LifecycleHistoryTableTable,
          LifecycleHistoryData,
          $$LifecycleHistoryTableTableFilterComposer,
          $$LifecycleHistoryTableTableOrderingComposer,
          $$LifecycleHistoryTableTableAnnotationComposer,
          $$LifecycleHistoryTableTableCreateCompanionBuilder,
          $$LifecycleHistoryTableTableUpdateCompanionBuilder,
          (
            LifecycleHistoryData,
            BaseReferences<
              _$AppDatabase,
              $LifecycleHistoryTableTable,
              LifecycleHistoryData
            >,
          ),
          LifecycleHistoryData,
          PrefetchHooks Function()
        > {
  $$LifecycleHistoryTableTableTableManager(
    _$AppDatabase db,
    $LifecycleHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifecycleHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LifecycleHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LifecycleHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifecycleHistoryTableCompanion(
                tradeDate: tradeDate,
                categoryName: categoryName,
                stage: stage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String categoryName,
                required String stage,
                Value<int> rowid = const Value.absent(),
              }) => LifecycleHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                categoryName: categoryName,
                stage: stage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LifecycleHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LifecycleHistoryTableTable,
      LifecycleHistoryData,
      $$LifecycleHistoryTableTableFilterComposer,
      $$LifecycleHistoryTableTableOrderingComposer,
      $$LifecycleHistoryTableTableAnnotationComposer,
      $$LifecycleHistoryTableTableCreateCompanionBuilder,
      $$LifecycleHistoryTableTableUpdateCompanionBuilder,
      (
        LifecycleHistoryData,
        BaseReferences<
          _$AppDatabase,
          $LifecycleHistoryTableTable,
          LifecycleHistoryData
        >,
      ),
      LifecycleHistoryData,
      PrefetchHooks Function()
    >;
typedef $$RotationHistoryTableTableCreateCompanionBuilder =
    RotationHistoryTableCompanion Function({
      required String tradeDate,
      required String fromCategory,
      required String toCategory,
      required double score,
      Value<int> rowid,
    });
typedef $$RotationHistoryTableTableUpdateCompanionBuilder =
    RotationHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> fromCategory,
      Value<String> toCategory,
      Value<double> score,
      Value<int> rowid,
    });

class $$RotationHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $RotationHistoryTableTable> {
  $$RotationHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromCategory => $composableBuilder(
    column: $table.fromCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toCategory => $composableBuilder(
    column: $table.toCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RotationHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RotationHistoryTableTable> {
  $$RotationHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromCategory => $composableBuilder(
    column: $table.fromCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toCategory => $composableBuilder(
    column: $table.toCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RotationHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RotationHistoryTableTable> {
  $$RotationHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get fromCategory => $composableBuilder(
    column: $table.fromCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toCategory => $composableBuilder(
    column: $table.toCategory,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$RotationHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RotationHistoryTableTable,
          RotationHistoryData,
          $$RotationHistoryTableTableFilterComposer,
          $$RotationHistoryTableTableOrderingComposer,
          $$RotationHistoryTableTableAnnotationComposer,
          $$RotationHistoryTableTableCreateCompanionBuilder,
          $$RotationHistoryTableTableUpdateCompanionBuilder,
          (
            RotationHistoryData,
            BaseReferences<
              _$AppDatabase,
              $RotationHistoryTableTable,
              RotationHistoryData
            >,
          ),
          RotationHistoryData,
          PrefetchHooks Function()
        > {
  $$RotationHistoryTableTableTableManager(
    _$AppDatabase db,
    $RotationHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RotationHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RotationHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RotationHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> fromCategory = const Value.absent(),
                Value<String> toCategory = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RotationHistoryTableCompanion(
                tradeDate: tradeDate,
                fromCategory: fromCategory,
                toCategory: toCategory,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String fromCategory,
                required String toCategory,
                required double score,
                Value<int> rowid = const Value.absent(),
              }) => RotationHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                fromCategory: fromCategory,
                toCategory: toCategory,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RotationHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RotationHistoryTableTable,
      RotationHistoryData,
      $$RotationHistoryTableTableFilterComposer,
      $$RotationHistoryTableTableOrderingComposer,
      $$RotationHistoryTableTableAnnotationComposer,
      $$RotationHistoryTableTableCreateCompanionBuilder,
      $$RotationHistoryTableTableUpdateCompanionBuilder,
      (
        RotationHistoryData,
        BaseReferences<
          _$AppDatabase,
          $RotationHistoryTableTable,
          RotationHistoryData
        >,
      ),
      RotationHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoryHistoryTableTableTableManager get categoryHistoryTable =>
      $$CategoryHistoryTableTableTableManager(_db, _db.categoryHistoryTable);
  $$MainstreamHistoryTableTableTableManager get mainstreamHistoryTable =>
      $$MainstreamHistoryTableTableTableManager(
        _db,
        _db.mainstreamHistoryTable,
      );
  $$LifecycleHistoryTableTableTableManager get lifecycleHistoryTable =>
      $$LifecycleHistoryTableTableTableManager(_db, _db.lifecycleHistoryTable);
  $$RotationHistoryTableTableTableManager get rotationHistoryTable =>
      $$RotationHistoryTableTableTableManager(_db, _db.rotationHistoryTable);
}
