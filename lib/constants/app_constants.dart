// 应用常量
import 'package:flutter/material.dart';

/// 应用常量类
/// 包含颜色常量、文本常量、配置常量等
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  // =========================== 颜色常量 ===========================

  /// 主色调渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  /// 标签颜色列表
  static const List<Color> tagColors = [
    Color(0xFF667EEA), // 蓝色
    Color(0xFF764BA2), // 紫色
    Color(0xFF4ECDC4), // 青色
    Color(0xFF96CEB4), // 绿色
    Color(0xFFFFEAA7), // 黄色
    Color(0xFFFF6B6B), // 红色
    Color(0xFFFFB347), // 橙色
    Color(0xFFDDA0DD), // 紫罗兰色
    Color(0xFF87CEEB), // 天蓝色
    Color(0xFF98FB98), // 浅绿色
    Color(0xFFF0E68C), // 卡其色
    Color(0xFFDEB887), // 棕色
  ];

  // =========================== 文本常量 ===========================

  /// 应用名称
  static const String appName = '工作日记';
  static const String appSubtitle = '记录每一天的工作成长';

  /// 页面标题
  static const String homeTitle = '首页';
  static const String addDiaryTitle = '添加日记';
  static const String editDiaryTitle = '编辑日记';
  static const String diaryDetailTitle = '日记详情';
  static const String calendarTitle = '日历';
  static const String statisticsTitle = '统计';
  static const String exportTitle = '导出';
  static const String settingsTitle = '设置';
  static const String tagsTitle = '标签管理';

  /// 按钮文本
  static const String saveButton = '保存';
  static const String cancelButton = '取消';
  static const String deleteButton = '删除';
  static const String editButton = '编辑';
  static const String addButton = '添加';
  static const String exportButton = '导出';
  static const String shareButton = '分享';
  static const String searchButton = '搜索';
  static const String filterButton = '筛选';
  static const String sortButton = '排序';
  static const String confirmButton = '确认';

  /// 输入框提示文本
  static const String titleHint = '请输入日记标题';
  static const String contentHint = '请输入日记内容';
  static const String notesHint = '请输入备注';
  static const String tagHint = '请输入标签';
  static const String searchHint = '搜索日记';

  /// 空状态文本
  static const String emptyDiaryList = '暂无日记记录\n点击右下角按钮添加第一篇日记';
  static const String emptySearchResult = '未找到相关日记';
  static const String emptyTagList = '暂无标签';

  /// 错误提示文本
  static const String networkError = '网络连接失败，请检查网络设置';
  static const String serverError = '服务器错误，请稍后重试';
  static const String unknownError = '未知错误，请联系客服';
  static const String exportError = '导出失败';

  /// 成功提示文本
  static const String saveSuccess = '保存成功';
  static const String deleteSuccess = '删除成功';
  static const String exportSuccess = '导出成功';

  // =========================== 配置常量 ===========================

  /// 分页配置
  static const int pageSize = 20;

  /// 内容配置
  static const int maxTitleLength = 100;
  static const int maxContentLength = 10000;
  static const int maxNotesLength = 500;
  static const int maxTagLength = 20;
  static const int maxTagsPerEntry = 10;

  /// 动画配置
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // =========================== 尺寸常量 ===========================

  /// 边距
  static const double smallMargin = 8.0;
  static const double mediumMargin = 16.0;
  static const double largeMargin = 24.0;

  /// 圆角
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;

  /// 高度
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardHeight = 120.0;
  static const double fabSize = 56.0;

  // =========================== 图标常量 ===========================

  /// 导航图标
  static const IconData homeIcon = Icons.home;
  static const IconData calendarIcon = Icons.calendar_today;
  static const IconData statisticsIcon = Icons.bar_chart;
  static const IconData profileIcon = Icons.person;

  /// 操作图标
  static const IconData addIcon = Icons.add;
  static const IconData editIcon = Icons.edit;
  static const IconData deleteIcon = Icons.delete;
  static const IconData saveIcon = Icons.save;
  static const IconData shareIcon = Icons.share;
  static const IconData exportIcon = Icons.download;
  static const IconData searchIcon = Icons.search;
  static const IconData filterIcon = Icons.filter_list;
  static const IconData sortIcon = Icons.sort;
  static const IconData settingsIcon = Icons.settings;
  static const IconData backIcon = Icons.arrow_back;
  static const IconData tagIcon = Icons.local_offer;

  // =========================== 工具方法 ===========================

  /// 获取随机标签颜色
  static Color getRandomTagColor() {
    return tagColors[(DateTime.now().millisecondsSinceEpoch %
        tagColors.length)];
  }

  /// 获取对比色（用于在彩色背景上显示文本）
  static Color getContrastColor(Color backgroundColor) {
    // 计算颜色的亮度
    final brightness =
        ((backgroundColor.r * 255.0).round() * 299 +
            (backgroundColor.g * 255.0).round() * 587 +
            (backgroundColor.b * 255.0).round() * 114) /
        (255 * 1000);

    // 根据亮度返回黑色或白色
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  /// 截断文本
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// 验证输入
  static bool isValidInput(String? value, {int? minLength, int? maxLength}) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final trimmed = value.trim();

    if (minLength != null && trimmed.length < minLength) {
      return false;
    }

    if (maxLength != null && trimmed.length > maxLength) {
      return false;
    }

    return true;
  }
}

/// 保持向后兼容的颜色类
class AppColors {
  // 主色调 - 紫蓝色渐变
  static const Color primary = Color(0xFF667eea);
  static const Color primaryDark = Color(0xFF764ba2);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  // 背景色
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // 文本色
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // 状态色
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // 标签色
  static const List<Color> tagColors = [
    Color(0xFF3B82F6), // 蓝色
    Color(0xFF10B981), // 绿色
    Color(0xFFF59E0B), // 黄色
    Color(0xFFEF4444), // 红色
    Color(0xFF8B5CF6), // 紫色
    Color(0xFF06B6D4), // 青色
    Color(0xFFEC4899), // 粉色
    Color(0xFF84CC16), // 青绿色
  ];

  // 边框色
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // 阴影色
  static const Color shadow = Color(0x0F000000);
  static const Color shadowLight = Color(0x05000000);
}

// 文本样式常量
class AppTextStyles {
  // 标题样式
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // 正文样式
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );

  // 按钮样式
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}

// 间距常量
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// 圆角常量
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double circle = 1000.0;
}

// 阴影常量
class AppShadows {
  static const BoxShadow light = BoxShadow(
    color: AppColors.shadowLight,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow heavy = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}

// 应用配置常量
class AppConfig {
  static const String appName = '工作日记';
  static const String appVersion = '1.0.0';
  static const String dbName = 'work_diary.db';
  static const int dbVersion = 1;

  // 分页配置
  static const int pageSize = 20;
  static const int searchDelay = 300; // 毫秒

  // 导出配置
  static const int maxExportDays = 365;
  static const List<String> exportFormats = ['PDF', 'Excel'];

  // 标签配置
  static const int maxTagLength = 20;
  static const int maxTagCount = 10;

  // 日记配置
  static const int maxTitleLength = 100;
  static const int maxContentLength = 5000;
}

/// 导出格式枚举
enum ExportFormat { word, excel }

/// 日期范围枚举
enum DateRange { all, thisMonth, lastMonth, thisWeek, lastWeek, custom }

/// 排序方式枚举
enum SortOrder { newest, oldest }

/// 导出状态枚举
enum ExportStatus { idle, preparing, exporting, completed, error }
