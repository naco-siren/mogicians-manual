import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  void showToast(BuildContext context, String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Theme.of(context).hoverColor,
        textColor: Theme.of(context).backgroundColor,
        fontSize: 14.0);
  }
}