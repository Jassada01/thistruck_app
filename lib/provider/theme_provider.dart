import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart' as AppThemeConfig;

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  AppThemeConfig.ThemeMode _themeMode = AppThemeConfig.ThemeMode.light;
  late SharedPreferences _prefs;
  
  AppThemeConfig.ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == AppThemeConfig.ThemeMode.dark;
  bool get isLightMode => _themeMode == AppThemeConfig.ThemeMode.light;
  bool get isSystemMode => _themeMode == AppThemeConfig.ThemeMode.system;
  
  // Get current colors based on theme
  AppThemeConfig.AppColorScheme get colors {
    AppThemeConfig.AppTheme.setTheme(_themeMode);
    return AppThemeConfig.AppTheme.colors;
  }
  
  // Get design config
  AppThemeConfig.AppDesignConfig get design => AppThemeConfig.AppDesignConfig();
  
  // Initialize theme provider
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTheme();
  }
  
  // Load saved theme
  Future<void> _loadTheme() async {
    final themeIndex = _prefs.getInt(_themeKey) ?? 0;
    _themeMode = AppThemeConfig.ThemeMode.values[themeIndex];
    AppThemeConfig.AppTheme.setTheme(_themeMode);
    notifyListeners();
  }
  
  // Save theme
  Future<void> _saveTheme() async {
    await _prefs.setInt(_themeKey, _themeMode.index);
  }
  
  // Set theme mode
  Future<void> setThemeMode(AppThemeConfig.ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      AppThemeConfig.AppTheme.setTheme(_themeMode);
      await _saveTheme();
      notifyListeners();
    }
  }
  
  // Toggle between light and dark
  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeConfig.ThemeMode.light 
        ? AppThemeConfig.ThemeMode.dark 
        : AppThemeConfig.ThemeMode.light;
    await setThemeMode(newMode);
  }
  
  // Get Flutter ThemeData for MaterialApp
  ThemeData get lightTheme {
    final colors = AppThemeConfig.AppColorScheme.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        background: colors.background,
        error: colors.error,
        onPrimary: colors.onPrimary,
        onSecondary: colors.onSecondary,
        onSurface: colors.onSurface,
        onBackground: colors.onBackground,
        onError: colors.onError,
      ),
      textTheme: TextTheme(
        headlineLarge: AppThemeConfig.AppDesignConfig.headlineStyle.copyWith(color: colors.textPrimary),
        titleLarge: AppThemeConfig.AppDesignConfig.titleStyle.copyWith(color: colors.textPrimary),
        titleMedium: AppThemeConfig.AppDesignConfig.subtitleStyle.copyWith(color: colors.textPrimary),
        bodyLarge: AppThemeConfig.AppDesignConfig.bodyStyle.copyWith(color: colors.textPrimary),
        bodyMedium: AppThemeConfig.AppDesignConfig.captionStyle.copyWith(color: colors.textSecondary),
        bodySmall: AppThemeConfig.AppDesignConfig.smallStyle.copyWith(color: colors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConfig.AppDesignConfig.buttonRadius),
          ),
          padding: AppThemeConfig.AppDesignConfig.buttonPadding,
          minimumSize: Size(double.infinity, AppThemeConfig.AppDesignConfig.buttonHeight),
        ),
      ),
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: AppThemeConfig.AppDesignConfig.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.AppDesignConfig.radiusLarge),
        ),
        margin: AppThemeConfig.AppDesignConfig.cardMargin,
      ),
    );
  }
  
  ThemeData get darkTheme {
    final colors = AppThemeConfig.AppColorScheme.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        background: colors.background,
        error: colors.error,
        onPrimary: colors.onPrimary,
        onSecondary: colors.onSecondary,
        onSurface: colors.onSurface,
        onBackground: colors.onBackground,
        onError: colors.onError,
      ),
      textTheme: TextTheme(
        headlineLarge: AppThemeConfig.AppDesignConfig.headlineStyle.copyWith(color: colors.textPrimary),
        titleLarge: AppThemeConfig.AppDesignConfig.titleStyle.copyWith(color: colors.textPrimary),
        titleMedium: AppThemeConfig.AppDesignConfig.subtitleStyle.copyWith(color: colors.textPrimary),
        bodyLarge: AppThemeConfig.AppDesignConfig.bodyStyle.copyWith(color: colors.textPrimary),
        bodyMedium: AppThemeConfig.AppDesignConfig.captionStyle.copyWith(color: colors.textSecondary),
        bodySmall: AppThemeConfig.AppDesignConfig.smallStyle.copyWith(color: colors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConfig.AppDesignConfig.buttonRadius),
          ),
          padding: AppThemeConfig.AppDesignConfig.buttonPadding,
          minimumSize: Size(double.infinity, AppThemeConfig.AppDesignConfig.buttonHeight),
        ),
      ),
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: AppThemeConfig.AppDesignConfig.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.AppDesignConfig.radiusLarge),
        ),
        margin: AppThemeConfig.AppDesignConfig.cardMargin,
      ),
    );
  }
}