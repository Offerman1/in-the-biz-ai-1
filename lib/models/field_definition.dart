import 'package:flutter/material.dart';

/// Defines a field type for form inputs
enum FieldType {
  text,
  number,
  currency,
  percentage,
  integer,
  toggle,
  date,
  time,
  attachment,
}

/// Defines a single field that can be added to a shift template
class FieldDefinition {
  final String key;
  final String label;
  final String category;
  final FieldType type;
  final bool canDeduct;
  final String? hintText;
  final IconData? icon;
  final String? description;

  const FieldDefinition({
    required this.key,
    required this.label,
    required this.category,
    required this.type,
    this.canDeduct = false,
    this.hintText,
    this.icon,
    this.description,
  });
}

/// A custom field that has been added to a job template
class CustomField {
  final String key;
  final bool enabled;
  final bool deductFromEarnings;
  final int order;

  const CustomField({
    required this.key,
    this.enabled = true,
    this.deductFromEarnings = false,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'enabled': enabled,
        'deductFromEarnings': deductFromEarnings,
        'order': order,
      };

  factory CustomField.fromJson(Map<String, dynamic> json) => CustomField(
        key: json['key'] as String,
        enabled: json['enabled'] as bool? ?? true,
        deductFromEarnings: json['deductFromEarnings'] as bool? ?? false,
        order: json['order'] as int? ?? 0,
      );

  CustomField copyWith({
    String? key,
    bool? enabled,
    bool? deductFromEarnings,
    int? order,
  }) =>
      CustomField(
        key: key ?? this.key,
        enabled: enabled ?? this.enabled,
        deductFromEarnings: deductFromEarnings ?? this.deductFromEarnings,
        order: order ?? this.order,
      );
}

/// Master registry of ALL available fields in the application
class FieldRegistry {
  static const List<FieldDefinition> allFields = [
    // =====================================================
    // RESTAURANT & HOSPITALITY
    // =====================================================
    FieldDefinition(
      key: 'receipts',
      label: 'Receipts',
      category: 'Restaurant & Hospitality',
      type: FieldType.attachment,
      canDeduct: true,
      hintText: 'Upload receipt images',
      icon: Icons.receipt_long,
      description: 'Track receipts for expenses, meals, or reimbursements',
    ),
    FieldDefinition(
      key: 'invoices',
      label: 'Invoices',
      category: 'Restaurant & Hospitality',
      type: FieldType.attachment,
      canDeduct: false,
      hintText: 'Upload invoice documents',
      icon: Icons.description,
      description: 'Store invoices for events or catering',
    ),
    FieldDefinition(
      key: 'tableSection',
      label: 'Table Section',
      category: 'Restaurant & Hospitality',
      type: FieldType.text,
      hintText: 'e.g., Section A, Tables 1-5',
      icon: Icons.table_restaurant,
    ),
    FieldDefinition(
      key: 'cashSales',
      label: 'Cash Sales',
      category: 'Restaurant & Hospitality',
      type: FieldType.currency,
      hintText: 'Total cash payments received',
      icon: Icons.payments,
    ),
    FieldDefinition(
      key: 'cardSales',
      label: 'Card Sales',
      category: 'Restaurant & Hospitality',
      type: FieldType.currency,
      hintText: 'Total card payments received',
      icon: Icons.credit_card,
    ),

    // =====================================================
    // RIDESHARE & DELIVERY
    // =====================================================
    FieldDefinition(
      key: 'ridesCount',
      label: 'Rides Count',
      category: 'Rideshare & Delivery',
      type: FieldType.integer,
      hintText: 'Number of rides completed',
      icon: Icons.directions_car,
    ),
    FieldDefinition(
      key: 'deliveriesCount',
      label: 'Deliveries Count',
      category: 'Rideshare & Delivery',
      type: FieldType.integer,
      hintText: 'Number of deliveries completed',
      icon: Icons.delivery_dining,
    ),
    FieldDefinition(
      key: 'deadMiles',
      label: 'Dead Miles',
      category: 'Rideshare & Delivery',
      type: FieldType.number,
      canDeduct: false,
      hintText: 'Miles driven without a fare',
      icon: Icons.remove_road,
    ),
    FieldDefinition(
      key: 'fuelCost',
      label: 'Fuel Cost',
      category: 'Rideshare & Delivery',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Amount spent on gas',
      icon: Icons.local_gas_station,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'tollsParking',
      label: 'Tolls & Parking',
      category: 'Rideshare & Delivery',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Tolls and parking fees',
      icon: Icons.toll,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'surgeMultiplier',
      label: 'Surge Multiplier',
      category: 'Rideshare & Delivery',
      type: FieldType.number,
      hintText: 'e.g., 1.5x, 2.0x',
      icon: Icons.trending_up,
    ),
    FieldDefinition(
      key: 'acceptanceRate',
      label: 'Acceptance Rate',
      category: 'Rideshare & Delivery',
      type: FieldType.percentage,
      hintText: 'Percentage of rides accepted',
      icon: Icons.check_circle_outline,
    ),
    FieldDefinition(
      key: 'baseFare',
      label: 'Base Fare',
      category: 'Rideshare & Delivery',
      type: FieldType.currency,
      hintText: 'Base fare before tips',
      icon: Icons.attach_money,
    ),

    // =====================================================
    // MUSIC & ENTERTAINMENT
    // =====================================================
    FieldDefinition(
      key: 'gigType',
      label: 'Gig Type',
      category: 'Music & Entertainment',
      type: FieldType.text,
      hintText: 'e.g., Wedding, Club, Private Party',
      icon: Icons.music_note,
    ),
    FieldDefinition(
      key: 'setupHours',
      label: 'Setup Hours',
      category: 'Music & Entertainment',
      type: FieldType.number,
      hintText: 'Time spent setting up',
      icon: Icons.build,
    ),
    FieldDefinition(
      key: 'performanceHours',
      label: 'Performance Hours',
      category: 'Music & Entertainment',
      type: FieldType.number,
      hintText: 'Time spent performing',
      icon: Icons.mic,
    ),
    FieldDefinition(
      key: 'breakdownHours',
      label: 'Breakdown Hours',
      category: 'Music & Entertainment',
      type: FieldType.number,
      hintText: 'Time spent breaking down',
      icon: Icons.archive,
    ),
    FieldDefinition(
      key: 'equipmentUsed',
      label: 'Equipment Used',
      category: 'Music & Entertainment',
      type: FieldType.text,
      hintText: 'List of equipment used',
      icon: Icons.speaker,
    ),
    FieldDefinition(
      key: 'equipmentRentalCost',
      label: 'Equipment Rental Cost',
      category: 'Music & Entertainment',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Cost of renting equipment',
      icon: Icons.shopping_cart,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'crewPayment',
      label: 'Crew Payment',
      category: 'Music & Entertainment',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Amount paid to crew/helpers',
      icon: Icons.people,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'merchSales',
      label: 'Merch Sales',
      category: 'Music & Entertainment',
      type: FieldType.currency,
      hintText: 'Revenue from merchandise',
      icon: Icons.shopping_bag,
    ),
    FieldDefinition(
      key: 'audienceSize',
      label: 'Audience Size',
      category: 'Music & Entertainment',
      type: FieldType.integer,
      hintText: 'Estimated audience count',
      icon: Icons.groups,
    ),

    // =====================================================
    // ARTIST & CRAFTS
    // =====================================================
    FieldDefinition(
      key: 'piecesCreated',
      label: 'Pieces Created',
      category: 'Artist & Crafts',
      type: FieldType.integer,
      hintText: 'Number of items made',
      icon: Icons.brush,
    ),
    FieldDefinition(
      key: 'piecesSold',
      label: 'Pieces Sold',
      category: 'Artist & Crafts',
      type: FieldType.integer,
      hintText: 'Number of items sold',
      icon: Icons.sell,
    ),
    FieldDefinition(
      key: 'materialsCost',
      label: 'Materials Cost',
      category: 'Artist & Crafts',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Cost of materials used',
      icon: Icons.palette,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'salePrice',
      label: 'Sale Price',
      category: 'Artist & Crafts',
      type: FieldType.currency,
      hintText: 'Price per item',
      icon: Icons.price_change,
    ),
    FieldDefinition(
      key: 'venueCommissionPercent',
      label: 'Venue Commission',
      category: 'Artist & Crafts',
      type: FieldType.percentage,
      canDeduct: true,
      hintText: 'Percentage taken by venue',
      icon: Icons.storefront,
    ),

    // =====================================================
    // RETAIL & SALES
    // =====================================================
    FieldDefinition(
      key: 'itemsSold',
      label: 'Items Sold',
      category: 'Retail & Sales',
      type: FieldType.integer,
      hintText: 'Total items sold',
      icon: Icons.shopping_cart,
    ),
    FieldDefinition(
      key: 'transactionsCount',
      label: 'Transactions Count',
      category: 'Retail & Sales',
      type: FieldType.integer,
      hintText: 'Number of transactions',
      icon: Icons.receipt,
    ),
    FieldDefinition(
      key: 'upsellsCount',
      label: 'Upsells Count',
      category: 'Retail & Sales',
      type: FieldType.integer,
      hintText: 'Number of upsells',
      icon: Icons.trending_up,
    ),
    FieldDefinition(
      key: 'upsellsAmount',
      label: 'Upsells Amount',
      category: 'Retail & Sales',
      type: FieldType.currency,
      hintText: 'Value of upsells',
      icon: Icons.attach_money,
    ),
    FieldDefinition(
      key: 'returnsCount',
      label: 'Returns Count',
      category: 'Retail & Sales',
      type: FieldType.integer,
      hintText: 'Number of returns',
      icon: Icons.undo,
    ),
    FieldDefinition(
      key: 'returnsAmount',
      label: 'Returns Amount',
      category: 'Retail & Sales',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Value of returns',
      icon: Icons.money_off,
    ),
    FieldDefinition(
      key: 'department',
      label: 'Department',
      category: 'Retail & Sales',
      type: FieldType.text,
      hintText: 'e.g., Electronics, Clothing',
      icon: Icons.category,
    ),

    // =====================================================
    // SALON & SPA
    // =====================================================
    FieldDefinition(
      key: 'serviceType',
      label: 'Service Type',
      category: 'Salon & Spa',
      type: FieldType.text,
      hintText: 'e.g., Haircut, Color, Massage',
      icon: Icons.content_cut,
    ),
    FieldDefinition(
      key: 'servicesCount',
      label: 'Services Count',
      category: 'Salon & Spa',
      type: FieldType.integer,
      hintText: 'Number of services performed',
      icon: Icons.format_list_numbered,
    ),
    FieldDefinition(
      key: 'productSales',
      label: 'Product Sales',
      category: 'Salon & Spa',
      type: FieldType.currency,
      hintText: 'Revenue from product sales',
      icon: Icons.local_mall,
    ),
    FieldDefinition(
      key: 'chairRental',
      label: 'Chair Rental',
      category: 'Salon & Spa',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Cost of chair/booth rental',
      icon: Icons.chair,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'newClientsCount',
      label: 'New Clients',
      category: 'Salon & Spa',
      type: FieldType.integer,
      hintText: 'Number of new clients',
      icon: Icons.person_add,
    ),
    FieldDefinition(
      key: 'returningClientsCount',
      label: 'Returning Clients',
      category: 'Salon & Spa',
      type: FieldType.integer,
      hintText: 'Number of returning clients',
      icon: Icons.people,
    ),

    // =====================================================
    // HEALTHCARE
    // =====================================================
    FieldDefinition(
      key: 'patientsCount',
      label: 'Patients Seen',
      category: 'Healthcare',
      type: FieldType.integer,
      hintText: 'Number of patients',
      icon: Icons.medical_services,
    ),
    FieldDefinition(
      key: 'proceduresCount',
      label: 'Procedures Performed',
      category: 'Healthcare',
      type: FieldType.integer,
      hintText: 'Number of procedures',
      icon: Icons.healing,
    ),
    FieldDefinition(
      key: 'callbackPay',
      label: 'Callback Pay',
      category: 'Healthcare',
      type: FieldType.currency,
      hintText: 'Extra pay for callbacks',
      icon: Icons.phone_callback,
    ),
    FieldDefinition(
      key: 'certificationBonus',
      label: 'Certification Bonus',
      category: 'Healthcare',
      type: FieldType.currency,
      hintText: 'Bonus for certifications',
      icon: Icons.verified,
    ),

    // =====================================================
    // FREELANCER & CONSULTING
    // =====================================================
    FieldDefinition(
      key: 'billableHours',
      label: 'Billable Hours',
      category: 'Freelancer & Consulting',
      type: FieldType.number,
      hintText: 'Hours billed to client',
      icon: Icons.access_time,
    ),
    FieldDefinition(
      key: 'revisionsCount',
      label: 'Revisions Count',
      category: 'Freelancer & Consulting',
      type: FieldType.integer,
      hintText: 'Number of revision rounds',
      icon: Icons.edit_note,
    ),
    FieldDefinition(
      key: 'clientType',
      label: 'Client Type',
      category: 'Freelancer & Consulting',
      type: FieldType.text,
      hintText: 'e.g., Agency, Direct, Referral',
      icon: Icons.business,
    ),
    FieldDefinition(
      key: 'expenses',
      label: 'Expenses',
      category: 'Freelancer & Consulting',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Business expenses',
      icon: Icons.receipt_long,
      description: 'Can be deducted from your total earnings',
    ),

    // =====================================================
    // TRANSPORTATION
    // =====================================================
    FieldDefinition(
      key: 'transportationCost',
      label: 'Transportation Cost',
      category: 'Transportation',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Cost of getting to work (Uber, bus, etc.)',
      icon: Icons.directions_bus,
      description: 'Can be deducted from your total earnings',
    ),
    FieldDefinition(
      key: 'milesDriven',
      label: 'Miles Driven',
      category: 'Transportation',
      type: FieldType.number,
      hintText: 'Total miles driven',
      icon: Icons.speed,
    ),
    FieldDefinition(
      key: 'parkingCost',
      label: 'Parking Cost',
      category: 'Transportation',
      type: FieldType.currency,
      canDeduct: true,
      hintText: 'Cost of parking',
      icon: Icons.local_parking,
      description: 'Can be deducted from your total earnings',
    ),
  ];

  /// Get all unique categories
  static List<String> get categories {
    final cats = allFields.map((f) => f.category).toSet().toList();
    cats.sort();
    return cats;
  }

  /// Get fields by category
  static List<FieldDefinition> getFieldsByCategory(String category) {
    return allFields.where((f) => f.category == category).toList();
  }

  /// Get a field definition by key
  static FieldDefinition? getField(String key) {
    try {
      return allFields.firstWhere((f) => f.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Get fields that can be deducted from earnings
  static List<FieldDefinition> get deductibleFields {
    return allFields.where((f) => f.canDeduct).toList();
  }
}
