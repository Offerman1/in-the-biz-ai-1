import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isPro = false;
  bool get isPro => _isPro;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  List<Package> _offerings = [];
  List<Package> get offerings => _offerings;

  // TODO: Replace with your actual RevenueCat API Keys
  final String _apiKeyAndroid = 'goog_placeholder_api_key';
  final String _apiKeyIOS = 'appl_placeholder_api_key';

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      await _checkSubscriptionStatus();
      await _fetchOfferings();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _customerInfo = customerInfo;
      // Check if the user has an active entitlement named "pro"
      // You must configure this Entitlement in RevenueCat dashboard
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        _offerings = offerings.current!.availablePackages;
        notifyListeners();
      }
    } on PlatformException catch (e) {
      debugPrint('Error fetching offerings: $e');
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _customerInfo = customerInfo;
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
      notifyListeners();
      return _isPro;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Error purchasing package: $e');
      }
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
      notifyListeners();
      return _isPro;
    } on PlatformException catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }
}
