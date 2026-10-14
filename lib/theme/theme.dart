import 'package:flutter/material.dart';
import 'tokens.dart';

const kFont = 'PlusJakartaSans';

class DText {
  static const title = TextStyle(
      fontFamily: kFont, fontSize: 28, fontWeight: FontWeight.w700,
      letterSpacing: -0.6, color: DColors.ink, height: 1.15);
  static const heading = TextStyle(
      fontFamily: kFont, fontSize: 18, fontWeight: FontWeight.w700,
      letterSpacing: -0.2, color: DColors.ink);
  static const body = TextStyle(
      fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w500,
      color: DColors.ink, height: 1.35);
  static const bodyStrong = TextStyle(
      fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600,
      color: DColors.ink, height: 1.35);
  static const caption = TextStyle(
      fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w500,
      color: DColors.textSecondary, height: 1.3);
  static const button = TextStyle(
      fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: DColors.accent,
    primary: DColors.accent,
    surface: DColors.card,
    error: DColors.urgent,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: kFont,
    colorScheme: scheme,
    scaffoldBackgroundColor: DColors.ground,
    dividerTheme: const DividerThemeData(
        color: DColors.border, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? DColors.accent : DColors.border),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    textTheme: const TextTheme(
      bodyMedium: DText.body,
      bodyLarge: DText.body,
      titleLarge: DText.title,
    ),
  );
}
