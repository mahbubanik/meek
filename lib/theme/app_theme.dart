import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

/// MEEK App Theme Configuration
/// Complete theme system with light and dark modes

class AppTheme {
  AppTheme._();

  // ============================================
  // SPACING SYSTEM (4px base)
  // ============================================
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 999.0;

  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // ============================================
  // SHADOWS
  // ============================================
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowPrimary(Color primaryColor) => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================
  // LIGHT THEME
  // ============================================
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: AppColors.lightBackground,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightForeground,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.headingSmall(AppColors.lightForeground),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusLarge,
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        textStyle: AppTypography.button(Colors.white),
      ),
    ),

    // Outlined Buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightPrimary,
        side: BorderSide(color: AppColors.lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        textStyle: AppTypography.button(AppColors.lightPrimary),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightPrimary,
        textStyle: AppTypography.button(AppColors.lightPrimary),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTypography.bodyMedium(AppColors.lightMuted),
      labelStyle: AppTypography.bodyMedium(AppColors.lightMuted),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.lightPrimary,
      unselectedItemColor: AppColors.lightMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: borderRadiusFull),
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.lightPrimary,
      unselectedLabelColor: AppColors.lightMuted,
      labelStyle: AppTypography.labelLarge(AppColors.lightPrimary),
      unselectedLabelStyle: AppTypography.labelMedium(AppColors.lightMuted),
      indicator: BoxDecoration(
        borderRadius: borderRadiusFull,
        color: AppColors.lightPrimary.withValues(alpha: 0.1),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Icon Theme
    iconTheme: IconThemeData(
      color: AppColors.lightForeground,
      size: 24,
    ),
  );

  // ============================================
  // DARK THEME
  // ============================================
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkForeground,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.headingSmall(AppColors.darkForeground),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusLarge,
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        textStyle: AppTypography.button(AppColors.deepNavy),
      ),
    ),

    // Outlined Buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        side: BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        textStyle: AppTypography.button(AppColors.darkPrimary),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        textStyle: AppTypography.button(AppColors.darkPrimary),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTypography.bodyMedium(AppColors.darkMuted),
      labelStyle: AppTypography.bodyMedium(AppColors.darkMuted),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.darkPrimary,
      unselectedItemColor: AppColors.darkMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.deepNavy,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: borderRadiusFull),
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.darkPrimary,
      unselectedLabelColor: AppColors.darkMuted,
      labelStyle: AppTypography.labelLarge(AppColors.darkPrimary),
      unselectedLabelStyle: AppTypography.labelMedium(AppColors.darkMuted),
      indicator: BoxDecoration(
        borderRadius: borderRadiusFull,
        color: AppColors.darkPrimary.withValues(alpha: 0.15),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Icon Theme
    iconTheme: IconThemeData(
      color: AppColors.darkForeground,
      size: 24,
    ),
  );
}

/// Extension for theme-aware colors
extension ThemeExtensions on BuildContext {
  /// Get current color based on theme
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get backgroundColor => isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surfaceColor => isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
  Color get foregroundColor => isDarkMode ? AppColors.darkForeground : AppColors.lightForeground;
  Color get mutedColor => isDarkMode ? AppColors.darkMuted : AppColors.lightMuted;
  Color get primaryColor => isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get accentColor => isDarkMode ? AppColors.darkAccent : AppColors.lightAccent;
  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
  Color get arabicTextColor => isDarkMode ? AppColors.darkArabicText : AppColors.lightArabicText;
}
