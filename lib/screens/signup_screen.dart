// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/scroll_physics.dart';
import '../models/app_state.dart';


class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onGoLogin;
  const SignUpScreen(
      {super.key, required this.onSignUp, required this.onGoLogin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _conf = TextEditingController();
  bool _loading = false;
  bool _agreeToTerms = false;
  bool _showPass = false;
  bool _showConf = false;
  String _err = '';

  void _submit() {
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty ||
        _conf.text.isEmpty) {
      setState(() => _err = 'Please fill in all fields.');
      return;
    }
    if (_pass.text != _conf.text) {
      setState(() => _err = 'Passwords do not match.');
      return;
    }
    if (_pass.text.length < 6) {
      setState(() => _err = 'Password must be at least 6 characters.');
      return;
    }
    if (!_agreeToTerms) {
      setState(() => _err = 'You must agree to Terms & Conditions.');
      return;
    }
    setState(() {
      _err = '';
      _loading = true;
    });

    // Use AppState to handle authentication
    final state = context.read<AppState>();
    state.signupWithEmail(_name.text, _email.text, _pass.text).then((success) {
      if (mounted) {
        setState(() => _loading = false);
        if (success) {
          widget.onSignUp();
        } else {
          setState(() => _err = 'Signup failed');
        }
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = 'Signup failed: ${e.toString()}';
        });
      }
    });
  }

  void _handleGoogleSignup() async {
    setState(() => _loading = true);

    final success = await context.read<AppState>().loginWithGoogle();

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      widget.onSignUp();
    } else {
      setState(() => _err = 'Google signup failed');
    }
  }

  void _handleFacebookSignup() {
    // Trigger Facebook OAuth authentication flow
    _authenticateWithFacebook();
  }

  Future<void> _authenticateWithFacebook() async {
    try {
      setState(() => _loading = true);
      // Capture state before async operation
      final state = context.read<AppState>();
      final fb.LoginResult result = await fb.FacebookAuth.instance.login();
      
      if (result.status == fb.LoginStatus.success) {
        final userData = await fb.FacebookAuth.instance.getUserData();
        
        // Use AppState to handle authentication
        final token = result.accessToken?.tokenString;

        if (token == null) {
          setState(() {
            _loading = false;
            _err = 'Facebook token missing';
          });
          return;
        }

        final success = await state.loginWithFacebook(token);
        
        if (success && mounted) {
          // Auto-populate user data from Facebook account
          setState(() {
            _name.text = userData['name'] ?? '';
            _email.text = userData['email'] ?? '';
            _err = '';
            _loading = false;
          });
          widget.onSignUp();
        } else if (mounted) {
          setState(() {
            _loading = false;
            _err = 'Facebook signup failed';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _err = 'Facebook signup cancelled or failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = 'Facebook signup failed: ${e.toString()}';
        });
      }
    }
  }

  void _handleAppleSignup() {
    // Trigger Apple Sign In authentication flow
    _authenticateWithApple();
  }

  Future<void> _authenticateWithApple() async {
    try {
      setState(() => _loading = true);
      // Capture state before async operation
      final state = context.read<AppState>();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Use AppState to handle authentication
      final success = await state.loginWithApple(credential.identityToken!, credential.userIdentifier!);
      
      if (success && mounted) {
        // Auto-populate user data from Apple account
        setState(() {
          if (credential.givenName != null) {
            _name.text = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
          }
          if (credential.email != null) {
            _email.text = credential.email!;
          }
          _err = '';
          _loading = false;
        });
        widget.onSignUp();
      } else if (mounted) {
        setState(() {
          _loading = false;
          _err = 'Apple signup failed';
        });
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (e.code == AuthorizationErrorCode.canceled) {
            _err = 'Apple signup cancelled';
          } else {
            _err = 'Apple signup failed: ${e.message}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = 'Apple signup failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _conf.dispose();
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onGoLogin,
                child: Row(children: [
                  AppIcon('back', size: 16, color: c.t2),
                  const SizedBox(width: 6),
                  Text('Back', style: AppText.body(13, c.t2)),
                ]),
              ),
              const SizedBox(height: 30),
              Text('Create account', style: AppText.h(24, c.t1)),
              const SizedBox(height: 6),
              Text('Join FlameGuard today', style: AppText.body(13, c.t2)),
              const SizedBox(height: 28),
              AppInput(
                  fieldLabel: 'Full Name',
                  placeholder: 'Juan dela Cruz',
                  controller: _name),
              AppInput(
                  fieldLabel: 'Email',
                  placeholder: 'you@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              // Password
              Text('PASSWORD', style: AppText.lbl(c.t3)),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: !_showPass,
                style: AppText.body(13, c.t1),
                cursorColor: c.blue,
                decoration: InputDecoration(
                  hintText: 'Min. 6 characters',
                  hintStyle: AppText.body(13, c.t3),
                  filled: true,
                  fillColor: c.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AppIcon('eye', size: 16, color: c.t3),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.blue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Confirm Password
              Text('CONFIRM PASSWORD', style: AppText.lbl(c.t3)),
              const SizedBox(height: 6),
              TextField(
                controller: _conf,
                obscureText: !_showConf,
                style: AppText.body(13, c.t1),
                cursorColor: c.blue,
                decoration: InputDecoration(
                  hintText: 'Re-enter password',
                  hintStyle: AppText.body(13, c.t3),
                  filled: true,
                  fillColor: c.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showConf = !_showConf),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AppIcon('eye', size: 16, color: c.t3),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.blue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _agreeToTerms ? c.blue : Colors.transparent,
                        border: Border.all(
                            color: _agreeToTerms ? c.blue : c.border, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _agreeToTerms
                          ? Icon(Icons.check, size: 14, color: c.bg)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                          text: TextSpan(
                        style: AppText.body(13, c.t2),
                        children: [
                          const TextSpan(text: 'Agree with '),
                          TextSpan(
                              text: 'Terms & Condition',
                              style: AppText.semi(12, c.blue)),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_err.isNotEmpty) ErrorBanner(_err),
              PrimaryButton(
                label: 'Create Account',
                onPressed: _loading ? null : _submit,
                loading: _loading,
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Divider(color: c.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: AppText.body(11, c.t3)),
                ),
                Expanded(child: Divider(color: c.border)),
              ]),
              const SizedBox(height: 18),
              // Social login section
              Column(
                children: [
                  Text('Sign up with', style: AppText.body(13, c.t2)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google button
                      IconButton(
                        onPressed: () => _handleGoogleSignup(),
                        icon: const _GoogleLogo(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 16),
                      // Facebook button
                      IconButton(
                        onPressed: () => _handleFacebookSignup(),
                        icon: const _FacebookLogo(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 16),
                      // Apple button
                      IconButton(
                        onPressed: () => _handleAppleSignup(),
                        icon: const _AppleLogo(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: AppText.body(13, c.t2)),
                GestureDetector(
                  onTap: widget.onGoLogin,
                  child: Text('Sign In', style: AppText.semi(13, c.blue)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/Google.png', width: 32, height: 32);
  }
}

class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/facebook.png', width: 32, height: 32);
  }
}

class _AppleLogo extends StatelessWidget {
  const _AppleLogo();
  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        c.t1, // Use theme text color (white in dark, black in light)
        BlendMode.srcIn,
      ),
      child: Image.asset('assets/Apple.png', width: 32, height: 32),
    );
  }
}
