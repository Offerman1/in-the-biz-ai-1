import 'job_template.dart';

class Job {
  final String id;
  final String userId;
  final String name;
  final String? employer;
  final String? industry;
  final double hourlyRate;
  final String color;
  final bool isActive;
  final bool isDefault;
  final JobTemplate template;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? defaultTipoutPercent; // NEW: Default tip out %
  final String? tipoutDescription; // NEW: Who gets tipped out

  Job({
    required this.id,
    required this.userId,
    required this.name,
    this.employer,
    this.industry,
    this.hourlyRate = 0.0,
    this.color = '#00D632',
    this.isActive = true,
    this.isDefault = false,
    JobTemplate? template,
    this.createdAt,
    this.updatedAt,
    this.defaultTipoutPercent,
    this.tipoutDescription,
  }) : template = template ?? JobTemplate();

  factory Job.fromSupabase(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      employer: map['employer'] as String?,
      industry: map['industry'] as String?,
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] as String? ?? '#00D632',
      isActive: map['is_active'] as bool? ?? true,
      isDefault: map['is_default'] as bool? ?? false,
      template: map['job_template'] != null
          ? JobTemplate.fromJson(map['job_template'] as Map<String, dynamic>)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      defaultTipoutPercent: (map['default_tipout_percent'] as num?)?.toDouble(),
      tipoutDescription: map['tipout_description'] as String?,
    );
  }

  Map<String, dynamic> toSupabase({bool isUpdate = false}) {
    final data = {
      'user_id': userId,
      'name': name,
      'employer': employer,
      'industry': industry,
      'hourly_rate': hourlyRate,
      'color': color,
      'is_active': isActive,
      'is_default': isDefault,
      'job_template': template.toJson(),
      'default_tipout_percent': defaultTipoutPercent,
      'tipout_description': tipoutDescription,
    };

    // Only include id for updates, let database generate it for inserts
    if (isUpdate) {
      data['id'] = id;
    }

    return data;
  }

  Job copyWith({
    String? id,
    String? userId,
    String? name,
    String? employer,
    String? industry,
    double? hourlyRate,
    String? color,
    bool? isActive,
    bool? isDefault,
    JobTemplate? template,
    double? defaultTipoutPercent,
    String? tipoutDescription,
  }) {
    return Job(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      employer: employer ?? this.employer,
      industry: industry ?? this.industry,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      template: template ?? this.template,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      defaultTipoutPercent: defaultTipoutPercent ?? this.defaultTipoutPercent,
      tipoutDescription: tipoutDescription ?? this.tipoutDescription,
    );
  }
}
