import 'package:sqflite/sqflite.dart';
import '../models/statistics.dart';
import '../models/diary_entry.dart';
import 'database_helper.dart';
import 'diary_service.dart';
import 'tag_service.dart';
import '../utils/date_utils.dart';

/// 统计服务
/// 负责生成各种统计数据和分析报告
class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final DiaryService _diaryService = DiaryService();
  final TagService _tagService = TagService();

  /// 获取完整的统计数据
  Future<Statistics> getCompleteStatistics() async {
    final db = await _databaseHelper.database;

    // 获取基本统计数据
    final basicStats = await _getBasicStatistics(db);

    // 获取标签使用统计
    final tagUsage = await _getTagUsageStatistics(db);

    // 获取按日统计
    final dailyEntries = await _getDailyStatistics(db);

    // 获取按周统计
    final weeklyEntries = await _getWeeklyStatistics(db);

    // 获取按月统计
    final monthlyEntries = await _getMonthlyStatistics(db);

    return Statistics(
      totalEntries: basicStats['totalEntries'] ?? 0,
      totalTags: basicStats['totalTags'] ?? 0,
      entriesThisWeek: basicStats['entriesThisWeek'] ?? 0,
      entriesThisMonth: basicStats['entriesThisMonth'] ?? 0,
      tagUsage: tagUsage,
      dailyEntries: dailyEntries,
      weeklyEntries: weeklyEntries,
      monthlyEntries: monthlyEntries,
    );
  }

  /// 获取基本统计信息
  Future<Statistics> getBasicStatistics() async {
    final allDiaries = await _diaryService.getAllDiaries();
    final allTags = await _tagService.getAllTags();
    final now = DateTime.now();

    // 计算本月日记数
    final thisMonth = allDiaries.where((diary) {
      return DateUtils.isSameMonth(diary.date, now);
    }).length;

    // 计算本周日记数
    final thisWeek = allDiaries.where((diary) {
      return DateUtils.isThisWeek(diary.date);
    }).length;

    // 计算今日日记数
    final today = allDiaries.where((diary) {
      return DateUtils.isToday(diary.date);
    }).length;

    // 计算总字数
    final totalWords = allDiaries.fold<int>(0, (sum, diary) {
      return sum + diary.content.length + diary.title.length;
    });

    // 计算平均字数
    final averageWords = allDiaries.isNotEmpty
        ? totalWords / allDiaries.length
        : 0.0;

    // 计算连续写作天数
    final writingStreak = _calculateWritingStreak(allDiaries);

    // 计算写作天数
    final writingDays = _calculateWritingDays(allDiaries);

    return Statistics(
      totalEntries: allDiaries.length,
      totalTags: allTags.length,
      entriesThisWeek: thisWeek,
      entriesThisMonth: thisMonth,
      todayEntries: today,
      totalWords: totalWords,
      averageWords: averageWords,
      writingStreak: writingStreak,
      writingDays: writingDays,
      tagUsage: {},
      dailyEntries: {},
      weeklyEntries: {},
      monthlyEntries: {},
    );
  }

  /// 获取基本统计数据
  Future<Map<String, int>> _getBasicStatistics(Database db) async {
    final DateTime now = DateTime.now();

    // 总日记数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.diaryTable}',
    );
    final int totalEntries = totalResult.first['count'] as int;

    // 总标签数
    final tagResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tagTable}',
    );
    final int totalTags = tagResult.first['count'] as int;

    // 本周日记数
    final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    final String weekStartStr = weekStart.toIso8601String().split('T')[0];

    final weekResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
    ''',
      [weekStartStr],
    );
    final int entriesThisWeek = weekResult.first['count'] as int;

    // 本月日记数
    final String monthStartStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

    final monthResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
    ''',
      [monthStartStr],
    );
    final int entriesThisMonth = monthResult.first['count'] as int;

    return {
      'totalEntries': totalEntries,
      'totalTags': totalTags,
      'entriesThisWeek': entriesThisWeek,
      'entriesThisMonth': entriesThisMonth,
    };
  }

  /// 计算当前连续写作天数
  int _calculateWritingStreak(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return 0;

    final sortedDiaries = List<DiaryEntry>.from(diaries)
      ..sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime.now();
    int streak = 0;

    // 检查今天是否有写作
    if (DateUtils.isToday(sortedDiaries.first.date)) {
      streak = 1;
    } else {
      // 如果昨天有写作，则从昨天开始计算
      final yesterday = today.subtract(const Duration(days: 1));
      if (DateUtils.isSameDay(sortedDiaries.first.date, yesterday)) {
        streak = 1;
      } else {
        return 0;
      }
    }

    // 向前计算连续天数
    DateTime expectedDate = sortedDiaries.first.date.subtract(
      const Duration(days: 1),
    );

    for (int i = 1; i < sortedDiaries.length; i++) {
      if (DateUtils.isSameDay(sortedDiaries[i].date, expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// 计算总写作天数
  int _calculateWritingDays(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return 0;

    final uniqueDates = diaries
        .map((diary) => DateUtils.formatDate(diary.date))
        .toSet();
    return uniqueDates.length;
  }

  /// 获取标签使用统计
  Future<Map<String, int>> _getTagUsageStatistics(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      columns: ['name', 'usage_count'],
      where: 'usage_count > 0',
      orderBy: 'usage_count DESC',
    );

    final Map<String, int> tagUsage = {};
    for (final map in maps) {
      tagUsage[map['name'] as String] = map['usage_count'] as int;
    }

    return tagUsage;
  }

  /// 获取按日统计（最近30天）
  Future<Map<String, int>> _getDailyStatistics(Database db) async {
    final DateTime now = DateTime.now();
    final DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        DATE(date) as day,
        COUNT(*) as count
      FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
      GROUP BY DATE(date)
      ORDER BY DATE(date)
    ''',
      [thirtyDaysAgo.toIso8601String().split('T')[0]],
    );

    final Map<String, int> dailyEntries = {};
    for (final map in maps) {
      dailyEntries[map['day'] as String] = map['count'] as int;
    }

    return dailyEntries;
  }

  /// 获取按周统计（最近12周）
  Future<Map<String, int>> _getWeeklyStatistics(Database db) async {
    final DateTime now = DateTime.now();
    final DateTime twelveWeeksAgo = now.subtract(const Duration(days: 84));

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        strftime('%Y-W%W', date) as week,
        COUNT(*) as count
      FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
      GROUP BY strftime('%Y-W%W', date)
      ORDER BY strftime('%Y-W%W', date)
    ''',
      [twelveWeeksAgo.toIso8601String().split('T')[0]],
    );

    final Map<String, int> weeklyEntries = {};
    for (final map in maps) {
      weeklyEntries[map['week'] as String] = map['count'] as int;
    }

    return weeklyEntries;
  }

  /// 获取按月统计（最近12个月）
  Future<Map<String, int>> _getMonthlyStatistics(Database db) async {
    final DateTime now = DateTime.now();
    final DateTime twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        strftime('%Y-%m', date) as month,
        COUNT(*) as count
      FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
      GROUP BY strftime('%Y-%m', date)
      ORDER BY strftime('%Y-%m', date)
    ''',
      [twelveMonthsAgo.toIso8601String().split('T')[0]],
    );

    final Map<String, int> monthlyEntries = {};
    for (final map in maps) {
      monthlyEntries[map['month'] as String] = map['count'] as int;
    }

    return monthlyEntries;
  }

  /// 获取写作频率统计
  Future<Map<String, dynamic>> getWritingFrequency() async {
    final db = await _databaseHelper.database;

    // 获取最早和最晚的日记日期
    final List<Map<String, dynamic>> dateRange = await db.rawQuery('''
      SELECT 
        MIN(date) as earliest_date,
        MAX(date) as latest_date
      FROM ${DatabaseHelper.diaryTable}
    ''');

    if (dateRange.isEmpty || dateRange.first['earliest_date'] == null) {
      return {
        'totalDays': 0,
        'writingDays': 0,
        'averagePerDay': 0.0,
        'frequency': 0.0,
      };
    }

    final DateTime earliest = DateTime.parse(dateRange.first['earliest_date']);
    final DateTime latest = DateTime.parse(dateRange.first['latest_date']);
    final int totalDays = latest.difference(earliest).inDays + 1;

    // 获取有日记的天数
    final List<Map<String, dynamic>> writingDaysResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT DATE(date)) as writing_days
      FROM ${DatabaseHelper.diaryTable}
    ''');
    final int writingDays = writingDaysResult.first['writing_days'] as int;

    // 获取总日记数
    final List<Map<String, dynamic>> totalResult = await db.rawQuery('''
      SELECT COUNT(*) as total_entries
      FROM ${DatabaseHelper.diaryTable}
    ''');
    final int totalEntries = totalResult.first['total_entries'] as int;

    final double averagePerDay = totalDays > 0 ? totalEntries / totalDays : 0.0;
    final double frequency = totalDays > 0 ? writingDays / totalDays : 0.0;

    return {
      'totalDays': totalDays,
      'writingDays': writingDays,
      'averagePerDay': averagePerDay,
      'frequency': frequency,
    };
  }

  /// 获取最活跃的时间段
  Future<Map<String, int>> getMostActiveTimeSlots() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        strftime('%H', created_at) as hour,
        COUNT(*) as count
      FROM ${DatabaseHelper.diaryTable}
      GROUP BY strftime('%H', created_at)
      ORDER BY count DESC
    ''');

    final Map<String, int> timeSlots = {};
    for (final map in maps) {
      final String hour = map['hour'] as String;
      timeSlots['$hour:00'] = map['count'] as int;
    }

    return timeSlots;
  }

  /// 获取标签共现统计
  Future<Map<String, Map<String, int>>> getTagCooccurrence() async {
    final db = await _databaseHelper.database;

    // 获取所有日记及其标签
    final List<Map<String, dynamic>> diaryTags = await db.rawQuery('''
      SELECT 
        d.id,
        GROUP_CONCAT(t.name) as tags
      FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      JOIN ${DatabaseHelper.tagTable} t ON dt.tag_id = t.id
      GROUP BY d.id
    ''');

    final Map<String, Map<String, int>> cooccurrence = {};

    for (final entry in diaryTags) {
      final String? tagsStr = entry['tags'] as String?;
      if (tagsStr != null) {
        final List<String> tags = tagsStr.split(',');

        // 计算标签共现
        for (int i = 0; i < tags.length; i++) {
          for (int j = i + 1; j < tags.length; j++) {
            final String tag1 = tags[i];
            final String tag2 = tags[j];

            cooccurrence[tag1] ??= {};
            cooccurrence[tag2] ??= {};

            cooccurrence[tag1]![tag2] = (cooccurrence[tag1]![tag2] ?? 0) + 1;
            cooccurrence[tag2]![tag1] = (cooccurrence[tag2]![tag1] ?? 0) + 1;
          }
        }
      }
    }

    return cooccurrence;
  }

  /// 获取内容长度统计
  Future<Map<String, dynamic>> getContentLengthStatistics() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        AVG(LENGTH(content)) as average_length,
        MIN(LENGTH(content)) as min_length,
        MAX(LENGTH(content)) as max_length
      FROM ${DatabaseHelper.diaryTable}
    ''');

    if (maps.isEmpty) {
      return {'averageLength': 0.0, 'minLength': 0, 'maxLength': 0};
    }

    final map = maps.first;
    return {
      'averageLength': (map['average_length'] as double?) ?? 0.0,
      'minLength': (map['min_length'] as int?) ?? 0,
      'maxLength': (map['max_length'] as int?) ?? 0,
    };
  }

  /// 获取成长趋势分析
  Future<Map<String, dynamic>> getGrowthTrend() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', date) as month,
        COUNT(*) as count,
        AVG(LENGTH(content)) as avg_length
      FROM ${DatabaseHelper.diaryTable}
      GROUP BY strftime('%Y-%m', date)
      ORDER BY strftime('%Y-%m', date)
    ''');

    final List<Map<String, dynamic>> trend = [];
    for (final map in maps) {
      trend.add({
        'month': map['month'],
        'count': map['count'],
        'averageLength': (map['avg_length'] as double?) ?? 0.0,
      });
    }

    return {'monthlyTrend': trend};
  }

  /// 获取日记质量指标
  Future<Map<String, dynamic>> getQualityMetrics() async {
    final db = await _databaseHelper.database;

    // 获取有标签的日记比例
    final List<Map<String, dynamic>> taggedResult = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT d.id) as tagged_count,
        (SELECT COUNT(*) FROM ${DatabaseHelper.diaryTable}) as total_count
      FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
    ''');

    final int taggedCount = taggedResult.first['tagged_count'] as int;
    final int totalCount = taggedResult.first['total_count'] as int;
    final double taggedRatio = totalCount > 0 ? taggedCount / totalCount : 0.0;

    // 获取有备注的日记比例
    final List<Map<String, dynamic>> notesResult = await db.rawQuery('''
      SELECT COUNT(*) as notes_count
      FROM ${DatabaseHelper.diaryTable}
      WHERE notes IS NOT NULL AND notes != ''
    ''');
    final int notesCount = notesResult.first['notes_count'] as int;
    final double notesRatio = totalCount > 0 ? notesCount / totalCount : 0.0;

    return {
      'taggedRatio': taggedRatio,
      'notesRatio': notesRatio,
      'totalEntries': totalCount,
      'taggedEntries': taggedCount,
      'entriesWithNotes': notesCount,
    };
  }
}
