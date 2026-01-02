import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:in_the_biz_ai/services/subscription_service.dart';
import 'package:in_the_biz_ai/theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final offerings = subscriptionService.offerings;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.star,
              size: 80,
              color: AppTheme.accentYellow,
            ),
            const SizedBox(height: 24),
            const Text(
              'Upgrade to Pro',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlock the full potential of In The Biz AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureItem('Unlimited Shifts'),
            _buildFeatureItem('Unlimited Photos & Videos'),
            _buildFeatureItem('Unlimited AI Chat & Vision'),
            _buildFeatureItem('Ad-Free Experience'),
            _buildFeatureItem('Export to PDF/CSV'),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator(color: AppTheme.primaryGreen)
            else if (offerings.isEmpty)
              const Text(
                'No offerings available. Please check configuration.',
                style: TextStyle(color: Colors.red),
              )
            else
              ...offerings.map((package) => _buildPackageButton(context, package)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                final success = await subscriptionService.restorePurchases();
                setState(() => _isLoading = false);
                if (success && mounted) {
                  Navigator.of(context).pop();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No purchases to restore found.')),
                  );
                }
              },
              child: const Text(
                'Restore Purchases',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Terms of Service • Privacy Policy',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageButton(BuildContext context, Package package) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            setState(() => _isLoading = true);
            final success = await subscriptionService.purchasePackage(package);
            setState(() => _isLoading = false);
            if (success && mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Column(
            children: [
              Text(
                package.storeProduct.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                package.storeProduct.priceString,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
