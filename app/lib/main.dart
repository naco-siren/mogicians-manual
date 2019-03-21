import 'package:flutter/material.dart';

import 'ui/home.dart';

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


