import 'package:flutter/material.dart';

import 'package:mogicians_manual/ui/mdi_icons.dart';

/// App-specific colors that no longer have a slot on [ThemeData]
/// (Flutter removed `toggleableActiveColor`).
@immutable
class MogicianColors extends ThemeExtension<MogicianColors> {
  const MogicianColors({
    required this.activeControl,
    required this.homeBackground,
  });

  /// Color of the play/pause icon of the music item that is currently active.
  final Color activeControl;

  /// Background of the home page behind the tab lists (formerly
  /// `ThemeData.backgroundColor`, which was grey[700] in the dark theme).
  final Color homeBackground;

  @override
  MogicianColors copyWith({Color? activeControl, Color? homeBackground}) =>
      MogicianColors(
        activeControl: activeControl ?? this.activeControl,
        homeBackground: homeBackground ?? this.homeBackground,
      );

  @override
  MogicianColors lerp(ThemeExtension<MogicianColors>? other, double t) {
    if (other is! MogicianColors) return this;
    return MogicianColors(
      activeControl: Color.lerp(activeControl, other.activeControl, t)!,
      homeBackground: Color.lerp(homeBackground, other.homeBackground, t)!,
    );
  }
}

extension MogicianThemeData on ThemeData {
  MogicianColors get mogicianColors =>
      extension<MogicianColors>() ??
      MogicianColors(
        activeControl: colorScheme.secondary,
        homeBackground: scaffoldBackgroundColor,
      );
}

mixin MyThemeDataProvider {
  ThemeData getLightThemeData() =>
      _lightThemeData(primarySwatch: Colors.blue, accentColor: Colors.yellow);

  ThemeData getFuneralThemeData() => _lightThemeData(
    primarySwatch: Colors.blueGrey,
    accentColor: Colors.black,
  );

  ThemeData getDarkThemeData() {
    final defaultDarkTheme = ThemeData.dark(useMaterial3: false);
    final defaultDarkColorScheme = defaultDarkTheme.colorScheme;
    return defaultDarkTheme.copyWith(
      colorScheme: defaultDarkColorScheme.copyWith(
        onSurface: Colors.grey.shade100,
        onSurfaceVariant: Colors.grey.shade400,
      ),
      // Thin separators on top of every tile.
      dividerColor: Colors.grey.shade800,
      unselectedWidgetColor: Colors.grey.shade500,
      extensions: <ThemeExtension<dynamic>>[
        MogicianColors(
          activeControl: Colors.grey.shade300,
          homeBackground: Colors.grey.shade700,
        ),
      ],
    );
  }

  ThemeData _lightThemeData({
    required MaterialColor primarySwatch,
    required Color accentColor,
  }) {
    final colorScheme =
        ColorScheme.fromSwatch(
          primarySwatch: primarySwatch,
          accentColor: accentColor,
        ).copyWith(
          onSurface: Colors.grey.shade900,
          onSurfaceVariant: Colors.grey.shade600,
        );

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: false,
    ).copyWith(
      canvasColor: Colors.grey.shade200,
      scaffoldBackgroundColor: Colors.grey.shade200,
      // Thin separators on top of every tile.
      dividerColor: Colors.grey.shade300,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
      ),
      extensions: <ThemeExtension<dynamic>>[
        MogicianColors(
          activeControl: Colors.grey.shade700,
          homeBackground: Colors.grey.shade200,
        ),
      ],
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
    }
  }
}
