// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/scroll_physics.dart';
import '../models/app_state.dart';

// ─── ENTRY POINT — manages the 2 steps internally ────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDone; // goes back to login after success

  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onDone,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0=email, 1=success
  String _email = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _EmailStep(
          onBack: widget.onBack,
          onNext: (email) => setState(() {
            _email = email;
            _step = 1;
          }),
        );
      case 1:
        return _SuccessStep(
          email: _email,
          onBack: () => setState(() => _step = 0),
          onDone: widget.onDone,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── STEP 1: EMAIL ────────────────────────────────────────────────────────────
class _EmailStep extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onNext;
  const _EmailStep({required this.onBack, required this.onNext});

  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<_EmailStep> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String _err = '';

  void _submit() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) {
      setState(() => _err = 'Please enter your email address.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _err = '';
      _loading = true;
    });

    // Send Firebase password reset email
    final state = context.read<AppState>();
    final success = await state.sendPasswordResetEmail(email);

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      widget.onNext(email);
    } else {
      setState(() => _err = 'Failed to send reset email. Please check your email and try again.');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: widget.onBack,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AppIcon('back', size: 16, color: c.t2),
                  const SizedBox(width: 6),
                  Text('Back to Sign In', style: AppText.body(13, c.t2)),
                ]),
              ),
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.blueFade,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.blue.withAlpha(40)),
                ),
                child: Center(child: AppIcon('lock', size: 24, color: c.blue)),
              ),
              const SizedBox(height: 22),

              // Step indicator
              const _StepIndicator(current: 0),
              const SizedBox(height: 20),

              Text('Forgot password?', style: AppText.h(24, c.t1)),
              const SizedBox(height: 8),
              Text(
                'No worries — enter your email and we\'ll send you a reset link.',
                style: AppText.body(13, c.t2).copyWith(height: 1.6),
              ),
              const SizedBox(height: 32),

              // Email input
              Text('EMAIL ADDRESS', style: AppText.lbl(c.t3)),
              const SizedBox(height: 7),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: AppText.body(13, c.t1),
                cursorColor: c.blue,
                onChanged: (_) => setState(() => _err = ''),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'you@email.com',
                  hintStyle: AppText.body(13, c.t3),
                  filled: true,
                  fillColor: c.surface,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: AppIcon('mail', size: 16, color: c.t3),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: c.blue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_err.isNotEmpty) ErrorBanner(_err),

              PrimaryButton(
                label: 'Send Reset Link',
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon('mail', size: 13, color: c.t3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Check your spam or junk folder if you don\'t see the email within a few minutes.',
                        style: AppText.body(11, c.t3).copyWith(height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STEP 2: SUCCESS (replaces old OTP + new password steps) ──────────────────
class _SuccessStep extends StatelessWidget {
  final String email;
  final VoidCallback onBack;
  final VoidCallback onDone;
  const _SuccessStep({
    required this.email,
    required this.onBack,
    required this.onDone,
  });

  String get _maskedEmail {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    if (local.length <= 2) return email;
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NoOverscrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AppIcon('back', size: 16, color: c.t2),
                  const SizedBox(width: 6),
                  Text('Back', style: AppText.body(13, c.t2)),
                ]),
              ),
              const SizedBox(height: 40),

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.greenFade,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.green.withAlpha(40)),
                ),
                child:
                    Center(child: AppIcon('check', size: 24, color: c.green)),
              ),
              const SizedBox(height: 22),

              const _StepIndicator(current: 1),
              const SizedBox(height: 20),

              Text('Check your email', style: AppText.h(24, c.t1)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppText.body(13, c.t2).copyWith(height: 1.6),
                  children: [
                    const TextSpan(
                        text: 'We sent a password reset link to '),
                    TextSpan(
                        text: _maskedEmail,
                        style: AppText.semi(13, c.t1)),
                    const TextSpan(
                        text: '. Click the link in the email to reset your password.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Instructions card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What to do next:', style: AppText.semi(13, c.t1)),
                    const SizedBox(height: 12),
                    _InstructionRow(
                      icon: 'mail',
                      text: 'Open the email from FlameGuard',
                      c: c,
                    ),
                    const SizedBox(height: 8),
                    _InstructionRow(
                      icon: 'link',
                      text: 'Click the password reset link',
                      c: c,
                    ),
                    const SizedBox(height: 8),
                    _InstructionRow(
                      icon: 'shield',
                      text: 'Create your new password',
                      c: c,
                    ),
                    const SizedBox(height: 8),
                    _InstructionRow(
                      icon: 'back',
                      text: 'Come back here and sign in',
                      c: c,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Back to Sign In',
                onPressed: onDone,
              ),
              const SizedBox(height: 16),

              // Spam note
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon('mail', size: 13, color: c.t3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Didn\'t get the email? Check your spam folder, or go back and try again.',
                        style: AppText.body(11, c.t3).copyWith(height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final String icon;
  final String text;
  final AppColors c;
  const _InstructionRow({required this.icon, required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: c.blueFade,
            shape: BoxShape.circle,
          ),
          child: Center(child: AppIcon(icon, size: 11, color: c.blue)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppText.body(12, c.t2)),
        ),
      ],
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current; // 0, 1
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final labels = ['Email', 'Done'];
    return Row(
      children: List.generate(2, (i) {
        final done = i < current;
        final active = i == current;
        final col = active
            ? c.blue
            : done
                ? c.green
                : c.t3;
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? c.blueFade
                    : done
                        ? c.greenFade
                        : c.raised,
                border: Border.all(
                  color: active
                      ? c.blue
                      : done
                          ? c.green
                          : c.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: done
                    ? AppIcon('check', size: 10, color: c.green)
                    : Text('${i + 1}', style: AppText.semi(9, col)),
              ),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: AppText.lbl(col).copyWith(fontSize: 8)),
          ]),
          if (i < 1)
            Container(
              width: 32,
              height: 1,
              margin: const EdgeInsets.only(bottom: 14, left: 6, right: 6),
              color: i < current ? c.green : c.border,
            ),
        ]);
      }),
    );
  }
}
