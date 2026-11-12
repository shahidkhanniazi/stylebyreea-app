import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SBR {
  static const ink = Color(0xFF111111);
  static const ink2 = Color(0xFF2A2A2A);
  static const muted = Color(0xFF77736B);
  static const line = Color(0xFFE8E3D9);
  static const ivory = Color(0xFFFAF7F2);
  static const cream = Color(0xFFF3EDE2);
  static const gold = Color(0xFFB8913A);
  static const gold2 = Color(0xFFE2C77F);
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFA67C2E), Color(0xFFE9D18F), Color(0xFFB8913A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static TextStyle serif(double size, {FontWeight w = FontWeight.w500, Color c = ink, double? height, FontStyle? style}) =>
      GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: w, color: c, height: height ?? 1.15, fontStyle: style);

  static TextStyle eyebrow({Color c = gold}) =>
      GoogleFonts.jost(fontSize: 11, letterSpacing: 3.2, fontWeight: FontWeight.w500, color: c);

  static ThemeData theme() {
    final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, primary: ink, secondary: gold, surface: Colors.white));
    final text = GoogleFonts.jostTextTheme(base.textTheme).apply(bodyColor: ink, displayColor: ink);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: ink, foregroundColor: const Color(0xFFF3EDE2), elevation: 0, centerTitle: true,
        titleTextStyle: serif(22, c: const Color(0xFFF3EDE2)),
      ),
      dividerColor: line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: line)),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: line)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: ink)),
        labelStyle: GoogleFonts.jost(color: muted, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink, behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.jost(color: Colors.white, fontSize: 14),
        actionTextColor: gold2,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
