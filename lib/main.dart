import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_the_biz_ai/screens/dashboard_screen.dart';
import 'package:in_the_biz_ai/screens/login_screen.dart';
import 'package:in_the_biz_ai/screens/onboarding_screen.dart';
import 'package:in_the_biz_ai/screens/settings_screen.dart';
import 'package:in_the_biz_ai/screens/quickbooks_callback_screen.dart';
import 'package:in_the_biz_ai/providers/shift_provider.dart';
import 'package:in_the_biz_ai/providers/theme_provider.dart';
import 'package:in_the_biz_ai/providers/field_order_provider.dart';
import 'package:in_the_biz_ai/services/database_service.dart';
import 'package:in_the_biz_ai/services/notification_service.dart';
import 'package:in_the_biz_ai/services/ad_service.dart';
import 'package:in_the_biz_ai/services/subscription_service.dart';
import 'package:in_the_biz_ai/utils/run_migrations.dart';
import 'dart:developer' as developer;

// App version - update this when deploying (matches pubspec.yaml)
const String appVersion = '1.2.0+11';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log app version to console (web only)
  if (kIsWeb) {
    developer.log('🚀 In The Biz AI - Version: $appVersion', name: 'App');
    // Also log to browser console
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
    // ignore: avoid_print
    print('🚀 In The Biz AI');
    // ignore: avoid_print
    print('📦 Version: $appVersion');
    // ignore: avoid_print
    print('⏰ Deployed: ${DateTime.now().toIso8601String()}');
    // ignore: avoid_print
    print('═══════════════════════════════════════════');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bokdjidrybwxbomemmrg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJva2RqaWRyeWJ3eGJvbWVtbXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2Mjc1MzcsImV4cCI6MjA4MjIwMzUzN30.SVdK-fKrQklp76pGozuaDyNsgp2vkwWfNYtdmDRjChs',
  );

  // Initialize notifications
  await NotificationService().initialize();

  // Initialize AdMob (mobile only)
  if (!kIsWeb) {
    await AdService().initialize();
  }

  // Initialize Subscription Service (mobile only)
  if (!kIsWeb) {
    await SubscriptionService().initialize();
  }

  // Configure system UI for edge-to-edge mode (Android)
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  // Run database migrations
  await runMigrations();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FieldOrderProvider()),
        // Only provide SubscriptionService on mobile
        if (!kIsWeb)
          ChangeNotifierProvider(create: (_) => SubscriptionService()),
      ],
      child: const InTheBizApp(),
    ),
  );
}

class InTheBizApp extends StatelessWidget {
  const InTheBizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Update system UI whenever theme changes (non-web only)
        if (!kIsWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeProvider.updateSystemUI();
          });
        }

        return MaterialApp(
          title: 'In The Biz AI',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getThemeData(),
          home: kIsWeb
              ? const ResponsiveWebLayout(child: AuthWrapper())
              : const AuthWrapper(),
          routes: {
            '/settings': (context) => kIsWeb
                ? const ResponsiveWebLayout(child: SettingsScreen())
                : const SettingsScreen(),
            '/quickbooks-callback': (context) => kIsWeb
                ? const ResponsiveWebLayout(child: QuickBooksCallbackScreen())
                : const QuickBooksCallbackScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle /quickbooks-callback route for web
            if (settings.name == '/quickbooks-callback') {
              return MaterialPageRoute(
                builder: (context) => kIsWeb
                    ? const ResponsiveWebLayout(
                        child: QuickBooksCallbackScreen())
                    : const QuickBooksCallbackScreen(),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

/// Responsive layout wrapper for web that adds horizontal padding on desktop
/// Background colors/gradients extend full-width naturally
class ResponsiveWebLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveWebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow screens (mobile/tablet), show full width
        if (constraints.maxWidth <= 1600) {
          return child;
        }

        // On desktop, add horizontal padding to constrain content
        // Background extends full-width naturally
        final horizontalPadding = (constraints.maxWidth - 1200) / 2;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        );
      },
    );
  }
}

/// Wrapper that shows login, onboarding, or dashboard based on state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check if user is logged in
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // User is logged in - check onboarding status
          return const OnboardingChecker();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Checks if user has completed onboarding
class OnboardingChecker extends StatefulWidget {
  const OnboardingChecker({super.key});

  @override
  State<OnboardingChecker> createState() => _OnboardingCheckerState();
}

class _OnboardingCheckerState extends State<OnboardingChecker> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final db = DatabaseService();
      final completed = await db.hasCompletedOnboarding();
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If error, assume onboarding is complete to not block user
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D632)),
        ),
      );
    }

    if (_hasCompletedOnboarding) {
      return const DashboardScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}
