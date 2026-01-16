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

  // RevenueCat API Keys
  final String _apiKeyAndroid = 'goog_kMppRJiBRaqDErscdbnFLUQWVBV';
  final String _apiKeyIOS = 'appl_bzMdtppQclnCntUMWzQdwZHPTiu';

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

  // Note: purchasePackage is deprecated but still works. The new API requires PurchaseParams.
  // ignore: deprecated_member_use
  Future<bool> purchasePackage(Package package) async {
    try {
      // ignore: deprecated_member_use
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
      final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

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

  /// Grant Pro access by user ID (admin function)
  Future<bool> grantProAccessByUserId(String userId, String notes) async {
    try {
      // Get user email using database function
      final emailResponse = await Supabase.instance.client
          .rpc('get_user_email', params: {'user_uuid': userId});

      if (emailResponse == null) {
        debugPrint('User not found with ID: $userId');
        return false;
      }

      final email = emailResponse as String;
      final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

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

  /// Revoke Pro access by user ID (admin function)
  Future<bool> revokeProAccessByUserId(String userId) async {
    try {
      await Supabase.instance.client
          .from('pro_users')
          .delete()
          .eq('user_id', userId);
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

  /// Get subscription analytics (admin function)
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      // Get admin-level analytics from database
      final proUsersResponse = await Supabase.instance.client
          .from('pro_users')
          .select('id, granted_at, granted_by');

      final proUsers = List<Map<String, dynamic>>.from(proUsersResponse);

      // Count manually granted Pro users
      final manuallyGrantedCount = proUsers.length;

      // Count users granted by admin vs system
      final adminGrantedCount = proUsers
          .where((u) => u['granted_by'] != null && u['granted_by'] != 'system')
          .length;

      // Get total user count
      final profilesCount =
          await Supabase.instance.client.from('profiles').select('id').count();

      final totalUsers = profilesCount.count;

      return {
        'total_users': totalUsers,
        'pro_users_admin_granted': adminGrantedCount,
        'pro_users_paid': 0, // TODO: Get from RevenueCat when integrated
        'free_users_count': totalUsers - manuallyGrantedCount,
      };
    } catch (e) {
      debugPrint('Error fetching subscription analytics: $e');
      return {
        'total_users': 0,
        'pro_users_count': 0,
        'error': e.toString(),
      };
    }
  }
}
