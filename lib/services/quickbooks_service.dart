import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// QuickBooks OAuth Integration Service
/// Handles authentication and data export to QuickBooks
class QuickBooksService {
  // QuickBooks OAuth Configuration
  static const String _clientId =
      'ABt6fOUBICqYWiTeSS6cEzRqJh4p0h8T8u71i2QZH0k74TYJL6'; // Set in production
  static const String _clientSecret =
      '1E8eEnenX9BMZWWvqsJdmC6Tbk4h41Mz7hmt2VUL';
  static const String _redirectUri = 'https://inthebiz.app/quickbooks-callback';
  static const String _authEndpoint =
      'https://appcenter.intuit.com/connect/oauth2';
  static const String _tokenEndpoint =
      'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
  static const String _apiEndpoint = 'https://quickbooks.api.intuit.com/v3';

  // Storage keys
  static const String _accessTokenKey = 'qb_access_token';
  static const String _refreshTokenKey = 'qb_refresh_token';
  static const String _realmIdKey = 'qb_realm_id';
  static const String _expiresAtKey = 'qb_expires_at';

  /// Check if user is connected to QuickBooks
  static Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final expiresAt = prefs.getInt(_expiresAtKey);

    if (accessToken == null || expiresAt == null) return false;

    // Check if token is still valid (with 5 min buffer)
    final isValid =
        DateTime.now().millisecondsSinceEpoch < (expiresAt - 300000);
    return isValid;
  }

  /// Get QuickBooks OAuth URL for user to authorize
  static String getAuthorizationUrl() {
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    return '$_authEndpoint?'
        'client_id=$_clientId&'
        'scope=com.intuit.quickbooks.accounting&'
        'redirect_uri=$_redirectUri&'
        'response_type=code&'
        'state=$state';
  }

  /// Exchange authorization code for access token
  static Future<bool> exchangeCodeForToken(String code, String realmId) async {
    try {
      final credentials =
          base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          realmId: realmId,
          expiresIn: data['expires_in'],
        );
        return true;
      }

      print('Token exchange failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error exchanging code for token: $e');
      return false;
    }
  }

  /// Refresh access token using refresh token
  static Future<bool> refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null) return false;

      final credentials =
          base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          realmId: prefs.getString(_realmIdKey)!,
          expiresIn: data['expires_in'],
        );
        return true;
      }

      print('Token refresh failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  /// Save tokens to secure storage
  static Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String realmId,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_realmIdKey, realmId);
    await prefs.setInt(_expiresAtKey, expiresAt);
  }

  /// Disconnect from QuickBooks
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_realmIdKey);
    await prefs.remove(_expiresAtKey);
  }

  /// Get valid access token (refresh if needed)
  static Future<String?> _getValidAccessToken() async {
    // Check if connected
    if (!await isConnected()) {
      // Try to refresh
      final refreshed = await refreshAccessToken();
      if (!refreshed) return null;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Export invoice to QuickBooks
  static Future<bool> exportInvoice({
    required String customerName,
    required double amount,
    required DateTime invoiceDate,
    required String description,
    String? category,
  }) async {
    try {
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) {
        print('Not connected to QuickBooks');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final realmId = prefs.getString(_realmIdKey);

      // Create invoice payload
      final invoicePayload = {
        'Line': [
          {
            'Amount': amount,
            'DetailType': 'SalesItemLineDetail',
            'SalesItemLineDetail': {
              'ItemRef': {
                'value': '1', // Use default service item
              },
            },
            'Description': description,
          }
        ],
        'CustomerRef': {
          'name': customerName,
        },
        'TxnDate': invoiceDate.toIso8601String().split('T')[0],
        'DueDate': invoiceDate
            .add(const Duration(days: 30))
            .toIso8601String()
            .split('T')[0],
      };

      final response = await http.post(
        Uri.parse('$_apiEndpoint/company/$realmId/invoice'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(invoicePayload),
      );

      if (response.statusCode == 200) {
        print('Invoice exported successfully');
        return true;
      }

      print('Invoice export failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error exporting invoice: $e');
      return false;
    }
  }

  /// Export shifts as sales receipts to QuickBooks
  static Future<bool> exportShiftsAsSalesReceipts({
    required List<Map<String, dynamic>> shifts,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) {
        print('Not connected to QuickBooks');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final realmId = prefs.getString(_realmIdKey);

      int successCount = 0;

      for (final shift in shifts) {
        final salesReceiptPayload = {
          'Line': [
            {
              'Amount': shift['total_income'],
              'DetailType': 'SalesItemLineDetail',
              'SalesItemLineDetail': {
                'ItemRef': {
                  'value': '1', // Service item
                },
              },
              'Description': '${shift['job_name']} - Tips & Wages',
            }
          ],
          'CustomerRef': {
            'name': shift['job_name'] ?? 'Restaurant Income',
          },
          'TxnDate': shift['date'].toString().split(' ')[0],
          'PrivateNote': 'Imported from In The Biz AI',
        };

        final response = await http.post(
          Uri.parse('$_apiEndpoint/company/$realmId/salesreceipt'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(salesReceiptPayload),
        );

        if (response.statusCode == 200) {
          successCount++;
        }
      }

      print('Exported $successCount/${shifts.length} shifts to QuickBooks');
      return successCount > 0;
    } catch (e) {
      print('Error exporting shifts: $e');
      return false;
    }
  }

  /// Get connected company info
  static Future<Map<String, dynamic>?> getCompanyInfo() async {
    try {
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) return null;

      final prefs = await SharedPreferences.getInstance();
      final realmId = prefs.getString(_realmIdKey);

      final response = await http.get(
        Uri.parse('$_apiEndpoint/company/$realmId/companyinfo/$realmId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['CompanyInfo'];
      }

      return null;
    } catch (e) {
      print('Error getting company info: $e');
      return null;
    }
  }
}
