import 'package:flutter/material.dart';

ThemeData buildPortalTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff076b66),
    surface: const Color(0xfff7f9f7),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
