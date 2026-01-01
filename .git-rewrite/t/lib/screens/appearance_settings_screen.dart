import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance Settings',
          style: AppTheme.headlineSmall
              .copyWith(color: AppTheme.adaptiveTextColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('THEME'),
          const SizedBox(height: 12),
          _buildThemeSelector(),
          const SizedBox(height: 24),
          _buildSectionHeader('BACKGROUND'),
          const SizedBox(height: 12),
          _buildBackgroundSelector(),
          const SizedBox(height: 24),
          _buildSectionHeader('VISUAL EFFECTS'),
          const SizedBox(height: 12),
          _buildAnimationToggles(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
    );
  }

  Widget _buildThemeSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    final themeNames = {
      'cash_app': 'Finance Green (Default)',
      'midnight_blue': 'Midnight Blue',
      'purple_reign': 'Purple Reign',
      'ocean_breeze': 'Ocean Breeze',
      'sunset_glow': 'Sunset Glow',
      'forest_night': 'Forest Night',
      'paypal_blue': 'PayPal Blue',
      'coinbase_pro': 'Finance Pro',
      'light_mode': 'Light Mode',
      'light_blue': 'Finance Light',
      'soft_purple': 'Soft Purple',
    };

    final themeIcons = {
      'cash_app': Icons.attach_money,
      'midnight_blue': Icons.nightlight_round,
      'purple_reign': Icons.auto_awesome,
      'ocean_breeze': Icons.waves,
      'sunset_glow': Icons.wb_twilight,
      'forest_night': Icons.forest,
      'paypal_blue': Icons.account_balance_wallet,
      'coinbase_pro': Icons.currency_bitcoin,
      'light_mode': Icons.light_mode,
      'light_blue': Icons.wb_sunny,
      'soft_purple': Icons.palette,
    };

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: ThemeProvider.themePresets.keys.map((themeName) {
          final isSelected = currentTheme == themeName;
          final primaryColor =
              ThemeProvider.themePresets[themeName]!['primary']!;

          return Column(
            children: [
              ListTile(
                onTap: () async {
                  await themeProvider.setTheme(themeName);

                  // Force full app restart by navigating to root
                  if (mounted) {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    );

                    // Wait a moment for theme to save
                    await Future.delayed(const Duration(milliseconds: 500));

                    if (mounted) {
                      // Pop the loading dialog
                      Navigator.of(context).pop();

                      // Restart app by going to root and rebuilding
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    }
                  }
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.2)
                        : themeProvider.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    themeIcons[themeName],
                    color: isSelected ? primaryColor : themeProvider.textMuted,
                  ),
                ),
                title: Text(
                  themeNames[themeName]!,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected ? primaryColor : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: primaryColor)
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
              if (themeName != ThemeProvider.themePresets.keys.last)
                Divider(
                  color: AppTheme.cardBackgroundLight,
                  height: 1,
                  indent: 72,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBackgroundSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.backgroundMode;

    final modes = {
      'default': 'Theme Default',
      'dark': 'Pure Black',
      'slate': 'Slate Gray',
      'white': 'Pure White',
      'custom': 'Custom Color',
    };

    final modeIcons = {
      'default': Icons.auto_awesome,
      'dark': Icons.dark_mode,
      'slate': Icons.gradient,
      'white': Icons.light_mode,
      'custom': Icons.palette,
    };

    final modeColors = {
      'default': AppTheme.primaryGreen,
      'dark': const Color(0xFF000000),
      'slate': const Color(0xFF1E293B),
      'white': const Color(0xFFFFFFFF),
      'custom': themeProvider.customBackgroundColor ?? AppTheme.primaryGreen,
    };

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: modes.entries.map((entry) {
          final isSelected = currentMode == entry.key;
          final modeColor = modeColors[entry.key]!;

          return Column(
            children: [
              ListTile(
                onTap: () async {
                  if (entry.key == 'custom') {
                    // Show color picker dialog
                    final result = await _showCustomColorPicker();
                    if (result != null && mounted) {
                      if (result['isGradient'] == true) {
                        // Save gradient
                        await themeProvider.setBackgroundMode(
                          'gradient',
                          null,
                          result['color1'] as Color,
                          result['color2'] as Color,
                        );
                      } else {
                        // Save solid color
                        await themeProvider.setBackgroundMode(
                          'custom',
                          result['color'] as Color,
                        );
                      }
                      // Restart app
                      if (mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen),
                          ),
                        );
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      }
                    }
                  } else {
                    await themeProvider.setBackgroundMode(entry.key);
                    // Restart app
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen),
                        ),
                      );
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    }
                  }
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen.withOpacity(0.2)
                        : themeProvider.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    modeIcons[entry.key],
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : themeProvider.textMuted,
                  ),
                ),
                title: Text(
                  entry.value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: modeColor,
                          shape: BoxShape.circle,
                          border: entry.key == 'white'
                              ? Border.all(
                                  color: AppTheme.cardBackgroundLight, width: 1)
                              : null,
                        ),
                      ),
              ),
              if (entry.key != modes.keys.last)
                Divider(
                  color: AppTheme.cardBackgroundLight,
                  height: 1,
                  indent: 72,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCustomColorPicker() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    Color pickerColor = AppTheme.darkBackground;
    Color? selectedColor;
    bool showGradients = false;
    Color? gradientColor1 = themeProvider.gradientColor1;
    Color? gradientColor2 = themeProvider.gradientColor2;
    int editingGradientIndex = 1; // 1 = first color, 2 = second color

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Choose Background', style: AppTheme.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle between Solid and Gradient
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => showGradients = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !showGradients
                                  ? AppTheme.primaryGreen.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Solid Color',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMedium.copyWith(
                                color: !showGradients
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textMuted,
                                fontWeight: !showGradients
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => showGradients = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: showGradients
                                  ? AppTheme.primaryGreen.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Gradient',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMedium.copyWith(
                                color: showGradients
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textMuted,
                                fontWeight: showGradients
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (!showGradients) ...[
                  // Solid Color Picker
                  ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) {
                      selectedColor = color;
                      pickerColor = color;
                    },
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hueWheel,
                    labelTypes: const [],
                  ),
                ] else ...[
                  // GRADIENT BUILDER
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradientColor1 ?? Colors.black,
                              gradientColor2 ?? Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Selection Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => editingGradientIndex = 1),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: gradientColor1 ?? Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: editingGradientIndex == 1
                                        ? AppTheme.primaryGreen
                                        : Colors.white30,
                                    width: editingGradientIndex == 1 ? 3 : 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Start Color',
                                    style: TextStyle(
                                      color:
                                          (gradientColor1?.computeLuminance() ??
                                                      0) >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white,
                                      fontWeight: editingGradientIndex == 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => editingGradientIndex = 2),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: gradientColor2 ?? Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: editingGradientIndex == 2
                                        ? AppTheme.primaryGreen
                                        : Colors.white30,
                                    width: editingGradientIndex == 2 ? 3 : 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'End Color',
                                    style: TextStyle(
                                      color:
                                          (gradientColor2?.computeLuminance() ??
                                                      0) >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white,
                                      fontWeight: editingGradientIndex == 2
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Single Large Color Picker
                      ColorPicker(
                        pickerColor: editingGradientIndex == 1
                            ? (gradientColor1 ?? Colors.black)
                            : (gradientColor2 ?? Colors.white),
                        onColorChanged: (c) {
                          setState(() {
                            if (editingGradientIndex == 1) {
                              gradientColor1 = c;
                            } else {
                              gradientColor2 = c;
                            }
                          });
                        },
                        pickerAreaHeightPercent: 0.8,
                        enableAlpha: false,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsv,
                        labelTypes: const [],
                        pickerAreaBorderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 16),

                      // Presets
                      Text('Quick Presets',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMiniGradientPreset(
                              'Dark Slate',
                              const Color(0xFF1E293B),
                              const Color(0xFF0F172A),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Deep Ocean',
                              const Color(0xFF0A1A2A),
                              const Color(0xFF001A33),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Midnight',
                              const Color(0xFF121212),
                              const Color(0xFF000000),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Purple Haze',
                              const Color(0xFF1A0033),
                              const Color(0xFF0D001A),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Forest',
                              const Color(0xFF0A1A0A),
                              const Color(0xFF001A00),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Sunset',
                              const Color(0xFF1A0F0A),
                              const Color(0xFF331A0A),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Clean White',
                              const Color(0xFFFFFFFF),
                              const Color(0xFFF5F5F5),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                          _buildMiniGradientPreset(
                              'Soft Gray',
                              const Color(0xFFF5F5F5),
                              const Color(0xFFE0E0E0),
                              setState, (c1, c2) {
                            gradientColor1 = c1;
                            gradientColor2 = c2;
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: AppTheme.bodyMedium),
            ),
            TextButton(
              onPressed: () {
                if (showGradients &&
                    gradientColor1 != null &&
                    gradientColor2 != null) {
                  Navigator.of(context).pop({
                    'isGradient': true,
                    'color1': gradientColor1,
                    'color2': gradientColor2,
                  });
                } else {
                  Navigator.of(context).pop({
                    'isGradient': false,
                    'color': selectedColor ?? pickerColor,
                  });
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
              ),
              child: Text('Select',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniGradientPreset(String name, Color c1, Color c2,
      StateSetter setState, Function(Color, Color) onSelect) {
    return GestureDetector(
      onTap: () {
        setState(() => onSelect(c1, c2));
      },
      child: Container(
        width: 70,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationToggles() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: themeProvider.animatedGradients,
            onChanged: (value) => themeProvider.toggleAnimatedGradients(value),
            title: Text('Animated Gradients', style: AppTheme.bodyMedium),
            subtitle: Text(
              'Subtle color shifts on backgrounds',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            activeColor: AppTheme.primaryGreen,
            secondary: Icon(Icons.gradient, color: AppTheme.primaryGreen),
          ),
          Divider(height: 1, color: AppTheme.cardBackgroundLight),
          SwitchListTile(
            value: themeProvider.parallaxScrolling,
            onChanged: (value) => themeProvider.toggleParallaxScrolling(value),
            title: Text('Parallax Scrolling', style: AppTheme.bodyMedium),
            subtitle: Text(
              'Background moves slower when scrolling',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            activeColor: AppTheme.primaryGreen,
            secondary: Icon(Icons.layers, color: AppTheme.primaryGreen),
          ),
          Divider(height: 1, color: AppTheme.cardBackgroundLight),
          SwitchListTile(
            value: themeProvider.shimmerEffects,
            onChanged: (value) => themeProvider.toggleShimmerEffects(value),
            title: Text('Shimmer Effects', style: AppTheme.bodyMedium),
            subtitle: Text(
              'Glossy shine on cards and containers',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            activeColor: AppTheme.primaryGreen,
            secondary: Icon(Icons.auto_awesome, color: AppTheme.primaryGreen),
          ),
          Divider(height: 1, color: AppTheme.cardBackgroundLight),
          SwitchListTile(
            value: themeProvider.particleEffects,
            onChanged: (value) => themeProvider.toggleParticleEffects(value),
            title: Text('Particle Effects', style: AppTheme.bodyMedium),
            subtitle: Text(
              'Floating particles (uses more battery)',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            activeColor: AppTheme.primaryGreen,
            secondary: Icon(Icons.blur_on, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }
}
