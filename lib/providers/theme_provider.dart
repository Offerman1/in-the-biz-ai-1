import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'sunset_glow';
  String _backgroundMode =
      'default'; // 'default', 'dark', 'slate', 'white', 'custom', 'gradient'
  Color? _customBackgroundColor;
  Color? _gradientColor1;
  Color? _gradientColor2;
  final _supabase = Supabase.instance.client;

  // Per-theme background settings storage
  final Map<String, Map<String, dynamic>> _themeBackgroundSettings = {};

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
  Color accentRed = const Color(0x00ff3b30);
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
    // First, ensure the system UI is visible (edge-to-edge mode)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    // Then set the overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // Transparent status bar for edge-to-edge display
        statusBarColor: Colors.transparent,
        // Dark icons on light backgrounds, light icons on dark backgrounds
        statusBarIconBrightness:
            isLightBackground ? Brightness.dark : Brightness.light,
        // For iOS - opposite of icon brightness
        statusBarBrightness:
            isLightBackground ? Brightness.light : Brightness.dark,
        // Also update navigation bar for Android
        systemNavigationBarColor: isLightBackground
            ? darkBackground // Use the current background color
            : Colors.black,
        systemNavigationBarIconBrightness:
            isLightBackground ? Brightness.dark : Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  ThemeProvider() {
    _loadTheme();
    updateSystemUI();
  }

  static final Map<String, Map<String, Color>> _themePresets = {
    // ====== DEFAULT THEME ======
    'sunset_glow': {
      'primary': const Color(0xFFFF6B35), // Keep orange accent
      'background': const Color(0xFF0D0D0D), // Very dark/black background
      'card': const Color(0xFF1A1A1A), // Dark neutral card
      'cardLight': const Color(0xFF2A2A2A), // Slightly lighter
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary':
          const Color(0xFFB3B3B3), // Neutral gray instead of orange tint
      'textMuted': const Color(0xFF666666), // Neutral muted
      'accentRed': const Color(0xFFFF3366),
      'accentBlue': const Color(0xFF6B8CFF),
      'accentYellow': const Color(0xFFFFCC33),
      'accentOrange': const Color(0xFFFF8C42),
      'accentPurple': const Color(0xFFAF52DE),
    },
    // ====== DARK THEMES ======
    'cash_app': {
      'primary': const Color.fromARGB(
          167, 16, 185, 38), // Forest Night green (YOUR FAVORITE!)
      'background': const Color(0xFF0D0D0D), // Almost black
      'card': const Color(0xFF1A1A1A), // Dark gray
      'cardLight': const Color(0xFF2C2C2C), // Lighter gray
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFEF4444),
      'accentBlue': const Color(0xFF3B82F6),
      'accentYellow': const Color(0xFFFBBF24),
      'accentOrange': const Color(0xFFF97316),
      'accentPurple': const Color(0xFFA855F7),
    },
    'midnight_blue': {
      'primary': const Color(0xFF3B82F6), // Blue accent
      'background': const Color(0xFF0D0D0D),
      'card': const Color(0xFF1A1A1A),
      'cardLight': const Color(0xFF2C2C2C),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFEF4444),
      'accentBlue': const Color(0xFF06B6D4),
      'accentYellow': const Color(0xFFFBBF24),
      'accentOrange': const Color(0xFFF97316),
      'accentPurple': const Color(0xFFA855F7),
    },
    'purple_reign': {
      'primary': const Color(0xFFA855F7), // Purple accent
      'background': const Color(0xFF0D0D0D),
      'card': const Color(0xFF1A1A1A),
      'cardLight': const Color(0xFF2C2C2C),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFEF4444),
      'accentBlue': const Color(0xFF06B6D4),
      'accentYellow': const Color(0xFFFBBF24),
      'accentOrange': const Color(0xFFF97316),
      'accentPurple': const Color(0xFFC084FC),
    },
    'ocean_breeze': {
      'primary': const Color(0xFF06B6D4), // Cyan/teal accent
      'background': const Color(0xFF0D0D0D),
      'card': const Color(0xFF1A1A1A),
      'cardLight': const Color(0xFF2C2C2C),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFEF4444),
      'accentBlue': const Color(0xFF3B82F6),
      'accentYellow': const Color(0xFFFBBF24),
      'accentOrange': const Color(0xFFF97316),
      'accentPurple': const Color(0xFFA855F7),
    },
    'neon_cash': {
      'primary': const Color(0xFF00D632), // Original bright neon green
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
    'paypal_blue': {
      'primary': const Color(0xFF0070BA), // Azure blue
      'background': const Color(0xFF0D0D0D),
      'card': const Color(0xFF1A1A1A),
      'cardLight': const Color(0xFF2C2C2C),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFEF4444),
      'accentBlue': const Color(0xFF3B82F6),
      'accentYellow': const Color(0xFFFBBF24),
      'accentOrange': const Color(0xFFF97316),
      'accentPurple': const Color(0xFFA855F7),
    },
    'coinbase_pro': {
      'primary': const Color(0xFF5B5FEF), // Blue/purple accent
      'background': const Color(0xFF0D0D0D),
      'card': const Color(0xFF1A1A1A),
      'cardLight': const Color(0xFF2C2C2C),
      'textPrimary': const Color(0xFFFFFFFF),
      'textSecondary': const Color(0xFFB3B3B3),
      'textMuted': const Color(0xFF666666),
      'accentRed': const Color(0xFFEF4444),
      'accentBlue': const Color(0xFF3B82F6),
      'accentYellow': const Color(0xFFFBBF24),
      'accentOrange': const Color(0xFFF97316),
      'accentPurple': const Color(0xFF8B5CF6),
    },
    // ====== LIGHT THEMES ======
    'cash_light': {
      'primary': const Color(0xFF059669), // Emerald green accent ONLY
      'background': const Color(0xFFF0FDF4), // Soft mint green tint
      'card': const Color(0xFFFFFFFF), // Pure white cards pop on tinted bg
      'cardLight': const Color(0xFFBBF7D0), // VIBRANT mint green
      'textPrimary': const Color(0xFF111827), // Almost black
      'textSecondary': const Color(0xFF4B5563), // Dark gray
      'textMuted': const Color(0xFF9CA3AF), // Medium gray
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'light_blue': {
      'primary': const Color(0xFF0070BA), // Blue accent ONLY
      'background': const Color(0xFFEFF6FF), // Soft blue tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFBFDBFE), // VIBRANT blue
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'purple_light': {
      'primary': const Color(0xFF7C3AED), // Purple accent ONLY
      'background': const Color(0xFFFAF5FF), // Soft lavender tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFE9D5FF), // VIBRANT purple (visible!)
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'sunset_light': {
      'primary': const Color(0xFFEA580C), // Orange accent ONLY
      'background':
          const Color(0xFFFFF0E5), // Light peachy-orange (start of gradient)
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFE5F2FF), // Light blue (end of gradient)
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'ocean_light': {
      'primary': const Color(0xFF0891B2), // Cyan accent ONLY
      'background': const Color(0xFFECFEFF), // Soft cyan tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFA5F3FC), // VIBRANT cyan
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'pink_light': {
      'primary': const Color(0xFFDB2777), // Pink accent ONLY
      'background': const Color(0xFFFDF2F8), // Soft rose tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFFBCFE8), // VIBRANT pink
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'slate_light': {
      'primary': const Color(0xFF475569), // Slate gray accent ONLY
      'background': const Color(0xFFF8FAFC), // Soft slate tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFFCFDFE), // Lighter slate (closer to white)
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'mint_light': {
      'primary': const Color(0xFF10B981), // Mint green accent ONLY
      'background': const Color(0xFFF0FDF4), // Fresh mint tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFBBF7D0), // VIBRANT mint
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'lavender_light': {
      'primary': const Color(0xFF8B5CF6), // Lavender accent ONLY
      'background': const Color(0xFFFAF5FF), // Soft lavender tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFE9D5FF), // VIBRANT lavender
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    'gold_light': {
      'primary': const Color(0xFFCA8A04), // Gold accent ONLY
      'background': const Color(0xFFFEFCE8), // Warm golden tint
      'card': const Color(0xFFFFFFFF), // Pure white cards
      'cardLight': const Color(0xFFFDE68A), // VIBRANT gold
      'textPrimary': const Color(0xFF111827),
      'textSecondary': const Color(0xFF4B5563),
      'textMuted': const Color(0xFF9CA3AF),
      'accentRed': const Color(0xFFDC2626),
      'accentBlue': const Color(0xFF2563EB),
      'accentYellow': const Color(0xFFF59E0B),
      'accentOrange': const Color(0xFFEA580C),
      'accentPurple': const Color(0xFF9333EA),
    },
    // Remove old forest_night, light_mode, soft_purple entries
  };

  Future<void> _loadTheme() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('user_preferences')
          .select(
              'theme, animated_gradients, parallax_scrolling, shimmer_effects, particle_effects, theme_background_settings')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && response['theme'] != null) {
        _currentTheme = response['theme'];
        _animatedGradients = response['animated_gradients'] ?? true;
        _parallaxScrolling = response['parallax_scrolling'] ?? true;
        _shimmerEffects = response['shimmer_effects'] ?? true;
        _particleEffects = response['particle_effects'] ?? false;

        // Load per-theme background settings
        if (response['theme_background_settings'] != null) {
          final savedSettings =
              response['theme_background_settings'] as Map<String, dynamic>;
          savedSettings.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              _themeBackgroundSettings[key] = Map<String, dynamic>.from(value);
            }
          });

          // Apply current theme's background settings if saved
          final currentSettings = _themeBackgroundSettings[_currentTheme];
          if (currentSettings != null) {
            _backgroundMode = currentSettings['mode'] ?? 'default';
            _customBackgroundColor = currentSettings['customColor'] != null
                ? Color(currentSettings['customColor'])
                : null;
            _gradientColor1 = currentSettings['gradientColor1'] != null
                ? Color(currentSettings['gradientColor1'])
                : null;
            _gradientColor2 = currentSettings['gradientColor2'] != null
                ? Color(currentSettings['gradientColor2'])
                : null;
          }
        }

        _applyTheme(_currentTheme);
        if (_backgroundMode != 'default') {
          _applyBackgroundMode();
        }
        notifyListeners();
      } else {
        // New user or no theme set - use default 'sunset_glow' and save it
        _currentTheme = 'sunset_glow';
        _applyTheme(_currentTheme);
        notifyListeners();
        
        // Save default theme to database
        await _supabase.from('user_preferences').upsert({
          'user_id': user.id,
          'theme': 'sunset_glow',
          'updated_at': DateTime.now().toIso8601String(),
        });
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
    // Save current theme's background settings before switching
    if (_currentTheme.isNotEmpty) {
      _themeBackgroundSettings[_currentTheme] = {
        'mode': _backgroundMode,
        'customColor': _customBackgroundColor?.toARGB32(),
        'gradientColor1': _gradientColor1?.toARGB32(),
        'gradientColor2': _gradientColor2?.toARGB32(),
      };
    }

    _currentTheme = themeName;

    // Load the new theme's saved background settings (if any)
    final savedSettings = _themeBackgroundSettings[themeName];
    if (savedSettings != null) {
      _backgroundMode = savedSettings['mode'] ?? 'default';
      _customBackgroundColor = savedSettings['customColor'] != null
          ? Color(savedSettings['customColor'])
          : null;
      _gradientColor1 = savedSettings['gradientColor1'] != null
          ? Color(savedSettings['gradientColor1'])
          : null;
      _gradientColor2 = savedSettings['gradientColor2'] != null
          ? Color(savedSettings['gradientColor2'])
          : null;
    } else {
      // No saved settings for this theme - use defaults
      _backgroundMode = 'default';
      _customBackgroundColor = null;
      _gradientColor1 = null;
      _gradientColor2 = null;
    }

    _applyTheme(themeName);
    if (_backgroundMode != 'default') {
      _applyBackgroundMode(); // Apply saved background mode
    }
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
      'sunset_glow': 'In the Biz',
      'neon_cash': 'Neon Cash',
      'paypal_blue': 'PayPal Blue',
      'coinbase_pro': 'Finance Pro',
      'cash_light': 'Cash Light',
      'light_blue': 'Finance Light',
      'purple_light': 'Purple Light',
      'sunset_light': 'Sunset Light',
      'ocean_light': 'Ocean Light',
      'pink_light': 'Pink Light',
      'slate_light': 'Slate Light',
      'mint_light': 'Mint Light',
      'lavender_light': 'Lavender Light',
      'gold_light': 'Gold Light',
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

    // Save to per-theme settings
    _themeBackgroundSettings[_currentTheme] = {
      'mode': mode,
      'customColor': customColor?.toARGB32(),
      'gradientColor1': gradientColor1?.toARGB32(),
      'gradientColor2': gradientColor2?.toARGB32(),
    };

    _applyBackgroundMode();
    updateSystemUI(); // Update status bar icons
    notifyListeners();

    // Save to database (with theme-specific key)
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Save per-theme background settings as JSON
      await _supabase.from('user_preferences').upsert({
        'user_id': user.id,
        'background_mode': mode,
        'custom_bg_color': customColor?.toARGB32(),
        'gradient_color1': gradientColor1?.toARGB32(),
        'gradient_color2': gradientColor2?.toARGB32(),
        'theme_background_settings': _themeBackgroundSettings,
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
      brightness: isLightBackground ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryColor,
      colorScheme: isLightBackground
          ? ColorScheme.light(
              primary: primaryColor,
              secondary: primaryColor,
              surface: cardBackground,
              error: accentRed,
            )
          : ColorScheme.dark(
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
      // Input decoration theme for text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackgroundLight,
        hintStyle: TextStyle(
          color: isLightBackground ? Colors.black54 : Colors.white54,
        ),
        labelStyle: TextStyle(
          color: isLightBackground ? Colors.black87 : Colors.white,
        ),
      ),
      // Text selection theme for cursor and selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
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
