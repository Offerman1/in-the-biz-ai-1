import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

/// Analytics dashboard for Server Checkout Scanner
/// Shows trends in Sales vs Tips, POS system usage, and validation rates
class CheckoutAnalyticsTab extends StatefulWidget {
  const CheckoutAnalyticsTab({super.key});

  @override
  State<CheckoutAnalyticsTab> createState() => _CheckoutAnalyticsTabState();
}

class _CheckoutAnalyticsTabState extends State<CheckoutAnalyticsTab> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _checkouts = [];
  String _selectedPeriod = 'Month'; // Day, Week, Month, Year, All

  @override
  void initState() {
    super.initState();
    _loadCheckouts();
  }

  Future<void> _loadCheckouts() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Get date range based on period
      final dateRange = _getDateRange();

      final response = await _db.supabase
          .from('server_checkouts')
          .select()
          .eq('user_id', userId)
          .gte('checkout_date', dateRange['start']!)
          .lte('checkout_date', dateRange['end']!)
          .order('checkout_date', ascending: true);

      setState(() {
        _checkouts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading checkouts: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, String> _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Day':
        return {
          'start': DateFormat('yyyy-MM-dd').format(now),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      case 'Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return {
          'start': DateFormat('yyyy-MM-dd').format(weekStart),
          'end': DateFormat('yyyy-MM-dd').format(weekEnd),
        };
      case 'Month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return {
          'start': DateFormat('yyyy-MM-dd').format(monthStart),
          'end': DateFormat('yyyy-MM-dd').format(monthEnd),
        };
      case 'Year':
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        return {
          'start': DateFormat('yyyy-MM-dd').format(yearStart),
          'end': DateFormat('yyyy-MM-dd').format(yearEnd),
        };
      case 'All':
      default:
        return {
          'start': '2020-01-01',
          'end': DateFormat('yyyy-MM-dd')
              .format(DateTime.now().add(const Duration(days: 365))),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_checkouts.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate totals
    final totalSales = _checkouts.fold<double>(
      0,
      (sum, c) => sum + (c['total_sales'] as num? ?? 0).toDouble(),
    );
    final totalTips = _checkouts.fold<double>(
      0,
      (sum, c) => sum + (c['net_tips'] as num? ?? 0).toDouble(),
    );
    final totalTipout = _checkouts.fold<double>(
      0,
      (sum, c) => sum + (c['tipout_amount'] as num? ?? 0).toDouble(),
    );

    // Calculate averages
    final avgSalesPerShift =
        _checkouts.isNotEmpty ? totalSales / _checkouts.length : 0;
    final avgTipsPerShift =
        _checkouts.isNotEmpty ? totalTips / _checkouts.length : 0;

    // Calculate tip percentage
    final tipPercentage = totalSales > 0 ? (totalTips / totalSales) * 100 : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        _buildPeriodSelector(),
        const SizedBox(height: 16),

        // Summary cards
        Row(
          children: [
            Expanded(
                child: _buildSummaryCard('Total Sales',
                    '\$${totalSales.toStringAsFixed(2)}', AppTheme.accentBlue)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Total Tips',
                    '\$${totalTips.toStringAsFixed(2)}',
                    AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildSummaryCard(
                    'Total Tipout',
                    '\$${totalTipout.toStringAsFixed(2)}',
                    AppTheme.dangerColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Tip %',
                    '${tipPercentage.toStringAsFixed(1)}%',
                    AppTheme.accentPurple)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildSummaryCard(
                    'Avg Sales/Shift',
                    '\$${avgSalesPerShift.toStringAsFixed(2)}',
                    AppTheme.accentBlue.withValues(alpha: 0.7))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Avg Tips/Shift',
                    '\$${avgTipsPerShift.toStringAsFixed(2)}',
                    AppTheme.primaryGreen.withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 24),

        // Sales vs Tips chart
        _buildSalesVsTipsChart(),
        const SizedBox(height: 24),

        // POS System breakdown
        _buildPOSSystemBreakdown(),
        const SizedBox(height: 24),

        // Recent checkouts list
        _buildRecentCheckoutsList(),
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
            Icon(Icons.receipt_long, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No checkouts scanned yet',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first checkout receipt using the ✨ Scan button',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: ['Day', 'Week', 'Month', 'Year', 'All'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _loadCheckouts();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: AppTheme.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesVsTipsChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales vs Tips Trend',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Sales line
                  LineChartBarData(
                    spots: _checkouts.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['total_sales'] as num? ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.accentBlue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  // Tips line
                  LineChartBarData(
                    spots: _checkouts.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['net_tips'] as num? ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryGreen,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegendItem('Sales', AppTheme.accentBlue),
              const SizedBox(width: 24),
              _buildChartLegendItem('Tips', AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPOSSystemBreakdown() {
    // Count checkouts by POS system
    final posSystemCounts = <String, int>{};
    for (final checkout in _checkouts) {
      final posSystem = checkout['pos_system'] as String? ?? 'Unknown';
      posSystemCounts[posSystem] = (posSystemCounts[posSystem] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POS System Usage',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...posSystemCounts.entries.map((entry) {
            final percentage = (_checkouts.isNotEmpty
                ? (entry.value / _checkouts.length) * 100
                : 0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.textPrimary),
                      ),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.textMuted.withValues(alpha: 0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentCheckoutsList() {
    final recentCheckouts = _checkouts.reversed.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Checkouts',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recentCheckouts.map((checkout) {
            final date = checkout['checkout_date'] as String?;
            final posSystem = checkout['pos_system'] as String? ?? 'Unknown';
            final sales = (checkout['total_sales'] as num? ?? 0).toDouble();
            final tips = (checkout['net_tips'] as num? ?? 0).toDouble();

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                date != null
                    ? DateFormat('MMM d, yyyy').format(DateTime.parse(date))
                    : 'Unknown date',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                posSystem,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${sales.toStringAsFixed(2)}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${tips.toStringAsFixed(2)} tips',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
