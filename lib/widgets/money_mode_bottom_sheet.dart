import 'package:flutter/material.dart';
import '../models/money_display_mode.dart';
import '../theme/app_theme.dart';

class MoneyModeBottomSheet extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeSelected;

  const MoneyModeBottomSheet({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Display Amount',
                style: AppTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose what earnings to display',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 20),

            // Mode options
            _buildModeOption(
              context,
              mode: MoneyDisplayMode.totalRevenue,
              icon: Icons.attach_money,
              isSelected: currentMode == MoneyDisplayMode.totalRevenue.name,
            ),
            _buildModeOption(
              context,
              mode: MoneyDisplayMode.takeHomePay,
              icon: Icons.account_balance_wallet,
              isSelected: currentMode == MoneyDisplayMode.takeHomePay.name,
            ),
            _buildModeOption(
              context,
              mode: MoneyDisplayMode.tipsOnly,
              icon: Icons.payments,
              isSelected: currentMode == MoneyDisplayMode.tipsOnly.name,
            ),
            _buildModeOption(
              context,
              mode: MoneyDisplayMode.hourlyOnly,
              icon: Icons.schedule,
              isSelected: currentMode == MoneyDisplayMode.hourlyOnly.name,
            ),
            _buildModeOption(
              context,
              mode: MoneyDisplayMode.netEarnings,
              icon: Icons.savings,
              isSelected: currentMode == MoneyDisplayMode.netEarnings.name,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required MoneyDisplayMode mode,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        onModeSelected(mode.name);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.cardBackground // Subtle neutral background
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : Colors.transparent, // Only accent on border
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundLight, // Always neutral
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.textMuted, // Always gray
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: AppTheme.textPrimary, // Always white
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
