import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/invoice.dart';
import '../models/receipt.dart';

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

  // Calculate totals
  double get _totalInvoiceAmount =>
      _invoices.fold(0, (sum, i) => sum + i.totalAmount);
  double get _totalReceiptAmount =>
      _receipts.fold(0, (sum, r) => sum + r.totalAmount);
  double get _totalDeductibleAmount => _receipts
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
            Tab(text: 'All (${_invoices.length + _receipts.length})'),
            Tab(text: 'Invoices (${_invoices.length})'),
            Tab(text: 'Receipts (${_receipts.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Column(
              children: [
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

    for (final invoice in _invoices) {
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

    for (final receipt in _receipts) {
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
    if (_invoices.isEmpty) {
      return _buildEmptyState(
          'No invoices yet', 'Scan an invoice to track client payments.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return _buildDocumentCard(_DocumentItem(
          type: 'invoice',
          date: invoice.invoiceDate,
          title: invoice.clientName,
          subtitle: 'Invoice ${invoice.invoiceNumber ?? ''}',
          amount: invoice.totalAmount,
          currency: invoice.currency,
          status: invoice.status.value,
        ));
      },
    );
  }

  Widget _buildReceiptsTab() {
    if (_receipts.isEmpty) {
      return _buildEmptyState('No receipts yet',
          'Scan a receipt to track expenses and deductions.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final receipt = _receipts[index];
        return _buildDocumentCard(_DocumentItem(
          type: 'receipt',
          date: receipt.receiptDate,
          title: receipt.vendorName,
          subtitle: receipt.expenseCategory ?? 'Other',
          amount: receipt.totalAmount,
          currency: receipt.currency,
          isDeductible: receipt.isTaxDeductible,
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
        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Deductible',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentBlue,
                      fontSize: 10,
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
        color: color.withOpacity(0.2),
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

  _DocumentItem({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    this.status,
    this.isDeductible,
  });
}
