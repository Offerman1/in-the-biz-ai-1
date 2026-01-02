import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../theme/app_theme.dart';
import '../services/quickbooks_service.dart';

/// QuickBooks OAuth Callback Handler
/// Captures the authorization code and realm ID from URL parameters
class QuickBooksCallbackScreen extends StatefulWidget {
  const QuickBooksCallbackScreen({super.key});

  @override
  State<QuickBooksCallbackScreen> createState() => _QuickBooksCallbackScreenState();
}

class _QuickBooksCallbackScreenState extends State<QuickBooksCallbackScreen> {
  bool _isProcessing = true;
  bool _success = false;
  String _message = 'Processing QuickBooks authorization...';

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Get URL parameters
      final uri = Uri.parse(html.window.location.href);
      final code = uri.queryParameters['code'];
      final realmId = uri.queryParameters['realmId'];
      final error = uri.queryParameters['error'];

      // Check for errors
      if (error != null) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _message = 'Authorization failed: $error';
        });
        return;
      }

      // Validate parameters
      if (code == null || realmId == null) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _message = 'Missing authorization code or company ID';
        });
        return;
      }

      // Exchange code for token
      final success = await QuickBooksService.exchangeCodeForToken(code, realmId);

      setState(() {
        _isProcessing = false;
        _success = success;
        _message = success
            ? '✓ Successfully connected to QuickBooks!'
            : 'Failed to connect. Please try again.';
      });

      // Redirect back to settings after 2 seconds
      if (success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/settings', (route) => false);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _success = false;
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              if (_isProcessing)
                CircularProgressIndicator(color: AppTheme.primaryGreen)
              else
                Icon(
                  _success ? Icons.check_circle : Icons.error,
                  size: 64,
                  color: _success ? AppTheme.primaryGreen : AppTheme.accentRed,
                ),

              const SizedBox(height: 24),

              // Message
              Text(
                _message,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Action button
              if (!_isProcessing && !_success)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/settings',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Back to Settings'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
