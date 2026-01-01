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
  final bool
      showShiftDifferential; // For healthcare, hospitality: night/weekend bonus

  // Rideshare & Delivery specific
  final bool showRidesCount; // Number of rides/deliveries
  final bool showDeadMiles; // Miles without passenger
  final bool showFuelCost; // Fuel expenses
  final bool showTollsParking; // Tolls and parking
  final bool showSurgeMultiplier; // Surge pricing
  final bool showBaseFare; // Base fare vs tips breakdown

  // Music & Entertainment specific
  final bool showSetupHours; // Setup time before performance
  final bool showPerformanceHours; // Actual performance time
  final bool showBreakdownHours; // Breakdown time after
  final bool showEquipmentUsed; // What gear was needed
  final bool showCrewPayment; // Split with bandmates/crew
  final bool showMerchSales; // Merchandise revenue
  final bool showAudienceSize; // Crowd/attendance

  // Artist & Crafts specific
  final bool showPiecesCreated; // Production count
  final bool showPiecesSold; // Sales count
  final bool showSalePrice; // Revenue per piece
  final bool showVenueCommission; // Gallery/venue commission %

  // Retail additional
  final bool showItemsSold; // Count of items
  final bool showTransactionsCount; // Number of customers

  // Salon additional
  final bool showServicesCount; // Number of services
  final bool showNewClients; // New vs returning
  final bool showWalkins; // Walk-in vs appointment

  // Hospitality additional
  final bool showRoomsCleaned; // For housekeeping
  final bool showRoomUpgrades; // Upsells for front desk
  final bool showGuestsCheckedIn; // Front desk
  final bool showCarsParked; // Valet

  // Healthcare additional
  final bool showPatientCount; // Patients seen
  final bool showProceduresCount; // Procedures performed

  // Fitness additional
  final bool showSessionsCount; // Sessions/classes taught
  final bool showPackageSales; // Packages sold
  final bool showSupplementSales; // Supplements sold

  // Construction additional
  final bool showLaborCost; // Crew wages
  final bool showSubcontractorCost; // Specialist payments
  final bool showSquareFootage; // Work completed
  final bool showWeatherDelay; // Weather delay hours

  // Freelancer additional
  final bool showRevisionsCount; // Rounds of changes
  final bool showClientType; // Startup/SMB/Enterprise
  final bool showExpenses; // Software, equipment, travel
  final bool showBillableHours; // Billable hours

  // Restaurant additional
  final bool showTableSection; // Which station/section

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
    // Rideshare & Delivery
    this.showRidesCount = false,
    this.showDeadMiles = false,
    this.showFuelCost = false,
    this.showTollsParking = false,
    this.showSurgeMultiplier = false,
    this.showBaseFare = false,
    // Music & Entertainment
    this.showSetupHours = false,
    this.showPerformanceHours = false,
    this.showBreakdownHours = false,
    this.showEquipmentUsed = false,
    this.showCrewPayment = false,
    this.showMerchSales = false,
    this.showAudienceSize = false,
    // Artist & Crafts
    this.showPiecesCreated = false,
    this.showPiecesSold = false,
    this.showSalePrice = false,
    this.showVenueCommission = false,
    // Retail additional
    this.showItemsSold = false,
    this.showTransactionsCount = false,
    // Salon additional
    this.showServicesCount = false,
    this.showNewClients = false,
    this.showWalkins = false,
    // Hospitality additional
    this.showRoomsCleaned = false,
    this.showRoomUpgrades = false,
    this.showGuestsCheckedIn = false,
    this.showCarsParked = false,
    // Healthcare additional
    this.showPatientCount = false,
    this.showProceduresCount = false,
    // Fitness additional
    this.showSessionsCount = false,
    this.showPackageSales = false,
    this.showSupplementSales = false,
    // Construction additional
    this.showLaborCost = false,
    this.showSubcontractorCost = false,
    this.showSquareFootage = false,
    this.showWeatherDelay = false,
    // Freelancer additional
    this.showRevisionsCount = false,
    this.showClientType = false,
    this.showExpenses = false,
    this.showBillableHours = false,
    // Restaurant additional
    this.showTableSection = false,
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
      // Rideshare & Delivery
      showRidesCount: json['show_rides_count'] ?? false,
      showDeadMiles: json['show_dead_miles'] ?? false,
      showFuelCost: json['show_fuel_cost'] ?? false,
      showTollsParking: json['show_tolls_parking'] ?? false,
      showSurgeMultiplier: json['show_surge_multiplier'] ?? false,
      showBaseFare: json['show_base_fare'] ?? false,
      // Music & Entertainment
      showSetupHours: json['show_setup_hours'] ?? false,
      showPerformanceHours: json['show_performance_hours'] ?? false,
      showBreakdownHours: json['show_breakdown_hours'] ?? false,
      showEquipmentUsed: json['show_equipment_used'] ?? false,
      showCrewPayment: json['show_crew_payment'] ?? false,
      showMerchSales: json['show_merch_sales'] ?? false,
      showAudienceSize: json['show_audience_size'] ?? false,
      // Artist & Crafts
      showPiecesCreated: json['show_pieces_created'] ?? false,
      showPiecesSold: json['show_pieces_sold'] ?? false,
      showSalePrice: json['show_sale_price'] ?? false,
      showVenueCommission: json['show_venue_commission'] ?? false,
      // Retail additional
      showItemsSold: json['show_items_sold'] ?? false,
      showTransactionsCount: json['show_transactions_count'] ?? false,
      // Salon additional
      showServicesCount: json['show_services_count'] ?? false,
      showNewClients: json['show_new_clients'] ?? false,
      showWalkins: json['show_walkins'] ?? false,
      // Hospitality additional
      showRoomsCleaned: json['show_rooms_cleaned'] ?? false,
      showRoomUpgrades: json['show_room_upgrades'] ?? false,
      showGuestsCheckedIn: json['show_guests_checked_in'] ?? false,
      showCarsParked: json['show_cars_parked'] ?? false,
      // Healthcare additional
      showPatientCount: json['show_patient_count'] ?? false,
      showProceduresCount: json['show_procedures_count'] ?? false,
      // Fitness additional
      showSessionsCount: json['show_sessions_count'] ?? false,
      showPackageSales: json['show_package_sales'] ?? false,
      showSupplementSales: json['show_supplement_sales'] ?? false,
      // Construction additional
      showLaborCost: json['show_labor_cost'] ?? false,
      showSubcontractorCost: json['show_subcontractor_cost'] ?? false,
      showSquareFootage: json['show_square_footage'] ?? false,
      showWeatherDelay: json['show_weather_delay'] ?? false,
      // Freelancer additional
      showRevisionsCount: json['show_revisions_count'] ?? false,
      showClientType: json['show_client_type'] ?? false,
      showExpenses: json['show_expenses'] ?? false,
      showBillableHours: json['show_billable_hours'] ?? false,
      // Restaurant additional
      showTableSection: json['show_table_section'] ?? false,
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
      // Rideshare & Delivery
      'show_rides_count': showRidesCount,
      'show_dead_miles': showDeadMiles,
      'show_fuel_cost': showFuelCost,
      'show_tolls_parking': showTollsParking,
      'show_surge_multiplier': showSurgeMultiplier,
      'show_base_fare': showBaseFare,
      // Music & Entertainment
      'show_setup_hours': showSetupHours,
      'show_performance_hours': showPerformanceHours,
      'show_breakdown_hours': showBreakdownHours,
      'show_equipment_used': showEquipmentUsed,
      'show_crew_payment': showCrewPayment,
      'show_merch_sales': showMerchSales,
      'show_audience_size': showAudienceSize,
      // Artist & Crafts
      'show_pieces_created': showPiecesCreated,
      'show_pieces_sold': showPiecesSold,
      'show_sale_price': showSalePrice,
      'show_venue_commission': showVenueCommission,
      // Retail additional
      'show_items_sold': showItemsSold,
      'show_transactions_count': showTransactionsCount,
      // Salon additional
      'show_services_count': showServicesCount,
      'show_new_clients': showNewClients,
      'show_walkins': showWalkins,
      // Hospitality additional
      'show_rooms_cleaned': showRoomsCleaned,
      'show_room_upgrades': showRoomUpgrades,
      'show_guests_checked_in': showGuestsCheckedIn,
      'show_cars_parked': showCarsParked,
      // Healthcare additional
      'show_patient_count': showPatientCount,
      'show_procedures_count': showProceduresCount,
      // Fitness additional
      'show_sessions_count': showSessionsCount,
      'show_package_sales': showPackageSales,
      'show_supplement_sales': showSupplementSales,
      // Construction additional
      'show_labor_cost': showLaborCost,
      'show_subcontractor_cost': showSubcontractorCost,
      'show_square_footage': showSquareFootage,
      'show_weather_delay': showWeatherDelay,
      // Freelancer additional
      'show_revisions_count': showRevisionsCount,
      'show_client_type': showClientType,
      'show_expenses': showExpenses,
      'show_billable_hours': showBillableHours,
      // Restaurant additional
      'show_table_section': showTableSection,
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
      // Restaurant-specific fields
      showTableSection: true,
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
      // Construction-specific fields
      showLaborCost: true,
      showSubcontractorCost: true,
      showSquareFootage: true,
      showWeatherDelay: true,
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
      // Freelancer-specific fields
      showRevisionsCount: true,
      showClientType: true,
      showExpenses: true,
      showBillableHours: true,
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
      // Rideshare-specific fields
      showRidesCount: true,
      showDeadMiles: true,
      showFuelCost: true,
      showTollsParking: true,
      showSurgeMultiplier: true,
      showBaseFare: true,
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
      showGuestCount: true,
      // Music/Entertainment-specific fields
      showSetupHours: true,
      showPerformanceHours: true,
      showBreakdownHours: true,
      showEquipmentUsed: true,
      showCrewPayment: true,
      showMerchSales: true,
      showAudienceSize: true,
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
      // Artist/Crafts-specific fields
      showPiecesCreated: true,
      showPiecesSold: true,
      showSalePrice: true,
      showVenueCommission: true,
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
      showGuestCount: true,
      // Salon-specific fields
      showServicesCount: true,
      showNewClients: true,
      showWalkins: true,
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
      // Hospitality-specific fields
      showRoomsCleaned: true,
      showRoomUpgrades: true,
      showGuestsCheckedIn: true,
      showCarsParked: true,
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
      // Fitness-specific fields
      showSessionsCount: true,
      showPackageSales: true,
      showSupplementSales: true,
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
      // Healthcare-specific fields
      showPatientCount: true,
      showProceduresCount: true,
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
      // Retail-specific fields
      showItemsSold: true,
      showTransactionsCount: true,
      showShrink: true,
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
      showRepeatClientPercent:
          showRepeatClientPercent ?? this.showRepeatClientPercent,
      showRetentionRate: showRetentionRate ?? this.showRetentionRate,
      showQualityScore: showQualityScore ?? this.showQualityScore,
      showCancellations: showCancellations ?? this.showCancellations,
      showChairRental: showChairRental ?? this.showChairRental,
      showOnCallHours: showOnCallHours ?? this.showOnCallHours,
      showRoomType: showRoomType ?? this.showRoomType,
      showShiftType: showShiftType ?? this.showShiftType,
      showShiftDifferential:
          showShiftDifferential ?? this.showShiftDifferential,
    );
  }
}

enum PayStructure {
  hourly, // Paid per hour
  flatRate, // Paid per project/job
  salary, // Annual salary (just track hours)
  commission // Percentage-based
}
