import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../theme/app_theme.dart';

/// Helper class to create coach marks for the app tour
class TourTargets {
  /// Create a target for the coach mark tutorial
  /// currentScreen: which screen this step is on (dashboard, addShift, calendar, chat, stats, settings)
  /// onSkipToNext: callback to skip to the next screen's tour
  /// onEndTour: callback to end the entire tour
  static TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required String currentScreen,
    required VoidCallback onSkipToNext,
    required VoidCallback onEndTour,
    ContentAlign? align,
    ShapeLightFocus? shape,
    CustomTargetContentPosition? customPosition,
  }) {
    // Determine the "Skip to X" button text based on current screen
    String skipButtonText;
    switch (currentScreen) {
      case 'dashboard':
        skipButtonText = 'Skip to Add Shift →';
        break;
      case 'addShift':
        skipButtonText = 'Skip to Calendar →';
        break;
      case 'calendar':
        skipButtonText = 'Skip to Chat →';
        break;
      case 'chat':
        skipButtonText = 'Skip to Stats →';
        break;
      case 'stats':
        skipButtonText = 'Skip to Settings →';
        break;
      case 'settings':
        skipButtonText = 'Finish Tour';
        break;
      default:
        skipButtonText = 'Skip Screen →';
    }

    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      enableOverlayTab: false, // Don't skip on tap outside
      enableTargetTab: false, // Don't advance on tap target
      shape: shape ?? ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: align ?? ContentAlign.bottom,
          customPosition: customPosition,
          builder: (context, controller) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title + End Tour button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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
                      // End Tour button (top right, red)
                      GestureDetector(
                        onTap: () {
                          onEndTour();
                          controller.skip();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'End Tour',
                            style: TextStyle(
                              color: AppTheme.dangerColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bottom buttons: Skip to Next Screen | Next
                  Row(
                    children: [
                      // Skip to next screen button
                      TextButton(
                        onPressed: () {
                          // Call onSkipToNext FIRST (this sets the new step/screen)
                          onSkipToNext();
                          // Then call next() instead of skip() - this closes the overlay
                          // without triggering onSkip callback
                          controller.next();
                        },
                        child: Text(
                          skipButtonText,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Next button
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Create welcome target (no specific widget targeted)
  static TargetFocus createWelcomeTarget(
    BuildContext context,
    VoidCallback onNext,
    VoidCallback onSkip, {
    String? title,
    String? message,
  }) {
    return TargetFocus(
      identify: title?.toLowerCase().replaceAll(' ', '_') ?? 'welcome',
      keyTarget: GlobalKey(), // Dummy key
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: CustomTargetContentPosition(
            top: MediaQuery.of(context).size.height * 0.3,
          ),
          builder: (context, controller) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.2),
                    AppTheme.accentBlue.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Icon(
                    Icons.tour,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    title ?? 'Welcome to In The Biz!',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    message ??
                        'Let\'s show you how to track your income like a pro. This quick tour will help you get the most out of the app.',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.skip();
                            onSkip();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                            side: BorderSide(
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Skip Tour'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.next();
                            onNext();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Let\'s Go!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
