import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/time_utils.dart';
import '../widgets/add_device_sheet.dart';
import '../widgets/setup_wizard.dart';
import '../widgets/share_access_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final bool isHome;
  final ValueChanged<DeviceModel> onSelectDevice;
  final ValueChanged<bool>? onScrollDown;
  final VoidCallback onSignOut;
  const DashboardScreen({
    super.key,
    required this.isHome,
    required this.onSelectDevice,
    required this.onSignOut,
    this.onScrollDown,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ScrollController _scrollCtrl;
  double _lastOffset = 0;
  String _selectedRoom = 'ALL';

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

  void _showAddDevice(BuildContext context, {DeviceModel? device}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDeviceSheet(device: device),
    );
  }

  void _startSmartSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmartSetupWizard(),
    );
  }

  void _showShareAccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareAccessSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final devices = state.devices;
    final total = state.totalWatts;
    final isLight = !c.isDark;

    final defaultRooms = ['Living', 'Bedroom', 'Kitchen'];
    final filtered = _selectedRoom == 'ALL'
        ? devices
        : devices.where((d) {
            if (_selectedRoom == 'Others') {
              return !defaultRooms.contains(d.zone);
            }
            return d.zone == _selectedRoom;
          }).toList();

    return Column(
      children: [
        // ── HEADER ─────────────────────────────────────────────────
        if (isLight)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D8BFF), Color(0xFF1756D6)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              minimum: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isHome) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const _CustomMenuIcon(color: Colors.white, size: 22),
                                    if (state.hasNewNotification)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: c.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF3D8BFF), width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showShareAccess(context),
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: AppIcon('userplus', size: 22, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('TOTAL POWER', style: AppText.lbl(Colors.white.withValues(alpha: 0.7)).copyWith(fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            total >= 1000 ? (total / 1000).toStringAsFixed(2) : '$total',
                            style: AppText.h(38, Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(total >= 1000 ? 'kW' : 'W', style: AppText.body(16, Colors.white.withValues(alpha: 0.7))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active', style: AppText.lbl(Colors.white.withValues(alpha: 0.7))),
                                const SizedBox(height: 2),
                                Text('${devices.where((d) => d.active).length} devices', style: AppText.semi(13, Colors.white)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.25)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Standby', style: AppText.lbl(Colors.white.withValues(alpha: 0.7))),
                                const SizedBox(height: 2),
                                Text('${devices.where((d) => !d.active).length} devices', style: AppText.semi(13, Colors.white.withValues(alpha: 0.85))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('ALL APPLIANCES', style: AppText.h(11, Colors.white)),
                          if (devices.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showShareAccess(context),
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: AppIcon('userplus', size: 22, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1.5)),
            ),
            child: SafeArea(
              bottom: false,
              minimum: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isHome) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _CustomMenuIcon(color: c.t2, size: 22),
                                    if (state.hasNewNotification)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: c.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF222222), width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showShareAccess(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: AppIcon('userplus', size: 22, color: c.t2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('TOTAL POWER', style: AppText.lbl(c.t2).copyWith(fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            total >= 1000 ? (total / 1000).toStringAsFixed(2) : '$total',
                            style: AppText.h(38, c.blue),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(total >= 1000 ? 'kW' : 'W', style: AppText.body(16, Colors.white.withValues(alpha: 0.55))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active', style: AppText.lbl(c.t2)),
                                const SizedBox(height: 2),
                                Text('${devices.where((d) => d.active).length} devices', style: AppText.semi(13, c.blue)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Standby', style: AppText.lbl(c.t2)),
                                const SizedBox(height: 2),
                                Text('${devices.where((d) => !d.active).length} devices', style: AppText.semi(13, Colors.white.withValues(alpha: 0.55))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('ALL APPLIANCES', style: AppText.lbl(c.t2)),
                          if (devices.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showShareAccess(context),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AppIcon('userplus', size: 22, color: c.t2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (widget.isHome)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('APPLIANCES', style: AppText.lbl(c.t3)),
                  ],
                ),
                const SizedBox(height: 12),
                _RoomFilterSelector(
                  selected: _selectedRoom,
                  onSelect: (r) => setState(() => _selectedRoom = r),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _RoomFilterSelector(
              selected: _selectedRoom,
              onSelect: (r) => setState(() => _selectedRoom = r),
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 16 * 2 - 12) / 2;
              final rows = (filtered.length / 2).ceil();
              return SingleChildScrollView(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(16, widget.isHome ? 8 : 20, 16, MediaQuery.of(context).padding.bottom + 100),
                physics: const ClampingScrollPhysics(),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: c.blueFade, shape: BoxShape.circle),
                              child: AppIcon('others', size: 48, color: c.blue),
                            ),
                            const SizedBox(height: 24),
                            Text('No Devices Yet', style: AppText.h(20, c.t1)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text('Connect your first adaptor to start monitoring your home appliances.', textAlign: TextAlign.center, style: AppText.body(13, c.t3)),
                            ),
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: () => _startSmartSetup(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                decoration: BoxDecoration(
                                  color: c.blue,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: c.blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                                ),
                                child: Text('Get Started', style: AppText.semi(15, Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: List.generate(rows, (row) {
                          final left = row * 2;
                          final right = row * 2 + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  height: cardWidth * 0.68,
                                  child: _DeviceCard(
                                    device: filtered[left],
                                    onTap: () => widget.onSelectDevice(filtered[left]),
                                    onEdit: () => _showAddDevice(context, device: filtered[left]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (right < filtered.length)
                                  SizedBox(
                                    width: cardWidth,
                                    height: cardWidth * 0.68,
                                    child: _DeviceCard(
                                      device: filtered[right],
                                      onTap: () => widget.onSelectDevice(filtered[right]),
                                      onEdit: () => _showAddDevice(context, device: filtered[right]),
                                    ),
                                  )
                                else
                                  SizedBox(width: cardWidth),
                              ],
                            ),
                          );
                        }),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoomFilterSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _RoomFilterSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final rooms = ['ALL', 'Living', 'Bedroom', 'Kitchen', 'Others'];
    final roomIcons = {
      'Living': 'assets/Living.png',
      'Bedroom': 'assets/Bedroom.png',
      'Kitchen': 'assets/Kitchen.png',
      'Others': 'assets/Others.png',
    };
    
    return SizedBox(
      width: double.infinity,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: rooms.map((r) {
          final isSelected = r == selected;
          
          // Adaptive color logic
          Color chipBg;
          Color textColor;
          Color borderColor;

          if (c.isDark) {
            // Dark mode general
            chipBg = isSelected ? c.blue : const Color(0xFF1E1E1E);
            textColor = isSelected ? Colors.white : c.t2;
            borderColor = isSelected ? c.blue : Colors.white.withValues(alpha: 0.1);
          } else {
            // Light mode general
            chipBg = isSelected ? c.blue : Colors.white;
            textColor = isSelected ? Colors.white : c.t2;
            borderColor = isSelected ? c.blue : const Color(0xFFE5E5E5);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: isSelected && !c.isDark
                      ? [BoxShadow(color: c.blue.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (roomIcons.containsKey(r)) ...[
                      Image.asset(
                        roomIcons[r]!,
                        width: 16,
                        height: 16,
                        color: textColor,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      r.toUpperCase(),
                      style: AppText.semi(11, textColor).copyWith(letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  ),
);
  }
}


class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _DeviceCard({
    required this.device,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.read<AppState>();
    final d = device;

    final cardBg = c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
    final cardBg2 =
        c.isDark ? const Color(0xFF222222) : const Color(0xFFFFFFFF);
    final cardBorder = c.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF222222).withValues(alpha: 0.25);
    final iconColor = c.isDark ? Colors.white : c.blue;
    final nameColor = c.isDark ? Colors.white : const Color(0xFF000000);
    final subColor =
        c.isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF333333);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardBg, cardBg2],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AppIcon(d.icon, size: 22, color: iconColor),
            const Spacer(),
            if (d.scheduleEnabled) ...[
              Image.asset('assets/Clock.png', width: 11, height: 11, color: c.blue),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  getTimerString(d.startHour, d.startMinute, d.endHour, d.endMinute, DateTime.now()),
                  style: AppText.semi(11, c.blue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
            AppToggle(
                value: d.active, onChanged: (_) => state.toggleDevicePower(d.id)),
          ]),
          const Spacer(),
          Text(d.name,
              style: AppText.semi(15, nameColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onEdit,
            child: Row(
              children: [
                Flexible(
                  child: Text(d.zone,
                        style: AppText.body(12, d.zone == 'Unknown Area' ? c.red : subColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_rounded, size: 11, color: c.blue.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(
                  d.active ? '· ${d.powerLabel}' : '· Off',
                  style: AppText.body(12, subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

class _CustomMenuIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _CustomMenuIcon({required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: size * 0.6, height: 2.2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5))),
            SizedBox(height: size * 0.18),
            Container(width: size * 1.0, height: 2.2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5))),
            SizedBox(height: size * 0.18),
            Container(width: size * 0.6, height: 2.2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5))),
          ],
        ),
      ),
    );
  }
}
