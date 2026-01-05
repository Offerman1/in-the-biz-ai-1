import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/job.dart';
import '../models/job_template.dart';
import '../models/industry_data.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddJobScreen extends StatefulWidget {
  final Job? existingJob;

  const AddJobScreen({super.key, this.existingJob});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _tipoutPercentController =
      TextEditingController();
  final TextEditingController _tipoutDescriptionController =
      TextEditingController();

  // Job data
  String? _selectedIndustry;
  String? _selectedJobTitle;
  double _baseRate = 15.0;
  PayStructure _payStructure = PayStructure.hourly;
  double _defaultTipoutPercent = 0.0;

  // Template toggles - Core fields
  bool _showTips = true;
  bool _showCommission = false;
  bool _showEventName = false;
  bool _showHostess = false;
  bool _showGuestCount = false;
  bool _showLocation = false;
  bool _showClientName = false;
  bool _showProjectName = false;
  bool _showMileage = false;
  bool _showPhotos = true;
  bool _showNotes = true;
  bool _tracksOvertime = false;
  bool _showSales = false;
  bool _showEventCost = false;

  // Finance Documents - for freelancers/contractors
  bool _showInvoices = false;
  bool _showReceipts = false;

  // Rideshare-specific fields
  bool? _showRidesCount;
  bool? _showDeadMiles;
  bool? _showFuelCost;
  bool? _showTollsParking;
  bool? _showSurgeMultiplier;
  bool? _showBaseFare;

  // Music & Entertainment fields
  bool? _showGigType;
  bool? _showSetupHours;
  bool? _showPerformanceHours;
  bool? _showBreakdownHours;
  bool? _showEquipmentUsed;
  bool? _showEquipmentRental;
  bool? _showCrewPayment;
  bool? _showMerchSales;
  bool? _showAudienceSize;

  // Art & Crafts fields
  bool? _showPiecesCreated;
  bool? _showPiecesSold;
  bool? _showMaterialsCost;
  bool? _showSalePrice;
  bool? _showVenueCommission;

  // Retail & Sales fields
  bool? _showItemsSold;
  bool? _showTransactionsCount;
  bool? _showUpsells;
  bool? _showReturns;
  bool? _showShrink;
  double _overtimeMultiplier = 1.5;

  bool _isSaving = false;
  bool _tipOutExpanded = false;

  // Industries - use IndustryData as source of truth
  late final List<String> _industries = [
    ...IndustryData.industries,
    '+ Add Custom Industry',
  ];

  // Custom job titles added by user - map of industry -> list of custom titles
  final Map<String, List<String>> _customJobTitles = {};

  /// Get job titles for an industry (combines standard + custom)
  List<String> _getJobTitlesForIndustry(String? industry) {
    if (industry == null) return [];

    // Get standard titles from IndustryData
    final standardTitles =
        List<String>.from(IndustryData.getJobTitles(industry));

    // Add custom titles if any exist for this industry
    if (_customJobTitles.containsKey(industry)) {
      standardTitles.addAll(_customJobTitles[industry]!);
    }

    // Add the "Add Custom" option if not already there
    if (!standardTitles.contains('+ Add Custom Job Title')) {
      standardTitles.add('+ Add Custom Job Title');
    }

    return standardTitles;
  }

  @override
  void initState() {
    super.initState();
    _rateController.text = _baseRate.toStringAsFixed(2);

    if (widget.existingJob != null) {
      _loadExistingJob();
    }
  }

  void _loadExistingJob() {
    final job = widget.existingJob!;
    _jobTitleController.text = job.name;
    _employerController.text = job.employer ?? '';

    // Ensure industry exists in the list, otherwise set to null
    if (job.industry != null && _industries.contains(job.industry)) {
      _selectedIndustry = job.industry;

      // Check if job title exists in the standard or custom job titles for this industry
      final jobTitles = _getJobTitlesForIndustry(_selectedIndustry);
      if (!jobTitles.contains(job.name)) {
        // Add custom job title to the custom list
        if (_selectedIndustry != null) {
          if (!_customJobTitles.containsKey(_selectedIndustry)) {
            _customJobTitles[_selectedIndustry!] = [];
          }
          _customJobTitles[_selectedIndustry]!.add(job.name);
        }
      }
      _selectedJobTitle = job.name;
    } else {
      _selectedIndustry = null;
      // If no valid industry, we can't set the job title in the dropdown
      _selectedJobTitle = null;
    }

    _baseRate = job.hourlyRate;
    _rateController.text = _baseRate.toStringAsFixed(2);

    final template = job.template;
    _payStructure = template.payStructure;
    _showTips = template.showTips;
    _showCommission = template.showCommission;
    _showEventName = template.showEventName;
    _showHostess = template.showHostess;
    _showGuestCount = template.showGuestCount;
    _showLocation = template.showLocation;
    _showClientName = template.showClientName;
    _showProjectName = template.showProjectName;
    _showMileage = template.showMileage;
    _showPhotos = template.showPhotos;
    _showNotes = template.showNotes;
    _showInvoices = template.showInvoices;
    _showReceipts = template.showReceipts;
    _tracksOvertime = template.tracksOvertime;
    _overtimeMultiplier = template.overtimeMultiplier;
  }

  /// Apply template settings when industry is selected
  void _applyIndustryTemplate(String? industry) {
    JobTemplate template;
    switch (industry) {
      case 'Restaurant/Bar/Nightclub':
        template = JobTemplate.restaurant();
        break;
      case 'Construction/Trades':
        template = JobTemplate.construction();
        break;
      case 'Freelancer/Consultant':
        template = JobTemplate.freelancer();
        break;
      case 'Healthcare':
        template = JobTemplate.healthcare();
        break;
      case 'Gig Worker':
        template = JobTemplate.gigWorker();
        break;
      case 'Rideshare & Delivery':
        template = JobTemplate.rideshareDelivery();
        break;
      case 'Music & Entertainment':
        template = JobTemplate.musicEntertainment();
        break;
      case 'Artist & Crafts':
        template = JobTemplate.artistCrafts();
        break;
      case 'Retail/Sales':
        template = JobTemplate.retail();
        break;
      case 'Salon/Spa':
        template = JobTemplate.salon();
        break;
      case 'Hospitality':
        template = JobTemplate.hospitality();
        break;
      case 'Fitness':
        template = JobTemplate.fitness();
        break;
      default:
        template = JobTemplate();
    }

    // Update state variables from template
    _payStructure = template.payStructure;
    _showTips = template.showTips;
    _showCommission = template.showCommission;
    _showSales = template.showSales;
    _showEventCost = template.showEventCost;
    _showEventName = template.showEventName;
    _showHostess = template.showHostess;
    _showGuestCount = template.showGuestCount;
    _showLocation = template.showLocation;
    _showClientName = template.showClientName;
    _showProjectName = template.showProjectName;
    _showMileage = template.showMileage;
    _showPhotos = template.showPhotos;
    _showNotes = template.showNotes;
    _showInvoices = template.showInvoices;
    _showReceipts = template.showReceipts;
    _tracksOvertime = template.tracksOvertime;
    _overtimeMultiplier = template.overtimeMultiplier;

    // Rideshare & Delivery fields
    _showRidesCount = template.showRidesCount;
    _showDeadMiles = template.showDeadMiles;
    _showFuelCost = template.showFuelCost;
    _showTollsParking = template.showTollsParking;
    _showSurgeMultiplier = template.showSurgeMultiplier;
    _showBaseFare = template.showBaseFare;

    // Music & Entertainment fields
    _showGigType = template.showGigType;
    _showSetupHours = template.showSetupHours;
    _showPerformanceHours = template.showPerformanceHours;
    _showBreakdownHours = template.showBreakdownHours;
    _showEquipmentUsed = template.showEquipmentUsed;
    _showEquipmentRental = template.showEquipmentRental;
    _showCrewPayment = template.showCrewPayment;
    _showMerchSales = template.showMerchSales;
    _showAudienceSize = template.showAudienceSize;

    // Art & Crafts fields
    _showPiecesCreated = template.showPiecesCreated;
    _showPiecesSold = template.showPiecesSold;
    _showMaterialsCost = template.showMaterialsCost;
    _showSalePrice = template.showSalePrice;
    _showVenueCommission = template.showVenueCommission;

    // Retail & Sales fields
    _showItemsSold = template.showItemsSold;
    _showTransactionsCount = template.showTransactionsCount;
    _showUpsells = template.showUpsells;
    _showReturns = template.showReturns;
    _showShrink = template.showShrink;
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _employerController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  JobTemplate _buildTemplate() {
    // Start with industry template
    JobTemplate base;
    switch (_selectedIndustry) {
      case 'Restaurant/Bar/Nightclub':
        base = JobTemplate.restaurant();
        break;
      case 'Construction/Trades':
        base = JobTemplate.construction();
        break;
      case 'Freelancer/Consultant':
        base = JobTemplate.freelancer();
        break;
      case 'Healthcare':
        base = JobTemplate.healthcare();
        break;
      case 'Gig Worker':
        base = JobTemplate.gigWorker();
        break;
      case 'Rideshare & Delivery':
        base = JobTemplate.rideshareDelivery();
        break;
      case 'Music & Entertainment':
        base = JobTemplate.musicEntertainment();
        break;
      case 'Artist & Crafts':
        base = JobTemplate.artistCrafts();
        break;
      case 'Retail/Sales':
        base = JobTemplate.retail();
        break;
      case 'Salon/Spa':
        base = JobTemplate.salon();
        break;
      case 'Hospitality':
        base = JobTemplate.hospitality();
        break;
      case 'Fitness':
        base = JobTemplate.fitness();
        break;
      default:
        base = JobTemplate();
    }

    // Apply customizations
    return base.copyWith(
      payStructure: _payStructure,
      showTips: _showTips,
      showCommission: _showCommission,
      showSales: _showSales,
      showEventCost: _showEventCost,
      showEventName: _showEventName,
      showHostess: _showHostess,
      showGuestCount: _showGuestCount,
      showLocation: _showLocation,
      showClientName: _showClientName,
      showProjectName: _showProjectName,
      showMileage: _showMileage,
      showPhotos: _showPhotos,
      showNotes: _showNotes,
      showInvoices: _showInvoices,
      showReceipts: _showReceipts,
      tracksOvertime: _tracksOvertime,
      overtimeMultiplier: _overtimeMultiplier,
    );
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    // Use the text from the text field, which might be edited
    final jobName = _jobTitleController.text.trim();
    if (jobName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a job name'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    // Check if hourly rate changed on existing job
    if (widget.existingJob != null &&
        widget.existingJob!.hourlyRate != _baseRate) {
      final shouldUpdate = await _showRateChangeDialog(
        widget.existingJob!.hourlyRate,
        _baseRate,
      );

      if (shouldUpdate == null) return; // User cancelled

      // Save the choice for later
      setState(() => _isSaving = true);

      try {
        final user = AuthService.currentUser;
        if (user == null) throw Exception('Not logged in');

        final job = Job(
          id: widget.existingJob!.id,
          userId: user.id,
          name: jobName,
          employer: _employerController.text.trim().isNotEmpty
              ? _employerController.text.trim()
              : null,
          industry: _selectedIndustry,
          hourlyRate: _baseRate,
          template: _buildTemplate(),
          isDefault: widget.existingJob!.isDefault,
        );

        await _db.updateJob(job);

        // Update existing shifts if user chose to
        if (shouldUpdate) {
          await _db.updateShiftsHourlyRate(
            jobId: job.id,
            newHourlyRate: _baseRate,
          );
        }

        if (mounted) {
          Navigator.pop(context, job);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving job: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('Not logged in');

      final job = Job(
        id: widget.existingJob?.id ??
            '', // Database generates UUID for new jobs
        userId: user.id,
        name: jobName,
        employer: _employerController.text.trim().isNotEmpty
            ? _employerController.text.trim()
            : null,
        industry: _selectedIndustry,
        hourlyRate: _baseRate,
        template: _buildTemplate(),
        isDefault: widget.existingJob?.isDefault ?? false,
        defaultTipoutPercent:
            _defaultTipoutPercent > 0 ? _defaultTipoutPercent : null,
        tipoutDescription: _tipoutDescriptionController.text.trim().isNotEmpty
            ? _tipoutDescriptionController.text.trim()
            : null,
      );

      if (widget.existingJob != null) {
        await _db.updateJob(job);
      } else {
        await _db.createJob(job);
      }

      if (mounted) {
        Navigator.pop(context, job);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving job: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool?> _showRateChangeDialog(double oldRate, double newRate) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Update Hourly Rate', style: AppTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You changed the base rate from \$${oldRate.toStringAsFixed(2)} to \$${newRate.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Apply this change to:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
            child: const Text('Future shifts only'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('All existing shifts'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          widget.existingJob != null ? 'Edit Job' : 'Create New Job',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveJob,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : Text(
                    'SAVE',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),

            // Job Name (FIRST - editable)
            Text(
              'Job Name',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _jobTitleController,
              builder: (context, value, child) {
                return TextFormField(
                  controller: _jobTitleController,
                  style: AppTheme.bodyLarge.copyWith(
                    color: value.text.isEmpty
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter job name',
                    hintStyle: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: Icon(Icons.work, color: AppTheme.primaryGreen),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a job name';
                    }
                    return null;
                  },
                  onChanged: (text) {
                    setState(() {
                      _selectedJobTitle = text.trim();
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Industry Dropdown (SECOND)
            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              decoration: InputDecoration(
                hintText:
                    _selectedIndustry == null ? 'Select an industry' : null,
                prefixIcon: Icon(Icons.category, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: AppTheme.cardBackground,
              iconEnabledColor: AppTheme.textPrimary,
              style: AppTheme.bodyLarge.copyWith(
                color: _selectedIndustry == null ||
                        _selectedIndustry == '+ Add Custom Industry'
                    ? AppTheme.textMuted
                    : AppTheme.textPrimary,
              ),
              hint: Text(
                'Select an industry',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              items: _industries.map((industry) {
                return DropdownMenuItem(
                  value: industry,
                  child: Text(
                    industry,
                    style: AppTheme.bodyLarge.copyWith(
                      color: industry == '+ Add Custom Industry'
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                      fontWeight: industry == '+ Add Custom Industry'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == '+ Add Custom Industry') {
                  _showAddCustomIndustryDialog();
                } else {
                  setState(() {
                    _selectedIndustry = value;
                    // Don't reset job name - user may have edited it
                    // Update template settings based on industry
                    _applyIndustryTemplate(value);
                  });
                }
              },
              validator: (value) {
                // Industry is optional
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Job Title (SECOND) - Chips layout when industry is selected (like onboarding)
            if (_selectedIndustry != null &&
                _selectedIndustry != '+ Add Custom Industry') ...[
              Text(
                'Job Title',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getJobTitlesForIndustry(_selectedIndustry)
                    .where((title) =>
                        title !=
                        '+ Add Custom Job Title') // Filter out the add button
                    .map((jobTitle) {
                  final isSelected = _selectedJobTitle == jobTitle;
                  return FilterChip(
                    label: Text(jobTitle),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedJobTitle = jobTitle;
                        _jobTitleController.text = jobTitle;
                        _applyIndustryTemplate(_selectedIndustry);
                      });
                    },
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showAddCustomJobTitleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Title'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.cardBackgroundLight),
                ),
              ),
            ],

            if (_selectedIndustry != null &&
                _selectedIndustry != '+ Add Custom Industry')
              const SizedBox(height: 16),

            // Employer (THIRD)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _employerController,
              builder: (context, value, child) {
                return TextFormField(
                  controller: _employerController,
                  style: AppTheme.bodyLarge.copyWith(
                    color: value.text.isEmpty
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Restaurant or company name',
                    hintStyle: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: Icon(Icons.business, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Base Hourly Rate (FOURTH - Simplified)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base Hourly Rate *',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showRateDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${_baseRate.toStringAsFixed(2)}/hr',
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Compact Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _baseRate.clamp(0.0, 75.0),
                min: 0,
                max: 75,
                divisions: 75, // $1 increments
                activeColor: AppTheme.primaryGreen,
                inactiveColor: AppTheme.cardBackgroundLight,
                onChanged: (value) {
                  setState(() {
                    _baseRate = value;
                    _rateController.text = value.toStringAsFixed(2);
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Tip Out Settings (Optional, Collapsible)
            _buildTipOutSection(),

            const SizedBox(height: 24),

            // Shift Fields Section
            _buildSectionHeader('Customize Shift Fields'),
            const SizedBox(height: 8),
            Text(
              'Date, Start Time, End Time, and Hours Worked are always included',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Organized Sections
            _buildOrganizedShiftFields(),

            const SizedBox(height: 80), // Space for save button
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.titleMedium.copyWith(
        color: AppTheme.primaryGreen,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTipOutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.accentYellow.withOpacity(0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _tipOutExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _tipOutExpanded = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: Icon(
            Icons.people_outline,
            color: AppTheme.accentYellow,
            size: 20,
          ),
          title: Text(
            'Tip Out Settings (Optional)',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: AppTheme.textSecondary,
          collapsedIconColor: AppTheme.textSecondary,
          children: [
            Text(
              'Set a default tip out percentage for support staff. You can adjust this per shift.',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip Out %',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tipoutPercentController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        style: AppTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: '0',
                          suffix: Text('%',
                              style: AppTheme.bodyMedium
                                  .copyWith(color: AppTheme.textSecondary)),
                          filled: true,
                          fillColor: AppTheme.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide:
                                BorderSide(color: AppTheme.cardBackgroundLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide:
                                BorderSide(color: AppTheme.cardBackgroundLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide:
                                BorderSide(color: AppTheme.primaryGreen),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            setState(() => _defaultTipoutPercent = parsed);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Who gets tipped out?',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tipoutDescriptionController,
                        style: AppTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: '',
                          filled: true,
                          fillColor: AppTheme.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide:
                                BorderSide(color: AppTheme.cardBackgroundLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide:
                                BorderSide(color: AppTheme.cardBackgroundLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            borderSide:
                                BorderSide(color: AppTheme.primaryGreen),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizedShiftFields() {
    final currentTemplate = _buildTemplate();

    // Build all sections as widgets
    final allSections = <String, Widget>{
      'pay': _buildTemplateSection(
        title: 'Pay Structure',
        icon: Icons.attach_money,
        children: [
          _buildPayStructureSelector(currentTemplate),
          if (currentTemplate.tracksOvertime)
            _buildOvertimeMultiplier(currentTemplate),
        ],
      ),
      'earnings': _buildTemplateSection(
        title: 'Earnings Tracking',
        icon: Icons.trending_up,
        children: [
          _buildTemplateToggle(
            'Tips (Cash & Credit)',
            'Track tips received',
            _showTips,
            (value) => setState(() => _showTips = value),
          ),
          _buildTemplateToggle(
            'Sales Amount',
            'Track total sales for tip %',
            _showSales,
            (value) => setState(() => _showSales = value),
          ),
          _buildTemplateToggle(
            'Commission',
            'Track sales commission',
            _showCommission,
            (value) => setState(() => _showCommission = value),
          ),
          _buildTemplateToggle(
            'Overtime',
            'Track overtime hours',
            _tracksOvertime,
            (value) => setState(() => _tracksOvertime = value),
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
            _showRidesCount ?? false,
            (value) => setState(() => _showRidesCount = value),
          ),
          _buildTemplateToggle(
            'Deadhead Miles',
            'Miles without passengers',
            _showDeadMiles ?? false,
            (value) => setState(() => _showDeadMiles = value),
          ),
          _buildTemplateToggle(
            'Fuel Cost',
            'Track fuel expenses',
            _showFuelCost ?? false,
            (value) => setState(() => _showFuelCost = value),
          ),
          _buildTemplateToggle(
            'Tolls & Parking',
            'Track parking and toll fees',
            _showTollsParking ?? false,
            (value) => setState(() => _showTollsParking = value),
          ),
          _buildTemplateToggle(
            'Surge Multiplier',
            'Track surge pricing bonuses',
            _showSurgeMultiplier ?? false,
            (value) => setState(() => _showSurgeMultiplier = value),
          ),
          _buildTemplateToggle(
            'Base Fare',
            'Base fare vs tips breakdown',
            _showBaseFare ?? false,
            (value) => setState(() => _showBaseFare = value),
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
            _showGigType ?? false,
            (value) => setState(() => _showGigType = value),
          ),
          _buildTemplateToggle(
            'Setup Hours',
            'Time to prepare equipment',
            _showSetupHours ?? false,
            (value) => setState(() => _showSetupHours = value),
          ),
          _buildTemplateToggle(
            'Performance Hours',
            'Time performing',
            _showPerformanceHours ?? false,
            (value) => setState(() => _showPerformanceHours = value),
          ),
          _buildTemplateToggle(
            'Breakdown Hours',
            'Time to pack up',
            _showBreakdownHours ?? false,
            (value) => setState(() => _showBreakdownHours = value),
          ),
          _buildTemplateToggle(
            'Equipment Used',
            'What equipment you used',
            _showEquipmentUsed ?? false,
            (value) => setState(() => _showEquipmentUsed = value),
          ),
          _buildTemplateToggle(
            'Equipment Rental',
            'Equipment rental costs',
            _showEquipmentRental ?? false,
            (value) => setState(() => _showEquipmentRental = value),
          ),
          _buildTemplateToggle(
            'Crew Payment',
            'Payment to crew members',
            _showCrewPayment ?? false,
            (value) => setState(() => _showCrewPayment = value),
          ),
          _buildTemplateToggle(
            'Merchandise Sales',
            'Sales of merchandise',
            _showMerchSales ?? false,
            (value) => setState(() => _showMerchSales = value),
          ),
          _buildTemplateToggle(
            'Audience Size',
            'Number of attendees',
            _showAudienceSize ?? false,
            (value) => setState(() => _showAudienceSize = value),
          ),
        ],
      ),
      'art': _buildTemplateSection(
        title: '🎨 Art & Crafts',
        icon: Icons.palette,
        children: [
          _buildTemplateToggle(
            'Pieces Created',
            'Number of items created',
            _showPiecesCreated ?? false,
            (value) => setState(() => _showPiecesCreated = value),
          ),
          _buildTemplateToggle(
            'Pieces Sold',
            'Number of items sold',
            _showPiecesSold ?? false,
            (value) => setState(() => _showPiecesSold = value),
          ),
          _buildTemplateToggle(
            'Materials Cost',
            'Cost of materials',
            _showMaterialsCost ?? false,
            (value) => setState(() => _showMaterialsCost = value),
          ),
          _buildTemplateToggle(
            'Sale Price',
            'Price per piece',
            _showSalePrice ?? false,
            (value) => setState(() => _showSalePrice = value),
          ),
          _buildTemplateToggle(
            'Venue Commission',
            'Commission to venue',
            _showVenueCommission ?? false,
            (value) => setState(() => _showVenueCommission = value),
          ),
        ],
      ),
      'retail': _buildTemplateSection(
        title: '🛍️ Retail & Sales',
        icon: Icons.shopping_bag,
        children: [
          _buildTemplateToggle(
            'Items Sold',
            'Number of items sold',
            _showItemsSold ?? false,
            (value) => setState(() => _showItemsSold = value),
          ),
          _buildTemplateToggle(
            'Transactions',
            'Number of transactions',
            _showTransactionsCount ?? false,
            (value) => setState(() => _showTransactionsCount = value),
          ),
          _buildTemplateToggle(
            'Upsells',
            'Number of upsells',
            _showUpsells ?? false,
            (value) => setState(() => _showUpsells = value),
          ),
          _buildTemplateToggle(
            'Returns',
            'Number of returns',
            _showReturns ?? false,
            (value) => setState(() => _showReturns = value),
          ),
          _buildTemplateToggle(
            'Shrink',
            'Inventory shrinkage',
            _showShrink ?? false,
            (value) => setState(() => _showShrink = value),
          ),
        ],
      ),
      'event': _buildTemplateSection(
        title: '🎉 Event Details',
        icon: Icons.celebration,
        children: [
          _buildTemplateToggle(
            'Event/Party Name',
            'Name the event',
            _showEventName,
            (value) => setState(() => _showEventName = value),
          ),
          _buildTemplateToggle(
            'Event Cost',
            'Total cost of event (DJs, planners)',
            _showEventCost,
            (value) => setState(() => _showEventCost = value),
          ),
          _buildTemplateToggle(
            'Hostess Name',
            'Track who hosted',
            _showHostess,
            (value) => setState(() => _showHostess = value),
          ),
          _buildTemplateToggle(
            'Guest Count',
            'Number of guests',
            _showGuestCount,
            (value) => setState(() => _showGuestCount = value),
          ),
        ],
      ),
      'work': _buildTemplateSection(
        title: '📍 Work Details',
        icon: Icons.location_on,
        children: [
          _buildTemplateToggle(
            'Location',
            'Where you worked',
            _showLocation,
            (value) => setState(() => _showLocation = value),
          ),
          _buildTemplateToggle(
            'Client/Patient Name',
            'Track clients',
            _showClientName,
            (value) => setState(() => _showClientName = value),
          ),
          _buildTemplateToggle(
            'Project Name',
            'Track projects',
            _showProjectName,
            (value) => setState(() => _showProjectName = value),
          ),
          _buildTemplateToggle(
            'Mileage',
            'Track miles driven',
            _showMileage,
            (value) => setState(() => _showMileage = value),
          ),
        ],
      ),
      'media': _buildTemplateSection(
        title: 'Media & Documentation',
        icon: Icons.image,
        children: [
          _buildTemplateToggle(
            'Photos',
            'Attach photos to shifts',
            _showPhotos,
            (value) => setState(() => _showPhotos = value),
          ),
          _buildTemplateToggle(
            'Notes',
            'Add shift notes',
            _showNotes,
            (value) => setState(() => _showNotes = value),
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
            _showInvoices,
            (value) => setState(() => _showInvoices = value),
          ),
          _buildTemplateToggle(
            'Receipts & Expenses',
            'Track receipts for tax deductions',
            _showReceipts,
            (value) => setState(() => _showReceipts = value),
          ),
        ],
      ),
    };

    // Determine the industry-specific section to prioritize
    final industrySection = _getIndustrySpecificSection(_selectedIndustry);

    // Build ordered list of sections
    final sectionOrder = <String>['pay', 'earnings'];
    if (industrySection != null) {
      sectionOrder.add(industrySection);
    }
    // Add remaining sections (excluding pay, earnings, and industry-specific)
    sectionOrder.addAll(
      allSections.keys.where((k) => !sectionOrder.contains(k)).toList(),
    );

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: sectionOrder.map<Widget>((key) {
        final widget = allSections[key];
        if (widget == null) return const SizedBox();
        return Column(
          children: [widget, const SizedBox(height: 16)],
        );
      }).toList(),
    );
  }

  /// Get the industry-specific section key for the selected industry
  String? _getIndustrySpecificSection(String? industry) {
    switch (industry) {
      case 'Rideshare & Delivery':
        return 'rideshare';
      case 'Music & Entertainment':
        return 'music';
      case 'Artist & Crafts':
        return 'art';
      case 'Retail/Sales':
        return 'retail';
      default:
        return null;
    }
  }

  /// Build collapsible template section
  Widget _buildTemplateSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.cardBackgroundLight,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          collapsedBackgroundColor: AppTheme.cardBackground,
          backgroundColor: AppTheme.cardBackground,
          textColor: AppTheme.textPrimary,
          iconColor: AppTheme.primaryGreen,
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build template toggle item
  Widget _buildTemplateToggle(
    String label,
    String hint,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  hint,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  /// Build pay structure selector
  Widget _buildPayStructureSelector(JobTemplate template) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you paid?',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Hourly'),
                  selected: _payStructure == PayStructure.hourly,
                  onSelected: (selected) =>
                      setState(() => _payStructure = PayStructure.hourly),
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
                  backgroundColor: AppTheme.cardBackgroundLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Flat Rate'),
                  selected: _payStructure == PayStructure.flatRate,
                  onSelected: (selected) =>
                      setState(() => _payStructure = PayStructure.flatRate),
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
                  backgroundColor: AppTheme.cardBackgroundLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Commission'),
                  selected: _payStructure == PayStructure.commission,
                  onSelected: (selected) =>
                      setState(() => _payStructure = PayStructure.commission),
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
                  backgroundColor: AppTheme.cardBackgroundLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build overtime multiplier
  Widget _buildOvertimeMultiplier(JobTemplate template) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overtime Multiplier',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${_overtimeMultiplier}x',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          Slider(
            value: _overtimeMultiplier,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            activeColor: AppTheme.primaryGreen,
            inactiveColor: AppTheme.cardBackgroundLight,
            onChanged: (value) => setState(() => _overtimeMultiplier = value),
          ),
        ],
      ),
    );
  }

  void _showRateDialog() {
    final controller = TextEditingController(); // Start blank for quick typing

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Edit Hourly Rate', style: AppTheme.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.titleLarge.copyWith(color: AppTheme.primaryGreen),
          decoration: InputDecoration(
            hintText: 'Enter hourly rate (e.g., 15.00)',
            prefixText: '\$ ',
            suffixText: '/hr',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0 && value <= 100000) {
                setState(() {
                  _baseRate = value;
                  _rateController.text = value.toStringAsFixed(2);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomIndustryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Add Custom Industry', style: AppTheme.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Industry name (e.g., Real Estate)',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final customIndustry = controller.text.trim();
              if (customIndustry.isNotEmpty) {
                setState(() {
                  // Add custom industry to the list (before the "+ Add" option)
                  _industries.insert(_industries.length - 1, customIndustry);
                  _selectedIndustry = customIndustry;
                  _selectedJobTitle = null;
                  // Initialize custom job titles list for this industry
                  _customJobTitles[customIndustry] = [];
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

  void _showAddCustomJobTitleDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Add Custom Job Title', style: AppTheme.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Job title (e.g., Event Manager)',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final customJobTitle = controller.text.trim();
              if (customJobTitle.isNotEmpty && _selectedIndustry != null) {
                setState(() {
                  // Add custom job title to the custom list for this industry
                  if (!_customJobTitles.containsKey(_selectedIndustry)) {
                    _customJobTitles[_selectedIndustry!] = [];
                  }
                  if (!_customJobTitles[_selectedIndustry]!
                      .contains(customJobTitle)) {
                    _customJobTitles[_selectedIndustry]!.add(customJobTitle);
                  }
                  _selectedJobTitle = customJobTitle;
                  // Reapply template to ensure fields are set for this job
                  _applyIndustryTemplate(_selectedIndustry);
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
}
