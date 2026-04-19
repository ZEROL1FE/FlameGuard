import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/scroll_physics.dart';
import '../models/app_state.dart';


class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onGoSignUp;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onGoSignUp,
    required this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  String? _err;

  void _submit() {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _err = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _err = null;
      _loading = true;
    });

    final state = context.read<AppState>();

    state.loginWithEmail(_email.text, _pass.text).then((success) {
      if (!mounted) return;

      setState(() => _loading = false);

      if (success) {
        widget.onLogin();
      } else {
        setState(() => _err = 'Invalid email or password');
      }
    }).catchError((e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _err = 'Login failed: $e';
      });
    });
  }

  void _handleGoogleLogin() async {
    setState(() => _loading = true);

    final success = await context.read<AppState>().loginWithGoogle();

    if (!mounted) return;

    if (kIsWeb) {
      setState(() => _loading = false);
      if (!success) {
        setState(() => _err = 'Google login failed');
      }
      return;
    }

    setState(() => _loading = false);

    if (success) {
      widget.onLogin();
    } else {
      setState(() => _err = 'Google login failed');
    }
  }


  void _handleFacebookLogin() => _authenticateWithFacebook();

  Future<void> _authenticateWithFacebook() async {
    try {
      setState(() => _loading = true);

      final state = context.read<AppState>();

      final result = await fb.FacebookAuth.instance.login();

      if (!mounted) return;

      if (result.status == fb.LoginStatus.success) {
        final token = result.accessToken?.tokenString;

        if (token == null) {
          setState(() {
            _loading = false;
            _err = 'Facebook token missing';
          });
          return;
        }

        final success = await state.loginWithFacebook(token);

        if (!mounted) return;

        setState(() => _loading = false);

        if (success) {
          widget.onLogin();
        } else {
          setState(() => _err = 'Facebook login failed');
        }
      } else {
        setState(() {
          _loading = false;
          _err = 'Facebook login cancelled';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _err = 'Facebook login failed: $e';
      });
    }
  }

  void _handleAppleLogin() => _authenticateWithApple();

  Future<void> _authenticateWithApple() async {
    try {
      setState(() {
        _loading = true;
        _err = null;
      });

      final state = context.read<AppState>();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      final userId = credential.userIdentifier;

      if (idToken == null || userId == null) {
        throw Exception("Apple Sign-In failed: missing credentials");
      }

      final success = await state.loginWithApple(idToken, userId);

      if (!mounted) return;

      if (success) {
        widget.onLogin();
      } else {
        setState(() {
          _err = 'Apple login failed';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _err = 'Apple login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NoOverscrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(small: true),
              const SizedBox(height: 50),

              Text('Welcome back', style: AppText.h(24, c.t1)),
              const SizedBox(height: 6),
              Text('Sign in to continue', style: AppText.body(13, c.t2)),

              const SizedBox(height: 30),

              AppInput(
                fieldLabel: 'Email',
                placeholder: 'you@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 12),

              Text('PASSWORD', style: AppText.lbl(c.t3)),
              const SizedBox(height: 6),

              TextField(
                controller: _pass,
                obscureText: !_showPass,
                style: AppText.body(13, c.t1),
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: c.surface,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () =>
                        setState(() => _showPass = !_showPass),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: widget.onForgotPassword,
                  child: Text(
                    'Forgot password?',
                    style: AppText.body(12, c.blue),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_err != null && _err!.isNotEmpty) ErrorBanner(_err!),

              PrimaryButton(
                label: 'Log In',
                onPressed: _loading ? null : _submit,
                loading: _loading,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: Divider(color: c.border)),
                  const SizedBox(width: 10),
                  Text('or', style: AppText.body(11, c.t3)),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(color: c.border)),
                ],
              ),

              const SizedBox(height: 20),
              // login buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/Google.png', width: 30),
                    onPressed: _handleGoogleLogin,
                  ),
                  IconButton(
                    icon: Image.asset('assets/facebook.png', width: 30),
                    onPressed: _handleFacebookLogin,
                  ),
                  IconButton(
                    icon: Image.asset('assets/Apple.png', width: 30),
                    onPressed: _handleAppleLogin,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: AppText.body(13, c.t2)),
                  GestureDetector(
                    onTap: widget.onGoSignUp,
                    child: Text(
                      'Sign Up',
                      style: AppText.semi(13, c.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}