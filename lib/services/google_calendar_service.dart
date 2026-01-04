import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Google Calendar service for web platform
/// Handles import/export of shifts to Google Calendar using REST API
class GoogleCalendarService {
  final DatabaseService _db = DatabaseService();
  calendar.CalendarApi? _calendarApi;
  static bool _initialized = false;
  GoogleSignInAccount? _currentUser;

  /// Initialize Google Calendar API with authenticated client
  Future<bool> initialize() async {
    if (!kIsWeb) {
      return false; // Only works on web
    }

    try {
      // Initialize GoogleSignIn singleton once
      if (!_initialized) {
        await GoogleSignIn.instance.initialize();
        _initialized = true;

        // Listen to authentication events
        GoogleSignIn.instance.authenticationEvents.listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
          }
        });
      }

      // Try lightweight authentication first
      await GoogleSignIn.instance.attemptLightweightAuthentication();

      // Wait a moment for authentication to complete
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentUser == null) {
        return false; // Not signed in
      }

      // Check if we already have authorization for calendar scopes
      final authClient = _currentUser!.authorizationClient;
      final authorization =
          await authClient.authorizationForScopes(AuthService.calendarScopes);

      // If no authorization, user needs to grant calendar access
      if (authorization == null) {
        print('No calendar authorization - user needs to grant access');
        return false;
      }

      // Get authenticated HTTP client
      final httpClient = authorization.authClient(
        scopes: AuthService.calendarScopes,
      );

      _calendarApi = calendar.CalendarApi(httpClient);
      return true;
    } catch (e) {
      print('Error initializing Google Calendar API: $e');
      return false;
    }
  }

  /// Request calendar access (re-authenticate with calendar scopes)
  Future<bool> requestCalendarAccess() async {
    if (!kIsWeb) {
      return false;
    }

    try {
      print('[v1.0.6] Starting requestCalendarAccess...');
      // Initialize GoogleSignIn singleton once
      if (!_initialized) {
        await GoogleSignIn.instance.initialize();
        _initialized = true;

        // Listen to authentication events
        GoogleSignIn.instance.authenticationEvents.listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
          }
        });
      }

      // Authenticate user and get account directly
      // Note: authenticate() never returns null on web, throws on cancellation
      print('[v1.0.6] About to call authenticate()...');
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: AuthService.calendarScopes,
      );

      print('[v1.0.6] Authentication successful, account ID: ${account.id}');
      _currentUser = account;

      // Request authorization for calendar scopes
      print('[v1.0.6] Getting authorizationClient...');
      final authClient = account.authorizationClient;
      print('[v1.0.6] Got authClient, calling authorizeScopes...');
      final authorization =
          await authClient.authorizeScopes(AuthService.calendarScopes);

      print('[v1.0.6] Authorization received, creating HTTP client...');
      // Get authenticated HTTP client
      final httpClient = authorization.authClient(
        scopes: AuthService.calendarScopes,
      );

      print('[v1.0.6] Creating CalendarApi...');
      _calendarApi = calendar.CalendarApi(httpClient);

      // Save that we have calendar access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_calendar_access', true);

      return true;
    } catch (e, stackTrace) {
      print('[v1.0.6] Error requesting calendar access: $e');
      print('[v1.0.6] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Import shifts from Google Calendar
  /// Returns the number of new shifts imported
  Future<int> importShiftsFromCalendar() async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return 0;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get job mappings
      final jobMappingsJson = prefs.getString('job_mappings');
      if (jobMappingsJson == null) {
        return 0; // No job mappings set up
      }

      // Parse job mappings
      final Map<String, dynamic> jobMappingsData = Map<String, dynamic>.from(
          await SharedPreferences.getInstance().then((p) => {}));
      final Map<String, String> jobMappings =
          jobMappingsData.map((k, v) => MapEntry(k, v.toString()));

      // Retrieve events from primary calendar
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endDate = now.add(const Duration(days: 180)); // 6 months ahead

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: today.toUtc(),
        timeMax: endDate.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items == null || events.items!.isEmpty) {
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

      final workEvents = events.items!.where((event) {
        final title = event.summary?.toLowerCase() ?? '';
        final description = event.description?.toLowerCase() ?? '';
        return workKeywords.any((keyword) =>
            title.contains(keyword) || description.contains(keyword));
      }).toList();

      int imported = 0;
      final existingShifts = await _db.getShifts();

      for (final event in workEvents) {
        if (event.start?.dateTime == null) continue;

        // Extract job title from event
        String jobTitle = event.summary!
            .replaceFirst(
                RegExp(
                    r'^(Hot Schedules|7shifts|When I Work|Homebase|Sling|🍺)\s*',
                    caseSensitive: false),
                '')
            .trim();

        // Find matching job ID
        final jobId = jobMappings[jobTitle];
        if (jobId == null) continue;

        // Check for duplicates using event ID
        final isDuplicate = existingShifts.any((shift) {
          // Primary check: If calendar event ID matches
          if (shift.calendarEventId == event.id) {
            return true;
          }

          // Secondary check: Same date + time + job
          final eventStart = event.start!.dateTime!.toLocal();
          final eventStartTime =
              '${eventStart.hour.toString().padLeft(2, '0')}:${eventStart.minute.toString().padLeft(2, '0')}';

          return shift.jobId == jobId &&
              shift.date.year == eventStart.year &&
              shift.date.month == eventStart.month &&
              shift.date.day == eventStart.day &&
              shift.startTime == eventStartTime;
        });

        if (isDuplicate) {
          continue;
        }

        // Calculate hours and times
        final startTime = event.start!.dateTime!.toLocal();
        final endTime = event.end?.dateTime?.toLocal() ??
            startTime.add(const Duration(hours: 8));

        final hoursWorked = endTime.difference(startTime).inMinutes / 60.0;
        final startTimeStr =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final endTimeStr =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        // Create new scheduled shift
        final shift = Shift(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: startTime,
          startTime: startTimeStr,
          endTime: endTimeStr,
          cashTips: 0,
          creditTips: 0,
          hourlyRate: 0,
          hoursWorked: hoursWorked,
          status: 'scheduled',
          source: 'google_calendar_sync',
          calendarEventId: event.id,
          jobId: jobId,
          notes: event.description,
        );

        await _db.saveShift(shift);
        imported++;
      }

      // Update last sync timestamp
      await prefs.setString(
          'last_calendar_sync', DateTime.now().toIso8601String());

      return imported;
    } catch (e) {
      print('Error importing from Google Calendar: $e');
      return 0;
    }
  }

  /// Export a shift to Google Calendar
  /// Returns the calendar event ID if successful
  Future<String?> exportShiftToCalendar(Shift shift) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      // Get job name
      final jobs = await _db.getJobs();
      String jobName = 'Work';
      String? employer;
      try {
        final jobMap = jobs.firstWhere((j) => j['id'] == shift.jobId);
        jobName = jobMap['name'] as String? ?? 'Work';
        employer = jobMap['employer'] as String?;
      } catch (e) {
        // Job not found, use defaults
      }

      // Build event
      final title = '🍺 $jobName';
      final description = _buildEventDescription(shift, null);

      final startDateTime = _parseShiftDateTime(shift.date, shift.startTime);
      final endDateTime = _parseShiftDateTime(shift.date, shift.endTime);

      final event = calendar.Event()
        ..summary = title
        ..description = description
        ..start = calendar.EventDateTime()
        ..start!.dateTime = startDateTime.toUtc()
        ..end = calendar.EventDateTime()
        ..end!.dateTime = endDateTime.toUtc()
        ..location = employer;

      // Create or update event
      if (shift.calendarEventId != null) {
        // Update existing event
        event.id = shift.calendarEventId;
        final result = await _calendarApi!.events
            .update(event, 'primary', shift.calendarEventId!);
        return result.id;
      } else {
        // Create new event
        final result = await _calendarApi!.events.insert(event, 'primary');
        return result.id;
      }
    } catch (e) {
      print('Error exporting shift to Google Calendar: $e');
      return null;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (_calendarApi == null) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      await _calendarApi!.events.delete('primary', eventId);
      return true;
    } catch (e) {
      print('Error deleting calendar event: $e');
      return false;
    }
  }

  /// Build event description with shift details
  String _buildEventDescription(Shift shift, dynamic jobData) {
    final lines = <String>[];

    if (shift.status == 'scheduled') {
      lines.add('📅 Scheduled Shift');
    } else {
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
