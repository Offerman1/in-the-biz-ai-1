import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'beo_detail_screen.dart';
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
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  String _selectedFilter = 'All'; // All, Wedding, Corporate, Birthday, Other

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Build query with conditional filter
      final query = _selectedFilter == 'all'
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

      setState(() {
        _events = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
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
        onPressed: _createNewBeo,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create BEO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Wedding', 'Corporate', 'Birthday', 'Other']
              .map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                  _loadEvents();
                },
                backgroundColor: AppTheme.cardBackground,
                selectedColor: AppTheme.primaryGreen,
                labelStyle: AppTheme.bodySmall.copyWith(
                  color: isSelected ? Colors.black : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textMuted.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ),
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
        childAspectRatio: 0.75,
      ),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventName = event['event_name'] as String? ?? 'Untitled Event';
    final eventType = event['event_type'] as String? ?? '';
    final eventDate = event['event_date'] as String?;
    final guestCount = event['guest_count_confirmed'] as int? ??
        event['guest_count_expected'] as int?;
    final totalSale = (event['total_sale_amount'] as num?)?.toDouble();
    final commission = (event['commission_amount'] as num?)?.toDouble();
    final venue = event['venue_name'] as String?;
    final imageUrls = event['image_urls'] as List?;

    // Get first image URL from Supabase storage
    String? firstImageUrl;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      final imagePath = imageUrls.first.toString();
      // Get public URL from Supabase storage
      firstImageUrl =
          _db.supabase.storage.from('beo-scans').getPublicUrl(imagePath);
    }

    return GestureDetector(
      onTap: () => _openBeoDetails(event),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image or placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: firstImageUrl != null
                    ? Image.network(
                        firstImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          // Show emoji if image fails to load
                          return Center(
                            child: Text(
                              _getEventEmoji(eventType),
                              style: const TextStyle(fontSize: 48),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryGreen,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          _getEventEmoji(eventType),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
              ),
            ),

            // Event details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name
                    Text(
                      eventName,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Event type
                    if (eventType.isNotEmpty)
                      Text(
                        eventType,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),

                    const Spacer(),

                    // Date
                    if (eventDate != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy')
                                .format(DateTime.parse(eventDate)),
                            style: AppTheme.labelSmall
                                .copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),

                    // Venue
                    if (venue != null && venue.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue,
                              style: AppTheme.labelSmall
                                  .copyWith(color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Guest count
                    if (guestCount != null)
                      Row(
                        children: [
                          Icon(Icons.people,
                              size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$guestCount guests',
                            style: AppTheme.labelSmall
                                .copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),

                    // Total Sale
                    if (totalSale != null && totalSale > 0)
                      Row(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 12, color: AppTheme.accentBlue),
                          const SizedBox(width: 4),
                          Text(
                            '\$${totalSale.toStringAsFixed(2)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        ],
                      ),

                    // Commission
                    if (commission != null)
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              size: 12, color: AppTheme.primaryGreen),
                          Text(
                            '\$${commission.toStringAsFixed(2)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
