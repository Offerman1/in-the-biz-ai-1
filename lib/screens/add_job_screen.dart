import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/job.dart';
import '../models/job_template.dart';
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
  bool? _showEquipmentRentalCost;
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
  bool? _showShrink;  double _overtimeMultiplier = 1.5;

  bool _isSaving = false;

  final List<String> _industries = [
    'Restaurant/Bar/Nightclub',
    'Construction/Trades',
    'Freelancer/Consultant',
    'Healthcare',
    'Rideshare & Delivery',
    'Music & Entertainment',
    'Artist & Crafts',
    'Retail/Sales',
    'Salon/Spa',
    'Hospitality',
    'Fitness',
    '+ Add Custom Industry',
  ];

  // Job titles by industry
  final Map<String, List<String>> _jobTitlesByIndustry = {
    'Restaurant/Bar/Nightclub': [
      'Server/Waiter',
      'Bartender',
      'Food Runner',
      'Busser',
      'Manager',
      'Hostess',
      'Chef/Sushi Chef',
      'Bar Back',
      'Sommelier',
      'Line Cook',
      'Prep Cook',
      'Expeditor',
      '+ Add Custom Job Title',
    ],
    'Construction/Trades': [
      'Carpenter',
      'Electrician',
      'Plumber',
      'HVAC Technician',
      'General Contractor',
      'Painter',
      'Roofer',
      'Mason',
      'Welder',
      'Landscaper',
      'Drywall Installer',
      'Tile Setter',
      '+ Add Custom Job Title',
    ],
    'Freelancer/Consultant': [
      'Graphic Designer',
      'Web Developer',
      'Photographer',
      'Writer/Copywriter',
      'Marketing Consultant',
      'Business Consultant',
      'Video Editor',
      'Social Media Manager',
      'Virtual Assistant',
      'Translator',
      '+ Add Custom Job Title',
    ],
    'Healthcare': [
      'Nurse (RN/LPN)',
      'CNA (Certified Nursing Assistant)',
      'Medical Assistant',
      'Phlebotomist',
      'Home Health Aide',
      'Physical Therapist',
      'Dental Hygienist',
      'Paramedic/EMT',
      'Pharmacy Technician',
      '+ Add Custom Job Title',
    ],
    'Gig Worker': [
      'Musician',
      'Band Member',
      'DJ',
      'Photographer',
      'Photo Booth Operator',
      'Event Performer',
      'Artist',
      'Rideshare Driver',
      'Delivery Driver',
      'Street Performer',
      '+ Add Custom Job Title',
    ],
    'Rideshare & Delivery': [
      'Uber Driver',
      'Lyft Driver',
      'DoorDash Driver',
      'Uber Eats Driver',
      'Grubhub Driver',
      'Instacart Shopper',
      'Amazon Flex Driver',
      'Local Delivery Driver',
      '+ Add Custom Job Title',
    ],
    'Music & Entertainment': [
      'Musician',
      'Band Member',
      'DJ',
      'Photographer',
      'Photo Booth Operator',
      'Event Performer',
      'Sound Engineer',
      'Live Streamer',
      '+ Add Custom Job Title',
    ],
    'Artist & Crafts': [
      'Painter/Artist',
      'Sculptor',
      'Jewelry Maker',
      'Ceramicist',
      'Street Performer',
      'Craftsperson',
      'Illustrator',
      'Printmaker',
      '+ Add Custom Job Title',
    ],
    'Retail/Sales': [
      'Sales Associate',
      'Cashier',
      'Store Manager',
      'Visual Merchandiser',
      'Stock Associate',
      'Department Manager',
      'Loss Prevention',
      'Sales Representative',
      '+ Add Custom Job Title',
    ],
    'Salon/Spa': [
      'Hair Stylist',
      'Nail Technician',
      'Massage Therapist',
      'Esthetician',
      'Barber',
      'Makeup Artist',
      'Spa Manager',
      'Waxing Specialist',
      '+ Add Custom Job Title',
    ],
    'Hospitality': [
      'Hotel Front Desk',
      'Concierge',
      'Housekeeper',
      'Bellhop/Porter',
      'Event Coordinator',
      'Catering Server',
      'Valet Attendant',
      'Hotel Manager',
      '+ Add Custom Job Title',
    ],
    'Fitness': [
      'Personal Trainer',
      'Yoga Instructor',
      'Gym Manager',
      'Group Fitness Instructor',
      'Spin Instructor',
      'Pilates Instructor',
      'Nutritionist/Dietitian',
      'Fitness Coach',
      '+ Add Custom Job Title',
    ],
  };

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

      // Check if job title exists in the dropdown list for this industry
      final jobTitles = _jobTitlesByIndustry[_selectedIndustry];
      if (jobTitles != null && !jobTitles.contains(job.name)) {
        // Add custom job title to the industry list (before the "+ Add" option)
        jobTitles.insert(jobTitles.length - 1, job.name);
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
    _tracksOvertime = template.tracksOvertime;
    _overtimeMultiplier = template.overtimeMultiplier;
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
      tracksOvertime: _tracksOvertime,
      overtimeMultiplier: _overtimeMultiplier,
    );
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIndustry == null ||
        _selectedIndustry == '+ Add Custom Industry') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an industry'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    if (_selectedJobTitle == null ||
        _selectedJobTitle == '+ Add Custom Job Title') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a job title'),
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
          name: _selectedJobTitle!,
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
        name: _selectedJobTitle!,
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

            // Industry Dropdown (FIRST)
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
                    _selectedJobTitle =
                        null; // Reset job title when industry changes
                    // Update template settings based on industry
                    _applyIndustryTemplate(value);
                  });
                }
              },
              validator: (value) {
                if (value == null || value == '+ Add Custom Industry') {
                  return 'Please select an industry';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Job Title (SECOND) - Dropdown when industry is selected
            if (_selectedIndustry != null &&
                _selectedIndustry != '+ Add Custom Industry')
              DropdownButtonFormField<String>(
                value: _selectedJobTitle,
                decoration: InputDecoration(
                  hintText: 'Select your job title',
                  prefixIcon: Icon(Icons.work, color: AppTheme.primaryGreen),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: AppTheme.cardBackground,
                style: AppTheme.bodyLarge.copyWith(
                  color: _selectedJobTitle == null ||
                          _selectedJobTitle == '+ Add Custom Job Title'
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                ),
                hint: Text(
                  'Select a job title',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                items: (_jobTitlesByIndustry[_selectedIndustry] ?? [])
                    .map((jobTitle) {
                  return DropdownMenuItem(
                    value: jobTitle,
                    child: Text(
                      jobTitle,
                      style: AppTheme.bodyLarge.copyWith(
                        color: jobTitle == '+ Add Custom Job Title'
                            ? AppTheme.primaryGreen
                            : AppTheme.textPrimary,
                        fontWeight: jobTitle == '+ Add Custom Job Title'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == '+ Add Custom Job Title') {
                    _showAddCustomJobTitleDialog();
                  } else {
                    setState(() => _selectedJobTitle = value);
                  }
                },
                validator: (value) {
                  if (value == null || value == '+ Add Custom Job Title') {
                    return 'Please select a job title';
                  }
                  return null;
                },
              ),

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.accentYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: AppTheme.accentYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tip Out Settings (Optional)',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                          borderSide: BorderSide(color: AppTheme.primaryGreen),
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
                          borderSide: BorderSide(color: AppTheme.primaryGreen),
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
    );
  }

  Widget _buildOrganizedShiftFields() {
    // Build the template based on current selections to show all available fields
    final currentTemplate = _buildTemplate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 💰 Income Tracking
        _buildFieldCategory(
          '💰 Income Tracking',
          [
            if (currentTemplate.showTips)
              _buildToggleItem('Tips', _showTips, Icons.attach_money, () {
                setState(() => _showTips = !_showTips);
              }),
            if (currentTemplate.showSales)
              _buildToggleItem('Sales Amount', _showSales, Icons.shopping_cart,
                  () {
                setState(() => _showSales = !_showSales);
              }),
            if (currentTemplate.showCommission)
              _buildToggleItem('Commission', _showCommission, Icons.sell, () {
                setState(() => _showCommission = !_showCommission);
              }),
            if (currentTemplate.showBaseFare)
              _buildToggleItem(
                  'Base Fare', _showBaseFare ?? true, Icons.trending_up, () {
                setState(() => _showBaseFare = !(_showBaseFare ?? false));
              }),
          ].where((w) => w != null).cast<Widget>().toList(),
        ),

        const SizedBox(height: 20),

        // 📋 Job Details
        _buildFieldCategory(
          '📋 Job Details',
          [
            if (currentTemplate.showEventName)
              _buildToggleItem('Event Name', _showEventName, Icons.celebration,
                  () {
                setState(() => _showEventName = !_showEventName);
              }),
            if (currentTemplate.showEventCost)
              _buildToggleItem('Event Cost', _showEventCost, Icons.payments,
                  () {
                setState(() => _showEventCost = !_showEventCost);
              }),
            if (currentTemplate.showLocation)
              _buildToggleItem('Location', _showLocation, Icons.location_on,
                  () {
                setState(() => _showLocation = !_showLocation);
              }),
            if (currentTemplate.showClientName)
              _buildToggleItem(
                  'Client Name', _showClientName, Icons.person_outline, () {
                setState(() => _showClientName = !_showClientName);
              }),
            if (currentTemplate.showProjectName)
              _buildToggleItem('Project', _showProjectName, Icons.folder, () {
                setState(() => _showProjectName = !_showProjectName);
              }),
          ].where((w) => w != null).cast<Widget>().toList(),
        ),

        const SizedBox(height: 20),

        // 👥 People & Guests
        _buildFieldCategory(
          '👥 People & Guests',
          [
            if (currentTemplate.showHostess)
              _buildToggleItem('Hostess', _showHostess, Icons.person, () {
                setState(() => _showHostess = !_showHostess);
              }),
            if (currentTemplate.showGuestCount)
              _buildToggleItem('Guest Count', _showGuestCount, Icons.groups,
                  () {
                setState(() => _showGuestCount = !_showGuestCount);
              }),
          ].where((w) => w != null).cast<Widget>().toList(),
        ),

        const SizedBox(height: 20),

        // 🚗 Expenses & Rideshare
        if (currentTemplate.showMileage ||
            currentTemplate.showRidesCount ||
            currentTemplate.showDeadMiles ||
            currentTemplate.showFuelCost ||
            currentTemplate.showTollsParking)
          _buildFieldCategory(
            '🚗 Rideshare & Delivery',
            [
              if (currentTemplate.showRidesCount)
                _buildToggleItem(
                    'Rides Count', _showRidesCount ?? true, Icons.local_taxi,
                    () {
                  setState(() => _showRidesCount = !(_showRidesCount ?? false));
                }),
              if (currentTemplate.showDeadMiles)
                _buildToggleItem('Deadhead Miles', _showDeadMiles ?? true,
                    Icons.trending_down, () {
                  setState(() => _showDeadMiles = !(_showDeadMiles ?? false));
                }),
              if (currentTemplate.showFuelCost)
                _buildToggleItem(
                    'Fuel Cost', _showFuelCost ?? true, Icons.local_gas_station,
                    () {
                  setState(() => _showFuelCost = !(_showFuelCost ?? false));
                }),
              if (currentTemplate.showTollsParking)
                _buildToggleItem(
                    'Tolls & Parking', _showTollsParking ?? true, Icons.paid,
                    () {
                  setState(
                      () => _showTollsParking = !(_showTollsParking ?? false));
                }),
              if (currentTemplate.showSurgeMultiplier)
                _buildToggleItem('Surge Multiplier',
                    _showSurgeMultiplier ?? true, Icons.trending_up, () {
                  setState(() =>
                      _showSurgeMultiplier = !(_showSurgeMultiplier ?? false));
                }),
              if (currentTemplate.showMileage)
                _buildToggleItem('Mileage', _showMileage, Icons.directions_car,
                    () {
                  setState(() => _showMileage = !_showMileage);
                }),
            ].where((w) => w != null).cast<Widget>().toList(),
          ),

        if (currentTemplate.showMileage ||
            currentTemplate.showRidesCount ||
            currentTemplate.showDeadMiles ||
            currentTemplate.showFuelCost ||
            currentTemplate.showTollsParking)
          const SizedBox(height: 20),

        // 🎵 Music & Entertainment
        if (currentTemplate.showGigType ||
            currentTemplate.showSetupHours ||
            currentTemplate.showPerformanceHours ||
            currentTemplate.showBreakdownHours ||
            currentTemplate.showEquipmentUsed ||
            currentTemplate.showEquipmentRentalCost ||
            currentTemplate.showCrewPayment ||
            currentTemplate.showMerchSales ||
            currentTemplate.showAudienceSize)
          _buildFieldCategory(
            '🎵 Music & Entertainment',
            [
              if (currentTemplate.showGigType)
                _buildToggleItem(
                    'Gig Type', _showGigType ?? true, Icons.music_note, () {
                  setState(() => _showGigType = !(_showGigType ?? false));
                }),
              if (currentTemplate.showSetupHours)
                _buildToggleItem(
                    'Setup Hours', _showSetupHours ?? true, Icons.construction,
                    () {
                  setState(() => _showSetupHours = !(_showSetupHours ?? false));
                }),
              if (currentTemplate.showPerformanceHours)
                _buildToggleItem('Performance Hours',
                    _showPerformanceHours ?? true, Icons.play_circle, () {
                  setState(() => _showPerformanceHours =
                      !(_showPerformanceHours ?? false));
                }),
              if (currentTemplate.showBreakdownHours)
                _buildToggleItem('Breakdown Hours', _showBreakdownHours ?? true,
                    Icons.storage, () {
                  setState(() =>
                      _showBreakdownHours = !(_showBreakdownHours ?? false));
                }),
              if (currentTemplate.showEquipmentRentalCost)
                _buildToggleItem('Equipment Rental',
                    _showEquipmentRentalCost ?? true, Icons.devices, () {
                  setState(() => _showEquipmentRentalCost =
                      !(_showEquipmentRentalCost ?? false));
                }),
              if (currentTemplate.showCrewPayment)
                _buildToggleItem(
                    'Crew Payment', _showCrewPayment ?? true, Icons.people, () {
                  setState(
                      () => _showCrewPayment = !(_showCrewPayment ?? false));
                }),
              if (currentTemplate.showMerchSales)
                _buildToggleItem(
                    'Merch Sales', _showMerchSales ?? true, Icons.store, () {
                  setState(() => _showMerchSales = !(_showMerchSales ?? false));
                }),
              if (currentTemplate.showAudienceSize)
                _buildToggleItem(
                    'Audience Size', _showAudienceSize ?? true, Icons.groups,
                    () {
                  setState(
                      () => _showAudienceSize = !(_showAudienceSize ?? false));
                }),
            ].where((w) => w != null).cast<Widget>().toList(),
          ),

        if (currentTemplate.showGigType ||
            currentTemplate.showSetupHours ||
            currentTemplate.showPerformanceHours ||
            currentTemplate.showBreakdownHours ||
            currentTemplate.showEquipmentUsed ||
            currentTemplate.showEquipmentRentalCost ||
            currentTemplate.showCrewPayment ||
            currentTemplate.showMerchSales ||
            currentTemplate.showAudienceSize)
          const SizedBox(height: 20),

        // 🎨 Art & Crafts
        if (currentTemplate.showPiecesCreated ||
            currentTemplate.showPiecesSold ||
            currentTemplate.showMaterialsCost ||
            currentTemplate.showSalePrice ||
            currentTemplate.showVenueCommissionPercent)
          _buildFieldCategory(
            '🎨 Art & Crafts',
            [
              if (currentTemplate.showPiecesCreated)
                _buildToggleItem(
                    'Pieces Created', _showPiecesCreated ?? true, Icons.palette,
                    () {
                  setState(() =>
                      _showPiecesCreated = !(_showPiecesCreated ?? false));
                }),
              if (currentTemplate.showPiecesSold)
                _buildToggleItem(
                    'Pieces Sold', _showPiecesSold ?? true, Icons.shopping_cart,
                    () {
                  setState(() => _showPiecesSold = !(_showPiecesSold ?? false));
                }),
              if (currentTemplate.showMaterialsCost)
                _buildToggleItem('Materials Cost', _showMaterialsCost ?? true,
                    Icons.shopping_bag, () {
                  setState(() =>
                      _showMaterialsCost = !(_showMaterialsCost ?? false));
                }),
              if (currentTemplate.showSalePrice)
                _buildToggleItem(
                    'Sale Price', _showSalePrice ?? true, Icons.attach_money,
                    () {
                  setState(() => _showSalePrice = !(_showSalePrice ?? false));
                }),
              if (currentTemplate.showVenueCommission)
                _buildToggleItem('Venue Commission %',
                    _showVenueCommission ?? true, Icons.percent, () {
                  setState(() => _showVenueCommission =
                      !(_showVenueCommission ?? false));
                }),
            ].where((w) => w != null).cast<Widget>().toList(),
          ),

        if (currentTemplate.showPiecesCreated ||
            currentTemplate.showPiecesSold ||
            currentTemplate.showMaterialsCost ||
            currentTemplate.showSalePrice ||
            currentTemplate.showVenueCommissionPercent)
          const SizedBox(height: 20),

        // 💼 Retail & Sales
        if (currentTemplate.showItemsSold ||
            currentTemplate.showTransactionsCount ||
            currentTemplate.showUpsellsCount ||
            currentTemplate.showReturnsCount ||
            currentTemplate.showShrinkAmount)
          _buildFieldCategory(
            '💼 Retail & Sales',
            [
              if (currentTemplate.showItemsSold)
                _buildToggleItem(
                    'Items Sold', _showItemsSold ?? true, Icons.shopping_cart,
                    () {
                  setState(() => _showItemsSold = !(_showItemsSold ?? false));
                }),
              if (currentTemplate.showTransactionsCount)
                _buildToggleItem('Transactions', _showTransactionsCount ?? true,
                    Icons.receipt, () {
                  setState(() => _showTransactionsCount =
                      !(_showTransactionsCount ?? false));
                }),
              if (currentTemplate.showUpsellsCount)
                _buildToggleItem(
                    'Upsells', _showUpsellsCount ?? true, Icons.trending_up,
                    () {
                  setState(
                      () => _showUpsellsCount = !(_showUpsellsCount ?? false));
                }),
              if (currentTemplate.showReturnsCount)
                _buildToggleItem(
                    'Returns', _showReturnsCount ?? true, Icons.keyboard_return,
                    () {
                  setState(
                      () => _showReturnsCount = !(_showReturnsCount ?? false));
                }),
              if (currentTemplate.showShrinkAmount)
                _buildToggleItem(
                    'Shrink', _showShrinkAmount ?? true, Icons.warning, () {
                  setState(
                      () => _showShrinkAmount = !(_showShrinkAmount ?? false));
                }),
            ].where((w) => w != null).cast<Widget>().toList(),
          ),

        if (currentTemplate.showItemsSold ||
            currentTemplate.showTransactionsCount ||
            currentTemplate.showUpsellsCount ||
            currentTemplate.showReturnsCount ||
            currentTemplate.showShrinkAmount)
          const SizedBox(height: 20),

        // 📝 Documentation
        _buildFieldCategory(
          '📝 Documentation',
          [
            if (currentTemplate.showNotes)
              _buildToggleItem('Notes', _showNotes, Icons.note, () {
                setState(() => _showNotes = !_showNotes);
              }),
            if (currentTemplate.showPhotos)
              _buildToggleItem('Photos', true, Icons.camera_alt, () {}),
          ].where((w) => w != null).cast<Widget>().toList(),
        ),

        const SizedBox(height: 20),

        // ⏰ Time Tracking
        _buildFieldCategory(
          '⏰ Time Tracking',
          [
            if (currentTemplate.tracksOvertime)
              _buildToggleItem('Overtime', _tracksOvertime, Icons.access_time,
                  () {
                setState(() => _tracksOvertime = !_tracksOvertime);
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldCategory(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...fields,
      ],
    );
  }

  Widget _buildToggleItem(
      String title, bool value, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.primaryGreen.withOpacity(0.12)
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color:
                  value ? AppTheme.primaryGreen : AppTheme.cardBackgroundLight,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: value ? AppTheme.primaryGreen : AppTheme.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: value
                        ? AppTheme.adaptiveTextColor
                        : AppTheme.textSecondary,
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // Toggle Switch
              Container(
                width: 46,
                height: 26,
                decoration: BoxDecoration(
                  color: value
                      ? AppTheme.primaryGreen
                      : AppTheme.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  // Add empty job titles list for custom industry
                  _jobTitlesByIndustry[customIndustry] = [
                    '+ Add Custom Job Title',
                  ];
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
                  // Add custom job title to the industry list (before the "+ Add" option)
                  final jobTitles = _jobTitlesByIndustry[_selectedIndustry!]!;
                  jobTitles.insert(jobTitles.length - 1, customJobTitle);
                  _selectedJobTitle = customJobTitle;
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
