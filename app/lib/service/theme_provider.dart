import 'package:flutter/material.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MyThemeDataProvider {

  ThemeData getLightThemeData() {
    // return ThemeData.light();
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      backgroundColor: Colors.grey.shade200,
      accentColorBrightness: Brightness.light,
      dialogBackgroundColor: Colors.grey.shade300,
      colorScheme: ColorScheme.light().copyWith(
        primary: Colors.grey.shade900,
        secondary: Colors.grey.shade600,
      ),
      buttonColor: Colors.grey.shade400,
      toggleableActiveColor: Colors.grey.shade700,
      hoverColor: Colors.grey.shade700.withOpacity(0.9),
    );
  }

  ThemeData getDarkThemeData() {
    // return ThemeData.dark();
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      accentColorBrightness: Brightness.dark,
      dialogBackgroundColor: Colors.grey.shade700,
      colorScheme: ColorScheme.dark().copyWith(
        primary: Colors.grey.shade400,
        secondary: Colors.grey.shade500,
      ),
      buttonColor: Colors.grey.shade500,
      toggleableActiveColor: Colors.grey.shade300,
      hoverColor: Colors.grey.shade300.withOpacity(0.9),
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