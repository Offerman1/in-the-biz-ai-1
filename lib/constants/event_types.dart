// Event type categories and their children for BEO events
// Used across Event Portfolio filtering and BEO creation/editing

class EventTypeCategory {
  final String name;
  final List<String> types;
  final bool isDynamic; // For "Recent/Frequent" which is computed

  const EventTypeCategory({
    required this.name,
    required this.types,
    this.isDynamic = false,
  });
}

class EventTypes {
  /// All event type categories with their children
  static const List<EventTypeCategory> categories = [
    // Life Celebrations
    EventTypeCategory(
      name: 'Life Celebrations',
      types: [
        'Wedding',
        'Rehearsal Dinner',
        'Engagement Party',
        'Bridal Shower',
        'Bachelor/Bachelorette Party',
        'Anniversary',
        'Birthday',
        'Sweet 16',
        'Quinceañera',
        'Bar Mitzvah',
        'Bat Mitzvah',
        'Baby Shower',
        'Gender Reveal',
        'Baptism/Christening',
        'First Communion',
        'Confirmation',
        'Graduation',
        'Retirement',
        'Celebration of Life',
      ],
    ),

    // Holidays
    EventTypeCategory(
      name: 'Holidays',
      types: [
        'Christmas Party',
        'New Year\'s Eve',
        'Thanksgiving',
        'Passover',
        '4th of July',
        'Halloween Party',
      ],
    ),

    // Corporate
    EventTypeCategory(
      name: 'Corporate',
      types: [
        'Corporate Event',
        'Conference',
        'Gala/Fundraiser',
        'Award Ceremony',
        'Team Building',
        'Networking',
        'Luncheon',
        'Seminar/Workshop',
      ],
    ),

    // Social
    EventTypeCategory(
      name: 'Social',
      types: [
        'Cocktail Party',
        'Wine Tasting',
        'Game Day',
        'Brunch',
        'Family Reunion',
        'Class Reunion',
        'Homecoming',
        'Prom',
      ],
    ),
  ];

  /// Standalone "Other" option
  static const String otherType = 'Other';

  /// Get all event types as a flat list (for AI scanning)
  static List<String> get allTypes {
    final types = <String>[];
    for (final category in categories) {
      types.addAll(category.types);
    }
    types.add(otherType);
    return types;
  }

  /// Get the category name for a given event type
  static String? getCategoryForType(String type) {
    if (type == otherType) return null;
    for (final category in categories) {
      if (category.types.contains(type)) {
        return category.name;
      }
    }
    return null;
  }

  /// Check if a type exists in any category
  static bool isValidType(String type) {
    if (type == otherType) return true;
    return allTypes.contains(type);
  }

  /// Get category icon
  static String getCategoryEmoji(String categoryName) {
    switch (categoryName) {
      case 'Recent':
        return '⭐';
      case 'Life Celebrations':
        return '🎉';
      case 'Holidays':
        return '🎄';
      case 'Corporate':
        return '💼';
      case 'Social':
        return '🥂';
      default:
        return '📋';
    }
  }

  /// Get event type emoji
  static String getTypeEmoji(String type) {
    switch (type) {
      // Life Celebrations
      case 'Wedding':
        return '💒';
      case 'Rehearsal Dinner':
        return '🍽️';
      case 'Engagement Party':
        return '💍';
      case 'Bridal Shower':
        return '👰';
      case 'Bachelor/Bachelorette Party':
        return '🎊';
      case 'Anniversary':
        return '💕';
      case 'Birthday':
        return '🎂';
      case 'Sweet 16':
        return '🎀';
      case 'Quinceañera':
        return '👗';
      case 'Bar Mitzvah':
      case 'Bat Mitzvah':
        return '✡️';
      case 'Baby Shower':
        return '👶';
      case 'Gender Reveal':
        return '🎈';
      case 'Baptism/Christening':
        return '⛪';
      case 'First Communion':
      case 'Confirmation':
        return '✝️';
      case 'Graduation':
        return '🎓';
      case 'Retirement':
        return '🏖️';
      case 'Celebration of Life':
        return '🕊️';
      // Holidays
      case 'Christmas Party':
        return '🎄';
      case 'New Year\'s Eve':
        return '🎆';
      case 'Thanksgiving':
        return '🦃';
      case 'Passover':
        return '🍷';
      case '4th of July':
        return '🇺🇸';
      case 'Halloween Party':
        return '🎃';
      // Corporate
      case 'Corporate Event':
        return '💼';
      case 'Conference':
        return '🎤';
      case 'Gala/Fundraiser':
        return '🏆';
      case 'Award Ceremony':
        return '🏅';
      case 'Team Building':
        return '🤝';
      case 'Networking':
        return '🔗';
      case 'Luncheon':
        return '🥗';
      case 'Seminar/Workshop':
        return '📚';
      // Social
      case 'Cocktail Party':
        return '🍸';
      case 'Wine Tasting':
        return '🍷';
      case 'Game Day':
        return '🏈';
      case 'Brunch':
        return '🥂';
      case 'Family Reunion':
        return '👨‍👩‍👧‍👦';
      case 'Class Reunion':
        return '🎒';
      case 'Homecoming':
        return '🏠';
      case 'Prom':
        return '👑';
      // Other
      case 'Other':
        return '📋';
      default:
        return '📅';
    }
  }
}
