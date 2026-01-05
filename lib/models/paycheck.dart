import 'package:uuid/uuid.dart';

/// Paycheck model for W-2 worker income tracking
/// Stores pay stub data including YTD totals for tax estimation
class Paycheck {
  final String id;
  final String userId;

  // Pay Period
  final DateTime payPeriodStart;
  final DateTime payPeriodEnd;
  final DateTime? payDate;

  // Earnings
  final double? grossPay;
  final double? regularHours;
  final double? overtimeHours;
  final double? hourlyRate;
  final double? overtimeRate;

  // Taxes & Deductions
  final double? federalTax;
  final double? stateTax;
  final double? ficaTax;
  final double? medicareTax;
  final double? otherDeductions;
  final String? otherDeductionsDescription;

  // Net Pay
  final double? netPay;

  // Year-to-Date Totals (CRITICAL for tax estimation)
  final double? ytdGross;
  final double? ytdFederalTax;
  final double? ytdStateTax;
  final double? ytdFica;
  final double? ytdMedicare;

  // Pay Stub Format
  final String?
      payrollProvider; // ADP, Gusto, Paychex, QuickBooks, Generic, Other
  final String? employerName;

  // Currency
  final String currency;

  // AI Metadata
  final String? imageUrl;
  final Map<String, dynamic>? aiConfidenceScores;
  final Map<String, dynamic>? rawAiResponse;

