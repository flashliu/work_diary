// 颜色常量
import 'package:flutter/material.dart';

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
