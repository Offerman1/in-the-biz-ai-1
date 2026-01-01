import 'dart:convert';
import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/shift.dart';
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

        // BULLETPROOF duplicate check: Same date + same start time + same job
        final isDuplicate = existingShifts.any((shift) {
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
}
