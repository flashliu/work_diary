import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// 应用状态管理类
/// 负责管理主题设置、用户偏好设置等全局状态
class AppProvider extends ChangeNotifier {
  // 主题设置
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;

  // 用户偏好设置
  String _language = 'zh';
  double _fontSize = 16.0;
  bool _enableNotifications = true;
  bool _enableAutoBackup = false;
  int _autoBackupInterval = 7; // 天

  // 显示设置
  bool _showWelcomeScreen = true;
  bool _showHelpTips = true;
  DiaryListViewType _listViewType = DiaryListViewType.card;

  // 导出设置
  ExportFormat _defaultExportFormat = ExportFormat.word;
  bool _includeTagsInExport = true;
  bool _includeNotesInExport = true;

  // 安全设置
  bool _enablePinLock = false;
  String? _pinCode;

  // 数据统计
  DateTime? _lastBackupTime;
  int _totalDiaryCount = 0;
  int _totalTagCount = 0;

  // SharedPreferences 键名
  static const String _themeModeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _languageKey = 'language';
  static const String _fontSizeKey = 'font_size';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _enableAutoBackupKey = 'enable_auto_backup';
  static const String _autoBackupIntervalKey = 'auto_backup_interval';
  static const String _showWelcomeScreenKey = 'show_welcome_screen';
  static const String _showHelpTipsKey = 'show_help_tips';
  static const String _listViewTypeKey = 'list_view_type';
  static const String _defaultExportFormatKey = 'default_export_format';
  static const String _includeTagsInExportKey = 'include_tags_in_export';
  static const String _includeNotesInExportKey = 'include_notes_in_export';
  static const String _enablePinLockKey = 'enable_pin_lock';
  static const String _pinCodeKey = 'pin_code';
  static const String _lastBackupTimeKey = 'last_backup_time';
  static const String _totalDiaryCountKey = 'total_diary_count';
  static const String _totalTagCountKey = 'total_tag_count';

