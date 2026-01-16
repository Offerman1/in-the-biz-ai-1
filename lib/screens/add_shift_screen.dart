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
import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, FunctionException;
import '../models/shift.dart';
import '../models/job.dart';
import '../models/job_template.dart';
import '../models/event_contact.dart';
import '../models/shift_attachment.dart';
import '../models/beo_event.dart';
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
import '../widgets/add_field_picker.dart';
import '../widgets/section_options_menu.dart';
import '../widgets/custom_time_picker.dart';
import 'beo_detail_screen.dart';
import '../widgets/add_section_picker.dart';
import 'dashboard_screen.dart';
import '../models/field_definition.dart';
import '../models/section_definition.dart';
import 'onboarding_screen.dart';
import 'add_job_screen.dart';
import 'settings_screen.dart';
import 'event_contacts_screen.dart';
import 'add_edit_contact_screen.dart';
import 'document_scanner_screen.dart';
import 'scan_verification_screen.dart';
import 'paywall_screen.dart';
import '../widgets/scan_type_menu.dart';
import '../widgets/document_preview_widget.dart';
import '../models/vision_scan.dart';
import '../services/vision_scanner_service.dart';
import '../services/scan_image_service.dart';
import '../services/beo_event_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../services/tour_service.dart';
import '../utils/tour_targets.dart';
import '../widgets/tour_transition_modal.dart';

class AddShiftScreen extends StatefulWidget {
  final Shift? existingShift;
  final String? aiAnalysis;
  final Uint8List? imageBytes;
  final DateTime? preselectedDate;
  final Map<String, dynamic>? prefilledCheckoutData;
  final Map<String, dynamic>? prefilledBeoData;
  final bool autoOpenBeoScanner;

  const AddShiftScreen({
    super.key,
    this.existingShift,
    this.aiAnalysis,
    this.imageBytes,
    this.preselectedDate,
    this.prefilledCheckoutData,
    this.prefilledBeoData,
    this.autoOpenBeoScanner = false,
  });

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final VisionScannerService _visionScanner = VisionScannerService();
  final ScanImageService _scanImageService = ScanImageService();

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
  final _sectionController =
      TextEditingController(); // NEW: Section/area worked
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

  // Custom field values (key -> value)
  final Map<String, dynamic> _customFieldValues = {};
  // Custom field controllers (key -> TextEditingController)
  final Map<String, TextEditingController> _customFieldControllers = {};

  // Hidden sections for this shift (per-shift override)
  List<String> _shiftHiddenSections = [];

  // Linked checkout ID (from server checkout scan)
  String? _checkoutId;

  // Linked BEO Event ID (from BEO scan)
  String? _beoEventId;

  // Linked BEO Event (loaded from database)
  BeoEvent? _linkedBeo;

  // Signed URL cache for fast image loading (storage_path -> signed_url)
  final Map<String, String> _signedUrlCache = {};
  bool _isLoadingSignedUrls = false;

  // Tour GlobalKeys
  final GlobalKey _scanButtonKey = GlobalKey();
  final GlobalKey _attachButtonKey =
      GlobalKey(); // Consolidated attachment button
  final GlobalKey _jobDropdownKey = GlobalKey();
  final GlobalKey _datePickerKey = GlobalKey();
  final GlobalKey _tipsFieldsKey = GlobalKey();
  final GlobalKey _photoButtonKey = GlobalKey();
  final GlobalKey _documentButtonKey = GlobalKey();
  final GlobalKey _contactButtonKey = GlobalKey();

