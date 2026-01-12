import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/vision_scan.dart';

/// Bottom sheet menu for selecting what type of document to scan
/// Users can scan with camera OR upload from gallery after selecting
class ScanTypeMenu extends StatelessWidget {
  final Function(ScanType) onScanTypeSelected;

  const ScanTypeMenu({
    super.key,
    required this.onScanTypeSelected,
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
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(
                    'What would you like to scan?',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📷 Take a photo or 📁 upload from gallery',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Scan type options
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ScanType.values.length,
              separatorBuilder: (context, index) => Divider(
                color: AppTheme.textMuted.withValues(alpha: 0.1),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final scanType = ScanType.values[index];
                return ListTile(
                  leading: Text(
                    scanType.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    scanType.displayName,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    scanType.description,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onScanTypeSelected(scanType);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Show the scan type menu as a modal bottom sheet
Future<void> showScanTypeMenu(
  BuildContext context,
  Function(ScanType) onScanTypeSelected,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ScanTypeMenu(onScanTypeSelected: onScanTypeSelected),
  );
}
