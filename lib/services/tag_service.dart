import 'package:sqflite/sqflite.dart';
import '../models/tag.dart';
import 'database_helper.dart';

/// 标签数据操作服务
/// 负责标签的增删改查和标签使用统计
class TagService {
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;
  TagService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 创建标签
  Future<int> createTag(Tag tag) async {
    final db = await _databaseHelper.database;

    return await db.insert(
      DatabaseHelper.tagTable,
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新标签
  Future<int> updateTag(Tag tag) async {
    final db = await _databaseHelper.database;

    return await db.update(
      DatabaseHelper.tagTable,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// 删除标签
  Future<int> deleteTag(int id) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 删除标签关联
      await txn.delete(
        DatabaseHelper.diaryTagTable,
        where: 'tag_id = ?',
        whereArgs: [id],
      );

      // 删除标签
      return await txn.delete(
        DatabaseHelper.tagTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// 获取标签详情
  Future<Tag?> getTagById(int id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Tag.fromMap(maps.first);
    }
    return null;
  }

  /// 根据名称获取标签
  Future<Tag?> getTagByName(String name) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      return Tag.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有标签
  Future<List<Tag>> getAllTags({
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      orderBy: orderBy ?? 'usage_count DESC, name ASC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  /// 搜索标签
  Future<List<Tag>> searchTags(String keyword) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'usage_count DESC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  /// 获取热门标签
  Future<List<Tag>> getPopularTags({int limit = 10}) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      where: 'usage_count > 0',
      orderBy: 'usage_count DESC, last_used_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  /// 获取最近使用的标签
  Future<List<Tag>> getRecentlyUsedTags({int limit = 10}) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      where: 'last_used_at IS NOT NULL',
      orderBy: 'last_used_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  /// 获取未使用的标签
  Future<List<Tag>> getUnusedTags() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      where: 'usage_count = 0',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Tag.fromMap(maps[i]);
    });
  }

  /// 获取标签使用统计
  Future<Map<String, int>> getTagUsageStatistics() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tagTable,
      columns: ['name', 'usage_count'],
      where: 'usage_count > 0',
      orderBy: 'usage_count DESC',
    );

    final Map<String, int> statistics = {};
    for (final map in maps) {
      statistics[map['name'] as String] = map['usage_count'] as int;
    }

    return statistics;
  }

  /// 获取标签总数
  Future<int> getTagCount() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tagTable}',
    );

    return result.first['count'] as int;
  }

  /// 增加标签使用次数
  Future<void> incrementTagUsage(String tagName) async {
    final db = await _databaseHelper.database;

    await db.rawUpdate(
      '''
      UPDATE ${DatabaseHelper.tagTable}
      SET usage_count = usage_count + 1,
          last_used_at = ?
      WHERE name = ?
    ''',
      [DateTime.now().toIso8601String(), tagName],
    );
  }

  /// 减少标签使用次数
  Future<void> decrementTagUsage(String tagName) async {
    final db = await _databaseHelper.database;

    await db.rawUpdate(
      '''
      UPDATE ${DatabaseHelper.tagTable}
      SET usage_count = CASE 
        WHEN usage_count > 0 THEN usage_count - 1
        ELSE 0
      END
      WHERE name = ?
    ''',
      [tagName],
    );
  }

  /// 批量创建标签
  Future<List<int>> createTags(List<Tag> tags) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      final List<int> ids = [];
      for (final tag in tags) {
        final id = await txn.insert(
          DatabaseHelper.tagTable,
          tag.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        ids.add(id);
      }
      return ids;
    });
  }

  /// 获取或创建标签
  Future<Tag> getOrCreateTag(String name, {String? color}) async {
    final existing = await getTagByName(name);
    if (existing != null) {
      return existing;
    }

    final tag = Tag(
      name: name,
      color: color ?? _getRandomTagColor(),
      usageCount: 0,
      createdAt: DateTime.now(),
    );

    final id = await createTag(tag);
    return tag.copyWith(id: id);
  }

  /// 清理未使用的标签
  Future<int> cleanupUnusedTags() async {
    final db = await _databaseHelper.database;

    return await db.delete(DatabaseHelper.tagTable, where: 'usage_count = 0');
  }

  /// 重新计算标签使用统计
  Future<void> recalculateTagUsage() async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // 重置所有标签的使用次数
      await txn.update(DatabaseHelper.tagTable, {
        'usage_count': 0,
        'last_used_at': null,
      });

      // 重新计算使用次数
      await txn.rawUpdate('''
        UPDATE ${DatabaseHelper.tagTable}
        SET usage_count = (
          SELECT COUNT(*)
          FROM ${DatabaseHelper.diaryTagTable}
          WHERE tag_id = ${DatabaseHelper.tagTable}.id
        )
      ''');

      // 更新最后使用时间
      await txn.rawUpdate('''
        UPDATE ${DatabaseHelper.tagTable}
        SET last_used_at = (
          SELECT MAX(d.created_at)
          FROM ${DatabaseHelper.diaryTable} d
          JOIN ${DatabaseHelper.diaryTagTable} dt ON d.id = dt.diary_id
          WHERE dt.tag_id = ${DatabaseHelper.tagTable}.id
        )
        WHERE usage_count > 0
      ''');
    });
  }

  /// 获取随机标签颜色
  String _getRandomTagColor() {
    final colors = [
      '#3B82F6', // 蓝色
      '#10B981', // 绿色
      '#F59E0B', // 黄色
      '#EF4444', // 红色
      '#8B5CF6', // 紫色
      '#06B6D4', // 青色
      '#EC4899', // 粉色
      '#84CC16', // 青绿色
    ];

    return colors[DateTime.now().microsecondsSinceEpoch % colors.length];
  }

  /// 获取标签颜色选项
  List<String> getTagColorOptions() {
    return [
      '#3B82F6', // 蓝色
      '#10B981', // 绿色
      '#F59E0B', // 黄色
      '#EF4444', // 红色
      '#8B5CF6', // 紫色
      '#06B6D4', // 青色
      '#EC4899', // 粉色
      '#84CC16', // 青绿色
      '#F97316', // 橙色
      '#6366F1', // 靛蓝
      '#EC4899', // 玫瑰红
      '#22C55E', // 明绿色
    ];
  }
}
