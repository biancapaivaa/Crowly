import 'package:flutter/material.dart';

abstract final class C {
  static const background = Color(0xFF1A0033);
  static const surface = Color(0xFF230A3B);
  static const raised = Color(0xFF2C1443);
  static const nav = Color(0xFF402B54);
  static const pink = Color(0xFFFF4DB8);
  static const violet = Color(0xFF9747FF);
  static const muted = Color(0xFFB4A2C6);
  static const green = Color(0xFF22D68B);
  static const yellow = Color(0xFFECC927);
  static const red = Color(0xFFFF575F);
  static const blue = Color(0xFF698BFF);
}

ThemeData crowlyTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'CrowlySans',
  );
  return base.copyWith(
    scaffoldBackgroundColor: C.background,
    primaryTextTheme: base.primaryTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    chipTheme: base.chipTheme.copyWith(labelStyle: const TextStyle(color: Colors.white), secondaryLabelStyle: const TextStyle(color: Colors.white)),
    tooltipTheme: const TooltipThemeData(decoration: BoxDecoration(color: C.raised), textStyle: TextStyle(color: Colors.white)),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white, selectionColor: C.violet, selectionHandleColor: Colors.white),
    colorScheme: const ColorScheme.dark(
      primary: C.pink,
      secondary: C.violet,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white,
      onError: Colors.white,
      surface: C.surface,
      error: C.red,
    ),
    textTheme: base.textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white)
        .copyWith(
          bodyMedium: const TextStyle(
            fontFamily: 'CrowlySans',
            fontSize: 13,
            color: Colors.white,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'CrowlySans',
            fontSize: 11,
            color: Colors.white,
          ),
          titleMedium: const TextStyle(color: Colors.white, 
            fontFamily: 'CrowlySans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(color: Colors.white, 
            fontFamily: 'CrowlySans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.raised,
      labelStyle: const TextStyle(color: Colors.white),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      errorStyle: const TextStyle(color: Colors.white),
      helperStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF48205F)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF48205F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.violet),
      ),
      prefixIconColor: C.muted,
      suffixIconColor: C.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.pink,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(color: Colors.white, 
          fontFamily: 'CrowlySans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 42),
        side: const BorderSide(color: C.violet),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(color: Colors.white, 
          fontFamily: 'CrowlySans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        textStyle: const TextStyle(color: Colors.white, fontFamily: 'CrowlySans', fontSize: 12),
      ),
    ),
    dividerColor: C.raised,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.raised,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
