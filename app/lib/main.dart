import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/ui/home.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/service/theme_provider.dart';

void main() => runApp(MyApp());

const String title = '膜法指南';

class MyApp extends StatefulWidget {
  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with MyThemeDataProvider {
  AudioPlayer audioPlayer = AudioPlayer();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: title,
        themeMode: _themeMode,
        theme: getLightThemeData(),
        darkTheme: getDarkThemeData(),
        home: MusicPlayer(
          child: HomePage(
            title: title,
            themeMode: _themeMode,
            onThemeModeChanged: _switchMode,
          ),
          audioPlayer: audioPlayer,
        )
    );
  }

  _switchMode() {
    setState(() {
      switch(_themeMode) {
        case ThemeMode.system:
          _themeMode = ThemeMode.light;
          break;
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
  }
}

bool isTabletLayout(BuildContext context) =>
    MediaQuery.of(context).size.shortestSide >= 600;
