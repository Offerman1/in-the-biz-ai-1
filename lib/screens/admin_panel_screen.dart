import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _proUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Set<String> _selectedUserIds = {};
  Map<String, dynamic>? _subscriptionAnalytics;
  bool _isLoading = true;
  bool _isLoadingUsers = false;
  bool _isLoadingAnalytics = false;
  bool _showUserList = false;

  @override
  void initState() {
    super.initState();
    _loadProUsers();
    _loadSubscriptionAnalytics();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    _searchController.dispose();
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

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, created_at')
          .order('created_at', ascending: false);

      final users = List<Map<String, dynamic>>.from(response);

      // Fetch emails for each user
      for (var user in users) {
        try {
          final email = await Supabase.instance.client
              .rpc('get_user_email', params: {'user_uuid': user['id']});
          user['email'] = email ?? 'No email';
        } catch (e) {
          user['email'] = 'Error loading email';
        }
      }

      setState(() {
        _allUsers = users;
        _filteredUsers = _allUsers;
        _isLoadingUsers = false;
        _showUserList = true;
      });

      // Pre-select users who already have Pro access
      final proUserIds = _proUsers.map((u) => u['user_id'].toString()).toSet();
      setState(() {
        _selectedUserIds = proUserIds;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final fullName = (user['full_name'] ?? '').toLowerCase();
          final email = (user['email'] ?? '').toLowerCase();
          return fullName.contains(query) || email.contains(query);
        }).toList();
      }
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
            content:
                const Text('✗ Failed to grant Pro access. User may not exist.'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _grantProAccessBulk() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    // Get newly selected users (not already Pro)
    final proUserIds = _proUsers.map((u) => u['user_id'].toString()).toSet();
    final newSelections =
        _selectedUserIds.where((id) => !proUserIds.contains(id)).toSet();
    final removedSelections =
        proUserIds.where((id) => !_selectedUserIds.contains(id)).toSet();

    int successCount = 0;
    int failCount = 0;

    // Grant Pro to new selections
    for (final userId in newSelections) {
      final success = await SubscriptionService().grantProAccessByUserId(
        userId,
        'Bulk granted by admin',
      );
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    // Revoke Pro from removed selections
    for (final userId in removedSelections) {
      final success =
          await SubscriptionService().revokeProAccessByUserId(userId);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (!mounted) return;
    await _loadProUsers();

    if (failCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✓ Successfully updated Pro access for $successCount user(s)'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠ Updated $successCount user(s), $failCount failed'),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
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
                    color: AppTheme.accentBlue.withValues(alpha: 0.3),
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
                          'User Analytics',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAnalyticRow(
                      'Total Users',
                      _subscriptionAnalytics!['total_users'].toString(),
                      AppTheme.textPrimary,
                    ),
                    const SizedBox(height: 16),
                    // Pro Users Section
                    Text(
                      'Pro Users Breakdown',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAnalyticRow(
                      '  ├─ Admin Granted',
                      _subscriptionAnalytics!['pro_users_admin_granted']
                          .toString(),
                      AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 8),
                    _buildAnalyticRow(
                      '  └─ Paid (RevenueCat)',
                      _subscriptionAnalytics!['pro_users_paid'].toString(),
                      AppTheme.successColor,
                    ),
                    const SizedBox(height: 16),
                    _buildAnalyticRow(
                      'Free Users',
                      _subscriptionAnalytics!['free_users_count'].toString(),
                      AppTheme.textSecondary,
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
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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

                  // Toggle between Manual Entry and User List
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showUserList = false;
                              _allUsers.clear();
                              _filteredUsers.clear();
                              _selectedUserIds.clear();
                              _searchController.clear();
                            });
                          },
                          icon: Icon(
                            Icons.edit,
                            color: !_showUserList
                                ? AppTheme.primaryGreen
                                : AppTheme.textSecondary,
                          ),
                          label: Text(
                            'Manual Entry',
                            style: TextStyle(
                              color: !_showUserList
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: !_showUserList
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary
                                      .withValues(alpha: 0.3),
                              width: !_showUserList ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingUsers ? null : _loadAllUsers,
                          icon: _isLoadingUsers
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryGreen,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.people,
                                  color: _showUserList
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textSecondary,
                                ),
                          label: Text(
                            'Select Users',
                            style: TextStyle(
                              color: _showUserList
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _showUserList
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary
                                      .withValues(alpha: 0.3),
                              width: _showUserList ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Manual Entry Mode
                  if (!_showUserList) ...[
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

                  // User List Mode
                  if (_showUserList) ...[
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email...',
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: AppTheme.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.cardBackgroundLight,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selection Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedUserIds.length} user(s) selected',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (_selectedUserIds.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedUserIds.clear();
                                });
                              },
                              child: Text(
                                'Clear All',
                                style: TextStyle(color: AppTheme.dangerColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User List
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackgroundLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: _isLoadingUsers
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            )
                          : _filteredUsers.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No users match your search'
                                          : 'No users found',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = _filteredUsers[index];
                                    final userId = user['id'].toString();
                                    final isSelected =
                                        _selectedUserIds.contains(userId);
                                    final fullName =
                                        user['full_name'] ?? 'Unknown User';
                                    final isProUser = _proUsers.any((p) =>
                                        p['user_id'].toString() == userId);

                                    final email = user['email'] ?? 'No email';

                                    return CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedUserIds.add(userId);
                                          } else {
                                            _selectedUserIds.remove(userId);
                                          }
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fullName,
                                              style:
                                                  AppTheme.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (isProUser)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.successColor
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppTheme.successColor,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'PRO',
                                                style: AppTheme.labelSmall
                                                    .copyWith(
                                                  color: AppTheme.successColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        email,
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      activeColor: AppTheme.primaryGreen,
                                      checkColor: Colors.white,
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 16),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedUserIds.isEmpty
                            ? null
                            : _grantProAccessBulk,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Apply Pro Access Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedUserIds.isEmpty
                              ? AppTheme.textMuted
                              : AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.15),
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
