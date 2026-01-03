import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

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

      var query =
          _db.supabase.from('beo_events').select().eq('user_id', userId);

      // Apply type filter if not "All"
      if (_selectedFilter != 'all') {
        query = query.eq('event_type', _selectedFilter);
      }

      query = query.order('event_date', ascending: false);

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
      onTap: () => _showEventDetails(event),
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

  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }
}

/// Bottom sheet showing full event details
class _EventDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final eventName = event['event_name'] as String? ?? 'Untitled Event';
    final eventType = event['event_type'] as String? ?? '';
    final eventDate = event['event_date'] as String?;
    final venue = event['venue_name'] as String?;
    final guestCount = event['guest_count_confirmed'] as int? ??
        event['guest_count_expected'] as int?;
    final totalSale = (event['total_sale_amount'] as num?)?.toDouble();
    final commission = (event['commission_amount'] as num?)?.toDouble();
    final contact = event['primary_contact_name'] as String?;
    final formattedNotes = event['formatted_notes'] as String?;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (eventType.isNotEmpty)
                        Text(
                          eventType,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (eventDate != null)
                  _buildDetailRow(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('MMMM d, yyyy')
                          .format(DateTime.parse(eventDate))),
                if (venue != null)
                  _buildDetailRow(Icons.location_on, 'Venue', venue),
                if (guestCount != null)
                  _buildDetailRow(Icons.people, 'Guests', '$guestCount'),
                if (contact != null)
                  _buildDetailRow(Icons.person, 'Contact', contact),
                if (totalSale != null)
                  _buildDetailRow(Icons.attach_money, 'Total Sale',
                      '\$${totalSale.toStringAsFixed(2)}'),
                if (commission != null)
                  _buildDetailRow(Icons.payments, 'Commission',
                      '\$${commission.toStringAsFixed(2)}',
                      color: AppTheme.primaryGreen),
                if (formattedNotes != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Event Details',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackgroundLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      formattedNotes,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  color: color ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
