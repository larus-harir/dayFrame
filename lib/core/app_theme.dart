import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SystemUiOverlayStyle systemBars(Brightness brightness) => SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  statusBarIconBrightness: brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark,
  systemNavigationBarIconBrightness: brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark,
  statusBarBrightness: brightness,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarContrastEnforced: false,
);

ThemeData plannerTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF58796C),
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: systemBars(scheme.brightness),
    ),
  );
}

Widget systemBarRegion(BuildContext context, Widget? child) =>
    AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBars(Theme.of(context).brightness),
      child: child ?? const SizedBox.shrink(),
    );
