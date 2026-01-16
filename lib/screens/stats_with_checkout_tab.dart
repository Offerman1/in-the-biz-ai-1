import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/checkout_analytics_tab.dart';
import '../widgets/paychecks_tab.dart';
import '../widgets/tour_transition_modal.dart';
import '../providers/shift_provider.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import '../services/tour_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../utils/tour_targets.dart';
import 'stats_screen.dart';

/// Wrapper for Stats Screen that adds Checkout Analytics and Paychecks as tabs
class StatsWithCheckoutTab extends StatefulWidget {
  final bool isVisible;

  const StatsWithCheckoutTab({super.key, this.isVisible = false});

  @override
  State<StatsWithCheckoutTab> createState() => _StatsWithCheckoutTabState();
}

class _StatsWithCheckoutTabState extends State<StatsWithCheckoutTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tour state
  bool _isTourShowing = false;
  TutorialCoachMark? _tutorialCoachMark;

  // GlobalKeys for tour targets
  final GlobalKey _exportButtonKey = GlobalKey();
  final GlobalKey _overviewTabKey = GlobalKey();
  final GlobalKey _checkoutsTabKey = GlobalKey();
  final GlobalKey _paychecksTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check if tour should start (only if visible from start)
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartTour();
      });
    }
  }

  @override
  void didUpdateWidget(StatsWithCheckoutTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When this screen becomes visible, check if tour should start
    if (widget.isVisible && !oldWidget.isVisible) {
      debugPrint('🎯 Stats: Became visible, checking tour');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkAndStartTour();
        }
      });
    }
  }

  Future<void> _checkAndStartTour() async {
    if (!mounted) return;

    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 Stats Tour Check: isActive=${tourService.isActive}, currentStep=${tourService.currentStep}, expectedScreen=${tourService.expectedScreen}');

    if (tourService.isActive &&
        tourService.expectedScreen == 'stats' &&
        tourService.currentStep >= 24 &&
        tourService.currentStep <= 27 &&
        !_isTourShowing) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showStatsTour();
      }
    }
  }

  void _showStatsTour() {
    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 _showStatsTour called, currentStep: ${tourService.currentStep}');

    if (_isTourShowing) {
      debugPrint('🎯 Stats tour already showing, ignoring');
      return;
    }

    if (tourService.currentStep < 24 || tourService.currentStep > 27) {
      debugPrint('🎯 Not on a stats step, ignoring');
      return;
    }

    _tutorialCoachMark = null;

    List<TargetFocus> targets = [];

    void onSkipToNext() {
      // Set Home to pulse so user knows to go there first
      tourService.setPulsingTarget('home');
      tourService.skipToScreen('settings');
      // Show non-blocking floating hint
      TourTransitionModal.showSettingsPrompt(context, () {});
    }

    void onEndTour() {
      tourService.skipAll();
    }

    // Step 24: Export button
    if (tourService.currentStep == 24) {
      targets.add(TourTargets.createTarget(
        identify: 'exportButton',
        keyTarget: _exportButtonKey,
        title: '📤 Export Your Data',
        description:
            'Export your stats and shifts as a CSV spreadsheet or a beautiful printable PDF report.',
        currentScreen: 'stats',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 25: Overview tab
    if (tourService.currentStep == 25) {
      targets.add(TourTargets.createTarget(
        identify: 'overviewTab',
        keyTarget: _overviewTabKey,
        title: '📊 Overview',
        description:
            'See all your earnings statistics at a glance - totals, averages, trends, and breakdowns by job.',
        currentScreen: 'stats',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 26: Checkouts tab
    if (tourService.currentStep == 26) {
      targets.add(TourTargets.createTarget(
        identify: 'checkoutsTab',
        keyTarget: _checkoutsTabKey,
        title: '🧾 Server Checkouts',
        description:
            'View all your scanned server checkouts in one place. Every checkout you\'ve photographed is saved here.',
        currentScreen: 'stats',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 27: Paychecks tab
    if (tourService.currentStep == 27) {
      targets.add(TourTargets.createTarget(
        identify: 'paychecksTab',
        keyTarget: _paychecksTabKey,
        title: '💵 Paychecks',
        description:
            'All your scanned paychecks are stored here. Great for tracking hourly pay and verifying your earnings.',
        currentScreen: 'stats',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    if (targets.isEmpty) return;

    _isTourShowing = true;

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.primaryGreen,
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: true,
      onFinish: () {
        debugPrint('🎯 Stats: Tour step finished');
        _isTourShowing = false;
        _tutorialCoachMark = null;

        if (tourService.isSkippingToScreen) {
          tourService.clearSkippingFlag();
          return;
        }

        tourService.nextStep();

        // Show next step if still in stats range
        if (tourService.currentStep >= 24 && tourService.currentStep <= 27) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showStatsTour();
            }
          });
        }
        // After step 27, guide user to Settings via Home → Menu → Settings
        else if (tourService.currentStep == 28) {
          // Set Home nav button to pulse
          tourService.setPulsingTarget('home');
          // Show non-blocking floating hint
          TourTransitionModal.showSettingsPrompt(context, () {});
        }
      },
      onSkip: () {
        _isTourShowing = false;
        if (tourService.isSkippingToScreen) {
          tourService.clearSkippingFlag();
          _tutorialCoachMark = null;
          return true;
        }
        tourService.skipAll();
        _tutorialCoachMark = null;
        return true;
      },
    );

    _tutorialCoachMark!.show(context: context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleExport(BuildContext context, String type) async {
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final shifts = shiftProvider.shifts;

    // Load jobs to get job names for export
    final db = DatabaseService();
    final jobs = await db.getJobs();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      String? filePath;

      if (type == 'csv') {
        filePath = await ExportService.exportToCSV(
          shifts: shifts,
          startDate: startOfMonth,
          endDate: endOfMonth,
          jobs: jobs,
        );
      } else if (type == 'pdf') {
        filePath = await ExportService.exportToPDF(
          shifts: shifts,
          startDate: startOfMonth,
          endDate: endOfMonth,
          title: 'Income Report - ${DateFormat('MMMM yyyy').format(now)}',
          jobs: jobs,
        );
      }

      if (filePath != null && context.mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'In The Biz AI - ${type.toUpperCase()} Report',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        toolbarHeight: 48, // Space for export button
        title: const SizedBox.shrink(), // No title
        actions: [
          PopupMenuButton<String>(
            key: _exportButtonKey,
            icon: Icon(Icons.ios_share, color: AppTheme.primaryGreen),
            color: AppTheme.cardBackground,
            onSelected: (value) => _handleExport(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart,
                        size: 20, color: AppTheme.adaptiveTextColor),
                    const SizedBox(width: 12),
                    Text('Export CSV',
                        style: TextStyle(color: AppTheme.adaptiveTextColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf,
                        size: 20, color: AppTheme.adaptiveTextColor),
                    const SizedBox(width: 12),
                    Text('Export PDF',
                        style: TextStyle(color: AppTheme.adaptiveTextColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              tabs: [
                Tab(key: _overviewTabKey, text: 'Overview'),
                Tab(key: _checkoutsTabKey, text: 'Checkouts'),
                Tab(key: _paychecksTabKey, text: 'Paychecks'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Original Stats Screen content (without AppBar)
          StatsScreen(),

          // Checkout Analytics Tab
          CheckoutAnalyticsTab(),

          // Paychecks Tab
          PaychecksTab(),
        ],
      ),
    );
  }
}
