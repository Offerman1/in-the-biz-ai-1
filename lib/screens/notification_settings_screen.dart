import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _shiftReminders = true;
  bool _endOfShiftPrompts = true;
  bool _weeklySummaries = true;
  bool _monthlySummaries = true;
  bool _scheduleChanges = true;
  bool _taxReminders = true;
  bool _inactivityReminders = true;
  bool _milestones = true;
  bool _goalProgress = true;
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // On Android 13+, check if permission is granted
    // This is a simple check - in production you'd want more robust checking
    setState(() {
      _permissionGranted = true; // Assume granted for now
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    setState(() {
      _permissionGranted = granted;
    });

    if (mounted) {
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions granted!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please enable notifications in your device settings'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shiftReminders = prefs.getBool('notif_shift_reminders') ?? true;
      _endOfShiftPrompts = prefs.getBool('notif_end_of_shift') ?? true;
      _weeklySummaries = prefs.getBool('notif_weekly_summary') ?? true;
      _monthlySummaries = prefs.getBool('notif_monthly_summary') ?? true;
      _scheduleChanges = prefs.getBool('notif_schedule_changes') ?? true;
      _taxReminders = prefs.getBool('notif_tax_reminders') ?? true;
      _inactivityReminders = prefs.getBool('notif_inactivity') ?? true;
      _milestones = prefs.getBool('notif_milestones') ?? true;
      _goalProgress = prefs.getBool('notif_goal_progress') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Notifications',
            style: AppTheme.titleLarge
                .copyWith(color: AppTheme.adaptiveTextColor)),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Manage your notification preferences',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          // Permission request banner (if needed)
          if (!_permissionGranted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_off,
                        color: AppTheme.accentOrange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications Disabled',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable notifications to receive shift reminders and updates',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Enable Notifications'),
                    ),
                  ),
                ],
              ),
            ),

          // Shift Reminders
          _buildNotificationTile(
            title: 'Shift Reminders',
            subtitle: 'Get notified 1 hour before your shift starts',
            icon: Icons.alarm,
            value: _shiftReminders,
            onChanged: (value) {
              setState(() => _shiftReminders = value);
              _saveSetting('notif_shift_reminders', value);
            },
          ),

          const SizedBox(height: 16),

          // End of Shift Prompts
          _buildNotificationTile(
            title: 'End-of-Shift Prompts',
            subtitle: 'Remind me to log earnings after shift ends',
            icon: Icons.edit_notifications,
            value: _endOfShiftPrompts,
            onChanged: (value) {
              setState(() => _endOfShiftPrompts = value);
              _saveSetting('notif_end_of_shift', value);
            },
          ),

          const SizedBox(height: 16),

          // Weekly Summaries
          _buildNotificationTile(
            title: 'Weekly Summaries',
            subtitle: 'Get a summary of your week every Monday at noon',
            icon: Icons.analytics_outlined,
            value: _weeklySummaries,
            onChanged: (value) {
              setState(() => _weeklySummaries = value);
              _saveSetting('notif_weekly_summary', value);
            },
          ),

          const SizedBox(height: 16),

          // Monthly Summaries
          _buildNotificationTile(
            title: 'Monthly Summaries',
            subtitle: 'Get a summary on the 1st of each month at 1 PM',
            icon: Icons.calendar_today,
            value: _monthlySummaries,
            onChanged: (value) async {
              setState(() => _monthlySummaries = value);
              _saveSetting('notif_monthly_summary', value);
              if (value) {
                // Schedule monthly summary when enabled
                await NotificationService().scheduleMonthlySummary();
              }
            },
          ),

          const SizedBox(height: 16),

          // Schedule Change Alerts
          _buildNotificationTile(
            title: 'Schedule Changes',
            subtitle: 'Alert when shifts are updated or synced',
            icon: Icons.sync_alt,
            value: _scheduleChanges,
            onChanged: (value) {
              setState(() => _scheduleChanges = value);
              _saveSetting('notif_schedule_changes', value);
            },
          ),

          const SizedBox(height: 16),

          // Tax Reminders
          _buildNotificationTile(
            title: 'Tax Reminders',
            subtitle: 'Quarterly reminders for tax deadlines',
            icon: Icons.account_balance,
            value: _taxReminders,
            onChanged: (value) async {
              setState(() => _taxReminders = value);
              _saveSetting('notif_tax_reminders', value);
              if (value) {
                // Schedule tax reminders when enabled
                await NotificationService().scheduleQuarterlyTaxReminders();
              }
            },
          ),

          const SizedBox(height: 16),

          // Inactivity Reminders
          _buildNotificationTile(
            title: 'Inactivity Reminders',
            subtitle: 'Remind me if I haven\'t logged shifts in 5+ days',
            icon: Icons.notifications_paused,
            value: _inactivityReminders,
            onChanged: (value) {
              setState(() => _inactivityReminders = value);
              _saveSetting('notif_inactivity', value);
            },
          ),

          const SizedBox(height: 16),

          // Milestone Celebrations
          _buildNotificationTile(
            title: 'Milestone Celebrations',
            subtitle: 'Celebrate when you hit earning goals',
            icon: Icons.emoji_events,
            value: _milestones,
            onChanged: (value) {
              setState(() => _milestones = value);
              _saveSetting('notif_milestones', value);
            },
          ),

          const SizedBox(height: 16),

          // Goal Progress
          _buildNotificationTile(
            title: 'Goal Progress',
            subtitle: 'Updates when you hit milestones or goals',
            icon: Icons.emoji_events_outlined,
            value: _goalProgress,
            onChanged: (value) {
              setState(() => _goalProgress = value);
              _saveSetting('notif_goal_progress', value);
            },
          ),

          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure notifications are enabled in your device settings',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : AppTheme.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryGreen,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                    : AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: value ? AppTheme.primaryGreen : AppTheme.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
