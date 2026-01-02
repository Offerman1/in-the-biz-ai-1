import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_contact.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_contact_screen.dart';

/// Event Contacts Directory - Browse and manage all saved contacts
class EventContactsScreen extends StatefulWidget {
  /// Optional: if provided, shows contacts for this shift and allows adding to it
  final String? shiftId;
  final String? shiftEventName;

  const EventContactsScreen({
    super.key,
    this.shiftId,
    this.shiftEventName,
  });

  @override
  State<EventContactsScreen> createState() => _EventContactsScreenState();
}

class _EventContactsScreenState extends State<EventContactsScreen> {
  final _db = DatabaseService();
  final _searchController = TextEditingController();

  List<EventContact> _allContacts = [];
  List<EventContact> _filteredContacts = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  final List<String> _categories = [
    'All',
    'Entertainment',
    'Event Staff',
    'Vendors',
    'Officiants',
    'Venue',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      List<EventContact> contacts;
      if (widget.shiftId != null) {
        // Show contacts for specific shift
        contacts = await _db.getEventContactsForShift(widget.shiftId!);
      } else {
        // Show all contacts
        contacts = await _db.getEventContacts();
      }

      setState(() {
        _allContacts = contacts;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<EventContact> filtered = _allContacts;

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.company?.toLowerCase().contains(query) ?? false) ||
            c.displayRole.toLowerCase().contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((c) => c.role.category == _selectedCategory).toList();
    }

    // Favorites filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((c) => c.isFavorite).toList();
    }

