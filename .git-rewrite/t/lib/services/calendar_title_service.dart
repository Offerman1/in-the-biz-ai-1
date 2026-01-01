import '../models/shift.dart';
import '../models/job.dart';
import 'database_service.dart';

/// Helper service for calendar title mappings and display
class CalendarTitleService {
  final DatabaseService _db = DatabaseService();

  // Cache for job names to avoid repeated database calls
  final Map<String, String> _jobNameCache = {};

  /// Get the display name for a shift (uses mapped job name if available)
  Future<String> getShiftDisplayName(Shift shift) async {
    // If shift has a jobId, use the job's name
    if (shift.jobId != null) {
      // Check cache first
      if (_jobNameCache.containsKey(shift.jobId)) {
        return _jobNameCache[shift.jobId]!;
      }

      // Fetch job from database
      try {
        final jobs = await _db.getJobs();
        final job = jobs.firstWhere(
          (j) => j['id'] == shift.jobId,
          orElse: () => <String, dynamic>{},
        );

        if (job.isNotEmpty) {
          final jobTitle =
              job['job_title'] as String? ?? job['employer'] as String? ?? '';
          _jobNameCache[shift.jobId!] = jobTitle;
          return jobTitle;
        }
      } catch (e) {
        // Fall through to eventName
      }
    }

    // Fallback to event name if no job mapping
    return shift.eventName ?? 'Shift';
  }

  /// Get the display name for a shift synchronously (for widgets that can't be async)
  /// Must call loadJobNamesCache() first during screen initialization
  String getShiftDisplayNameSync(Shift shift) {
    if (shift.jobId != null && _jobNameCache.containsKey(shift.jobId)) {
      return _jobNameCache[shift.jobId]!;
    }
    return shift.eventName ?? 'Shift';
  }

  /// Pre-load job names into cache for synchronous access
  Future<void> loadJobNamesCache() async {
    try {
      final jobs = await _db.getJobs();
      for (final job in jobs) {
        final jobId = job['id'] as String;
        final jobTitle =
            job['job_title'] as String? ?? job['employer'] as String? ?? '';
        _jobNameCache[jobId] = jobTitle;
      }
    } catch (e) {
      // Silent fail - cache will just be empty
    }
  }

  /// Clear the cache (call when jobs are updated)
  void clearCache() {
    _jobNameCache.clear();
  }

  /// Extract unique calendar titles from a list of shifts
  /// Returns a list of {title: String, count: int}
  List<Map<String, dynamic>> extractCalendarTitles(List<Shift> shifts) {
    final titleCounts = <String, int>{};

    for (final shift in shifts) {
      if (shift.eventName != null && shift.eventName!.isNotEmpty) {
        titleCounts[shift.eventName!] =
            (titleCounts[shift.eventName!] ?? 0) + 1;
      }
    }

    return titleCounts.entries
        .map((e) => {'title': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  /// Save job group mappings after user creates groups
  Future<void> saveJobGroups(List<Map<String, dynamic>> groups) async {
    for (final group in groups) {
      final job = group['job'] as Job;
      final titles = group['titles'] as List<String>;

      await _db.saveCalendarTitleMappings(
        jobId: job.id,
        calendarTitles: titles,
      );
    }

    // Clear cache so new mappings are picked up
    clearCache();
  }

  /// Auto-assign job to shift based on calendar title mapping
  Future<String?> autoAssignJob(String calendarTitle) async {
    return await _db.getJobIdFromCalendarTitle(calendarTitle);
  }
}
