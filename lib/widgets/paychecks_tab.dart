import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/paycheck.dart';
import '../models/vision_scan.dart';
import '../screens/document_scanner_screen.dart';

/// Paychecks analytics tab for Stats screen
/// Shows YTD summary, Reality Check, and paycheck history
class PaychecksTab extends StatefulWidget {
  const PaychecksTab({super.key});

  @override
  State<PaychecksTab> createState() => _PaychecksTabState();
}

class _PaychecksTabState extends State<PaychecksTab> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<Paycheck> _paychecks = [];
  String _selectedYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _loadPaychecks();
  }

  Future<void> _loadPaychecks() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser!.id;
      final yearStart = '$_selectedYear-01-01';
      final yearEnd = '$_selectedYear-12-31';

      final response = await _db.supabase
          .from('paychecks')
          .select()
          .eq('user_id', userId)
          .gte('pay_period_start', yearStart)
          .lte('pay_period_end', yearEnd)
          .order('pay_period_end', ascending: false);

      setState(() {
        _paychecks = (response as List)
            .map((e) => Paycheck.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading paychecks: $e');
      setState(() => _isLoading = false);
    }
  }

  // Calculate YTD totals from most recent paycheck (has YTD fields)
  Map<String, double> _getYTDTotals() {
    if (_paychecks.isEmpty) {
      return {
        'gross': 0,
        'federal': 0,
        'state': 0,
        'fica': 0,
        'medicare': 0,
        'net': 0,
      };
    }

    // Get most recent paycheck with YTD data
    final mostRecent = _paychecks.first;

    // If YTD data exists on the paycheck, use it
    if (mostRecent.ytdGross != null && mostRecent.ytdGross! > 0) {
      return {
        'gross': mostRecent.ytdGross ?? 0,
        'federal': mostRecent.ytdFederalTax ?? 0,
        'state': mostRecent.ytdStateTax ?? 0,
        'fica': mostRecent.ytdFica ?? 0,
        'medicare': mostRecent.ytdMedicare ?? 0,
        'net': (mostRecent.ytdGross ?? 0) -
            (mostRecent.ytdFederalTax ?? 0) -
            (mostRecent.ytdStateTax ?? 0) -
            (mostRecent.ytdFica ?? 0) -
            (mostRecent.ytdMedicare ?? 0),
      };
    }

    // Otherwise, sum up all paychecks
    double gross = 0, federal = 0, state = 0, fica = 0, medicare = 0;
    for (final p in _paychecks) {
      gross += p.grossPay ?? 0;
      federal += p.federalTax ?? 0;
      state += p.stateTax ?? 0;
      fica += p.ficaTax ?? 0;
      medicare += p.medicareTax ?? 0;
    }

    return {
      'gross': gross,
      'federal': federal,
      'state': state,
      'fica': fica,
      'medicare': medicare,
      'net': gross - federal - state - fica - medicare,
    };
  }

  // Calculate Reality Check summary
  Map<String, dynamic> _getRealityCheck() {
    int totalWithGaps = 0;
    double totalGap = 0;

    for (final p in _paychecks) {
      if (p.hasUnreportedGap) {
        totalWithGaps++;
        totalGap += p.unreportedGap ?? 0;
      }
    }

    return {
      'totalPaychecks': _paychecks.length,
      'paychecksWithGaps': totalWithGaps,
      'totalGap': totalGap,
      'hasIssues': totalWithGaps > 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_paychecks.isEmpty) {
      return _buildEmptyState();
    }

    final ytd = _getYTDTotals();
    final realityCheck = _getRealityCheck();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action buttons row
        _buildActionButtons(),
        const SizedBox(height: 16),

        // Year selector
        _buildYearSelector(),
        const SizedBox(height: 16),

        // YTD Summary Card
        _buildYTDSummaryCard(ytd),
        const SizedBox(height: 16),

        // Reality Check Card
        _buildRealityCheckCard(realityCheck),
        const SizedBox(height: 16),

        // Tax Withholding Breakdown
        _buildTaxBreakdownCard(ytd),
        const SizedBox(height: 24),

        // Paycheck History
        _buildPaycheckHistory(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No paychecks scanned yet',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first paycheck using the ✨ Scan button\nto track your W-2 income and taxes',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToPaycheckScanner(),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Paycheck'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => (currentYear - i).toString());

    return Row(
      children: [
        Text('Year:',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
          ),
          child: DropdownButton<String>(
            value: _selectedYear,
            dropdownColor: AppTheme.cardBackground,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year,
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedYear = value);
                _loadPaychecks();
              }
            },
          ),
        ),
        const Spacer(),
        Text(
          '${_paychecks.length} paychecks',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildYTDSummaryCard(Map<String, double> ytd) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.15),
            AppTheme.accentBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                'Year-to-Date Summary',
                style:
                    AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildYTDMetric(
                    'Gross Income', ytd['gross']!, AppTheme.textPrimary),
              ),
              Expanded(
                child: _buildYTDMetric(
                    'Taxes Paid',
                    ytd['federal']! +
                        ytd['state']! +
                        ytd['fica']! +
                        ytd['medicare']!,
                    AppTheme.dangerColor),
              ),
              Expanded(
                child: _buildYTDMetric(
                    'Net Income', ytd['net']!, AppTheme.primaryGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYTDMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${NumberFormat('#,##0.00').format(value)}',
          style: AppTheme.titleMedium
              .copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRealityCheckCard(Map<String, dynamic> data) {
    final hasIssues = data['hasIssues'] as bool;
    final color = hasIssues ? AppTheme.warningColor : AppTheme.successColor;
    final icon = hasIssues ? Icons.warning_amber_rounded : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                'Reality Check',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasIssues ? 'Review Needed' : 'All Good',
                  style: AppTheme.labelSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasIssues) ...[
            Text(
              '${data['paychecksWithGaps']} of ${data['totalPaychecks']} paychecks have income gaps',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Total gap: \$${NumberFormat('#,##0.00').format(data['totalGap'])}',
              style: AppTheme.bodyMedium
                  .copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This could indicate unreported cash tips. Review for tax compliance.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ] else ...[
            Text(
              'Your app-tracked income matches your paycheck records.',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxBreakdownCard(Map<String, double> ytd) {
    final totalTaxes =
        ytd['federal']! + ytd['state']! + ytd['fica']! + ytd['medicare']!;
    final effectiveRate =
        ytd['gross']! > 0 ? (totalTaxes / ytd['gross']!) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tax Withholding Breakdown',
                style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${effectiveRate.toStringAsFixed(1)}% effective',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaxRow(
              'Federal Income Tax', ytd['federal']!, AppTheme.accentBlue),
          _buildTaxRow(
              'State Income Tax', ytd['state']!, AppTheme.accentPurple),
          _buildTaxRow(
              'Social Security (FICA)', ytd['fica']!, AppTheme.accentOrange),
          _buildTaxRow('Medicare', ytd['medicare']!, AppTheme.primaryGreen),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Withheld',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  )),
              Text('\$${NumberFormat('#,##0.00').format(totalTaxes)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.dangerColor,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.textSecondary)),
          ),
          Text('\$${NumberFormat('#,##0.00').format(amount)}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPaycheckHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paycheck History',
          style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._paychecks.map((p) => _buildPaycheckCard(p)),
      ],
    );
  }

  Widget _buildPaycheckCard(Paycheck paycheck) {
    final dateFormat = DateFormat('MMM d');
    final periodText =
        '${dateFormat.format(paycheck.payPeriodStart)} - ${dateFormat.format(paycheck.payPeriodEnd)}';
    final hasGap = paycheck.hasUnreportedGap;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasGap
              ? AppTheme.warningColor.withOpacity(0.5)
              : AppTheme.textMuted.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodText,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (paycheck.employerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        paycheck.employerName!,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${NumberFormat('#,##0.00').format(paycheck.grossPay ?? 0)}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gross',
                    style:
                        AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPaycheckStat(
                  'Hours', '${paycheck.regularHours ?? 0}', Icons.access_time),
              const SizedBox(width: 16),
              _buildPaycheckStat(
                  'Net',
                  '\$${NumberFormat('#,##0').format(paycheck.netPay ?? 0)}',
                  Icons.attach_money),
              const SizedBox(width: 16),
              _buildPaycheckStat(
                  'Taxes',
                  '\$${NumberFormat('#,##0').format(paycheck.totalTaxesWithheld)}',
                  Icons.account_balance),
            ],
          ),
          if (hasGap) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber,
                      size: 14, color: AppTheme.warningColor),
                  const SizedBox(width: 4),
                  Text(
                    'Gap: \$${NumberFormat('#,##0').format(paycheck.unreportedGap?.abs() ?? 0)}',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppTheme.warningColor),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaycheckStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// Build action buttons for scanning and manual entry
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigateToPaycheckScanner(),
            icon: Icon(Icons.document_scanner, size: 18),
            label: Text('Scan Paycheck'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showManualPaycheckForm,
            icon: Icon(Icons.edit_note, size: 18),
            label: Text('Add Manually'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentBlue,
              side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Show manual paycheck entry form
  void _showManualPaycheckForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualPaycheckForm(
        onSave: (paycheckData) async {
          Navigator.pop(context);
          try {
            final userId = _db.supabase.auth.currentUser!.id;
            await _db.supabase.from('paychecks').insert({
              ...paycheckData,
              'user_id': userId,
              'created_at': DateTime.now().toIso8601String(),
            });
            _loadPaychecks();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Paycheck added!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving paycheck: $e'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Navigate to paycheck scanner
  Future<void> _navigateToPaycheckScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          scanType: ScanType.paycheck,
          onScanComplete: (session) async {
            // Close scanner
            Navigator.pop(context);

            // Process the scanned paycheck
            if (session.hasImages) {
              // For now, show a success message
              // The vision processing will happen in the scanner screen
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paycheck scanned! Processing...'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                _loadPaychecks(); // Refresh the list
              }
            }
          },
        ),
      ),
    );
  }
}

// ============================================
// MANUAL PAYCHECK ENTRY FORM
// ============================================

/// Manual Paycheck Entry Form
class ManualPaycheckForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const ManualPaycheckForm({super.key, required this.onSave});

  @override
  State<ManualPaycheckForm> createState() => _ManualPaycheckFormState();
}

class _ManualPaycheckFormState extends State<ManualPaycheckForm> {
  final _formKey = GlobalKey<FormState>();
  final _employerController = TextEditingController();
  final _grossPayController = TextEditingController();
  final _netPayController = TextEditingController();
  final _hoursController = TextEditingController();
  final _federalTaxController = TextEditingController();
  final _stateTaxController = TextEditingController();
  final _ficaController = TextEditingController();
  final _medicareController = TextEditingController();

  DateTime _payPeriodStart = DateTime.now().subtract(Duration(days: 14));
  DateTime _payPeriodEnd = DateTime.now();
  DateTime _payDate = DateTime.now();

  @override
  void dispose() {
    _employerController.dispose();
    _grossPayController.dispose();
    _netPayController.dispose();
    _hoursController.dispose();
    _federalTaxController.dispose();
    _stateTaxController.dispose();
    _ficaController.dispose();
    _medicareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Paycheck', style: AppTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Employer
                  TextFormField(
                    controller: _employerController,
                    decoration: InputDecoration(
                      labelText: 'Employer Name',
                      hintText: 'ABC Company',
                      prefixIcon:
                          Icon(Icons.business, color: AppTheme.accentBlue),
                    ),
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Pay Period
                  Text('Pay Period',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.calendar_today,
                              size: 20, color: AppTheme.accentBlue),
                          title: Text('Start', style: AppTheme.bodySmall),
                          subtitle: Text(
                            '${_payPeriodStart.month}/${_payPeriodStart.day}/${_payPeriodStart.year}',
                            style: AppTheme.bodyMedium,
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _payPeriodStart,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null)
                              setState(() => _payPeriodStart = picked);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.event,
                              size: 20, color: AppTheme.accentOrange),
                          title: Text('End', style: AppTheme.bodySmall),
                          subtitle: Text(
                            '${_payPeriodEnd.month}/${_payPeriodEnd.day}/${_payPeriodEnd.year}',
                            style: AppTheme.bodyMedium,
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _payPeriodEnd,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null)
                              setState(() => _payPeriodEnd = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gross & Net Pay
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _grossPayController,
                          decoration: InputDecoration(
                            labelText: 'Gross Pay *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money,
                                color: AppTheme.primaryGreen),
                          ),
                          style: AppTheme.bodyMedium,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _netPayController,
                          decoration: InputDecoration(
                            labelText: 'Net Pay',
                            hintText: '0.00',
                            prefixIcon:
                                Icon(Icons.money, color: AppTheme.accentBlue),
                          ),
                          style: AppTheme.bodyMedium,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hours
                  TextFormField(
                    controller: _hoursController,
                    decoration: InputDecoration(
                      labelText: 'Hours Worked',
                      hintText: '80',
                      prefixIcon:
                          Icon(Icons.schedule, color: AppTheme.textMuted),
                    ),
                    style: AppTheme.bodyMedium,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),

                  // Tax Withholdings Section
                  Text('Tax Withholdings',
                      style: AppTheme.titleMedium
                          .copyWith(color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _federalTaxController,
                          decoration: InputDecoration(
                            labelText: 'Federal Tax',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.account_balance,
                                size: 20, color: AppTheme.accentBlue),
                          ),
                          style: AppTheme.bodyMedium,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateTaxController,
                          decoration: InputDecoration(
                            labelText: 'State Tax',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.location_city,
                                size: 20, color: AppTheme.accentPurple),
                          ),
                          style: AppTheme.bodyMedium,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ficaController,
                          decoration: InputDecoration(
                            labelText: 'FICA/Social Security',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.security,
                                size: 20, color: AppTheme.accentOrange),
                          ),
                          style: AppTheme.bodyMedium,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _medicareController,
                          decoration: InputDecoration(
                            labelText: 'Medicare',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.local_hospital,
                                size: 20, color: AppTheme.primaryGreen),
                          ),
                          style: AppTheme.bodyMedium,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSave({
                          'employer_name': _employerController.text.isEmpty
                              ? null
                              : _employerController.text,
                          'pay_period_start':
                              _payPeriodStart.toIso8601String().split('T')[0],
                          'pay_period_end':
                              _payPeriodEnd.toIso8601String().split('T')[0],
                          'pay_date': _payDate.toIso8601String().split('T')[0],
                          'gross_pay':
                              double.tryParse(_grossPayController.text) ?? 0,
                          'net_pay': double.tryParse(_netPayController.text),
                          'hours_worked':
                              double.tryParse(_hoursController.text),
                          'federal_tax':
                              double.tryParse(_federalTaxController.text),
                          'state_tax':
                              double.tryParse(_stateTaxController.text),
                          'fica': double.tryParse(_ficaController.text),
                          'medicare': double.tryParse(_medicareController.text),
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Save Paycheck',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
