import 'package:flutter/material.dart';

/// Visual language from the Grade 5 word-block pages:
/// prefix orange / root blue / suffix green on soft paper blue.
class ChenningColors {
  static const bg = Color(0xFFEEF4FF);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17213B);
  static const muted = Color(0xFF56637F);
  static const line = Color(0xFFD3DDF2);
  static const prefix = Color(0xFFC9560A);
  static const root = Color(0xFF2B62D9);
  static const suffix = Color(0xFF1F8A57);
  static const prefixTint = Color(0xFFFFEBD9);
  static const rootTint = Color(0xFFDEE9FF);
  static const suffixTint = Color(0xFFDAF3E6);
  static const highlight = Color(0xFFFFE27A);
  static const bad = Color(0xFFFDE3E3);
  static const good = Color(0xFFDDF5E8);
}

class ChenningTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ChenningColors.bg,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: ChenningColors.root,
        primary: ChenningColors.root,
        secondary: ChenningColors.prefix,
        tertiary: ChenningColors.suffix,
        surface: ChenningColors.paper,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ChenningColors.ink,
        displayColor: ChenningColors.ink,
        fontFamily: 'Nunito',
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ChenningColors.bg,
        foregroundColor: ChenningColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: ChenningColors.ink,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: ChenningColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ChenningColors.line, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ChenningColors.root,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChenningColors.ink,
          side: const BorderSide(color: ChenningColors.line, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
