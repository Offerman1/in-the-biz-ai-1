class Goal {
  final String id;
  final String userId;
  final String? jobId;
  final String type; // 'weekly', 'monthly', 'yearly', 'custom'
  final double targetAmount;
  final double? targetHours;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Goal({
    required this.id,
    required this.userId,
    this.jobId,
    required this.type,
    required this.targetAmount,
    this.targetHours,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Goal.fromSupabase(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      jobId: map['job_id'] as String?,
      type: map['type'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      targetHours: (map['target_hours'] as num?)?.toDouble(),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
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
      'job_id': jobId,
      'type': type,
      'target_amount': targetAmount,
      'target_hours': targetHours,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? jobId,
    String? type,
    double? targetAmount,
    double? targetHours,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      targetHours: targetHours ?? this.targetHours,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Get progress towards this goal based on current income
  double getProgress(double currentIncome) {
    if (targetAmount <= 0) return 0;
    return (currentIncome / targetAmount).clamp(0.0, 1.0);
  }

  /// Get progress percentage as string
  String getProgressPercent(double currentIncome) {
    return '${(getProgress(currentIncome) * 100).toStringAsFixed(0)}%';
  }

  /// Check if goal is complete
  bool isComplete(double currentIncome) {
    return currentIncome >= targetAmount;
  }

  /// Get remaining amount to reach goal
  double getRemaining(double currentIncome) {
    return (targetAmount - currentIncome).clamp(0.0, double.infinity);
  }
}
