import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wrapper widget that adds reorder capabilities to shift form sections
/// Shows a drag handle that users can long-press to reorder sections
class ReorderableSection extends StatelessWidget {
  final String sectionKey;
  final Widget child;
  final bool isLocked; // Set true for Job selector and Date sections

  const ReorderableSection({
    super.key,
    required this.sectionKey,
    required this.child,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      // Locked sections can't be dragged
      return child;
    }

    return Stack(
      children: [
        child,
        // Drag handle indicator (top-right corner)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.drag_indicator,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
