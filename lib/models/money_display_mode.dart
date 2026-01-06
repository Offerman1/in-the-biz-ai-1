/// Enum for different money display modes in the calendar
enum MoneyDisplayMode {
  /// Total Revenue: Everything earned (hourly + tips + commission + flat rate)
  totalRevenue,

  /// Take Home Pay: Total income minus tip outs
  takeHomePay,

  /// Tips Only: Just tips (cash + credit) minus tip outs
  tipsOnly,

  /// Hourly Only: Base hourly pay only
  hourlyOnly,

  /// Net Earnings: Take home pay minus custom field deductions (fuel, tolls, etc.)
  netEarnings,
}

extension MoneyDisplayModeExtension on MoneyDisplayMode {
  String get displayName {
    switch (this) {
      case MoneyDisplayMode.totalRevenue:
        return 'Total Revenue';
      case MoneyDisplayMode.takeHomePay:
        return 'Take Home Pay';
      case MoneyDisplayMode.tipsOnly:
        return 'Tips Only';
      case MoneyDisplayMode.hourlyOnly:
        return 'Hourly Only';
      case MoneyDisplayMode.netEarnings:
        return 'Net Earnings';
    }
  }

  String get description {
    switch (this) {
      case MoneyDisplayMode.totalRevenue:
        return 'Hourly + Tips + All Earnings';
      case MoneyDisplayMode.takeHomePay:
        return 'All Earnings - Tip Outs';
      case MoneyDisplayMode.tipsOnly:
        return 'Tips - Tip Outs';
      case MoneyDisplayMode.hourlyOnly:
        return 'Base Pay Only';
      case MoneyDisplayMode.netEarnings:
        return 'After Deductions (fuel, tolls, etc.)';
    }
  }

  String toJson() => name;

  static MoneyDisplayMode fromJson(String value) {
    return MoneyDisplayMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MoneyDisplayMode.takeHomePay, // Default
    );
  }
}
