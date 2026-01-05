/// Tax Estimation Service
/// Provides estimated tax calculations for service industry workers
/// Note: This is for estimation only - not tax advice!

class TaxEstimationService {
  // 2024 Federal Tax Brackets (Single)
  static const List<TaxBracket> _singleBrackets = [
    TaxBracket(min: 0, max: 11600, rate: 0.10),
    TaxBracket(min: 11600, max: 47150, rate: 0.12),
    TaxBracket(min: 47150, max: 100525, rate: 0.22),
    TaxBracket(min: 100525, max: 191950, rate: 0.24),
    TaxBracket(min: 191950, max: 243725, rate: 0.32),
    TaxBracket(min: 243725, max: 609350, rate: 0.35),
    TaxBracket(min: 609350, max: double.infinity, rate: 0.37),
  ];

  // 2024 Federal Tax Brackets (Married Filing Jointly)
  static const List<TaxBracket> _marriedJointBrackets = [
    TaxBracket(min: 0, max: 23200, rate: 0.10),
    TaxBracket(min: 23200, max: 94300, rate: 0.12),
    TaxBracket(min: 94300, max: 201050, rate: 0.22),
    TaxBracket(min: 201050, max: 383900, rate: 0.24),
    TaxBracket(min: 383900, max: 487450, rate: 0.32),
    TaxBracket(min: 487450, max: 731200, rate: 0.35),
    TaxBracket(min: 731200, max: double.infinity, rate: 0.37),
  ];

  // Standard Deductions 2024
  static const Map<String, double> _standardDeductions = {
    'single': 14600,
    'married_joint': 29200,
    'married_separate': 14600,
    'head_of_household': 21900,
  };

  // Self-employment tax rate (Social Security + Medicare)
  static const double _selfEmploymentRate = 0.153; // 15.3%
  static const double _selfEmploymentDeduction = 0.5; // Can deduct half

  /// Calculate estimated federal tax for the year
  static TaxEstimate calculateFederalTax({
    required double totalIncome,
    required String filingStatus,
    double additionalIncome = 0,
    double deductions = 0,
    int dependents = 0,
    bool isSelfEmployed = false,
  }) {
    // Total gross income
    double grossIncome = totalIncome + additionalIncome;

    // Self-employment tax (if applicable)
    double selfEmploymentTax = 0;
    if (isSelfEmployed) {
      selfEmploymentTax = grossIncome * _selfEmploymentRate;
      // Can deduct half of SE tax from income
      grossIncome -= selfEmploymentTax * _selfEmploymentDeduction;
    }

    // Standard deduction
    double standardDeduction = _standardDeductions[filingStatus] ?? 14600;

    // Dependent credits ($2000 per child under 17, $500 for other dependents)
    double dependentCredit = dependents * 2000;

    // Taxable income
    double taxableIncome = grossIncome - standardDeduction - deductions;
    if (taxableIncome < 0) taxableIncome = 0;

    // Get tax brackets based on filing status
    List<TaxBracket> brackets = filingStatus == 'married_joint'
        ? _marriedJointBrackets
        : _singleBrackets;

    // Calculate tax
    double federalTax = 0;
    double remainingIncome = taxableIncome;

    for (var bracket in brackets) {
      if (remainingIncome <= 0) break;

      double taxableInBracket = (remainingIncome > (bracket.max - bracket.min))
          ? (bracket.max - bracket.min)
          : remainingIncome;

      if (taxableIncome > bracket.min) {
        double amountInBracket =
            (taxableIncome > bracket.max ? bracket.max : taxableIncome) -
                bracket.min;
        if (amountInBracket > 0) {
          federalTax += amountInBracket * bracket.rate;
        }
      }
      remainingIncome -= taxableInBracket;
    }

    // Apply credits
    federalTax -= dependentCredit;
    if (federalTax < 0) federalTax = 0;

    // Total tax liability
    double totalTax = federalTax + selfEmploymentTax;

    // Effective tax rate
    double effectiveRate = grossIncome > 0 ? totalTax / grossIncome : 0;

    // Monthly and quarterly estimates
    double monthlyEstimate = totalTax / 12;
    double quarterlyEstimate = totalTax / 4;

    return TaxEstimate(
      grossIncome: totalIncome + additionalIncome,
      taxableIncome: taxableIncome,
      federalTax: federalTax,
      selfEmploymentTax: selfEmploymentTax,
      totalTax: totalTax,
      effectiveRate: effectiveRate,
      monthlyEstimate: monthlyEstimate,
      quarterlyEstimate: quarterlyEstimate,
      standardDeduction: standardDeduction,
      dependentCredits: dependentCredit,
    );
  }

