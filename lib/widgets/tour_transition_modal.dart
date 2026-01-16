import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum HintArrowDirection { up, down, none }

/// Non-blocking floating hint for tour transitions.
/// Shows a message with an animated arrow pointing at the target.
/// User can tap the target button directly without dismissing the hint first.
class TourTransitionModal {
  static OverlayEntry? _currentEntry;
  static VoidCallback? _onTargetTapped;

  /// Show a non-blocking floating hint
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onDismiss,
    HintArrowDirection arrowDirection = HintArrowDirection.down,
    String buttonText =
        'Got It!', // Kept for backward compatibility but not shown
  }) {
    hide(); // Remove any existing hint
    _onTargetTapped = onDismiss;

    _currentEntry = OverlayEntry(
      builder: (context) => _FloatingHintWidget(
        title: title,
        message: message,
        arrowDirection: arrowDirection,
        onClose: () {
          hide();
          onDismiss?.call();
        },
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  /// Hide the current floating hint
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Called when the target button is tapped - hides the overlay
  static void notifyTargetTapped() {
    hide();
    _onTargetTapped?.call();
    _onTargetTapped = null;
  }

  /// Check if a hint is currently showing
  static bool get isShowing => _currentEntry != null;

  // Legacy methods for backward compatibility
  static void showAddShiftPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: '➕ Add Your First Shift!',
      message: 'Tap the + button at the top!',
      arrowDirection: HintArrowDirection.up, // Point UP toward + button
      onDismiss: onDismiss,
    );
  }

  static void showCalendarPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: '📅 Explore the Calendar!',
      message: 'Tap the Calendar button below!',
      onDismiss: onDismiss,
    );
  }

  static void showChatPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: '✨ Meet Your AI Assistant!',
      message: 'Tap the Chat button below!',
      onDismiss: onDismiss,
    );
  }

  static void showStatsPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: '📊 Check Your Stats!',
      message: 'Tap the Stats button below!',
      onDismiss: onDismiss,
    );
  }

  static void showSettingsPrompt(BuildContext context, VoidCallback onDismiss) {
    show(
      context: context,
      title: '⚙️ Head to Settings!',
      message: 'Tap the Home button below!',
      onDismiss: onDismiss,
    );
  }

  static void showCompletionModal(
      BuildContext context, VoidCallback onDismiss) {
    // This one uses a blocking dialog since it's the final completion
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 2,
          ),
        ),
        title: Text(
          '🎉 Tour Complete!',
          style: TextStyle(color: AppTheme.primaryGreen, fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'re ready to start tracking your income like a pro!',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You can restart this tour anytime from Settings → Help & Support.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  const Text('Let\'s Go! 🚀', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingHintWidget extends StatefulWidget {
  final String title;
  final String message;
  final HintArrowDirection arrowDirection;
  final VoidCallback onClose;

  const _FloatingHintWidget({
    required this.title,
    required this.message,
    required this.onClose,
    this.arrowDirection = HintArrowDirection.down,
  });

  @override
  State<_FloatingHintWidget> createState() => _FloatingHintWidgetState();
}

class _FloatingHintWidgetState extends State<_FloatingHintWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if arrow points up or down
    final bool arrowUp = widget.arrowDirection == HintArrowDirection.up;
    final bool showArrow = widget.arrowDirection != HintArrowDirection.none;

    // Use IgnorePointer on the full-screen container so touches pass through
    // Only the hint box itself is tappable
    return IgnorePointer(
      ignoring: true, // Let touches pass through to elements below
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // The floating hint card - positioned based on arrow direction
            Positioned(
              top: arrowUp ? 180 : 120, // Lower when arrow points up
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Message
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Animated arrow - pointing up or down based on direction
            if (showArrow)
              Positioned(
                top: arrowUp ? 100 : null, // Position at top when pointing up
                bottom: arrowUp
                    ? null
                    : 100, // Position at bottom when pointing down
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    // Bounce in the direction of the arrow
                    final double offset = arrowUp
                        ? -_bounceAnimation.value // Bounce up
                        : _bounceAnimation.value; // Bounce down
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            arrowUp ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
