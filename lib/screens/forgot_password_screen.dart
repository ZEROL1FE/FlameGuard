// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/scroll_physics.dart';

// ─── ENTRY POINT — manages all 3 steps internally ────────────────────────────
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
  int _step = 0; // 0=email, 1=otp, 2=new password
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
        return _OtpStep(
          email: _email,
          onBack: () => setState(() => _step = 0),
          onNext: () => setState(() => _step = 2),
        );
      case 2:
        return _NewPasswordStep(
          onBack: () => setState(() => _step = 1),
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

  void _submit() {
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
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _loading = false);
        widget.onNext(email);
      }
    });
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
                'No worries — enter your email and we\'ll send you a reset code.',
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
                label: 'Send Reset Code',
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

// ─── STEP 2: OTP ──────────────────────────────────────────────────────────────
class _OtpStep extends StatefulWidget {
  final String email;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _OtpStep(
      {required this.email, required this.onBack, required this.onNext});

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resent = false;
  String _err = '';

  // Timer countdown
  int _countdown = 600; // 10 min in seconds
  bool _timerActive = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  void _startTimer() async {
    while (_countdown > 0 && mounted && _timerActive) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown--);
    }
  }

  String get _timerLabel {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final local = parts[0];
    if (local.length <= 2) return widget.email;
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@${parts[1]}';
  }

  bool get _filled => _ctrls.every((c) => c.text.isNotEmpty);

  void _onChanged(int i, String val) {
    setState(() => _err = '');
    if (val.length > 1) {
      // paste support
      final digits = val.replaceAll(RegExp(r'\D'), '');
      for (int j = 0; j < digits.length && (i + j) < 6; j++) {
        _ctrls[i + j].text = digits[j];
      }
      final next = (i + digits.length).clamp(0, 5);
      _nodes[next].requestFocus();
      setState(() {});
      return;
    }
    if (val.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
    setState(() {});
  }

  void _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[i].text.isEmpty &&
        i > 0) {
      _nodes[i - 1].requestFocus();
    }
  }

  void _submit() {
    if (!_filled) {
      setState(() => _err = 'Please enter all 6 digits.');
      return;
    }
    setState(() {
      _err = '';
      _loading = true;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _loading = false);
        widget.onNext();
      }
    });
  }

  void _resend() {
    for (final c in _ctrls) {
      c.clear();
    }
    setState(() {
      _resent = true;
      _err = '';
      _countdown = 600;
    });
    _nodes[0].requestFocus();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _resent = false);
    });
  }

  @override
  void dispose() {
    _timerActive = false;
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
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
              GestureDetector(
                onTap: widget.onBack,
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
                  color: c.blueFade,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.blue.withAlpha(40)),
                ),
                child: Center(child: AppIcon('mail', size: 24, color: c.blue)),
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
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(text: _maskedEmail, style: AppText.semi(13, c.t1)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // OTP boxes
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final filled = _ctrls[i].text.isNotEmpty;
                    return KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (e) => _onKey(i, e),
                      child: Container(
                        width: 44,
                        height: 54,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: AppText.h(22, c.t1),
                          cursorColor: c.blue,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: filled ? c.blueFade : c.surface,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: filled ? c.blue : c.border,
                                  width: filled ? 1.5 : 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: filled ? c.blue : c.border,
                                  width: filled ? 1.5 : 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: c.blue, width: 2),
                            ),
                          ),
                          onChanged: (val) => _onChanged(i, val),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon('refresh',
                      size: 12, color: _countdown > 0 ? c.t3 : c.red),
                  const SizedBox(width: 6),
                  Text(
                    _countdown > 0
                        ? 'Code expires in $_timerLabel'
                        : 'Code expired',
                    style: AppText.body(11, _countdown > 0 ? c.t3 : c.red),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_err.isNotEmpty) ErrorBanner(_err),
              if (_resent) const SuccessBanner('A new code has been sent.'),

              PrimaryButton(
                label: 'Verify Code',
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 16),

              // Resend
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Didn\'t receive a code? ', style: AppText.body(13, c.t2)),
                GestureDetector(
                  onTap: _resend,
                  child: Text('Resend', style: AppText.semi(13, c.blue)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STEP 3: NEW PASSWORD ─────────────────────────────────────────────────────
class _NewPasswordStep extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDone;
  const _NewPasswordStep({required this.onBack, required this.onDone});

  @override
  State<_NewPasswordStep> createState() => _NewPasswordStepState();
}

class _NewPasswordStepState extends State<_NewPasswordStep> {
  final _pass = TextEditingController();
  final _conf = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  bool _showConf = false;
  String _err = '';

  // Password strength
  int get _strength {
    final p = _pass.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  Color _strengthColor(AppColors c) {
    switch (_strength) {
      case 0:
      case 1:
        return c.red;
      case 2:
        return c.amber;
      case 3:
        return c.blue;
      default:
        return c.green;
    }
  }

  void _submit() {
    if (_pass.text.isEmpty || _conf.text.isEmpty) {
      setState(() => _err = 'Please fill in both fields.');
      return;
    }
    if (_pass.text.length < 8) {
      setState(() => _err = 'Password must be at least 8 characters.');
      return;
    }
    if (_pass.text != _conf.text) {
      setState(() => _err = 'Passwords do not match.');
      return;
    }
    setState(() {
      _err = '';
      _loading = true;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _loading = false);
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _pass.dispose();
    _conf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final sCol = _strengthColor(c);

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
                onTap: widget.onBack,
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
                    Center(child: AppIcon('shield', size: 24, color: c.green)),
              ),
              const SizedBox(height: 22),

              const _StepIndicator(current: 2),
              const SizedBox(height: 20),

              Text('Create new password', style: AppText.h(24, c.t1)),
              const SizedBox(height: 8),
              Text(
                'Your new password must be different from your previous one.',
                style: AppText.body(13, c.t2).copyWith(height: 1.6),
              ),
              const SizedBox(height: 32),

              // New password
              Text('NEW PASSWORD', style: AppText.lbl(c.t3)),
              const SizedBox(height: 7),
              TextField(
                controller: _pass,
                obscureText: !_showPass,
                style: AppText.body(13, c.t1),
                cursorColor: c.blue,
                onChanged: (_) => setState(() => _err = ''),
                decoration: InputDecoration(
                  hintText: 'Min. 8 characters',
                  hintStyle: AppText.body(13, c.t3),
                  filled: true,
                  fillColor: c.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AppIcon(_showPass ? 'eye' : 'eye',
                          size: 16, color: c.t3),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
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

              // Strength bar
              if (_pass.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  ...List.generate(
                      4,
                      (i) => Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i < _strength ? sCol : c.raised,
                              ),
                            ),
                          )),
                  const SizedBox(width: 10),
                  Text(_strengthLabel,
                      style:
                          AppText.semi(10, sCol).copyWith(letterSpacing: 0.3)),
                ]),
                const SizedBox(height: 8),
                // Requirements
                _PassReq(
                    met: _pass.text.length >= 8,
                    label: 'At least 8 characters',
                    c: c),
                _PassReq(
                    met: _pass.text.contains(RegExp(r'[A-Z]')),
                    label: 'One uppercase letter',
                    c: c),
                _PassReq(
                    met: _pass.text.contains(RegExp(r'[0-9]')),
                    label: 'One number',
                    c: c),
                _PassReq(
                    met: _pass.text.contains(RegExp(r'[!@#\$%^&*]')),
                    label: 'One special character (!@#\$%^&*)',
                    c: c),
              ],
              const SizedBox(height: 18),

              // Confirm
              Text('CONFIRM PASSWORD', style: AppText.lbl(c.t3)),
              const SizedBox(height: 7),
              TextField(
                controller: _conf,
                obscureText: !_showConf,
                style: AppText.body(13, c.t1),
                cursorColor: c.blue,
                onChanged: (_) => setState(() => _err = ''),
                decoration: InputDecoration(
                  hintText: 'Re-enter password',
                  hintStyle: AppText.body(13, c.t3),
                  filled: true,
                  fillColor: c.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showConf = !_showConf),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AppIcon(_showConf ? 'eye' : 'eye',
                          size: 16, color: c.t3),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                      color: _conf.text.isNotEmpty && _conf.text != _pass.text
                          ? c.red
                          : c.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: c.blue, width: 1.5),
                  ),
                ),
              ),

              // Match indicator
              if (_conf.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  AppIcon(
                    _conf.text == _pass.text ? 'check' : 'x',
                    size: 11,
                    color: _conf.text == _pass.text ? c.green : c.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _conf.text == _pass.text
                        ? 'Passwords match'
                        : 'Passwords do not match',
                    style: AppText.body(
                        11, _conf.text == _pass.text ? c.green : c.red),
                  ),
                ]),
              ],
              const SizedBox(height: 24),

              if (_err.isNotEmpty) ErrorBanner(_err),

              PrimaryButton(
                label: 'Reset Password',
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 16),

              // Success info card
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
                    AppIcon('shield', size: 13, color: c.t3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After resetting, you will be signed out of all active sessions.',
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

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current; // 0, 1, 2
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final labels = ['Email', 'Verify', 'Reset'];
    return Row(
      children: List.generate(3, (i) {
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
          if (i < 2)
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

class _PassReq extends StatelessWidget {
  final bool met;
  final String label;
  final AppColors c;
  const _PassReq({required this.met, required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met ? c.greenFade : c.raised,
            border: Border.all(color: met ? c.green : c.border),
          ),
          child: met
              ? Center(child: AppIcon('check', size: 8, color: c.green))
              : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: AppText.body(11, met ? c.green : c.t3)),
      ]),
    );
  }
}
