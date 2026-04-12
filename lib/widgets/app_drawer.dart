import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/remaining_screens.dart';
import 'common_widgets.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback onSignOut;
  const AppDrawer({super.key, required this.onSignOut});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _selectedLabel;

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final isDark = state.isDark;

    return Drawer(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ───────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 16, 32),
              child: AppLogo(showTagline: false, scale: 0.85),
            ),
            Divider(height: 1, thickness: 1, indent: 24, endIndent: 24, color: Colors.grey.withValues(alpha: 0.9)),
            const SizedBox(height: 24),

            // ── MAIN MENU ITEMS ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('MENU', style: AppText.med(11, Colors.grey.withValues(alpha: 0.6)).copyWith(letterSpacing: 1.5)),
                    ),
                    _DrawerItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Personal Information',
                      selected: _selectedLabel == 'Personal Information',
                      onTap: () {
                        setState(() => _selectedLabel = 'Personal Information');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSubScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Security & Password',
                      selected: _selectedLabel == 'Security & Password',
                      onTap: () {
                        setState(() => _selectedLabel = 'Security & Password');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySubScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.smartphone_rounded,
                      label: 'Manage Shared Access',
                      badge: '${state.totalSharedUsersCount}',
                      selected: _selectedLabel == 'Manage Shared Access',
                      onTap: () {
                        setState(() => _selectedLabel = 'Manage Shared Access');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveSharedDevicesSubScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications & Updates',
                      selected: _selectedLabel == 'Notifications & Updates',
                      onTap: () {
                        setState(() => _selectedLabel = 'Notifications & Updates');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSubScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.contrast_rounded,
                      label: 'Appearance',
                      selected: _selectedLabel == 'Appearance',
                      trailing: AppToggle(
                        value: isDark,
                        onChanged: (_) {
                          setState(() => _selectedLabel = 'Appearance');
                          state.toggleTheme();
                        },
                      ),
                      onTap: () => setState(() => _selectedLabel = 'Appearance'),
                    ),
                    _DrawerItem(
                      icon: Icons.refresh_rounded,
                      label: 'Firmware Update',
                      selected: _selectedLabel == 'Firmware Update',
                      onTap: () {
                        setState(() => _selectedLabel = 'Firmware Update');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmwareSubScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About FlameGuard',
                      selected: _selectedLabel == 'About FlameGuard',
                      onTap: () {
                        setState(() => _selectedLabel = 'About FlameGuard');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── FOOTER ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                selected: _selectedLabel == 'Log out',
                onTap: () {
                  setState(() => _selectedLabel = 'Log out');
                  Navigator.pop(context);
                  widget.onSignOut();
                },
              ),
            ),
            Divider(height: 1, thickness: 1, indent: 24, endIndent: 24, color: Colors.grey.withValues(alpha: 0.9)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline_rounded, size: 24, color: c.t2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kenneth Cajayon', style: AppText.med(14, c.t1)),
                          Text('kenneth.cajayon@gmail.com', style: AppText.body(11, c.t3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.badge,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final color = selected ? c.blue : c.t2;
    final textCol = selected ? c.blue : c.t1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  right: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: c.blue,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label, style: AppText.med(14, textCol)),
                    ),
                    if (trailing != null || badge != null)
                      trailing ?? (badge != null 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        : const SizedBox.shrink()),
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
