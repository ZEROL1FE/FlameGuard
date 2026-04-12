import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── DARK TOKENS ─────────────────────────────────────────────────────────────
class DarkColors {
  static const bg        = Color(0xFF0F0F0F);
  static const surface   = Color(0xFF1A1A1A);
  static const raised    = Color(0xFF222222);
  static const border    = Color(0xFF2A2A2A);
  static const borderMid = Color(0xFF333333);
  static const blue      = Color(0xFF4F8EF7);
  static const blueFade  = Color(0x194F8EF7);
  static const red       = Color(0xFFE5534B);
  static const redFade   = Color(0x14E5534B);
  static const amber     = Color(0xFFC89B10);
  static const amberFade = Color(0x14C89B10);
  static const green     = Color(0xFF3FB950);
  static const greenFade = Color(0x143FB950);
  static const t1        = Color(0xFFF0F0F0);
  static const t2        = Color(0xFF888888);
  static const t3        = Color(0xFF444444);
}

// ─── LIGHT TOKENS ────────────────────────────────────────────────────────────
class LightColors {
  static const bg        = Color(0xFFFFFFFF); // pure white bg
  static const surface   = Color(0xFFF5F5F5); // light gray cards
  static const raised    = Color(0xFFEAEAEA); // raised elements
  static const border    = Color(0xFFDDDDDD); // subtle borders
  static const borderMid = Color(0xFFBBBBBB); // mid border
  static const blue      = Color(0xFF1877F2);
  static const blueFade  = Color(0x1A1877F2);
  static const red       = Color(0xFFD93025);
  static const redFade   = Color(0x14D93025);
  static const amber     = Color(0xFF8A5C00);
  static const amberFade = Color(0x148A5C00);
  static const green     = Color(0xFF1A7F37);
  static const greenFade = Color(0x141A7F37);
  static const t1        = Color(0xFF000000); // pure black
  static const t2        = Color(0xFF1A1A1A); // near-black
  static const t3        = Color(0xFF333333); // dark gray — readable labels
}

// ─── DYNAMIC COLOR SCHEME ────────────────────────────────────────────────────
class AppColors {
  final Color bg, surface, raised, border, borderMid;
  final Color blue, blueFade, red, redFade, amber, amberFade, green, greenFade;
  final Color t1, t2, t3;
  final bool isDark;

  const AppColors._({
    required this.isDark,
    required this.bg, required this.surface, required this.raised,
    required this.border, required this.borderMid,
    required this.blue, required this.blueFade,
    required this.red, required this.redFade,
    required this.amber, required this.amberFade,
    required this.green, required this.greenFade,
    required this.t1, required this.t2, required this.t3,
  });

  static const dark = AppColors._(
    isDark: true,
    bg: DarkColors.bg, surface: DarkColors.surface, raised: DarkColors.raised,
    border: DarkColors.border, borderMid: DarkColors.borderMid,
    blue: DarkColors.blue, blueFade: DarkColors.blueFade,
    red: DarkColors.red, redFade: DarkColors.redFade,
    amber: DarkColors.amber, amberFade: DarkColors.amberFade,
    green: DarkColors.green, greenFade: DarkColors.greenFade,
    t1: DarkColors.t1, t2: DarkColors.t2, t3: DarkColors.t3,
  );

  static const light = AppColors._(
    isDark: false,
    bg: LightColors.bg, surface: LightColors.surface, raised: LightColors.raised,
    border: LightColors.border, borderMid: LightColors.borderMid,
    blue: LightColors.blue, blueFade: LightColors.blueFade,
    red: LightColors.red, redFade: LightColors.redFade,
    amber: LightColors.amber, amberFade: LightColors.amberFade,
    green: LightColors.green, greenFade: LightColors.greenFade,
    t1: LightColors.t1, t2: LightColors.t2, t3: LightColors.t3,
  );

  Color riskColor(String risk) {
    if (risk == 'High')   return red;
    if (risk == 'Medium') return amber;
    return green;
  }
  Color riskFade(String risk) {
    if (risk == 'High')   return redFade;
    if (risk == 'Medium') return amberFade;
    return greenFade;
  }
}

// ─── TEXT STYLES ─────────────────────────────────────────────────────────────
class AppText {
  static TextStyle h(double sz, Color c) =>
      GoogleFonts.dmSans(fontSize: sz, fontWeight: FontWeight.w700, color: c);
  static TextStyle semi(double sz, Color c) =>
      GoogleFonts.dmSans(fontSize: sz, fontWeight: FontWeight.w600, color: c);
  static TextStyle med(double sz, Color c) =>
      GoogleFonts.dmSans(fontSize: sz, fontWeight: FontWeight.w500, color: c);
  static TextStyle body(double sz, Color c) =>
      GoogleFonts.dmSans(fontSize: sz, fontWeight: FontWeight.w400, color: c);
  static TextStyle lbl(Color c) =>
      GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600,
          color: c, letterSpacing: 0.8);
}

// ─── THEME BUILDER ────────────────────────────────────────────────────────────
ThemeData buildTheme(AppColors c) => ThemeData(
  useMaterial3: true,
  brightness: c.isDark ? Brightness.dark : Brightness.light,
  scaffoldBackgroundColor: c.bg,
  colorScheme: ColorScheme(
    brightness: c.isDark ? Brightness.dark : Brightness.light,
    primary: c.blue, onPrimary: Colors.white,
    secondary: c.amber, onSecondary: Colors.white,
    error: c.red, onError: Colors.white,
    surface: c.surface, onSurface: c.t1,
  ),
  textTheme: GoogleFonts.dmSansTextTheme().apply(bodyColor: c.t1, displayColor: c.t1),
  appBarTheme: AppBarTheme(
    backgroundColor: c.bg, surfaceTintColor: Colors.transparent, elevation: 0,
    iconTheme: IconThemeData(color: c.t2),
    titleTextStyle: AppText.semi(17, c.t1),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: c.surface,
    selectedItemColor: c.blue,
    unselectedItemColor: c.t3,
    showUnselectedLabels: true,
    selectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
    unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
    elevation: 0,
  ),
  toggleButtonsTheme: ToggleButtonsThemeData(
    borderWidth: 1,
    borderColor: c.borderMid,
    selectedBorderColor: c.borderMid,
    borderRadius: BorderRadius.circular(8),
  ),
  timePickerTheme: TimePickerThemeData(
    dayPeriodColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? c.blue : (c.isDark ? Colors.white12 : const Color(0xFFEEEEEE))),
    dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? Colors.white : c.t3),
    dayPeriodBorderSide: BorderSide.none,
    dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.borderMid, width: 1)),
    hourMinuteTextStyle: GoogleFonts.dmSans(fontSize: 44, fontWeight: FontWeight.w600),
    hourMinuteColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? c.blue.withValues(alpha: 0.12) : (c.isDark ? Colors.white12 : const Color(0xFFEEEEEE))),
    hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected) ? c.blue : c.t1),
    dialHandColor: c.blue,
  ),
  dividerColor: c.border,
);