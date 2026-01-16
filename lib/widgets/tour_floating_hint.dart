import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A floating hint widget that appears during tour transitions.
/// Unlike dialogs, this doesn't block user interaction with the UI below.
class TourFloatingHint extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  final Alignment alignment;
  final bool showArrow;
  final ArrowDirection arrowDirection;
  final double? arrowTargetX;
  final double? arrowTargetY;

  const TourFloatingHint({
    super.key,
    required this.message,
    this.onDismiss,
    this.alignment = Alignment.center,
    this.showArrow = true,
    this.arrowDirection = ArrowDirection.down,
    this.arrowTargetX,
    this.arrowTargetY,
  });

  @override
  State<TourFloatingHint> createState() => _TourFloatingHintState();
}

class _TourFloatingHintState extends State<TourFloatingHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The hint box - positioned based on alignment
        Positioned(
          top: widget.alignment == Alignment.topCenter ||
                  widget.alignment == Alignment.topLeft ||
                  widget.alignment == Alignment.topRight
              ? 100
              : null,
          bottom: widget.alignment == Alignment.bottomCenter ||
                  widget.alignment == Alignment.bottomLeft ||
                  widget.alignment == Alignment.bottomRight
              ? 120
              : null,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Animated pointing arrow
        if (widget.showArrow &&
            widget.arrowTargetX != null &&
            widget.arrowTargetY != null)
          AnimatedBuilder(
            animation: _arrowAnimation,
            builder: (context, child) {
              double offsetX = 0;
              double offsetY = 0;

              switch (widget.arrowDirection) {
                case ArrowDirection.down:
                  offsetY = _arrowAnimation.value;
                  break;
                case ArrowDirection.up:
                  offsetY = -_arrowAnimation.value;
                  break;
                case ArrowDirection.left:
                  offsetX = -_arrowAnimation.value;
                  break;
                case ArrowDirection.right:
                  offsetX = _arrowAnimation.value;
                  break;
              }

              return Positioned(
                left: widget.arrowTargetX! - 20 + offsetX,
                top: widget.arrowTargetY! - 50 + offsetY,
                child: _buildArrow(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildArrow() {
    IconData arrowIcon;

    switch (widget.arrowDirection) {
      case ArrowDirection.down:
        arrowIcon = Icons.arrow_downward;
        break;
      case ArrowDirection.up:
        arrowIcon = Icons.arrow_upward;
        break;
      case ArrowDirection.left:
        arrowIcon = Icons.arrow_back;
        break;
      case ArrowDirection.right:
        arrowIcon = Icons.arrow_forward;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        arrowIcon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

enum ArrowDirection { up, down, left, right }

/// Overlay manager for showing floating hints during tour
class TourHintOverlay {
  static OverlayEntry? _currentEntry;

  /// Show a floating hint that doesn't block interaction
  static void show({
    required BuildContext context,
    required String message,
    required GlobalKey targetKey,
    ArrowDirection arrowDirection = ArrowDirection.down,
    Alignment hintAlignment = Alignment.topCenter,
  }) {
    hide(); // Remove any existing hint

    final RenderBox? targetBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    double? arrowX;
    double? arrowY;

    if (targetBox != null) {
      final position = targetBox.localToGlobal(Offset.zero);
      final size = targetBox.size;
      arrowX = position.dx + size.width / 2;

      // Position arrow above or below target based on direction
      if (arrowDirection == ArrowDirection.down) {
        arrowY = position.dy - 10;
      } else {
        arrowY = position.dy + size.height + 10;
      }
    }

    _currentEntry = OverlayEntry(
      builder: (context) => TourFloatingHint(
        message: message,
        alignment: hintAlignment,
        showArrow: arrowX != null,
        arrowDirection: arrowDirection,
        arrowTargetX: arrowX,
        arrowTargetY: arrowY,
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  /// Hide the current floating hint
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Check if a hint is currently showing
  static bool get isShowing => _currentEntry != null;
}
