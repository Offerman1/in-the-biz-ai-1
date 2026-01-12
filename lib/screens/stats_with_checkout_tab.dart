import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/checkout_analytics_tab.dart';
import '../widgets/paychecks_tab.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Statistics',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Checkouts'),
            Tab(text: 'Paychecks'),
          ],
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
