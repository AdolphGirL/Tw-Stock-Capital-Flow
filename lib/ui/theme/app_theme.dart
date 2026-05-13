import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111315),
    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),

    // Change CardTheme to CardThemeData here:
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1D21),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111315),
      elevation: 0,
      centerTitle: false,
    ),
  );
}