  // Reality Check Metadata
  final bool realityCheckRun;
  final double? appTrackedIncome; // Sum of shifts in this pay period
  final double? w2ReportedIncome; // Gross pay from this stub
  final double? unreportedGap; // Difference (for tax warnings)

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Paycheck({
    String? id,
    required this.userId,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    this.payDate,
    this.grossPay,
    this.regularHours,
    this.overtimeHours,
    this.hourlyRate,
    this.overtimeRate,
    this.federalTax,
    this.stateTax,
    this.ficaTax,
    this.medicareTax,
    this.otherDeductions,
    this.otherDeductionsDescription,
    this.netPay,
    this.ytdGross,
    this.ytdFederalTax,
    this.ytdStateTax,
    this.ytdFica,
    this.ytdMedicare,
    this.payrollProvider,
    this.employerName,
    this.currency = 'USD',
    this.imageUrl,
    this.aiConfidenceScores,
    this.rawAiResponse,
    this.realityCheckRun = false,
    this.appTrackedIncome,
    this.w2ReportedIncome,
    this.unreportedGap,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create Paycheck from database JSON
  factory Paycheck.fromJson(Map<String, dynamic> json) {
    return Paycheck(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      payPeriodStart: DateTime.parse(json['pay_period_start'] as String),
      payPeriodEnd: DateTime.parse(json['pay_period_end'] as String),
      payDate: json['pay_date'] != null
          ? DateTime.parse(json['pay_date'] as String)
          : null,
      grossPay: (json['gross_pay'] as num?)?.toDouble(),
      regularHours: (json['regular_hours'] as num?)?.toDouble(),
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble(),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      overtimeRate: (json['overtime_rate'] as num?)?.toDouble(),
      federalTax: (json['federal_tax'] as num?)?.toDouble(),
      stateTax: (json['state_tax'] as num?)?.toDouble(),
      ficaTax: (json['fica_tax'] as num?)?.toDouble(),
      medicareTax: (json['medicare_tax'] as num?)?.toDouble(),
      otherDeductions: (json['other_deductions'] as num?)?.toDouble(),
      otherDeductionsDescription:
          json['other_deductions_description'] as String?,
      netPay: (json['net_pay'] as num?)?.toDouble(),
      ytdGross: (json['ytd_gross'] as num?)?.toDouble(),
      ytdFederalTax: (json['ytd_federal_tax'] as num?)?.toDouble(),
      ytdStateTax: (json['ytd_state_tax'] as num?)?.toDouble(),
      ytdFica: (json['ytd_fica'] as num?)?.toDouble(),
      ytdMedicare: (json['ytd_medicare'] as num?)?.toDouble(),
      payrollProvider: json['payroll_provider'] as String?,
      employerName: json['employer_name'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: json['image_url'] as String?,
      aiConfidenceScores: json['ai_confidence_scores'] as Map<String, dynamic>?,
      rawAiResponse: json['raw_ai_response'] as Map<String, dynamic>?,
      realityCheckRun: json['reality_check_run'] as bool? ?? false,
      appTrackedIncome: (json['app_tracked_income'] as num?)?.toDouble(),
      w2ReportedIncome: (json['w2_reported_income'] as num?)?.toDouble(),
      unreportedGap: (json['unreported_gap'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert Paycheck to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pay_period_start': payPeriodStart.toIso8601String().split('T')[0],
      'pay_period_end': payPeriodEnd.toIso8601String().split('T')[0],
      'pay_date': payDate?.toIso8601String().split('T')[0],
      'gross_pay': grossPay,
      'regular_hours': regularHours,
      'overtime_hours': overtimeHours,
      'hourly_rate': hourlyRate,
      'overtime_rate': overtimeRate,
      'federal_tax': federalTax,
      'state_tax': stateTax,
      'fica_tax': ficaTax,
      'medicare_tax': medicareTax,
      'other_deductions': otherDeductions,
      'other_deductions_description': otherDeductionsDescription,
      'net_pay': netPay,
      'ytd_gross': ytdGross,
      'ytd_federal_tax': ytdFederalTax,
      'ytd_state_tax': ytdStateTax,
      'ytd_fica': ytdFica,
      'ytd_medicare': ytdMedicare,
      'payroll_provider': payrollProvider,
      'employer_name': employerName,
      'currency': currency,
      'image_url': imageUrl,
      'ai_confidence_scores': aiConfidenceScores,
      'raw_ai_response': rawAiResponse,
      'reality_check_run': realityCheckRun,
      'app_tracked_income': appTrackedIncome,
      'w2_reported_income': w2ReportedIncome,
      'unreported_gap': unreportedGap,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with updated fields
  Paycheck copyWith({
    String? id,
    String? userId,
    DateTime? payPeriodStart,
    DateTime? payPeriodEnd,
    DateTime? payDate,
    double? grossPay,
    double? regularHours,
    double? overtimeHours,
    double? hourlyRate,
    double? overtimeRate,
    double? federalTax,
    double? stateTax,
    double? ficaTax,
    double? medicareTax,
    double? otherDeductions,
    String? otherDeductionsDescription,
    double? netPay,
    double? ytdGross,
    double? ytdFederalTax,
    double? ytdStateTax,
    double? ytdFica,
    double? ytdMedicare,
    String? payrollProvider,
    String? employerName,
    String? currency,
    String? imageUrl,
    Map<String, dynamic>? aiConfidenceScores,
    Map<String, dynamic>? rawAiResponse,
    bool? realityCheckRun,
    double? appTrackedIncome,
    double? w2ReportedIncome,
    double? unreportedGap,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Paycheck(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      payPeriodStart: payPeriodStart ?? this.payPeriodStart,
      payPeriodEnd: payPeriodEnd ?? this.payPeriodEnd,
      payDate: payDate ?? this.payDate,
      grossPay: grossPay ?? this.grossPay,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      federalTax: federalTax ?? this.federalTax,
      stateTax: stateTax ?? this.stateTax,
      ficaTax: ficaTax ?? this.ficaTax,
      medicareTax: medicareTax ?? this.medicareTax,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      otherDeductionsDescription:
          otherDeductionsDescription ?? this.otherDeductionsDescription,
      netPay: netPay ?? this.netPay,
      ytdGross: ytdGross ?? this.ytdGross,
      ytdFederalTax: ytdFederalTax ?? this.ytdFederalTax,
      ytdStateTax: ytdStateTax ?? this.ytdStateTax,
      ytdFica: ytdFica ?? this.ytdFica,
      ytdMedicare: ytdMedicare ?? this.ytdMedicare,
      payrollProvider: payrollProvider ?? this.payrollProvider,
      employerName: employerName ?? this.employerName,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      aiConfidenceScores: aiConfidenceScores ?? this.aiConfidenceScores,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      realityCheckRun: realityCheckRun ?? this.realityCheckRun,
      appTrackedIncome: appTrackedIncome ?? this.appTrackedIncome,
      w2ReportedIncome: w2ReportedIncome ?? this.w2ReportedIncome,
      unreportedGap: unreportedGap ?? this.unreportedGap,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate total taxes withheld
  double get totalTaxesWithheld {
    return (federalTax ?? 0) +
        (stateTax ?? 0) +
        (ficaTax ?? 0) +
        (medicareTax ?? 0);
  }

  /// Calculate YTD total taxes withheld
  double get ytdTotalTaxes {
    return (ytdFederalTax ?? 0) +
        (ytdStateTax ?? 0) +
        (ytdFica ?? 0) +
        (ytdMedicare ?? 0);
  }

  /// Get pay period duration in days
  int get payPeriodDays {
    return payPeriodEnd.difference(payPeriodStart).inDays + 1;
  }

  /// Determine pay frequency based on period length
  PayFrequency get payFrequency {
    final days = payPeriodDays;
    if (days <= 8) return PayFrequency.weekly;
    if (days <= 16) return PayFrequency.biweekly;
    if (days <= 17) return PayFrequency.semiMonthly;
    return PayFrequency.monthly;
  }

  /// Check if there's an unreported income gap
  bool get hasUnreportedGap {
    if (unreportedGap == null) return false;
    return unreportedGap!.abs() > 50; // $50 threshold
  }

  /// Get severity of unreported gap
  GapSeverity get gapSeverity {
    if (unreportedGap == null || unreportedGap!.abs() <= 50) {
      return GapSeverity.none;
    }
    if (unreportedGap!.abs() <= 200) return GapSeverity.low;
    if (unreportedGap!.abs() <= 500) return GapSeverity.medium;
    return GapSeverity.high;
  }
}

/// Pay frequency enum
enum PayFrequency {
  weekly('Weekly', 52),
  biweekly('Bi-weekly', 26),
  semiMonthly('Semi-monthly', 24),
  monthly('Monthly', 12);

  final String label;
  final int periodsPerYear;
  const PayFrequency(this.label, this.periodsPerYear);
}

/// Gap severity for Reality Check
enum GapSeverity {
  none,
  low,
  medium,
  high;

  String get message {
    switch (this) {
      case none:
        return 'No significant gap';
      case low:
        return 'Minor discrepancy - likely rounding';
      case medium:
        return 'Notable gap - review tip reporting';
      case high:
        return 'Significant gap - may affect taxes';
    }
  }
}

/// Common payroll providers
class PayrollProvider {
  static const String adp = 'ADP';
  static const String gusto = 'Gusto';
  static const String paychex = 'Paychex';
  static const String quickbooks = 'QuickBooks';
  static const String square = 'Square Payroll';
  static const String toast = 'Toast Payroll';
  static const String generic = 'Generic';
  static const String other = 'Other';

  static List<String> get all => [
        adp,
        gusto,
        paychex,
        quickbooks,
        square,
        toast,
        generic,
        other,
      ];
}
