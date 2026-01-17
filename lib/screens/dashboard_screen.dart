import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../models/shift.dart';
import '../models/goal.dart';
import '../providers/shift_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/add_shift_screen.dart';
import '../screens/all_shifts_screen.dart';
import '../screens/better_calendar_screen.dart';
import '../widgets/hero_card.dart';
import '../screens/assistant_screen.dart';
import '../screens/stats_with_checkout_tab.dart';
import '../screens/single_shift_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/goals_screen.dart';
import '../services/database_service.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../utils/tour_targets.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/particle_background.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/animated_logo.dart';
import '../widgets/floating_tour_button.dart';
import '../widgets/tour_transition_modal.dart';
import '../widgets/pulsing_button.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  // Nav bar GlobalKeys for tour
  final GlobalKey _homeNavKey = GlobalKey();
  final GlobalKey _calendarNavKey = GlobalKey();
  final GlobalKey _chatNavKey = GlobalKey();
  final GlobalKey _statsNavKey = GlobalKey();

  // Store the tour trigger callback from _HomeScreen
  VoidCallback? _startHomeTour;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ShiftProvider>(context, listen: false).loadShifts();
    });
  }

  List<Widget> get _screens => [
        _HomeScreen(
          homeNavKey: _homeNavKey,
          calendarNavKey: _calendarNavKey,
          chatNavKey: _chatNavKey,
          statsNavKey: _statsNavKey,
          onTourReady: (callback) {
            _startHomeTour = callback; // Store the callback
          },
        ),
        BetterCalendarScreen(
            isVisible: _selectedIndex == 1, chatNavKey: _chatNavKey),
        AssistantScreen(
            isVisible: _selectedIndex == 2, statsNavKey: _statsNavKey),
        StatsWithCheckoutTab(isVisible: _selectedIndex == 3),
      ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGradient = themeProvider.backgroundMode == 'gradient';
    final isLightBg = themeProvider.isLightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLightBg ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLightBg ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isLightBg ? AppTheme.darkBackground : Colors.black,
        systemNavigationBarIconBrightness:
            isLightBg ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background layers (extends under status bar for edge-to-edge)
            Positioned.fill(
              child: RepaintBoundary(
                child: ParticleBackground(
                  enabled: themeProvider.particleEffects,
                  particleColor: AppTheme.primaryGreen,
                  child: AnimatedGradientBackground(
                    enabled: themeProvider.animatedGradients,
                    baseColor:
                        _getLightThemeBaseColor(themeProvider.currentTheme),
                    accentColor: isLightBg
                        ? _getLightThemeAccentColor(themeProvider.currentTheme)
                        : null,
                    isGradient: isGradient,
                    gradientColor1: themeProvider.gradientColor1,
                    gradientColor2: themeProvider.gradientColor2,
                    child: Container(), // Just the background
                  ),
                ),
              ),
            ),
            // Content layer (with SafeArea to avoid status bar)
            SafeArea(
              child: RepaintBoundary(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ),
            // Floating tour button (context-aware based on current screen)
            FloatingTourButton(
              onTap: () {
                // Start tour for current screen
                switch (_selectedIndex) {
                  case 0: // Home/Dashboard
                    _startHomeTour
                        ?.call(); // Call the tour trigger from _HomeScreen
                    break;
                  case 1: // Calendar
                    // TODO: Implement calendar tour
                    break;
                  case 2: // Chat
                    // TODO: Implement chat tour
                    break;
                  case 3: // Stats
                    // TODO: Implement stats tour
                    break;
                }
              },
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.navBarBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      0, Icons.home_outlined, Icons.home, 'Home', _homeNavKey),
                  _buildNavItem(1, Icons.calendar_today_outlined,
                      Icons.calendar_today, 'Calendar', _calendarNavKey),
                  _buildNavItem(2, Icons.auto_awesome_outlined,
                      Icons.auto_awesome, 'Chat', _chatNavKey),
                  _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart,
                      'Stats', _statsNavKey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon,
      String label, GlobalKey key) {
    final isSelected = _selectedIndex == index;

    // Determine if this nav item should pulse
    String? pulsingTarget;
    if (label == 'Home') pulsingTarget = 'home';
    if (label == 'Calendar') pulsingTarget = 'calendar';
    if (label == 'Chat') pulsingTarget = 'chat';
    if (label == 'Stats') pulsingTarget = 'stats';

    Widget navItem = GestureDetector(
      key: key,
      onTap: () {
        // Hide any non-blocking tour modal
        TourTransitionModal.hide();

        // Clear pulsing when tapped
        final tourService = Provider.of<TourService>(context, listen: false);
        if (tourService.pulsingTarget == pulsingTarget) {
          tourService.clearPulsingTarget();

          // If coming from Stats to Home for Settings tour, pulse the menu button
          if (pulsingTarget == 'home' &&
              tourService.expectedScreen == 'settings') {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                tourService.setPulsingTarget('menuButton');
                // Show modal for menu
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withValues(alpha: 0.7),
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 2),
                    ),
                    title: Text(
                      '⚙️ Open Settings',
                      style:
                          TextStyle(color: AppTheme.primaryGreen, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    content: Text(
                      'Tap the menu button (⋮) in the top right corner.',
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Got It'),
                        ),
                      ),
                    ],
                  ),
                );
              }
            });
          }
        }
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.navBarActiveBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppTheme.navBarIconActiveColor
                  : AppTheme.navBarIconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.navBarIconActiveColor
                    : AppTheme.navBarIconColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with PulsingButton if this item can pulse
    if (pulsingTarget != null) {
      return Consumer<TourService>(
        builder: (context, tourService, child) {
          return PulsingButton(
            isPulsing: tourService.pulsingTarget == pulsingTarget,
            child: navItem,
          );
        },
      );
    }

    return navItem;
  }

  // Helper methods for light theme gradients
  Color _getLightThemeBaseColor(String theme) {
    switch (theme) {
      case 'sunset_light':
        return const Color(0xFFFFEEDD); // Peach
      case 'cash_light':
        return const Color(0xFFF4FDF9); // Very light mint
      case 'light_blue':
        return const Color(0xFFF6FAFF); // Very light blue
      case 'purple_light':
        return const Color(0xFFFAF6FF); // Very light lavender
      case 'ocean_light':
        return const Color(0xFFF4FCFE); // Very light cyan
      case 'pink_light':
        return const Color(0xFFFFF7FC); // Very light pink
      case 'slate_light':
        return const Color(0xFFF9FAFC); // Very light slate
      case 'mint_light':
        return const Color(0xFFF4FDF9); // Very light mint
      case 'lavender_light':
        return const Color(0xFFFAF6FF); // Very light lavender
      case 'gold_light':
        return const Color(0xFFFFFCF4); // Very light gold
      default:
        return AppTheme.darkBackground;
    }
  }

  Color? _getLightThemeAccentColor(String theme) {
    switch (theme) {
      case 'sunset_light':
        return const Color(0xFFDAEEFF); // Light blue
      case 'cash_light':
        return const Color(0xFFEEFAF3); // Lighter mint
      case 'light_blue':
        return const Color(0xFFEEF6FF); // Lighter blue
      case 'purple_light':
        return const Color(0xFFF4EEFF); // Lighter lavender
      case 'ocean_light':
        return const Color(0xFFEDF9FC); // Lighter cyan
      case 'pink_light':
        return const Color(0xFFFFF1F8); // Lighter pink
      case 'slate_light':
        return const Color(0xFFF4F7FA); // Lighter slate
      case 'mint_light':
        return const Color(0xFFEEFAF3); // Lighter mint
      case 'lavender_light':
        return const Color(0xFFF4EEFF); // Lighter lavender
      case 'gold_light':
        return const Color(0xFFFDF4D4); // Lighter gold
      default:
        return null;
    }
  }
}

