import 'package:flutter/material.dart';

import 'package:mogicians_manual/ui/home.dart';

void main() => runApp(MyApp());

const String title = '膜法指南';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: title),
    );
  }
}


bool isTabletLayout(BuildContext context) =>
    MediaQuery.of(context).size.shortestSide >= 600;