    setState(() => _filteredContacts = filtered);
  }

  Future<void> _addContact() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(
          shiftId: widget.shiftId,
        ),
      ),
    );

    if (result == true) {
      _loadContacts();
    }
  }

  Future<void> _editContact(EventContact contact) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(
          contact: contact,
        ),
      ),
    );

    if (result == true) {
      _loadContacts();
    }
  }

  Future<void> _deleteContact(EventContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Contact',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to delete ${contact.name}?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && contact.id != null) {
      await _db.deleteEventContact(contact.id!);
      _loadContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${contact.name} deleted')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(EventContact contact) async {
    if (contact.id == null) return;
    await _db.toggleContactFavorite(contact.id!, !contact.isFavorite);
    _loadContacts();
  }

  Future<void> _callContact(EventContact contact) async {
    if (contact.phone == null || contact.phone!.isEmpty) return;
    final uri = Uri.parse('tel:${contact.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailContact(EventContact contact) async {
    if (contact.email == null || contact.email!.isEmpty) return;
    final uri = Uri.parse('mailto:${contact.email}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.shiftId != null
        ? 'Event Team${widget.shiftEventName != null ? ' - ${widget.shiftEventName}' : ''}'
        : 'Contacts Directory';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          title,
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly
                  ? AppTheme.accentYellow
                  : AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
                _applyFilters();
              });
            },
            tooltip: 'Show favorites only',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Category filter chips
            if (widget.shiftId == null)
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                            _applyFilters();
                          });
                        },
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.cardBackground,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : AppTheme.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        checkmarkColor: Colors.black,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // Contacts list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    )
                  : _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            return _buildContactCard(_filteredContacts[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty ||
        _selectedCategory != 'All' ||
        _showFavoritesOnly) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style:
                  AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            widget.shiftId != null ? 'No team members yet' : 'No contacts yet',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.shiftId != null
                ? 'Add vendors and staff who worked this event'
                : 'Start building your vendor directory',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.add),
            label: const Text('Add Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(EventContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editContact(contact),
          onLongPress: () => _showContactOptions(contact),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar / Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: contact.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            contact.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildContactIcon(contact),
                          ),
                        )
                      : _buildContactIcon(contact),
                ),
                const SizedBox(width: 12),

                // Contact info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (contact.isFavorite)
                            Icon(
                              Icons.star,
                              size: 18,
                              color: AppTheme.accentYellow,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildRoleBadge(contact),
                      if (contact.company != null &&
                          contact.company!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact.company!,
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Social media icons
                      if (contact.hasSocialMedia) ...[
                        const SizedBox(height: 6),
                        _buildSocialMediaIcons(contact),
                      ],
                    ],
                  ),
                ),

                // Quick actions
                if (contact.hasContactInfo)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (contact.phone != null && contact.phone!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.phone, color: AppTheme.primaryGreen),
                          onPressed: () => _callContact(contact),
                          tooltip: 'Call',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      if (contact.email != null && contact.email!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.email, color: AppTheme.accentBlue),
                          onPressed: () => _emailContact(contact),
                          tooltip: 'Email',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactIcon(EventContact contact) {
    IconData iconData;
    switch (contact.role.iconName) {
      case 'music_note':
        iconData = Icons.music_note;
        break;
      case 'camera_alt':
        iconData = Icons.camera_alt;
        break;
      case 'event':
        iconData = Icons.event;
        break;
      case 'person':
        iconData = Icons.person;
        break;
      case 'security':
        iconData = Icons.security;
        break;
      case 'directions_car':
        iconData = Icons.directions_car;
        break;
      case 'local_florist':
        iconData = Icons.local_florist;
        break;
      case 'inventory_2':
        iconData = Icons.inventory_2;
        break;
      case 'cake':
        iconData = Icons.cake;
        break;
      case 'restaurant':
        iconData = Icons.restaurant;
        break;
      case 'lightbulb':
        iconData = Icons.lightbulb;
        break;
      case 'church':
        iconData = Icons.church;
        break;
      case 'business':
        iconData = Icons.business;
        break;
      default:
        iconData = Icons.person_outline;
    }

    return Icon(iconData, color: AppTheme.primaryGreen, size: 24);
  }

  Widget _buildRoleBadge(EventContact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        contact.displayRole,
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.accentPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcons(EventContact contact) {
    final socialIcons = <Widget>[];

    if (contact.instagram != null && contact.instagram!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.camera_alt,
        const Color(0xFFE4405F),
        'Instagram',
        () => _openSocialMedia('instagram', contact.instagram!),
      ));
    }
    if (contact.tiktok != null && contact.tiktok!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.music_note,
        const Color(0xFF00F2EA),
        'TikTok',
        () => _openSocialMedia('tiktok', contact.tiktok!),
      ));
    }
    if (contact.facebook != null && contact.facebook!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.facebook,
        const Color(0xFF1877F2),
        'Facebook',
        () => _openSocialMedia('facebook', contact.facebook!),
      ));
    }
    if (contact.twitter != null && contact.twitter!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.alternate_email,
        AppTheme.textPrimary,
        'X',
        () => _openSocialMedia('twitter', contact.twitter!),
      ));
    }
    if (contact.linkedin != null && contact.linkedin!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.business_center,
        const Color(0xFF0A66C2),
        'LinkedIn',
        () => _openSocialMedia('linkedin', contact.linkedin!),
      ));
    }
    if (contact.youtube != null && contact.youtube!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.play_circle_filled,
        const Color(0xFFFF0000),
        'YouTube',
        () => _openSocialMedia('youtube', contact.youtube!),
      ));
    }
    if (contact.snapchat != null && contact.snapchat!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.chat_bubble,
        const Color(0xFFFFFC00),
        'Snapchat',
        () => _openSocialMedia('snapchat', contact.snapchat!),
      ));
    }
    if (contact.pinterest != null && contact.pinterest!.isNotEmpty) {
      socialIcons.add(_socialIcon(
        Icons.push_pin,
        const Color(0xFFE60023),
        'Pinterest',
        () => _openSocialMedia('pinterest', contact.pinterest!),
      ));
    }

    return Wrap(
      spacing: 4,
      children: socialIcons,
    );
  }

  Widget _socialIcon(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }

  Future<void> _openSocialMedia(String platform, String handle) async {
    String url;
    switch (platform) {
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$handle';
        break;
      case 'facebook':
        url =
            handle.startsWith('http') ? handle : 'https://facebook.com/$handle';
        break;
      case 'twitter':
        url = 'https://x.com/$handle';
        break;
      case 'linkedin':
        url = handle.startsWith('http')
            ? handle
            : 'https://linkedin.com/in/$handle';
        break;
      case 'youtube':
        url =
            handle.startsWith('http') ? handle : 'https://youtube.com/@$handle';
        break;
      case 'snapchat':
        url = 'https://snapchat.com/add/$handle';
        break;
      case 'pinterest':
        url = handle.startsWith('http')
            ? handle
            : 'https://pinterest.com/$handle';
        break;
      default:
        return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContactOptions(EventContact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.name,
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryGreen),
              title:
                  Text('Edit', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _editContact(contact);
              },
            ),
            ListTile(
              leading: Icon(
                contact.isFavorite ? Icons.star : Icons.star_border,
                color: AppTheme.accentYellow,
              ),
              title: Text(
                contact.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(contact);
              },
            ),
            if (contact.phone != null && contact.phone!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.phone, color: AppTheme.primaryGreen),
                title: Text('Call ${contact.phone}',
                    style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _callContact(contact);
                },
              ),
            if (contact.email != null && contact.email!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.email, color: AppTheme.accentBlue),
                title: Text('Email ${contact.email}',
                    style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _emailContact(contact);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.accentRed),
              title:
                  Text('Delete', style: TextStyle(color: AppTheme.accentRed)),
              onTap: () {
                Navigator.pop(context);
                _deleteContact(contact);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
