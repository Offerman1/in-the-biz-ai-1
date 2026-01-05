import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/vision_scan.dart';

/// Universal verification screen for all AI scan types
/// Shows extracted data with confidence badges for user review before saving
class ScanVerificationScreen extends StatefulWidget {
  final ScanType scanType;
  final Map<String, dynamic> extractedData;
  final Map<String, dynamic>? confidenceScores;
  final Function(Map<String, dynamic>) onConfirm;
  final Function()? onRetry;

  const ScanVerificationScreen({
    super.key,
    required this.scanType,
    required this.extractedData,
    this.confidenceScores,
    required this.onConfirm,
    this.onRetry,
  });

  @override
  State<ScanVerificationScreen> createState() => _ScanVerificationScreenState();
}

class _ScanVerificationScreenState extends State<ScanVerificationScreen> {
  late Map<String, dynamic> _editableData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editableData = Map<String, dynamic>.from(widget.extractedData);
  }

  /// Get confidence level emoji for a field
  String _getConfidenceBadge(String fieldName) {
    if (widget.confidenceScores == null ||
        !widget.confidenceScores!.containsKey(fieldName)) {
      return ''; // No confidence score available
    }

    final score = widget.confidenceScores![fieldName];
    if (score == null) return '';

    return ConfidenceLevel.fromScore(score as double).emoji;
  }

  /// Get confidence level color
  Color _getConfidenceColor(String fieldName) {
    if (widget.confidenceScores == null ||
        !widget.confidenceScores!.containsKey(fieldName)) {
      return AppTheme.textMuted;
    }

    final score = widget.confidenceScores![fieldName];
    if (score == null) return AppTheme.textMuted;

    final level = ConfidenceLevel.fromScore(score as double);
    switch (level) {
      case ConfidenceLevel.high:
        return AppTheme.successColor;
      case ConfidenceLevel.medium:
        return AppTheme.warningColor;
      case ConfidenceLevel.low:
        return AppTheme.dangerColor;
    }
  }

  /// Build a single field row with label, value, and confidence badge
  Widget _buildFieldRow(String label, String fieldKey,
      {String? suffix, bool multiline = false}) {
    final value = _editableData[fieldKey];
    if (value == null) return const SizedBox.shrink(); // Hide null fields

    final confidenceBadge = _getConfidenceBadge(fieldKey);
    final confidenceColor = _getConfidenceColor(fieldKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (confidenceBadge.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  confidenceBadge,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: confidenceBadge.isNotEmpty
                    ? confidenceColor.withOpacity(0.3)
                    : AppTheme.textMuted.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.toString() + (suffix ?? ''),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: multiline ? null : 1,
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.edit, color: AppTheme.primaryGreen, size: 20),
                  onPressed: () =>
                      _editField(label, fieldKey, value.toString()),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit a field
  Future<void> _editField(
      String label, String fieldKey, String currentValue) async {
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Edit $label', style: AppTheme.titleMedium),
        content: TextField(
          controller: controller,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Try to parse as number if the original value was numeric
                if (_editableData[fieldKey] is num) {
                  _editableData[fieldKey] =
                      double.tryParse(controller.text) ?? controller.text;
                } else {
                  _editableData[fieldKey] = controller.text;
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSave() async {
    setState(() => _isSaving = true);

    try {
      await widget.onConfirm(_editableData);

      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Verify ${widget.scanType.displayName}',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          if (widget.onRetry != null)
            TextButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentOrange,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Row(
              children: [
                Text(widget.scanType.emoji,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Extraction Complete',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review the data below. Tap ✏️ to edit any field.',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confidence legend
          if (widget.confidenceScores != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildConfidenceLegendItem('🟢', 'High'),
                  const SizedBox(width: 16),
                  _buildConfidenceLegendItem('🟡', 'Medium'),
                  const SizedBox(width: 16),
                  _buildConfidenceLegendItem('🔴', 'Low'),
                ],
              ),
            ),

          // Extracted fields
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _buildFieldsForScanType(),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.textMuted),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _confirmAndSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(_isSaving ? 'Saving...' : 'Confirm & Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceLegendItem(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// Build fields specific to each scan type
  List<Widget> _buildFieldsForScanType() {
    switch (widget.scanType) {
      case ScanType.beo:
        return _buildBEOFields();
      case ScanType.checkout:
        return _buildCheckoutFields();
      case ScanType.paycheck:
        return _buildPaycheckFields();
      case ScanType.businessCard:
        return _buildBusinessCardFields();
      case ScanType.invoice:
        return _buildInvoiceFields();
      case ScanType.receipt:
        return _buildReceiptFields();
    }
  }

  List<Widget> _buildBEOFields() {
    return [
      _buildFieldRow('Event Name', 'event_name'),
      _buildFieldRow('Event Date', 'event_date'),
      _buildFieldRow('Event Type', 'event_type'),
      _buildFieldRow('Venue', 'venue_name'),
      _buildFieldRow('Guest Count', 'guest_count_confirmed'),
      _buildFieldRow('Total Sale', 'total_sale_amount', suffix: ' USD'),
      _buildFieldRow('Commission', 'commission_amount', suffix: ' USD'),
      _buildFieldRow('Primary Contact', 'primary_contact_name'),
      _buildFieldRow('Contact Phone', 'primary_contact_phone'),
      _buildFieldRow('Contact Email', 'primary_contact_email'),
      _buildFieldRow('Event Start Time', 'event_start_time'),
      _buildFieldRow('Event End Time', 'event_end_time'),
      if (_editableData['formatted_notes'] != null)
        _buildFieldRow('Additional Notes', 'formatted_notes', multiline: true),
    ];
  }

  List<Widget> _buildCheckoutFields() {
    return [
      _buildFieldRow('POS System', 'pos_system'),
      _buildFieldRow('Date', 'checkout_date'),
      _buildFieldRow('Server Name', 'server_name'),
      _buildFieldRow('Total Sales', 'total_sales', suffix: ' USD'),
      _buildFieldRow('Gross Tips', 'gross_tips', suffix: ' USD'),
      _buildFieldRow('Tipout Amount', 'tipout_amount', suffix: ' USD'),
      _buildFieldRow('Net Tips (Take Home)', 'net_tips', suffix: ' USD'),
      _buildFieldRow('Table Count', 'table_count'),
      _buildFieldRow('Cover Count', 'cover_count'),
      if (_editableData['validation_notes'] != null)
        _buildFieldRow('Validation Notes', 'validation_notes', multiline: true),
    ];
  }

  List<Widget> _buildPaycheckFields() {
    return [
      _buildFieldRow('Payroll Provider', 'payroll_provider'),
      _buildFieldRow('Employer', 'employer_name'),
      _buildFieldRow('Pay Period Start', 'pay_period_start'),
      _buildFieldRow('Pay Period End', 'pay_period_end'),
      _buildFieldRow('Gross Pay', 'gross_pay', suffix: ' USD'),
      _buildFieldRow('Federal Tax', 'federal_tax', suffix: ' USD'),
      _buildFieldRow('State Tax', 'state_tax', suffix: ' USD'),
      _buildFieldRow('FICA', 'fica_tax', suffix: ' USD'),
      _buildFieldRow('Medicare', 'medicare_tax', suffix: ' USD'),
      _buildFieldRow('Net Pay', 'net_pay', suffix: ' USD'),
      _buildFieldRow('YTD Gross', 'ytd_gross', suffix: ' USD'),
      _buildFieldRow('YTD Federal Tax', 'ytd_federal_tax', suffix: ' USD'),
      _buildFieldRow('Regular Hours', 'regular_hours'),
      _buildFieldRow('Overtime Hours', 'overtime_hours'),
    ];
  }

  List<Widget> _buildBusinessCardFields() {
    return [
      _buildFieldRow('Name', 'name'),
      _buildFieldRow('Company', 'company'),
      _buildFieldRow('Role', 'role'),
      _buildFieldRow('Phone', 'phone'),
      _buildFieldRow('Email', 'email'),
      _buildFieldRow('Website', 'website'),
      _buildFieldRow('Instagram', 'instagram_handle'),
      _buildFieldRow('TikTok', 'tiktok_handle'),
      _buildFieldRow('LinkedIn', 'linkedin_url'),
      _buildFieldRow('Twitter/X', 'twitter_handle'),
    ];
  }

  List<Widget> _buildInvoiceFields() {
    return [
      _buildFieldRow('Invoice Number', 'invoice_number'),
      _buildFieldRow('Invoice Date', 'invoice_date'),
      _buildFieldRow('Due Date', 'due_date'),
      _buildFieldRow('Client Name', 'client_name'),
      _buildFieldRow('Client Email', 'client_email'),
      _buildFieldRow('Subtotal', 'subtotal', suffix: ' USD'),
      _buildFieldRow('Tax', 'tax_amount', suffix: ' USD'),
      _buildFieldRow('Total Amount', 'total_amount', suffix: ' USD'),
      _buildFieldRow('Payment Terms', 'payment_terms'),
      _buildFieldRow('QuickBooks Category', 'quickbooks_category'),
    ];
  }

  List<Widget> _buildReceiptFields() {
    return [
      _buildFieldRow('Vendor Name', 'vendor_name'),
      _buildFieldRow('Receipt Date', 'receipt_date'),
      _buildFieldRow('Receipt Number', 'receipt_number'),
      _buildFieldRow('Subtotal', 'subtotal', suffix: ' USD'),
      _buildFieldRow('Tax', 'tax_amount', suffix: ' USD'),
      _buildFieldRow('Tip', 'tip_amount', suffix: ' USD'),
      _buildFieldRow('Total Amount', 'total_amount', suffix: ' USD'),
      _buildFieldRow('Payment Method', 'payment_method'),
      _buildFieldRow('Expense Category', 'expense_category'),
      _buildFieldRow('QuickBooks Category', 'quickbooks_category'),
      _buildFieldRow('Tax Deductible', 'is_tax_deductible'),
    ];
  }
}
