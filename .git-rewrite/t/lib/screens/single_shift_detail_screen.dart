import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shift.dart';
import '../models/event_contact.dart';
import '../models/shift_attachment.dart';
import '../providers/shift_provider.dart';
import '../screens/add_shift_screen.dart';
import '../screens/event_contacts_screen.dart';
import '../screens/add_edit_contact_screen.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/navigation_wrapper.dart';
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
                const Text('Changes saved'),
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
      // Download file to temp directory
      final bytes = await _db.downloadAttachment(attachment.filePath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${attachment.fileName}');
      await tempFile.writeAsBytes(bytes);

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Shift Attachment - ${attachment.fileName}',
      );
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
              icon: const Icon(Icons.edit),
              onPressed: () => _editShift(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Combined Hero Card - Job Info + Earnings + Date
                _buildCombinedHeroCard(),
                const SizedBox(height: 20),

                // BEO-Style Event Contract Section
                _buildBEOSection(),
                const SizedBox(height: 20),

                // Income Breakdown
                _buildBreakdownCard(),
                const SizedBox(height: 20),

                // Photos (if any)
                if (shift.imageUrl != null && shift.imageUrl!.isNotEmpty) ...[
                  _buildPhotosCard(context),
                  const SizedBox(height: 20),
                ],

                // Work Details - Always show for inline editing
                _buildWorkDetailsCard(),
                const SizedBox(height: 20),

                // Additional Earnings - Always show for inline editing
                _buildAdditionalEarningsCard(),
                const SizedBox(height: 20),

                // Notes - Always show for inline editing
                _buildNotesCard(),
                const SizedBox(height: 20),

                // File Attachments
                _buildAttachmentsCard(),
                const SizedBox(height: 20),

                // Event Team (Contacts)
                _buildEventTeamSection(),
                const SizedBox(height: 20),

                // Extra bottom padding for scrolling
                const SizedBox(height: 60),
              ],
            ),
          ),
        ), // Close GestureDetector
      ), // Close NavigationWrapper child Scaffold
    ); // Close NavigationWrapper
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
                          color: AppTheme.primaryGreen.withOpacity(0.2),
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
                      color: AppTheme.primaryGreen.withOpacity(0.3),
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
                  color: AppTheme.primaryGreen.withOpacity(0.15),
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
    final baseEarnings = effectiveHourlyRate * shift.hoursWorked;
    final totalTips = shift.cashTips + shift.creditTips;

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
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(shift.date).toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('d').format(shift.date),
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                Text(
                  DateFormat('y').format(shift.date),
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.primaryGreen,
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
                            color: AppTheme.accentPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.accentPurple.withOpacity(0.3),
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
                            color: AppTheme.accentBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.accentBlue.withOpacity(0.3),
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

                  // Hours widget (right side for first row)
                  final hoursWidget = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
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
                      '${shift.startTime} - ${shift.endTime}',
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

  Widget _buildHeroStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsHeroCard() {
    return HeroCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: AppTheme.radiusLarge,
      child: Column(
        children: [
          Text(
            'Total Earnings',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${effectiveTotalIncome.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBEOSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.assignment, color: AppTheme.accentYellow, size: 24),
              const SizedBox(width: 12),
              Text(
                'Event Contract',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
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

          // Two-column layout for details
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
                    // Editable Time section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIME',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildEditableTimeField(
                          fieldKey: 'startTime',
                          value: shift.startTime ?? '',
                        ),
                        Text(
                          'to',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        _buildEditableTimeField(
                          fieldKey: 'endTime',
                          value: shift.endTime ?? '',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Hours - calculated from time, NOT editable
                    _buildBEODetailRow(
                        'HOURS', '${_calculatedHours.toStringAsFixed(1)} hrs'),
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
                      label: 'HOSTESS',
                      fieldKey: 'hostess',
                      value: shift.hostess ?? '',
                    ),
                    const SizedBox(height: 16),
                    _buildEditableBEORow(
                      label: 'RATE',
                      fieldKey: 'hourlyRate',
                      value: effectiveHourlyRate.toStringAsFixed(2),
                      prefix: '\$',
                      suffix: '/hr',
                      isNumeric: true,
                    ),
                    const SizedBox(height: 16),
                    // Editable tips (cash + credit combined for display, but we edit them separately)
                    _buildEditableTipsRow(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  // Editable time field - shows formatted time, allows direct text entry
  Widget _buildEditableTimeField({
    required String fieldKey,
    required String value,
  }) {
    final isEditing = _activeEditField == fieldKey;
    final controller = _controllers[fieldKey];
    final focusNode = _focusNodes[fieldKey];

    if (controller == null || focusNode == null) {
      return Text(
        _formatTime(value),
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      );
    }

    final baseStyle = AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600);
    final displayText =
        controller.text.isEmpty ? 'Tap to add' : _formatTime(controller.text);

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
                style: baseStyle,
                cursorColor: AppTheme.primaryGreen,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '3:00 PM',
                  hintStyle: baseStyle.copyWith(
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                onTapOutside: (_) => _onFieldEditComplete(fieldKey),
              ),
            )
          : Text(
              displayText,
              style: controller.text.isEmpty
                  ? baseStyle.copyWith(
                      color: AppTheme.textMuted, fontStyle: FontStyle.italic)
                  : baseStyle,
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

  // Editable tips row - shows total, taps to edit cash/credit separately
  Widget _buildEditableTipsRow() {
    final isEditingCash = _activeEditField == 'cashTips';
    final isEditingCredit = _activeEditField == 'creditTips';
    final isEditing = isEditingCash || isEditingCredit;

    final cashController = _controllers['cashTips'];
    final creditController = _controllers['creditTips'];
    final cashFocusNode = _focusNodes['cashTips'];
    final creditFocusNode = _focusNodes['creditTips'];

    final baseStyle = AppTheme.bodyLarge.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    final totalTips = shift.cashTips + shift.creditTips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPS',
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        if (!isEditing)
          GestureDetector(
            onTap: () {
              setState(() => _activeEditField = 'cashTips');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                cashFocusNode?.requestFocus();
              });
            },
            child: Text(
              '\$${totalTips.toStringAsFixed(2)}',
              style: baseStyle,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cash tips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cash: \$', style: baseStyle.copyWith(fontSize: 14)),
                  IntrinsicWidth(
                    child: TextField(
                      controller: cashController,
                      focusNode: cashFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: baseStyle.copyWith(fontSize: 14),
                      cursorColor: AppTheme.primaryGreen,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) {
                        setState(() => _activeEditField = 'creditTips');
                        creditFocusNode?.requestFocus();
                      },
                      onTapOutside: (_) => _onFieldEditComplete('cashTips'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Credit tips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Credit: \$', style: baseStyle.copyWith(fontSize: 14)),
                  IntrinsicWidth(
                    child: TextField(
                      controller: creditController,
                      focusNode: creditFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: baseStyle.copyWith(fontSize: 14),
                      cursorColor: AppTheme.primaryGreen,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _onFieldEditComplete('creditTips'),
                      onTapOutside: (_) => _onFieldEditComplete('creditTips'),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.greenGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.black, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(shift.date),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('MMMM d, y').format(shift.date),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        children: [
          Text(
            'Total Earnings',
            style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${effectiveTotalIncome.toStringAsFixed(2)}',
            style: AppTheme.headlineLarge.copyWith(
              color: AppTheme.primaryGreen,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
          _buildEditableBreakdownRow(
            label: 'Cash Tips',
            fieldKey: 'cashTips',
            icon: Icons.attach_money,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          _buildEditableBreakdownRow(
            label: 'Credit Tips',
            fieldKey: 'creditTips',
            icon: Icons.credit_card,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 12),
          // Hours - NOT editable, calculated from time fields above
          _buildBreakdownRow(
            'Hours Worked',
            _calculatedHours,
            Icons.schedule,
            AppTheme.accentYellow,
            suffix: ' hrs',
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
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTheme.bodyMedium)),
        Text(
          isCurrency
              ? '\$${amount.toStringAsFixed(2)}'
              : '${amount.toStringAsFixed(1)}${suffix ?? ''}',
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
            color: color.withOpacity(0.15),
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

  Widget _buildHoursCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.access_time,
              color: AppTheme.accentPurple,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hours Worked', style: AppTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  '${shift.hoursWorked.toStringAsFixed(1)} hrs',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.accentPurple,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rate', style: AppTheme.labelSmall),
              Text(
                '\$${effectiveHourlyRate.toStringAsFixed(2)}/hr',
                style: AppTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photoPaths
                .map((path) => GestureDetector(
                      onTap: () => _viewFullImage(context, path),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(path)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsCard() {
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
              Icon(Icons.celebration, color: AppTheme.accentYellow, size: 20),
              const SizedBox(width: 8),
              Text('Event Details', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (shift.eventName != null) ...[
            _buildInfoRow('Event Name', shift.eventName!),
            const SizedBox(height: 12),
          ],
          if (shift.hostess != null) ...[
            _buildInfoRow('Hostess', shift.hostess!),
            const SizedBox(height: 12),
          ],
          if (shift.guestCount != null)
            _buildInfoRow('Guest Count', '${shift.guestCount} guests'),
        ],
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
                        color: AppTheme.accentBlue.withOpacity(0.2),
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
              IconButton(
                icon: _isUploadingAttachment
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.primaryGreen),
                        ),
                      )
                    : Icon(Icons.add, color: AppTheme.primaryGreen),
                onPressed: _isUploadingAttachment ? null : _pickAndUploadFile,
                tooltip: 'Add Attachment',
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                return _buildAttachmentTile(attachment);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(ShiftAttachment attachment) {
    IconData fileIcon;
    Color iconColor;

    // Determine icon and color based on file type
    if (attachment.isPdf) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = AppTheme.accentRed;
    } else if (attachment.isImage) {
      fileIcon = Icons.image;
      iconColor = AppTheme.accentPurple;
    } else if (attachment.isVideo) {
      fileIcon = Icons.videocam;
      iconColor = AppTheme.accentOrange;
    } else if (attachment.isDocument) {
      fileIcon = Icons.description;
      iconColor = AppTheme.accentBlue;
    } else if (attachment.isSpreadsheet) {
      fileIcon = Icons.table_chart;
      iconColor = AppTheme.primaryGreen;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = AppTheme.textMuted;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAttachment(attachment),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // File icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              // File info
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
                    const SizedBox(height: 2),
                    Text(
                      '${attachment.extension.toUpperCase()} • ${attachment.formattedSize}',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textMuted),
                color: AppTheme.cardBackgroundLight,
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
                            color: AppTheme.textPrimary, size: 18),
                        const SizedBox(width: 12),
                        Text('Open', style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share,
                            color: AppTheme.textPrimary, size: 18),
                        const SizedBox(width: 12),
                        Text('Share', style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            color: AppTheme.dangerColor, size: 18),
                        const SizedBox(width: 12),
                        Text('Delete',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.dangerColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
