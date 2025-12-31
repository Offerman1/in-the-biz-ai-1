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

  // Industry-specific fields (Salon, Hospitality, Fitness, etc.)
  final bool showServiceType; // Hair cut, color, massage type, etc.
  final bool showSessionType; // PT session vs group class, etc.
  final bool showClassSize; // For group fitness
  final bool showGigType; // For musicians: wedding, corporate, street, etc.
  final bool showMaterialsCost; // For construction, salon, artists
  final bool showEquipmentRental; // For construction, music
  final bool showUpsells; // For retail: warranties, credit cards, etc.
  final bool showShrink; // For retail: inventory loss/shrink
  final bool showReturns; // For retail: return tracking
  final bool showProductSales; // For salon: separate product revenue
  final bool showRepeatClientPercent; // For salon, fitness: loyalty metric
  final bool showRetentionRate; // For fitness: recurring clients %
  final bool showQualityScore; // For housekeeping: quality metrics
  final bool showCancellations; // For fitness, healthcare: no-show tracking
  final bool showChairRental; // For salon: freelance stylists
  final bool showOnCallHours; // For healthcare: on-call shifts
  final bool showRoomType; // For housekeeping: standard/suite/deluxe
  final bool showShiftType; // For hospitality, retail, healthcare: peak vs slow
  final bool showShiftDifferential; // For healthcare, hospitality: night/weekend bonus

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
    this.showServiceType = false,
    this.showSessionType = false,
    this.showClassSize = false,
    this.showGigType = false,
    this.showMaterialsCost = false,
    this.showEquipmentRental = false,
    this.showUpsells = false,
    this.showShrink = false,
    this.showReturns = false,
    this.showProductSales = false,
    this.showRepeatClientPercent = false,
    this.showRetentionRate = false,
    this.showQualityScore = false,
    this.showCancellations = false,
    this.showChairRental = false,
    this.showOnCallHours = false,
    this.showRoomType = false,
    this.showShiftType = false,
    this.showShiftDifferential = false,
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
      showServiceType: json['show_service_type'] ?? false,
      showSessionType: json['show_session_type'] ?? false,
      showClassSize: json['show_class_size'] ?? false,
      showGigType: json['show_gig_type'] ?? false,
      showMaterialsCost: json['show_materials_cost'] ?? false,
      showEquipmentRental: json['show_equipment_rental'] ?? false,
      showUpsells: json['show_upsells'] ?? false,
      showShrink: json['show_shrink'] ?? false,
      showReturns: json['show_returns'] ?? false,
      showProductSales: json['show_product_sales'] ?? false,
      showRepeatClientPercent: json['show_repeat_client_percent'] ?? false,
      showRetentionRate: json['show_retention_rate'] ?? false,
      showQualityScore: json['show_quality_score'] ?? false,
      showCancellations: json['show_cancellations'] ?? false,
      showChairRental: json['show_chair_rental'] ?? false,
      showOnCallHours: json['show_on_call_hours'] ?? false,
      showRoomType: json['show_room_type'] ?? false,
      showShiftType: json['show_shift_type'] ?? false,
      showShiftDifferential: json['show_shift_differential'] ?? false,
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
      'show_service_type': showServiceType,
      'show_session_type': showSessionType,
      'show_class_size': showClassSize,
      'show_gig_type': showGigType,
      'show_materials_cost': showMaterialsCost,
      'show_equipment_rental': showEquipmentRental,
      'show_upsells': showUpsells,
      'show_shrink': showShrink,
      'show_returns': showReturns,
      'show_product_sales': showProductSales,
      'show_repeat_client_percent': showRepeatClientPercent,
      'show_retention_rate': showRetentionRate,
      'show_quality_score': showQualityScore,
      'show_cancellations': showCancellations,
      'show_chair_rental': showChairRental,
      'show_on_call_hours': showOnCallHours,
      'show_room_type': showRoomType,
      'show_shift_type': showShiftType,
      'show_shift_differential': showShiftDifferential,
    };
  }

  /// Pre-configured template for restaurant/bar jobs
  factory JobTemplate.restaurant() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showSales: true,
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
      showMileage: true,
      showLocation: true,
      showClientName: true,
      showProjectName: true,
      showMaterialsCost: true,
      showEquipmentRental: true,
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
      showCommission: false,
      showMileage: false,
      showClientName: true,
      showProjectName: true,
      showLocation: false,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for rideshare & delivery (Uber, Lyft, DoorDash)
  factory JobTemplate.rideshareDelivery() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showMileage: true,
      showSales: true,
      showLocation: true,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for musicians, DJs, photographers, entertainers
  factory JobTemplate.musicEntertainment() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showSales: true,
      showClientName: true,
      showEventName: true,
      showGigType: true,
      showEquipmentRental: true,
      showLocation: true,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for artists and crafts workers
  factory JobTemplate.artistCrafts() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showSales: true,
      showMaterialsCost: true,
      showLocation: true,
      showEventName: true,
      showClientName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for salon & spa (hair, nails, massage, esthetician)
  factory JobTemplate.salon() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showCommission: true,
      showSales: true,
      showClientName: true,
      showServiceType: true,
      showProductSales: true,
      showRepeatClientPercent: true,
      showChairRental: true,
      showEventName: false,
      showHostess: false,
      showGuestCount: false,
    );
  }

  /// Pre-configured template for hospitality (hotels, events, catering)
  factory JobTemplate.hospitality() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: true,
      showGuestCount: true,
      showEventName: true,
      showClientName: true,
      showShiftType: true,
      showServiceType: true,
      showRoomType: true,
      showQualityScore: true,
      showLocation: true,
      showHostess: false,
    );
  }

  /// Pre-configured template for fitness (personal trainers, group classes)
  factory JobTemplate.fitness() {
    return JobTemplate(
      payStructure: PayStructure.hourly,
      showTips: false,
      showCommission: true,
      showSales: true,
      showClientName: true,
      showSessionType: true,
      showClassSize: true,
      showRetentionRate: true,
      showCancellations: true,
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
      showShiftType: true,
      showShiftDifferential: true,
      showOnCallHours: true,
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
      showSales: true,
      showUpsells: true,
      showReturns: true,
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
    bool? showServiceType,
    bool? showSessionType,
    bool? showClassSize,
    bool? showGigType,
    bool? showMaterialsCost,
    bool? showEquipmentRental,
    bool? showUpsells,
    bool? showShrink,
    bool? showReturns,
    bool? showProductSales,
    bool? showRepeatClientPercent,
    bool? showRetentionRate,
    bool? showQualityScore,
    bool? showCancellations,
    bool? showChairRental,
    bool? showOnCallHours,
    bool? showRoomType,
    bool? showShiftType,
    bool? showShiftDifferential,
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
      showServiceType: showServiceType ?? this.showServiceType,
      showSessionType: showSessionType ?? this.showSessionType,
      showClassSize: showClassSize ?? this.showClassSize,
      showGigType: showGigType ?? this.showGigType,
      showMaterialsCost: showMaterialsCost ?? this.showMaterialsCost,
      showEquipmentRental: showEquipmentRental ?? this.showEquipmentRental,
      showUpsells: showUpsells ?? this.showUpsells,
      showShrink: showShrink ?? this.showShrink,
      showReturns: showReturns ?? this.showReturns,
      showProductSales: showProductSales ?? this.showProductSales,
      showRepeatClientPercent: showRepeatClientPercent ?? this.showRepeatClientPercent,
      showRetentionRate: showRetentionRate ?? this.showRetentionRate,
      showQualityScore: showQualityScore ?? this.showQualityScore,
      showCancellations: showCancellations ?? this.showCancellations,
      showChairRental: showChairRental ?? this.showChairRental,
      showOnCallHours: showOnCallHours ?? this.showOnCallHours,
      showRoomType: showRoomType ?? this.showRoomType,
      showShiftType: showShiftType ?? this.showShiftType,
      showShiftDifferential: showShiftDifferential ?? this.showShiftDifferential,
    );
  }
}

enum PayStructure {
  hourly, // Paid per hour
  flatRate, // Paid per project/job
  salary, // Annual salary (just track hours)
  commission // Percentage-based
}
