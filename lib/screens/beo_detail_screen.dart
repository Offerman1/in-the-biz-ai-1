import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/beo_event.dart';
import '../services/beo_pdf_service.dart';
import '../theme/app_theme.dart';

/// Screen for viewing/editing BEO (Banquet Event Order) details
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

  // Form controllers
  final _eventNameController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _functionSpaceController = TextEditingController();
  final _primaryContactNameController = TextEditingController();
  final _primaryContactPhoneController = TextEditingController();
  final _primaryContactEmailController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _grandTotalController = TextEditingController();
  final _commissionController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _eventDate = DateTime.now();
  String? _eventType;
  String? _eventStartTime;
  String? _eventEndTime;

  final _dateFormat = DateFormat('EEEE, MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing || widget.isCreating;
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.beoEvent != null) {
      final event = widget.beoEvent!;
      _eventNameController.text = event.eventName;
      _venueNameController.text = event.venueName ?? '';
      _venueAddressController.text = event.venueAddress ?? '';
      _functionSpaceController.text = event.functionSpace ?? '';
      _primaryContactNameController.text = event.primaryContactName ?? '';
      _primaryContactPhoneController.text = event.primaryContactPhone ?? '';
      _primaryContactEmailController.text = event.primaryContactEmail ?? '';
      _guestCountController.text = event.displayGuestCount?.toString() ?? '';
      _grandTotalController.text = event.displayTotal?.toString() ?? '';
      _commissionController.text = event.commissionAmount?.toString() ?? '';
      _notesController.text =
          event.formattedNotes ?? event.specialRequests ?? '';
      _eventDate = event.eventDate;
      _eventType = event.eventType;
      _eventStartTime = event.eventStartTime;
      _eventEndTime = event.eventEndTime;
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _functionSpaceController.dispose();
    _primaryContactNameController.dispose();
    _primaryContactPhoneController.dispose();
    _primaryContactEmailController.dispose();
    _guestCountController.dispose();
    _grandTotalController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
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
      setState(() => _eventDate = picked);
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

    // TODO: Implement save functionality with BeoEventProvider
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
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
      // TODO: Get company name and logo URL from user profile
      await pdfService.generateAndSharePdf(
        widget.beoEvent!,
        companyName: 'In The Biz', // Could be loaded from profile
        logoUrl: null, // Could be loaded from profile.company_logo_url
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
        ),
        actions: [
          // PDF Export button (only in view mode with existing BEO)
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
            _buildSection('Event Information', Icons.event, [
              _buildTextField('Event Name', _eventNameController,
                  isRequired: true),
              _buildDateField(),
              _buildDropdown(
                  'Event Type',
                  _eventType,
                  [
                    'Wedding',
                    'Corporate',
                    'Birthday',
                    'Gala',
                    'Product Launch',
                    'Other'
                  ],
                  (val) => setState(() => _eventType = val)),
              _buildTextField('Venue', _venueNameController),
              _buildTextField('Venue Address', _venueAddressController),
              _buildTextField('Function Space', _functionSpaceController),
            ]),
            const SizedBox(height: 24),
            _buildSection('Contact Information', Icons.people, [
              _buildTextField(
                  'Client/Host Name', _primaryContactNameController),
              _buildTextField('Phone', _primaryContactPhoneController),
              _buildTextField('Email', _primaryContactEmailController),
            ]),
            const SizedBox(height: 24),
            _buildSection('Event Details', Icons.info_outline, [
              _buildTextField('Guest Count', _guestCountController,
                  keyboardType: TextInputType.number),
              _buildTimeFields(),
            ]),
            const SizedBox(height: 24),
            _buildSection('Financials', Icons.attach_money, [
              _buildTextField('Grand Total', _grandTotalController,
                  keyboardType: TextInputType.number, prefix: '\$'),
              _buildTextField('Commission', _commissionController,
                  keyboardType: TextInputType.number, prefix: '\$'),
            ]),
            const SizedBox(height: 24),
            _buildSection('Notes', Icons.notes, [
              _buildTextField('Notes', _notesController, multiline: true),
            ]),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

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
          child: Column(
            children: children,
          ),
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
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              if (isRequired)
                Text(' *', style: TextStyle(color: AppTheme.dangerColor)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            maxLines: multiline ? 5 : 1,
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

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Date',
            style: AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _isEditing ? _selectDate : null,
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
                    _dateFormat.format(_eventDate),
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
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

  Widget _buildTimeFields() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Time',
                  style: AppTheme.labelMedium
                      .copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _eventStartTime ?? '--:--',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End Time',
                  style: AppTheme.labelMedium
                      .copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _eventEndTime ?? '--:--',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary),
          ),
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
                    .map((opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(opt),
                        ))
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
