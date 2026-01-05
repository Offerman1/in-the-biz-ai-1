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
  // SHIFT ACTIONS
  // ============================================

  /// Create a new shift with all industry-specific fields
  Future<Shift> createShift({
    required String jobId,
    required DateTime date,
    double cashTips = 0,
    double creditTips = 0,
    double hoursWorked = 0,
    double hourlyRate = 0,
    String? startTime,
    String? endTime,
    String? eventName,
    String? hostess,
    int? guestCount,
    String? location,
    String? clientName,
    String? projectName,
    double? commission,
    double? mileage,
    double? flatRate,
    double? overtimeHours,
    String? notes,
    double? salesAmount,
    double? tipoutPercent,
    double? additionalTipout,
    String? additionalTipoutNote,
    double? eventCost,
    // Rideshare & Delivery
    int? ridesCount,
    int? deliveriesCount,
    double? deadMiles,
    double? fuelCost,
    double? tollsParking,
    double? surgeMultiplier,
    double? acceptanceRate,
    double? baseFare,
    // Music & Entertainment
    String? gigType,
    double? setupHours,
    double? performanceHours,
    double? breakdownHours,
    String? equipmentUsed,
    double? equipmentRentalCost,
    double? crewPayment,
    double? merchSales,
    int? audienceSize,
    // Artist & Crafts
    int? piecesCreated,
    int? piecesSold,
    double? materialsCost,
    double? salePrice,
    double? venueCommissionPercent,
    // Retail/Sales
    int? itemsSold,
    int? transactionsCount,
    int? upsellsCount,
    double? upsellsAmount,
    int? returnsCount,
    double? returnsAmount,
    double? shrinkAmount,
    String? department,
    // Salon/Spa
    String? serviceType,
    int? servicesCount,
    double? productSales,
    double? repeatClientPercent,
    double? chairRental,
    int? newClientsCount,
    int? returningClientsCount,
    int? walkinCount,
    int? appointmentCount,
    // Hospitality
    String? roomType,
    int? roomsCleaned,
    double? qualityScore,
    String? shiftType,
    int? roomUpgrades,
    int? guestsCheckedIn,
    int? carsParked,
    // Healthcare
    int? patientCount,
    double? shiftDifferential,
    double? onCallHours,
    int? proceduresCount,
    String? specialization,
    // Fitness
    int? sessionsCount,
    String? sessionType,
    int? classSize,
    double? retentionRate,
    int? cancellationsCount,
    double? packageSales,
    double? supplementSales,
    // Construction/Trades
    double? laborCost,
    double? subcontractorCost,
    double? squareFootage,
    double? weatherDelayHours,
    // Freelancer
    int? revisionsCount,
    String? clientType,
    double? expenses,
    double? billableHours,
    // Restaurant Additional
    String? tableSection,
    double? cashSales,
    double? cardSales,
  }) async {
    final shift = Shift(
      id: const Uuid().v4(),
      date: date,
      cashTips: cashTips,
      creditTips: creditTips,
      hoursWorked: hoursWorked,
      hourlyRate: hourlyRate,
      startTime: startTime,
      endTime: endTime,
      eventName: eventName,
      hostess: hostess,
      guestCount: guestCount,
      location: location,
      clientName: clientName,
      projectName: projectName,
      commission: commission,
      mileage: mileage,
      flatRate: flatRate,
      overtimeHours: overtimeHours,
      notes: notes,
      jobId: jobId,
      salesAmount: salesAmount,
      tipoutPercent: tipoutPercent,
      additionalTipout: additionalTipout,
      additionalTipoutNote: additionalTipoutNote,
      eventCost: eventCost,
      // Rideshare & Delivery
      ridesCount: ridesCount,
      deliveriesCount: deliveriesCount,
      deadMiles: deadMiles,
      fuelCost: fuelCost,
      tollsParking: tollsParking,
      surgeMultiplier: surgeMultiplier,
      acceptanceRate: acceptanceRate,
      baseFare: baseFare,
      // Music & Entertainment
      gigType: gigType,
      setupHours: setupHours,
      performanceHours: performanceHours,
      breakdownHours: breakdownHours,
      equipmentUsed: equipmentUsed,
      equipmentRentalCost: equipmentRentalCost,
      crewPayment: crewPayment,
      merchSales: merchSales,
      audienceSize: audienceSize,
      // Artist & Crafts
      piecesCreated: piecesCreated,
      piecesSold: piecesSold,
      materialsCost: materialsCost,
      salePrice: salePrice,
      venueCommissionPercent: venueCommissionPercent,
      // Retail/Sales
      itemsSold: itemsSold,
      transactionsCount: transactionsCount,
      upsellsCount: upsellsCount,
      upsellsAmount: upsellsAmount,
      returnsCount: returnsCount,
      returnsAmount: returnsAmount,
      shrinkAmount: shrinkAmount,
      department: department,
      // Salon/Spa
      serviceType: serviceType,
      servicesCount: servicesCount,
      productSales: productSales,
      repeatClientPercent: repeatClientPercent,
      chairRental: chairRental,
      newClientsCount: newClientsCount,
      returningClientsCount: returningClientsCount,
      walkinCount: walkinCount,
      appointmentCount: appointmentCount,
      // Hospitality
      roomType: roomType,
      roomsCleaned: roomsCleaned,
      qualityScore: qualityScore,
      shiftType: shiftType,
      roomUpgrades: roomUpgrades,
      guestsCheckedIn: guestsCheckedIn,
      carsParked: carsParked,
      // Healthcare
      patientCount: patientCount,
      shiftDifferential: shiftDifferential,
      onCallHours: onCallHours,
      proceduresCount: proceduresCount,
      specialization: specialization,
      // Fitness
      sessionsCount: sessionsCount,
      sessionType: sessionType,
      classSize: classSize,
      retentionRate: retentionRate,
      cancellationsCount: cancellationsCount,
      packageSales: packageSales,
      supplementSales: supplementSales,
      // Construction/Trades
      laborCost: laborCost,
      subcontractorCost: subcontractorCost,
      squareFootage: squareFootage,
      weatherDelayHours: weatherDelayHours,
      // Freelancer
      revisionsCount: revisionsCount,
      clientType: clientType,
      expenses: expenses,
      billableHours: billableHours,
      // Restaurant Additional
      tableSection: tableSection,
      cashSales: cashSales,
      cardSales: cardSales,
    );

    await _db.saveShift(shift);
    return shift;
  }

  /// Update an existing shift
  Future<Shift> updateShift(Shift shift) async {
    await _db.updateShift(shift);
    return shift;
  }

  /// Delete a shift
  Future<void> deleteShift(String shiftId) async {
    await _db.deleteShift(shiftId);
  }

  /// Get shift by ID
  Future<Shift?> getShiftById(String shiftId) async {
    final shifts = await _db.getShifts();
    try {
      return shifts.firstWhere((s) => s.id == shiftId);
    } catch (e) {
      return null;
    }
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

  // ============================================
  // INVOICE QUERIES
  // ============================================

  /// Get all invoices for the user
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _db.supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .order('invoice_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get invoices by client name
  Future<List<Map<String, dynamic>>> getInvoicesByClient(
      String clientName) async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _db.supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .ilike('client_name', '%$clientName%')
        .order('invoice_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get total invoice amount for a period
  Future<Map<String, dynamic>> getInvoiceTotals(
      {String period = 'year'}) async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null)
      return {'total': 0, 'count': 0, 'paid': 0, 'pending': 0};

    final now = DateTime.now();
    DateTime startDate;
    switch (period) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
      default:
        startDate = DateTime(now.year, 1, 1);
    }

    final response = await _db.supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .gte('invoice_date', startDate.toIso8601String().split('T')[0]);

    final invoices = List<Map<String, dynamic>>.from(response);
    final total = invoices.fold<double>(
        0, (sum, i) => sum + (i['total_amount'] as num? ?? 0).toDouble());
    final paid = invoices.where((i) => i['status'] == 'paid').fold<double>(
        0, (sum, i) => sum + (i['total_amount'] as num? ?? 0).toDouble());
    final pending = total - paid;

    return {
      'total': total,
      'paid': paid,
      'pending': pending,
      'count': invoices.length,
      'period': period,
    };
  }

  // ============================================
  // RECEIPT QUERIES
  // ============================================

  /// Get all receipts for the user
  Future<List<Map<String, dynamic>>> getReceipts() async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _db.supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .order('receipt_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get receipts by expense category
  Future<List<Map<String, dynamic>>> getReceiptsByCategory(
      String category) async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _db.supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .eq('expense_category', category)
        .order('receipt_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get receipts by vendor
  Future<List<Map<String, dynamic>>> getReceiptsByVendor(String vendor) async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _db.supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .ilike('vendor_name', '%$vendor%')
        .order('receipt_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get total expenses for a period
  Future<Map<String, dynamic>> getExpenseTotals(
      {String period = 'year'}) async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return {'total': 0, 'deductible': 0, 'count': 0};

    final now = DateTime.now();
    DateTime startDate;
    switch (period) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
      default:
        startDate = DateTime(now.year, 1, 1);
    }

    final response = await _db.supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .gte('receipt_date', startDate.toIso8601String().split('T')[0]);

    final receipts = List<Map<String, dynamic>>.from(response);
    final total = receipts.fold<double>(
        0, (sum, r) => sum + (r['total_amount'] as num? ?? 0).toDouble());
    final deductible = receipts
        .where((r) => r['is_tax_deductible'] == true)
        .fold<double>(
            0, (sum, r) => sum + (r['total_amount'] as num? ?? 0).toDouble());

    // Group by category
    final byCategory = <String, double>{};
    for (final r in receipts) {
      final category = r['expense_category'] as String? ?? 'Other';
      byCategory[category] = (byCategory[category] ?? 0) +
          (r['total_amount'] as num? ?? 0).toDouble();
    }

    return {
      'total': total,
      'deductible': deductible,
      'count': receipts.length,
      'byCategory': byCategory,
      'period': period,
    };
  }

  /// Get tax deductible expenses summary
  Future<Map<String, dynamic>> getTaxDeductibleExpenses() async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return {'total': 0, 'categories': {}};

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final response = await _db.supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .eq('is_tax_deductible', true)
        .gte('receipt_date', yearStart.toIso8601String().split('T')[0]);

    final receipts = List<Map<String, dynamic>>.from(response);
    final total = receipts.fold<double>(
        0, (sum, r) => sum + (r['total_amount'] as num? ?? 0).toDouble());

    // Group by Schedule C category
    final byQuickbooksCategory = <String, double>{};
    for (final r in receipts) {
      final category = r['quickbooks_category'] as String? ?? 'Other Expenses';
      byQuickbooksCategory[category] = (byQuickbooksCategory[category] ?? 0) +
          (r['total_amount'] as num? ?? 0).toDouble();
    }

    return {
      'total': total,
      'count': receipts.length,
      'categories': byQuickbooksCategory,
      'year': now.year,
    };
  }

  // ============================================
  // PAYCHECK QUERIES
  // ============================================

  /// Get all paychecks for the user
  Future<List<Map<String, dynamic>>> getPaychecks() async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _db.supabase
        .from('paychecks')
        .select()
        .eq('user_id', userId)
        .order('pay_period_end', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get YTD paycheck totals
  Future<Map<String, dynamic>> getPaycheckYTDTotals() async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null)
      return {
        'ytdGross': 0,
        'ytdFederalTax': 0,
        'ytdStateTax': 0,
        'ytdFica': 0,
        'ytdMedicare': 0,
        'ytdNet': 0,
        'count': 0
      };

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final response = await _db.supabase
        .from('paychecks')
        .select()
        .eq('user_id', userId)
        .gte('pay_period_start', yearStart.toIso8601String().split('T')[0])
        .order('pay_period_end', ascending: false)
        .limit(1);

    final paychecks = List<Map<String, dynamic>>.from(response);

    if (paychecks.isEmpty) {
      return {
        'ytdGross': 0,
        'ytdFederalTax': 0,
        'ytdStateTax': 0,
        'ytdFica': 0,
        'ytdMedicare': 0,
        'ytdNet': 0,
        'count': 0
      };
    }

    // Most recent paycheck should have YTD data
    final latest = paychecks.first;
    final ytdGross = (latest['ytd_gross'] as num?)?.toDouble() ?? 0;
    final ytdFederal = (latest['ytd_federal_tax'] as num?)?.toDouble() ?? 0;
    final ytdState = (latest['ytd_state_tax'] as num?)?.toDouble() ?? 0;
    final ytdFica = (latest['ytd_fica'] as num?)?.toDouble() ?? 0;
    final ytdMedicare = (latest['ytd_medicare'] as num?)?.toDouble() ?? 0;

    return {
      'ytdGross': ytdGross,
      'ytdFederalTax': ytdFederal,
      'ytdStateTax': ytdState,
      'ytdFica': ytdFica,
      'ytdMedicare': ytdMedicare,
      'ytdTotalTaxes': ytdFederal + ytdState + ytdFica + ytdMedicare,
      'ytdNet': ytdGross - (ytdFederal + ytdState + ytdFica + ytdMedicare),
      'year': now.year,
    };
  }

  /// Get Reality Check summary (compare app-tracked vs paycheck income)
  Future<Map<String, dynamic>> getRealityCheckSummary() async {
    final userId = _db.supabase.auth.currentUser?.id;
    if (userId == null) return {'hasGaps': false, 'totalGap': 0, 'gapCount': 0};

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final response = await _db.supabase
        .from('paychecks')
        .select()
        .eq('user_id', userId)
        .gte('pay_period_start', yearStart.toIso8601String().split('T')[0]);

    final paychecks = List<Map<String, dynamic>>.from(response);

    double totalGap = 0;
    int gapCount = 0;

    for (final p in paychecks) {
      final gap = (p['unreported_gap'] as num?)?.toDouble() ?? 0;
      if (gap.abs() > 50) {
        // $50 threshold
        totalGap += gap;
        gapCount++;
      }
    }

    return {
      'hasGaps': gapCount > 0,
      'totalGap': totalGap,
      'gapCount': gapCount,
      'paycheckCount': paychecks.length,
      'year': now.year,
    };
  }

  // ============================================
  // COMBINED FINANCIAL SUMMARY
  // ============================================

  /// Get comprehensive financial summary for AI context
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final invoiceTotals = await getInvoiceTotals();
    final expenseTotals = await getExpenseTotals();
    final paycheckYTD = await getPaycheckYTDTotals();
    final deductibles = await getTaxDeductibleExpenses();
    final realityCheck = await getRealityCheckSummary();

    return {
      'invoices': invoiceTotals,
      'expenses': expenseTotals,
      'paychecks': paycheckYTD,
      'deductibles': deductibles,
      'realityCheck': realityCheck,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