// ============================================================
// HOME SCREEN (Dashboard Tab)
// ============================================================

class _HomeScreen extends StatefulWidget {
  final GlobalKey homeNavKey;
  final GlobalKey calendarNavKey;
  final GlobalKey chatNavKey;
  final GlobalKey statsNavKey;
  final Function(VoidCallback)
      onTourReady; // NEW: Callback to pass tour trigger up

  const _HomeScreen({
    required this.homeNavKey,
    required this.calendarNavKey,
    required this.chatNavKey,
    required this.statsNavKey,
    required this.onTourReady, // NEW
  });

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final DatabaseService _db = DatabaseService();
  Goal? _activeGoal;
  String _selectedPeriod = 'week'; // 'day', 'week', 'month', 'year', 'all'
  String? _selectedJobId; // null means "All Jobs"
  List<Map<String, dynamic>> _jobs = [];
  bool _isRefreshing = false;
  TourService? _tourService;
  bool _isTourShowing = false; // Guard to prevent multiple simultaneous tours

  // Tour GlobalKeys
  final GlobalKey _addShiftButtonKey = GlobalKey();
  final GlobalKey _recentShiftsKey = GlobalKey();
  final GlobalKey _seeAllButtonKey = GlobalKey();
  final GlobalKey _goalsButtonKey = GlobalKey();
  final GlobalKey _refreshButtonKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();

  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadGoal();

    // Pass the tour trigger function up to parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any stuck tour overlays from previous sessions
      TourTransitionModal.forceHide();

      widget.onTourReady(() {
        final tourService = Provider.of<TourService>(context, listen: false);
        tourService.startTour(checkJobs: true);
      });

      _checkAndStartTour();

