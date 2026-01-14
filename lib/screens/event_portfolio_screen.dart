import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/vision_scanner_service.dart';
import '../services/beo_event_service.dart';
import '../models/vision_scan.dart';
import '../models/shift.dart';
import '../constants/event_types.dart';
import 'beo_detail_screen.dart';
import 'document_scanner_screen.dart';
import 'scan_verification_screen.dart';
import 'single_shift_detail_screen.dart';
import '../models/beo_event.dart';

/// Event Portfolio Gallery for Event Planners
/// Shows past BEO events with photos and details
class EventPortfolioScreen extends StatefulWidget {
  const EventPortfolioScreen({super.key});

  @override
  State<EventPortfolioScreen> createState() => _EventPortfolioScreenState();
}

class _EventPortfolioScreenState extends State<EventPortfolioScreen> {
  final DatabaseService _db = DatabaseService();
  final VisionScannerService _visionScanner = VisionScannerService();
  final BeoEventService _beoService = BeoEventService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  Map<String, String> _linkedShifts = {}; // beoId -> shiftId
  Map<String, double> _shiftTips = {}; // beoId -> total tips (cash + credit)
  String _selectedFilter = 'All';
  List<String> _recentEventTypes = []; // User's most frequently used types

  @override
  void initState() {
    super.initState();
    _loadRecentEventTypes();
    _loadEvents();
  }

  /// Load user's most frequently used event types
  Future<void> _loadRecentEventTypes() async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Get all event types used by this user, grouped and counted
      final response = await _db.supabase
          .from('beo_events')
          .select('event_type')
          .eq('user_id', userId)
          .not('event_type', 'is', null);

