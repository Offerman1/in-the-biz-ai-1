/// Vision Scanner Scan Types
/// Defines all supported document types for AI vision scanning
enum ScanType {
  beo('BEO (Event Details)', '🧾',
      'Extract event name, guests, and financials from Banquet Event Orders'),
  checkout('Server Checkout', '📊',
      'Extract sales, tips, and tipout from POS receipts'),
  businessCard('Business Card (Contact)', '💼',
      'Add contact to Event Team with social media'),
  paycheck('Paycheck', '💵', 'Track W-2 income, taxes, and YTD earnings'),
  invoice(
      'Invoice', '📄', 'Track client invoices for freelancers and contractors'),
  receipt('Receipt', '🧾', 'Track expenses and deductions for tax purposes');

  final String displayName;
  final String emoji;
  final String description;

  const ScanType(this.displayName, this.emoji, this.description);
}

/// Represents a document scanning session with multiple pages
class DocumentScanSession {
  final ScanType scanType;
  final List<String> imagePaths;
  final DateTime createdAt;

  DocumentScanSession({
    required this.scanType,
    required this.imagePaths,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasImages => imagePaths.isNotEmpty;
  int get pageCount => imagePaths.length;

  Map<String, dynamic> toJson() => {
        'scanType': scanType.name,
        'imagePaths': imagePaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DocumentScanSession.fromJson(Map<String, dynamic> json) {
    return DocumentScanSession(
      scanType: ScanType.values.firstWhere((e) => e.name == json['scanType']),
      imagePaths: List<String>.from(json['imagePaths']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Confidence level for AI extraction
enum ConfidenceLevel {
  high(0.85, '🟢'),
  medium(0.65, '🟡'),
  low(0.0, '🔴');

  final double threshold;
  final String emoji;

  const ConfidenceLevel(this.threshold, this.emoji);

  static ConfidenceLevel fromScore(double score) {
    if (score >= ConfidenceLevel.high.threshold) return ConfidenceLevel.high;
    if (score >= ConfidenceLevel.medium.threshold)
      return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}
