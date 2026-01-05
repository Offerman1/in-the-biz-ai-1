import 'package:uuid/uuid.dart';

/// Invoice model for freelancer/contractor income tracking
/// Linked to shifts as documentation attachments
class Invoice {
  final String id;
  final String userId;
  final String? shiftId; // Link to shift (optional)

  // Invoice Identity
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;

  // Client Information
  final String clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientAddress;

  // Financials
  final double? subtotal;
  final double? taxAmount;
  final double totalAmount;
  final double amountPaid;
  final double? balanceDue;
  final String currency; // Default: USD

  // Payment Terms
  final String? paymentTerms; // Net 30, Due on Receipt, Net 15, etc.

  // Line Items
  final List<InvoiceLineItem>? lineItems;

  // Status
  final InvoiceStatus status;
  final DateTime? paidDate;

  // QuickBooks Integration
  final bool quickbooksSynced;
  final String? quickbooksInvoiceId;
  final String? quickbooksCategory; // Suggested income category
  final DateTime? quickbooksSyncDate;
  final String? quickbooksSyncError;

  // AI Metadata
  final List<String>? imageUrls;
  final Map<String, dynamic>? aiConfidenceScores;
  final Map<String, dynamic>? rawAiResponse;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    String? id,
    required this.userId,
    this.shiftId,
    this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    this.subtotal,
    this.taxAmount,
    required this.totalAmount,
    this.amountPaid = 0,
    this.balanceDue,
    this.currency = 'USD',
    this.paymentTerms,
    this.lineItems,
    this.status = InvoiceStatus.pending,
    this.paidDate,
    this.quickbooksSynced = false,
    this.quickbooksInvoiceId,
    this.quickbooksCategory,
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

  /// Create Invoice from database JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      shiftId: json['shift_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      clientName: json['client_name'] as String,
      clientEmail: json['client_email'] as String?,
      clientPhone: json['client_phone'] as String?,
      clientAddress: json['client_address'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      balanceDue: (json['balance_due'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentTerms: json['payment_terms'] as String?,
      lineItems: json['line_items'] != null
          ? (json['line_items'] as List)
              .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      status: InvoiceStatus.fromString(json['status'] as String? ?? 'pending'),
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      quickbooksSynced: json['quickbooks_synced'] as bool? ?? false,
      quickbooksInvoiceId: json['quickbooks_invoice_id'] as String?,
      quickbooksCategory: json['quickbooks_category'] as String?,
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

  /// Convert Invoice to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shift_id': shiftId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'balance_due': balanceDue,
      'currency': currency,
      'payment_terms': paymentTerms,
      'line_items': lineItems?.map((e) => e.toJson()).toList(),
      'status': status.value,
      'paid_date': paidDate?.toIso8601String().split('T')[0],
      'quickbooks_synced': quickbooksSynced,
      'quickbooks_invoice_id': quickbooksInvoiceId,
      'quickbooks_category': quickbooksCategory,
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
  Invoice copyWith({
    String? id,
    String? userId,
    String? shiftId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    double? amountPaid,
    double? balanceDue,
    String? currency,
    String? paymentTerms,
    List<InvoiceLineItem>? lineItems,
    InvoiceStatus? status,
    DateTime? paidDate,
    bool? quickbooksSynced,
    String? quickbooksInvoiceId,
    String? quickbooksCategory,
    DateTime? quickbooksSyncDate,
    String? quickbooksSyncError,
    List<String>? imageUrls,
    Map<String, dynamic>? aiConfidenceScores,
    Map<String, dynamic>? rawAiResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shiftId: shiftId ?? this.shiftId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      currency: currency ?? this.currency,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      lineItems: lineItems ?? this.lineItems,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      quickbooksSynced: quickbooksSynced ?? this.quickbooksSynced,
      quickbooksInvoiceId: quickbooksInvoiceId ?? this.quickbooksInvoiceId,
      quickbooksCategory: quickbooksCategory ?? this.quickbooksCategory,
      quickbooksSyncDate: quickbooksSyncDate ?? this.quickbooksSyncDate,
      quickbooksSyncError: quickbooksSyncError ?? this.quickbooksSyncError,
      imageUrls: imageUrls ?? this.imageUrls,
      aiConfidenceScores: aiConfidenceScores ?? this.aiConfidenceScores,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if invoice is overdue
  bool get isOverdue {
    if (dueDate == null || status == InvoiceStatus.paid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Calculate days until due (negative if overdue)
  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }
}

/// Invoice line item
class InvoiceLineItem {
  final String description;
  final double? quantity;
  final double? rate;
  final double amount;

  InvoiceLineItem({
    required this.description,
    this.quantity,
    this.rate,
    required this.amount,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      rate: (json['rate'] as num?)?.toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }
}

/// Invoice status enum
enum InvoiceStatus {
  pending('pending'),
  paid('paid'),
  overdue('overdue'),
  cancelled('cancelled');

  final String value;
  const InvoiceStatus(this.value);

  static InvoiceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.pending;
    }
  }
}

/// Common payment terms
class PaymentTerms {
  static const String dueOnReceipt = 'Due on Receipt';
  static const String net7 = 'Net 7';
  static const String net15 = 'Net 15';
  static const String net30 = 'Net 30';
  static const String net45 = 'Net 45';
  static const String net60 = 'Net 60';
  static const String net90 = 'Net 90';
  static const String twoTenNet30 =
      '2/10 Net 30'; // 2% discount if paid in 10 days

  static List<String> get all => [
        dueOnReceipt,
        net7,
        net15,
        net30,
        net45,
        net60,
        net90,
        twoTenNet30,
      ];

  /// Calculate due date from invoice date based on terms
  static DateTime? calculateDueDate(DateTime invoiceDate, String terms) {
    switch (terms) {
      case dueOnReceipt:
        return invoiceDate;
      case net7:
        return invoiceDate.add(const Duration(days: 7));
      case net15:
        return invoiceDate.add(const Duration(days: 15));
      case net30:
      case twoTenNet30:
        return invoiceDate.add(const Duration(days: 30));
      case net45:
        return invoiceDate.add(const Duration(days: 45));
      case net60:
        return invoiceDate.add(const Duration(days: 60));
      case net90:
        return invoiceDate.add(const Duration(days: 90));
      default:
        return null;
    }
  }
}

/// Common QuickBooks income categories
class IncomeCategory {
  static const String services = 'Services';
  static const String productSales = 'Product Sales';
  static const String consulting = 'Consulting';
  static const String design = 'Design Services';
  static const String development = 'Development Services';
  static const String photography = 'Photography';
  static const String music = 'Music/Entertainment';
  static const String events = 'Event Services';
  static const String construction = 'Construction';
  static const String repair = 'Repair Services';
  static const String other = 'Other Income';

  static List<String> get all => [
        services,
        productSales,
        consulting,
        design,
        development,
        photography,
        music,
        events,
        construction,
        repair,
        other,
      ];
}
