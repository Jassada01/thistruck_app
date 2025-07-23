import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeLevel {
  small,
  medium,
  large,
  jumbo,
}

class FontSizeProvider extends ChangeNotifier {
  static const String _fontSizeKey = 'font_size_level';
  
  FontSizeLevel _fontSizeLevel = FontSizeLevel.medium;
  late SharedPreferences _prefs;
  
  FontSizeLevel get fontSizeLevel => _fontSizeLevel;
  
  // Font size multipliers for each level
  double get fontMultiplier {
    switch (_fontSizeLevel) {
      case FontSizeLevel.small:
        return 0.85;
      case FontSizeLevel.medium:
        return 1.0;
      case FontSizeLevel.large:
        return 1.2;
      case FontSizeLevel.jumbo:
        return 1.5;
    }
  }
  
  // Get display name for font size level
  String get fontSizeName {
    switch (_fontSizeLevel) {
      case FontSizeLevel.small:
        return 'เล็ก';
      case FontSizeLevel.medium:
        return 'กลาง';
      case FontSizeLevel.large:
        return 'ใหญ่';
      case FontSizeLevel.jumbo:
        return 'จัมโบ้';
    }
  }
  
  // Get all available font size options
  List<Map<String, dynamic>> get fontSizeOptions {
    return [
      {'level': FontSizeLevel.small, 'name': 'เล็ก', 'multiplier': 0.85},
      {'level': FontSizeLevel.medium, 'name': 'กลาง', 'multiplier': 1.0},
      {'level': FontSizeLevel.large, 'name': 'ใหญ่', 'multiplier': 1.2},
      {'level': FontSizeLevel.jumbo, 'name': 'จัมโบ้', 'multiplier': 1.5},
    ];
  }
  
  // Initialize font size provider
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFontSize();
  }
  
  // Load saved font size
  Future<void> _loadFontSize() async {
    final fontSizeIndex = _prefs.getInt(_fontSizeKey) ?? FontSizeLevel.medium.index;
    _fontSizeLevel = FontSizeLevel.values[fontSizeIndex];
    notifyListeners();
  }
  
  // Save font size
  Future<void> _saveFontSize() async {
    await _prefs.setInt(_fontSizeKey, _fontSizeLevel.index);
  }
  
  // Set font size level
  Future<void> setFontSizeLevel(FontSizeLevel level) async {
    if (_fontSizeLevel != level) {
      _fontSizeLevel = level;
      await _saveFontSize();
      notifyListeners();
    }
  }
  
  // Helper methods to get scaled font sizes
  double getScaledFontSize(double baseSize) {
    return baseSize * fontMultiplier;
  }
  
  // Common font sizes with scaling
  double get captionSize => getScaledFontSize(12);
  double get bodySmallSize => getScaledFontSize(14);
  double get bodySize => getScaledFontSize(16);
  double get subtitleSize => getScaledFontSize(18);
  double get titleSize => getScaledFontSize(20);
  double get headlineSize => getScaledFontSize(24);
  double get displaySmallSize => getScaledFontSize(28);
  double get displayMediumSize => getScaledFontSize(32);
  double get displayLargeSize => getScaledFontSize(36);
}