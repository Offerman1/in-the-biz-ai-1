import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/shift_provider.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _jobs = [];
  String? _selectedJobId;
  String _selectedPeriod = 'Month'; // Day, Week, Month, Year, All

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final jobs = await _db.getJobs();
    setState(() {
      _jobs = jobs;
    });
  }

  Future<void> _handleExport(
      BuildContext context, String type, List<dynamic> shifts) async {
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
        );
      } else if (type == 'pdf') {
        filePath = await ExportService.exportToPDF(
          shifts: shifts,
          startDate: startOfMonth,
          endDate: endOfMonth,
          title: 'Income Report - ${DateFormat('MMMM yyyy').format(now)}',
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
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency();

    // Filter shifts by selected job
    var shifts = _selectedJobId == null
        ? shiftProvider.shifts
        : shiftProvider.shifts.where((s) => s.jobId == _selectedJobId).toList();

    // Filter shifts by selected period
    final filteredShifts = _filterShiftsByPeriod(shifts);

    // Calculate totals for filtered period
    final periodTotal =
        filteredShifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final periodHours =
        filteredShifts.fold(0.0, (sum, s) => sum + s.hoursWorked);

    // Calculate previous period for comparison
    final previousPeriodShifts = _getPreviousPeriodShifts(shifts);
    final previousPeriodTotal =
        previousPeriodShifts.fold(0.0, (sum, s) => sum + s.totalIncome);

    final percentChange = previousPeriodTotal > 0
        ? ((periodTotal - previousPeriodTotal) / previousPeriodTotal * 100)
        : 0.0;

    // Calculate weekly totals for chart
    final weeklyTotals = <int, double>{};
    for (final shift in filteredShifts) {
      final weekOfMonth = ((shift.date.day - 1) ~/ 7) + 1;
      weeklyTotals[weekOfMonth] =
          (weeklyTotals[weekOfMonth] ?? 0) + shift.totalIncome;
    }

    // Best days analysis
    final dayTotals = <int, List<double>>{};
    for (final shift in shifts) {
      final weekday = shift.date.weekday;
      dayTotals.putIfAbsent(weekday, () => []).add(shift.totalIncome);
    }

    final dayAverages = dayTotals.map((key, value) =>
        MapEntry(key, value.fold(0.0, (a, b) => a + b) / value.length));

    final sortedDays = dayAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Statistics',
              style: AppTheme.titleLarge
                  .copyWith(color: AppTheme.adaptiveTextColor)),
          centerTitle: false,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.ios_share, color: AppTheme.primaryGreen),
              color: AppTheme.cardBackground,
              onSelected: (value) => _handleExport(context, value, shifts),
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
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtering UI
            _buildFilterSection(),
            const SizedBox(height: 16),

            // Quick Stats Cards
            _buildQuickStatsCards(
                filteredShifts, periodTotal, periodHours, currencyFormat),
            const SizedBox(height: 16),

            // Monthly Total Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPeriodLabel().toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
                      ),
                      if (previousPeriodTotal > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: percentChange >= 0
                                ? AppTheme.primaryGreen.withOpacity(0.15)
                                : AppTheme.accentRed.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                percentChange >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 14,
                                color: percentChange >= 0
                                    ? AppTheme.primaryGreen
                                    : AppTheme.accentRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: percentChange >= 0
                                      ? AppTheme.primaryGreen
                                      : AppTheme.accentRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormat.format(periodTotal),
                    style: AppTheme.moneyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredShifts.length} shifts • ${periodHours.toStringAsFixed(0)} hours',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Weekly Breakdown with fl_chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY BREAKDOWN',
                    style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: weeklyTotals.values.isEmpty
                            ? 100
                            : weeklyTotals.values
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '\$${rod.toY.toInt()}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'W${value.toInt() + 1}',
                                    style: AppTheme.labelSmall,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(4, (index) {
                          final week = index + 1;
                          final total = weeklyTotals[week] ?? 0;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: total,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.primaryGreen.withOpacity(0.7),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 40,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Monthly Trend Line Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6-MONTH TREND',
                    style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: _buildMonthlyTrendChart(shifts),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Income Breakdown Pie Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INCOME BY JOB TYPE',
                    style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: _buildJobTypePieChart(shifts, currencyFormat),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Best Days
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BEST DAYS',
                    style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  if (sortedDays.isEmpty)
                    Text('Not enough data yet', style: AppTheme.bodyMedium)
                  else
                    ...sortedDays.take(3).map((entry) {
                      final dayName = _getDayName(entry.key);
                      final isTop = entry == sortedDays.first;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isTop
                                    ? AppTheme.primaryGreen.withOpacity(0.15)
                                    : AppTheme.cardBackgroundLight,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Center(
                                child: Text(
                                  dayName.substring(0, 2),
                                  style: TextStyle(
                                    color: isTop
                                        ? AppTheme.primaryGreen
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dayName, style: AppTheme.bodyLarge),
                                  Text(
                                    '${dayTotals[entry.key]?.length ?? 0} shifts logged',
                                    style: AppTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(entry.value),
                                  style: isTop
                                      ? AppTheme.moneySmall
                                      : AppTheme.titleMedium,
                                ),
                                Text('avg', style: AppTheme.labelSmall),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tips Analysis
            _buildTipsAnalysis(filteredShifts, currencyFormat),
            const SizedBox(height: 16),

            // Hourly Rate Analysis
            _buildHourlyRateAnalysis(filteredShifts, currencyFormat),
            const SizedBox(height: 16),

            // Efficiency Metrics
            _buildEfficiencyMetrics(filteredShifts, currencyFormat),
            const SizedBox(height: 16),

            // Goal Progress (if goals exist)
            _buildGoalProgress(filteredShifts, currencyFormat),
            const SizedBox(height: 16),

            // Income Forecast
            _buildIncomeForecast(shifts, filteredShifts, currencyFormat),
            const SizedBox(height: 16),

            // Income Sources Breakdown
            _buildIncomeSourcesBreakdown(filteredShifts, currencyFormat),
            const SizedBox(height: 16),

            // All-time Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALL TIME',
                    style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  _buildAllTimeStat(
                    'Total Earned',
                    currencyFormat.format(
                        shifts.fold(0.0, (sum, s) => sum + s.totalIncome)),
                    Icons.attach_money,
                  ),
                  Divider(color: AppTheme.cardBackgroundLight, height: 24),
                  _buildAllTimeStat(
                    'Total Shifts',
                    '${shifts.length}',
                    Icons.work_outline,
                  ),
                  Divider(color: AppTheme.cardBackgroundLight, height: 24),
                  _buildAllTimeStat(
                    'Total Hours',
                    shifts.fold(0.0, (sum, s) => sum + s.hoursWorked).toStringAsFixed(0),
                    Icons.schedule_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimeStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTheme.bodyLarge)),
        Text(value, style: AppTheme.titleMedium),
      ],
    );
  }

  Widget _buildMonthlyTrendChart(List shifts) {
    final now = DateTime.now();
    final monthlyData = <int, double>{};

    // Get last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthShifts = shifts
          .where(
              (s) => s.date.month == month.month && s.date.year == month.year)
          .toList();
      final total = monthShifts.fold(0.0, (sum, s) => sum + s.totalIncome);
      monthlyData[i] = total;
    }

    final maxY = monthlyData.values.isEmpty
        ? 100.0
        : (monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2)
            .clamp(100.0, double.infinity);

    // Calculate interval - must be > 0
    final interval = maxY > 0 ? maxY / 4 : 25.0;

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '\$${spot.y.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.cardBackgroundLight,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final monthIndex = value.toInt();
                if (monthIndex < 0 || monthIndex > 5) return const SizedBox();
                final month = DateTime(now.year, now.month - (5 - monthIndex));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM').format(month),
                    style: AppTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: monthlyData.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.7),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2,
                  strokeColor: AppTheme.darkBackground,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.3),
                  AppTheme.primaryGreen.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypePieChart(List shifts, NumberFormat currencyFormat) {
    final jobTypeData = <String, double>{};

    for (final shift in shifts) {
      final jobType = shift.jobType ?? 'Server';
      jobTypeData[jobType] = (jobTypeData[jobType] ?? 0) + shift.totalIncome;
    }

    if (jobTypeData.isEmpty) {
      return Center(
        child: Text('No data yet', style: AppTheme.bodyMedium),
      );
    }

    final total = jobTypeData.values.fold(0.0, (a, b) => a + b);
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.chartGreen1,
      AppTheme.chartGreen2,
      AppTheme.chartGreen3,
    ];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections:
                  jobTypeData.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final percentage =
                    (data.value / total * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  value: data.value,
                  title: '$percentage%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  color: colors[index % colors.length],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: jobTypeData.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.key,
                            style: AppTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currencyFormat.format(data.value),
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday];
  }

  List<dynamic> _filterShiftsByPeriod(List<dynamic> shifts) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Day':
        final today = DateTime(now.year, now.month, now.day);
        return shifts.where((s) {
          final shiftDate = DateTime(s.date.year, s.date.month, s.date.day);
          return shiftDate == today;
        }).toList();

      case 'Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return shifts
            .where((s) =>
                s.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                s.date.isBefore(endOfWeek))
            .toList();

      case 'Month':
        return shifts
            .where((s) => s.date.month == now.month && s.date.year == now.year)
            .toList();

      case 'Year':
        return shifts.where((s) => s.date.year == now.year).toList();

      case 'All':
      default:
        return shifts;
    }
  }

  List<dynamic> _getPreviousPeriodShifts(List<dynamic> shifts) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Day':
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);
        return shifts.where((s) {
          final shiftDate = DateTime(s.date.year, s.date.month, s.date.day);
          return shiftDate == yesterdayDate;
        }).toList();

      case 'Week':
        final lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
        final lastWeekEnd = lastWeekStart.add(const Duration(days: 7));
        return shifts
            .where((s) =>
                s.date
                    .isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
                s.date.isBefore(lastWeekEnd))
            .toList();

      case 'Month':
        final lastMonth = DateTime(now.year, now.month - 1);
        return shifts
            .where((s) =>
                s.date.month == lastMonth.month &&
                s.date.year == lastMonth.year)
            .toList();

      case 'Year':
        return shifts.where((s) => s.date.year == now.year - 1).toList();

      case 'All':
      default:
        return [];
    }
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Day':
        return DateFormat('EEEE, MMMM d').format(now);
      case 'Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return 'Week of ${DateFormat('MMM d').format(startOfWeek)}';
      case 'Month':
        return DateFormat('MMMM yyyy').format(now);
      case 'Year':
        return DateFormat('yyyy').format(now);
      case 'All':
      default:
        return 'All Time';
    }
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Job Filter Tabs (with container border to look like tabs)
          if (_jobs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildJobTab('All', null),
                  if (_jobs.isNotEmpty)
                    _buildJobTab(
                        _jobs[0]['name'] as String, _jobs[0]['id'] as String),
                  if (_jobs.length > 1)
                    _buildJobTab(
                        _jobs[1]['name'] as String, _jobs[1]['id'] as String),
                  if (_jobs.length > 2) ...[
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_drop_down,
                            color: AppTheme.primaryGreen, size: 20),
                      ),
                      onSelected: (jobId) {
                        setState(() {
                          _selectedJobId = jobId;
                        });
                      },
                      itemBuilder: (context) {
                        return _jobs.skip(2).map((job) {
                          final jobId = job['id'] as String;
                          final jobName = job['name'] as String;
                          return PopupMenuItem<String>(
                            value: jobId,
                            child: Row(
                              children: [
                                if (_selectedJobId == jobId)
                                  Icon(Icons.check,
                                      color: AppTheme.primaryGreen, size: 16),
                                if (_selectedJobId == jobId)
                                  const SizedBox(width: 8),
                                Text(jobName),
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
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: AppTheme.primaryGreen.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
          ],

          // Period Filter Chips (centered)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodChip('Day'),
              _buildPeriodChip('Week'),
              _buildPeriodChip('Month'),
              _buildPeriodChip('Year'),
              _buildPeriodChip('All'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobTab(String label, String? jobId) {
    final isSelected = _selectedJobId == jobId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedJobId = jobId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Quick Stats Cards
  Widget _buildQuickStatsCards(List shifts, double periodTotal,
      double periodHours, NumberFormat currencyFormat) {
    final avgPerShift = shifts.isEmpty ? 0.0 : periodTotal / shifts.length;
    final effectiveRate = periodHours > 0 ? periodTotal / periodHours : 0.0;

    // Today's earnings
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayShifts = shifts.where((s) {
      final shiftDate = DateTime(s.date.year, s.date.month, s.date.day);
      return shiftDate == today;
    }).toList();
    final todayTotal = todayShifts.fold(0.0, (sum, s) => sum + s.totalIncome);

    return Row(
      children: [
        Expanded(
            child: _buildQuickStatCard(
                'Today',
                currencyFormat.format(todayTotal),
                Icons.today,
                AppTheme.accentBlue)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildQuickStatCard(
                'Avg/Shift',
                currencyFormat.format(avgPerShift),
                Icons.attach_money,
                AppTheme.primaryGreen)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildQuickStatCard(
                'Eff. Rate',
                '${currencyFormat.format(effectiveRate)}/hr',
                Icons.speed,
                AppTheme.accentOrange)),
      ],
    );
  }

  Widget _buildQuickStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: AppTheme.titleMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // Tips Analysis
  Widget _buildTipsAnalysis(List shifts, NumberFormat currencyFormat) {
    final totalCashTips = shifts.fold(0.0, (sum, s) => sum + s.cashTips);
    final totalCreditTips = shifts.fold(0.0, (sum, s) => sum + s.creditTips);
    final totalTips = totalCashTips + totalCreditTips;
    final totalIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final tipsPercentage =
        totalIncome > 0 ? (totalTips / totalIncome * 100) : 0.0;
    final avgTipsPerShift = shifts.isEmpty ? 0.0 : totalTips / shifts.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIPS ANALYSIS',
              style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Cash', style: AppTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(currencyFormat.format(totalCashTips),
                        style: AppTheme.moneySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Credit', style: AppTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(currencyFormat.format(totalCreditTips),
                        style: AppTheme.moneySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Total Tips', style: AppTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(currencyFormat.format(totalTips),
                        style: AppTheme.moneySmall
                            .copyWith(color: AppTheme.primaryGreen)),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: AppTheme.cardBackgroundLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Tips % of Income', style: AppTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text('${tipsPercentage.toStringAsFixed(1)}%',
                      style: AppTheme.titleMedium),
                ],
              ),
              Column(
                children: [
                  Text('Avg Tips/Shift', style: AppTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(currencyFormat.format(avgTipsPerShift),
                      style: AppTheme.titleMedium),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hourly Rate Analysis
  Widget _buildHourlyRateAnalysis(List shifts, NumberFormat currencyFormat) {
    final totalIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final totalHours = shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);
    final effectiveRate = totalHours > 0 ? totalIncome / totalHours : 0.0;

    // Base rate average
    final avgBaseRate = shifts.isEmpty
        ? 0.0
        : shifts.fold(0.0, (sum, s) => sum + s.hourlyRate) / shifts.length;

    // Best paying job by effective rate
    final jobRates = <String, Map<String, double>>{};
    for (final shift in shifts) {
      final jobType = shift.jobType ?? 'Unknown';
      if (!jobRates.containsKey(jobType)) {
        jobRates[jobType] = {'income': 0.0, 'hours': 0.0};
      }
      jobRates[jobType]!['income'] =
          jobRates[jobType]!['income']! + shift.totalIncome;
      jobRates[jobType]!['hours'] =
          jobRates[jobType]!['hours']! + shift.hoursWorked;
    }

    final jobEffectiveRates = jobRates.map((key, value) {
      final rate =
          value['hours']! > 0 ? value['income']! / value['hours']! : 0.0;
      return MapEntry(key, rate);
    });

    final bestPayingJob = jobEffectiveRates.entries.isEmpty
        ? null
        : jobEffectiveRates.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOURLY RATE ANALYSIS',
              style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.attach_money,
                        color: AppTheme.primaryGreen, size: 32),
                    const SizedBox(height: 8),
                    Text('Effective Rate', style: AppTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text('${currencyFormat.format(effectiveRate)}/hr',
                        style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.schedule,
                        color: AppTheme.textSecondary, size: 32),
                    const SizedBox(height: 8),
                    Text('Base Rate', style: AppTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text('${currencyFormat.format(avgBaseRate)}/hr',
                        style: AppTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          if (bestPayingJob != null) ...[
            Divider(height: 24, color: AppTheme.cardBackgroundLight),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 8),
                Text('Best: ${bestPayingJob.key}',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${currencyFormat.format(bestPayingJob.value)}/hr',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.primaryGreen)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Efficiency Metrics
  Widget _buildEfficiencyMetrics(List shifts, NumberFormat currencyFormat) {
    final totalIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final avgPerShift = shifts.isEmpty ? 0.0 : totalIncome / shifts.length;
    final totalHours = shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);

    // Shifts per week calculation
    if (shifts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = shifts.map((s) => s.date).toList()..sort();
    final firstShift = sortedDates.first;
    final lastShift = sortedDates.last;
    final daysDiff = lastShift.difference(firstShift).inDays + 1;
    final weeks = daysDiff / 7;
    final shiftsPerWeek = weeks > 0 ? shifts.length / weeks : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EFFICIENCY METRICS',
              style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildEfficiencyRow('Avg Income/Shift',
              currencyFormat.format(avgPerShift), Icons.trending_up),
          const SizedBox(height: 12),
          _buildEfficiencyRow('Total Hours',
              '${totalHours.toStringAsFixed(0)} hrs', Icons.schedule),
          const SizedBox(height: 12),
          _buildEfficiencyRow('Shifts per Week',
              shiftsPerWeek.toStringAsFixed(1), Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildEfficiencyRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTheme.bodyMedium)),
        Text(value,
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Goal Progress
  Widget _buildGoalProgress(List shifts, NumberFormat currencyFormat) {
    // This would integrate with your goals system
    // For now, showing a placeholder
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GOAL PROGRESS',
                  style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
              Icon(Icons.flag, color: AppTheme.accentOrange, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text('Connect your goals to see progress tracking here',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Set Goals'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  // Income Forecast
  Widget _buildIncomeForecast(
      List allShifts, List filteredShifts, NumberFormat currencyFormat) {
    if (filteredShifts.isEmpty) return const SizedBox.shrink();

    final totalIncome =
        filteredShifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final now = DateTime.now();

    // Calculate daily average
    final sortedDates = filteredShifts.map((s) => s.date).toList()..sort();
    final firstShift = sortedDates.first;
    final lastShift = sortedDates.last;
    final daysDiff = lastShift.difference(firstShift).inDays + 1;
    final dailyAvg = totalIncome / daysDiff;

    // Forecast for rest of month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = daysInMonth - now.day;
    final forecastedIncome = dailyAvg * remainingDays;

    // Year-over-year growth (if data exists)
    final lastYearShifts = allShifts
        .where((s) => s.date.year == now.year - 1 && s.date.month == now.month)
        .toList();
    final lastYearTotal =
        lastYearShifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final yoyGrowth = lastYearTotal > 0
        ? ((totalIncome - lastYearTotal) / lastYearTotal * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentBlue.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text('INCOME FORECAST',
                  style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Projected End of Month', style: AppTheme.labelSmall),
          const SizedBox(height: 4),
          Text(currencyFormat.format(totalIncome + forecastedIncome),
              style:
                  AppTheme.moneyLarge.copyWith(color: AppTheme.primaryGreen)),
          const SizedBox(height: 12),
          Text('Based on ${currencyFormat.format(dailyAvg)}/day average',
              style:
                  AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
          if (lastYearTotal > 0) ...[
            Divider(height: 24, color: AppTheme.cardBackgroundLight),
            Row(
              children: [
                Text('YoY Growth: ', style: AppTheme.bodyMedium),
                Text(
                  '${yoyGrowth >= 0 ? '+' : ''}${yoyGrowth.toStringAsFixed(1)}%',
                  style: AppTheme.bodyMedium.copyWith(
                    color: yoyGrowth >= 0
                        ? AppTheme.primaryGreen
                        : AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Income Sources Breakdown
  Widget _buildIncomeSourcesBreakdown(
      List shifts, NumberFormat currencyFormat) {
    final totalHourlyWages =
        shifts.fold(0.0, (sum, s) => sum + (s.hourlyRate * s.hoursWorked));
    final totalTips =
        shifts.fold(0.0, (sum, s) => sum + s.cashTips + s.creditTips);
    final totalCommission =
        shifts.fold(0.0, (sum, s) => sum + (s.commission ?? 0.0));
    final totalOvertime = shifts.fold(
        0.0, (sum, s) => sum + ((s.overtimeHours ?? 0.0) * s.hourlyRate * 0.5));
    final totalIncome =
        totalHourlyWages + totalTips + totalCommission + totalOvertime;

    if (totalIncome == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INCOME SOURCES',
              style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildIncomeSourceRow('Hourly Wages', totalHourlyWages, totalIncome,
              currencyFormat, AppTheme.primaryGreen),
          const SizedBox(height: 8),
          _buildIncomeSourceRow('Tips', totalTips, totalIncome, currencyFormat,
              AppTheme.accentBlue),
          if (totalCommission > 0) ...[
            const SizedBox(height: 8),
            _buildIncomeSourceRow('Commission', totalCommission, totalIncome,
                currencyFormat, AppTheme.accentOrange),
          ],
          if (totalOvertime > 0) ...[
            const SizedBox(height: 8),
            _buildIncomeSourceRow('Overtime', totalOvertime, totalIncome,
                currencyFormat, AppTheme.accentPurple),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeSourceRow(String label, double amount, double total,
      NumberFormat currencyFormat, Color color) {
    final percentage = (amount / total * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodyMedium),
            Text('${currencyFormat.format(amount)} ($percentage%)',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: amount / total,
          backgroundColor: AppTheme.cardBackgroundLight,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
