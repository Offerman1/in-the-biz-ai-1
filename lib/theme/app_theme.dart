import 'package:flutter/material.dart';

/// Cash App inspired theme for In The Biz AI
class AppTheme {
  // Global theme instance that gets set at startup
  static AppThemeColors? _colors;

  static void setColors(AppThemeColors colors) {
    _colors = colors;
  }

  // Current active theme colors
  static Color get primaryGreen =>
      _colors?.primaryColor ?? const Color(0xFF00D632);
  static Color get darkBackground =>
      _colors?.darkBackground ?? const Color(0xFF121212);
  static Color get cardBackground =>
      _colors?.cardBackground ?? const Color(0xFF1E1E1E);
  static Color get cardBackgroundLight =>
      _colors?.cardBackgroundLight ?? const Color(0xFF2C2C2C);
  static Color get textPrimary =>
      _colors?.textPrimary ?? const Color(0xFFFFFFFF);
  static Color get textSecondary =>
      _colors?.textSecondary ?? const Color(0xFFB3B3B3);
  static Color get textMuted => _colors?.textMuted ?? const Color(0xFF666666);
  static Color get accentRed => _colors?.accentRed ?? const Color(0xFFFF3B30);
  static Color get accentBlue => _colors?.accentBlue ?? const Color(0xFF007AFF);
  static Color get accentYellow =>
      _colors?.accentYellow ?? const Color(0xFFFFCC00);
  static Color get accentOrange =>
      _colors?.accentOrange ?? const Color(0xFFFF9500);
  static Color get accentPurple =>
      _colors?.accentPurple ?? const Color(0xFFAF52DE);

  // Additional semantic colors (derived from theme)
  static Color get primaryOnDark =>
      Colors.white; // Text on primary color buttons - always white
  static Color get scheduledShiftColor =>
      accentBlue; // Blue for scheduled shifts
  static Color get warningColor => accentOrange; // Orange for warnings

  // Adaptive text color based on background luminance
  static Color get adaptiveTextColor {
    return darkBackground.computeLuminance() > 0.5
        ? Colors.black87 // Light background
        : Colors.white; // Dark background
  }

  // Header icon color - subtle theme color (not harsh bright colors)
  static Color get headerIconColor {
    final isLight = (_colors?.isLightBackground ?? false);
    // Use primary color but make it subtle
    return isLight
        ? primaryGreen.withOpacity(0.7) // Subtle in light mode
        : primaryGreen.withOpacity(0.6); // Subtle in dark mode
  }

  // Hero card background - ALWAYS black, never changes, period
  static const Color heroCardBackground = Color(0xFF000000); // Pure black

  // Hero card gradient colors - fixed dark mode colors, never change
  static Color get heroGradientGreen =>
      const Color(0xFF00D632); // Finance green
  static Color get heroGradientBlue => const Color(0xFF007AFF); // Blue
  static Color get dangerColor => accentRed; // Red for errors/danger
  static Color get successColor => primaryGreen; // Green for success
  static Color get chartGreen1 => primaryGreen;
  static Color get chartGreen2 => primaryGreen.withOpacity(0.7);
  static Color get chartGreen3 => primaryGreen.withOpacity(0.4);

  // Nav bar colors - Professional design for both light and dark themes
  static Color get navBarBackground {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? const Color(
            0xFFFFFFFF) // Pure white with border/shadow for separation
        : cardBackground;
  }

  static Color get navBarIconColor {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? const Color(0xFF6B7280) // Darker gray for light mode
        : const Color(0xFF9CA3AF); // Light gray (not white) for dark mode
  }

  static Color get navBarIconActiveColor {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? primaryGreen // Use the theme's accent color for active state
        : primaryGreen;
  }

  static Color get navBarActiveBackground {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? primaryGreen.withOpacity(0.08) // Very subtle tint of accent color
        : primaryGreen.withOpacity(0.15);
  }

  // Shadow colors - adapt to theme
  static Color get shadowColor {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? Colors.black.withOpacity(0.08) // Very subtle shadow in light mode
        : Colors.black.withOpacity(0.3); // Darker shadow in dark mode
  }

  static Color get overlayColor {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? Colors.black.withOpacity(0.15) // Subtle overlay in light mode
        : Colors.black.withOpacity(0.4); // Darker overlay in dark mode
  }

  // Text shadow - only visible in dark mode, invisible in light mode
  static List<Shadow> get textShadow {
    final isLight = (_colors?.isLightBackground ?? false);
    return isLight
        ? [] // No text shadow in light mode
        : [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ];
  }

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

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.4,
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

