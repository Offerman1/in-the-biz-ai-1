import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/job.dart';

class JobGroupingScreen extends StatefulWidget {
  final List<Map<String, dynamic>>
      calendarTitles; // {title: String, count: int}

  const JobGroupingScreen({
    super.key,
    required this.calendarTitles,
  });

  @override
  State<JobGroupingScreen> createState() => _JobGroupingScreenState();
}

class _JobGroupingScreenState extends State<JobGroupingScreen> {
  final Set<String> _selectedTitles = {};
  final List<Map<String, dynamic>> _groups =
      []; // {name: String, titles: List<String>, job: Job?}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text('Group Your Jobs',
            style: AppTheme.titleLarge
                .copyWith(color: AppTheme.adaptiveTextColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header explanation
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Tip', style: AppTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We found ${widget.calendarTitles.length} different job titles in your calendar. Select titles that belong to the same job to group them together.',
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),

            // Created groups
            if (_groups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Groups', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    ..._groups.map((group) => _buildGroupCard(group)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: AppTheme.cardBackgroundLight),
            ],

            // Available titles
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available Titles', style: AppTheme.titleMedium),
                  if (_selectedTitles.isNotEmpty)
                    Text(
                      '${_selectedTitles.length} selected',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                ],
              ),
            ),

            // Calendar titles list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.calendarTitles.length,
                itemBuilder: (context, index) {
                  final titleData = widget.calendarTitles[index];
                  final title = titleData['title'] as String;
                  final count = titleData['count'] as int;

                  // Skip if already grouped
                  if (_groups
                      .any((g) => (g['titles'] as List).contains(title))) {
                    return const SizedBox.shrink();
                  }

                  final isSelected = _selectedTitles.contains(title);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.cardBackgroundLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedTitles.add(title);
                          } else {
                            _selectedTitles.remove(title);
                          }
                        });
                      },
                      title: Text(title, style: AppTheme.bodyMedium),
                      subtitle: Text(
                        '$count ${count == 1 ? 'shift' : 'shifts'}',
                        style: AppTheme.labelSmall,
                      ),
                      activeColor: AppTheme.primaryGreen,
                      checkColor: Colors.white,
                    ),
                  );
                },
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_selectedTitles.length >= 2)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createGroup,
                        icon: const Icon(Icons.group_work),
                        label: const Text('Create Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  if (_selectedTitles.length >= 2) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _groups.isEmpty ? null : _finishGrouping,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_groups.isEmpty ? 'Skip' : 'Continue'),
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

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] as String;
    final titles = group['titles'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppTheme.accentRed),
                onPressed: () => _deleteGroup(group),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: titles.map((title) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  title,
                  style: AppTheme.labelSmall,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_selectedTitles.length < 2) return;

    // Show dialog to name the group and create job
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GroupNamingDialog(
        selectedTitles: _selectedTitles.toList(),
      ),
    );

    if (result != null) {
      setState(() {
        _groups.add({
          'name': result['name'],
          'titles': _selectedTitles.toList(),
          'job': result['job'],
        });
        _selectedTitles.clear();
      });
    }
  }

  void _deleteGroup(Map<String, dynamic> group) {
    setState(() {
      _groups.remove(group);
    });
  }

  void _finishGrouping() {
    // Return the groups to the caller
    Navigator.of(context).pop(_groups);
  }
}

class _GroupNamingDialog extends StatefulWidget {
  final List<String> selectedTitles;

  const _GroupNamingDialog({required this.selectedTitles});

  @override
  State<_GroupNamingDialog> createState() => _GroupNamingDialogState();
}

class _GroupNamingDialogState extends State<_GroupNamingDialog> {
  final _nameController = TextEditingController();
  final _employerController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _employerController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: Text('Name This Job Group', style: AppTheme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'These titles will be grouped:',
              style: AppTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            ...widget.selectedTitles.map((title) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $title', style: AppTheme.labelSmall),
                )),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Job name (e.g., The Capital Grille - GP)',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _employerController,
              decoration: const InputDecoration(
                hintText: 'Employer (e.g., The Capital Grille)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(
                hintText: 'Hourly rate (e.g., 15.00)',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      final userId = AuthService.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Create the job with a generated UUID
      final job = Job(
        id: const Uuid().v4(), // Generate proper UUID
        userId: userId,
        name: _nameController.text.trim(),
        employer: _employerController.text.trim().isEmpty
            ? _nameController.text.trim()
            : _employerController.text.trim(),
        hourlyRate: double.tryParse(_rateController.text) ?? 0.0,
        industry: 'Restaurant',
      );

      final jobData = await db.createJob(job);

      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'job': jobData,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
