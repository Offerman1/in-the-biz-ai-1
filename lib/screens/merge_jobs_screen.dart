import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Screen to merge multiple existing jobs into one.
/// This allows users to combine duplicate jobs (e.g., "Catering" and "CATERING")
/// and reassign all shifts to the merged job.
class MergeJobsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> jobs; // All user's jobs

  const MergeJobsScreen({
    super.key,
    required this.jobs,
  });

  @override
  State<MergeJobsScreen> createState() => _MergeJobsScreenState();
}

class _MergeJobsScreenState extends State<MergeJobsScreen> {
  final Set<String> _selectedJobIds = {};
  final DatabaseService _db = DatabaseService();
  Map<String, int> _shiftCounts = {}; // job_id -> shift count
  bool _isLoading = true;
  bool _isMerging = false;

  @override
  void initState() {
    super.initState();
    _loadShiftCounts();
  }

  Future<void> _loadShiftCounts() async {
    try {
      final counts = <String, int>{};
      for (final job in widget.jobs) {
        final jobId = job['id'] as String;
        final count = await _db.getShiftCountForJob(jobId);
        counts[jobId] = count;
      }
      setState(() {
        _shiftCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading shift counts: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
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
          'Merge Jobs',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : Column(
                children: [
                  // Header explanation
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
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
                            Icon(Icons.merge_type,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Text('Merge Duplicate Jobs',
                                style: AppTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select 2 or more jobs to merge together. All shifts from the selected jobs will be moved to a single job.',
                          style: AppTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),

                  // Jobs list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.jobs.length,
                      itemBuilder: (context, index) {
                        final job = widget.jobs[index];
                        final jobId = job['id'] as String;
                        final jobName = job['name'] as String? ?? 'Unknown';
                        final employer = job['employer'] as String?;
                        final shiftCount = _shiftCounts[jobId] ?? 0;
                        final isSelected = _selectedJobIds.contains(jobId);
                        final isDefault = job['is_default'] == true;

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
                                  _selectedJobIds.add(jobId);
                                } else {
                                  _selectedJobIds.remove(jobId);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    jobName,
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.primaryGreen,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (employer != null && employer.isNotEmpty)
                                  Text(
                                    employer,
                                    style: AppTheme.labelSmall.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                Text(
                                  '$shiftCount ${shiftCount == 1 ? 'shift' : 'shifts'}',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
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
                    child: Column(
                      children: [
                        if (_selectedJobIds.length >= 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${_selectedJobIds.length} jobs selected - ${_getTotalShiftCount()} shifts will be merged',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textMuted,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _selectedJobIds.length >= 2 && !_isMerging
                                        ? _showMergeDialog
                                        : null,
                                icon: _isMerging
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.merge_type),
                                label: Text(_selectedJobIds.length >= 2
                                    ? 'Merge ${_selectedJobIds.length} Jobs'
                                    : 'Select 2+ Jobs'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppTheme.primaryGreen.withOpacity(0.3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  int _getTotalShiftCount() {
    int total = 0;
    for (final jobId in _selectedJobIds) {
      total += _shiftCounts[jobId] ?? 0;
    }
    return total;
  }

  Future<void> _showMergeDialog() async {
    // Get selected jobs for display
    final selectedJobs =
        widget.jobs.where((j) => _selectedJobIds.contains(j['id'])).toList();

    // Pre-fill with the job that has the most shifts
    String bestJobId = selectedJobs.first['id'];
    int maxShifts = _shiftCounts[bestJobId] ?? 0;
    for (final job in selectedJobs) {
      final count = _shiftCounts[job['id']] ?? 0;
      if (count > maxShifts) {
        maxShifts = count;
        bestJobId = job['id'];
      }
    }
    final bestJob = selectedJobs.firstWhere((j) => j['id'] == bestJobId);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MergeJobDialog(
        selectedJobs: selectedJobs,
        shiftCounts: _shiftCounts,
        suggestedJob: bestJob,
      ),
    );

    if (result != null && mounted) {
      await _performMerge(result);
    }
  }

  Future<void> _performMerge(Map<String, dynamic> mergeConfig) async {
    setState(() => _isMerging = true);

    try {
      final targetJobId = mergeConfig['targetJobId'] as String;
      final newName = mergeConfig['newName'] as String;
      final newEmployer = mergeConfig['newEmployer'] as String?;
      final newRate = mergeConfig['newRate'] as double?;

      // Get all job IDs to merge (excluding the target)
      final jobsToMerge =
          _selectedJobIds.where((id) => id != targetJobId).toList();

      // Perform the merge
      await _db.mergeJobs(
        targetJobId: targetJobId,
        sourceJobIds: jobsToMerge,
        newName: newName,
        newEmployer: newEmployer,
        newRate: newRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully merged ${_selectedJobIds.length} jobs into "$newName"',
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate merge was done
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error merging jobs: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMerging = false);
      }
    }
  }
}

/// Dialog to configure the merge (choose name, rate, etc.)
class _MergeJobDialog extends StatefulWidget {
  final List<Map<String, dynamic>> selectedJobs;
  final Map<String, int> shiftCounts;
  final Map<String, dynamic> suggestedJob;

  const _MergeJobDialog({
    required this.selectedJobs,
    required this.shiftCounts,
    required this.suggestedJob,
  });

  @override
  State<_MergeJobDialog> createState() => _MergeJobDialogState();
}

class _MergeJobDialogState extends State<_MergeJobDialog> {
  late TextEditingController _nameController;
  late TextEditingController _employerController;
  late TextEditingController _rateController;
  late String _selectedTargetId;

  @override
  void initState() {
    super.initState();
    _selectedTargetId = widget.suggestedJob['id'];
    _nameController = TextEditingController(
      text: widget.suggestedJob['name'] ?? '',
    );
    _employerController = TextEditingController(
      text: widget.suggestedJob['employer'] ?? '',
    );
    _rateController = TextEditingController(
      text: (widget.suggestedJob['hourly_rate'] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employerController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _selectJob(Map<String, dynamic> job) {
    setState(() {
      _selectedTargetId = job['id'];
      _nameController.text = job['name'] ?? '';
      _employerController.text = job['employer'] ?? '';
      _rateController.text = (job['hourly_rate'] ?? 0).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: Text('Configure Merge', style: AppTheme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merging ${widget.selectedJobs.length} jobs:',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),

            // List selected jobs as chips (tap to use as template)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedJobs.map((job) {
                final isSelected = job['id'] == _selectedTargetId;
                final shiftCount = widget.shiftCounts[job['id']] ?? 0;
                return InkWell(
                  onTap: () => _selectJob(job),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen.withOpacity(0.2)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.cardBackgroundLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          job['name'] ?? 'Unknown',
                          style: AppTheme.labelSmall.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$shiftCount shifts',
                          style: AppTheme.labelSmall.copyWith(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
            Text(
              'Tap a job above to use its details as a template',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              'Final Job Details:',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Job Name *',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                hintText: 'e.g., The Capital Grille - GP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _employerController,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Employer',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                hintText: 'e.g., The Capital Grille',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _rateController,
              style: AppTheme.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hourly Rate',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please enter a job name'),
                  backgroundColor: AppTheme.accentRed,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'targetJobId': _selectedTargetId,
              'newName': _nameController.text.trim(),
              'newEmployer': _employerController.text.trim().isEmpty
                  ? null
                  : _employerController.text.trim(),
              'newRate': double.tryParse(_rateController.text),
            });
          },
          icon: const Icon(Icons.merge_type, size: 18),
          label: const Text('Merge Jobs'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
