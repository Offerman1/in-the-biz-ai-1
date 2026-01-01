class IndustryTemplate {
  final String id;
  final String industry;
  final String displayName;
  final String? icon;
  final List<JobTypeTemplate> defaultJobTypes;
  final String tipStructure; // 'pooled', 'individual', 'no_tips'
  final double? minHourly;
  final double? maxHourly;

  IndustryTemplate({
    required this.id,
    required this.industry,
    required this.displayName,
    this.icon,
    required this.defaultJobTypes,
    required this.tipStructure,
    this.minHourly,
    this.maxHourly,
  });

  factory IndustryTemplate.fromSupabase(Map<String, dynamic> map) {
    final jobTypesJson = map['default_job_types'] as List<dynamic>? ?? [];
    final hourlyRange = map['typical_hourly_range'] as Map<String, dynamic>?;

    return IndustryTemplate(
      id: map['id'] as String,
      industry: map['industry'] as String,
      displayName: map['display_name'] as String,
      icon: map['icon'] as String?,
      defaultJobTypes: jobTypesJson
          .map((j) => JobTypeTemplate.fromJson(j as Map<String, dynamic>))
          .toList(),
      tipStructure: map['tip_structure'] as String? ?? 'individual',
      minHourly: (hourlyRange?['min'] as num?)?.toDouble(),
      maxHourly: (hourlyRange?['max'] as num?)?.toDouble(),
    );
  }
}

class JobTypeTemplate {
  final String name;
  final double rate;

  JobTypeTemplate({
    required this.name,
    required this.rate,
  });

  factory JobTypeTemplate.fromJson(Map<String, dynamic> json) {
    return JobTypeTemplate(
      name: json['name'] as String,
      rate: (json['rate'] as num).toDouble(),
    );
  }
}
