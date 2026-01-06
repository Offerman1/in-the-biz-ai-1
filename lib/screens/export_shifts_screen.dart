import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shift.dart';
import '../models/job.dart';
import '../providers/shift_provider.dart';
import '../services/database_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/google_calendar_service.dart';
import '../theme/app_theme.dart';

class ExportShiftsScreen extends StatefulWidget {
  final bool isRemoveMode; // true = remove synced, false = export unsynced

  const ExportShiftsScreen({
    super.key,
    this.isRemoveMode = false,
  });

  @override
  State<ExportShiftsScreen> createState() => _ExportShiftsScreenState();
}

class _ExportShiftsScreenState extends State<ExportShiftsScreen> {
  final DatabaseService _db = DatabaseService();
  final CalendarSyncService _calendarSync = CalendarSyncService();
  final GoogleCalendarService _googleCalendar = GoogleCalendarService();
  final _currencyFormat = NumberFormat.simpleCurrency();

  List<Shift> _shifts = [];
  List<Job> _jobs = [];
  Set<String> _selectedShiftIds = {};
  List<String> _selectedJobIds = []; // Empty = all jobs
  bool _isLoading = true;
  bool _isProcessing = false;

  /// Converts 24-hour time format to 12-hour format with AM/PM
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';

    // If already in 12-hour format (contains AM/PM), return as is
    if (time.toUpperCase().contains('AM') ||
        time.toUpperCase().contains('PM')) {
      return time;
    }

    try {
      // Parse 24-hour format (e.g., "15:30" or "15:30:00")
      final parts = time.split(':');
      if (parts.isEmpty) return time;

      int hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';

      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time; // Return original if parsing fails
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final jobs = await _db.getJobs();
      final jobModels = jobs.map((j) => Job.fromSupabase(j)).toList();

      // Filter shifts based on mode
      final allShifts = shiftProvider.shifts;
      final filteredShifts = widget.isRemoveMode
          ? allShifts.where((s) => s.calendarEventId != null).toList()
          : allShifts.where((s) => s.calendarEventId == null).toList();

      // Sort by date descending
      filteredShifts.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _shifts = filteredShifts;
        _jobs = jobModels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shifts: $e')),
        );
      }
    }
  }

  List<Shift> get _filteredShifts {
    if (_selectedJobIds.isEmpty) return _shifts;
    return _shifts.where((s) => _selectedJobIds.contains(s.jobId)).toList();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedShiftIds.length == _filteredShifts.length) {
        _selectedShiftIds.clear();
      } else {
        _selectedShiftIds = _filteredShifts.map((s) => s.id).toSet();
      }
    });
  }

  double get _selectedTotal {
    return _shifts
        .where((s) => _selectedShiftIds.contains(s.id))
        .fold(0.0, (sum, shift) => sum + shift.totalIncome);
  }

  Future<void> _showJobFilterDialog() async {
    final tempSelected = List<String>.from(_selectedJobIds);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Filter by Job', style: AppTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('All Jobs', style: AppTheme.bodyLarge),
                  value: tempSelected.isEmpty,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        tempSelected.clear();
                      }
                    });
                  },
                ),
                const Divider(),
                ..._jobs.map((job) => CheckboxListTile(
                      title: Text(job.name, style: AppTheme.bodyMedium),
                      subtitle: job.employer != null
                          ? Text(job.employer!, style: AppTheme.labelSmall)
                          : null,
                      value: tempSelected.contains(job.id),
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(job.id);
                          } else {
                            tempSelected.remove(job.id);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedJobIds = tempSelected;
                  _selectedShiftIds
                      .clear(); // Clear selection when filter changes
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processShifts() async {
    if (_selectedShiftIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shifts selected')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final selectedShifts =
          _shifts.where((s) => _selectedShiftIds.contains(s.id)).toList();

      int successCount = 0;
      int failCount = 0;

      for (final shift in selectedShifts) {
        if (widget.isRemoveMode) {
          // Remove calendar event
          bool success;
          if (kIsWeb) {
            success = await _googleCalendar
                .deleteCalendarEvent(shift.calendarEventId!);
          } else {
            // Mobile - use primary calendar
            success = await _calendarSync.deleteCalendarEvent(
                'primary', shift.calendarEventId!);
          }

          if (success) {
            // Clear calendar event ID from shift
            final updatedShift = shift.copyWith(calendarEventId: null);
            await _db.updateShift(updatedShift);
            successCount++;
          } else {
            failCount++;
          }
        } else {
          // Export to calendar
          String? eventId;
          if (kIsWeb) {
            eventId = await _googleCalendar.exportShiftToCalendar(shift);
          } else {
            eventId = await _calendarSync.exportShiftToCalendar(shift);
          }

          if (eventId != null) {
            // Save event ID to shift
            final updatedShift = shift.copyWith(calendarEventId: eventId);
            await _db.updateShift(updatedShift);
            successCount++;
          } else {
            failCount++;
          }
        }
      }

      setState(() => _isProcessing = false);

      if (mounted) {
        final action = widget.isRemoveMode ? 'removed from' : 'exported to';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$successCount shifts $action calendar${failCount > 0 ? ', $failCount failed' : ''}'),
            backgroundColor:
                failCount > 0 ? AppTheme.accentOrange : AppTheme.primaryGreen,
          ),
        );

        if (failCount == 0) {
          Navigator.pop(context, true); // Return true = success
        } else {
          _loadData(); // Reload to show updated state
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          widget.isRemoveMode ? 'Remove Synced Events' : 'Export Shifts',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Column(
              children: [
                // Job filter button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: _showJobFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list,
                              color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedJobIds.isEmpty
                                  ? 'All Jobs'
                                  : '${_selectedJobIds.length} job(s) selected',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),

                // Select all checkbox
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _filteredShifts.isNotEmpty &&
                            _selectedShiftIds.length == _filteredShifts.length,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (_) => _toggleSelectAll(),
                      ),
                      Expanded(
                        child: Text(
                          'Select All (${_filteredShifts.length} shifts)',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Shifts list
                Expanded(
                  child: _filteredShifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isRemoveMode
                                    ? Icons.cloud_done
                                    : Icons.cloud_upload,
                                size: 64,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.isRemoveMode
                                    ? 'No synced shifts to remove'
                                    : 'No shifts to export',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredShifts.length,
                          itemBuilder: (context, index) {
                            final shift = _filteredShifts[index];
                            final job = _jobs.firstWhere(
                              (j) => j.id == shift.jobId,
                              orElse: () => Job(
                                  id: '',
                                  name: 'Unknown',
                                  color: '',
                                  userId: ''),
                            );

                            return CheckboxListTile(
                              value: _selectedShiftIds.contains(shift.id),
                              activeColor: AppTheme.primaryGreen,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedShiftIds.add(shift.id);
                                  } else {
                                    _selectedShiftIds.remove(shift.id);
                                  }
                                });
                              },
                              title: Text(
                                job.name,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(shift.date),
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (shift.startTime != null &&
                                      shift.endTime != null)
                                    Text(
                                      '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                              secondary: Container(
                                width: 80,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _currencyFormat.format(shift.totalIncome),
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Bottom action bar
                if (_selectedShiftIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected: ${_selectedShiftIds.length} shifts',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!widget.isRemoveMode)
                              Text(
                                _currencyFormat.format(_selectedTotal),
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _processShifts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isRemoveMode
                                  ? AppTheme.accentRed
                                  : AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    widget.isRemoveMode
                                        ? 'Remove Selected (${_selectedShiftIds.length})'
                                        : 'Export Selected (${_selectedShiftIds.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
