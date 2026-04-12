// lib/screens/remaining_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─── ANALYTICS DATA MODEL ─────────────────────────────────────────────────────
class _PeriodData {
  final List<double> vals;
  final List<String> labs;
  final String peak, top, dev;
  final List<_ApplianceUsage> appliances;
  const _PeriodData({
    required this.vals,
    required this.labs,
    required this.peak,
    required this.top,
    required this.dev,
    required this.appliances,
  });
}

class _ApplianceUsage {
  final String name;
  final double kwh;
  final double share;
  const _ApplianceUsage(
      {required this.name, required this.kwh, required this.share});
}

// helper — light mode bg
Color _screenBg(AppColors c) => c.isDark ? c.bg : const Color(0xFFF2F2F2);
Color _cardBg(AppColors c) => c.isDark ? c.surface : Colors.white;

// ─── ANALYTICS ────────────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollDown;
  const AnalyticsScreen({super.key, this.onScrollDown});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _period = 0;
  late final ScrollController _scrollCtrl;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        final offset = _scrollCtrl.offset;
        final goingDown = offset > _lastOffset;
        if ((offset - _lastOffset).abs() > 4) {
          widget.onScrollDown?.call(goingDown);
          _lastOffset = offset;
        }
      });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  static final _data = [
    const _PeriodData(
      vals: [0.2, 0.1, 0.1, 0.3, 1.8, 2.4, 1.9, 2.1, 2.6, 3.2, 2.8, 1.4],
      labs: [
        '12a',
        '2a',
        '4a',
        '6a',
        '8a',
        '10a',
        '12p',
        '2p',
        '4p',
        '6p',
        '8p',
        '10p'
      ],
      peak: '6–8 PM',
      top: '3.2 kWh',
      dev: 'Kitchen Kettle',
      appliances: [
        _ApplianceUsage(name: 'Kitchen Kettle', kwh: 3.2, share: 0.82),
        _ApplianceUsage(name: 'Living Room TV', kwh: 0.4, share: 0.10),
        _ApplianceUsage(name: 'Master Fan', kwh: 0.2, share: 0.05),
        _ApplianceUsage(name: 'TV Adaptor', kwh: 0.1, share: 0.03),
      ],
    ),
    const _PeriodData(
      vals: [14.2, 11.8, 16.5, 13.1, 18.4, 22.6, 19.3],
      labs: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      peak: 'Saturday',
      top: '22.6 kWh',
      dev: 'Multiple',
      appliances: [
        _ApplianceUsage(name: 'Kitchen Kettle', kwh: 48.2, share: 0.43),
        _ApplianceUsage(name: 'Master Fan', kwh: 32.1, share: 0.29),
        _ApplianceUsage(name: 'Living Room TV', kwh: 18.6, share: 0.17),
        _ApplianceUsage(name: 'TV Adaptor', kwh: 12.4, share: 0.11),
      ],
    ),
    const _PeriodData(
      vals: [
        88.0,
        72.0,
        95.0,
        81.0,
        104.0,
        118.0,
        99.0,
        112.0,
        136.0,
        94.0,
        78.0,
        101.0
      ],
      labs: ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'],
      peak: 'September',
      top: '136 kWh',
      dev: 'Kettle + Fan',
      appliances: [
        _ApplianceUsage(name: 'Kitchen Kettle', kwh: 486.0, share: 0.40),
        _ApplianceUsage(name: 'Master Fan', kwh: 364.0, share: 0.30),
        _ApplianceUsage(name: 'Living Room TV', kwh: 243.0, share: 0.20),
        _ApplianceUsage(name: 'TV Adaptor', kwh: 121.0, share: 0.10),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final devices = state.devices;
    final d = _data[_period];
    final total = d.vals.fold<double>(0.0, (a, b) => a + b);
    final avg = total / d.vals.length;
    final maxV = d.vals.fold<double>(0.0, (a, b) => a > b ? a : b);

    final totalWatts = devices.fold<int>(0, (s, d) => s + d.wattage);
    final liveAppliances = totalWatts == 0
        ? <_ApplianceUsage>[]
        : devices
            .map((d) => _ApplianceUsage(
                  name: d.name,
                  kwh: d.wattage / 1000.0,
                  share: d.wattage / totalWatts,
                ))
            .toList()
      ..sort((a, b) => b.kwh.compareTo(a.kwh));



    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // Period selector — sleek Segmented Control
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _cardBg(c),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: ['DAILY', 'WEEKLY', 'MONTHLY'].asMap().entries.map((e) {
                  final on = e.key == _period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _period = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: on ? c.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: on ? [BoxShadow(color: c.blue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                        ),
                        child: Center(
                          child: Text(e.value,
                              style: AppText.semi(12, on ? Colors.white : c.t3)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Consumption Overview — Unified Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg(c),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CONSUMPTION', style: AppText.lbl(c.blue).copyWith(letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              _period == 0 ? 'Today\'s Activity' : _period == 1 ? 'Weekly Overview' : 'Monthly Performance',
                              style: AppText.h(16, c.t1),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+12%', style: AppText.semi(11, c.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(children: [
                        _AnalyticStat(
                            label: 'Total',
                            value: total.toStringAsFixed(1),
                            unit: 'kWh',
                            color: c.t1),
                        Container(width: 1, color: c.border, height: 30),
                        _AnalyticStat(
                            label: 'Avg',
                            value: avg.toStringAsFixed(1),
                            unit: 'kWh',
                            color: c.t1),
                        Container(width: 1, color: c.border, height: 30),
                        _AnalyticStat(
                            label: 'Peak',
                            value: maxV.toStringAsFixed(1),
                            unit: 'kWh',
                            color: c.amber),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    // Enhanced Bar Chart
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(d.vals.length, (i) {
                          final h = ((d.vals[i] / maxV) * 85).clamp(6.0, 85.0);
                          final isPeak = (d.vals[i] - maxV).abs() < 0.0001;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Track
                                      Container(
                                        height: 85,
                                        width: 8,
                                        decoration: BoxDecoration(
                                          color: c.isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      // Bar
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 600 + (i * 50)),
                                        curve: Curves.easeOutBack,
                                        height: h,
                                        width: 8,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: isPeak 
                                              ? [c.blue, c.blue.withValues(alpha: 0.7)]
                                              : [c.blue.withValues(alpha: 0.3), c.blue.withValues(alpha: 0.15)],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(d.labs[i],
                                      style: AppText.lbl(isPeak ? c.blue : c.t2).copyWith(fontSize: 8)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ]),
            ),
          ),

          // Usage by appliance header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('USAGE BY APPLIANCE', style: AppText.lbl(c.t2)),
                  Text('kW rated', style: AppText.body(10, c.blue)),
                ]),
          ),

          // ── Scrollable appliance list (Diagnostic Cards) ─────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              itemCount: liveAppliances.isEmpty ? 1 : liveAppliances.length,
              itemBuilder: (context, i) {
                if (liveAppliances.isEmpty) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No device data available.', style: AppText.body(14, c.t3)),
                  ));
                }
                final a = liveAppliances[i];
                final Color barColor = a.share > 0.3
                    ? const Color(0xFF1756D6) // Deep Blue
                    : a.share > 0.1
                        ? const Color(0xFF3D8BFF) // Standard Blue
                        : const Color(0xFF90CAF9); // Light Sky Blue

                final bool isLive = a.kwh > 0.02;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _cardBg(c),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: barColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(child: Icon(Icons.bolt_rounded, size: 14, color: barColor)),
                                ),
                              if (isLive)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: c.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _cardBg(c), width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a.name, style: AppText.semi(14, c.t1)),
                              Row(
                                children: [
                                  Text('${(a.share * 100).round()}%', style: AppText.semi(10, barColor)),
                                  const SizedBox(width: 4),
                                  Text('contribution', style: AppText.body(10, c.t2)),
                                ],
                              ),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(a.kwh >= 1 ? a.kwh.toStringAsFixed(1) : '${(a.kwh * 1000).round()}', style: AppText.h(16, c.t1)),
                                const SizedBox(width: 2),
                                Text(a.kwh >= 1 ? 'kW' : 'W', style: AppText.body(9, c.t3)),
                              ],
                            ),
                            Text('current load', style: AppText.body(8, c.t2)),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Segmented Pro Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(children: [
                          Container(
                            height: 4, 
                            width: double.infinity, 
                            color: c.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F0F0)
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutQuart,
                            height: 4,
                            width: (MediaQuery.of(context).size.width - 64) * a.share,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [barColor.withValues(alpha: 0.4), barColor],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: barColor.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)
                              ]
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _AnalyticStat extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _AnalyticStat(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: AppText.lbl(c.t2).copyWith(fontSize: 9)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppText.h(18, color)),
              const SizedBox(width: 2),
              Text(unit, style: AppText.body(10, c.t3)),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─── ALERTS ───────────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  final ValueChanged<bool>? onScrollDown;
  const AlertsScreen({super.key, this.onScrollDown});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _tabIndex = 0; // 0 for ACTIVE ALERTS, 1 for EVENT LOG
  late final ScrollController _scrollCtrlActive;
  late final ScrollController _scrollCtrlLog;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrlActive = ScrollController()..addListener(_scrollListener);
    _scrollCtrlLog = ScrollController()..addListener(_scrollListener);
  }

  void _scrollListener() {
    final ctrl = _tabIndex == 0 ? _scrollCtrlActive : _scrollCtrlLog;
    if (!ctrl.hasClients) return;
    final offset = ctrl.offset;
    final goingDown = offset > _lastOffset;
    if ((offset - _lastOffset).abs() > 4) {
      widget.onScrollDown?.call(goingDown);
      _lastOffset = offset;
    }
  }

  @override
  void dispose() {
    _scrollCtrlActive.dispose();
    _scrollCtrlLog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();

    final active = state.activeAlerts;

    final logs = [
      (
        dot: c.red,
        label: 'CRITICAL',
        text: 'Overload · Kitchen Kettle',
        time: '1 min ago'
      ),
      (
        dot: c.red,
        label: 'CRITICAL',
        text: 'Overload · Kitchen Kettle',
        time: '3 min ago'
      ),
      (
        dot: c.amber,
        label: 'WARNING',
        text: 'High Temp · Kitchen Kettle',
        time: '6 min ago'
      ),
      (
        dot: c.blue,
        label: 'INFO',
        text: 'Device On · Master Fan',
        time: '12 min ago'
      ),
      (
        dot: c.green,
        label: 'RESOLVED',
        text: 'Cleared · Living Room TV',
        time: '18 min ago'
      ),
    ];

    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const SizedBox(height: 16),


          // ─── TAB TOGGLE (ACTIVE ALERTS | EVENT LOG) ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _cardBg(c),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _tabIndex == 0 ? c.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: _tabIndex == 0 
                            ? [BoxShadow(color: c.blue.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))] 
                            : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/Active Alert.png', width: 14, height: 14, color: _tabIndex == 0 ? Colors.white : c.t3),
                              const SizedBox(width: 6),
                              Text('ACTIVE ALERTS', style: AppText.semi(11, _tabIndex == 0 ? Colors.white : c.t3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _tabIndex == 1 ? c.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: _tabIndex == 1 
                            ? [BoxShadow(color: c.blue.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))] 
                            : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/Event Log.png', width: 14, height: 14, color: _tabIndex == 1 ? Colors.white : c.t3),
                              const SizedBox(width: 6),
                              Text('EVENT LOG', style: AppText.semi(11, _tabIndex == 1 ? Colors.white : c.t3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                // TAB 0: ACTIVE ALERTS
                ListView(
                  controller: _scrollCtrlActive,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (active.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: c.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check_circle_outline, size: 32, color: c.green),
                              ),
                              const SizedBox(height: 16),
                              Text('All Systems Normal', style: AppText.semi(16, c.t1)),
                              const SizedBox(height: 8),
                              Text('No active alerts at this time', style: AppText.body(13, c.t3)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...active.map((a) {
                        final col = a.isRed ? c.red : c.amber;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _cardBg(c),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c.border.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: col.withValues(alpha: 0.08),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(width: 6, height: 6, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Text(a.severity, style: AppText.med(11, col).copyWith(letterSpacing: 0.5)),
                                      ],
                                    ),
                                    Text(a.time, style: AppText.body(10, c.t3)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: col.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(child: Icon(Icons.warning_amber_rounded, size: 20, color: col)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.type, style: AppText.semi(15, c.t1)),
                                          const SizedBox(height: 4),
                                          Text(a.device, style: AppText.semi(13, col)),
                                          const SizedBox(height: 8),
                                          Text(a.detail, style: AppText.body(12, c.t2).copyWith(height: 1.5)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => state.dismissAlert(a.id),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: c.raised,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: c.border),
                                        ),
                                        child: Icon(Icons.close, size: 16, color: c.t3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
                // TAB 1: EVENT LOG
                ListView.builder(
                  controller: _scrollCtrlLog,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: logs.length,
                  itemBuilder: (context, i) {
                    final log = logs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cardBg(c),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: log.dot, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: log.dot.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(log.label, style: AppText.semi(10, log.dot)),
                                    ),
                                    Text(log.time, style: AppText.body(10, c.t3)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(log.text, style: AppText.med(13, c.t1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}


// ─── SETTINGS ─────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const SettingsScreen({super.key, required this.onSignOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif = true;



  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // ── Header Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: AppIcon('back', size: 18, color: c.t1),
                ),
                const SizedBox(width: 16),
                Text('Settings', style: AppText.h(20, c.t1)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: [
                // ── Search Bar (Sleek) ──────────────────────────────────────
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _cardBg(c),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(children: [
                    Image.asset('assets/Search.png', width: 16, height: 16, color: c.t3),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Search preferences...',
                          hintStyle: AppText.body(14, c.t3),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 8),

                _SettingsGroup(
                    title: 'Account',
                    cardBg: _cardBg(c),
                    border: c.border,
                    children: [
                      AppListRow(
                          icon: 'user',
                          iconColor: c.blue,
                          label: 'Personal Information',
                          sub: 'Name, email, phone number',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AccountSubScreen()))),
                      AppListRow(
                          icon: 'lock',
                          iconColor: c.amber,
                          label: 'Security & Password',
                          sub: '2FA, login sessions, privacy',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SecuritySubScreen()))),
                      AppListRow(
                          icon: 'bell',
                          iconColor: c.red,
                          label: 'Alert Notifications',
                          sub: 'Manage critical device alerts',
                          trailing: AppToggle(
                              value: _notif,
                              onChanged: (v) => setState(() => _notif = v))),
                      AppListRow(
                          icon: 'info',
                          iconColor: c.blue,
                          label: 'Announcements & Updates',
                          sub: 'App news and account info',
                          trailing: state.hasNewNotification 
                            ? Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: c.red, shape: BoxShape.circle),
                              )
                            : null,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsSubScreen()))),
                      AppListRow(
                          icon: 'phone',
                          iconColor: c.green,
                          label: 'Manage Shared Access',
                          sub: '${state.totalSharedUsersCount} users have access to devices',
                          trailing: AppTag(text: '${state.totalSharedUsersCount}', color: c.blue),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ActiveSharedDevicesSubScreen())), // Dedicated screen
                          divider: false),
                    ]),
                const SizedBox(height: 2),
                _SettingsGroup(
                    title: 'Application',
                    cardBg: _cardBg(c),
                    border: c.border,
                    children: [
                      AppListRow(
                          icon: 'refresh',
                          iconColor: c.green,
                          label: 'Firmware Update',
                          sub: 'v2.4.1 — Latest version',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FirmwareSubScreen()))),
                      AppListRow(
                        icon: state.isDark ? 'moon' : 'sun',
                        iconColor: state.isDark ? c.t2 : c.amber,
                        label: 'Appearance',
                        sub: state.isDark ? 'System Dark Mode' : 'System Light Mode',
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: RotationTransition(
                            turns: AlwaysStoppedAnimation(state.isDark ? 0 : 0.5),
                            child: Switch(
                              value: state.isDark,
                              onChanged: (_) => state.toggleTheme(),
                              activeThumbColor: c.blue,
                            ),
                          ),
                        ),
                      ),
                      AppListRow(
                          icon: 'info',
                          iconColor: c.t3,
                          label: 'About FlameGuard',
                          sub: 'Version 1.0.0 (Build 240)',
                          divider: false),
                    ]),
                const SizedBox(height: 10),
                
                // ── Logout Button (Professional Variant) ────────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    widget.onSignOut();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.red.withValues(alpha: 0.15)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon('logout', size: 16, color: c.red),
                          const SizedBox(width: 8),
                          Text('Sign Out', style: AppText.semi(15, c.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── SETTINGS GROUP (white card version) ─────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final String title;
  final Color cardBg;
  final Color border;
  final List<Widget> children;
  const _SettingsGroup(
      {required this.title,
      required this.cardBg,
      required this.border,
      required this.children});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: AppText.lbl(c.t3)),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(children: children),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ─── SHARED BACK HEADER ───────────────────────────────────────────────────────
Widget _buildBackHeader(BuildContext context, String title) {
  final c = colorsOf(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: AppIcon('back', size: 18, color: c.t1),
      ),
      const SizedBox(width: 14),
      Text(title, style: AppText.semi(16, c.t1)),
    ]),
  );
}

