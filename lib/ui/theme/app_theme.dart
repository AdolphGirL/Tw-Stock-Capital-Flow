import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const bg = Color(0xFFF4F7FB);

  static const card = Colors.white;

  static const primary = Color(0xFF2563EB);

  static const text = Color(0xFF111827);

  static const subText = Color(0xFF6B7280);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.light,

    scaffoldBackgroundColor: bg,

    primaryColor: primary,

    textTheme: GoogleFonts.notoSansTextTheme(),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: bg,
      foregroundColor: text,
    ),

    cardTheme: CardThemeData(
      color: card,

      elevation: 0,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),

      margin: EdgeInsets.zero,
    ),
  );
}
