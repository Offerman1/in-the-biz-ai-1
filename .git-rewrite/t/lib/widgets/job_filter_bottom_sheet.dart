import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

class JobFilterBottomSheet extends StatelessWidget {
  final List<Job> jobs;
  final String? selectedJobId;
  final Function(String?) onJobSelected;

  const JobFilterBottomSheet({
    super.key,
    required this.jobs,
    required this.selectedJobId,
    required this.onJobSelected,
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
                'Filter by Job',
                style: AppTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Show shifts for specific job',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 20),

            // "All Jobs" option
            _buildJobOption(
              context,
              jobId: null,
              jobTitle: 'All Jobs',
              employer: 'Show all shifts',
              icon: Icons.work,
              isSelected: selectedJobId == null,
            ),

            // Divider
            if (jobs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: AppTheme.textMuted.withOpacity(0.2)),
              ),

            // Individual jobs
            ...jobs.map((job) => _buildJobOption(
                  context,
                  jobId: job.id,
                  jobTitle: job.name,
                  employer: job.employer,
                  icon: Icons.work_outline,
                  isSelected: selectedJobId == job.id,
                )),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildJobOption(
    BuildContext context, {
    required String? jobId,
    required String jobTitle,
    required String? employer,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        onJobSelected(jobId);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
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
                color: isSelected
                    ? AppTheme.primaryGreen.withOpacity(0.2)
                    : AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
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
                    jobTitle,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (employer != null && employer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      employer,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
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
