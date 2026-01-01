class Shift {
  final String id;
  final DateTime date;
  final double cashTips;
  final double creditTips;
  final double hourlyRate;
  final double hoursWorked;
  final String? notes;
  final String? imageUrl; // Path to stored BEO/Receipt image
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Job and time fields
  final String? jobId; // Reference to jobs table
  final String? jobType; // Bartender, Server, Manager, etc. (legacy/display)
  final String? startTime; // e.g., "9:00 AM"
  final String? endTime; // e.g., "5:00 PM"

  // Event metadata
  final String? eventName; // Party name, event title
  final String? hostess; // Hostess name for events
  final int? guestCount; // Number of guests

  // Work details (trades, freelancers, healthcare)
  final String? location; // Job site address or location
  final String? clientName; // Client/patient name
  final String? projectName; // Project or job name

  // Additional earnings tracking
  final double? commission; // Commission earned (retail, sales)
  final double? mileage; // Miles driven (for reimbursement)
  final double? flatRate; // Flat rate for project-based work
  final double? overtimeHours; // Overtime hours worked

  // Sales and tip out tracking (NEW)
  final double? salesAmount; // Total sales for the shift (servers, bartenders)
  final double?
      tipoutPercent; // Percentage of sales to tip out (e.g., 3.0 for 3%)
  final double? additionalTipout; // Extra cash given (e.g., $20 to dishwasher)
  final String? additionalTipoutNote; // Who received it (e.g., "Dishwasher")
  final double? eventCost; // Total cost of event (DJs, event planners)

  // Future shift fields (NEW)
  final String status; // 'scheduled' or 'completed'
  final String source; // 'manual' or 'calendar_sync'
  final bool isRecurring; // Whether this is part of a recurring series
  final String? recurrenceRule; // e.g., "WEEKLY:MON,WED,FRI"
  final String? recurringSeriesId; // Links all shifts in same series
  final String? calendarEventId; // ID from device calendar if synced

  Shift({
    required this.id,
    required this.date,
    this.cashTips = 0.0,
    this.creditTips = 0.0,
    this.hourlyRate = 0.0,
    this.hoursWorked = 0.0,
    this.notes,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.jobId,
    this.jobType,
    this.startTime,
    this.endTime,
    this.eventName,
    this.hostess,
    this.guestCount,
    this.location,
    this.clientName,
    this.projectName,
    this.commission,
    this.mileage,
    this.flatRate,
    this.overtimeHours,
    this.salesAmount,
    this.tipoutPercent,
    this.additionalTipout,
    this.additionalTipoutNote,
    this.eventCost,
    this.status = 'completed',
    this.source = 'manual',
    this.isRecurring = false,
    this.recurrenceRule,
    this.recurringSeriesId,
    this.calendarEventId,
  });

  double get totalIncome {
    double base = hourlyRate * hoursWorked;
    double tips = cashTips + creditTips;
    double overtimePay =
        (overtimeHours ?? 0) * hourlyRate * 0.5; // Extra 0.5x for overtime
    double commissionEarnings = commission ?? 0;
    double flatRateEarnings = flatRate ?? 0;
    return base + tips + overtimePay + commissionEarnings + flatRateEarnings;
  }

  double get totalTips => cashTips + creditTips;
  double get calculatedTipout {
    final fromSales = (salesAmount != null && tipoutPercent != null)
        ? (salesAmount! * tipoutPercent! / 100)
        : 0.0;
    return fromSales + (additionalTipout ?? 0);
  }

  double get netTips => totalTips - calculatedTipout; // Tips after all tipouts
  double get hourlyEarnings => hourlyRate * hoursWorked;
  double get tipPercentage => (salesAmount != null && salesAmount! > 0)
      ? (totalTips / salesAmount!) * 100
      : 0.0; // Tip % on sales

  /// Get display amount based on selected money display mode
  double getDisplayAmount(String mode) {
    switch (mode) {
      case 'totalRevenue':
        // Everything earned (existing totalIncome getter)
        return totalIncome;

      case 'takeHomePay':
        // Total income minus tip outs
        return totalIncome - calculatedTipout;

      case 'tipsOnly':
        // Just tips, minus tip outs
        return netTips;

      case 'hourlyOnly':
        // Just base hourly pay
        return hourlyEarnings;

      default:
        return totalIncome - calculatedTipout; // Default to take home pay
    }
  }

  /// Create a copy with modified fields
  Shift copyWith({
    String? id,
    DateTime? date,
    double? cashTips,
    double? creditTips,
    double? hourlyRate,
    double? hoursWorked,
    String? notes,
    String? imageUrl,
    String? jobId,
    String? jobType,
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
    double? salesAmount,
    double? tipoutPercent,
    double? additionalTipout,
    String? additionalTipoutNote,
    double? eventCost,
    String? status,
    String? source,
    bool? isRecurring,
    String? recurrenceRule,
    String? recurringSeriesId,
    String? calendarEventId,
  }) {
    return Shift(
      id: id ?? this.id,
      date: date ?? this.date,
      cashTips: cashTips ?? this.cashTips,
      creditTips: creditTips ?? this.creditTips,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      jobId: jobId ?? this.jobId,
      jobType: jobType ?? this.jobType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      eventName: eventName ?? this.eventName,
      hostess: hostess ?? this.hostess,
      guestCount: guestCount ?? this.guestCount,
      location: location ?? this.location,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      commission: commission ?? this.commission,
      mileage: mileage ?? this.mileage,
      flatRate: flatRate ?? this.flatRate,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      salesAmount: salesAmount ?? this.salesAmount,
      tipoutPercent: tipoutPercent ?? this.tipoutPercent,
      additionalTipout: additionalTipout ?? this.additionalTipout,
      additionalTipoutNote: additionalTipoutNote ?? this.additionalTipoutNote,
      eventCost: eventCost ?? this.eventCost,
      status: status ?? this.status,
      source: source ?? this.source,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurringSeriesId: recurringSeriesId ?? this.recurringSeriesId,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to map for local storage (SharedPreferences fallback)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'cashTips': cashTips,
      'creditTips': creditTips,
      'hourlyRate': hourlyRate,
      'hoursWorked': hoursWorked,
      'notes': notes,
      'imageUrl': imageUrl,
      'jobId': jobId,
      'jobType': jobType,
      'startTime': startTime,
      'endTime': endTime,
      'eventName': eventName,
      'hostess': hostess,
      'guestCount': guestCount,
      'location': location,
      'clientName': clientName,
      'projectName': projectName,
      'commission': commission,
      'mileage': mileage,
      'flatRate': flatRate,
      'overtimeHours': overtimeHours,
      'salesAmount': salesAmount,
      'tipoutPercent': tipoutPercent,
      'additionalTipout': additionalTipout,
      'additionalTipoutNote': additionalTipoutNote,
      'eventCost': eventCost,
      'status': status,
      'source': source,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'recurringSeriesId': recurringSeriesId,
      'calendarEventId': calendarEventId,
    };
  }

  /// Create from local storage map
  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      date: DateTime.parse(map['date']),
      cashTips: (map['cashTips'] ?? 0.0).toDouble(),
      creditTips: (map['creditTips'] ?? 0.0).toDouble(),
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      hoursWorked: (map['hoursWorked'] ?? 0.0).toDouble(),
      notes: map['notes'],
      imageUrl: map['imageUrl'],
      jobId: map['jobId'],
      jobType: map['jobType'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      eventName: map['eventName'],
      hostess: map['hostess'],
      guestCount: map['guestCount'],
      location: map['location'],
      clientName: map['clientName'],
      projectName: map['projectName'],
      commission: map['commission']?.toDouble(),
      mileage: map['mileage']?.toDouble(),
      flatRate: map['flatRate']?.toDouble(),
      overtimeHours: map['overtimeHours']?.toDouble(),
      salesAmount: map['salesAmount']?.toDouble(),
      tipoutPercent: map['tipoutPercent']?.toDouble(),
      additionalTipout: map['additionalTipout']?.toDouble(),
      additionalTipoutNote: map['additionalTipoutNote'],
      eventCost: map['eventCost']?.toDouble(),
      status: map['status'] ?? 'completed',
      source: map['source'] ?? 'manual',
      isRecurring: map['isRecurring'] ?? false,
      recurrenceRule: map['recurrenceRule'],
      recurringSeriesId: map['recurringSeriesId'],
      calendarEventId: map['calendarEventId'],
    );
  }

  /// Create from Supabase response
  factory Shift.fromSupabase(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      date: DateTime.parse(map['date']),
      cashTips: (map['cash_tips'] ?? 0.0).toDouble(),
      creditTips: (map['credit_tips'] ?? 0.0).toDouble(),
      hourlyRate: (map['hourly_rate'] ?? 0.0).toDouble(),
      hoursWorked: (map['hours_worked'] ?? 0.0).toDouble(),
      notes: map['notes'],
      imageUrl: map['image_url'],
      jobId: map['job_id'],
      jobType: map['job_type'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      eventName: map['event_name'],
      hostess: map['hostess'],
      guestCount: map['guest_count'],
      location: map['location'],
      clientName: map['client_name'],
      projectName: map['project_name'],
      commission: (map['commission'] ?? 0.0).toDouble(),
      mileage: (map['mileage'] ?? 0.0).toDouble(),
      flatRate: (map['flat_rate'] ?? 0.0).toDouble(),
      overtimeHours: (map['overtime_hours'] ?? 0.0).toDouble(),
      salesAmount: map['sales_amount']?.toDouble(),
      tipoutPercent: map['tipout_percent']?.toDouble(),
      additionalTipout: map['additional_tipout']?.toDouble(),
      additionalTipoutNote: map['additional_tipout_note'],
      eventCost: map['event_cost']?.toDouble(),
      status: map['status'] ?? 'completed',
      source: map['source'] ?? 'manual',
      isRecurring: map['is_recurring'] ?? false,
      recurrenceRule: map['recurrence_rule'],
      recurringSeriesId: map['recurring_series_id'],
      calendarEventId: map['calendar_event_id'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  /// Convert to Supabase insert format
  Map<String, dynamic> toSupabase(String userId) {
    return {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'cash_tips': cashTips,
      'credit_tips': creditTips,
      'hourly_rate': hourlyRate,
      'hours_worked': hoursWorked,
      'notes': notes,
      'job_id': jobId,
      'job_type': jobType,
      'start_time': startTime,
      'end_time': endTime,
      'event_name': eventName,
      'hostess': hostess,
      'guest_count': guestCount,
      'location': location,
      'client_name': clientName,
      'project_name': projectName,
      'commission': commission,
      'mileage': mileage,
      'flat_rate': flatRate,
      'overtime_hours': overtimeHours,
      'sales_amount': salesAmount,
      'tipout_percent': tipoutPercent,
      'additional_tipout': additionalTipout,
      'additional_tipout_note': additionalTipoutNote,
      'event_cost': eventCost,
      'status': status,
      'source': source,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'recurring_series_id': recurringSeriesId,
      'calendar_event_id': calendarEventId,
    };
  }
}