  /// Project year-end income based on current earnings
  static double projectYearEndIncome({
    required double currentIncome,
    required int daysElapsed,
  }) {
    if (daysElapsed <= 0) return currentIncome;
    double dailyAverage = currentIncome / daysElapsed;
    return dailyAverage * 365;
  }

  /// Calculate quarterly estimated payment due
  static double calculateQuarterlyPayment(TaxEstimate estimate) {
    return estimate.quarterlyEstimate;
  }

  /// Get tax bracket for given income
  static TaxBracket? getBracketForIncome(double income, String filingStatus) {
    List<TaxBracket> brackets = filingStatus == 'married_joint'
        ? _marriedJointBrackets
        : _singleBrackets;

    for (var bracket in brackets) {
      if (income >= bracket.min && income < bracket.max) {
        return bracket;
      }
    }
    return brackets.last;
  }

  /// Calculate distance to next tax bracket
  static BracketDistance getDistanceToNextBracket(
      double income, String filingStatus) {
    final bracket = getBracketForIncome(income, filingStatus);
    if (bracket == null) {
      return BracketDistance(
        currentBracket: _singleBrackets.last,
        nextBracket: null,
        distanceToNext: 0,
        percentageComplete: 100,
      );
    }

    List<TaxBracket> brackets = filingStatus == 'married_joint'
        ? _marriedJointBrackets
        : _singleBrackets;

    final currentIndex = brackets.indexOf(bracket);
    final nextBracket =
        currentIndex < brackets.length - 1 ? brackets[currentIndex + 1] : null;

    final incomeInBracket = income - bracket.min;
    final bracketRange = bracket.max - bracket.min;
    final percentageComplete = bracketRange > 0
        ? (incomeInBracket / bracketRange * 100).clamp(0.0, 100.0)
        : 100.0;

    return BracketDistance(
      currentBracket: bracket,
      nextBracket: nextBracket,
      distanceToNext: bracket.max - income,
      percentageComplete: percentageComplete.toDouble(),
    );
  }

