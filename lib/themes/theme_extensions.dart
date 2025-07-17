import 'package:flutter/material.dart';

/// 深色主题扩展
extension ThemeModeExtension on ThemeMode {
  /// 获取主题模式的显示名称
  String get displayName {
    switch (this) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  /// 获取主题模式的图标
  IconData get icon {
    switch (this) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  /// 获取主题模式的描述
  String get description {
    switch (this) {
      case ThemeMode.light:
        return '始终使用浅色主题';
      case ThemeMode.dark:
        return '始终使用深色主题';
      case ThemeMode.system:
        return '根据系统设置自动切换';
    }
  }
}

/// 主题颜色扩展
extension ThemeColorExtension on Color {
  /// 获取颜色的显示名称
  String get displayName {
    if (this == Colors.blue) return '蓝色';
    if (this == Colors.purple) return '紫色';
    if (this == Colors.green) return '绿色';
    if (this == Colors.orange) return '橙色';
    if (this == Colors.red) return '红色';
    if (this == Colors.teal) return '青色';
    if (this == Colors.indigo) return '靛蓝';
    if (this == Colors.pink) return '粉色';
    return '自定义';
  }

  /// 获取颜色的亮度
  bool get isLight {
    return computeLuminance() > 0.5;
  }

  /// 获取颜色的对比色
  Color get contrastColor {
    return isLight ? Colors.black : Colors.white;
  }

  /// 获取颜色的深色变体
  Color get darkVariant {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  /// 获取颜色的浅色变体
  Color get lightVariant {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }
}

/// 深色主题配色方案
class DarkThemeColors {
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2D2D2D);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFFBDBDBD);
  static const Color outline = Color(0xFF424242);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFFF5F5F5);
  static const Color inverseOnSurface = Color(0xFF1E1E1E);
  static const Color inversePrimary = Color(0xFF0D47A1);
  static const Color primaryContainer = Color(0xFF0D47A1);
  static const Color onPrimaryContainer = Color(0xFFE3F2FD);
  static const Color secondaryContainer = Color(0xFF424242);
  static const Color onSecondaryContainer = Color(0xFFE0E0E0);
  static const Color tertiaryContainer = Color(0xFF1A237E);
  static const Color onTertiaryContainer = Color(0xFFE8EAF6);
  static const Color errorContainer = Color(0xFFB71C1C);
  static const Color onErrorContainer = Color(0xFFFFEBEE);
}

/// 浅色主题配色方案
class LightThemeColors {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF1E1E1E);
  static const Color onSurfaceVariant = Color(0xFF424242);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFF1E1E1E);
  static const Color inverseOnSurface = Color(0xFFF5F5F5);
  static const Color inversePrimary = Color(0xFF90CAF9);
  static const Color primaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimaryContainer = Color(0xFF0D47A1);
  static const Color secondaryContainer = Color(0xFFE0E0E0);
  static const Color onSecondaryContainer = Color(0xFF424242);
  static const Color tertiaryContainer = Color(0xFFE8EAF6);
  static const Color onTertiaryContainer = Color(0xFF1A237E);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onErrorContainer = Color(0xFFB71C1C);
}

/// 主题工具类
class ThemeUtils {
  /// 获取主题数据
  static ThemeData getThemeData({
    required Brightness brightness,
    required Color primaryColor,
    required double fontSize,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primarySwatch: _generateMaterialColor(primaryColor),
      colorScheme: _generateColorScheme(brightness, primaryColor),
      textTheme: _generateTextTheme(fontSize, brightness),
      appBarTheme: _generateAppBarTheme(brightness, primaryColor),
      cardTheme: _generateCardTheme(brightness),
      elevatedButtonTheme: _generateElevatedButtonTheme(
        brightness,
        primaryColor,
      ),
      outlinedButtonTheme: _generateOutlinedButtonTheme(
        brightness,
        primaryColor,
      ),
      textButtonTheme: _generateTextButtonTheme(brightness, primaryColor),
      inputDecorationTheme: _generateInputDecorationTheme(brightness),
      floatingActionButtonTheme: _generateFABTheme(brightness, primaryColor),
      bottomNavigationBarTheme: _generateBottomNavTheme(brightness),
      drawerTheme: _generateDrawerTheme(brightness),
      dialogTheme: _generateDialogTheme(brightness),
      snackBarTheme: _generateSnackBarTheme(brightness),
      chipTheme: _generateChipTheme(brightness, primaryColor),
      switchTheme: _generateSwitchTheme(brightness, primaryColor),
      checkboxTheme: _generateCheckboxTheme(brightness, primaryColor),
      radioTheme: _generateRadioTheme(brightness, primaryColor),
    );
  }

