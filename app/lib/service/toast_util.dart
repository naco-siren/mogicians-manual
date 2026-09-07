import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

mixin ToastUtil {
  void showToast(BuildContext context, String msg) {
    final theme = Theme.of(context);
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: theme.hoverColor,
      textColor: theme.scaffoldBackgroundColor,
      fontSize: 14.0,
    );
  }
}
