// lib/screens/device_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/scroll_physics.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onBack;

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final d = state.getDevice(device.id) ?? device;

    // Temp color — vivid in both modes
    final tempColor = d.tempStatus == 'Critical'
        ? c.red
        : d.tempStatus == 'Warning'
            ? c.amber
            : c.green;

    // Adaptive colors
    final bgColor = c.isDark ? const Color(0xFF141414) : const Color(0xFFF2F2F2);
    final statusBg = c.isDark ? const Color(0xFF222222) : Colors.white;
    final statusBorder =
        c.isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFBBBBBB);
    final onlineText = c.isDark ? Colors.white70 : const Color(0xFF333333);
    final offlineText = c.isDark ? Colors.white38 : const Color(0xFF888888);
    final titleColor = c.isDark ? Colors.white : c.t1;

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          child: Column(children: [
            // ── App bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(children: [
                GestureDetector(
                  onTap: onBack,
                  child: AppIcon('back', size: 18, color: titleColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.name.toUpperCase(),
                    style: AppText.semi(15, titleColor)
                        .copyWith(letterSpacing: 1.2),
                  ),
                ),
                AppToggle(
                  value: d.active,
                  onChanged: (_) => state.toggleDevicePower(d.id),
                ),
              ]),
            ),

            // ── Status bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(children: [
                  StatusDot(on: d.active),
                  const SizedBox(width: 8),
                  Text(
                    d.active
                        ? 'Online — monitoring active'
                        : 'Offline — standby',
                    style:
                        AppText.body(12, d.active ? onlineText : offlineText),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      d.runtime,
                      style: AppText.semi(11, c.t2),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Scrollable content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const NoOverscrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Column(children: [
                      // ── Stat cards: Voltage · Current · Power ──
                      Column(children: [
                        IntrinsicHeight(
                          child: Row(children: [
                            _StatCard(
                                label: 'Voltage',
                                value: d.voltage.toStringAsFixed(0),
                                unit: 'V'),
                            _StatDivider(),
                            _StatCard(
                                label: 'Current',
                                value: d.current.toStringAsFixed(1),
                                unit: 'A'),
                            _StatDivider(),
                            _StatCard(
                              label: 'Power',
                              value: d.wattage >= 1000
                                  ? (d.wattage / 1000).toStringAsFixed(1)
                                  : '${d.wattage}',
                              unit: d.wattage >= 1000 ? 'kW' : 'W',
                            ),
                          ]),
                        ),

                        const SizedBox(height: 20),

                        // Temperature row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TEMPERATURE',
                                        style: AppText.lbl(c.t2)),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          d.temperature.toStringAsFixed(1),
                                          style: AppText.h(32, tempColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('°C',
                                            style: AppText.body(14, c.t2)),
                                      ],
                                    ),
                                  ]),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: tempColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: tempColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: tempColor,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(d.tempStatus,
                                          style: AppText.semi(12, tempColor)),
                                    ]),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _TempRangeBar(temp: d.temperature),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // ── Fire Risk Gauge ──────────────────────────────────
                      FireRiskGauge(score: d.riskScore, risk: d.risk),

                      const SizedBox(height: 48),

                      // Hint bar
                      _RiskHintBar(risk: d.risk),

                      const SizedBox(height: 32),

                      // ── Auto-cutoff reminder ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _AutoCutoffReminder(),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // ── Plug Schedule ─────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: c.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFBBBBBB),
                      ),
                    ),
                    child: _PlugScheduleCard(device: d),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Vertical divider between stat cards ──────────────────────────────────────
class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: 1,
      color:
          c.isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBBBBBB),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, unit;
  const _StatCard(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: AppText.lbl(c.t2)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppText.h(22, c.t1)),
              const SizedBox(width: 3),
              Text(unit, style: AppText.body(11, c.t2)),
            ],
          ),
        ]),
      ),
    );
  }
}

// ── Temperature range bar ────────────────────────────────────────────────────
class _TempRangeBar extends StatelessWidget {
  final double temp;
  const _TempRangeBar({required this.temp});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final pct = (temp / 100).clamp(0.0, 1.0);
    final color = temp >= 65
        ? const Color(0xFFD93025)
        : temp >= 45
            ? const Color(0xFFB45309)
            : const Color(0xFF15803D);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(
              height: 4,
              width: double.infinity,
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFDDDDDD)),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('0°C', style: AppText.body(8, c.t2)),
        Text('45°C — Warning', style: AppText.body(8, c.t2)),
        Text('100°C', style: AppText.body(8, c.t2)),
      ]),
    ]);
  }
}