// ─── ACCOUNT SUB-SCREEN ───────────────────────────────────────────────────────
class AccountSubScreen extends StatelessWidget {
  const AccountSubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        child: Column(children: [
          _buildBackHeader(context, 'Account'),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        const SizedBox(height: 32),
                    Text('Account', style: AppText.semi(15, c.t1)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: _cardBg(c),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border)),
                      child: Column(children: [
                        _AccountRow(icon: 'user', label: 'Personal Data', c: c),
                        Divider(height: 1, indent: 52, color: c.border),
                        _AccountRow(icon: 'mail', label: 'Email Address', c: c),
                        Divider(height: 1, indent: 52, color: c.border),
                        _AccountRow(
                            icon: 'phone',
                            label: 'Phone Number',
                            c: c,
                            isLast: true),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    Text('Danger Zone', style: AppText.semi(15, c.t1)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: _cardBg(c),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border)),
                      child: _AccountRow(
                          icon: 'x',
                          label: 'Delete Account',
                          c: c,
                          iconColor: c.red,
                          isLast: true),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── NOTIFICATIONS SUB-SCREEN ────────────────────────────────────────────────
class NotificationsSubScreen extends StatefulWidget {
  const NotificationsSubScreen({super.key});

  @override
  State<NotificationsSubScreen> createState() => NotificationsSubScreenState();
}

class NotificationsSubScreenState extends State<NotificationsSubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().clearNewNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final notifications = state.notifications;

    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        child: Column(children: [
          _buildBackHeader(context, 'Announcements'),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(color: c.raised, shape: BoxShape.circle),
                          child: Icon(Icons.notifications_none_rounded, size: 30, color: c.t3),
                        ),
                        const SizedBox(height: 16),
                        Text('No announcements', style: AppText.semi(16, c.t1)),
                        const SizedBox(height: 8),
                        Text('You\'re all caught up!', style: AppText.body(13, c.t3)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
                        padding: const EdgeInsets.all(12), // Reduced from 16
                        decoration: BoxDecoration(
                          color: _cardBg(c),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8), // Reduced from 9
                                  decoration: BoxDecoration(
                                    color: n.isNew ? c.blue.withValues(alpha: 0.1) : c.raised,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: AppIcon(n.isNew ? 'bell' : 'info', 
                                    size: 14, color: n.isNew ? c.blue : c.t3), // Slightly smaller icon
                                ),
                                const SizedBox(width: 10), // Reduced from 12
                                Expanded(
                                  child: Text(n.title, 
                                    style: AppText.semi(14, c.t1), // Slightly smaller text
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                PopupMenuButton<int>(
                                  icon: Icon(Icons.more_horiz_rounded, size: 18, color: c.t3.withValues(alpha: 0.4)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (val) {
                                    if (val == 0) {
                                      state.deleteNotification(n.id);
                                    } else if (val == 1) {
                                      state.toggleCategory(n.category, false);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: c.red),
                                          const SizedBox(width: 10),
                                          Text('Delete this notification', style: AppText.med(13, c.t1)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          Icon(Icons.notifications_off_outlined, size: 18, color: c.t2),
                                          const SizedBox(width: 10),
                                          Text('Turn off ${n.category.name} notifications', style: AppText.med(13, c.t1)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 42), // Adjusted for new proportions (8*2+14+12=42)
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.body, style: AppText.body(12, c.t3).copyWith(height: 1.3)),
                                  const SizedBox(height: 6), // Reduced from 8
                                  Row(
                                    children: [
                                      Text(n.time, style: AppText.body(10, c.t3)),
                                      if (n.isNew) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: c.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('NEW', style: AppText.semi(7, c.blue)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── SECURITY SUB-SCREEN ──────────────────────────────────────────────────────
class SecuritySubScreen extends StatefulWidget {
  const SecuritySubScreen({super.key});
  @override
  State<SecuritySubScreen> createState() => SecuritySubScreenState();
}

class SecuritySubScreenState extends State<SecuritySubScreen> {
  bool _twoFA = true;
  bool _bio = false;

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        child: Column(children: [
          _buildBackHeader(context, 'Security'),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _SettingsGroup(
                    title: 'Authentication',
                    cardBg: _cardBg(c),
                    border: c.border,
                    children: [
                      AppListRow(
                          icon: 'shield',
                          iconColor: c.blue,
                          label: 'Two-Factor Auth',
                          sub: 'Extra layer of login security',
                          trailing: AppToggle(
                              value: _twoFA,
                              onChanged: (v) => setState(() => _twoFA = v))),
                      AppListRow(
                          icon: 'eye',
                          label: 'Biometric Login',
                          sub: 'Fingerprint or Face ID',
                          trailing: AppToggle(
                              value: _bio,
                              onChanged: (v) => setState(() => _bio = v))),
                      AppListRow(
                          icon: 'bell',
                          label: 'Security Alerts',
                          sub: 'Notify on suspicious activity',
                          trailing: AppToggle(value: true, onChanged: (_) {}),
                          divider: false),
                    ]),
                _SettingsGroup(
                    title: 'Access Control',
                    cardBg: _cardBg(c),
                    border: c.border,
                    children: const [
                      AppListRow(
                          icon: 'lock',
                          label: 'Change Password',
                          sub: 'Update your password',
                          divider: false),
                    ]),
                // Last login card — white in light
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: _cardBg(c),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border)),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: c.blue.withAlpha(18),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: AppIcon('phone', size: 18, color: c.blue)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('LAST LOGIN', style: AppText.lbl(c.t3)),
                          const SizedBox(height: 4),
                          Text('Today · 9:28 AM',
                              style: AppText.semi(14, c.t1)),
                          const SizedBox(height: 2),
                          Text('iPhone 14 Pro · Metro Manila, PH',
                              style: AppText.body(11, c.t3)),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: c.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('Verified', style: AppText.semi(10, c.green)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── FIRMWARE SUB-SCREEN ──────────────────────────────────────────────────────
class FirmwareSubScreen extends StatefulWidget {
  const FirmwareSubScreen({super.key});
  @override
  State<FirmwareSubScreen> createState() => FirmwareSubScreenState();
}

class FirmwareSubScreenState extends State<FirmwareSubScreen> {
  bool _checking = false;
  bool _checked = false;

  void _checkFw() {
    setState(() {
      _checking = true;
      _checked = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _checking = false;
          _checked = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        child: Column(children: [
          _buildBackHeader(context, 'Firmware'),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Version card — white in light
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _cardBg(c),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border)),
                  child: Column(children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                          color: c.blue,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: c.blue.withAlpha(18),
                              borderRadius: BorderRadius.circular(13)),
                          child: Center(
                              child: Image.asset('assets/Charger.png',
                                  width: 24, height: 24, color: c.blue)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('CURRENT VERSION', style: AppText.lbl(c.t3)),
                              const SizedBox(height: 4),
                              Text('v2.4.1', style: AppText.h(22, c.t1)),
                              const SizedBox(height: 2),
                              Text('Released November 28, 2024',
                                  style: AppText.body(11, c.t3)),
                            ])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.green.withAlpha(40)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: c.green, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('Latest', style: AppText.semi(10, c.green)),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
                PrimaryButton(
                    label: _checking ? 'Checking...' : 'Check for Updates',
                    onPressed: _checkFw,
                    loading: _checking),
                if (_checked) ...[
                  const SizedBox(height: 12),
                  const SuccessBanner('You are up to date.'),
                ],
                const SizedBox(height: 20),
                _SettingsGroup(
                    title: 'Release History',
                    cardBg: _cardBg(c),
                    border: c.border,
                    children: [
                      AppListRow(
                          icon: 'check',
                          iconColor: c.green,
                          label: 'v2.4.1',
                          sub: 'Bug fixes and stability',
                          trailing: AppTag(text: 'Current', color: c.green)),
                      const AppListRow(
                          icon: 'refresh',
                          label: 'v2.4.0',
                          sub: 'Auto-Cutoff feature'),
                      const AppListRow(
                          icon: 'refresh',
                          label: 'v2.3.5',
                          sub: 'Fire Risk Gauge improvements',
                          divider: false),
                    ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── ACCOUNT ROW HELPER ───────────────────────────────────────────────────────
class _AccountRow extends StatelessWidget {
  final String icon;
  final String label;
  final AppColors c;
  final Color? iconColor;
  final bool isLast;

  const _AccountRow(
      {required this.icon,
      required this.label,
      required this.c,
      this.iconColor,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final col = iconColor ?? c.t2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: col.withAlpha(16),
              borderRadius: BorderRadius.circular(10)),
          child: Center(child: AppIcon(icon, size: 16, color: col)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: AppText.semi(14, c.t1))),
        AppIcon('right', size: 14, color: c.t3),
      ]),
    );
  }
}

// ─── ACTIVE SHARED DEVICES SUB-SCREEN ────────────────────────────────────────
class ActiveSharedDevicesSubScreen extends StatelessWidget {
  const ActiveSharedDevicesSubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final sharedDevices = state.devices.where((d) => d.sharedUsers.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: _screenBg(c),
      body: SafeArea(
        child: Column(children: [
          _buildBackHeader(context, 'Active Shared Devices'),
          Expanded(
            child: sharedDevices.isEmpty
                ? _buildEmptyState(c)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: sharedDevices.length,
                    itemBuilder: (context, i) {
                      final d = sharedDevices[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _cardBg(c),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: c.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AppIcon(d.icon, size: 16, color: c.blue),
                            ),
                            title: Text(d.name, style: AppText.semi(14, c.t1)),
                            subtitle: Text('Shared with ${d.sharedUsers.length} user${d.sharedUsers.length > 1 ? 's' : ''}', 
                                style: AppText.body(11, c.t3)),
                            trailing: _buildUserAvatars(d.sharedUsers, c),
                            children: d.sharedUsers.map((u) => _buildSharedUserRow(context, state, d, u, c)).toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(dynamic c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: c.raised, shape: BoxShape.circle),
            child: Icon(Icons.share_outlined, size: 28, color: c.t3),
          ),
          const SizedBox(height: 16),
          Text('No shared devices yet', style: AppText.semi(16, c.t1)),
          const SizedBox(height: 8),
          Text('Devices you share will appear here.', style: AppText.body(14, c.t3)),
        ],
      ),
    );
  }

  Widget _buildUserAvatars(List<SharedUser> users, dynamic c) {
    int show = users.length > 3 ? 3 : users.length;
    return SizedBox(
      width: 44,
      child: Stack(
        children: List.generate(show, (i) {
          return Positioned(
            left: i * 12.0,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Center(
                child: Image.asset('assets/User Icon.png', width: 18, height: 18, color: c.t3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSharedUserRow(BuildContext context, AppState state, DeviceModel d, SharedUser u, dynamic c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.raised.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.border.withOpacity(0.5))),
            child: Image.asset('assets/User Icon.png', color: c.t2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name, style: AppText.med(13, c.t1)),
                Text('Standard Access', style: AppText.body(10, c.t3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: c.surface,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   title: Text('Terminate Access', style: AppText.semi(18, c.t1)),
                   content: Text('Remove ${u.name}\'s access to ${d.name}?', style: AppText.body(14, c.t2)),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(context), 
                        child: Text('Cancel', style: AppText.med(14, c.t3))),
                     TextButton(onPressed: () {
                        state.deleteSharedUser(d.id, u.id);
                        Navigator.pop(context);
                     }, child: Text('Remove', style: AppText.semi(14, c.red))),
                   ],
                 ),
               );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: c.red.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, color: c.red, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
