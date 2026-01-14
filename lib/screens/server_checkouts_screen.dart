import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/shift.dart';
import '../screens/single_shift_detail_screen.dart';
import '../screens/checkout_detail_screen.dart';

/// Server Checkouts Screen - Shows all server checkout records
/// Displays checkout images, financial data, and shift links
class ServerCheckoutsScreen extends StatefulWidget {
  const ServerCheckoutsScreen({super.key});

  @override
  State<ServerCheckoutsScreen> createState() => _ServerCheckoutsScreenState();
}

class _ServerCheckoutsScreenState extends State<ServerCheckoutsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _checkouts = [];
  String _selectedPeriod = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadCheckouts();
  }

  Future<void> _loadCheckouts() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser!.id;

      final response = await _db.supabase
          .from('server_checkouts')
          .select()
          .eq('user_id', userId)
          .order('checkout_date', ascending: false);

      setState(() {
        _checkouts = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading checkouts: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCheckouts {
    return _checkouts.where((checkout) {
      final date = DateTime.parse(checkout['checkout_date']);
      return _isInSelectedPeriod(date);
    }).toList();
  }

  bool _isInSelectedPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekMidnight =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return date.isAfter(startOfWeekMidnight) ||
            date.isAtSameMomentAs(startOfWeekMidnight);
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      case 'This Year':
        return date.year == now.year;
      case 'All Time':
      default:
        return true;
    }
  }

  double get _totalGrossSales =>
      _filteredCheckouts.fold(0, (sum, c) => sum + (c['gross_sales'] ?? 0));
  double get _totalNetTips =>
      _filteredCheckouts.fold(0, (sum, c) => sum + (c['net_tips'] ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Server Checkouts',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Column(
              children: [
                // Filter bar
                _buildFilterBar(),

                // Summary cards
                _buildSummaryCards(),

                // Checkouts list
                Expanded(
                  child: _filteredCheckouts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCheckouts.length,
                          itemBuilder: (context, index) {
                            final checkout = _filteredCheckouts[index];
                            return _buildCheckoutCard(checkout);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCheckoutOptions,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final periods = ['All Time', 'This Week', 'This Month', 'This Year'];

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
            value: _selectedPeriod,
            isExpanded: true,
            dropdownColor: AppTheme.cardBackground,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            icon:
                Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
            items: periods
                .map((period) => DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPeriod = value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Sales',
              '\$${NumberFormat('#,##0.00').format(_totalGrossSales)}',
              AppTheme.accentBlue,
              Icons.shopping_cart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Net Tips',
              '\$${NumberFormat('#,##0.00').format(_totalNetTips)}',
              AppTheme.primaryGreen,
              Icons.attach_money,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutCard(Map<String, dynamic> checkout) {
    final date = DateTime.parse(checkout['checkout_date']);
    final grossSales = (checkout['gross_sales'] ?? 0) as num;
    final netTips = (checkout['net_tips'] ?? 0) as num;
    final shiftId = checkout['shift_id'] as String?;
    final imageUrls = (checkout['image_urls'] as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutDetailScreen(checkout: checkout),
          ),
        );

        // Reload list if checkout was deleted
        if (deleted == true) {
          _loadCheckouts();
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
                    color: AppTheme.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.point_of_sale,
                      color: AppTheme.accentBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Checkout',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, yyyy').format(date),
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
                      '\$${NumberFormat('#,##0.00').format(grossSales)}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tips: \$${NumberFormat('#,##0.00').format(netTips)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (shiftId != null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _viewLinkedShift(shiftId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link,
                                  color: AppTheme.primaryGreen, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'VIEW SHIFT',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  Future<void> _viewLinkedShift(String shiftId) async {
    try {
      final response =
          await _db.supabase.from('shifts').select().eq('id', shiftId).single();

      final shift = Shift.fromMap(response);

      if (mounted) {
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

  void _showAddCheckoutOptions() {
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
                'Add Server Checkout',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: AppTheme.accentBlue),
                ),
                title: Text('Scan Checkout',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Use AI to extract data from photo',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Checkout scanning from settings coming soon!'),
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
            Icon(Icons.point_of_sale, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Checkouts Yet',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a server checkout to track tips and sales',
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
