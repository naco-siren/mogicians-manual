import 'package:flutter/widgets.dart';

/// The handful of Material Design Icons (https://pictogrammers.com/library/mdi/)
/// this app uses, served from the subset font in `assets/fonts/`.
///
/// Keeping these `const` lets Flutter's icon tree-shaking strip unused glyphs
/// from release builds.
abstract final class MdiIcons {
  static const String _family = 'MaterialDesignIcons';

  static const IconData brightnessAuto = IconData(0xf00e1, fontFamily: _family);
  static const IconData brightness5 = IconData(0xf00de, fontFamily: _family);
  static const IconData brightness3 = IconData(0xf00dc, fontFamily: _family);
  static const IconData brightness4 = IconData(0xf00dd, fontFamily: _family);
  static const IconData candle = IconData(0xf05e2, fontFamily: _family);
  static const IconData glasses = IconData(0xf02aa, fontFamily: _family);
  static const IconData github = IconData(0xf02a4, fontFamily: _family);
  static const IconData guyFawkesMask = IconData(0xf0825, fontFamily: _family);
}
