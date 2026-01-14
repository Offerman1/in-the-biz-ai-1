import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/paycheck.dart';
import '../models/shift_attachment.dart';
import '../widgets/document_preview_widget.dart';

/// Paycheck Detail Screen - Shows full paycheck data with images
class PaycheckDetailScreen extends StatefulWidget {
  final Paycheck paycheck;

  const PaycheckDetailScreen({super.key, required this.paycheck});

  @override
  State<PaycheckDetailScreen> createState() => _PaycheckDetailScreenState();
}

class _PaycheckDetailScreenState extends State<PaycheckDetailScreen> {
  final DatabaseService _db = DatabaseService();
  List<ShiftAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Load attachments from shift_attachments table where file_path contains paycheck ID
      final response = await _db.supabase
          .from('shift_attachments')
          .select()
          .eq('user_id', userId)
          .like('file_path', '%paycheck%${widget.paycheck.id}%');

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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Paycheck Details',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: 'Delete Paycheck',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),

            const SizedBox(height: 16),

            // Pay Period
            _buildPayPeriodCard(),

            const SizedBox(height: 16),

            // Earnings Details
            _buildEarningsDetails(),

            const SizedBox(height: 16),

            // Taxes & Deductions
            _buildTaxesDeductions(),

            const SizedBox(height: 16),

            // YTD Totals
            if (_hasYTDData()) ...[
              _buildYTDTotals(),
              const SizedBox(height: 16),
            ],

            // Additional Info
            _buildAdditionalInfo(),

            const SizedBox(height: 16),

            // Attachments
            if (_attachments.isNotEmpty) ...[
              _buildAttachmentsSection(),
              const SizedBox(height: 16),
            ],

            // Legacy Image URL
            if (widget.paycheck.imageUrl != null) ...[
              _buildLegacyImageSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.attach_money,
                color: AppTheme.successColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.paycheck.employerName ?? 'W-2 Paycheck',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.paycheck.payrollProvider != null)
                  Text(
                    widget.paycheck.payrollProvider!,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,##0.00').format(widget.paycheck.grossPay ?? 0)}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gross Pay',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayPeriodCard() {
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
            'Pay Period',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Period Start',
            DateFormat('MMM d, yyyy').format(widget.paycheck.payPeriodStart),
            AppTheme.textPrimary,
          ),
          _buildDetailRow(
            'Period End',
            DateFormat('MMM d, yyyy').format(widget.paycheck.payPeriodEnd),
            AppTheme.textPrimary,
          ),
          if (widget.paycheck.payDate != null)
            _buildDetailRow(
              'Pay Date',
              DateFormat('MMM d, yyyy').format(widget.paycheck.payDate!),
              AppTheme.primaryGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsDetails() {
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
            'Earnings',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.paycheck.regularHours != null)
            _buildDetailRow(
              'Regular Hours',
              '${widget.paycheck.regularHours!.toStringAsFixed(2)} hrs',
              AppTheme.textPrimary,
            ),
          if (widget.paycheck.overtimeHours != null &&
              widget.paycheck.overtimeHours! > 0)
            _buildDetailRow(
              'Overtime Hours',
              '${widget.paycheck.overtimeHours!.toStringAsFixed(2)} hrs',
              AppTheme.accentOrange,
            ),
          if (widget.paycheck.hourlyRate != null)
            _buildDetailRow(
              'Hourly Rate',
              '\$${widget.paycheck.hourlyRate!.toStringAsFixed(2)}/hr',
              AppTheme.textPrimary,
            ),
          if (widget.paycheck.overtimeRate != null)
            _buildDetailRow(
              'Overtime Rate',
              '\$${widget.paycheck.overtimeRate!.toStringAsFixed(2)}/hr',
              AppTheme.accentOrange,
            ),
          const Divider(height: 24),
          _buildDetailRow(
            'Gross Pay',
            '\$${NumberFormat('#,##0.00').format(widget.paycheck.grossPay ?? 0)}',
            AppTheme.successColor,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxesDeductions() {
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
            'Taxes & Deductions',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.paycheck.federalTax != null)
            _buildDetailRow(
              'Federal Tax',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.federalTax)}',
              AppTheme.dangerColor,
            ),
          if (widget.paycheck.stateTax != null)
            _buildDetailRow(
              'State Tax',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.stateTax)}',
              AppTheme.dangerColor,
            ),
          if (widget.paycheck.ficaTax != null)
            _buildDetailRow(
              'FICA (Social Security)',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.ficaTax)}',
              AppTheme.accentOrange,
            ),
          if (widget.paycheck.medicareTax != null)
            _buildDetailRow(
              'Medicare',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.medicareTax)}',
              AppTheme.accentOrange,
            ),
          if (widget.paycheck.otherDeductions != null &&
              widget.paycheck.otherDeductions! > 0) ...[
            _buildDetailRow(
              widget.paycheck.otherDeductionsDescription ?? 'Other Deductions',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.otherDeductions)}',
              AppTheme.textMuted,
            ),
          ],
          const Divider(height: 24),
          _buildDetailRow(
            'Net Pay (Take Home)',
            '\$${NumberFormat('#,##0.00').format(widget.paycheck.netPay ?? 0)}',
            AppTheme.primaryGreen,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  bool _hasYTDData() {
    return widget.paycheck.ytdGross != null && widget.paycheck.ytdGross! > 0;
  }

  Widget _buildYTDTotals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: AppTheme.accentPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Year-to-Date Totals',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.paycheck.ytdGross != null)
            _buildDetailRow(
              'YTD Gross',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.ytdGross)}',
              AppTheme.successColor,
            ),
          if (widget.paycheck.ytdFederalTax != null)
            _buildDetailRow(
              'YTD Federal Tax',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.ytdFederalTax)}',
              AppTheme.dangerColor,
            ),
          if (widget.paycheck.ytdStateTax != null)
            _buildDetailRow(
              'YTD State Tax',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.ytdStateTax)}',
              AppTheme.dangerColor,
            ),
          if (widget.paycheck.ytdFica != null)
            _buildDetailRow(
              'YTD FICA',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.ytdFica)}',
              AppTheme.accentOrange,
            ),
          if (widget.paycheck.ytdMedicare != null)
            _buildDetailRow(
              'YTD Medicare',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.ytdMedicare)}',
              AppTheme.accentOrange,
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    if (widget.paycheck.realityCheckRun != true) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              Icon(Icons.fact_check, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reality Check',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.paycheck.appTrackedIncome != null)
            _buildDetailRow(
              'App-Tracked Income',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.appTrackedIncome)}',
              AppTheme.textPrimary,
            ),
          if (widget.paycheck.w2ReportedIncome != null)
            _buildDetailRow(
              'W-2 Reported Income',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.w2ReportedIncome)}',
              AppTheme.textPrimary,
            ),
          if (widget.paycheck.unreportedGap != null &&
              widget.paycheck.unreportedGap! != 0)
            _buildDetailRow(
              'Unreported Gap',
              '\$${NumberFormat('#,##0.00').format(widget.paycheck.unreportedGap)}',
              widget.paycheck.unreportedGap! > 0
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
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

  Widget _buildLegacyImageSection() {
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
            'Legacy Image',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stored in paycheck-scans bucket',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Delete Paycheck?',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary)),
        content: Text(
          'This will permanently delete this paycheck record. This action cannot be undone.',
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
      await _deletePaycheck();
    }
  }

  Future<void> _deletePaycheck() async {
    try {
      await _db.supabase
          .from('paychecks')
          .delete()
          .eq('id', widget.paycheck.id);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paycheck deleted'),
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
}
