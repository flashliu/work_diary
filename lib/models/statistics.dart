// 统计数据模型
class Statistics {
  final int totalEntries;
  final int totalTags;
  final int entriesThisWeek;
  final int entriesThisMonth;
  final Map<String, int> tagUsage;
  final Map<String, int> dailyEntries;
  final Map<String, int> weeklyEntries;
  final Map<String, int> monthlyEntries;

  Statistics({
    required this.totalEntries,
    required this.totalTags,
    required this.entriesThisWeek,
    required this.entriesThisMonth,
    required this.tagUsage,
    required this.dailyEntries,
    required this.weeklyEntries,
    required this.monthlyEntries,
  });

  // 从 Map 创建 Statistics
  factory Statistics.fromMap(Map<String, dynamic> map) {
    return Statistics(
      totalEntries: map['total_entries'] ?? 0,
      totalTags: map['total_tags'] ?? 0,
      entriesThisWeek: map['entries_this_week'] ?? 0,
      entriesThisMonth: map['entries_this_month'] ?? 0,
      tagUsage: Map<String, int>.from(map['tag_usage'] ?? {}),
      dailyEntries: Map<String, int>.from(map['daily_entries'] ?? {}),
      weeklyEntries: Map<String, int>.from(map['weekly_entries'] ?? {}),
      monthlyEntries: Map<String, int>.from(map['monthly_entries'] ?? {}),
    );
  }

  // 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'total_entries': totalEntries,
      'total_tags': totalTags,
      'entries_this_week': entriesThisWeek,
      'entries_this_month': entriesThisMonth,
      'tag_usage': tagUsage,
      'daily_entries': dailyEntries,
      'weekly_entries': weeklyEntries,
      'monthly_entries': monthlyEntries,
    };
  }

  // 创建空的统计数据
  factory Statistics.empty() {
    return Statistics(
      totalEntries: 0,
      totalTags: 0,
      entriesThisWeek: 0,
      entriesThisMonth: 0,
      tagUsage: {},
      dailyEntries: {},
      weeklyEntries: {},
      monthlyEntries: {},
    );
  }

  // 获取最常用的标签
  List<MapEntry<String, int>> get topTags {
    final sortedTags = tagUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedTags.take(10).toList();
  }

  // 获取最近7天的数据
  List<MapEntry<String, int>> get recentDays {
    final now = DateTime.now();
    final recent = <MapEntry<String, int>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final count = dailyEntries[dateStr] ?? 0;
      recent.add(MapEntry(dateStr, count));
    }

    return recent;
  }

  // 获取本周平均每天记录数
  double get averageEntriesPerDay {
    if (totalEntries == 0) return 0;
    return totalEntries / 7;
  }

  // 获取标签使用率
  double getTagUsageRate(String tag) {
    if (totalEntries == 0) return 0;
    return (tagUsage[tag] ?? 0) / totalEntries;
  }

  @override
  String toString() {
    return 'Statistics{totalEntries: $totalEntries, totalTags: $totalTags, entriesThisWeek: $entriesThisWeek, entriesThisMonth: $entriesThisMonth}';
  }
}
