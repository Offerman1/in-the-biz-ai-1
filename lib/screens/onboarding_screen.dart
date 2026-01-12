import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/industry_template.dart';
import '../models/industry_data.dart';
import '../models/job.dart';
import '../models/job_template.dart';
import '../models/shift.dart';
import 'dashboard_screen.dart';
import 'onboarding_import_welcome_screen.dart';
import 'calendar_sync_screen.dart';
import 'job_grouping_screen.dart';

/// Onboarding screen that can be used for first-time setup or adding new jobs
class OnboardingScreen extends StatefulWidget {
  /// If true, this is the first time setup (shows welcome, requires industry)
  /// If false, this is for adding a new job (can skip more, returns to previous screen)
  final bool isFirstTime;

  const OnboardingScreen({
    super.key,
    this.isFirstTime = true,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Total pages: Welcome, Import, Industry, Jobs, Template, Goals, Confirmation
  static const int _totalPages = 7;

  // User selections
  String? _selectedIndustry;

  // Imported jobs from calendar/CSV
  Map<String, String> _importedJobs = {}; // jobTitle -> jobId
  List<dynamic>? _importedEvents; // Store calendar events for later import

  // Multi-job selection - Map of job name to (hourlyRate, template)
  final Map<String, JobEntry> _selectedJobs = {};

  // Custom jobs added by user
  final List<JobTypeTemplate> _customJobs = [];

  // Goals - Map of goal type to amount (null means disabled)
  final Map<String, double?> _goalAmounts = {
    'daily': null,
    'weekly': null,
    'monthly': null,
    'yearly': null,
  };

  // Controllers for goal inputs
  final Map<String, TextEditingController> _goalControllers = {
    'daily': TextEditingController(),
    'weekly': TextEditingController(),
    'monthly': TextEditingController(),
    'yearly': TextEditingController(),
  };

  List<IndustryTemplate> _industries = [];
  bool _isLoading = true;
  bool _isCompletingSetup = false; // Loading state for final setup

  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadIndustries();
  }

  @override
  void dispose() {
    _goalControllers.forEach((key, controller) => controller.dispose());
    _pageController.dispose();
    super.dispose();
  }

  /// Load industries from IndustryData (NOT database)
  void _loadIndustries() {
    try {
      // Create IndustryTemplate objects from IndustryData
      final templates = <IndustryTemplate>[];
      for (final industryKey in IndustryData.industries) {
        // Get job titles for this industry from IndustryData
        final jobTitles = IndustryData.getJobTitles(industryKey);

        // Convert to JobTypeTemplate objects with default rate of $15/hr
        final jobTypes = jobTitles
            .map((title) => JobTypeTemplate(name: title, rate: 15.0))
            .toList();

        templates.add(IndustryTemplate(
          id: industryKey, // Use industry name as ID
          industry: industryKey,
          displayName: industryKey,
          icon: _getIconKeyForIndustry(industryKey),
          defaultJobTypes: jobTypes,
          tipStructure: 'individual',
        ));
      }

      setState(() {
        _industries = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Map industry name to icon string
  String? _getIconKeyForIndustry(String industry) {
    switch (industry) {
      case 'Restaurant/Bar/Nightclub':
        return 'restaurant';
      case 'Construction/Trades':
        return 'construction';
      case 'Freelancer/Consultant':
        return 'freelancer';
      case 'Healthcare':
        return 'local_hospital';
      case 'Rideshare & Delivery':
        return 'delivery_dining';
      case 'Music & Entertainment':
        return 'celebration';
      case 'Artist & Crafts':
        return 'palette';
      case 'Retail/Sales':
        return 'store';
      case 'Salon/Spa':
        return 'spa';
      case 'Hospitality':
        return 'hotel';
      case 'Fitness':
        return 'fitness_center';
      default:
        return null;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skipOnboarding() async {
    try {
      // Mark onboarding complete without creating any jobs
      await _db.completeOnboarding();

      if (!mounted) return;

      // Navigate to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Prevent multiple submissions
    if (_isCompletingSetup) return;

    setState(() => _isCompletingSetup = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Create all selected jobs ONLY if they weren't imported from calendar
      // Calendar-imported jobs are already created in the job grouping screen
      if (_importedJobs.isEmpty) {
        bool isFirst = true;
        for (final entry in _selectedJobs.entries) {
          final jobEntry = entry.value;

          final job = Job(
            id: '', // Database will generate UUID
            userId: user.id,
            name: entry.key,
            industry: _selectedIndustry,
            hourlyRate: jobEntry.hourlyRate,
            isDefault: isFirst &&
                widget.isFirstTime, // First job is default only on first setup
            template: jobEntry.template,
            employer: jobEntry.employer,
          );
          await _db.createJob(job);
          isFirst = false;
        }
      }

      // Create goals for each enabled type
      for (final goalEntry in _goalAmounts.entries) {
        if (goalEntry.value != null && goalEntry.value! > 0) {
          await _db.createGoal(
            type: goalEntry.key,
            targetAmount: goalEntry.value!,
          );
        }
      }

      // Mark onboarding complete only on first time
      if (widget.isFirstTime) {
        await _db.completeOnboarding();
      }

      // If we have imported jobs from calendar, import the shifts now
      if (_importedJobs.isNotEmpty && _importedEvents != null) {
        await _importCalendarShifts(_importedEvents!, _importedJobs);
      }

      if (!mounted) return;

      if (widget.isFirstTime) {
        // First time: go to dashboard (skip import welcome if we already imported)
        if (_importedJobs.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          // No import: go to import welcome screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const OnboardingImportWelcomeScreen()),
          );
        }
      } else {
        // Adding new job from settings: go to dashboard if importing, otherwise back to settings
        if (_importedJobs.isNotEmpty) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _isCompletingSetup = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup error: $e')),
        );
      }
    }
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0: // Welcome
        return true;
      case 1: // Import Data
        return true; // Import is optional
      case 2: // Industry
        return _selectedIndustry != null;
      case 3: // Jobs
        return _selectedJobs.isNotEmpty;
      case 4: // Template
        return true; // Templates have defaults
      case 5: // Goals
        return true; // Goals are optional
      case 6: // Confirmation
        return _selectedJobs.isNotEmpty;
      default:
        return true;
    }
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Welcome';
      case 1:
        return 'Import Data';
      case 2:
        return 'Industry';
      case 3:
        return 'Jobs';
      case 4:
        return 'Customize';
      case 5:
        return 'Goals';
      case 6:
        return 'Review';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      resizeToAvoidBottomInset: true, // Allow resize when keyboard appears
      appBar: !widget.isFirstTime
          ? AppBar(
              backgroundColor: AppTheme.darkBackground,
              title: Text(_getPageTitle(), style: AppTheme.titleLarge),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator (6 pages)
            Padding(
              padding: EdgeInsets.all(widget.isFirstTime ? 20 : 16),
              child: Row(
                children: List.generate(
                    _totalPages,
                    (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index <= _currentPage
                                  ? AppTheme.primaryGreen
                                  : AppTheme.cardBackgroundLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildImportDataPage(), // NEW: Page 1
                  _buildIndustryPage(),
                  _buildJobPage(),
                  _buildTemplatePage(),
                  _buildGoalPage(),
                  _buildConfirmationPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text('Back',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  const Spacer(),

                  // Skip button on welcome page (first time only)
                  if (_currentPage == 0 && widget.isFirstTime)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text('Skip',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  // Skip button (for optional pages)
                  if (_currentPage == 4 ||
                      _currentPage == 5) // Template & Goals (shifted by +1)
                    TextButton(
                      onPressed: _nextPage,
                      child: Text('Skip',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  if (_currentPage == 0 ||
                      _currentPage == 4 ||
                      _currentPage == 5)
                    const SizedBox(width: 8),

                  ElevatedButton(
                    onPressed: _canContinue() && !_isCompletingSetup
                        ? (isLastPage ? _completeOnboarding : _nextPage)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.cardBackgroundLight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: _isCompletingSetup
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            isLastPage
                                ? (widget.isFirstTime
                                    ? (_importedEvents != null &&
                                            _importedEvents!.isNotEmpty
                                        ? "Complete Setup"
                                        : "Let's Go!")
                                    : "Complete Setup")
                                : 'Continue',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppTheme.primaryGreen,
                    BlendMode.modulate,
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to\nIn The Biz',
              style:
                  AppTheme.headlineLarge.copyWith(color: AppTheme.primaryGreen),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI-powered financial companion for the service industry',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildFeatureItem(Icons.camera_alt, 'Scan receipts & BEOs'),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.chat_bubble, 'AI assistant for insights'),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.trending_up, 'Track income & goals'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 24),
        const SizedBox(width: 12),
        Text(text, style: AppTheme.bodyMedium),
      ],
    );
  }

  Widget _buildImportDataPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download, size: 80, color: AppTheme.primaryGreen),
            const SizedBox(height: 32),
            Text(
              'Import Your Work History',
              style:
                  AppTheme.headlineLarge.copyWith(color: AppTheme.primaryGreen),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect your calendar or import a file to get started quickly',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Calendar button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 24),
                label: const Text('Connect Calendar',
                    style: TextStyle(fontSize: 16)),
                onPressed: _startCalendarImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CSV button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, size: 24),
                label: const Text('Import CSV File',
                    style: TextStyle(fontSize: 16)),
                onPressed: _startCsvImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardBackground,
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: _skipImport,
              child: Text(
                'Skip - I\'ll add shifts manually',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCalendarImport() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarSyncScreen(
          isOnboarding: true,
          onImportComplete: (jobMapping) {
            setState(() {
              _importedJobs = jobMapping;
            });
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Show loading indicator while processing
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
        );
      }

      // Extract jobs, mapping, and events from calendar sync
      final List<Job> jobs = result['jobs'] as List<Job>? ?? [];
      final Map<String, String> mapping =
          result['mapping'] as Map<String, String>? ?? {};
      final List<dynamic>? events = result['events'] as List<dynamic>?;

      setState(() {
        _importedJobs = mapping;
        _importedEvents = events; // Store events for later import

        // Populate _selectedJobs with the created jobs
        for (final job in jobs) {
          _selectedJobs[job.name] = JobEntry(
            hourlyRate: job.hourlyRate,
            template: job.template,
            employer: job.employer,
          );
        }
      });

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Jump directly to Template page (page 4) - skip Industry and Jobs pages
      _pageController.jumpToPage(4);
      setState(() => _currentPage = 4);
    }
  }

  void _startCsvImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  const SizedBox(height: 16),
                  Text('Parsing CSV...', style: AppTheme.bodyMedium),
                ],
              ),
            ),
          ),
        );

        // Parse CSV
        String csvContent;
        if (file.bytes != null) {
          csvContent = utf8.decode(file.bytes!);
        } else {
          throw Exception('Could not read file');
        }

        final lines = csvContent.split('\n');
        if (lines.isEmpty) {
          throw Exception('CSV file is empty');
        }

        // Parse header
        final headers =
            lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();

        // Find column indices
        final dateIdx = headers.indexWhere((h) => h.contains('date'));
        final jobIdx = headers.indexWhere((h) =>
            h.contains('job') || h.contains('title') || h.contains('position'));
        final hoursIdx = headers.indexWhere((h) => h.contains('hour'));
        final tipsIdx = headers.indexWhere((h) => h.contains('tip'));
        final wageIdx = headers.indexWhere((h) =>
            h.contains('wage') || h.contains('pay') || h.contains('earning'));

        if (dateIdx == -1) {
          throw Exception('CSV must have a date column');
        }

        // Parse rows and extract unique job titles
        final uniqueJobTitles = <String>[];
        final parsedShifts = <Map<String, dynamic>>[];

        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final values = line.split(',');
          if (values.length <= dateIdx) continue;

          final jobTitle = jobIdx >= 0 && values.length > jobIdx
              ? values[jobIdx].trim()
              : 'Imported Job';

          final cleanJobTitle = jobTitle.isEmpty ? 'Imported Job' : jobTitle;

          if (!uniqueJobTitles.contains(cleanJobTitle)) {
            uniqueJobTitles.add(cleanJobTitle);
          }

          parsedShifts.add({
            'date': values[dateIdx].trim(),
            'job': cleanJobTitle,
            'hours': hoursIdx >= 0 && values.length > hoursIdx
                ? double.tryParse(values[hoursIdx].trim()) ?? 0
                : 0,
            'tips': tipsIdx >= 0 && values.length > tipsIdx
                ? double.tryParse(values[tipsIdx].trim()) ?? 0
                : 0,
            'wages': wageIdx >= 0 && values.length > wageIdx
                ? double.tryParse(values[wageIdx].trim()) ?? 0
                : 0,
          });
        }

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (parsedShifts.isEmpty) {
          throw Exception('No valid shifts found in CSV');
        }

        // Convert job titles to the format JobGroupingScreen expects
        // Count occurrences of each job title
        final jobCounts = <String, int>{};
        for (final shift in parsedShifts) {
          final job = shift['job'] as String;
          jobCounts[job] = (jobCounts[job] ?? 0) + 1;
        }
        final calendarTitles = jobCounts.entries
            .map((e) => {'title': e.key, 'count': e.value})
            .toList();

        // Navigate to JobGroupingScreen to let user organize jobs
        if (mounted) {
          final groupingResult = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => JobGroupingScreen(
                calendarTitles: calendarTitles,
              ),
            ),
          );

          if (groupingResult != null && groupingResult.isNotEmpty) {
            // Extract jobs and mapping from grouping result
            final List<Job> jobs = groupingResult['jobs'] as List<Job>? ?? [];
            final Map<String, String> mapping =
                groupingResult['mapping'] as Map<String, String>? ?? {};

            // Store the mapping and jobs
            setState(() {
              _importedJobs = mapping;

              // Convert parsed shifts to event format for later import
              _importedEvents = parsedShifts
                  .map((s) => {
                        'title': s['job'],
                        'start': DateTime.tryParse(s['date']) ?? DateTime.now(),
                        'end': DateTime.tryParse(s['date']) ?? DateTime.now(),
                        'hours': s['hours'],
                        'tips': s['tips'],
                        'wages': s['wages'],
                      })
                  .toList();

              // Populate _selectedJobs with the created jobs
              for (final job in jobs) {
                _selectedJobs[job.name] = JobEntry(
                  hourlyRate: job.hourlyRate,
                  template: job.template,
                  employer: job.employer,
                );
              }
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Ready to import ${parsedShifts.length} shifts into ${jobs.length} job(s)!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );

              // Jump to template customization page
              _pageController.jumpToPage(4);
              setState(() => _currentPage = 4);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Try to close loading dialog if it's open
        try {
          Navigator.pop(context);
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing CSV: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  void _skipImport() {
    _nextPage(); // Go to industry selection
  }

  Widget _buildIndustryPage() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What industry are you in?', style: AppTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'This helps us customize your experience',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _industries.length,
              itemBuilder: (context, index) {
                final industry = _industries[index];
                final isSelected = _selectedIndustry == industry.industry;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndustry = industry.industry;
                      // Clear selections when changing industry
                      _selectedJobs.clear();
                      _customJobs.clear();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.2)
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIndustryIcon(industry.icon),
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            industry.displayName,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }

  IconData _getIndustryIcon(String? icon) {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_bar':
        return Icons.local_bar;
      case 'spa':
        return Icons.spa;
      case 'store':
        return Icons.store;
      case 'hotel':
        return Icons.hotel;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'celebration':
        return Icons.celebration;
      case 'coffee':
        return Icons.coffee;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.work;
    }
  }

  Widget _buildJobPage() {
    final selectedIndustryTemplate =
        _industries.where((i) => i.industry == _selectedIndustry).firstOrNull;

    final jobTypes = [
      ...selectedIndustryTemplate?.defaultJobTypes ?? [],
      ..._customJobs,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s your role?', style: AppTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Select all that apply - you can have multiple roles!',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Job type selection - multi-select with chips
          if (jobTypes.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: jobTypes.map((job) {
                final isSelected = _selectedJobs.containsKey(job.name);
                return FilterChip(
                  label: Text(job.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedJobs[job.name] = JobEntry(
                          hourlyRate: job.rate,
                          template: _getTemplateForIndustry(_selectedIndustry),
                        );
                      } else {
                        _selectedJobs.remove(job.name);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  backgroundColor: AppTheme.cardBackground,
                  checkmarkColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Add custom job button
          OutlinedButton.icon(
            onPressed: () => _showCustomJobDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Role'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: BorderSide(color: AppTheme.cardBackgroundLight),
            ),
          ),

          const SizedBox(height: 24),

          // Hourly rates for selected jobs
          if (_selectedJobs.isNotEmpty) ...[
            Text('Set Hourly Rates', style: AppTheme.titleMedium),
            const SizedBox(height: 12),
            // Use Column instead of ListView since we're already in SingleChildScrollView
            ..._selectedJobs.entries.map((entry) {
              return _buildJobRateSlider(entry.key, entry.value.hourlyRate);
            }),
          ] else ...[
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Icon(Icons.touch_app, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Tap jobs above to select them',
                    style:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ],
      ),
    );
  }

  void _showCustomJobDialog() {
    final controller = TextEditingController();
    final rateController = TextEditingController(text: '15');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Add Custom Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Job title (e.g., Manager, Cocktail Server)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Hourly rate (e.g., 15.00)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final rate = double.tryParse(rateController.text) ?? 15.0;
                setState(() {
                  // Add to custom jobs list so it shows in chips
                  _customJobs
                      .add(JobTypeTemplate(name: controller.text, rate: rate));
                  // Also select it automatically
                  _selectedJobs[controller.text] = JobEntry(
                    hourlyRate: rate,
                    template: _getTemplateForIndustry(_selectedIndustry),
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  JobTemplate _getTemplateForIndustry(String? industry) {
    switch (industry) {
      case 'Restaurant/Bar/Nightclub':
        return JobTemplate.restaurant();
      case 'Construction/Trades':
        return JobTemplate.construction();
      case 'Freelancer/Consultant':
        return JobTemplate.freelancer();
      case 'Healthcare':
        return JobTemplate.healthcare();
      case 'Gig Worker':
        return JobTemplate.gigWorker();
      case 'Rideshare & Delivery':
        return JobTemplate.rideshareDelivery();
      case 'Music & Entertainment':
        return JobTemplate.musicEntertainment();
      case 'Artist & Crafts':
        return JobTemplate.artistCrafts();
      case 'Retail/Sales':
        return JobTemplate.retail();
      case 'Salon/Spa':
        return JobTemplate.salon();
      case 'Hospitality':
        return JobTemplate.hospitality();
      case 'Fitness':
        return JobTemplate.fitness();
      default:
        return JobTemplate();
    }
  }

  Widget _buildJobRateSlider(String jobName, double rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              Text(jobName, style: AppTheme.bodyLarge),
              SizedBox(
                width: 100,
                child: _JobRateTextField(
                  initialRate: rate,
                  onRateChanged: (newRate) {
                    final entry = _selectedJobs[jobName];
                    if (entry != null) {
                      setState(() {
                        _selectedJobs[jobName] = JobEntry(
                          hourlyRate: newRate,
                          template: entry.template,
                        );
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: rate.clamp(0.0, 75.0),
            min: 0,
            max: 75,
            divisions: 75, // $1 increments
            activeColor: AppTheme.primaryGreen,
            inactiveColor: AppTheme.cardBackgroundLight,
            onChangeStart: (_) {
              // Unfocus text field when slider starts moving
              FocusScope.of(context).unfocus();
            },
            onChanged: (value) {
              setState(() {
                final entry = _selectedJobs[jobName];
                if (entry != null) {
                  _selectedJobs[jobName] = JobEntry(
                    hourlyRate: value,
                    template: entry.template,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  /// Build template customization page for each job
  Widget _buildTemplatePage() {
    if (_selectedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No jobs selected', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Go back and select at least one job',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: _selectedJobs.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customize each job', style: AppTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Toggle what you want to track for each job',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar if multiple jobs
          if (_selectedJobs.length > 1)
            TabBar(
              isScrollable: true,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: _selectedJobs.keys.map((name) => Tab(text: name)).toList(),
            ),

          Expanded(
            child: _selectedJobs.length == 1
                ? _buildJobTemplateEditor(_selectedJobs.keys.first)
                : TabBarView(
                    children: _selectedJobs.keys
                        .map((name) => _buildJobTemplateEditor(name))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTemplateEditor(String jobName) {
    final jobEntry = _selectedJobs[jobName];
    if (jobEntry == null) return const SizedBox();

    final template = jobEntry.template;

    // Build all sections as a map
    final allSections = <String, Widget>{
      'pay': _buildTemplateSection(
        title: 'Pay Structure',
        icon: Icons.attach_money,
        children: [
          _buildPayStructureSelector(jobName, template),
          if (template.tracksOvertime)
            _buildOvertimeMultiplier(jobName, template),
        ],
      ),
      'earnings': _buildTemplateSection(
        title: 'Earnings Tracking',
        icon: Icons.trending_up,
        children: [
          _buildTemplateToggle(
            'Tips (Cash & Credit)',
            'Track tips received',
            template.showTips,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showTips: value)),
          ),
          _buildTemplateToggle(
            'Sales Amount',
            'Track total sales for tip %',
            template.showSales,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showSales: value)),
          ),
          _buildTemplateToggle(
            'Commission',
            'Track sales commission',
            template.showCommission,
            (value) => _updateTemplate(
                jobName, template.copyWith(showCommission: value)),
          ),
          _buildTemplateToggle(
            'Overtime',
            'Track overtime hours',
            template.tracksOvertime,
            (value) => _updateTemplate(
                jobName, template.copyWith(tracksOvertime: value)),
          ),
        ],
      ),
      'rideshare': _buildTemplateSection(
        title: '🚗 Rideshare & Delivery',
        icon: Icons.directions_car,
        children: [
          _buildTemplateToggle(
            'Rides Count',
            'Number of rides/deliveries',
            template.showRidesCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showRidesCount: value)),
          ),
          _buildTemplateToggle(
            'Deadhead Miles',
            'Miles without passengers',
            template.showDeadMiles,
            (value) => _updateTemplate(
                jobName, template.copyWith(showDeadMiles: value)),
          ),
          _buildTemplateToggle(
            'Fuel Cost',
            'Track fuel expenses',
            template.showFuelCost,
            (value) => _updateTemplate(
                jobName, template.copyWith(showFuelCost: value)),
          ),
          _buildTemplateToggle(
            'Tolls & Parking',
            'Track parking and toll fees',
            template.showTollsParking,
            (value) => _updateTemplate(
                jobName, template.copyWith(showTollsParking: value)),
          ),
          _buildTemplateToggle(
            'Surge Multiplier',
            'Track surge pricing bonuses',
            template.showSurgeMultiplier,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSurgeMultiplier: value)),
          ),
          _buildTemplateToggle(
            'Base Fare',
            'Base fare vs tips breakdown',
            template.showBaseFare,
            (value) => _updateTemplate(
                jobName, template.copyWith(showBaseFare: value)),
          ),
        ],
      ),
      'music': _buildTemplateSection(
        title: '🎵 Music & Entertainment',
        icon: Icons.music_note,
        children: [
          _buildTemplateToggle(
            'Gig Type',
            'Wedding, corporate, street, etc.',
            template.showGigType,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showGigType: value)),
          ),
          _buildTemplateToggle(
            'Setup Hours',
            'Time spent setting up',
            template.showSetupHours,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSetupHours: value)),
          ),
          _buildTemplateToggle(
            'Performance Hours',
            'Actual performance time',
            template.showPerformanceHours,
            (value) => _updateTemplate(
                jobName, template.copyWith(showPerformanceHours: value)),
          ),
          _buildTemplateToggle(
            'Breakdown Hours',
            'Time spent breaking down',
            template.showBreakdownHours,
            (value) => _updateTemplate(
                jobName, template.copyWith(showBreakdownHours: value)),
          ),
          _buildTemplateToggle(
            'Equipment Rental',
            'Track equipment rental costs',
            template.showEquipmentRental,
            (value) => _updateTemplate(
                jobName, template.copyWith(showEquipmentRental: value)),
          ),
          _buildTemplateToggle(
            'Crew Payment',
            'Split payment with crew',
            template.showCrewPayment,
            (value) => _updateTemplate(
                jobName, template.copyWith(showCrewPayment: value)),
          ),
          _buildTemplateToggle(
            'Merch Sales',
            'Merchandise revenue',
            template.showMerchSales,
            (value) => _updateTemplate(
                jobName, template.copyWith(showMerchSales: value)),
          ),
          _buildTemplateToggle(
            'Audience Size',
            'Crowd/attendance numbers',
            template.showAudienceSize,
            (value) => _updateTemplate(
                jobName, template.copyWith(showAudienceSize: value)),
          ),
        ],
      ),
      'art': _buildTemplateSection(
        title: '🎨 Art & Crafts',
        icon: Icons.palette,
        children: [
          _buildTemplateToggle(
            'Pieces Created',
            'Production count',
            template.showPiecesCreated,
            (value) => _updateTemplate(
                jobName, template.copyWith(showPiecesCreated: value)),
          ),
          _buildTemplateToggle(
            'Pieces Sold',
            'Sales count',
            template.showPiecesSold,
            (value) => _updateTemplate(
                jobName, template.copyWith(showPiecesSold: value)),
          ),
          _buildTemplateToggle(
            'Materials Cost',
            'Track material expenses',
            template.showMaterialsCost,
            (value) => _updateTemplate(
                jobName, template.copyWith(showMaterialsCost: value)),
          ),
          _buildTemplateToggle(
            'Sale Price',
            'Revenue per piece',
            template.showSalePrice,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSalePrice: value)),
          ),
          _buildTemplateToggle(
            'Venue Commission %',
            'Gallery/venue commission percentage',
            template.showVenueCommission,
            (value) => _updateTemplate(
                jobName, template.copyWith(showVenueCommission: value)),
          ),
        ],
      ),
      'retail': _buildTemplateSection(
        title: '🛍️ Retail & Sales',
        icon: Icons.shopping_bag,
        children: [
          _buildTemplateToggle(
            'Items Sold',
            'Item count',
            template.showItemsSold,
            (value) => _updateTemplate(
                jobName, template.copyWith(showItemsSold: value)),
          ),
          _buildTemplateToggle(
            'Transactions',
            'Number of customers',
            template.showTransactionsCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showTransactionsCount: value)),
          ),
          _buildTemplateToggle(
            'Upsells',
            'Warranties and credit cards',
            template.showUpsells,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showUpsells: value)),
          ),
          _buildTemplateToggle(
            'Returns',
            'Return tracking',
            template.showReturns,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showReturns: value)),
          ),
          _buildTemplateToggle(
            'Shrink',
            'Inventory loss',
            template.showShrink,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showShrink: value)),
          ),
        ],
      ),
      'event': _buildTemplateSection(
        title: 'Event Details',
        icon: Icons.celebration,
        children: [
          _buildTemplateToggle(
            'Event/Party Name',
            'Name the event',
            template.showEventName,
            (value) => _updateTemplate(
                jobName, template.copyWith(showEventName: value)),
          ),
          _buildTemplateToggle(
            'Event Cost',
            'Total cost of event (DJs, planners)',
            template.showEventCost,
            (value) => _updateTemplate(
                jobName, template.copyWith(showEventCost: value)),
          ),
          _buildTemplateToggle(
            'Hostess Name',
            'Track who hosted',
            template.showHostess,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showHostess: value)),
          ),
          _buildTemplateToggle(
            'Guest Count',
            'Number of guests',
            template.showGuestCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showGuestCount: value)),
          ),
        ],
      ),
      'work': _buildTemplateSection(
        title: 'Work Details',
        icon: Icons.location_on,
        children: [
          _buildTemplateToggle(
            'Location',
            'Where you worked',
            template.showLocation,
            (value) => _updateTemplate(
                jobName, template.copyWith(showLocation: value)),
          ),
          _buildTemplateToggle(
            'Client/Patient Name',
            'Track clients',
            template.showClientName,
            (value) => _updateTemplate(
                jobName, template.copyWith(showClientName: value)),
          ),
          _buildTemplateToggle(
            'Project Name',
            'Track projects',
            template.showProjectName,
            (value) => _updateTemplate(
                jobName, template.copyWith(showProjectName: value)),
          ),
          _buildTemplateToggle(
            'Mileage',
            'Track miles driven',
            template.showMileage,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showMileage: value)),
          ),
        ],
      ),
      'salon': _buildTemplateSection(
        title: '💇 Salon & Spa',
        icon: Icons.spa,
        children: [
          _buildTemplateToggle(
            'Services Count',
            'Number of services performed',
            template.showServicesCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showServicesCount: value)),
          ),
          _buildTemplateToggle(
            'Product Sales',
            'Separate product revenue',
            template.showProductSales,
            (value) => _updateTemplate(
                jobName, template.copyWith(showProductSales: value)),
          ),
          _buildTemplateToggle(
            'Chair Rental',
            'Freelance stylist chair costs',
            template.showChairRental,
            (value) => _updateTemplate(
                jobName, template.copyWith(showChairRental: value)),
          ),
        ],
      ),
      'hospitality': _buildTemplateSection(
        title: '🏨 Hospitality',
        icon: Icons.hotel,
        children: [
          _buildTemplateToggle(
            'Rooms Cleaned',
            'Housekeeping rooms count',
            template.showRoomsCleaned,
            (value) => _updateTemplate(
                jobName, template.copyWith(showRoomsCleaned: value)),
          ),
          _buildTemplateToggle(
            'Room Upgrades',
            'Front desk upsells',
            template.showRoomUpgrades,
            (value) => _updateTemplate(
                jobName, template.copyWith(showRoomUpgrades: value)),
          ),
          _buildTemplateToggle(
            'Guests Checked In',
            'Front desk checkins',
            template.showGuestsCheckedIn,
            (value) => _updateTemplate(
                jobName, template.copyWith(showGuestsCheckedIn: value)),
          ),
          _buildTemplateToggle(
            'Cars Parked',
            'Valet cars parked',
            template.showCarsParked,
            (value) => _updateTemplate(
                jobName, template.copyWith(showCarsParked: value)),
          ),
        ],
      ),
      'fitness': _buildTemplateSection(
        title: '💪 Fitness',
        icon: Icons.fitness_center,
        children: [
          _buildTemplateToggle(
            'Sessions/Classes',
            'Sessions or classes taught',
            template.showSessionsCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSessionsCount: value)),
          ),
          _buildTemplateToggle(
            'Package Sales',
            'Fitness packages sold',
            template.showPackageSales,
            (value) => _updateTemplate(
                jobName, template.copyWith(showPackageSales: value)),
          ),
          _buildTemplateToggle(
            'Supplement Sales',
            'Supplements sold',
            template.showSupplementSales,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSupplementSales: value)),
          ),
        ],
      ),
      'healthcare': _buildTemplateSection(
        title: '⚕️ Healthcare',
        icon: Icons.medical_services,
        children: [
          _buildTemplateToggle(
            'Patient Count',
            'Patients seen',
            template.showPatientCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showPatientCount: value)),
          ),
          _buildTemplateToggle(
            'Procedures',
            'Procedures performed',
            template.showProceduresCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showProceduresCount: value)),
          ),
          _buildTemplateToggle(
            'On-Call Hours',
            'On-call shift hours',
            template.showOnCallHours,
            (value) => _updateTemplate(
                jobName, template.copyWith(showOnCallHours: value)),
          ),
        ],
      ),
      'construction': _buildTemplateSection(
        title: '🔨 Construction',
        icon: Icons.construction,
        children: [
          _buildTemplateToggle(
            'Labor Cost',
            'Crew wages',
            template.showLaborCost,
            (value) => _updateTemplate(
                jobName, template.copyWith(showLaborCost: value)),
          ),
          _buildTemplateToggle(
            'Subcontractor Cost',
            'Specialist payments',
            template.showSubcontractorCost,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSubcontractorCost: value)),
          ),
          _buildTemplateToggle(
            'Square Footage',
            'Work completed',
            template.showSquareFootage,
            (value) => _updateTemplate(
                jobName, template.copyWith(showSquareFootage: value)),
          ),
        ],
      ),
      'freelancer': _buildTemplateSection(
        title: '👨‍💼 Freelancer',
        icon: Icons.business,
        children: [
          _buildTemplateToggle(
            'Revisions',
            'Rounds of changes',
            template.showRevisionsCount,
            (value) => _updateTemplate(
                jobName, template.copyWith(showRevisionsCount: value)),
          ),
          _buildTemplateToggle(
            'Client Type',
            'Startup/SMB/Enterprise',
            template.showClientType,
            (value) => _updateTemplate(
                jobName, template.copyWith(showClientType: value)),
          ),
          _buildTemplateToggle(
            'Expenses',
            'Software, equipment, travel',
            template.showExpenses,
            (value) => _updateTemplate(
                jobName, template.copyWith(showExpenses: value)),
          ),
          _buildTemplateToggle(
            'Billable Hours',
            'Billable hours tracking',
            template.showBillableHours,
            (value) => _updateTemplate(
                jobName, template.copyWith(showBillableHours: value)),
          ),
        ],
      ),
      'documentation': _buildTemplateSection(
        title: 'Documentation',
        icon: Icons.note_alt,
        children: [
          _buildTemplateToggle(
            'Notes',
            'Add notes to shifts',
            template.showNotes,
            (value) =>
                _updateTemplate(jobName, template.copyWith(showNotes: value)),
          ),
        ],
      ),
      'finance': _buildTemplateSection(
        title: '💰 Finance Documents',
        icon: Icons.receipt_long,
        children: [
          _buildTemplateToggle(
            'Invoices',
            'Attach invoices to shifts (for contractors)',
            template.showInvoices,
            (value) => _updateTemplate(
                jobName, template.copyWith(showInvoices: value)),
          ),
          _buildTemplateToggle(
            'Receipts & Expenses',
            'Track receipts for tax deductions',
            template.showReceipts,
            (value) => _updateTemplate(
                jobName, template.copyWith(showReceipts: value)),
          ),
        ],
      ),
    };

    // Determine industry-specific section - this appears right after earnings
    final industrySection =
        _getIndustrySpecificSectionForTemplate(_selectedIndustry);

    // Build ordered list
    final sectionOrder = <String>['pay', 'earnings'];
    if (industrySection != null) {
      sectionOrder.add(industrySection);
    }
    // Add all remaining sections
    sectionOrder.addAll(
      allSections.keys.where((k) => !sectionOrder.contains(k)).toList(),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sectionOrder.map<Widget>((key) {
        final widget = allSections[key];
        if (widget == null) return const SizedBox();
        return Column(
          children: [widget, const SizedBox(height: 16)],
        );
      }).toList(),
    );
  }

  Widget _buildTemplateSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = true,
    bool hasActiveFields = false,
  }) {
    return _CollapsibleSection(
      title: title,
      icon: icon,
      initiallyExpanded: initiallyExpanded,
      hasActiveFields: hasActiveFields,
      children: children,
    );
  }

  Widget _buildTemplateToggle(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title, style: AppTheme.bodyLarge),
      subtitle: Text(subtitle, style: AppTheme.labelSmall),
      trailing: Switch(
        value: value,
        activeThumbColor: AppTheme.primaryGreen,
        onChanged: onChanged,
      ),
      dense: true,
    );
  }

  Widget _buildPayStructureSelector(String jobName, JobTemplate template) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay Type',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PayStructure.values.map((structure) {
              final isSelected = template.payStructure == structure;
              return ChoiceChip(
                label: Text(_getPayStructureName(structure)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _updateTemplate(
                        jobName, template.copyWith(payStructure: structure));
                  }
                },
                selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                backgroundColor: AppTheme.cardBackgroundLight,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textSecondary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Get the industry-specific section for onboarding template ordering
  String? _getIndustrySpecificSectionForTemplate(String? industry) {
    switch (industry) {
      case 'Rideshare & Delivery':
        return 'rideshare';
      case 'Music & Entertainment':
        return 'music';
      case 'Artist & Crafts':
        return 'art';
      case 'Retail/Sales':
        return 'retail';
      case 'Salon/Spa':
        return 'salon';
      case 'Hospitality':
        return 'hospitality';
      default:
        return null;
    }
  }

  String _getPayStructureName(PayStructure structure) {
    switch (structure) {
      case PayStructure.hourly:
        return 'Hourly';
      case PayStructure.flatRate:
        return 'Flat Rate';
      case PayStructure.salary:
        return 'Salary';
      case PayStructure.commission:
        return 'Commission';
    }
  }

  Widget _buildOvertimeMultiplier(String jobName, JobTemplate template) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Overtime Rate:', style: AppTheme.bodyMedium),
          const SizedBox(width: 16),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 1.5, label: Text('1.5x')),
              ButtonSegment(value: 2.0, label: Text('2x')),
            ],
            selected: {template.overtimeMultiplier},
            onSelectionChanged: (value) {
              _updateTemplate(
                  jobName, template.copyWith(overtimeMultiplier: value.first));
            },
          ),
        ],
      ),
    );
  }

  void _updateTemplate(String jobName, JobTemplate newTemplate) {
    setState(() {
      final entry = _selectedJobs[jobName];
      if (entry != null) {
        _selectedJobs[jobName] = JobEntry(
          hourlyRate: entry.hourlyRate,
          template: newTemplate,
        );
      }
    });
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set your income goals', style: AppTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Toggle the goals you want to track',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Goal cards
          Expanded(
            child: ListView(
              children: [
                _buildGoalCard('daily', 'Daily Goal', Icons.today, 100),
                const SizedBox(height: 12),
                _buildGoalCard(
                    'weekly', 'Weekly Goal', Icons.calendar_view_week, 500),
                const SizedBox(height: 12),
                _buildGoalCard(
                    'monthly', 'Monthly Goal', Icons.calendar_month, 2000),
                const SizedBox(height: 12),
                _buildGoalCard(
                    'yearly', 'Yearly Goal', Icons.calendar_today, 25000),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can always adjust goals later in Settings',
                    style:
                        AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalPeriodLabel(String type) {
    switch (type) {
      case 'daily':
        return 'per day';
      case 'weekly':
        return 'per week';
      case 'monthly':
        return 'per month';
      case 'yearly':
        return 'per year';
      default:
        return 'per $type';
    }
  }

  Widget _buildGoalCard(
      String type, String label, IconData icon, double defaultAmount) {
    final amount = _goalAmounts[type];
    final isEnabled = amount != null;
    final controller = _goalControllers[type]!;

    // Set initial text if controller is empty and goal is enabled
    if (isEnabled && controller.text.isEmpty) {
      controller.text =
          (amount == 0 ? defaultAmount : amount).toStringAsFixed(0);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                      : AppTheme.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? AppTheme.primaryGreen : AppTheme.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTheme.bodyLarge),
              ),
              Switch(
                value: isEnabled,
                activeThumbColor: AppTheme.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      _goalAmounts[type] = defaultAmount;
                      controller.text = defaultAmount.toStringAsFixed(0);
                    } else {
                      _goalAmounts[type] = null;
                      controller.clear();
                    }
                  });
                },
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('\$',
                    style: AppTheme.titleMedium
                        .copyWith(color: AppTheme.primaryGreen)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: AppTheme.titleMedium
                        .copyWith(color: AppTheme.primaryGreen),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      // Update the goal amount WITHOUT calling setState to avoid rebuild
                      if (value.isEmpty) {
                        _goalAmounts[type] = 0;
                      } else {
                        final parsed = double.tryParse(value);
                        _goalAmounts[type] = parsed ?? 0;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getGoalPeriodLabel(type),
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    // Get enabled goals with capitalized names
    final enabledGoals = _goalAmounts.entries
        .where((e) => e.value != null && e.value! > 0)
        .map((e) =>
            '${e.key[0].toUpperCase()}${e.key.substring(1)}: \$${e.value!.toStringAsFixed(0)}')
        .toList();

    // Calculate import breakdown by job
    final importBreakdown = <String, int>{};
    int totalImports = 0;
    if (_importedEvents != null && _importedJobs.isNotEmpty) {
      final now = DateTime.now();
      for (final eventData in _importedEvents!) {
        if (eventData is Event &&
            eventData.start != null &&
            eventData.start!.isBefore(now)) {
          String jobTitle = eventData.title!
              .replaceFirst(
                  RegExp(
                      r'^(Hot Schedules|7shifts|When I Work|Homebase|Sling)\s*',
                      caseSensitive: false),
                  '')
              .trim();
          final jobId = _importedJobs[jobTitle];
          if (jobId != null) {
            final jobName = _selectedJobs.keys.firstWhere(
                (k) => _selectedJobs[k] != null,
                orElse: () => jobTitle);
            importBreakdown[jobName] = (importBreakdown[jobName] ?? 0) + 1;
            totalImports++;
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isFirstTime ? 'You\'re all set!' : 'Ready to add!',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s a summary of your setup',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Summary cards
          Expanded(
            child: ListView(
              children: [
                // Industry
                if (_selectedIndustry != null)
                  _buildSummaryCard(
                    icon: Icons.business,
                    title: 'Industry',
                    content: _industries
                            .where((i) => i.industry == _selectedIndustry)
                            .firstOrNull
                            ?.displayName ??
                        _selectedIndustry!,
                  ),

                const SizedBox(height: 12),

                // Jobs
                if (_selectedJobs.isNotEmpty)
                  _buildSummaryCard(
                    icon: Icons.work,
                    title: 'Your Jobs (${_selectedJobs.length})',
                    content: _selectedJobs.entries.map((e) {
                      final parts = <String>[
                        '${e.key} - \$${e.value.hourlyRate.toStringAsFixed(0)}/hr'
                      ];
                      if (e.value.employer != null &&
                          e.value.employer!.isNotEmpty) {
                        parts.add('  Employer: ${e.value.employer}');
                      }
                      return parts.join('\n');
                    }).join('\n\n'),
                  ),

                const SizedBox(height: 12),

                // Import breakdown
                if (totalImports > 0)
                  _buildSummaryCard(
                    icon: Icons.cloud_download,
                    title: 'Importing $totalImports Shifts',
                    content: importBreakdown.entries
                        .map((e) => '${e.key}: ${e.value} shifts')
                        .join('\n'),
                  ),

                if (totalImports > 0) const SizedBox(height: 12),

                // Goals
                if (enabledGoals.isNotEmpty)
                  _buildSummaryCard(
                    icon: Icons.flag,
                    title: 'Income Goals (${enabledGoals.length})',
                    content: enabledGoals.join('\n'),
                  )
                else
                  _buildSummaryCard(
                    icon: Icons.flag_outlined,
                    title: 'Income Goals',
                    content: 'No goals set - you can add them later',
                    isSecondary: true,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ready message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isFirstTime
                        ? (_importedEvents != null &&
                                _importedEvents!.isNotEmpty
                            ? 'Tap "Complete Setup" to import your shifts!'
                            : 'Tap "Let\'s Go!" to start tracking your income!')
                        : 'Tap "Complete Setup" to finish!',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String content,
    bool isSecondary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isSecondary
            ? Border.all(color: AppTheme.cardBackgroundLight)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSecondary
                  ? AppTheme.cardBackgroundLight
                  : AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: isSecondary ? AppTheme.textMuted : AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelSmall.copyWith(
                    color: isSecondary
                        ? AppTheme.textMuted
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTheme.bodyLarge.copyWith(
                    color:
                        isSecondary ? AppTheme.textMuted : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Import calendar shifts after jobs are created
  Future<void> _importCalendarShifts(
      List<dynamic> events, Map<String, String> jobMapping) async {
    try {
      int imported = 0;
      int skipped = 0;

      // Get existing shifts to check for duplicates
      final existingShifts = await _db.getShifts();

      // Filter: Only import PAST shifts (anything before RIGHT NOW)
      final now = DateTime.now();

      final shiftsToImport = events.whereType<Event>().where((event) {
        if (event.start == null) return false;
        // Only import if event start time has already passed
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
          skipped++;
          continue;
        }

        // Check for duplicates
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

        // Skip if shift already has earnings
        final hasEarnings =
            existingShift.totalIncome > 0 || existingShift.hoursWorked > 0;

        if (existingShift.id.isNotEmpty && hasEarnings) {
          skipped++;
          continue;
        }

        final isUpdate = existingShift.id.isNotEmpty;

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

        final isFuture = event.start!.isAfter(now);

        final shift = Shift(
          id: isUpdate ? existingShift.id : const Uuid().v4(),
          date: event.start!,
          startTime: startTime,
          endTime: endTime,
          cashTips: 0,
          creditTips: 0,
          hourlyRate: 0,
          hoursWorked: hoursWorked,
          status: isFuture ? 'scheduled' : 'completed',
          source: 'calendar_sync',
          calendarEventId: event.eventId,
          eventName: null,
          jobId: jobId,
          notes: event.description,
        );

        await _db.saveShift(shift);
        imported++;
      }

      // Save job mappings and calendar ID for auto-sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('job_mappings', jsonEncode(jobMapping));
      await prefs.setBool('calendar_permission_granted', true);

      if (mounted && imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Imported $imported shifts${skipped > 0 ? ' ($skipped skipped)' : ''}'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
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
    }
  }
}

/// Helper class to store job data during onboarding
class JobEntry {
  double hourlyRate;
  JobTemplate template;
  String? employer;

  JobEntry({
    required this.hourlyRate,
    required this.template,
    this.employer,
  });
}

// Separate StatefulWidget to maintain its own TextEditingController
class _JobRateTextField extends StatefulWidget {
  final double initialRate;
  final Function(double) onRateChanged;

  const _JobRateTextField({
    required this.initialRate,
    required this.onRateChanged,
  });

  @override
  State<_JobRateTextField> createState() => _JobRateTextFieldState();
}

class _JobRateTextFieldState extends State<_JobRateTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialRate.toStringAsFixed(2));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(_JobRateTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text when slider changes, but only if not currently editing
    if (oldWidget.initialRate != widget.initialRate && !_isEditing) {
      _controller.text = widget.initialRate.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTheme.bodyMedium
          .copyWith(color: AppTheme.primaryGreen, fontSize: 14),
      textAlign: TextAlign.right,
      decoration: const InputDecoration(
        prefixText: '\$ ',
        suffixText: '/hr',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onSubmitted: (value) {
        final newRate = double.tryParse(value);
        if (newRate != null && newRate >= 0 && newRate <= 100000) {
          widget.onRateChanged(newRate);
        }
      },
      onEditingComplete: () {
        final newRate = double.tryParse(_controller.text);
        if (newRate != null && newRate >= 0 && newRate <= 100000) {
          widget.onRateChanged(newRate);
        }
        _focusNode.unfocus();
      },
    );
  }
}

/// Collapsible section widget for template customization
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool hasActiveFields;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.hasActiveFields = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: widget.hasActiveFields
            ? Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.hasActiveFields
                        ? AppTheme.primaryGreen
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.titleMedium.copyWith(
                        color: widget.hasActiveFields
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (widget.hasActiveFields)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (_isExpanded && widget.children.isNotEmpty) ...[
            Divider(height: 1, color: AppTheme.cardBackgroundLight),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}
