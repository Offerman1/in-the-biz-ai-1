import 'package:flutter/material.dart';

/// Defines a section that can be shown/hidden on shift forms
class SectionDefinition {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final bool
      isRemovable; // If false, section cannot be hidden (e.g., job selector)

  const SectionDefinition({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    this.isRemovable = true,
  });
}

/// Registry of all available sections
class SectionRegistry {
  /// All removable sections (green outline)
  static const List<SectionDefinition> allSections = [
    SectionDefinition(
      key: 'time_hours',
      label: 'Time & Hours',
      description: 'Start time, end time, hours worked, hourly rate',
      icon: Icons.access_time,
    ),
    SectionDefinition(
      key: 'event_contract',
      label: 'Event Details/BEO',
      description: 'BEO details: event name, guest count, hostess, venue, etc.',
      icon: Icons.assignment,
    ),
    SectionDefinition(
      key: 'work_details',
      label: 'Work Details',
      description: 'Location, client name, project name',
      icon: Icons.work_outline,
    ),
    SectionDefinition(
      key: 'income_breakdown',
      label: 'Income Breakdown',
      description: 'Work time, hourly rate, cash tips, credit tips',
      icon: Icons.attach_money,
    ),
    SectionDefinition(
      key: 'additional_earnings',
      label: 'Additional Earnings',
      description: 'Commission, flat rate, overtime hours',
      icon: Icons.trending_up,
    ),
    SectionDefinition(
      key: 'notes',
      label: 'Notes',
      description: 'Shift notes and comments',
      icon: Icons.notes,
    ),
    SectionDefinition(
      key: 'attachments',
      label: 'Attachments',
      description: 'Photos, receipts, documents',
      icon: Icons.attach_file,
    ),
    SectionDefinition(
      key: 'custom_fields',
      label: 'Custom Fields',
      description: 'User-added custom fields',
      icon: Icons.tune,
    ),
  ];

  /// Get section by key
  static SectionDefinition? getSection(String key) {
    try {
      return allSections.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Get all section keys
  static List<String> get allSectionKeys =>
      allSections.map((s) => s.key).toList();

  /// Check if a section is visible
  static bool isSectionVisible({
    required String sectionKey,
    required List<String> templateHiddenSections,
    required List<String> shiftHiddenSections,
  }) {
    // Section is visible if NOT in either hidden list
    return !templateHiddenSections.contains(sectionKey) &&
        !shiftHiddenSections.contains(sectionKey);
  }

  /// Get list of hidden sections for display
  static List<SectionDefinition> getHiddenSections({
    required List<String> templateHiddenSections,
    required List<String> shiftHiddenSections,
  }) {
    final allHidden = {...templateHiddenSections, ...shiftHiddenSections};
    return allSections.where((s) => allHidden.contains(s.key)).toList();
  }

  /// Get list of visible sections
  static List<SectionDefinition> getVisibleSections({
    required List<String> templateHiddenSections,
    required List<String> shiftHiddenSections,
  }) {
    final allHidden = {...templateHiddenSections, ...shiftHiddenSections};
    return allSections.where((s) => !allHidden.contains(s.key)).toList();
  }
}

/// Options for removing a section
enum RemoveSectionOption {
  thisShiftOnly,
  allFutureShifts,
  allShiftsIncludingPast,
  cancel,
}

extension RemoveSectionOptionExtension on RemoveSectionOption {
  String get label {
    switch (this) {
      case RemoveSectionOption.thisShiftOnly:
        return 'Remove from this shift only';
      case RemoveSectionOption.allFutureShifts:
        return 'Remove from all future shifts';
      case RemoveSectionOption.allShiftsIncludingPast:
        return 'Remove from all shifts (including past)';
      case RemoveSectionOption.cancel:
        return 'Cancel';
    }
  }

  String get description {
    switch (this) {
      case RemoveSectionOption.thisShiftOnly:
        return 'Only this shift will be affected';
      case RemoveSectionOption.allFutureShifts:
        return 'Updates job template for new shifts';
      case RemoveSectionOption.allShiftsIncludingPast:
        return 'Updates all existing shifts for this job';
      case RemoveSectionOption.cancel:
        return '';
    }
  }

  IconData get icon {
    switch (this) {
      case RemoveSectionOption.thisShiftOnly:
        return Icons.event;
      case RemoveSectionOption.allFutureShifts:
        return Icons.update;
      case RemoveSectionOption.allShiftsIncludingPast:
        return Icons.history;
      case RemoveSectionOption.cancel:
        return Icons.close;
    }
  }
}
