import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/vision_scan.dart';
import '../models/beo_event.dart';
import '../services/database_service.dart';
import '../services/beo_event_service.dart';
import '../services/scan_image_service.dart';
import 'add_shift_screen.dart';
import 'add_edit_contact_screen.dart';
import 'dart:typed_data';

/// Universal verification screen for all AI scan types
/// Shows extracted data with confidence badges for user review before saving
class ScanVerificationScreen extends StatefulWidget {
  final ScanType scanType;
  final Map<String, dynamic> extractedData;
  final Map<String, dynamic>? confidenceScores;
  final Function(Map<String, dynamic>) onConfirm;
  final Function()? onRetry;
  final String? existingCheckoutId;
  final List<String>? imagePaths; // Image paths from scan session
  final List<Uint8List>? imageBytes; // Image bytes for web compatibility
  final List<String>? mimeTypes; // MIME types for web images

  const ScanVerificationScreen({
    super.key,
    required this.scanType,
    required this.extractedData,
    this.confidenceScores,
    required this.onConfirm,
    this.onRetry,
    this.existingCheckoutId,
    this.imagePaths,
    this.imageBytes,
    this.mimeTypes,
  });

  @override
  State<ScanVerificationScreen> createState() => _ScanVerificationScreenState();
}

class _ScanVerificationScreenState extends State<ScanVerificationScreen> {
  late Map<String, dynamic> _editableData;
  bool _isSaving = false;
  bool _isCreatingShift = false;
  bool _isSavingBeo = false;
  final DatabaseService _db = DatabaseService();
  final BeoEventService _beoService = BeoEventService();
  final ScanImageService _scanImageService = ScanImageService();

  @override
  void initState() {
    super.initState();
    _editableData = Map<String, dynamic>.from(widget.extractedData);

    // Normalize table_count_type to match dropdown options (capitalize first letter)
    if (_editableData.containsKey('table_count_type')) {
      final type = _editableData['table_count_type'] as String?;
      if (type != null && type.isNotEmpty) {
        // Capitalize first letter to match dropdown options: 'checks' -> 'Checks', 'tables' -> 'Tables'
        _editableData['table_count_type'] =
            type[0].toUpperCase() + type.substring(1).toLowerCase();
      }
    }
  }

