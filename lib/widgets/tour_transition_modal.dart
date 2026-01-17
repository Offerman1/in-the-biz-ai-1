import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable modal: "Tap X to continue!"
/// Configurable title, message, target button
/// Auto-triggers pulse on target button via callback
class TourTransitionModal {
  static OverlayEntry? _overlayEntry;

  /// Check if modal is currently visible
  static bool get isVisible => _overlayEntry != null;

  /// Force remove any stuck overlays (call if interactions are blocked)
  static void forceHide() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Ignore errors if overlay was already removed
    }
    _overlayEntry = null;
  }

  /// Hide the non-blocking modal (call when target button is tapped)
  static void hide() {
    forceHide();
  }

  /// Show a non-blocking modal with green overlay and cutout around target
  static void showNonBlocking({
    required BuildContext context,
    required String title,
    required String message,
    required GlobalKey targetKey,
  }) {
    hide(); // Remove any existing overlay first

    // Wait for the next frame to ensure target widget is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get target button position and size
      final RenderBox? targetBox =
          targetKey.currentContext?.findRenderObject() as RenderBox?;
      Rect? targetRect;
      if (targetBox != null) {
        final position = targetBox.localToGlobal(Offset.zero);
        final size = targetBox.size;
        // Create larger circle centered on the button for pulsing visibility
        final centerX = position.dx + size.width / 2;
        final centerY = position.dy + size.height / 2;
        const radius = 40.0; // Larger radius to show pulsing
        targetRect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: radius * 2,
          height: radius * 2,
        );
      }

      _overlayEntry = OverlayEntry(
        builder: (_) {
          return IgnorePointer(
            // Let ALL taps pass through - overlay is visual only
            ignoring: true,
            child: Stack(
              children: [
                // Green overlay with cutout - purely visual
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      targetRect: targetRect,
                      overlayColor: AppTheme.primaryGreen.withOpacity(0.85),
                    ),
                  ),
                ),
                // The modal message
                Positioned(
                  top: 180,
                  left: 20,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
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
                            const SizedBox(height: 12),
                            Text(
                              message,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  /// Show transition modal with custom message (BLOCKING - requires Got It)
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

/// Custom painter that draws overlay with a circular cutout for the target
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  _SpotlightPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // Draw full screen overlay
    final fullScreen = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect != null) {
      // Create path with hole cut out
      final path = Path()
        ..addRect(fullScreen)
        ..addOval(targetRect!)
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(path, paint);
    } else {
      // No target, just draw full overlay
      canvas.drawRect(fullScreen, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
