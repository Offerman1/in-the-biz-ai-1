import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift.dart';
import '../models/job.dart';
import '../models/beo_event.dart';
import '../models/money_display_mode.dart';
import '../providers/shift_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/beo_event_provider.dart';
import '../services/database_service.dart';
import '../services/calendar_sync_service.dart';
import '../screens/add_shift_screen.dart';
import '../screens/shift_detail_screen.dart';
import '../screens/single_shift_detail_screen.dart';
import '../screens/beo_detail_screen.dart';
import '../widgets/job_filter_bottom_sheet.dart';
import '../widgets/money_mode_bottom_sheet.dart';
import '../theme/app_theme.dart';

enum CalendarViewMode { month, week, year }

class BetterCalendarScreen extends StatefulWidget {
  const BetterCalendarScreen({super.key});

  @override
  State<BetterCalendarScreen> createState() => _BetterCalendarScreenState();
}

class _BetterCalendarScreenState extends State<BetterCalendarScreen>
    with WidgetsBindingObserver {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isDrawerExpanded = false;
  bool _isMonthListView = false; // Toggle for month grid vs list

  // Scroll controller for month list view
  final ScrollController _monthListScrollController = ScrollController();

  // Pinch-to-zoom state for calendar
  // We use a simple approach: track scale and a single translation offset
  double _calendarScale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero; // Current translation offset
  Offset _baseOffset = Offset.zero; // Offset at gesture start
  Offset _startFocalPoint = Offset.zero; // Focal point when gesture started
  bool _isZooming = false; // Track if this is a zoom gesture (2+ fingers)

  // Filter state
  String? _selectedJobId; // null = All Jobs
  String _moneyDisplayMode = MoneyDisplayMode.takeHomePay.name; // Default

  // Jobs cache for displaying job names
  Map<String, Job> _jobs = {};

  // Loading state for sync button
  bool _isSyncing = false;

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  /// Reset zoom to default (1x) and focal point to center
  void _resetZoom() {
    setState(() {
      _calendarScale = 1.0;
      _baseScale = 1.0;
      _offset = Offset.zero;
      _baseOffset = Offset.zero;
      _startFocalPoint = Offset.zero;
      _isZooming = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monthListScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _loadJobs();
    _loadBeoEvents(); // Load BEO events
    _autoSyncCalendar(); // Auto-sync future shifts when screen opens
  }

  /// Load BEO events from provider
  Future<void> _loadBeoEvents() async {
    final beoProvider = Provider.of<BeoEventProvider>(context, listen: false);
    await beoProvider.loadBeoEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset to today when returning to the calendar screen
    // BUT only if we're still in the current month/week/year
    final now = DateTime.now();

    // If viewing the current month, reset to today
    if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
      _focusedDay = now;
    }
    // If viewing the current year but different month, keep the current month
    // (user intentionally navigated to a different month)
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh shifts when app comes back to foreground
      // This catches changes made by AI assistant
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      shiftProvider.forceReload();
    }
  }

  // Auto-sync calendar for future shifts only
  Future<void> _autoSyncCalendar() async {
    try {
      final calendarSyncService = CalendarSyncService();

      // Check if enough time has passed since last sync (prevents excessive syncing)
      final shouldSync = await calendarSyncService.shouldSync();
      if (!shouldSync) return;

      // Run auto-sync in background
      final newShiftsCount = await calendarSyncService.autoSyncFutureShifts();

      // If new shifts were found, reload the UI
      if (newShiftsCount > 0 && mounted) {
        final shiftProvider =
            Provider.of<ShiftProvider>(context, listen: false);
        await shiftProvider.loadShifts();

        // Optional: Show subtle notification (uncomment if desired)
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('✨ $newShiftsCount new shift${newShiftsCount > 1 ? 's' : ''} synced'),
        //     duration: const Duration(seconds: 2),
        //     backgroundColor: AppTheme.primaryGreen,
        //   ),
        // );
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience
      print('Auto-sync failed: $e');
    }
  }

  // Load jobs data
  Future<void> _loadJobs() async {
    final dbService = DatabaseService();
    final jobsData = await dbService.getJobs();
    final jobs = jobsData.map((data) => Job.fromSupabase(data)).toList();
    setState(() {
      _jobs = {for (var job in jobs) job.id: job};
    });
  }

  // Load saved filter preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedJobId = prefs.getString('calendar_selected_job_id');
      _moneyDisplayMode = prefs.getString('calendar_money_mode') ??
          MoneyDisplayMode.takeHomePay.name;
    });
  }

  // Save filter preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedJobId != null) {
      await prefs.setString('calendar_selected_job_id', _selectedJobId!);
    } else {
      await prefs.remove('calendar_selected_job_id');
    }
    await prefs.setString('calendar_money_mode', _moneyDisplayMode);
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final beoProvider = Provider.of<BeoEventProvider>(context);
    final allShifts = shiftProvider.shifts;
    final allBeoEvents = beoProvider.beoEvents;

    // Apply job filter (BEOs are not filtered by job)
    final filteredShifts = _selectedJobId == null
        ? allShifts
        : allShifts.where((shift) => shift.jobId == _selectedJobId).toList();

    // Get standalone BEOs (not linked to a shift) for calendar display
    final standaloneBeoEvents =
        allBeoEvents.where((e) => e.isStandalone).toList();

    // Group shifts by date
    final shiftsByDate = <DateTime, List<Shift>>{};
    for (final shift in filteredShifts) {
      final date = DateTime(shift.date.year, shift.date.month, shift.date.day);
      shiftsByDate.putIfAbsent(date, () => []).add(shift);
    }

    // Group standalone BEOs by date (for calendar display)
    final beosByDate = <DateTime, List<BeoEvent>>{};
    for (final beo in standaloneBeoEvents) {
      final date =
          DateTime(beo.eventDate.year, beo.eventDate.month, beo.eventDate.day);
      beosByDate.putIfAbsent(date, () => []).add(beo);
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildViewToggle(),
                Expanded(
                  child: _buildContent(shiftsByDate, filteredShifts,
                      beosByDate: beosByDate),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    String title;
    switch (_viewMode) {
      case CalendarViewMode.month:
        title = DateFormat('MMM yyyy').format(_focusedDay);
        break;
      case CalendarViewMode.week:
        final weekStart =
            _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        title =
            '${DateFormat('M/d').format(weekStart)} - ${DateFormat('M/d').format(weekEnd)}';
        break;
      case CalendarViewMode.year:
        title = DateFormat('yyyy').format(_focusedDay);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // View toggle on the left (only for month view)
          if (_viewMode == CalendarViewMode.month)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(
                  _isMonthListView
                      ? Icons.calendar_view_month
                      : Icons.view_list,
                  color: AppTheme.headerIconColor,
                ),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _isMonthListView = !_isMonthListView;
                    _isDrawerExpanded = false;
                  });
                },
              ),
            ),

          // Job filter icon (left side, 2nd position for month, 1st for week/year)
          Positioned(
            left: _viewMode == CalendarViewMode.month ? 36 : 0,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: Icon(
                Icons.work_outline,
                color: AppTheme.headerIconColor,
              ),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final dbService = DatabaseService();
                final jobsData = await dbService.getJobs();
                final jobs =
                    jobsData.map((data) => Job.fromSupabase(data)).toList();
                if (!mounted) return;
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => JobFilterBottomSheet(
                    jobs: jobs,
                    selectedJobId: _selectedJobId,
                    onJobSelected: (jobId) {
                      setState(() {
                        _selectedJobId = jobId;
                      });
                      _savePreferences();
                    },
                  ),
                );
              },
            ),
          ),

          // Centered title and arrows
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left arrow - navigate to previous period
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_viewMode == CalendarViewMode.week) {
                        _focusedDay =
                            _focusedDay.subtract(const Duration(days: 7));
                      } else if (_viewMode == CalendarViewMode.month) {
                        _focusedDay =
                            DateTime(_focusedDay.year, _focusedDay.month - 1);
                      } else if (_viewMode == CalendarViewMode.year) {
                        _focusedDay = DateTime(_focusedDay.year - 1);
                      }
                    });
                  },
                  child: Icon(Icons.chevron_left,
                      color: AppTheme.headerIconColor, size: 28),
                ),
                // Title - on mobile: refresh calendar, on tablet: navigate back
                GestureDetector(
                  onTap: () async {
                    if (isMobile) {
                      // On mobile: trigger calendar sync/refresh
                      if (_isSyncing) return;

                      setState(() => _isSyncing = true);

                      final calendarSyncService = CalendarSyncService();
                      try {
                        final newShiftsCount =
                            await calendarSyncService.autoSyncFutureShifts();

                        if (mounted) {
                          final shiftProvider = Provider.of<ShiftProvider>(
                              context,
                              listen: false);
                          await shiftProvider.loadShifts();

                          setState(() => _isSyncing = false);

                          if (newShiftsCount > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('✅ Synced $newShiftsCount new shifts'),
                                backgroundColor: AppTheme.primaryGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('✅ Calendar is up to date'),
                                backgroundColor: AppTheme.primaryGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isSyncing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sync failed: $e'),
                              backgroundColor: AppTheme.accentRed,
                            ),
                          );
                        }
                      }
                    } else {
                      // On tablet: navigate to previous period (same as left arrow)
                      setState(() {
                        if (_viewMode == CalendarViewMode.week) {
                          _focusedDay =
                              _focusedDay.subtract(const Duration(days: 7));
                        } else if (_viewMode == CalendarViewMode.month) {
                          _focusedDay =
                              DateTime(_focusedDay.year, _focusedDay.month - 1);
                        } else if (_viewMode == CalendarViewMode.year) {
                          _focusedDay = DateTime(_focusedDay.year - 1);
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      title,
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                // Right arrow - navigate to next period
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_viewMode == CalendarViewMode.week) {
                        _focusedDay = _focusedDay.add(const Duration(days: 7));
                      } else if (_viewMode == CalendarViewMode.month) {
                        _focusedDay =
                            DateTime(_focusedDay.year, _focusedDay.month + 1);
                      } else if (_viewMode == CalendarViewMode.year) {
                        _focusedDay = DateTime(_focusedDay.year + 1);
                      }
                    });
                  },
                  child: Icon(Icons.chevron_right,
                      color: AppTheme.headerIconColor, size: 28),
                ),
              ],
            ),
          ),

          // Money mode icon (position changes based on screen size)
          // Mobile: 2nd from right (no sync button), Tablet: 3rd from right
          Positioned(
            right: isMobile ? 36 : 72,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: Icon(
                Icons.attach_money,
                color: AppTheme.headerIconColor,
              ),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => MoneyModeBottomSheet(
                    currentMode: _moneyDisplayMode,
                    onModeSelected: (mode) {
                      setState(() {
                        _moneyDisplayMode = mode;
                      });
                      _savePreferences();
                    },
                  ),
                );
              },
            ),
          ),

          // Calendar sync button (2nd from right) - only visible on tablet
          if (!isMobile)
            Positioned(
              right: 36,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: _isSyncing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryGreen),
                        ),
                      )
                    : Icon(Icons.sync, color: AppTheme.headerIconColor),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _isSyncing
                    ? null
                    : () async {
                        // Prevent multiple clicks
                        if (_isSyncing) return;

                        setState(() => _isSyncing = true);

                        final calendarSyncService = CalendarSyncService();
                        try {
                          final newShiftsCount =
                              await calendarSyncService.autoSyncFutureShifts();

                          if (mounted) {
                            final shiftProvider = Provider.of<ShiftProvider>(
                                context,
                                listen: false);
                            await shiftProvider.loadShifts();

                            setState(() => _isSyncing = false);

                            if (newShiftsCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ Synced $newShiftsCount new shifts'),
                                  backgroundColor: AppTheme.primaryGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('✅ Calendar is up to date'),
                                  backgroundColor: AppTheme.primaryGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isSyncing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sync failed: $e'),
                                backgroundColor: AppTheme.accentRed,
                              ),
                            );
                          }
                        }
                      },
              ),
            ),

          // Today button (rightmost)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: Icon(Icons.today, color: AppTheme.headerIconColor),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          _buildToggleButton('Month', CalendarViewMode.month),
          _buildToggleButton('Week', CalendarViewMode.week),
          _buildToggleButton('Year', CalendarViewMode.year),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, CalendarViewMode mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _resetZoom(); // Reset zoom when changing view mode
          setState(() {
            _viewMode = mode;
            _isDrawerExpanded = false;

            // Reset to today when switching views IF we're in the current month
            final now = DateTime.now();
            if (_focusedDay.year == now.year &&
                _focusedDay.month == now.month) {
              _focusedDay = now;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      Map<DateTime, List<Shift>> shiftsByDate, List<Shift> allShifts,
      {Map<DateTime, List<BeoEvent>>? beosByDate}) {
    switch (_viewMode) {
      case CalendarViewMode.month:
        return _buildMonthView(shiftsByDate, beosByDate: beosByDate ?? {});
      case CalendarViewMode.week:
        return _buildWeekView(shiftsByDate, allShifts);
      case CalendarViewMode.year:
        return _buildYearView(allShifts);
    }
  }

  // MONTH VIEW
  Widget _buildMonthView(Map<DateTime, List<Shift>> shiftsByDate,
      {Map<DateTime, List<BeoEvent>> beosByDate = const {}}) {
    // If list view is enabled, show list instead of calendar
    if (_isMonthListView) {
      return _buildMonthListView(shiftsByDate);
    }

    // Calculate dynamic drawer height based on content
    final selectedDayNormalized = _selectedDay != null
        ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
        : null;
    final selectedDayShifts = selectedDayNormalized != null
        ? (shiftsByDate[selectedDayNormalized] ?? [])
        : [];
    final selectedDayBeos = selectedDayNormalized != null
        ? (beosByDate[selectedDayNormalized] ?? [])
        : [];

    // Height calculation: compact summary bar (60) + each shift card (110) + each BEO card (90) + padding (80)
    final contentHeight = 60 +
        (selectedDayShifts.length * 110) +
        (selectedDayBeos.length * 90) +
        80;
    final maxDrawerHeight =
        MediaQuery.of(context).size.height * 0.7; // Max 70% of screen
    final calculatedHeight = contentHeight.toDouble();
    final drawerHeight = _isDrawerExpanded
        ? (calculatedHeight > maxDrawerHeight
            ? maxDrawerHeight
            : calculatedHeight)
        : 0.0;

    // Calculate month stats
    final monthShifts = shiftsByDate.entries
        .where((e) =>
            e.key.month == _focusedDay.month && e.key.year == _focusedDay.year)
        .expand((e) => e.value)
        .toList();
    final monthIncome =
        monthShifts.fold<double>(0, (sum, shift) => sum + shift.totalIncome);
    final monthHours =
        monthShifts.fold<double>(0, (sum, shift) => sum + shift.hoursWorked);

    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.15),
                AppTheme.accentBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeekStat('Income', currencyFormat.format(monthIncome)),
              _buildWeekStat('Hours', monthHours.toStringAsFixed(1)),
              _buildWeekStat('Shifts', '${monthShifts.length}'),
            ],
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              // Calendar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: drawerHeight + 10,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate number of weeks in current month
                    final firstDayOfMonth =
                        DateTime(_focusedDay.year, _focusedDay.month, 1);
                    final lastDayOfMonth =
                        DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
                    final firstWeekday =
                        firstDayOfMonth.weekday % 7; // Sunday = 0
                    final totalDays = lastDayOfMonth.day;
                    final numberOfWeeks =
                        ((firstWeekday + totalDays) / 7).ceil();

                    // Calculate dynamic row height based on available space
                    // Reserve space for days-of-week header (40px)
                    final availableHeight = constraints.maxHeight - 40;

                    // Calculate row height to fill space naturally (no clamps)
                    final dynamicRowHeight = availableHeight / numberOfWeeks;

                    // Pinch-to-zoom: TableCalendar gestures disabled, we handle everything
                    // 1 finger horizontal swipe = change month
                    // 2 fingers pinch = zoom to focal point
                    return GestureDetector(
                      onScaleStart: (details) {
                        _baseScale = _calendarScale;
                        _baseOffset = _offset;
                        _startFocalPoint = details.localFocalPoint;
                        _isZooming = details.pointerCount >= 2;
                      },
                      onScaleUpdate: (details) {
                        // Track if we have 2+ fingers at any point
                        if (details.pointerCount >= 2) {
                          _isZooming = true;
                        }

                        if (_isZooming && details.pointerCount >= 2) {
                          setState(() {
                            // Calculate new scale
                            final newScale =
                                (_baseScale * details.scale).clamp(1.0, 2.5);

                            // Calculate offset to zoom around focal point
                            // Formula: new_offset = focal - (focal - old_offset) * (new_scale / old_scale)
                            // This keeps the point under fingers stationary during zoom
                            final focalPoint = details.localFocalPoint;

                            // How much the focal point moved (for panning)
                            final focalDelta = focalPoint - _startFocalPoint;

                            // Scale change ratio
                            final scaleChange = newScale / _baseScale;

                            // New offset: start from base, apply scale change around start focal, then add pan
                            _offset = _startFocalPoint -
                                (_startFocalPoint - _baseOffset) * scaleChange +
                                focalDelta;

                            _calendarScale = newScale;
                          });
                        }
                      },
                      onScaleEnd: (details) {
                        // Only handle swipe if it was NOT a zoom gesture and not zoomed in
                        if (!_isZooming && _calendarScale == 1.0) {
                          // This was a 1-finger gesture, check for swipe
                          // Use velocity if available, otherwise use distance
                          if (details.velocity.pixelsPerSecond.dx.abs() > 100) {
                            if (details.velocity.pixelsPerSecond.dx < -100) {
                              // Swipe left = next month
                              setState(() {
                                _focusedDay = DateTime(
                                  _focusedDay.year,
                                  _focusedDay.month + 1,
                                  1,
                                );
                              });
                            } else if (details.velocity.pixelsPerSecond.dx >
                                100) {
                              // Swipe right = previous month
                              setState(() {
                                _focusedDay = DateTime(
                                  _focusedDay.year,
                                  _focusedDay.month - 1,
                                  1,
                                );
                              });
                            }
                          }
                        }
                        _baseScale = _calendarScale;
                        _baseOffset = _offset;
                        _isZooming = false;
                      },
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(_offset.dx, _offset.dy)
                          ..scale(_calendarScale),
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          color: AppTheme.darkBackground,
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxHeight: double.infinity,
                            child: ClipRect(
                              child: TableCalendar(
                                // Disable swipe gestures to allow pinch-zoom
                                // Month navigation is handled by header arrows
                                availableGestures: AvailableGestures.none,
                                firstDay: DateTime(2020),
                                lastDay: DateTime(2030),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                calendarFormat: CalendarFormat.month,
                                startingDayOfWeek: StartingDayOfWeek.sunday,
                                headerVisible: false,
                                sixWeekMonthsEnforced:
                                    false, // Only show needed rows
                                rowHeight: dynamicRowHeight,
                                daysOfWeekHeight: 40,
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: AppTheme.labelLarge,
                                  weekendStyle: AppTheme.labelLarge,
                                ),
                                calendarStyle: CalendarStyle(
                                  cellMargin: const EdgeInsets.all(2),
                                  cellPadding: EdgeInsets.zero,
                                  defaultDecoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppTheme.primaryGreen, width: 2),
                                  ),
                                  outsideDecoration: BoxDecoration(
                                    color: AppTheme.darkBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder: (context, day, focusedDay) {
                                    return _buildDayCell(
                                        day,
                                        shiftsByDate,
                                        false,
                                        false,
                                        dynamicRowHeight,
                                        _isDrawerExpanded,
                                        beosByDate: beosByDate);
                                  },
                                  selectedBuilder: (context, day, focusedDay) {
                                    return _buildDayCell(
                                        day,
                                        shiftsByDate,
                                        true,
                                        false,
                                        dynamicRowHeight,
                                        _isDrawerExpanded,
                                        beosByDate: beosByDate);
                                  },
                                  todayBuilder: (context, day, focusedDay) {
                                    return _buildDayCell(
                                        day,
                                        shiftsByDate,
                                        false,
                                        true,
                                        dynamicRowHeight,
                                        _isDrawerExpanded,
                                        beosByDate: beosByDate);
                                  },
                                  outsideBuilder: (context, day, focusedDay) {
                                    return _buildDayCell(
                                        day,
                                        shiftsByDate,
                                        false,
                                        false,
                                        dynamicRowHeight,
                                        _isDrawerExpanded,
                                        beosByDate: beosByDate);
                                  },
                                  disabledBuilder: (context, day, focusedDay) {
                                    return _buildDayCell(
                                        day,
                                        shiftsByDate,
                                        false,
                                        false,
                                        dynamicRowHeight,
                                        _isDrawerExpanded,
                                        beosByDate: beosByDate);
                                  },
                                ),
                                onDaySelected: (selectedDay, focusedDay) {
                                  final normalizedDay = DateTime(
                                      selectedDay.year,
                                      selectedDay.month,
                                      selectedDay.day);
                                  final hasShifts =
                                      shiftsByDate.containsKey(normalizedDay);
                                  final hasBeos =
                                      beosByDate.containsKey(normalizedDay);

                                  if (!hasShifts && !hasBeos) {
                                    // Empty day - go directly to add shift with selected date
                                    _resetZoom(); // Reset zoom when navigating
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AddShiftScreen(
                                                preselectedDate: selectedDay,
                                              )),
                                    );
                                  } else {
                                    // Has shifts - expand drawer
                                    _resetZoom(); // Reset zoom when opening drawer
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                      _isDrawerExpanded = true;
                                    });
                                  }
                                },
                                onPageChanged: (focusedDay) {
                                  _resetZoom(); // Reset zoom when changing month
                                  setState(() {
                                    _focusedDay = focusedDay;
                                  });
                                },
                              ), // Closing for TableCalendar
                            ), // Closing for ClipRect
                          ), // Closing for OverflowBox
                        ), // Closing for Container
                      ), // Closing for Transform.scale
                    ); // Closing for GestureDetector
                  },
                ),
              ),

              // Bottom Drawer
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (details) {
                    // Close immediately on any drag start
                    setState(() {
                      _isDrawerExpanded = false;
                    });
                  },
                  onTap: () {
                    if (_selectedDay != null) {
                      final normalizedDay = DateTime(_selectedDay!.year,
                          _selectedDay!.month, _selectedDay!.day);
                      final hasShifts = shiftsByDate.containsKey(normalizedDay);
                      if (hasShifts) {
                        setState(() {
                          _isDrawerExpanded = !_isDrawerExpanded;
                        });
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: drawerHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Down arrow handle - tap/drag to dismiss
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isDrawerExpanded = false;
                            });
                          },
                          onVerticalDragUpdate: (details) {
                            if (details.delta.dy > 3) {
                              setState(() {
                                _isDrawerExpanded = false;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: AppTheme.textMuted,
                              size: 28,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildDrawerContent(shiftsByDate, beosByDate),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, Map<DateTime, List<Shift>> shiftsByDate,
      bool isSelected, bool isToday, double rowHeight, bool isDrawerExpanded,
      {Map<DateTime, List<BeoEvent>>? beosByDate}) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final dayShifts = shiftsByDate[normalizedDay] ?? [];
    final dayBeos = beosByDate?[normalizedDay] ?? [];

    // Check if day is outside current month
    final isOutsideMonth = day.month != _focusedDay.month;

    // HIDE badges on grayed-out PAST days (but show future shifts)
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isPastOutsideDay = isOutsideMonth && normalizedDay.isBefore(today);

    // Filter shifts: hide past shifts on outside days
    final visibleShifts = isPastOutsideDay ? <Shift>[] : dayShifts;
    final visibleBeos = isPastOutsideDay ? <BeoEvent>[] : dayBeos;

    // Sort shifts by start time (earliest first)
    final sortedShifts = List<Shift>.from(visibleShifts);
    sortedShifts.sort((a, b) {
      // If both have start times, compare them
      if (a.startTime != null && b.startTime != null) {
        final aTime = _parseTime(a.startTime!);
        final bTime = _parseTime(b.startTime!);
        if (aTime != null && bTime != null) {
          return aTime.compareTo(bTime);
        }
      }
      // If one has start time and other doesn't, prioritize the one with time
      if (a.startTime != null && b.startTime == null) return -1;
      if (a.startTime == null && b.startTime != null) return 1;
      // If neither has start time, use creation time or keep original order
      return 0;
    });

    // Calculate total income using selected money display mode
    final totalIncome = sortedShifts.fold<double>(
        0, (sum, shift) => sum + shift.getDisplayAmount(_moneyDisplayMode));

    Color bgColor =
        isOutsideMonth ? AppTheme.darkBackground : AppTheme.cardBackground;
    Color textColor =
        isOutsideMonth ? AppTheme.textMuted : AppTheme.textPrimary;

    // Only highlight today, not selected days (drawer shows selection)
    bool showTodayHighlight = false;
    if (isToday) {
      showTodayHighlight = true;
    }

    // Check for incomplete shifts (past date, no earnings)
    final hasIncompleteShift = sortedShifts.any((shift) =>
        normalizedDay.isBefore(today) &&
        shift.status != 'completed' &&
        shift.totalIncome == 0);

    // Responsive font sizes: larger on tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // When drawer is expanded on mobile, cells are squeezed - hide extra details
    final isSqueezed = isDrawerExpanded && !isTablet;

    // When row height is very small OR drawer is expanded on mobile, hide EVERYTHING except day number
    // Be aggressive - if drawer is open on mobile, always use minimal mode to prevent overflow
    // ADD MINIMUM HEIGHT CHECK to prevent calendar duplication bug
    final isExtremelySqueezed = (rowHeight < 50 && !isTablet) ||
        (isDrawerExpanded && !isTablet && rowHeight < 80);

    // Determine what to show based on squeeze level
    final showDollarAmount = !isExtremelySqueezed;
    final showShiftBadges = !isSqueezed && !isExtremelySqueezed;

    final dayFontSize = isTablet
        ? 18.0
        : (isExtremelySqueezed ? 10.0 : (isSqueezed ? 9.0 : 10.0));
    final totalFontSize = isTablet
        ? (totalIncome >= 1000 ? 14.0 : 16.0)
        : (isSqueezed ? 8.0 : (totalIncome >= 1000 ? 8.0 : 10.0));

    return Container(
      // CRITICAL FIX: Use Container with constraints instead of SizedBox.expand
      // This prevents the duplication bug when drawer squeezes the calendar
      constraints: const BoxConstraints(
        minHeight: 40, // Minimum height to prevent complete collapse
        minWidth: 30, // Minimum width for day number
      ),
      margin: const EdgeInsets.all(2),
      padding: EdgeInsets.all(isExtremelySqueezed ? 1 : (isSqueezed ? 2 : 4)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: showTodayHighlight
            ? Border.all(
                color: AppTheme.primaryGreen,
                width: isExtremelySqueezed ? 1 : 2)
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: isExtremelySqueezed
          // EXTREMELY SQUEEZED: FittedBox scales ALL cells uniformly
          // All cells have same structure (day + dot row) for consistent sizing
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Dot row - always present for uniform sizing
                  // Dot visible only for single shifts, invisible/transparent for doubles+
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Show colored dot for single shift, transparent for none or doubles+
                          color: (sortedShifts.length == 1)
                              ? (hasIncompleteShift
                                  ? AppTheme.accentOrange
                                  : AppTheme.primaryGreen)
                              : Colors.transparent,
                        ),
                      ),
                      // BEO dot - show if BEOs exist and single or no shifts
                      if (visibleBeos.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sortedShifts.length <= 1
                                ? AppTheme.accentPurple
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
          // NORMAL/SQUEEZED: Show full content
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Day number + Total (if has shifts) + Warning icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day number (smaller)
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: dayFontSize,
                      ),
                    ),

                    // Daily total (right side) - RED if any incomplete shifts
                    if (sortedShifts.isNotEmpty && showDollarAmount)
                      Flexible(
                        child: Text(
                          currencyFormat.format(totalIncome),
                          style: TextStyle(
                            // Red if incomplete shifts exist, green otherwise
                            color: hasIncompleteShift
                                ? AppTheme.accentRed
                                : AppTheme.primaryGreen,
                            fontSize: totalFontSize,
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),

                // Only show shift badges when NOT squeezed (drawer closed or tablet)
                if (showShiftBadges) ...[
                  const SizedBox(height: 4),

                  // Shift badges (horizontal bars)
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          sortedShifts.length > 5 ? 5 : sortedShifts.length,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final shift = sortedShifts[index];
                        return _buildShiftBadge(
                            shift, normalizedDay, sortedShifts.length);
                      },
                    ),
                  ),

                  // "+X more" indicator
                  if (sortedShifts.length > 5)
                    Text(
                      '+${sortedShifts.length - 5}',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  // Helper method to build individual shift badge
  // totalShiftsForDay: controls layout - stacked for 1-2 shifts, compact for 3+
  Widget _buildShiftBadge(
      Shift shift, DateTime shiftDate, int totalShiftsForDay) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isPast = shiftDate.isBefore(today);
    final isFuture =
        shiftDate.isAfter(today) || shiftDate.isAtSameMomentAs(today);
    final isIncomplete =
        isPast && shift.status != 'completed' && shift.totalIncome == 0;

    // Determine badge color based on FUTURE vs PAST, not completion status
    Color badgeColor;
    if (isIncomplete) {
      badgeColor = AppTheme.textMuted; // Gray for incomplete past shifts
    } else if (isFuture || shift.status == 'scheduled') {
      badgeColor = Colors.blue.shade400; // Blue for future/scheduled
    } else {
      badgeColor = AppTheme.primaryGreen; // Green for past/completed
    }

    final hasTime = shift.startTime != null && shift.endTime != null;

    // Use stacked layout for 1-2 shifts (more readable), compact for 3+
    final useStackedTime = totalShiftsForDay <= 2 && hasTime;

    // ALWAYS show time on calendar badges - money is shown in the modal
    final showTime = hasTime; // Always show time if available

    // Responsive badge sizing for tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final badgeHeight = isTablet ? 22.0 : 14.0;
    final badgeFontSize = isTablet ? 12.0 : 8.0;

    // Stacked layout for 1-2 shifts: time on two lines for better readability
    if (useStackedTime && showTime) {
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
          // Red border for incomplete shifts, normal color otherwise
          border: Border.all(
            color: isIncomplete ? AppTheme.accentRed : badgeColor,
            width: isIncomplete ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_formatTimeShort(shift.startTime!)} -',
              style: TextStyle(
                color: badgeColor,
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatTimeShort(shift.endTime!),
              style: TextStyle(
                color: badgeColor,
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Compact single-line layout for 3+ shifts or money display
    return Container(
      height: badgeHeight,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
        // Red border for incomplete shifts, normal color otherwise
        border: Border.all(
          color: isIncomplete ? AppTheme.accentRed : badgeColor,
          width: isIncomplete ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Time range (compact single line for 3+ shifts)
          if (showTime)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_formatTimeShort(shift.startTime!)}-${_formatTimeShort(shift.endTime!)}',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper to format time smartly (e.g., "5:00 PM" -> "5P", "5:30 PM" -> "5:30P")
  // Only shows minutes if they're not :00
  String _formatTimeShort(String time) {
    try {
      final parts = time.split(':');
      if (parts.isEmpty) return time;
      var hour = int.parse(parts[0]);
      // Extract minutes, handling various formats
      String minuteStr = '00';
      if (parts.length > 1) {
        // Remove AM/PM from minute part if present
        minuteStr = parts[1].replaceAll(RegExp(r'[APMapm\s]'), '');
        if (minuteStr.length > 2) minuteStr = minuteStr.substring(0, 2);
      }
      final minute = int.tryParse(minuteStr) ?? 0;

      final isPM = time.toUpperCase().contains('PM') || hour >= 12;

      // Convert 24-hour to 12-hour if needed
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      // Single letter: A or P (not AM/PM) to save space
      final periodChar = isPM ? 'P' : 'A';
      final minuteDisplay = minute.toString().padLeft(2, '0');

      // Always show full format: 3:00A, 11:30P
      return '$hour:$minuteDisplay$periodChar';
    } catch (e) {
      return time.substring(0, time.length > 6 ? 6 : time.length);
    }
  }

  // Helper to get shift count label (Double, Triple, etc.)
  String _getShiftCountLabel(int count) {
    switch (count) {
      case 2:
        return 'Double';
      case 3:
        return 'Triple';
      case 4:
        return 'Quad';
      default:
        return '${count}x';
    }
  }

  String _formatTime(String time) {
    try {
      // If time already contains AM/PM, return it as-is
      if (time.toUpperCase().contains('AM') ||
          time.toUpperCase().contains('PM')) {
        return time;
      }

      // Otherwise, convert from 24-hour to 12-hour format
      final parts = time.split(':');
      if (parts.length < 2) return time;
      var hour = int.parse(parts[0]);
      final minute = parts[1].substring(0, 2);

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  Widget _buildDrawerContent(Map<DateTime, List<Shift>> shiftsByDate,
      Map<DateTime, List<BeoEvent>> beosByDate) {
    if (_selectedDay == null) {
      return Center(
        child: Text('Select a day', style: AppTheme.bodyMedium),
      );
    }

    final normalizedDay =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayShifts = shiftsByDate[normalizedDay] ?? [];
    final dayBeos = beosByDate[normalizedDay] ?? [];

    if (dayShifts.isEmpty && dayBeos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No shift', style: AppTheme.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddShiftScreen(
                      preselectedDate: _selectedDay,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Shift'),
            ),
          ],
        ),
      );
    }

    final totalIncome = dayShifts.fold<double>(
        0, (sum, shift) => sum + shift.getDisplayAmount(_moneyDisplayMode));
    final totalHours =
        dayShifts.fold<double>(0, (sum, shift) => sum + shift.hoursWorked);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Intercept scroll attempts and close drawer instead
        if (notification is ScrollStartNotification) {
          setState(() {
            _isDrawerExpanded = false;
          });
          return true; // Stop the scroll
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          // If dragging down, close the drawer
          if (details.delta.dy > 5) {
            setState(() {
              _isDrawerExpanded = false;
            });
          }
        },
        onVerticalDragEnd: (details) {
          // If flinging down, close the drawer
          if (details.velocity.pixelsPerSecond.dy > 100) {
            setState(() {
              _isDrawerExpanded = false;
            });
          }
        },
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Compact Summary Bar - Income, Hours, Shift Count, Add Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Income
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShiftDetailScreen(
                                date: normalizedDay,
                                shifts: dayShifts,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalIncome),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Hours
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShiftDetailScreen(
                                date: normalizedDay,
                                shifts: dayShifts,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hours',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              totalHours.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Shift count badge (Double, Triple, etc.)
                    if (dayShifts.length > 1)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getShiftCountLabel(dayShifts.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    // Add Shift Button (compact)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddShiftScreen(
                              preselectedDate: _selectedDay,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Shift cards - matching dashboard style
              ...dayShifts.map((shift) => _buildDrawerShiftCard(shift)),

              // BEO event cards - purple accent
              ...dayBeos.map((beo) => _buildDrawerBeoCard(beo)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a BEO event card for the drawer
  Widget _buildDrawerBeoCard(BeoEvent beo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BeoDetailScreen(beoEvent: beo),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentPurple.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Purple BEO icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description_outlined,
                color: AppTheme.accentPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beo.eventName,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          beo.venueName ?? 'No venue',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Guest count if available
            if (beo.displayGuestCount != null && beo.displayGuestCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 12,
                      color: AppTheme.accentPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${beo.displayGuestCount}',
                      style: TextStyle(
                        color: AppTheme.accentPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a shift card for the drawer - matches dashboard Recent Shifts style
  Widget _buildDrawerShiftCard(Shift shift) {
    final isScheduled = shift.status == 'scheduled';
    final accentColor =
        isScheduled ? AppTheme.accentBlue : AppTheme.primaryGreen;

    // Get job info from jobs map
    final job = _jobs[shift.jobId];
    final jobName = job?.name ?? 'No Job';
    final employer = job?.employer;

    // Clean up event name
    String? cleanEventName;
    if (shift.eventName != null) {
      String eventName = shift.eventName!;
      eventName = eventName.replaceFirst(
          RegExp(r'^Hot Schedules\s*', caseSensitive: false), '');
      if (eventName.trim().isNotEmpty &&
          eventName.toLowerCase() != jobName.toLowerCase()) {
        cleanEventName = eventName.trim();
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleShiftDetailScreen(shift: shift),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
                  // Date Badge with Month Abbreviation (matches dashboard)
                  Container(
                    width: 56,
                    height: 70,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(shift.date),
                          style: AppTheme.labelSmall.copyWith(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(shift.date),
                          style: AppTheme.titleLarge.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          shift.date.year == DateTime.now().year
                              ? DateFormat('MMM').format(shift.date)
                              : DateFormat("MMM ''yy").format(shift.date),
                          style: AppTheme.labelSmall.copyWith(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Shift Info - Dynamic Row Stacking (matches dashboard)
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
                            // Show 'Scheduled' only for FUTURE shifts, otherwise show earnings
                            if (isScheduled &&
                                shift.date.isAfter(DateTime.now()))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Scheduled',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (shift.totalIncome > 0
                                          ? AppTheme.primaryGreen
                                          : AppTheme.accentRed)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  shift.totalIncome == 0
                                      ? '\$0'
                                      : currencyFormat
                                          .format(shift.totalIncome),
                                  style: AppTheme.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: shift.totalIncome > 0
                                        ? AppTheme.primaryGreen
                                        : AppTheme.accentRed,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Dynamic rows below
                        ..._buildDynamicShiftRows(
                            shift, cleanEventName, employer),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds dynamic rows for shift card (event badge, employer badge, time, hours)
  /// Layout: Row 2: Event (left) + Hours (right)
  ///         Row 3: Employer (left) + Time range (right)
  /// Items move up if previous items don't exist
  List<Widget> _buildDynamicShiftRows(
      Shift shift, String? eventName, String? employer) {
    final List<Widget> rows = [];
    final hasTime = shift.startTime != null && shift.endTime != null;

    // Build left column items (event badge, then employer badge)
    final List<Widget?> leftItems = [];
    final List<Widget?> rightItems = [];

    // Event badge (left) + Hours (right) - Row 2
    if (eventName != null) {
      leftItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.accentPurple.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event, size: 10, color: AppTheme.accentPurple),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  eventName,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.accentPurple,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Guest count
              if (shift.guestCount != null && shift.guestCount! > 0) ...[
                const SizedBox(width: 4),
                Icon(Icons.people, size: 10, color: AppTheme.accentPurple),
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
      );
      rightItems.add(
        Text(
          '${shift.hoursWorked.toStringAsFixed(1)} hrs',
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      );
    }

    // Employer badge (left) + Time range (right) - Row 3
    if (employer?.isNotEmpty == true) {
      leftItems.add(
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.accentBlue.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business, size: 10, color: AppTheme.accentBlue),
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
      );
      rightItems.add(
        hasTime
            ? Text(
                '${_formatTime(shift.startTime!)} - ${_formatTime(shift.endTime!)}',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              )
            : null,
      );
    }

    // If no left items at all, show a minimal row with hours and time
    if (leftItems.isEmpty) {
      rows.add(const SizedBox(height: 6));
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Time range if available
            if (hasTime)
              Text(
                '${_formatTime(shift.startTime!)} - ${_formatTime(shift.endTime!)}',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              )
            else
              const SizedBox(),
            // Hours
            Text(
              '${shift.hoursWorked.toStringAsFixed(1)} hrs',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else {
      // Build rows from left/right items
      for (int i = 0; i < leftItems.length; i++) {
        rows.add(const SizedBox(height: 6));
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: leftItems[i]!),
              if (i < rightItems.length && rightItems[i] != null)
                rightItems[i]!,
            ],
          ),
        );
      }

      // If we have event but no employer, and have time, add time on separate row
      if (eventName != null && (employer?.isEmpty ?? true) && hasTime) {
        rows.add(const SizedBox(height: 6));
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_formatTime(shift.startTime!)} - ${_formatTime(shift.endTime!)}',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }
    }

    return rows;
  }

  // MONTH LIST VIEW (like week view but for whole month)
  Widget _buildMonthListView(Map<DateTime, List<Shift>> shiftsByDate) {
    // Get all days in the current month
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Calculate month stats
    final monthShifts = shiftsByDate.entries
        .where((e) =>
            e.key.month == _focusedDay.month && e.key.year == _focusedDay.year)
        .expand((e) => e.value)
        .toList();
    final monthIncome =
        monthShifts.fold<double>(0, (sum, shift) => sum + shift.totalIncome);
    final monthHours =
        monthShifts.fold<double>(0, (sum, shift) => sum + shift.hoursWorked);

    // Scroll to today after frame is built (if in current month)
    final now = DateTime.now();
    if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthListScrollController.hasClients) {
          final dayOfMonth = now.day;
          // Each card is approximately 120px tall (including margin)
          final scrollOffset = (dayOfMonth - 1) * 120.0;
          // Scroll to position today in the middle of the screen
          final screenHeight = MediaQuery.of(context).size.height;
          final targetOffset = scrollOffset - (screenHeight / 2) + 60;

          _monthListScrollController.jumpTo(
            targetOffset.clamp(
                0.0, _monthListScrollController.position.maxScrollExtent),
          );
        }
      });
    }

    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.15),
                AppTheme.accentBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeekStat('Income', currencyFormat.format(monthIncome)),
              _buildWeekStat('Hours', monthHours.toStringAsFixed(1)),
              _buildWeekStat('Shifts', '${monthShifts.length}'),
            ],
          ),
        ),

        // Day list
        Expanded(
          child: ListView.builder(
            controller: _monthListScrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day =
                  DateTime(_focusedDay.year, _focusedDay.month, index + 1);
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final dayShifts = shiftsByDate[normalizedDay] ?? [];
              final dayIncome = dayShifts.fold<double>(
                  0, (sum, shift) => sum + shift.totalIncome);
              final dayHours = dayShifts.fold<double>(
                  0, (sum, shift) => sum + shift.hoursWorked);

              final isToday = isSameDay(day, DateTime.now());

              return GestureDetector(
                onTap: () {
                  _resetZoom(); // Reset zoom when tapping a day
                  if (dayShifts.isEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddShiftScreen(
                          preselectedDate: day,
                        ),
                      ),
                    );
                  } else {
                    // Open drawer modal for days with shifts
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                      _isDrawerExpanded = true;
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday
                        ? Border.all(color: AppTheme.primaryGreen, width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: Date + Day total
                      Row(
                        children: [
                          // Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEE').format(day).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat('d').format(day),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Day total
                          if (dayShifts.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currencyFormat.format(dayIncome),
                                      style: TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('•',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${dayHours.toStringAsFixed(1)}h',
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${dayShifts.length} shift${dayShifts.length > 1 ? 's' : ''}',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      if (dayShifts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: Text(
                              '+ Add shift',
                              style: AppTheme.bodyMedium
                                  .copyWith(color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      else if (dayShifts.length == 1) ...[
                        // SINGLE SHIFT - Show detailed view (no redundant summary)
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingleShiftDetailScreen(
                                    shift: dayShifts.first),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dayShifts.first.status == 'scheduled'
                                  ? AppTheme.accentBlue.withOpacity(0.08)
                                  : AppTheme.primaryGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dayShifts.first.status == 'scheduled'
                                    ? AppTheme.accentBlue.withOpacity(0.3)
                                    : AppTheme.primaryGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: Job name and time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Job name with dot
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: dayShifts.first.status ==
                                                      'scheduled'
                                                  ? AppTheme.accentBlue
                                                  : AppTheme.primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _jobs[dayShifts.first.jobId]
                                                      ?.name ??
                                                  'Shift',
                                              style:
                                                  AppTheme.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (dayShifts.first.startTime != null &&
                                          dayShifts.first.endTime != null) ...[
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 16),
                                          child: Text(
                                            '${_formatTime(dayShifts.first.startTime!)} - ${_formatTime(dayShifts.first.endTime!)}',
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right: Event, guests, notes
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Event name
                                      if (dayShifts.first.eventName != null &&
                                          dayShifts
                                              .first.eventName!.isNotEmpty) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(Icons.event,
                                                size: 14,
                                                color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                dayShifts.first.eventName!,
                                                style: AppTheme.labelMedium
                                                    .copyWith(
                                                  color: AppTheme.textMuted,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      // Guest count
                                      if (dayShifts.first.guestCount != null &&
                                          dayShifts.first.guestCount! > 0) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(Icons.people,
                                                size: 14,
                                                color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${dayShifts.first.guestCount} guests',
                                              style:
                                                  AppTheme.labelMedium.copyWith(
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      // Notes preview
                                      if (dayShifts.first.notes != null &&
                                          dayShifts.first.notes!.isNotEmpty)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(Icons.note,
                                                size: 14,
                                                color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                dayShifts.first.notes!,
                                                style: AppTheme.labelMedium
                                                    .copyWith(
                                                  color: AppTheme.textMuted,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // MULTIPLE SHIFTS (2+) - Show compressed cards
                        const SizedBox(height: 16),
                        ...dayShifts.take(2).map((shift) {
                          final isScheduled = shift.status == 'scheduled';
                          final hasTime =
                              shift.startTime != null && shift.endTime != null;

                          final job = _jobs[shift.jobId];
                          final jobName = job?.name ?? 'Shift';

                          Color dotColor = isScheduled
                              ? AppTheme.accentBlue
                              : AppTheme.primaryGreen;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SingleShiftDetailScreen(shift: shift),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isScheduled
                                    ? AppTheme.accentBlue.withOpacity(0.08)
                                    : AppTheme.primaryGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isScheduled
                                      ? AppTheme.accentBlue.withOpacity(0.3)
                                      : AppTheme.primaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Job name + Time
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Job name with dot
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: dotColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                jobName,
                                                style: AppTheme.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hasTime) ...[
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 16),
                                            child: Text(
                                              '${_formatTime(shift.startTime!)} - ${_formatTime(shift.endTime!)}',
                                              style:
                                                  AppTheme.bodyMedium.copyWith(
                                                color: AppTheme.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Center: Event name + Guest count
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (shift.eventName != null &&
                                            shift.eventName!.isNotEmpty)
                                          Text(
                                            shift.eventName!,
                                            style:
                                                AppTheme.labelMedium.copyWith(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          )
                                        else
                                          const SizedBox(height: 14),
                                        if (shift.guestCount != null &&
                                            shift.guestCount! > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${shift.guestCount} guests',
                                            style:
                                                AppTheme.labelMedium.copyWith(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Right: Amount + Hours
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat
                                            .format(shift.totalIncome),
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${shift.hoursWorked.toStringAsFixed(1)}h',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        // "+X more" indicator
                        if (dayShifts.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+ ${dayShifts.length - 2} more shift${dayShifts.length - 2 > 1 ? 's' : ''} · Tap to see all',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // WEEK VIEW
  Widget _buildWeekView(
      Map<DateTime, List<Shift>> shiftsByDate, List<Shift> allShifts) {
    final weekStart =
        _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekShifts = allShifts.where((shift) {
      return shift.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          shift.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    final totalIncome =
        weekShifts.fold<double>(0, (sum, shift) => sum + shift.totalIncome);
    final totalHours =
        weekShifts.fold<double>(0, (sum, shift) => sum + shift.hoursWorked);

    return Column(
      children: [
        // Compact stats
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.15),
                AppTheme.accentBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeekStat('Income', currencyFormat.format(totalIncome)),
              _buildWeekStat('Hours', totalHours.toStringAsFixed(1)),
              _buildWeekStat('Shifts', '${weekShifts.length}'),
            ],
          ),
        ),

        // Week days (all 7 visible) - scrollable
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isTablet = screenWidth > 600;

              // On tablets, use Column with Expanded to fill the screen
              if (isTablet) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: List.generate(7, (index) {
                      final day = weekStart.add(Duration(days: index));
                      final normalizedDay =
                          DateTime(day.year, day.month, day.day);
                      final dayShifts = shiftsByDate[normalizedDay] ?? [];
                      final dayIncome = dayShifts.fold<double>(
                          0, (sum, shift) => sum + shift.totalIncome);
                      final dayHours = dayShifts.fold<double>(
                          0, (sum, shift) => sum + shift.hoursWorked);
                      final isToday = isSameDay(day, DateTime.now());

                      return _buildWeekDayCard(
                        day,
                        normalizedDay,
                        dayShifts,
                        dayIncome,
                        dayHours,
                        isToday,
                        constraints.maxHeight / 7.5, // Distribute height evenly
                      );
                    }),
                  ),
                );
              }

              // On phones, use regular ListView
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final day = weekStart.add(Duration(days: index));
                  final normalizedDay = DateTime(day.year, day.month, day.day);
                  final dayShifts = shiftsByDate[normalizedDay] ?? [];
                  final dayIncome = dayShifts.fold<double>(
                      0, (sum, shift) => sum + shift.totalIncome);
                  final dayHours = dayShifts.fold<double>(
                      0, (sum, shift) => sum + shift.hoursWorked);
                  final isToday = isSameDay(day, DateTime.now());

                  return _buildWeekDayCard(
                    day,
                    normalizedDay,
                    dayShifts,
                    dayIncome,
                    dayHours,
                    isToday,
                    null, // No fixed height for phones
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build week day card
  Widget _buildWeekDayCard(
    DateTime day,
    DateTime normalizedDay,
    List<Shift> dayShifts,
    double dayIncome,
    double dayHours,
    bool isToday,
    double? fixedHeight,
  ) {
    return GestureDetector(
      onTap: () {
        _resetZoom(); // Reset zoom when tapping a day
        if (dayShifts.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddShiftScreen(
                preselectedDate: day,
              ),
            ),
          );
        } else {
          // Open drawer modal for days with shifts
          setState(() {
            _selectedDay = day;
            _focusedDay = day;
            _isDrawerExpanded = true;
          });
        }
      },
      child: Container(
        height: fixedHeight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday
              ? AppTheme.primaryGreen.withOpacity(0.12)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? AppTheme.primaryGreen : Colors.transparent,
            width: isToday ? 2 : 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Date + Day total
            Row(
              children: [
                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE').format(day).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(day),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? AppTheme.primaryGreen
                            : AppTheme.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Day total
                if (dayShifts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            currencyFormat.format(dayIncome),
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('•',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(width: 6),
                          Text(
                            '${dayHours.toStringAsFixed(1)}h',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${dayShifts.length} shift${dayShifts.length > 1 ? 's' : ''}',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (dayShifts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    '+ Add shift',
                    style:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                  ),
                ),
              )
            else if (dayShifts.length == 1) ...[
              // SINGLE SHIFT - Show detailed view (no redundant summary)
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SingleShiftDetailScreen(shift: dayShifts.first),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dayShifts.first.status == 'scheduled'
                        ? AppTheme.accentBlue.withOpacity(0.08)
                        : AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dayShifts.first.status == 'scheduled'
                          ? AppTheme.accentBlue.withOpacity(0.3)
                          : AppTheme.primaryGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Job name and time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job name with dot
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dayShifts.first.status == 'scheduled'
                                        ? AppTheme.accentBlue
                                        : AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _jobs[dayShifts.first.jobId]?.name ??
                                        'Shift',
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (dayShifts.first.startTime != null &&
                                dayShifts.first.endTime != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  '${_formatTime(dayShifts.first.startTime!)} - ${_formatTime(dayShifts.first.endTime!)}',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right: Event, guests, notes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Event name
                            if (dayShifts.first.eventName != null &&
                                dayShifts.first.eventName!.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.event,
                                      size: 14, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      dayShifts.first.eventName!,
                                      style: AppTheme.labelMedium.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            // Guest count
                            if (dayShifts.first.guestCount != null &&
                                dayShifts.first.guestCount! > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.people,
                                      size: 14, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dayShifts.first.guestCount} guests',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            // Notes preview
                            if (dayShifts.first.notes != null &&
                                dayShifts.first.notes!.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.note,
                                      size: 14, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      dayShifts.first.notes!,
                                      style: AppTheme.labelMedium.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // MULTIPLE SHIFTS (2+) - Show compressed cards
              const SizedBox(height: 16),
              ...dayShifts.take(2).map((shift) {
                final isScheduled = shift.status == 'scheduled';
                final hasTime =
                    shift.startTime != null && shift.endTime != null;

                final job = _jobs[shift.jobId];
                final jobName = job?.name ?? 'Shift';

                Color dotColor =
                    isScheduled ? AppTheme.accentBlue : AppTheme.primaryGreen;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SingleShiftDetailScreen(shift: shift),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isScheduled
                          ? AppTheme.accentBlue.withOpacity(0.08)
                          : AppTheme.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isScheduled
                            ? AppTheme.accentBlue.withOpacity(0.3)
                            : AppTheme.primaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Job name + Time
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Job name with dot
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dotColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      jobName,
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasTime) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    '${_formatTime(shift.startTime!)} - ${_formatTime(shift.endTime!)}',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Center: Event name + Guest count
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (shift.eventName != null &&
                                  shift.eventName!.isNotEmpty)
                                Text(
                                  shift.eventName!,
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                              else
                                const SizedBox(height: 14),
                              if (shift.guestCount != null &&
                                  shift.guestCount! > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${shift.guestCount} guests',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right: Amount + Hours
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(shift.totalIncome),
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${shift.hoursWorked.toStringAsFixed(1)}h',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "+X more" indicator
              if (dayShifts.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${dayShifts.length - 2} more shift${dayShifts.length - 2 > 1 ? 's' : ''} · Tap to see all',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // YEAR VIEW - 3x4 Grid
  Widget _buildYearView(List<Shift> allShifts) {
    final shiftsByMonth = <int, List<Shift>>{};
    final yearShifts =
        allShifts.where((s) => s.date.year == _focusedDay.year).toList();
    final yearIncome =
        yearShifts.fold<double>(0, (sum, shift) => sum + shift.totalIncome);
    final yearHours =
        yearShifts.fold<double>(0, (sum, shift) => sum + shift.hoursWorked);

    for (final shift in allShifts) {
      if (shift.date.year == _focusedDay.year) {
        shiftsByMonth.putIfAbsent(shift.date.month, () => []).add(shift);
      }
    }

    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.15),
                AppTheme.accentBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeekStat('Income', currencyFormat.format(yearIncome)),
              _buildWeekStat('Hours', yearHours.toStringAsFixed(1)),
              _buildWeekStat('Shifts', '${yearShifts.length}'),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isTablet = screenWidth > 600;

              // Calculate card dimensions that fill the space
              // 4 rows of cards (12 months / 3 columns = 4 rows)
              const spacing = 12.0;
              const padding = 16.0;
              const totalVerticalSpacing = spacing * 3; // 3 gaps between 4 rows
              final cardHeight = (constraints.maxHeight -
                      totalVerticalSpacing -
                      (padding * 2)) /
                  4;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: cardHeight,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthShifts = shiftsByMonth[month] ?? [];
                  final totalIncome = monthShifts.fold<double>(
                      0, (sum, shift) => sum + shift.totalIncome);
                  final totalHours = monthShifts.fold<double>(
                      0, (sum, shift) => sum + shift.hoursWorked);

                  // Check if this is the current month
                  final now = DateTime.now();
                  final isCurrentMonth =
                      month == now.month && _focusedDay.year == now.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _viewMode = CalendarViewMode.month;
                        _focusedDay = DateTime(_focusedDay.year, month);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentMonth
                              ? AppTheme.primaryGreen
                              : (monthShifts.isEmpty
                                  ? AppTheme.cardBackgroundLight
                                  : AppTheme.primaryGreen.withOpacity(0.3)),
                          width: isCurrentMonth
                              ? 2
                              : (monthShifts.isEmpty ? 1 : 1.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Month name
                          Text(
                            DateFormat('MMM')
                                .format(DateTime(_focusedDay.year, month))
                                .toUpperCase(),
                            style: AppTheme.titleMedium.copyWith(
                              fontSize: isTablet ? 20 : 13,
                              fontWeight: FontWeight.w600,
                              color: monthShifts.isEmpty
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Stats or empty state
                          if (monthShifts.isEmpty)
                            Text(
                              '—',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                                fontSize: isTablet ? 36 : 24,
                              ),
                            )
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Money amount (largest)
                                Text(
                                  currencyFormat.format(totalIncome),
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: isTablet ? 28 : 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Hours + Shifts count combined
                                Text(
                                  '${totalHours.toStringAsFixed(0)}h · ${monthShifts.length} shift${monthShifts.length > 1 ? 's' : ''}',
                                  style: AppTheme.labelMedium.copyWith(
                                    fontSize: isTablet ? 16 : 10,
                                    color: AppTheme.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to parse time strings like "2:00 PM" into comparable DateTime
  DateTime? _parseTime(String timeString) {
    try {
      // Parse time string (e.g., "2:00 PM", "14:30", etc.)
      final now = DateTime.now();
      final formats = [
        DateFormat('h:mm a'), // 2:00 PM
        DateFormat('h:mma'), // 2:00PM
        DateFormat('HH:mm'), // 14:00
        DateFormat('h a'), // 2 PM
        DateFormat('ha'), // 2PM
      ];

      for (final format in formats) {
        try {
          final parsed = format.parse(timeString);
          // Return a DateTime with today's date but the parsed time
          return DateTime(
              now.year, now.month, now.day, parsed.hour, parsed.minute);
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
