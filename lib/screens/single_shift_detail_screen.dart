import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/shift.dart';
import '../models/event_contact.dart';
import '../models/shift_attachment.dart';
import '../models/beo_event.dart';
import '../providers/shift_provider.dart';
import '../providers/field_order_provider.dart';
import '../screens/add_shift_screen.dart';
import '../screens/event_contacts_screen.dart';
import '../screens/add_edit_contact_screen.dart';
import '../services/database_service.dart';
import '../services/beo_event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/navigation_wrapper.dart';
import '../widgets/document_preview_widget.dart';
import 'package:intl/intl.dart';

class SingleShiftDetailScreen extends StatefulWidget {
  final Shift shift;

  const SingleShiftDetailScreen({super.key, required this.shift});

  @override
  State<SingleShiftDetailScreen> createState() =>
      _SingleShiftDetailScreenState();
}

class _SingleShiftDetailScreenState extends State<SingleShiftDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  String? _jobName;
  String? _employer;
  double? _jobHourlyRate; // Store job's default hourly rate
  List<EventContact> _eventContacts = [];
  bool _isLoadingContacts = false;

  // File attachments
  List<ShiftAttachment> _attachments = [];
  bool _isLoadingAttachments = false;
  bool _isUploadingAttachment = false;
  bool _attachmentViewIsGrid = false; // false = list, true = grid
  Map<String, String> _attachmentUrlCache =
      {}; // Cache signed URLs to prevent reloading
  bool _isSelectingAttachments = false;
  Set<String> _selectedAttachmentIds = {};

  // Linked BEO Event
  BeoEvent? _linkedBeoEvent;
  bool _isLoadingBeo = false;
  bool _isBeoExpanded = false;
  final BeoEventService _beoService = BeoEventService();

  // Inline editing state
  late Shift _editableShift;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  String? _activeEditField;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Text controllers for inline editing
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Convenience getter to access shift (now uses editable)
  Shift get shift => _editableShift;

  // Get effective hourly rate (shift override or job default)
  double get effectiveHourlyRate {
    if (shift.hourlyRate > 0) {
      return shift.hourlyRate; // Use shift's override rate
    }
    return _jobHourlyRate ?? 0; // Fall back to job's rate
  }

  // Calculate hours from start/end time
  double get _calculatedHours {
    final startTime = _controllers['startTime']?.text ?? shift.startTime ?? '';
    final endTime = _controllers['endTime']?.text ?? shift.endTime ?? '';

    if (startTime.isEmpty || endTime.isEmpty) {
      return shift.hoursWorked; // Fall back to stored value
    }

    try {
      final start = _parseTimeToMinutes(startTime);
      final end = _parseTimeToMinutes(endTime);

      if (start == null || end == null) return shift.hoursWorked;

      int diffMinutes = end - start;
      if (diffMinutes < 0) {
        diffMinutes += 24 * 60; // Handle overnight shifts
      }

      return diffMinutes / 60.0;
    } catch (e) {
      return shift.hoursWorked;
    }
  }

  // Parse time string to minutes since midnight
  int? _parseTimeToMinutes(String time) {
    if (time.isEmpty) return null;

    // Handle various formats: "2:00 PM", "14:00", "2PM", "2 PM"
    String cleaned = time.trim().toUpperCase();
    bool isPM = cleaned.contains('PM');
    bool isAM = cleaned.contains('AM');

    // Remove AM/PM
    cleaned = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim();

    // Split by : or just get the hour
    List<String> parts = cleaned.split(':');
    int hour = int.tryParse(parts[0].trim()) ?? 0;
    int minute = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;

    // Convert to 24-hour if needed
    if (isPM && hour < 12) hour += 12;
    if (isAM && hour == 12) hour = 0;

    // If no AM/PM specified and hour > 12, assume 24-hour format
    // Otherwise if hour <= 12 and no indicator, leave as-is (user should specify)

    return hour * 60 + minute;
  }

  // Calculate total income using effective hourly rate
  double get effectiveTotalIncome {
    double base = effectiveHourlyRate * _calculatedHours;
    double tips = shift.cashTips + shift.creditTips;
    double overtimePay = (shift.overtimeHours ?? 0) * effectiveHourlyRate * 0.5;
    double commissionEarnings = shift.commission ?? 0;
    double flatRateEarnings = shift.flatRate ?? 0;
    return base + tips + overtimePay + commissionEarnings + flatRateEarnings;
  }

  @override
  void initState() {
    super.initState();

    // Initialize editable shift copy
    _editableShift = widget.shift;

    // Setup pulse animation for save button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Initialize text controllers
    _initializeControllers();

    _loadJobName();
    _loadEventContacts();
    _loadAttachments();
    _loadLinkedBeoEvent();
    _loadAttachmentViewPreference();
  }

  Future<void> _loadAttachmentViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _attachmentViewIsGrid =
            prefs.getBool('attachment_view_is_grid') ?? false;
      });
    }
  }

  Future<void> _toggleAttachmentView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _attachmentViewIsGrid = !_attachmentViewIsGrid;
    });
    await prefs.setBool('attachment_view_is_grid', _attachmentViewIsGrid);
  }

  void _toggleAttachmentSelection(String attachmentId) {
    setState(() {
      if (_selectedAttachmentIds.contains(attachmentId)) {
        _selectedAttachmentIds.remove(attachmentId);
        if (_selectedAttachmentIds.isEmpty) {
          _isSelectingAttachments = false;
        }
      } else {
        _selectedAttachmentIds.add(attachmentId);
      }
    });
  }

  void _startAttachmentSelection(String attachmentId) {
    setState(() {
      _isSelectingAttachments = true;
      _selectedAttachmentIds.add(attachmentId);
    });
  }

  void _cancelAttachmentSelection() {
    setState(() {
      _isSelectingAttachments = false;
      _selectedAttachmentIds.clear();
    });
  }

  Future<void> _shareSelectedAttachments() async {
    final selectedAttachments = _attachments
        .where((a) => _selectedAttachmentIds.contains(a.id))
        .toList();

    // Show loading dialog immediately
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: AppTheme.cardBackground,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen)),
                SizedBox(height: 16),
                Text('Preparing files...', style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();

      // Download all files IN PARALLEL
      final downloadFutures = selectedAttachments.map((attachment) async {
        // Use cached URL if available, otherwise fetch it
        final url = _attachmentUrlCache[attachment.id] ??
            await _db.getAttachmentUrl(attachment.storagePath);
        final response = await http.get(Uri.parse(url));
        final file = File('${tempDir.path}/${attachment.fileName}');
        await file.writeAsBytes(response.bodyBytes);
        return XFile(file.path);
      }).toList();

      final files = await Future.wait(downloadFutures);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show share sheet
      await Share.shareXFiles(files, text: 'Attachments');
      _cancelAttachmentSelection();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _deleteSelectedAttachments() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete ${_selectedAttachmentIds.length} attachments?',
            style: AppTheme.titleMedium),
        content: Text('These attachments will be permanently deleted.',
            style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final selectedAttachments = _attachments
            .where((a) => _selectedAttachmentIds.contains(a.id))
            .toList();
        for (final attachment in selectedAttachments) {
          await _db.deleteAttachment(attachment);
        }
        await _loadAttachments();
        _cancelAttachmentSelection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${selectedAttachments.length} attachments deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  /// Load linked BEO event if shift has beoEventId
  Future<void> _loadLinkedBeoEvent() async {
    if (_editableShift.beoEventId == null) return;

    setState(() => _isLoadingBeo = true);

    try {
      final beo = await _beoService.getBeoEventById(_editableShift.beoEventId!);
      if (mounted) {
        setState(() {
          _linkedBeoEvent = beo;
          _isLoadingBeo = false;
        });
      }
    } catch (e) {
      print('Error loading linked BEO: $e');
      if (mounted) {
        setState(() => _isLoadingBeo = false);
      }
    }
  }

  void _initializeControllers() {
    final s = _editableShift;

    // Money fields
    _controllers['cashTips'] =
        TextEditingController(text: s.cashTips.toStringAsFixed(2));
    _controllers['creditTips'] =
        TextEditingController(text: s.creditTips.toStringAsFixed(2));
    _controllers['hourlyRate'] =
        TextEditingController(text: s.hourlyRate.toStringAsFixed(2));
    _controllers['hoursWorked'] =
        TextEditingController(text: s.hoursWorked.toStringAsFixed(1));

    // Event details
    _controllers['eventName'] = TextEditingController(text: s.eventName ?? '');
    _controllers['hostess'] = TextEditingController(text: s.hostess ?? '');
    _controllers['guestCount'] =
        TextEditingController(text: s.guestCount?.toString() ?? '');
    // Initialize time in 12-hour format for editing
    _controllers['startTime'] = TextEditingController(
        text: s.startTime != null && s.startTime!.isNotEmpty
            ? _formatTimeForEdit(s.startTime!)
            : '');
    _controllers['endTime'] = TextEditingController(
        text: s.endTime != null && s.endTime!.isNotEmpty
            ? _formatTimeForEdit(s.endTime!)
            : '');

    // Work details
    _controllers['location'] = TextEditingController(text: s.location ?? '');
    _controllers['clientName'] =
        TextEditingController(text: s.clientName ?? '');
    _controllers['projectName'] =
        TextEditingController(text: s.projectName ?? '');
    _controllers['mileage'] =
        TextEditingController(text: s.mileage?.toStringAsFixed(1) ?? '');

    // Additional earnings
    _controllers['commission'] =
        TextEditingController(text: s.commission?.toStringAsFixed(2) ?? '');
    _controllers['flatRate'] =
        TextEditingController(text: s.flatRate?.toStringAsFixed(2) ?? '');
    _controllers['overtimeHours'] =
        TextEditingController(text: s.overtimeHours?.toStringAsFixed(1) ?? '');

    // Notes
    _controllers['notes'] = TextEditingController(text: s.notes ?? '');

    // Create focus nodes for each field
    for (final key in _controllers.keys) {
      _focusNodes[key] = FocusNode();
      _focusNodes[key]!.addListener(() {
        if (!_focusNodes[key]!.hasFocus && _activeEditField == key) {
          _onFieldEditComplete(key);
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onFieldEditComplete(String fieldKey) {
    setState(() {
      _activeEditField = null;
    });
    _updateShiftField(fieldKey);
  }

  void _updateShiftField(String fieldKey) {
    final controller = _controllers[fieldKey];
    if (controller == null) return;

    final value = controller.text.trim();
    bool changed = false;

    setState(() {
      switch (fieldKey) {
        case 'cashTips':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.cashTips != parsed) {
            _editableShift = _editableShift.copyWith(cashTips: parsed);
            changed = true;
          }
          break;
        case 'creditTips':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.creditTips != parsed) {
            _editableShift = _editableShift.copyWith(creditTips: parsed);
            changed = true;
          }
          break;
        case 'hourlyRate':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.hourlyRate != parsed) {
            _editableShift = _editableShift.copyWith(hourlyRate: parsed);
            changed = true;
          }
          break;
        case 'hoursWorked':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.hoursWorked != parsed) {
            _editableShift = _editableShift.copyWith(hoursWorked: parsed);
            changed = true;
          }
          break;
        case 'eventName':
          if (_editableShift.eventName != (value.isEmpty ? null : value)) {
            _editableShift = _editableShift.copyWith(
                eventName: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'hostess':
          if (_editableShift.hostess != (value.isEmpty ? null : value)) {
            _editableShift =
                _editableShift.copyWith(hostess: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'guestCount':
          final parsed = int.tryParse(value);
          if (_editableShift.guestCount != parsed) {
            _editableShift = _editableShift.copyWith(guestCount: parsed);
            changed = true;
          }
          break;
        case 'startTime':
          // Smart complete the time (auto-add AM/PM based on reasonable shift length)
          final completedStart =
              value.isEmpty ? null : _smartCompleteTime(value, 'startTime');
          // Update the controller to show the completed time
          if (completedStart != null && completedStart != value) {
            _controllers['startTime']?.text = completedStart;
          }
          if (_editableShift.startTime != completedStart) {
            _editableShift = _editableShift.copyWith(
                startTime: completedStart, hoursWorked: _calculatedHours);
            changed = true;
          }
          break;
        case 'endTime':
          // Smart complete the time (auto-add AM/PM based on reasonable shift length)
          final completedEnd =
              value.isEmpty ? null : _smartCompleteTime(value, 'endTime');
          // Update the controller to show the completed time
          if (completedEnd != null && completedEnd != value) {
            _controllers['endTime']?.text = completedEnd;
          }
          if (_editableShift.endTime != completedEnd) {
            _editableShift = _editableShift.copyWith(
                endTime: completedEnd, hoursWorked: _calculatedHours);
            changed = true;
          }
          break;
        case 'location':
          if (_editableShift.location != (value.isEmpty ? null : value)) {
            _editableShift =
                _editableShift.copyWith(location: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'clientName':
          if (_editableShift.clientName != (value.isEmpty ? null : value)) {
            _editableShift = _editableShift.copyWith(
                clientName: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'projectName':
          if (_editableShift.projectName != (value.isEmpty ? null : value)) {
            _editableShift = _editableShift.copyWith(
                projectName: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'mileage':
          final parsed = double.tryParse(value);
          if (_editableShift.mileage != parsed) {
            _editableShift = _editableShift.copyWith(mileage: parsed);
            changed = true;
          }
          break;
        case 'commission':
          final parsed = double.tryParse(value);
          if (_editableShift.commission != parsed) {
            _editableShift = _editableShift.copyWith(commission: parsed);
            changed = true;
          }
          break;
        case 'flatRate':
          final parsed = double.tryParse(value);
          if (_editableShift.flatRate != parsed) {
            _editableShift = _editableShift.copyWith(flatRate: parsed);
            changed = true;
          }
          break;
        case 'overtimeHours':
          final parsed = double.tryParse(value);
          if (_editableShift.overtimeHours != parsed) {
            _editableShift = _editableShift.copyWith(overtimeHours: parsed);
            changed = true;
          }
          break;
        case 'notes':
          if (_editableShift.notes != (value.isEmpty ? null : value)) {
            _editableShift =
                _editableShift.copyWith(notes: value.isEmpty ? null : value);
            changed = true;
          }
          break;
      }

      if (changed) {
        _hasUnsavedChanges = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _db.updateShift(_editableShift);

      // Auto-refresh calendar/shifts after every save
      if (mounted) {
        final shiftProvider =
            Provider.of<ShiftProvider>(context, listen: false);
        await shiftProvider.loadShifts();
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text('Changes saved',
                    style: TextStyle(color: AppTheme.textPrimary)),
              ],
            ),
            backgroundColor: AppTheme.cardBackground,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Unsaved Changes'),
        content:
            const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back without saving
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveChanges();
              if (mounted) Navigator.pop(context); // Go back after saving
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadEventContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final contacts = await _db.getEventContactsForShift(shift.id);
      setState(() {
        _eventContacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _loadAttachments() async {
    setState(() => _isLoadingAttachments = true);
    try {
      final attachments = await _db.getShiftAttachments(shift.id);

      // Pre-load URLs for all image attachments to cache them
      for (final attachment in attachments) {
        if (attachment.isImage &&
            !_attachmentUrlCache.containsKey(attachment.id)) {
          try {
            final url = await _db.getAttachmentUrl(attachment.storagePath);
            _attachmentUrlCache[attachment.id] = url;
          } catch (e) {
            // Skip failed loads
          }
        }
      }

      setState(() {
        _attachments = attachments;
        _isLoadingAttachments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAttachments = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick a file of any type
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploadingAttachment = true);

      final file = result.files.first;
      final fileBytes = file.bytes;
      final filePath = file.path;

      // Create File object from path or bytes
      File fileToUpload;
      if (filePath != null) {
        fileToUpload = File(filePath);
      } else if (fileBytes != null) {
        // Web platform - save bytes to temp file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(fileBytes);
        fileToUpload = tempFile;
      } else {
        throw Exception('Could not read file');
      }

      // Upload to Supabase
      final storagePath = await _db.uploadShiftAttachment(
        shiftId: shift.id,
        file: fileToUpload,
        fileName: file.name,
      );

      // Save metadata
      await _db.saveAttachmentMetadata(
        shiftId: shift.id,
        fileName: file.name,
        filePath: storagePath,
        fileType: file.extension ?? 'unknown',
        fileSize: file.size,
        fileExtension: file.extension ?? '',
      );

      // Reload attachments
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${file.name} attached successfully'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach file: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _deleteAttachment(ShiftAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Attachment?', style: AppTheme.titleMedium),
        content: Text(
          'Are you sure you want to delete "${attachment.fileName}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.deleteAttachment(attachment);
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${attachment.fileName} deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete attachment: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(ShiftAttachment attachment) async {
    try {
      // Get signed URL
      final url = await _db.getAttachmentUrl(attachment.filePath);

      // Try to open in system default app
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open file';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open attachment: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _shareAttachment(ShiftAttachment attachment) async {
    try {
      if (kIsWeb) {
        // On web, share the file URL directly
        final url = await _db.getAttachmentUrl(attachment.filePath);
        await Share.share(url,
            subject: 'Shift Attachment - ${attachment.fileName}');
      } else {
        // On mobile, download and share the file
        final bytes = await _db.downloadAttachment(attachment.filePath);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${attachment.fileName}');
        await tempFile.writeAsBytes(bytes);

        // Share using share_plus
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: 'Shift Attachment - ${attachment.fileName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share attachment: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _loadJobName() async {
    if (widget.shift.jobId != null) {
      final jobs = await _db.getJobs();
      final job = jobs.firstWhere(
        (j) => j['id'] == widget.shift.jobId,
        orElse: () => {},
      );
      if (job.isNotEmpty && job['name'] != null) {
        setState(() {
          _jobName = job['name'] as String;
          _employer = job['employer'] as String?;
          _jobHourlyRate = (job['hourly_rate'] as num?)?.toDouble() ?? 0;
        });
      }
    } else if (widget.shift.jobType != null &&
        widget.shift.jobType!.isNotEmpty) {
      setState(() {
        _jobName = widget.shift.jobType;
      });
    }
  }

  /// Converts military time (e.g., "17:00") to 12-hour format (e.g., "5:00 PM")
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';

    try {
      // Check if already in 12-hour format (contains AM/PM)
      if (time.toUpperCase().contains('AM') ||
          time.toUpperCase().contains('PM')) {
        return time;
      }

      // Parse 24-hour time
      final parts = time.split(':');
      if (parts.length < 2) return time;

      int hour = int.parse(parts[0]);
      final minute = parts[1].substring(0, 2); // Handle cases like "17:00:00"

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:$minute $period';
    } catch (e) {
      return time; // Return original if parsing fails
    }
  }

  /// Same as _formatTime but returns the formatted time for editing (no "--:--")
  String _formatTimeForEdit(String time) {
    if (time.isEmpty) return '';

    try {
      // Check if already in 12-hour format (contains AM/PM)
      if (time.toUpperCase().contains('AM') ||
          time.toUpperCase().contains('PM')) {
        return time;
      }

      // Parse 24-hour time
      final parts = time.split(':');
      if (parts.length < 2) return time;

      int hour = int.parse(parts[0]);
      final minute = parts[1].substring(0, 2); // Handle cases like "17:00:00"

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:$minute $period';
    } catch (e) {
      return time; // Return original if parsing fails
    }
  }

  /// Smart time completion - auto-adds AM/PM based on what makes a reasonable shift
  /// If user types "2" for end time and start is "2:00 PM", picks "10:00 PM" (8hr) not "10:00 AM" (20hr)
  String _smartCompleteTime(String input, String fieldKey) {
    if (input.isEmpty) return '';

    String cleaned = input.trim().toUpperCase();

    // Already has AM/PM - just format it properly
    if (cleaned.contains('AM') || cleaned.contains('PM')) {
      return _normalizeTimeFormat(cleaned);
    }

    // Parse the hour and minute from input
    int hour;
    int minute = 0;

    // Remove any non-numeric characters except colon
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9:]'), '');

    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      hour = int.tryParse(parts[0]) ?? 0;
      minute = int.tryParse(parts[1]) ?? 0;
    } else {
      hour = int.tryParse(cleaned) ?? 0;
    }

    if (hour < 1 || hour > 12) {
      // Invalid hour, try to salvage
      if (hour > 12 && hour <= 23) {
        // Already in 24-hour format
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '$hour:${minute.toString().padLeft(2, '0')} $period';
      }
      return input; // Can't parse, return as-is
    }

    // Need to determine AM or PM intelligently
    String otherTimeField = fieldKey == 'startTime' ? 'endTime' : 'startTime';
    String? otherTime = _controllers[otherTimeField]?.text;

    // Default assumptions for typical work shifts
    // Most shifts are between 4-10 hours
    // Most service industry shifts start between 10 AM and 6 PM

    String bestPeriod = 'PM'; // Default to PM for service industry

    if (otherTime != null && otherTime.isNotEmpty) {
      int? otherMinutes = _parseTimeToMinutes(otherTime);

      if (otherMinutes != null) {
        // Calculate both AM and PM options
        int thisAsAM = (hour == 12 ? 0 : hour) * 60 + minute;
        int thisAsPM = (hour == 12 ? 12 : hour + 12) * 60 + minute;

        int diffAM, diffPM;

        if (fieldKey == 'startTime') {
          // This is start time, other is end time
          diffAM = otherMinutes - thisAsAM;
          diffPM = otherMinutes - thisAsPM;
          if (diffAM < 0) diffAM += 24 * 60;
          if (diffPM < 0) diffPM += 24 * 60;
        } else {
          // This is end time, other is start time
          diffAM = thisAsAM - otherMinutes;
          diffPM = thisAsPM - otherMinutes;
          if (diffAM < 0) diffAM += 24 * 60;
          if (diffPM < 0) diffPM += 24 * 60;
        }

        // Pick the one that results in a reasonable shift (4-12 hours ideal)
        bool amReasonable = diffAM >= 3 * 60 && diffAM <= 14 * 60;
        bool pmReasonable = diffPM >= 3 * 60 && diffPM <= 14 * 60;

        if (amReasonable && !pmReasonable) {
          bestPeriod = 'AM';
        } else if (pmReasonable && !amReasonable) {
          bestPeriod = 'PM';
        } else if (amReasonable && pmReasonable) {
          // Both reasonable, pick shorter shift
          bestPeriod = diffAM <= diffPM ? 'AM' : 'PM';
        } else {
          // Neither great, pick shorter
          bestPeriod = diffAM <= diffPM ? 'AM' : 'PM';
        }
      }
    } else {
      // No other time to compare - use smart defaults
      // For start time: assume PM (afternoon/evening shifts common)
      // For end time: assume PM unless hour is very early (1-5 suggest AM next day)
      if (fieldKey == 'endTime' && hour >= 1 && hour <= 5) {
        bestPeriod = 'AM'; // Likely overnight shift ending early morning
      } else if (fieldKey == 'startTime' && hour >= 6 && hour <= 11) {
        bestPeriod = 'AM'; // Morning start
      } else {
        bestPeriod = 'PM';
      }
    }

    return '$hour:${minute.toString().padLeft(2, '0')} $bestPeriod';
  }

  /// Normalize time format to consistent "H:MM AM/PM" format
  String _normalizeTimeFormat(String time) {
    String cleaned = time.trim().toUpperCase();
    bool isPM = cleaned.contains('PM');
    bool isAM = cleaned.contains('AM');

    cleaned = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim();

    int hour;
    int minute = 0;

    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      hour = int.tryParse(parts[0].trim()) ?? 0;
      minute = int.tryParse(parts[1].trim()) ?? 0;
    } else {
      hour = int.tryParse(cleaned) ?? 0;
    }

    if (hour < 1) hour = 12;
    if (hour > 12) {
      hour -= 12;
      isPM = true;
      isAM = false;
    }

    String period = isPM ? 'PM' : (isAM ? 'AM' : 'PM');
    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      currentTabIndex: null,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (_hasUnsavedChanges) {
                _showUnsavedChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text('Shift Details',
              style: AppTheme.titleLarge
                  .copyWith(color: AppTheme.adaptiveTextColor)),
          actions: [
            // Pulsing save button (only visible when changes exist)
            if (_hasUnsavedChanges)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.save,
                              color: AppTheme.primaryGreen,
                            ),
                      onPressed: _isSaving ? null : _saveChanges,
                      tooltip: 'Save changes',
                    ),
                  );
                },
              ),
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.navBarIconColor),
              onPressed: () => _editShift(context),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: AppTheme.navBarIconColor),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard and end editing when tapping outside
            FocusScope.of(context).unfocus();
            if (_activeEditField != null) {
              setState(() => _activeEditField = null);
            }
          },
          child: Consumer<FieldOrderProvider>(
            builder: (context, fieldOrderProvider, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Combined Hero Card - Job Info + Earnings + Date (NOT reorderable)
                    _buildCombinedHeroCard(),
                    const SizedBox(height: 20),

                    // Reorderable sections
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        _handleReorder(oldIndex, newIndex,
                            fieldOrderProvider.detailsFieldOrder);
                      },
                      children: _buildOrderedSections(
                          fieldOrderProvider.detailsFieldOrder),
                    ),

                    // Extra bottom padding for scrolling
                    const SizedBox(height: 60),
                  ],
                ),
              );
            },
          ),
        ), // Close GestureDetector
      ), // Close NavigationWrapper child Scaffold
    ); // Close NavigationWrapper
  }

  /// Handle reordering of sections
  void _handleReorder(int oldIndex, int newIndex, List<String> currentOrder) {
    // Adjust indices if needed
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final updatedOrder = List<String>.from(currentOrder);
    final item = updatedOrder.removeAt(oldIndex);
    updatedOrder.insert(newIndex, item);

    // Save the new order
    final fieldOrderProvider =
        Provider.of<FieldOrderProvider>(context, listen: false);
    fieldOrderProvider.updateDetailsFieldOrder(updatedOrder);

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Layout saved'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Build sections in the order specified by field order provider
  List<Widget> _buildOrderedSections(List<String> fieldOrder) {
    final widgets = <Widget>[];

    for (final sectionKey in fieldOrder) {
      switch (sectionKey) {
        case 'earnings_section':
          widgets.add(Padding(
            key: const ValueKey('earnings_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildBreakdownCard(),
          ));
          break;

        case 'event_details_section':
          widgets.add(Padding(
            key: const ValueKey('event_details_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildBEOSection(),
          ));
          break;

        case 'work_details_section':
          widgets.add(Padding(
            key: const ValueKey('work_details_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildWorkDetailsCard(),
          ));
          break;

        case 'time_section':
          widgets.add(Padding(
            key: const ValueKey('time_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildAdditionalEarningsCard(),
          ));
          break;

        case 'documentation_section':
          widgets.add(Padding(
            key: const ValueKey('documentation_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildNotesCard(),
          ));
          break;

        case 'photos_section':
          if (shift.imageUrl != null && shift.imageUrl!.isNotEmpty) {
            widgets.add(Padding(
              key: const ValueKey('photos_section'),
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildPhotosCard(context),
            ));
          }
          break;

        case 'attachments_section':
          widgets.add(Padding(
            key: const ValueKey('attachments_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildAttachmentsCard(),
          ));
          break;

        case 'event_team_section':
          widgets.add(Padding(
            key: const ValueKey('event_team_section'),
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildEventTeamSection(),
          ));
          break;

        case 'checkout_section':
          if (shift.checkoutId != null) {
            widgets.add(Padding(
              key: const ValueKey('checkout_section'),
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildCheckoutSection(),
            ));
          }
          break;
      }
    }

    return widgets;
  }

  Widget _buildCheckoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.receipt_long,
                    color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Linked Checkout',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This shift was created from a scanned server checkout',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.accentOrange, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checkout ID',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shift.checkoutId ?? '',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textPrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: shift.checkoutId ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Checkout ID copied'),
                              backgroundColor: AppTheme.successColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy ID',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTeamSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.groups, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Event Team',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_eventContacts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_eventContacts.length}',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    // Add contact button
                    IconButton(
                      icon:
                          Icon(Icons.person_add, color: AppTheme.primaryGreen),
                      onPressed: _addEventContact,
                      tooltip: 'Add contact',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    // View all contacts
                    IconButton(
                      icon: Icon(Icons.open_in_new, color: AppTheme.textMuted),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventContactsScreen(
                              shiftId: shift.id,
                              shiftEventName: shift.eventName,
                            ),
                          ),
                        ).then((_) => _loadEventContacts());
                      },
                      tooltip: 'View all',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contacts list or empty state
          if (_isLoadingContacts)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_eventContacts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: _addEventContact,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add vendors & staff from this event',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              _eventContacts.length > 3 ? 3 : _eventContacts.length,
              (index) => _buildContactRow(_eventContacts[index]),
            ),

          // "View all" if more than 3 contacts
          if (_eventContacts.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventContactsScreen(
                        shiftId: shift.id,
                        shiftEventName: shift.eventName,
                      ),
                    ),
                  ).then((_) => _loadEventContacts());
                },
                child: Text(
                  'View all ${_eventContacts.length} contacts →',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(EventContact contact) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () => _editContact(contact),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: contact.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          contact.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),

              // Name and role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.displayRole,
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick actions
              if (contact.phone != null && contact.phone!.isNotEmpty)
                IconButton(
                  icon:
                      Icon(Icons.phone, color: AppTheme.primaryGreen, size: 18),
                  onPressed: () => _callContact(contact),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              if (contact.email != null && contact.email!.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.email, color: AppTheme.accentBlue, size: 18),
                  onPressed: () => _emailContact(contact),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addEventContact() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(shiftId: shift.id),
      ),
    );
    if (result == true) {
      _loadEventContacts();
    }
  }

  Future<void> _editContact(EventContact contact) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(contact: contact),
      ),
    );
    if (result == true) {
      _loadEventContacts();
    }
  }

  Future<void> _callContact(EventContact contact) async {
    if (contact.phone == null || contact.phone!.isEmpty) return;
    final uri = Uri.parse('tel:${contact.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailContact(EventContact contact) async {
    if (contact.email == null || contact.email!.isEmpty) return;
    final uri = Uri.parse('mailto:${contact.email}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildCombinedHeroCard() {
    return HeroCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Reduced padding
      borderRadius: AppTheme.radiusLarge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Badge (left side, compact)
          Container(
            width: 56,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(shift.date),
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('d').format(shift.date),
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                Text(
                  shift.date.year == DateTime.now().year
                      ? DateFormat('MMM').format(shift.date)
                      : DateFormat("MMM ''yy").format(shift.date),
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12), // Reduced from 16

          // Right side - Shift info stacked in rows
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Job Name + Dollar Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _jobName ?? 'Shift',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12
                    Text(
                      '\$${effectiveTotalIncome.toStringAsFixed(2)}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),

                // Dynamic rows below - same logic as dashboard
                ...() {
                  final List<Widget> leftItems = [];

                  // Event badge
                  if (shift.eventName?.isNotEmpty == true) {
                    leftItems.add(
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.accentPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  AppTheme.accentPurple.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                size: 12,
                                color: AppTheme.accentPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shift.eventName!,
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.accentPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (shift.guestCount != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${shift.guestCount})',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.accentPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Employer badge
                  if (_employer?.isNotEmpty == true) {
                    leftItems.add(
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.accentBlue.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business,
                                size: 12,
                                color: AppTheme.accentBlue,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _employer!,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.accentBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Linked Checkout badge
                  if (shift.checkoutId != null) {
                    leftItems.add(
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  AppTheme.accentOrange.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 12,
                                color: AppTheme.accentOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Checkout',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.accentOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Hours widget (right side for first row)
                  final hoursWidget = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackgroundLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${shift.hoursWorked.toStringAsFixed(1)}h',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );

                  // Time range widget (right side for second row)
                  Widget? detailWidget;
                  if (shift.startTime != null && shift.endTime != null) {
                    detailWidget = Text(
                      '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    );
                  }

                  // Build rows dynamically
                  final List<Widget> rows = [];

                  if (leftItems.isNotEmpty) {
                    // First row: first left item + hours
                    rows.add(const SizedBox(height: 8));
                    rows.add(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: leftItems[0]),
                          hoursWidget,
                        ],
                      ),
                    );

                    // Second row: second left item (if exists) + time
                    if (leftItems.length > 1) {
                      rows.add(const SizedBox(height: 8));
                      rows.add(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: leftItems[1]),
                            if (detailWidget != null) detailWidget,
                          ],
                        ),
                      );
                    } else if (detailWidget != null) {
                      // Only one left item but we have time - add it on second row
                      rows.add(const SizedBox(height: 8));
                      rows.add(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(),
                            detailWidget,
                          ],
                        ),
                      );
                    }
                  }

                  return rows;
                }(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBEOSection({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Scan BEO button
          Row(
            children: [
              Icon(Icons.assignment, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Event Details/BEO',
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // ✨ Scan BEO Button
              IconButton(
                icon: Icon(Icons.auto_awesome,
                    color: AppTheme.primaryGreen, size: 24),
                onPressed: () {
                  // Navigate to edit screen with auto-open BEO scanner
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddShiftScreen(
                        existingShift: shift,
                        autoOpenBeoScanner: true,
                      ),
                    ),
                  ).then((result) {
                    // Pop back to parent screen if shift was updated
                    // The parent (shift list) will reload automatically
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  });
                },
                tooltip: 'Scan BEO',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.cardBackgroundLight, thickness: 1),
          const SizedBox(height: 20),

          // Event Name (editable, prominent)
          Text('EVENT',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 6),
          _buildEditableText(
            fieldKey: 'eventName',
            value: shift.eventName ?? 'Tap to add event name...',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            placeholder: 'Tap to add event name...',
          ),
          const SizedBox(height: 20),

          // When BEO is linked, show simplified view. Otherwise show full editable fields.
          if (_linkedBeoEvent != null) ...[
            // Simplified view for linked BEO - just show key info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBEODetailRow(
                        'FUNCTION SPACE',
                        _linkedBeoEvent!.functionSpace ??
                            shift.location ??
                            'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildBEODetailRow(
                        'GUESTS',
                        '${_linkedBeoEvent!.displayGuestCount ?? shift.guestCount ?? 0}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBEODetailRow(
                        'TOTAL',
                        '\$${(_linkedBeoEvent!.grandTotal ?? shift.eventCost ?? 0).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildBEODetailRow(
                        'CONTACT',
                        _linkedBeoEvent!.primaryContactName ??
                            shift.hostess ??
                            'N/A',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Full editable fields when no BEO is linked
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditableBEORow(
                        label: 'GUEST COUNT',
                        fieldKey: 'guestCount',
                        value: shift.guestCount?.toString() ?? '',
                        suffix: ' guests',
                        isNumeric: true,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableMultilineRow(
                        label: 'HOSTESS',
                        fieldKey: 'hostess',
                        value: shift.hostess ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildEditableMultilineRow(
                        label: 'LOCATION',
                        fieldKey: 'location',
                        value: shift.location ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildEditableBEORow(
                        label: 'TOTAL SALES',
                        fieldKey: 'eventCost',
                        value: (shift.eventCost ?? 0).toStringAsFixed(2),
                        prefix: '\$',
                        isNumeric: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditableMultilineRow(
                        label: 'CLIENT',
                        fieldKey: 'clientName',
                        value: shift.clientName ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildEditableMultilineRow(
                        label: 'PROJECT',
                        fieldKey: 'projectName',
                        value: shift.projectName ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildEditableBEORow(
                        label: 'COMMISSION',
                        fieldKey: 'commission',
                        value: (shift.commission ?? 0).toStringAsFixed(2),
                        prefix: '\$',
                        isNumeric: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Show linked BEO details if available
          if (_linkedBeoEvent != null || _isLoadingBeo) ...[
            const SizedBox(height: 24),
            Divider(color: AppTheme.cardBackgroundLight, thickness: 1),
            const SizedBox(height: 16),
            _buildExpandableBeoDetails(),
          ],
        ],
      ),
    );
  }

  /// Build the expandable section showing ALL BEO fields
  Widget _buildExpandableBeoDetails() {
    if (_isLoadingBeo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    final beo = _linkedBeoEvent;
    if (beo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expand/Collapse toggle
        InkWell(
          onTap: () => setState(() => _isBeoExpanded = !_isBeoExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isBeoExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.accentPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isBeoExpanded
                      ? 'Hide Full BEO Details'
                      : 'Show Full BEO Details',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SCANNED BEO',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded BEO details
        if (_isBeoExpanded) ...[
          const SizedBox(height: 16),

          // SECTION 1: Event Identity & Contacts
          _buildBeoSectionHeader('EVENT DETAILS/BEO', Icons.event),
          _buildBeoFieldGrid([
            ('Event Type', beo.eventType),
            ('Post As', beo.postAs),
            ('Venue', beo.venueName),
            ('Venue Address', beo.venueAddress),
            ('Function Space', beo.functionSpace),
            ('Account Name', beo.accountName),
          ]),

          const SizedBox(height: 20),
          _buildBeoSectionHeader('CLIENT CONTACT', Icons.person),
          _buildBeoFieldGrid([
            ('Primary Contact', beo.primaryContactName),
            ('Phone', beo.primaryContactPhone),
            ('Email', beo.primaryContactEmail),
          ]),

          const SizedBox(height: 20),
          _buildBeoSectionHeader('INTERNAL CONTACTS', Icons.people),
          _buildBeoFieldGrid([
            ('Sales Manager', beo.salesManagerName),
            ('Sales Phone', beo.salesManagerPhone),
            ('Sales Email', beo.salesManagerEmail),
            ('Catering Manager', beo.cateringManagerName),
            ('Catering Phone', beo.cateringManagerPhone),
          ]),

          // SECTION 2: Timeline & Logistics
          const SizedBox(height: 20),
          _buildBeoSectionHeader('TIMELINE', Icons.schedule),
          _buildBeoFieldGrid([
            (
              'Setup Date',
              beo.setupDate != null
                  ? DateFormat('MMM d, yyyy').format(beo.setupDate!)
                  : null
            ),
            (
              'Teardown Date',
              beo.teardownDate != null
                  ? DateFormat('MMM d, yyyy').format(beo.teardownDate!)
                  : null
            ),
            ('Load-In Time', _formatTimeToAmPm(beo.loadInTime)),
            ('Setup Time', _formatTimeToAmPm(beo.setupTime)),
            ('Guest Arrival', _formatTimeToAmPm(beo.guestArrivalTime)),
            ('Event Start', _formatTimeToAmPm(beo.eventStartTime)),
            ('Event End', _formatTimeToAmPm(beo.eventEndTime)),
            ('Breakdown Time', _formatTimeToAmPm(beo.breakdownTime)),
            ('Load-Out Time', _formatTimeToAmPm(beo.loadOutTime)),
          ]),

          // SECTION 3: Guest Counts
          const SizedBox(height: 20),
          _buildBeoSectionHeader('GUEST COUNTS', Icons.groups),
          _buildBeoFieldGrid([
            ('Expected', beo.guestCountExpected?.toString()),
            ('Confirmed', beo.guestCountConfirmed?.toString()),
            ('Adults', beo.adultCount?.toString()),
            ('Children', beo.childCount?.toString()),
            ('Vendor Meals', beo.vendorMealCount?.toString()),
          ]),

          // SECTION 4: Financials
          const SizedBox(height: 20),
          _buildBeoSectionHeader('FINANCIALS', Icons.attach_money),
          _buildBeoFieldGrid([
            (
              'Food Total',
              beo.foodTotal != null
                  ? '\$${beo.foodTotal!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Beverage Total',
              beo.beverageTotal != null
                  ? '\$${beo.beverageTotal!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Labor Total',
              beo.laborTotal != null
                  ? '\$${beo.laborTotal!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Room Rental',
              beo.roomRental != null
                  ? '\$${beo.roomRental!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Equipment Rental',
              beo.equipmentRental != null
                  ? '\$${beo.equipmentRental!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Subtotal',
              beo.subtotal != null
                  ? '\$${beo.subtotal!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Service Charge %',
              beo.serviceChargePercent != null
                  ? '${beo.serviceChargePercent!.toStringAsFixed(1)}%'
                  : null
            ),
            (
              'Service Charge',
              beo.serviceChargeAmount != null
                  ? '\$${beo.serviceChargeAmount!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Tax %',
              beo.taxPercent != null
                  ? '${beo.taxPercent!.toStringAsFixed(2)}%'
                  : null
            ),
            (
              'Tax Amount',
              beo.taxAmount != null
                  ? '\$${beo.taxAmount!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Gratuity',
              beo.gratuityAmount != null
                  ? '\$${beo.gratuityAmount!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Grand Total',
              beo.grandTotal != null
                  ? '\$${beo.grandTotal!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Deposits Paid',
              beo.depositsPaid != null
                  ? '\$${beo.depositsPaid!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Deposit Amount',
              beo.depositAmount != null
                  ? '\$${beo.depositAmount!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Balance Due',
              beo.balanceDue != null
                  ? '\$${beo.balanceDue!.toStringAsFixed(2)}'
                  : null
            ),
            (
              'Commission %',
              beo.commissionPercentage != null
                  ? '${beo.commissionPercentage!.toStringAsFixed(1)}%'
                  : null
            ),
            (
              'Commission',
              beo.commissionAmount != null
                  ? '\$${beo.commissionAmount!.toStringAsFixed(2)}'
                  : null
            ),
          ]),

          // SECTION 5: Food & Beverage
          const SizedBox(height: 20),
          _buildBeoSectionHeader('FOOD & BEVERAGE', Icons.restaurant),
          _buildBeoFieldGrid([
            ('Menu Style', beo.menuStyle),
          ]),

          // Display detailed menu breakdown if available
          if (beo.menuDetails != null && beo.menuDetails!.isNotEmpty) ...[
            _buildMenuDetailsWidget(beo.menuDetails!),
          ] else if (beo.menuItems != null) ...[
            _buildBeoFieldGrid([('Menu Items', beo.menuItems)]),
          ],

          _buildBeoFieldGrid([
            ('Dietary Restrictions', beo.dietaryRestrictions),
          ]),

          // Beverages
          if (beo.beverageDetails != null &&
              beo.beverageDetails!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildBeverageDetailsWidget(beo.beverageDetails!),
          ],

          // SECTION 6: Setup & Decor
          if (beo.decorNotes != null ||
              beo.floorPlanNotes != null ||
              beo.setupDetails != null) ...[
            const SizedBox(height: 20),
            _buildBeoSectionHeader('SETUP & DECOR', Icons.design_services),
            if (beo.setupDetails != null && beo.setupDetails!.isNotEmpty)
              _buildSetupDetailsWidget(beo.setupDetails!),
            _buildBeoFieldGrid([
              ('Decor Notes', beo.decorNotes),
              ('Floor Plan', beo.floorPlanNotes),
            ]),
          ],

          // SECTION 7: Staffing
          if (beo.staffingRequirements != null) ...[
            const SizedBox(height: 20),
            _buildBeoSectionHeader('STAFFING', Icons.badge),
            _buildBeoFieldGrid([
              ('Requirements', beo.staffingRequirements),
            ]),
          ],

          // SECTION 9: Billing & Legal
          const SizedBox(height: 20),
          _buildBeoSectionHeader('BILLING & LEGAL', Icons.gavel),
          _buildBeoFieldGrid([
            ('Payment Method', beo.paymentMethod),
            ('Cancellation Policy', beo.cancellationPolicy),
            (
              'Client Signed',
              beo.clientSignatureDate != null
                  ? DateFormat('MMM d, yyyy').format(beo.clientSignatureDate!)
                  : null
            ),
            (
              'Venue Signed',
              beo.venueSignatureDate != null
                  ? DateFormat('MMM d, yyyy').format(beo.venueSignatureDate!)
                  : null
            ),
          ]),

          // SECTION 10: Notes
          if (beo.specialRequests != null || beo.formattedNotes != null) ...[
            const SizedBox(height: 20),
            _buildBeoSectionHeader('NOTES', Icons.notes),
            if (beo.specialRequests != null) ...[
              _buildBeoNoteField('Special Requests', beo.specialRequests!),
            ],
            if (beo.formattedNotes != null) ...[
              const SizedBox(height: 12),
              _buildBeoNoteField('Additional Notes', beo.formattedNotes!),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildBeoSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Format military time to AM/PM
  String _formatTimeToAmPm(String? time) {
    if (time == null || time.isEmpty) return '';
    final timeStr = time; // Capture non-null for use in catch
    try {
      if (timeStr.toUpperCase().contains('AM') ||
          timeStr.toUpperCase().contains('PM')) {
        return timeStr;
      }
      final parts = timeStr.split(':');
      if (parts.isEmpty) return timeStr;
      var hour = int.parse(parts[0]);
      final minute = parts.length > 1
          ? parts[1]
              .replaceAll(RegExp(r'[^0-9]'), '')
              .padRight(2, '0')
              .substring(0, 2)
          : '00';
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (e) {
      return timeStr;
    }
  }

  /// Check if text is a disclaimer/boilerplate
  bool _isDisclaimer(String? text) {
    if (text == null || text.isEmpty) return false;
    final lowerText = text.toLowerCase();
    final disclaimerPatterns = [
      'we\'re happy to accommodate',
      'prior to signing',
      'please specify',
      'certificate of liability',
      'certificate of insurance',
      'non-refundable deposit',
      'deposit is deducted',
      'final bill',
      'must be received',
      'cancellation policy',
      'terms and conditions',
      'subject to',
      '% of the estimated',
      'signed contract',
    ];
    for (final pattern in disclaimerPatterns) {
      if (lowerText.contains(pattern)) return true;
    }
    return false;
  }

  Widget _buildBeoFieldGrid(List<(String, String?)> fields) {
    // Filter out null, empty values, and disclaimers
    final nonEmptyFields = fields
        .where((f) => f.$2 != null && f.$2!.isNotEmpty && !_isDisclaimer(f.$2))
        .toList();

    if (nonEmptyFields.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 26),
        child: Text(
          'No data available',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: nonEmptyFields
            .map((field) => SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.$1,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        field.$2!,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBeoNoteField(String label, String value) {
    // Skip disclaimers
    if (_isDisclaimer(value)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Build menu details widget from JSON
  Widget _buildMenuDetailsWidget(Map<String, dynamic> menuDetails) {
    final widgets = <Widget>[];

    void addMenuSection(String label, String key) {
      if (menuDetails[key] != null && (menuDetails[key] as List).isNotEmpty) {
        final items = (menuDetails[key] as List)
            .map((a) => a['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '• $item',
                          style: AppTheme.bodyMedium,
                        ),
                      )),
                ],
              ),
            ),
          );
        }
      }
    }

    addMenuSection('Appetizers', 'appetizers');
    addMenuSection('Salads', 'salads');
    addMenuSection('Entrees', 'entrees');
    addMenuSection('Sides', 'sides');
    addMenuSection('Desserts', 'desserts');
    addMenuSection('Passed Items', 'passed_items');

    return Column(children: widgets);
  }

  /// Build beverage details widget from JSON
  Widget _buildBeverageDetailsWidget(Map<String, dynamic> beverageDetails) {
    final fields = <(String, String?)>[
      ('Package', beverageDetails['package']?.toString()),
      ('Bar Type', beverageDetails['bar_type']?.toString()),
      (
        'Per Person',
        beverageDetails['price_per_person'] != null
            ? '\$${beverageDetails['price_per_person']}'
            : null
      ),
      ('Brands', beverageDetails['brands']?.toString()),
    ];

    return _buildBeoFieldGrid(fields);
  }

  /// Build setup details widget from JSON
  Widget _buildSetupDetailsWidget(Map<String, dynamic> setupDetails) {
    final fields = <(String, String?)>[];

    // Tables
    if (setupDetails['tables'] != null &&
        (setupDetails['tables'] as List).isNotEmpty) {
      final tables = (setupDetails['tables'] as List)
          .map((t) =>
              '${t['qty']} ${t['type']}${t['linen_color'] != null ? ' (${t['linen_color']})' : ''}')
          .join(', ');
      if (tables.isNotEmpty) fields.add(('Tables', tables));
    }

    // Linens
    if (setupDetails['linens'] != null && setupDetails['linens'] is Map) {
      final linens = setupDetails['linens'] as Map;
      final linenList = <String>[];
      if (linens['tablecloths'] != null)
        linenList.add('Tablecloths: ${linens['tablecloths']}');
      if (linens['napkins'] != null)
        linenList.add('Napkins: ${linens['napkins']}');
      if (linenList.isNotEmpty) fields.add(('Linens', linenList.join(', ')));
    }

    // Chairs
    if (setupDetails['chairs'] != null && setupDetails['chairs'] is Map) {
      final chairs = setupDetails['chairs'] as Map;
      fields.add(('Chairs', '${chairs['qty']} ${chairs['type']}'));
    }

    // Decor
    if (setupDetails['decor'] != null &&
        (setupDetails['decor'] as List).isNotEmpty) {
      fields.add(('Decor Items', (setupDetails['decor'] as List).join(', ')));
    }

    // AV Equipment
    if (setupDetails['av_equipment'] != null &&
        (setupDetails['av_equipment'] as List).isNotEmpty) {
      fields.add(
          ('AV Equipment', (setupDetails['av_equipment'] as List).join(', ')));
    }

    // Special Items
    if (setupDetails['special_items'] != null &&
        (setupDetails['special_items'] as List).isNotEmpty) {
      fields.add((
        'Special Items',
        (setupDetails['special_items'] as List).join(', ')
      ));
    }

    return _buildBeoFieldGrid(fields);
  }

  Widget _buildBEODetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // TRUE inline editing - looks exactly the same, just with a cursor when tapped
  Widget _buildEditableBEORow({
    required String label,
    required String fieldKey,
    required String value,
    String? prefix,
    String? suffix,
    bool isNumeric = false,
  }) {
    final isEditing = _activeEditField == fieldKey;
    final controller = _controllers[fieldKey];
    final focusNode = _focusNodes[fieldKey];

    if (controller == null || focusNode == null) {
      return _buildBEODetailRow(label, '${prefix ?? ''}$value${suffix ?? ''}');
    }

    final baseStyle = AppTheme.bodyLarge.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    final displayValue =
        value.isEmpty ? 'Tap to add' : '${prefix ?? ''}$value${suffix ?? ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() => _activeEditField = fieldKey);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusNode.requestFocus();
            });
          },
          child: isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefix != null) Text(prefix, style: baseStyle),
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: isNumeric
                            ? const TextInputType.numberWithOptions(
                                decimal: true)
                            : TextInputType.text,
                        inputFormatters: isNumeric
                            ? [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'))
                              ]
                            : null,
                        style: baseStyle,
                        cursorColor: AppTheme.primaryGreen,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                        onTapOutside: (_) => _onFieldEditComplete(fieldKey),
                      ),
                    ),
                    if (suffix != null) Text(suffix, style: baseStyle),
                  ],
                )
              : Text(
                  displayValue,
                  style: value.isEmpty
                      ? baseStyle.copyWith(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)
                      : baseStyle,
                ),
        ),
      ],
    );
  }

  // TRUE inline editing for text (like event name) - no visual change, just cursor when tapped
  Widget _buildEditableText({
    required String fieldKey,
    required String value,
    required TextStyle style,
    String? placeholder,
  }) {
    final isEditing = _activeEditField == fieldKey;
    final controller = _controllers[fieldKey];
    final focusNode = _focusNodes[fieldKey];

    if (controller == null || focusNode == null) {
      return Text(value, style: style);
    }

    final displayText = controller.text.isEmpty
        ? (placeholder ?? 'Tap to add...')
        : controller.text;

    return GestureDetector(
      onTap: () {
        setState(() => _activeEditField = fieldKey);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      },
      child: isEditing
          ? IntrinsicWidth(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: style,
                cursorColor: AppTheme.primaryGreen,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                onTapOutside: (_) => _onFieldEditComplete(fieldKey),
              ),
            )
          : Text(
              displayText,
              style: controller.text.isEmpty
                  ? style.copyWith(
                      color: AppTheme.textMuted, fontStyle: FontStyle.italic)
                  : style,
            ),
    );
  }

  // Editable multi-line row - for hostess and other fields that may wrap
  Widget _buildEditableMultilineRow({
    required String label,
    required String fieldKey,
    required String value,
  }) {
    final isEditing = _activeEditField == fieldKey;
    final controller = _controllers[fieldKey];
    final focusNode = _focusNodes[fieldKey];

    if (controller == null || focusNode == null) {
      return _buildBEODetailRow(label, value);
    }

    final baseStyle = AppTheme.bodyLarge.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    final displayText =
        controller.text.isEmpty ? 'Tap to add' : controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() => _activeEditField = fieldKey);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusNode.requestFocus();
            });
          },
          child: isEditing
              ? TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null, // Allow multi-line
                  style: baseStyle,
                  cursorColor: AppTheme.primaryGreen,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTapOutside: (_) => _onFieldEditComplete(fieldKey),
                )
              : Text(
                  displayText,
                  style: controller.text.isEmpty
                      ? baseStyle.copyWith(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)
                      : baseStyle,
                ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Income Breakdown', style: AppTheme.titleMedium),
          const SizedBox(height: 16),
          // Work Time (Start - End)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(Icons.access_time,
                    color: AppTheme.accentPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Work Time', style: AppTheme.bodyMedium)),
              Text(
                '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                style: AppTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hours Worked
          _buildBreakdownRow(
            'Hours Worked',
            _calculatedHours,
            Icons.schedule,
            AppTheme.accentYellow,
            suffix: ' hrs',
          ),
          const SizedBox(height: 12),
          // Hourly Rate
          _buildEditableBreakdownRow(
            label: 'Hourly Rate',
            fieldKey: 'hourlyRate',
            icon: Icons.attach_money,
            color: AppTheme.accentOrange,
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.cardBackgroundLight),
          const SizedBox(height: 16),
          _buildEditableBreakdownRow(
            label: 'Cash Tips',
            fieldKey: 'cashTips',
            icon: Icons.payments,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          _buildEditableBreakdownRow(
            label: 'Credit Tips',
            fieldKey: 'creditTips',
            icon: Icons.credit_card,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.cardBackgroundLight),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Tips', style: AppTheme.bodyLarge),
              Text(
                '\$${shift.totalTips.toStringAsFixed(2)}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final bool isCurrency = suffix == null;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTheme.bodyMedium)),
        Text(
          isCurrency
              ? '\$${amount.toStringAsFixed(2)}'
              : '${amount.toStringAsFixed(1)}$suffix',
          style: AppTheme.titleMedium,
        ),
      ],
    );
  }

  // TRUE inline editable breakdown row - shows as Text, becomes TextField only when tapped
  Widget _buildEditableBreakdownRow({
    required String label,
    required String fieldKey,
    required IconData icon,
    required Color color,
    String? suffix,
    bool isCurrency = true,
  }) {
    final isEditing = _activeEditField == fieldKey;
    final controller = _controllers[fieldKey];
    final focusNode = _focusNodes[fieldKey];

    if (controller == null || focusNode == null) {
      return _buildBreakdownRow(label, 0, icon, color);
    }

    final displayValue = controller.text.isEmpty ? '0.00' : controller.text;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTheme.bodyMedium)),
        GestureDetector(
          onTap: () {
            setState(() => _activeEditField = fieldKey);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusNode.requestFocus();
            });
          },
          child: isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrency) Text('\$', style: AppTheme.titleMedium),
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        textAlign: TextAlign.right,
                        style: AppTheme.titleMedium,
                        cursorColor: AppTheme.primaryGreen,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                        onTapOutside: (_) => _onFieldEditComplete(fieldKey),
                      ),
                    ),
                    if (suffix != null)
                      Text(suffix, style: AppTheme.titleMedium),
                  ],
                )
              : Text(
                  '${isCurrency ? '\$' : ''}$displayValue${suffix ?? ''}',
                  style: AppTheme.titleMedium,
                ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    final isEditing = _activeEditField == 'notes';
    final controller = _controllers['notes']!;
    final focusNode = _focusNodes['notes']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text('Notes', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _activeEditField = 'notes');
              focusNode.requestFocus();
            },
            child: isEditing
                ? TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: null,
                    minLines: 3,
                    style: AppTheme.bodyMedium.copyWith(
                      height: 1.5,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Add notes...',
                    ),
                    onTapOutside: (_) => _onFieldEditComplete('notes'),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      shift.notes?.isNotEmpty == true
                          ? shift.notes!
                          : 'Tap to add notes...',
                      style: AppTheme.bodyMedium.copyWith(
                        height: 1.5,
                        color: shift.notes?.isNotEmpty == true
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        fontStyle: shift.notes?.isNotEmpty == true
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard(BuildContext context) {
    // Parse photo paths (comma-separated string)
    final photoPaths =
        shift.imageUrl!.split(',').where((p) => p.trim().isNotEmpty).toList();

    // Use FutureBuilder to batch-load all signed URLs like gallery images
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: AppTheme.accentPurple, size: 20),
              const SizedBox(width: 8),
              Text('Photos', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Batch-load all signed URLs at once
          FutureBuilder<List<Map<String, String>>>(
            future: _batchLoadSignedUrls(photoPaths),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading photos: ${snapshot.error}'),
                );
              }

              final photoUrls = snapshot.data ?? [];

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: photoUrls
                    .map((photoData) =>
                        _buildInstantPhotoThumbnail(context, photoData))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Batch-load signed URLs for all photos at once (like gallery images)
  Future<List<Map<String, String>>> _batchLoadSignedUrls(
      List<String> photoPaths) async {
    return await Future.wait(photoPaths.map((path) async {
      try {
        // Use existing bucket that actually exists
        const bucketName = 'shift-attachments';

        final db = DatabaseService();
        final signedUrl = await db.getPhotoUrlForBucket(bucketName, path);

        return {
          'originalPath': path,
          'signedUrl': signedUrl,
        };
      } catch (e) {
        print('Error loading signed URL for $path: $e');
        return {
          'originalPath': path,
          'signedUrl': '', // Empty indicates error
        };
      }
    }));
  }

  /// Build thumbnail using pre-loaded signed URL (instant display)
  Widget _buildInstantPhotoThumbnail(
      BuildContext context, Map<String, String> photoData) {
    final originalPath = photoData['originalPath']!;
    final signedUrl = photoData['signedUrl']!;

    return GestureDetector(
      onTap: () => _viewFullImage(context, originalPath),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.cardBackgroundLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: signedUrl.isNotEmpty
            ? Image.network(
                signedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppTheme.textMuted,
                      size: 40,
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  Icons.broken_image,
                  color: AppTheme.textMuted,
                  size: 40,
                ),
              ),
      ),
    );
  }

  void _viewFullImage(BuildContext context, String path) {
    final isUrl = path.startsWith('http://') || path.startsWith('https://');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isUrl
                ? Image.network(
                    path,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.error,
                                color: AppTheme.accentRed, size: 48),
                            const SizedBox(height: 8),
                            Text('Failed to load image',
                                style: AppTheme.bodyMedium),
                          ],
                        ),
                      );
                    },
                  )
                : Image.file(File(path)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text('Work Details', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditableInfoRow('Location', 'location'),
          const SizedBox(height: 12),
          _buildEditableInfoRow('Client', 'clientName'),
          const SizedBox(height: 12),
          _buildEditableInfoRow('Project', 'projectName'),
          const SizedBox(height: 12),
          _buildEditableBEORow(
            label: 'MILEAGE',
            fieldKey: 'mileage',
            value: shift.mileage?.toStringAsFixed(1) ?? '',
            suffix: ' miles',
            isNumeric: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text('Additional Earnings', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditableBreakdownRow(
            label: 'Commission',
            fieldKey: 'commission',
            icon: Icons.trending_up,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          _buildEditableBreakdownRow(
            label: 'Flat Rate',
            fieldKey: 'flatRate',
            icon: Icons.payments,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 12),
          _buildEditableBreakdownRow(
            label: 'Overtime Hours',
            fieldKey: 'overtimeHours',
            icon: Icons.access_time_filled,
            color: AppTheme.accentYellow,
            suffix: ' hrs',
            isCurrency: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        Text(value, style: AppTheme.bodyLarge),
      ],
    );
  }

  // TRUE inline editable info row (for work details like location, client, etc.)
  Widget _buildEditableInfoRow(String label, String fieldKey) {
    final isEditing = _activeEditField == fieldKey;
    final controller = _controllers[fieldKey];
    final focusNode = _focusNodes[fieldKey];

    if (controller == null || focusNode == null) {
      return _buildInfoRow(label, '');
    }

    final displayText =
        controller.text.isEmpty ? 'Tap to add' : controller.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            setState(() => _activeEditField = fieldKey);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusNode.requestFocus();
            });
          },
          child: isEditing
              ? IntrinsicWidth(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textAlign: TextAlign.right,
                    style: AppTheme.bodyLarge,
                    cursorColor: AppTheme.primaryGreen,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                    onTapOutside: (_) => _onFieldEditComplete(fieldKey),
                  ),
                )
              : Text(
                  displayText,
                  style: controller.text.isEmpty
                      ? AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)
                      : AppTheme.bodyLarge,
                ),
        ),
      ],
    );
  }

  void _editShift(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddShiftScreen(existingShift: shift),
      ),
    );

    // If edit was successful, refresh the shift data
    if (result == true && context.mounted) {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      await shiftProvider.loadShifts();
      // Pop back to refresh the previous screen
      Navigator.pop(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Shift?', style: AppTheme.titleLarge),
        content: Text(
          'This action cannot be undone. Are you sure?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await _deleteShift(
                  context); // Pass the screen context, not dialog context
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShift(BuildContext context) async {
    try {
      final provider = Provider.of<ShiftProvider>(context, listen: false);
      await provider.deleteShift(shift.id);

      if (context.mounted) {
        // Navigate back to previous screen (calendar)
        Navigator.of(context).pop();

        // Show confirmation after navigating back
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Shift deleted'),
                backgroundColor: AppTheme.accentRed,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildAttachmentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_file, color: AppTheme.accentBlue, size: 20),
                  const SizedBox(width: 8),
                  Text('Attachments', style: AppTheme.titleMedium),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_attachments.length}',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSelectingAttachments) ...[
                    IconButton(
                      icon: Icon(Icons.share,
                          color: AppTheme.primaryGreen, size: 18),
                      onPressed: _selectedAttachmentIds.isEmpty
                          ? null
                          : _shareSelectedAttachments,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: AppTheme.dangerColor, size: 18),
                      onPressed: _selectedAttachmentIds.isEmpty
                          ? null
                          : _deleteSelectedAttachments,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: AppTheme.textSecondary, size: 18),
                      onPressed: _cancelAttachmentSelection,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ] else ...[
                    if (_attachments.isNotEmpty)
                      IconButton(
                        icon: Icon(
                            _attachmentViewIsGrid
                                ? Icons.view_list
                                : Icons.grid_view,
                            color: AppTheme.textSecondary,
                            size: 18),
                        onPressed: _toggleAttachmentView,
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    IconButton(
                      icon: _isUploadingAttachment
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppTheme.primaryGreen)))
                          : Icon(Icons.add,
                              color: AppTheme.primaryGreen, size: 18),
                      onPressed:
                          _isUploadingAttachment ? null : _pickAndUploadFile,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAttachments)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                ),
              ),
            )
          else if (_attachments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.folder_open,
                        color: AppTheme.textMuted, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No attachments yet',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to attach PDFs, docs, Excel files, etc.',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            _attachmentViewIsGrid
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = _attachments[index];
                      final isSelected =
                          _selectedAttachmentIds.contains(attachment.id);
                      return GestureDetector(
                        onTap: _isSelectingAttachments
                            ? () => _toggleAttachmentSelection(attachment.id)
                            : null,
                        onLongPress: () {
                          if (!_isSelectingAttachments) {
                            _startAttachmentSelection(attachment.id);
                          }
                        },
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: _isSelectingAttachments,
                              child: Opacity(
                                opacity: isSelected ? 0.6 : 1.0,
                                child: DocumentPreviewWidget(
                                  attachment: attachment,
                                  showFileName: true,
                                  showFileSize: true,
                                  height: 150,
                                  cachedUrl: _attachmentUrlCache[attachment.id],
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 24),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final attachment = _attachments[index];
                      final isSelected =
                          _selectedAttachmentIds.contains(attachment.id);
                      return GestureDetector(
                        onTap: () {
                          if (_isSelectingAttachments) {
                            _toggleAttachmentSelection(attachment.id);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectingAttachments) {
                            _startAttachmentSelection(attachment.id);
                          }
                        },
                        child: Container(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                              : null,
                          child: Row(
                            children: [
                              if (_isSelectingAttachments)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, right: 8),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              SizedBox(
                                width: 100,
                                height: 80,
                                child: DocumentPreviewWidget(
                                  attachment: attachment,
                                  showFileName: false,
                                  showFileSize: false,
                                  cachedUrl: _attachmentUrlCache[attachment.id],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment.fileName,
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${attachment.extension.toUpperCase()} • ${attachment.formattedSize}',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Attachment actions menu - hide in selection mode
                              if (!_isSelectingAttachments)
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color: AppTheme.textSecondary, size: 20),
                                  color: AppTheme.cardBackground,
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'open':
                                        _openAttachment(attachment);
                                        break;
                                      case 'share':
                                        _shareAttachment(attachment);
                                        break;
                                      case 'delete':
                                        _deleteAttachment(attachment);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'open',
                                      child: Row(
                                        children: [
                                          Icon(Icons.open_in_new,
                                              color: AppTheme.textPrimary,
                                              size: 18),
                                          const SizedBox(width: 12),
                                          Text('Open in App',
                                              style: AppTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          Icon(Icons.share,
                                              color: AppTheme.textPrimary,
                                              size: 18),
                                          const SizedBox(width: 12),
                                          Text('Share',
                                              style: AppTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: AppTheme.dangerColor,
                                              size: 18),
                                          const SizedBox(width: 12),
                                          Text('Delete',
                                              style: AppTheme.bodyMedium
                                                  .copyWith(
                                                      color: AppTheme
                                                          .dangerColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ],
      ),
    );
  }
}
