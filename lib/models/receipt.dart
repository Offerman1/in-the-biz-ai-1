import 'package:uuid/uuid.dart';

/// Receipt model for expense tracking (1099 contractors)
/// Linked to shifts as documentation attachments
class Receipt {
  final String id;
  final String userId;
  final String? shiftId; // Link to shift (optional)

  // Receipt Identity
  final DateTime receiptDate;
  final String vendorName;
  final String? receiptNumber;

  // Financials
  final double? subtotal;
  final double? taxAmount;
  final double totalAmount;
  final String currency; // Default: USD
  final String? paymentMethod; // Cash, Credit, Debit, Check, Other

  // Expense Categorization
  final String?
      expenseCategory; // Materials, Equipment, Travel, Meals, Supplies, Marketing, Utilities, Other
  final String?
      quickbooksCategory; // AI-suggested QuickBooks expense category (Schedule C)
  final bool isTaxDeductible;

  // Line Items
  final List<ReceiptLineItem>? lineItems;

  // QuickBooks Integration
  final bool quickbooksSynced;
  final String? quickbooksExpenseId;
  final DateTime? quickbooksSyncDate;
  final String? quickbooksSyncError;

  // AI Metadata
  final List<String>? imageUrls;
  final Map<String, dynamic>? aiConfidenceScores;
  final Map<String, dynamic>? rawAiResponse;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt({
    String? id,
    required this.userId,
    this.shiftId,
    required this.receiptDate,
    required this.vendorName,
    this.receiptNumber,
    this.subtotal,
    this.taxAmount,
    required this.totalAmount,
    this.currency = 'USD',
    this.paymentMethod,
    this.expenseCategory,
    this.quickbooksCategory,
    this.isTaxDeductible = true,
    this.lineItems,
    this.quickbooksSynced = false,
    this.quickbooksExpenseId,
    this.quickbooksSyncDate,
    this.quickbooksSyncError,
    this.imageUrls,
    this.aiConfidenceScores,
    this.rawAiResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create Receipt from database JSON
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      shiftId: json['shift_id'] as String?,
      receiptDate: DateTime.parse(json['receipt_date'] as String),
      vendorName: json['vendor_name'] as String,
      receiptNumber: json['receipt_number'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['payment_method'] as String?,
      expenseCategory: json['expense_category'] as String?,
      quickbooksCategory: json['quickbooks_category'] as String?,
      isTaxDeductible: json['is_tax_deductible'] as bool? ?? true,
      lineItems: json['line_items'] != null
          ? (json['line_items'] as List)
              .map((e) => ReceiptLineItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      quickbooksSynced: json['quickbooks_synced'] as bool? ?? false,
      quickbooksExpenseId: json['quickbooks_expense_id'] as String?,
      quickbooksSyncDate: json['quickbooks_sync_date'] != null
          ? DateTime.parse(json['quickbooks_sync_date'] as String)
          : null,
      quickbooksSyncError: json['quickbooks_sync_error'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      aiConfidenceScores: json['ai_confidence_scores'] as Map<String, dynamic>?,
      rawAiResponse: json['raw_ai_response'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert Receipt to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shift_id': shiftId,
      'receipt_date': receiptDate.toIso8601String().split('T')[0],
      'vendor_name': vendorName,
      'receipt_number': receiptNumber,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'payment_method': paymentMethod,
      'expense_category': expenseCategory,
      'quickbooks_category': quickbooksCategory,
      'is_tax_deductible': isTaxDeductible,
      'line_items': lineItems?.map((e) => e.toJson()).toList(),
      'quickbooks_synced': quickbooksSynced,
      'quickbooks_expense_id': quickbooksExpenseId,
      'quickbooks_sync_date': quickbooksSyncDate?.toIso8601String(),
      'quickbooks_sync_error': quickbooksSyncError,
      'image_urls': imageUrls,
      'ai_confidence_scores': aiConfidenceScores,
      'raw_ai_response': rawAiResponse,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with updated fields
  Receipt copyWith({
    String? id,
    String? userId,
    String? shiftId,
    DateTime? receiptDate,
    String? vendorName,
    String? receiptNumber,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    String? paymentMethod,
    String? expenseCategory,
    String? quickbooksCategory,
    bool? isTaxDeductible,
    List<ReceiptLineItem>? lineItems,
    bool? quickbooksSynced,
    String? quickbooksExpenseId,
    DateTime? quickbooksSyncDate,
    String? quickbooksSyncError,
    List<String>? imageUrls,
    Map<String, dynamic>? aiConfidenceScores,
    Map<String, dynamic>? rawAiResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shiftId: shiftId ?? this.shiftId,
      receiptDate: receiptDate ?? this.receiptDate,
      vendorName: vendorName ?? this.vendorName,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      quickbooksCategory: quickbooksCategory ?? this.quickbooksCategory,
      isTaxDeductible: isTaxDeductible ?? this.isTaxDeductible,
      lineItems: lineItems ?? this.lineItems,
      quickbooksSynced: quickbooksSynced ?? this.quickbooksSynced,
      quickbooksExpenseId: quickbooksExpenseId ?? this.quickbooksExpenseId,
      quickbooksSyncDate: quickbooksSyncDate ?? this.quickbooksSyncDate,
      quickbooksSyncError: quickbooksSyncError ?? this.quickbooksSyncError,
      imageUrls: imageUrls ?? this.imageUrls,
      aiConfidenceScores: aiConfidenceScores ?? this.aiConfidenceScores,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Line item for detailed receipt breakdown
class ReceiptLineItem {
  final String description;
  final int? quantity;
  final double? unitPrice;
  final double amount;

  ReceiptLineItem({
    required this.description,
    this.quantity,
    this.unitPrice,
    required this.amount,
  });

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      description: json['description'] as String,
      quantity: json['quantity'] as int?,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
    };
  }
}

/// Expense categories for 1099 Schedule C deductions
class ExpenseCategory {
  static const String materials = 'Materials';
  static const String equipment = 'Equipment';
  static const String travel = 'Travel';
  static const String meals = 'Meals';
  static const String supplies = 'Supplies';
  static const String marketing = 'Marketing';
  static const String utilities = 'Utilities';
  static const String insurance = 'Insurance';
  static const String professional = 'Professional Services';
  static const String software = 'Software/Subscriptions';
  static const String vehicle = 'Vehicle/Mileage';
  static const String office = 'Office Expenses';
  static const String other = 'Other';

  static List<String> get all => [
        materials,
        equipment,
        travel,
        meals,
        supplies,
        marketing,
        utilities,
        insurance,
        professional,
        software,
        vehicle,
        office,
        other,
      ];

  /// Get Schedule C category for QuickBooks mapping
  static String getScheduleCCategory(String category) {
    switch (category) {
      case materials:
        return 'Cost of Goods Sold - Materials';
      case equipment:
        return 'Equipment Rental/Purchase';
      case travel:
        return 'Travel Expenses';
      case meals:
        return 'Meals (50% deductible)';
      case supplies:
        return 'Supplies';
      case marketing:
        return 'Advertising';
      case utilities:
        return 'Utilities';
      case insurance:
        return 'Insurance';
      case professional:
        return 'Legal and Professional Services';
      case software:
        return 'Office Expense';
      case vehicle:
        return 'Car and Truck Expenses';
      case office:
        return 'Office Expense';
      default:
        return 'Other Expenses';
    }
  }
}

/// Payment methods
class PaymentMethod {
  static const String cash = 'Cash';
  static const String credit = 'Credit Card';
  static const String debit = 'Debit Card';
  static const String check = 'Check';
  static const String bankTransfer = 'Bank Transfer';
  static const String venmo = 'Venmo';
  static const String paypal = 'PayPal';
  static const String zelle = 'Zelle';
  static const String other = 'Other';

  static List<String> get all => [
        cash,
        credit,
        debit,
        check,
        bankTransfer,
        venmo,
        paypal,
        zelle,
        other,
      ];
}
