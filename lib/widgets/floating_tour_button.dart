import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/tour_service.dart';

/// Floating tour button that appears on every major screen
/// Pulsing animation to draw attention
/// Can be dismissed with "Never show again" option
class FloatingTourButton extends StatefulWidget {
  final VoidCallback onTap;

  const FloatingTourButton({
    super.key,
    required this.onTap,
  });

  @override
  State<FloatingTourButton> createState() => _FloatingTourButtonState();
}

class _FloatingTourButtonState extends State<FloatingTourButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDismissDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Hide Tour Button?',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // X button to close
            IconButton(
              icon: Icon(Icons.close, color: AppTheme.textMuted),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Text(
          'You can always restart the tour from Settings → Help & Support.',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          // Close for Now button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final tourService =
                    Provider.of<TourService>(context, listen: false);
                tourService.hideTourButtonTemporarily();
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.textMuted),
                foregroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
              ),
              child: const Text(
                'Close for Now',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Never Show Again button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final tourService =
                    Provider.of<TourService>(context, listen: false);
                tourService.hideTourButton();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
              ),
              child: const Text(
                'Never Show Again',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tourService = Provider.of<TourService>(context);

    // Don't show if user has hidden it
    if (tourService.isTourButtonHidden) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      bottom: 80, // Above nav bar (nav bar is ~60px)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer glow
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Main button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.accentBlue,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // X button (top-right corner)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: _showDismissDialog,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.dangerColor,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
