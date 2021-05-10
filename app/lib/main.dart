import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/ui/home.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/service/brightness_controller.dart';

void main() => runApp(MyApp());

const String title = '膜法指南';

class MyApp extends StatefulWidget {
  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AudioPlayer audioPlayer = AudioPlayer();
  BrightnessMode _brightnessMode = BrightnessMode.AUTO;

  @override
  Widget build(BuildContext context) {
    // final Brightness brightnessValue = MediaQuery.of(context).platformBrightness;
    // bool isDark = brightnessValue == Brightness.dark;

    return MaterialApp(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue
        ),
        home: MusicPlayer(
          child: HomePage(
            title: title,
            brightnessMode: _brightnessMode,
            onBrightnessModeChanged: _switchMode,
          ),
          audioPlayer: audioPlayer,
        )
    );
  }

  _switchMode() {
    setState(() {
      switch(_brightnessMode) {
        case BrightnessMode.AUTO:
          _brightnessMode = BrightnessMode.BRIGHT;
          break;
        case BrightnessMode.BRIGHT:
          _brightnessMode = BrightnessMode.DARK;
          break;
        case BrightnessMode.DARK:
          _brightnessMode = BrightnessMode.AUTO;
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
