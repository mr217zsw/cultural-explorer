import 'package:flutter/material.dart';

/// 应用设计令牌 —— 统一管理颜色、间距、排版、组件主题
class AppTheme {
  AppTheme._();

  // ── 调色板 ──
  static const Color primary = Color(0xff8b1e2d);
  static const Color primaryLight = Color(0xffb54a3a);
  static const Color accent = Color(0xfff5a623);
  static const Color background = Color(0xfffffaf0);
  static const Color surface = Color(0xffffffff);
  static const Color textPrimary = Color(0xff2d2520);
  static const Color textSecondary = Color(0xff8c7568);
  static const Color success = Color(0xff66bb6a);
  static const Color mnemonicBg = Color(0xfffff0d5);
  static const Color gold = Color(0xfff5a623);
  static const Color silver = Color(0xffb0bec5);
  static const Color bronze = Color(0xffd4a574);

  // ── 渐变 ──
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryLight, accent],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // ── 间距 ──
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;
  static const double spacingXxxl = 32;

  // ── 圆角 ──
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // ── 完整 ThemeData ──
  static ThemeData get themeData {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: surface,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),

      // 卡片
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        color: surface,
        margin: EdgeInsets.zero,
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(spacingLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.all(spacingLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // SearchBar
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
        ),
        backgroundColor: WidgetStateProperty.all(surface),
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
      ),

      // 排版
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.8,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // 进度条
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xfff0e0d0),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    );
  }

  // ── 暗色 ThemeData ──
  static ThemeData get darkThemeData {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xffd45a5a),
      brightness: Brightness.dark,
      primary: const Color(0xffd45a5a),
      secondary: const Color(0xffffb84d),
      surface: const Color(0xff2a2218),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xff1a1410),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff2a2218),
        foregroundColor: Color(0xffe8dcc8),
        centerTitle: true,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        color: const Color(0xff2a2218),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xffd45a5a),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(spacingLg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xffd45a5a),
        linearTrackColor: Color(0xff3a3028),
      ),
    );
  }
}
