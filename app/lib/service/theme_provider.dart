import 'package:flutter/material.dart';

import 'package:mogicians_manual/ui/mdi_icons.dart';

/// App-specific colors that no longer have a slot on [ThemeData]
/// (Flutter removed `toggleableActiveColor`).
@immutable
class MogicianColors extends ThemeExtension<MogicianColors> {
  const MogicianColors({required this.activeControl});

  /// Color of the play/pause icon of the music item that is currently active.
  final Color activeControl;

  @override
  MogicianColors copyWith({Color? activeControl}) =>
      MogicianColors(activeControl: activeControl ?? this.activeControl);

  @override
  MogicianColors lerp(ThemeExtension<MogicianColors>? other, double t) {
    if (other is! MogicianColors) return this;
    return MogicianColors(
      activeControl: Color.lerp(activeControl, other.activeControl, t)!,
    );
  }
}

extension MogicianThemeData on ThemeData {
  MogicianColors get mogicianColors =>
      extension<MogicianColors>() ??
      MogicianColors(activeControl: colorScheme.secondary);
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
      // Historically the home Scaffold used ThemeData.backgroundColor, which
      // defaulted to grey[700] in a Material 2 dark theme.
      scaffoldBackgroundColor: Colors.grey.shade700,
      // Thin separators on top of every tile.
      dividerColor: Colors.grey.shade800,
      unselectedWidgetColor: Colors.grey.shade500,
      extensions: <ThemeExtension<dynamic>>[
        MogicianColors(activeControl: Colors.grey.shade300),
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
      hoverColor: Colors.grey.shade700.withValues(alpha: 0.9),
      extensions: <ThemeExtension<dynamic>>[
        MogicianColors(activeControl: Colors.grey.shade700),
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
