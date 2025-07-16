import 'package:sqflite/sqflite.dart';
import '../models/diary_entry.dart';
import '../models/tag.dart';
import 'database_helper.dart';

/// 日记数据操作服务
/// 负责日记相关的CRUD操作、搜索和筛选功能
class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 创建日记
  Future<int> createDiary(DiaryEntry diary) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 插入日记
      final diaryId = await txn.insert(
        DatabaseHelper.diaryTable,
        diary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 处理标签关联
      if (diary.tags.isNotEmpty) {
        await _updateDiaryTags(txn, diaryId, diary.tags);
      }

      return diaryId;
    });
  }

  /// 更新日记
  Future<int> updateDiary(DiaryEntry diary) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 更新日记
      final result = await txn.update(
        DatabaseHelper.diaryTable,
        diary.toMap(),
        where: 'id = ?',
        whereArgs: [diary.id],
      );

      // 更新标签关联
      if (diary.id != null) {
        await _updateDiaryTags(txn, diary.id!, diary.tags);
      }

      return result;
    });
  }

  /// 删除日记
  Future<int> deleteDiary(int id) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 删除标签关联
      await txn.delete(
        DatabaseHelper.diaryTagTable,
        where: 'diary_id = ?',
        whereArgs: [id],
      );

      // 删除日记
      return await txn.delete(
        DatabaseHelper.diaryTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// 获取日记详情
  Future<DiaryEntry?> getDiaryById(int id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diaryTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return DiaryEntry.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有日记
  Future<List<DiaryEntry>> getAllDiaries({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diaryTable,
      orderBy: orderBy ?? 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 按日期获取日记
  Future<List<DiaryEntry>> getDiariesByDate(DateTime date) async {
    final db = await _databaseHelper.database;

    final String dateStr = date.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diaryTable,
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 按日期范围获取日记
  Future<List<DiaryEntry>> getDiariesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    final String startDateStr = startDate.toIso8601String().split('T')[0];
    final String endDateStr = endDate.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diaryTable,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 搜索日记
  Future<List<DiaryEntry>> searchDiaries(String keyword) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diaryTable,
      where: 'title LIKE ? OR content LIKE ? OR notes LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'date DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 按标签筛选日记
  Future<List<DiaryEntry>> getDiariesByTag(String tagName) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT d.* FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      JOIN ${DatabaseHelper.tagTable} t ON dt.tag_id = t.id
      WHERE t.name = ?
      ORDER BY d.date DESC, d.created_at DESC
    ''',
      [tagName],
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 按多个标签筛选日记
  Future<List<DiaryEntry>> getDiariesByTags(List<String> tagNames) async {
    if (tagNames.isEmpty) return [];

    final db = await _databaseHelper.database;

    final String placeholders = tagNames.map((_) => '?').join(',');

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT d.* FROM ${DatabaseHelper.diaryTable} d
      JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
      JOIN ${DatabaseHelper.tagTable} t ON dt.tag_id = t.id
      WHERE t.name IN ($placeholders)
      GROUP BY d.id
      HAVING COUNT(DISTINCT t.name) = ?
      ORDER BY d.date DESC, d.created_at DESC
    ''',
      [...tagNames, tagNames.length],
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 获取日记统计数据
  Future<Map<String, int>> getDiaryStatistics() async {
    final db = await _databaseHelper.database;

    // 总日记数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.diaryTable}',
    );
    final int totalCount = totalResult.first['count'] as int;

    // 本周日记数
    final DateTime now = DateTime.now();
    final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    final String weekStartStr = weekStart.toIso8601String().split('T')[0];

    final weekResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.diaryTable}
      WHERE date >= ?
    ''',
      [weekStartStr],
    );
    final int weekCount = weekResult.first['count'] as int;

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
    final int monthCount = monthResult.first['count'] as int;

    return {
      'total': totalCount,
      'thisWeek': weekCount,
      'thisMonth': monthCount,
    };
  }

  /// 获取最近的日记
  Future<List<DiaryEntry>> getRecentDiaries(int limit) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.diaryTable,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return DiaryEntry.fromMap(maps[i]);
    });
  }

  /// 更新日记标签关联
  Future<void> _updateDiaryTags(
    Transaction txn,
    int diaryId,
    List<String> tagNames,
  ) async {
    // 删除现有的标签关联
    await txn.delete(
      DatabaseHelper.diaryTagTable,
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );

    // 添加新的标签关联
    for (final tagName in tagNames) {
      // 获取或创建标签
      final List<Map<String, dynamic>> existingTags = await txn.query(
        DatabaseHelper.tagTable,
        where: 'name = ?',
        whereArgs: [tagName],
      );

      int tagId;
      if (existingTags.isNotEmpty) {
        tagId = existingTags.first['id'] as int;

        // 更新标签使用次数和最后使用时间
        await txn.update(
          DatabaseHelper.tagTable,
          {
            'usage_count': (existingTags.first['usage_count'] as int) + 1,
            'last_used_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [tagId],
        );
      } else {
        // 创建新标签
        final tag = Tag(
          name: tagName,
          color: '#3B82F6', // 默认蓝色
          usageCount: 1,
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        tagId = await txn.insert(DatabaseHelper.tagTable, tag.toMap());
      }

      // 创建关联
      await txn.insert(DatabaseHelper.diaryTagTable, {
        'diary_id': diaryId,
        'tag_id': tagId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// 获取日记的标签
  Future<List<Tag>> getDiaryTags(int diaryId) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT t.* FROM ${DatabaseHelper.tagTable} t
      JOIN ${DatabaseHelper.diaryTagTable} dt ON t.id = dt.tag_id
      WHERE dt.diary_id = ?
      ORDER BY t.name
    ''',
      [diaryId],
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }
}
