import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/shift.dart';
import '../models/job.dart';
import '../models/job_template.dart';
import '../models/event_contact.dart';
import '../models/shift_attachment.dart';
import '../providers/shift_provider.dart';
import '../providers/field_order_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/hero_card.dart';
import '../widgets/navigation_wrapper.dart';
import 'onboarding_screen.dart';
import 'add_job_screen.dart';
import 'settings_screen.dart';
import 'event_contacts_screen.dart';
import 'add_edit_contact_screen.dart';
import 'document_scanner_screen.dart';
import 'scan_verification_screen.dart';
import 'paywall_screen.dart';
import '../widgets/scan_type_menu.dart';
import '../models/vision_scan.dart';
import '../services/vision_scanner_service.dart';

class AddShiftScreen extends StatefulWidget {
  final Shift? existingShift;
  final String? aiAnalysis;
  final Uint8List? imageBytes;
  final DateTime? preselectedDate;

  const AddShiftScreen({
    super.key,
    this.existingShift,
    this.aiAnalysis,
    this.imageBytes,
    this.preselectedDate,
  });

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final VisionScannerService _visionScanner = VisionScannerService();

  // Controllers for all possible fields
  final _cashTipsController = TextEditingController();
  final _creditTipsController = TextEditingController();
  final _salesAmountController = TextEditingController(); // NEW
  final _tipoutPercentController = TextEditingController(); // NEW - Percentage
  final _additionalTipoutController =
      TextEditingController(); // NEW - Extra cash
  final _additionalTipoutNoteController =
      TextEditingController(); // NEW - Who received it
  final _commissionController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _eventCostController = TextEditingController(); // NEW
  final _hostessController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _locationController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();
  final _hoursWorkedController = TextEditingController();
  final _overtimeHoursController = TextEditingController();
  final _flatRateController = TextEditingController();
  final _hourlyRateOverrideController = TextEditingController();

  // =====================================================
  // RIDESHARE & DELIVERY CONTROLLERS
  // =====================================================
  final _ridesCountController = TextEditingController();
  final _deliveriesCountController = TextEditingController();
  final _deadMilesController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _tollsParkingController = TextEditingController();
  final _surgeMultiplierController = TextEditingController();
  final _acceptanceRateController = TextEditingController();
  final _baseFareController = TextEditingController();

  // =====================================================
  // MUSIC & ENTERTAINMENT CONTROLLERS
  // =====================================================
  final _gigTypeController = TextEditingController();
  final _setupHoursController = TextEditingController();
  final _performanceHoursController = TextEditingController();
  final _breakdownHoursController = TextEditingController();
  final _equipmentUsedController = TextEditingController();
  final _equipmentRentalCostController = TextEditingController();
  final _crewPaymentController = TextEditingController();
  final _merchSalesController = TextEditingController();
  final _audienceSizeController = TextEditingController();

  // =====================================================
  // ARTIST & CRAFTS CONTROLLERS
  // =====================================================
  final _piecesCreatedController = TextEditingController();
  final _piecesSoldController = TextEditingController();
  final _materialsCostController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _venueCommissionPercentController = TextEditingController();

  // =====================================================
  // RETAIL/SALES CONTROLLERS
  // =====================================================
  final _itemsSoldController = TextEditingController();
  final _transactionsCountController = TextEditingController();
  final _upsellsCountController = TextEditingController();
  final _upsellsAmountController = TextEditingController();
  final _returnsCountController = TextEditingController();
  final _returnsAmountController = TextEditingController();
  final _shrinkAmountController = TextEditingController();
  final _departmentController = TextEditingController();

  // =====================================================
  // SALON/SPA CONTROLLERS
  // =====================================================
  final _serviceTypeController = TextEditingController();
  final _servicesCountController = TextEditingController();
  final _productSalesController = TextEditingController();
  final _repeatClientPercentController = TextEditingController();
  final _chairRentalController = TextEditingController();
  final _newClientsCountController = TextEditingController();
  final _returningClientsCountController = TextEditingController();
  final _walkinCountController = TextEditingController();
  final _appointmentCountController = TextEditingController();

  // =====================================================
  // HOSPITALITY CONTROLLERS
  // =====================================================
  final _roomTypeController = TextEditingController();
  final _roomsCleanedController = TextEditingController();
  final _qualityScoreController = TextEditingController();
  final _shiftTypeController = TextEditingController();
  final _roomUpgradesController = TextEditingController();
  final _guestsCheckedInController = TextEditingController();
  final _carsParkedController = TextEditingController();

  // =====================================================
  // HEALTHCARE CONTROLLERS
  // =====================================================
  final _patientCountController = TextEditingController();
  final _shiftDifferentialController = TextEditingController();
  final _onCallHoursController = TextEditingController();
  final _proceduresCountController = TextEditingController();
  final _specializationController = TextEditingController();

  // =====================================================
  // FITNESS CONTROLLERS
  // =====================================================
  final _sessionsCountController = TextEditingController();
  final _sessionTypeController = TextEditingController();
  final _classSizeController = TextEditingController();
  final _retentionRateController = TextEditingController();
  final _cancellationsCountController = TextEditingController();
  final _packageSalesController = TextEditingController();
  final _supplementSalesController = TextEditingController();

  // =====================================================
  // CONSTRUCTION/TRADES CONTROLLERS
  // =====================================================
  final _laborCostController = TextEditingController();
  final _subcontractorCostController = TextEditingController();
  final _squareFootageController = TextEditingController();
  final _weatherDelayHoursController = TextEditingController();

  // =====================================================
  // FREELANCER CONTROLLERS
  // =====================================================
  final _revisionsCountController = TextEditingController();
  final _clientTypeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _billableHoursController = TextEditingController();

  // =====================================================
  // RESTAURANT ADDITIONAL CONTROLLERS
  // =====================================================
  final _tableSectionController = TextEditingController();
  final _cashSalesController = TextEditingController();
  final _cardSalesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Job? _selectedJob;
  bool _useHourlyRateOverride = false;
  JobTemplate? _template;
  List<Job> _userJobs = [];
  bool _loadingJobs = true;
  bool _isSaving = false;
  final List<String> _capturedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  // Event contacts and attachments
  List<EventContact> _eventContacts = [];
  bool _isLoadingContacts = false;
  List<ShiftAttachment> _attachments = [];
  bool _isLoadingAttachments = false;
  bool _isUploadingAttachment = false;

  // Recurring shift fields
  bool _isRecurring = false;
  List<int> _selectedWeekdays = []; // 1=Mon, 7=Sun

  @override
  void initState() {
    super.initState();
    // Set initial date from preselectedDate or default to today
    _selectedDate = widget.preselectedDate ?? DateTime.now();
    _loadUserJobs();
    if (widget.existingShift != null) {
      _loadExistingShift();
      _loadEventContacts();
      _loadAttachments();
    }
    if (widget.aiAnalysis != null) {
      _parseAiAnalysis();
    }
  }

  /// Parse AI analysis data and pre-fill form fields
  void _parseAiAnalysis() {
    try {
      final data = jsonDecode(widget.aiAnalysis!) as Map<String, dynamic>;

      // Pre-fill tips
      if (data['cash_tips'] != null) {
        _cashTipsController.text = data['cash_tips'].toString();
      }
      if (data['credit_tips'] != null) {
        _creditTipsController.text = data['credit_tips'].toString();
      }

      // Pre-fill hours
      if (data['hours_worked'] != null) {
        _hoursWorkedController.text = data['hours_worked'].toString();
      }

      // Pre-fill commission
      if (data['commission'] != null) {
        _commissionController.text = data['commission'].toString();
      }

      // Pre-fill event details
      if (data['event_name'] != null) {
        _eventNameController.text = data['event_name'].toString();
      }
      if (data['guest_count'] != null) {
        _guestCountController.text = data['guest_count'].toString();
      }

      // Pre-fill notes (AI-generated summary)
      if (data['notes'] != null) {
        _notesController.text = data['notes'].toString();
      }

      // Pre-fill flat rate if detected
      if (data['flat_rate'] != null) {
        _flatRateController.text = data['flat_rate'].toString();
      }

      // Pre-fill mileage if detected
      if (data['mileage'] != null) {
        _mileageController.text = data['mileage'].toString();
      }
    } catch (e) {
      // If parsing fails, just ignore and let user fill manually
      debugPrint('Error parsing AI analysis: $e');
    }
  }