      // Count occurrences of each type
      final typeCounts = <String, int>{};
      for (final event in response) {
        final type = event['event_type'] as String?;
        if (type != null && type.isNotEmpty) {
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
      }

      // Sort by count and take top 5
      final sortedTypes = typeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _recentEventTypes = sortedTypes.take(5).map((e) => e.key).toList();
        });
      }
    } catch (e) {
      print('Error loading recent event types: $e');
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser!.id;
      print('🎯 Event Portfolio: Loading events for user: $userId');
      print('🎯 Event Portfolio: Selected filter: $_selectedFilter');

      // Build query with conditional filter
      // Note: 'All' is capitalized to match the filter chip values
      final query = _selectedFilter == 'All'
          ? _db.supabase
              .from('beo_events')
              .select()
              .eq('user_id', userId)
              .order('event_date', ascending: false)
          : _db.supabase
              .from('beo_events')
              .select()
              .eq('user_id', userId)
              .eq('event_type', _selectedFilter)
              .order('event_date', ascending: false);

      final response = await query;

      print('🎯 Event Portfolio: Found ${response.length} events');

      // Load linked shifts for all BEOs
      final linkedShifts = <String, String>{};
      final shiftTips = <String, double>{};
      for (final event in response) {
        final beoId = event['id'] as String?;
        if (beoId != null) {
          final shiftResult = await _db.supabase
              .from('shifts')
              .select('id, cash_tips, credit_tips')
              .eq('beo_event_id', beoId)
              .maybeSingle();
          if (shiftResult != null) {
            linkedShifts[beoId] = shiftResult['id'] as String;
            final cashTips =
                (shiftResult['cash_tips'] as num?)?.toDouble() ?? 0.0;
            final creditTips =
                (shiftResult['credit_tips'] as num?)?.toDouble() ?? 0.0;
            shiftTips[beoId] = cashTips + creditTips;
          }
        }
      }

      setState(() {
        _events = List<Map<String, dynamic>>.from(response);
        _linkedShifts = linkedShifts;
        _shiftTips = shiftTips;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Delete a BEO event with confirmation
  Future<void> _deleteBeo(Map<String, dynamic> event) async {
    final beoId = event['id'] as String;
    final beoName = event['event_name'] as String? ?? 'Untitled Event';
    final linkedShiftId = _linkedShifts[beoId];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Delete BEO?',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$beoName"?',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            if (linkedShiftId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This BEO is linked to a shift. The shift will remain but the BEO reference will be removed.',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.warningColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
      // If linked to a shift, unlink first
      if (linkedShiftId != null) {
        await _beoService.unlinkBeoFromShift(linkedShiftId);
      }

      // Delete the BEO
      await _beoService.deleteBeoEvent(beoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('BEO deleted successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete BEO: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  /// Navigate to create new BEO
  void _createNewBeo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BeoDetailScreen(isCreating: true),
      ),
    ).then((result) {
      if (result == true) {
        _loadEvents(); // Refresh list after creating
      }
    });
  }

  /// Navigate to view/edit existing BEO
  void _openBeoDetails(Map<String, dynamic> eventData) {
    final beo = BeoEvent.fromJson(eventData);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeoDetailScreen(beoEvent: beo),
      ),
    ).then((_) => _loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Event Portfolio',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Events grid or empty state
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _events.isEmpty
                    ? _buildEmptyState()
                    : _buildEventsGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBeoOptions,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add BEO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Show options to add BEO (Scan or Create manually)
  void _showAddBeoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Add BEO',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Scan BEO option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: AppTheme.accentPurple),
                ),
                title: Text('Scan BEO',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Use AI to extract data from photos',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  _scanBeo();
                },
              ),

              const SizedBox(height: 8),

              // Create manually option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.edit_document, color: AppTheme.primaryGreen),
                ),
                title: Text('Create Manually',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Enter BEO details by hand',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  _createNewBeo();
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Scan BEO using AI Vision
  Future<void> _scanBeo() async {
    // Open document scanner
    final session = await Navigator.push<DocumentScanSession>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          scanType: ScanType.beo,
          onScanComplete: (session) {
            Navigator.pop(context, session);
          },
        ),
      ),
    );

    if (session == null || !mounted) return;

    // Show processing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Analyzing BEO with AI...'),
          ],
        ),
        duration: const Duration(seconds: 30),
        backgroundColor: AppTheme.cardBackground,
      ),
    );

    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Analyze with AI
      Map<String, dynamic> result;
      if (session.hasBytes && session.imageBytes != null) {
        // Web: use bytes directly
        result = await _visionScanner.analyzeBEOFromBytes(
          session.imageBytes!,
          userId,
          mimeTypes: session.mimeTypes,
        );
      } else {
        // Mobile: use file paths
        result = await _visionScanner.analyzeBEO(
          session.imagePaths,
          userId,
        );
      }

      if (!mounted) return;
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
            onConfirm: (data) {
              // Data is already saved by verification screen
              Navigator.pop(context, true);
            },
          ),
        ),
      );

      if (confirmed == true) {
        _loadEvents(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze BEO: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showFilterDropdown,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFilter != 'All'
                        ? AppTheme.primaryGreen
                        : AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedFilter == 'All'
                          ? '${EventTypes.getCategoryEmoji('Recent')} All Events'
                          : '${EventTypes.getTypeEmoji(_selectedFilter)} $_selectedFilter',
                      style: AppTheme.bodyMedium.copyWith(
                        color: _selectedFilter != 'All'
                            ? AppTheme.primaryGreen
                            : AppTheme.textPrimary,
                        fontWeight: _selectedFilter != 'All'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedFilter != 'All') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = 'All');
                _loadEvents();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: AppTheme.dangerColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Filter by Event Type',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedFilter != 'All')
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedFilter = 'All');
                        _loadEvents();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: AppTheme.dangerColor),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Filter options
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // All option
                  _buildFilterOption('All', 'All Events', '📋', null),
                  const SizedBox(height: 8),

                  // Recent/Frequent section (if user has history)
                  if (_recentEventTypes.isNotEmpty) ...[
                    _buildCategoryHeader('Recent', '⭐'),
                    ..._recentEventTypes.map((type) => _buildFilterOption(
                          type,
                          type,
                          EventTypes.getTypeEmoji(type),
                          'Recent',
                        )),
                    const SizedBox(height: 8),
                  ],

                  // All categories
                  ...EventTypes.categories.expand((category) => [
                        _buildCategoryHeader(category.name,
                            EventTypes.getCategoryEmoji(category.name)),
                        ...category.types.map((type) => _buildFilterOption(
                              type,
                              type,
                              EventTypes.getTypeEmoji(type),
                              category.name,
                            )),
                        const SizedBox(height: 8),
                      ]),

                  // Other option
                  _buildCategoryHeader('Other', '📋'),
                  _buildFilterOption('Other', 'Other', '📋', 'Other'),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String name, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '$emoji $name',
        style: AppTheme.labelMedium.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterOption(
      String value, String label, String emoji, String? category) {
    final isSelected = _selectedFilter == value;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(
        left: category != null ? 32 : 16,
        right: 16,
      ),
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20)
          : null,
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadEvents();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No events yet',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first BEO using the ✨ Scan button',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72, // Balanced ratio for new card design
      ),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final beoId = event['id'] as String?;
    final eventName = event['event_name'] as String? ?? 'Untitled Event';
    final eventType = event['event_type'] as String? ?? '';
    final eventDate = event['event_date'] as String?;
    final guestCount = event['guest_count_confirmed'] as int? ??
        event['guest_count_expected'] as int?;
    final venue = event['venue_name'] as String?;
    final functionSpace = event['function_space'] as String?;
    final eventStartTime = event['event_start_time'] as String?;
    final eventEndTime = event['event_end_time'] as String?;
    final imageUrls = event['image_urls'] as List?;
    final coverImageUrl = event['cover_image_url'] as String?;

    // DEBUG: Log what we're getting
    print('🖼️ Event "$eventName" - cover_image_url from DB: $coverImageUrl');

    // Check if this BEO is linked to a shift using our tracked map
    final linkedShiftId = beoId != null ? _linkedShifts[beoId] : null;
    final isLinkedToShift = linkedShiftId != null;

    // Get cover image or first scanned image from Supabase storage
    String? displayImageUrl;
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      // Check if it's already a full URL or just a path
      if (coverImageUrl.startsWith('http')) {
        displayImageUrl = coverImageUrl;
      } else {
        // It's a storage path - use as image key for FutureBuilder
        displayImageUrl =
            coverImageUrl; // Will be converted to signed URL in Image.network
      }
      print('🖼️ Using cover image path: $coverImageUrl');
    } else if (imageUrls != null && imageUrls.isNotEmpty) {
      final imagePath = imageUrls.first.toString();
      // Check if it's already a full URL or just a path
      if (imagePath.startsWith('http')) {
        // Already a full URL, use as-is
        displayImageUrl = imagePath;
      } else {
        // It's a storage path
        displayImageUrl = imagePath;
      }
      print('🖼️ Using first scan image path: $imagePath');
    } else {
      print('🖼️ No image available for this event');
    }

    // Format time range (convert from 24h to 12h AM/PM format)
    String? timeRange;
    if (eventStartTime != null || eventEndTime != null) {
      String formatTime(String? time) {
        if (time == null || time.isEmpty) return '';
        try {
          // Parse HH:mm:ss or HH:mm format
          final parts = time.split(':');
          if (parts.isEmpty) return time;
          int hour = int.parse(parts[0]);
          final minute = parts.length > 1 ? parts[1] : '00';
          final period = hour >= 12 ? 'PM' : 'AM';
          if (hour == 0) {
            hour = 12;
          } else if (hour > 12) hour -= 12;
          return '$hour:$minute $period';
        } catch (e) {
          return time; // Return original if parsing fails
        }
      }

      final start = formatTime(eventStartTime);
      final end = formatTime(eventEndTime);
      if (start.isNotEmpty && end.isNotEmpty) {
        timeRange = '$start - $end';
      } else if (start.isNotEmpty) {
        timeRange = 'Starts $start';
      } else if (end.isNotEmpty) {
        timeRange = 'Ends $end';
      }
    }

    return GestureDetector(
      onTap: () => _openBeoDetails(event),
      onLongPress: () => _showBeoOptions(event),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border:
              Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Image + Title/Type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small image thumbnail
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: displayImageUrl != null
                              ? _BeoImage(
                                  imagePath: displayImageUrl,
                                  width: 56,
                                  height: 56,
                                  eventName: eventName,
                                  eventType: eventType,
                                )
                              : Center(
                                  child: Text(
                                    _getEventEmoji(eventType),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                        ),
                      ),
                      // Linked badge on thumbnail
                      if (isLinkedToShift)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.cardBackground, width: 2),
                            ),
                            child: const Icon(Icons.link,
                                size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Title and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (eventType.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              eventType,
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Details section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    if (eventDate != null)
                      _buildDetailRow(
                        Icons.calendar_today,
                        DateFormat('EEE, MMM d, yyyy')
                            .format(DateTime.parse(eventDate)),
                      ),

                    // Time
                    if (timeRange != null)
                      _buildDetailRow(Icons.access_time, timeRange),

                    // Venue
                    if (venue != null && venue.isNotEmpty)
                      _buildDetailRow(Icons.location_on, venue),

                    // Function Space
                    if (functionSpace != null && functionSpace.isNotEmpty)
                      _buildDetailRow(Icons.meeting_room, functionSpace),

                    // Guest count
                    if (guestCount != null)
                      _buildDetailRow(Icons.people, '$guestCount guests'),

                    const Spacer(),

                    // View Shift button for linked BEOs with tips display
                    if (isLinkedToShift)
                      GestureDetector(
                        onTap: () => _openLinkedShift(linkedShiftId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show tips if available
                              if (beoId != null &&
                                  _shiftTips.containsKey(beoId) &&
                                  _shiftTips[beoId]! > 0) ...[
                                Text(
                                  '\$${_shiftTips[beoId]!.toStringAsFixed(2)}',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: 1,
                                  height: 12,
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                              Icon(Icons.work_outline,
                                  size: 12, color: AppTheme.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                'View Shift',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
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
        ),
      ),
    );
  }

  /// Helper to build a detail row with icon
  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style:
                  AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Show options for a BEO (long press menu)
  void _showBeoOptions(Map<String, dynamic> event) {
    final beoId = event['id'] as String?;
    final eventName = event['event_name'] as String? ?? 'Untitled Event';
    final linkedShiftId = beoId != null ? _linkedShifts[beoId] : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                eventName,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // View Details option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.visibility, color: AppTheme.primaryGreen),
                ),
                title: Text('View Details',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  _openBeoDetails(event);
                },
              ),

              // View Linked Shift option (if linked)
              if (linkedShiftId != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.work_outline, color: AppTheme.accentBlue),
                  ),
                  title: Text('View Linked Shift',
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  trailing:
                      Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(context);
                    _openLinkedShift(linkedShiftId);
                  },
                ),

              const Divider(height: 24),

              // Delete option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                ),
                title: Text('Delete BEO',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dangerColor,
                    )),
                subtitle: linkedShiftId != null
                    ? Text(
                        'Will unlink from shift',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textMuted),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _deleteBeo(event);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Open the linked shift for a BEO
  Future<void> _openLinkedShift(String shiftId) async {
    try {
      final response = await _db.supabase
          .from('shifts')
          .select()
          .eq('id', shiftId)
          .maybeSingle();

      if (response != null && mounted) {
        final shift = Shift.fromSupabase(response);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleShiftDetailScreen(shift: shift),
          ),
        );
      }
    } catch (e) {
      print('Error loading linked shift: $e');
    }
  }

  String _getEventEmoji(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return '💒';
      case 'corporate':
        return '🏢';
      case 'birthday':
        return '🎂';
      default:
        return '🎉';
    }
  }
}

