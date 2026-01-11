/// BeoEvent Model - Represents a Banquet Event Order
/// Supports comprehensive event management with all industry-standard fields
class BeoEvent {
  final String id;
  final String userId;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: EVENT IDENTITY & CONTACTS
  // ═══════════════════════════════════════════════════════════════════════════
  final String eventName;
  final DateTime eventDate;
  final String? eventType;
  final String? postAs;
  final String? venueName;
  final String? venueAddress;
  final String? functionSpace;
  final String? accountName;

  // Client Contact
  final String? primaryContactName;
  final String? primaryContactPhone;
  final String? primaryContactEmail;

  // Internal Contacts
  final String? salesManagerName;
  final String? salesManagerPhone;
  final String? salesManagerEmail;
  final String? cateringManagerName;
  final String? cateringManagerPhone;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: TIMELINE & LOGISTICS
  // ═══════════════════════════════════════════════════════════════════════════
  final DateTime? setupDate;
  final DateTime? teardownDate;
  final String? loadInTime;
  final String? setupTime;
  final String? guestArrivalTime;
  final String? eventStartTime;
  final String? eventEndTime;
  final String? breakdownTime;
  final String? loadOutTime;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: GUEST COUNTS
  // ═══════════════════════════════════════════════════════════════════════════
  final int? guestCountExpected;
  final int? guestCountConfirmed;
  final int? adultCount;
  final int? childCount;
  final int? vendorMealCount;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4: FINANCIALS
  // ═══════════════════════════════════════════════════════════════════════════
  final double? foodTotal;
  final double? beverageTotal;
  final double? laborTotal;
  final double? roomRental;
  final double? equipmentRental;
  final double? subtotal;
  final double? serviceChargePercent;
  final double? serviceChargeAmount;
  final double? taxPercent;
  final double? taxAmount;
  final double? gratuityAmount;
  final double? grandTotal;
  final double? depositsPaid;
  final double? depositAmount;
  final double? balanceDue;
  final double? totalSaleAmount;
  final double? commissionPercentage;
  final double? commissionAmount;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5: FOOD & BEVERAGE
  // ═══════════════════════════════════════════════════════════════════════════
  final String? menuStyle;
  final Map<String, dynamic>? menuDetails;
  final Map<String, dynamic>? beverageDetails;
  final String? menuItems;
  final String? dietaryRestrictions;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 6: SETUP & DECOR
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, dynamic>? setupDetails;
  final String? decorNotes;
  final String? floorPlanNotes;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 7: STAFFING & VENDORS
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, dynamic>? staffingDetails;
  final String? staffingRequirements;
  final List<Map<String, dynamic>>? vendorDetails;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 8: TIMELINE/AGENDA
  // ═══════════════════════════════════════════════════════════════════════════
  final List<Map<String, dynamic>>? eventTimeline;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 9: BILLING & LEGAL
  // ═══════════════════════════════════════════════════════════════════════════
  final String? paymentMethod;
  final String? cancellationPolicy;
  final DateTime? clientSignatureDate;
  final DateTime? venueSignatureDate;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 10: NOTES & METADATA
  // ═══════════════════════════════════════════════════════════════════════════
  final String? specialRequests;
  final String? formattedNotes;
  final List<String>? imageUrls;
  final Map<String, dynamic>? aiConfidenceScores;
  final Map<String, dynamic>? rawAiResponse;

