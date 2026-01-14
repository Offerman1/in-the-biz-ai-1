import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/invoice.dart';
import '../models/receipt.dart';
import '../models/shift.dart';
import '../screens/single_shift_detail_screen.dart';

/// Invoices & Receipts management screen
/// Shows all invoices and receipts with filters
class InvoicesReceiptsScreen extends StatefulWidget {
  const InvoicesReceiptsScreen({super.key});

  @override
  State<InvoicesReceiptsScreen> createState() => _InvoicesReceiptsScreenState();
}

class _InvoicesReceiptsScreenState extends State<InvoicesReceiptsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Invoice> _invoices = [];
  List<Receipt> _receipts = [];

  // Filter state
  String _selectedPeriod = 'All Time';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _db.supabase.auth.currentUser!.id;

      // Load invoices
      final invoicesResponse = await _db.supabase
          .from('invoices')
          .select()
          .eq('user_id', userId)
          .order('invoice_date', ascending: false);

      // Load receipts
      final receiptsResponse = await _db.supabase
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .order('receipt_date', ascending: false);

      setState(() {
        _invoices = (invoicesResponse as List)
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
            .toList();
        _receipts = (receiptsResponse as List)
            .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading invoices/receipts: $e');
      setState(() => _isLoading = false);
    }
  }

  // Calculate totals based on filtered data
  List<Invoice> get _filteredInvoices {
    return _invoices.where((invoice) {
      // Apply period filter
      if (!_isInSelectedPeriod(invoice.invoiceDate)) return false;
      return true;
    }).toList();
  }

  List<Receipt> get _filteredReceipts {
    return _receipts.where((receipt) {
      // Apply period filter
      if (!_isInSelectedPeriod(receipt.receiptDate)) return false;
      // Apply category filter
      if (_selectedCategory != null && _selectedCategory != 'All') {
        if (receipt.expenseCategory != _selectedCategory) return false;
      }
      return true;
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

  double get _totalInvoiceAmount =>
      _filteredInvoices.fold(0, (sum, i) => sum + i.totalAmount);
  double get _totalReceiptAmount =>
      _filteredReceipts.fold(0, (sum, r) => sum + r.totalAmount);
  double get _totalDeductibleAmount => _filteredReceipts
      .where((r) => r.isTaxDeductible)
      .fold(0, (sum, r) => sum + r.totalAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Invoices & Receipts',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(
                text:
                    'All (${_filteredInvoices.length + _filteredReceipts.length})'),
            Tab(text: 'Invoices (${_filteredInvoices.length})'),
            Tab(text: 'Receipts (${_filteredReceipts.length})'),
          ],
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

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(),
                      _buildInvoicesTab(),
                      _buildReceiptsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDocumentOptions,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Document',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddDocumentOptions() {
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
                'Add Invoice or Receipt',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: AppTheme.accentPurple),
                ),
                title: Text('Scan Document',
                    style: AppTheme.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Use AI to extract invoice/receipt data',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Document scanning from settings coming soon!'),
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

  Widget _buildFilterBar() {
    final periods = ['All Time', 'This Week', 'This Month', 'This Year'];
    final categories = [
      'All',
      'Materials',
      'Equipment',
      'Travel',
      'Meals',
      'Supplies',
      'Marketing',
      'Utilities',
      'Other'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Period filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.textMuted.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardBackground,
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary),
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
          ),
          const SizedBox(width: 12),
          // Category filter (for receipts)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.textMuted.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory ?? 'All',
                  isExpanded: true,
                  dropdownColor: AppTheme.cardBackground,
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary),
                  items: categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() =>
                        _selectedCategory = value == 'All' ? null : value);
                  },
                ),
              ),
            ),
          ),
        ],
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
              'Invoices',
              '\$${NumberFormat('#,##0.00').format(_totalInvoiceAmount)}',
              AppTheme.primaryGreen,
              Icons.receipt_long,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Expenses',
              '\$${NumberFormat('#,##0.00').format(_totalReceiptAmount)}',
              AppTheme.dangerColor,
              Icons.shopping_cart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Deductible',
              '\$${NumberFormat('#,##0.00').format(_totalDeductibleAmount)}',
              AppTheme.accentBlue,
              Icons.savings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
                color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    final allItems = <_DocumentItem>[];

    for (final invoice in _filteredInvoices) {
      allItems.add(_DocumentItem(
        type: 'invoice',
        date: invoice.invoiceDate,
        title: invoice.clientName,
        subtitle: 'Invoice ${invoice.invoiceNumber ?? ''}',
        amount: invoice.totalAmount,
        currency: invoice.currency,
        status: invoice.status.value,
      ));
    }

    for (final receipt in _filteredReceipts) {
      allItems.add(_DocumentItem(
        type: 'receipt',
        date: receipt.receiptDate,
        title: receipt.vendorName,
        subtitle: receipt.expenseCategory ?? 'Other',
        amount: receipt.totalAmount,
        currency: receipt.currency,
        isDeductible: receipt.isTaxDeductible,
      ));
    }

    // Sort by date descending
    allItems.sort((a, b) => b.date.compareTo(a.date));

    if (allItems.isEmpty) {
      return _buildEmptyState('No documents yet',
          'Scan your first invoice or receipt to get started.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: allItems.length,
      itemBuilder: (context, index) => _buildDocumentCard(allItems[index]),
    );
  }

  Widget _buildInvoicesTab() {
    if (_filteredInvoices.isEmpty) {
      return _buildEmptyState(
          'No invoices yet', 'Scan an invoice to track client payments.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredInvoices.length,
      itemBuilder: (context, index) {
        final invoice = _filteredInvoices[index];
        return _buildDocumentCard(_DocumentItem(
          type: 'invoice',
          date: invoice.invoiceDate,
          title: invoice.clientName,
          subtitle: 'Invoice ${invoice.invoiceNumber ?? ''}',
          amount: invoice.totalAmount,
          currency: invoice.currency,
          status: invoice.status.value,
          shiftId: invoice.shiftId,
        ));
      },
    );
  }

  Widget _buildReceiptsTab() {
    if (_filteredReceipts.isEmpty) {
      return _buildEmptyState('No receipts yet',
          'Scan a receipt to track expenses and deductions.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredReceipts.length,
      itemBuilder: (context, index) {
        final receipt = _filteredReceipts[index];
        return _buildDocumentCard(_DocumentItem(
          type: 'receipt',
          date: receipt.receiptDate,
          title: receipt.vendorName,
          subtitle: receipt.expenseCategory ?? 'Other',
          amount: receipt.totalAmount,
          currency: receipt.currency,
          isDeductible: receipt.isTaxDeductible,
          shiftId: receipt.shiftId,
        ));
      },
    );
  }

  Widget _buildDocumentCard(_DocumentItem item) {
    final isInvoice = item.type == 'invoice';
    final color = isInvoice ? AppTheme.primaryGreen : AppTheme.accentOrange;
    final icon = isInvoice ? Icons.receipt_long : Icons.shopping_cart;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.subtitle,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(item.date),
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,##0.00').format(item.amount)}',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.status != null) ...[
                const SizedBox(height: 4),
                _buildStatusBadge(item.status!),
              ],
              if (item.isDeductible == true) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DEDUCTIBLE',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentPurple,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              if (item.shiftId != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _viewLinkedShift(item.shiftId!),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.5),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppTheme.successColor;
        break;
      case 'overdue':
        color = AppTheme.dangerColor;
        break;
      case 'cancelled':
        color = AppTheme.textMuted;
        break;
      default:
        color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

/// Helper class for unified document display
class _DocumentItem {
  final String type; // 'invoice' or 'receipt'
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final String? status;
  final bool? isDeductible;
  final String? shiftId; // Link to shift

  _DocumentItem({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    this.status,
    this.isDeductible,
    this.shiftId,
  });
}