/// Custom BEO image widget that handles signed URL generation
/// Works like gallery photos - no async in main widget
class _BeoImage extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final String eventName;
  final String eventType;

  const _BeoImage({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.eventName,
    required this.eventType,
  });

  @override
  State<_BeoImage> createState() => _BeoImageState();
}

class _BeoImageState extends State<_BeoImage> {
  final DatabaseService _db = DatabaseService();
  String? _signedUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    try {
      if (widget.imagePath.startsWith('http')) {
        // Already a URL
        _signedUrl = widget.imagePath;
      } else {
        // Storage path - generate signed URL
        _signedUrl = await _db.getPhotoUrlForBucket(
            'shift-attachments', widget.imagePath);
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading BEO image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _signedUrl == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: AppTheme.cardBackgroundLight,
        child: Center(
          child: Text(
            _getEventEmoji(widget.eventType),
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    return Image.network(
      _signedUrl!,
      key: ValueKey(_signedUrl),
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image load error for ${widget.eventName}: $error');
        return Center(
          child: Text(
            _getEventEmoji(widget.eventType),
            style: const TextStyle(fontSize: 24),
          ),
        );
      },
    );
  }

  String _getEventEmoji(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return '💒';
      case 'corporate':
        return '🏢';
      case 'birthday':
        return '🎂';
      default:
        return '🎉';
    }
  }
}