  /// Calculate comprehensive tax estimate with paycheck and deduction data
  static AdvancedTaxEstimate calculateAdvancedTax({
    required double appTrackedIncome, // From shifts
    required double w2GrossYTD, // From paychecks
    required double w2TaxesWithheld, // Federal+State+FICA from paychecks
    required double invoiceIncome, // 1099 income from invoices
    required double deductibleExpenses, // From receipts
    required double mileageDeduction, // From mileage logs
    required String filingStatus,
    int dependents = 0,
  }) {
    // Total income combines W-2 and 1099 income
    final totalW2Income = w2GrossYTD;
    final total1099Income = invoiceIncome;
    final totalGrossIncome = totalW2Income + total1099Income;

    // Self-employment tax only applies to 1099 income
    double selfEmploymentTax = 0;
    double adjustedIncome = totalGrossIncome;

    if (total1099Income > 0) {
      selfEmploymentTax = total1099Income * _selfEmploymentRate;
      // Can deduct half of SE tax from income
      adjustedIncome -= selfEmploymentTax * _selfEmploymentDeduction;
    }

    // Total deductions
    final totalDeductions = deductibleExpenses + mileageDeduction;

    // Standard deduction
    final standardDeduction = _standardDeductions[filingStatus] ?? 14600;

    // Taxable income (subtract both standard deduction and business deductions for 1099)
    double taxableIncome = adjustedIncome - standardDeduction - totalDeductions;
    if (taxableIncome < 0) taxableIncome = 0;

    // Get tax brackets based on filing status
    List<TaxBracket> brackets = filingStatus == 'married_joint'
        ? _marriedJointBrackets
        : _singleBrackets;

    // Calculate federal tax
    double federalTax = 0;
    for (var bracket in brackets) {
      if (taxableIncome > bracket.min) {
        double amountInBracket =
            (taxableIncome > bracket.max ? bracket.max : taxableIncome) -
                bracket.min;
        if (amountInBracket > 0) {
          federalTax += amountInBracket * bracket.rate;
        }
      }
    }

    // Dependent credits
    final dependentCredit = dependents * 2000.0;
    federalTax -= dependentCredit;
    if (federalTax < 0) federalTax = 0;

    // Total estimated tax liability
    final totalEstimatedTax = federalTax + selfEmploymentTax;

    // Calculate amount still owed vs already withheld
    final taxStillOwed = totalEstimatedTax - w2TaxesWithheld;

    // Bracket tracking
    final bracketInfo = getDistanceToNextBracket(taxableIncome, filingStatus);

    // Year-end projection (if we continue at this pace)
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final projectedYearEndIncome =
        dayOfYear > 0 ? totalGrossIncome / dayOfYear * 365 : totalGrossIncome;
    final projectedBracket = getBracketForIncome(
        projectedYearEndIncome - standardDeduction - totalDeductions,
        filingStatus);

    // Savings from deductions
    final deductionSavings = totalDeductions * bracketInfo.currentBracket.rate;

    return AdvancedTaxEstimate(
      // Income breakdown
      w2Income: totalW2Income,
      income1099: total1099Income,
      totalGrossIncome: totalGrossIncome,
      taxableIncome: taxableIncome,

      // Deductions
      standardDeduction: standardDeduction,
      businessDeductions: totalDeductions,
      deductionTaxSavings: deductionSavings,

      // Tax calculations
      federalTax: federalTax,
      selfEmploymentTax: selfEmploymentTax,
      totalEstimatedTax: totalEstimatedTax,

      // Already paid
      taxesAlreadyWithheld: w2TaxesWithheld,
      taxStillOwed: taxStillOwed,

      // Bracket info
      currentBracket: bracketInfo.currentBracket,
      distanceToNextBracket: bracketInfo.distanceToNext,
      bracketProgress: bracketInfo.percentageComplete,

      // Projections
      projectedYearEndIncome: projectedYearEndIncome,
      projectedBracket: projectedBracket,

      // Rates
      effectiveRate:
          totalGrossIncome > 0 ? totalEstimatedTax / totalGrossIncome : 0,
      marginalRate: bracketInfo.currentBracket.rate,
    );
  }
}

/// Distance to next tax bracket calculation
class BracketDistance {
  final TaxBracket currentBracket;
  final TaxBracket? nextBracket;
  final double distanceToNext;
  final double percentageComplete;

  BracketDistance({
    required this.currentBracket,
    this.nextBracket,
    required this.distanceToNext,
    required this.percentageComplete,
  });
}

/// Advanced tax estimate with full income/deduction breakdown
class AdvancedTaxEstimate {
  // Income
  final double w2Income;
  final double income1099;
  final double totalGrossIncome;
  final double taxableIncome;

  // Deductions
  final double standardDeduction;
  final double businessDeductions;
  final double deductionTaxSavings;

  // Taxes
  final double federalTax;
  final double selfEmploymentTax;
  final double totalEstimatedTax;

  // Withholdings
  final double taxesAlreadyWithheld;
  final double taxStillOwed;

  // Bracket info
  final TaxBracket currentBracket;
  final double distanceToNextBracket;
  final double bracketProgress;

  // Projections
  final double projectedYearEndIncome;
  final TaxBracket? projectedBracket;

  // Rates
  final double effectiveRate;
  final double marginalRate;

  AdvancedTaxEstimate({
    required this.w2Income,
    required this.income1099,
    required this.totalGrossIncome,
    required this.taxableIncome,
    required this.standardDeduction,
    required this.businessDeductions,
    required this.deductionTaxSavings,
    required this.federalTax,
    required this.selfEmploymentTax,
    required this.totalEstimatedTax,
    required this.taxesAlreadyWithheld,
    required this.taxStillOwed,
    required this.currentBracket,
    required this.distanceToNextBracket,
    required this.bracketProgress,
    required this.projectedYearEndIncome,
    this.projectedBracket,
    required this.effectiveRate,
    required this.marginalRate,
  });

  String get effectiveRatePercent =>
      '${(effectiveRate * 100).toStringAsFixed(1)}%';
  String get marginalRatePercent =>
      '${(marginalRate * 100).toStringAsFixed(0)}%';

