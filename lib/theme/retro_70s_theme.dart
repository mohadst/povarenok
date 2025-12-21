import 'package:flutter/material.dart';
import 'retro_colors.dart';

class Retro70sTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: RetroColors.cream,
      primaryColor: RetroColors.cherryRed,
      fontFamily: 'Georgia',
      appBarTheme: const AppBarTheme(
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RetroColors.mustard,
        linearTrackColor: Color(0xFFFFE0B2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RetroColors.mustard,
          foregroundColor: RetroColors.cocoa,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}