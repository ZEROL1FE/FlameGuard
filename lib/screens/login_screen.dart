// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  String _err = '';

  void _submit() {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _err = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _err = '';
      _loading = true;
    });

    // Use AppState to handle authentication
    final state = context.read<AppState>();
    state.loginWithEmail(_email.text, _pass.text).then((success) {
      if (mounted) {
        setState(() => _loading = false);
        if (success) {
          widget.onLogin();
        } else {
          setState(() => _err = 'Invalid email or password');
        }
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = 'Login failed: ${e.toString()}';
        });
      }
    });
  }

  void _handleGoogleLogin() {
    _authenticateWithGoogle();
  }

  Future<void> _authenticateWithGoogle() async {
    try {
      setState(() => _loading = true);

      final state = context.read<AppState>();
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        setState(() {
          _loading = false;
          _err = 'Google sign in cancelled';
        });
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        throw Exception("Google ID token missing");
      }

      final success = await state.loginWithGoogle(auth.idToken!);

      if (success) {
        setState(() {
          _loading = false;
          _err = '';
        });
        widget.onLogin();
      } else {
        setState(() {
          _loading = false;
          _err = 'Google login failed';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _err = 'Google sign in failed: ${e.toString()}';
      });
    }
  }

  void _handleFacebookLogin() {
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
        final fb.AccessToken? token = result.accessToken;
        
        // Use AppState to handle authentication
        final success = await state.loginWithFacebook((token as dynamic).token);
        
        if (success) {
          setState(() {
            _err = '';
            _loading = false;
          });
          widget.onLogin();
        } else {
          setState(() {
            _loading = false;
            _err = 'Facebook login failed';
          });
        }
      } else {
        setState(() {
          _loading = false;
          _err = 'Facebook login cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _err = 'Facebook login failed: ${e.toString()}';
      });
    }
  }

  void _handleAppleLogin() {
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
      
      if (success) {
        setState(() {
          _err = '';
          _loading = false;
        });
        widget.onLogin();
      } else {
        setState(() {
          _loading = false;
          _err = 'Apple sign in failed';
        });
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      setState(() {
        _loading = false;
        if (e.code == AuthorizationErrorCode.canceled) {
          _err = 'Apple sign in cancelled';
        } else {
          _err = 'Apple sign in failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _err = 'Apple sign in failed: ${e.toString()}';
      });
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
                  hintText: 'Password',
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
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: widget.onForgotPassword,
                  child:
                      Text('Forgot password?', style: AppText.body(12, c.blue)),
                ),
              ),
              const SizedBox(height: 22),
              if (_err.isNotEmpty) ErrorBanner(_err),
              PrimaryButton(
                  label: 'Sign In', onPressed: _submit, loading: _loading),
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
                        onPressed: () => _handleGoogleLogin(),
                        icon: const _GoogleLogo(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 16),
                      // Facebook button
                      IconButton(
                        onPressed: () => _handleFacebookLogin(),
                        icon: const _FacebookLogo(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 16),
                      // Apple button
                      IconButton(
                        onPressed: () => _handleAppleLogin(),
                        icon: const _AppleLogo(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Don\'t have an account? ', style: AppText.body(13, c.t2)),
                GestureDetector(
                  onTap: widget.onGoSignUp,
                  child: Text('Sign Up', style: AppText.semi(13, c.blue)),
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
