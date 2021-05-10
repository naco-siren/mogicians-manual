import 'package:flutter/material.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BrightnessController {
  static IconData getBrightnessIcon(BrightnessMode mode) {
    switch (mode) {
      case BrightnessMode.AUTO:
        return MdiIcons.brightnessAuto;
      case BrightnessMode.BRIGHT:
        return MdiIcons.brightness5;
      case BrightnessMode.DARK:
        return MdiIcons.brightness3;
      default:
        return MdiIcons.brightness4;
    }
  }
}

enum BrightnessMode {
  AUTO,
  BRIGHT,
  DARK
}