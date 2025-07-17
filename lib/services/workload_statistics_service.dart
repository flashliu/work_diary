import 'dart:math';
import 'database_helper.dart';
import '../utils/date_utils.dart';

/// 工作量统计服务
/// 专门负责工作量相关的统计分析
class WorkloadStatisticsService {
  static final WorkloadStatisticsService _instance =
      WorkloadStatisticsService._internal();
  factory WorkloadStatisticsService() => _instance;
  WorkloadStatisticsService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 获取工作量统计数据（按日统计）
  Future<Map<String, dynamic>> getDailyWorkloadStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    startDate ??= now.subtract(const Duration(days: 30));
    endDate ??= now;

    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        DATE(date) as day,
        COUNT(*) as entry_count,
        SUM(LENGTH(title) + LENGTH(content)) as total_chars,
        AVG(LENGTH(title) + LENGTH(content)) as avg_chars,
        MIN(LENGTH(title) + LENGTH(content)) as min_chars,
        MAX(LENGTH(title) + LENGTH(content)) as max_chars,
        COUNT(DISTINCT strftime('%H', created_at)) as active_hours
      FROM ${DatabaseHelper.diaryTable}
      WHERE date BETWEEN ? AND ?
      GROUP BY DATE(date)
      ORDER BY DATE(date)
    ''',
      [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
    );

    final Map<String, Map<String, dynamic>> dailyStats = {};
    int totalEntries = 0;
    int totalChars = 0;

    for (final map in maps) {
      final day = map['day'] as String;
      final entryCount = map['entry_count'] as int;
      final totalCharsDay = map['total_chars'] as int;

      totalEntries += entryCount;
      totalChars += totalCharsDay;

      dailyStats[day] = {
        'date': day,
        'entryCount': entryCount,
        'totalChars': totalCharsDay,
        'avgChars': (map['avg_chars'] as double).round(),
        'minChars': map['min_chars'] as int,
        'maxChars': map['max_chars'] as int,
        'activeHours': map['active_hours'] as int,
        'productivity': _calculateProductivityScore(entryCount, totalCharsDay),
      };
    }

    return {
      'dailyStats': dailyStats,
      'totalEntries': totalEntries,
      'totalChars': totalChars,
      'avgEntriesPerDay': dailyStats.isNotEmpty
          ? totalEntries / dailyStats.length
          : 0.0,
      'avgCharsPerDay': dailyStats.isNotEmpty
          ? totalChars / dailyStats.length
          : 0.0,
      'activeDays': dailyStats.length,
      'period':
          '${DateUtils.formatDate(startDate)} - ${DateUtils.formatDate(endDate)}',
    };
  }

  /// 获取工作量统计数据（按周统计）
  Future<Map<String, dynamic>> getWeeklyWorkloadStatistics({
    int weekCount = 12,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weekCount * 7));

    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        strftime('%Y-W%W', date) as week,
        strftime('%Y-%m-%d', date, 'weekday 0', '-6 days') as week_start,
        COUNT(*) as entry_count,
        SUM(LENGTH(title) + LENGTH(content)) as total_chars,
        AVG(LENGTH(title) + LENGTH(content)) as avg_chars,
        COUNT(DISTINCT DATE(date)) as active_days
      FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
      GROUP BY strftime('%Y-W%W', date)
      ORDER BY strftime('%Y-W%W', date)
    ''',
      [startDate.toIso8601String().split('T')[0]],
    );

    final Map<String, Map<String, dynamic>> weeklyStats = {};
    int totalEntries = 0;
    int totalChars = 0;

    for (final map in maps) {
      final week = map['week'] as String;
      final entryCount = map['entry_count'] as int;
      final totalCharsWeek = map['total_chars'] as int;
      final activeDays = map['active_days'] as int;

      totalEntries += entryCount;
      totalChars += totalCharsWeek;

      weeklyStats[week] = {
        'week': week,
        'weekStart': map['week_start'] as String,
        'entryCount': entryCount,
        'totalChars': totalCharsWeek,
        'avgChars': (map['avg_chars'] as double).round(),
        'activeDays': activeDays,
        'consistency': activeDays / 7.0, // 一致性评分（一周中有多少天在写作）
        'productivity': _calculateProductivityScore(entryCount, totalCharsWeek),
      };
    }

    return {
      'weeklyStats': weeklyStats,
      'totalEntries': totalEntries,
      'totalChars': totalChars,
      'avgEntriesPerWeek': weeklyStats.isNotEmpty
          ? totalEntries / weeklyStats.length
          : 0.0,
      'avgCharsPerWeek': weeklyStats.isNotEmpty
          ? totalChars / weeklyStats.length
          : 0.0,
      'activeWeeks': weeklyStats.length,
    };
  }

  /// 获取工作量统计数据（按月统计）
  Future<Map<String, dynamic>> getMonthlyWorkloadStatistics({
    int monthCount = 12,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, 1);

    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        strftime('%Y-%m', date) as month,
        COUNT(*) as entry_count,
        SUM(LENGTH(title) + LENGTH(content)) as total_chars,
        AVG(LENGTH(title) + LENGTH(content)) as avg_chars,
        COUNT(DISTINCT DATE(date)) as active_days,
        COUNT(DISTINCT strftime('%W', date)) as active_weeks
      FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
      GROUP BY strftime('%Y-%m', date)
      ORDER BY strftime('%Y-%m', date)
    ''',
      [startDate.toIso8601String().split('T')[0]],
    );

    final Map<String, Map<String, dynamic>> monthlyStats = {};
    int totalEntries = 0;
    int totalChars = 0;

    for (final map in maps) {
      final month = map['month'] as String;
      final entryCount = map['entry_count'] as int;
      final totalCharsMonth = map['total_chars'] as int;
      final activeDays = map['active_days'] as int;

      totalEntries += entryCount;
      totalChars += totalCharsMonth;

      // 计算该月的总天数
      final monthDate = DateTime.parse('$month-01');
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      monthlyStats[month] = {
        'month': month,
        'entryCount': entryCount,
        'totalChars': totalCharsMonth,
        'avgChars': (map['avg_chars'] as double).round(),
        'activeDays': activeDays,
        'activeWeeks': map['active_weeks'] as int,
        'daysInMonth': daysInMonth,
        'consistency': activeDays / daysInMonth, // 月度一致性
        'productivity': _calculateProductivityScore(
          entryCount,
          totalCharsMonth,
        ),
      };
    }

    return {
      'monthlyStats': monthlyStats,
      'totalEntries': totalEntries,
      'totalChars': totalChars,
      'avgEntriesPerMonth': monthlyStats.isNotEmpty
          ? totalEntries / monthlyStats.length
          : 0.0,
      'avgCharsPerMonth': monthlyStats.isNotEmpty
          ? totalChars / monthlyStats.length
          : 0.0,
      'activeMonths': monthlyStats.length,
    };
  }

  /// 获取趋势分析数据
  Future<Map<String, dynamic>> getTrendAnalysis() async {
    final dailyStats = await getDailyWorkloadStatistics();
    final weeklyStats = await getWeeklyWorkloadStatistics();
    final monthlyStats = await getMonthlyWorkloadStatistics();

    // 计算增长趋势
    final Map<String, dynamic> dailyTrend = _calculateTrend(
      (dailyStats['dailyStats'] as Map<String, Map<String, dynamic>>).values
          .map((stats) => (stats['entryCount'] as int).toDouble())
          .toList(),
    );

    final Map<String, dynamic> weeklyTrend = _calculateTrend(
      (weeklyStats['weeklyStats'] as Map<String, Map<String, dynamic>>).values
          .map((stats) => (stats['entryCount'] as int).toDouble())
          .toList(),
    );

    final Map<String, dynamic> monthlyTrend = _calculateTrend(
      (monthlyStats['monthlyStats'] as Map<String, Map<String, dynamic>>).values
          .map((stats) => (stats['entryCount'] as int).toDouble())
          .toList(),
    );

    return {
      'dailyTrend': dailyTrend,
      'weeklyTrend': weeklyTrend,
      'monthlyTrend': monthlyTrend,
      'overallTrend': _calculateOverallTrend([
        dailyTrend,
        weeklyTrend,
        monthlyTrend,
      ]),
    };
  }

  /// 获取对比分析数据
  Future<Map<String, dynamic>> getComparisonAnalysis() async {
    final now = DateTime.now();

    // 本周 vs 上周
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekStats = await getDailyWorkloadStatistics(
      startDate: thisWeekStart,
      endDate: now,
    );

    final lastWeekStats = await getDailyWorkloadStatistics(
      startDate: lastWeekStart,
      endDate: thisWeekStart.subtract(const Duration(days: 1)),
    );

    // 本月 vs 上月
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    final thisMonthStats = await getDailyWorkloadStatistics(
      startDate: thisMonthStart,
      endDate: now,
    );

    final lastMonthStats = await getDailyWorkloadStatistics(
      startDate: lastMonthStart,
      endDate: lastMonthEnd,
    );

    return {
      'weekComparison': {
        'thisWeek': thisWeekStats,
        'lastWeek': lastWeekStats,
        'entryGrowth': _calculateGrowthRate(
          thisWeekStats['totalEntries'] as int,
          lastWeekStats['totalEntries'] as int,
        ),
        'charsGrowth': _calculateGrowthRate(
          thisWeekStats['totalChars'] as int,
          lastWeekStats['totalChars'] as int,
        ),
      },
      'monthComparison': {
        'thisMonth': thisMonthStats,
        'lastMonth': lastMonthStats,
        'entryGrowth': _calculateGrowthRate(
          thisMonthStats['totalEntries'] as int,
          lastMonthStats['totalEntries'] as int,
        ),
        'charsGrowth': _calculateGrowthRate(
          thisMonthStats['totalChars'] as int,
          lastMonthStats['totalChars'] as int,
        ),
      },
    };
  }

  /// 获取生产力指标
  Future<Map<String, dynamic>> getProductivityMetrics() async {
    final db = await _databaseHelper.database;

    // 获取最活跃的时间段
    final List<Map<String, dynamic>> hourlyActivity = await db.rawQuery('''
      SELECT 
        strftime('%H', created_at) as hour,
        COUNT(*) as entry_count,
        AVG(LENGTH(title) + LENGTH(content)) as avg_chars
      FROM ${DatabaseHelper.diaryTable}
      GROUP BY strftime('%H', created_at)
      ORDER BY entry_count DESC
    ''');

    // 获取最活跃的星期
    final List<Map<String, dynamic>> weekdayActivity = await db.rawQuery('''
      SELECT 
        strftime('%w', date) as weekday,
        COUNT(*) as entry_count,
        AVG(LENGTH(title) + LENGTH(content)) as avg_chars
      FROM ${DatabaseHelper.diaryTable}
      GROUP BY strftime('%w', date)
      ORDER BY entry_count DESC
    ''');

    // 计算写作效率
    final List<Map<String, dynamic>> efficiencyData = await db.rawQuery('''
      SELECT 
        DATE(date) as day,
        COUNT(*) as entry_count,
        SUM(LENGTH(title) + LENGTH(content)) as total_chars,
        MIN(created_at) as first_entry,
        MAX(created_at) as last_entry
      FROM ${DatabaseHelper.diaryTable}
      GROUP BY DATE(date)
      HAVING COUNT(*) > 1
    ''');

    final List<double> efficiencyScores = [];
    for (final data in efficiencyData) {
      final firstEntry = DateTime.parse(data['first_entry']);
      final lastEntry = DateTime.parse(data['last_entry']);
      final totalMinutes = lastEntry.difference(firstEntry).inMinutes;
      final totalChars = data['total_chars'] as int;

      if (totalMinutes > 0) {
        efficiencyScores.add(totalChars / totalMinutes);
      }
    }

    final avgEfficiency = efficiencyScores.isNotEmpty
        ? efficiencyScores.reduce((a, b) => a + b) / efficiencyScores.length
        : 0.0;

    return {
      'hourlyActivity': hourlyActivity,
      'weekdayActivity': weekdayActivity,
      'averageEfficiency': avgEfficiency,
      'mostProductiveHour': hourlyActivity.isNotEmpty
          ? hourlyActivity.first['hour']
          : null,
      'mostProductiveWeekday': weekdayActivity.isNotEmpty
          ? _getWeekdayName(weekdayActivity.first['weekday'])
          : null,
    };
  }

  /// 计算生产力评分
  double _calculateProductivityScore(int entryCount, int totalChars) {
    // 基于日记数量和字符数计算生产力评分 (0-100)
    final entryScore = min(entryCount * 10, 50).toDouble(); // 最多50分
    final charScore = min(totalChars / 100, 50).toDouble(); // 最多50分
    return entryScore + charScore;
  }

  /// 计算趋势
  Map<String, dynamic> _calculateTrend(List<double> values) {
    if (values.length < 2) {
      return {'direction': 'stable', 'percentage': 0.0, 'slope': 0.0};
    }

    // 计算线性回归斜率
    final n = values.length;
    final xSum = (n * (n - 1)) / 2;
    final ySum = values.reduce((a, b) => a + b);
    final xySum = values
        .asMap()
        .entries
        .map((entry) => entry.key * entry.value)
        .reduce((a, b) => a + b);
    final xSquareSum = (n * (n - 1) * (2 * n - 1)) / 6;

    final slope = (n * xySum - xSum * ySum) / (n * xSquareSum - xSum * xSum);

    String direction;
    if (slope > 0.1) {
      direction = 'increasing';
    } else if (slope < -0.1) {
      direction = 'decreasing';
    } else {
      direction = 'stable';
    }

    final firstValue = values.first;
    final lastValue = values.last;
    final percentage = firstValue != 0
        ? ((lastValue - firstValue) / firstValue) * 100
        : 0.0;

    return {'direction': direction, 'percentage': percentage, 'slope': slope};
  }

  /// 计算整体趋势
  Map<String, dynamic> _calculateOverallTrend(
    List<Map<String, dynamic>> trends,
  ) {
    final slopes = trends.map((trend) => trend['slope'] as double).toList();
    final avgSlope = slopes.reduce((a, b) => a + b) / slopes.length;

    String direction;
    if (avgSlope > 0.1) {
      direction = 'increasing';
    } else if (avgSlope < -0.1) {
      direction = 'decreasing';
    } else {
      direction = 'stable';
    }

    return {'direction': direction, 'slope': avgSlope};
  }

  /// 计算增长率
  double _calculateGrowthRate(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
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
