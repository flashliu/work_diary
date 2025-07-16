import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库助手类
/// 负责数据库的初始化、版本管理和表结构创建
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// 数据库版本
  static const int _databaseVersion = 1;

  /// 数据库名称
  static const String _databaseName = 'work_diary.db';

  /// 表名
  static const String diaryTable = 'diary_entries';
  static const String tagTable = 'tags';
  static const String diaryTagTable = 'diary_tags';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 创建日记表
    await db.execute('''
      CREATE TABLE $diaryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        tags TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建标签表
    await db.execute('''
      CREATE TABLE $tagTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_used_at TEXT
      )
    ''');

    // 创建日记标签关联表
    await db.execute('''
      CREATE TABLE $diaryTagTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diary_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        FOREIGN KEY (diary_id) REFERENCES $diaryTable (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $tagTable (id) ON DELETE CASCADE,
        UNIQUE(diary_id, tag_id)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_diary_date ON $diaryTable (date)');
    await db.execute(
      'CREATE INDEX idx_diary_created_at ON $diaryTable (created_at)',
    );
    await db.execute('CREATE INDEX idx_tag_name ON $tagTable (name)');
    await db.execute(
      'CREATE INDEX idx_diary_tag_diary_id ON $diaryTagTable (diary_id)',
    );
    await db.execute(
      'CREATE INDEX idx_diary_tag_tag_id ON $diaryTagTable (tag_id)',
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // 根据版本号进行相应的升级操作
      // 例如：添加新字段、创建新表等
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(diaryTagTable);
      await txn.delete(diaryTable);
      await txn.delete(tagTable);
    });
  }

  /// 获取数据库路径
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), _databaseName);
  }

  /// 备份数据库
  Future<void> backupDatabase(String backupPath) async {
    // 实现数据库备份逻辑
    // 可以在后续版本中实现
  }

  /// 恢复数据库
  Future<void> restoreDatabase(String backupPath) async {
    // 实现数据库恢复逻辑
    // 可以在后续版本中实现
  }
}
