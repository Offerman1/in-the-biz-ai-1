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

  // =====================================================
  // RIDESHARE & DELIVERY FIELDS
  // =====================================================
  final int? ridesCount;
  final int? deliveriesCount;
  final double? deadMiles;
  final double? fuelCost;
  final double? tollsParking;
  final double? surgeMultiplier;
  final double? acceptanceRate;
  final double? baseFare;

  // =====================================================
  // MUSIC & ENTERTAINMENT FIELDS
  // =====================================================
  final String? gigType;
  final double? setupHours;
  final double? performanceHours;
  final double? breakdownHours;
  final String? equipmentUsed;
  final double? equipmentRentalCost;
  final double? crewPayment;
  final double? merchSales;
  final int? audienceSize;

  // =====================================================
  // ARTIST & CRAFTS FIELDS
  // =====================================================
  final int? piecesCreated;
  final int? piecesSold;
  final double? materialsCost;
  final double? salePrice;
  final double? venueCommissionPercent;

  // =====================================================
  // RETAIL/SALES FIELDS
  // =====================================================
  final int? itemsSold;
  final int? transactionsCount;
  final int? upsellsCount;
  final double? upsellsAmount;
  final int? returnsCount;
  final double? returnsAmount;
  final double? shrinkAmount;
  final String? department;

  // =====================================================
  // SALON/SPA FIELDS
  // =====================================================
  final String? serviceType;
  final int? servicesCount;
  final double? productSales;
  final double? repeatClientPercent;
  final double? chairRental;
  final int? newClientsCount;
  final int? returningClientsCount;
  final int? walkinCount;
  final int? appointmentCount;

  // =====================================================
  // HOSPITALITY FIELDS
  // =====================================================
  final String? roomType;
  final int? roomsCleaned;
  final double? qualityScore;
  final String? shiftType;
  final int? roomUpgrades;
  final int? guestsCheckedIn;
  final int? carsParked;

  // =====================================================
  // HEALTHCARE FIELDS
  // =====================================================
  final int? patientCount;
  final double? shiftDifferential;
  final double? onCallHours;
  final int? proceduresCount;
  final String? specialization;

  // =====================================================
  // FITNESS FIELDS
  // =====================================================
  final int? sessionsCount;
  final String? sessionType;
  final int? classSize;
  final double? retentionRate;
  final int? cancellationsCount;
  final double? packageSales;
  final double? supplementSales;

  // =====================================================
  // CONSTRUCTION/TRADES FIELDS
  // =====================================================
  final double? laborCost;
  final double? subcontractorCost;
  final double? squareFootage;
  final double? weatherDelayHours;

  // =====================================================
  // FREELANCER FIELDS
  // =====================================================
  final int? revisionsCount;
  final String? clientType;
  final double? expenses;
  final double? billableHours;

  // =====================================================
  // RESTAURANT FIELDS (additional)
  // =====================================================
  final String? tableSection;
  final double? cashSales;
  final double? cardSales;

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
    // Rideshare & Delivery
    this.ridesCount,
    this.deliveriesCount,
    this.deadMiles,
    this.fuelCost,
    this.tollsParking,
    this.surgeMultiplier,
    this.acceptanceRate,
    this.baseFare,
    // Music & Entertainment
    this.gigType,
    this.setupHours,
    this.performanceHours,
    this.breakdownHours,
    this.equipmentUsed,
    this.equipmentRentalCost,
    this.crewPayment,
    this.merchSales,
    this.audienceSize,
    // Artist & Crafts
    this.piecesCreated,
    this.piecesSold,
    this.materialsCost,
    this.salePrice,
    this.venueCommissionPercent,
    // Retail/Sales
    this.itemsSold,
    this.transactionsCount,
    this.upsellsCount,
    this.upsellsAmount,
    this.returnsCount,
    this.returnsAmount,
    this.shrinkAmount,
    this.department,
    // Salon/Spa
    this.serviceType,
    this.servicesCount,
    this.productSales,
    this.repeatClientPercent,
    this.chairRental,
    this.newClientsCount,
    this.returningClientsCount,
    this.walkinCount,
    this.appointmentCount,
    // Hospitality
    this.roomType,
    this.roomsCleaned,
    this.qualityScore,
    this.shiftType,
    this.roomUpgrades,
    this.guestsCheckedIn,
    this.carsParked,
    // Healthcare
    this.patientCount,
    this.shiftDifferential,
    this.onCallHours,
    this.proceduresCount,
    this.specialization,
    // Fitness
    this.sessionsCount,
    this.sessionType,
    this.classSize,
    this.retentionRate,
    this.cancellationsCount,
    this.packageSales,
    this.supplementSales,
    // Construction/Trades
    this.laborCost,
    this.subcontractorCost,
    this.squareFootage,
    this.weatherDelayHours,
    // Freelancer
    this.revisionsCount,
    this.clientType,
    this.expenses,
    this.billableHours,
    // Restaurant
    this.tableSection,
    this.cashSales,
    this.cardSales,
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
    // Rideshare & Delivery
    int? ridesCount,
    int? deliveriesCount,
    double? deadMiles,
    double? fuelCost,
    double? tollsParking,
    double? surgeMultiplier,
    double? acceptanceRate,
    double? baseFare,
    // Music & Entertainment
    String? gigType,
    double? setupHours,
    double? performanceHours,
    double? breakdownHours,
    String? equipmentUsed,
    double? equipmentRentalCost,
    double? crewPayment,
    double? merchSales,
    int? audienceSize,
    // Artist & Crafts
    int? piecesCreated,
    int? piecesSold,
    double? materialsCost,
    double? salePrice,
    double? venueCommissionPercent,
    // Retail/Sales
    int? itemsSold,
    int? transactionsCount,
    int? upsellsCount,
    double? upsellsAmount,
    int? returnsCount,
    double? returnsAmount,
    double? shrinkAmount,
    String? department,
    // Salon/Spa
    String? serviceType,
    int? servicesCount,
    double? productSales,
    double? repeatClientPercent,
    double? chairRental,
    int? newClientsCount,
    int? returningClientsCount,
    int? walkinCount,
    int? appointmentCount,
    // Hospitality
    String? roomType,
    int? roomsCleaned,
    double? qualityScore,
    String? shiftType,
    int? roomUpgrades,
    int? guestsCheckedIn,
    int? carsParked,
    // Healthcare
    int? patientCount,
    double? shiftDifferential,
    double? onCallHours,
    int? proceduresCount,
    String? specialization,
    // Fitness
    int? sessionsCount,
    String? sessionType,
    int? classSize,
    double? retentionRate,
    int? cancellationsCount,
    double? packageSales,
    double? supplementSales,
    // Construction/Trades
    double? laborCost,
    double? subcontractorCost,
    double? squareFootage,
    double? weatherDelayHours,
    // Freelancer
    int? revisionsCount,
    String? clientType,
    double? expenses,
    double? billableHours,
    // Restaurant
    String? tableSection,
    double? cashSales,
    double? cardSales,
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
      // Rideshare & Delivery
      ridesCount: ridesCount ?? this.ridesCount,
      deliveriesCount: deliveriesCount ?? this.deliveriesCount,
      deadMiles: deadMiles ?? this.deadMiles,
      fuelCost: fuelCost ?? this.fuelCost,
      tollsParking: tollsParking ?? this.tollsParking,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      baseFare: baseFare ?? this.baseFare,
      // Music & Entertainment
      gigType: gigType ?? this.gigType,
      setupHours: setupHours ?? this.setupHours,
      performanceHours: performanceHours ?? this.performanceHours,
      breakdownHours: breakdownHours ?? this.breakdownHours,
      equipmentUsed: equipmentUsed ?? this.equipmentUsed,
      equipmentRentalCost: equipmentRentalCost ?? this.equipmentRentalCost,
      crewPayment: crewPayment ?? this.crewPayment,
      merchSales: merchSales ?? this.merchSales,
      audienceSize: audienceSize ?? this.audienceSize,
      // Artist & Crafts
      piecesCreated: piecesCreated ?? this.piecesCreated,
      piecesSold: piecesSold ?? this.piecesSold,
      materialsCost: materialsCost ?? this.materialsCost,
      salePrice: salePrice ?? this.salePrice,
      venueCommissionPercent: venueCommissionPercent ?? this.venueCommissionPercent,
      // Retail/Sales
      itemsSold: itemsSold ?? this.itemsSold,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      upsellsCount: upsellsCount ?? this.upsellsCount,
      upsellsAmount: upsellsAmount ?? this.upsellsAmount,
      returnsCount: returnsCount ?? this.returnsCount,
      returnsAmount: returnsAmount ?? this.returnsAmount,
      shrinkAmount: shrinkAmount ?? this.shrinkAmount,
      department: department ?? this.department,
      // Salon/Spa
      serviceType: serviceType ?? this.serviceType,
      servicesCount: servicesCount ?? this.servicesCount,
      productSales: productSales ?? this.productSales,
      repeatClientPercent: repeatClientPercent ?? this.repeatClientPercent,
      chairRental: chairRental ?? this.chairRental,
      newClientsCount: newClientsCount ?? this.newClientsCount,
      returningClientsCount: returningClientsCount ?? this.returningClientsCount,
      walkinCount: walkinCount ?? this.walkinCount,
      appointmentCount: appointmentCount ?? this.appointmentCount,
      // Hospitality
      roomType: roomType ?? this.roomType,
      roomsCleaned: roomsCleaned ?? this.roomsCleaned,
      qualityScore: qualityScore ?? this.qualityScore,
      shiftType: shiftType ?? this.shiftType,
      roomUpgrades: roomUpgrades ?? this.roomUpgrades,
      guestsCheckedIn: guestsCheckedIn ?? this.guestsCheckedIn,
      carsParked: carsParked ?? this.carsParked,
      // Healthcare
      patientCount: patientCount ?? this.patientCount,
      shiftDifferential: shiftDifferential ?? this.shiftDifferential,
      onCallHours: onCallHours ?? this.onCallHours,
      proceduresCount: proceduresCount ?? this.proceduresCount,
      specialization: specialization ?? this.specialization,
      // Fitness
      sessionsCount: sessionsCount ?? this.sessionsCount,
      sessionType: sessionType ?? this.sessionType,
      classSize: classSize ?? this.classSize,
      retentionRate: retentionRate ?? this.retentionRate,
      cancellationsCount: cancellationsCount ?? this.cancellationsCount,
      packageSales: packageSales ?? this.packageSales,
      supplementSales: supplementSales ?? this.supplementSales,
      // Construction/Trades
      laborCost: laborCost ?? this.laborCost,
      subcontractorCost: subcontractorCost ?? this.subcontractorCost,
      squareFootage: squareFootage ?? this.squareFootage,
      weatherDelayHours: weatherDelayHours ?? this.weatherDelayHours,
      // Freelancer
      revisionsCount: revisionsCount ?? this.revisionsCount,
      clientType: clientType ?? this.clientType,
      expenses: expenses ?? this.expenses,
      billableHours: billableHours ?? this.billableHours,
      // Restaurant
      tableSection: tableSection ?? this.tableSection,
      cashSales: cashSales ?? this.cashSales,
      cardSales: cardSales ?? this.cardSales,
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
      // Rideshare & Delivery
      'ridesCount': ridesCount,
      'deliveriesCount': deliveriesCount,
      'deadMiles': deadMiles,
      'fuelCost': fuelCost,
      'tollsParking': tollsParking,
      'surgeMultiplier': surgeMultiplier,
      'acceptanceRate': acceptanceRate,
      'baseFare': baseFare,
      // Music & Entertainment
      'gigType': gigType,
      'setupHours': setupHours,
      'performanceHours': performanceHours,
      'breakdownHours': breakdownHours,
      'equipmentUsed': equipmentUsed,
      'equipmentRentalCost': equipmentRentalCost,
      'crewPayment': crewPayment,
      'merchSales': merchSales,
      'audienceSize': audienceSize,
      // Artist & Crafts
      'piecesCreated': piecesCreated,
      'piecesSold': piecesSold,
      'materialsCost': materialsCost,
      'salePrice': salePrice,
      'venueCommissionPercent': venueCommissionPercent,
      // Retail/Sales
      'itemsSold': itemsSold,
      'transactionsCount': transactionsCount,
      'upsellsCount': upsellsCount,
      'upsellsAmount': upsellsAmount,
      'returnsCount': returnsCount,
      'returnsAmount': returnsAmount,
      'shrinkAmount': shrinkAmount,
      'department': department,
      // Salon/Spa
      'serviceType': serviceType,
      'servicesCount': servicesCount,
      'productSales': productSales,
      'repeatClientPercent': repeatClientPercent,
      'chairRental': chairRental,
      'newClientsCount': newClientsCount,
      'returningClientsCount': returningClientsCount,
      'walkinCount': walkinCount,
      'appointmentCount': appointmentCount,
      // Hospitality
      'roomType': roomType,
      'roomsCleaned': roomsCleaned,
      'qualityScore': qualityScore,
      'shiftType': shiftType,
      'roomUpgrades': roomUpgrades,
      'guestsCheckedIn': guestsCheckedIn,
      'carsParked': carsParked,
      // Healthcare
      'patientCount': patientCount,
      'shiftDifferential': shiftDifferential,
      'onCallHours': onCallHours,
      'proceduresCount': proceduresCount,
      'specialization': specialization,
      // Fitness
      'sessionsCount': sessionsCount,
      'sessionType': sessionType,
      'classSize': classSize,
      'retentionRate': retentionRate,
      'cancellationsCount': cancellationsCount,
      'packageSales': packageSales,
      'supplementSales': supplementSales,
      // Construction/Trades
      'laborCost': laborCost,
      'subcontractorCost': subcontractorCost,
      'squareFootage': squareFootage,
      'weatherDelayHours': weatherDelayHours,
      // Freelancer
      'revisionsCount': revisionsCount,
      'clientType': clientType,
      'expenses': expenses,
      'billableHours': billableHours,
      // Restaurant
      'tableSection': tableSection,
      'cashSales': cashSales,
      'cardSales': cardSales,
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
      // Rideshare & Delivery
      ridesCount: map['ridesCount'],
      deliveriesCount: map['deliveriesCount'],
      deadMiles: map['deadMiles']?.toDouble(),
      fuelCost: map['fuelCost']?.toDouble(),
      tollsParking: map['tollsParking']?.toDouble(),
      surgeMultiplier: map['surgeMultiplier']?.toDouble(),
      acceptanceRate: map['acceptanceRate']?.toDouble(),
      baseFare: map['baseFare']?.toDouble(),
      // Music & Entertainment
      gigType: map['gigType'],
      setupHours: map['setupHours']?.toDouble(),
      performanceHours: map['performanceHours']?.toDouble(),
      breakdownHours: map['breakdownHours']?.toDouble(),
      equipmentUsed: map['equipmentUsed'],
      equipmentRentalCost: map['equipmentRentalCost']?.toDouble(),
      crewPayment: map['crewPayment']?.toDouble(),
      merchSales: map['merchSales']?.toDouble(),
      audienceSize: map['audienceSize'],
      // Artist & Crafts
      piecesCreated: map['piecesCreated'],
      piecesSold: map['piecesSold'],
      materialsCost: map['materialsCost']?.toDouble(),
      salePrice: map['salePrice']?.toDouble(),
      venueCommissionPercent: map['venueCommissionPercent']?.toDouble(),
      // Retail/Sales
      itemsSold: map['itemsSold'],
      transactionsCount: map['transactionsCount'],
      upsellsCount: map['upsellsCount'],
      upsellsAmount: map['upsellsAmount']?.toDouble(),
      returnsCount: map['returnsCount'],
      returnsAmount: map['returnsAmount']?.toDouble(),
      shrinkAmount: map['shrinkAmount']?.toDouble(),
      department: map['department'],
      // Salon/Spa
      serviceType: map['serviceType'],
      servicesCount: map['servicesCount'],
      productSales: map['productSales']?.toDouble(),
      repeatClientPercent: map['repeatClientPercent']?.toDouble(),
      chairRental: map['chairRental']?.toDouble(),
      newClientsCount: map['newClientsCount'],
      returningClientsCount: map['returningClientsCount'],
      walkinCount: map['walkinCount'],
      appointmentCount: map['appointmentCount'],
      // Hospitality
      roomType: map['roomType'],
      roomsCleaned: map['roomsCleaned'],
      qualityScore: map['qualityScore']?.toDouble(),
      shiftType: map['shiftType'],
      roomUpgrades: map['roomUpgrades'],
      guestsCheckedIn: map['guestsCheckedIn'],
      carsParked: map['carsParked'],
      // Healthcare
      patientCount: map['patientCount'],
      shiftDifferential: map['shiftDifferential']?.toDouble(),
      onCallHours: map['onCallHours']?.toDouble(),
      proceduresCount: map['proceduresCount'],
      specialization: map['specialization'],
      // Fitness
      sessionsCount: map['sessionsCount'],
      sessionType: map['sessionType'],
      classSize: map['classSize'],
      retentionRate: map['retentionRate']?.toDouble(),
      cancellationsCount: map['cancellationsCount'],
      packageSales: map['packageSales']?.toDouble(),
      supplementSales: map['supplementSales']?.toDouble(),
      // Construction/Trades
      laborCost: map['laborCost']?.toDouble(),
      subcontractorCost: map['subcontractorCost']?.toDouble(),
      squareFootage: map['squareFootage']?.toDouble(),
      weatherDelayHours: map['weatherDelayHours']?.toDouble(),
      // Freelancer
      revisionsCount: map['revisionsCount'],
      clientType: map['clientType'],
      expenses: map['expenses']?.toDouble(),
      billableHours: map['billableHours']?.toDouble(),
      // Restaurant
      tableSection: map['tableSection'],
      cashSales: map['cashSales']?.toDouble(),
      cardSales: map['cardSales']?.toDouble(),
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
