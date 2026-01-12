import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../services/database_service.dart';
import '../services/google_calendar_service.dart';
import '../theme/app_theme.dart';
import 'single_shift_detail_screen.dart';

/// Enhanced All Shifts Screen with filtering, search, and bulk operations
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

  // Jobs data
  List<Map<String, dynamic>> _jobs = [];

  // Filter state
  bool _isFilterExpanded = false;
  String _selectedDateFilter = 'all';
  String? _selectedJobFilter;
  String _sortBy = 'newest';
  String _searchQuery = '';

  // Selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedShiftIds = {};

  // Loading states
  bool _isProcessingBulk = false;

  // Date filter options
  final List<Map<String, String>> _dateFilters = [
    {'value': 'all', 'label': 'All Time'},
    {'value': 'today', 'label': 'Today'},
    {'value': 'this_week', 'label': 'This Week'},
    {'value': 'this_month', 'label': 'This Month'},
    {'value': 'last_month', 'label': 'Last Month'},
    {'value': 'this_year', 'label': 'This Year'},
    {'value': 'last_year', 'label': 'Last Year'},
  ];

  // Sort options
  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'oldest', 'label': 'Oldest First'},
    {'value': 'highest_pay', 'label': 'Highest Pay'},
    {'value': 'lowest_pay', 'label': 'Lowest Pay'},
    {'value': 'longest', 'label': 'Longest Shift'},
    {'value': 'shortest', 'label': 'Shortest Shift'},
    {'value': 'most_tips', 'label': 'Most Tips'},
    {'value': 'highest_hourly', 'label': 'Highest Hourly'},
  ];

  @override
  void initState() {
    super.initState();
    _loadJobs();
    // If we came from a specific job, set that filter
    if (widget.selectedJobId != null) {
      _selectedJobFilter = widget.selectedJobId;
    }
  }

  Future<void> _loadJobs() async {
    final jobs = await _db.getJobs();
    setState(() {
      _jobs = jobs;
    });
  }

  List<Shift> _getFilteredShifts(List<Shift> allShifts) {
    var filtered = List<Shift>.from(allShifts);

    // Apply job filter
    if (_selectedJobFilter != null) {
      filtered = filtered.where((s) => s.jobId == _selectedJobFilter).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    switch (_selectedDateFilter) {
      case 'today':
        filtered = filtered
            .where((s) =>
                s.date.year == now.year &&
                s.date.month == now.month &&
                s.date.day == now.day)
            .toList();
        break;
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        filtered = filtered
            .where((s) =>
                s.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                s.date.isBefore(weekEnd.add(const Duration(days: 1))))
            .toList();
        break;
      case 'this_month':
        filtered = filtered
            .where((s) => s.date.year == now.year && s.date.month == now.month)
            .toList();
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1);
        filtered = filtered
            .where((s) =>
                s.date.year == lastMonth.year &&
                s.date.month == lastMonth.month)
            .toList();
        break;
      case 'this_year':
        filtered = filtered.where((s) => s.date.year == now.year).toList();
        break;
      case 'last_year':
        filtered = filtered.where((s) => s.date.year == now.year - 1).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        final jobName = _getJobName(s.jobId)?.toLowerCase() ?? '';
        final eventName = s.eventName?.toLowerCase() ?? '';
        final notes = s.notes?.toLowerCase() ?? '';
        final location = s.location?.toLowerCase() ?? '';
        final client = s.clientName?.toLowerCase() ?? '';
        final dateStr = DateFormat('MMM d, yyyy').format(s.date).toLowerCase();

        return jobName.contains(query) ||
            eventName.contains(query) ||
            notes.contains(query) ||
            location.contains(query) ||
            client.contains(query) ||
            dateStr.contains(query);
      }).toList();
    }

    // Apply sort
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'highest_pay':
        filtered.sort((a, b) => b.totalIncome.compareTo(a.totalIncome));
        break;
      case 'lowest_pay':
        filtered.sort((a, b) => a.totalIncome.compareTo(b.totalIncome));
        break;
      case 'longest':
        filtered.sort((a, b) => b.hoursWorked.compareTo(a.hoursWorked));
        break;
      case 'shortest':
        filtered.sort((a, b) => a.hoursWorked.compareTo(b.hoursWorked));
        break;
      case 'most_tips':
        filtered.sort((a, b) =>
            (b.cashTips + b.creditTips).compareTo(a.cashTips + a.creditTips));
        break;
      case 'highest_hourly':
        filtered.sort((a, b) {
          final aHourly = a.hoursWorked > 0 ? a.totalIncome / a.hoursWorked : 0;
          final bHourly = b.hoursWorked > 0 ? b.totalIncome / b.hoursWorked : 0;
          return bHourly.compareTo(aHourly);
        });
        break;
    }

    return filtered;
  }

  String? _getJobName(String? jobId) {
    if (jobId == null) return null;
    final job = _jobs.firstWhere(
      (j) => j['id'] == jobId,
      orElse: () => {},
    );
    return job.isNotEmpty ? job['name'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final filteredShifts = _getFilteredShifts(shiftProvider.shifts);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          _isSelectionMode
              ? '${_selectedShiftIds.length} Selected'
              : (widget.jobTitle != null
                  ? '${widget.jobTitle} Shifts'
                  : 'All Shifts'),
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        elevation: 0,
        actions: [
          // Selection mode toggle
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.check_box_outline_blank,
              color: _isSelectionMode
                  ? AppTheme.dangerColor
                  : AppTheme.headerIconColor,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _selectedShiftIds.clear();
                }
              });
            },
            tooltip: _isSelectionMode ? 'Cancel Selection' : 'Select Multiple',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search shifts...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isFilterExpanded ? Icons.expand_less : Icons.tune,
                      color: AppTheme.primaryGreen,
                    ),
                    onPressed: () {
                      setState(() => _isFilterExpanded = !_isFilterExpanded);
                    },
                  ),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: AppTheme.bodyMedium,
              ),
            ),

            // Collapsible filter section
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildFilterSection(),
              crossFadeState: _isFilterExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            // Selection controls and bulk actions (when in selection mode)
            if (_isSelectionMode) _buildSelectionControls(filteredShifts),

            // Bulk actions bar (when items selected)
            if (_isSelectionMode && _selectedShiftIds.isNotEmpty)
              _buildBulkActionsBar(),

            // Shift count and sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredShifts.length} shift${filteredShifts.length == 1 ? '' : 's'}',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  PopupMenuButton<String>(
                    initialValue: _sortBy,
                    onSelected: (value) => setState(() => _sortBy = value),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sortOptions.firstWhere(
                              (o) => o['value'] == _sortBy)['label']!,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.primaryGreen),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: AppTheme.primaryGreen, size: 20),
                      ],
                    ),
                    itemBuilder: (context) => _sortOptions
                        .map((option) => PopupMenuItem<String>(
                              value: option['value'],
                              child: Text(option['label']!),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Shifts list
            Expanded(
              child: filteredShifts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredShifts.length,
                      itemBuilder: (context, index) {
                        final shift = filteredShifts[index];
                        return _buildShiftCard(shift);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Date filter
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDateFilter,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: AppTheme.cardBackground,
                  style: AppTheme.bodyMedium,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDateFilter = value);
                    }
                  },
                  items: _dateFilters
                      .map((filter) => DropdownMenuItem<String>(
                            value: filter['value'],
                            child: Text(filter['label']!),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 12),
              // Job filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedJobFilter,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: AppTheme.cardBackground,
                  style: AppTheme.bodyMedium,
                  onChanged: (value) =>
                      setState(() => _selectedJobFilter = value),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Jobs'),
                    ),
                    ..._jobs.map((job) => DropdownMenuItem<String?>(
                          value: job['id'] as String,
                          child: Text(job['name'] as String),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Clear filters button
          if (_selectedDateFilter != 'all' || _selectedJobFilter != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDateFilter = 'all';
                    _selectedJobFilter = null;
                    _searchQuery = '';
                  });
                },
                icon: Icon(Icons.clear_all,
                    size: 18, color: AppTheme.textSecondary),
                label: Text('Clear Filters',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls(List<Shift> shifts) {
    final allSelected = shifts.isNotEmpty &&
        shifts.every((s) => _selectedShiftIds.contains(s.id));
    final someSelected = _selectedShiftIds.isNotEmpty;

    String selectionText;
    if (_selectedShiftIds.isEmpty) {
      selectionText = '${shifts.length} shifts found';
    } else if (allSelected) {
      selectionText = 'All ${shifts.length} selected';
    } else {
      selectionText = '${_selectedShiftIds.length} / ${shifts.length} selected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectionText,
            style: AppTheme.bodyMedium.copyWith(
              color:
                  someSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
              fontWeight: someSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    for (final shift in shifts) {
                      _selectedShiftIds.add(shift.id);
                    }
                  });
                },
                child: Text(
                  'Select All',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
              ),
              if (someSelected)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedShiftIds.clear());
                  },
                  child: Text(
                    'Deselect All',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
          bottom: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          if (_isProcessingBulk)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          Text(
            _isProcessingBulk
                ? 'Processing...'
                : '${_selectedShiftIds.length} selected',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
          const Spacer(),
          // Bulk Actions Dropdown
          IgnorePointer(
            ignoring: _isProcessingBulk,
            child: Opacity(
              opacity: _isProcessingBulk ? 0.5 : 1.0,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _showDeleteConfirmation();
                      break;
                    case 'export':
                      _showExportOptions();
                      break;
                    case 'change_job':
                      _showChangeJobDialog();
                      break;
                    case 'move_date':
                      _showMoveDateDialog();
                      break;
                    case 'adjust_pay':
                      _showAdjustPayDialog();
                      break;
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Actions',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            color: AppTheme.dangerColor, size: 20),
                        const SizedBox(width: 12),
                        Text('Delete',
                            style: TextStyle(color: AppTheme.dangerColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download,
                            color: AppTheme.accentBlue, size: 20),
                        const SizedBox(width: 12),
                        const Text('Export'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'change_job',
                    child: Row(
                      children: [
                        Icon(Icons.work,
                            color: AppTheme.accentPurple, size: 20),
                        const SizedBox(width: 12),
                        const Text('Change Job'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'move_date',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: AppTheme.accentOrange, size: 20),
                        const SizedBox(width: 12),
                        const Text('Move Date'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'adjust_pay',
                    child: Row(
                      children: [
                        Icon(Icons.attach_money,
                            color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 12),
                        const Text('Adjust Pay'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            _searchQuery.isNotEmpty ||
                    _selectedDateFilter != 'all' ||
                    _selectedJobFilter != null
                ? 'No shifts match your filters'
                : 'No shifts recorded yet',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
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

  Widget _buildShiftCard(Shift shift) {
    final isSelected = _selectedShiftIds.contains(shift.id);

    // Get job name and employer
    String jobName = 'Shift';
    String? employer;
    if (shift.jobId != null && _jobs.isNotEmpty) {
      final job = _jobs.firstWhere(
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isSelected
            ? Border.all(color: AppTheme.primaryGreen, width: 2)
            : null,
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
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedShiftIds.remove(shift.id);
                } else {
                  _selectedShiftIds.add(shift.id);
                }
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SingleShiftDetailScreen(shift: shift),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox (in selection mode)
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedShiftIds.add(shift.id);
                          } else {
                            _selectedShiftIds.remove(shift.id);
                          }
                        });
                      },
                      activeColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.textMuted),
                    ),
                  ),
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
                        DateFormat('E').format(shift.date),
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
                        shift.date.year == DateTime.now().year
                            ? DateFormat('MMM').format(shift.date)
                            : DateFormat("MMM ''yy").format(shift.date),
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
                // Shift Info - Matches Dashboard Recent Shifts EXACTLY
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

                        // Employer badge
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
                        Widget? detailWidget;
                        if (shift.startTime?.isNotEmpty == true &&
                            shift.endTime?.isNotEmpty == true) {
                          // Format times to ensure 12-hour format
                          String formatTime(String time) {
                            if (time.toUpperCase().contains('AM') ||
                                time.toUpperCase().contains('PM')) {
                              return time;
                            }
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
                              return time;
                            }
                            return time;
                          }

                          detailWidget = Text(
                            '${formatTime(shift.startTime!)} - ${formatTime(shift.endTime!)}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        } else if (shift.guestCount != null &&
                            shift.guestCount! > 0) {
                          detailWidget = Text(
                            '${shift.guestCount} guests',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        } else if (shift.location?.isNotEmpty == true) {
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

                        // Add notes row if present (full width)
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

  // ============================================
  // BULK ACTIONS
  // ============================================

  Future<void> _showDeleteConfirmation() async {
    final selectedShifts = Provider.of<ShiftProvider>(context, listen: false)
        .shifts
        .where((s) => _selectedShiftIds.contains(s.id))
        .toList();

    final totalEarnings =
        selectedShifts.fold<double>(0, (sum, s) => sum + s.totalIncome);

    // Check if any shifts have calendar sync
    final hasCalendarSynced =
        selectedShifts.any((s) => s.calendarEventId != null);

    String? deleteOption = 'app_only';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Delete ${_selectedShiftIds.length} Shifts?',
            style: AppTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total earnings: ${currencyFormat.format(totalEarnings)}',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (hasCalendarSynced) ...[
                Text(
                  'Some shifts are synced to calendar:',
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title:
                      Text('Delete from app only', style: AppTheme.bodyMedium),
                  subtitle: Text('Keep events in calendar',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.textMuted)),
                  value: 'app_only',
                  groupValue: deleteOption,
                  onChanged: (value) =>
                      setDialogState(() => deleteOption = value),
                  activeColor: AppTheme.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: Text('Delete from app & calendar',
                      style: AppTheme.bodyMedium),
                  subtitle: Text('Remove everywhere',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.textMuted)),
                  value: 'both',
                  groupValue: deleteOption,
                  onChanged: (value) =>
                      setDialogState(() => deleteOption = value),
                  activeColor: AppTheme.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style:
                    AppTheme.labelSmall.copyWith(color: AppTheme.dangerColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _executeBulkDelete(deleteOption == 'both');
    }
  }

  Future<void> _executeBulkDelete(bool deleteFromCalendar) async {
    setState(() => _isProcessingBulk = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final shiftsToDelete = shiftProvider.shifts
          .where((s) => _selectedShiftIds.contains(s.id))
          .toList();

      int deletedCount = 0;
      int calendarDeletedCount = 0;

      for (final shift in shiftsToDelete) {
        // Delete from calendar if requested and shift has calendar event
        if (deleteFromCalendar && shift.calendarEventId != null) {
          try {
            final googleCalendarService = GoogleCalendarService();
            await googleCalendarService
                .deleteCalendarEvent(shift.calendarEventId!);
            calendarDeletedCount++;
          } catch (e) {
            print('Failed to delete calendar event: $e');
          }
        }

        // Delete shift from database
        await _db.deleteShift(shift.id);
        deletedCount++;
      }

      // Reload shifts
      await shiftProvider.loadShifts();

      // Clear selection
      setState(() {
        _selectedShiftIds.clear();
        _isSelectionMode = false;
        _isProcessingBulk = false;
      });

      if (mounted) {
        String message =
            'Deleted $deletedCount shift${deletedCount == 1 ? '' : 's'}';
        if (calendarDeletedCount > 0) {
          message += ' ($calendarDeletedCount removed from calendar)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingBulk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _showExportOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export ${_selectedShiftIds.length} Shifts',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.table_chart, color: AppTheme.primaryGreen),
                ),
                title: Text('Export as CSV', style: AppTheme.bodyMedium),
                subtitle:
                    Text('For Excel/Google Sheets', style: AppTheme.labelSmall),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: AppTheme.accentRed),
                ),
                title: Text('Export as PDF', style: AppTheme.bodyMedium),
                subtitle: Text('Formatted report', style: AppTheme.labelSmall),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == 'csv') {
      await _exportToCsv();
    } else if (choice == 'pdf') {
      await _exportToPdf();
    }
  }

  Future<void> _exportToCsv() async {
    setState(() => _isProcessingBulk = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final shiftsToExport = shiftProvider.shifts
          .where((s) => _selectedShiftIds.contains(s.id))
          .toList();

      // Sort by date
      shiftsToExport.sort((a, b) => a.date.compareTo(b.date));

      // Build CSV data
      final List<List<dynamic>> csvData = [
        // Header row
        [
          'Date',
          'Job',
          'Event',
          'Hours',
          'Hourly Rate',
          'Base Pay',
          'Cash Tips',
          'Card Tips',
          'Total Income',
          'Location',
          'Notes'
        ],
        // Data rows
        ...shiftsToExport.map((s) => [
              DateFormat('yyyy-MM-dd').format(s.date),
              _getJobName(s.jobId) ?? s.jobType ?? '',
              s.eventName ?? '',
              s.hoursWorked.toStringAsFixed(2),
              s.hourlyRate.toStringAsFixed(2),
              (s.hourlyRate * s.hoursWorked).toStringAsFixed(2),
              s.cashTips.toStringAsFixed(2),
              s.creditTips.toStringAsFixed(2),
              s.totalIncome.toStringAsFixed(2),
              s.location ?? '',
              s.notes ?? '',
            ]),
      ];

      final csv = const ListToCsvConverter().convert(csvData);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'shifts_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csv);

      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Shift Export');

      setState(() => _isProcessingBulk = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${shiftsToExport.length} shifts to CSV'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingBulk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    setState(() => _isProcessingBulk = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final shiftsToExport = shiftProvider.shifts
          .where((s) => _selectedShiftIds.contains(s.id))
          .toList();

      // Sort by date
      shiftsToExport.sort((a, b) => a.date.compareTo(b.date));

      // Calculate totals
      final totalIncome =
          shiftsToExport.fold<double>(0, (sum, s) => sum + s.totalIncome);
      final totalHours =
          shiftsToExport.fold<double>(0, (sum, s) => sum + s.hoursWorked);
      final totalCashTips =
          shiftsToExport.fold<double>(0, (sum, s) => sum + s.cashTips);
      final totalCreditTips =
          shiftsToExport.fold<double>(0, (sum, s) => sum + s.creditTips);

      // Build PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text('Shift Export Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
                'Generated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}'),
            pw.Text('Total Shifts: ${shiftsToExport.length}'),
            pw.SizedBox(height: 16),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Total Income', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('\$${totalIncome.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Hours', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('${totalHours.toStringAsFixed(1)}h',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Tips', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        '\$${(totalCashTips + totalCreditTips).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Job', 'Hours', 'Income'],
              data: shiftsToExport
                  .map((s) => [
                        DateFormat('MM/dd/yy').format(s.date),
                        _getJobName(s.jobId) ?? s.jobType ?? 'Shift',
                        '${s.hoursWorked.toStringAsFixed(1)}h',
                        '\$${s.totalIncome.toStringAsFixed(2)}',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(4),
            ),
          ],
        ),
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'shifts_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Shift Report');

      setState(() => _isProcessingBulk = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${shiftsToExport.length} shifts to PDF'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingBulk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _showChangeJobDialog() async {
    final selectedShifts = Provider.of<ShiftProvider>(context, listen: false)
        .shifts
        .where((s) => _selectedShiftIds.contains(s.id))
        .toList();

    // Count current job distribution
    final jobCounts = <String?, int>{};
    for (final shift in selectedShifts) {
      final key = shift.jobId ?? 'none';
      jobCounts[key] = (jobCounts[key] ?? 0) + 1;
    }

    String? newJobId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Change Job for ${_selectedShiftIds.length} Shifts',
            style: AppTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Distribution:',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...jobCounts.entries.map((entry) {
                final jobName = entry.key == 'none'
                    ? 'No job assigned'
                    : _getJobName(entry.key) ?? 'Unknown';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $jobName: ${entry.value} shifts',
                    style:
                        AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text('Assign to:',
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: newJobId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardBackgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: AppTheme.cardBackground,
                hint: Text('Select job',
                    style: TextStyle(color: AppTheme.textMuted)),
                onChanged: (value) => setDialogState(() => newJobId = value),
                items: _jobs
                    .map((job) => DropdownMenuItem<String?>(
                          value: job['id'] as String,
                          child: Text(job['name'] as String),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  newJobId == null ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && newJobId != null) {
      await _executeBulkChangeJob(newJobId!);
    }
  }

  Future<void> _executeBulkChangeJob(String newJobId) async {
    setState(() => _isProcessingBulk = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);

      for (final shiftId in _selectedShiftIds) {
        await _db.supabase
            .from('shifts')
            .update({'job_id': newJobId}).eq('id', shiftId);
      }

      await shiftProvider.loadShifts();

      setState(() {
        _selectedShiftIds.clear();
        _isSelectionMode = false;
        _isProcessingBulk = false;
      });

      if (mounted) {
        final jobName = _getJobName(newJobId) ?? 'Unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Changed ${_selectedShiftIds.length} shifts to "$jobName"'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingBulk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change job: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _showMoveDateDialog() async {
    DateTime? newDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Move ${_selectedShiftIds.length} Shifts',
            style: AppTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Move all selected shifts to a new date.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() => newDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  newDate != null
                      ? DateFormat('MMM d, yyyy').format(newDate!)
                      : 'Select Date',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardBackgroundLight,
                  foregroundColor: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  newDate == null ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && newDate != null) {
      await _executeBulkMoveDate(newDate!);
    }
  }

  Future<void> _executeBulkMoveDate(DateTime newDate) async {
    setState(() => _isProcessingBulk = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);

      for (final shiftId in _selectedShiftIds) {
        await _db.supabase
            .from('shifts')
            .update({'date': newDate.toIso8601String().split('T')[0]}).eq(
                'id', shiftId);
      }

      await shiftProvider.loadShifts();

      final count = _selectedShiftIds.length;
      setState(() {
        _selectedShiftIds.clear();
        _isSelectionMode = false;
        _isProcessingBulk = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Moved $count shifts to ${DateFormat('MMM d, yyyy').format(newDate)}'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingBulk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move shifts: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _showAdjustPayDialog() async {
    final selectedShifts = Provider.of<ShiftProvider>(context, listen: false)
        .shifts
        .where((s) => _selectedShiftIds.contains(s.id))
        .toList();

    final currentTotal =
        selectedShifts.fold<double>(0, (sum, s) => sum + s.totalIncome);

    String adjustType = 'add';
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Adjust Pay for ${_selectedShiftIds.length} Shifts',
            style: AppTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Total: ${currencyFormat.format(currentTotal)}',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Add', style: AppTheme.bodySmall),
                      value: 'add',
                      groupValue: adjustType,
                      onChanged: (v) => setDialogState(() => adjustType = v!),
                      activeColor: AppTheme.primaryGreen,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Multiply', style: AppTheme.bodySmall),
                      value: 'multiply',
                      groupValue: adjustType,
                      onChanged: (v) => setDialogState(() => adjustType = v!),
                      activeColor: AppTheme.primaryGreen,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: adjustType == 'add'
                      ? 'Amount to add (\$)'
                      : 'Multiply by',
                  hintText: adjustType == 'add'
                      ? 'e.g., 50'
                      : 'e.g., 1.1 for 10% increase',
                  filled: true,
                  fillColor: AppTheme.cardBackgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && amountController.text.isNotEmpty) {
      final amount = double.tryParse(amountController.text);
      if (amount != null) {
        await _executeBulkAdjustPay(adjustType, amount);
      }
    }
  }

  Future<void> _executeBulkAdjustPay(String adjustType, double amount) async {
    setState(() => _isProcessingBulk = true);

    try {
      final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
      final shiftsToUpdate = shiftProvider.shifts
          .where((s) => _selectedShiftIds.contains(s.id))
          .toList();

      for (final shift in shiftsToUpdate) {
        double newHourlyRate;
        if (adjustType == 'add') {
          // Add amount to the effective base pay by adjusting hourly rate
          newHourlyRate = shift.hourlyRate +
              (shift.hoursWorked > 0 ? amount / shift.hoursWorked : 0);
        } else {
          newHourlyRate = shift.hourlyRate * amount;
        }

        await _db.supabase
            .from('shifts')
            .update({'hourly_rate': newHourlyRate}).eq('id', shift.id);
      }

      await shiftProvider.loadShifts();

      final count = _selectedShiftIds.length;
      setState(() {
        _selectedShiftIds.clear();
        _isSelectionMode = false;
        _isProcessingBulk = false;
      });

      if (mounted) {
        String message;
        if (adjustType == 'add') {
          message = 'Added \$${amount.toStringAsFixed(2)} to $count shifts';
        } else {
          message = 'Multiplied pay by ${amount}x for $count shifts';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingBulk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to adjust pay: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }
}
