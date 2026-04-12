// lib/widgets/common_widgets.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

// ─── THEME HELPER ─────────────────────────────────────────────────────────────
AppColors colorsOf(BuildContext ctx) {
  final isDark = ctx.watch<AppState>().isDark;
  return isDark ? AppColors.dark : AppColors.light;
}

// ─── APP LOGO — Plug + Boxed Wordmark ─────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final bool small;
  final bool showTagline;
  final double scale;
  const AppLogo({super.key, this.small = false, this.showTagline = true, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final logoAsset =
        c.isDark ? 'assets/FLAMEGUARD_WHT.png' : 'assets/FLAMEGUARD_BLK.png';
    final logoSize =
        (small ? (c.isDark ? 60.0 : 32.0) : (c.isDark ? 74.0 : 44.0)) * scale;
    final gap = c.isDark ? 0.0 : 6.0;
    final xOffset = c.isDark ? (small ? -6.0 : -8.0) : 0.0; // Reduced from -10

    final headerHeight = (small ? 24.0 : 34.0) * scale;
    final topOffset = (logoSize - headerHeight) / 2;

    if (small) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(logoAsset,
              width: logoSize, height: logoSize, fit: BoxFit.contain),
          SizedBox(width: gap),
          Transform.translate(
            offset: Offset(xOffset, topOffset),
            child: SizedBox(
              height: headerHeight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: c.t1, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text('FLAMEGUARD',
                    style: AppText.semi(11 * scale, c.t1).copyWith(letterSpacing: 1.3 * scale)),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(logoAsset,
            width: logoSize, height: logoSize, fit: BoxFit.contain),
        SizedBox(width: gap),
        Transform.translate(
          offset: Offset(xOffset, topOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: headerHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: c.t1, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('FLAMEGUARD',
                      style: AppText.h(16 * scale, c.t1).copyWith(letterSpacing: 1.6 * scale)), // Reduced from 18
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 1),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text('SMART FIRE PROTECTION',
                      style: AppText.lbl(c.t3).copyWith(letterSpacing: 1.4 * scale, fontSize: 10 * scale)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── TOGGLE ────────────────────────────────────────────────────────────────────
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final accent = activeColor ?? c.blue;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? accent : c.raised,
          border: Border.all(color: value ? accent : c.borderMid),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── TAG / BADGE ───────────────────────────────────────────────────────────────
class AppTag extends StatelessWidget {
  final String text;
  final Color color;
  const AppTag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text.toUpperCase(),
          style: AppText.lbl(color).copyWith(letterSpacing: 0.5)),
    );
  }
}

// ─── STATUS DOT ────────────────────────────────────────────────────────────────
class StatusDot extends StatelessWidget {
  final bool on;
  const StatusDot({super.key, required this.on});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? c.green : c.t3,
      ),
    );
  }
}

// ─── SECTION GROUP ────────────────────────────────────────────────────────────
class AppGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const AppGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title!, style: AppText.lbl(c.t3)),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── LIST ROW ─────────────────────────────────────────────────────────────────
class AppListRow extends StatelessWidget {
  final String? icon;
  final Color? iconColor;
  final String label;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divider;

  const AppListRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.label,
    this.sub,
    this.trailing,
    this.onTap,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final iCol = iconColor ?? c.t2;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: (iconColor != null && iconColor != c.t2)
                          ? iCol.withAlpha(20)
                          : c.raised,
                    ),
                    child: Center(child: AppIcon(icon!, size: 15, color: iCol)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.med(14, c.t1)),
                      if (sub != null) ...[
                        const SizedBox(height: 2),
                        Text(sub!, style: AppText.body(11, c.t3)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  AppIcon('right', size: 14, color: c.t3),
              ],
            ),
          ),
          if (divider)
            Divider(
                height: 1,
                thickness: 1,
                indent: icon != null ? 58 : 16,
                color: c.border),
        ],
      ),
    );
  }
}

// ─── PRIMARY BUTTON ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: loading ? c.raised : c.blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.t2))
            : Text(label, style: AppText.semi(14, Colors.white)),
      ),
    );
  }
}

// ─── GHOST BUTTON ─────────────────────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GhostButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(color: c.borderMid),
          ),
        ),
        child: Text(label, style: AppText.med(14, c.t2)),
      ),
    );
  }
}

// ─── INPUT FIELD ──────────────────────────────────────────────────────────────
class AppInput extends StatefulWidget {
  final String fieldLabel;
  final String placeholder;
  final TextInputType keyboardType;
  final bool obscure;
  final TextEditingController controller;
  final bool showPasswordToggle;

