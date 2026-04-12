// lib/screens/verify_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/scroll_physics.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  final VoidCallback onBack;
  const VerifyScreen({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onBack,
  });

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resent = false;
  String _err = '';

  bool get _filled => _controllers.every((c) => c.text.isNotEmpty);

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final local = parts[0];
    final masked = local[0] + '*' * (local.length - 1);
    return '$masked@${parts[1]}';
  }

  void _onChanged(int i, String val) {
    if (val.length > 1) {
      // Handle paste
      final digits = val
          .replaceAll(RegExp(r'\D'), '')
          .substring(0, val.length > 6 ? 6 : val.length);
      for (int j = 0; j < digits.length && (i + j) < 6; j++) {
        _controllers[i + j].text = digits[j];
      }
      final next = (i + digits.length).clamp(0, 5);
      _focusNodes[next].requestFocus();
      setState(() {});
      return;
    }
    setState(() => _err = '');
    if (val.isNotEmpty && i < 5) {
      _focusNodes[i + 1].requestFocus();
    }
  }

  void _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _focusNodes[i - 1].requestFocus();
    }
  }

  void _submit() {
    if (!_filled) {
      setState(() => _err = 'Please enter the 6-digit code.');
      return;
    }
    setState(() {
      _err = '';
      _loading = true;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _loading = false);
        widget.onVerified();
      }
    });
  }

  void _resend() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _resent = true;
      _err = '';
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _resent = false);
    });
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
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
                child: Row(children: [
                  AppIcon('back', size: 16, color: c.t2),
                  const SizedBox(width: 6),
                  Text('Back', style: AppText.body(13, c.t2)),
                ]),
              ),
              const SizedBox(height: 40),
              // Mail icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.blueFade,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.blue.withAlpha(32)),
                ),
                child: Center(child: AppIcon('mail', size: 24, color: c.blue)),
              ),
              const SizedBox(height: 24),
              Text('Check your email', style: AppText.h(24, c.t1)),
              const SizedBox(height: 8),
              RichText(
                  text: TextSpan(
                style: AppText.body(13, c.t2).copyWith(height: 1.6),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to '),
                  TextSpan(text: _maskedEmail, style: AppText.semi(13, c.t1)),
                ],
              )),
              const SizedBox(height: 32),

              // OTP boxes
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      6,
                      (i) => Container(
                            width: 44,
                            height: 58,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _controllers[i].text.isNotEmpty
                                    ? c.blue
                                    : c.border,
                                width: _controllers[i].text.isNotEmpty ? 1.5 : 1,
                              ),
                            ),
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (e) => _onKey(i, e),
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: AppText.h(22, c.t1),
                                cursorColor: c.blue,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => _onChanged(i, val),
                              ),
                            ),
                          )),
                ),
              ),
              const SizedBox(height: 28),

              if (_err.isNotEmpty) ErrorBanner(_err),
              if (_resent) const SuccessBanner('Code resent successfully.'),

              PrimaryButton(
                label: _loading ? 'Verifying...' : 'Verify',
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Did not receive a code? ', style: AppText.body(13, c.t2)),
                GestureDetector(
                  onTap: _resend,
                  child: Text('Resend', style: AppText.semi(13, c.blue)),
                ),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  'Code expires in 10 minutes. Check your spam folder if you do not see it.',
                  style: AppText.body(11, c.t3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
