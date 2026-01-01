/// Represents a contact/vendor associated with events
/// Can be linked to a specific shift or be a general directory contact

enum ContactRole {
  dj,
  bandMusician,
  photoBooth,
  photographer,
  videographer,
  weddingPlanner,
  eventCoordinator,
  hostess,
  supportStaff,
  security,
  valet,
  florist,
  linenRental,
  cakeBakery,
  catering,
  rentals,
  lightingAv,
  rabbi,
  priest,
  pastor,
  officiant,
  venueManager,
  venueCoordinator,
  custom,
}

extension ContactRoleExtension on ContactRole {
  /// Convert to database enum string
  String toDbString() {
    switch (this) {
      case ContactRole.dj:
        return 'dj';
      case ContactRole.bandMusician:
        return 'band_musician';
      case ContactRole.photoBooth:
        return 'photo_booth';
      case ContactRole.photographer:
        return 'photographer';
      case ContactRole.videographer:
        return 'videographer';
      case ContactRole.weddingPlanner:
        return 'wedding_planner';
      case ContactRole.eventCoordinator:
        return 'event_coordinator';
      case ContactRole.hostess:
        return 'hostess';
      case ContactRole.supportStaff:
        return 'support_staff';
      case ContactRole.security:
        return 'security';
      case ContactRole.valet:
        return 'valet';
      case ContactRole.florist:
        return 'florist';
      case ContactRole.linenRental:
        return 'linen_rental';
      case ContactRole.cakeBakery:
        return 'cake_bakery';
      case ContactRole.catering:
        return 'catering';
      case ContactRole.rentals:
        return 'rentals';
      case ContactRole.lightingAv:
        return 'lighting_av';
      case ContactRole.rabbi:
        return 'rabbi';
      case ContactRole.priest:
        return 'priest';
      case ContactRole.pastor:
        return 'pastor';
      case ContactRole.officiant:
        return 'officiant';
      case ContactRole.venueManager:
        return 'venue_manager';
      case ContactRole.venueCoordinator:
        return 'venue_coordinator';
      case ContactRole.custom:
        return 'custom';
    }
  }

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case ContactRole.dj:
        return 'DJ';
      case ContactRole.bandMusician:
        return 'Band/Musician';
      case ContactRole.photoBooth:
        return 'Photo Booth';
      case ContactRole.photographer:
        return 'Photographer';
      case ContactRole.videographer:
        return 'Videographer';
      case ContactRole.weddingPlanner:
        return 'Wedding Planner';
      case ContactRole.eventCoordinator:
        return 'Event Coordinator';
      case ContactRole.hostess:
        return 'Hostess';
      case ContactRole.supportStaff:
        return 'Support Staff';
      case ContactRole.security:
        return 'Security';
      case ContactRole.valet:
        return 'Valet';
      case ContactRole.florist:
        return 'Florist';
      case ContactRole.linenRental:
        return 'Linen Rental';
      case ContactRole.cakeBakery:
        return 'Cake/Bakery';
      case ContactRole.catering:
        return 'Catering';
      case ContactRole.rentals:
        return 'Rentals';
      case ContactRole.lightingAv:
        return 'Lighting/AV Tech';
      case ContactRole.rabbi:
        return 'Rabbi';
      case ContactRole.priest:
        return 'Priest';
      case ContactRole.pastor:
        return 'Pastor';
      case ContactRole.officiant:
        return 'Officiant';
      case ContactRole.venueManager:
        return 'Venue Manager';
      case ContactRole.venueCoordinator:
        return 'Venue Coordinator';
      case ContactRole.custom:
        return 'Custom';
    }
  }

  /// Get icon for the role
  String get iconName {
    switch (this) {
      case ContactRole.dj:
      case ContactRole.bandMusician:
        return 'music_note';
      case ContactRole.photoBooth:
      case ContactRole.photographer:
      case ContactRole.videographer:
        return 'camera_alt';
      case ContactRole.weddingPlanner:
      case ContactRole.eventCoordinator:
        return 'event';
      case ContactRole.hostess:
      case ContactRole.supportStaff:
        return 'person';
      case ContactRole.security:
        return 'security';
      case ContactRole.valet:
        return 'directions_car';
      case ContactRole.florist:
        return 'local_florist';
      case ContactRole.linenRental:
      case ContactRole.rentals:
        return 'inventory_2';
      case ContactRole.cakeBakery:
        return 'cake';
      case ContactRole.catering:
        return 'restaurant';
      case ContactRole.lightingAv:
        return 'lightbulb';
      case ContactRole.rabbi:
      case ContactRole.priest:
      case ContactRole.pastor:
      case ContactRole.officiant:
        return 'church';
      case ContactRole.venueManager:
      case ContactRole.venueCoordinator:
        return 'business';
      case ContactRole.custom:
        return 'person_outline';
    }
  }

  /// Get category for grouping
  String get category {
    switch (this) {
      case ContactRole.dj:
      case ContactRole.bandMusician:
      case ContactRole.photoBooth:
      case ContactRole.photographer:
      case ContactRole.videographer:
        return 'Entertainment';
      case ContactRole.weddingPlanner:
      case ContactRole.eventCoordinator:
      case ContactRole.hostess:
      case ContactRole.supportStaff:
      case ContactRole.security:
      case ContactRole.valet:
        return 'Event Staff';
      case ContactRole.florist:
      case ContactRole.linenRental:
      case ContactRole.cakeBakery:
      case ContactRole.catering:
      case ContactRole.rentals:
      case ContactRole.lightingAv:
        return 'Vendors';
      case ContactRole.rabbi:
      case ContactRole.priest:
      case ContactRole.pastor:
      case ContactRole.officiant:
        return 'Officiants';
      case ContactRole.venueManager:
      case ContactRole.venueCoordinator:
        return 'Venue';
      case ContactRole.custom:
        return 'Other';
    }
  }

  /// Parse from database string
  static ContactRole fromDbString(String? value) {
    switch (value) {
      case 'dj':
        return ContactRole.dj;
      case 'band_musician':
        return ContactRole.bandMusician;
      case 'photo_booth':
        return ContactRole.photoBooth;
      case 'photographer':
        return ContactRole.photographer;
      case 'videographer':
        return ContactRole.videographer;
      case 'wedding_planner':
        return ContactRole.weddingPlanner;
      case 'event_coordinator':
        return ContactRole.eventCoordinator;
      case 'hostess':
        return ContactRole.hostess;
      case 'support_staff':
        return ContactRole.supportStaff;
      case 'security':
        return ContactRole.security;
      case 'valet':
        return ContactRole.valet;
      case 'florist':
        return ContactRole.florist;
      case 'linen_rental':
        return ContactRole.linenRental;
      case 'cake_bakery':
        return ContactRole.cakeBakery;
      case 'catering':
        return ContactRole.catering;
      case 'rentals':
        return ContactRole.rentals;
      case 'lighting_av':
        return ContactRole.lightingAv;
      case 'rabbi':
        return ContactRole.rabbi;
      case 'priest':
        return ContactRole.priest;
      case 'pastor':
        return ContactRole.pastor;
      case 'officiant':
        return ContactRole.officiant;
      case 'venue_manager':
        return ContactRole.venueManager;
      case 'venue_coordinator':
        return ContactRole.venueCoordinator;
      default:
        return ContactRole.custom;
    }
  }
}