  const AppInput({
    super.key,
    required this.fieldLabel,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.showPasswordToggle = false,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.fieldLabel.toUpperCase(), style: AppText.lbl(c.t3)),
        const SizedBox(height: 6),
        Focus(
          child: TextField(
            controller: widget.controller,
            obscureText:
                widget.showPasswordToggle ? _obscureText : widget.obscure,
            keyboardType: widget.keyboardType,
            style: AppText.body(13, c.t1),
            cursorColor: c.blue,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppText.body(13, c.t3),
              filled: true,
              fillColor: c.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: c.blue, width: 1.5),
              ),
              suffixIcon: widget.showPasswordToggle
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: c.t3,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final items = [
      ('assets/home.png', 'Home'),
      ('assets/devices.png', 'Devices'),
      ('assets/analytics.png', 'Analytics'),
      ('assets/Notification.png', 'Alerts'),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        color: c.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const AutomaticNotchedShape(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
          StadiumBorder(),
        ),
        notchMargin: 6,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildItem(context, 0, items[0], c, state),
                  _buildItem(context, 1, items[1], c, state),
                ],
              ),
            ),
            const SizedBox(width: 70), // Wider gap for the FAB and notch
            Expanded(
              child: Row(
                children: [
                  _buildItem(context, 2, items[2], c, state),
                  _buildItem(context, 3, items[3], c, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int i, (String, String) item, AppColors c, AppState state) {
    final on = i == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(item.$1,
                    width: on ? 22 : 20,
                    height: on ? 22 : 20,
                    color: on ? c.blue : c.t2),
                if (i == 3 && state.activeAlertCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '${state.activeAlertCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.$2,
                style: AppText.lbl(on ? c.blue : c.t2)
                    .copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ─── FIRE RISK GAUGE ──────────────────────────────────────────────────────────
class FireRiskGauge extends StatelessWidget {
  final int score;
  final String risk;
  const FireRiskGauge({super.key, required this.score, required this.risk});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                AppIcon('flame',
                    size: 13, color: c.isDark ? Colors.white60 : c.t3),
                const SizedBox(width: 6),
                Text(
                  'FIRE RISK ASSESSMENT',
                  style: AppText.lbl(c.isDark ? Colors.white60 : c.t3),
                ),
              ]),
              Row(children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: c.riskColor(risk))),
                const SizedBox(width: 6),
                Text(risk, style: AppText.semi(11, c.riskColor(risk))),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          // Gauge painter
          SizedBox(
            width: 240,
            height: 140,
            child: CustomPaint(
              painter: _GaugePainter(score: score, risk: risk, colors: c),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final String risk;
  final AppColors colors;
  _GaugePainter(
      {required this.score, required this.risk, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height - 12.0;
    final R = size.width * 0.44;
    const strokeW = 10.0;
    const startAngle = -200 * math.pi / 180;
    const sweepAngle = 220 * math.pi / 180;
    const gapDeg = 3 * math.pi / 180;

    final trackPaint = Paint()
      ..color = colors.raised
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: R),
        startAngle, sweepAngle, false, trackPaint);

    final segs = [
      (0, 39, colors.green),
      (40, 69, colors.amber),
      (70, 100, colors.red),
    ];

    for (final seg in segs) {
      final from = seg.$1, to = seg.$2, col = seg.$3;
      final aStart =
          startAngle + (from / 100) * sweepAngle + (from == 0 ? 0 : gapDeg / 2);
      final aEnd =
          startAngle + (to / 100) * sweepAngle - (to == 100 ? 0 : gapDeg / 2);
      final aSweep = aEnd - aStart;

      final activeIdx = score <= 39
          ? 0
          : score <= 69
              ? 1
              : 2;
      final segIdx = segs.indexOf(seg);
      final opacity = segIdx == activeIdx
          ? 0.9
          : segIdx < activeIdx
              ? 0.35
              : 0.12;

      final segPaint = Paint()
        ..color = col.withAlpha((opacity * 255).round())
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: R), aStart,
          aSweep, false, segPaint);
    }

    // Needle
    final needleAngle = startAngle + (score / 100) * sweepAngle;
    final nLen = R - strokeW / 2 - 6;
    final nx = cx + nLen * math.cos(needleAngle);
    final ny = cy + nLen * math.sin(needleAngle);
    final baseR = R * 0.22;
    final perpX = math.cos(needleAngle + math.pi / 2) * 4;
    final perpY = math.sin(needleAngle + math.pi / 2) * 4;
    final bx = cx + baseR * math.cos(needleAngle);
    final by = cy + baseR * math.sin(needleAngle);

    final needlePaint = Paint()
      ..color = colors.t1.withAlpha(178)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(nx, ny)
      ..lineTo(bx + perpX, by + perpY)
      ..lineTo(bx - perpX, by - perpY)
      ..close();
    canvas.drawPath(path, needlePaint);

    // Center circle
    canvas.drawCircle(
        Offset(cx, cy),
        9,
        Paint()
          ..color = colors.raised
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(cx, cy),
        9,
        Paint()
          ..color = colors.borderMid
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(
        Offset(cx, cy),
        3.5,
        Paint()
          ..color = (risk == 'High'
              ? colors.red
              : risk == 'Medium'
                  ? colors.amber
                  : colors.green)
          ..style = PaintingStyle.fill);

    // Score text
    final scoreTp = TextPainter(
      text: TextSpan(text: '$score', style: AppText.h(32, colors.t1)),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas, Offset(cx - scoreTp.width / 2, cy + 16));
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.score != score || old.risk != risk;
}

// ─── APP ICON (maps string keys to Icons) ─────────────────────────────────────
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const AppIcon(this.name,
      {super.key, required this.size, required this.color});

  static const _map = {
    'fan': Icons.wind_power_outlined,
    'tv': Icons.tv_outlined,
    'kettle': Icons.local_cafe_outlined,
    'home': Icons.home_outlined,
    'grid': Icons.grid_view_outlined,
    'bell': Icons.notifications_none_outlined,
    'cog': Icons.settings_outlined,
    'back': Icons.chevron_left,
    'right': Icons.chevron_right,
    'zap': Icons.bolt_outlined,
    'rice': Icons.rice_bowl_outlined,
    'shield': Icons.shield_outlined,
    'flame': Icons.local_fire_department_outlined,
    'wifi': Icons.wifi_outlined,
    'bt': Icons.bluetooth_outlined,
    'user': Icons.person_outline,
    'refresh': Icons.refresh_outlined,
    'plus': Icons.add,
    'warn': Icons.warning_amber_outlined,
    'phone': Icons.smartphone_outlined,
    'share': Icons.share_outlined,
    'userplus': Icons.person_add_alt_1_outlined,
    'bars': Icons.bar_chart_outlined,
    'x': Icons.close,
    'lock': Icons.lock_outline,
    'mail': Icons.mail_outline,
    'check': Icons.check,
    'eye': Icons.visibility_outlined,
    'logout': Icons.logout_outlined,
    'moon': Icons.dark_mode_outlined,
    'sun': Icons.light_mode_outlined,
    'router': Icons.router_outlined,
    'ref': Icons.kitchen_outlined,
    'fridge': Icons.kitchen_outlined,
    'ac': Icons.ac_unit_outlined,
    'aircon': Icons.ac_unit_outlined,
    'wash': Icons.local_laundry_service_outlined,
    'laundry': Icons.local_laundry_service_outlined,
    'micro': Icons.microwave_outlined,
    'oven': Icons.microwave_outlined,
    'heater': Icons.hot_tub_outlined,
    'water': Icons.hot_tub_outlined,
    'blender': Icons.blender_outlined,
    'iron': Icons.iron_outlined,
    'plansa': Icons.iron_outlined,
    'menu': Icons.menu,
  };

  @override
  Widget build(BuildContext context) {
    final key = name.toLowerCase();

    // 1. Exact match in map
    if (key == 'others') {
      return Image.asset('assets/Others.png', width: size, height: size, color: color);
    }
    if (_map.containsKey(key)) {
      return Icon(_map[key]!, size: size, color: color);
    }

    // 2. Smart keyword matching (e.g. "Rice Cooker" -> rice bowl icon)
    String? foundKey;
    for (final k in _map.keys) {
      if (k.length > 2 && key.contains(k)) {
        foundKey = k;
        break;
      }
    }
    if (foundKey != null) {
      return Icon(_map[foundKey]!, size: size, color: color);
    }

    // 3. Premium asset fallback for everything else
    return Image.asset('assets/Others.png', width: size, height: size, color: color);
  }
}

// ─── ERROR BANNER ─────────────────────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.redFade,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.red.withAlpha(34)),
      ),
      child: Text(message, style: AppText.body(12, c.red)),
    );
  }
}

// ─── SUCCESS BANNER ───────────────────────────────────────────────────────────
class SuccessBanner extends StatelessWidget {
  final String message;
  const SuccessBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.greenFade,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.green.withAlpha(34)),
      ),
      child: Row(children: [
        AppIcon('check', size: 13, color: c.green),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: AppText.body(12, c.green))),
      ]),
    );
  }
}
