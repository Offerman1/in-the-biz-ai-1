/// Defines which fields should be visible/hidden for a specific job's shift entry
class JobTemplate {
  // Pay structure
  final PayStructure payStructure;
  final double? flatRateAmount; // For flat rate projects
  final bool tracksOvertime;
  final double overtimeMultiplier; // 1.5x, 2x, etc.

  // Field visibility toggles
  final bool showTips;
  final bool showCommission;
  final bool showMileage;
  final bool showSales; // NEW: Show sales field
  final bool showEventCost; // NEW: Show event cost field

  // Event details (for catering, events)
  final bool showEventName;
  final bool showHostess;
  final bool showGuestCount;

  // Work details (for trades, freelancers)
  final bool showLocation;
  final bool showClientName;
  final bool showProjectName;

  // Documentation
  final bool showPhotos;
  final bool showNotes;

  JobTemplate({
    this.payStructure = PayStructure.hourly,
    this.flatRateAmount,
    this.tracksOvertime = false,
    this.overtimeMultiplier = 1.5,
    this.showTips = true,
    this.showCommission = false,
    this.showMileage = false,
    this.showSales = false,
    this.showEventCost = false,
    this.showEventName = true,
    this.showHostess = false,
    this.showGuestCount = false,
    this.showLocation = false,
    this.showClientName = false,
    this.showProjectName = false,
    this.showPhotos = true,
    this.showNotes = true,
  });

  /// Create from Supabase JSONB field
  factory JobTemplate.fromJson(Map<String, dynamic> json) {
    return JobTemplate(
      payStructure: PayStructure.values.firstWhere(
        (e) => e.name == json['pay_structure'],
        orElse: () => PayStructure.hourly,
      ),
      flatRateAmount: json['flat_rate_amount']?.toDouble(),
      tracksOvertime: json['tracks_overtime'] ?? false,
      overtimeMultiplier: json['overtime_multiplier']?.toDouble() ?? 1.5,
      showTips: json['show_tips'] ?? true,
      showCommission: json['show_commission'] ?? false,
      showMileage: json['show_mileage'] ?? false,
      showSales: json['show_sales'] ?? false,
      showEventCost: json['show_event_cost'] ?? false,
      showEventName: json['show_event_name'] ?? true,
      showHostess: json['show_hostess'] ?? false,
      showGuestCount: json['show_guest_count'] ?? false,
      showLocation: json['show_location'] ?? false,
      showClientName: json['show_client_name'] ?? false,
      showProjectName: json['show_project_name'] ?? false,
      showPhotos: json['show_photos'] ?? true,
      showNotes: json['show_notes'] ?? true,
    );
  }

  /// Convert to JSONB for Supabase
  Map<String, dynamic> toJson() {
    return {
      'pay_structure': payStructure.name,
      'flat_rate_amount': flatRateAmount,
      'tracks_overtime': tracksOvertime,
      'overtime_multiplier': overtimeMultiplier,
      'show_tips': showTips,
      'show_commission': showCommission,
      'show_mileage': showMileage,
      'show_sales': showSales,
      'show_event_cost': showEventCost,
      'show_event_name': showEventName,
      'show_hostess': showHostess,
      'show_guest_count': showGuestCount,
      'show_location': showLocation,
      'show_client_name': showClientName,
      'show_project_name': showProjectName,
      'show_photos': showPhotos,
      'show_notes': showNotes,
    };
  }

  /// Pre-configured template for restaurant/bar jobs
  factory JobTemplate.restaurant() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showEventName: true,
      showHostess: true,
      showGuestCount: true,
      showLocation: false,
      showClientName: false,
      showProjectName: false,
    );
  }

  /// Pre-configured template for construction/trades
  factory JobTemplate.construction() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      tracksOvertime: true,
      overtimeMultiplier: 1.5,
      showTips: false,
      showLocation: true,
      showClientName: true,
      showProjectName: true,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for freelancers
  factory JobTemplate.freelancer() {
    return JobTemplate(
      payStructure: PayStructure.flatRate,
      showTips: false,
      showClientName: true,
      showProjectName: true,
      showLocation: false,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for healthcare
  factory JobTemplate.healthcare() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: false,
      showMileage: true,
      showLocation: true,
      showClientName: true,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for gig workers
  factory JobTemplate.gigWorker() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showMileage: true,
      showLocation: false,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for retail/sales
  factory JobTemplate.retail() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: false,
      showCommission: true,
      showLocation: false,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  JobTemplate copyWith({
    PayStructure? payStructure,
    double? flatRateAmount,
    bool? tracksOvertime,
    double? overtimeMultiplier,
    bool? showTips,
    bool? showCommission,
    bool? showMileage,
    bool? showSales,
    bool? showEventCost,
    bool? showEventName,
    bool? showHostess,
    bool? showGuestCount,
    bool? showLocation,
    bool? showClientName,
    bool? showProjectName,
    bool? showPhotos,
    bool? showNotes,
  }) {
    return JobTemplate(
      payStructure: payStructure ?? this.payStructure,
      flatRateAmount: flatRateAmount ?? this.flatRateAmount,
      tracksOvertime: tracksOvertime ?? this.tracksOvertime,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      showTips: showTips ?? this.showTips,
      showCommission: showCommission ?? this.showCommission,
      showMileage: showMileage ?? this.showMileage,
      showSales: showSales ?? this.showSales,
      showEventCost: showEventCost ?? this.showEventCost,
      showEventName: showEventName ?? this.showEventName,
      showHostess: showHostess ?? this.showHostess,
      showGuestCount: showGuestCount ?? this.showGuestCount,
      showLocation: showLocation ?? this.showLocation,
      showClientName: showClientName ?? this.showClientName,
      showProjectName: showProjectName ?? this.showProjectName,
      showPhotos: showPhotos ?? this.showPhotos,
      showNotes: showNotes ?? this.showNotes,
    );
  }
}

enum PayStructure {
  hourly, // Paid per hour
  flatRate, // Paid per project/job
  salary, // Annual salary (just track hours)
  commission // Percentage-based
}
