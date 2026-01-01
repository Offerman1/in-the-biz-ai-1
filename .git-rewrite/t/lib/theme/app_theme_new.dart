import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Theme accessor that reads colors from ThemeProvider
/// This allows instant theme changes without restart
class AppTheme {
  // Get theme provider
  static ThemeProvider _theme(BuildContext context) =>
      Provider.of<ThemeProvider>(context, listen: false);

  // Colors - now read from ThemeProvider
  static Color get primaryGreen => const Color(0xFF00D632);
  static Color get darkBackground => const Color(0xFF121212);
  static Color get cardBackground => const Color(0xFF1E1E1E);
  static Color get cardBackgroundLight => const Color(0xFF2C2C2C);
  static Color get textPrimary => const Color(0xFFFFFFFF);
  static Color get textSecondary => const Color(0xFFB3B3B3);
  static Color get textMuted => const Color(0xFF666666);
  static Color get accentRed => const Color(0xFFFF3B30);
  static Color get accentBlue => const Color(0xFF007AFF);
  static Color get accentYellow => const Color(0xFFFFCC00);
  static Color get accentOrange => const Color(0xFFFF9500);
  static Color get accentPurple => const Color(0xFFAF52DE);
  static Color get primaryOnDark => const Color(0xFFFFFFFF);
  static Color get scheduledShiftColor => const Color(0xFF42A5F5);
  static Color get warningColor => const Color(0xFFFF9800);
  static Color get dangerColor => const Color(0xFFF44336);
  static Color get successColor => const Color(0xFF4CAF50);
  static Color get chartGreen1 => const Color(0xFF4CAF50);
  static Color get chartGreen2 => const Color(0xFF81C784);
  static Color get chartGreen3 => const Color(0xFFA5D6A7);
  static Color get shadowColor => Colors.black.withOpacity(0.3);
  static Color get overlayColor => Colors.black.withOpacity(0.4);

  // Gradients
  static LinearGradient get greenGradient => LinearGradient(
        colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // Text Styles
  static TextStyle get headlineLarge => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -1,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      );

  static TextStyle get labelLarge => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get moneyLarge => TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
        letterSpacing: -2,
      );

  static TextStyle get moneyMedium => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
        letterSpacing: -1,
      );

  static TextStyle get moneySmall => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      );

  // Theme data getter
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        primaryColor: primaryGreen,
        colorScheme: ColorScheme.dark(
          primary: primaryGreen,
          secondary: primaryGreen,
          surface: cardBackground,
          error: accentRed,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBackground,
          foregroundColor: textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryGreen,
          foregroundColor: primaryOnDark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: primaryOnDark,
          ),
        ),
      );

  // Dynamic color methods that read from ThemeProvider
  static Color primaryColor(BuildContext context) =>
      _theme(context).primaryColor;
  static Color background(BuildContext context) =>
      _theme(context).darkBackground;
  static Color card(BuildContext context) => _theme(context).cardBackground;
  static Color cardLight(BuildContext context) =>
      _theme(context).cardBackgroundLight;
  static Color text1(BuildContext context) => _theme(context).textPrimary;
  static Color text2(BuildContext context) => _theme(context).textSecondary;
  static Color text3(BuildContext context) => _theme(context).textMuted;
  static Color red(BuildContext context) => _theme(context).accentRed;
  static Color blue(BuildContext context) => _theme(context).accentBlue;
  static Color yellow(BuildContext context) => _theme(context).accentYellow;
  static Color orange(BuildContext context) => _theme(context).accentOrange;
  static Color purple(BuildContext context) => _theme(context).accentPurple;
}