  bool get owesMoney => taxStillOwed > 0;
  bool get willMoveUpBracket =>
      projectedBracket != null && projectedBracket!.rate > currentBracket.rate;
}

class TaxBracket {
  final double min;
  final double max;
  final double rate;

  const TaxBracket({
    required this.min,
    required this.max,
    required this.rate,
  });

  String get ratePercent => '${(rate * 100).toStringAsFixed(0)}%';
}

class TaxEstimate {
  final double grossIncome;
  final double taxableIncome;
  final double federalTax;
  final double selfEmploymentTax;
  final double totalTax;
  final double effectiveRate;
  final double monthlyEstimate;
  final double quarterlyEstimate;
  final double standardDeduction;
  final double dependentCredits;

  TaxEstimate({
    required this.grossIncome,
    required this.taxableIncome,
    required this.federalTax,
    required this.selfEmploymentTax,
    required this.totalTax,
    required this.effectiveRate,
    required this.monthlyEstimate,
    required this.quarterlyEstimate,
    required this.standardDeduction,
    required this.dependentCredits,
  });

  String get effectiveRatePercent =>
      '${(effectiveRate * 100).toStringAsFixed(1)}%';
}

/// Simplified TaxService wrapper for quick calculations
class TaxService {
  // State income tax rates (simplified - using average rates)
  static const Map<String, double> _stateRates = {
    'AL': 0.05,
    'AK': 0.0,
    'AZ': 0.025,
    'AR': 0.055,
    'CA': 0.093,
    'CO': 0.044,
    'CT': 0.05,
    'DE': 0.066,
    'FL': 0.0,
    'GA': 0.055,
    'HI': 0.11,
    'ID': 0.058,
    'IL': 0.0495,
    'IN': 0.032,
    'IA': 0.06,
    'KS': 0.057,
    'KY': 0.045,
    'LA': 0.0425,
    'ME': 0.075,
    'MD': 0.0575,
    'MA': 0.05,
    'MI': 0.0425,
    'MN': 0.0985,
    'MS': 0.05,
    'MO': 0.054,
    'MT': 0.069,
    'NE': 0.0684,
    'NV': 0.0,
    'NH': 0.0,
    'NJ': 0.1075,
    'NM': 0.059,
    'NY': 0.109,
    'NC': 0.0525,
    'ND': 0.029,
    'OH': 0.04,
    'OK': 0.05,
    'OR': 0.099,
    'PA': 0.0307,
    'RI': 0.0599,
    'SC': 0.07,
    'SD': 0.0,
    'TN': 0.0,
    'TX': 0.0,
    'UT': 0.0485,
    'VT': 0.0875,
    'VA': 0.0575,
    'WA': 0.0,
    'WV': 0.065,
    'WI': 0.0765,
    'WY': 0.0,
  };

  /// Calculate simple tax estimate
  static Map<String, dynamic> calculateTaxes({
    required double yearlyIncome,
    required String state,
  }) {
    // Social Security (6.2% up to $168,600)
    final socialSecurity = (yearlyIncome * 0.062).clamp(0.0, 168600 * 0.062);

    // Medicare (1.45%)
    final medicare = yearlyIncome * 0.0145;

    // Federal tax (simplified progressive)
    double federal = 0;
    if (yearlyIncome > 14600) {
      // After standard deduction
      final taxable = yearlyIncome - 14600;
      if (taxable <= 11600) {
        federal = taxable * 0.10;
      } else if (taxable <= 47150) {
        federal = 1160 + (taxable - 11600) * 0.12;
      } else if (taxable <= 100525) {
        federal = 5426 + (taxable - 47150) * 0.22;
      } else {
        federal = 17168.50 + (taxable - 100525) * 0.24;
      }
    }

    // State tax
    final stateRate = _stateRates[state] ?? 0.05;
    final stateTax = yearlyIncome * stateRate;

    final total = federal + stateTax + socialSecurity + medicare;

    return {
      'federal': federal,
      'state': stateTax,
      'socialSecurity': socialSecurity,
      'medicare': medicare,
      'total': total,
      'effectiveRate': yearlyIncome > 0 ? total / yearlyIncome : 0,
    };
  }
}
