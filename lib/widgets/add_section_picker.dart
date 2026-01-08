import 'package:flutter/material.dart';
import '../models/section_definition.dart';
import '../theme/app_theme.dart';

/// Picker to add back hidden sections
/// Similar to AddFieldPicker but for sections
class AddSectionPicker extends StatelessWidget {
  final List<String> hiddenSectionKeys;
  final Function(String sectionKey, RemoveSectionOption scope)
      onSectionSelected;

  const AddSectionPicker({
    super.key,
    required this.hiddenSectionKeys,
    required this.onSectionSelected,
  });

  static void show({
    required BuildContext context,
    required List<String> hiddenSectionKeys,
    required Function(String sectionKey, RemoveSectionOption scope)
        onSectionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddSectionPicker(
        hiddenSectionKeys: hiddenSectionKeys,
        onSectionSelected: onSectionSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hiddenSections = hiddenSectionKeys
        .map((key) => SectionRegistry.getSection(key))
        .where((s) => s != null)
        .cast<SectionDefinition>()
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: AppTheme.primaryGreen, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Section',
                    style: AppTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a section to add back:',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            if (hiddenSections.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.primaryGreen,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All sections are visible',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...hiddenSections.map((section) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSectionTile(context, section),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile(BuildContext context, SectionDefinition section) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showScopeDialog(context, section),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  section.icon,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle,
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScopeDialog(BuildContext context, SectionDefinition section) {
    Navigator.pop(context); // Close the picker first

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(section.icon, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add "${section.label}"',
                      style: AppTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Where should this section be added?',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // This shift only
              _buildScopeOption(
                ctx,
                section.key,
                RemoveSectionOption.thisShiftOnly,
                'Add to this shift only',
                'Only this shift will show this section',
                Icons.event,
              ),
              const SizedBox(height: 8),

              // All future shifts
              _buildScopeOption(
                ctx,
                section.key,
                RemoveSectionOption.allFutureShifts,
                'Add to all future shifts',
                'Updates job template for new shifts',
                Icons.update,
              ),
              const SizedBox(height: 8),

              // All shifts including past
              _buildScopeOption(
                ctx,
                section.key,
                RemoveSectionOption.allShiftsIncludingPast,
                'Add to all shifts (including past)',
                'Updates all existing shifts for this job',
                Icons.history,
              ),
              const SizedBox(height: 16),

              // Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeOption(
    BuildContext context,
    String sectionKey,
    RemoveSectionOption scope,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSectionSelected(sectionKey, scope);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
