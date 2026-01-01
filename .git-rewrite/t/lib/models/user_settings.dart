class UserSettings {
  final String id;
  final String userId;
  final String
      filingStatus; // 'single', 'married_joint', 'married_separate', 'head_of_household'
  final String? state;
  final double additionalIncome;
  final double deductions;
  final int dependents;
  final bool hasCompletedOnboarding;
  final String? preferredIndustry;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    this.filingStatus = 'single',
    this.state,
    this.additionalIncome = 0.0,
    this.deductions = 0.0,
    this.dependents = 0,
    this.hasCompletedOnboarding = false,
    this.preferredIndustry,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromSupabase(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      filingStatus: map['filing_status'] as String? ?? 'single',
      state: map['state'] as String?,
      additionalIncome: (map['additional_income'] as num?)?.toDouble() ?? 0.0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0.0,
      dependents: map['dependents'] as int? ?? 0,
      hasCompletedOnboarding: map['has_completed_onboarding'] as bool? ?? false,
      preferredIndustry: map['preferred_industry'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'filing_status': filingStatus,
      'state': state,
      'additional_income': additionalIncome,
      'deductions': deductions,
      'dependents': dependents,
      'has_completed_onboarding': hasCompletedOnboarding,
      'preferred_industry': preferredIndustry,
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    String? filingStatus,
    String? state,
    double? additionalIncome,
    double? deductions,
    int? dependents,
    bool? hasCompletedOnboarding,
    String? preferredIndustry,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      filingStatus: filingStatus ?? this.filingStatus,
      state: state ?? this.state,
      additionalIncome: additionalIncome ?? this.additionalIncome,
      deductions: deductions ?? this.deductions,
      dependents: dependents ?? this.dependents,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      preferredIndustry: preferredIndustry ?? this.preferredIndustry,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
