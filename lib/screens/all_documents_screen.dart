import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shift.dart';
import '../models/shift_attachment.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/document_preview_widget.dart';
import 'single_shift_detail_screen.dart';

/// All Documents Screen - Shows all attachments from all shifts
/// Filterable by type (All, BEOs, Invoices, Receipts, Paychecks, Other)
class AllDocumentsScreen extends StatefulWidget {
  const AllDocumentsScreen({super.key});

  @override
  State<AllDocumentsScreen> createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends State<AllDocumentsScreen> {
  final DatabaseService _db = DatabaseService();
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  bool _isLoading = true;
  List<DocumentWithShift> _allDocuments = [];
  String _selectedFilter = 'All';
  String _sortBy = 'newest';
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'All',
    'Images',
    'PDFs',
    'Spreadsheets',
    'Documents',
    'Other'
  ];

  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'oldest', 'label': 'Oldest First'},
    {'value': 'name_asc', 'label': 'Name A-Z'},
    {'value': 'name_desc', 'label': 'Name Z-A'},
    {'value': 'size_desc', 'label': 'Largest First'},
    {'value': 'size_asc', 'label': 'Smallest First'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all attachments
      final attachmentsResponse = await _db.supabase
          .from('shift_attachments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Get all shifts for reference
      final shiftsResponse = await _db.supabase
          .from('shifts')
          .select('id, job_id, date, event_name, total_income')
          .eq('user_id', userId);

      // Get all jobs for names
      final jobsResponse = await _db.supabase
          .from('jobs')
          .select('id, name')
          .eq('user_id', userId);

      // Build job name map
      final jobNames = <String, String>{};
      for (final job in jobsResponse as List) {
        jobNames[job['id']] = job['name'];
      }

      // Build shift map
      final shiftMap = <String, Map<String, dynamic>>{};
      for (final shift in shiftsResponse as List) {
        shiftMap[shift['id']] = shift;
      }

      // Combine documents with shift info
      final documents = <DocumentWithShift>[];
      for (final attachmentData in attachmentsResponse as List) {
        final attachment = ShiftAttachment.fromMap(attachmentData);
        final shiftData = shiftMap[attachment.shiftId];

        String shiftName = 'Unknown Shift';
        DateTime? shiftDate;
        double? shiftIncome;

        if (shiftData != null) {
          final jobId = shiftData['job_id'];
          final eventName = shiftData['event_name'];
          shiftDate = DateTime.tryParse(shiftData['date'] ?? '');
          shiftIncome = (shiftData['total_income'] as num?)?.toDouble();

          if (eventName != null && eventName.isNotEmpty) {
            shiftName = eventName;
          } else if (jobId != null && jobNames.containsKey(jobId)) {
            shiftName = jobNames[jobId]!;
          }

          if (shiftDate != null) {
            shiftName += ' - ${DateFormat('MMM d, yyyy').format(shiftDate)}';
          }
        }

        documents.add(DocumentWithShift(
          attachment: attachment,
          shiftName: shiftName,
          shiftDate: shiftDate,
          shiftIncome: shiftIncome,
          shiftId: attachment.shiftId,
        ));
      }

      setState(() {
        _allDocuments = documents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
    }
  }

  List<DocumentWithShift> get _filteredDocuments {
    var filtered = _allDocuments;

    // Apply type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((doc) {
        switch (_selectedFilter) {
          case 'Images':
            return doc.attachment.isImage;
          case 'PDFs':
            return doc.attachment.isPdf;
          case 'Spreadsheets':
            return doc.attachment.isSpreadsheet;
          case 'Documents':
            return doc.attachment.isDocument;
          case 'Other':
            return !doc.attachment.isImage &&
                !doc.attachment.isPdf &&
                !doc.attachment.isSpreadsheet &&
                !doc.attachment.isDocument;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((doc) {
        return doc.attachment.fileName.toLowerCase().contains(query) ||
            doc.shiftName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sort
    switch (_sortBy) {
      case 'newest':
        filtered.sort(
            (a, b) => b.attachment.createdAt.compareTo(a.attachment.createdAt));
        break;
      case 'oldest':
        filtered.sort(
            (a, b) => a.attachment.createdAt.compareTo(b.attachment.createdAt));
        break;
      case 'name_asc':
        filtered.sort(
            (a, b) => a.attachment.fileName.compareTo(b.attachment.fileName));
        break;
      case 'name_desc':
        filtered.sort(
            (a, b) => b.attachment.fileName.compareTo(a.attachment.fileName));
        break;
      case 'size_desc':
        filtered.sort((a, b) =>
            (b.attachment.fileSize ?? 0).compareTo(a.attachment.fileSize ?? 0));
        break;
      case 'size_asc':
        filtered.sort((a, b) =>
            (a.attachment.fileSize ?? 0).compareTo(b.attachment.fileSize ?? 0));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'All Documents',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search documents...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: AppTheme.bodyMedium,
            ),
          ),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                  },
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: AppTheme.cardBackground,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.cardBackgroundLight,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Sort dropdown and count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredDocuments.length} document${_filteredDocuments.length == 1 ? '' : 's'}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (value) => setState(() => _sortBy = value),
                  child: Row(
                    children: [
                      Text(
                        _sortOptions
                            .firstWhere((o) => o['value'] == _sortBy)['label']!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.primaryGreen,
                      ),
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

          const SizedBox(height: 12),

          // Documents list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : _filteredDocuments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final doc = _filteredDocuments[index];
                          return _buildDocumentCard(doc);
                        },
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
            Icons.folder_open,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'No documents match your filters'
                : 'No documents yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Documents attached to shifts will appear here',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentWithShift doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Document preview
          SizedBox(
            width: 80,
            height: 80,
            child: DocumentPreviewWidget(
              attachment: doc.attachment,
              showFileName: false,
              showFileSize: false,
            ),
          ),
          const SizedBox(width: 12),
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.attachment.fileName,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${doc.attachment.extension.toUpperCase()} • ${doc.attachment.formattedSize}',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                // Shift link
                GestureDetector(
                  onTap: () => _navigateToShift(doc.shiftId),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 12,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          doc.shiftName,
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onSelected: (value) async {
              switch (value) {
                case 'view_shift':
                  _navigateToShift(doc.shiftId);
                  break;
                case 'delete':
                  await _deleteDocument(doc);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_shift',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 18),
                    SizedBox(width: 8),
                    Text('View Shift'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToShift(String shiftId) async {
    try {
      final shiftData =
          await _db.supabase.from('shifts').select().eq('id', shiftId).single();

      if (mounted) {
        final shift = Shift.fromSupabase(shiftData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleShiftDetailScreen(shift: shift),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load shift: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(DocumentWithShift doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Document?', style: AppTheme.titleMedium),
        content: Text(
          'Are you sure you want to delete "${doc.attachment.fileName}"?\n\nThis cannot be undone.',
          style: AppTheme.bodyMedium,
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
    );

    if (confirmed == true) {
      try {
        await _db.deleteAttachment(doc.attachment);
        await _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Document deleted'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
      }
    }
  }
}

/// Helper class to combine attachment with shift info
class DocumentWithShift {
  final ShiftAttachment attachment;
  final String shiftName;
  final DateTime? shiftDate;
  final double? shiftIncome;
  final String shiftId;

  DocumentWithShift({
    required this.attachment,
    required this.shiftName,
    this.shiftDate,
    this.shiftIncome,
    required this.shiftId,
  });
}