  // Flags
  final bool isStandalone;
  final bool createdManually;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  BeoEvent({
    required this.id,
    required this.userId,
    required this.eventName,
    required this.eventDate,
    this.eventType,
    this.postAs,
    this.venueName,
    this.venueAddress,
    this.functionSpace,
    this.accountName,
    this.primaryContactName,
    this.primaryContactPhone,
    this.primaryContactEmail,
    this.salesManagerName,
    this.salesManagerPhone,
    this.salesManagerEmail,
    this.cateringManagerName,
    this.cateringManagerPhone,
    this.setupDate,
    this.teardownDate,
    this.loadInTime,
    this.setupTime,
    this.guestArrivalTime,
    this.eventStartTime,
    this.eventEndTime,
    this.breakdownTime,
    this.loadOutTime,
    this.guestCountExpected,
    this.guestCountConfirmed,
    this.adultCount,
    this.childCount,
    this.vendorMealCount,
    this.foodTotal,
    this.beverageTotal,
    this.laborTotal,
    this.roomRental,
    this.equipmentRental,
    this.subtotal,
    this.serviceChargePercent,
    this.serviceChargeAmount,
    this.taxPercent,
    this.taxAmount,
    this.gratuityAmount,
    this.grandTotal,
    this.depositsPaid,
    this.depositAmount,
    this.balanceDue,
    this.totalSaleAmount,
    this.commissionPercentage,
    this.commissionAmount,
    this.menuStyle,
    this.menuDetails,
    this.beverageDetails,
    this.menuItems,
    this.dietaryRestrictions,
    this.setupDetails,
    this.decorNotes,
    this.floorPlanNotes,
    this.staffingDetails,
    this.staffingRequirements,
    this.vendorDetails,
    this.eventTimeline,
    this.paymentMethod,
    this.cancellationPolicy,
    this.clientSignatureDate,
    this.venueSignatureDate,
    this.specialRequests,
    this.formattedNotes,
    this.imageUrls,
    this.aiConfidenceScores,
    this.rawAiResponse,
    this.isStandalone = false,
    this.createdManually = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase/API response
  factory BeoEvent.fromJson(Map<String, dynamic> json) {
    return BeoEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventName: json['event_name'] as String? ?? 'Untitled Event',
      eventDate: DateTime.parse(json['event_date'] as String),
      eventType: json['event_type'] as String?,
      postAs: json['post_as'] as String?,
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      functionSpace: json['function_space'] as String?,
      accountName: json['account_name'] as String?,
      primaryContactName: json['primary_contact_name'] as String?,
      primaryContactPhone: json['primary_contact_phone'] as String?,
      primaryContactEmail: json['primary_contact_email'] as String?,
      salesManagerName: json['sales_manager_name'] as String?,
      salesManagerPhone: json['sales_manager_phone'] as String?,
      salesManagerEmail: json['sales_manager_email'] as String?,
      cateringManagerName: json['catering_manager_name'] as String?,
      cateringManagerPhone: json['catering_manager_phone'] as String?,
      setupDate: json['setup_date'] != null
          ? DateTime.parse(json['setup_date'] as String)
          : null,
      teardownDate: json['teardown_date'] != null
          ? DateTime.parse(json['teardown_date'] as String)
          : null,
      loadInTime: json['load_in_time'] as String?,
      setupTime: json['setup_time'] as String?,
      guestArrivalTime: json['guest_arrival_time'] as String?,
      eventStartTime: json['event_start_time'] as String?,
      eventEndTime: json['event_end_time'] as String?,
      breakdownTime: json['breakdown_time'] as String?,
      loadOutTime: json['load_out_time'] as String?,
      guestCountExpected: json['guest_count_expected'] as int?,
      guestCountConfirmed: json['guest_count_confirmed'] as int?,
      adultCount: json['adult_count'] as int?,
      childCount: json['child_count'] as int?,
      vendorMealCount: json['vendor_meal_count'] as int?,
      foodTotal: _parseDouble(json['food_total']),
      beverageTotal: _parseDouble(json['beverage_total']),
      laborTotal: _parseDouble(json['labor_total']),
      roomRental: _parseDouble(json['room_rental']),
      equipmentRental: _parseDouble(json['equipment_rental']),
      subtotal: _parseDouble(json['subtotal']),
      serviceChargePercent: _parseDouble(json['service_charge_percent']),
      serviceChargeAmount: _parseDouble(json['service_charge_amount']),
      taxPercent: _parseDouble(json['tax_percent']),
      taxAmount: _parseDouble(json['tax_amount']),
      gratuityAmount: _parseDouble(json['gratuity_amount']),
      grandTotal: _parseDouble(json['grand_total']),
      depositsPaid: _parseDouble(json['deposits_paid']),
      depositAmount: _parseDouble(json['deposit_amount']),
      balanceDue: _parseDouble(json['balance_due']),
      totalSaleAmount: _parseDouble(json['total_sale_amount']),
      commissionPercentage: _parseDouble(json['commission_percentage']),
      commissionAmount: _parseDouble(json['commission_amount']),
      menuStyle: json['menu_style'] as String?,
      menuDetails: json['menu_details'] as Map<String, dynamic>?,
      beverageDetails: json['beverage_details'] as Map<String, dynamic>?,
      menuItems: json['menu_items'] as String?,
      dietaryRestrictions: json['dietary_restrictions'] as String?,
      setupDetails: json['setup_details'] as Map<String, dynamic>?,
      decorNotes: json['decor_notes'] as String?,
      floorPlanNotes: json['floor_plan_notes'] as String?,
      staffingDetails: json['staffing_details'] as Map<String, dynamic>?,
      staffingRequirements: json['staffing_requirements'] as String?,
      vendorDetails: json['vendor_details'] != null
          ? List<Map<String, dynamic>>.from((json['vendor_details'] as List)
              .map((e) => e as Map<String, dynamic>))
          : null,
      eventTimeline: json['event_timeline'] != null
          ? List<Map<String, dynamic>>.from((json['event_timeline'] as List)
              .map((e) => e as Map<String, dynamic>))
          : null,
      paymentMethod: json['payment_method'] as String?,
      cancellationPolicy: json['cancellation_policy'] as String?,
      clientSignatureDate: json['client_signature_date'] != null
          ? DateTime.parse(json['client_signature_date'] as String)
          : null,
      venueSignatureDate: json['venue_signature_date'] != null
          ? DateTime.parse(json['venue_signature_date'] as String)
          : null,
      specialRequests: json['special_requests'] as String?,
      formattedNotes: json['formatted_notes'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      aiConfidenceScores: json['ai_confidence_scores'] as Map<String, dynamic>?,
      rawAiResponse: json['raw_ai_response'] as Map<String, dynamic>?,
      isStandalone: json['is_standalone'] as bool? ?? false,
      createdManually: json['created_manually'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API/database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_name': eventName,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'event_type': eventType,
      'post_as': postAs,
      'venue_name': venueName,
      'venue_address': venueAddress,
      'function_space': functionSpace,
      'account_name': accountName,
      'primary_contact_name': primaryContactName,
      'primary_contact_phone': primaryContactPhone,
      'primary_contact_email': primaryContactEmail,
      'sales_manager_name': salesManagerName,
      'sales_manager_phone': salesManagerPhone,
      'sales_manager_email': salesManagerEmail,
      'catering_manager_name': cateringManagerName,
      'catering_manager_phone': cateringManagerPhone,
      'setup_date': setupDate?.toIso8601String().split('T')[0],
      'teardown_date': teardownDate?.toIso8601String().split('T')[0],
      'load_in_time': loadInTime,
      'setup_time': setupTime,
      'guest_arrival_time': guestArrivalTime,
      'event_start_time': eventStartTime,
      'event_end_time': eventEndTime,
      'breakdown_time': breakdownTime,
      'load_out_time': loadOutTime,
      'guest_count_expected': guestCountExpected,
      'guest_count_confirmed': guestCountConfirmed,
      'adult_count': adultCount,
      'child_count': childCount,
      'vendor_meal_count': vendorMealCount,
      'food_total': foodTotal,
      'beverage_total': beverageTotal,
      'labor_total': laborTotal,
      'room_rental': roomRental,
      'equipment_rental': equipmentRental,
      'subtotal': subtotal,
      'service_charge_percent': serviceChargePercent,
      'service_charge_amount': serviceChargeAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'gratuity_amount': gratuityAmount,
      'grand_total': grandTotal,
      'deposits_paid': depositsPaid,
      'deposit_amount': depositAmount,
      'balance_due': balanceDue,
      'total_sale_amount': totalSaleAmount,
      'commission_percentage': commissionPercentage,
      'commission_amount': commissionAmount,
      'menu_style': menuStyle,
      'menu_details': menuDetails,
      'beverage_details': beverageDetails,
      'menu_items': menuItems,
      'dietary_restrictions': dietaryRestrictions,
      'setup_details': setupDetails,
      'decor_notes': decorNotes,
      'floor_plan_notes': floorPlanNotes,
      'staffing_details': staffingDetails,
      'staffing_requirements': staffingRequirements,
      'vendor_details': vendorDetails,
      'event_timeline': eventTimeline,
      'payment_method': paymentMethod,
      'cancellation_policy': cancellationPolicy,
      'client_signature_date': clientSignatureDate?.toIso8601String(),
      'venue_signature_date': venueSignatureDate?.toIso8601String(),
      'special_requests': specialRequests,
      'formatted_notes': formattedNotes,
      'image_urls': imageUrls,
      'ai_confidence_scores': aiConfidenceScores,
      'raw_ai_response': rawAiResponse,
      'is_standalone': isStandalone,
      'created_manually': createdManually,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper to safely parse doubles
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Create a copy with modified fields
  BeoEvent copyWith({
    String? id,
    String? userId,
    String? eventName,
    DateTime? eventDate,
    String? eventType,
    String? postAs,
    String? venueName,
    String? venueAddress,
    String? functionSpace,
    String? accountName,
    String? primaryContactName,
    String? primaryContactPhone,
    String? primaryContactEmail,
    String? salesManagerName,
    String? salesManagerPhone,
    String? salesManagerEmail,
    String? cateringManagerName,
    String? cateringManagerPhone,
    DateTime? setupDate,
    DateTime? teardownDate,
    String? loadInTime,
    String? setupTime,
    String? guestArrivalTime,
    String? eventStartTime,
    String? eventEndTime,
    String? breakdownTime,
    String? loadOutTime,
    int? guestCountExpected,
    int? guestCountConfirmed,
    int? adultCount,
    int? childCount,
    int? vendorMealCount,
    double? foodTotal,
    double? beverageTotal,
    double? laborTotal,
    double? roomRental,
    double? equipmentRental,
    double? subtotal,
    double? serviceChargePercent,
    double? serviceChargeAmount,
    double? taxPercent,
    double? taxAmount,
    double? gratuityAmount,
    double? grandTotal,
    double? depositsPaid,
    double? depositAmount,
    double? balanceDue,
    double? totalSaleAmount,
    double? commissionPercentage,
    double? commissionAmount,
    String? menuStyle,
    Map<String, dynamic>? menuDetails,
    Map<String, dynamic>? beverageDetails,
    String? menuItems,
    String? dietaryRestrictions,
    Map<String, dynamic>? setupDetails,
    String? decorNotes,
    String? floorPlanNotes,
    Map<String, dynamic>? staffingDetails,
    String? staffingRequirements,
    List<Map<String, dynamic>>? vendorDetails,
    List<Map<String, dynamic>>? eventTimeline,
    String? paymentMethod,
    String? cancellationPolicy,
    DateTime? clientSignatureDate,
    DateTime? venueSignatureDate,
    String? specialRequests,
    String? formattedNotes,
    List<String>? imageUrls,
    Map<String, dynamic>? aiConfidenceScores,
    Map<String, dynamic>? rawAiResponse,
    bool? isStandalone,
    bool? createdManually,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BeoEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      eventType: eventType ?? this.eventType,
      postAs: postAs ?? this.postAs,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      functionSpace: functionSpace ?? this.functionSpace,
      accountName: accountName ?? this.accountName,
      primaryContactName: primaryContactName ?? this.primaryContactName,
      primaryContactPhone: primaryContactPhone ?? this.primaryContactPhone,
      primaryContactEmail: primaryContactEmail ?? this.primaryContactEmail,
      salesManagerName: salesManagerName ?? this.salesManagerName,
      salesManagerPhone: salesManagerPhone ?? this.salesManagerPhone,
      salesManagerEmail: salesManagerEmail ?? this.salesManagerEmail,
      cateringManagerName: cateringManagerName ?? this.cateringManagerName,
      cateringManagerPhone: cateringManagerPhone ?? this.cateringManagerPhone,
      setupDate: setupDate ?? this.setupDate,
      teardownDate: teardownDate ?? this.teardownDate,
      loadInTime: loadInTime ?? this.loadInTime,
      setupTime: setupTime ?? this.setupTime,
      guestArrivalTime: guestArrivalTime ?? this.guestArrivalTime,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      breakdownTime: breakdownTime ?? this.breakdownTime,
      loadOutTime: loadOutTime ?? this.loadOutTime,
      guestCountExpected: guestCountExpected ?? this.guestCountExpected,
      guestCountConfirmed: guestCountConfirmed ?? this.guestCountConfirmed,
      adultCount: adultCount ?? this.adultCount,
      childCount: childCount ?? this.childCount,
      vendorMealCount: vendorMealCount ?? this.vendorMealCount,
      foodTotal: foodTotal ?? this.foodTotal,
      beverageTotal: beverageTotal ?? this.beverageTotal,
      laborTotal: laborTotal ?? this.laborTotal,
      roomRental: roomRental ?? this.roomRental,
      equipmentRental: equipmentRental ?? this.equipmentRental,
      subtotal: subtotal ?? this.subtotal,
      serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
      serviceChargeAmount: serviceChargeAmount ?? this.serviceChargeAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      gratuityAmount: gratuityAmount ?? this.gratuityAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      depositsPaid: depositsPaid ?? this.depositsPaid,
      depositAmount: depositAmount ?? this.depositAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      totalSaleAmount: totalSaleAmount ?? this.totalSaleAmount,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      menuStyle: menuStyle ?? this.menuStyle,
      menuDetails: menuDetails ?? this.menuDetails,
      beverageDetails: beverageDetails ?? this.beverageDetails,
      menuItems: menuItems ?? this.menuItems,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      setupDetails: setupDetails ?? this.setupDetails,
      decorNotes: decorNotes ?? this.decorNotes,
      floorPlanNotes: floorPlanNotes ?? this.floorPlanNotes,
      staffingDetails: staffingDetails ?? this.staffingDetails,
      staffingRequirements: staffingRequirements ?? this.staffingRequirements,
      vendorDetails: vendorDetails ?? this.vendorDetails,
      eventTimeline: eventTimeline ?? this.eventTimeline,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      clientSignatureDate: clientSignatureDate ?? this.clientSignatureDate,
      venueSignatureDate: venueSignatureDate ?? this.venueSignatureDate,
      specialRequests: specialRequests ?? this.specialRequests,
      formattedNotes: formattedNotes ?? this.formattedNotes,
      imageUrls: imageUrls ?? this.imageUrls,
      aiConfidenceScores: aiConfidenceScores ?? this.aiConfidenceScores,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      isStandalone: isStandalone ?? this.isStandalone,
      createdManually: createdManually ?? this.createdManually,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the display guest count (confirmed or expected)
  int? get displayGuestCount => guestCountConfirmed ?? guestCountExpected;

  /// Get the display total (grand total or total sale amount)
  double? get displayTotal => grandTotal ?? totalSaleAmount;

  /// Check if this BEO has financial data
  bool get hasFinancials =>
      foodTotal != null ||
      beverageTotal != null ||
      grandTotal != null ||
      totalSaleAmount != null;

  /// Check if this BEO has menu data
  bool get hasMenu =>
      menuDetails != null || (menuItems != null && menuItems!.isNotEmpty);

  /// Check if this BEO has staffing data
  bool get hasStaffing =>
      staffingDetails != null ||
      (staffingRequirements != null && staffingRequirements!.isNotEmpty);

  /// Check if this BEO has vendor data
  bool get hasVendors => vendorDetails != null && vendorDetails!.isNotEmpty;

  /// Check if this BEO has timeline data
  bool get hasTimeline => eventTimeline != null && eventTimeline!.isNotEmpty;

  /// Check if this BEO has setup/decor data
  bool get hasSetup =>
      setupDetails != null || (decorNotes != null && decorNotes!.isNotEmpty);

  /// Get formatted time range
  String? get timeRange {
    if (eventStartTime == null && eventEndTime == null) return null;
    final start = eventStartTime ?? '?';
    final end = eventEndTime ?? '?';
    return '$start - $end';
  }

  @override
  String toString() {
    return 'BeoEvent(id: $id, eventName: $eventName, eventDate: $eventDate, guestCount: $displayGuestCount)';
  }
}
