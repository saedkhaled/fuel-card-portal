import 'package:flutter/material.dart';

const portalNavy = Color(0xff003262);
const portalInk = Color(0xff071c33);
const portalGold = Color(0xffdba513);
const portalPaper = Color(0xfff3f6fa);
const portalLine = Color(0xffd6e0ea);
const portalMuted = Color(0xff52657b);

ThemeData buildPortalTheme({required Locale locale}) {
  final fontFamily = locale.languageCode == 'ar' ? 'Cairo' : 'Inter';
  final colors = ColorScheme.fromSeed(seedColor: portalNavy).copyWith(
    primary: portalNavy,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xffe6edf6),
    onPrimaryContainer: portalInk,
    secondary: const Color(0xff044064),
    secondaryContainer: const Color(0xffe6edf6),
    onSecondaryContainer: portalNavy,
    surface: Colors.white,
    onSurface: portalInk,
    onSurfaceVariant: portalMuted,
    surfaceContainerLow: portalPaper,
    surfaceContainerHighest: const Color(0xffe6edf6),
    outline: portalMuted,
    outlineVariant: portalLine,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    fontFamily: fontFamily,
  );
  final text = base.textTheme;
  const corners = BorderRadius.all(Radius.circular(12));
  const fieldBorder = OutlineInputBorder(
    borderRadius: corners,
    borderSide: BorderSide(color: portalLine),
  );
  return base.copyWith(
    scaffoldBackgroundColor: portalPaper,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium!.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: text.headlineSmall!.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: portalNavy,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontFamily: fontFamily,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? portalNavy
              : portalMuted,
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: portalLine),
      ),
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: corners,
        borderSide: BorderSide(color: portalNavy, width: 2),
      ),
      prefixIconColor: portalNavy,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xffe6edf6),
      side: const BorderSide(color: portalLine),
      shape: const StadiumBorder(),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: portalNavy,
      contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(borderRadius: corners),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: portalLine),
        shape: const RoundedRectangleBorder(borderRadius: corners),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: portalLine),
  );
}