  // Theme Data
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
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cardBackground,
          indicatorColor: primaryGreen.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBackgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide(color: accentRed, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide(color: accentRed, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: DividerThemeData(
          color: cardBackgroundLight,
          thickness: 1,
        ),
      );

  // ========== THEME PRESETS ==========

  static final Map<String, Map<String, Color>> themePresets = {
    'cash_app': {
      'primary': const Color(0xFF00D632),
      'background': const Color(0xFF121212),
      'card': const Color(0xFF1E1E1E),
      'cardLight': const Color(0xFF2C2C2C),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFFF3B30),
      'accentBlue': const Color(0xFF007AFF),
      'accentYellow': const Color(0xFFFFCC00),
      'accentOrange': const Color(0xFFFF9500),
      'accentPurple': const Color(0xFFAF52DE),
      'primaryOnDark': const Color(0xFF000000),
    },
    'midnight_blue': {
      'primary': const Color(0xFF3B82F6), // Blue accent for buttons/highlights
      'background': const Color(0xFF0D0D0D), // Almost black (neutral)
      'card': const Color(0xFF1A1A1A), // Dark gray (neutral)
      'cardLight': const Color(0xFF2C2C2C), // Lighter gray (neutral)
      'textPrimary': const Color(0xFFFFFFFF), // White text
      'textSecondary': const Color(0xFFB3B3B3), // Light gray text
      'textMuted': const Color(0xFF666666), // Muted gray text
      'accentRed': const Color(0xFFEF4444), // Red for errors
      'accentBlue': const Color(0xFF06B6D4), // Cyan for secondary accent
      'accentYellow': const Color(0xFFFBBF24), // Yellow for warnings
      'accentOrange': const Color(0xFFF97316), // Orange for info
      'accentPurple': const Color(0xFFA855F7), // Purple for special items
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on blue buttons
    },
    'purple_reign': {
      'primary':
          const Color(0xFFA855F7), // Purple accent for buttons/highlights
      'background': const Color(0xFF0D0D0D), // Almost black (neutral)
      'card': const Color(0xFF1A1A1A), // Dark gray (neutral)
      'cardLight': const Color(0xFF2C2C2C), // Lighter gray (neutral)
      'textPrimary': const Color(0xFFFFFFFF), // White text
      'textSecondary': const Color(0xFFB3B3B3), // Light gray text
      'textMuted': const Color(0xFF666666), // Muted gray text
      'accentRed': const Color(0xFFEF4444), // Red for errors
      'accentBlue': const Color(0xFF06B6D4), // Cyan for secondary
      'accentYellow': const Color(0xFFFBBF24), // Yellow for warnings
      'accentOrange': const Color(0xFFF97316), // Orange for info
      'accentPurple': const Color(0xFFC084FC), // Light purple for gradients
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on purple buttons
    },
    'ocean_breeze': {
      'primary':
          const Color(0xFF06B6D4), // Cyan/teal accent for buttons/highlights
      'background': const Color(0xFF0D0D0D), // Almost black (neutral)
      'card': const Color(0xFF1A1A1A), // Dark gray (neutral)
      'cardLight': const Color(0xFF2C2C2C), // Lighter gray (neutral)
      'textPrimary': const Color(0xFFFFFFFF), // White text
      'textSecondary': const Color(0xFFB3B3B3), // Light gray text
      'textMuted': const Color(0xFF666666), // Muted gray text
      'accentRed': const Color(0xFFEF4444), // Red for errors
      'accentBlue': const Color(0xFF3B82F6), // Blue for secondary
      'accentYellow': const Color(0xFFFBBF24), // Yellow for warnings
      'accentOrange': const Color(0xFFF97316), // Orange for info
      'accentPurple': const Color(0xFFA855F7), // Purple for special items
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on cyan buttons
    },
    'sunset_glow': {
      'primary': const Color(0xFFFF6B35),
      'background': const Color(0xFF1A0F0A),
      'card': const Color(0xFF2A1F1A),
      'cardLight': const Color(0xFF3A2F2A),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFFFD4B3),
      'textMuted': const Color(0xFFB39480),
      'accentRed': const Color(0xFFFF3366),
      'accentBlue': const Color(0xFF6B8CFF),
      'accentYellow': const Color(0xFFFFCC33),
      'accentOrange': const Color(0xFFFF8C42),
      'accentPurple': const Color(0xFFAF52DE),
      'primaryOnDark': const Color(0xFFFFFFFF),
    },
    'forest_night': {
      'primary': const Color(
          0xFF10B981), // Emerald green accent for buttons/highlights
      'background': const Color(0xFF0D0D0D), // Almost black (neutral)
      'card': const Color(0xFF1A1A1A), // Dark gray (neutral)
      'cardLight': const Color(0xFF2C2C2C), // Lighter gray (neutral)
      'textPrimary': const Color(0xFFFFFFFF), // White text
      'textSecondary': const Color(0xFFB3B3B3), // Light gray text
      'textMuted': const Color(0xFF666666), // Muted gray text
      'accentRed': const Color(0xFFEF4444), // Red for errors
      'accentBlue': const Color(0xFF3B82F6), // Blue for secondary
      'accentYellow': const Color(0xFFFBBF24), // Yellow for warnings
      'accentOrange': const Color(0xFFF97316), // Orange for info
      'accentPurple': const Color(0xFFA855F7), // Purple for special items
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on green buttons
    },
    'coinbase_pro': {
      'primary':
          const Color(0xFF5B5FEF), // Blue/purple accent for buttons/highlights
      'background': const Color(0xFF0D0D0D), // Almost black (neutral)
      'card': const Color(0xFF1A1A1A), // Dark gray (neutral)
      'cardLight': const Color(0xFF2C2C2C), // Lighter gray (neutral)
      'textPrimary': const Color(0xFFFFFFFF), // White text
      'textSecondary': const Color(0xFFB3B3B3), // Light gray text
      'textMuted': const Color(0xFF666666), // Muted gray text
      'accentRed': const Color(0xFFEF4444), // Red for errors
      'accentBlue': const Color(0xFF3B82F6), // Blue for secondary
      'accentYellow': const Color(0xFFFBBF24), // Yellow for warnings
      'accentOrange': const Color(0xFFF97316), // Orange for info
      'accentPurple': const Color(0xFF8B5CF6), // Purple for gradients
      'primaryOnDark':
          const Color(0xFFFFFFFF), // White text on blue/purple buttons
    },
    'light_mode': {
      'primary': const Color(
          0xFF059669), // Darker emerald green (professional, not neon)
      'background': const Color(0xFFFFFFFF), // Pure white background
      'card': const Color(0xFFF9FAFB), // Slightly off-white for subtle depth
      'cardLight': const Color(0xFFF3F4F6), // Light gray
      'textPrimary':
          const Color(0xFF111827), // Almost black (softer than pure black)
      'textSecondary': const Color(0xFF6B7280), // Medium gray
      'textMuted': const Color(0xFF9CA3AF), // Light gray
      'accentRed': const Color(0xFFDC2626), // Darker red
      'accentBlue': const Color(0xFF2563EB), // Darker blue
      'accentYellow': const Color(0xFFF59E0B), // Darker yellow
      'accentOrange': const Color(0xFFEA580C), // Darker orange
      'accentPurple': const Color(0xFF9333EA), // Darker purple
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on colored buttons
    },
    'light_blue': {
      'primary': const Color(0xFF0070BA), // PayPal blue
      'background': const Color(0xFFFAFAFA), // Very light gray (not pure white)
      'card': const Color(0xFFFFFFFF), // White cards
      'cardLight': const Color(0xFFF5F5F5), // Light gray for subtle elements
      'textPrimary': const Color(0xFF2C2E2F), // Almost black
      'textSecondary': const Color(0xFF6C7378), // Gray
      'textMuted': const Color(0xFF9DA3A6), // Light gray
      'accentRed': const Color(0xFFD32F2F), // Red
      'accentBlue': const Color(0xFF0070BA), // PayPal blue
      'accentYellow': const Color(0xFFFFC439), // PayPal yellow accent
      'accentOrange': const Color(0xFFFF6B35), // Orange
      'accentPurple': const Color(0xFF7B4FFF), // Purple
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on blue buttons
    },
    'soft_purple': {
      'primary': const Color(0xFF8E24AA), // Purple accent
      'background': const Color(0xFFFAF9FC), // Very light purple background
      'card': const Color(0xFFF3E5F5), // Light purple cards
      'cardLight': const Color(0xFFE1BEE7), // Lighter purple
      'textPrimary': const Color(0xFF000000), // Black text
      'textSecondary': const Color(0xFF4A148C), // Dark purple text
      'textMuted': const Color(0xFF7B1FA2), // Purple-gray text
      'accentRed': const Color(0xFFE53935), // Red for errors
      'accentBlue': const Color(0xFF1E88E5), // Blue for secondary
      'accentYellow': const Color(0xFFFDD835), // Yellow for warnings
      'accentOrange': const Color(0xFFFB8C00), // Orange for info
      'accentPurple': const Color(0xFF8E24AA), // Purple for special items
      'primaryOnDark': const Color(0xFFFFFFFF), // White text on colored buttons
    },
  };
}

// Simple class to hold theme colors
class AppThemeColors {
  final Color primaryColor;
  final Color darkBackground;
  final Color cardBackground;
  final Color cardBackgroundLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentRed;
  final Color accentBlue;
  final Color accentYellow;
  final Color accentOrange;
  final Color accentPurple;
  final bool isLightBackground;

  AppThemeColors({
    required this.primaryColor,
    required this.darkBackground,
    required this.cardBackground,
    required this.cardBackgroundLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentRed,
    required this.accentBlue,
    required this.accentYellow,
    required this.accentOrange,
    required this.accentPurple,
    this.isLightBackground = false,
  });
}
