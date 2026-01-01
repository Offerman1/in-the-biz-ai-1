import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'cash_app';
  String _backgroundMode =
      'default'; // 'default', 'dark', 'slate', 'white', 'custom', 'gradient'
  Color? _customBackgroundColor;
  Color? _gradientColor1;
  Color? _gradientColor2;
  final _supabase = Supabase.instance.client;

  // Animation toggles
  bool _animatedGradients = true;
  bool _parallaxScrolling = false; // Off by default
  bool _shimmerEffects = false; // Off by default
  bool _particleEffects = false; // Off by default to save battery

  // Theme colors - these are what the app will actually use
  Color primaryColor = const Color(0xFF00D632);
  Color darkBackground = const Color(0xFF121212);
  Color cardBackground = const Color(0xFF1E1E1E);
  Color cardBackgroundLight = const Color(0xFF2C2C2C);
  Color textPrimary = const Color(0xFFFFFFFF);
  Color textSecondary = const Color(0xFFB3B3B3);
  Color textMuted = const Color(0xFF666666);
  Color accentRed = const Color(0xFF3B30);
  Color accentBlue = const Color(0xFF007AFF);
  Color accentYellow = const Color(0xFFFFCC00);
  Color accentOrange = const Color(0xFFFF9500);
  Color accentPurple = const Color(0xFFAF52DE);

  String get currentTheme => _currentTheme;
  String get backgroundMode => _backgroundMode;
  Color? get customBackgroundColor => _customBackgroundColor;
  Color? get gradientColor1 => _gradientColor1;
  Color? get gradientColor2 => _gradientColor2;
  bool get animatedGradients => _animatedGradients;
  bool get parallaxScrolling => _parallaxScrolling;
  bool get shimmerEffects => _shimmerEffects;
  bool get particleEffects => _particleEffects;

  // Adaptive text color based on background luminance
  Color get adaptiveTextColor {
    Color bgColor = darkBackground; // default

    if (_backgroundMode == 'gradient' && _gradientColor1 != null) {
      bgColor = _gradientColor1!;
    } else if (_backgroundMode == 'custom' && _customBackgroundColor != null) {
      bgColor = _customBackgroundColor!;
    } else if (_backgroundMode == 'white') {
      bgColor = Colors.white;
    } else if (_backgroundMode == 'slate') {
      bgColor = const Color(0xFF1E293B);
    }

    return bgColor.computeLuminance() > 0.5
        ? Colors.black87 // Light background
        : Colors.white; // Dark background
  }

  // Check if background is light
  bool get isLightBackground {
    Color bgColor = darkBackground;

    if (_backgroundMode == 'gradient' && _gradientColor1 != null) {
      bgColor = _gradientColor1!;
    } else if (_backgroundMode == 'custom' && _customBackgroundColor != null) {
      bgColor = _customBackgroundColor!;
    } else if (_backgroundMode == 'white') {
      bgColor = Colors.white;
    } else if (_backgroundMode == 'slate') {
      bgColor = const Color(0xFF1E293B);
    }

    return bgColor.computeLuminance() > 0.5;
  }

  // Update system status bar based on background
  void updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // Use semi-transparent background on light themes so icons are visible
        statusBarColor: isLightBackground
            ? Colors.white.withOpacity(0.9)
            : Colors.transparent,
        statusBarIconBrightness:
            isLightBackground ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            isLightBackground ? Brightness.light : Brightness.dark,
      ),
    );
  }

  ThemeProvider() {
    _loadTheme();
    updateSystemUI();
  }

  static final Map<String, Map<String, Color>> _themePresets = {
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
    },
    'forest_night': {
      'primary': const Color.fromARGB(
          167, 16, 185, 38), // Emerald green accent for buttons/highlights
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
    },
    // NEW THEMES
    'paypal_blue': {
      'primary':
          const Color(0xFF0070BA), // PayPal blue accent for buttons/highlights
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
    },
    'light_mode': {
      'primary': const Color.fromARGB(
          255, 107, 197, 89), // Darker emerald green (professional, not neon)
      'background': const Color(0xFFFFFFFF),
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
    },
    'soft_purple': {
      'primary': const Color(0xFF8E24AA),
      'background': const Color(0xFFFAF9FC),
      'card': const Color(0xFFF3E5F5),
      'cardLight': const Color(0xFFE1BEE7),
      'textPrimary': const Color(0xFF000000),
      'textSecondary': const Color(0xFF4A148C),
      'textMuted': const Color(0xFF7B1FA2),
      'accentRed': const Color(0xFFE53935),
      'accentBlue': const Color(0xFF1E88E5),
      'accentYellow': const Color(0xFFFDD835),
      'accentOrange': const Color(0xFFFB8C00),
      'accentPurple': const Color(0xFF8E24AA),
    },
  };

  Future<void> _loadTheme() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('user_preferences')
          .select(
              'theme, animated_gradients, parallax_scrolling, shimmer_effects, particle_effects')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && response['theme'] != null) {
        _currentTheme = response['theme'];
        _animatedGradients = response['animated_gradients'] ?? true;
        _parallaxScrolling = response['parallax_scrolling'] ?? true;
        _shimmerEffects = response['shimmer_effects'] ?? true;
        _particleEffects = response['particle_effects'] ?? false;
        _applyTheme(_currentTheme);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  void _applyTheme(String themeName) {
    final theme = _themePresets[themeName];
    if (theme == null) return;

    primaryColor = theme['primary']!;
    darkBackground = theme['background']!;
    cardBackground = theme['card']!;
    cardBackgroundLight = theme['cardLight']!;
    textPrimary = theme['textPrimary']!;
    textSecondary = theme['textSecondary']!;
    textMuted = theme['textMuted']!;
    accentRed = theme['accentRed']!;
    accentBlue = theme['accentBlue']!;
    accentYellow = theme['accentYellow']!;
    accentOrange = theme['accentOrange']!;
    accentPurple = theme['accentPurple']!;

    // Also update AppTheme static colors
    AppTheme.setColors(AppThemeColors(
      primaryColor: primaryColor,
      darkBackground: darkBackground,
      cardBackground: cardBackground,
      cardBackgroundLight: cardBackgroundLight,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      accentRed: accentRed,
      accentBlue: accentBlue,
      accentYellow: accentYellow,
      accentOrange: accentOrange,
      accentPurple: accentPurple,
      isLightBackground: isLightBackground,
    ));
  }

  Future<void> setTheme(String themeName, {bool setPending = true}) async {
    _currentTheme = themeName;
    _applyTheme(themeName);
    updateSystemUI(); // Update status bar icons for theme
    notifyListeners();

    // Save to database
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get current theme before changing (for undo)
      String? previousTheme;
      if (setPending) {
        final prefs = await _supabase
            .from('user_preferences')
            .select('theme')
            .eq('user_id', user.id)
            .maybeSingle();
        previousTheme = prefs?['theme'] as String?;
      }

      // Get theme display name
      final themeDisplayName = _getThemeDisplayName(themeName);

      await _supabase.from('user_preferences').upsert({
        'user_id': user.id,
        'theme': themeName,
        'pending_theme_change': setPending,
        'previous_theme_id': previousTheme,
        'new_theme_name': themeDisplayName,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  String _getThemeDisplayName(String themeKey) {
    final names = {
      'cash_app': 'Finance Green',
      'midnight_blue': 'Midnight Blue',
      'purple_reign': 'Purple Reign',
      'ocean_breeze': 'Ocean Breeze',
      'sunset_glow': 'Sunset Glow',
      'forest_night': 'Forest Night',
      'paypal_blue': 'PayPal Blue',
      'finance_pro': 'Finance Pro',
      'light_mode': 'Light Mode',
      'light_blue': 'Finance Light',
      'soft_purple': 'Soft Purple',
    };
    return names[themeKey] ?? themeKey;
  }

  Future<Map<String, dynamic>?> getPendingThemeChange() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final prefs = await _supabase
          .from('user_preferences')
          .select('pending_theme_change, previous_theme_id, new_theme_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (prefs != null && prefs['pending_theme_change'] == true) {
        return prefs;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting pending theme change: $e');
      return null;
    }
  }

  Future<void> clearPendingThemeChange() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_preferences').update({
        'pending_theme_change': false,
        'previous_theme_id': null,
        'new_theme_name': null,
      }).eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error clearing pending theme change: $e');
    }
  }

  Future<void> undoThemeChange(String previousTheme) async {
    await setTheme(previousTheme, setPending: false);
    await clearPendingThemeChange();
  }

  Future<void> setBackgroundMode(String mode,
      [Color? customColor,
      Color? gradientColor1,
      Color? gradientColor2]) async {
    _backgroundMode = mode;
    _customBackgroundColor = customColor;
    _gradientColor1 = gradientColor1;
    _gradientColor2 = gradientColor2;
    _applyBackgroundMode();
    updateSystemUI(); // Update status bar icons
    notifyListeners();

    // Save to database
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_preferences').upsert({
        'user_id': user.id,
        'background_mode': mode,
        'custom_bg_color': customColor?.value,
        'gradient_color1': gradientColor1?.value,
        'gradient_color2': gradientColor2?.value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving background mode: $e');
    }
  }

  void _applyBackgroundMode() {
    // ONLY change the main background, nothing else
    switch (_backgroundMode) {
      case 'dark':
        darkBackground = const Color(0xFF000000);
        break;
      case 'slate':
        darkBackground = const Color(0xFF1E293B);
        break;
      case 'white':
        darkBackground = const Color(0xFFFFFFFF);
        break;
      case 'custom':
        if (_customBackgroundColor != null) {
          darkBackground = _customBackgroundColor!;
        }
        break;
      case 'default':
      default:
        _applyTheme(_currentTheme);
        return;
    }

    // Update AppTheme with ONLY background changed, everything else from theme
    AppTheme.setColors(AppThemeColors(
      primaryColor: primaryColor,
      darkBackground: darkBackground,
      cardBackground: cardBackground,
      cardBackgroundLight: cardBackgroundLight,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      accentRed: accentRed,
      accentBlue: accentBlue,
      accentYellow: accentYellow,
      accentOrange: accentOrange,
      accentPurple: accentPurple,
      isLightBackground: isLightBackground,
    ));
  }

  ThemeData getThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: cardBackground,
        error: accentRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: isLightBackground ? Colors.black87 : Colors.white,
        iconTheme: IconThemeData(
          color: isLightBackground ? Colors.black87 : Colors.white,
        ),
        elevation: 0,
      ),
      iconTheme: IconThemeData(
        color: isLightBackground ? Colors.black87 : Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  // Animation toggle methods
  Future<void> toggleAnimatedGradients(bool value) async {
    _animatedGradients = value;
    notifyListeners();
    await _saveAnimationSettings();
  }

  Future<void> toggleParallaxScrolling(bool value) async {
    _parallaxScrolling = value;
    notifyListeners();
    await _saveAnimationSettings();
  }

  Future<void> toggleShimmerEffects(bool value) async {
    _shimmerEffects = value;
    notifyListeners();
    await _saveAnimationSettings();
  }

  Future<void> toggleParticleEffects(bool value) async {
    _particleEffects = value;
    notifyListeners();
    await _saveAnimationSettings();
  }

  Future<void> _saveAnimationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_preferences').upsert({
        'user_id': user.id,
        'animated_gradients': _animatedGradients,
        'parallax_scrolling': _parallaxScrolling,
        'shimmer_effects': _shimmerEffects,
        'particle_effects': _particleEffects,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving animation settings: $e');
    }
  }

  static Map<String, Map<String, Color>> get themePresets => _themePresets;
}
