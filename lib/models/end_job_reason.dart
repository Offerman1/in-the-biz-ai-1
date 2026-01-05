/// Categories for why a user ended a job
enum EndJobReason {
  promoted('promoted', '🚀 Promoted', 'Got promoted to a better position'),
  betterOpportunity('better_opportunity', '💰 Better Opportunity',
      'Found a higher-paying job'),
  relocated('relocated', '📍 Relocated', 'Moved to a different city/state'),
  careerChange('career_change', '🎓 Career Change', 'Switched industries'),
  personal('personal', '🏠 Personal Reasons',
      'Family, health, or other personal matters'),
  terminated('terminated', '😞 Terminated', 'Fired by employer'),
  mutualAgreement(
      'mutual_agreement', '🤝 Mutual Agreement', 'Parted ways amicably'),
  contractEnded('contract_ended', '📅 Contract Ended',
      'Seasonal or temporary job finished'),
  quitManagement('quit_management', '😤 Quit - Management Issues',
      'Bad boss or company culture'),
  quitBurnout('quit_burnout', '😓 Quit - Burnout', 'Too much stress or hours'),
  laidOff('laid_off', '💔 Laid Off', 'Company downsizing'),
  retired('retired', '🎉 Retired', 'End of career'),
  other('other', '📝 Other', 'Custom reason - add notes below');

  final String value;
  final String displayName;
  final String description;

  const EndJobReason(this.value, this.displayName, this.description);

  /// Get enum from database value
  static EndJobReason? fromValue(String? value) {
    if (value == null) return null;
    try {
      return EndJobReason.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }

  /// Get all values for dropdown
  static List<EndJobReason> get dropdownValues => EndJobReason.values;
}
