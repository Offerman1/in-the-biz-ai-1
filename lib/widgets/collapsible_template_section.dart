import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A collapsible section widget for job template customization
/// Used in onboarding, add job, and edit job screens
class CollapsibleTemplateSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool hasActiveFields; // True if any toggles in this section are enabled

  const CollapsibleTemplateSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.hasActiveFields = false,
  });

  @override
  State<CollapsibleTemplateSection> createState() =>
      _CollapsibleTemplateSectionState();
}

class _CollapsibleTemplateSectionState
    extends State<CollapsibleTemplateSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(CollapsibleTemplateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initiallyExpanded changed, update state
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: widget.hasActiveFields
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible, tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.hasActiveFields
                        ? AppTheme.primaryGreen
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.titleMedium.copyWith(
                        color: widget.hasActiveFields
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  // Active indicator
                  if (widget.hasActiveFields)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content - shown when expanded
          if (_isExpanded) ...[
            Divider(height: 1, color: AppTheme.cardBackgroundLight),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}

/// A single toggle item for use inside CollapsibleTemplateSection
class TemplateToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const TemplateToggleItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: value ? AppTheme.primaryGreen : AppTheme.textMuted,
              size: 20,
            )
          : null,
      title: Text(
        title,
        style: AppTheme.bodyLarge.copyWith(
          color: value ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.textMuted,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