  /// Upload scan images and return the public URLs
  /// Works with both file paths (mobile) and bytes (web)
  Future<List<String>> _uploadScanImages(String scanType,
      {String? entityId}) async {
    try {
      if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) {
        // Web: Upload from bytes
        return await _scanImageService.uploadFromBytes(
          imageBytes: widget.imageBytes!,
          scanType: scanType,
          entityId: entityId,
          mimeTypes: widget.mimeTypes,
        );
      } else if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
        // Mobile: Upload from file paths
        return await _scanImageService.uploadFromPaths(
          imagePaths: widget.imagePaths!,
          scanType: scanType,
          entityId: entityId,
        );
      }
      return [];
    } catch (e) {
      print('Error uploading scan images: $e');
      return [];
    }
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

  /// Convert military time (e.g., "15:30" or "1530") to 12-hour format (e.g., "3:30 PM")
  String _formatTimeDisplay(String? timeValue) {
    if (timeValue == null || timeValue.isEmpty) return '';

    try {
      String normalized = timeValue.trim();

      // Handle various formats: "15:30", "1530", "15:30:00", "3:30 PM" (already formatted)
      if (normalized.toLowerCase().contains('am') ||
          normalized.toLowerCase().contains('pm')) {
        // Already in 12-hour format
        return normalized;
      }

      int hour;
      int minute;

      if (normalized.contains(':')) {
        final parts = normalized.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      } else if (normalized.length == 4) {
        // Format: "1530"
        hour = int.parse(normalized.substring(0, 2));
        minute = int.parse(normalized.substring(2, 4));
      } else if (normalized.length == 3) {
        // Format: "930" (9:30)
        hour = int.parse(normalized.substring(0, 1));
        minute = int.parse(normalized.substring(1, 3));
      } else {
        return timeValue; // Can't parse, return original
      }

      // Convert to 12-hour format
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');

      return '$displayHour:$displayMinute $period';
    } catch (e) {
      return timeValue; // Return original if parsing fails
    }
  }

  /// Check if a field key is a time field
  bool _isTimeField(String fieldKey) {
    return fieldKey.contains('time') || fieldKey.contains('Time');
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
                    color: AppTheme.accentOrange.withValues(alpha: 0.2),
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
                    : AppTheme.cardBackgroundLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: hasValue
                      ? (confidenceBadge.isNotEmpty
                          ? confidenceColor.withValues(alpha: 0.3)
                          : AppTheme.textMuted.withValues(alpha: 0.2))
                      : AppTheme.accentOrange.withValues(alpha: 0.5),
                  width: hasValue ? 1 : 2,
                  style: hasValue ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? (_isTimeField(fieldKey)
                                  ? _formatTimeDisplay(value.toString())
                                  : value.toString()) +
                              (suffix ?? '')
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

    // Safety: Ensure currentType exists in typeOptions, fallback to first option if not
    String? rawType = _editableData[typeKey];
    String currentType;
    if (rawType != null && typeOptions.contains(rawType)) {
      currentType = rawType;
    } else if (rawType != null) {
      // Try to normalize the value (capitalize first letter)
      final normalized =
          rawType[0].toUpperCase() + rawType.substring(1).toLowerCase();
      if (typeOptions.contains(normalized)) {
        currentType = normalized;
        // Update the stored value
        _editableData[typeKey] = normalized;
      } else {
        currentType = typeOptions.first;
        _editableData[typeKey] = typeOptions.first;
      }
    } else {
      currentType = typeOptions.first;
    }
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
                    color: AppTheme.accentBlue.withValues(alpha: 0.2),
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
                  : AppTheme.cardBackgroundLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: hasValue
                    ? (confidenceBadge.isNotEmpty
                        ? confidenceColor.withValues(alpha: 0.3)
                        : AppTheme.textMuted.withValues(alpha: 0.2))
                    : AppTheme.accentOrange.withValues(alpha: 0.5),
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
      // Determine scan type folder for image storage
      String scanTypeFolder;
      switch (widget.scanType) {
        case ScanType.paycheck:
          scanTypeFolder = 'paycheck';
          break;
        case ScanType.invoice:
          scanTypeFolder = 'invoice';
          break;
        case ScanType.receipt:
          scanTypeFolder = 'receipt';
          break;
        case ScanType.businessCard:
          scanTypeFolder = 'business_card';
          break;
        case ScanType.checkout:
          scanTypeFolder = 'checkout';
          break;
        case ScanType.beo:
          scanTypeFolder = 'beo';
          break;
      }

      // Upload scan images
      final imageUrls = await _uploadScanImages(scanTypeFolder);

      // Add image URLs to the data
      if (imageUrls.isNotEmpty) {
        // Use 'image_urls' for multiple images, 'image_url' for single
        if (widget.scanType == ScanType.paycheck ||
            widget.scanType == ScanType.businessCard) {
          // These typically have single images
          _editableData['image_url'] = imageUrls.first;
        } else {
          _editableData['image_urls'] = imageUrls;
        }
      }

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
      // Upload scan images for checkout
      final imageUrls = await _uploadScanImages('checkout');

      // Add image URLs to the data before saving
      if (imageUrls.isNotEmpty) {
        _editableData['image_urls'] = imageUrls;
      }

      // Save the checkout with images
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
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
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
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: widget.scanType == ScanType.checkout
                  ? _buildCheckoutActionButtons()
                  : widget.scanType == ScanType.beo
                      ? _buildBeoActionButtons()
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

  /// BEO-specific action buttons (Cancel, Save BEO Only, Save & Create Shift)
  Widget _buildBeoActionButtons() {
    final isLoading = _isSavingBeo || _isCreatingShift;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: Cancel + Save BEO Only
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
                onPressed: isLoading ? null : _saveBeoOnly,
                icon: _isSavingBeo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.description_outlined,
                        color: AppTheme.accentPurple),
                label: Text(
                  _isSavingBeo ? 'Saving...' : 'Save as BEO Only',
                  style: TextStyle(color: AppTheme.accentPurple),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentPurple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom: Save BEO & Create Shift (primary action)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _saveBeoAndCreateShift,
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
            label: Text(
                _isCreatingShift ? 'Creating...' : 'Save BEO & Create Shift'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Helper text
        Text(
          'BEO will appear on your calendar • Shift tracks your work hours',
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Save BEO only (standalone) - appears on calendar with purple dot
  Future<void> _saveBeoOnly() async {
    setState(() => _isSavingBeo = true);

    try {
      final userId = _db.supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Generate BEO ID first so we can use it for image upload
      final beoId = _editableData['id'] ?? const Uuid().v4();

      // Upload scan images
      final imageUrls = await _uploadScanImages('beo', entityId: beoId);

      // Ensure required fields are present
      final beoData = {
        ..._editableData,
        'id': beoId,
        'user_id': userId,
        'event_date': _editableData['event_date'] ??
            DateTime.now().toIso8601String().split('T')[0],
        'event_name': _editableData['event_name'] ?? 'Untitled Event',
        'is_standalone': true,
        'created_manually': false,
        'image_urls': imageUrls.isNotEmpty ? imageUrls : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Create BeoEvent from extracted data
      final beoEvent = BeoEvent.fromJson(beoData);

      // Save to database
      await _beoService.createBeoEvent(beoEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    imageUrls.isNotEmpty
                        ? 'BEO saved with ${imageUrls.length} image(s)! It will appear on your calendar.'
                        : 'BEO saved! It will appear on your calendar.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentPurple,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save BEO: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBeo = false);
      }
    }
  }

  /// Save BEO and create a linked shift
  Future<void> _saveBeoAndCreateShift() async {
    setState(() => _isCreatingShift = true);

    try {
      final userId = _db.supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Use existing BEO ID from AI analysis or generate new one
      final beoId = _editableData['id'] as String? ?? const Uuid().v4();
      final isExistingBeo = _editableData['id'] != null;

      print('🎯 BEO ID for Shift+BEO: $beoId, isExisting: $isExistingBeo');

      // Upload scan images
      final imageUrls = await _uploadScanImages('beo', entityId: beoId);

      // Ensure required fields are present
      final beoData = {
        ..._editableData,
        'id': beoId,
        'user_id': userId,
        'event_date': _editableData['event_date'] ??
            DateTime.now().toIso8601String().split('T')[0],
        'event_name': _editableData['event_name'] ?? 'Untitled Event',
        'is_standalone': false, // Will be linked to a shift
        'created_manually': false,
        'image_urls': imageUrls.isNotEmpty ? imageUrls : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Create or update the BEO event
      final beoEvent = BeoEvent.fromJson(beoData);
      print(
          '🎯 BEO Event for Shift+BEO: eventName=${beoEvent.eventName}, venueName=${beoEvent.venueName}, eventDate=${beoEvent.eventDate}');

      final savedBeo = isExistingBeo
          ? await _beoService.updateBeoEvent(beoEvent) // Update existing BEO
          : await _beoService.createBeoEvent(beoEvent); // Create new BEO

      print(
          '🎯 BEO ${isExistingBeo ? 'updated' : 'created'} with ID: ${savedBeo.id}');

      if (!mounted) return;

      // Prepare the data to pass to AddShiftScreen
      final prefilledData = {
        'event_name': beoEvent.eventName,
        'location': beoEvent.venueName ?? '',
        'hostess': beoEvent.primaryContactName ?? '',
        'guest_count': beoEvent.displayGuestCount?.toString() ?? '',
        'event_cost': beoEvent.grandTotal?.toString() ?? '',
        'commission': beoEvent.commissionAmount?.toString() ?? '',
        'start_time': beoEvent.eventStartTime,
        'end_time': beoEvent.eventEndTime,
        'beo_event_id': savedBeo.id,
        'image_urls': imageUrls, // Pass the uploaded image URLs
      };
      print(
          '🎯 Navigating to AddShiftScreen with prefilledBeoData: $prefilledData');

      // Navigate to Add Shift screen with pre-filled data from BEO
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddShiftScreen(
            preselectedDate: beoEvent.eventDate,
            prefilledBeoData: prefilledData,
          ),
        ),
      );

      if (mounted) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'BEO saved & Shift created!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // Only pop if we can safely do so
        if (Navigator.canPop(context)) {
          Navigator.pop(context, result ?? false);
        }
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
        setState(() => _isCreatingShift = false);
      }
    }
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
      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 1: EVENT IDENTITY
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Event Information', Icons.event),
      _buildFieldRow('Event Name', 'event_name', isRequired: true),
      _buildFieldRow('Event Date', 'event_date', isRequired: true),
      _buildFieldRow('Event Type', 'event_type'),
      _buildFieldRow('Venue', 'venue_name'),
      _buildFieldRow('Venue Address', 'venue_address'),
      _buildFieldRow('Function Space', 'function_space'),
      _buildFieldRow('Account Name', 'account_name'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 2: CONTACTS
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Contact Information', Icons.people),
      _buildFieldRow('Client/Host Name', 'primary_contact_name'),
      _buildFieldRow('Client Phone', 'primary_contact_phone'),
      _buildFieldRow('Client Email', 'primary_contact_email'),
      _buildFieldRow('Sales Manager', 'sales_manager_name'),
      _buildFieldRow('Sales Manager Phone', 'sales_manager_phone'),
      _buildFieldRow('Catering Manager', 'catering_manager_name'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 3: TIMING
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Timeline', Icons.schedule),
      _buildFieldRow('Event Start Time', 'event_start_time'),
      _buildFieldRow('Event End Time', 'event_end_time'),
      _buildFieldRow('Setup Time', 'setup_time'),
      _buildFieldRow('Guest Arrival Time', 'guest_arrival_time'),
      _buildFieldRow('Breakdown Time', 'breakdown_time'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 4: GUEST COUNTS
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Guest Count', Icons.groups),
      _buildFieldRow('Confirmed Guests', 'guest_count_confirmed'),
      _buildFieldRow('Expected Guests', 'guest_count_expected'),
      _buildFieldRow('Adult Count', 'adult_count'),
      _buildFieldRow('Child Count', 'child_count'),
      _buildFieldRow('Vendor Meals', 'vendor_meal_count'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 5: FINANCIALS
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Financials', Icons.attach_money),
      _buildFieldRow('Food Total', 'food_total', suffix: ' USD'),
      _buildFieldRow('Beverage Total', 'beverage_total', suffix: ' USD'),
      _buildFieldRow('Labor Total', 'labor_total', suffix: ' USD'),
      _buildFieldRow('Room Rental', 'room_rental', suffix: ' USD'),
      _buildFieldRow('Equipment Rental', 'equipment_rental', suffix: ' USD'),
      _buildFieldRow('Subtotal', 'subtotal', suffix: ' USD'),
      _buildFieldRow('Service Charge %', 'service_charge_percent', suffix: '%'),
      _buildFieldRow('Service Charge', 'service_charge_amount', suffix: ' USD'),
      _buildFieldRow('Tax %', 'tax_percent', suffix: '%'),
      _buildFieldRow('Tax Amount', 'tax_amount', suffix: ' USD'),
      _buildFieldRow('Gratuity', 'gratuity_amount', suffix: ' USD'),
      _buildFieldRow('Grand Total', 'grand_total', suffix: ' USD'),
      _buildFieldRow('Deposits Paid', 'deposits_paid', suffix: ' USD'),
      _buildFieldRow('Balance Due', 'balance_due', suffix: ' USD'),
      _buildFieldRow('Total Sale', 'total_sale_amount', suffix: ' USD'),
      _buildFieldRow('Commission %', 'commission_percentage', suffix: '%'),
      _buildFieldRow('Commission Amount', 'commission_amount', suffix: ' USD'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 6: MENU
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Menu', Icons.restaurant_menu),
      _buildFieldRow('Menu Style', 'menu_style'),
      _buildFieldRow('Menu Items', 'menu_items', multiline: true),
      _buildFieldRow('Dietary Restrictions', 'dietary_restrictions',
          multiline: true),
      if (_editableData['menu_details'] != null)
        _buildJsonFieldDisplay('Menu Details', 'menu_details'),
      if (_editableData['beverage_details'] != null)
        _buildJsonFieldDisplay('Beverage Details', 'beverage_details'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 7: SETUP & DECOR
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Setup & Decor', Icons.chair),
      _buildFieldRow('Decor Notes', 'decor_notes', multiline: true),
      _buildFieldRow('Floor Plan Notes', 'floor_plan_notes', multiline: true),
      if (_editableData['setup_details'] != null)
        _buildJsonFieldDisplay('Setup Details', 'setup_details'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 8: STAFFING
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Staffing', Icons.badge),
      _buildFieldRow('Staffing Requirements', 'staffing_requirements',
          multiline: true),
      if (_editableData['staffing_details'] != null)
        _buildJsonFieldDisplay('Staffing Details', 'staffing_details'),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 9: VENDORS
      // ═══════════════════════════════════════════════════════════════════════
      if (_editableData['vendor_details'] != null) ..._buildVendorSection(),

      // ═══════════════════════════════════════════════════════════════════════
      // SECTION 10: ADDITIONAL NOTES
      // ═══════════════════════════════════════════════════════════════════════
      _buildSectionHeader('Additional Notes', Icons.notes),
      _buildFieldRow('Special Requests', 'special_requests', multiline: true),
      if (_editableData['formatted_notes'] != null)
        _buildFieldRow('AI-Organized Notes', 'formatted_notes',
            multiline: true),
    ];
  }

  /// Build a section header with icon
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Expanded(child: SizedBox()),
          Container(
            height: 1,
            width: 100,
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// Build a display for JSON fields (menu_details, setup_details, etc.)
  Widget _buildJsonFieldDisplay(String label, String fieldKey) {
    final data = _editableData[fieldKey];
    if (data == null) return const SizedBox.shrink();

    String displayText = '';
    if (data is Map) {
      data.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          if (value is List) {
            displayText += '• $key:\n';
            for (var item in value) {
              if (item is Map) {
                final name = item['name'] ?? item['type'] ?? 'Item';
                displayText += '  - $name\n';
              } else {
                displayText += '  - $item\n';
              }
            }
          } else {
            displayText += '• $key: $value\n';
          }
        }
      });
    }

    if (displayText.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.textMuted.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              displayText.trim(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build vendor section with "Add to Contacts" buttons
  List<Widget> _buildVendorSection() {
    final vendors = _editableData['vendor_details'];
    if (vendors == null || vendors is! List || vendors.isEmpty) {
      return [];
    }

    return [
      _buildSectionHeader('Vendors', Icons.business),
      ...vendors.map<Widget>((vendor) {
        final name = vendor['name'] ?? 'Unknown Vendor';
        final type = vendor['type'] ?? 'Vendor';
        final phone = vendor['phone'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.textMuted.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        type,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addVendorToContacts(vendor),
                  icon: Icon(Icons.person_add,
                      color: AppTheme.primaryGreen, size: 18),
                  label: Text(
                    'Add to Contacts',
                    style:
                        TextStyle(color: AppTheme.primaryGreen, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  /// Add vendor to contacts - navigates to add contact screen with pre-filled data
  void _addVendorToContacts(Map<String, dynamic> vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(
          preFillData: {
            'name': vendor['name'] ?? '',
            'type': vendor['type'] ?? '',
            'phone': vendor['phone'] ?? '',
            'email': vendor['email'] ?? '',
            'company': vendor['company'] ?? vendor['name'] ?? '',
            'notes': 'Added from BEO scan',
          },
        ),
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vendor['name']} added to contacts'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    });
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
                    color: sourceColor.withValues(alpha: 0.2),
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
                    : AppTheme.cardBackgroundLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: hasValue
                      ? AppTheme.textMuted.withValues(alpha: 0.2)
                      : AppTheme.accentOrange.withValues(alpha: 0.5),
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
