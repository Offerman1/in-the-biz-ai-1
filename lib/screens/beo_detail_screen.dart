import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/beo_event.dart';
import '../services/beo_event_service.dart';
import '../services/beo_pdf_service.dart';
import '../theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';

/// Screen for viewing/editing BEO (Banquet Event Order) details
/// Shows ALL 40+ fields from scanned BEOs
/// Modes: view, edit, create
class BeoDetailScreen extends StatefulWidget {
  final BeoEvent? beoEvent;
  final bool isEditing;
  final bool isCreating;

  const BeoDetailScreen({
    super.key,
    this.beoEvent,
    this.isEditing = false,
    this.isCreating = false,
  });

  @override
  State<BeoDetailScreen> createState() => _BeoDetailScreenState();
}

class _BeoDetailScreenState extends State<BeoDetailScreen> {
  late bool _isEditing;
  bool _isSaving = false;
  final BeoEventService _beoService = BeoEventService();
  final DatabaseService _db = DatabaseService();
  final _dateFormat = DateFormat('EEEE, MMMM d, yyyy');

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: EVENT IDENTITY & CONTACTS
  // ═══════════════════════════════════════════════════════════════════════════
  final _eventNameController = TextEditingController();
  DateTime _eventDate = DateTime.now();
  String? _eventType;
  final _postAsController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _functionSpaceController = TextEditingController();
  final _accountNameController = TextEditingController();

  // Client Contact
  final _primaryContactNameController = TextEditingController();
  final _primaryContactPhoneController = TextEditingController();
  final _primaryContactEmailController = TextEditingController();