  Future<void> _loadUserJobs() async {
    setState(() => _loadingJobs = true);
    try {
      final jobsData = await _db.getJobs();
      final jobs = jobsData.map((j) => Job.fromSupabase(j)).toList();
      setState(() {
        _userJobs = jobs;
        if (jobs.isNotEmpty) {
          // Select default job or first job
          _selectedJob =
              jobs.firstWhere((j) => j.isDefault, orElse: () => jobs.first);
          _template = _selectedJob?.template;
        }
        _loadingJobs = false;
      });
    } catch (e) {
      setState(() => _loadingJobs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  void _loadExistingShift() {
    final shift = widget.existingShift!;
    _selectedDate = shift.date;
    _cashTipsController.text = shift.cashTips.toString();
    _creditTipsController.text = shift.creditTips.toString();
    _hoursWorkedController.text = shift.hoursWorked.toString();
    _commissionController.text = (shift.commission ?? 0).toString();
    _eventNameController.text = shift.eventName ?? '';
    _hostessController.text = shift.hostess ?? '';
    _guestCountController.text = shift.guestCount?.toString() ?? '';
    _locationController.text = shift.location ?? '';
    _clientNameController.text = shift.clientName ?? '';
    _projectNameController.text = shift.projectName ?? '';
    _mileageController.text = (shift.mileage ?? 0).toString();
    _notesController.text = shift.notes ?? '';
    _overtimeHoursController.text = (shift.overtimeHours ?? 0).toString();
    _flatRateController.text = (shift.flatRate ?? 0).toString();
    _hourlyRateOverrideController.text = shift.hourlyRate.toString();
    _salesAmountController.text = shift.salesAmount?.toString() ?? '';
    _tipoutPercentController.text = shift.tipoutPercent?.toString() ?? '';
    _additionalTipoutController.text = shift.additionalTipout?.toString() ?? '';
    _additionalTipoutNoteController.text = shift.additionalTipoutNote ?? '';
    _eventCostController.text = shift.eventCost?.toString() ?? '';

    // =====================================================
    // RIDESHARE & DELIVERY FIELDS
    // =====================================================
    _ridesCountController.text = shift.ridesCount?.toString() ?? '';
    _deliveriesCountController.text = shift.deliveriesCount?.toString() ?? '';
    _deadMilesController.text = shift.deadMiles?.toString() ?? '';
    _fuelCostController.text = shift.fuelCost?.toString() ?? '';
    _tollsParkingController.text = shift.tollsParking?.toString() ?? '';
    _surgeMultiplierController.text = shift.surgeMultiplier?.toString() ?? '';
    _acceptanceRateController.text = shift.acceptanceRate?.toString() ?? '';
    _baseFareController.text = shift.baseFare?.toString() ?? '';

    // =====================================================
    // MUSIC & ENTERTAINMENT FIELDS
    // =====================================================
    _gigTypeController.text = shift.gigType ?? '';
    _setupHoursController.text = shift.setupHours?.toString() ?? '';
    _performanceHoursController.text = shift.performanceHours?.toString() ?? '';
    _breakdownHoursController.text = shift.breakdownHours?.toString() ?? '';
    _equipmentUsedController.text = shift.equipmentUsed ?? '';
    _equipmentRentalCostController.text =
        shift.equipmentRentalCost?.toString() ?? '';
    _crewPaymentController.text = shift.crewPayment?.toString() ?? '';
    _merchSalesController.text = shift.merchSales?.toString() ?? '';
    _audienceSizeController.text = shift.audienceSize?.toString() ?? '';

    // =====================================================
    // ARTIST & CRAFTS FIELDS
    // =====================================================
    _piecesCreatedController.text = shift.piecesCreated?.toString() ?? '';
    _piecesSoldController.text = shift.piecesSold?.toString() ?? '';
    _materialsCostController.text = shift.materialsCost?.toString() ?? '';
    _salePriceController.text = shift.salePrice?.toString() ?? '';
    _venueCommissionPercentController.text =
        shift.venueCommissionPercent?.toString() ?? '';

    // =====================================================
    // RETAIL/SALES FIELDS
    // =====================================================
    _itemsSoldController.text = shift.itemsSold?.toString() ?? '';
    _transactionsCountController.text =
        shift.transactionsCount?.toString() ?? '';
    _upsellsCountController.text = shift.upsellsCount?.toString() ?? '';
    _upsellsAmountController.text = shift.upsellsAmount?.toString() ?? '';
    _returnsCountController.text = shift.returnsCount?.toString() ?? '';
    _returnsAmountController.text = shift.returnsAmount?.toString() ?? '';
    _shrinkAmountController.text = shift.shrinkAmount?.toString() ?? '';
    _departmentController.text = shift.department ?? '';

    // =====================================================
    // SALON/SPA FIELDS
    // =====================================================
    _serviceTypeController.text = shift.serviceType ?? '';
    _servicesCountController.text = shift.servicesCount?.toString() ?? '';
    _productSalesController.text = shift.productSales?.toString() ?? '';
    _repeatClientPercentController.text =
        shift.repeatClientPercent?.toString() ?? '';
    _chairRentalController.text = shift.chairRental?.toString() ?? '';
    _newClientsCountController.text = shift.newClientsCount?.toString() ?? '';
    _returningClientsCountController.text =
        shift.returningClientsCount?.toString() ?? '';
    _walkinCountController.text = shift.walkinCount?.toString() ?? '';
    _appointmentCountController.text = shift.appointmentCount?.toString() ?? '';

    // =====================================================
    // HOSPITALITY FIELDS
    // =====================================================
    _roomTypeController.text = shift.roomType ?? '';
    _roomsCleanedController.text = shift.roomsCleaned?.toString() ?? '';
    _qualityScoreController.text = shift.qualityScore?.toString() ?? '';
    _shiftTypeController.text = shift.shiftType ?? '';
    _roomUpgradesController.text = shift.roomUpgrades?.toString() ?? '';
    _guestsCheckedInController.text = shift.guestsCheckedIn?.toString() ?? '';
    _carsParkedController.text = shift.carsParked?.toString() ?? '';

    // =====================================================
    // HEALTHCARE FIELDS
    // =====================================================
    _patientCountController.text = shift.patientCount?.toString() ?? '';
    _shiftDifferentialController.text =
        shift.shiftDifferential?.toString() ?? '';
    _onCallHoursController.text = shift.onCallHours?.toString() ?? '';
    _proceduresCountController.text = shift.proceduresCount?.toString() ?? '';
    _specializationController.text = shift.specialization ?? '';

    // =====================================================
    // FITNESS FIELDS
    // =====================================================
    _sessionsCountController.text = shift.sessionsCount?.toString() ?? '';
    _sessionTypeController.text = shift.sessionType ?? '';
    _classSizeController.text = shift.classSize?.toString() ?? '';
    _retentionRateController.text = shift.retentionRate?.toString() ?? '';
    _cancellationsCountController.text =
        shift.cancellationsCount?.toString() ?? '';
    _packageSalesController.text = shift.packageSales?.toString() ?? '';
    _supplementSalesController.text = shift.supplementSales?.toString() ?? '';

    // =====================================================
    // CONSTRUCTION/TRADES FIELDS
    // =====================================================
    _laborCostController.text = shift.laborCost?.toString() ?? '';
    _subcontractorCostController.text =
        shift.subcontractorCost?.toString() ?? '';
    _squareFootageController.text = shift.squareFootage?.toString() ?? '';
    _weatherDelayHoursController.text =
        shift.weatherDelayHours?.toString() ?? '';

    // =====================================================
    // FREELANCER FIELDS
    // =====================================================
    _revisionsCountController.text = shift.revisionsCount?.toString() ?? '';
    _clientTypeController.text = shift.clientType ?? '';
    _expensesController.text = shift.expenses?.toString() ?? '';
    _billableHoursController.text = shift.billableHours?.toString() ?? '';

    // =====================================================
    // RESTAURANT ADDITIONAL FIELDS
    // =====================================================
    _tableSectionController.text = shift.tableSection ?? '';
    _cashSalesController.text = shift.cashSales?.toString() ?? '';
    _cardSalesController.text = shift.cardSales?.toString() ?? '';

    // Parse times if available
    if (shift.startTime != null) {
      final parts = shift.startTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1].substring(0, 2)),
      );
    }
    if (shift.endTime != null) {
      final parts = shift.endTime!.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1].substring(0, 2)),
      );
    }
  }

  @override
  void dispose() {
    _cashTipsController.dispose();
    _creditTipsController.dispose();
    _salesAmountController.dispose();
    _tipoutPercentController.dispose();
    _additionalTipoutController.dispose();
    _additionalTipoutNoteController.dispose();
    _commissionController.dispose();
    _eventNameController.dispose();
    _eventCostController.dispose();
    _hostessController.dispose();
    _guestCountController.dispose();
    _locationController.dispose();
    _clientNameController.dispose();
    _projectNameController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    _hoursWorkedController.dispose();
    _overtimeHoursController.dispose();
    _flatRateController.dispose();
    _hourlyRateOverrideController.dispose();
    // Rideshare & Delivery
    _ridesCountController.dispose();
    _deliveriesCountController.dispose();
    _deadMilesController.dispose();
    _fuelCostController.dispose();
    _tollsParkingController.dispose();
    _surgeMultiplierController.dispose();
    _acceptanceRateController.dispose();
    _baseFareController.dispose();
    // Music & Entertainment
    _gigTypeController.dispose();
    _setupHoursController.dispose();
    _performanceHoursController.dispose();
    _breakdownHoursController.dispose();
    _equipmentUsedController.dispose();
    _equipmentRentalCostController.dispose();
    _crewPaymentController.dispose();
    _merchSalesController.dispose();
    _audienceSizeController.dispose();
    // Artist & Crafts
    _piecesCreatedController.dispose();
    _piecesSoldController.dispose();
    _materialsCostController.dispose();
    _salePriceController.dispose();
    _venueCommissionPercentController.dispose();
    // Retail/Sales
    _itemsSoldController.dispose();
    _transactionsCountController.dispose();
    _upsellsCountController.dispose();
    _upsellsAmountController.dispose();
    _returnsCountController.dispose();
    _returnsAmountController.dispose();
    _shrinkAmountController.dispose();
    _departmentController.dispose();
    // Salon/Spa
    _serviceTypeController.dispose();
    _servicesCountController.dispose();
    _productSalesController.dispose();
    _repeatClientPercentController.dispose();
    _chairRentalController.dispose();
    _newClientsCountController.dispose();
    _returningClientsCountController.dispose();
    _walkinCountController.dispose();
    _appointmentCountController.dispose();
    // Hospitality
    _roomTypeController.dispose();
    _roomsCleanedController.dispose();
    _qualityScoreController.dispose();
    _shiftTypeController.dispose();
    _roomUpgradesController.dispose();
    _guestsCheckedInController.dispose();
    _carsParkedController.dispose();
    // Healthcare
    _patientCountController.dispose();
    _shiftDifferentialController.dispose();
    _onCallHoursController.dispose();
    _proceduresCountController.dispose();
    _specializationController.dispose();
    // Fitness
    _sessionsCountController.dispose();
    _sessionTypeController.dispose();
    _classSizeController.dispose();
    _retentionRateController.dispose();
    _cancellationsCountController.dispose();
    _packageSalesController.dispose();
    _supplementSalesController.dispose();
    // Construction/Trades
    _laborCostController.dispose();
    _subcontractorCostController.dispose();
    _squareFootageController.dispose();
    _weatherDelayHoursController.dispose();
    // Freelancer
    _revisionsCountController.dispose();
    _clientTypeController.dispose();
    _expensesController.dispose();
    _billableHoursController.dispose();
    // Restaurant Additional
    _tableSectionController.dispose();
    _cashSalesController.dispose();
    _cardSalesController.dispose();
    super.dispose();
  }

  Future<void> _showRateOverrideDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text('Override Hourly Rate?', style: AppTheme.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a one-time override for this shift only.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your default rate: \$${(_selectedJob?.hourlyRate ?? 0).toStringAsFixed(2)}/hr',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'If you want this change to apply to all future shifts, please adjust your hourly rate in Job Settings.',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(),
                  ),
                );
              },
              icon:
                  Icon(Icons.settings, size: 16, color: AppTheme.primaryGreen),
              label: Text('Go to Job Settings',
                  style: TextStyle(color: AppTheme.primaryGreen)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryGreen),
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
            child: const Text('Override for This Shift'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _useHourlyRateOverride = true;
        if (_hourlyRateOverrideController.text.isEmpty) {
          _hourlyRateOverrideController.text =
              (_selectedJob?.hourlyRate ?? 0).toStringAsFixed(2);
        }
      });
    }
  }

  Future<void> _saveShift() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job')),
      );
      return;
    }

    // Check for Pro status and show ad if needed (Mobile only)
    if (!kIsWeb) {
      final subscriptionService =
          Provider.of<SubscriptionService>(context, listen: false);
      if (!subscriptionService.isPro) {
        await AdService().showInterstitialAd();
      }
    }

    setState(() => _isSaving = true);

    try {
      // Determine which hourly rate to use
      final effectiveHourlyRate = _useHourlyRateOverride
          ? (double.tryParse(_hourlyRateOverrideController.text) ??
              _selectedJob!.hourlyRate)
          : _selectedJob!.hourlyRate;

      final shift = Shift(
        id: widget.existingShift?.id ?? const Uuid().v4(),
        date: _selectedDate,
        cashTips: double.tryParse(_cashTipsController.text) ?? 0,
        creditTips: double.tryParse(_creditTipsController.text) ?? 0,
        salesAmount: double.tryParse(_salesAmountController.text),
        tipoutPercent: double.tryParse(_tipoutPercentController.text),
        additionalTipout: double.tryParse(_additionalTipoutController.text),
        additionalTipoutNote:
            _additionalTipoutNoteController.text.trim().isNotEmpty
                ? _additionalTipoutNoteController.text.trim()
                : null,
        hourlyRate: effectiveHourlyRate,
        hoursWorked: double.tryParse(_hoursWorkedController.text) ?? 0,
        startTime: _startTime != null ? _formatTime(_startTime!) : null,
        endTime: _endTime != null ? _formatTime(_endTime!) : null,
        eventName: _eventNameController.text.trim().isNotEmpty
            ? _eventNameController.text.trim()
            : null,
        eventCost: double.tryParse(_eventCostController.text),
        hostess: _hostessController.text.trim().isNotEmpty
            ? _hostessController.text.trim()
            : null,
        guestCount: int.tryParse(_guestCountController.text),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        clientName: _clientNameController.text.trim().isNotEmpty
            ? _clientNameController.text.trim()
            : null,
        projectName: _projectNameController.text.trim().isNotEmpty
            ? _projectNameController.text.trim()
            : null,
        commission: double.tryParse(_commissionController.text),
        mileage: double.tryParse(_mileageController.text),
        flatRate: double.tryParse(_flatRateController.text),
        overtimeHours: double.tryParse(_overtimeHoursController.text),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        imageUrl: _capturedPhotos.isNotEmpty ? _capturedPhotos.join(',') : null,
        jobId: _selectedJob!.id,
        // =====================================================
        // RIDESHARE & DELIVERY FIELDS
        // =====================================================
        ridesCount: int.tryParse(_ridesCountController.text),
        deliveriesCount: int.tryParse(_deliveriesCountController.text),
        deadMiles: double.tryParse(_deadMilesController.text),
        fuelCost: double.tryParse(_fuelCostController.text),
        tollsParking: double.tryParse(_tollsParkingController.text),
        surgeMultiplier: double.tryParse(_surgeMultiplierController.text),
        acceptanceRate: double.tryParse(_acceptanceRateController.text),
        baseFare: double.tryParse(_baseFareController.text),
        // =====================================================
        // MUSIC & ENTERTAINMENT FIELDS
        // =====================================================
        gigType: _gigTypeController.text.trim().isNotEmpty
            ? _gigTypeController.text.trim()
            : null,
        setupHours: double.tryParse(_setupHoursController.text),
        performanceHours: double.tryParse(_performanceHoursController.text),
        breakdownHours: double.tryParse(_breakdownHoursController.text),
        equipmentUsed: _equipmentUsedController.text.trim().isNotEmpty
            ? _equipmentUsedController.text.trim()
            : null,
        equipmentRentalCost:
            double.tryParse(_equipmentRentalCostController.text),
        crewPayment: double.tryParse(_crewPaymentController.text),
        merchSales: double.tryParse(_merchSalesController.text),
        audienceSize: int.tryParse(_audienceSizeController.text),
        // =====================================================
        // ARTIST & CRAFTS FIELDS
        // =====================================================
        piecesCreated: int.tryParse(_piecesCreatedController.text),
        piecesSold: int.tryParse(_piecesSoldController.text),
        materialsCost: double.tryParse(_materialsCostController.text),
        salePrice: double.tryParse(_salePriceController.text),
        venueCommissionPercent:
            double.tryParse(_venueCommissionPercentController.text),
        // =====================================================
        // RETAIL/SALES FIELDS
        // =====================================================
        itemsSold: int.tryParse(_itemsSoldController.text),
        transactionsCount: int.tryParse(_transactionsCountController.text),
        upsellsCount: int.tryParse(_upsellsCountController.text),
        upsellsAmount: double.tryParse(_upsellsAmountController.text),
        returnsCount: int.tryParse(_returnsCountController.text),
        returnsAmount: double.tryParse(_returnsAmountController.text),
        shrinkAmount: double.tryParse(_shrinkAmountController.text),
        department: _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : null,
        // =====================================================
        // SALON/SPA FIELDS
        // =====================================================
        serviceType: _serviceTypeController.text.trim().isNotEmpty
            ? _serviceTypeController.text.trim()
            : null,
        servicesCount: int.tryParse(_servicesCountController.text),
        productSales: double.tryParse(_productSalesController.text),
        repeatClientPercent:
            double.tryParse(_repeatClientPercentController.text),
        chairRental: double.tryParse(_chairRentalController.text),
        newClientsCount: int.tryParse(_newClientsCountController.text),
        returningClientsCount:
            int.tryParse(_returningClientsCountController.text),
        walkinCount: int.tryParse(_walkinCountController.text),
        appointmentCount: int.tryParse(_appointmentCountController.text),
        // =====================================================
        // HOSPITALITY FIELDS
        // =====================================================
        roomType: _roomTypeController.text.trim().isNotEmpty
            ? _roomTypeController.text.trim()
            : null,
        roomsCleaned: int.tryParse(_roomsCleanedController.text),
        qualityScore: double.tryParse(_qualityScoreController.text),
        shiftType: _shiftTypeController.text.trim().isNotEmpty
            ? _shiftTypeController.text.trim()
            : null,
        roomUpgrades: int.tryParse(_roomUpgradesController.text),
        guestsCheckedIn: int.tryParse(_guestsCheckedInController.text),
        carsParked: int.tryParse(_carsParkedController.text),
        // =====================================================
        // HEALTHCARE FIELDS
        // =====================================================
        patientCount: int.tryParse(_patientCountController.text),
        shiftDifferential: double.tryParse(_shiftDifferentialController.text),
        onCallHours: double.tryParse(_onCallHoursController.text),
        proceduresCount: int.tryParse(_proceduresCountController.text),
        specialization: _specializationController.text.trim().isNotEmpty
            ? _specializationController.text.trim()
            : null,
        // =====================================================
        // FITNESS FIELDS
        // =====================================================
        sessionsCount: int.tryParse(_sessionsCountController.text),
        sessionType: _sessionTypeController.text.trim().isNotEmpty
            ? _sessionTypeController.text.trim()
            : null,
        classSize: int.tryParse(_classSizeController.text),
        retentionRate: double.tryParse(_retentionRateController.text),
        cancellationsCount: int.tryParse(_cancellationsCountController.text),
        packageSales: double.tryParse(_packageSalesController.text),
        supplementSales: double.tryParse(_supplementSalesController.text),
        // =====================================================
        // CONSTRUCTION/TRADES FIELDS
        // =====================================================
        laborCost: double.tryParse(_laborCostController.text),
        subcontractorCost: double.tryParse(_subcontractorCostController.text),
        squareFootage: double.tryParse(_squareFootageController.text),
        weatherDelayHours: double.tryParse(_weatherDelayHoursController.text),
        // =====================================================
        // FREELANCER FIELDS
        // =====================================================
        revisionsCount: int.tryParse(_revisionsCountController.text),
        clientType: _clientTypeController.text.trim().isNotEmpty
            ? _clientTypeController.text.trim()
            : null,
        expenses: double.tryParse(_expensesController.text),
        billableHours: double.tryParse(_billableHoursController.text),
        // =====================================================
        // RESTAURANT ADDITIONAL FIELDS
        // =====================================================
        tableSection: _tableSectionController.text.trim().isNotEmpty
            ? _tableSectionController.text.trim()
            : null,
        cashSales: double.tryParse(_cashSalesController.text),
        cardSales: double.tryParse(_cardSalesController.text),
      );

      // Debug logging
      print('🔍 SAVING SHIFT:');
      print('  Event Name: ${shift.eventName}');
      print('  Hostess: ${shift.hostess}');
      print('  Guest Count: ${shift.guestCount}');
      print('  Location: ${shift.location}');
      print('  Photos: ${shift.imageUrl}');

      if (widget.existingShift != null) {
        await _db.updateShift(shift);
      } else {
        // Handle recurring shifts
        if (_isRecurring && _selectedWeekdays.isNotEmpty) {
          await _createRecurringShifts(shift);
        } else {
          await _db.saveShift(shift);
        }
      }

      if (mounted) {
        final shiftProvider =
            Provider.of<ShiftProvider>(context, listen: false);
        await shiftProvider.loadShifts();
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving shift: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _createRecurringShifts(Shift templateShift) async {
    final seriesId = const Uuid().v4();
    final shiftsToCreate = <Shift>[];
    final notificationService = NotificationService();

    // Create shifts for next 12 weeks
    for (int week = 0; week < 12; week++) {
      for (int weekday in _selectedWeekdays) {
        // Calculate the date for this occurrence
        final baseDate = _selectedDate.add(Duration(days: week * 7));
        final daysToAdd = weekday - baseDate.weekday;
        final shiftDate = baseDate.add(Duration(days: daysToAdd));

        // Only create if future date
        if (shiftDate.isAfter(DateTime.now())) {
          final newShift = templateShift.copyWith(
            id: const Uuid().v4(),
            date: shiftDate,
            status: 'scheduled',
            isRecurring: true,
            recurrenceRule: 'WEEKLY:${_selectedWeekdays.join(',')}',
            recurringSeriesId: seriesId,
            // Clear earnings for scheduled shifts
            cashTips: 0,
            creditTips: 0,
            commission: 0,
            flatRate: 0,
            hoursWorked: 0,
          );
          shiftsToCreate.add(newShift);

          // Schedule notifications if times are set
          if (_startTime != null) {
            final shiftStartDateTime = DateTime(
              shiftDate.year,
              shiftDate.month,
              shiftDate.day,
              _startTime!.hour,
              _startTime!.minute,
            );

            // Schedule start reminder
            await notificationService.scheduleShiftReminder(
              shiftId: newShift.id,
              shiftStartTime: shiftStartDateTime,
              jobName: _selectedJob?.name ?? 'Shift',
            );

            // Schedule end-of-shift reminder if end time exists
            if (_endTime != null) {
              final shiftEndDateTime = DateTime(
                shiftDate.year,
                shiftDate.month,
                shiftDate.day,
                _endTime!.hour,
                _endTime!.minute,
              );

              await notificationService.scheduleEndOfShiftReminder(
                shiftId: newShift.id,
                shiftEndTime: shiftEndDateTime,
                jobName: _selectedJob?.name ?? 'Shift',
              );
            }
          }
        }
      }
    }

    // Save all shifts
    for (final shift in shiftsToCreate) {
      await _db.saveShift(shift);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created ${shiftsToCreate.length} recurring shifts'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  String _formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return '\$${amount.toInt()}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  double _calculateHours() {
    if (_startTime == null || _endTime == null) return 0;

    final start = _startTime!.hour + _startTime!.minute / 60.0;
    var end = _endTime!.hour + _endTime!.minute / 60.0;

    // Handle overnight shifts
    if (end < start) end += 24;

    return end - start;
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Save to phone gallery immediately
        final bytes = await photo.readAsBytes();
        await Gal.putImageBytes(bytes);

        setState(() {
          _capturedPhotos.add(photo.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Photo captured and saved to gallery!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedPhotos.add(image.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        // Save to phone gallery immediately
        await Gal.putVideo(video.path);

        setState(() {
          _capturedPhotos.add(video.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Video recorded and saved to gallery!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording video: $e')),
        );
      }
    }
  }

  Future<void> _showAttachmentMenu() async {
    // Get the position of the button to show menu near it
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 250, // Right side
        kToolbarHeight + 10, // Just below the app bar
        10,
        0,
      ),
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.photo_library, color: AppTheme.primaryGreen),
            title: Text('Pick from Gallery', style: AppTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.insert_drive_file, color: AppTheme.accentBlue),
            title: Text('Choose File', style: AppTheme.bodyMedium),
            subtitle: Text(
              'PDF, Word, Excel, images, videos, etc.',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // UNIFIED AI VISION SCANNER SYSTEM
  // ============================================================================

  /// Handle scan type selection from the bottom sheet menu
  void _handleScanTypeSelected(ScanType scanType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          scanType: scanType,
          onScanComplete: _handleScanComplete,
        ),
      ),
    );
  }

  /// Handle completed scan session - process images with AI
  Future<void> _handleScanComplete(DocumentScanSession session) async {
    // Show loading indicator
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
                'Processing ${session.pageCount} page${session.pageCount == 1 ? '' : 's'} with AI...'),
          ],
        ),
        duration: const Duration(seconds: 30),
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.9),
      ),
    );

    try {
      // Route to appropriate handler based on scan type
      switch (session.scanType) {
        case ScanType.beo:
          await _processBEOScan(session);
          break;
        case ScanType.checkout:
          await _processCheckoutScan(session);
          break;
        case ScanType.businessCard:
          await _processBusinessCardScan(session);
          break;
        case ScanType.paycheck:
          await _processPaycheckScan(session);
          break;
        case ScanType.invoice:
          await _processInvoiceScan(session);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan processing failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Process BEO scan - Extract event details
  Future<void> _processBEOScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;
      final result =
          await _visionScanner.analyzeBEO(session.imagePaths, userId);

      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.beo,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            onConfirm: (data) async {
              // Pre-fill shift form with BEO data
              setState(() {
                if (data['event_name'] != null) {
                  _eventNameController.text = data['event_name'].toString();
                }
                if (data['guest_count_confirmed'] != null) {
                  _guestCountController.text =
                      data['guest_count_confirmed'].toString();
                }
                if (data['total_sale_amount'] != null) {
                  _eventCostController.text =
                      data['total_sale_amount'].toString();
                }
                if (data['commission_amount'] != null) {
                  _commissionController.text =
                      data['commission_amount'].toString();
                }
                if (data['venue_name'] != null) {
                  _locationController.text = data['venue_name'].toString();
                }
                if (data['primary_contact_name'] != null) {
                  _hostessController.text =
                      data['primary_contact_name'].toString();
                }
                if (data['formatted_notes'] != null) {
                  _notesController.text = data['formatted_notes'].toString();
                }
              });
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('BEO data imported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BEO scan failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Process server checkout scan - Extract financial data
  Future<void> _processCheckoutScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;
      final result = await _visionScanner.analyzeCheckout(
        session.imagePaths,
        userId,
        shiftId: widget.existingShift?.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.checkout,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            onConfirm: (data) async {
              // Pre-fill shift form with checkout data
              setState(() {
                if (data['total_sales'] != null) {
                  _salesAmountController.text = data['total_sales'].toString();
                }
                if (data['gross_tips'] != null) {
                  _creditTipsController.text = data['gross_tips'].toString();
                }
                if (data['tipout_amount'] != null) {
                  _additionalTipoutController.text =
                      data['tipout_amount'].toString();
                }
                if (data['tipout_percentage'] != null) {
                  _tipoutPercentController.text =
                      data['tipout_percentage'].toString();
                }
              });
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Checkout data imported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout scan failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Process business card scan - Add contact
  Future<void> _processBusinessCardScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;
      final result = await _visionScanner.scanBusinessCard(
        session.imagePaths,
        userId,
        shiftId: widget.existingShift?.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.businessCard,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            onConfirm: (data) async {
              // Contact already saved by Edge Function
              // Just refresh the contacts list
              await _loadEventContacts();
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Contact "${result['data']['name']}" added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Business card scan failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Process paycheck scan - Track W-2 income
  Future<void> _processPaycheckScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;
      final result =
          await _visionScanner.analyzePaycheck(session.imagePaths, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Check for Reality Check warning
      final realityCheck = result['realityCheck'] as Map<String, dynamic>?;
      final unreportedGap = realityCheck?['unreportedGap'] as double?;

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.paycheck,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            onConfirm: (data) async {
              // Paycheck already saved by Edge Function
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        String message = 'Paycheck tracked successfully!';

        // Show Reality Check warning if applicable
        if (unreportedGap != null && unreportedGap > 100) {
          message =
              '⚠️ Reality Check: \$${unreportedGap.toStringAsFixed(2)} in unreported tips detected. Set aside ~\$${(unreportedGap * 0.22).toStringAsFixed(2)} for taxes.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: unreportedGap != null && unreportedGap > 100
                ? AppTheme.warningColor
                : AppTheme.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paycheck scan failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Process invoice scan - Track freelancer income
  Future<void> _processInvoiceScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;
      final result =
          await _visionScanner.analyzeInvoice(session.imagePaths, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.invoice,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            onConfirm: (data) async {
              // Invoice already saved by Edge Function
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        final qbCategory = result['quickbooksCategory'] as String?;
        String message = 'Invoice tracked successfully!';

        if (qbCategory != null) {
          message = 'Invoice tracked! QuickBooks category: $qbCategory';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice scan failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Consolidated attachment menu - Take Photo, Record Video, Pick from Gallery, Attach File
  Future<void> _showConsolidatedAttachmentMenu() async {
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 250, // Right side
        kToolbarHeight + 10, // Just below the app bar
        10,
        0,
      ),
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
            title: Text('Take Photo', style: AppTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.videocam, color: AppTheme.accentBlue),
            title: Text('Record Video', style: AppTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _pickVideoFromCamera();
            },
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.photo_library, color: AppTheme.primaryGreen),
            title: Text('Pick from Gallery', style: AppTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading:
                Icon(Icons.insert_drive_file, color: AppTheme.accentOrange),
            title: Text('Choose File', style: AppTheme.bodyMedium),
            subtitle: Text(
              'PDF, Word, Excel, etc.',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String? filePath = file.path;

      // Handle web platform or cases where path is null
      if (filePath == null && file.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(file.bytes!);
        filePath = tempFile.path;
      }

      if (filePath != null) {
        setState(() {
          _capturedPhotos.add(filePath!);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} added!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingJobs) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          title: Text('Add Shift',
              style: AppTheme.titleLarge
                  .copyWith(color: AppTheme.adaptiveTextColor)),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_userJobs.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          title: Text('Add Shift',
              style: AppTheme.titleLarge
                  .copyWith(color: AppTheme.adaptiveTextColor)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('No jobs yet',
                    style: AppTheme.titleLarge
                        .copyWith(color: AppTheme.adaptiveTextColor)),
                const SizedBox(height: 8),
                Text(
                  'Please create a job before adding shifts',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close Add Shift
                    // Note: User can create job via Settings > Jobs
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddJobModal();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return NavigationWrapper(
      currentTabIndex: null, // No tab is actively selected on detail screens
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackground,
          title: Text(
            widget.existingShift != null ? 'Edit Shift' : 'Add Shift',
            style:
                AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
          ),
          actions: [
            // ✨ Scan button - Opens AI Vision Scanner menu
            IconButton(
              icon: const Text('✨', style: TextStyle(fontSize: 24)),
              onPressed: () =>
                  showScanTypeMenu(context, _handleScanTypeSelected),
              tooltip: 'AI Scanner',
            ),
            // 📎 Attach button - Consolidated media menu
            IconButton(
              icon: Icon(Icons.attach_file, color: AppTheme.primaryGreen),
              onPressed: _showConsolidatedAttachmentMenu,
              tooltip: 'Attach Media',
            ),
            TextButton(
              onPressed: _isSaving ? null : _saveShift,
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
          child: Consumer<FieldOrderProvider>(
            builder: (context, fieldOrderProvider, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 90), // Bottom padding for fixed AI bar
                children: [
                  // Photo Thumbnails (if any photos captured) - NOT reorderable
                  if (_capturedPhotos.isNotEmpty) ...[
                    _buildPhotoThumbnails(),
                    const SizedBox(height: 16),
                  ],

                  // Hero Card - Income Summary (NOT reorderable)
                  _buildHeroCard(),

                  const SizedBox(height: 16),

                  // My Job Selector (NOT reorderable)
                  _buildJobSelector(),

                  const SizedBox(height: 16),

                  // Date (NOT reorderable)
                  _buildDateSelector(),

                  const SizedBox(height: 16),

                  // Recurring Shift Section (only for future dates) - NOT reorderable
                  if (widget.existingShift == null &&
                      _selectedDate.isAfter(DateTime.now())) ...[
                    _buildRecurringSection(),
                    const SizedBox(height: 16),
                  ],

                  // Reorderable dynamic sections
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      _handleReorder(oldIndex, newIndex,
                          fieldOrderProvider.formFieldOrder);
                    },
                    children: _buildOrderedSections(
                        fieldOrderProvider.formFieldOrder),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final hours = double.tryParse(_hoursWorkedController.text) ?? 0;
    final cashTips = double.tryParse(_cashTipsController.text) ?? 0;
    final creditTips = double.tryParse(_creditTipsController.text) ?? 0;
    final hourlyRate = _useHourlyRateOverride
        ? (double.tryParse(_hourlyRateOverrideController.text) ??
            _selectedJob?.hourlyRate ??
            0)
        : (_selectedJob?.hourlyRate ?? 0);
    final commission = double.tryParse(_commissionController.text) ?? 0;
    final flatRate = double.tryParse(_flatRateController.text) ?? 0;

    final baseEarnings = hourlyRate * hours;
    final totalTips = cashTips + creditTips;
    final totalIncome = baseEarnings + totalTips + commission + flatRate;

    return HeroCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Total Income - Left side
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Income',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalIncome.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats - Right side
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroStat('Hours', hours.toStringAsFixed(1)),
                _buildHeroStat('Base', '\$${baseEarnings.toStringAsFixed(2)}'),
                if (_template?.showTips ?? false)
                  _buildHeroStat('Tips', '\$${totalTips.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle reordering of sections
  void _handleReorder(int oldIndex, int newIndex, List<String> currentOrder) {
    // Adjust indices if needed
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final updatedOrder = List<String>.from(currentOrder);
    final item = updatedOrder.removeAt(oldIndex);
    updatedOrder.insert(newIndex, item);

    // Save the new order
    final fieldOrderProvider =
        Provider.of<FieldOrderProvider>(context, listen: false);
    fieldOrderProvider.updateFormFieldOrder(updatedOrder);

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Layout saved'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Build sections in the order specified by field order provider
  List<Widget> _buildOrderedSections(List<String> fieldOrder) {
    final widgets = <Widget>[];

    for (final sectionKey in fieldOrder) {
      // Only show sections if template allows them
      if (_template == null) continue;

      switch (sectionKey) {
        case 'time_section':
          widgets.add(Padding(
            key: ValueKey('time_section'),
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTimeSection(),
          ));
          break;

        case 'earnings_section':
          if (_template!.showTips || _template!.showCommission) {
            widgets.add(Padding(
              key: ValueKey('earnings_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEarningsSection(),
            ));
          }
          break;

        case 'event_details_section':
          if (_template!.showEventName ||
              _template!.showHostess ||
              _template!.showGuestCount) {
            widgets.add(Padding(
              key: ValueKey('event_details_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventDetailsSection(),
            ));
          }
          break;

        case 'work_details_section':
          if (_template!.showLocation ||
              _template!.showClientName ||
              _template!.showProjectName ||
              _template!.showMileage) {
            widgets.add(Padding(
              key: ValueKey('work_details_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildWorkDetailsSection(),
            ));
          }
          break;

        case 'documentation_section':
          if (_template!.showNotes || _template!.showPhotos) {
            widgets.add(Padding(
              key: ValueKey('documentation_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDocumentationSection(),
            ));
          }
          break;

        case 'attachments_section':
          if (widget.existingShift != null) {
            widgets.add(Padding(
              key: ValueKey('attachments_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAttachmentsSection(),
            ));
          }
          break;

        case 'event_team_section':
          if (widget.existingShift != null) {
            widgets.add(Padding(
              key: ValueKey('event_team_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventTeamSection(),
            ));
          }
          break;
      }
    }

    return widgets;
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildJobSelector() {
    final selectedJobName = _selectedJob?.name ?? 'Select a job';
    final selectedEmployer = _selectedJob?.employer;
    return CollapsibleSection(
      title: 'My Job: $selectedJobName',
      icon: Icons.work,
      initiallyExpanded: false,
      children: [
        // Employer badge (if available)
        if (selectedEmployer?.isNotEmpty == true) ...[
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business,
                    size: 14,
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedEmployer!,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _userJobs.map((job) {
            final isSelected = _selectedJob?.id == job.id;
            return ChoiceChip(
              label: Text(job.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedJob = job;
                    _template = job.template;
                  });
                }
              },
              selectedColor: AppTheme.primaryGreen,
              backgroundColor: AppTheme.cardBackgroundLight,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift Date', style: AppTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: AppTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    final hours = _calculateHours();
    final isUsingTimeRange = _startTime != null && _endTime != null;
    final manualHours = double.tryParse(_hoursWorkedController.text) ?? 0;
    final displayHours = isUsingTimeRange ? hours : manualHours;
    final hoursText = displayHours > 0 ? ': ${_formatHours(displayHours)}' : '';

    return CollapsibleSection(
      title: 'Time & Hours$hoursText',
      icon: Icons.access_time,
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTimePicker('Start Time', _startTime, (time) {
              setState(() {
                _startTime = time;
                if (_endTime != null) {
                  _hoursWorkedController.text =
                      _calculateHours().toStringAsFixed(2);
                }
              });
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildTimePicker('End Time', _endTime, (time) {
              setState(() {
                _endTime = time;
                if (_startTime != null) {
                  _hoursWorkedController.text =
                      _calculateHours().toStringAsFixed(2);
                }
              });
            })),
          ],
        ),
        if (isUsingTimeRange) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hours auto-calculated: ${_formatHours(hours)}',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.primaryGreen, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startTime = null;
                      _endTime = null;
                    });
                  },
                  child: Text('Clear',
                      style: TextStyle(color: AppTheme.primaryGreen)),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _hoursWorkedController,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.timer, color: AppTheme.primaryGreen),
                    hintText: 'Hours worked (e.g., 8.5)',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              // Hourly Rate Display with Override
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap:
                      _useHourlyRateOverride ? null : _showRateOverrideDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: _useHourlyRateOverride
                          ? AppTheme.cardBackgroundLight
                          : AppTheme.cardBackgroundLight.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: _useHourlyRateOverride
                          ? Border.all(
                              color: AppTheme.accentOrange.withOpacity(0.5))
                          : null,
                    ),
                    child: _useHourlyRateOverride
                        ? Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _hourlyRateOverrideController,
                                  keyboardType: TextInputType.number,
                                  style: AppTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Override rate',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                    prefixText: '\$ ',
                                    suffixText: '/hr',
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close,
                                    size: 18, color: AppTheme.textMuted),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _useHourlyRateOverride = false;
                                    _hourlyRateOverrideController.clear();
                                  });
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(Icons.attach_money,
                                  color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hourly Rate',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '\$${(_selectedJob?.hourlyRate ?? 0).toStringAsFixed(2)}/hr',
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit,
                                    size: 18, color: AppTheme.primaryGreen),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: _showRateOverrideDialog,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_template?.tracksOvertime ?? false) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _overtimeHoursController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText:
                  'Overtime hours (${_template?.overtimeMultiplier ?? 1.5}x pay)',
              prefixIcon: Icon(Icons.trending_up, color: AppTheme.accentBlue),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimePicker(
      String label, TimeOfDay? time, Function(TimeOfDay) onSelected) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              time != null ? time.format(context) : '--:--',
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection() {
    return CollapsibleSection(
      title: 'Repeat Schedule',
      icon: Icons.repeat,
      initiallyExpanded: _isRecurring,
      children: [
        // Recurring toggle
        SwitchListTile(
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
              if (value && _selectedWeekdays.isEmpty) {
                // Default to current weekday
                _selectedWeekdays = [_selectedDate.weekday];
              }
            });
          },
          title: Text('Make this a recurring shift', style: AppTheme.bodyLarge),
          subtitle: Text(
            'Create multiple scheduled shifts',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          activeColor: AppTheme.primaryGreen,
        ),

        if (_isRecurring) ...[
          const SizedBox(height: 16),

          // Weekday selection
          Text('Repeat on:', style: AppTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildWeekdayChip('M', 1),
              _buildWeekdayChip('T', 2),
              _buildWeekdayChip('W', 3),
              _buildWeekdayChip('T', 4),
              _buildWeekdayChip('F', 5),
              _buildWeekdayChip('S', 6),
              _buildWeekdayChip('S', 7),
            ],
          ),

          const SizedBox(height: 16),

          // Info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This will create scheduled shifts for the next 12 weeks',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeekdayChip(String label, int weekday) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryGreen
            : AppTheme.textMuted.withOpacity(0.3),
      ),
    );
  }

  List<Widget> _buildDynamicSections() {
    final sections = <Widget>[];

    // Earnings Section
    if (_template!.showTips || _template!.showCommission) {
      sections.add(_buildEarningsSection());
      sections.add(const SizedBox(height: 16));
    }

    // Event Details Section
    if (_template!.showEventName ||
        _template!.showHostess ||
        _template!.showGuestCount) {
      sections.add(_buildEventDetailsSection());
      sections.add(const SizedBox(height: 16));
    }

    // Work Details Section
    if (_template!.showLocation ||
        _template!.showClientName ||
        _template!.showProjectName ||
        _template!.showMileage) {
      sections.add(_buildWorkDetailsSection());
      sections.add(const SizedBox(height: 16));
    }

    // Documentation Section
    if (_template!.showNotes || _template!.showPhotos) {
      sections.add(_buildDocumentationSection());
      sections.add(const SizedBox(height: 16));
    }

    return sections;
  }

  Widget _buildEarningsSection() {
    final cashTips = double.tryParse(_cashTipsController.text) ?? 0;
    final creditTips = double.tryParse(_creditTipsController.text) ?? 0;
    final commission = double.tryParse(_commissionController.text) ?? 0;
    final flatRate = double.tryParse(_flatRateController.text) ?? 0;
    final totalEarnings = cashTips + creditTips + commission + flatRate;
    final earningsText =
        totalEarnings > 0 ? ': ${_formatCurrency(totalEarnings)}' : '';

    return CollapsibleSection(
      title: 'Earnings$earningsText',
      icon: Icons.attach_money,
      accentColor: AppTheme.primaryGreen,
      children: [
        const SizedBox(height: 8), // Top padding to prevent label overlap
        if (_template!.showTips) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cashTipsController,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cash tips (e.g., 50.00)',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}), // Refresh hero card
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _creditTipsController,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Credit card tips (e.g., 125.00)',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],

        // Sales Amount (NEW)
        if (_template!.showSales) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _salesAmountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Total sales (e.g., 1200.00)',
              prefixText: '\$ ',
              suffixText: _salesAmountController.text.isNotEmpty &&
                      (cashTips + creditTips) > 0
                  ? '${((cashTips + creditTips) / (double.tryParse(_salesAmountController.text) ?? 1) * 100).toStringAsFixed(1)}%'
                  : null,
              suffixStyle: TextStyle(
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        // Tip Out Section (REDESIGNED) - Calculate from sales
        if (_template!.showTips && _template!.showSales) ...[
          const SizedBox(height: 16),
          Text(
            '🤝 Tip Out',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final salesAmount =
                  double.tryParse(_salesAmountController.text) ?? 0;
              final tipoutPercent =
                  double.tryParse(_tipoutPercentController.text) ??
                      _selectedJob?.defaultTipoutPercent ??
                      0;
              final additionalTipout =
                  double.tryParse(_additionalTipoutController.text) ?? 0;
              final calculatedTipout = (salesAmount * tipoutPercent / 100);
              final totalTipout = calculatedTipout + additionalTipout;
              final totalTips = cashTips + creditTips;
              final netTips = totalTips - totalTipout;

              // Pre-fill tipout % from job default if empty
              if (_tipoutPercentController.text.isEmpty &&
                  _selectedJob?.defaultTipoutPercent != null &&
                  _selectedJob!.defaultTipoutPercent! > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _tipoutPercentController.text =
                        _selectedJob!.defaultTipoutPercent!.toStringAsFixed(1);
                  }
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tipoutPercentController,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Tip out % (e.g., 2.5)',
                            suffixText: '% of sales',
                            suffixStyle: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                            filled: true,
                            fillColor: AppTheme.cardBackgroundLight,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (calculatedTipout > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Text(
                            '= ${_formatCurrency(calculatedTipout)}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.accentYellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tipoutPercent > 0 &&
                      _selectedJob?.tipoutDescription != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '💡 ${tipoutPercent.toStringAsFixed(1)}% to ${_selectedJob!.tipoutDescription}',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _additionalTipoutController,
                          keyboardType: TextInputType.number,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Extra tipout (e.g., 15.00)',
                            prefixText: '\$ ',
                            helperText: 'Extra cash (e.g., dishwasher)',
                            helperStyle: TextStyle(
                                color: Colors.grey[500], fontSize: 10),
                            filled: true,
                            fillColor: AppTheme.cardBackgroundLight,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _additionalTipoutNoteController,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Who? (e.g., Dishwasher)',
                            helperText: 'e.g., "Dishwasher", "Holiday bonus"',
                            helperStyle: TextStyle(
                                color: Colors.grey[500], fontSize: 10),
                            filled: true,
                            fillColor: AppTheme.cardBackgroundLight,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (totalTipout > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip Breakdown',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gross Tips: ${_formatCurrency(totalTips)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Total Tipout: ${_formatCurrency(totalTipout)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.accentRed,
                            ),
                          ),
                          if (calculatedTipout > 0)
                            Text(
                              '  • From Sales: ${_formatCurrency(calculatedTipout)}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          if (additionalTipout > 0)
                            Text(
                              '  • Additional: ${_formatCurrency(additionalTipout)}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          const Divider(height: 8),
                          Text(
                            'Net Tips: ${_formatCurrency(netTips)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],

        if (_template!.showCommission) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _commissionController,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Sales commission (e.g., 200.00)',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_template!.payStructure == PayStructure.flatRate) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _flatRateController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Fixed payment (e.g., 300.00)',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: AppTheme.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ] else
                const Expanded(
                    child: SizedBox()), // Empty space if no flat rate
            ],
          ),
        ] else if (_template!.payStructure == PayStructure.flatRate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _flatRateController,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Fixed payment (e.g., 300.00)',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Expanded(child: SizedBox()), // Empty space
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEventDetailsSection() {
    final guestCount = int.tryParse(_guestCountController.text);
    String summary = 'Event Details';

    if (guestCount != null && guestCount > 0) {
      summary = 'Event Details: $guestCount guests';
    }

    return CollapsibleSection(
      title: summary,
      icon: Icons.celebration,
      accentColor: AppTheme.accentYellow,
      children: [
        const SizedBox(height: 8), // Top padding to prevent label overlap
        if (_template!.showEventName) ...[
          TextFormField(
            controller: _eventNameController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Event or party name (e.g., Smith Wedding)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Event Cost (NEW)
        if (_template!.showEventCost) ...[
          TextFormField(
            controller: _eventCostController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Total event cost (e.g., 5000.00)',
              prefixText: '\$ ',
              helperText: 'Total cost of event (for DJs, planners)',
              helperStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_template!.showGuestCount && _template!.showHostess) ...[
          Row(
            children: [
              SizedBox(
                width: 75,
                child: TextFormField(
                  controller: _guestCountController,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Number of guests (e.g., 150)',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _hostessController,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Hostess or contact name (e.g., Jessica)',
                    filled: true,
                    fillColor: AppTheme.cardBackgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          if (_template!.showHostess) ...[
            TextFormField(
              controller: _hostessController,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Hostess or contact name (e.g., Jessica)',
                filled: true,
                fillColor: AppTheme.cardBackgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_template!.showGuestCount) ...[
            TextFormField(
              controller: _guestCountController,
              keyboardType: TextInputType.number,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Total guests served (e.g., 75)',
                filled: true,
                fillColor: AppTheme.cardBackgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildWorkDetailsSection() {
    return CollapsibleSection(
      title: 'Work Details',
      icon: Icons.location_on,
      accentColor: AppTheme.accentBlue,
      children: [
        if (_template!.showLocation) ...[
          TextFormField(
            controller: _locationController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Job site or venue (e.g., Grand Ballroom)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showClientName) ...[
          TextFormField(
            controller: _clientNameController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Client or company name (e.g., ABC Corp)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showProjectName) ...[
          TextFormField(
            controller: _projectNameController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Project or booking name (e.g., Holiday Party)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showMileage) ...[
          TextFormField(
            controller: _mileageController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Miles driven (e.g., 25)',
              suffixText: 'miles',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // RIDESHARE & DELIVERY FIELDS
        // =====================================================
        if (_template!.showRidesCount) ...[
          TextFormField(
            controller: _ridesCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Number of rides/deliveries',
              prefixIcon:
                  Icon(Icons.directions_car, color: AppTheme.primaryGreen),
              suffixText: 'rides',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showDeadMiles) ...[
          TextFormField(
            controller: _deadMilesController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Dead miles (without passenger)',
              suffixText: 'miles',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showFuelCost) ...[
          TextFormField(
            controller: _fuelCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Fuel cost',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showTollsParking) ...[
          TextFormField(
            controller: _tollsParkingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Tolls & parking',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSurgeMultiplier) ...[
          TextFormField(
            controller: _surgeMultiplierController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Surge multiplier (e.g., 1.5, 2.0)',
              suffixText: 'x',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showBaseFare) ...[
          TextFormField(
            controller: _baseFareController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Base fare (before tips)',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // MUSIC & ENTERTAINMENT FIELDS
        // =====================================================
        if (_template!.showGigType) ...[
          TextFormField(
            controller: _gigTypeController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Gig type (Wedding, Corporate, Bar, Street)',
              prefixIcon: Icon(Icons.music_note, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSetupHours) ...[
          TextFormField(
            controller: _setupHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Setup time',
              suffixText: 'hours',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showPerformanceHours) ...[
          TextFormField(
            controller: _performanceHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Performance time',
              suffixText: 'hours',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showBreakdownHours) ...[
          TextFormField(
            controller: _breakdownHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Breakdown/teardown time',
              suffixText: 'hours',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showEquipmentUsed) ...[
          TextFormField(
            controller: _equipmentUsedController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Equipment used (PA, lights, etc.)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showEquipmentRental) ...[
          TextFormField(
            controller: _equipmentRentalCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Equipment rental cost',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showCrewPayment) ...[
          TextFormField(
            controller: _crewPaymentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Crew/band payment',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showMerchSales) ...[
          TextFormField(
            controller: _merchSalesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Merchandise/CD sales',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showAudienceSize) ...[
          TextFormField(
            controller: _audienceSizeController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Audience/crowd size',
              suffixText: 'people',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // ARTIST & CRAFTS FIELDS
        // =====================================================
        if (_template!.showPiecesCreated) ...[
          TextFormField(
            controller: _piecesCreatedController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Pieces created',
              prefixIcon: Icon(Icons.palette, color: AppTheme.primaryGreen),
              suffixText: 'pieces',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showPiecesSold) ...[
          TextFormField(
            controller: _piecesSoldController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Pieces sold',
              suffixText: 'pieces',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showMaterialsCost) ...[
          TextFormField(
            controller: _materialsCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Materials cost',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSalePrice) ...[
          TextFormField(
            controller: _salePriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Average sale price',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showVenueCommission) ...[
          TextFormField(
            controller: _venueCommissionPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Venue/gallery commission',
              suffixText: '%',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // RETAIL/SALES FIELDS
        // =====================================================
        if (_template!.showItemsSold) ...[
          TextFormField(
            controller: _itemsSoldController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Items sold',
              prefixIcon:
                  Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
              suffixText: 'items',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showTransactionsCount) ...[
          TextFormField(
            controller: _transactionsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Transactions/customers',
              suffixText: 'customers',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showUpsells) ...[
          TextFormField(
            controller: _upsellsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Upsells (warranties, credit cards)',
              suffixText: 'upsells',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showReturns) ...[
          TextFormField(
            controller: _returnsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Returns processed',
              suffixText: 'returns',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showShrink) ...[
          TextFormField(
            controller: _shrinkAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Shrink/loss amount',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // SALON/SPA FIELDS
        // =====================================================
        if (_template!.showServiceType) ...[
          TextFormField(
            controller: _serviceTypeController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Service type (Cut, Color, Massage, etc.)',
              prefixIcon: Icon(Icons.spa, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showServicesCount) ...[
          TextFormField(
            controller: _servicesCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Services performed',
              suffixText: 'services',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showProductSales) ...[
          TextFormField(
            controller: _productSalesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Product sales',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showChairRental) ...[
          TextFormField(
            controller: _chairRentalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Chair/booth rental',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showNewClients) ...[
          TextFormField(
            controller: _newClientsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'New clients',
              suffixText: 'clients',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showWalkins) ...[
          TextFormField(
            controller: _walkinCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Walk-ins',
              suffixText: 'walk-ins',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // HOSPITALITY FIELDS
        // =====================================================
        if (_template!.showRoomType) ...[
          TextFormField(
            controller: _roomTypeController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Room type (Standard, Suite, Deluxe)',
              prefixIcon: Icon(Icons.hotel, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showRoomsCleaned) ...[
          TextFormField(
            controller: _roomsCleanedController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Rooms cleaned',
              suffixText: 'rooms',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showQualityScore) ...[
          TextFormField(
            controller: _qualityScoreController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Quality score (1-10)',
              suffixText: '/10',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showShiftType) ...[
          TextFormField(
            controller: _shiftTypeController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Shift type (Day, Night, Swing, Peak)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showGuestsCheckedIn) ...[
          TextFormField(
            controller: _guestsCheckedInController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Guests checked in',
              suffixText: 'guests',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showCarsParked) ...[
          TextFormField(
            controller: _carsParkedController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Cars parked (valet)',
              suffixText: 'cars',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // HEALTHCARE FIELDS
        // =====================================================
        if (_template!.showPatientCount) ...[
          TextFormField(
            controller: _patientCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Patients seen',
              prefixIcon:
                  Icon(Icons.medical_services, color: AppTheme.primaryGreen),
              suffixText: 'patients',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showShiftDifferential) ...[
          TextFormField(
            controller: _shiftDifferentialController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Shift differential (night/weekend bonus)',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showOnCallHours) ...[
          TextFormField(
            controller: _onCallHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'On-call hours',
              suffixText: 'hours',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showProceduresCount) ...[
          TextFormField(
            controller: _proceduresCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Procedures performed',
              suffixText: 'procedures',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // FITNESS FIELDS
        // =====================================================
        if (_template!.showSessionsCount) ...[
          TextFormField(
            controller: _sessionsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Sessions/classes taught',
              prefixIcon:
                  Icon(Icons.fitness_center, color: AppTheme.primaryGreen),
              suffixText: 'sessions',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSessionType) ...[
          TextFormField(
            controller: _sessionTypeController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Session type (1-on-1, Group, Online)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showClassSize) ...[
          TextFormField(
            controller: _classSizeController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Class size',
              suffixText: 'students',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showCancellations) ...[
          TextFormField(
            controller: _cancellationsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Cancellations/no-shows',
              suffixText: 'cancellations',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showPackageSales) ...[
          TextFormField(
            controller: _packageSalesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Package sales',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSupplementSales) ...[
          TextFormField(
            controller: _supplementSalesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Supplement/product sales',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // CONSTRUCTION/TRADES FIELDS
        // =====================================================
        if (_template!.showLaborCost) ...[
          TextFormField(
            controller: _laborCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Labor/crew cost',
              prefixIcon:
                  Icon(Icons.construction, color: AppTheme.primaryGreen),
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSubcontractorCost) ...[
          TextFormField(
            controller: _subcontractorCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Subcontractor cost',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showSquareFootage) ...[
          TextFormField(
            controller: _squareFootageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Square footage completed',
              suffixText: 'sq ft',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showWeatherDelay) ...[
          TextFormField(
            controller: _weatherDelayHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Weather delay',
              suffixText: 'hours',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // FREELANCER FIELDS
        // =====================================================
        if (_template!.showBillableHours) ...[
          TextFormField(
            controller: _billableHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Billable hours',
              prefixIcon: Icon(Icons.computer, color: AppTheme.primaryGreen),
              suffixText: 'hours',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showRevisionsCount) ...[
          TextFormField(
            controller: _revisionsCountController,
            keyboardType: TextInputType.number,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Revisions/rounds',
              suffixText: 'revisions',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showClientType) ...[
          TextFormField(
            controller: _clientTypeController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Client type (Startup, SMB, Enterprise)',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_template!.showExpenses) ...[
          TextFormField(
            controller: _expensesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Expenses (software, travel, etc.)',
              prefixText: '\$ ',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // =====================================================
        // RESTAURANT ADDITIONAL FIELDS
        // =====================================================
        if (_template!.showTableSection) ...[
          TextFormField(
            controller: _tableSectionController,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Table section (Bar, Patio, Section A)',
              prefixIcon:
                  Icon(Icons.table_restaurant, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDocumentationSection() {
    return CollapsibleSection(
      title: 'Documentation',
      icon: Icons.description,
      accentColor: AppTheme.textSecondary,
      children: [
        if (_template!.showNotes) ...[
          TextFormField(
            controller: _notesController,
            style: AppTheme.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any notes about this shift...',
              filled: true,
              fillColor: AppTheme.cardBackgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAIChatBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  maxLines: null,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Ask AI to help fill out this shift...',
                    hintStyle:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: AppTheme.bodyMedium,
                  onSubmitted: (value) {
                    // TODO: Implement AI chat functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI chat coming soon!')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.send, color: AppTheme.primaryGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attachments (${_capturedPhotos.length})',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _capturedPhotos.length,
              itemBuilder: (context, index) {
                return _buildThumbnail(_capturedPhotos[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String filePath, int index) {
    final fileName = filePath.split('/').last.split('\\').last;
    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

    // Determine if it's an image or video
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
    final isVideo =
        ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'].contains(extension);

    // Determine icon and color for non-image/video files
    IconData fileIcon;
    Color iconColor;

    if (extension == 'pdf') {
      fileIcon = Icons.picture_as_pdf;
      iconColor = AppTheme.accentRed;
    } else if (['doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      fileIcon = Icons.description;
      iconColor = AppTheme.accentBlue;
    } else if (['xls', 'xlsx', 'csv'].contains(extension)) {
      fileIcon = Icons.table_chart;
      iconColor = AppTheme.primaryGreen;
    } else if (['ppt', 'pptx'].contains(extension)) {
      fileIcon = Icons.slideshow;
      iconColor = AppTheme.accentOrange;
    } else if (['zip', 'rar', '7z'].contains(extension)) {
      fileIcon = Icons.folder_zip;
      iconColor = AppTheme.accentYellow;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = AppTheme.textMuted;
    }

    return GestureDetector(
      onTap: isImage ? () => _showFullImage(filePath) : null,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: (isImage || isVideo)
                ? AppTheme.primaryGreen.withOpacity(0.3)
                : iconColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 2),
              child: (isImage || isVideo)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.cardBackgroundLight,
                              child: Icon(
                                isVideo ? Icons.videocam : Icons.broken_image,
                                color: AppTheme.textMuted,
                                size: 40,
                              ),
                            );
                          },
                        ),
                        if (isVideo)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: AppTheme.cardBackgroundLight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(fileIcon, color: iconColor, size: 40),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              extension.toUpperCase(),
                              style: AppTheme.labelSmall.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _capturedPhotos.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 5.0,
                child: Image.file(File(imagePath)),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddJobModal() async {
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
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
      if (result == true && mounted) {
        // Job was created, pop back to dashboard
        Navigator.pop(context);
      }
    } else {
      // Use quick add
      final result = await Navigator.push<Job>(
        context,
        MaterialPageRoute(builder: (context) => const AddJobScreen()),
      );
      if (result != null && mounted) {
        // Job was created, pop back to dashboard
        Navigator.pop(context);
      }
    }
  }

  // ============================================================
  // EVENT CONTACTS METHODS
  // ============================================================

  Future<void> _loadEventContacts() async {
    if (widget.existingShift == null) return;

    setState(() => _isLoadingContacts = true);
    try {
      final contacts =
          await _db.getEventContactsForShift(widget.existingShift!.id);
      setState(() {
        _eventContacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _addEventContact() async {
    if (widget.existingShift == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditContactScreen(shiftId: widget.existingShift!.id),
      ),
    );
    if (result == true) {
      _loadEventContacts();
    }
  }

  Future<void> _editContact(EventContact contact) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(contact: contact),
      ),
    );
    if (result == true) {
      _loadEventContacts();
    }
  }

  Widget _buildEventTeamSection() {
    if (widget.existingShift == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.groups, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Event Team',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_eventContacts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_eventContacts.length}',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    // Add contact button
                    IconButton(
                      icon:
                          Icon(Icons.person_add, color: AppTheme.primaryGreen),
                      onPressed: _addEventContact,
                      tooltip: 'Add contact',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    // View all contacts
                    IconButton(
                      icon: Icon(Icons.open_in_new, color: AppTheme.textMuted),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventContactsScreen(
                              shiftId: widget.existingShift!.id,
                              shiftEventName: widget.existingShift!.eventName,
                            ),
                          ),
                        ).then((_) => _loadEventContacts());
                      },
                      tooltip: 'View all',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contacts list or empty state
          if (_isLoadingContacts)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_eventContacts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: _addEventContact,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add vendors & staff from this event',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              _eventContacts.length > 3 ? 3 : _eventContacts.length,
              (index) => _buildContactRow(_eventContacts[index]),
            ),

          // "View all" if more than 3 contacts
          if (_eventContacts.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventContactsScreen(
                        shiftId: widget.existingShift!.id,
                        shiftEventName: widget.existingShift!.eventName,
                      ),
                    ),
                  ).then((_) => _loadEventContacts());
                },
                child: Text(
                  'View all ${_eventContacts.length} contacts →',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(EventContact contact) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () => _editContact(contact),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: contact.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          contact.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contact.role != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.role!.displayName,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ATTACHMENTS METHODS
  // ============================================================

  Future<void> _loadAttachments() async {
    if (widget.existingShift == null) return;

    setState(() => _isLoadingAttachments = true);
    try {
      final attachments =
          await _db.getShiftAttachments(widget.existingShift!.id);
      setState(() {
        _attachments = attachments;
        _isLoadingAttachments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAttachments = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (widget.existingShift == null) return;

    // Check Pro status and limits (Mobile only)
    if (!kIsWeb) {
      final subscriptionService =
          Provider.of<SubscriptionService>(context, listen: false);
      if (!subscriptionService.isPro && _attachments.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Free limit reached (5 attachments). Upgrade to Pro!'),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaywallScreen()),
                );
              },
            ),
          ),
        );
        return;
      }
    }

    try {
      // Pick a file of any type
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploadingAttachment = true);

      final file = result.files.first;
      final fileBytes = file.bytes;
      final filePath = file.path;

      // Create File object from path or bytes
      File fileToUpload;
      if (filePath != null) {
        fileToUpload = File(filePath);
      } else if (fileBytes != null) {
        // Web platform - save bytes to temp file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(fileBytes);
        fileToUpload = tempFile;
      } else {
        throw Exception('Could not read file');
      }

      // Upload to Supabase
      final storagePath = await _db.uploadShiftAttachment(
        shiftId: widget.existingShift!.id,
        file: fileToUpload,
        fileName: file.name,
      );

      // Save metadata
      await _db.saveAttachmentMetadata(
        shiftId: widget.existingShift!.id,
        fileName: file.name,
        filePath: storagePath,
        fileType: file.extension ?? 'unknown',
        fileSize: file.size,
        fileExtension: file.extension ?? '',
      );

      // Reload attachments
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${file.name} attached successfully'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach file: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _deleteAttachment(ShiftAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Attachment?', style: AppTheme.titleMedium),
        content: Text(
          'Are you sure you want to delete "${attachment.fileName}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.deleteAttachment(attachment);
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${attachment.fileName} deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Widget _buildAttachmentsSection() {
    if (widget.existingShift == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.cardBackgroundLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_file, color: AppTheme.accentBlue, size: 20),
                  const SizedBox(width: 8),
                  Text('Attachments', style: AppTheme.titleMedium),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_attachments.length}',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: _isUploadingAttachment
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.primaryGreen),
                        ),
                      )
                    : Icon(Icons.add, color: AppTheme.primaryGreen),
                onPressed: _isUploadingAttachment ? null : _pickAndUploadFile,
                tooltip: 'Add Attachment',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAttachments)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                ),
              ),
            )
          else if (_attachments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.folder_open,
                        color: AppTheme.textMuted, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No attachments yet',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to attach PDFs, docs, Excel files, etc.',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                return _buildAttachmentTile(attachment);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(ShiftAttachment attachment) {
    IconData fileIcon;
    Color iconColor;

    // Determine icon and color based on file type
    if (attachment.isPdf) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = AppTheme.accentRed;
    } else if (attachment.isImage) {
      fileIcon = Icons.image;
      iconColor = AppTheme.accentPurple;
    } else if (attachment.isVideo) {
      fileIcon = Icons.videocam;
      iconColor = AppTheme.accentOrange;
    } else if (attachment.isDocument) {
      fileIcon = Icons.description;
      iconColor = AppTheme.accentBlue;
    } else if (attachment.isSpreadsheet) {
      fileIcon = Icons.table_chart;
      iconColor = AppTheme.primaryGreen;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = AppTheme.textMuted;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Open attachment (you can implement _openAttachment if needed)
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // File icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${attachment.extension.toUpperCase()} • ${attachment.formattedSize}',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete, color: AppTheme.dangerColor, size: 20),
                onPressed: () => _deleteAttachment(attachment),
                tooltip: 'Delete',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
