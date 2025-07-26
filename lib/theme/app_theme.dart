import 'package:flutter/material.dart';

// Theme Mode Enum
enum ThemeMode { light, dark, system }

// App Theme Configuration Class
class AppTheme {
  // Current theme mode
  static ThemeMode _currentTheme = ThemeMode.light;
  
  // Getters
  static ThemeMode get currentTheme => _currentTheme;
  static bool get isDarkMode => _currentTheme == ThemeMode.dark;
  static bool get isLightMode => _currentTheme == ThemeMode.light;
  
  // Theme setter
  static void setTheme(ThemeMode theme) {
    _currentTheme = theme;
  }
  
  // Get current color scheme
  static AppColorScheme get colors {
    switch (_currentTheme) {
      case ThemeMode.dark:
        return AppColorScheme.dark();
      case ThemeMode.light:
      case ThemeMode.system:
      return AppColorScheme.light();
    }
  }
  
  // Get current design config
  static AppDesignConfig get design => AppDesignConfig();
}

// Color Scheme Class
class AppColorScheme {
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color surface;
  final Color background;
  final Color error;
  final Color errorVariant;
  final Color success;
  final Color successVariant;
  final Color warning;
  final Color warningVariant;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color shadow;
  final Color overlay;
  
  // Gradient Colors
  final List<Color> backgroundGradient;
  final List<Color> primaryGradient;
  final List<Color> cardGradient;
  
  AppColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.secondaryVariant,
    required this.surface,
    required this.background,
    required this.error,
    required this.errorVariant,
    required this.success,
    required this.successVariant,
    required this.warning,
    required this.warningVariant,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.shadow,
    required this.overlay,
    required this.backgroundGradient,
    required this.primaryGradient,
    required this.cardGradient,
  });
  
  // Light Theme Colors
  factory AppColorScheme.light() {
    return AppColorScheme(
      primary: Color(0xFF2196F3),
      primaryVariant: Color(0xFF1976D2),
      secondary: Color(0xFF03DAC6),
      secondaryVariant: Color(0xFF018786),
      surface: Colors.white,
      background: Color(0xFFFAFAFA),
      error: Color(0xFFE53E3E),
      errorVariant: Color(0xFFC53030),
      success: Color(0xFF38A169),
      successVariant: Color(0xFF2F855A),
      warning: Color(0xFFED8936),
      warningVariant: Color(0xFFDD6B20),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
      textPrimary: Color(0xFF1A1A1A),
      textSecondary: Color(0xFF6B7280),
      textTertiary: Color(0xFF9CA3AF),
      divider: Color(0xFFE5E5E5),
      shadow: Colors.black.withOpacity(0.1),
      overlay: Colors.black.withOpacity(0.5),
      // Gradients
      backgroundGradient: [
        Color(0xFFE3F2FD),
        Color(0xFFBBDEFB),
        Color(0xFF90CAF9),
        Color(0xFF64B5F6),
      ],
      primaryGradient: [
        Color(0xFF42A5F5),
        Color(0xFF1E88E5),
      ],
      cardGradient: [
        Colors.white.withOpacity(0.9),
        Colors.white.withOpacity(0.7),
      ],
    );
  }
  
  // Dark Theme Colors
  factory AppColorScheme.dark() {
    return AppColorScheme(
      primary: Color(0xFF64B5F6),
      primaryVariant: Color(0xFF42A5F5),
      secondary: Color(0xFF4DD0E1),
      secondaryVariant: Color(0xFF26C6DA),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Color(0xFFEF5350),
      errorVariant: Color(0xFFE53935),
      success: Color(0xFF66BB6A),
      successVariant: Color(0xFF4CAF50),
      warning: Color(0xFFFF9800),
      warningVariant: Color(0xFFE65100),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFB0BEC5),
      textTertiary: Color(0xFF78909C),
      divider: Color(0xFF37474F),
      shadow: Colors.black.withOpacity(0.3),
      overlay: Colors.black.withOpacity(0.7),
      // Gradients
      backgroundGradient: [
        Color(0xFF0D47A1),
        Color(0xFF1565C0),
        Color(0xFF1976D2),
        Color(0xFF1E88E5),
      ],
      primaryGradient: [
        Color(0xFF64B5F6),
        Color(0xFF42A5F5),
      ],
      cardGradient: [
        Color(0xFF1E1E1E).withOpacity(0.9),
        Color(0xFF2D2D2D).withOpacity(0.7),
      ],
    );
  }
}

// Design Configuration Class
class AppDesignConfig {
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 50.0;
  
  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double spaceXXLarge = 48.0;
  
  // Typography
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  static const TextStyle smallStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  // Button Styles
  static const double buttonHeight = 50.0;
  static const double buttonRadius = 25.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );
  
  // Card Styles
  static const double cardElevation = 8.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets cardMargin = EdgeInsets.all(8);
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 800);
  static const Duration animationXSlow = Duration(milliseconds: 1200);
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Shadow Configuration
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppTheme.colors.shadow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: AppTheme.colors.primary.withOpacity(0.3),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: AppTheme.colors.shadow,
      blurRadius: 25,
      offset: Offset(0, 10),
    ),
  ];
}

// Theme Helper Extensions
extension ColorExtension on Color {
  Color get light => Color.lerp(this, Colors.white, 0.1) ?? this;
  Color get dark => Color.lerp(this, Colors.black, 0.1) ?? this;
}

extension TextStyleExtension on TextStyle {
  TextStyle get primary => copyWith(color: AppTheme.colors.textPrimary);
  TextStyle get secondary => copyWith(color: AppTheme.colors.textSecondary);
  TextStyle get tertiary => copyWith(color: AppTheme.colors.textTertiary);
  TextStyle get onPrimary => copyWith(color: AppTheme.colors.onPrimary);
  TextStyle get onSurface => copyWith(color: AppTheme.colors.onSurface);
  TextStyle get error => copyWith(color: AppTheme.colors.error);
  TextStyle get success => copyWith(color: AppTheme.colors.success);
  TextStyle get warning => copyWith(color: AppTheme.colors.warning);
}

// Widget Helper Functions
class ThemeHelper {
  // Create gradient decoration
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      border: border,
    );
  }
  
  // Create card decoration
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? AppTheme.colors.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(AppDesignConfig.radiusLarge),
      boxShadow: boxShadow ?? AppDesignConfig.cardShadow,
      border: border ?? Border.all(
        color: AppTheme.colors.divider,
        width: 1,
      ),
    );
  }
  
  // Create button decoration
  static BoxDecoration buttonDecoration({
    List<Color>? gradientColors,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors ?? AppTheme.colors.primaryGradient,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(AppDesignConfig.buttonRadius),
      boxShadow: boxShadow ?? AppDesignConfig.buttonShadow,
    );
  }
}