  // Tour service
  TourService? _tourService;
  TutorialCoachMark? _tutorialCoachMark;
  bool _isTourShowing = false; // Guard to prevent multiple simultaneous tours

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
    if (widget.prefilledCheckoutData != null) {
      _applyCheckoutData();
    }
    if (widget.prefilledBeoData != null) {
      print('🎯 AddShiftScreen: prefilledBeoData = ${widget.prefilledBeoData}');
      _applyBeoData();
    }
    // Auto-open BEO scanner if flag is set
    if (widget.autoOpenBeoScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleScanTypeSelected(ScanType.beo);
      });
    }

    // Check if tour should start after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartTour();

      // Listen to tour service changes
      _tourService = Provider.of<TourService>(context, listen: false);
      _tourService?.addListener(_onTourServiceChanged);
    });
  }

  /// Apply checkout data to pre-fill form fields
  void _applyCheckoutData() {
    final data = widget.prefilledCheckoutData!;

    if (data['cashTips'] != null && data['cashTips'] != 0.0) {
      _cashTipsController.text = data['cashTips'].toString();
    }
    if (data['creditTips'] != null && data['creditTips'] != 0.0) {
      _creditTipsController.text = data['creditTips'].toString();
    }
    if (data['hoursWorked'] != null && data['hoursWorked'] != 0.0) {
      _hoursWorkedController.text = data['hoursWorked'].toString();
    }
    if (data['salesAmount'] != null && data['salesAmount'] != 0.0) {
      _salesAmountController.text = data['salesAmount'].toString();
    }
    if (data['additionalTipout'] != null && data['additionalTipout'] != 0.0) {
      _additionalTipoutController.text = data['additionalTipout'].toString();
    }
    if (data['guestCount'] != null) {
      _guestCountController.text = data['guestCount'].toString();
    }
    if (data['section'] != null && data['section'].toString().isNotEmpty) {
      _sectionController.text = data['section'].toString();
    }
    if (data['notes'] != null && data['notes'].toString().isNotEmpty) {
      _notesController.text = data['notes'].toString();
    }
    // Store checkout ID for linking
    if (data['checkoutId'] != null) {
      _checkoutId = data['checkoutId'].toString();
    }
  }

  /// Apply BEO data to pre-fill form fields
  void _applyBeoData() {
    final data = widget.prefilledBeoData!;

    if (data['event_name'] != null &&
        data['event_name'].toString().isNotEmpty) {
      _eventNameController.text = data['event_name'].toString();
    }
    if (data['location'] != null && data['location'].toString().isNotEmpty) {
      _locationController.text = data['location'].toString();
    }
    if (data['hostess'] != null && data['hostess'].toString().isNotEmpty) {
      _hostessController.text = data['hostess'].toString();
    }
    if (data['guest_count'] != null &&
        data['guest_count'].toString().isNotEmpty) {
      _guestCountController.text = data['guest_count'].toString();
    }
    if (data['event_cost'] != null &&
        data['event_cost'].toString().isNotEmpty) {
      _eventCostController.text = data['event_cost'].toString();
    }
    if (data['commission'] != null &&
        data['commission'].toString().isNotEmpty) {
      _commissionController.text = data['commission'].toString();
    }

    // Store BEO Event ID for linking
    if (data['beo_event_id'] != null) {
      _beoEventId = data['beo_event_id'].toString();
      print('🎯 Set _beoEventId: $_beoEventId');
    }

    // IMPORTANT: Make the Event Details/BEO section visible when BEO data is present
    // Remove from hidden sections if it was hidden
    _shiftHiddenSections.remove('event_contract');
    print('🎯 Made Event Details/BEO section visible');

    // Load the linked BEO from database
    if (_beoEventId != null) {
      _loadLinkedBeo();
    }

    // Preload signed URLs for all storage paths to fix performance
    _preloadSignedUrls();

    // Only set times if this is a NEW shift (no existing shift)
    // For existing shifts, preserve their scheduled work times
    // The BEO times are for the party, not the work schedule
    final isNewShift = widget.existingShift == null;

    if (isNewShift) {
      // Parse start time
      if (data['start_time'] != null &&
          data['start_time'].toString().isNotEmpty) {
        try {
          final time = data['start_time'].toString();
          final parts = time.split(':');
          if (parts.length >= 2) {
            _startTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (_) {}
      }
      // Parse end time
      if (data['end_time'] != null && data['end_time'].toString().isNotEmpty) {
        try {
          final time = data['end_time'].toString();
          final parts = time.split(':');
          if (parts.length >= 2) {
            _endTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (_) {}
      }
    }

    // Store BEO Event ID for linking
    if (data['beo_event_id'] != null) {
      _beoEventId = data['beo_event_id'].toString();
      print('🎯 Set _beoEventId: $_beoEventId');
    }
    // Add scanned image URLs as attachments
    if (data['image_urls'] != null && data['image_urls'] is List) {
      final urls = data['image_urls'] as List;
      for (final url in urls) {
        if (url != null && url.toString().isNotEmpty) {
          _capturedPhotos.add(url.toString());
          print(
              '🎯 Added image URL to _capturedPhotos: ${url.toString().substring(0, 50)}...');
        }
      }
      print('🎯 Total _capturedPhotos count: ${_capturedPhotos.length}');
    }

    // IMPORTANT: Make the Event Details/BEO section visible when BEO data is present
    // Remove from hidden sections if it was hidden
    _shiftHiddenSections.remove('event_contract');
    print('🎯 Made Event Details/BEO section visible');

    // Load the linked BEO from database
    if (_beoEventId != null) {
      _loadLinkedBeo();
    }

    // Preload signed URLs for all storage paths to fix performance
    _preloadSignedUrls();
  }

  /// Preload signed URLs for all storage paths to avoid individual API calls
  Future<void> _preloadSignedUrls() async {
    if (_isLoadingSignedUrls) return; // Prevent multiple calls

    setState(() => _isLoadingSignedUrls = true);

    try {
      // Get all storage paths that need signed URLs
      final storagePaths = _capturedPhotos.where((path) {
        final isUrl = path.startsWith('http://') || path.startsWith('https://');
        final isStoragePath = !isUrl &&
            (path.contains(
                    '/beo/') || // BEO images use shift-attachments bucket
                (path.contains('/') &&
                    path.split('/').length >= 2 &&
                    !path.startsWith('/') &&
                    !path.contains('\\') &&
                    !path.contains('cache') &&
                    !path.contains('tmp')));
        return isStoragePath;
      }).toList();

      if (storagePaths.isEmpty) return;

      print('🎯 Preloading ${storagePaths.length} signed URLs...');

      // Generate all signed URLs in parallel
      final signedUrlFutures = storagePaths.map((path) async {
        final bucketName = 'shift-attachments'; // Use existing bucket

        try {
          final signedUrl = await _db.getPhotoUrlForBucket(bucketName, path);
          return MapEntry(path, signedUrl);
        } catch (e) {
          print('🖼️ ERROR generating signed URL for $path: $e');
          return MapEntry(path, ''); // Empty string indicates error
        }
      }).toList();

      final signedUrls = await Future.wait(signedUrlFutures);

      // Cache all signed URLs
      for (final entry in signedUrls) {
        if (entry.value.isNotEmpty) {
          _signedUrlCache[entry.key] = entry.value;
        }
      }

      print('🎯 Cached ${_signedUrlCache.length} signed URLs');

      if (mounted) {
        setState(() {}); // Trigger rebuild to use cached URLs
      }
    } catch (e) {
      print('🖼️ ERROR preloading signed URLs: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSignedUrls = false);
      }
    }
  }

  /// Load the linked BEO event from database
  Future<void> _loadLinkedBeo() async {
    if (_beoEventId == null) return;
    try {
      final beoService = BeoEventService();
      final beo = await beoService.getBeoEventById(_beoEventId!);
      if (mounted && beo != null) {
        setState(() {
          _linkedBeo = beo;
          // Sync form fields with BEO data when BEO is updated
          _eventNameController.text = beo.eventName;
          if (beo.guestCountConfirmed != null) {
            _guestCountController.text = beo.guestCountConfirmed.toString();
          } else if (beo.displayGuestCount != null) {
            _guestCountController.text = beo.displayGuestCount.toString();
          }
          if (beo.functionSpace != null) {
            _locationController.text = beo.functionSpace!;
          }
          if (beo.primaryContactName != null) {
            _hostessController.text = beo.primaryContactName!;
          }
          if (beo.grandTotal != null) {
            _eventCostController.text = beo.grandTotal.toString();
          }
        });
        print('🎯 Loaded and synced linked BEO: ${beo.eventName}');
      }
    } catch (e) {
      print('Error loading linked BEO: $e');
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
    _sectionController.text = shift.section ?? '';
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

    // Load shift-level hidden sections
    _shiftHiddenSections = List.from(shift.shiftHiddenSections);

    // Load linked BEO Event ID and BEO data
    _beoEventId = shift.beoEventId;

    // If shift has a linked BEO, load it and make section visible
    if (_beoEventId != null) {
      print('🎯 Editing shift with linked BEO ID: $_beoEventId');
      _shiftHiddenSections.remove('event_contract'); // Make section visible
      _loadLinkedBeo();
    }

    // Load existing photos from shift_attachments table
    if (widget.existingShift != null) {
      _loadExistingPhotos();
    }
  }

  /// Load existing photos from shift_attachments table for editing
  Future<void> _loadExistingPhotos() async {
    if (widget.existingShift == null) return;

    try {
      print('🔍 Loading photos for shift ID: ${widget.existingShift!.id}');

      // Check both tables for debugging
      final attachmentsPhotos =
          await _db.getShiftPhotos(widget.existingShift!.id);
      print(
          '🔍 Found ${attachmentsPhotos.length} photos in shift_attachments table');

      // Also check old shift_photos table
      final oldPhotos = await _db.supabase
          .from('shift_photos')
          .select()
          .eq('shift_id', widget.existingShift!.id);
      print('🔍 Found ${oldPhotos.length} photos in OLD shift_photos table');

      // Use attachments photos (new system)
      for (final photo in attachmentsPhotos) {
        final storagePath = photo['storage_path'] as String;
        _capturedPhotos.add(storagePath);
        print('🔍 Added photo: $storagePath');
        setState(() {}); // Refresh UI to show loaded photos
      }
    } catch (e) {
      print('❌ Error loading existing photos: $e');
    }
  }

  @override
  void dispose() {
    _tourService?.removeListener(_onTourServiceChanged);
    _tutorialCoachMark = null;
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
    _sectionController.dispose();
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
    // Custom Fields
    for (final controller in _customFieldControllers.values) {
      controller.dispose();
    }
    _customFieldControllers.clear();
    super.dispose();
  }

  void _onTourServiceChanged() {
    if (!mounted) return;

    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 Tour service changed: isActive=${tourService.isActive}, expectedScreen=${tourService.expectedScreen}, currentStep=${tourService.currentStep}');

    // Trigger tour when entering Add Shift screen (steps 10-11)
    // Only trigger if not already showing
    if (tourService.isActive &&
        tourService.expectedScreen == 'addShift' &&
        tourService.currentStep >= 10 &&
        tourService.currentStep <= 11 &&
        !_isTourShowing) {
      debugPrint('🎯 Tour service changed - showing Add Shift tour');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showAddShiftTour();
        }
      });
    }
  }

  Future<void> _checkAndStartTour() async {
    if (!mounted) return;

    try {
      final tourService = Provider.of<TourService>(context, listen: false);

      debugPrint(
          '🎯 Tour Check: isActive=${tourService.isActive}, currentStep=${tourService.currentStep}, expectedScreen=${tourService.expectedScreen}');

      // Check if tour is active and we're on the expected screen
      if (tourService.isActive && tourService.expectedScreen == 'addShift') {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint('🎯 Starting Add Shift tour...');
          _showAddShiftTour();
        }
      } else {
        debugPrint('🎯 Tour not active or wrong screen');
      }
    } catch (e) {
      debugPrint('❌ Error checking tour: $e');
    }
  }

  void _showAddShiftTour() {
    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 _showAddShiftTour called, currentStep: ${tourService.currentStep}');

    // Guard: prevent multiple simultaneous tours
    if (_isTourShowing) {
      debugPrint('🎯 Tour already showing, skipping duplicate call');
      return;
    }

    // Don't call finish() - just set to null to avoid callback recursion
    _tutorialCoachMark = null;

    List<TargetFocus> targets = [];

    // Helper callbacks for skip functionality
    void onSkipToNext() {
      // Just set up state - no modal here (modal causes stacking issues)
      // The coach mark will close via controller.next()
      // Then user sees the pulsing Calendar button on dashboard
      tourService.setPulsingTarget('calendar');
      tourService.skipToScreen('calendar');
      // Pop back to dashboard after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    }

    void onEndTour() {
      tourService.skipAll();
    }

    // Step 10: Scan Button
    if (tourService.currentStep == 10) {
      debugPrint('🎯 Adding Scan button target');
      targets.add(TourTargets.createTarget(
        identify: 'scanButton',
        keyTarget: _scanButtonKey,
        title: '✨ AI-Powered Scanning',
        description:
            'Scan server checkouts, receipts, BEOs, business cards, paychecks, or invoices - AI extracts the data automatically! Create shifts from Server checkouts or BEO/Event Contracts!',
        currentScreen: 'addShift',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Step 11: Attachment Button (simplified - skip to this after scan)
    if (tourService.currentStep == 11) {
      debugPrint('🎯 Adding Attachment button target');
      targets.add(TourTargets.createTarget(
        identify: 'attachButton',
        keyTarget: _attachButtonKey,
        title: '📎 Attach Files',
        description:
            'Add photos, videos, or documents to any shift. Great for floor plans, receipts, or event photos!',
        currentScreen: 'addShift',
        onSkipToNext: onSkipToNext,
        onEndTour: onEndTour,
        align: ContentAlign.bottom,
      ));
    }

    // Steps 12-17: SKIPPED - these are industry-specific or covered by scan/attach
    // The tour ends after step 11 for Add Shift screen

    debugPrint('🎯 Total targets: ${targets.length}');

    if (targets.isEmpty) {
      debugPrint('🎯 No targets to show');
      return;
    }

    _isTourShowing = true; // Set guard BEFORE creating tour

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.primaryGreen,
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: true, // Hide default top-right skip button (we have our own)
      onFinish: () {
        debugPrint('🎯 Tour step finished, moving to next');
        _isTourShowing = false; // Clear guard
        _tutorialCoachMark = null;

        // If we're skipping to another screen, don't do anything here
        if (tourService.isSkippingToScreen) {
          debugPrint('🎯 Skipping to another screen, ignoring onFinish');
          tourService.clearSkippingFlag();
          return;
        }

        // Advance to next step
        tourService.nextStep();

        // Add Shift tour is now simplified: 10 (scan) → 11 (attach) → 12 (calendar)
        // Show step 11 if we just finished step 10
        if (tourService.currentStep == 11) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showAddShiftTour();
            }
          });
        }
        // After step 11, show transition to Calendar
        else if (tourService.currentStep == 12) {
          // Set Calendar as the pulsing target
          tourService.setPulsingTarget('calendar');
          // Show non-blocking floating hint
          TourTransitionModal.show(
            context: context,
            title: '📅 Explore the Calendar!',
            message: 'Tap the Calendar button below to continue.',
            onDismiss: () {
              // User will navigate back and tap Calendar
              // Pop this screen to go back to dashboard
              Navigator.pop(context);
            },
          );
        }
      },
      onSkip: () {
        debugPrint('🎯 Tour skipped');
        _isTourShowing = false; // Clear guard

        // If we're skipping to another screen, don't end the tour
        if (tourService.isSkippingToScreen) {
          debugPrint('🎯 Skipping to another screen, ignoring onSkip');
          tourService.clearSkippingFlag();
          _tutorialCoachMark = null;
          return true;
        }

        tourService.skipAll();
        _tutorialCoachMark = null;
        return true;
      },
    );

    debugPrint('🎯 Showing tutorial...');
    _tutorialCoachMark?.show(context: context);
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
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
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
                    builder: (_) => const SettingsScreen(),
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
        section: _sectionController.text.trim().isNotEmpty
            ? _sectionController.text.trim()
            : null,
        checkoutId: _checkoutId,
        beoEventId: _beoEventId,
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
        imageUrl:
            null, // BEO images now go to shift_attachments table, not imageUrl field
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
        // =====================================================
        // HIDDEN SECTIONS (per-shift override)
        // =====================================================
        shiftHiddenSections: _shiftHiddenSections,
      );

      // Debug logging
      print('🔍 SAVING SHIFT:');
      print('  Event Name: ${shift.eventName}');
      print('  BEO Event ID: ${shift.beoEventId}');
      print('  Hostess: ${shift.hostess}');
      print('  Guest Count: ${shift.guestCount}');
      print('  Location: ${shift.location}');
      print('  Photos: ${shift.imageUrl}');

      if (widget.existingShift != null) {
        await _db.updateShift(shift);
        // Upload any new photos for existing shift
        await _uploadCapturedPhotosToShiftPhotosTable(shift.id);

        // Send schedule change notification for edited shift
        if (!kIsWeb) {
          final jobName = _selectedJob?.name ?? 'Shift';
          await NotificationService().sendScheduleChangeAlert(
            message: 'Your $jobName shift has been updated',
            jobName: jobName,
          );
        }
      } else {
        // Handle recurring shifts
        if (_isRecurring && _selectedWeekdays.isNotEmpty) {
          await _createRecurringShifts(shift);
        } else {
          final savedShift = await _db.saveShift(shift);
          // Upload all captured photos to shift_attachments table for unified system
          await _uploadCapturedPhotosToShiftPhotosTable(savedShift.id);
        }
      }

      if (mounted) {
        final shiftProvider =
            Provider.of<ShiftProvider>(context, listen: false);
        await shiftProvider.loadShifts();

        // Check milestone celebrations after saving shift with earnings
        if (!kIsWeb) {
          final totalEarnings = shift.cashTips +
              shift.creditTips +
              (shift.commission ?? 0) +
              (shift.flatRate ?? 0) +
              (shift.hoursWorked * shift.hourlyRate);
          if (totalEarnings > 0) {
            // Get all shifts to calculate total earnings
            final allShifts = await _db.getShifts();
            final grandTotal = allShifts.fold<double>(
                0,
                (sum, s) =>
                    sum +
                    s.cashTips +
                    s.creditTips +
                    (s.commission ?? 0) +
                    (s.flatRate ?? 0) +
                    (s.hoursWorked * s.hourlyRate));
            await NotificationService().sendMilestoneCelebration(
              totalEarnings: grandTotal,
            );
          }
        }

        // Navigate to Calendar page (index 1) after saving shift
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(initialIndex: 1),
          ),
          (route) => false,
        );
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

  /// Upload all captured photos to shift_attachments table (unified system)
  Future<void> _uploadCapturedPhotosToShiftPhotosTable(String shiftId) async {
    if (_capturedPhotos.isEmpty) return;

    print(
        '🎯 Uploading ${_capturedPhotos.length} photos to shift_attachments table...');

    for (final photoPath in _capturedPhotos) {
      try {
        // Skip URLs - they're already uploaded
        if (photoPath.startsWith('http://') ||
            photoPath.startsWith('https://')) {
          continue;
        }

        // Check if it's a storage path (already uploaded) vs local file
        final isStoragePath = photoPath.contains('/beo/') ||
            (photoPath.contains('/') &&
                photoPath.split('/').length >= 2 &&
                !photoPath.startsWith('/') &&
                !photoPath.contains('\\') &&
                !photoPath.contains('cache') &&
                !photoPath.contains('tmp'));

        if (isStoragePath) {
          // Storage path - just add reference to shift_attachments table
          final userId = _db.supabase.auth.currentUser?.id;
          if (userId == null) continue;

          await _db.supabase.from('shift_attachments').insert({
            'shift_id': shiftId,
            'user_id': userId,
            'file_name': photoPath.split('/').last,
            'file_path': photoPath,
            'file_type': 'image',
            'file_size': 0,
            'file_extension': '.jpg',
          });

          print('🎯 Added storage path to shift_attachments: $photoPath');
        } else {
          // Local file - upload it
          final file = File(photoPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName =
                'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

            await _db.uploadPhoto(
              shiftId: shiftId,
              imageBytes: bytes,
              fileName: fileName,
              photoType: 'gallery',
            );

            print('🎯 Uploaded local file to shift_attachments: $photoPath');
          }
        }
      } catch (e) {
        print('🎯 Error uploading photo $photoPath: $e');
        // Continue with other photos
      }
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

  /// Check if a section is visible (not hidden)
  bool _isSectionVisible(String sectionKey) {
    // Check job template hidden sections
    final templateHidden = _template?.hiddenSections ?? [];
    // Check shift-level hidden sections
    final shiftHidden = _shiftHiddenSections;
    // Section is visible if NOT in either list
    return !templateHidden.contains(sectionKey) &&
        !shiftHidden.contains(sectionKey);
  }

  /// Get all hidden section keys
  List<String> _getAllHiddenSections() {
    final templateHidden = _template?.hiddenSections ?? [];
    return {...templateHidden, ..._shiftHiddenSections}.toList();
  }

  /// Handle section removal
  Future<void> _handleRemoveSection(
      String sectionKey, RemoveSectionOption option) async {
    if (option == RemoveSectionOption.cancel) return;

    switch (option) {
      case RemoveSectionOption.thisShiftOnly:
        // Add to shift-level hidden sections
        setState(() {
          if (!_shiftHiddenSections.contains(sectionKey)) {
            _shiftHiddenSections.add(sectionKey);
          }
        });
        _showSnackBar('Section hidden for this shift');
        break;

      case RemoveSectionOption.allFutureShifts:
        // Update job template
        await _updateTemplateHiddenSections(sectionKey, hide: true);
        _showSnackBar('Section hidden for all future shifts');
        break;

      case RemoveSectionOption.allShiftsIncludingPast:
        // Update job template AND batch update all existing shifts
        await _updateTemplateHiddenSections(sectionKey, hide: true);
        await _batchUpdateShiftsSections(sectionKey, hide: true);
        _showSnackBar('Section hidden for all shifts');
        break;

      case RemoveSectionOption.cancel:
        break;
    }
  }

  /// Handle section addition
  Future<void> _handleAddSection(
      String sectionKey, RemoveSectionOption scope) async {
    switch (scope) {
      case RemoveSectionOption.thisShiftOnly:
        // Remove from shift-level hidden sections
        setState(() {
          _shiftHiddenSections.remove(sectionKey);
        });
        _showSnackBar('Section added to this shift');
        break;

      case RemoveSectionOption.allFutureShifts:
        // Update job template
        await _updateTemplateHiddenSections(sectionKey, hide: false);
        _showSnackBar('Section added for all future shifts');
        break;

      case RemoveSectionOption.allShiftsIncludingPast:
        // Update job template AND batch update all existing shifts
        await _updateTemplateHiddenSections(sectionKey, hide: false);
        await _batchUpdateShiftsSections(sectionKey, hide: false);
        _showSnackBar('Section added to all shifts');
        break;

      case RemoveSectionOption.cancel:
        break;
    }
  }

  /// Update template hidden sections
  Future<void> _updateTemplateHiddenSections(String sectionKey,
      {required bool hide}) async {
    if (_selectedJob == null || _template == null) return;

    List<String> updatedHidden = List.from(_template!.hiddenSections);
    if (hide && !updatedHidden.contains(sectionKey)) {
      updatedHidden.add(sectionKey);
    } else if (!hide) {
      updatedHidden.remove(sectionKey);
    }

    final updatedTemplate = _template!.copyWith(hiddenSections: updatedHidden);
    final updatedJob = _selectedJob!.copyWith(template: updatedTemplate);

    try {
      await _db.updateJob(updatedJob);
      setState(() {
        _template = updatedTemplate;
        final index = _userJobs.indexWhere((j) => j.id == _selectedJob!.id);
        if (index >= 0) {
          _userJobs[index] = updatedJob;
        }
        _selectedJob = updatedJob;
      });
    } catch (e) {
      _showSnackBar('Failed to update template: $e');
    }
  }

  /// Batch update all shifts for this job
  Future<void> _batchUpdateShiftsSections(String sectionKey,
      {required bool hide}) async {
    if (_selectedJob == null) return;

    try {
      // Get all shifts for this job
      final shifts = await _db.getShiftsByJob(_selectedJob!.id);

      for (final shift in shifts) {
        List<String> updatedHidden = List.from(shift.shiftHiddenSections);
        if (hide && !updatedHidden.contains(sectionKey)) {
          updatedHidden.add(sectionKey);
        } else if (!hide) {
          updatedHidden.remove(sectionKey);
        }

        final updatedShift = shift.copyWith(shiftHiddenSections: updatedHidden);
        await _db.updateShift(updatedShift);
      }
    } catch (e) {
      _showSnackBar('Failed to update shifts: $e');
    }
  }

  /// Show a snackbar message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    print('🎯 _handleScanComplete CALLED!');
    print('🎯 Session scan type: ${session.scanType}');
    print('🎯 Session page count: ${session.pageCount}');
    print('🎯 Session image paths: ${session.imagePaths}');

    // Show loading indicator
    if (!mounted) {
      print('🎯 Widget not mounted, returning early');
      return;
    }

    print('🎯 Showing processing snackbar...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
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
        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.9),
      ),
    );

    try {
      print('🎯 Routing to handler for ${session.scanType}...');
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
        case ScanType.receipt:
          await _processReceiptScan(session);
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

      Map<String, dynamic> result;

      // Use bytes on web, file paths on mobile
      if (kIsWeb && session.hasBytes) {
        result = await _visionScanner.analyzeBEOFromBytes(
          session.imageBytes!,
          userId,
          mimeTypes: session.mimeTypes,
        );
      } else {
        result = await _visionScanner.analyzeBEO(session.imagePaths, userId);
      }

      if (!mounted) return;

      // Capture the BEO Event ID from the response
      final beoEventId = result['beoEventId'] as String?;
      print('🎯 Set _beoEventId: $beoEventId');

      // Add the BEO ID to extracted data so verification screen uses existing BEO
      if (beoEventId != null) {
        (result['data'] as Map<String, dynamic>)['id'] = beoEventId;
      }

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
            imagePaths: session.imagePaths,
            imageBytes: session.imageBytes,
            mimeTypes: session.mimeTypes,
            onConfirm: (data) async {
              // Store the BEO Event ID to link with shift
              setState(() {
                _beoEventId = beoEventId;

                // Pre-fill shift form with BEO data
                if (data['event_name'] != null) {
                  _eventNameController.text = data['event_name'].toString();
                }
                if (data['primary_contact_name'] != null) {
                  _hostessController.text =
                      data['primary_contact_name'].toString();
                }
                if (data['guest_count_confirmed'] != null) {
                  _guestCountController.text =
                      data['guest_count_confirmed'].toString();
                } else if (data['guest_count_expected'] != null) {
                  _guestCountController.text =
                      data['guest_count_expected'].toString();
                }
                if (data['venue_name'] != null) {
                  _locationController.text = data['venue_name'].toString();
                }

                // Financial data
                if (data['grand_total'] != null) {
                  _eventCostController.text = data['grand_total'].toString();
                } else if (data['total_sale_amount'] != null) {
                  _eventCostController.text =
                      data['total_sale_amount'].toString();
                }
                if (data['commission_amount'] != null) {
                  _commissionController.text =
                      data['commission_amount'].toString();
                }

                // Timing - ONLY set if this is a NEW shift (not editing existing)
                // For existing shifts, preserve the scheduled work times
                // The BEO's event time is for the party, not the work schedule
                final isNewShift = widget.existingShift == null;

                if (data['event_date'] != null && isNewShift) {
                  try {
                    _selectedDate =
                        DateTime.parse(data['event_date'].toString());
                  } catch (_) {}
                }

                // Only override times for NEW shifts
                // Existing shifts keep their scheduled work times
                if (isNewShift) {
                  if (data['event_start_time'] != null) {
                    try {
                      final time = data['event_start_time'].toString();
                      final parts = time.split(':');
                      if (parts.length >= 2) {
                        _startTime = TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        );
                      }
                    } catch (_) {}
                  }
                  if (data['event_end_time'] != null) {
                    try {
                      final time = data['event_end_time'].toString();
                      final parts = time.split(':');
                      if (parts.length >= 2) {
                        _endTime = TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        );
                      }
                    } catch (_) {}
                  }
                }

                // Notes
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
    final userId = _db.supabase.auth.currentUser!.id;

    try {
      print('💳 _processCheckoutScan started');
      print('💳 User ID: $userId');
      print(
          '💳 Calling analyzeCheckout with ${session.imagePaths.length} images');

      Map<String, dynamic> result;

      // Use bytes on web, file paths on mobile
      if (kIsWeb && session.hasBytes) {
        result = await _visionScanner.analyzeCheckoutFromBytes(
          session.imageBytes!,
          userId,
          shiftId: widget.existingShift?.id,
          mimeTypes: session.mimeTypes,
        );
      } else {
        result = await _visionScanner.analyzeCheckout(
          session.imagePaths,
          userId,
          shiftId: widget.existingShift?.id,
        );
      }

      print('💳 analyzeCheckout completed successfully');

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Get checkout ID from result
      final checkoutId = result['data']['id'] as String?;

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.checkout,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            imagePaths: session.imagePaths,
            imageBytes: session.imageBytes,
            mimeTypes: session.mimeTypes,
            onConfirm: (data) async {
              // Upload images to both buckets and create shift_attachments entries
              if (checkoutId != null && widget.existingShift != null) {
                await _scanImageService.uploadScanToShiftAttachments(
                  imagePaths: session.imagePaths,
                  imageBytes: session.imageBytes,
                  scanType: 'checkout',
                  entityId: checkoutId,
                  shiftId: widget.existingShift!.id,
                  mimeTypes: session.mimeTypes,
                );
              }
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
    } on FunctionException catch (e) {
      print(
          '💳 FunctionException in _processCheckoutScan: ${e.status} - ${e.details}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Check if it's a duplicate (409 Conflict)
      if (e.status == 409 && e.details != null) {
        final details = e.details as Map<String, dynamic>;
        final existingCheckout =
            details['existingCheckout'] as Map<String, dynamic>?;
        final extractedData = details['extractedData'] as Map<String, dynamic>?;

        if (existingCheckout != null && extractedData != null) {
          // Show duplicate dialog with options
          final action = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: Text(
                '⚠️ Duplicate Checkout Detected',
                style:
                    AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A checkout with the same financial data was already recorded:',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Date: ${existingCheckout['checkout_date']}',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                  Text(
                    '• Gross Sales: \$${existingCheckout['gross_sales']?.toStringAsFixed(2) ?? '0.00'}',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                  Text(
                    '• Net Tips: \$${existingCheckout['net_tips']?.toStringAsFixed(2) ?? '0.00'}',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'What would you like to do?',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'edit'),
                  child: Text('Edit Existing',
                      style: TextStyle(color: AppTheme.accentBlue)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'new'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save as New'),
                ),
              ],
            ),
          );

          if (action == 'edit') {
            // Navigate to verification screen with existing checkout data
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => ScanVerificationScreen(
                  scanType: ScanType.checkout,
                  extractedData: extractedData,
                  confidenceScores: extractedData['ai_confidence_scores']
                      as Map<String, dynamic>?,
                  existingCheckoutId: existingCheckout['id'],
                  onConfirm: (data) async {
                    // Update existing checkout in database
                    try {
                      await _db.supabase.from('server_checkouts').update({
                        ...data,
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', existingCheckout['id']);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Checkout updated successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update checkout: $e'),
                            backgroundColor: AppTheme.dangerColor,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          } else if (action == 'new') {
            // Force save as new checkout (with forceNew flag to bypass duplicate check)
            try {
              final result = await _visionScanner.analyzeCheckout(
                session.imagePaths,
                userId,
                shiftId: widget.existingShift?.id,
                forceNew: true, // This will bypass duplicate check
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('New checkout saved successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );

              // Show verification screen
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanVerificationScreen(
                    scanType: ScanType.checkout,
                    extractedData: result['data'] as Map<String, dynamic>,
                    confidenceScores: result['data']['ai_confidence_scores']
                        as Map<String, dynamic>?,
                    onConfirm: (data) async {
                      // Pre-fill shift form with checkout data
                      setState(() {
                        if (data['total_sales'] != null) {
                          _salesAmountController.text =
                              data['total_sales'].toString();
                        }
                        if (data['gross_tips'] != null) {
                          _creditTipsController.text =
                              data['gross_tips'].toString();
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
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save new checkout: $e'),
                    backgroundColor: AppTheme.dangerColor,
                  ),
                );
              }
            }
          }
          return;
        }
      }

      // Handle other FunctionException errors
      String errorMessage =
          'Checkout scan failed: ${e.details?['message'] ?? e.reasonPhrase}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.dangerColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, stackTrace) {
      print('💳 ERROR in _processCheckoutScan: $e');
      print('💳 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        // Check for JWT/auth errors
        String errorMessage = 'Checkout scan failed: $e';
        if (e.toString().contains('JWT') || e.toString().contains('401')) {
          errorMessage = '🔐 Session expired. Please log out and log back in.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 5),
            action: e.toString().contains('JWT') || e.toString().contains('401')
                ? SnackBarAction(
                    label: 'Log Out',
                    textColor: Colors.white,
                    onPressed: () async {
                      await _db.supabase.auth.signOut();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  /// Process business card scan - Add contact
  Future<void> _processBusinessCardScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;

      Map<String, dynamic> result;

      // Use bytes on web, file paths on mobile
      if (kIsWeb && session.hasBytes) {
        result = await _visionScanner.scanBusinessCardFromBytes(
          session.imageBytes!,
          userId,
          shiftId: widget.existingShift?.id,
          mimeTypes: session.mimeTypes,
        );
      } else {
        result = await _visionScanner.scanBusinessCard(
          session.imagePaths,
          userId,
          shiftId: widget.existingShift?.id,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Get contact ID from result
      final contactId = result['data']['id'] as String?;

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.businessCard,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            imagePaths: session.imagePaths,
            imageBytes: session.imageBytes,
            mimeTypes: session.mimeTypes,
            onConfirm: (data) async {
              // Upload images to both buckets and create shift_attachments entries
              if (contactId != null && widget.existingShift != null) {
                await _scanImageService.uploadScanToShiftAttachments(
                  imagePaths: session.imagePaths,
                  imageBytes: session.imageBytes,
                  scanType: 'business_card',
                  entityId: contactId,
                  shiftId: widget.existingShift!.id,
                  mimeTypes: session.mimeTypes,
                );
              }
              // Refresh the contacts list
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

      Map<String, dynamic> result;

      // Use bytes on web, file paths on mobile
      if (kIsWeb && session.hasBytes) {
        result = await _visionScanner.analyzePaycheckFromBytes(
          session.imageBytes!,
          userId,
          mimeTypes: session.mimeTypes,
        );
      } else {
        result =
            await _visionScanner.analyzePaycheck(session.imagePaths, userId);
      }

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

      Map<String, dynamic> result;

      // Use bytes on web, file paths on mobile
      if (kIsWeb && session.hasBytes) {
        result = await _visionScanner.analyzeInvoiceFromBytes(
          session.imageBytes!,
          userId,
          mimeTypes: session.mimeTypes,
        );
      } else {
        result =
            await _visionScanner.analyzeInvoice(session.imagePaths, userId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Get invoice ID from result
      final invoiceId = result['data']['id'] as String?;

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.invoice,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            imagePaths: session.imagePaths,
            imageBytes: session.imageBytes,
            mimeTypes: session.mimeTypes,
            onConfirm: (data) async {
              // Upload images to both buckets and create shift_attachments entries
              if (invoiceId != null && widget.existingShift != null) {
                await _scanImageService.uploadScanToShiftAttachments(
                  imagePaths: session.imagePaths,
                  imageBytes: session.imageBytes,
                  scanType: 'invoice',
                  entityId: invoiceId,
                  shiftId: widget.existingShift!.id,
                  mimeTypes: session.mimeTypes,
                );
              }
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

  /// Process receipt scan - Track expenses and deductions
  Future<void> _processReceiptScan(DocumentScanSession session) async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;

      Map<String, dynamic> result;

      // Use bytes on web, file paths on mobile
      if (kIsWeb && session.hasBytes) {
        result = await _visionScanner.analyzeReceiptFromBytes(
          session.imageBytes!,
          userId,
          shiftId: widget.existingShift?.id,
          mimeTypes: session.mimeTypes,
        );
      } else {
        result = await _visionScanner.analyzeReceipt(
          session.imagePaths,
          userId,
          shiftId: widget.existingShift?.id,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Get receipt ID from result
      final receiptId = result['data']['id'] as String?;

      // Show verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: ScanType.receipt,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            imagePaths: session.imagePaths,
            imageBytes: session.imageBytes,
            mimeTypes: session.mimeTypes,
            onConfirm: (data) async {
              // Upload images to both buckets and create shift_attachments entries
              if (receiptId != null && widget.existingShift != null) {
                await _scanImageService.uploadScanToShiftAttachments(
                  imagePaths: session.imagePaths,
                  imageBytes: session.imageBytes,
                  scanType: 'receipt',
                  entityId: receiptId,
                  shiftId: widget.existingShift!.id,
                  mimeTypes: session.mimeTypes,
                );
              }
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        final category = result['data']['expense_category'] as String?;
        final amount = result['data']['total_amount'] as num?;
        final deductibleAmount =
            result['deduction_summary']?['deductible_amount'] as num?;

        String message = 'Receipt saved!';
        if (category != null && amount != null) {
          message = 'Receipt saved: \$${amount.toStringAsFixed(2)} ($category)';
          if (deductibleAmount != null && deductibleAmount != amount) {
            message += ' - \$${deductibleAmount.toStringAsFixed(2)} deductible';
          }
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
            content: Text('Receipt scan failed: $e'),
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
          key: _photoButtonKey,
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
          key: _documentButtonKey,
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
              key: _scanButtonKey,
              icon: const Text('✨', style: TextStyle(fontSize: 24)),
              onPressed: () =>
                  showScanTypeMenu(context, _handleScanTypeSelected),
              tooltip: 'AI Scanner',
            ),
            // 📎 Attach button - Consolidated media menu
            IconButton(
              key: _attachButtonKey,
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

                  // Custom Fields Section (user-added fields)
                  if (_template != null &&
                      _template!.customFields.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCustomFieldsSection(),
                  ],

                  // Add Field Button
                  const SizedBox(height: 16),
                  _buildAddFieldButton(),

                  // Add Section Button (if sections are hidden)
                  if (_getAllHiddenSections().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildAddSectionButton(),
                  ],
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
                        color: Colors.black.withValues(alpha: 0.4),
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
            key: const ValueKey('time_section'),
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTimeSection(),
          ));
          break;

        case 'earnings_section':
          if (_template!.showTips || _template!.showCommission) {
            widgets.add(Padding(
              key: const ValueKey('earnings_section'),
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
              key: const ValueKey('event_details_section'),
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
              key: const ValueKey('work_details_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildWorkDetailsSection(),
            ));
          }
          break;

        case 'documentation_section':
          if (_template!.showNotes || _template!.showPhotos) {
            widgets.add(Padding(
              key: const ValueKey('documentation_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDocumentationSection(),
            ));
          }
          break;

        case 'attachments_section':
          if (widget.existingShift != null) {
            widgets.add(Padding(
              key: const ValueKey('attachments_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAttachmentsSection(),
            ));
          }
          break;

        case 'event_team_section':
          if (widget.existingShift != null) {
            widgets.add(Padding(
              key: const ValueKey('event_team_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventTeamSection(),
            ));
          }
          break;

        case 'invoices_section':
          if (_template!.showInvoices) {
            widgets.add(Padding(
              key: const ValueKey('invoices_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInvoicesSection(),
            ));
          }
          break;

        case 'receipts_section':
          if (_template!.showReceipts) {
            widgets.add(Padding(
              key: const ValueKey('receipts_section'),
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildReceiptsSection(),
            ));
          }
          break;
      }
    }

    return widgets;
  }

  /// Build custom fields section (user-added fields)
  Widget _buildCustomFieldsSection() {
    final customFields = _template?.customFields ?? [];
    if (customFields.isEmpty) return const SizedBox.shrink();

    // Sort by order
    final sortedFields = List<CustomField>.from(customFields)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      children: sortedFields.map((customField) {
        final fieldDef = FieldRegistry.getField(customField.key);
        if (fieldDef == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCustomFieldWidget(customField, fieldDef),
        );
      }).toList(),
    );
  }

  /// Build a single custom field widget
  Widget _buildCustomFieldWidget(
      CustomField customField, FieldDefinition fieldDef) {
    // Get or create controller for this field
    if (!_customFieldControllers.containsKey(customField.key)) {
      _customFieldControllers[customField.key] = TextEditingController();
    }
    final controller = _customFieldControllers[customField.key]!;

    return CollapsibleSection(
      title: fieldDef.label,
      icon: fieldDef.icon ?? Icons.text_fields,
      accentColor: customField.deductFromEarnings
          ? AppTheme.accentOrange
          : AppTheme.primaryGreen,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Deduction toggle (if applicable)
          if (fieldDef.canDeduct) ...[
            GestureDetector(
              onTap: () => _toggleDeduction(customField),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: customField.deductFromEarnings
                      ? AppTheme.accentOrange.withValues(alpha: 0.2)
                      : AppTheme.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      customField.deductFromEarnings
                          ? Icons.remove_circle
                          : Icons.remove_circle_outline,
                      size: 14,
                      color: customField.deductFromEarnings
                          ? AppTheme.accentOrange
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      customField.deductFromEarnings ? 'Deducting' : 'Deduct',
                      style: AppTheme.labelSmall.copyWith(
                        color: customField.deductFromEarnings
                            ? AppTheme.accentOrange
                            : AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: AppTheme.dangerColor, size: 20),
            onPressed: () => _removeCustomField(customField),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      children: [
        _buildCustomFieldInput(fieldDef, controller),
      ],
    );
  }

  /// Build the input widget based on field type
  Widget _buildCustomFieldInput(
      FieldDefinition fieldDef, TextEditingController controller) {
    switch (fieldDef.type) {
      case FieldType.currency:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: fieldDef.hintText ?? 'Enter amount',
            prefixText: '\$ ',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        );

      case FieldType.number:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: fieldDef.hintText ?? 'Enter number',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        );

      case FieldType.integer:
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: fieldDef.hintText ?? 'Enter count',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        );

      case FieldType.percentage:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: fieldDef.hintText ?? 'Enter percentage',
            suffixText: '%',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        );

      case FieldType.text:
      default:
        return TextFormField(
          controller: controller,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: fieldDef.hintText ?? 'Enter value',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        );
    }
  }

  /// Build the Add Field button
  Widget _buildAddFieldButton() {
    return OutlinedButton.icon(
      onPressed: _showAddFieldPicker,
      icon: Icon(Icons.add, color: AppTheme.primaryGreen),
      label: Text(
        'Add Field',
        style: TextStyle(color: AppTheme.primaryGreen),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  /// Build the Add Section button
  Widget _buildAddSectionButton() {
    final hiddenCount = _getAllHiddenSections().length;
    return OutlinedButton.icon(
      onPressed: _showAddSectionPicker,
      icon: Icon(Icons.view_module, color: AppTheme.accentBlue),
      label: Text(
        'Add Section ($hiddenCount hidden)',
        style: TextStyle(color: AppTheme.accentBlue),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppTheme.accentBlue.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  /// Show the Add Section picker
  void _showAddSectionPicker() {
    final hiddenSections = _getAllHiddenSections();
    AddSectionPicker.show(
      context: context,
      hiddenSectionKeys: hiddenSections,
      onSectionSelected: (sectionKey, scope) async {
        await _handleAddSection(sectionKey, scope);
      },
    );
  }

  /// Show the Add Field picker
  void _showAddFieldPicker() {
    final alreadyAddedKeys =
        _template?.customFields.map((f) => f.key).toList() ?? [];

    AddFieldPicker.show(
      context,
      alreadyAddedKeys: alreadyAddedKeys,
      onFieldSelected: (fieldDef, deductFromEarnings) async {
        await _addCustomField(fieldDef, deductFromEarnings);
      },
    );
  }

  /// Add a custom field to the template
  Future<void> _addCustomField(
      FieldDefinition fieldDef, bool deductFromEarnings) async {
    if (_selectedJob == null || _template == null) return;

    final newField = CustomField(
      key: fieldDef.key,
      enabled: true,
      deductFromEarnings: deductFromEarnings,
      order: _template!.customFields.length,
    );

    final updatedCustomFields = [..._template!.customFields, newField];
    final updatedTemplate =
        _template!.copyWith(customFields: updatedCustomFields);

    // Update the job with new template
    final updatedJob = _selectedJob!.copyWith(template: updatedTemplate);

    try {
      await _db.updateJob(updatedJob);

      setState(() {
        _template = updatedTemplate;
        // Update the job in the list
        final index = _userJobs.indexWhere((j) => j.id == _selectedJob!.id);
        if (index >= 0) {
          _userJobs[index] = updatedJob;
        }
        _selectedJob = updatedJob;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fieldDef.label} added'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add field: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Remove a custom field from the template
  Future<void> _removeCustomField(CustomField customField) async {
    final fieldDef = FieldRegistry.getField(customField.key);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Remove ${fieldDef?.label ?? customField.key}?',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This will remove this field from future shifts.\n\nData from past shifts will NOT be deleted.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove Field'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_selectedJob == null || _template == null) return;

    final updatedCustomFields =
        _template!.customFields.where((f) => f.key != customField.key).toList();
    final updatedTemplate =
        _template!.copyWith(customFields: updatedCustomFields);

    final updatedJob = _selectedJob!.copyWith(template: updatedTemplate);

    try {
      await _db.updateJob(updatedJob);

      // Clean up controller
      _customFieldControllers[customField.key]?.dispose();
      _customFieldControllers.remove(customField.key);
      _customFieldValues.remove(customField.key);

      setState(() {
        _template = updatedTemplate;
        final index = _userJobs.indexWhere((j) => j.id == _selectedJob!.id);
        if (index >= 0) {
          _userJobs[index] = updatedJob;
        }
        _selectedJob = updatedJob;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fieldDef?.label ?? customField.key} removed'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove field: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Toggle deduction for a custom field
  Future<void> _toggleDeduction(CustomField customField) async {
    if (_selectedJob == null || _template == null) return;

    final updatedCustomFields = _template!.customFields.map((f) {
      if (f.key == customField.key) {
        return f.copyWith(deductFromEarnings: !f.deductFromEarnings);
      }
      return f;
    }).toList();

    final updatedTemplate =
        _template!.copyWith(customFields: updatedCustomFields);
    final updatedJob = _selectedJob!.copyWith(template: updatedTemplate);

    try {
      await _db.updateJob(updatedJob);

      setState(() {
        _template = updatedTemplate;
        final index = _userJobs.indexWhere((j) => j.id == _selectedJob!.id);
        if (index >= 0) {
          _userJobs[index] = updatedJob;
        }
        _selectedJob = updatedJob;
      });
    } catch (e) {
      // Silently fail - user can try again
    }
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
    return Container(
      key: _jobDropdownKey,
      child: CollapsibleSection(
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
                  color: AppTheme.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.accentBlue.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      key: _datePickerKey,
      child: GestureDetector(
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
      ),
    );
  }

  Widget _buildTimeSection() {
    // Check visibility
    if (!_isSectionVisible('time_hours')) return const SizedBox.shrink();

    final hours = _calculateHours();
    final isUsingTimeRange = _startTime != null && _endTime != null;
    final manualHours = double.tryParse(_hoursWorkedController.text) ?? 0;
    final displayHours = isUsingTimeRange ? hours : manualHours;
    final hoursText = displayHours > 0 ? ': ${_formatHours(displayHours)}' : '';

    return CollapsibleSection(
      title: 'Time & Hours$hoursText',
      icon: Icons.access_time,
      trailing: SectionOptionsMenu(
        sectionKey: 'time_hours',
        onOptionSelected: (option) =>
            _handleRemoveSection('time_hours', option),
      ),
      children: [
        // ROW 1: Start Time & End Time (2x2 Grid)
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
        const SizedBox(height: 12),
        // ROW 2: Hours Worked & Hourly Rate (2x2 Grid)
        Row(
          children: [
            // Hours Worked - matching style of time pickers
            Expanded(
              child: GestureDetector(
                onTap: isUsingTimeRange ? null : () {},
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hours Worked', style: AppTheme.labelSmall),
                      const SizedBox(height: 4),
                      isUsingTimeRange
                          ? Text(
                              _formatHours(hours),
                              style: AppTheme.bodyLarge,
                            )
                          : TextField(
                              controller: _hoursWorkedController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: '8.5',
                                hintStyle: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Hourly Rate - matching style of time pickers
            Expanded(
              child: GestureDetector(
                onTap: _useHourlyRateOverride ? null : _showRateOverrideDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: _useHourlyRateOverride
                        ? Border.all(
                            color: AppTheme.accentOrange.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                                Text('Hourly Rate', style: AppTheme.labelSmall),
                          ),
                          if (_useHourlyRateOverride)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _useHourlyRateOverride = false;
                                  _hourlyRateOverrideController.clear();
                                });
                              },
                              child: Icon(Icons.close,
                                  size: 16, color: AppTheme.textMuted),
                            )
                          else
                            GestureDetector(
                              onTap: _showRateOverrideDialog,
                              child: Icon(Icons.edit,
                                  size: 16, color: AppTheme.primaryGreen),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _useHourlyRateOverride
                          ? TextField(
                              controller: _hourlyRateOverrideController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: '25.00',
                                hintStyle: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                                prefixText: '\$',
                                suffixText: '/hr',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            )
                          : Text(
                              '\$${(_selectedJob?.hourlyRate ?? 0).toStringAsFixed(2)}/hr',
                              style: AppTheme.bodyLarge,
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isUsingTimeRange) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hours auto-calculated from time range',
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
        final picked = await CustomTimePicker.show(
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
          activeThumbColor: AppTheme.primaryGreen,
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
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
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
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryGreen,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryGreen
            : AppTheme.textMuted.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildEarningsSection() {
    // Check visibility
    if (!_isSectionVisible('income_breakdown')) return const SizedBox.shrink();

    final cashTips = double.tryParse(_cashTipsController.text) ?? 0;
    final creditTips = double.tryParse(_creditTipsController.text) ?? 0;
    final commission = double.tryParse(_commissionController.text) ?? 0;
    final flatRate = double.tryParse(_flatRateController.text) ?? 0;
    final totalEarnings = cashTips + creditTips + commission + flatRate;
    final earningsText =
        totalEarnings > 0 ? ': ${_formatCurrency(totalEarnings)}' : '';

    return Container(
      key: _tipsFieldsKey,
      child: CollapsibleSection(
        title: 'Earnings$earningsText',
        icon: Icons.attach_money,
        accentColor: AppTheme.primaryGreen,
        trailing: SectionOptionsMenu(
          sectionKey: 'income_breakdown',
          onOptionSelected: (option) =>
              _handleRemoveSection('income_breakdown', option),
        ),
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
                      _tipoutPercentController.text = _selectedJob!
                          .defaultTipoutPercent!
                          .toStringAsFixed(1);
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: AppTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Tip out % (e.g., 2.5)',
                              suffixText: '% of sales',
                              suffixStyle: TextStyle(
                                  color: Colors.grey[500], fontSize: 11),
                              filled: true,
                              fillColor: AppTheme.cardBackgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
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
                              color:
                                  AppTheme.accentYellow.withValues(alpha: 0.1),
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
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
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
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
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
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildEventDetailsSection() {
    // Check visibility
    if (!_isSectionVisible('event_contract')) return const SizedBox.shrink();

    final guestCount = int.tryParse(_guestCountController.text);
    String summary = 'Event Details/BEO';

    if (_linkedBeo != null) {
      summary = 'Event Details/BEO: ${_linkedBeo!.eventName}';
    } else if (guestCount != null && guestCount > 0) {
      summary = 'Event Details/BEO: $guestCount guests';
    }

    // If we have a linked BEO, show read-only full details with edit button
    if (_linkedBeo != null) {
      return _buildLinkedBeoSection(summary);
    }

    // Otherwise show the editable fields
    return CollapsibleSection(
      title: summary,
      icon: Icons.celebration,
      trailing: SectionOptionsMenu(
        sectionKey: 'event_contract',
        onOptionSelected: (option) =>
            _handleRemoveSection('event_contract', option),
      ),
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

  /// Build read-only BEO section with all 40+ fields and edit button
  Widget _buildLinkedBeoSection(String summary) {
    final beo = _linkedBeo!;

    return CollapsibleSection(
      title: summary,
      icon: Icons.description,
      accentColor: AppTheme.accentPurple,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit button
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.accentPurple, size: 20),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BeoDetailScreen(
                    beoEvent: beo,
                    isEditing: true,
                  ),
                ),
              );
              // Reload BEO if it was edited
              if (result == true) {
                _loadLinkedBeo();
              }
            },
            tooltip: 'Edit BEO',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          SectionOptionsMenu(
            sectionKey: 'event_contract',
            onOptionSelected: (option) =>
                _handleRemoveSection('event_contract', option),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 8),
        // Build read-only display of all BEO fields
        ..._buildBeoDetailRows(beo),
      ],
    );
  }

  /// Format military time to AM/PM
  String _formatTimeToAmPm(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      // If already has AM/PM, return as-is
      if (time.toUpperCase().contains('AM') ||
          time.toUpperCase().contains('PM')) {
        return time;
      }
      // Parse military time
      final parts = time.split(':');
      if (parts.isEmpty) return time;
      var hour = int.parse(parts[0]);
      final minute = parts.length > 1
          ? parts[1]
              .replaceAll(RegExp(r'[^0-9]'), '')
              .padRight(2, '0')
              .substring(0, 2)
          : '00';
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  /// Check if text is a disclaimer/boilerplate
  bool _isDisclaimer(String? text) {
    if (text == null || text.isEmpty) return true;
    final lowerText = text.toLowerCase();
    final disclaimerPatterns = [
      'we\'re happy to accommodate',
      'prior to signing',
      'please specify',
      'certificate of liability',
      'certificate of insurance',
      'non-refundable deposit',
      'deposit is deducted',
      'final bill',
      'must be received',
      'cancellation policy',
      'terms and conditions',
      'subject to',
      '% of the estimated',
      'signed contract',
    ];
    for (final pattern in disclaimerPatterns) {
      if (lowerText.contains(pattern)) return true;
    }
    return false;
  }

  /// Build rows for all non-empty BEO fields - clean layout without icons on sub-fields
  List<Widget> _buildBeoDetailRows(BeoEvent beo) {
    final rows = <Widget>[];

    /// Add a section header with icon
    void addSectionHeader(String title, IconData icon) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.accentPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    /// Add a regular field row - no icons, consistent alignment
    void addRow(String label, String? value) {
      if (value != null && value.isNotEmpty && !_isDisclaimer(value)) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // EVENT INFO
    addSectionHeader('Event', Icons.celebration);
    addRow('Name', beo.eventName);
    addRow('Type', beo.eventType);
    addRow('Date', DateFormat('EEE, MMM d, yyyy').format(beo.eventDate));
    if (beo.eventStartTime != null || beo.eventEndTime != null) {
      String time = '';
      if (beo.eventStartTime != null)
        time = _formatTimeToAmPm(beo.eventStartTime);
      if (beo.eventEndTime != null)
        time += ' - ${_formatTimeToAmPm(beo.eventEndTime)}';
      addRow('Time', time);
    }
    addRow('Account', beo.accountName);

    // VENUE
    addSectionHeader('Venue', Icons.location_on);
    addRow('Name', beo.venueName);
    addRow('Function Space', beo.functionSpace);
    addRow('Address', beo.venueAddress);

    // GUEST COUNT
    if ((beo.displayGuestCount ?? 0) > 0 ||
        beo.guestCountExpected != null ||
        beo.guestCountConfirmed != null) {
      addSectionHeader('Guests', Icons.people);
      if (beo.displayGuestCount != null && beo.displayGuestCount! > 0) {
        addRow('Total', '${beo.displayGuestCount}');
      }
      addRow('Expected', beo.guestCountExpected?.toString());
      addRow('Confirmed', beo.guestCountConfirmed?.toString());
      addRow('Adults', beo.adultCount?.toString());
      addRow('Children', beo.childCount?.toString());
    }

    // TIMELINE
    if (beo.loadInTime != null ||
        beo.setupTime != null ||
        beo.guestArrivalTime != null) {
      addSectionHeader('Timeline', Icons.schedule);
      addRow('Load In', _formatTimeToAmPm(beo.loadInTime));
      addRow('Setup', _formatTimeToAmPm(beo.setupTime));
      addRow('Guest Arrival', _formatTimeToAmPm(beo.guestArrivalTime));
      addRow('Breakdown', _formatTimeToAmPm(beo.breakdownTime));
      addRow('Load Out', _formatTimeToAmPm(beo.loadOutTime));
    }

    // FINANCIALS
    if (beo.grandTotal != null ||
        beo.foodTotal != null ||
        beo.depositAmount != null) {
      addSectionHeader('Financials', Icons.attach_money);
      if (beo.foodTotal != null)
        addRow('Food', '\$${beo.foodTotal!.toStringAsFixed(2)}');
      if (beo.beverageTotal != null)
        addRow('Beverage', '\$${beo.beverageTotal!.toStringAsFixed(2)}');
      if (beo.laborTotal != null)
        addRow('Labor', '\$${beo.laborTotal!.toStringAsFixed(2)}');
      if (beo.roomRental != null)
        addRow('Room Rental', '\$${beo.roomRental!.toStringAsFixed(2)}');
      if (beo.subtotal != null)
        addRow('Subtotal', '\$${beo.subtotal!.toStringAsFixed(2)}');
      if (beo.serviceChargePercent != null)
        addRow('Service Charge',
            '${beo.serviceChargePercent!.toStringAsFixed(1)}%');
      if (beo.taxAmount != null)
        addRow('Tax', '\$${beo.taxAmount!.toStringAsFixed(2)}');
      if (beo.gratuityAmount != null)
        addRow('Gratuity', '\$${beo.gratuityAmount!.toStringAsFixed(2)}');
      if (beo.grandTotal != null)
        addRow('Grand Total', '\$${beo.grandTotal!.toStringAsFixed(2)}');
      if (beo.depositAmount != null)
        addRow('Deposit', '\$${beo.depositAmount!.toStringAsFixed(2)}');
      if (beo.balanceDue != null)
        addRow('Balance Due', '\$${beo.balanceDue!.toStringAsFixed(2)}');
    }

    // CONTACTS
    if (beo.primaryContactName != null || beo.salesManagerName != null) {
      addSectionHeader('Contacts', Icons.person);
      addRow('Primary', beo.primaryContactName);
      addRow('Phone', beo.primaryContactPhone);
      addRow('Email', beo.primaryContactEmail);
      addRow('Sales Manager', beo.salesManagerName);
      addRow('Catering Manager', beo.cateringManagerName);
    }

    // MENU
    if (beo.menuStyle != null ||
        beo.menuItems != null ||
        beo.menuDetails != null) {
      addSectionHeader('Menu', Icons.restaurant_menu);
      addRow('Style', beo.menuStyle);

      // Display detailed menu breakdown if available
      if (beo.menuDetails != null && beo.menuDetails!.isNotEmpty) {
        final md = beo.menuDetails!;

        // Appetizers
        if (md['appetizers'] != null && (md['appetizers'] as List).isNotEmpty) {
          final items = (md['appetizers'] as List)
              .map((a) => a['name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (items.isNotEmpty) addRow('Appetizers', items);
        }

        // Salads
        if (md['salads'] != null && (md['salads'] as List).isNotEmpty) {
          final items = (md['salads'] as List)
              .map((a) => a['name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (items.isNotEmpty) addRow('Salads', items);
        }

        // Entrees
        if (md['entrees'] != null && (md['entrees'] as List).isNotEmpty) {
          final items = (md['entrees'] as List)
              .map((a) => a['name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (items.isNotEmpty) addRow('Entrees', items);
        }

        // Sides
        if (md['sides'] != null && (md['sides'] as List).isNotEmpty) {
          final items = (md['sides'] as List)
              .map((a) => a['name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (items.isNotEmpty) addRow('Sides', items);
        }

        // Desserts
        if (md['desserts'] != null && (md['desserts'] as List).isNotEmpty) {
          final items = (md['desserts'] as List)
              .map((a) => a['name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (items.isNotEmpty) addRow('Desserts', items);
        }

        // Passed Items
        if (md['passed_items'] != null &&
            (md['passed_items'] as List).isNotEmpty) {
          final items = (md['passed_items'] as List)
              .map((a) => a['name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (items.isNotEmpty) addRow('Passed Items', items);
        }
      } else if (beo.menuItems != null) {
        // Fall back to legacy menu items string
        addRow('Items', beo.menuItems);
      }

      addRow('Dietary', beo.dietaryRestrictions);
    }

    // BEVERAGES
    if (beo.beverageDetails != null && beo.beverageDetails!.isNotEmpty) {
      addSectionHeader('Beverages', Icons.local_bar);
      final bd = beo.beverageDetails!;
      addRow('Package', bd['package']?.toString());
      addRow('Bar Type', bd['bar_type']?.toString());
      if (bd['price_per_person'] != null) {
        addRow('Per Person', '\$${bd['price_per_person']}');
      }
      addRow('Brands', bd['brands']?.toString());
    }

    // SETUP & DECOR
    if (beo.decorNotes != null ||
        beo.floorPlanNotes != null ||
        beo.setupDetails != null) {
      addSectionHeader('Setup & Decor', Icons.design_services);

      // Display detailed setup if available
      if (beo.setupDetails != null && beo.setupDetails!.isNotEmpty) {
        final sd = beo.setupDetails!;

        // Tables
        if (sd['tables'] != null && (sd['tables'] as List).isNotEmpty) {
          final tables = (sd['tables'] as List)
              .map((t) =>
                  '${t['qty']} ${t['type']}${t['linen_color'] != null ? ' (${t['linen_color']})' : ''}')
              .join(', ');
          if (tables.isNotEmpty) addRow('Tables', tables);
        }

        // Linens
        if (sd['linens'] != null && sd['linens'] is Map) {
          final linens = sd['linens'] as Map;
          final linenList = <String>[];
          if (linens['tablecloths'] != null)
            linenList.add('Tablecloths: ${linens['tablecloths']}');
          if (linens['napkins'] != null)
            linenList.add('Napkins: ${linens['napkins']}');
          if (linenList.isNotEmpty) addRow('Linens', linenList.join(', '));
        }

        // Chairs
        if (sd['chairs'] != null && sd['chairs'] is Map) {
          final chairs = sd['chairs'] as Map;
          addRow('Chairs', '${chairs['qty']} ${chairs['type']}');
        }

        // Decor
        if (sd['decor'] != null && (sd['decor'] as List).isNotEmpty) {
          addRow('Decor Items', (sd['decor'] as List).join(', '));
        }

        // AV Equipment
        if (sd['av_equipment'] != null &&
            (sd['av_equipment'] as List).isNotEmpty) {
          addRow('AV Equipment', (sd['av_equipment'] as List).join(', '));
        }

        // Special Items
        if (sd['special_items'] != null &&
            (sd['special_items'] as List).isNotEmpty) {
          addRow('Special Items', (sd['special_items'] as List).join(', '));
        }
      }

      addRow('Decor Notes', beo.decorNotes);
      addRow('Floor Plan', beo.floorPlanNotes);
    }

    // NOTES
    if (beo.specialRequests != null || beo.formattedNotes != null) {
      addSectionHeader('Notes', Icons.note);
      addRow('Special Requests', beo.specialRequests);
      addRow('Notes', beo.formattedNotes);
    }

    // BILLING
    if (beo.paymentMethod != null) {
      addSectionHeader('Billing', Icons.payment);
      addRow('Payment Method', beo.paymentMethod);
    }

    return rows;
  }

  Widget _buildWorkDetailsSection() {
    // Check visibility
    if (!_isSectionVisible('work_details')) return const SizedBox.shrink();

    return CollapsibleSection(
      title: 'Work Details',
      icon: Icons.location_on,
      accentColor: AppTheme.accentBlue,
      trailing: SectionOptionsMenu(
        sectionKey: 'work_details',
        onOptionSelected: (option) =>
            _handleRemoveSection('work_details', option),
      ),
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
        // Section field (Main Dining, Bar, Patio, etc.) - for restaurant/hospitality jobs
        TextFormField(
          controller: _sectionController,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Section or area (e.g., Main Dining, Bar, Patio)',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
    // Check visibility
    if (!_isSectionVisible('notes')) return const SizedBox.shrink();

    return CollapsibleSection(
      title: 'Documentation',
      icon: Icons.description,
      trailing: SectionOptionsMenu(
        sectionKey: 'notes',
        onOptionSelected: (option) => _handleRemoveSection('notes', option),
      ),
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

  Widget _buildPhotoThumbnails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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

    // Check if this is a URL (from Supabase storage) or a local file
    final isUrl =
        filePath.startsWith('http://') || filePath.startsWith('https://');

    // Check if this is a storage path (Supabase storage paths - NOT local file paths)
    final isStoragePath = !isUrl &&
        (filePath.contains('/scans/') || // BEO scans: userId/scans/beo/file.jpg
            (filePath.contains('/') &&
                filePath.split('/').length >= 2 &&
                !filePath
                    .startsWith('/') && // NOT local file path like /data/...
                !filePath.contains('\\') && // NOT Windows path like C:\...
                !filePath.contains('cache') && // NOT cache path
                !filePath.contains('tmp'))); // NOT temp path

    print(
        '🖼️ Building thumbnail for: ${filePath.length > 60 ? '${filePath.substring(0, 60)}...' : filePath}');
    print(
        '🖼️ isUrl: $isUrl, isStoragePath: $isStoragePath, extension: $extension');

    // Determine if it's an image or video
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension) ||
            ((isUrl || isStoragePath) &&
                ![
                  'mp4',
                  'mov',
                  'avi',
                  'mkv',
                  'flv',
                  'wmv',
                  'pdf',
                  'doc',
                  'docx'
                ].any((ext) => filePath.toLowerCase().contains('.$ext')));
    final isVideo =
        ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'].contains(extension);

    print('🖼️ isImage: $isImage, isVideo: $isVideo');

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

    // Build the image widget based on whether it's a URL, storage path, or local file
    Widget imageWidget;
    if (isUrl) {
      // Network image from Supabase storage (full URL)
      imageWidget = Image.network(
        filePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppTheme.cardBackgroundLight,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppTheme.primaryGreen,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('🖼️ ERROR loading network image: $error');
          print('🖼️ URL was: $filePath');
          return Container(
            color: AppTheme.cardBackgroundLight,
            child: Icon(
              Icons.broken_image,
              color: AppTheme.textMuted,
              size: 40,
            ),
          );
        },
      );
    } else if (isStoragePath) {
      // Use cached signed URL if available, otherwise show loading
      final cachedUrl = _signedUrlCache[filePath];

      if (cachedUrl != null) {
        // Use cached signed URL - INSTANT loading!
        imageWidget = Image.network(
          cachedUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('🖼️ ERROR loading cached image: $error');
            print('🖼️ Cached URL was: $cachedUrl');
            return Container(
              color: AppTheme.cardBackgroundLight,
              child: Icon(
                Icons.broken_image,
                color: AppTheme.textMuted,
                size: 40,
              ),
            );
          },
        );
      } else if (_isLoadingSignedUrls) {
        // Currently loading signed URLs - show spinner
        imageWidget = Container(
          color: AppTheme.cardBackgroundLight,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        );
      } else {
        // No cached URL and not loading - show error
        imageWidget = Container(
          color: AppTheme.cardBackgroundLight,
          child: Icon(
            Icons.broken_image,
            color: AppTheme.textMuted,
            size: 40,
          ),
        );
      }
    } else {
      // Local file
      imageWidget = Image.file(
        File(filePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('🖼️ ERROR loading local file: $error');
          return Container(
            color: AppTheme.cardBackgroundLight,
            child: Icon(
              isVideo ? Icons.videocam : Icons.broken_image,
              color: AppTheme.textMuted,
              size: 40,
            ),
          );
        },
      );
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
                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                : iconColor.withValues(alpha: 0.3),
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
                        imageWidget,
                        if (isVideo)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
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
                    color: Colors.black.withValues(alpha: 0.6),
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
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
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
                    color: AppTheme.accentBlue.withValues(alpha: 0.15),
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
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
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
                      key: _contactButtonKey,
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
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
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
                    const SizedBox(height: 2),
                    Text(
                      contact.role.displayName,
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
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
                  MaterialPageRoute(
                      builder: (context) => const PaywallScreen()),
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
    // Check visibility
    if (!_isSectionVisible('attachments')) return const SizedBox.shrink();

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
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
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
                return Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 80,
                      child: DocumentPreviewWidget(
                        attachment: attachment,
                        showFileName: false,
                        showFileSize: false,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          const SizedBox(height: 4),
                          Text(
                            '${attachment.extension.toUpperCase()} • ${attachment.formattedSize}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: AppTheme.dangerColor, size: 20),
                      onPressed: () => _deleteAttachment(attachment),
                      tooltip: 'Delete',
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================
  // INVOICES & RECEIPTS SECTIONS
  // ============================================

  /// Build the Invoices section (for freelancers/contractors)
  Widget _buildInvoicesSection() {
    return CollapsibleSection(
      title: 'Invoices',
      icon: Icons.receipt_long,
      accentColor: AppTheme.accentBlue,
      initiallyExpanded: false,
      children: [
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleScanTypeSelected(ScanType.invoice),
                icon: const Icon(Icons.document_scanner, size: 18),
                label: const Text('Scan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                  side: BorderSide(
                      color: AppTheme.accentBlue.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickInvoiceFile,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentPurple,
                  side: BorderSide(
                      color: AppTheme.accentPurple.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showManualInvoiceForm,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Manual'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Invoice list (placeholder)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long, color: AppTheme.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(
                'No invoices attached',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan, upload, or add manually',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the Receipts section (for expense tracking)
  Widget _buildReceiptsSection() {
    return CollapsibleSection(
      title: 'Receipts & Expenses',
      icon: Icons.receipt,
      accentColor: AppTheme.accentOrange,
      initiallyExpanded: false,
      children: [
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleScanTypeSelected(ScanType.receipt),
                icon: const Icon(Icons.document_scanner, size: 18),
                label: const Text('Scan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentOrange,
                  side: BorderSide(
                      color: AppTheme.accentOrange.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickReceiptFile,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentPurple,
                  side: BorderSide(
                      color: AppTheme.accentPurple.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showManualReceiptForm,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Manual'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Receipt list (placeholder)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt, color: AppTheme.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(
                'No receipts attached',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Track expenses for tax deductions',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pick and upload invoice file
  Future<void> _pickInvoiceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading invoice...'),
              ],
            ),
            backgroundColor: AppTheme.accentBlue,
            duration: const Duration(seconds: 10),
          ),
        );

        // Upload to Supabase storage
        final userId = _db.supabase.auth.currentUser!.id;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final storagePath = '$userId/invoices/$fileName';

        await _db.supabase.storage.from('documents').uploadBinary(
              storagePath,
              file.bytes!,
              fileOptions: FileOptions(
                  contentType: _getContentType(file.extension ?? '')),
            );

        final publicUrl =
            _db.supabase.storage.from('documents').getPublicUrl(storagePath);

        // Create invoice record
        await _db.createInvoice({
          'shift_id': widget.existingShift?.id,
          'invoice_number': 'UPLOAD-${DateTime.now().millisecondsSinceEpoch}',
          'client_name': 'Uploaded Invoice',
          'total_amount': 0, // User can update later
          'invoice_date': DateTime.now().toIso8601String().split('T')[0],
          'status': 'draft',
          'image_urls': [publicUrl],
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invoice uploaded! Edit to add details.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading invoice: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Pick and upload receipt file
  Future<void> _pickReceiptFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading receipt...'),
              ],
            ),
            backgroundColor: AppTheme.accentOrange,
            duration: const Duration(seconds: 10),
          ),
        );

        // Upload to Supabase storage
        final userId = _db.supabase.auth.currentUser!.id;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final storagePath = '$userId/receipts/$fileName';

        await _db.supabase.storage.from('documents').uploadBinary(
              storagePath,
              file.bytes!,
              fileOptions: FileOptions(
                  contentType: _getContentType(file.extension ?? '')),
            );

        final publicUrl =
            _db.supabase.storage.from('documents').getPublicUrl(storagePath);

        // Create receipt record
        await _db.createReceipt({
          'shift_id': widget.existingShift?.id,
          'vendor_name': file.name.split('.').first,
          'total_amount': 0, // User can update later
          'receipt_date': DateTime.now().toIso8601String().split('T')[0],
          'expense_category': 'other',
          'is_tax_deductible': true,
          'image_urls': [publicUrl],
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Receipt uploaded! Edit to add details.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading receipt: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Get content type for file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Show manual invoice entry form
  void _showManualInvoiceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualInvoiceForm(
        onSave: (invoiceData) async {
          Navigator.pop(context);
          try {
            // Add shift_id if editing an existing shift
            if (widget.existingShift != null) {
              invoiceData['shift_id'] = widget.existingShift!.id;
            }
            await _db.createInvoice(invoiceData);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Invoice added!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving invoice: $e'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Show manual receipt entry form
  void _showManualReceiptForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualReceiptForm(
        onSave: (receiptData) async {
          Navigator.pop(context);
          try {
            // Add shift_id if editing an existing shift
            if (widget.existingShift != null) {
              receiptData['shift_id'] = widget.existingShift!.id;
            }
            await _db.createReceipt(receiptData);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Receipt added!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving receipt: $e'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ============================================
// MANUAL ENTRY FORM WIDGETS
// ============================================

/// Manual Invoice Entry Form
class _ManualInvoiceForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _ManualInvoiceForm({required this.onSave});

  @override
  State<_ManualInvoiceForm> createState() => _ManualInvoiceFormState();
}

class _ManualInvoiceFormState extends State<_ManualInvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _status = 'draft';

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Invoice', style: AppTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Invoice Number
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: InputDecoration(
                      labelText: 'Invoice Number',
                      hintText: 'INV-001',
                      prefixIcon: Icon(Icons.tag, color: AppTheme.accentBlue),
                    ),
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  // Client Name
                  TextFormField(
                    controller: _clientNameController,
                    decoration: InputDecoration(
                      labelText: 'Client Name *',
                      hintText: 'Acme Corp',
                      prefixIcon:
                          Icon(Icons.business, color: AppTheme.accentBlue),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Client Email
                  TextFormField(
                    controller: _clientEmailController,
                    decoration: InputDecoration(
                      labelText: 'Client Email',
                      hintText: 'client@example.com',
                      prefixIcon: Icon(Icons.email, color: AppTheme.accentBlue),
                    ),
                    style: AppTheme.bodyMedium,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Total Amount *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money,
                          color: AppTheme.primaryGreen),
                    ),
                    style: AppTheme.bodyMedium,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Services rendered...',
                      prefixIcon:
                          Icon(Icons.description, color: AppTheme.textMuted),
                    ),
                    style: AppTheme.bodyMedium,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Invoice Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.calendar_today, color: AppTheme.accentBlue),
                    title: Text('Invoice Date', style: AppTheme.bodyMedium),
                    subtitle: Text(
                      '${_invoiceDate.month}/${_invoiceDate.day}/${_invoiceDate.year}',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _invoiceDate = picked);
                    },
                  ),
                  // Due Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event, color: AppTheme.accentOrange),
                    title: Text('Due Date', style: AppTheme.bodyMedium),
                    subtitle: Text(
                      _dueDate != null
                          ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                          : 'Not set',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Status
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon:
                          Icon(Icons.flag, color: AppTheme.accentPurple),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'sent', child: Text('Sent')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(
                          value: 'overdue', child: Text('Overdue')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'draft'),
                  ),
                  const SizedBox(height: 32),
                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSave({
                          'invoice_number': _invoiceNumberController.text,
                          'client_name': _clientNameController.text,
                          'client_email': _clientEmailController.text,
                          'total_amount':
                              double.tryParse(_amountController.text) ?? 0,
                          'description': _descriptionController.text,
                          'invoice_date': _invoiceDate.toIso8601String(),
                          'due_date': _dueDate?.toIso8601String(),
                          'status': _status,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Invoice',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Manual Receipt Entry Form
class _ManualReceiptForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _ManualReceiptForm({required this.onSave});

  @override
  State<_ManualReceiptForm> createState() => _ManualReceiptFormState();
}

class _ManualReceiptFormState extends State<_ManualReceiptForm> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _receiptDate = DateTime.now();
  String _expenseCategory = 'supplies';
  bool _isTaxDeductible = true;
  String _paymentMethod = 'credit_card';

  static const List<Map<String, String>> _expenseCategories = [
    {'value': 'supplies', 'label': 'Supplies & Materials'},
    {'value': 'equipment', 'label': 'Equipment'},
    {'value': 'travel', 'label': 'Travel & Transportation'},
    {'value': 'meals', 'label': 'Meals & Entertainment'},
    {'value': 'fuel', 'label': 'Fuel & Gas'},
    {'value': 'parking', 'label': 'Parking & Tolls'},
    {'value': 'utilities', 'label': 'Utilities'},
    {'value': 'software', 'label': 'Software & Subscriptions'},
    {'value': 'office', 'label': 'Office Expenses'},
    {'value': 'professional', 'label': 'Professional Services'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _vendorNameController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Receipt', style: AppTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vendor Name
                  TextFormField(
                    controller: _vendorNameController,
                    decoration: InputDecoration(
                      labelText: 'Vendor/Store Name *',
                      hintText: 'Home Depot',
                      prefixIcon:
                          Icon(Icons.store, color: AppTheme.accentOrange),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Total Amount *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money,
                          color: AppTheme.primaryGreen),
                    ),
                    style: AppTheme.bodyMedium,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Tax Amount
                  TextFormField(
                    controller: _taxController,
                    decoration: InputDecoration(
                      labelText: 'Tax Amount',
                      hintText: '0.00',
                      prefixIcon:
                          Icon(Icons.calculate, color: AppTheme.textMuted),
                    ),
                    style: AppTheme.bodyMedium,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  // Expense Category
                  DropdownButtonFormField<String>(
                    initialValue: _expenseCategory,
                    decoration: InputDecoration(
                      labelText: 'Expense Category',
                      prefixIcon:
                          Icon(Icons.category, color: AppTheme.accentPurple),
                    ),
                    items: _expenseCategories
                        .map((c) => DropdownMenuItem(
                              value: c['value'],
                              child: Text(c['label']!),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _expenseCategory = v ?? 'supplies'),
                  ),
                  const SizedBox(height: 16),
                  // Payment Method
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon:
                          Icon(Icons.payment, color: AppTheme.accentBlue),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                          value: 'credit_card', child: Text('Credit Card')),
                      DropdownMenuItem(
                          value: 'debit_card', child: Text('Debit Card')),
                      DropdownMenuItem(value: 'check', child: Text('Check')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? 'credit_card'),
                  ),
                  const SizedBox(height: 16),
                  // Receipt Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today,
                        color: AppTheme.accentOrange),
                    title: Text('Receipt Date', style: AppTheme.bodyMedium),
                    subtitle: Text(
                      '${_receiptDate.month}/${_receiptDate.day}/${_receiptDate.year}',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _receiptDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _receiptDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Tax Deductible Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tax Deductible', style: AppTheme.bodyMedium),
                    subtitle: Text(
                      _isTaxDeductible
                          ? 'Will be included in tax deductions'
                          : 'Personal expense',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    value: _isTaxDeductible,
                    onChanged: (v) => setState(() => _isTaxDeductible = v),
                    activeThumbColor: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'What was this for?',
                      prefixIcon: Icon(Icons.note, color: AppTheme.textMuted),
                    ),
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSave({
                          'vendor_name': _vendorNameController.text,
                          'total_amount':
                              double.tryParse(_amountController.text) ?? 0,
                          'tax_amount':
                              double.tryParse(_taxController.text) ?? 0,
                          'expense_category': _expenseCategory,
                          'payment_method': _paymentMethod,
                          'receipt_date': _receiptDate.toIso8601String(),
                          'is_tax_deductible': _isTaxDeductible,
                          'notes': _notesController.text,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Receipt',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
