import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:work_diary/services/database_helper.dart';
import 'package:work_diary/services/diary_service.dart';
import 'package:work_diary/services/tag_service.dart';
import 'package:work_diary/services/statistics_service.dart';
import 'package:work_diary/models/diary_entry.dart';
import 'package:work_diary/models/tag.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late DiaryService diaryService;
  late TagService tagService;
  late StatisticsService statisticsService;

  setUpAll(() {
    // 初始化 sqflite ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    databaseHelper = DatabaseHelper();
    diaryService = DiaryService();
    tagService = TagService();
    statisticsService = StatisticsService();
  });

  tearDown(() async {
    // 清理测试数据
    await databaseHelper.clearAllData();
    await databaseHelper.close();
  });

  group('DatabaseHelper Tests', () {
    test('should create database and tables', () async {
      final db = await databaseHelper.database;
      expect(db, isNotNull);

      // 验证表是否创建成功
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      final tableNames = tables.map((table) => table['name']).toList();
      expect(tableNames, contains('diary_entries'));
      expect(tableNames, contains('tags'));
      expect(tableNames, contains('diary_tags'));
    });
  });

  group('DiaryService Tests', () {
    test('should create and retrieve diary entry', () async {
      final now = DateTime.now();
      final diary = DiaryEntry(
        title: '测试日记',
        content: '这是一个测试日记的内容',
        date: now,
        tags: ['工作', '测试'],
        createdAt: now,
        updatedAt: now,
      );

      // 创建日记
      final id = await diaryService.createDiary(diary);
      expect(id, greaterThan(0));

      // 检索日记
      final retrievedDiary = await diaryService.getDiaryById(id);
      expect(retrievedDiary, isNotNull);
      expect(retrievedDiary!.title, equals('测试日记'));
      expect(retrievedDiary.content, equals('这是一个测试日记的内容'));
      expect(retrievedDiary.tags, contains('工作'));
      expect(retrievedDiary.tags, contains('测试'));
    });

    test('should update diary entry', () async {
      final now = DateTime.now();
      final diary = DiaryEntry(
        title: '原始标题',
        content: '原始内容',
        date: now,
        tags: ['标签1'],
        createdAt: now,
        updatedAt: now,
      );

      // 创建日记
      final id = await diaryService.createDiary(diary);

      // 更新日记
      final updatedDiary = DiaryEntry(
        id: id,
        title: '更新后的标题',
        content: '更新后的内容',
        date: now,
        tags: ['标签1', '标签2'],
        createdAt: now,
        updatedAt: DateTime.now(),
      );

      final result = await diaryService.updateDiary(updatedDiary);
      expect(result, equals(1));

      // 验证更新
      final retrievedDiary = await diaryService.getDiaryById(id);
      expect(retrievedDiary!.title, equals('更新后的标题'));
      expect(retrievedDiary.content, equals('更新后的内容'));
      expect(retrievedDiary.tags, contains('标签2'));
    });

    test('should delete diary entry', () async {
      final now = DateTime.now();
      final diary = DiaryEntry(
        title: '要删除的日记',
        content: '内容',
        date: now,
        tags: [],
        createdAt: now,
        updatedAt: now,
      );

      // 创建日记
      final id = await diaryService.createDiary(diary);

      // 删除日记
      final result = await diaryService.deleteDiary(id);
      expect(result, equals(1));

      // 验证删除
      final retrievedDiary = await diaryService.getDiaryById(id);
      expect(retrievedDiary, isNull);
    });

    test('should search diaries', () async {
      final now = DateTime.now();

      // 创建多个日记
      await diaryService.createDiary(
        DiaryEntry(
          title: 'Flutter 开发',
          content: '今天学习了 Flutter 的基础知识',
          date: now,
          tags: ['Flutter', '学习'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await diaryService.createDiary(
        DiaryEntry(
          title: 'Dart 语言',
          content: '深入了解 Dart 语言特性',
          date: now,
          tags: ['Dart', '学习'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await diaryService.createDiary(
        DiaryEntry(
          title: '工作总结',
          content: '完成了项目的重构工作',
          date: now,
          tags: ['工作'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 搜索包含 "Flutter" 的日记
      final flutterDiaries = await diaryService.searchDiaries('Flutter');
      expect(flutterDiaries.length, equals(1));
      expect(flutterDiaries.first.title, equals('Flutter 开发'));

      // 搜索包含 "学习" 的日记
      final learningDiaries = await diaryService.searchDiaries('学习');
      expect(learningDiaries.length, greaterThanOrEqualTo(1));
    });
  });

  group('TagService Tests', () {
    test('should create and retrieve tag', () async {
      final tag = Tag(
        name: '测试标签',
        color: '#FF0000',
        createdAt: DateTime.now(),
      );

      // 创建标签
      final id = await tagService.createTag(tag);
      expect(id, greaterThan(0));

      // 检索标签
      final retrievedTag = await tagService.getTagById(id);
      expect(retrievedTag, isNotNull);
      expect(retrievedTag!.name, equals('测试标签'));
      expect(retrievedTag.color, equals('#FF0000'));
    });

    test('should get or create tag', () async {
      // 第一次调用应该创建新标签
      final tag1 = await tagService.getOrCreateTag('新标签');
      expect(tag1.name, equals('新标签'));
      expect(tag1.id, isNotNull);

      // 第二次调用应该返回现有标签
      final tag2 = await tagService.getOrCreateTag('新标签');
      expect(tag2.id, equals(tag1.id));
    });

    test('should get popular tags', () async {
      // 创建一些标签
      await tagService.createTag(
        Tag(
          name: '热门标签1',
          color: '#FF0000',
          usageCount: 5,
          createdAt: DateTime.now(),
        ),
      );

      await tagService.createTag(
        Tag(
          name: '热门标签2',
          color: '#00FF00',
          usageCount: 3,
          createdAt: DateTime.now(),
        ),
      );

      await tagService.createTag(
        Tag(
          name: '冷门标签',
          color: '#0000FF',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
      );

      // 获取热门标签
      final popularTags = await tagService.getPopularTags(limit: 2);
      expect(popularTags.length, equals(2));
      expect(popularTags.first.name, equals('热门标签1'));
      expect(popularTags.last.name, equals('热门标签2'));
    });
  });

  group('StatisticsService Tests', () {
    test('should calculate basic statistics', () async {
      final now = DateTime.now();

      // 创建一些测试数据
      await diaryService.createDiary(
        DiaryEntry(
          title: '日记1',
          content: '内容1',
          date: now,
          tags: ['标签1', '标签2'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await diaryService.createDiary(
        DiaryEntry(
          title: '日记2',
          content: '内容2',
          date: now.subtract(const Duration(days: 1)),
          tags: ['标签1'],
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 获取统计数据
      final statistics = await statisticsService.getCompleteStatistics();

      expect(statistics.totalEntries, equals(2));
      expect(statistics.totalTags, greaterThan(0));
      expect(statistics.tagUsage.containsKey('标签1'), isTrue);
      expect(statistics.tagUsage.containsKey('标签2'), isTrue);
    });

    test('should calculate writing frequency', () async {
      final now = DateTime.now();

      // 创建一些测试数据
      await diaryService.createDiary(
        DiaryEntry(
          title: '日记1',
          content: '内容1',
          date: now,
          tags: [],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await diaryService.createDiary(
        DiaryEntry(
          title: '日记2',
          content: '内容2',
          date: now.subtract(const Duration(days: 1)),
          tags: [],
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 获取写作频率
      final frequency = await statisticsService.getWritingFrequency();

      expect(frequency['totalDays'], greaterThan(0));
      expect(frequency['writingDays'], equals(2));
      expect(frequency['averagePerDay'], greaterThan(0));
      expect(frequency['frequency'], greaterThan(0));
    });
  });
}
