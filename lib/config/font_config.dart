import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  // Font Family
  static String get fontFamily => GoogleFonts.notoSansThai().fontFamily!;
  
  // Text Styles สำหรับภาษาไทย
  static TextStyle get headlineLarge => GoogleFonts.notoSansThai(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.notoSansThai(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.notoSansThai(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleLarge => GoogleFonts.notoSansThai(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleMedium => GoogleFonts.notoSansThai(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle get titleSmall => GoogleFonts.notoSansThai(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.notoSansThai(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.notoSansThai(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static TextStyle get bodySmall => GoogleFonts.notoSansThai(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static TextStyle get labelLarge => GoogleFonts.notoSansThai(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle get labelMedium => GoogleFonts.notoSansThai(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static TextStyle get labelSmall => GoogleFonts.notoSansThai(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  // Button Text Styles
  static TextStyle get buttonLarge => GoogleFonts.notoSansThai(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  static TextStyle get buttonMedium => GoogleFonts.notoSansThai(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  static TextStyle get buttonSmall => GoogleFonts.notoSansThai(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  // Caption and Helper Text
  static TextStyle get caption => GoogleFonts.notoSansThai(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static TextStyle get overline => GoogleFonts.notoSansThai(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
  
  // Method สำหรับสร้าง TextTheme ที่สมบูรณ์
  static TextTheme getTextTheme([TextTheme? baseTheme]) {
    return GoogleFonts.notoSansThaiTextTheme(baseTheme).copyWith(
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
  
  // Method สำหรับสร้าง TextTheme สำหรับ Light Theme
  static TextTheme getLightTextTheme() {
    return getTextTheme().apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    );
  }
  
  // Method สำหรับสร้าง TextTheme สำหรับ Dark Theme
  static TextTheme getDarkTextTheme() {
    return getTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );
  }
  
  // Helper method สำหรับสร้าง TextStyle ที่มีสี
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  // Helper method สำหรับสร้าง TextStyle ที่มีขนาดต่างจากเดิม
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }
  
  // Helper method สำหรับสร้าง TextStyle ที่มี FontWeight ต่างจากเดิม
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }
}

// Extension สำหรับ TextStyle ที่ใช้งานง่าย
extension AppTextStyleExtension on TextStyle {
  TextStyle get notoSansThai => GoogleFonts.notoSansThai(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    height: height,
  );
  
  TextStyle withAppColor(Color color) => copyWith(color: color);
  TextStyle withAppSize(double size) => copyWith(fontSize: size);
  TextStyle withAppWeight(FontWeight weight) => copyWith(fontWeight: weight);
}

// Helper Class สำหรับ Font Weights ที่ใช้บ่อย
class AppFontWeights {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

// Helper Class สำหรับ Font Sizes ที่ใช้บ่อย
class AppFontSizes {
  static const double xs = 10;
  static const double sm = 12;
  static const double base = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xl2 = 22;
  static const double xl3 = 24;
  static const double xl4 = 28;
  static const double xl5 = 32;
  static const double xl6 = 36;
}