// ── Risk hint bar ─────────────────────────────────────────────────────────────
class _RiskHintBar extends StatelessWidget {
  final String risk;
  const _RiskHintBar({required this.risk});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.riskFade(risk),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.riskColor(risk).withValues(alpha: 32 / 255)),
      ),
      child: Row(children: [
        AppIcon('flame', size: 13, color: c.riskColor(risk)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            risk == 'Low'
                ? 'Appliance is operating within safe parameters.'
                : risk == 'Medium'
                    ? 'Elevated risk detected. Monitor this device.'
                    : 'High risk — consider turning off this device.',
            style: AppText.body(11, c.riskColor(risk)).copyWith(height: 1.5),
          ),
        ),
      ]),
    );
  }
}

// ── Auto-cutoff reminder (no toggle — always active) ─────────────────────────
class _AutoCutoffReminder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: c.red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon('flame', size: 14, color: c.red.withValues(alpha: 0.10)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Auto-Cutoff', style: AppText.med(13, c.t1)),
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Always On',
                      style: AppText.semi(9, c.green)
                          .copyWith(letterSpacing: 0.4)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(
                'Power cuts off automatically when risk reaches a critical threshold.',
                style: AppText.body(11, c.t3).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Plug Schedule card ────────────────────────────────────────────────────────
class _PlugScheduleCard extends StatefulWidget {
  final DeviceModel device;
  const _PlugScheduleCard({required this.device});

  @override
  State<_PlugScheduleCard> createState() => _PlugScheduleCardState();
}

class _PlugScheduleCardState extends State<_PlugScheduleCard> {
  String _fmt(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final hh = h % 12 == 0 ? 12 : h % 12;
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  Future<void> _pickTime(BuildContext context, bool isPlugIn) async {
    final d = widget.device;
    final state = context.read<AppState>();
    
    final initial = isPlugIn 
        ? TimeOfDay(hour: d.startHour, minute: d.startMinute)
        : TimeOfDay(hour: d.endHour, minute: d.endMinute);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );

    if (picked != null) {
      if (isPlugIn) {
        state.updateSchedule(d.id, d.scheduleEnabled, picked.hour, picked.minute, d.endHour, d.endMinute);
      } else {
        state.updateSchedule(d.id, d.scheduleEnabled, d.startHour, d.startMinute, picked.hour, picked.minute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final d = widget.device;
    final state = context.read<AppState>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plug Schedule', style: AppText.med(14, c.t1)),
            const SizedBox(height: 2),
            Text('Set allowed plug-in hours', style: AppText.body(11, c.t2)),
          ]),
          AppToggle(
            value: d.scheduleEnabled,
            onChanged: (v) => state.updateSchedule(d.id, v, d.startHour, d.startMinute, d.endHour, d.endMinute),
          ),
        ],
      ),

      // Time pickers — shown only when enabled
      if (d.scheduleEnabled) ...[
        const SizedBox(height: 14),
        Container(
          height: 1,
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFEEEEEE),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _TimeTile(
              label: 'PLUG IN FROM',
              time: _fmt(d.startHour, d.startMinute),
              onTap: () => _pickTime(context, true),
              accentColor: c.green,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: c.isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFDDDDDD),
          ),
          Expanded(
            child: _TimeTile(
              label: 'UNTIL',
              time: _fmt(d.endHour, d.endMinute),
              onTap: () => _pickTime(context, false),
              accentColor: c.amber,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: c.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Device may only draw power between ${_fmt(d.startHour, d.startMinute)} and ${_fmt(d.endHour, d.endMinute)}.',
            style: AppText.body(10, c.t3).copyWith(height: 1.5),
          ),
        ),
      ],
    ]);
  }
}

// ── Time tile (tap to pick) ───────────────────────────────────────────────────
class _TimeTile extends StatelessWidget {
  final String label, time;
  final VoidCallback onTap;
  final Color accentColor;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Image.asset('assets/Clock.png', width: 12, height: 12, color: c.t3),
            const SizedBox(width: 6),
            Text(label, style: AppText.lbl(c.t2)),
          ]),
          const SizedBox(height: 5),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(time, style: AppText.h(18, accentColor)),
          ]),
        ]),
      ),
    );
  }
}
