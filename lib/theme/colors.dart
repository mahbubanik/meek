import 'package:flutter/material.dart';

/// MEEK App Color System
/// Extracted from the web app's globals.css design tokens

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================
  // EDITORIAL COLOR PALETTE (Base Colors)
  // ============================================
  static const Color deepNavy = Color(0xFF0A1628);
  static const Color teal = Color(0xFF2D5F5D);
  static const Color tealDark = Color(0xFF1A3B3A);
  static const Color warmGold = Color(0xFFE8C49A);
  static const Color charcoal = Color(0xFF2B2B2B);
  static const Color warmGray = Color(0xFF5B5B5B);
  static const Color lightGray = Color(0xFF7B7B7B);
  static const Color cream = Color(0xFFF5F1E8);
  static const Color offWhite = Color(0xFFFAFAF5);
  static const Color softGrayBg = Color(0xFFFAFAFA);

  // ============================================
  // LIGHT MODE TOKENS
  // ============================================
  static const Color lightBackground = offWhite;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightForeground = charcoal;
  static const Color lightMuted = warmGray;
  static const Color lightPrimary = teal;
  static const Color lightAccent = warmGold;
  static const Color lightBorder = Color(0xFFE4DDD4);
  static const Color lightArabicText = warmGold;

  // ============================================
  // DARK MODE TOKENS
  // ============================================
  static const Color darkBackground = deepNavy;
  static const Color darkSurface = Color(0xFF1A2A3A);
  static const Color darkForeground = cream;
  static const Color darkMuted = Color(0xFFA8A8A8);
  static const Color darkPrimary = warmGold; // Swapped for better contrast
  static const Color darkAccent = teal; // Swapped for better contrast
  static const Color darkBorder = Color(0xFF2A3A4A);
  static const Color darkArabicText = warmGold;

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Recording state colors
  static const Color recordingRed = Color(0xFFEF4444);
  static const Color recordingRedLight = Color(0x1AEF4444); // 10% opacity

  // Feedback colors
  static const Color feedbackExcellent = Color(0xFFFFD700);
  static const Color feedbackGood = Color(0xFF22C55E);
  static const Color feedbackImprovement = Color(0xFFF97316);
}

/// Light theme color scheme
ColorScheme lightColorScheme = const ColorScheme.light(
  primary: AppColors.lightPrimary,
  onPrimary: Colors.white,
  secondary: AppColors.lightAccent,
  onSecondary: Colors.white,
  surface: AppColors.lightSurface,
  onSurface: AppColors.lightForeground,
  error: AppColors.error,
  onError: Colors.white,
);

/// Dark theme color scheme
ColorScheme darkColorScheme = const ColorScheme.dark(
  primary: AppColors.darkPrimary,
  onPrimary: AppColors.deepNavy,
  secondary: AppColors.darkAccent,
  onSecondary: Colors.white,
  surface: AppColors.darkSurface,
  onSurface: AppColors.darkForeground,
  error: AppColors.error,
  onError: Colors.white,
);
