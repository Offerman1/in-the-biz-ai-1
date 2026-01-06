import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/vision_scan.dart';
import '../services/database_service.dart';
import 'add_shift_screen.dart';

/// Universal verification screen for all AI scan types
/// Shows extracted data with confidence badges for user review before saving
class ScanVerificationScreen extends StatefulWidget {
  final ScanType scanType;
  final Map<String, dynamic> extractedData;
  final Map<String, dynamic>? confidenceScores;
  final Function(Map<String, dynamic>) onConfirm;
  final Function()? onRetry;
  final String? existingCheckoutId;

  const ScanVerificationScreen({
    super.key,
    required this.scanType,
    required this.extractedData,
    this.confidenceScores,
    required this.onConfirm,
    this.onRetry,
    this.existingCheckoutId,
  });

  @override
  State<ScanVerificationScreen> createState() => _ScanVerificationScreenState();
}

class _ScanVerificationScreenState extends State<ScanVerificationScreen> {
  late Map<String, dynamic> _editableData;
  bool _isSaving = false;
  bool _isCreatingShift = false;
  final DatabaseService _db = DatabaseService();

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
  /// ALWAYS shows the field - if empty, user can fill it in
  Widget _buildFieldRow(String label, String fieldKey,
      {String? suffix, bool multiline = false, bool isRequired = false}) {
    final value = _editableData[fieldKey];
    final hasValue = value != null && value.toString().isNotEmpty;
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
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(color: AppTheme.dangerColor, fontSize: 14),
                ),
              ],
              if (confidenceBadge.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  confidenceBadge,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              if (!hasValue) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Not found - tap to add',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentOrange,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                _editField(label, fieldKey, hasValue ? value.toString() : ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: hasValue
                    ? AppTheme.cardBackgroundLight
                    : AppTheme.cardBackgroundLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: hasValue
                      ? (confidenceBadge.isNotEmpty
                          ? confidenceColor.withOpacity(0.3)
                          : AppTheme.textMuted.withOpacity(0.2))
                      : AppTheme.accentOrange.withOpacity(0.5),
                  width: hasValue ? 1 : 2,
                  style: hasValue ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? value.toString() + (suffix ?? '')
                          : 'Tap to enter ${label.toLowerCase()}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: hasValue
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        fontStyle:
                            hasValue ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: multiline ? null : 1,
                    ),
                  ),
                  Icon(
                    hasValue ? Icons.edit : Icons.add_circle_outline,
                    color: hasValue
                        ? AppTheme.primaryGreen
                        : AppTheme.accentOrange,
                    size: 20,
                  ),
                ],
              ),
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

  /// Build field with type dropdown (for ambiguous fields like tables/checks)
  Widget _buildFieldRowWithType(
    String label,
    String fieldKey,
    String typeKey,
    List<String> typeOptions, {
    String? detectedLabel,
  }) {
    final value = _editableData[fieldKey];
    final hasValue = value != null && value.toString().isNotEmpty;
    final currentType = _editableData[typeKey] ?? typeOptions.first;
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
              if (detectedLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Found as "$detectedLabel"',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentBlue,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: hasValue
                  ? AppTheme.cardBackgroundLight
                  : AppTheme.cardBackgroundLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: hasValue
                    ? (confidenceBadge.isNotEmpty
                        ? confidenceColor.withOpacity(0.3)
                        : AppTheme.textMuted.withOpacity(0.2))
                    : AppTheme.accentOrange.withOpacity(0.5),
                width: hasValue ? 1 : 2,
              ),
            ),
            child: Row(
              children: [
                // Number value
                GestureDetector(
                  onTap: () => _editField(
                      label, fieldKey, hasValue ? value.toString() : ''),
                  child: Text(
                    hasValue ? value.toString() : '—',
                    style: AppTheme.bodyMedium.copyWith(
                      color:
                          hasValue ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Type dropdown
                Expanded(
                  child: DropdownButton<String>(
                    value: currentType,
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: AppTheme.cardBackground,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    items: typeOptions.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newType) {
                      if (newType != null) {
                        setState(() {
                          _editableData[typeKey] = newType;
                        });
                      }
                    },
                    icon: Icon(Icons.arrow_drop_down,
                        color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit icon
                IconButton(
                  icon:
                      Icon(Icons.edit, color: AppTheme.primaryGreen, size: 20),
                  onPressed: () => _editField(
                      label, fieldKey, hasValue ? value.toString() : ''),
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

  /// Save checkout and navigate to Add Shift with pre-filled data
  Future<void> _saveAndCreateShift() async {
    setState(() => _isCreatingShift = true);

    try {
      // First save the checkout
      await widget.onConfirm(_editableData);

      if (!mounted) return;

      // Check for existing shift on this date
      final checkoutDate = _editableData['checkout_date'];
      DateTime? shiftDate;
      if (checkoutDate != null) {
        try {
          shiftDate = DateTime.parse(checkoutDate.toString());
        } catch (_) {
          // Use today if date parsing fails
          shiftDate = DateTime.now();
        }
      } else {
        shiftDate = DateTime.now();
      }

      // Check for existing shifts on this date
      final existingShifts = await _db.getShiftsForDate(shiftDate);

      if (existingShifts.isNotEmpty && mounted) {
        // Show dialog to ask what to do
        final action =
            await _showDuplicateShiftDialog(existingShifts, shiftDate);

        if (action == null) {
          // User cancelled
          setState(() => _isCreatingShift = false);
          return;
        }

        if (action == 'update' && existingShifts.isNotEmpty) {
          // Open edit shift with existing shift pre-filled and updated from checkout
          Navigator.pop(context, true); // Close verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddShiftScreen(
                existingShift: existingShifts.first,
                prefilledCheckoutData: _buildShiftDataFromCheckout(),
              ),
            ),
          );
          return;
        }
        // If action == 'new', continue to create new shift
      }

      // Navigate to Add Shift with pre-filled data
      Navigator.pop(context, true); // Close verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddShiftScreen(
            prefilledCheckoutData: _buildShiftDataFromCheckout(),
            preselectedDate: shiftDate,
          ),
        ),
      );
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
        setState(() => _isCreatingShift = false);
      }
    }
  }

  /// Build shift data from checkout data
  Map<String, dynamic> _buildShiftDataFromCheckout() {
    // Get checkout ID from either widget or editable data
    final checkoutId =
        widget.existingCheckoutId ?? _editableData['id']?.toString();

    return {
      'cashTips': _parseDouble(_editableData['cash_tips']),
      'creditTips': _parseDouble(_editableData['credit_card_tips']),
      'hoursWorked': _parseDouble(_editableData['hours_worked']),
      'salesAmount': _parseDouble(_editableData['gross_sales']),
      'tipoutPercent': null, // User should set this based on their tipout rules
      'additionalTipout': _parseDouble(_editableData['tip_share']),
      'guestCount': _parseInt(_editableData['cover_count']),
      'section': _editableData['section']?.toString(),
      'checkoutId': checkoutId,
      'notes': _buildNotesFromCheckout(),
    };
  }

  /// Build notes from checkout data that doesn't have direct shift mapping
  String _buildNotesFromCheckout() {
    final parts = <String>[];

    if (_editableData['table_count'] != null) {
      final type = _editableData['table_count_type'] ?? 'Tables';
      parts.add('$type: ${_editableData['table_count']}');
    }
    if (_editableData['comps'] != null &&
        _parseDouble(_editableData['comps']) > 0) {
      parts.add('Comps: \$${_editableData['comps']}');
    }
    if (_editableData['promos'] != null &&
        _parseDouble(_editableData['promos']) > 0) {
      parts.add('Promos: \$${_editableData['promos']}');
    }
    if (_editableData['server_name'] != null &&
        _editableData['server_name'].toString().isNotEmpty) {
      parts.add('Server: ${_editableData['server_name']}');
    }

    return parts.join(' • ');
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Show dialog when a shift already exists for this date
  Future<String?> _showDuplicateShiftDialog(
      List<dynamic> existingShifts, DateTime date) {
    final dateStr = '${date.month}/${date.day}/${date.year}';
    final shiftCount = existingShifts.length;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
            const SizedBox(width: 12),
            Text(
              'Shift Already Exists',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have ${shiftCount == 1 ? 'a shift' : '$shiftCount shifts'} recorded for $dateStr.',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like to do?',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'new'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
            child: Text('Create New Shift',
                style: TextStyle(color: AppTheme.primaryGreen)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Update Existing'),
          ),
        ],
      ),
    );
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
              child: widget.scanType == ScanType.checkout
                  ? _buildCheckoutActionButtons()
                  : _buildDefaultActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  /// Default action buttons (Cancel + Confirm & Save)
  Widget _buildDefaultActionButtons() {
    return Row(
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
    );
  }

  /// Checkout-specific action buttons (Cancel, Save Checkout, Save & Create Shift)
  Widget _buildCheckoutActionButtons() {
    final isLoading = _isSaving || _isCreatingShift;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: Save Checkout Only
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.textMuted),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _confirmAndSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.save_outlined, color: AppTheme.primaryGreen),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Checkout Only',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom: Save & Create Shift (primary action)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _saveAndCreateShift,
            icon: _isCreatingShift
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.add_circle),
            label:
                Text(_isCreatingShift ? 'Creating...' : 'Save & Create Shift'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
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
      // Basic info
      _buildFieldRow('Date', 'checkout_date', isRequired: true),
      _buildFieldRow('Server Name', 'server_name'),
      _buildFieldRow('Section', 'section'),

      // Sales
      _buildFieldRow('Gross Sales', 'gross_sales', suffix: ' USD'),
      _buildFieldRow('Comps', 'comps', suffix: ' USD'),
      _buildFieldRow('Promos', 'promos', suffix: ' USD'),
      _buildFieldRow('Net Sales', 'net_sales', suffix: ' USD'),

      // Tips breakdown
      _buildFieldRow('Credit Card Tips', 'credit_card_tips', suffix: ' USD'),
      _buildFieldRowWithCashTipsSource(),
      _buildFieldRow(
          'Total Tips (Before Tip Share)', 'total_tips_before_tipshare',
          suffix: ' USD'),
      _buildFieldRow('Tip Share', 'tip_share', suffix: ' USD'),
      _buildFieldRow('Net Tips (Take Home)', 'net_tips',
          suffix: ' USD', isRequired: true),

      // Additional info
      _buildFieldRow('Hours Worked', 'hours_worked'),
      _buildFieldRowWithType(
        'Service Count',
        'table_count',
        'table_count_type',
        ['Tables', 'Checks'],
        detectedLabel: _editableData['table_count_label_found'],
      ),
      _buildFieldRow('Guest Count', 'cover_count'),

      // Validation
      _buildFieldRow('Validation Notes', 'validation_notes', multiline: true),
    ];
  }

  /// Special widget for cash tips with source indicator
  Widget _buildFieldRowWithCashTipsSource() {
    final value = _editableData['cash_tips'];
    final source = _editableData['cash_tips_source'] ?? 'unknown';
    final hasValue = value != null && value.toString().isNotEmpty;

    String sourceLabel = '';
    Color sourceColor = AppTheme.textMuted;
    if (source == 'calculated') {
      sourceLabel = 'Calculated';
      sourceColor = AppTheme.accentBlue;
    } else if (source == 'found') {
      sourceLabel = 'Found on receipt';
      sourceColor = AppTheme.successColor;
    } else if (source == 'manual') {
      sourceLabel = 'Manual entry';
      sourceColor = AppTheme.accentOrange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Cash Tips',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sourceLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: sourceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sourceLabel,
                    style: AppTheme.labelSmall.copyWith(
                      color: sourceColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              _editField(
                  'Cash Tips', 'cash_tips', hasValue ? value.toString() : '');
              // Mark as manual after editing
              setState(() {
                _editableData['cash_tips_source'] = 'manual';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: hasValue
                    ? AppTheme.cardBackgroundLight
                    : AppTheme.cardBackgroundLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: hasValue
                      ? AppTheme.textMuted.withOpacity(0.2)
                      : AppTheme.accentOrange.withOpacity(0.5),
                  width: hasValue ? 1 : 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? '\$${value.toString()}'
                          : 'Tap to enter cash tips',
                      style: AppTheme.bodyMedium.copyWith(
                        color: hasValue
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        fontStyle:
                            hasValue ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                  Icon(
                    hasValue ? Icons.edit : Icons.add_circle_outline,
                    color: hasValue
                        ? AppTheme.primaryGreen
                        : AppTheme.accentOrange,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
