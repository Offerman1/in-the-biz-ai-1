import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/shift.dart';
import '../models/shift_attachment.dart';
import '../widgets/document_preview_widget.dart';
import '../screens/single_shift_detail_screen.dart';

/// Checkout Detail Screen - Shows full checkout data with images
class CheckoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic> checkout;

  const CheckoutDetailScreen({super.key, required this.checkout});

  @override
  State<CheckoutDetailScreen> createState() => _CheckoutDetailScreenState();
}

class _CheckoutDetailScreenState extends State<CheckoutDetailScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoadingShift = false;
  Shift? _linkedShift;
  List<ShiftAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadLinkedShift(),
      _loadAttachments(),
    ]);
  }

  Future<void> _loadLinkedShift() async {
    final shiftId = widget.checkout['shift_id'] as String?;
    if (shiftId == null) return;

    setState(() => _isLoadingShift = true);

    try {
      final response =
          await _db.supabase.from('shifts').select().eq('id', shiftId).single();

      setState(() {
        _linkedShift = Shift.fromMap(response);
        _isLoadingShift = false;
      });
    } catch (e) {
      print('Error loading shift: $e');
      setState(() => _isLoadingShift = false);
    }
  }

  Future<void> _loadAttachments() async {
    final checkoutId = widget.checkout['id'] as String?;
    if (checkoutId == null) {
      return;
    }

    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Load attachments from shift_attachments table where file_path contains checkout ID
      final response = await _db.supabase
          .from('shift_attachments')
          .select()
          .eq('user_id', userId)
          .like('file_path', '%checkout%$checkoutId%');

      setState(() {
        _attachments = (response as List)
            .map((e) => ShiftAttachment.fromMap(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      print('Error loading attachments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.checkout['checkout_date']);
    final imageUrls =
        (widget.checkout['image_urls'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Checkout Details',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: 'Delete Checkout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(date),

            const SizedBox(height: 16),

            // Financial Details
            _buildFinancialDetails(),

            const SizedBox(height: 16),

            // Linked Shift
            if (widget.checkout['shift_id'] != null) ...[
              _buildLinkedShiftCard(),
              const SizedBox(height: 16),
            ],

            // Attachments
            if (_attachments.isNotEmpty) ...[
              _buildAttachmentsSection(),
              const SizedBox(height: 16),
            ],

            // Legacy Image URLs (if any)
            if (imageUrls.isNotEmpty) ...[
              _buildLegacyImagesSection(imageUrls),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(Icons.point_of_sale, color: AppTheme.accentBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server Checkout',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDetails() {
    final data = widget.checkout;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Details',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Sales Section
          Text(
            'SALES',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (data['gross_sales'] != null)
            _buildDetailRow(
              'Gross Sales',
              '\$${NumberFormat('#,##0.00').format(data['gross_sales'])}',
              AppTheme.accentBlue,
            ),
          if (data['net_sales'] != null)
            _buildDetailRow(
              'Net Sales',
              '\$${NumberFormat('#,##0.00').format(data['net_sales'])}',
              AppTheme.textPrimary,
            ),
          if (data['total_sales'] != null)
            _buildDetailRow(
              'Total Sales',
              '\$${NumberFormat('#,##0.00').format(data['total_sales'])}',
              AppTheme.textPrimary,
            ),
          if (data['comps'] != null && data['comps'] > 0)
            _buildDetailRow(
              'Comps',
              '\$${NumberFormat('#,##0.00').format(data['comps'])}',
              AppTheme.accentOrange,
            ),
          if (data['promos'] != null && data['promos'] > 0)
            _buildDetailRow(
              'Promos',
              '\$${NumberFormat('#,##0.00').format(data['promos'])}',
              AppTheme.accentPurple,
            ),

          const SizedBox(height: 16),

          // Tips Section
          Text(
            'TIPS',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (data['gross_tips'] != null)
            _buildDetailRow(
              'Gross Tips',
              '\$${NumberFormat('#,##0.00').format(data['gross_tips'])}',
              AppTheme.primaryGreen,
            ),
          if (data['credit_card_tips'] != null)
            _buildDetailRow(
              'Credit Card Tips',
              '\$${NumberFormat('#,##0.00').format(data['credit_card_tips'])}',
              AppTheme.textPrimary,
            ),
          if (data['cash_tips'] != null)
            _buildDetailRow(
              'Cash Tips',
              '\$${NumberFormat('#,##0.00').format(data['cash_tips'])}',
              AppTheme.textPrimary,
            ),
          if (data['total_tips_before_tipshare'] != null)
            _buildDetailRow(
              'Total Tips (Before Tipshare)',
              '\$${NumberFormat('#,##0.00').format(data['total_tips_before_tipshare'])}',
              AppTheme.textPrimary,
            ),
          if (data['tipout_amount'] != null)
            _buildDetailRow(
              'Tipout / Tip Share',
              '\$${NumberFormat('#,##0.00').format(data['tipout_amount'])}',
              AppTheme.accentOrange,
            ),
          if (data['tipout_percentage'] != null)
            _buildDetailRow(
              'Tipout Percentage',
              '${NumberFormat('#,##0.0').format(data['tipout_percentage'])}%',
              AppTheme.textMuted,
            ),
          if (data['tip_share'] != null && data['tip_share'] > 0)
            _buildDetailRow(
              'Tip Share',
              '\$${NumberFormat('#,##0.00').format(data['tip_share'])}',
              AppTheme.accentOrange,
            ),

          const Divider(height: 24),
          _buildDetailRow(
            'Net Tips (Take Home)',
            '\$${NumberFormat('#,##0.00').format(data['net_tips'] ?? 0)}',
            AppTheme.primaryGreen,
            isLarge: true,
          ),

          const SizedBox(height: 16),

          // Service Details
          Text(
            'SERVICE DETAILS',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (data['table_count'] != null)
            _buildDetailRow(
              data['table_count_label_found'] ?? 'Tables/Checks',
              '${data['table_count']}',
              AppTheme.textPrimary,
            ),
          if (data['cover_count'] != null)
            _buildDetailRow(
              'Covers (Guests)',
              '${data['cover_count']}',
              AppTheme.textPrimary,
            ),
          if (data['hours_worked'] != null)
            _buildDetailRow(
              'Hours Worked',
              '${NumberFormat('#,##0.0').format(data['hours_worked'])} hrs',
              AppTheme.textPrimary,
            ),
          if (data['server_name'] != null && data['server_name'].isNotEmpty)
            _buildDetailRow(
              'Server Name',
              data['server_name'],
              AppTheme.textPrimary,
            ),

          // POS System
          if (data['pos_system'] != null && data['pos_system'].isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'POS SYSTEM',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'System',
              data['pos_system'],
              AppTheme.accentPurple,
            ),
            if (data['pos_system_confidence'] != null)
              _buildDetailRow(
                'AI Confidence',
                '${(data['pos_system_confidence'] * 100).toStringAsFixed(0)}%',
                AppTheme.textMuted,
              ),
          ],

          // Validation Status
          if (data['math_validated'] != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  data['math_validated'] ? Icons.check_circle : Icons.warning,
                  color: data['math_validated']
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  data['math_validated']
                      ? 'Math Validated ✓'
                      : 'Math Validation Failed',
                  style: AppTheme.bodySmall.copyWith(
                    color: data['math_validated']
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            if (data['validation_notes'] != null &&
                data['validation_notes'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data['validation_notes'],
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color,
      {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isLarge ? AppTheme.bodyLarge : AppTheme.bodyMedium)
                .copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style:
                (isLarge ? AppTheme.titleMedium : AppTheme.bodyMedium).copyWith(
              color: color,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedShiftCard() {
    if (_isLoadingShift) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_linkedShift == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Linked Shift',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _linkedShift!.eventName ?? 'Shift',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(_linkedShift!.date),
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SingleShiftDetailScreen(shift: _linkedShift!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Shift'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scanned Images (${_attachments.length})',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              return DocumentPreviewWidget(
                attachment: _attachments[index],
                height: 150,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Checkout?',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary)),
        content: Text(
          'This will permanently delete this checkout record. This action cannot be undone.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteCheckout();
    }
  }

  Future<void> _deleteCheckout() async {
    try {
      await _db.supabase
          .from('server_checkouts')
          .delete()
          .eq('id', widget.checkout['id']);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Checkout deleted'),
            backgroundColor: AppTheme.successColor,
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

  Widget _buildLegacyImagesSection(List<String> imageUrls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legacy Images (${imageUrls.length})',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stored in checkout-scans bucket',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
