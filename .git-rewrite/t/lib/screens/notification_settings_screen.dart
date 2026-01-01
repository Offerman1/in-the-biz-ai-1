import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

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
  bool _conflictAlerts = true;
  bool _weeklySummaries = true;
  bool _goalProgress = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shiftReminders = prefs.getBool('notif_shift_reminders') ?? true;
      _endOfShiftPrompts = prefs.getBool('notif_end_of_shift') ?? true;
      _conflictAlerts = prefs.getBool('notif_conflicts') ?? true;
      _weeklySummaries = prefs.getBool('notif_weekly_summary') ?? true;
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

          // Conflict Alerts
          _buildNotificationTile(
            title: 'Schedule Conflict Alerts',
            subtitle: 'Warn me about overlapping shifts or events',
            icon: Icons.warning_amber_rounded,
            value: _conflictAlerts,
            onChanged: (value) {
              setState(() => _conflictAlerts = value);
              _saveSetting('notif_conflicts', value);
            },
          ),

          const SizedBox(height: 16),

          // Weekly Summaries
          _buildNotificationTile(
            title: 'Weekly Summaries',
            subtitle: 'Get a summary of your week every Monday',
            icon: Icons.analytics_outlined,
            value: _weeklySummaries,
            onChanged: (value) {
              setState(() => _weeklySummaries = value);
              _saveSetting('notif_weekly_summary', value);
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
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
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
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : AppTheme.textMuted.withOpacity(0.1),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? AppTheme.primaryGreen.withOpacity(0.2)
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
