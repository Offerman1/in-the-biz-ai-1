import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isPro = false;
  bool get isPro => _isPro || _isDebugProMode || _isManuallyGrantedPro;

  bool _isDebugProMode = false;
  bool get isDebugProMode => _isDebugProMode;

  bool _isManuallyGrantedPro = false;
  bool get isManuallyGrantedPro => _isManuallyGrantedPro;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  List<Package> _offerings = [];
  List<Package> get offerings => _offerings;

  // TODO: Replace with your actual RevenueCat API Keys
  final String _apiKeyAndroid = 'goog_placeholder_api_key';
  final String _apiKeyIOS = 'appl_placeholder_api_key';

  Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);

    // Load debug Pro mode setting
    final prefs = await SharedPreferences.getInstance();
    _isDebugProMode = prefs.getBool('debug_pro_mode') ?? false;

    // Check if user has manually granted Pro access
    await _checkManualProAccess();

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
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        _offerings = offerings.current!.availablePackages;
        notifyListeners();
      }
    } on PlatformException catch (e) {
      debugPrint('Error fetching offerings: $e');
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      _customerInfo = purchaseResult.customerInfo;
      _isPro = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ??
          false;
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

  /// Toggle debug Pro mode (for testing/admin use)
  Future<void> setDebugProMode(bool enabled) async {
    _isDebugProMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_pro_mode', enabled);
    notifyListeners();
  }

  /// Check if user has manually granted Pro access from database
  Future<void> _checkManualProAccess() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _isManuallyGrantedPro = false;
        return;
      }

      final response = await Supabase.instance.client
          .from('pro_users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      _isManuallyGrantedPro = response != null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking manual Pro access: $e');
      _isManuallyGrantedPro = false;
    }
  }

  /// Grant Pro access to a user (admin function)
  Future<bool> grantProAccess(String email, String notes) async {
    try {
      // Find user by email
      final users = await Supabase.instance.client
          .from('auth.users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (users == null) {
        debugPrint('User not found with email: $email');
        return false;
      }

      final userId = users['id'];
      final currentUserEmail =
          Supabase.instance.client.auth.currentUser?.email;

      await Supabase.instance.client.from('pro_users').upsert({
        'user_id': userId,
        'email': email,
        'granted_by': currentUserEmail,
        'notes': notes,
      });

      return true;
    } catch (e) {
      debugPrint('Error granting Pro access: $e');
      return false;
    }
  }

  /// Revoke Pro access from a user (admin function)
  Future<bool> revokeProAccess(String email) async {
    try {
      await Supabase.instance.client
          .from('pro_users')
          .delete()
          .eq('email', email);
      return true;
    } catch (e) {
      debugPrint('Error revoking Pro access: $e');
      return false;
    }
  }

  /// Get list of all manually granted Pro users (admin function)
  Future<List<Map<String, dynamic>>> getProUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('pro_users')
          .select()
          .order('granted_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching Pro users: $e');
      return [];
    }
  }
}
