// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/main_shell.dart';
import 'screens/forgot_password_screen.dart';
import 'widgets/common_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:developer';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      log("Logged in: ${user.email}");
    } else {
      log("Logged out");
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const FlameGuardApp(),
    ),
  );
}


class FlameGuardApp extends StatelessWidget {
  const FlameGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return MaterialApp(
      title: 'FlameGuard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(colors),
      scrollBehavior: const _NoOverscrollBehavior(),
      builder: (context, child) {
        return MediaQuery(
          // Lock text scaling to 1.0 to ensure consistent UI across devices
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      home: const _Router(),
    );
  }
}

// ─── GLOBAL SCROLL BEHAVIOR ───────────────────────────────────────────────────
class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

// ─── ROUTER ───────────────────────────────────────────────────────────────────
enum _Screen {
  splash,
  onboard0,
  onboard1,
  login,
  signup,
  verify,
  main,
  forgotPassword
}

class _Router extends StatefulWidget {
  const _Router();

  @override
  State<_Router> createState() => _RouterState();
}

class _RouterState extends State<_Router> {
  _Screen _screen = _Screen.splash;
  final String _email = '';

  void _go(_Screen s) => setState(() => _screen = s);

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: KeyedSubtree(
        key: ValueKey(_screen),
        child: _buildScreen(c),
      ),
    );
  }

  Widget _buildScreen(AppColors c) {
    switch (_screen) {
      case _Screen.splash:
        return SplashScreen(onDone: () => _go(_Screen.onboard0));

      case _Screen.onboard0:
        return OnboardingScreen(
          step: 0,
          onNext: () => _go(_Screen.onboard1),
          onSkip: () => _go(_Screen.login),
        );

      case _Screen.onboard1:
        return OnboardingScreen(
          step: 1,
          onNext: () => _go(_Screen.login),
          onSkip: () => _go(_Screen.login),
        );

      case _Screen.login:
        return LoginScreen(
          onLogin: () => _go(_Screen.verify),
          onGoSignUp: () => _go(_Screen.signup),
          onForgotPassword: () => _go(_Screen.forgotPassword),
        );

      case _Screen.signup:
        return SignUpScreen(
          onSignUp: () => _go(_Screen.verify),
          onGoLogin: () => _go(_Screen.login),
        );

      case _Screen.verify:
        return VerifyScreen(
          email: _email.isEmpty ? 'juan@email.com' : _email,
          onVerified: () => _go(_Screen.main),
          onBack: () => _go(_Screen.login),
        );

      case _Screen.forgotPassword:
        return ForgotPasswordScreen(
          onBack: () => _go(_Screen.login),
          onDone: () => _go(_Screen.login),
        );

      case _Screen.main:
        return MainShell(
          onSignOut: () => _go(_Screen.login),
        );
    }
  }
}