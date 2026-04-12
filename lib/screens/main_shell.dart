// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device_model.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'device_detail_screen.dart';
import 'remaining_screens.dart';
import '../widgets/setup_wizard.dart';
import '../widgets/app_drawer.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onSignOut;
  const MainShell({super.key, required this.onSignOut});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  DeviceModel? _selectedDevice;
  bool _navVisible = true;
  bool _drawerOpen = false;
  late final AnimationController _navAnim;
  late final Animation<Offset> _navSlide;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _navSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _navAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _navAnim.dispose();
    super.dispose();
  }

  void _onScrollDown(bool goingDown) {
    if (_drawerOpen) return;
    if (goingDown && _navVisible) {
      setState(() => _navVisible = false);
      _navAnim.reverse();
    } else if (!goingDown && !_navVisible) {
      setState(() => _navVisible = true);
      _navAnim.forward();
    }
  }

  void _openDevice(DeviceModel d) {
    context.read<AppState>().selectDevice(d);
    if (!_navVisible) {
      setState(() => _navVisible = true);
      _navAnim.forward();
    }
    setState(() => _selectedDevice = d);
  }

  void _closeDevice() => setState(() => _selectedDevice = null);

  void _startSmartSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmartSetupWizard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);

    if (_selectedDevice != null) {
      return DeviceDetailScreen(
        device: _selectedDevice!,
        onBack: _closeDevice,
      );
    }

    final screens = [
      DashboardScreen(isHome: true,  onSelectDevice: _openDevice, onScrollDown: _onScrollDown, onSignOut: widget.onSignOut),
      DashboardScreen(isHome: false, onSelectDevice: _openDevice, onScrollDown: _onScrollDown, onSignOut: widget.onSignOut),
      AnalyticsScreen(onScrollDown: _onScrollDown),
      AlertsScreen(onScrollDown: _onScrollDown),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF2F2F2),
      onDrawerChanged: (isOpen) {
        setState(() => _drawerOpen = isOpen);
        if (isOpen) {
          _navAnim.reverse();
        } else if (_navVisible) {
          _navAnim.forward();
        }
      },
      drawer: AppDrawer(onSignOut: widget.onSignOut),
      body: IndexedStack(
        index: _tab,
        children: screens,
      ),
      bottomNavigationBar: SlideTransition(
          position: _navSlide,
          child: AppBottomNav(
          currentIndex: _tab,
          onTap: (i) {
            if (!_navVisible) {
              setState(() => _navVisible = true);
              _navAnim.forward();
            }
            setState(() => _tab = i);
          },
          ),
        ),
      floatingActionButton: ScaleTransition(
        scale: _navAnim,
        child: FloatingActionButton(
          onPressed: _startSmartSetup,
          backgroundColor: c.blue,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}