  /// 生成 Material Color
  static MaterialColor _generateMaterialColor(Color color) {
    final List<double> strengths = [
      0.05,
      0.1,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.8,
      0.9,
    ];
    final Map<int, Color> swatch = {};

    for (int i = 0; i < strengths.length; i++) {
      final double ds = 0.5 - strengths[i];
      final red = (color.r * 255).round();
      final green = (color.g * 255).round();
      final blue = (color.b * 255).round();

      swatch[(i + 1) * 100] = Color.fromRGBO(
        red + ((ds < 0 ? red : (255 - red)) * ds).round(),
        green + ((ds < 0 ? green : (255 - green)) * ds).round(),
        blue + ((ds < 0 ? blue : (255 - blue)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.toARGB32() & 0xFFFFFF, swatch);
  }

  /// 生成颜色方案
  static ColorScheme _generateColorScheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );
  }

  /// 生成文本主题
  static TextTheme _generateTextTheme(double fontSize, Brightness brightness) {
    final color = brightness == Brightness.dark ? Colors.white : Colors.black;

    return TextTheme(
      displayLarge: TextStyle(fontSize: fontSize + 16, color: color),
      displayMedium: TextStyle(fontSize: fontSize + 12, color: color),
      displaySmall: TextStyle(fontSize: fontSize + 8, color: color),
      headlineLarge: TextStyle(fontSize: fontSize + 6, color: color),
      headlineMedium: TextStyle(fontSize: fontSize + 4, color: color),
      headlineSmall: TextStyle(fontSize: fontSize + 2, color: color),
      titleLarge: TextStyle(fontSize: fontSize + 2, color: color),
      titleMedium: TextStyle(fontSize: fontSize, color: color),
      titleSmall: TextStyle(fontSize: fontSize - 2, color: color),
      bodyLarge: TextStyle(fontSize: fontSize, color: color),
      bodyMedium: TextStyle(fontSize: fontSize - 2, color: color),
      bodySmall: TextStyle(fontSize: fontSize - 4, color: color),
      labelLarge: TextStyle(fontSize: fontSize - 2, color: color),
      labelMedium: TextStyle(fontSize: fontSize - 4, color: color),
      labelSmall: TextStyle(fontSize: fontSize - 6, color: color),
    );
  }

  /// 生成 AppBar 主题
  static AppBarTheme _generateAppBarTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: brightness == Brightness.dark
          ? Colors.white
          : primaryColor,
      iconTheme: IconThemeData(
        color: brightness == Brightness.dark ? Colors.white : primaryColor,
      ),
      titleTextStyle: TextStyle(
        color: brightness == Brightness.dark ? Colors.white : primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 生成卡片主题
  static CardThemeData _generateCardTheme(Brightness brightness) {
    return CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: brightness == Brightness.dark
          ? DarkThemeColors.surface
          : LightThemeColors.surface,
    );
  }

  /// 生成按钮主题
  static ElevatedButtonThemeData _generateElevatedButtonTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: primaryColor.contrastColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  /// 生成描边按钮主题
  static OutlinedButtonThemeData _generateOutlinedButtonTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  /// 生成文本按钮主题
  static TextButtonThemeData _generateTextButtonTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  /// 生成输入装饰主题
  static InputDecorationTheme _generateInputDecorationTheme(
    Brightness brightness,
  ) {
    return InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: brightness == Brightness.dark
          ? DarkThemeColors.surfaceVariant
          : LightThemeColors.surfaceVariant,
    );
  }

  /// 生成 FAB 主题
  static FloatingActionButtonThemeData _generateFABTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: primaryColor.contrastColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  /// 生成底部导航主题
  static BottomNavigationBarThemeData _generateBottomNavTheme(
    Brightness brightness,
  ) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: brightness == Brightness.dark
          ? DarkThemeColors.surface
          : LightThemeColors.surface,
      selectedItemColor: brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
      unselectedItemColor: brightness == Brightness.dark
          ? Colors.white54
          : Colors.black54,
    );
  }

  /// 生成抽屉主题
  static DrawerThemeData _generateDrawerTheme(Brightness brightness) {
    return DrawerThemeData(
      backgroundColor: brightness == Brightness.dark
          ? DarkThemeColors.surface
          : LightThemeColors.surface,
    );
  }

  /// 生成对话框主题
  static DialogThemeData _generateDialogTheme(Brightness brightness) {
    return DialogThemeData(
      backgroundColor: brightness == Brightness.dark
          ? DarkThemeColors.surface
          : LightThemeColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  /// 生成提示条主题
  static SnackBarThemeData _generateSnackBarTheme(Brightness brightness) {
    return SnackBarThemeData(
      backgroundColor: brightness == Brightness.dark
          ? DarkThemeColors.surfaceVariant
          : LightThemeColors.surfaceVariant,
      contentTextStyle: TextStyle(
        color: brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// 生成标签主题
  static ChipThemeData _generateChipTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return ChipThemeData(
      backgroundColor: brightness == Brightness.dark
          ? DarkThemeColors.surfaceVariant
          : LightThemeColors.surfaceVariant,
      selectedColor: primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
    );
  }

  /// 生成开关主题
  static SwitchThemeData _generateSwitchTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return brightness == Brightness.dark ? Colors.white : Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.5);
        }
        return brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[300];
      }),
    );
  }

  /// 生成复选框主题
  static CheckboxThemeData _generateCheckboxTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(primaryColor.contrastColor),
    );
  }

  /// 生成单选框主题
  static RadioThemeData _generateRadioTheme(
    Brightness brightness,
    Color primaryColor,
  ) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return brightness == Brightness.dark ? Colors.white : Colors.grey;
      }),
    );
  }
}
