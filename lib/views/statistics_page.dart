import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../models/diary_entry.dart';

/// 统计页面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<DiaryProvider, TagProvider>(
      builder: (context, diaryProvider, tagProvider, child) {
        return Column(
          children: [
            CustomAppBar(title: '统计分析', subtitle: '工作日记数据统计'),
            Expanded(
              child: Column(
                children: [
                  // 统计标签
                  _buildStatsTabs(),

                  // 统计内容
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        _buildOverviewTab(diaryProvider),
                        _buildTrendTab(diaryProvider),
                        _buildTagsTab(diaryProvider, tagProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(child: _buildTab('概览', 0)),
            Expanded(child: _buildTab('趋势', 1)),
            Expanded(child: _buildTab('标签', 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(DiaryProvider diaryProvider) {
    final total = diaryProvider.totalEntries;
    final thisMonth = diaryProvider.thisMonthEntries;
    final thisWeek = diaryProvider.thisWeekEntries;
    final avgPerMonth = total > 0
        ? (total / _getMonthCount(diaryProvider)).toStringAsFixed(1)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 概览卡片
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '总日记数',
                  value: total.toString(),
                  icon: Icons.note,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: '本月日记',
                  value: thisMonth.toString(),
                  icon: Icons.calendar_today,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '本周日记',
                  value: thisWeek.toString(),
                  icon: Icons.date_range,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: '月均产量',
                  value: avgPerMonth,
                  icon: Icons.trending_up,
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 最近活跃度
          _buildActivityCard(diaryProvider),

          const SizedBox(height: 24),

          // 字数统计
          _buildWordCountCard(diaryProvider),
        ],
      ),
    );
  }

  Widget _buildTrendTab(DiaryProvider diaryProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 月度趋势图
          _buildMonthlyTrendChart(diaryProvider),

          const SizedBox(height: 24),

          // 周度活跃度
          _buildWeeklyActivityChart(diaryProvider),
        ],
      ),
    );
  }

  Widget _buildTagsTab(DiaryProvider diaryProvider, TagProvider tagProvider) {
    final tagUsage = _getTagUsageStats(diaryProvider.allEntries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 标签使用饼图
          _buildTagPieChart(tagUsage),

          const SizedBox(height: 24),

          // 标签使用列表
          _buildTagUsageList(tagUsage),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(DiaryProvider diaryProvider) {
    final recentEntries = diaryProvider.allEntries
        .where((entry) => DateTime.now().difference(entry.date).inDays <= 30)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近30天活跃度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 30,
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(
                  Duration(days: 29 - index),
                );
                final hasEntry = recentEntries.any(
                  (entry) =>
                      entry.date.day == date.day &&
                      entry.date.month == date.month,
                );

                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: hasEntry
                        ? AppColors.success
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '30天前',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${recentEntries.length}篇',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                '今天',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCountCard(DiaryProvider diaryProvider) {
    final totalWords = diaryProvider.allEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.content.length,
    );
    final avgWords = diaryProvider.allEntries.isEmpty
        ? 0
        : totalWords / diaryProvider.allEntries.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '字数统计',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    totalWords.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    '总字数',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    avgWords.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const Text(
                    '平均字数',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(DiaryProvider diaryProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '月度趋势',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                minY: 0,
                maxY: _getMaxY(diaryProvider),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return _getMonthTitle(value.toInt());
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getMonthlySpots(diaryProvider),
                    isCurved: true,
                    color: AppColors.primary,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart(DiaryProvider diaryProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '周度活跃度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const weekdays = [
                          '周一',
                          '周二',
                          '周三',
                          '周四',
                          '周五',
                          '周六',
                          '周日',
                        ];
                        return Text(
                          weekdays[value.toInt()],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getWeeklyBarGroups(diaryProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPieChart(Map<String, int> tagUsage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '标签使用分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sections: _getPieChartSections(tagUsage),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagUsageList(Map<String, int> tagUsage) {
    final sortedTags = tagUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '标签使用排行',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedTags.take(10).map((entry) {
            final index = sortedTags.indexOf(entry);
            final color =
                AppColors.tagColors[index % AppColors.tagColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<FlSpot> _getMonthlySpots(DiaryProvider diaryProvider) {
    final entries = diaryProvider.allEntries;
    if (entries.isEmpty) {
      return List.generate(6, (index) => FlSpot(index.toDouble(), 0));
    }

    // 获取最近6个月的数据
    final now = DateTime.now();
    final monthlyData = <int>[];

    // 初始化最近6个月的数据为0（从6个月前到当前月）
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      int count = 0;

      // 统计该月的日记数量
      for (final entry in entries) {
        if (entry.date.year == month.year && entry.date.month == month.month) {
          count++;
        }
      }

      monthlyData.add(count);
    }

    // 转换为FlSpot数组
    return monthlyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();
  }

  List<BarChartGroupData> _getWeeklyBarGroups(DiaryProvider diaryProvider) {
    final weeklyData = List.generate(7, (index) {
      final count = diaryProvider.allEntries.where((entry) {
        return entry.date.weekday == index + 1;
      }).length;
      return count.toDouble();
    });

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyData[index],
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, int> tagUsage) {
    final total = tagUsage.values.fold<int>(0, (sum, value) => sum + value);

    return tagUsage.entries.take(5).map((entry) {
      final index = tagUsage.keys.toList().indexOf(entry.key);
      final color = AppColors.tagColors[index % AppColors.tagColors.length];
      final percentage = (entry.value / total * 100).toInt();

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Map<String, int> _getTagUsageStats(List<DiaryEntry> entries) {
    final tagUsage = <String, int>{};

    for (final entry in entries) {
      for (final tag in entry.tags) {
        tagUsage[tag] = (tagUsage[tag] ?? 0) + 1;
      }
    }

    return tagUsage;
  }

  int _getMonthCount(DiaryProvider diaryProvider) {
    if (diaryProvider.allEntries.isEmpty) return 1;

    final firstEntry = diaryProvider.allEntries.reduce(
      (a, b) => a.date.isBefore(b.date) ? a : b,
    );
    final now = DateTime.now();

    return (now.year - firstEntry.date.year) * 12 +
        (now.month - firstEntry.date.month) +
        1;
  }

  Widget _getMonthTitle(int index) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - (5 - index), 1);
    final monthNames = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        monthNames[month.month - 1],
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  double _getMaxY(DiaryProvider diaryProvider) {
    final spots = _getMonthlySpots(diaryProvider);
    final maxValue = spots.isEmpty
        ? 0
        : spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // 确保图表有合理的高度，即使所有数据都是0
    return maxValue == 0 ? 10 : maxValue + 8;
  }
}
