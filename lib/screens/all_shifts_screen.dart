import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'single_shift_detail_screen.dart';

class AllShiftsScreen extends StatefulWidget {
  final String? selectedJobId;
  final String? jobTitle;

  const AllShiftsScreen({
    super.key,
    this.selectedJobId,
    this.jobTitle,
  });

  @override
  State<AllShiftsScreen> createState() => _AllShiftsScreenState();
}

class _AllShiftsScreenState extends State<AllShiftsScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _db = DatabaseService();
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final jobs = await _db.getJobs();
    setState(() {
      _jobs = jobs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context);

    // Filter shifts based on selected job
    final filteredShifts = widget.selectedJobId == null
        ? shiftProvider.shifts
        : shiftProvider.shifts
            .where((shift) => shift.jobId == widget.selectedJobId)
            .toList();

    // Sort shifts by date (most recent first)
    filteredShifts.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          widget.jobTitle != null ? '${widget.jobTitle} Shifts' : 'All Shifts',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: filteredShifts.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: filteredShifts.length,
                itemBuilder: (context, index) {
                  final shift = filteredShifts[index];
                  return _buildShiftCard(context, shift, _jobs);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No shifts recorded yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your shifts to see them here',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(
      BuildContext context, Shift shift, List<Map<String, dynamic>> jobs) {
    // Get the job name from the jobs list
    String jobName = 'Shift';
    String? employer;
    if (shift.jobId != null && jobs.isNotEmpty) {
      final job = jobs.firstWhere(
        (j) => j['id'] == shift.jobId,
        orElse: () => {},
      );
      if (job.isNotEmpty && job['name'] != null) {
        jobName = job['name'] as String;
        employer = job['employer'] as String?;
      }
    } else if (shift.jobType != null && shift.jobType!.isNotEmpty) {
      jobName = shift.jobType!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SingleShiftDetailScreen(shift: shift),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Badge
                Container(
                  width: 56,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(shift.date).toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('d').format(shift.date),
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        DateFormat('y').format(shift.date),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primaryGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Shift Info - Left and Right Columns with Dynamic Row Stacking
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Job Title + Dollar Amount (always first)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              jobName,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            shift.totalIncome == 0
                                ? '\$0'
                                : currencyFormat.format(shift.totalIncome),
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      // Dynamic rows below
                      ...() {
                        final List<Widget> leftItems = [];
                        // Event badge
                        if (shift.eventName?.isNotEmpty == true) {
                          leftItems.add(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.accentPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        AppTheme.accentPurple.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 10,
                                      color: AppTheme.accentPurple,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      shift.eventName!,
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.accentPurple,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Add guest count if available
                                    if (shift.guestCount != null &&
                                        shift.guestCount! > 0) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.people,
                                        size: 10,
                                        color: AppTheme.accentPurple,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${shift.guestCount}',
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.accentPurple,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        // Employer badge (moved here)
                        if (employer?.isNotEmpty == true) {
                          leftItems.add(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.accentBlue.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 10,
                                      color: AppTheme.accentBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        employer!,
                                        style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.accentBlue,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Hours display (for Event badge row)
                        final hoursWidget = Text(
                          '${shift.hoursWorked.toStringAsFixed(1)} hrs',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        );

                        // Smart detail display - Priority: Time Range > Guest Count > Location
                        // (for Employer badge row)
                        Widget? detailWidget;
                        if (shift.startTime?.isNotEmpty == true &&
                            shift.endTime?.isNotEmpty == true) {
                          // Format times to ensure 12-hour format
                          String formatTime(String time) {
                            // If already has AM/PM, return as is
                            if (time.toUpperCase().contains('AM') ||
                                time.toUpperCase().contains('PM')) {
                              return time;
                            }
                            // Otherwise parse and format to 12-hour
                            try {
                              final parts = time.split(':');
                              if (parts.length >= 2) {
                                int hour = int.parse(parts[0]);
                                final minute = parts[1];
                                final period = hour >= 12 ? 'PM' : 'AM';
                                if (hour > 12) hour -= 12;
                                if (hour == 0) hour = 12;
                                return '$hour:$minute $period';
                              }
                            } catch (e) {
                              // If parsing fails, return original
                              return time;
                            }
                            return time;
                          }

                          // Show time range
                          detailWidget = Text(
                            '${formatTime(shift.startTime!)} - ${formatTime(shift.endTime!)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        } else if (shift.guestCount != null &&
                            shift.guestCount! > 0) {
                          // Show guest count
                          detailWidget = Text(
                            '${shift.guestCount} guests',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        } else if (shift.location?.isNotEmpty == true) {
                          // Show location
                          detailWidget = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 10,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  shift.location!,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }

                        // Build rows for Event badge and Employer badge
                        final rows = <Widget>[];

                        // Add rows for left items with appropriate details on the right
                        for (int i = 0; i < leftItems.length; i++) {
                          Widget? rightWidget;
                          if (i == 0) {
                            // First row (Event badge) - show hours
                            rightWidget = hoursWidget;
                          } else if (i == 1 && detailWidget != null) {
                            // Second row (Employer badge) - show smart detail
                            rightWidget = detailWidget;
                          }

                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: leftItems[i]),
                                  const SizedBox(width: 12),
                                  if (rightWidget != null) rightWidget,
                                ],
                              ),
                            ),
                          );
                        }

                        // Add notes row if present (full width, wrapping allowed)
                        if (shift.notes?.isNotEmpty == true) {
                          rows.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                shift.notes!,
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          );
                        }

                        return rows;
                      }(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