  // 预定义的主题颜色
  static const List<Color> themeColors = [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  String get language => _language;
  double get fontSize => _fontSize;
  bool get enableNotifications => _enableNotifications;
  bool get enableAutoBackup => _enableAutoBackup;
  int get autoBackupInterval => _autoBackupInterval;
  bool get showWelcomeScreen => _showWelcomeScreen;
  bool get showHelpTips => _showHelpTips;
  DiaryListViewType get listViewType => _listViewType;
  ExportFormat get defaultExportFormat => _defaultExportFormat;
  bool get includeTagsInExport => _includeTagsInExport;
  bool get includeNotesInExport => _includeNotesInExport;
  bool get enablePinLock => _enablePinLock;
  String? get pinCode => _pinCode;
  DateTime? get lastBackupTime => _lastBackupTime;
  int get totalDiaryCount => _totalDiaryCount;
  int get totalTagCount => _totalTagCount;

  // 获取当前主题数据
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _primaryColor,
      brightness: Brightness.light,
      fontFamily: 'System',
      textTheme: _getTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _primaryColor,
      brightness: Brightness.dark,
      fontFamily: 'System',
      textTheme: _getTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// 初始化设置
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// 设置主题颜色
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.toARGB32());
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  /// 设置字体大小
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  /// 设置通知开关
  Future<void> setEnableNotifications(bool enable) async {
    _enableNotifications = enable;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableNotificationsKey, enable);
  }

  /// 设置自动备份
  Future<void> setEnableAutoBackup(bool enable) async {
    _enableAutoBackup = enable;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableAutoBackupKey, enable);
  }

  /// 设置自动备份间隔
  Future<void> setAutoBackupInterval(int days) async {
    _autoBackupInterval = days;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoBackupIntervalKey, days);
  }

  /// 设置欢迎屏幕显示
  Future<void> setShowWelcomeScreen(bool show) async {
    _showWelcomeScreen = show;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showWelcomeScreenKey, show);
  }

  /// 设置帮助提示显示
  Future<void> setShowHelpTips(bool show) async {
    _showHelpTips = show;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showHelpTipsKey, show);
  }

  /// 设置列表视图类型
  Future<void> setListViewType(DiaryListViewType type) async {
    _listViewType = type;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listViewTypeKey, type.name);
  }

  /// 设置默认导出格式
  Future<void> setDefaultExportFormat(ExportFormat format) async {
    _defaultExportFormat = format;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultExportFormatKey, format.name);
  }

  /// 设置导出包含标签
  Future<void> setIncludeTagsInExport(bool include) async {
    _includeTagsInExport = include;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_includeTagsInExportKey, include);
  }

  /// 设置导出包含备注
  Future<void> setIncludeNotesInExport(bool include) async {
    _includeNotesInExport = include;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_includeNotesInExportKey, include);
  }

  /// 设置PIN锁定
  Future<void> setEnablePinLock(bool enable) async {
    _enablePinLock = enable;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enablePinLockKey, enable);
  }

  /// 设置PIN码
  Future<void> setPinCode(String? pin) async {
    _pinCode = pin;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (pin != null) {
      await prefs.setString(_pinCodeKey, pin);
    } else {
      await prefs.remove(_pinCodeKey);
    }
  }

  /// 更新最后备份时间
  Future<void> updateLastBackupTime() async {
    _lastBackupTime = DateTime.now();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastBackupTimeKey,
      _lastBackupTime!.toIso8601String(),
    );
  }

  /// 更新统计数据
  Future<void> updateStatistics(int diaryCount, int tagCount) async {
    _totalDiaryCount = diaryCount;
    _totalTagCount = tagCount;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalDiaryCountKey, diaryCount);
    await prefs.setInt(_totalTagCountKey, tagCount);
  }

  /// 重置所有设置
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 重置为默认值
    _themeMode = ThemeMode.system;
    _primaryColor = Colors.blue;
    _language = 'zh';
    _fontSize = 16.0;
    _enableNotifications = true;
    _enableAutoBackup = false;
    _autoBackupInterval = 7;
    _showWelcomeScreen = true;
    _showHelpTips = true;
    _listViewType = DiaryListViewType.card;
    _defaultExportFormat = ExportFormat.word;
    _includeTagsInExport = true;
    _includeNotesInExport = true;
    _enablePinLock = false;
    _pinCode = null;
    _lastBackupTime = null;
    _totalDiaryCount = 0;
    _totalTagCount = 0;

    notifyListeners();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载主题设置
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }

    final primaryColorValue = prefs.getInt(_primaryColorKey);
    if (primaryColorValue != null) {
      _primaryColor = Color(primaryColorValue);
    }

    // 加载用户偏好
    _language = prefs.getString(_languageKey) ?? 'zh';
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 16.0;
    _enableNotifications = prefs.getBool(_enableNotificationsKey) ?? true;
    _enableAutoBackup = prefs.getBool(_enableAutoBackupKey) ?? false;
    _autoBackupInterval = prefs.getInt(_autoBackupIntervalKey) ?? 7;

    // 加载显示设置
    _showWelcomeScreen = prefs.getBool(_showWelcomeScreenKey) ?? true;
    _showHelpTips = prefs.getBool(_showHelpTipsKey) ?? true;

    final listViewTypeString = prefs.getString(_listViewTypeKey);
    if (listViewTypeString != null) {
      _listViewType = DiaryListViewType.values.firstWhere(
        (type) => type.name == listViewTypeString,
        orElse: () => DiaryListViewType.card,
      );
    }

    // 加载导出设置
    final exportFormatString = prefs.getString(_defaultExportFormatKey);
    if (exportFormatString != null) {
      _defaultExportFormat = ExportFormat.values.firstWhere(
        (format) => format.name == exportFormatString,
        orElse: () => ExportFormat.word,
      );
    }

    _includeTagsInExport = prefs.getBool(_includeTagsInExportKey) ?? true;
    _includeNotesInExport = prefs.getBool(_includeNotesInExportKey) ?? true;

    // 加载安全设置
    _enablePinLock = prefs.getBool(_enablePinLockKey) ?? false;
    _pinCode = prefs.getString(_pinCodeKey);

    // 加载统计数据
    final lastBackupTimeString = prefs.getString(_lastBackupTimeKey);
    if (lastBackupTimeString != null) {
      _lastBackupTime = DateTime.parse(lastBackupTimeString);
    }

    _totalDiaryCount = prefs.getInt(_totalDiaryCountKey) ?? 0;
    _totalTagCount = prefs.getInt(_totalTagCountKey) ?? 0;
  }

  /// 获取文本主题
  TextTheme _getTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(fontSize: _fontSize + 16),
      displayMedium: TextStyle(fontSize: _fontSize + 12),
      displaySmall: TextStyle(fontSize: _fontSize + 8),
      headlineLarge: TextStyle(fontSize: _fontSize + 6),
      headlineMedium: TextStyle(fontSize: _fontSize + 4),
      headlineSmall: TextStyle(fontSize: _fontSize + 2),
      titleLarge: TextStyle(fontSize: _fontSize + 2),
      titleMedium: TextStyle(fontSize: _fontSize),
      titleSmall: TextStyle(fontSize: _fontSize - 2),
      bodyLarge: TextStyle(fontSize: _fontSize),
      bodyMedium: TextStyle(fontSize: _fontSize - 2),
      bodySmall: TextStyle(fontSize: _fontSize - 4),
      labelLarge: TextStyle(fontSize: _fontSize - 2),
      labelMedium: TextStyle(fontSize: _fontSize - 4),
      labelSmall: TextStyle(fontSize: _fontSize - 6),
    );
  }
}

/// 日记列表视图类型
enum DiaryListViewType { card, list, grid }

/// 枚举扩展
extension DiaryListViewTypeExtension on DiaryListViewType {
  String get displayName {
    switch (this) {
      case DiaryListViewType.card:
        return '卡片视图';
      case DiaryListViewType.list:
        return '列表视图';
      case DiaryListViewType.grid:
        return '网格视图';
    }
  }

  IconData get icon {
    switch (this) {
      case DiaryListViewType.card:
        return Icons.view_agenda;
      case DiaryListViewType.list:
        return Icons.view_list;
      case DiaryListViewType.grid:
        return Icons.view_module;
    }
  }
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.word:
        return 'Word';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.excel:
        return '.xlsx';
      case ExportFormat.word:
        return '.docx';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.excel:
        return Icons.table_chart;
      case ExportFormat.word:
        return Icons.description;
    }
  }
}
