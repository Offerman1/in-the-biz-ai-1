import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../models/job.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Goal types supported by the system
enum GoalType { daily, weekly, monthly, yearly }

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.daily:
        return 'Daily';
      case GoalType.weekly:
        return 'Weekly';
      case GoalType.monthly:
        return 'Monthly';
      case GoalType.yearly:
        return 'Yearly';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalType.daily:
        return Icons.today;
      case GoalType.weekly:
        return Icons.calendar_view_week;
      case GoalType.monthly:
        return Icons.calendar_month;
      case GoalType.yearly:
        return Icons.calendar_today;
    }
  }

  double get defaultAmount {
    switch (this) {
      case GoalType.daily:
        return 100;
      case GoalType.weekly:
        return 500;
      case GoalType.monthly:
        return 2000;
      case GoalType.yearly:
        return 25000;
    }
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final _currencyFormat = NumberFormat.simpleCurrency();

  TabController? _tabController;
  List<Goal> _goals = [];
  List<Job> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final goalsData = await _db.getGoals();
      final jobsData = await _db.getJobs();

      final jobs = jobsData.map((j) => Job.fromSupabase(j)).toList();

      // Only create tab controller once, or recreate if job count changed
      if (_tabController == null || _tabController!.length != 1 + jobs.length) {
        _tabController?.dispose();
        _tabController = TabController(length: 1 + jobs.length, vsync: this);
      }

      setState(() {
        _goals = goalsData.map((g) => Goal.fromSupabase(g)).toList();
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: $e')),
        );
      }
    }
  }

  Goal? _getGoalForType(GoalType type, {String? jobId}) {
    return _goals
        .where((g) => g.type == type.name && g.jobId == jobId && g.isActive)
        .firstOrNull;
  }

  double _calculateProgress(GoalType type, List<Shift> shifts,
      {String? jobId}) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (type) {
      case GoalType.daily:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case GoalType.weekly:
        final weekDay = now.weekday;
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekDay - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;
      case GoalType.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case GoalType.yearly:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
    }

    double total = 0.0;
    for (final shift in shifts) {
      // Filter by job if specified
      if (jobId != null && shift.jobId != jobId) continue;

      if (shift.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          shift.date.isBefore(endDate)) {
        total += shift.totalIncome;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final shifts = shiftProvider.shifts;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text('Goals',
            style: AppTheme.titleLarge
                .copyWith(color: AppTheme.adaptiveTextColor)),
        bottom: _isLoading || _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGreen,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.textSecondary,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'Overall'),
                  ..._jobs.map((job) => Tab(text: job.name)),
                ],
              ),
      ),
      body: _isLoading || _tabController == null
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsTab(
                    shifts, null, 'Track your total income across all jobs'),
                ..._jobs.map((job) => _buildGoalsTab(
                      shifts,
                      job.id,
                      'Track income for ${job.name}${job.employer != null ? ' @ ${job.employer}' : ''}',
                    )),
              ],
            ),
    );
  }

  Widget _buildGoalsTab(List<Shift> shifts, String? jobId, String subtitle) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          subtitle,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        ...GoalType.values.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGoalCard(type, shifts, jobId),
            )),
      ],
    );
  }

  Widget _buildGoalCard(GoalType type, List<Shift> shifts, String? jobId) {
    final goal = _getGoalForType(type, jobId: jobId);
    final hasGoal = goal != null;
    final progress = _calculateProgress(type, shifts, jobId: jobId);
    final progressPercent =
        hasGoal ? (progress / goal.targetAmount).clamp(0.0, 1.5) : 0.0;
    final isComplete = hasGoal && progress >= goal.targetAmount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: isComplete
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.25),
                  AppTheme.accentBlue.withOpacity(0.15),
                ],
              )
            : null,
        boxShadow: [
          if (isComplete)
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: hasGoal ? AppTheme.cardBackground : AppTheme.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isComplete
                ? AppTheme.primaryGreen.withOpacity(0.5)
                : hasGoal
                    ? AppTheme.primaryGreen.withOpacity(0.2)
                    : AppTheme.cardBackgroundLight,
            width: isComplete ? 2 : 1,
          ),
        ),
      child: Column(
        children: [
          // Header row
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: hasGoal
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.3),
                          AppTheme.accentBlue.withOpacity(0.2),
                        ],
                      )
                    : null,
                color: hasGoal ? null : AppTheme.cardBackgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: hasGoal
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                type.icon,
                color: hasGoal ? AppTheme.primaryGreen : AppTheme.textMuted,
                size: 24,
              ),
            ),
            title: Text(
              type.displayName,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isComplete ? AppTheme.primaryGreen : AppTheme.textPrimary,
              ),
            ),
            subtitle: hasGoal
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${_currencyFormat.format(goal.targetAmount)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.stars,
                                  color: AppTheme.accentYellow, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Crushing it!',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.accentYellow,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (progressPercent > 0.7)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Almost there! 🔥',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (progressPercent > 0.4)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Making progress 💪',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  )
                : Text(
                    'Tap to set your target',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
            trailing: hasGoal
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete)
                        Icon(Icons.check_circle,
                            color: AppTheme.primaryGreen, size: 20),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppTheme.textSecondary,
                        onPressed: () => _editGoal(goal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppTheme.textMuted,
                        onPressed: () => _deleteGoal(goal),
                      ),
                    ],
                  )
                : TextButton(
                    onPressed: () => _createGoal(type, jobId),
                    child: const Text('SET GOAL'),
                  ),
          ),

          // Progress section (only if goal exists)
          if (hasGoal) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.cardBackgroundLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete
                            ? AppTheme.primaryGreen
                            : AppTheme.accentBlue,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currencyFormat.format(progress),
                        style: AppTheme.titleMedium.copyWith(
                          color: isComplete
                              ? AppTheme.primaryGreen
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: AppTheme.bodyLarge.copyWith(
                          color: isComplete
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isComplete) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.celebration,
                              color: AppTheme.primaryGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Goal reached!',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createGoal(GoalType type, String? jobId) async {
    final controller = TextEditingController(
      text: type.defaultAmount.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Set ${type.displayName} Goal', style: AppTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Target amount (e.g., 1000.00)',
                prefixText: '\$',
                filled: true,
                fillColor: AppTheme.cardBackgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getGoalHint(type),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context, amount);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set Goal'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _db.createGoal(
          type: type.name,
          targetAmount: result,
          jobId: jobId,
        );
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _editGoal(Goal goal) async {
    final controller = TextEditingController(
      text: goal.targetAmount.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Edit ${goal.type} Goal', style: AppTheme.titleLarge),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Target amount (e.g., 1000.00)',
            prefixText: '\$',
            filled: true,
            fillColor: AppTheme.cardBackgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context, amount);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _db.updateGoal(goal.id, {'target_amount': result});
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete Goal?'),
        content: Text(
          'Remove your ${goal.type} goal of ${_currencyFormat.format(goal.targetAmount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteGoal(goal.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting goal: $e')),
          );
        }
      }
    }
  }

  String _getGoalHint(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return 'How much do you want to earn each day?';
      case GoalType.weekly:
        return 'Track your weekly earnings (Mon-Sun)';
      case GoalType.monthly:
        return 'Set your monthly income target';
      case GoalType.yearly:
        return 'Your annual income goal';
    }
  }
}