  // Internal Contacts
  final _salesManagerNameController = TextEditingController();
  final _salesManagerPhoneController = TextEditingController();
  final _salesManagerEmailController = TextEditingController();
  final _cateringManagerNameController = TextEditingController();
  final _cateringManagerPhoneController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: TIMELINE & LOGISTICS
  // ═══════════════════════════════════════════════════════════════════════════
  DateTime? _setupDate;
  DateTime? _teardownDate;
  final _loadInTimeController = TextEditingController();
  final _setupTimeController = TextEditingController();
  final _guestArrivalTimeController = TextEditingController();
  final _eventStartTimeController = TextEditingController();
  final _eventEndTimeController = TextEditingController();
  final _breakdownTimeController = TextEditingController();
  final _loadOutTimeController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: GUEST COUNTS
  // ═══════════════════════════════════════════════════════════════════════════
  final _guestCountExpectedController = TextEditingController();
  final _guestCountConfirmedController = TextEditingController();
  final _adultCountController = TextEditingController();
  final _childCountController = TextEditingController();
  final _vendorMealCountController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4: FINANCIALS
  // ═══════════════════════════════════════════════════════════════════════════
  final _foodTotalController = TextEditingController();
  final _beverageTotalController = TextEditingController();
  final _laborTotalController = TextEditingController();
  final _roomRentalController = TextEditingController();
  final _equipmentRentalController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _serviceChargePercentController = TextEditingController();
  final _serviceChargeAmountController = TextEditingController();
  final _taxPercentController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _gratuityAmountController = TextEditingController();
  final _grandTotalController = TextEditingController();
  final _depositsPaidController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _balanceDueController = TextEditingController();
  final _totalSaleAmountController = TextEditingController();
  final _commissionPercentageController = TextEditingController();
  final _commissionAmountController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5: FOOD & BEVERAGE
  // ═══════════════════════════════════════════════════════════════════════════
  final _menuStyleController = TextEditingController();
  final _menuItemsController = TextEditingController();
  final _dietaryRestrictionsController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 6: SETUP & DECOR
  // ═══════════════════════════════════════════════════════════════════════════
  final _decorNotesController = TextEditingController();
  final _floorPlanNotesController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 7: STAFFING
  // ═══════════════════════════════════════════════════════════════════════════
  final _staffingRequirementsController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 9: BILLING & LEGAL
  // ═══════════════════════════════════════════════════════════════════════════
  final _paymentMethodController = TextEditingController();
  final _cancellationPolicyController = TextEditingController();
  DateTime? _clientSignatureDate;
  DateTime? _venueSignatureDate;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 10: NOTES
  // ═══════════════════════════════════════════════════════════════════════════
  final _specialRequestsController = TextEditingController();
  final _formattedNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing || widget.isCreating;
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.beoEvent != null) {
      final e = widget.beoEvent!;

      // Section 1: Event Identity
      _eventNameController.text = e.eventName;
      _eventDate = e.eventDate;
      _eventType = e.eventType;
      _postAsController.text = e.postAs ?? '';
      _venueNameController.text = e.venueName ?? '';
      _venueAddressController.text = e.venueAddress ?? '';
      _functionSpaceController.text = e.functionSpace ?? '';
      _accountNameController.text = e.accountName ?? '';

      // Client Contact
      _primaryContactNameController.text = e.primaryContactName ?? '';
      _primaryContactPhoneController.text = e.primaryContactPhone ?? '';
      _primaryContactEmailController.text = e.primaryContactEmail ?? '';

      // Internal Contacts
      _salesManagerNameController.text = e.salesManagerName ?? '';
      _salesManagerPhoneController.text = e.salesManagerPhone ?? '';
      _salesManagerEmailController.text = e.salesManagerEmail ?? '';
      _cateringManagerNameController.text = e.cateringManagerName ?? '';
      _cateringManagerPhoneController.text = e.cateringManagerPhone ?? '';

      // Section 2: Timeline
      _setupDate = e.setupDate;
      _teardownDate = e.teardownDate;
      _loadInTimeController.text = e.loadInTime ?? '';
      _setupTimeController.text = e.setupTime ?? '';
      _guestArrivalTimeController.text = e.guestArrivalTime ?? '';
      _eventStartTimeController.text = e.eventStartTime ?? '';
      _eventEndTimeController.text = e.eventEndTime ?? '';
      _breakdownTimeController.text = e.breakdownTime ?? '';
      _loadOutTimeController.text = e.loadOutTime ?? '';

      // Section 3: Guest Counts
      _guestCountExpectedController.text =
          e.guestCountExpected?.toString() ?? '';
      _guestCountConfirmedController.text =
          e.guestCountConfirmed?.toString() ?? '';
      _adultCountController.text = e.adultCount?.toString() ?? '';
      _childCountController.text = e.childCount?.toString() ?? '';
      _vendorMealCountController.text = e.vendorMealCount?.toString() ?? '';

      // Section 4: Financials
      _foodTotalController.text = e.foodTotal?.toStringAsFixed(2) ?? '';
      _beverageTotalController.text = e.beverageTotal?.toStringAsFixed(2) ?? '';
      _laborTotalController.text = e.laborTotal?.toStringAsFixed(2) ?? '';
      _roomRentalController.text = e.roomRental?.toStringAsFixed(2) ?? '';
      _equipmentRentalController.text =
          e.equipmentRental?.toStringAsFixed(2) ?? '';
      _subtotalController.text = e.subtotal?.toStringAsFixed(2) ?? '';
      _serviceChargePercentController.text =
          e.serviceChargePercent?.toStringAsFixed(1) ?? '';
      _serviceChargeAmountController.text =
          e.serviceChargeAmount?.toStringAsFixed(2) ?? '';
      _taxPercentController.text = e.taxPercent?.toStringAsFixed(2) ?? '';
      _taxAmountController.text = e.taxAmount?.toStringAsFixed(2) ?? '';
      _gratuityAmountController.text =
          e.gratuityAmount?.toStringAsFixed(2) ?? '';
      _grandTotalController.text = e.grandTotal?.toStringAsFixed(2) ?? '';
      _depositsPaidController.text = e.depositsPaid?.toStringAsFixed(2) ?? '';
      _depositAmountController.text = e.depositAmount?.toStringAsFixed(2) ?? '';
      _balanceDueController.text = e.balanceDue?.toStringAsFixed(2) ?? '';
      _totalSaleAmountController.text =
          e.totalSaleAmount?.toStringAsFixed(2) ?? '';
      _commissionPercentageController.text =
          e.commissionPercentage?.toStringAsFixed(1) ?? '';
      _commissionAmountController.text =
          e.commissionAmount?.toStringAsFixed(2) ?? '';

      // Section 5: Food & Beverage
      _menuStyleController.text = e.menuStyle ?? '';
      _menuItemsController.text = e.menuItems ?? '';
      _dietaryRestrictionsController.text = e.dietaryRestrictions ?? '';

      // Section 6: Setup & Decor
      _decorNotesController.text = e.decorNotes ?? '';
      _floorPlanNotesController.text = e.floorPlanNotes ?? '';

      // Section 7: Staffing
      _staffingRequirementsController.text = e.staffingRequirements ?? '';

      // Section 9: Billing & Legal
      _paymentMethodController.text = e.paymentMethod ?? '';
      _cancellationPolicyController.text = e.cancellationPolicy ?? '';
      _clientSignatureDate = e.clientSignatureDate;
      _venueSignatureDate = e.venueSignatureDate;

      // Section 10: Notes
      _specialRequestsController.text = e.specialRequests ?? '';
      _formattedNotesController.text = e.formattedNotes ?? '';
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _eventNameController.dispose();
    _postAsController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _functionSpaceController.dispose();
    _accountNameController.dispose();
    _primaryContactNameController.dispose();
    _primaryContactPhoneController.dispose();
    _primaryContactEmailController.dispose();
    _salesManagerNameController.dispose();
    _salesManagerPhoneController.dispose();
    _salesManagerEmailController.dispose();
    _cateringManagerNameController.dispose();
    _cateringManagerPhoneController.dispose();
    _loadInTimeController.dispose();
    _setupTimeController.dispose();
    _guestArrivalTimeController.dispose();
    _eventStartTimeController.dispose();
    _eventEndTimeController.dispose();
    _breakdownTimeController.dispose();
    _loadOutTimeController.dispose();
    _guestCountExpectedController.dispose();
    _guestCountConfirmedController.dispose();
    _adultCountController.dispose();
    _childCountController.dispose();
    _vendorMealCountController.dispose();
    _foodTotalController.dispose();
    _beverageTotalController.dispose();
    _laborTotalController.dispose();
    _roomRentalController.dispose();
    _equipmentRentalController.dispose();
    _subtotalController.dispose();
    _serviceChargePercentController.dispose();
    _serviceChargeAmountController.dispose();
    _taxPercentController.dispose();
    _taxAmountController.dispose();
    _gratuityAmountController.dispose();
    _grandTotalController.dispose();
    _depositsPaidController.dispose();
    _depositAmountController.dispose();
    _balanceDueController.dispose();
    _totalSaleAmountController.dispose();
    _commissionPercentageController.dispose();
    _commissionAmountController.dispose();
    _menuStyleController.dispose();
    _menuItemsController.dispose();
    _dietaryRestrictionsController.dispose();
    _decorNotesController.dispose();
    _floorPlanNotesController.dispose();
    _staffingRequirementsController.dispose();
    _paymentMethodController.dispose();
    _cancellationPolicyController.dispose();
    _specialRequestsController.dispose();
    _formattedNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(String field) async {
    DateTime initialDate;
    switch (field) {
      case 'event':
        initialDate = _eventDate;
        break;
      case 'setup':
        initialDate = _setupDate ?? _eventDate;
        break;
      case 'teardown':
        initialDate = _teardownDate ?? _eventDate;
        break;
      case 'clientSigned':
        initialDate = _clientSignatureDate ?? DateTime.now();
        break;
      case 'venueSigned':
        initialDate = _venueSignatureDate ?? DateTime.now();
        break;
      default:
        initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              surface: AppTheme.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (field) {
          case 'event':
            _eventDate = picked;
            break;
          case 'setup':
            _setupDate = picked;
            break;
          case 'teardown':
            _teardownDate = picked;
            break;
          case 'clientSigned':
            _clientSignatureDate = picked;
            break;
          case 'venueSigned':
            _venueSignatureDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_eventNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event name is required'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _db.supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Build the BEO data map
      final beoData = {
        'id': widget.beoEvent?.id ?? const Uuid().v4(),
        'user_id': userId,
        'event_name': _eventNameController.text.trim(),
        'event_date': _eventDate.toIso8601String().split('T')[0],
        'event_type': _eventType,
        'post_as':
            _postAsController.text.isNotEmpty ? _postAsController.text : null,
        'venue_name': _venueNameController.text.isNotEmpty
            ? _venueNameController.text
            : null,
        'venue_address': _venueAddressController.text.isNotEmpty
            ? _venueAddressController.text
            : null,
        'function_space': _functionSpaceController.text.isNotEmpty
            ? _functionSpaceController.text
            : null,
        'account_name': _accountNameController.text.isNotEmpty
            ? _accountNameController.text
            : null,
        'primary_contact_name': _primaryContactNameController.text.isNotEmpty
            ? _primaryContactNameController.text
            : null,
        'primary_contact_phone': _primaryContactPhoneController.text.isNotEmpty
            ? _primaryContactPhoneController.text
            : null,
        'primary_contact_email': _primaryContactEmailController.text.isNotEmpty
            ? _primaryContactEmailController.text
            : null,
        'sales_manager_name': _salesManagerNameController.text.isNotEmpty
            ? _salesManagerNameController.text
            : null,
        'sales_manager_phone': _salesManagerPhoneController.text.isNotEmpty
            ? _salesManagerPhoneController.text
            : null,
        'sales_manager_email': _salesManagerEmailController.text.isNotEmpty
            ? _salesManagerEmailController.text
            : null,
        'catering_manager_name': _cateringManagerNameController.text.isNotEmpty
            ? _cateringManagerNameController.text
            : null,
        'catering_manager_phone':
            _cateringManagerPhoneController.text.isNotEmpty
                ? _cateringManagerPhoneController.text
                : null,
        'setup_date': _setupDate?.toIso8601String().split('T')[0],
        'teardown_date': _teardownDate?.toIso8601String().split('T')[0],
        'load_in_time': _loadInTimeController.text.isNotEmpty
            ? _loadInTimeController.text
            : null,
        'setup_time': _setupTimeController.text.isNotEmpty
            ? _setupTimeController.text
            : null,
        'guest_arrival_time': _guestArrivalTimeController.text.isNotEmpty
            ? _guestArrivalTimeController.text
            : null,
        'event_start_time': _eventStartTimeController.text.isNotEmpty
            ? _eventStartTimeController.text
            : null,
        'event_end_time': _eventEndTimeController.text.isNotEmpty
            ? _eventEndTimeController.text
            : null,
        'breakdown_time': _breakdownTimeController.text.isNotEmpty
            ? _breakdownTimeController.text
            : null,
        'load_out_time': _loadOutTimeController.text.isNotEmpty
            ? _loadOutTimeController.text
            : null,
        'guest_count_expected':
            int.tryParse(_guestCountExpectedController.text),
        'guest_count_confirmed':
            int.tryParse(_guestCountConfirmedController.text),
        'adult_count': int.tryParse(_adultCountController.text),
        'child_count': int.tryParse(_childCountController.text),
        'vendor_meal_count': int.tryParse(_vendorMealCountController.text),
        'food_total': double.tryParse(_foodTotalController.text),
        'beverage_total': double.tryParse(_beverageTotalController.text),
        'labor_total': double.tryParse(_laborTotalController.text),
        'room_rental': double.tryParse(_roomRentalController.text),
        'equipment_rental': double.tryParse(_equipmentRentalController.text),
        'subtotal': double.tryParse(_subtotalController.text),
        'service_charge_percent':
            double.tryParse(_serviceChargePercentController.text),
        'service_charge_amount':
            double.tryParse(_serviceChargeAmountController.text),
        'tax_percent': double.tryParse(_taxPercentController.text),
        'tax_amount': double.tryParse(_taxAmountController.text),
        'gratuity_amount': double.tryParse(_gratuityAmountController.text),
        'grand_total': double.tryParse(_grandTotalController.text),
        'deposits_paid': double.tryParse(_depositsPaidController.text),
        'deposit_amount': double.tryParse(_depositAmountController.text),
        'balance_due': double.tryParse(_balanceDueController.text),
        'total_sale_amount': double.tryParse(_totalSaleAmountController.text),
        'commission_percentage':
            double.tryParse(_commissionPercentageController.text),
        'commission_amount': double.tryParse(_commissionAmountController.text),
        'menu_style': _menuStyleController.text.isNotEmpty
            ? _menuStyleController.text
            : null,
        'menu_items': _menuItemsController.text.isNotEmpty
            ? _menuItemsController.text
            : null,
        'dietary_restrictions': _dietaryRestrictionsController.text.isNotEmpty
            ? _dietaryRestrictionsController.text
            : null,
        'decor_notes': _decorNotesController.text.isNotEmpty
            ? _decorNotesController.text
            : null,
        'floor_plan_notes': _floorPlanNotesController.text.isNotEmpty
            ? _floorPlanNotesController.text
            : null,
        'staffing_requirements': _staffingRequirementsController.text.isNotEmpty
            ? _staffingRequirementsController.text
            : null,
        'payment_method': _paymentMethodController.text.isNotEmpty
            ? _paymentMethodController.text
            : null,
        'cancellation_policy': _cancellationPolicyController.text.isNotEmpty
            ? _cancellationPolicyController.text
            : null,
        'client_signature_date':
            _clientSignatureDate?.toIso8601String().split('T')[0],
        'venue_signature_date':
            _venueSignatureDate?.toIso8601String().split('T')[0],
        'special_requests': _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
        'formatted_notes': _formattedNotesController.text.isNotEmpty
            ? _formattedNotesController.text
            : null,
        'is_standalone': widget.beoEvent?.isStandalone ?? true,
        'created_manually': widget.isCreating,
        'created_at': widget.beoEvent?.createdAt.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final beoEvent = BeoEvent.fromJson(beoData);

      if (widget.isCreating) {
        await _beoService.createBeoEvent(beoEvent);
      } else {
        await _beoService.updateBeoEvent(beoEvent);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isCreating ? 'BEO created!' : 'BEO updated!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Export BEO as PDF
  Future<void> _exportPdf() async {
    if (widget.beoEvent == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Generating PDF...'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final pdfService = BeoPdfService();
      await pdfService.generateAndSharePdf(
        widget.beoEvent!,
        companyName: 'In The Biz',
        logoUrl: null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCreating
        ? 'Create BEO'
        : (_isEditing
            ? 'Edit BEO'
            : widget.beoEvent?.eventName ?? 'BEO Details');

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_isEditing && widget.beoEvent != null)
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: AppTheme.accentBlue),
              onPressed: _exportPdf,
              tooltip: 'Export PDF',
            ),
          if (!_isEditing && widget.beoEvent != null)
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.primaryGreen),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _save,
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
                      'Save',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // SECTION 1: EVENT IDENTITY
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Event Information', Icons.event, [
              _buildTextField('Event Name', _eventNameController,
                  isRequired: true),
              _buildDateField(
                  'Event Date', _eventDate, () => _selectDate('event')),
              _buildDropdown(
                  'Event Type',
                  _eventType,
                  [
                    'Wedding',
                    'Corporate',
                    'Birthday',
                    'Gala',
                    'Anniversary',
                    'Product Launch',
                    'Holiday Party',
                    'Fundraiser',
                    'Conference',
                    'Other'
                  ],
                  (val) => setState(() => _eventType = val)),
              _buildTextField('Post As', _postAsController),
              _buildTextField('Venue Name', _venueNameController),
              _buildTextField('Venue Address', _venueAddressController),
              _buildTextField('Function Space', _functionSpaceController),
              _buildTextField('Account Name', _accountNameController),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // CLIENT CONTACT
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Client Contact', Icons.person, [
              _buildTextField('Contact Name', _primaryContactNameController),
              _buildTextField('Phone', _primaryContactPhoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField('Email', _primaryContactEmailController,
                  keyboardType: TextInputType.emailAddress),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // INTERNAL CONTACTS
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Internal Contacts', Icons.people, [
              _buildTextField('Sales Manager', _salesManagerNameController),
              _buildTextField('Sales Phone', _salesManagerPhoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField('Sales Email', _salesManagerEmailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField(
                  'Catering Manager', _cateringManagerNameController),
              _buildTextField('Catering Phone', _cateringManagerPhoneController,
                  keyboardType: TextInputType.phone),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 2: TIMELINE
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Timeline & Logistics', Icons.schedule, [
              _buildDateField(
                  'Setup Date', _setupDate, () => _selectDate('setup'),
                  allowNull: true),
              _buildDateField(
                  'Teardown Date', _teardownDate, () => _selectDate('teardown'),
                  allowNull: true),
              _buildTimeRow('Load-In', _loadInTimeController, 'Setup',
                  _setupTimeController),
              _buildTimeRow('Guest Arrival', _guestArrivalTimeController,
                  'Event Start', _eventStartTimeController),
              _buildTimeRow('Event End', _eventEndTimeController, 'Breakdown',
                  _breakdownTimeController),
              _buildTextField('Load-Out Time', _loadOutTimeController),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 3: GUEST COUNTS
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Guest Counts', Icons.groups, [
              _buildNumberRow('Expected', _guestCountExpectedController,
                  'Confirmed', _guestCountConfirmedController),
              _buildNumberRow('Adults', _adultCountController, 'Children',
                  _childCountController),
              _buildTextField('Vendor Meals', _vendorMealCountController,
                  keyboardType: TextInputType.number),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 4: FINANCIALS
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Financials', Icons.attach_money, [
              _buildCurrencyRow('Food Total', _foodTotalController, 'Beverage',
                  _beverageTotalController),
              _buildCurrencyRow('Labor', _laborTotalController, 'Room Rental',
                  _roomRentalController),
              _buildCurrencyRow('Equipment', _equipmentRentalController,
                  'Subtotal', _subtotalController),
              _buildPercentAmountRow(
                  'Service Charge',
                  _serviceChargePercentController,
                  _serviceChargeAmountController),
              _buildPercentAmountRow(
                  'Tax', _taxPercentController, _taxAmountController),
              _buildTextField('Gratuity', _gratuityAmountController,
                  keyboardType: TextInputType.number, prefix: '\$'),
              _buildTextField('Grand Total', _grandTotalController,
                  keyboardType: TextInputType.number, prefix: '\$'),
              _buildCurrencyRow('Deposits Paid', _depositsPaidController,
                  'Balance Due', _balanceDueController),
              _buildPercentAmountRow('Commission',
                  _commissionPercentageController, _commissionAmountController),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 5: FOOD & BEVERAGE
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Food & Beverage', Icons.restaurant, [
              _buildTextField('Menu Style', _menuStyleController),
              _buildTextField('Menu Items', _menuItemsController,
                  multiline: true),
              _buildTextField(
                  'Dietary Restrictions', _dietaryRestrictionsController,
                  multiline: true),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 6: SETUP & DECOR
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Setup & Decor', Icons.design_services, [
              _buildTextField('Decor Notes', _decorNotesController,
                  multiline: true),
              _buildTextField('Floor Plan Notes', _floorPlanNotesController,
                  multiline: true),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 7: STAFFING
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Staffing', Icons.badge, [
              _buildTextField(
                  'Staffing Requirements', _staffingRequirementsController,
                  multiline: true),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 9: BILLING & LEGAL
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Billing & Legal', Icons.gavel, [
              _buildTextField('Payment Method', _paymentMethodController),
              _buildTextField(
                  'Cancellation Policy', _cancellationPolicyController,
                  multiline: true),
              _buildDateField('Client Signed', _clientSignatureDate,
                  () => _selectDate('clientSigned'),
                  allowNull: true),
              _buildDateField('Venue Signed', _venueSignatureDate,
                  () => _selectDate('venueSigned'),
                  allowNull: true),
            ]),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // SECTION 10: NOTES
            // ═══════════════════════════════════════════════════════════════
            _buildSection('Notes', Icons.notes, [
              _buildTextField('Special Requests', _specialRequestsController,
                  multiline: true),
              _buildTextField('Additional Notes', _formattedNotesController,
                  multiline: true),
            ]),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILDER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType? keyboardType,
    bool multiline = false,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: AppTheme.labelMedium
                      .copyWith(color: AppTheme.textSecondary)),
              if (isRequired)
                Text(' *', style: TextStyle(color: AppTheme.dangerColor)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            maxLines: multiline ? 4 : 1,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              prefixText: prefix,
              prefixStyle: TextStyle(color: AppTheme.textPrimary),
              filled: true,
              fillColor: _isEditing
                  ? AppTheme.cardBackgroundLight
                  : AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap,
      {bool allowNull = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _isEditing ? onTap : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: _isEditing
                    ? AppTheme.cardBackgroundLight
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date != null
                        ? _dateFormat.format(date)
                        : (allowNull ? 'Not set' : '--'),
                    style: AppTheme.bodyMedium.copyWith(
                      color: date != null
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
                    ),
                  ),
                  if (_isEditing)
                    Icon(Icons.calendar_today,
                        size: 18, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label1, TextEditingController ctrl1,
      String label2, TextEditingController ctrl2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _buildSmallTextField(label1, ctrl1)),
          const SizedBox(width: 12),
          Expanded(child: _buildSmallTextField(label2, ctrl2)),
        ],
      ),
    );
  }

  Widget _buildNumberRow(String label1, TextEditingController ctrl1,
      String label2, TextEditingController ctrl2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              child: _buildSmallTextField(label1, ctrl1,
                  keyboardType: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(
              child: _buildSmallTextField(label2, ctrl2,
                  keyboardType: TextInputType.number)),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(String label1, TextEditingController ctrl1,
      String label2, TextEditingController ctrl2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              child: _buildSmallTextField(label1, ctrl1,
                  keyboardType: TextInputType.number, prefix: '\$')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildSmallTextField(label2, ctrl2,
                  keyboardType: TextInputType.number, prefix: '\$')),
        ],
      ),
    );
  }

  Widget _buildPercentAmountRow(String label, TextEditingController percentCtrl,
      TextEditingController amountCtrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              child: _buildSmallTextField('$label %', percentCtrl,
                  keyboardType: TextInputType.number, suffix: '%')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildSmallTextField('$label \$', amountCtrl,
                  keyboardType: TextInputType.number, prefix: '\$')),
        ],
      ),
    );
  }

  Widget _buildSmallTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? prefix,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.labelSmall
                .copyWith(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: keyboardType,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixText: prefix,
            suffixText: suffix,
            prefixStyle: TextStyle(color: AppTheme.textPrimary),
            suffixStyle: TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: _isEditing
                ? AppTheme.cardBackgroundLight
                : AppTheme.cardBackground,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isEditing
                  ? AppTheme.cardBackgroundLight
                  : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.cardBackground,
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                hint: Text('Select $label',
                    style: TextStyle(color: AppTheme.textMuted)),
                items: options
                    .map(
                        (opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                    .toList(),
                onChanged: _isEditing ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