class EventContact {
  final String? id;
  final String? userId;
  final String? shiftId;
  final String name;
  final ContactRole role;
  final String? customRole;
  final String? company;
  final String? phone;
  final String? email;
  final String? website;
  final String? notes;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Social media fields
  final String? instagram;
  final String? tiktok;
  final String? facebook;
  final String? twitter; // X (formerly Twitter)
  final String? linkedin;
  final String? youtube;
  final String? snapchat;
  final String? pinterest;

  EventContact({
    this.id,
    this.userId,
    this.shiftId,
    required this.name,
    this.role = ContactRole.custom,
    this.customRole,
    this.company,
    this.phone,
    this.email,
    this.website,
    this.notes,
    this.imageUrl,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
    // Social media
    this.instagram,
    this.tiktok,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.youtube,
    this.snapchat,
    this.pinterest,
  });

  /// Get the display role (uses customRole if role is custom)
  String get displayRole {
    if (role == ContactRole.custom &&
        customRole != null &&
        customRole!.isNotEmpty) {
      return customRole!;
    }
    return role.displayName;
  }

  /// Create from Supabase response
  factory EventContact.fromSupabase(Map<String, dynamic> data) {
    return EventContact(
      id: data['id'] as String?,
      userId: data['user_id'] as String?,
      shiftId: data['shift_id'] as String?,
      name: data['name'] as String? ?? '',
      role: ContactRoleExtension.fromDbString(data['role'] as String?),
      customRole: data['custom_role'] as String?,
      company: data['company'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      notes: data['notes'] as String?,
      imageUrl: data['image_url'] as String?,
      isFavorite: data['is_favorite'] as bool? ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      // Social media
      instagram: data['instagram'] as String?,
      tiktok: data['tiktok'] as String?,
      facebook: data['facebook'] as String?,
      twitter: data['twitter'] as String?,
      linkedin: data['linkedin'] as String?,
      youtube: data['youtube'] as String?,
      snapchat: data['snapchat'] as String?,
      pinterest: data['pinterest'] as String?,
    );
  }

  /// Convert to Supabase insert/update map
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'shift_id': shiftId,
      'name': name,
      'role': role.toDbString(),
      'custom_role': customRole,
      'company': company,
      'phone': phone,
      'email': email,
      'website': website,
      'notes': notes,
      'image_url': imageUrl,
      'is_favorite': isFavorite,
      // Social media
      'instagram': instagram,
      'tiktok': tiktok,
      'facebook': facebook,
      'twitter': twitter,
      'linkedin': linkedin,
      'youtube': youtube,
      'snapchat': snapchat,
      'pinterest': pinterest,
    };
  }

  /// Create a copy with updated fields
  EventContact copyWith({
    String? id,
    String? userId,
    String? shiftId,
    String? name,
    ContactRole? role,
    String? customRole,
    String? company,
    String? phone,
    String? email,
    String? website,
    String? notes,
    String? imageUrl,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? instagram,
    String? tiktok,
    String? facebook,
    String? twitter,
    String? linkedin,
    String? youtube,
    String? snapchat,
    String? pinterest,
  }) {
    return EventContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shiftId: shiftId ?? this.shiftId,
      name: name ?? this.name,
      role: role ?? this.role,
      customRole: customRole ?? this.customRole,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      youtube: youtube ?? this.youtube,
      snapchat: snapchat ?? this.snapchat,
      pinterest: pinterest ?? this.pinterest,
    );
  }

  /// Check if contact has any contact info
  bool get hasContactInfo {
    return (phone != null && phone!.isNotEmpty) ||
        (email != null && email!.isNotEmpty) ||
        (website != null && website!.isNotEmpty);
  }

  /// Check if contact has any social media
  bool get hasSocialMedia {
    return (instagram != null && instagram!.isNotEmpty) ||
        (tiktok != null && tiktok!.isNotEmpty) ||
        (facebook != null && facebook!.isNotEmpty) ||
        (twitter != null && twitter!.isNotEmpty) ||
        (linkedin != null && linkedin!.isNotEmpty) ||
        (youtube != null && youtube!.isNotEmpty) ||
        (snapchat != null && snapchat!.isNotEmpty) ||
        (pinterest != null && pinterest!.isNotEmpty);
  }

  /// Get list of social media platforms this contact has
  List<String> get socialMediaPlatforms {
    final platforms = <String>[];
    if (instagram != null && instagram!.isNotEmpty) platforms.add('instagram');
    if (tiktok != null && tiktok!.isNotEmpty) platforms.add('tiktok');
    if (facebook != null && facebook!.isNotEmpty) platforms.add('facebook');
    if (twitter != null && twitter!.isNotEmpty) platforms.add('twitter');
    if (linkedin != null && linkedin!.isNotEmpty) platforms.add('linkedin');
    if (youtube != null && youtube!.isNotEmpty) platforms.add('youtube');
    if (snapchat != null && snapchat!.isNotEmpty) platforms.add('snapchat');
    if (pinterest != null && pinterest!.isNotEmpty) platforms.add('pinterest');
    return platforms;
  }

  @override
  String toString() {
    return 'EventContact(id: $id, name: $name, role: ${role.displayName}, company: $company)';
  }
}
