import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/paycheck.dart';
import '../screens/paycheck_detail_screen.dart';

/// Paychecks Screen - Shows all W-2 paycheck records
/// Displays paycheck images and financial data (no shift links - W-2 income)
class PaychecksScreen extends StatefulWidget {
  const PaychecksScreen({super.key});

  @override
  State<PaychecksScreen> createState() => _PaychecksScreenState();
}

class _PaychecksScreenState extends State<PaychecksScreen> {
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

    final mostRecent = _paychecks.first;

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

    // Fallback: sum all paychecks
    return {
      'gross': _paychecks.fold(0.0, (sum, p) => sum + (p.grossPay ?? 0)),
      'federal': _paychecks.fold(0.0, (sum, p) => sum + (p.federalTax ?? 0)),
      'state': _paychecks.fold(0.0, (sum, p) => sum + (p.stateTax ?? 0)),
      'fica': _paychecks.fold(0.0, (sum, p) => sum + (p.ficaTax ?? 0)),
      'medicare': _paychecks.fold(0.0, (sum, p) => sum + (p.medicareTax ?? 0)),
      'net': _paychecks.fold(0.0, (sum, p) => sum + (p.netPay ?? 0)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ytdTotals = _getYTDTotals();
    final availableYears = _getAvailableYears();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Paychecks',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Column(
              children: [
                // Year selector
                _buildYearSelector(availableYears),

                // YTD Summary
                _buildYTDSummary(ytdTotals),

                // Paychecks list
                Expanded(
                  child: _paychecks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _paychecks.length,
                          itemBuilder: (context, index) {
                            final paycheck = _paychecks[index];
                            return _buildPaycheckCard(paycheck);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaycheckOptions,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Paycheck',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<String> _getAvailableYears() {
    if (_paychecks.isEmpty) return [DateTime.now().year.toString()];

    final years = <String>{};
    for (final paycheck in _paychecks) {
      years.add(paycheck.payPeriodEnd.year.toString());
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  Widget _buildYearSelector(List<String> years) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedYear,
            isExpanded: true,
            dropdownColor: AppTheme.cardBackground,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            icon:
                Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
            items: years
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedYear = value);
                _loadPaychecks();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildYTDSummary(Map<String, double> ytd) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Year-to-Date Summary',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildYTDItem(
                    'Gross Pay', ytd['gross']!, AppTheme.successColor),
              ),
              Expanded(
                child: _buildYTDItem(
                    'Net Pay', ytd['net']!, AppTheme.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Withholdings',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildWithholdingRow('Federal Tax', ytd['federal']!),
          _buildWithholdingRow('State Tax', ytd['state']!),
          _buildWithholdingRow('FICA', ytd['fica']!),
          _buildWithholdingRow('Medicare', ytd['medicare']!),
        ],
      ),
    );
  }

  Widget _buildYTDItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${NumberFormat('#,##0.00').format(amount)}',
          style: AppTheme.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWithholdingRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
          Text(
            '\$${NumberFormat('#,##0.00').format(amount)}',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaycheckCard(Paycheck paycheck) {
    final imageUrls = paycheck.imageUrl != null ? [paycheck.imageUrl!] : [];

    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaycheckDetailScreen(paycheck: paycheck),
          ),
        );

        // Reload list if paycheck was deleted
        if (deleted == true) {
          _loadPaychecks();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.attach_money,
                      color: AppTheme.successColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paycheck.employerName ?? 'Paycheck',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM d').format(paycheck.payPeriodStart)} - ${DateFormat('MMM d, yyyy').format(paycheck.payPeriodEnd)}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${NumberFormat('#,##0.00').format(paycheck.grossPay)}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Net: \$${NumberFormat('#,##0.00').format(paycheck.netPay)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${imageUrls.length} image(s) attached',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddPaycheckOptions() {
    showModalBottomSheet(
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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Paycheck',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: AppTheme.successColor),
                ),
                title: Text('Scan Paycheck',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Use AI to extract data from pay stub',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Paycheck scanning from settings coming soon!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Paychecks Yet',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a paycheck to track W-2 income and withholdings',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
