import 'package:flutter_test/flutter_test.dart';
import 'package:work_diary/services/workload_statistics_service.dart';
import 'package:work_diary/services/tag_analysis_service.dart';
import 'package:work_diary/services/file_share_service.dart';
import 'package:work_diary/widgets/chart_widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('阶段五功能测试', () {
    setUpAll(() {
      // 初始化 SQLite FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    group('工作量统计服务测试', () {
      late WorkloadStatisticsService workloadService;

      setUp(() {
        workloadService = WorkloadStatisticsService();
      });

      test('应该能够获取每日工作量统计', () async {
        final result = await workloadService.getDailyWorkloadStatistics();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('dailyStats'), isTrue);
        expect(result.containsKey('totalEntries'), isTrue);
        expect(result.containsKey('totalChars'), isTrue);
      });

      test('应该能够获取每周工作量统计', () async {
        final result = await workloadService.getWeeklyWorkloadStatistics();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('weeklyStats'), isTrue);
        expect(result.containsKey('totalEntries'), isTrue);
      });

      test('应该能够获取每月工作量统计', () async {
        final result = await workloadService.getMonthlyWorkloadStatistics();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('monthlyStats'), isTrue);
        expect(result.containsKey('activeMonths'), isTrue);
      });

      test('应该能够获取趋势分析', () async {
        final result = await workloadService.getTrendAnalysis();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('dailyTrend'), isTrue);
        expect(result.containsKey('weeklyTrend'), isTrue);
        expect(result.containsKey('monthlyTrend'), isTrue);
      });

      test('应该能够获取对比分析', () async {
        final result = await workloadService.getComparisonAnalysis();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('weekComparison'), isTrue);
        expect(result.containsKey('monthComparison'), isTrue);
      });

      test('应该能够获取生产力指标', () async {
        final result = await workloadService.getProductivityMetrics();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('hourlyActivity'), isTrue);
        expect(result.containsKey('weekdayActivity'), isTrue);
        expect(result.containsKey('averageEfficiency'), isTrue);
      });
    });

    group('标签分析服务测试', () {
      late TagAnalysisService tagAnalysisService;

      setUp(() {
        tagAnalysisService = TagAnalysisService();
      });

      test('应该能够获取标签使用频率统计', () async {
        final result = await tagAnalysisService.getTagUsageFrequency();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('tagFrequency'), isTrue);
        expect(result.containsKey('totalTags'), isTrue);
        expect(result.containsKey('totalUsage'), isTrue);
      });

      test('应该能够获取标签共现分析', () async {
        final result = await tagAnalysisService.getTagCooccurrenceAnalysis();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('cooccurrence'), isTrue);
        expect(result.containsKey('topTagPairs'), isTrue);
      });

      test('应该能够获取标签关联分析', () async {
        final result = await tagAnalysisService.getTagCorrelationAnalysis();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('correlations'), isTrue);
        expect(result.containsKey('strongCorrelations'), isTrue);
      });

      test('应该能够获取标签使用模式分析', () async {
        final result = await tagAnalysisService.getTagUsagePatterns();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('monthlyPatterns'), isTrue);
        expect(result.containsKey('weekdayPatterns'), isTrue);
      });

      test('应该能够获取标签演化分析', () async {
        final result = await tagAnalysisService.getTagEvolutionAnalysis();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('tagLifecycle'), isTrue);
        expect(result.containsKey('statusCounts'), isTrue);
      });

      test('应该能够获取标签效果分析', () async {
        final result = await tagAnalysisService.getTagEffectivenessAnalysis();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('taggedVsUntagged'), isTrue);
        expect(result.containsKey('tagCountImpact'), isTrue);
      });
    });

    group('文件分享服务测试', () {
      late FileShareService fileShareService;

      setUp(() {
        fileShareService = FileShareService();
      });

      test('应该能够创建文件分享服务实例', () {
        expect(fileShareService, isNotNull);
        expect(fileShareService, isA<FileShareService>());
      });

      test('应该能够格式化文件大小', () {
        final size1 = fileShareService.formatFileSize(1024);
        expect(size1, equals('1.0KB'));

        final size2 = fileShareService.formatFileSize(1048576);
        expect(size2, equals('1.0MB'));

        final size3 = fileShareService.formatFileSize(1073741824);
        expect(size3, equals('1.0GB'));
      });
    });
  });

  group('图表组件数据模型测试', () {
    test('ChartBarData 应该正确创建', () {
      final data = ChartBarData(label: 'Test Label', value: 10.5);

      expect(data.label, equals('Test Label'));
      expect(data.value, equals(10.5));
      expect(data.color, isNull);
    });

    test('ChartLineData 应该正确创建', () {
      final data = ChartLineData(label: 'Line Data', value: 25.0);

      expect(data.label, equals('Line Data'));
      expect(data.value, equals(25.0));
      expect(data.color, isNull);
    });

    test('ChartPieData 应该正确创建', () {
      final data = ChartPieData(label: 'Pie Slice', value: 15.5);

      expect(data.label, equals('Pie Slice'));
      expect(data.value, equals(15.5));
      expect(data.color, isNull);
    });
  });
}
