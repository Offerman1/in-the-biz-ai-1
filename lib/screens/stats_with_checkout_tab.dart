import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/checkout_analytics_tab.dart';
import '../widgets/paychecks_tab.dart';
import '../providers/shift_provider.dart';
import '../services/export_service.dart';
import 'stats_screen.dart';

/// Wrapper for Stats Screen that adds Checkout Analytics and Paychecks as tabs
class StatsWithCheckoutTab extends StatefulWidget {
  const StatsWithCheckoutTab({super.key});

  @override
  State<StatsWithCheckoutTab> createState() => _StatsWithCheckoutTabState();
}

class _StatsWithCheckoutTabState extends State<StatsWithCheckoutTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleExport(BuildContext context, String type) async {
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final shifts = shiftProvider.shifts;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      String? filePath;

      if (type == 'csv') {
        filePath = await ExportService.exportToCSV(
          shifts: shifts,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
      } else if (type == 'pdf') {
        filePath = await ExportService.exportToPDF(
          shifts: shifts,
          startDate: startOfMonth,
          endDate: endOfMonth,
          title: 'Income Report - ${DateFormat('MMMM yyyy').format(now)}',
        );
      }

      if (filePath != null && context.mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'In The Biz AI - ${type.toUpperCase()} Report',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        toolbarHeight: 48, // Space for export button
        title: const SizedBox.shrink(), // No title
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.ios_share, color: AppTheme.primaryGreen),
            color: AppTheme.cardBackground,
            onSelected: (value) => _handleExport(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart,
                        size: 20, color: AppTheme.adaptiveTextColor),
                    const SizedBox(width: 12),
                    Text('Export CSV',
                        style: TextStyle(color: AppTheme.adaptiveTextColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf,
                        size: 20, color: AppTheme.adaptiveTextColor),
                    const SizedBox(width: 12),
                    Text('Export PDF',
                        style: TextStyle(color: AppTheme.adaptiveTextColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Checkouts'),
                Tab(text: 'Paychecks'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Original Stats Screen content (without AppBar)
          StatsScreen(),

          // Checkout Analytics Tab
          CheckoutAnalyticsTab(),

          // Paychecks Tab
          PaychecksTab(),
        ],
      ),
    );
  }
}
