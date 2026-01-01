import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/calendar_title_service.dart';
import '../providers/shift_provider.dart';
import '../models/shift.dart';
import '../models/job.dart';
import 'job_grouping_screen.dart';
import 'dashboard_screen.dart';

class CalendarSyncScreen extends StatefulWidget {
  final bool isOnboarding;
  final Function(Map<String, String>)? onImportComplete;

  const CalendarSyncScreen({
    super.key,
    this.isOnboarding = false,
    this.onImportComplete,
  });

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  final DatabaseService _db = DatabaseService();
  List<Calendar> _calendars = [];
  Calendar? _selectedCalendar;
  List<Event> _upcomingShifts = [];
  Set<String> _selectedShiftIds = {}; // Track selected shift IDs
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _showSetupGuide = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
      setState(() {
        _hasPermission = true;
        _showSetupGuide = false;
      });
      await _loadCalendars();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    // First try using permission_handler for a proper system dialog
    var status = await Permission.calendar.request();

    if (status.isGranted) {
      // Also request through device_calendar plugin
      await _deviceCalendarPlugin.requestPermissions();

      setState(() {
        _hasPermission = true;
        _showSetupGuide = false;
      });
      await _loadCalendars();
    } else if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calendar permission is required to sync schedules'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        // Show dialog to open app settings
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Calendar permission is permanently denied. Please enable it in app settings to sync your schedule.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoading = true);

    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        setState(() {
          _calendars = calendarsResult.data!;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calendars: $e')),
        );
      }
    }
  }

  Future<void> _loadEventsFromCalendar(Calendar calendar) async {
    setState(() {
      _selectedCalendar = calendar;
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      // Get full history (up to 15 years back), future shifts up to 6 months ahead
      final startDate =
          now.subtract(const Duration(days: 5475)); // 15 years back
      final endDate = now.add(const Duration(days: 180)); // 6 months ahead

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        // Filter for work-related events (look for keywords)
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

        setState(() {
          _upcomingShifts = workEvents;
          // Auto-select all shifts by default
          _selectedShiftIds = workEvents.map((e) => e.eventId!).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
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
        title: Text('Sync Schedule',
            style: AppTheme.titleLarge
                .copyWith(color: AppTheme.adaptiveTextColor)),
        actions: [
          if (_hasPermission)
            IconButton(
              icon: Icon(Icons.help_outline, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _showSetupGuide = true),
            ),
        ],
      ),
      body: _showSetupGuide
          ? _buildSetupGuide()
          : _isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen))
              : _buildCalendarList(),
    );
  }

  Widget _buildSetupGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.black, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Your Schedule',
                        style:
                            AppTheme.titleLarge.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sync shifts from Hot Schedules, 7shifts, When I Work, and more!',
                        style:
                            AppTheme.bodyMedium.copyWith(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text('How It Works', style: AppTheme.headlineMedium),
          const SizedBox(height: 16),

          _buildStepCard(
            step: 1,
            title: 'Enable Calendar Sync in Your Scheduling App',
            description:
                'Open your scheduling app (Hot Schedules, 7shifts, etc.) and enable "Sync to Calendar" in settings.',
            icon: Icons.settings,
          ),

          _buildStepCard(
            step: 2,
            title: 'Choose Google or Apple Calendar',
            description:
                'Select which calendar to sync your shifts to. This creates events on your phone\'s calendar.',
            icon: Icons.phone_android,
          ),

          _buildStepCard(
            step: 3,
            title: 'Import Into In The Biz',
            description:
                'We\'ll read your calendar and import your upcoming shifts automatically!',
            icon: Icons.download,
          ),

          const SizedBox(height: 24),

          // App-specific instructions
          Text('Setup Instructions by App', style: AppTheme.titleMedium),
          const SizedBox(height: 16),

          _buildAppInstructions(
            appName: 'Hot Schedules (Fourth)',
            icon: '📅',
            steps: [
              'Open Hot Schedules app',
              'Tap Menu → Settings',
              'Tap "Calendar Sync"',
              'Choose Google Calendar or Apple Calendar',
              'Enable sync and confirm',
            ],
          ),

          _buildAppInstructions(
            appName: '7shifts',
            icon: '7️⃣',
            steps: [
              'Open 7shifts app',
              'Go to Account → Settings',
              'Tap "Calendar Integration"',
              'Select your calendar app',
              'Grant permission when prompted',
            ],
          ),

          _buildAppInstructions(
            appName: 'When I Work',
            icon: '⏰',
            steps: [
              'Open When I Work app',
              'Tap your profile icon',
              'Go to Settings → Calendar Sync',
              'Choose your calendar',
              'Toggle sync ON',
            ],
          ),

          _buildAppInstructions(
            appName: 'Homebase',
            icon: '🏠',
            steps: [
              'Open Homebase app',
              'Go to More → Settings',
              'Tap "Calendar Sync"',
              'Select calendar type',
              'Follow prompts to connect',
            ],
          ),

          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasPermission
                  ? () => setState(() => _showSetupGuide = false)
                  : _requestPermissions,
              icon: Icon(
                  _hasPermission ? Icons.arrow_forward : Icons.calendar_month),
              label: Text(_hasPermission
                  ? 'Continue to Calendar'
                  : 'Grant Calendar Access'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Skip option
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'I\'ll do this later',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ),

          const SizedBox(height: 32), // Extra bottom padding to prevent cutoff
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppTheme.textMuted, size: 24),
        ],
      ),
    );
  }

  Widget _buildAppInstructions({
    required String appName,
    required String icon,
    required List<String> steps,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ExpansionTile(
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(appName, style: AppTheme.bodyLarge),
        iconColor: AppTheme.primaryGreen,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value, style: AppTheme.bodyMedium),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarList() {
    if (_calendars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No calendars found', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Make sure you have a calendar app\nand have synced your schedule to it.',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showSetupGuide = true),
              icon: const Icon(Icons.help_outline),
              label: const Text('View Setup Guide'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Calendar selector
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Calendar', style: AppTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Choose the calendar where your work shifts are synced',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = _calendars[index];
                    final isSelected = _selectedCalendar?.id == calendar.id;
                    return GestureDetector(
                      onTap: () => _loadEventsFromCalendar(calendar),
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withOpacity(0.2)
                              : AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              calendar.name ?? 'Calendar',
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Divider(color: AppTheme.cardBackgroundLight),

        // Events list
        Expanded(
          child: _selectedCalendar == null
              ? Center(
                  child: Text(
                    'Select a calendar to view shifts',
                    style:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                  ),
                )
              : _upcomingShifts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text('No shifts found', style: AppTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'No work-related events found in this calendar.\nMake sure your scheduling app is syncing.',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _upcomingShifts.length + 1, // +1 for import button
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final allSelected = _selectedShiftIds.length ==
                              _upcomingShifts.length;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                // Select All / Unselect All
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_selectedShiftIds.length} of ${_upcomingShifts.length} selected',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          if (allSelected) {
                                            _selectedShiftIds.clear();
                                          } else {
                                            _selectedShiftIds = _upcomingShifts
                                                .map((e) => e.eventId!)
                                                .toSet();
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        allSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        size: 20,
                                      ),
                                      label: Text(allSelected
                                          ? 'Unselect All'
                                          : 'Select All'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Import and Clear buttons side by side
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isImporting ||
                                                _selectedShiftIds.isEmpty
                                            ? null
                                            : () => _showJobMatchingAndImport(),
                                        icon: _isImporting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                              )
                                            : const Icon(Icons.download),
                                        label: Text(
                                          _isImporting
                                              ? 'Importing...'
                                              : 'Import ${_selectedShiftIds.length}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryGreen,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isImporting
                                            ? null
                                            : () => _clearCalendarShifts(),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20),
                                        label: const Text(
                                          'Clear All',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.accentRed,
                                          side: BorderSide(
                                              color: AppTheme.accentRed),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        final event = _upcomingShifts[index - 1];
                        return _buildEventCard(event);
                      },
                    ),
        ),
      ],
    );
  }

  /// Clean up duplicate consecutive words in event title
  /// "GP Server GP Server" → "GP Server"
  /// "Server Banquet Server Banquet" → "Server Banquet"
  String _cleanEventTitle(String? title) {
    if (title == null || title.isEmpty) return 'Shift';

    // Remove common app prefixes first
    String cleaned = title
        .replaceFirst(
          RegExp(r'^(Hot Schedules|7shifts|When I Work|Homebase|Sling)\s*',
              caseSensitive: false),
          '',
        )
        .trim();

    // Split into words
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length <= 1) return cleaned;

    // Remove consecutive duplicates (case-insensitive)
    final result = <String>[words[0]];
    for (int i = 1; i < words.length; i++) {
      if (words[i].toLowerCase() != words[i - 1].toLowerCase()) {
        result.add(words[i]);
      }
    }

    return result.join(' ');
  }

  Widget _buildEventCard(Event event) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final isSelected = _selectedShiftIds.contains(event.eventId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedShiftIds.remove(event.eventId);
          } else {
            _selectedShiftIds.add(event.eventId!);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            // Checkbox
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  event.start != null
                      ? DateFormat('d').format(event.start!)
                      : '?',
                  style: AppTheme.titleMedium
                      .copyWith(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanEventTitle(event.title),
                    style: AppTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.start != null
                        ? '${dateFormat.format(event.start!)} • ${timeFormat.format(event.start!)}${event.end != null ? ' - ${timeFormat.format(event.end!)}' : ''}'
                        : 'Time unknown',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extract job titles from calendar events
  Map<String, int> _extractJobTitles() {
    final jobCounts = <String, int>{};

    for (final event in _upcomingShifts) {
      if (event.title == null) continue;

      // Remove common prefixes like "Hot Schedules", "7shifts", etc.
      String jobTitle = event.title!
          .replaceFirst(
              RegExp(r'^(Hot Schedules|7shifts|When I Work|Homebase|Sling)\s*',
                  caseSensitive: false),
              '')
          .trim();

      // CLEAN DUPLICATE WORDS HERE - at the source!
      jobTitle = _cleanEventTitle(jobTitle);

      if (jobTitle.isNotEmpty) {
        jobCounts[jobTitle] = (jobCounts[jobTitle] ?? 0) + 1;
      }
    }

    return jobCounts;
  }

  // Show job grouping screen and import
  Future<void> _showJobMatchingAndImport() async {
    // Extract job titles
    final extractedJobs = _extractJobTitles();

    if (extractedJobs.isEmpty) {
      // No jobs found, skip import
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No work shifts found in calendar'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      return;
    }

    // Skip job matching screen - go straight to grouping
    if (mounted) {
      final calendarTitles = extractedJobs.entries
          .map((e) => {'title': e.key, 'count': e.value})
          .toList();

      final groups = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => JobGroupingScreen(
            calendarTitles: calendarTitles,
          ),
        ),
      );

      // Create job mapping from groups
      Map<String, String> finalJobMapping = {};
      List<Job> createdJobs = [];

      if (groups != null && groups.isNotEmpty) {
        // Only save job groups if NOT onboarding (settings flow)
        // During onboarding, jobs will be created in _completeOnboarding()
        if (!widget.isOnboarding) {
          final titleService = CalendarTitleService();
          await titleService.saveJobGroups(groups);
        }

        // Build job mapping from groups and collect created jobs
        for (final group in groups) {
          final job = group['job'] as Job;
          final titles = group['titles'] as List<String>;

          createdJobs.add(job);

          // Map all titles in this group to the same job ID
          for (final title in titles) {
            finalJobMapping[title] = job.id;
          }
        }
      }

      // If this is onboarding, pass jobs back to continue through Template/Goals/Confirmation
      // Otherwise (settings flow), import directly
      if (widget.isOnboarding && finalJobMapping.isNotEmpty) {
        if (widget.onImportComplete != null) {
          // Pass job mapping back to onboarding to continue flow
          widget.onImportComplete!(finalJobMapping);
        }
        // Pop back to onboarding with jobs, mapping, AND events (don't import yet)
        if (mounted) {
          // Get selected events
          final selectedEvents = _upcomingShifts
              .where((e) => _selectedShiftIds.contains(e.eventId))
              .toList();

          Navigator.pop(context, {
            'jobs': createdJobs,
            'mapping': finalJobMapping,
            'events': selectedEvents,
          });
        }
      } else if (finalJobMapping.isNotEmpty) {
        // Settings flow - import directly
        await _importShiftsWithJobMapping(finalJobMapping);
      }
    }
  }

  // Import shifts with job mapping
  Future<void> _importShiftsWithJobMapping(
      Map<String, String> jobMapping) async {
    setState(() => _isImporting = true);

    int imported = 0;
    int skipped = 0;

    // Show video ad placeholder for large imports (>25 shifts)
    final isLargeImport = _upcomingShifts.length > 25;
    if (isLargeImport && mounted) {
      _showLargeImportDialog();
    }

    try {
      // Get existing shifts to check for duplicates
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final existingShifts = shiftProvider.shifts;

      // Only process selected shifts
      final selectedShifts = _upcomingShifts
          .where((e) => _selectedShiftIds.contains(e.eventId))
          .toList();

      // Filter: Only import PAST shifts during manual import (anything before RIGHT NOW)
      // Auto-sync handles current moment + future shifts to prevent duplicates
      final now = DateTime.now();

      final shiftsToImport = selectedShifts.where((event) {
        if (event.start == null) return false;
        // Only import if event start time has already passed (even by 1 second)
        return event.start!.isBefore(now);
      }).toList();

      for (final event in shiftsToImport) {
        if (event.start == null) {
          skipped++;
          continue;
        }

        // Extract job title from event (strip prefixes)
        String jobTitle = event.title!
            .replaceFirst(
                RegExp(
                    r'^(Hot Schedules|7shifts|When I Work|Homebase|Sling)\s*',
                    caseSensitive: false),
                '')
            .trim();

        // Find matching job ID
        final jobId = jobMapping[jobTitle];

        if (jobId == null) {
          // No job mapping found, skip this shift
          skipped++;
          continue;
        }

        // Smart duplicate detection:
        // 1. Check by calendar event ID
        // 2. If user added earnings (modified), SKIP to preserve their data
        // 3. If still empty ($0), allow update in case schedule changed
        final existingShift = existingShifts.firstWhere(
          (shift) =>
              shift.calendarEventId == event.eventId ||
              (shift.date.year == event.start!.year &&
                  shift.date.month == event.start!.month &&
                  shift.date.day == event.start!.day &&
                  shift.source == 'calendar_sync'),
          orElse: () => Shift(
            id: '',
            date: DateTime(1900),
            cashTips: -1,
            creditTips: -1,
            hourlyRate: -1,
            hoursWorked: -1,
          ),
        );

        // If shift exists and user added earnings, DON'T overwrite
        final hasEarnings =
            existingShift.totalIncome > 0 || existingShift.hoursWorked > 0;

        if (existingShift.id.isNotEmpty && hasEarnings) {
          skipped++;
          continue; // Preserve user's data
        }

        // If shift exists but is still empty, update it instead of creating new
        final isUpdate = existingShift.id.isNotEmpty;

        // Calculate hours worked
        double hoursWorked = 0;
        String? startTime;
        String? endTime;

        if (event.start != null && event.end != null) {
          hoursWorked = event.end!.difference(event.start!).inMinutes / 60.0;

          // Format times as HH:mm
          startTime =
              '${event.start!.hour.toString().padLeft(2, '0')}:${event.start!.minute.toString().padLeft(2, '0')}';
          endTime =
              '${event.end!.hour.toString().padLeft(2, '0')}:${event.end!.minute.toString().padLeft(2, '0')}';
        }

        // Determine if this is a future shift
        final now = DateTime.now();
        final isFuture = event.start!.isAfter(now);

        // CRITICAL: Import actual hours worked from calendar
        // BUT keep earnings at $0 - user must add earnings manually
        final shift = Shift(
          id: isUpdate ? existingShift.id : const Uuid().v4(),
          date: event.start!,
          startTime: startTime,
          endTime: endTime,
          cashTips: 0,
          creditTips: 0,
          hourlyRate: 0, // Don't use default rate
          hoursWorked: hoursWorked, // IMPORT ACTUAL HOURS from calendar
          status: isFuture ? 'scheduled' : 'completed',
          source: 'calendar_sync',
          calendarEventId: event.eventId,
          eventName:
              null, // DO NOT import calendar title - let user fill this manually
          jobId: jobId,
          notes: event
              .description, // Just use the calendar description, no "Imported from..." text
        );

        // Save to database (will update if ID exists, insert if new)
        await _db.saveShift(shift);

        imported++;
      }

      // Save job mappings and calendar ID for auto-sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('job_mappings', jsonEncode(jobMapping));
      await prefs.setString('selected_calendar_id', _selectedCalendar!.id!);
      await prefs.setBool('calendar_permission_granted', true);

      // Refresh the shift provider to show new shifts
      if (mounted) {
        final shiftProvider =
            Provider.of<ShiftProvider>(context, listen: false);
        await shiftProvider.loadShifts();

        // Auto-clean all shift titles after import
        await _cleanAllShiftTitles();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Imported $imported shifts${skipped > 0 ? ' ($skipped skipped)' : ''}'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Context-aware navigation
        if (widget.isOnboarding) {
          // Onboarding complete - go directly to dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false, // Remove all previous routes
          );
        } else {
          // Settings flow - go back to main screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing shifts: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _clearCalendarShifts() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Calendar Shifts?'),
        content: const Text(
          'This will delete all shifts that were imported from your calendar. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final calendarShifts = shiftProvider.shifts
          .where((shift) => shift.source == 'calendar_sync')
          .toList();

      for (final shift in calendarShifts) {
        await _db.deleteShift(shift.id);
      }

      await shiftProvider.loadShifts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Deleted ${calendarShifts.length} calendar-synced shifts'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting shifts: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  // Mock video ad dialog for large imports
  void _showLargeImportDialog() {
    final totalShifts = _upcomingShifts.length;
    final estimatedSeconds = (totalShifts * 0.3).ceil(); // ~0.3 sec per shift
    final displaySeconds =
        estimatedSeconds < 60 ? 60 : estimatedSeconds; // Min 60 sec

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Importing $totalShifts Shifts',
          style: AppTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displaySeconds > 60
                  ? 'This may take up to ${(displaySeconds / 60).ceil()} minutes...'
                  : 'This may take up to 60 seconds...',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // MOCK VIDEO AD PLACEHOLDER
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 64,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '📹 VIDEO AD PLACEHOLDER',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${displaySeconds}-second ad plays here',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Progress indicator
            LinearProgressIndicator(
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.darkBackground,
            ),
            const SizedBox(height: 8),
            Text(
              'Importing shifts... ($totalShifts total)',
              style: AppTheme.labelMedium.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );

    // Intelligent auto-close based on actual import time
    Future.delayed(Duration(seconds: displaySeconds), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Show job grouping screen if there are 3+ unique calendar titles
  Future<void> _showJobGroupingIfNeeded(List<Shift> shifts) async {
    final titleService = CalendarTitleService();
    final calendarTitles = titleService.extractCalendarTitles(shifts);

    // Only show grouping if 3+ unique titles (skip if just 1-2 jobs)
    if (calendarTitles.length >= 3) {
      final groups = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => JobGroupingScreen(
            calendarTitles: calendarTitles,
          ),
        ),
      );

      // Save the groups if user created any
      if (groups != null && groups.isNotEmpty) {
        await titleService.saveJobGroups(groups);

        // Update shifts with the new job mappings
        final provider = Provider.of<ShiftProvider>(context, listen: false);
        await provider.loadShifts();
      }
    }
  }

  /// Auto-clean all shift titles in the database
  /// Removes duplicate consecutive words from event names
  /// Only processes shifts that haven't been cleaned yet
  Future<void> _cleanAllShiftTitles() async {
    try {
      final provider = Provider.of<ShiftProvider>(context, listen: false);
      final shifts = provider.shifts;

      int cleanedCount = 0;

      for (final shift in shifts) {
        if (shift.eventName == null || shift.eventName!.isEmpty) continue;

        // Only process if title has consecutive duplicate words
        final words = shift.eventName!.split(RegExp(r'\s+'));
        bool hasDuplicates = false;

        for (int i = 1; i < words.length; i++) {
          if (words[i].toLowerCase() == words[i - 1].toLowerCase()) {
            hasDuplicates = true;
            break;
          }
        }

        // Skip if already clean
        if (!hasDuplicates) continue;

        final cleanedTitle = _cleanEventTitle(shift.eventName);

        // Only update if the title actually changed
        if (cleanedTitle != shift.eventName) {
          final updatedShift = shift.copyWith(eventName: cleanedTitle);
          await _db.updateShift(updatedShift);
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        // Reload shifts to show cleaned titles
        await provider.loadShifts();
      }
    } catch (e) {
      // Silent fail - don't interrupt the import process
      debugPrint('Error cleaning shift titles: $e');
    }
  }
}
