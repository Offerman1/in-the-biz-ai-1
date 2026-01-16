import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable modal: "Tap X to continue!"
/// Configurable title, message, target button
/// Auto-triggers pulse on target button via callback
class TourTransitionModal {
  /// Show transition modal with custom message
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Got It!',
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to tap button
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.arrow_forward,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show transition modal for "Tap + to add a shift" (after Step 9)
  static void showAddShiftPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: 'Add Your First Shift!',
      message:
          'Now tap the + button at the top to add a shift and see how easy it is!',
      onDismiss: onDismiss,
    );
  }

  /// Show transition modal for Calendar navigation (after Step 17)
  static void showCalendarPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: 'Explore the Calendar!',
      message:
          'Tap the Calendar button at the bottom to see your shifts organized by date.',
      onDismiss: onDismiss,
    );
  }

  /// Show transition modal for Chat navigation (after Step 24)
  static void showChatPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: 'Meet Your AI Assistant!',
      message:
          'Tap the Chat button to explore AI-powered features that make tracking income effortless.',
      onDismiss: onDismiss,
    );
  }

  /// Show transition modal for Stats navigation (after Step 30)
  static void showStatsPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: 'Check Your Stats!',
      message:
          'Tap the Stats button to view detailed analytics about your earnings.',
      onDismiss: onDismiss,
    );
  }

  /// Show transition modal for Settings navigation (after Step 33)
  static void showSettingsPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: 'Explore Settings!',
      message:
          'Tap the 3 dots (⋮) at the top, then tap Settings to configure your app.',
      onDismiss: onDismiss,
    );
  }

  /// Show final completion modal (after Step 43)
  static void showCompletionModal(
      BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: '🎉 Tour Complete!',
      message:
          'You\'re ready to start tracking your income like a pro!\n\nYou can restart this tour anytime from Settings → Help & Support.',
      buttonText: 'Start Earning!',
      onDismiss: onDismiss,
    );
  }
}
