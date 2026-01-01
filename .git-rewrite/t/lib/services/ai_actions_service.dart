import '../models/shift.dart';
import '../models/job.dart';
import '../models/job_template.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../services/tax_service.dart';
import '../services/export_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// AI Actions Service
/// This is the bridge between the AI assistant and all app features.
/// The AI can call these actions to manipulate data and answer user questions.
class AIActionsService {
  final DatabaseService _db = DatabaseService();
  final _currencyFormat = NumberFormat.simpleCurrency();

  // ============================================
  // SHIFT QUERIES
  // ============================================

  /// Get all shifts for context
  Future<List<Shift>> getAllShifts() async {
    return await _db.getShifts();
  }

  /// Get shifts for a date range
  Future<List<Shift>> getShiftsInRange(DateTime start, DateTime end) async {
    return await _db.getShiftsByDateRange(start, end);
  }

  /// Get total income for current week
  Future<Map<String, dynamic>> getWeeklyIncome() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final shifts = await _db.getShiftsByDateRange(weekStart, weekEnd);
    final total = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final tips = shifts.fold(0.0, (sum, s) => sum + s.totalTips);
    final hours = shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);

    return {
      'total': total,
      'tips': tips,
      'hours': hours,
      'shiftCount': shifts.length,
      'avgHourly': hours > 0 ? total / hours : 0,
      'period': 'This Week',
    };
  }

  /// Get total income for current month
  Future<Map<String, dynamic>> getMonthlyIncome() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final shifts = await _db.getShiftsByDateRange(monthStart, monthEnd);
    final total = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final tips = shifts.fold(0.0, (sum, s) => sum + s.totalTips);
    final hours = shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);

    return {
      'total': total,
      'tips': tips,
      'hours': hours,
      'shiftCount': shifts.length,
      'avgHourly': hours > 0 ? total / hours : 0,
      'period': DateFormat('MMMM yyyy').format(now),
    };
  }

  /// Get total income for current year
  Future<Map<String, dynamic>> getYearlyIncome() async {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);

    final shifts = await _db.getShiftsByDateRange(yearStart, yearEnd);
    final total = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final tips = shifts.fold(0.0, (sum, s) => sum + s.totalTips);
    final hours = shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);

    return {
      'total': total,
      'tips': tips,
      'hours': hours,
      'shiftCount': shifts.length,
      'avgHourly': hours > 0 ? total / hours : 0,
      'period': now.year.toString(),
    };
  }

  /// Get income for a specific event/party
  Future<Map<String, dynamic>> getEventIncome(String eventName) async {
    final shifts = await _db.getShiftsByEventName(eventName);
    final total = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
    final tips = shifts.fold(0.0, (sum, s) => sum + s.totalTips);

    return {
      'eventName': eventName,
      'total': total,
      'tips': tips,
      'shiftCount': shifts.length,
      'shifts': shifts
          .map((s) => {
                'date': DateFormat('MMM d, yyyy').format(s.date),
                'income': s.totalIncome,
                'tips': s.totalTips,
              })
          .toList(),
    };
  }

  /// Get best performing days
  Future<List<Map<String, dynamic>>> getBestDays({int limit = 5}) async {
    final shifts = await _db.getShifts();

    // Group by weekday
    final dayTotals = <int, List<double>>{};
    for (final shift in shifts) {
      final weekday = shift.date.weekday;
      dayTotals.putIfAbsent(weekday, () => []).add(shift.totalIncome);
    }

    // Calculate averages
    final dayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayAverages = dayTotals.entries.map((e) {
      final avg = e.value.fold(0.0, (a, b) => a + b) / e.value.length;
      return {
        'day': dayNames[e.key],
        'avgIncome': avg,
        'shiftCount': e.value.length,
      };
    }).toList();

    dayAverages.sort((a, b) =>
        (b['avgIncome'] as double).compareTo(a['avgIncome'] as double));
    return dayAverages.take(limit).toList();
  }

  // ============================================
  // JOB ACTIONS
  // ============================================

  /// Get all jobs
  Future<List<Job>> getJobs() async {
    final response = await _db.getJobs();
    return response.map((j) => Job.fromSupabase(j)).toList();
  }

  /// Create a new job
  Future<Job> createJob({
    required String name,
    String? industry,
    double hourlyRate = 0,
    String color = '#00D632',
    bool isDefault = false,
    JobTemplate? template,
  }) async {
    final job = Job(
      id: const Uuid().v4(),
      userId: '', // Will be set by database
      name: name,
      industry: industry,
      hourlyRate: hourlyRate,
      color: color,
      isDefault: isDefault,
      template: template,
    );
    final response = await _db.createJob(job);
    return response;
  }

  /// Get income breakdown by job
  Future<Map<String, double>> getIncomeByJob() async {
    return await _db.getIncomeByJob();
  }

  // ============================================
  // GOAL ACTIONS
  // ============================================

  /// Get all goals with progress
  Future<List<Map<String, dynamic>>> getGoalsWithProgress() async {
    final goals = await _db.getGoals();
    final result = <Map<String, dynamic>>[];

    for (final goalData in goals) {
      final goal = Goal.fromSupabase(goalData);

      // Get current income for goal period
      double currentIncome = 0;
      final now = DateTime.now();

      switch (goal.type) {
        case 'weekly':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final shifts = await _db.getShiftsByDateRange(weekStart, now);
          currentIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
          break;
        case 'monthly':
          final monthStart = DateTime(now.year, now.month, 1);
          final shifts = await _db.getShiftsByDateRange(monthStart, now);
          currentIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
          break;
        case 'yearly':
          final yearStart = DateTime(now.year, 1, 1);
          final shifts = await _db.getShiftsByDateRange(yearStart, now);
          currentIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
          break;
        case 'custom':
          if (goal.startDate != null) {
            final shifts = await _db.getShiftsByDateRange(
              goal.startDate!,
              goal.endDate ?? now,
            );
            currentIncome = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
          }
          break;
      }

      result.add({
        'goal': goal,
        'currentIncome': currentIncome,
        'progress': goal.getProgress(currentIncome),
        'progressPercent': goal.getProgressPercent(currentIncome),
        'remaining': goal.getRemaining(currentIncome),
        'isComplete': goal.isComplete(currentIncome),
      });
    }

    return result;
  }

  /// Create a new goal
  Future<Goal> createGoal({
    required String type,
    required double targetAmount,
    double? targetHours,
    String? jobId,
  }) async {
    final response = await _db.createGoal(
      type: type,
      targetAmount: targetAmount,
      targetHours: targetHours,
      jobId: jobId,
    );
    return Goal.fromSupabase(response);
  }

  // ============================================
  // TAX ACTIONS
  // ============================================

  /// Get tax estimate for current year
  Future<Map<String, dynamic>> getTaxEstimate() async {
    final yearlyData = await getYearlyIncome();
    final settings = await _db.getUserSettings();

    final estimate = TaxEstimationService.calculateFederalTax(
      totalIncome: yearlyData['total'],
      filingStatus: settings['filing_status'] ?? 'single',
      additionalIncome: settings['additional_income'] ?? 0,
      deductions: settings['deductions'] ?? 0,
      dependents: settings['dependents'] ?? 0,
      isSelfEmployed: true, // Assume tips are self-employment
    );

    return {
      'grossIncome': estimate.grossIncome,
      'taxableIncome': estimate.taxableIncome,
      'federalTax': estimate.federalTax,
      'selfEmploymentTax': estimate.selfEmploymentTax,
      'totalTax': estimate.totalTax,
      'effectiveRate': estimate.effectiveRatePercent,
      'monthlyEstimate': estimate.monthlyEstimate,
      'quarterlyEstimate': estimate.quarterlyEstimate,
    };
  }

  /// Get projected year-end income and tax
  Future<Map<String, dynamic>> getProjectedTax() async {
    final yearlyData = await getYearlyIncome();
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    final projectedIncome = TaxEstimationService.projectYearEndIncome(
      currentIncome: yearlyData['total'],
      daysElapsed: dayOfYear,
    );

    final settings = await _db.getUserSettings();
    final estimate = TaxEstimationService.calculateFederalTax(
      totalIncome: projectedIncome,
      filingStatus: settings['filing_status'] ?? 'single',
      additionalIncome: settings['additional_income'] ?? 0,
      deductions: settings['deductions'] ?? 0,
      dependents: settings['dependents'] ?? 0,
      isSelfEmployed: true,
    );

    return {
      'currentIncome': yearlyData['total'],
      'projectedIncome': projectedIncome,
      'projectedTax': estimate.totalTax,
      'effectiveRate': estimate.effectiveRatePercent,
      'quarterlyPayment': estimate.quarterlyEstimate,
    };
  }

  // ============================================
  // EXPORT ACTIONS
  // ============================================

  /// Generate CSV export
  Future<String> exportToCSV({DateTime? startDate, DateTime? endDate}) async {
    final shifts = await _db.getShifts();

    List<Shift> filteredShifts = shifts;
    if (startDate != null && endDate != null) {
      filteredShifts = shifts
          .where((s) =>
              s.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              s.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    return ExportService.generateSummaryCSV(
      shifts: filteredShifts,
      startDate: startDate ?? filteredShifts.last.date,
      endDate: endDate ?? filteredShifts.first.date,
    );
  }

  /// Generate JSON export
  Future<String> exportToJSON() async {
    final shifts = await _db.getShifts();
    return ExportService.generateShiftsJSON(shifts);
  }

  // ============================================
  // YEAR OVER YEAR
  // ============================================

  /// Get year-over-year comparison
  Future<Map<String, dynamic>> getYearOverYearComparison() async {
    final yearlyTotals = await _db.getYearlyTotals();
    final years = yearlyTotals.keys.toList()..sort();

    if (years.length < 2) {
      return {
        'hasComparison': false,
        'message': 'Need at least 2 years of data for comparison',
        'years': yearlyTotals,
      };
    }

    final currentYear = years.last;
    final previousYear = years[years.length - 2];

    final currentTotal = yearlyTotals[currentYear] ?? 0;
    final previousTotal = yearlyTotals[previousYear] ?? 0;

    final difference = currentTotal - previousTotal;
    final percentChange =
        previousTotal > 0 ? (difference / previousTotal) * 100 : 0.0;

    return {
      'hasComparison': true,
      'currentYear': currentYear,
      'currentTotal': currentTotal,
      'previousYear': previousYear,
      'previousTotal': previousTotal,
      'difference': difference,
      'percentChange': percentChange,
      'isUp': difference > 0,
      'allYears': yearlyTotals,
    };
  }

  // ============================================
  // CONTEXT BUILDER
  // ============================================

  /// Build context string for AI with user's data
  Future<String> buildContextForAI() async {
    final weekly = await getWeeklyIncome();
    final monthly = await getMonthlyIncome();
    final yearly = await getYearlyIncome();
    final jobs = await getJobs();
    final goals = await getGoalsWithProgress();
    final bestDays = await getBestDays(limit: 3);

    final buffer = StringBuffer();
    buffer.writeln('=== USER CONTEXT ===');
    buffer.writeln('');
    buffer.writeln('INCOME SUMMARY:');
    buffer.writeln(
        '- This Week: ${_currencyFormat.format(weekly['total'])} (${weekly['shiftCount']} shifts)');
    buffer.writeln(
        '- This Month: ${_currencyFormat.format(monthly['total'])} (${monthly['shiftCount']} shifts)');
    buffer.writeln(
        '- This Year: ${_currencyFormat.format(yearly['total'])} (${yearly['shiftCount']} shifts)');
    buffer.writeln('');

    if (jobs.isNotEmpty) {
      buffer.writeln('JOBS:');
      for (final job in jobs) {
        buffer.writeln(
            '- ${job.name} (${job.industry ?? "General"}) - \$${job.hourlyRate}/hr${job.isDefault ? " [DEFAULT]" : ""}');
      }
      buffer.writeln('');
    }

    if (goals.isNotEmpty) {
      buffer.writeln('GOALS:');
      for (final g in goals) {
        final goal = g['goal'] as Goal;
        buffer.writeln(
            '- ${goal.type.toUpperCase()}: ${_currencyFormat.format(goal.targetAmount)} - ${g['progressPercent']} complete');
      }
      buffer.writeln('');
    }

    if (bestDays.isNotEmpty) {
      buffer.writeln('BEST DAYS:');
      for (final day in bestDays) {
        buffer.writeln(
            '- ${day['day']}: avg ${_currencyFormat.format(day['avgIncome'])}');
      }
    }

    return buffer.toString();
  }

  /// Get formatted response for common queries
  String formatIncomeResponse(Map<String, dynamic> data) {
    return '''
${data['period']} Summary:
💰 Total Income: ${_currencyFormat.format(data['total'])}
💵 Tips: ${_currencyFormat.format(data['tips'])}
⏰ Hours: ${(data['hours'] as double).toStringAsFixed(1)}
📊 Avg/Hour: ${_currencyFormat.format(data['avgHourly'])}
📅 Shifts: ${data['shiftCount']}
''';
  }
}
