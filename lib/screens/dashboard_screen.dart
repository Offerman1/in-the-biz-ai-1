import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
import '../theme/app_theme.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/particle_background.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/animated_logo.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    Future.microtask(
        () => Provider.of<ShiftProvider>(context, listen: false).loadShifts());
  }

  final List<Widget> _screens = [
    const _HomeScreen(),
    const BetterCalendarScreen(),
    const AssistantScreen(),
    const StatsWithCheckoutTab(),
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
                    baseColor: AppTheme.darkBackground,
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
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.navBarBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildNavItem(1, Icons.calendar_today_outlined,
                      Icons.calendar_today, 'Calendar'),
                  _buildNavItem(2, Icons.auto_awesome_outlined,
                      Icons.auto_awesome, 'Chat'),
                  _buildNavItem(
                      3, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
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
  }
}

// ============================================================
// HOME SCREEN (Dashboard Tab)
// ============================================================

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

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

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadGoal();
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
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AddShiftScreen()),
                                ).then((_) {
                                  // Reload data when returning from Add Shift
                                  setState(() {});
                                });
                              },
                              child: Icon(Icons.add,
                                  color: AppTheme.primaryGreen, size: 28),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
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
                              child: Icon(Icons.flag,
                                  color: AppTheme.primaryGreen, size: 28),
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
                                  color: AppTheme.textPrimary.withOpacity(0.1),
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
                                            content: Text('Data refreshed'),
                                            backgroundColor:
                                                AppTheme.primaryGreen,
                                            duration: Duration(seconds: 2),
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
                                      color: AppTheme.primaryGreen, size: 28),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SettingsScreen()),
                                );
                              },
                              child: Icon(Icons.settings_outlined,
                                  color: AppTheme.primaryGreen, size: 28),
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
                                          SizedBox(width: 16),
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
                            color: AppTheme.primaryGreen.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: LinearProgressIndicator(
                              value: goalPercent,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
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
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
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
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
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
                                      AppTheme.primaryGreen.withOpacity(0.25),
                                      AppTheme.primaryGreen.withOpacity(0.15),
                                    ]
                                  : [
                                      AppTheme.accentRed.withOpacity(0.25),
                                      AppTheme.accentRed.withOpacity(0.15),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: percentChange >= 0
                                  ? AppTheme.primaryGreen.withOpacity(0.4)
                                  : AppTheme.accentRed.withOpacity(0.4),
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
                                      color: Colors.black.withOpacity(0.3),
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
                    '${periodShifts.fold(0.0, (sum, s) => sum + s.hoursWorked).toStringAsFixed(0)}',
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
                        icon: const Icon(Icons.add),
                        label: const Text('Add Shift'),
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
                // Filter shifts by selected job, include today's shifts and past shifts
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final filteredShifts = (_selectedJobId == null
                        ? shiftProvider.shifts
                        : shiftProvider.shifts
                            .where((shift) => shift.jobId == _selectedJobId)
                            .toList())
                    .where((shift) {
                  final shiftDate = DateTime(
                      shift.date.year, shift.date.month, shift.date.day);
                  // Include today and past shifts (not future shifts)
                  return !shiftDate.isAfter(today);
                }).toList();

                final recentShifts = filteredShifts.take(5).toList();
                if (index >= recentShifts.length) return null;

                final shift = recentShifts[index];
                return _buildShiftCard(context, shift, currencyFormat);
              },
              childCount: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final filteredShifts = (_selectedJobId == null
                        ? shiftProvider.shifts
                        : shiftProvider.shifts
                            .where((shift) => shift.jobId == _selectedJobId)
                            .toList())
                    .where((shift) {
                  final shiftDate = DateTime(
                      shift.date.year, shift.date.month, shift.date.day);
                  // Include today and past shifts (not future shifts)
                  return !shiftDate.isAfter(today);
                }).toList();
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
    final isLightMode = AppTheme.darkBackground.computeLuminance() > 0.5;
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
          color: isSelected
              ? (isLightMode
                  ? const Color(
                      0xFFD1D5DB) // Darker gray for light mode selected
                  : AppTheme.cardBackgroundLight)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.textPrimary
                : AppTheme.textSecondary, // White/gray text, not colored
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildJobTab(String label, String? jobId) {
    final isSelected = _selectedJobId == jobId;
    final isLightMode = AppTheme.darkBackground.computeLuminance() > 0.5;
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
            color: isSelected
                ? (isLightMode
                    ? const Color(
                        0xFFD1D5DB) // Darker gray for light mode selected
                    : AppTheme.cardBackgroundLight)
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.adaptiveTextColor
                  : AppTheme.textSecondary,
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
                // Date Badge with Month Abbreviation
                Container(
                  width: 56,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      width: 1,
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
                          color: AppTheme.textPrimary,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.accentPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        AppTheme.accentPurple.withOpacity(0.3),
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
                                    Text(
                                      shift.eventName!,
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.accentPurple,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
