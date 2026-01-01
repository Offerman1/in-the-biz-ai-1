import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';

/// Wraps any screen with the bottom navigation bar
/// This ensures the bottom nav is always visible, even on detail screens
class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final int? currentTabIndex; // Optional: highlights the active tab

  const NavigationWrapper({
    super.key,
    required this.child,
    this.currentTabIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navBarBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    context, 0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(context, 1, Icons.calendar_today_outlined,
                    Icons.calendar_today, 'Calendar'),
                _buildNavItem(context, 2, Icons.auto_awesome_outlined,
                    Icons.auto_awesome, 'Chat'),
                _buildNavItem(context, 3, Icons.bar_chart_outlined,
                    Icons.bar_chart, 'Stats'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon,
      IconData activeIcon, String label) {
    final isSelected = currentTabIndex == index;

    return GestureDetector(
      onTap: () {
        // Navigate back to dashboard with the selected tab
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.navBarActiveBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppTheme.navBarIconActiveColor
                  : AppTheme.navBarIconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.navBarIconActiveColor
                    : AppTheme.navBarIconColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
