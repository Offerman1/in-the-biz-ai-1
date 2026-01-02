import 'dart:convert';
import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/shift.dart';
import '../models/job.dart';
import '../services/database_service.dart';

class CalendarSyncService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  final DatabaseService _db = DatabaseService();

  /// Auto-sync future shifts from device calendar
  /// Returns the number of new shifts imported
  Future<int> autoSyncFutureShifts() async {
    try {
      // Check if permission is granted
      final prefs = await SharedPreferences.getInstance();
      final hasPermission =
          prefs.getBool('calendar_permission_granted') ?? false;

      if (!hasPermission) {
        return 0; // No permission, skip silently
      }

      // Get the selected calendar ID
      final selectedCalendarId = prefs.getString('selected_calendar_id');
      if (selectedCalendarId == null) {
        return 0; // No calendar selected
      }

      // Get job mappings (calendar event titles → job IDs)
      final jobMappingsJson = prefs.getString('job_mappings');
      if (jobMappingsJson == null) {
        return 0; // No job mappings set up
      }

      // Parse job mappings (stored as JSON string)
      final Map<String, dynamic> jobMappingsData = jsonDecode(jobMappingsJson);
      final Map<String, String> jobMappings =
          jobMappingsData.map((k, v) => MapEntry(k, v.toString()));

      // Retrieve future events only (today + 6 months ahead)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endDate = now.add(const Duration(days: 180)); // 6 months ahead

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        selectedCalendarId,
        RetrieveEventsParams(startDate: today, endDate: endDate),
      );

      if (!eventsResult.isSuccess || eventsResult.data == null) {
        return 0;
      }

      // Filter for work-related events
      final workKeywords = [
        'shift',
        'work',
        'server',
        'bartender',
        'host',
        'bar',
        'restaurant',
        'schedule',
        'hot schedules',
        '7shifts',
        'when i work',
        'homebase',
        'sling',
      ];

      final workEvents = eventsResult.data!.where((event) {
        final title = event.title?.toLowerCase() ?? '';
        final description = event.description?.toLowerCase() ?? '';
        return workKeywords.any((keyword) =>
            title.contains(keyword) || description.contains(keyword));
      }).toList();

      int imported = 0;

      for (final event in workEvents) {
        if (event.start == null) continue;

        // Extract job title from event (strip prefixes)
        String jobTitle = event.title!
            .replaceFirst(
                RegExp(
                    r'^(Hot Schedules|7shifts|When I Work|Homebase|Sling)\s*',
                    caseSensitive: false),
                '')
            .trim();

        // Find matching job ID
        final jobId = jobMappings[jobTitle];
        if (jobId == null) continue; // No job mapping found

        // CRITICAL: Get FRESH shifts from database AFTER we know the jobId
        final existingShifts = await _db.getShifts();

        // Format event start time for comparison
        final eventStartTime = event.start != null
            ? '${event.start!.hour.toString().padLeft(2, '0')}:${event.start!.minute.toString().padLeft(2, '0')}'
            : null;

        // ENHANCED duplicate check: Check calendar event ID first, then date/time/job
        final isDuplicate = existingShifts.any((shift) {
          // Primary check: If calendar event ID matches, it's definitely a duplicate
          if (event.eventId != null && shift.calendarEventId == event.eventId) {
            return true;
          }

          // Secondary check: Same date + time + job (for events without ID or pre-existing shifts)
          return shift.jobId == jobId &&
              shift.date.year == event.start!.year &&
              shift.date.month == event.start!.month &&
              shift.date.day == event.start!.day &&
              shift.startTime == eventStartTime;
        });

        if (isDuplicate) {
          continue; // Skip duplicates
        }

        // Calculate hours worked
        double hoursWorked = 0;
        String? startTime;
        String? endTime;

        if (event.start != null && event.end != null) {
          hoursWorked = event.end!.difference(event.start!).inMinutes / 60.0;
          startTime =
              '${event.start!.hour.toString().padLeft(2, '0')}:${event.start!.minute.toString().padLeft(2, '0')}';
          endTime =
              '${event.end!.hour.toString().padLeft(2, '0')}:${event.end!.minute.toString().padLeft(2, '0')}';
        }

        // Create new scheduled shift
        final shift = Shift(
          id: const Uuid().v4(),
          date: event.start!,
          startTime: startTime,
          endTime: endTime,
          cashTips: 0,
          creditTips: 0,
          hourlyRate: 0,
          hoursWorked: hoursWorked,
          status: 'scheduled',
          source: 'calendar_sync',
          calendarEventId: event.eventId,
          eventName:
              null, // DO NOT pollute with calendar title - let user fill manually
          jobId: jobId,
          notes: event
              .description, // Just use raw description, no 'Auto-synced' prefix
        );

        await _db.saveShift(shift);
        imported++;
      }

      // Update last sync timestamp
      await prefs.setString(
          'last_calendar_sync', DateTime.now().toIso8601String());

      return imported;
    } catch (e) {
      print('Auto-sync error: $e');
      return 0; // Fail silently
    }
  }

  /// Check if enough time has passed since last sync (prevents excessive syncing)
  Future<bool> shouldSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_calendar_sync');

      if (lastSyncStr == null) return true; // Never synced before

      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();

      // Only sync if 1+ hour has passed
      return now.difference(lastSync).inHours >= 1;
    } catch (e) {
      return true; // If error, allow sync
    }
  }

  /// Export a shift to device calendar (Mobile only)
  /// Returns the calendar event ID if successful, null if failed
  Future<String?> exportShiftToCalendar(Shift shift,
      {String? calendarId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get selected calendar ID if not provided
      calendarId ??= prefs.getString('selected_calendar_id');
      if (calendarId == null) {
        print('No calendar selected for export');
        return null;
      }

      // Check permission
      final hasPermission = await _deviceCalendarPlugin.hasPermissions();
      if (!hasPermission.isSuccess || !(hasPermission.data ?? false)) {
        print('No calendar permission for export');
        return null;
      }

      // Get job name for event title
      final jobs = await _db.getJobs();
      Job? job;
      try {
        final jobMap = jobs.firstWhere((j) => j['id'] == shift.jobId);
        job = Job.fromMap(jobMap);
      } catch (e) {
        job = null;
      }
      final jobName = job?.name ?? 'Work Shift';

      // Build event title and description
      final title = '🍺 $jobName';
      final description = _buildEventDescription(shift, job);

      // Create start and end DateTime
      final startDateTime = _parseShiftDateTime(shift.date, shift.startTime);
      final endDateTime = _parseShiftDateTime(shift.date, shift.endTime);

      // Create calendar event
      final event = Event(
        calendarId,
        title: title,
        description: description,
        start: tz.TZDateTime.from(startDateTime, tz.local),
        end: tz.TZDateTime.from(endDateTime, tz.local),
        location: job?.employer,
      );

      // Create or update event
      if (shift.calendarEventId != null) {
        // Update existing event
        event.eventId = shift.calendarEventId;
        final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
        if (result.isSuccess) {
          return shift.calendarEventId;
        }
      } else {
        // Create new event
        final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
        if (result.isSuccess && result.data != null) {
          return result.data; // Return the new event ID
        }
      }

      return null;
    } catch (e) {
      print('Error exporting shift to calendar: $e');
      return null;
    }
  }

  /// Delete a shift's calendar event (Mobile only)
  Future<bool> deleteCalendarEvent(String calendarId, String eventId) async {
    try {
      final result =
          await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      return result?.isSuccess ?? false;
    } catch (e) {
      print('Error deleting calendar event: $e');
      return false;
    }
  }

  /// Build event description with shift details
  String _buildEventDescription(Shift shift, Job? job) {
    final lines = <String>[];

    if (shift.status == 'scheduled') {
      lines.add('📅 Scheduled Shift');
    } else {
      // Include earnings for completed shifts
      lines.add('💰 Total Earned: \$${shift.totalIncome.toStringAsFixed(2)}');

      if (shift.hourlyRate > 0 && shift.hoursWorked > 0) {
        lines.add(
            '⏱️ ${shift.hoursWorked.toStringAsFixed(1)} hrs @ \$${shift.hourlyRate.toStringAsFixed(2)}/hr');
      }

      final totalTips = shift.cashTips + shift.creditTips;
      if (totalTips > 0) {
        lines.add('💵 Tips: \$${totalTips.toStringAsFixed(2)}');
      }
    }

    if (shift.notes != null && shift.notes!.isNotEmpty) {
      lines.add('');
      lines.add('📝 Notes:');
      lines.add(shift.notes!);
    }

    lines.add('');
    lines.add('Created by In The Biz AI');

    return lines.join('\n');
  }

  /// Parse shift date and time string into DateTime
  DateTime _parseShiftDateTime(DateTime date, String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return date;
    }

    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      print('Error parsing time: $timeString');
    }

    return date;
  }
}
