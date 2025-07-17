import 'database_helper.dart';

/// 标签使用分析服务
/// 专门负责标签相关的统计分析
class TagAnalysisService {
  static final TagAnalysisService _instance = TagAnalysisService._internal();
  factory TagAnalysisService() => _instance;
  TagAnalysisService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 获取标签使用频率统计
  Future<Map<String, dynamic>> getTagUsageFrequency() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.name,
        t.color,
        t.usage_count,
        COUNT(dt.diary_id) as actual_usage,
        t.created_at
      FROM ${DatabaseHelper.tagTable} t
      LEFT JOIN ${DatabaseHelper.diaryTagTable} dt ON t.id = dt.tag_id
      GROUP BY t.id, t.name, t.color, t.usage_count, t.created_at
      ORDER BY t.usage_count DESC
    ''');

    final totalUsage = maps.fold<int>(
      0,
      (sum, map) => sum + (map['usage_count'] as int),
    );

    final List<Map<String, dynamic>> tagFrequency = [];
    for (final map in maps) {
      final usageCount = map['usage_count'] as int;
      final percentage = totalUsage > 0 ? (usageCount / totalUsage) * 100 : 0.0;

      tagFrequency.add({
        'name': map['name'],
        'color': map['color'],
        'usageCount': usageCount,
        'actualUsage': map['actual_usage'],
        'percentage': percentage,
        'createdAt': map['created_at'],
        'rank': tagFrequency.length + 1,
      });
    }

    return {
      'tagFrequency': tagFrequency,
      'totalTags': maps.length,
      'totalUsage': totalUsage,
      'averageUsage': maps.isNotEmpty ? totalUsage / maps.length : 0.0,
    };
  }

  /// 获取标签共现分析
  Future<Map<String, dynamic>> getTagCooccurrenceAnalysis() async {
    final db = await _databaseHelper.database;

    // 获取所有日记及其标签
    final List<Map<String, dynamic>> diaryTags = await db.rawQuery('''
      SELECT 
        d.id as diary_id,
        d.date,
        GROUP_CONCAT(t.name, '|') as tag_names,
        GROUP_CONCAT(t.id, '|') as tag_ids
      FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      JOIN ${DatabaseHelper.tagTable} t ON dt.tag_id = t.id
      GROUP BY d.id, d.date
      HAVING COUNT(t.id) > 1
    ''');

    final Map<String, Map<String, int>> cooccurrence = {};
    final Map<String, int> tagPairCounts = {};

    for (final entry in diaryTags) {
      final tagNames = (entry['tag_names'] as String).split('|');

      // 计算所有标签对的共现次数
      for (int i = 0; i < tagNames.length; i++) {
        for (int j = i + 1; j < tagNames.length; j++) {
          final tag1 = tagNames[i];
          final tag2 = tagNames[j];
          final pairKey = tag1.compareTo(tag2) < 0
              ? '$tag1-$tag2'
              : '$tag2-$tag1';

          tagPairCounts[pairKey] = (tagPairCounts[pairKey] ?? 0) + 1;

          cooccurrence[tag1] ??= {};
          cooccurrence[tag2] ??= {};
          cooccurrence[tag1]![tag2] = (cooccurrence[tag1]![tag2] ?? 0) + 1;
          cooccurrence[tag2]![tag1] = (cooccurrence[tag2]![tag1] ?? 0) + 1;
        }
      }
    }

    // 找出最常见的标签组合
    final sortedPairs = tagPairCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topPairs = sortedPairs.take(10).map((entry) {
      final tags = entry.key.split('-');
      return {'tag1': tags[0], 'tag2': tags[1], 'count': entry.value};
    }).toList();

    return {
      'cooccurrence': cooccurrence,
      'topTagPairs': topPairs,
      'totalPairs': tagPairCounts.length,
      'totalCooccurrences': tagPairCounts.values.fold<int>(
        0,
        (sum, count) => sum + count,
      ),
    };
  }

  /// 获取标签关联分析
  Future<Map<String, dynamic>> getTagCorrelationAnalysis() async {
    final cooccurrenceData = await getTagCooccurrenceAnalysis();
    final cooccurrence =
        cooccurrenceData['cooccurrence'] as Map<String, Map<String, int>>;

    // 获取所有标签的使用次数
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> tagCounts = await db.rawQuery('''
      SELECT name, usage_count
      FROM ${DatabaseHelper.tagTable}
      WHERE usage_count > 0
    ''');

    final Map<String, int> individualCounts = {};
    for (final tag in tagCounts) {
      individualCounts[tag['name'] as String] = tag['usage_count'] as int;
    }

    final Map<String, Map<String, double>> correlations = {};

    // 计算Jaccard相似系数
    for (final tag1 in cooccurrence.keys) {
      correlations[tag1] = {};
      for (final tag2 in cooccurrence[tag1]!.keys) {
        if (tag1 != tag2) {
          final intersection = cooccurrence[tag1]![tag2] ?? 0;
          final union =
              (individualCounts[tag1] ?? 0) +
              (individualCounts[tag2] ?? 0) -
              intersection;

          final jaccard = union > 0 ? intersection / union : 0.0;
          correlations[tag1]![tag2] = jaccard;
        }
      }
    }

    // 找出相关性最强的标签对
    final List<Map<String, dynamic>> strongCorrelations = [];
    correlations.forEach((tag1, correlationMap) {
      correlationMap.forEach((tag2, correlation) {
        if (correlation > 0.1) {
          // 阈值可调整
          strongCorrelations.add({
            'tag1': tag1,
            'tag2': tag2,
            'correlation': correlation,
            'strength': _getCorrelationStrength(correlation),
          });
        }
      });
    });

    strongCorrelations.sort(
      (a, b) =>
          (b['correlation'] as double).compareTo(a['correlation'] as double),
    );

    return {
      'correlations': correlations,
      'strongCorrelations': strongCorrelations.take(20).toList(),
      'averageCorrelation': _calculateAverageCorrelation(correlations),
    };
  }

  /// 获取标签使用模式分析
  Future<Map<String, dynamic>> getTagUsagePatterns() async {
    final db = await _databaseHelper.database;

    // 按时间分析标签使用模式
    final List<Map<String, dynamic>> monthlyUsage = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', d.date) as month,
        t.name as tag_name,
        COUNT(*) as usage_count
      FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      JOIN ${DatabaseHelper.tagTable} t ON dt.tag_id = t.id
      GROUP BY strftime('%Y-%m', d.date), t.name
      ORDER BY month, usage_count DESC
    ''');

    // 按星期分析标签使用模式
    final List<Map<String, dynamic>> weekdayUsage = await db.rawQuery('''
      SELECT 
        strftime('%w', d.date) as weekday,
        t.name as tag_name,
        COUNT(*) as usage_count
      FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      JOIN ${DatabaseHelper.tagTable} t ON dt.tag_id = t.id
      GROUP BY strftime('%w', d.date), t.name
      ORDER BY weekday, usage_count DESC
    ''');

    // 分析标签的时间规律
    final Map<String, Map<String, int>> monthlyPatterns = {};
    for (final usage in monthlyUsage) {
      final month = usage['month'] as String;
      final tagName = usage['tag_name'] as String;
      final count = usage['usage_count'] as int;

      monthlyPatterns[tagName] ??= {};
      monthlyPatterns[tagName]![month] = count;
    }

    final Map<String, Map<String, int>> weekdayPatterns = {};
    for (final usage in weekdayUsage) {
      final weekday = _getWeekdayName(usage['weekday']);
      final tagName = usage['tag_name'] as String;
      final count = usage['usage_count'] as int;

      weekdayPatterns[tagName] ??= {};
      weekdayPatterns[tagName]![weekday] = count;
    }

    return {
      'monthlyPatterns': monthlyPatterns,
      'weekdayPatterns': weekdayPatterns,
      'seasonalTrends': _analyzeSeasonalTrends(monthlyPatterns),
      'workdayVsWeekend': _analyzeWorkdayWeekendPattern(weekdayPatterns),
    };
  }

  /// 获取标签演化分析
  Future<Map<String, dynamic>> getTagEvolutionAnalysis() async {
    final db = await _databaseHelper.database;

    // 获取标签的首次和最近使用时间
    final List<Map<String, dynamic>> tagTimeline = await db.rawQuery('''
      SELECT 
        t.name,
        t.created_at,
        MIN(d.date) as first_used,
        MAX(d.date) as last_used,
        COUNT(dt.diary_id) as total_usage,
        COUNT(DISTINCT strftime('%Y-%m', d.date)) as active_months
      FROM ${DatabaseHelper.tagTable} t
      LEFT JOIN ${DatabaseHelper.diaryTagTable} dt ON t.id = dt.tag_id
      LEFT JOIN ${DatabaseHelper.diaryTable} d ON dt.diary_id = d.id
      GROUP BY t.id, t.name, t.created_at
      ORDER BY t.created_at
    ''');

    // 分析标签生命周期
    final List<Map<String, dynamic>> tagLifecycle = [];
    for (final tag in tagTimeline) {
      final createdAt = tag['created_at'] != null
          ? DateTime.parse(tag['created_at'])
          : null;
      final firstUsed = tag['first_used'] != null
          ? DateTime.parse(tag['first_used'])
          : null;
      final lastUsed = tag['last_used'] != null
          ? DateTime.parse(tag['last_used'])
          : null;
      final totalUsage = tag['total_usage'] as int;
      final activeMonths = tag['active_months'] as int;

      String status = 'inactive';
      if (lastUsed != null) {
        final daysSinceLastUse = DateTime.now().difference(lastUsed).inDays;
        if (daysSinceLastUse <= 7) {
          status = 'active';
        } else if (daysSinceLastUse <= 30) {
          status = 'recent';
        } else {
          status = 'dormant';
        }
      }

      tagLifecycle.add({
        'name': tag['name'],
        'createdAt': createdAt?.toIso8601String(),
        'firstUsed': firstUsed?.toIso8601String(),
        'lastUsed': lastUsed?.toIso8601String(),
        'totalUsage': totalUsage,
        'activeMonths': activeMonths,
        'status': status,
        'longevity': firstUsed != null && lastUsed != null
            ? lastUsed.difference(firstUsed).inDays
            : 0,
      });
    }

    // 统计不同状态的标签数量
    final Map<String, int> statusCounts = {};
    for (final tag in tagLifecycle) {
      final status = tag['status'] as String;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return {
      'tagLifecycle': tagLifecycle,
      'statusCounts': statusCounts,
      'avgLongevity': _calculateAverageLongevity(tagLifecycle),
      'retentionRate': _calculateRetentionRate(tagLifecycle),
    };
  }

  /// 获取标签效果分析
  Future<Map<String, dynamic>> getTagEffectivenessAnalysis() async {
    final db = await _databaseHelper.database;

    // 分析带标签的日记 vs 不带标签的日记
    final List<Map<String, dynamic>> taggedVsUntagged = await db.rawQuery('''
      SELECT 
        CASE WHEN dt.diary_id IS NOT NULL THEN 'tagged' ELSE 'untagged' END as type,
        COUNT(DISTINCT d.id) as diary_count,
        AVG(LENGTH(d.content)) as avg_content_length,
        AVG(LENGTH(d.title)) as avg_title_length
      FROM ${DatabaseHelper.diaryTable} d
      LEFT JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      GROUP BY CASE WHEN dt.diary_id IS NOT NULL THEN 'tagged' ELSE 'untagged' END
    ''');

    // 分析不同标签数量对日记质量的影响
    final List<Map<String, dynamic>> tagCountImpact = await db.rawQuery('''
      SELECT 
        tag_count,
        COUNT(*) as diary_count,
        AVG(content_length) as avg_content_length
      FROM (
        SELECT 
          d.id,
          LENGTH(d.content) as content_length,
          COUNT(dt.tag_id) as tag_count
        FROM ${DatabaseHelper.diaryTable} d
        LEFT JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
        GROUP BY d.id, LENGTH(d.content)
      ) as diary_stats
      GROUP BY tag_count
      ORDER BY tag_count
    ''');

    final Map<String, dynamic> effectiveness = {};
    for (final item in taggedVsUntagged) {
      effectiveness[item['type'] as String] = {
        'diaryCount': item['diary_count'],
        'avgContentLength': (item['avg_content_length'] as double?) ?? 0.0,
        'avgTitleLength': (item['avg_title_length'] as double?) ?? 0.0,
      };
    }

    return {
      'taggedVsUntagged': effectiveness,
      'tagCountImpact': tagCountImpact,
      'optimalTagCount': _findOptimalTagCount(tagCountImpact),
    };
  }

  /// 获取相关性强度描述
  String _getCorrelationStrength(double correlation) {
    if (correlation >= 0.7) return '强相关';
    if (correlation >= 0.5) return '中等相关';
    if (correlation >= 0.3) return '弱相关';
    return '微弱相关';
  }

  /// 计算平均相关性
  double _calculateAverageCorrelation(
    Map<String, Map<String, double>> correlations,
  ) {
    double sum = 0;
    int count = 0;

    correlations.forEach((tag1, correlationMap) {
      correlationMap.forEach((tag2, correlation) {
        sum += correlation;
        count++;
      });
    });

    return count > 0 ? sum / count : 0.0;
  }

  /// 分析季节性趋势
  Map<String, dynamic> _analyzeSeasonalTrends(
    Map<String, Map<String, int>> monthlyPatterns,
  ) {
    final Map<String, List<int>> seasonalData = {
      '春季': [], // 3-5月
      '夏季': [], // 6-8月
      '秋季': [], // 9-11月
      '冬季': [], // 12-2月
    };

    monthlyPatterns.forEach((tagName, monthData) {
      monthData.forEach((month, count) {
        final monthNum = int.parse(month.split('-')[1]);
        if (monthNum >= 3 && monthNum <= 5) {
          seasonalData['春季']!.add(count);
        } else if (monthNum >= 6 && monthNum <= 8) {
          seasonalData['夏季']!.add(count);
        } else if (monthNum >= 9 && monthNum <= 11) {
          seasonalData['秋季']!.add(count);
        } else {
          seasonalData['冬季']!.add(count);
        }
      });
    });

    final Map<String, double> seasonalAverages = {};
    seasonalData.forEach((season, counts) {
      seasonalAverages[season] = counts.isNotEmpty
          ? counts.reduce((a, b) => a + b) / counts.length
          : 0.0;
    });

    return seasonalAverages;
  }

  /// 分析工作日vs周末模式
  Map<String, dynamic> _analyzeWorkdayWeekendPattern(
    Map<String, Map<String, int>> weekdayPatterns,
  ) {
    final Map<String, List<int>> patterns = {'工作日': [], '周末': []};

    weekdayPatterns.forEach((tagName, weekdayData) {
      weekdayData.forEach((weekday, count) {
        if (weekday == '周六' || weekday == '周日') {
          patterns['周末']!.add(count);
        } else {
          patterns['工作日']!.add(count);
        }
      });
    });

    final Map<String, double> averages = {};
    patterns.forEach((type, counts) {
      averages[type] = counts.isNotEmpty
          ? counts.reduce((a, b) => a + b) / counts.length
          : 0.0;
    });

    return averages;
  }

  /// 计算平均存活时长
  double _calculateAverageLongevity(List<Map<String, dynamic>> tagLifecycle) {
    final longevities = tagLifecycle
        .where((tag) => (tag['longevity'] as int) > 0)
        .map((tag) => (tag['longevity'] as int).toDouble())
        .toList();

    return longevities.isNotEmpty
        ? longevities.reduce((a, b) => a + b) / longevities.length
        : 0.0;
  }

  /// 计算标签保留率
  double _calculateRetentionRate(List<Map<String, dynamic>> tagLifecycle) {
    final totalTags = tagLifecycle.length;
    final activeTags = tagLifecycle
        .where((tag) => tag['status'] == 'active')
        .length;

    return totalTags > 0 ? activeTags / totalTags : 0.0;
  }

  /// 找出最优标签数量
  int _findOptimalTagCount(List<Map<String, dynamic>> tagCountImpact) {
    if (tagCountImpact.isEmpty) return 0;

    double maxAvgLength = 0;
    int optimalCount = 0;

    for (final impact in tagCountImpact) {
      final avgLength = (impact['avg_content_length'] as double?) ?? 0.0;
      if (avgLength > maxAvgLength) {
        maxAvgLength = avgLength;
        optimalCount = impact['tag_count'] as int;
      }
    }

    return optimalCount;
  }

  /// 获取星期名称
  String _getWeekdayName(dynamic weekday) {
    final day = weekday is String ? int.parse(weekday) : weekday as int;
    switch (day) {
      case 0:
        return '周日';
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      default:
        return '未知';
    }
  }
}
