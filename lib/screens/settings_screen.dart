import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shift_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/tax_service.dart';
import '../services/auth_service.dart';
import '../services/calendar_title_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/google_calendar_service.dart';
import '../theme/app_theme.dart';
import '../models/job.dart';
import '../widgets/hero_card.dart';
import '../widgets/navigation_wrapper.dart';
import '../widgets/field_order_settings.dart';
import 'goals_screen.dart';
import 'login_screen.dart';
import 'calendar_sync_screen.dart';
import 'export_shifts_screen.dart';
import 'add_job_screen.dart';
import 'onboarding_screen.dart';
import 'import_screen.dart';
import 'notification_settings_screen.dart';
import 'job_grouping_screen.dart';
import 'appearance_settings_screen.dart';
import 'event_contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final currencyFormat = NumberFormat.simpleCurrency();

  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _taxEstimate;
  bool _isLoading = true;
  String _selectedState = 'FL';
  bool _isEndedJobsExpanded = false; // Collapsed by default
  bool _isJobsSectionExpanded = false; // MY JOBS collapsed by default
  bool _isTaxSectionExpanded = false; // TAX ESTIMATION collapsed by default
  bool _isAutoSyncEnabled = false; // Calendar auto-sync toggle

  final List<String> _states = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAutoSyncPreference();
  }

  Future<void> _loadAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoSyncEnabled = prefs.getBool('auto_sync_calendar') ?? false;
    });
  }

  Future<void> _setAutoSyncPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_calendar', value);
    setState(() {
      _isAutoSyncEnabled = value;
    });
  }

  Future<void> _loadData() async {
    try {
      final jobs = await _db.getJobs();
      final inactiveJobs = await _db.getInactiveJobs();
      setState(() {
        _jobs = [...jobs, ...inactiveJobs]; // Combine active and inactive
        _isLoading = false;
      });
      _calculateTax();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTax() {
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final yearlyIncome = shiftProvider.shifts
        .where((s) => s.date.year == DateTime.now().year)
        .fold(0.0, (sum, s) => sum + s.totalIncome);

    final estimate = TaxService.calculateTaxes(
      yearlyIncome: yearlyIncome,
      state: _selectedState,
    );

    setState(() => _taxEstimate = estimate);
  }

  Future<void> _addJob() async {
    // Show choice dialog
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Job', style: AppTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add your new job',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Guided Setup option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: AppTheme.primaryGreen),
                ),
                title: Text('Guided Setup', style: AppTheme.bodyLarge),
                subtitle: Text(
                  'Step-by-step onboarding wizard with all options',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textPrimary),
                onTap: () => Navigator.pop(context, 'onboarding'),
              ),

              const SizedBox(height: 8),

              // Quick Add option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flash_on, color: AppTheme.accentBlue),
                ),
                title: Text('Quick Add', style: AppTheme.bodyLarge),
                subtitle: Text(
                  'Manual setup for experienced users',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.textPrimary),
                onTap: () => Navigator.pop(context, 'quick'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'onboarding') {
      // Use guided onboarding
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(isFirstTime: false),
        ),
      );
      if (result == true) {
        _loadData();
      }
    } else {
      // Use quick add
      final result = await Navigator.push<Job>(
        context,
        MaterialPageRoute(builder: (context) => const AddJobScreen()),
      );
      if (result != null) {
        _loadData();
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Sign Out?', style: AppTheme.bodyMedium),
        content: Text('Are you sure you want to sign out?',
            style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: Text('Sign Out', style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      currentTabIndex: null,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          title: Text('Settings',
              style: AppTheme.titleLarge
                  .copyWith(color: AppTheme.adaptiveTextColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: () async {
                setState(() => _isLoading = true);

                // Refresh shift provider data
                final shiftProvider =
                    Provider.of<ShiftProvider>(context, listen: false);
                await shiftProvider.loadShifts();

                // Reload local data
                await _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data refreshed'),
                      backgroundColor: AppTheme.primaryGreen,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Jobs Section - Collapsible
                  _buildSectionHeader('MY JOBS'),
                  const SizedBox(height: 12),
                  _buildJobsTile(),
                  if (_isJobsSectionExpanded) ...[
                    const SizedBox(height: 12),
                    _buildJobsHeroSection(),
                  ],

                  const SizedBox(height: 24),

                  // Event Contacts Section (moved up)
                  _buildSectionHeader('EVENT CONTACTS'),
                  const SizedBox(height: 12),
                  _buildContactsDirectoryTile(),

                  const SizedBox(height: 24),

                  // Notifications Section (moved up)
                  _buildSectionHeader('NOTIFICATIONS'),
                  const SizedBox(height: 12),
                  _buildNotificationsTile(),

                  const SizedBox(height: 24),

                  // Appearance Section (moved up)
                  _buildSectionHeader('APPEARANCE'),
                  const SizedBox(height: 12),
                  _buildAppearanceTile(),

                  const SizedBox(height: 24),

                  // Shift Layout Section
                  _buildSectionHeader('SHIFT LAYOUT'),
                  const SizedBox(height: 12),
                  const FieldOrderSettings(),

                  const SizedBox(height: 24),

                  // Import Data Section
                  _buildSectionHeader('DATA IMPORT'),
                  const SizedBox(height: 12),
                  _buildImportDataTile(),

                  const SizedBox(height: 24),

                  // Schedule Sync Section (moved down)
                  _buildSectionHeader('SCHEDULE SYNC'),
                  const SizedBox(height: 12),
                  _buildScheduleSyncTile(),
                  const SizedBox(height: 8),
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.accentBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.accentBlue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Web version syncs with Google Calendar only. Mobile app supports all device calendars.',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.accentBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.accentBlue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Web version syncs with Google Calendar only. Mobile app supports all device calendars.',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _buildCalendarExportSection(),
                  const SizedBox(height: 8),
                  _buildJobGroupingTile(),

                  const SizedBox(height: 24),

                  // Goals Section
                  _buildSectionHeader('GOALS'),
                  const SizedBox(height: 12),
                  _buildGoalsTile(),

                  const SizedBox(height: 24),

                  // Tax Estimation Section
                  _buildSectionHeader('TAX ESTIMATION'),
                  const SizedBox(height: 12),
                  _buildTaxEstimationTile(),
                  if (_isTaxSectionExpanded) ...[
                    const SizedBox(height: 12),
                    _buildTaxEstimation(),
                  ],

                  const SizedBox(height: 24),

                  // Account Section
                  _buildSectionHeader('ACCOUNT'),
                  const SizedBox(height: 12),
                  _buildAccountSection(),

                  const SizedBox(height: 40),
                ],
              ),
      ), // Close NavigationWrapper child Scaffold
    ); // Close NavigationWrapper
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.labelSmall.copyWith(letterSpacing: 1),
        ),
        if (onAdd != null)
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primaryGreen, size: 20),
            onPressed: onAdd,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildJobsHeroSection() {
    return HeroCard(
      borderRadius: AppTheme.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.work,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY JOBS',
                        style: AppTheme.labelSmall.copyWith(
                          letterSpacing: 1.5,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_jobs.where((j) => j['is_active'] == true).length} ${_jobs.where((j) => j['is_active'] == true).length == 1 ? 'Job' : 'Jobs'}',
                        style: AppTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addJob,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add Job',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.adaptiveTextColor,
                    )),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildJobsList(),
          const SizedBox(height: 20),

          // Inactive Jobs Section (Collapsible)
          if (_jobs
              .where((j) => j['is_active'] == false && j['deleted_at'] == null)
              .isNotEmpty) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _isEndedJobsExpanded = !_isEndedJobsExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      _isEndedJobsExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ended Jobs (${_jobs.where((j) => j['is_active'] == false && j['deleted_at'] == null).length})',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isEndedJobsExpanded) ...[
              const SizedBox(height: 12),
              _buildInactiveJobsList(),
            ],
            const SizedBox(height: 20),
          ],

          // Restore Deleted Jobs button at bottom
          Center(
            child: TextButton.icon(
              onPressed: _showRestoreDeletedJobsDialog,
              icon: const Icon(Icons.restore_from_trash, size: 16),
              label: Text('Restore Deleted Jobs',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.adaptiveTextColor,
                  )),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportDataTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImportScreen()),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.upload_file, color: AppTheme.primaryGreen),
        ),
        title: Text('Import Shift Data', style: AppTheme.bodyMedium),
        subtitle: Text(
          'Upload CSV/Excel from your old tip tracking app',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildNotificationsTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen()),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(Icons.notifications_outlined, color: AppTheme.primaryGreen),
        ),
        title: Text('Notification Preferences', style: AppTheme.bodyMedium),
        subtitle: Text(
          'Shift reminders, earnings prompts, and alerts',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildScheduleSyncTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarSyncScreen()),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_month, color: AppTheme.accentBlue),
        ),
        title: Text('Import from Calendar', style: AppTheme.bodyMedium),
        subtitle: Text(
          'Sync shifts from Hot Schedules, 7shifts, etc.',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildJobsList() {
    // Filter to show ONLY active jobs (not ended)
    final activeJobs = _jobs.where((j) => j['is_active'] == true).toList();

    if (activeJobs.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.textMuted.withOpacity(0.2),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.work_outline,
                  size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No jobs added yet',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first job to start tracking shifts',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: activeJobs.asMap().entries.map((entry) {
        final index = entry.key;
        final job = entry.value;
        final isDefault = job['is_default'] == true;
        final employer = job['employer'] as String?;
        final industry = job['industry'] as String?;
        final baseRate = job['hourly_rate'] ?? 0;

        return Container(
          margin: EdgeInsets.only(top: index > 0 ? 12 : 0),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: isDefault
                ? Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editJob(job),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Job name and action menu
                    Row(
                      children: [
                        // Job name and default badge
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  job['name'] ?? 'Unknown',
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star,
                                          color: AppTheme.primaryGreen,
                                          size: 11),
                                      const SizedBox(width: 3),
                                      Text(
                                        'DEFAULT',
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Compact action menu
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                          color: AppTheme.cardBackground,
                          offset: const Offset(0, 40),
                          onSelected: (value) async {
                            if (value == 'end') {
                              _confirmEndJob(job);
                            } else if (value == 'archive') {
                              _confirmDeleteJob(job);
                            } else if (value == 'default') {
                              await _db.setDefaultJob(job['id']);
                              _loadData();
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isDefault)
                              PopupMenuItem(
                                value: 'default',
                                child: Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: AppTheme.primaryGreen, size: 18),
                                    const SizedBox(width: 12),
                                    Text('Set as Default',
                                        style: AppTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'end',
                              child: Row(
                                children: [
                                  Icon(Icons.work_off_outlined,
                                      color: AppTheme.accentOrange, size: 18),
                                  const SizedBox(width: 12),
                                  Text('End Job', style: AppTheme.bodyMedium),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(Icons.archive_outlined,
                                      color: AppTheme.accentYellow, size: 18),
                                  const SizedBox(width: 12),
                                  Text('Archive Job',
                                      style: AppTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Job details row
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        // Hourly rate
                        _buildJobDetailChip(
                          icon: Icons.attach_money,
                          label: '${currencyFormat.format(baseRate)}/hr',
                          color: AppTheme.primaryGreen,
                        ),
                        // Employer
                        if (employer != null && employer.isNotEmpty)
                          _buildJobDetailChip(
                            icon: Icons.business,
                            label: employer,
                            color: AppTheme.accentBlue,
                          ),
                        // Industry
                        if (industry != null && industry.isNotEmpty)
                          _buildJobDetailChip(
                            icon: Icons.category_outlined,
                            label: industry,
                            color: AppTheme.textMuted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJobDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: color == AppTheme.textMuted
                    ? AppTheme.textSecondary
                    : color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editJob(Map<String, dynamic> jobData) async {
    final job = Job.fromSupabase(jobData);
    final result = await Navigator.push<Job>(
      context,
      MaterialPageRoute(
        builder: (context) => AddJobScreen(existingJob: job),
      ),
    );

    if (result != null) {
      _loadData();
    }
  }

  Widget _buildInactiveJobsList() {
    final inactiveJobs = _jobs
        .where((j) => j['is_active'] == false && j['deleted_at'] == null)
        .toList();
    final currencyFormat = NumberFormat.simpleCurrency();

    return Column(
      children: inactiveJobs.map((job) {
        final String name = job['name'] ?? '';
        final String? employer = job['employer'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.textMuted.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Reactivate button
              IconButton(
                icon:
                    Icon(Icons.restore, size: 20, color: AppTheme.primaryGreen),
                onPressed: () => _confirmReactivateJob(job),
                tooltip: 'Reactivate job',
                padding: const EdgeInsets.all(12),
              ),
              // Main job info area
              Expanded(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.work_off,
                      color: AppTheme.textMuted,
                      size: 24,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ENDED',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(job['hourly_rate'] ?? 0)}/hr',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (employer != null && employer.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          employer,
                          style: AppTheme.labelSmall
                              .copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmReactivateJob(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Reactivate Job?', style: AppTheme.titleMedium),
        content: Text(
          'Mark "${job['name']}" as active again?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text('Reactivate', style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.reactivateJob(job['id']);

        if (mounted) {
          await Provider.of<ShiftProvider>(context, listen: false).loadShifts();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job "${job['name']}" reactivated.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reactivating job: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildGoalsTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.flag, color: AppTheme.accentBlue),
        ),
        title: Text('Income Goals', style: AppTheme.bodyMedium),
        subtitle: Text('Set and track your earnings targets',
            style: AppTheme.bodyMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildContactsDirectoryTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.contacts, color: AppTheme.accentPurple),
        ),
        title: Text('Event Contacts', style: AppTheme.bodyMedium),
        subtitle:
            Text('Vendors, DJs, planners & more', style: AppTheme.bodyMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventContactsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildTaxEstimation() {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final yearlyIncome = shiftProvider.shifts
        .where((s) => s.date.year == DateTime.now().year)
        .fold(0.0, (sum, s) => sum + s.totalIncome);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${DateTime.now().year} ESTIMATED TAXES',
                  style: AppTheme.labelSmall),
              DropdownButton<String>(
                value: _selectedState,
                dropdownColor: AppTheme.cardBackgroundLight,
                style: AppTheme.bodyMedium,
                iconEnabledColor: AppTheme.textPrimary,
                underline: const SizedBox(),
                items: _states
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: AppTheme.bodyMedium),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedState = value);
                    _calculateTax();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YTD Income', style: AppTheme.bodyMedium),
              Text(currencyFormat.format(yearlyIncome),
                  style: AppTheme.titleMedium),
            ],
          ),
          Divider(height: 24, color: AppTheme.cardBackgroundLight),
          if (_taxEstimate != null) ...[
            _buildTaxRow('Federal Tax', _taxEstimate!['federal']),
            _buildTaxRow('State Tax ($_selectedState)', _taxEstimate!['state']),
            _buildTaxRow('Social Security', _taxEstimate!['socialSecurity']),
            _buildTaxRow('Medicare', _taxEstimate!['medicare']),
            Divider(height: 24, color: AppTheme.cardBackgroundLight),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Estimated Tax', style: AppTheme.titleMedium),
                Text(
                  currencyFormat.format(_taxEstimate!['total']),
                  style:
                      AppTheme.titleMedium.copyWith(color: AppTheme.accentRed),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Effective Rate', style: AppTheme.bodyMedium),
                Text(
                  '${((_taxEstimate!['effectiveRate'] ?? 0) * 100).toStringAsFixed(1)}%',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.accentBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set aside ${currencyFormat.format((_taxEstimate!['total'] ?? 0) / 12)}/month for taxes',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.accentBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double? amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(currencyFormat.format(amount ?? 0), style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildJobsTile() {
    final activeJobsCount = _jobs.where((j) => j['is_active'] == true).length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _isJobsSectionExpanded = !_isJobsSectionExpanded;
          });
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.work, color: AppTheme.primaryGreen),
        ),
        title: Text('My Jobs', style: AppTheme.bodyMedium),
        subtitle: Text(
          '$activeJobsCount active ${activeJobsCount == 1 ? 'job' : 'jobs'}',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(
          _isJobsSectionExpanded ? Icons.expand_less : Icons.chevron_right,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildTaxEstimationTile() {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final yearlyIncome = shiftProvider.shifts
        .where((s) => s.date.year == DateTime.now().year)
        .fold(0.0, (sum, s) => sum + s.totalIncome);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _isTaxSectionExpanded = !_isTaxSectionExpanded;
          });
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance, color: AppTheme.accentRed),
        ),
        title: Text('Tax Estimation', style: AppTheme.bodyMedium),
        subtitle: Text(
          'YTD Income: ${currencyFormat.format(yearlyIncome)}',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(
          _isTaxSectionExpanded ? Icons.expand_less : Icons.chevron_right,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildAppearanceTile() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.palette, color: AppTheme.primaryGreen),
        ),
        title: Text('Theme & Background', style: AppTheme.bodyMedium),
        subtitle: Text(
          'Customize your app appearance',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildAccountSection() {
    final user = AuthService.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
              child: Text(
                (user?.email?.substring(0, 1) ?? 'U').toUpperCase(),
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
            title: Text(user?.email ?? 'Unknown', style: AppTheme.bodyMedium),
            subtitle: Text('Logged in', style: AppTheme.bodyMedium),
          ),
          Divider(height: 1, color: AppTheme.cardBackgroundLight),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.accentRed),
            title:
                Text('Sign Out', style: TextStyle(color: AppTheme.accentRed)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteJob(Map<String, dynamic> job) async {
    bool deleteShiftData = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Delete Job?', style: AppTheme.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${job['name']}"?',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentYellow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.archive,
                      color: AppTheme.accentYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This job will be archived. You can restore it within 30 days.',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: AppTheme.cardBackgroundLight),
              const SizedBox(height: 12),
              Text(
                'What about your shift data?',
                style:
                    AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    deleteShiftData = !deleteShiftData;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: deleteShiftData,
                      onChanged: (value) {
                        setState(() {
                          deleteShiftData = value ?? false;
                        });
                      },
                      activeColor: AppTheme.accentRed,
                    ),
                    Expanded(
                      child: Text(
                        'Also remove shifts and statistics associated with this job',
                        style: AppTheme.bodyMedium.copyWith(
                          color: deleteShiftData
                              ? AppTheme.accentYellow
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (deleteShiftData) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentYellow.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentYellow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will remove shifts and statistics from tax calculations and historical data. Restorable for 30 days.',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.accentYellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!deleteShiftData) ...[
                const SizedBox(height: 8),
                Text(
                  'Your shifts will remain in tax calculations and historical records.',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                // Store the deleteShiftData value before popping
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: deleteShiftData
                    ? AppTheme.accentYellow
                    : AppTheme.accentYellow,
                foregroundColor: Colors.black,
              ),
              child: Text(deleteShiftData ? 'Archive All' : 'Archive Job'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        if (deleteShiftData) {
          // Archive job AND shifts (both hidden from stats)
          await _db.deleteJobAndShifts(job['id']);
        } else {
          // Archive job only (shifts remain visible)
          await _db.deleteJob(job['id']);
        }

        // Reload shifts in the provider so dashboard updates
        if (mounted) {
          await Provider.of<ShiftProvider>(context, listen: false).loadShifts();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                deleteShiftData
                    ? 'Job "${job['name']}" and all shifts archived. Restore within 30 days.'
                    : 'Job "${job['name']}" archived. Shifts preserved. Restore within 30 days.',
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmEndJob(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('End Job?', style: AppTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark "${job['name']}" as ended?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentOrange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This job will be removed from your active job list, but all historical shifts and statistics will remain.',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Perfect for promotions, job changes, or when you stop working a gig.',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('End Job', style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deactivateJob(job['id']);

        // Reload shifts and jobs
        if (mounted) {
          await Provider.of<ShiftProvider>(context, listen: false).loadShifts();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Job "${job['name']}" marked as ended. All historical data preserved.',
              ),
              backgroundColor: AppTheme.accentOrange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ending job: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRestoreDeletedJobsDialog() async {
    try {
      final deletedJobs = await _db.getDeletedJobs();

      if (!mounted) return;

      if (deletedJobs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No archived jobs to restore'),
            backgroundColor: AppTheme.textMuted,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Restore Archived Jobs', style: AppTheme.titleMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: deletedJobs.length,
              itemBuilder: (context, index) {
                final job = deletedJobs[index];
                final deletedAt = DateTime.parse(job['deleted_at']);
                final daysAgo = DateTime.now().difference(deletedAt).inDays;

                return ListTile(
                  leading: Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                          int.parse(job['color'].replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: Text(job['name'], style: AppTheme.bodyLarge),
                  subtitle: Text(
                    'Deleted $daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago • ${30 - daysAgo} days left',
                    style:
                        AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await _db.restoreJob(job['id']);

                        // Reload shifts in the provider so dashboard updates
                        if (context.mounted) {
                          await Provider.of<ShiftProvider>(context,
                                  listen: false)
                              .loadShifts();
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Job "${job['name']}" restored'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                        _loadData();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error restoring job: $e'),
                              backgroundColor: AppTheme.accentRed,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('Restore', style: AppTheme.bodyMedium),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: AppTheme.bodyMedium),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading archived jobs: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildJobGroupingTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        onTap: () async {
          // Get all shifts to analyze calendar titles
          final provider = Provider.of<ShiftProvider>(context, listen: false);
          final titleService = CalendarTitleService();
          final calendarTitles =
              titleService.extractCalendarTitles(provider.shifts);

          if (calendarTitles.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No calendar shifts found to group'),
                backgroundColor: AppTheme.accentYellow,
              ),
            );
            return;
          }

          // Show job grouping screen
          final groups = await Navigator.push<List<Map<String, dynamic>>>(
            context,
            MaterialPageRoute(
              builder: (context) => JobGroupingScreen(
                calendarTitles: calendarTitles,
              ),
            ),
          );

          // Save the groups if user created any
          if (groups != null && groups.isNotEmpty && mounted) {
            await titleService.saveJobGroups(groups);
            await provider.loadShifts();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Job groups saved successfully'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.group_work, color: AppTheme.primaryGreen),
        ),
        title: Text('Group Calendar Jobs', style: AppTheme.bodyMedium),
        subtitle: Text(
          'Combine duplicate job titles from your calendar',
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildCalendarExportSection() {
    return Column(
      children: [
        // Auto-sync toggle card
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.sync, color: AppTheme.primaryGreen),
            ),
            title: Text('Auto-Sync to Calendar', style: AppTheme.bodyMedium),
            subtitle: Text(
              kIsWeb
                  ? 'Automatically export new shifts to Google Calendar'
                  : 'Automatically export new shifts to your device calendar',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            trailing: Switch(
              value: _isAutoSyncEnabled,
              activeColor: AppTheme.primaryGreen,
              onChanged: _setAutoSyncPreference,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Sync actions card
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              // Choose shifts to sync
              ListTile(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ExportShiftsScreen(isRemoveMode: false),
                    ),
                  );
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(kIsWeb
                            ? 'Shifts synced to Google Calendar'
                            : 'Shifts synced to calendar'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle_outline,
                      color: AppTheme.accentBlue),
                ),
                title:
                    Text('Choose Shifts to Sync', style: AppTheme.bodyMedium),
                subtitle: Text(
                  kIsWeb
                      ? 'Select specific shifts to export to Google Calendar'
                      : 'Select specific shifts to export to your calendar',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),

              // Sync all shifts now
              ListTile(
                onTap: () => _syncAllShifts(),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flash_on, color: AppTheme.accentYellow),
                ),
                title: Text('Sync All Shifts Now', style: AppTheme.bodyMedium),
                subtitle: Text(
                  kIsWeb
                      ? 'Export all unsynced shifts to Google Calendar'
                      : 'Export all unsynced shifts to your calendar',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Unsync actions card
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              // Unsync specific events
              ListTile(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ExportShiftsScreen(isRemoveMode: true),
                    ),
                  );
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(kIsWeb
                            ? 'Events removed from Google Calendar'
                            : 'Events removed from calendar'),
                        backgroundColor: AppTheme.accentOrange,
                      ),
                    );
                  }
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove_circle_outline,
                      color: AppTheme.accentOrange),
                ),
                title:
                    Text('Unsync Specific Events', style: AppTheme.bodyMedium),
                subtitle: Text(
                  kIsWeb
                      ? 'Choose synced shifts to remove from Google Calendar'
                      : 'Choose synced shifts to remove from your calendar',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),

              // Remove all synced events
              ListTile(
                onTap: () => _removeAllSyncedEvents(),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber, color: AppTheme.accentRed),
                ),
                title: Text('Unsync All Events',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.accentRed)),
                subtitle: Text(
                  kIsWeb
                      ? 'Remove all synced shifts from Google Calendar'
                      : 'Remove all synced shifts from your calendar',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _syncAllShifts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Sync All Shifts?', style: AppTheme.titleLarge),
        content: Text(
          'This will export all unsynced shifts to your calendar. Continue?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Sync All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final unsyncedShifts =
          shiftProvider.shifts.where((s) => s.calendarEventId == null).toList();

      int successCount = 0;
      final calendarSync = CalendarSyncService();
      final googleCalendar = GoogleCalendarService();

      for (final shift in unsyncedShifts) {
        String? eventId;
        if (kIsWeb) {
          eventId = await googleCalendar.exportShiftToCalendar(shift);
        } else {
          eventId = await calendarSync.exportShiftToCalendar(shift);
        }

        if (eventId != null) {
          final updatedShift = shift.copyWith(calendarEventId: eventId);
          await _db.updateShift(updatedShift);
          successCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount shifts exported to calendar'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing shifts: $e')),
        );
      }
    }
  }

  Future<void> _removeAllSyncedEvents() async {
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final syncedCount =
        shiftProvider.shifts.where((s) => s.calendarEventId != null).length;

    if (syncedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No synced events to remove')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Remove All Synced Events?', style: AppTheme.titleLarge),
        content: Text(
          'This will delete $syncedCount calendar events. This action cannot be undone. Continue?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    try {
      final syncedShifts =
          shiftProvider.shifts.where((s) => s.calendarEventId != null).toList();

      int successCount = 0;
      final calendarSync = CalendarSyncService();
      final googleCalendar = GoogleCalendarService();

      for (final shift in syncedShifts) {
        bool success;
        if (kIsWeb) {
          success =
              await googleCalendar.deleteCalendarEvent(shift.calendarEventId!);
        } else {
          success = await calendarSync.deleteCalendarEvent(
              'primary', shift.calendarEventId!);
        }

        if (success) {
          final updatedShift = shift.copyWith(calendarEventId: null);
          await _db.updateShift(updatedShift);
          successCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount calendar events removed'),
            backgroundColor: AppTheme.accentOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing events: $e')),
        );
      }
    }
  }
}
