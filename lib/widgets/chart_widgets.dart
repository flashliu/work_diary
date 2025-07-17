import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_constants.dart';

/// 通用图表配置
abstract class ChartConfig {
  static const double defaultRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const Color defaultGridColor = Color(0xFFE0E0E0);
  static const Color defaultTextColor = AppColors.textSecondary;

  // 预定义颜色方案
  static const List<Color> primaryColors = [
    AppColors.primary,
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
  ];
}

/// 通用图表容器
class ChartContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final List<Widget>? actions;
  final double? height;
  final EdgeInsets? padding;

  const ChartContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.actions,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(ChartConfig.defaultPadding),
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
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: 16),
          // 图表内容
          SizedBox(height: height ?? 200, child: chart),
        ],
      ),
    );
  }
}

/// 自定义柱状图组件
class CustomBarChart extends StatelessWidget {
  final List<ChartBarData> data;
  final String? Function(double)? getBottomTitles;
  final double maxY;
  final bool showGrid;
  final Color? barColor;

  const CustomBarChart({
    super.key,
    required this.data,
    this.getBottomTitles,
    required this.maxY,
    this.showGrid = true,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: getBottomTitles != null,
              getTitlesWidget: (double value, TitleMeta meta) {
                final title = getBottomTitles?.call(value);
                return title != null
                    ? Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ChartConfig.defaultTextColor,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: ChartConfig.defaultGridColor,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.value,
            color:
                barColor ??
                ChartConfig.primaryColors[index %
                    ChartConfig.primaryColors.length],
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }
}

/// 自定义折线图组件
class CustomLineChart extends StatelessWidget {
  final List<ChartLineData> data;
  final bool showDots;
  final bool showArea;
  final bool curved;
  final Color? lineColor;

  const CustomLineChart({
    super.key,
    required this.data,
    this.showDots = false,
    this.showArea = true,
    this.curved = true,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _buildSpots(),
            isCurved: curved,
            color: lineColor ?? AppColors.primary,
            dotData: FlDotData(show: showDots),
            belowBarData: BarAreaData(
              show: showArea,
              color: (lineColor ?? AppColors.primary).withValues(alpha: 0.1),
            ),
            barWidth: 3,
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  barSpot.y.toStringAsFixed(1),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }
}

/// 自定义饼图组件
class CustomPieChart extends StatelessWidget {
  final List<ChartPieData> data;
  final bool showPercentage;
  final bool showLegend;
  final double radius;

  const CustomPieChart({
    super.key,
    required this.data,
    this.showPercentage = true,
    this.showLegend = true,
    this.radius = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: _buildSections(),
              centerSpaceRadius: 0,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
          ),
        ),
        if (showLegend) ...[const SizedBox(height: 16), _buildLegend()],
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = total > 0 ? (item.value / total * 100) : 0.0;

      return PieChartSectionData(
        color:
            item.color ??
            ChartConfig.primaryColors[index % ChartConfig.primaryColors.length],
        value: item.value,
        title: showPercentage ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final color =
            item.color ??
            ChartConfig.primaryColors[index % ChartConfig.primaryColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                color: ChartConfig.defaultTextColor,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// 数据模型
class ChartBarData {
  final String label;
  final double value;
  final Color? color;

  const ChartBarData({required this.label, required this.value, this.color});
}

class ChartLineData {
  final String label;
  final double value;
  final Color? color;

  const ChartLineData({required this.label, required this.value, this.color});
}

class ChartPieData {
  final String label;
  final double value;
  final Color? color;

  const ChartPieData({required this.label, required this.value, this.color});
}

/// 统计卡片组件
class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTrendColor(trend!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTrendColor(trend!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    if (trend.startsWith('+')) {
      return Colors.green;
    } else if (trend.startsWith('-')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
}
