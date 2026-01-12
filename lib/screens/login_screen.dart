import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

// Conditional import for web
import 'login_screen_web_stub.dart'
    if (dart.library.html) 'package:google_sign_in_web/web_only.dart' as web;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;
  bool _showResendConfirmation = false; // Show resend button after signup
  bool _isResending = false; // Loading state for resend

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeGoogleSignInWeb();
    }
  }

  Future<void> _initializeGoogleSignInWeb() async {
    try {
      // Initialize GoogleSignIn (scopes are requested during authorization, not here)
      await GoogleSignIn.instance.initialize(
        clientId:
            '30441285456-pkvqkagh3fcv0b6n71t5tpnuda94l8d5.apps.googleusercontent.com',
        serverClientId:
            '30441285456-pkvqkagh3fcv0b6n71t5tpnuda94l8d5.apps.googleusercontent.com',
      );

      GoogleSignIn.instance.authenticationEvents.listen((event) async {
        // Handle sign-in event
        if (event is GoogleSignInAuthenticationEventSignIn) {
          if (!mounted) return;

          // Set loading state immediately when user selects account
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });

          try {
            final user = event.user;
            final googleAuth = user.authentication;

            if (googleAuth.idToken != null) {
              // No nonce - simpler flow
              final response = await AuthService.signInWithIdToken(
                idToken: googleAuth.idToken!,
                nonce: null, // Skip nonce
              );

              if (response != null && mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              }
            }
          } catch (e) {
            print('Supabase sign-in error: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Sign-in failed: $e';
                _isLoading = false;
              });
            }
          }
        }
      });
    } catch (e) {
      print('Failed to initialize Google Sign-In: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.signInWithGoogle();
      if (response != null && mounted) {
        // Manually navigate to dashboard after successful sign-in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        // Show success message after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Signed in successfully!'),
                backgroundColor: AppTheme.primaryGreen,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showResendConfirmation = false;
    });

    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _showResendConfirmation = true; // Show resend button
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Check your email to confirm your account!'),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        await AuthService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = _friendlyErrorMessage(errorStr);
        // If error mentions email confirmation, show resend button
        if (errorStr.toLowerCase().contains('confirm') ||
            errorStr.toLowerCase().contains('verify') ||
            errorStr.toLowerCase().contains('email')) {
          _showResendConfirmation = true;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Convert technical error messages to user-friendly ones
  String _friendlyErrorMessage(String error) {
    if (error.contains('AuthRetryableFetchException')) {
      return 'We\'re having trouble connecting. Please check your internet and try again.';
    }
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please confirm your email before signing in. Check your inbox!';
    }
    if (error.contains('User already registered')) {
      return 'This email is already registered. Try signing in instead.';
    }
    return error;
  }

  /// Resend confirmation email
  Future<void> _resendConfirmationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address'),
          backgroundColor: AppTheme.accentYellow,
        ),
      );
      return;
    }

    setState(() => _isResending = true);

    try {
      await AuthService.resendConfirmationEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Confirmation email sent! Check your inbox.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not send email. Please try again later.'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.2 : 24.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Logo / App Name
              Center(
                child: Column(
                  children: [
                    // Your actual logo
                    Image.asset(
                      'assets/icon/app_icon.png',
                      width: isTablet ? 240 : 120,
                      height: isTablet ? 240 : 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'In The Biz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 40 : 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome,
                            size: isTablet ? 32 : 24,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen.withValues(alpha: 0.3),
                            AppTheme.primaryGreen.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.accentBlue,
                            AppTheme.primaryGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'TIPS AND INCOME TRACKER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 16 : 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Subtitle
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: AppTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Start tracking your income today'
                    : 'Sign in to continue',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Google Sign In Button
              Center(child: _buildGoogleButton()),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.cardBackgroundLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: AppTheme.labelSmall),
                  ),
                  Expanded(child: Divider(color: AppTheme.cardBackgroundLight)),
                ],
              ),

              const SizedBox(height: 24),

              // Email/Password Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outlined,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border:
                        Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.accentRed),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy,
                            color: AppTheme.accentRed, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _errorMessage!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy error',
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              // Resend Confirmation Email Button (shows after signup or confirmation-related errors)
              if (_showResendConfirmation)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mark_email_read,
                              color: AppTheme.primaryGreen, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Didn\'t receive the email? Check your spam folder or resend it.',
                              style: AppTheme.bodyMedium
                                  .copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isResending ? null : _resendConfirmationEmail,
                          icon: _isResending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGreen,
                                  ),
                                )
                              : const Icon(Icons.send, size: 18),
                          label: Text(_isResending
                              ? 'Sending...'
                              : 'Resend Confirmation Email'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: BorderSide(color: AppTheme.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Sign In / Sign Up Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle Sign In / Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: AppTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Terms
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: AppTheme.labelSmall.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    if (kIsWeb) {
      // Web: Use Google's official button widget
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: web.renderButton(),
      );
    }

    // Mobile: Custom button that calls authenticate()
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _signInWithGoogle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Official Google "G" logo colors
                Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image doesn't load
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          // Multi-color G logo approximation
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GoogleLogoPainter(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: AppTheme.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyMedium,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.cardBackgroundLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.primaryGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.accentRed),
        ),
      ),
    );
  }
}

// Custom painter for Google logo fallback
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Simplified multi-color G
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Blue section
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.5, 1.5, true, paint);

    // Red section
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.5, 1.0, true, paint);

    // Yellow section
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.5, 1.0, true, paint);

    // Green section
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.0, 1.5, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
