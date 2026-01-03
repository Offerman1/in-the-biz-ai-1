import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  List<Map<String, dynamic>> _proUsers = [];
  Map<String, dynamic>? _subscriptionAnalytics;
  bool _isLoading = true;
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _loadProUsers();
    _loadSubscriptionAnalytics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProUsers() async {
    setState(() => _isLoading = true);
    final users = await SubscriptionService().getProUsers();
    setState(() {
      _proUsers = users;
      _isLoading = false;
    });
  }

  Future<void> _loadSubscriptionAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    final analytics = await SubscriptionService().getSubscriptionAnalytics();
    setState(() {
      _subscriptionAnalytics = analytics;
      _isLoadingAnalytics = false;
    });
  }

  Future<void> _grantProAccess() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    final success = await SubscriptionService().grantProAccess(
      _emailController.text.trim(),
      _notesController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Pro access granted to ${_emailController.text}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _emailController.clear();
        _notesController.clear();
        await _loadProUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Failed to grant Pro access. User may not exist.'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _revokeProAccess(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Pro Access'),
        content: Text('Remove Pro access from $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SubscriptionService().revokeProAccess(email);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Pro access revoked from $email'),
              backgroundColor: AppTheme.accentOrange,
            ),
          );
          await _loadProUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✗ Failed to revoke Pro access'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Admin Panel',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription Analytics Section
            if (_isLoadingAnalytics)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
              )
            else if (_subscriptionAnalytics != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics,
                            color: AppTheme.accentBlue, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Your Subscription Analytics',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAnalyticRow(
                      'Status',
                      _subscriptionAnalytics!['is_subscribed'] == true
                          ? 'Pro Active ✅'
                          : 'Free Tier',
                      _subscriptionAnalytics!['is_subscribed'] == true
                          ? AppTheme.successColor
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    _buildAnalyticRow(
                      'Plan Type',
                      _subscriptionAnalytics!['subscription_type']
                              ?.toString()
                              .toUpperCase() ??
                          'NONE',
                      AppTheme.textPrimary,
                    ),
                    if (_subscriptionAnalytics!['will_renew'] != null) ...[
                      const SizedBox(height: 8),
                      _buildAnalyticRow(
                        'Auto-Renew',
                        _subscriptionAnalytics!['will_renew'] == true
                            ? 'Enabled ✅'
                            : 'Disabled ❌',
                        _subscriptionAnalytics!['will_renew'] == true
                            ? AppTheme.successColor
                            : AppTheme.dangerColor,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Note: Full analytics (MRR, total subs, etc.) will be available once RevenueCat API keys are configured.',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Grant Pro Access Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grant Pro Access',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'User email address',
                      prefixIcon:
                          Icon(Icons.email, color: AppTheme.primaryGreen),
                      filled: true,
                      fillColor: AppTheme.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _grantProAccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: const Text(
                        'Grant Pro Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pro Users List
            Text(
              'Pro Users (${_proUsers.length})',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
              )
            else if (_proUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          color: AppTheme.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No Pro users yet',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _proUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = _proUsers[index];
                  final grantedAt = DateTime.parse(user['granted_at']);
                  final dateFormat = DateFormat('MMM d, y h:mm a');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.star,
                              color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email'],
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Granted: ${dateFormat.format(grantedAt)}',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              if (user['notes'] != null &&
                                  user['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user['notes'],
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppTheme.dangerColor),
                          onPressed: () => _revokeProAccess(user['email']),
                          tooltip: 'Revoke Pro Access',
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
