import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/chart_widgets.dart';
import '../constants/app_constants.dart';
import '../services/workload_statistics_service.dart';
import '../services/tag_analysis_service.dart';

/// 增强的统计页面
class EnhancedStatisticsPage extends StatefulWidget {
  const EnhancedStatisticsPage({super.key});

  @override
  State<EnhancedStatisticsPage> createState() => _EnhancedStatisticsPageState();
}

class _EnhancedStatisticsPageState extends State<EnhancedStatisticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final WorkloadStatisticsService _workloadService =
      WorkloadStatisticsService();
  final TagAnalysisService _tagAnalysisService = TagAnalysisService();

  Map<String, dynamic>? _workloadStats;
  Map<String, dynamic>? _tagStats;
  Map<String, dynamic>? _trendData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _workloadService.getDailyWorkloadStatistics(),
        _tagAnalysisService.getTagUsageFrequency(),
        _workloadService.getTrendAnalysis(),
      ]);

      setState(() {
        _workloadStats = results[0];
        _tagStats = results[1];
        _trendData = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载统计数据失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DiaryProvider, TagProvider>(
      builder: (context, diaryProvider, tagProvider, child) {
        return Column(
          children: [
            CustomAppBar(
              title: '数据分析',
              subtitle: '深度洞察工作记录',
              actions: [
                IconButton(
                  onPressed: () => _showFilterDialog(context),
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  tooltip: '筛选',
                ),
                IconButton(
                  onPressed: _loadStatistics,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: '刷新',
                ),
              ],
            ),
            // 标签栏
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: '概览'),
                  Tab(text: '工作量'),
                  Tab(text: '标签分析'),
                  Tab(text: '趋势预测'),
                ],
              ),
            ),
            // 内容区域
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(diaryProvider, tagProvider),
                        _buildWorkloadTab(),
                        _buildTagAnalysisTab(),
                        _buildTrendTab(),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  /// 概览标签页
  Widget _buildOverviewTab(
    DiaryProvider diaryProvider,
    TagProvider tagProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 核心指标卡片
          _buildCoreMetricsGrid(diaryProvider),
          const SizedBox(height: 16),

          // 最近活动图表
          ChartContainer(
            title: '最近30天活动',
            subtitle: '每日记录数量趋势',
            height: 200,
            chart: _buildRecentActivityChart(diaryProvider),
            actions: [
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('查看详情'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 标签使用Top5
          ChartContainer(
            title: '热门标签',
            subtitle: '使用频率最高的5个标签',
            height: 300,
            chart: _buildTopTagsChart(tagProvider),
          ),
        ],
      ),
    );
  }

  /// 工作量分析标签页
  Widget _buildWorkloadTab() {
    if (_workloadStats == null) {
      return const Center(child: Text('暂无工作量数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 工作量概况卡片
          _buildWorkloadSummaryCards(),
          const SizedBox(height: 16),

          // 每日工作量分布
          ChartContainer(
            title: '每日工作量分布',
            subtitle: '最近30天记录数量',
            height: 250,
            chart: _buildDailyWorkloadChart(),
          ),
          const SizedBox(height: 16),

          // 工作时间模式
          ChartContainer(
            title: '工作时间模式',
            subtitle: '一周内各天记录分布',
            height: 200,
            chart: _buildWeekdayWorkloadChart(),
          ),
        ],
      ),
    );
  }

  /// 标签分析标签页
  Widget _buildTagAnalysisTab() {
    if (_tagStats == null) {
      return const Center(child: Text('暂无标签数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 标签使用统计
          ChartContainer(
            title: '标签使用分布',
            subtitle: '各标签使用占比',
            height: 300,
            chart: _buildTagUsagePieChart(),
          ),
          const SizedBox(height: 16),

          // 标签使用排行
          _buildTagUsageRanking(),
        ],
      ),
    );
  }

  /// 趋势预测标签页
  Widget _buildTrendTab() {
    if (_trendData == null) {
      return const Center(child: Text('暂无趋势数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 趋势概况
          _buildTrendSummary(),
          const SizedBox(height: 16),

          // 月度趋势图
          ChartContainer(
            title: '月度记录趋势',
            subtitle: '记录数量变化趋势',
            height: 250,
            chart: _buildMonthlyTrendChart(),
          ),
          const SizedBox(height: 16),

          // 预测建议
          _buildPredictionSuggestions(),
        ],
      ),
    );
  }

  /// 核心指标网格
  Widget _buildCoreMetricsGrid(DiaryProvider diaryProvider) {
    final entries = diaryProvider.allEntries;
    final totalEntries = entries.length;
    final thisWeekEntries = entries
        .where((e) => DateTime.now().difference(e.date).inDays <= 7)
        .length;
    final avgWordsPerEntry = entries.isNotEmpty
        ? entries.map((e) => e.content.length).reduce((a, b) => a + b) /
              entries.length
        : 0.0;

    // 计算连续记录天数
    int streak = 0;
    final now = DateTime.now();
    final sortedDates = entries.map((e) => e.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    for (int i = 0; i < sortedDates.length; i++) {
      final expectedDate = now.subtract(Duration(days: i));
      final dateStr =
          '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}';
      final entryDateStr =
          '${sortedDates[i].year}-${sortedDates[i].month.toString().padLeft(2, '0')}-${sortedDates[i].day.toString().padLeft(2, '0')}';

      if (dateStr == entryDateStr) {
        streak++;
      } else {
        break;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        StatisticCard(
          title: '总记录数',
          value: totalEntries.toString(),
          icon: Icons.edit_note,
          color: AppColors.primary,
          trend: thisWeekEntries > 0 ? '+$thisWeekEntries 本周' : null,
        ),
        StatisticCard(
          title: '本周记录',
          value: thisWeekEntries.toString(),
          subtitle: '过去7天',
          icon: Icons.calendar_today,
          color: Colors.green,
        ),
        StatisticCard(
          title: '连续天数',
          value: streak.toString(),
          subtitle: '连续记录',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        StatisticCard(
          title: '平均字数',
          value: avgWordsPerEntry.round().toString(),
          subtitle: '每篇记录',
          icon: Icons.text_fields,
          color: Colors.purple,
        ),
      ],
    );
  }

  /// 最近活动图表
  Widget _buildRecentActivityChart(DiaryProvider diaryProvider) {
    final entries = diaryProvider.allEntries;
    final now = DateTime.now();
    final data = <ChartLineData>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final count = entries
          .where(
            (e) =>
                e.date.year == date.year &&
                e.date.month == date.month &&
                e.date.day == date.day,
          )
          .length;

      data.add(ChartLineData(label: '${date.day}', value: count.toDouble()));
    }

    return CustomLineChart(data: data, showArea: true, curved: true);
  }

  /// 热门标签图表
  Widget _buildTopTagsChart(TagProvider tagProvider) {
    final tagUsage = <String, int>{};

    // 这里应该从真实数据计算，临时模拟
    tagUsage['开发'] = 25;
    tagUsage['会议'] = 18;
    tagUsage['设计'] = 15;
    tagUsage['测试'] = 12;
    tagUsage['文档'] = 8;

    final data = tagUsage.entries
        .take(5)
        .map(
          (entry) =>
              ChartPieData(label: entry.key, value: entry.value.toDouble()),
        )
        .toList();

    return CustomPieChart(data: data, showLegend: true, radius: 100);
  }

  /// 工作量概况卡片
  Widget _buildWorkloadSummaryCards() {
    final stats = _workloadStats!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatisticCard(
          title: '活跃天数',
          value: (stats['activeDays'] ?? 0).toString(),
          subtitle: '最近30天',
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
        StatisticCard(
          title: '平均日记录',
          value: (stats['avgEntriesPerDay'] ?? 0.0).toStringAsFixed(1),
          subtitle: '每日平均',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        StatisticCard(
          title: '总字符数',
          value: _formatNumber(stats['totalChars'] ?? 0),
          subtitle: '累计字符',
          icon: Icons.text_snippet,
          color: Colors.orange,
        ),
        StatisticCard(
          title: '平均字符数',
          value: _formatNumber((stats['avgCharsPerDay'] ?? 0.0).round()),
          subtitle: '每日平均',
          icon: Icons.analytics,
          color: Colors.purple,
        ),
      ],
    );
  }

  /// 每日工作量图表
  Widget _buildDailyWorkloadChart() {
    final dailyStats =
        (_workloadStats!['dailyStats'] as Map<String, dynamic>?) ?? {};
    final data = <ChartBarData>[];

    dailyStats.forEach((date, stats) {
      final entryCount = (stats as Map<String, dynamic>)['entryCount'] ?? 0;
      data.add(
        ChartBarData(label: date.split('-').last, value: entryCount.toDouble()),
      );
    });

    return CustomBarChart(
      data: data,
      maxY: data.isEmpty
          ? 10
          : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2,
      getBottomTitles: (value) {
        final index = value.toInt();
        return index < data.length ? data[index].label : '';
      },
    );
  }

  /// 周工作模式图表
  Widget _buildWeekdayWorkloadChart() {
    // 模拟一周数据
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final data = weekdays
        .asMap()
        .entries
        .map(
          (entry) => ChartBarData(
            label: entry.value,
            value: (5 + (entry.key * 2) % 8).toDouble(),
          ),
        )
        .toList();

    return CustomBarChart(
      data: data,
      maxY: 10,
      getBottomTitles: (value) {
        final index = value.toInt();
        return index < data.length ? data[index].label : '';
      },
    );
  }

  /// 标签使用饼图
  Widget _buildTagUsagePieChart() {
    final tagFrequency = (_tagStats!['tagFrequency'] as List<dynamic>?) ?? [];

    final data = tagFrequency.take(8).map((tag) {
      final tagMap = tag as Map<String, dynamic>;
      return ChartPieData(
        label: tagMap['name'] ?? '',
        value: (tagMap['usageCount'] ?? 0).toDouble(),
      );
    }).toList();

    return CustomPieChart(data: data, showLegend: true, radius: 120);
  }

  /// 标签使用排行
  Widget _buildTagUsageRanking() {
    final tagFrequency = (_tagStats!['tagFrequency'] as List<dynamic>?) ?? [];

    return ChartContainer(
      title: '标签使用排行',
      subtitle: '按使用次数排序',
      height: null,
      chart: Column(
        children: tagFrequency.take(10).map((tag) {
          final tagMap = tag as Map<String, dynamic>;
          final name = tagMap['name'] ?? '';
          final count = tagMap['usageCount'] ?? 0;
          final percentage = tagMap['percentage'] ?? 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        ChartConfig.primaryColors[tagFrequency.indexOf(tag) %
                            ChartConfig.primaryColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          ChartConfig.primaryColors[tagFrequency.indexOf(tag) %
                              ChartConfig.primaryColors.length],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 趋势概况
  Widget _buildTrendSummary() {
    final dailyTrend =
        (_trendData!['dailyTrend'] as Map<String, dynamic>?) ?? {};
    final direction = dailyTrend['direction'] ?? 'stable';
    final percentage = (dailyTrend['percentage'] ?? 0.0) as double;

    String trendText;
    Color trendColor;
    IconData trendIcon;

    switch (direction) {
      case 'increasing':
        trendText = '记录频率呈上升趋势';
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case 'decreasing':
        trendText = '记录频率呈下降趋势';
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      default:
        trendText = '记录频率保持稳定';
        trendColor = Colors.orange;
        trendIcon = Icons.trending_flat;
    }

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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(trendIcon, color: trendColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trendText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '变化幅度: ${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: trendColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 月度趋势图表
  Widget _buildMonthlyTrendChart() {
    // 模拟月度数据
    final months = ['1月', '2月', '3月', '4月', '5月', '6月'];
    final data = months
        .asMap()
        .entries
        .map(
          (entry) => ChartLineData(
            label: entry.value,
            value: (15 + entry.key * 3 + (entry.key % 2) * 5).toDouble(),
          ),
        )
        .toList();

    return CustomLineChart(
      data: data,
      showArea: true,
      curved: true,
      lineColor: Colors.purple,
    );
  }

  /// 预测建议
  Widget _buildPredictionSuggestions() {
    final suggestions = [
      {
        'icon': Icons.lightbulb,
        'title': '保持记录习惯',
        'description': '建议每天至少记录一条工作内容，有助于提高工作效率',
        'color': Colors.amber,
      },
      {
        'icon': Icons.trending_up,
        'title': '增加记录详度',
        'description': '适当增加记录的详细程度，有助于后续回顾和总结',
        'color': Colors.green,
      },
      {
        'icon': Icons.label,
        'title': '合理使用标签',
        'description': '建议为每条记录添加2-3个相关标签，便于分类管理',
        'color': Colors.blue,
      },
    ];

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (suggestion['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  suggestion['icon'] as IconData,
                  color: suggestion['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据筛选'),
        content: const Text('筛选功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 格式化数字
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
