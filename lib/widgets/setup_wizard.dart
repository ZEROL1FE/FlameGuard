import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/add_device_sheet.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ─── SMART SETUP WIZARD ──────────────────────────────────────────────────────
enum SetupPhase { discovery, qr, found, wifi, syncing, details }

class SmartSetupWizard extends StatefulWidget {
  const SmartSetupWizard({super.key});
  @override
  State<SmartSetupWizard> createState() => _SmartSetupWizardState();
}

class _SmartSetupWizardState extends State<SmartSetupWizard> with TickerProviderStateMixin {
  SetupPhase _phase = SetupPhase.discovery;
  late AnimationController _radarCtrl;
  bool _foundFallback = false;
  
  // Wi-Fi inputs
  final _wifiPass = TextEditingController();
  final String _selectedWifi = 'Home_WiFi_5G';

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    
    // Simulation: Find device after 8s
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _phase == SetupPhase.discovery) {
        setState(() => _phase = SetupPhase.found);
      }
    });

    // Fallback logic
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _phase == SetupPhase.discovery) {
        setState(() => _foundFallback = true);
      }
    });
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _wifiPass.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      if (_phase == SetupPhase.qr) {
        _phase = SetupPhase.found;
      } else if (_phase == SetupPhase.found) {
        _phase = SetupPhase.wifi;
      } else if (_phase == SetupPhase.wifi) {
        _phase = SetupPhase.syncing;
      } else if (_phase == SetupPhase.syncing) {
        _phase = SetupPhase.details;
      }
    });

    if (_phase == SetupPhase.syncing) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _next();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.65,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: c.border),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
        ),
        
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder: (child, entries) => Stack(
              alignment: Alignment.topCenter,
              children: [if (child != null) child, ...entries],
            ),
            child: _buildPhase(context),
          ),
        ),
      ]),
    );
  }

  Widget _buildPhase(BuildContext context) {
    switch (_phase) {
      case SetupPhase.discovery: return _DiscoveryView(radarCtrl: _radarCtrl, fallback: _foundFallback, onScanQR: () => setState(() => _phase = SetupPhase.qr));
      case SetupPhase.qr: return _QRScanView(onScanned: _next);
      case SetupPhase.found: return _FoundView(onConnect: _next, radarCtrl: _radarCtrl);
      case SetupPhase.wifi: return _WifiView(onNext: _next, controller: _wifiPass, selected: _selectedWifi);
      case SetupPhase.syncing: return _SyncingView();
      case SetupPhase.details: return const AddDeviceSheet(); // Reusing the final form
    }
  }
}

// ─── Phase Views ─────────────────────────────────────────────────────────────

class _DiscoveryView extends StatelessWidget {
  final AnimationController radarCtrl;
  final bool fallback;
  final VoidCallback onScanQR;
  const _DiscoveryView({required this.radarCtrl, required this.fallback, required this.onScanQR});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text('Searching for Adaptors', style: AppText.h(19, c.t1)),
          const SizedBox(height: 4),
          Text('Make sure your adaptor is plugged in\nand nearby.', style: AppText.body(13, c.t3)),
          
          const Spacer(),
          SizedBox(
            height: 180,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
              children: [
                ...List.generate(3, (i) {
                  final anim = CurvedAnimation(parent: radarCtrl, curve: Interval(i * 0.2, 1.0, curve: Curves.easeOut));
                  return AnimatedBuilder(
                    animation: anim,
                    builder: (context, child) => Container(
                      width: 40 + (anim.value * 60),
                      height: 40 + (anim.value * 60),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.blue.withValues(alpha: 0.8 * (1 - anim.value)), width: 1.5),
                      ),
                    ),
                  );
                }),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: c.blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.blue.withValues(alpha: 0.2))),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.blue, shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: c.blue.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
                      ]),
                      child: const Icon(Icons.wifi_tethering, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          
          if (fallback) ...[
            Center(
              child: Column(children: [
                Text('Still searching...', style: AppText.semi(13, c.t3)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onScanQR,
                  child: Text('Scan QR instead', style: AppText.body(13, c.blue)),
                ),
              ]),
            ),
          ],
          
          const Spacer(),

          Opacity(
            opacity: 0.6,
            child: Container(
              height: 60,
              decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Searching for Hotspot...', style: AppText.semi(18, c.t3))),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _FoundView extends StatelessWidget {
  final VoidCallback onConnect;
  final AnimationController radarCtrl;
  const _FoundView({required this.onConnect, required this.radarCtrl});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text('FlameGuard Adaptor V1', style: AppText.h(19, c.t1)),
          const SizedBox(height: 8),
          Text('Ready to connect via Hotspot', style: AppText.body(14, c.t3)),
          
          const Spacer(),
          SizedBox(
            height: 180,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (i) {
                    final anim = CurvedAnimation(parent: radarCtrl, curve: Interval(i * 0.2, 1.0, curve: Curves.easeOut));
                    return AnimatedBuilder(
                      animation: anim,
                      builder: (context, child) => Container(
                        width: 40 + (anim.value * 60),
                        height: 40 + (anim.value * 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.blue.withValues(alpha: 0.8 * (1 - anim.value)), width: 1.5),
                        ),
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.blueFade, 
                      shape: BoxShape.circle,
                      border: Border.all(color: c.blue.withValues(alpha: 0.1)),
                    ),
                    child: AppIcon('others', size: 48, color: c.blue),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          GestureDetector(
            onTap: onConnect,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: c.blue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: c.blue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Center(child: Text('Connect Now', style: AppText.semi(16, Colors.white))),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _WifiView extends StatelessWidget {
  final VoidCallback onNext;
  final TextEditingController controller;
  final String selected;
  const _WifiView({required this.onNext, required this.controller, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Connect to Wi-Fi', style: AppText.h(16, c.t1)),
          const SizedBox(height: 4),
          Text('The adaptor needs to connect to your home network.', style: AppText.body(13, c.t3)),
          const SizedBox(height: 16),
          Text('SELECT NETWORK', style: AppText.lbl(c.t3)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Row(children: [
              Icon(Icons.wifi, size: 20, color: c.blue),
              const SizedBox(width: 12),
              Expanded(child: Text(selected, style: AppText.semi(15, c.t1))),
              Icon(Icons.keyboard_arrow_down, color: c.t3),
            ]),
          ),
          const SizedBox(height: 12),
          Text('PASSWORD', style: AppText.lbl(c.t3)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            style: AppText.body(15, c.t1),
            decoration: InputDecoration(
              filled: true, fillColor: c.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.blue, width: 2)),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onNext,
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: c.blue, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Sync Wi-Fi Settings', style: AppText.semi(16, Colors.white))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SyncingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Syncing Process...', style: AppText.h(19, c.t1)),
          const SizedBox(height: 4),
          Text('Connecting adaptor to the cloud.', style: AppText.body(14, c.t3)),
          
          const Spacer(),
          const Center(
            child: SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
          ),
          const Spacer(),

          Opacity(
            opacity: 0.6,
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Connecting to Cloud...', style: AppText.semi(16, c.t3))),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _QRScanView extends StatelessWidget {
  final VoidCallback onScanned;
  const _QRScanView({required this.onScanned});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('Scan QR Code', style: AppText.h(22, c.t1)),
          const SizedBox(height: 8),
          Text('Point your camera at the QR code on the adaptor.', style: AppText.body(14, c.t3)),
          const Spacer(),
          Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: c.blue, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    onScanned();
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onScanned,
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: c.blue, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Simulate Scan Success', style: AppText.semi(16, Colors.white))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
