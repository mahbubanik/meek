import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MEEK App Typography System
/// Uses Inter for UI, Noto Naskh Arabic for Arabic text, Crimson Text for serif

class AppTypography {
  AppTypography._();

  // ============================================
  // BASE FONT FAMILIES
  // ============================================
  
  /// Inter - Sans-serif for UI text
  static String get fontFamilySans => GoogleFonts.inter().fontFamily!;
  
  /// Crimson Text - Serif for special headings
  static String get fontFamilySerif => GoogleFonts.crimsonText().fontFamily!;
  
  /// Noto Naskh Arabic - Arabic text
  static String get fontFamilyArabic => GoogleFonts.notoNaskhArabic().fontFamily!;
  
  /// Scheherazade New - Alternative Arabic text
  static String get fontFamilyArabicDisplay => GoogleFonts.scheherazadeNew().fontFamily!;

  // ============================================
  // TEXT STYLES - HEADINGS
  // ============================================
  
  static TextStyle headingLarge(Color color) => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.2,
  );

  static TextStyle headingMedium(Color color) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
  );

  static TextStyle headingSmall(Color color) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.35,
  );

  // ============================================
  // TEXT STYLES - BODY
  // ============================================

  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodySmall(Color color) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  // ============================================
  // TEXT STYLES - LABELS & BUTTONS
  // ============================================

  static TextStyle labelLarge(Color color) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.5,
  );

  static TextStyle labelMedium(Color color) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall(Color color) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: 0.8,
  );

  static TextStyle button(Color color) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // ============================================
  // TEXT STYLES - ARABIC
  // ============================================

  static TextStyle arabicLarge(Color color) => GoogleFonts.scheherazadeNew(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: color,
    height: 2.0,
  );

  static TextStyle arabicMedium(Color color) => GoogleFonts.notoNaskhArabic(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.8,
  );

  static TextStyle arabicSmall(Color color) => GoogleFonts.notoNaskhArabic(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.6,
  );

  /// Arabic mashallah/feedback text
  static TextStyle arabicFeedback(Color color) => GoogleFonts.scheherazadeNew(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.5,
  );

  // ============================================
  // TEXT STYLES - SPECIAL
  // ============================================

  static TextStyle serifHeading(Color color) => GoogleFonts.crimsonText(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
    fontStyle: FontStyle.italic,
  );

  static TextStyle mono(Color color) => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle monoLarge(Color color) => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Uppercase tracking label (e.g., "YOUR RECITATION")
  static TextStyle uppercaseLabel(Color color) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 1.5,
  );
}