      // Listen to tour service changes
      _tourService = Provider.of<TourService>(context, listen: false);
      _tourService?.addListener(_onTourServiceChanged);
    });
  }

  @override
  void dispose() {
    _tourService?.removeListener(_onTourServiceChanged);
    _tutorialCoachMark = null;
    super.dispose();
  }

  /// Check if a shift has already started (for filtering recent shifts)
  bool _hasShiftStarted(Shift shift) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shiftDate =
        DateTime(shift.date.year, shift.date.month, shift.date.day);

    // Exclude future dates
    if (shiftDate.isAfter(today)) return false;

    // For today's shifts, check if they've started
    if (shiftDate.isAtSameMomentAs(today)) {
      if (shift.startTime != null && shift.startTime!.isNotEmpty) {
        try {
          // Parse start time (e.g., "4:30 PM")
          final timeParts = shift.startTime!.trim().split(' ');
          if (timeParts.length == 2) {
            final hourMin = timeParts[0].split(':');
            if (hourMin.length == 2) {
              int hour = int.parse(hourMin[0]);
              final minute = int.parse(hourMin[1]);
              final isPM = timeParts[1].toUpperCase() == 'PM';

              if (isPM && hour != 12) hour += 12;
              if (!isPM && hour == 12) hour = 0;

              final shiftStartTime = DateTime(
                shift.date.year,
                shift.date.month,
                shift.date.day,
                hour,
                minute,
              );

              // Only include if shift has started
              final hasStarted = now.isAfter(shiftStartTime) ||
                  now.isAtSameMomentAs(shiftStartTime);

              debugPrint(
                  '🕒 Shift time check: ${shift.startTime} -> Start: $shiftStartTime, Now: $now, HasStarted: $hasStarted');
              return hasStarted;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing shift time "${shift.startTime}": $e');
          // If parsing fails, exclude today's shifts to be safe
          return false;
        }
      }
      // If no start time for today's shift, exclude it from recent shifts
      debugPrint(
          '⚠️ Today\'s shift has no start time, excluding from recent shifts');
      return false;
    }

    // Include all past shifts
    return true;
  }

  void _onTourServiceChanged() {
    if (!mounted) return;

    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 Tour service changed: isActive=${tourService.isActive}, expectedScreen=${tourService.expectedScreen}, currentStep=${tourService.currentStep}');

    // ONLY trigger on initial activation (step -1), NOT on every step change
    // The onFinish callback handles step progression, not this listener
    if (tourService.isActive &&
        tourService.expectedScreen == 'dashboard' &&
        tourService.currentStep == -1 &&
        !_isTourShowing) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkJobPrerequisite();
        }
      });
    }
  }

  Future<void> _checkAndStartTour() async {
    if (!mounted) return;

    try {
      final tourService = Provider.of<TourService>(context, listen: false);

      debugPrint(
          '🎯 Tour Check: isActive=${tourService.isActive}, currentStep=${tourService.currentStep}, expectedScreen=${tourService.expectedScreen}');

      // Check if we're on the job prerequisite step (-1)
      if (tourService.isActive && tourService.isJobPrerequisiteStep) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint('🎯 Checking job prerequisite...');
          await _checkJobPrerequisite();
        }
        return;
      }

      // Check if tour is active and we're on the expected screen
      if (tourService.isActive && tourService.expectedScreen == 'dashboard') {
        // Wait a bit longer to ensure all widgets are fully laid out
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint('🎯 Starting dashboard tour...');
          _showDashboardTour();
        }
      } else {
        debugPrint('🎯 Tour not active or wrong screen');
      }
    } catch (e) {
      debugPrint('❌ Error checking tour: $e');
    }
  }

  /// Check if user has jobs created (Step -1)
  Future<void> _checkJobPrerequisite() async {
    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint('🎯 Checking if user has jobs...');

    if (_jobs.isEmpty) {
      // No jobs - show modal to guide user to create one
      debugPrint('🎯 No jobs found - showing job creation modal');
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.work_outline,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Let\'s Create Your First Job!',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Before we begin, you\'ll need to create at least one job.\n\nTap the Settings button (⋮) at the top, then go to Jobs & Data → Add Job.',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                debugPrint('🎯 User acknowledged job creation requirement');

                // Reload jobs to see if they created one
                await _loadJobs();

                // Re-check the prerequisite
                if (mounted) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  _checkJobPrerequisite();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Got It!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Has jobs - proceed to Step 0
      debugPrint('🎯 Jobs found - proceeding to Step 0');
      tourService.nextStep(); // Move from -1 to 0
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showDashboardTour();
      }
    }
  }

  void _showDashboardTour() {
    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 _showDashboardTour called, currentStep: ${tourService.currentStep}');

    // Guard: prevent multiple simultaneous tours
    if (_isTourShowing) {
      debugPrint('🎯 Tour already showing, skipping duplicate call');
      return;
    }

    // Don't call finish() - it triggers onFinish callback and causes recursion
    // Just set to null, the previous overlay will be garbage collected
    _tutorialCoachMark = null;

    // Handle prerequisite check (Step -1)
    if (tourService.currentStep == -1) {
      debugPrint('🎯 Running prerequisite check...');
      _checkJobPrerequisite();
      return;
    }

    List<TargetFocus> targets = [];

    debugPrint('🎯 Checking steps...');

    // Helper callbacks for skip functionality
    void onSkipToNext() {
      // Set up state for Add Shift transition
      tourService.setPulsingTarget('addShift');
      tourService.skipToScreen('addShift');
      // Show the same non-blocking modal as Step 9
      TourTransitionModal.showNonBlocking(
        context: context,
        title: 'Add Your First Shift!',
        message:
            'Now tap the + button at the top to add a shift and see how easy it is!',
        targetKey: _addShiftButtonKey,
      );
    }

    void onEndTour() {
      tourService.skipAll();
    }

    // Step 0: Add Shift Button (+ icon top-left)
    if (tourService.currentStep == 0) {
      debugPrint('🎯 Adding Add Shift FAB target');
      targets.add(TourTargets.createTarget(
        identify: 'addShiftButton',
        keyTarget: _addShiftButtonKey,
        title: 'Add Your Shifts',
        description:
            'This is the most important button! Tap this + icon anytime to add your shifts, tips, and income.',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 1: Recent Shifts Section
    if (tourService.currentStep == 1) {
      debugPrint('🎯 Adding Recent Shifts section target');
      targets.add(TourTargets.createTarget(
        identify: 'recentShifts',
        keyTarget: _recentShiftsKey,
        title: 'Recent Shifts',
        description:
            'Your most recent shifts appear here. Tap any shift to view or edit its details.',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 2: See All Button
    if (tourService.currentStep == 2) {
      debugPrint('🎯 Adding See All button target');
      targets.add(TourTargets.createTarget(
        identify: 'seeAllButton',
        keyTarget: _seeAllButtonKey,
        title: 'View All Shifts',
        description: 'View all your shifts in a searchable, filterable list.',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 3: Goals Button (flag icon)
    if (tourService.currentStep == 3) {
      debugPrint('🎯 Adding Goals button target');
      targets.add(TourTargets.createTarget(
        identify: 'goalsButton',
        keyTarget: _goalsButtonKey,
        title: 'Income Goals',
        description:
            'Set daily, weekly, monthly, or yearly income goals and track your progress in real-time.',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 4: Refresh Button
    if (tourService.currentStep == 4) {
      debugPrint('🎯 Adding Refresh button target');
      targets.add(TourTargets.createTarget(
        identify: 'refreshButton',
        keyTarget: _refreshButtonKey,
        title: 'Refresh Data',
        description:
            'If you think your data needs updating, tap here to refresh everything.',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 5: Settings Menu (3 dots)
    if (tourService.currentStep == 5) {
      debugPrint('🎯 Adding Settings menu target');
      targets.add(TourTargets.createTarget(
        identify: 'settingsButton',
        keyTarget: _settingsButtonKey,
        title: 'Settings Menu',
        description:
            '⚙️ Settings - App preferences\n\n💼 Jobs & Data - Manage jobs, calendar sync, imports\n\n📄 Docs & Contacts - All your attachments and contacts\n\n💰 Taxes - Estimate what you owe',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 6: Home Nav Button
    if (tourService.currentStep == 6) {
      debugPrint('🎯 Step 6 - Adding Home nav button target');
      debugPrint('🎯 widget.homeNavKey = ${widget.homeNavKey}');
      targets.add(TourTargets.createTarget(
        identify: 'homeNavButton',
        keyTarget: widget.homeNavKey,
        title: '🏠 Home',
        description: 'Dashboard overview - Your earnings at a glance',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.top,
      ));
    } else {
      debugPrint(
          '🎯 Step 6 skipped (currentStep = ${tourService.currentStep})');
    }

    // Step 7: Calendar Nav Button
    if (tourService.currentStep == 7) {
      debugPrint('🎯 Adding Calendar nav button target');
      targets.add(TourTargets.createTarget(
        identify: 'calendarNavButton',
        keyTarget: widget.calendarNavKey,
        title: '📅 Calendar',
        description:
            'View all your previously worked shifts or future scheduled shifts! Easily view or edit your income, hours worked and so much more!',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.top,
      ));
    }

    // Step 8: Chat Nav Button
    if (tourService.currentStep == 8) {
      debugPrint('🎯 Adding Chat nav button target');
      targets.add(TourTargets.createTarget(
        identify: 'chatNavButton',
        keyTarget: widget.chatNavKey,
        title: '✨ Chat',
        description:
            'AI assistant to help you with questions and tasks. The AI can quickly do anything a user can do and give deep analytics. Just ask and feel the power!',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.top,
      ));
    }

    // Step 9: Stats Nav Button
    if (tourService.currentStep == 9) {
      debugPrint('🎯 Adding Stats nav button target');
      targets.add(TourTargets.createTarget(
        identify: 'statsNavButton',
        keyTarget: widget.statsNavKey,
        title: '📊 Stats',
        description: 'Detailed earnings analytics and insights',
        currentScreen: 'dashboard',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.top,
      ));
    }

    debugPrint('🎯 Total targets: ${targets.length}');

    if (targets.isEmpty) {
      debugPrint('🎯 No targets to show');
      return;
    }

    _isTourShowing = true; // Set guard BEFORE creating tour

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.primaryGreen,
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: true, // Hide default top-right skip button (we have our own)
      onFinish: () {
        debugPrint('🎯 Tour step finished, moving to next');
        _isTourShowing = false; // Clear guard
        _tutorialCoachMark = null;

        // If we're skipping to another screen, don't do anything here
        // The skipToScreen already set up the next step
        if (tourService.isSkippingToScreen) {
          debugPrint('🎯 Skipping to another screen, ignoring onFinish');
          tourService.clearSkippingFlag();
          return;
        }

        // Special handling for step 9 - show transition modal and pulse + button
        if (tourService.currentStep == 9) {
          tourService.nextStep(); // Move to step 10
          tourService.setPulsingTarget('addShift'); // Make + button pulse
          TourTransitionModal.showNonBlocking(
            context: context,
            title: 'Add Your First Shift!',
            message:
                'Now tap the + button at the top to add a shift and see how easy it is!',
            targetKey: _addShiftButtonKey,
          );
        } else {
          // Advance to next step
          tourService.nextStep();

          // Show next tour step if still in dashboard range
          if (tourService.currentStep >= 0 && tourService.currentStep <= 9) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showDashboardTour();
              }
            });
          }
        }
      },
      onSkip: () {
        debugPrint('🎯 Tour skipped');
        _isTourShowing = false; // Clear guard

        // If we're skipping to another screen, don't end the tour
        if (tourService.isSkippingToScreen) {
          debugPrint('🎯 Skipping to another screen, ignoring onSkip');
          tourService.clearSkippingFlag();
          _tutorialCoachMark = null;
          return true;
        }

        tourService.skipAll();
        _tutorialCoachMark = null;
        return true;
      },
    );

    debugPrint('🎯 Showing tutorial...');
    _tutorialCoachMark?.show(context: context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload jobs whenever we return to this screen
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await _db.getJobs();
      print('📊 Dashboard: Loaded ${jobs.length} jobs');
      setState(() {
        _jobs = jobs;
      });
    } catch (e) {
      print('❌ Dashboard: Error loading jobs: $e');
    }
  }

  Future<void> _loadGoal() async {
    try {
      final goals = await _db.getGoals();
      if (goals.isNotEmpty) {
        // Get goal matching the selected period AND job
        final matchingGoals = goals.where((g) {
          final type = g['type'] as String;
          final jobId = g['job_id'] as String?;
          final periodMatches = (type == 'daily' && _selectedPeriod == 'day') ||
              (type == 'weekly' && _selectedPeriod == 'week') ||
              (type == 'monthly' && _selectedPeriod == 'month') ||
              (type == 'yearly' && _selectedPeriod == 'year');
          final jobMatches = _selectedJobId == null || jobId == _selectedJobId;
          return periodMatches && jobMatches;
        }).toList();

        if (matchingGoals.isNotEmpty) {
          setState(() {
            _activeGoal = Goal.fromSupabase(matchingGoals.first);
          });
        } else {
          setState(() {
            _activeGoal = null;
          });
        }
      }
    } catch (e) {
      // Ignore errors loading goals
    }
  }

  double _calculateGoalProgress(Goal goal, List<Shift> shifts) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (goal.type) {
      case 'weekly':
        final weekDay = now.weekday;
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekDay - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      default:
        startDate = goal.startDate ?? now;
        endDate = goal.endDate ?? now;
    }

    double total = 0.0;
    for (final shift in shifts) {
      if (shift.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          shift.date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += shift.totalIncome;
      }
    }

    return total;
  }

  Map<String, dynamic> _calculatePeriodStats(List<Shift> shifts) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;
    DateTime previousStartDate;
    DateTime previousEndDate;
    String label;

    switch (_selectedPeriod) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        previousStartDate = startDate.subtract(const Duration(days: 1));
        previousEndDate = startDate;
        label = 'TODAY';
        break;
      case 'week':
        final weekDay = now.weekday;
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekDay - 1));
        endDate = startDate.add(const Duration(days: 7));
        previousStartDate = startDate.subtract(const Duration(days: 7));
        previousEndDate = startDate;
        label = 'THIS WEEK';
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        previousStartDate = DateTime(now.year, now.month - 1, 1);
        previousEndDate = startDate;
        label = 'THIS MONTH';
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        previousStartDate = DateTime(now.year - 1, 1, 1);
        previousEndDate = startDate;
        label = 'THIS YEAR';
        break;
      case 'all':
        startDate = shifts.isNotEmpty
            ? shifts.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b)
            : now;
        endDate = now.add(const Duration(days: 1));
        previousStartDate = startDate;
        previousEndDate = startDate;
        label = 'ALL TIME';
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        previousStartDate = startDate;
        previousEndDate = startDate;
        label = 'TODAY';
    }

    double total = 0.0;
    double previousTotal = 0.0;
    List<Shift> periodShifts = [];

    for (final shift in shifts) {
      // Filter by selected job if one is selected
      final jobMatches =
          _selectedJobId == null || shift.jobId == _selectedJobId;
      if (!jobMatches) continue;

      if (shift.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          shift.date.isBefore(endDate)) {
        total += shift.totalIncome;
        periodShifts.add(shift);
      }
      if (shift.date
              .isAfter(previousStartDate.subtract(const Duration(days: 1))) &&
          shift.date.isBefore(previousEndDate)) {
        previousTotal += shift.totalIncome;
      }
    }

    double percentChange = 0.0;
    if (_selectedPeriod != 'all' && previousTotal > 0) {
      percentChange = ((total - previousTotal) / previousTotal * 100);
    }

    return {
      'total': total,
      'previousTotal': previousTotal,
      'percentChange': percentChange,
      'label': label,
      'shifts': periodShifts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency();

    // Calculate period stats
    final stats = _calculatePeriodStats(shiftProvider.shifts);
    final periodTotal = stats['total'] as double;
    final previousTotal = stats['previousTotal'] as double;
    final percentChange = stats['percentChange'] as double;
    final periodShifts = stats['shifts'] as List<Shift>;

    // Calculate tip breakdown
    final grossTips =
        periodShifts.fold<double>(0, (sum, s) => sum + s.totalTips);
    final totalTipout =
        periodShifts.fold<double>(0, (sum, s) => sum + s.calculatedTipout);
    final netTips = grossTips - totalTipout;

    // Calculate goal progress
    double goalProgress = 0;
    double goalPercent = 0;
    if (_activeGoal != null) {
      goalProgress = _calculateGoalProgress(_activeGoal!, shiftProvider.shifts);
      goalPercent = (goalProgress / _activeGoal!.targetAmount).clamp(0.0, 1.0);
    }

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = MediaQuery.of(context).size.width > 600;
                return SizedBox(
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      // Left side action buttons
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            Consumer<TourService>(
                              builder: (context, tourService, child) {
                                return PulsingButton(
                                  isPulsing:
                                      tourService.pulsingTarget == 'addShift',
                                  child: GestureDetector(
                                    key: _addShiftButtonKey,
                                    onTap: () {
                                      // Hide the non-blocking modal if showing
                                      TourTransitionModal.hide();
                                      // Clear pulsing when tapped
                                      if (tourService.pulsingTarget ==
                                          'addShift') {
                                        tourService.clearPulsingTarget();
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AddShiftScreen()),
                                      ).then((_) {
                                        // Reload data when returning from Add Shift
                                        setState(() {});
                                        // If returning during Calendar transition, show modal
                                        final ts = Provider.of<TourService>(
                                            context,
                                            listen: false);
                                        if (ts.isActive &&
                                            ts.currentStep == 12 &&
                                            ts.pulsingTarget == 'calendar') {
                                          // Wait for nav bar to fully render
                                          Future.delayed(
                                              const Duration(milliseconds: 300),
                                              () {
                                            if (mounted) {
                                              TourTransitionModal
                                                  .showNonBlocking(
                                                context: context,
                                                title: 'Explore the Calendar!',
                                                message:
                                                    'Now tap the Calendar button to see your shifts organized by date.',
                                                targetKey:
                                                    widget.calendarNavKey,
                                              );
                                            }
                                          });
                                        }
                                      });
                                    },
                                    child: Icon(Icons.add,
                                        color: AppTheme.navBarIconColor,
                                        size: 28),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              key: _goalsButtonKey,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const GoalsScreen()),
                                ).then((_) {
                                  // Reload goals when returning from Goals screen
                                  _loadGoal();
                                });
                              },
                              child: Icon(Icons.flag_outlined,
                                  color: AppTheme.navBarIconColor, size: 28),
                            ),
                          ],
                        ),
                      ),
                      // Center logo and title
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 10,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedLogo(isTablet: isTablet),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.textPrimary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppTheme.primaryGreen,
                                      AppTheme.accentBlue,
                                      AppTheme.primaryGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    'TIPS AND INCOME TRACKER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 14 : 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right side buttons (refresh and settings)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            GestureDetector(
                              key: _refreshButtonKey,
                              onTap: _isRefreshing
                                  ? null
                                  : () async {
                                      setState(() => _isRefreshing = true);

                                      // Refresh shift provider data
                                      final shiftProvider =
                                          Provider.of<ShiftProvider>(context,
                                              listen: false);
                                      await shiftProvider.loadShifts();

                                      // Reload local data
                                      await _loadJobs();
                                      await _loadGoal();

                                      setState(() => _isRefreshing = false);

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                const Text('Data refreshed'),
                                            backgroundColor:
                                                AppTheme.primaryGreen,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                              child: _isRefreshing
                                  ? SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryGreen),
                                      ),
                                    )
                                  : Icon(Icons.refresh,
                                      color: AppTheme.navBarIconColor,
                                      size: 28),
                            ),
                            const SizedBox(width: 12),
                            Consumer<TourService>(
                              builder: (context, tourService, child) {
                                final shouldPulse =
                                    tourService.pulsingTarget == 'menuButton';

                                Widget menuButton = GestureDetector(
                                  key: _settingsButtonKey,
                                  onTap: () {
                                    // If in tour mode and menu button is pulsing, go directly to Settings
                                    if (shouldPulse &&
                                        tourService.expectedScreen ==
                                            'settings') {
                                      tourService.clearPulsingTarget();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SettingsScreen(
                                              initialTab: 0),
                                        ),
                                      );
                                      return;
                                    }

                                    final RenderBox button =
                                        context.findRenderObject() as RenderBox;
                                    final RenderBox overlay =
                                        Navigator.of(context)
                                            .overlay!
                                            .context
                                            .findRenderObject() as RenderBox;
                                    final RelativeRect position =
                                        RelativeRect.fromRect(
                                      Rect.fromPoints(
                                        button.localToGlobal(
                                            Offset(button.size.width - 48, 40),
                                            ancestor: overlay),
                                        button.localToGlobal(
                                            button.size
                                                .bottomRight(Offset.zero),
                                            ancestor: overlay),
                                      ),
                                      Offset.zero & overlay.size,
                                    );
                                    showMenu<int>(
                                      context: context,
                                      position: position,
                                      color: AppTheme.cardBackground,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      items: [
                                        PopupMenuItem<int>(
                                          value: 0,
                                          child: Row(
                                            children: [
                                              Icon(Icons.settings,
                                                  color: AppTheme.textSecondary,
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Text('Settings',
                                                  style: AppTheme.bodyMedium
                                                      .copyWith(
                                                          color: AppTheme
                                                              .textPrimary)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<int>(
                                          value: 1,
                                          child: Row(
                                            children: [
                                              Icon(Icons.work,
                                                  color: AppTheme.textSecondary,
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Text('Jobs & Data',
                                                  style: AppTheme.bodyMedium
                                                      .copyWith(
                                                          color: AppTheme
                                                              .textPrimary)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<int>(
                                          value: 2,
                                          child: Row(
                                            children: [
                                              Icon(Icons.folder_outlined,
                                                  color: AppTheme.textSecondary,
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Text('Docs & Contacts',
                                                  style: AppTheme.bodyMedium
                                                      .copyWith(
                                                          color: AppTheme
                                                              .textPrimary)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<int>(
                                          value: 3,
                                          child: Row(
                                            children: [
                                              Icon(Icons.account_balance,
                                                  color: AppTheme.textSecondary,
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Text('Taxes',
                                                  style: AppTheme.bodyMedium
                                                      .copyWith(
                                                          color: AppTheme
                                                              .textPrimary)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ).then((value) {
                                      if (value != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SettingsScreen(
                                                initialTab: value),
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  child: Icon(Icons.more_vert,
                                      color: AppTheme.navBarIconColor,
                                      size: 28),
                                );

                                if (shouldPulse) {
                                  return PulsingButton(
                                    isPulsing: true,
                                    child: menuButton,
                                  );
                                }
                                return menuButton;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Hero Card - Period Earnings with Goal Progress
        SliverToBoxAdapter(
          child: ShimmerCard(
            enabled: themeProvider.shimmerEffects,
            child: HeroCard(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Selector TABS (styled differently from period chips)
                  if (_jobs.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Show first 3 jobs (All Jobs + 2 actual jobs)
                          _buildJobTab('All', null),
                          if (_jobs.isNotEmpty)
                            _buildJobTab(_jobs[0]['name'] as String,
                                _jobs[0]['id'] as String),
                          if (_jobs.length > 1)
                            _buildJobTab(_jobs[1]['name'] as String,
                                _jobs[1]['id'] as String),
                          // Dropdown menu for remaining jobs
                          if (_jobs.length > 2) ...[
                            PopupMenuButton<String?>(
                              icon: Icon(Icons.arrow_drop_down,
                                  color: AppTheme.textMuted, size: 20),
                              padding: EdgeInsets.zero,
                              color: AppTheme.cardBackground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (String? jobId) {
                                setState(() {
                                  _selectedJobId = jobId;
                                  _loadGoal();
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return _jobs.skip(2).map((job) {
                                  final jobId = job['id'] as String;
                                  final jobName = job['name'] as String;
                                  final isSelected = _selectedJobId == jobId;
                                  return PopupMenuItem<String?>(
                                    value: jobId,
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          Icon(Icons.check,
                                              color: AppTheme.primaryGreen,
                                              size: 16)
                                        else
                                          const SizedBox(width: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          jobName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.primaryGreen
                                                : AppTheme.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Period Selector Chips (smaller, distinct style)
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPeriodChip('Day', 'day'),
                          const SizedBox(width: 6),
                          _buildPeriodChip('Week', 'week'),
                          const SizedBox(width: 6),
                          _buildPeriodChip('Month', 'month'),
                          const SizedBox(width: 6),
                          _buildPeriodChip('Year', 'year'),
                          const SizedBox(width: 6),
                          _buildPeriodChip('All', 'all'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      currencyFormat.format(periodTotal),
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                  ),

                  // Tip breakdown (if applicable)
                  if (totalTipout > 0) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '💰 ${currencyFormat.format(netTips)} net (${currencyFormat.format(grossTips)} - ${currencyFormat.format(totalTipout)} tipout)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Goal progress bar with percentage and target inside
                  if (_activeGoal != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: LinearProgressIndicator(
                              value: goalPercent,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.transparent,
                              ),
                              minHeight: 32,
                            ),
                          ),
                        ),
                        // Full gradient overlay that fills based on progress
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: goalPercent.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppTheme.primaryGreen,
                                      AppTheme.accentBlue,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(goalPercent * 100).toInt()}% of goal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat
                                      .format(_activeGoal!.targetAmount),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (goalPercent >= 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.celebration,
                                color: AppTheme.primaryGreen, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Goal reached! +${currencyFormat.format(goalProgress - _activeGoal!.targetAmount)} over',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                shadows: AppTheme.textShadow,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 12),
                    if (_selectedPeriod != 'all' && previousTotal > 0)
                      Center(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: percentChange >= 0
                                  ? [
                                      AppTheme.primaryGreen
                                          .withValues(alpha: 0.25),
                                      AppTheme.primaryGreen
                                          .withValues(alpha: 0.15),
                                    ]
                                  : [
                                      AppTheme.accentRed
                                          .withValues(alpha: 0.25),
                                      AppTheme.accentRed
                                          .withValues(alpha: 0.15),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: percentChange >= 0
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                                  : AppTheme.accentRed.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                percentChange >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: percentChange >= 0
                                    ? AppTheme.primaryGreen
                                    : AppTheme.accentRed,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(0)}% from last ${_selectedPeriod == 'day' ? 'day' : _selectedPeriod == 'week' ? 'week' : _selectedPeriod == 'month' ? 'month' : 'year'}',
                                style: TextStyle(
                                  color: percentChange >= 0
                                      ? AppTheme.primaryGreen
                                      : AppTheme.accentRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Quick Stats Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Total Shifts',
                    '${periodShifts.length}',
                    Icons.work_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    'Hours',
                    periodShifts
                        .fold(0.0, (sum, s) => sum + s.hoursWorked)
                        .toStringAsFixed(0),
                    Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    'Avg/Shift',
                    currencyFormat.format(periodShifts.isNotEmpty
                        ? periodTotal / periodShifts.length
                        : 0),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Recent Shifts Header
        SliverToBoxAdapter(
          child: Padding(
            key: _recentShiftsKey,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Shifts',
                  style: AppTheme.titleMedium.copyWith(
                    color: themeProvider.adaptiveTextColor,
                  ),
                ),
                TextButton(
                  key: _seeAllButtonKey,
                  onPressed: () {
                    // Get the selected job title for the header
                    String? jobTitle;
                    if (_selectedJobId != null) {
                      final selectedJob = _jobs.firstWhere(
                        (job) => job['id'] == _selectedJobId,
                        orElse: () => {},
                      );
                      jobTitle = selectedJob['name'] as String?;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllShiftsScreen(
                          selectedJobId: _selectedJobId,
                          jobTitle: jobTitle,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent Shifts List
        if (shiftProvider.shifts.isEmpty)
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = MediaQuery.of(context).size.width > 600;
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical:
                        isTablet ? 180 : 16, // Tablet: 180px, Mobile: 16px
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.cardBackgroundLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No shifts yet',
                        style: AppTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first shift to get started',
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddShiftScreen()),
                          );
                          // Refresh data if shift was saved
                          if (result == true && mounted) {
                            final shiftProvider = Provider.of<ShiftProvider>(
                                context,
                                listen: false);
                            await shiftProvider.loadShifts();
                            await _loadJobs();
                            await _loadGoal();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add Shift',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Filter shifts by selected job, only include shifts that have started
                final filteredShifts = (_selectedJobId == null
                        ? shiftProvider.shifts
                        : shiftProvider.shifts
                            .where((shift) => shift.jobId == _selectedJobId)
                            .toList())
                    .where((shift) => _hasShiftStarted(shift))
                    .toList();

                final recentShifts = filteredShifts.take(5).toList();
                if (index >= recentShifts.length) return null;

                final shift = recentShifts[index];
                return _buildShiftCard(context, shift, currencyFormat);
              },
              childCount: () {
                // Filter shifts by selected job, only include shifts that have started
                final filteredShifts = (_selectedJobId == null
                        ? shiftProvider.shifts
                        : shiftProvider.shifts
                            .where((shift) => shift.jobId == _selectedJobId)
                            .toList())
                    .where((shift) => _hasShiftStarted(shift))
                    .toList();
                return filteredShifts.length > 5 ? 5 : filteredShifts.length;
              }(),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _loadGoal(); // Reload goal for the selected period
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildJobTab(String label, String? jobId) {
    final isSelected = _selectedJobId == jobId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedJobId = jobId;
            _loadGoal(); // Reload goal for the selected job
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return ShimmerCard(
      enabled: themeProvider.shimmerEffects,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard(
      BuildContext context, Shift shift, NumberFormat currencyFormat) {
    // Get the job name from the jobs list
    String jobName = 'Shift';
    String? employer;
    if (shift.jobId != null && _jobs.isNotEmpty) {
      final job = _jobs.firstWhere(
        (j) => j['id'] == shift.jobId,
        orElse: () => {},
      );
      if (job.isNotEmpty && job['name'] != null) {
        jobName = job['name'] as String;
        employer = job['employer'] as String?;
      }
    } else if (shift.jobType != null && shift.jobType!.isNotEmpty) {
      jobName = shift.jobType!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SingleShiftDetailScreen(shift: shift),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Badge with Month Abbreviation
                Container(
                  width: 56,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.primaryGreen,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(shift.date),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('d').format(shift.date),
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        shift.date.year == DateTime.now().year
                            ? DateFormat('MMM').format(shift.date)
                            : DateFormat("MMM ''yy").format(shift.date),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Shift Info - Left and Right Columns with Dynamic Row Stacking
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Job Title + Dollar Amount (always first)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              jobName,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            shift.totalIncome == 0
                                ? '\$0'
                                : currencyFormat.format(shift.totalIncome),
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      // Dynamic rows below
                      ...() {
                        final List<Widget> leftItems = [];
                        // Event badge
                        if (shift.eventName?.isNotEmpty == true) {
                          leftItems.add(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPurple
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.accentPurple
                                        .withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 10,
                                      color: AppTheme.accentPurple,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        shift.eventName!,
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.accentPurple,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Add guest count if available
                                    if (shift.guestCount != null &&
                                        shift.guestCount! > 0) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.people,
                                        size: 10,
                                        color: AppTheme.accentPurple,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${shift.guestCount}',
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.accentPurple,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        // Employer badge (moved here)
                        if (employer?.isNotEmpty == true) {
                          leftItems.add(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.accentBlue
                                        .withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 10,
                                      color: AppTheme.accentBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        employer!,
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.accentBlue,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Hours display (for Event badge row)
                        final hoursWidget = Text(
                          '${shift.hoursWorked.toStringAsFixed(1)} hrs',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        );

                        // Smart detail display - Priority: Time Range > Guest Count > Location
                        // (for Employer badge row)
                        Widget? detailWidget;
                        if (shift.startTime?.isNotEmpty == true &&
                            shift.endTime?.isNotEmpty == true) {
                          // Format times to ensure 12-hour format
                          String formatTime(String time) {
                            // If already has AM/PM, return as is
                            if (time.toUpperCase().contains('AM') ||
                                time.toUpperCase().contains('PM')) {
                              return time;
                            }
                            // Otherwise parse and format to 12-hour
                            try {
                              final parts = time.split(':');
                              if (parts.length >= 2) {
                                int hour = int.parse(parts[0]);
                                final minute = parts[1];
                                final period = hour >= 12 ? 'PM' : 'AM';
                                if (hour > 12) hour -= 12;
                                if (hour == 0) hour = 12;
                                return '$hour:$minute $period';
                              }
                            } catch (e) {
                              // If parsing fails, return original
                              return time;
                            }
                            return time;
                          }

                          // Show time range
                          detailWidget = Text(
                            '${formatTime(shift.startTime!)} - ${formatTime(shift.endTime!)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        } else if (shift.guestCount != null &&
                            shift.guestCount! > 0) {
                          // Show guest count
                          detailWidget = Text(
                            '${shift.guestCount} guests',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        } else if (shift.location?.isNotEmpty == true) {
                          // Show location
                          detailWidget = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 10,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  shift.location!,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }

                        // Build rows for Event badge and Employer badge
                        final rows = <Widget>[];

                        // Add rows for left items with appropriate details on the right
                        for (int i = 0; i < leftItems.length; i++) {
                          Widget? rightWidget;
                          if (i == 0) {
                            // First row (Event badge) - show hours
                            rightWidget = hoursWidget;
                          } else if (i == 1 && detailWidget != null) {
                            // Second row (Employer badge) - show smart detail
                            rightWidget = detailWidget;
                          }

                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: leftItems[i]),
                                  const SizedBox(width: 12),
                                  if (rightWidget != null) rightWidget,
                                ],
                              ),
                            ),
                          );
                        }

                        // Add notes row if present (full width, wrapping allowed)
                        if (shift.notes?.isNotEmpty == true) {
                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                shift.notes!,
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          );
                        }

                        return rows;
                      }(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
