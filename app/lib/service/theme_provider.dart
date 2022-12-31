import 'package:flutter/material.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MyThemeDataProvider {

  ThemeData getLightThemeData() {
    return ThemeData.from(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        accentColor: Colors.yellow,
        backgroundColor: Colors.grey.shade200,
      ).copyWith(
        onSurface: Colors.grey.shade900,
        onBackground: Colors.grey.shade600,
      ),
    ).copyWith(
      dialogBackgroundColor: Colors.grey.shade300,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white
      ),
      hoverColor: Colors.grey.shade700.withOpacity(0.9),
      toggleableActiveColor: Colors.grey.shade700,
    );
  }

  ThemeData getDarkThemeData() {
    final defaultDarkTheme = ThemeData.dark();
    final defaultDarkColorScheme = defaultDarkTheme.colorScheme;
    return defaultDarkTheme.copyWith(
        colorScheme: defaultDarkColorScheme.copyWith(
          onSurface: Colors.grey.shade100,
          onBackground: Colors.grey.shade400,
        ),
        unselectedWidgetColor: Colors.grey.shade500,
        toggleableActiveColor: Colors.grey.shade300
    );
  }

  static IconData getBrightnessIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return MdiIcons.brightnessAuto;
      case ThemeMode.light:
        return MdiIcons.brightness5;
      case ThemeMode.dark:
        return MdiIcons.brightness3;
      default:
        return MdiIcons.brightness4;
    }
  }
}