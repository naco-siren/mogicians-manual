import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

mixin ToastUtil {
  /// Shows a short toast. The colours are fixed rather than taken from the
  /// theme: since fluttertoast 10 honours them on Android 12L+, deriving them
  /// from the dark theme's hoverColor made the toast almost invisible.
  void showToast(BuildContext context, String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey.shade700.withValues(alpha: 0.9),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
