/// Shared industry and job role data used across onboarding and job creation screens
/// This ensures consistency between guided flow (onboarding) and manual flow (add job)
library;

class IndustryData {
  static const List<String> industries = [
    'Restaurant/Bar/Nightclub',
    'Construction/Trades',
    'Freelancer/Consultant',
    'Healthcare',
    'Rideshare & Delivery',
    'Music & Entertainment',
    'Artist & Crafts',
    'Retail/Sales',
    'Salon/Spa',
    'Hospitality',
    'Fitness',
  ];

  static const Map<String, List<String>> jobTitlesByIndustry = {
    'Restaurant/Bar/Nightclub': [
      'Server/Waiter',
      'Bartender',
      'Food Runner',
      'Busser',
      'Manager',
      'Hostess',
      'Chef/Sushi Chef',
      'Bar Back',
      'Sommelier',
      'Line Cook',
      'Prep Cook',
      'Expeditor',
      'Banquet Server',
      'Cocktail Waitress',
      'Barista',
    ],
    'Construction/Trades': [
      'Carpenter',
      'Electrician',
      'Plumber',
      'HVAC Technician',
      'General Contractor',
      'Painter',
      'Roofer',
      'Mason',
      'Welder',
      'Landscaper',
      'Drywall Installer',
      'Tile Setter',
      'Flooring Installer',
      'Cabinet Maker',
    ],
    'Freelancer/Consultant': [
      'Graphic Designer',
      'Web Developer',
      'Photographer',
      'Writer/Copywriter',
      'Marketing Consultant',
      'Business Consultant',
      'Video Editor',
      'Social Media Manager',
      'Virtual Assistant',
      'Translator',
      'UX Designer',
      'Software Developer',
    ],
    'Healthcare': [
      'Nurse (RN/LPN)',
      'CNA (Certified Nursing Assistant)',
      'Medical Assistant',
      'Phlebotomist',
      'Home Health Aide',
      'Physical Therapist',
      'Dental Hygienist',
      'Paramedic/EMT',
      'Pharmacy Technician',
      'Caregiver',
      'Dental Assistant',
    ],
    'Rideshare & Delivery': [
      'Uber Driver',
      'Lyft Driver',
      'DoorDash Driver',
      'Uber Eats Driver',
      'Grubhub Driver',
      'Instacart Shopper',
      'Amazon Flex Driver',
      'Postmates Driver',
      'Shipt Shopper',
      'Local Delivery Driver',
      'Spark Driver',
      'GoPuff Driver',
    ],
    'Music & Entertainment': [
      'Musician',
      'Band Member',
      'DJ',
      'Photographer',
      'Photo Booth Operator',
      'Event Performer',
      'Sound Engineer',
      'Live Streamer',
      'Videographer',
      'MC/Host',
      'Lighting Technician',
      'Stage Hand',
    ],
    'Artist & Crafts': [
      'Painter/Artist',
      'Sculptor',
      'Jewelry Maker',
      'Ceramicist',
      'Street Performer',
      'Craftsperson',
      'Illustrator',
      'Printmaker',
      'Woodworker',
      'Leatherworker',
      'Glass Artist',
      'Textile Artist',
    ],
    'Retail/Sales': [
      'Sales Associate',
      'Cashier',
      'Store Manager',
      'Visual Merchandiser',
      'Stock Associate',
      'Department Manager',
      'Loss Prevention',
      'Sales Representative',
      'Customer Service Rep',
      'Buyer',
      'Inventory Specialist',
    ],
    'Salon/Spa': [
      'Hair Stylist',
      'Nail Technician',
      'Massage Therapist',
      'Esthetician',
      'Barber',
      'Makeup Artist',
      'Spa Manager',
      'Waxing Specialist',
      'Lash Technician',
      'Brow Specialist',
      'Colorist',
      'Salon Assistant',
    ],
    'Hospitality': [
      'Hotel Front Desk',
      'Concierge',
      'Housekeeper',
      'Bellhop',
      'Valet',
      'Room Service',
      'Night Auditor',
      'Guest Services',
      'Banquet Captain',
      'Event Coordinator',
      'Spa Attendant',
      'Pool Attendant',
    ],
    'Fitness': [
      'Personal Trainer',
      'Group Fitness Instructor',
      'Yoga Instructor',
      'Pilates Instructor',
      'Spin Instructor',
      'CrossFit Coach',
      'Gym Manager',
      'Front Desk',
      'Swimming Instructor',
      'Dance Instructor',
      'Martial Arts Instructor',
      'Nutrition Coach',
    ],
  };

  /// Get job titles for an industry, returns empty list if not found
  static List<String> getJobTitles(String? industry) {
    if (industry == null) return [];
    return jobTitlesByIndustry[industry] ?? [];
  }

  /// Get the template type string for an industry
  static String getTemplateType(String? industry) {
    switch (industry) {
      case 'Restaurant/Bar/Nightclub':
        return 'restaurant';
      case 'Construction/Trades':
        return 'construction';
      case 'Freelancer/Consultant':
        return 'freelancer';
      case 'Healthcare':
        return 'healthcare';
      case 'Rideshare & Delivery':
        return 'rideshare';
      case 'Music & Entertainment':
        return 'music';
      case 'Artist & Crafts':
        return 'artist';
      case 'Retail/Sales':
        return 'retail';
      case 'Salon/Spa':
        return 'salon';
      case 'Hospitality':
        return 'hospitality';
      case 'Fitness':
        return 'fitness';
      default:
        return 'custom';
    }
  }
}
