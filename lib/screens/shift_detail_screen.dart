import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import '../models/shift.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'add_shift_screen.dart';
import 'photo_viewer_screen.dart';

class ShiftDetailScreen extends StatefulWidget {
  final DateTime date;
  final List<Shift> shifts;

  const ShiftDetailScreen({
    super.key,
    required this.date,
    required this.shifts,
  });

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>> _photos = [];
  bool _isLoadingPhotos = true;
  bool _isUploadingPhoto = false;

  // Inline editing state
  late Shift _editableShift;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  String? _activeEditField;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Text controllers for inline editing
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();

    // Initialize editable shift copy
    _editableShift = widget.shifts.first;

    // Setup pulse animation for save button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Initialize text controllers
    _initializeControllers();
  }

  void _initializeControllers() {
    final shift = _editableShift;

    // Money fields
    _controllers['cashTips'] =
        TextEditingController(text: shift.cashTips.toStringAsFixed(2));
    _controllers['creditTips'] =
        TextEditingController(text: shift.creditTips.toStringAsFixed(2));
    _controllers['hourlyRate'] =
        TextEditingController(text: shift.hourlyRate.toStringAsFixed(2));
    _controllers['hoursWorked'] =
        TextEditingController(text: shift.hoursWorked.toStringAsFixed(1));

    // Event details
    _controllers['eventName'] =
        TextEditingController(text: shift.eventName ?? '');
    _controllers['hostess'] = TextEditingController(text: shift.hostess ?? '');
    _controllers['guestCount'] =
        TextEditingController(text: shift.guestCount?.toString() ?? '');

    // Work details
    _controllers['location'] =
        TextEditingController(text: shift.location ?? '');
    _controllers['clientName'] =
        TextEditingController(text: shift.clientName ?? '');
    _controllers['projectName'] =
        TextEditingController(text: shift.projectName ?? '');
    _controllers['mileage'] =
        TextEditingController(text: shift.mileage?.toStringAsFixed(1) ?? '');

    // Additional earnings
    _controllers['commission'] =
        TextEditingController(text: shift.commission?.toStringAsFixed(2) ?? '');
    _controllers['flatRate'] =
        TextEditingController(text: shift.flatRate?.toStringAsFixed(2) ?? '');
    _controllers['overtimeHours'] = TextEditingController(
        text: shift.overtimeHours?.toStringAsFixed(1) ?? '');

    // Notes
    _controllers['notes'] = TextEditingController(text: shift.notes ?? '');

    // Create focus nodes for each field
    for (final key in _controllers.keys) {
      _focusNodes[key] = FocusNode();
      _focusNodes[key]!.addListener(() {
        if (!_focusNodes[key]!.hasFocus && _activeEditField == key) {
          _onFieldEditComplete(key);
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onFieldEditComplete(String fieldKey) {
    setState(() {
      _activeEditField = null;
    });
    _updateShiftField(fieldKey);
  }

  void _updateShiftField(String fieldKey) {
    final controller = _controllers[fieldKey];
    if (controller == null) return;

    final value = controller.text.trim();
    bool changed = false;

    setState(() {
      switch (fieldKey) {
        case 'cashTips':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.cashTips != parsed) {
            _editableShift = _editableShift.copyWith(cashTips: parsed);
            changed = true;
          }
          break;
        case 'creditTips':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.creditTips != parsed) {
            _editableShift = _editableShift.copyWith(creditTips: parsed);
            changed = true;
          }
          break;
        case 'hourlyRate':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.hourlyRate != parsed) {
            _editableShift = _editableShift.copyWith(hourlyRate: parsed);
            changed = true;
          }
          break;
        case 'hoursWorked':
          final parsed = double.tryParse(value) ?? 0;
          if (_editableShift.hoursWorked != parsed) {
            _editableShift = _editableShift.copyWith(hoursWorked: parsed);
            changed = true;
          }
          break;
        case 'eventName':
          if (_editableShift.eventName != (value.isEmpty ? null : value)) {
            _editableShift = _editableShift.copyWith(
                eventName: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'hostess':
          if (_editableShift.hostess != (value.isEmpty ? null : value)) {
            _editableShift =
                _editableShift.copyWith(hostess: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'guestCount':
          final parsed = int.tryParse(value);
          if (_editableShift.guestCount != parsed) {
            _editableShift = _editableShift.copyWith(guestCount: parsed);
            changed = true;
          }
          break;
        case 'location':
          if (_editableShift.location != (value.isEmpty ? null : value)) {
            _editableShift =
                _editableShift.copyWith(location: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'clientName':
          if (_editableShift.clientName != (value.isEmpty ? null : value)) {
            _editableShift = _editableShift.copyWith(
                clientName: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'projectName':
          if (_editableShift.projectName != (value.isEmpty ? null : value)) {
            _editableShift = _editableShift.copyWith(
                projectName: value.isEmpty ? null : value);
            changed = true;
          }
          break;
        case 'mileage':
          final parsed = double.tryParse(value);
          if (_editableShift.mileage != parsed) {
            _editableShift = _editableShift.copyWith(mileage: parsed);
            changed = true;
          }
          break;
        case 'commission':
          final parsed = double.tryParse(value);
          if (_editableShift.commission != parsed) {
            _editableShift = _editableShift.copyWith(commission: parsed);
            changed = true;
          }
          break;
        case 'flatRate':
          final parsed = double.tryParse(value);
          if (_editableShift.flatRate != parsed) {
            _editableShift = _editableShift.copyWith(flatRate: parsed);
            changed = true;
          }
          break;
        case 'overtimeHours':
          final parsed = double.tryParse(value);
          if (_editableShift.overtimeHours != parsed) {
            _editableShift = _editableShift.copyWith(overtimeHours: parsed);
            changed = true;
          }
          break;
        case 'notes':
          if (_editableShift.notes != (value.isEmpty ? null : value)) {
            _editableShift =
                _editableShift.copyWith(notes: value.isEmpty ? null : value);
            changed = true;
          }
          break;
      }

      if (changed) {
        _hasUnsavedChanges = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _dbService.updateShift(_editableShift);

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text('Changes saved'),
              ],
            ),
            backgroundColor: AppTheme.cardBackground,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _loadPhotos() async {
    if (widget.shifts.isEmpty) return;

    setState(() => _isLoadingPhotos = true);

    try {
      final photos = await _dbService.getShiftPhotos(widget.shifts.first.id);

      // Get signed URLs for each photo
      final photosWithUrls = await Future.wait(photos.map((photo) async {
        final url = await _dbService.getPhotoUrl(photo['storage_path']);
        return {...photo, 'url': url};
      }));

      if (mounted) {
        setState(() {
          _photos = photosWithUrls;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load photos: $e')),
        );
      }
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await image.readAsBytes();

      // Save to phone gallery immediately if taken from camera
      if (source == ImageSource.camera) {
        await Gal.putImageBytes(bytes);
      }

      await _dbService.uploadPhoto(
        shiftId: widget.shifts.first.id,
        imageBytes: bytes,
        fileName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        photoType: source == ImageSource.camera ? 'camera' : 'gallery',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(source == ImageSource.camera
                  ? 'Photo captured and saved to gallery!'
                  : 'Photo added!')),
        );
        _loadPhotos(); // Reload photos
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency();

    // Calculate totals from the editable shift
    final shift = _editableShift;
    double totalCashTips = shift.cashTips;
    double totalCreditTips = shift.creditTips;
    double totalHours = shift.hoursWorked;
    double totalWages = shift.hourlyRate * shift.hoursWorked;
    double totalCommission = shift.commission ?? 0;
    double totalFlatRate = shift.flatRate ?? 0;
    double totalOvertimePay = 0;

    // Calculate overtime pay (extra 0.5x for overtime hours)
    if (shift.overtimeHours != null && shift.overtimeHours! > 0) {
      totalOvertimePay = shift.hourlyRate * shift.overtimeHours! * 0.5;
    }

    final totalTips = totalCashTips + totalCreditTips;
    final totalIncome = totalTips +
        totalWages +
        totalCommission +
        totalFlatRate +
        totalOvertimePay;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard and end editing when tapping outside
          FocusScope.of(context).unfocus();
          if (_activeEditField != null) {
            setState(() => _activeEditField = null);
          }
        },
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.darkBackground,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  if (_hasUnsavedChanges) {
                    _showUnsavedChangesDialog();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              actions: [
                // Pulsing save button (only visible when changes exist)
                if (_hasUnsavedChanges)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: IconButton(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.save,
                                  color: AppTheme.primaryGreen,
                                ),
                          onPressed: _isSaving ? null : _saveChanges,
                          tooltip: 'Save changes',
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddShiftScreen(
                          existingShift: _editableShift,
                        ),
                      ),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.greenGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          DateFormat('EEEE').format(widget.date),
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, y').format(widget.date),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currencyFormat.format(totalIncome),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -2,
                          ),
                        ),
                        Text(
                          'TOTAL EARNED',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breakdown Card
                    _buildSectionCard(
                      title: 'Breakdown',
                      child: Column(
                        children: [
                          _buildBreakdownRow(
                            'Cash Tips',
                            currencyFormat.format(totalCashTips),
                            Icons.payments_outlined,
                            fieldKey: 'cashTips',
                          ),
                          Divider(
                              color: AppTheme.cardBackgroundLight, height: 24),
                          _buildBreakdownRow(
                            'Credit Tips',
                            currencyFormat.format(totalCreditTips),
                            Icons.credit_card_outlined,
                            fieldKey: 'creditTips',
                          ),
                          Divider(
                              color: AppTheme.cardBackgroundLight, height: 24),
                          _buildBreakdownRow(
                            'Hourly Wages',
                            currencyFormat.format(totalWages),
                            Icons.access_time_outlined,
                            fieldKey: 'hourlyRate',
                          ),
                          Divider(
                              color: AppTheme.cardBackgroundLight, height: 24),
                          _buildBreakdownRow(
                            'Hours Worked',
                            '${totalHours.toStringAsFixed(1)} hrs',
                            Icons.schedule_outlined,
                            isGreen: false,
                            fieldKey: 'hoursWorked',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Hourly Avg',
                            currencyFormat.format(
                                totalHours > 0 ? totalIncome / totalHours : 0),
                            '/hr',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Tips Ratio',
                            '${totalIncome > 0 ? ((totalTips / totalIncome) * 100).toStringAsFixed(0) : 0}%',
                            'tips',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Event Details/BEO - Always show for editing
                    _buildSectionCard(
                      title: 'Event Details/BEO',
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Event Name',
                            _editableShift.eventName ?? 'Tap to add...',
                            Icons.celebration,
                            fieldKey: 'eventName',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Hostess',
                            _editableShift.hostess ?? 'Tap to add...',
                            Icons.person_outline,
                            fieldKey: 'hostess',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Guest Count',
                            _editableShift.guestCount?.toString() ??
                                'Tap to add...',
                            Icons.groups_outlined,
                            fieldKey: 'guestCount',
                            isNumeric: true,
                            suffix: _editableShift.guestCount != null
                                ? 'guests'
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Work Details - Always show for editing
                    _buildSectionCard(
                      title: 'Work Details',
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Location',
                            _editableShift.location ?? 'Tap to add...',
                            Icons.location_on_outlined,
                            fieldKey: 'location',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Client',
                            _editableShift.clientName ?? 'Tap to add...',
                            Icons.business_outlined,
                            fieldKey: 'clientName',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Project',
                            _editableShift.projectName ?? 'Tap to add...',
                            Icons.folder_outlined,
                            fieldKey: 'projectName',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Mileage',
                            _editableShift.mileage?.toStringAsFixed(1) ??
                                'Tap to add...',
                            Icons.directions_car_outlined,
                            fieldKey: 'mileage',
                            isNumeric: true,
                            suffix:
                                _editableShift.mileage != null ? 'miles' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Additional Earnings - Always show for editing
                    _buildSectionCard(
                      title: 'Additional Earnings',
                      child: Column(
                        children: [
                          _buildBreakdownRow(
                            'Commission',
                            currencyFormat
                                .format(_editableShift.commission ?? 0),
                            Icons.trending_up,
                            fieldKey: 'commission',
                          ),
                          Divider(
                              color: AppTheme.cardBackgroundLight, height: 24),
                          _buildBreakdownRow(
                            'Flat Rate',
                            currencyFormat.format(_editableShift.flatRate ?? 0),
                            Icons.payments,
                            fieldKey: 'flatRate',
                          ),
                          Divider(
                              color: AppTheme.cardBackgroundLight, height: 24),
                          _buildBreakdownRow(
                            'Overtime',
                            '${(_editableShift.overtimeHours ?? 0).toStringAsFixed(1)} hrs',
                            Icons.access_time_filled,
                            isGreen: false,
                            fieldKey: 'overtimeHours',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes Card - Always show for editing
                    _buildSectionCard(
                      title: 'Notes',
                      child: _buildEditableNotesSection(),
                    ),

                    const SizedBox(height: 16),

                    // Photos gallery
                    _buildSectionCard(
                      title: 'Photos',
                      child: _isLoadingPhotos
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _photos.isEmpty
                              ? SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 32,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No photos attached',
                                          style: AppTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: _isUploadingPhoto
                                              ? null
                                              : _showPhotoOptions,
                                          icon: _isUploadingPhoto
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                )
                                              : const Icon(Icons.add_a_photo,
                                                  size: 18),
                                          label: Text(_isUploadingPhoto
                                              ? 'Uploading...'
                                              : 'Add Photos'),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount: _photos.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == _photos.length) {
                                          // Add button
                                          return GestureDetector(
                                            onTap: _isUploadingPhoto
                                                ? null
                                                : _showPhotoOptions,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.darkBackground,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: AppTheme.primaryGreen
                                                      .withValues(alpha: 0.3),
                                                  width: 2,
                                                  style: BorderStyle.solid,
                                                ),
                                              ),
                                              child: _isUploadingPhoto
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    )
                                                  : Icon(
                                                      Icons.add_a_photo,
                                                      color:
                                                          AppTheme.primaryGreen,
                                                      size: 32,
                                                    ),
                                            ),
                                          );
                                        }

                                        final photo = _photos[index];
                                        return GestureDetector(
                                          onTap: () async {
                                            final deleted =
                                                await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PhotoViewerScreen(
                                                  photos: _photos,
                                                  initialIndex: index,
                                                  onDelete:
                                                      (photoId, storagePath) {
                                                    // Will be handled by photo viewer
                                                  },
                                                ),
                                              ),
                                            );
                                            if (deleted == true) _loadPhotos();
                                          },
                                          onLongPress: () async {
                                            final shouldDelete =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor:
                                                    AppTheme.cardBackground,
                                                title: Text('Delete Photo?',
                                                    style:
                                                        AppTheme.titleMedium),
                                                content: Text(
                                                  'This photo will be permanently deleted.',
                                                  style: AppTheme.bodyMedium,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppTheme.accentRed,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (shouldDelete == true &&
                                                mounted) {
                                              try {
                                                await _dbService.deletePhoto(
                                                  photo['id'],
                                                  photo['storage_path'],
                                                );
                                                _loadPhotos();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Photo deleted')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Failed to delete: $e')),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          child: Hero(
                                            tag: photo['id'],
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      photo['url']),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                    ),

                    const SizedBox(height: 24),

                    // Delete button (centered)
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showDeleteConfirmation(context);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete Shift'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentRed,
                            side: BorderSide(color: AppTheme.accentRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ), // Close GestureDetector
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Unsaved Changes'),
        content:
            const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back without saving
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveChanges();
              if (mounted) Navigator.pop(context); // Go back after saving
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(
              letterSpacing: 1,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, IconData icon,
      {bool isGreen = true, String? fieldKey}) {
    final isEditing = _activeEditField == fieldKey;
    final controller = fieldKey != null ? _controllers[fieldKey] : null;
    final focusNode = fieldKey != null ? _focusNodes[fieldKey] : null;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isGreen
                ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                : AppTheme.cardBackgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isGreen ? AppTheme.primaryGreen : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTheme.bodyLarge),
        ),
        // Editable value
        if (fieldKey != null && controller != null && focusNode != null)
          GestureDetector(
            onTap: () {
              setState(() => _activeEditField = fieldKey);
              focusNode.requestFocus();
            },
            child: isEditing
                ? SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textAlign: TextAlign.right,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style:
                          (isGreen ? AppTheme.moneySmall : AppTheme.titleMedium)
                              .copyWith(
                        color: Colors.white, // Brighter when editing
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                    ),
                    child: Text(
                      value,
                      style:
                          isGreen ? AppTheme.moneySmall : AppTheme.titleMedium,
                    ),
                  ),
          )
        else
          Text(
            value,
            style: isGreen ? AppTheme.moneySmall : AppTheme.titleMedium,
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String suffix) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTheme.moneyMedium),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(suffix, style: AppTheme.bodyMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {String? fieldKey, bool isNumeric = false, String? suffix}) {
    final isEditing = _activeEditField == fieldKey;
    final controller = fieldKey != null ? _controllers[fieldKey] : null;
    final focusNode = fieldKey != null ? _focusNodes[fieldKey] : null;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              // Editable value
              if (fieldKey != null && controller != null && focusNode != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _activeEditField = fieldKey);
                    focusNode.requestFocus();
                  },
                  child: isEditing
                      ? TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: isNumeric
                              ? const TextInputType.numberWithOptions(
                                  decimal: true)
                              : TextInputType.text,
                          inputFormatters: isNumeric
                              ? [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ]
                              : null,
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white, // Brighter when editing
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixText: suffix,
                            suffixStyle: AppTheme.bodyMedium,
                          ),
                          onSubmitted: (_) => _onFieldEditComplete(fieldKey),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  value,
                                  style: AppTheme.bodyLarge,
                                ),
                              ),
                              if (suffix != null)
                                Text(
                                  ' $suffix',
                                  style: AppTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                )
              else
                Text(value, style: AppTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableNotesSection() {
    final isEditing = _activeEditField == 'notes';
    final controller = _controllers['notes']!;
    final focusNode = _focusNodes['notes']!;

    return GestureDetector(
      onTap: () {
        setState(() => _activeEditField = 'notes');
        focusNode.requestFocus();
      },
      child: isEditing
          ? TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              minLines: 3,
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white, // Brighter when editing
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Add notes...',
              ),
              onTapOutside: (_) => _onFieldEditComplete('notes'),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _editableShift.notes?.isNotEmpty == true
                    ? _editableShift.notes!
                    : 'Tap to add notes...',
                style: AppTheme.bodyLarge.copyWith(
                  color: _editableShift.notes?.isNotEmpty == true
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                  fontStyle: _editableShift.notes?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Delete Shift?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dbService.deleteShift(_editableShift.id);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(
                      context, true); // Return to previous screen with result
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Shift deleted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting shift: $e'),
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
