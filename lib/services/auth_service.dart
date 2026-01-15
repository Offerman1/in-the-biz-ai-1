import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  // OAuth Client IDs from Google Cloud Console
  // App name "In The Biz AI" is configured in OAuth consent screen
  static const String _webClientId =
      '30441285456-pkvqkagh3fcv0b6n71t5tpnuda94l8d5.apps.googleusercontent.com';

  // Android OAuth clients - different for debug vs release builds
  static const String _androidDebugClientId =
      '30441285456-5a965980027k9dbq3ati2cjald8ou2hd.apps.googleusercontent.com'; // Debug SHA-1
  static const String _androidReleaseClientId =
      '30441285456-d1e0f38r07vghj3kf3u7c8am25p1cmk3.apps.googleusercontent.com'; // Release SHA-1

  static const String _iosClientId =
      '30441285456-9ea4rfqkepbjigq8jku8qkamr8abap3r.apps.googleusercontent.com';

  // Calendar scopes for Google Calendar API
  static const List<String> calendarScopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events',
  ];

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Auth state stream
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Sign in with Google using native Google Sign-In
  /// Shows "In The Biz AI" as the app name in Google's consent screen
  /// Works on Android and iOS with the new google_sign_in 7.x API
  /// Note: Web must use renderButton() - see login_screen.dart
  static Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      // Web doesn't support authenticate() - must use renderButton()
      throw UnimplementedError(
        'On web, use GoogleSignIn.instance.authenticationEvents stream '
        'and display the button from web.renderButton() instead.',
      );
    }

    // Mobile: Use authenticate() method with initialization
    try {
      String? clientId;

      if (Platform.isIOS) {
        clientId = _iosClientId;
      } else if (Platform.isAndroid) {
        // Use different OAuth client for debug vs release builds
        clientId = kDebugMode ? _androidDebugClientId : _androidReleaseClientId;
      }

      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: _webClientId,
      );

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Sign in to Supabase with the ID token
      // This may throw an error but still save the session
      try {
        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
        );
        return response;
      } catch (e) {
        // Check if user is actually logged in despite the error
        // (Supabase sometimes throws 400 but still authenticates)
        if (_supabase.auth.currentUser != null) {
          // User is logged in - return success
          return _supabase.auth.currentSession as AuthResponse?;
        }
        // Otherwise re-throw the error
        rethrow;
      }
    } catch (e) {
      // Check final state: if user got logged in despite error, don't fail
      if (_supabase.auth.currentUser != null) {
        return _supabase.auth.currentSession as AuthResponse?;
      }
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign in with Google ID token (for web authentication events)
  static Future<AuthResponse?> signInWithIdToken({
    required String idToken,
    String? nonce,
  }) async {
    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: nonce,
    );
  }

  /// Sign in with Apple
  /// Works on Android, iOS, and Web
  static Future<AuthResponse?> signInWithApple() async {
    try {
      // Use Supabase's built-in OAuth flow instead of sign_in_with_apple package
      // This handles redirects properly on all platforms
      final result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb
            ? 'https://inthebiz.app'
            : 'io.supabase.inthebizai://login-callback',
      );

      if (!result) {
        throw Exception('Apple sign-in was cancelled or failed');
      }

      return _supabase.auth.currentSession as AuthResponse?;
    } catch (e) {
      // Check if user is actually logged in despite the error
      if (_supabase.auth.currentUser != null) {
        return _supabase.auth.currentSession as AuthResponse?;
      }
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Resend confirmation email
  static Future<void> resendConfirmationEmail(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Get user display name
  static String? get displayName {
    final user = currentUser;
    if (user == null) return null;
    return user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email?.split('@').first;
  }

  /// Get user avatar URL
  static String? get avatarUrl {
    final user = currentUser;
    if (user == null) return null;
    return user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;
  }
}
