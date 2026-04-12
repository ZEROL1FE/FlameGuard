// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  final int step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const OnboardingScreen({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    // step data for titles/body; icons handled separately so we can draw custom
    // layout for the first step that matches the screenshot with three boxes.
    final steps = [
      (
        title: 'Connect Your Adapter',
        body:
            'Pair your FlameGuard smart adapter via Hotspot. Make sure the hotspot is active and the device is nearby.'
      ),
      (
        title: 'Join Your Network',
        body:
            'Connect to your home Wi-Fi so FlameGuard can send real-time fire risk alerts directly to your phone.'
      ),
    ];
    final s = steps[step];

    Widget iconSection;
    if (step == 0) {
      // three-box illustration with bluetooth highlighted and dots below
      iconSection = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _onboardBoxIcon(Icons.print, c),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _onboardBoxIcon(Icons.wifi_tethering, c, active: true),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    3,
                    (i) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 1 ? c.blue : c.raised,
                            border: Border.all(color: c.border),
                          ),
                        )),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _onboardBoxIcon(Icons.smartphone, c),
        ],
      );
    } else {
      // three-box illustration with wifi highlighted and dots below (step 1)
      iconSection = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _onboardBoxIcon(Icons.router, c),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _onboardBoxIcon(Icons.wifi, c, active: true),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    3,
                    (i) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 1 ? c.blue : c.raised,
                            border: Border.all(color: c.border),
                          ),
                        )),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _onboardBoxIcon(Icons.smartphone, c),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onSkip,
                  child: Text('Skip', style: AppText.body(13, c.t3)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconSection,
                    const SizedBox(height: 28),
                    Text('Step ${step + 1} of 2', style: AppText.lbl(c.t3)),
                    const SizedBox(height: 12),
                    Text(s.title,
                        textAlign: TextAlign.center,
                        style: AppText.h(19, c.t1)),
                    const SizedBox(height: 12),
                    Text(s.body,
                        textAlign: TextAlign.center,
                        style: AppText.body(12.5, c.t2).copyWith(height: 1.65)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        2,
                        (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: i == step ? 20 : 6,
                              height: 3.5,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i == step ? c.blue : c.raised,
                                border: Border.all(
                                    color: i == step ? c.blue : c.border),
                              ),
                            )),
                  ),
                  const SizedBox(height: 22),
                  if (step == 1)
                    PrimaryButton(label: 'Get Started', onPressed: onNext)
                  else
                    Row(children: [
                      Expanded(
                          child: GhostButton(label: 'Skip', onPressed: onSkip)),
                      const SizedBox(width: 10),
                      Expanded(
                          flex: 2,
                          child: PrimaryButton(
                              label: 'Continue', onPressed: onNext)),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // little square container used in the first onboarding step
  Widget _onboardBoxIcon(IconData icon, AppColors c, {bool active = false}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: active ? c.surface : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? c.blue : c.borderMid),
      ),
      child: Center(
        child: Icon(icon, size: 26, color: active ? c.blue : c.t1),
      ),
    );
  }
}
