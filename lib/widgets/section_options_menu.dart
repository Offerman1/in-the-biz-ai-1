import 'package:flutter/material.dart';
import '../models/section_definition.dart';
import '../theme/app_theme.dart';

/// Three-dot menu for section headers
/// Allows users to remove sections from shifts or templates
class SectionOptionsMenu extends StatelessWidget {
  final String sectionKey;
  final Function(RemoveSectionOption) onOptionSelected;

  const SectionOptionsMenu({
    super.key,
    required this.sectionKey,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppTheme.textMuted,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      color: AppTheme.cardBackground,
      onSelected: (value) {
        if (value == 'remove') {
          _showRemoveDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline,
                  color: AppTheme.dangerColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Remove Section',
                style: TextStyle(color: AppTheme.dangerColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRemoveDialog(BuildContext context) {
    final section = SectionRegistry.getSection(sectionKey);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.remove_circle_outline,
                      color: AppTheme.dangerColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remove "${section?.label ?? sectionKey}"',
                      style: AppTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to remove this section:',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Options
              _buildOption(
                context,
                RemoveSectionOption.thisShiftOnly,
              ),
              const SizedBox(height: 8),
              _buildOption(
                context,
                RemoveSectionOption.allFutureShifts,
              ),
              const SizedBox(height: 8),
              _buildOption(
                context,
                RemoveSectionOption.allShiftsIncludingPast,
              ),
              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onOptionSelected(RemoveSectionOption.cancel);
                  },
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

  Widget _buildOption(BuildContext context, RemoveSectionOption option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onOptionSelected(option);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: option == RemoveSectionOption.allShiftsIncludingPast
                  ? AppTheme.dangerColor.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: option == RemoveSectionOption.allShiftsIncludingPast
                    ? AppTheme.dangerColor
                    : AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            option == RemoveSectionOption.allShiftsIncludingPast
                                ? AppTheme.dangerColor
                                : null,
                      ),
                    ),
                    if (option.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
