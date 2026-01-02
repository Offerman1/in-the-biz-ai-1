import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/field_order_provider.dart';
import '../theme/app_theme.dart';

/// Settings widget for managing field order preferences
/// Can be added to the Settings screen
class FieldOrderSettings extends StatelessWidget {
  const FieldOrderSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FieldOrderProvider>(
      builder: (context, fieldOrderProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reset Add/Edit Shift Layout
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: ListTile(
                onTap: () {
                  _showResetConfirmation(
                    context,
                    'Reset Add/Edit Shift Layout?',
                    'This will restore the default order for the Add Shift and Edit Shift screens.',
                    () async {
                      await fieldOrderProvider.resetFormFieldOrder();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('✓ Add/Edit Shift layout reset'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
                  );
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restore, color: AppTheme.accentOrange),
                ),
                title: Text('Reset Add/Edit Shift Layout',
                    style: AppTheme.bodyMedium),
                subtitle: Text(
                  'Restore default field order for data entry',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 12),

            // Reset Shift Details Layout
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: ListTile(
                onTap: () {
                  _showResetConfirmation(
                    context,
                    'Reset Shift Details Layout?',
                    'This will restore the default order for the Shift Details (preview) screen.',
                    () async {
                      await fieldOrderProvider.resetDetailsFieldOrder();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('✓ Shift Details layout reset'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
                  );
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restore, color: AppTheme.accentOrange),
                ),
                title: Text('Reset Shift Details Layout',
                    style: AppTheme.bodyMedium),
                subtitle: Text(
                  'Restore default field order for shift preview',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 12),

            // Reset All Layouts
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: ListTile(
                onTap: () {
                  _showResetConfirmation(
                    context,
                    'Reset All Layouts?',
                    'This will restore the default order for both Add/Edit Shift and Shift Details screens.',
                    () async {
                      await fieldOrderProvider.resetFormFieldOrder();
                      await fieldOrderProvider.resetDetailsFieldOrder();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('✓ All layouts reset to default'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
                  );
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restart_alt, color: AppTheme.dangerColor),
                ),
                title: Text('Reset All Layouts',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.w600,
                    )),
                subtitle: Text(
                  'Restore all default field orders',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmation(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(title, style: AppTheme.titleMedium),
          content: Text(message, style: AppTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child:
                  Text('Reset', style: TextStyle(color: AppTheme.dangerColor)),
            ),
          ],
        );
      },
    );
  }
}
