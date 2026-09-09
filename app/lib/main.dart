import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/ui/home.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/service/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await AudioService.init(
    builder: () => MogicianAudioHandler(AudioPlayer()),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nacosiren.blog.mogiciansmanual.audio',
      androidNotificationChannelName: '音乐播放',
      androidNotificationIcon: 'drawable/ic_stat_music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  // audio_session owns audio focus (see MogicianAudioHandler.attachSession).
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  audioHandler.attachSession(session);
  runApp(MyApp(audioHandler: audioHandler));
}

const String title = '膜法指南';
const int _monthDeceased = 11;

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.audioHandler});

  final MogicianAudioHandler audioHandler;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with MyThemeDataProvider {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final isNovember = DateTime.now().month == _monthDeceased;

    return MaterialApp(
      title: title,
      themeMode: _themeMode,
      theme: isNovember ? getFuneralThemeData() : getLightThemeData(),
      darkTheme: isNovember ? getFuneralThemeData() : getDarkThemeData(),
      home: MusicPlayer(
        handler: widget.audioHandler,
        child: HomePage(
          title: title,
          isNovember: isNovember,
          themeMode: _themeMode,
          onThemeModeChanged: _switchMode,
        ),
      ),
    );
  }

  void _switchMode() {
    setState(() {
      switch (_themeMode) {
        case ThemeMode.system:
          _themeMode = ThemeMode.light;
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
        case ThemeMode.dark:
          _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  void dispose() {
    widget.audioHandler.dispose();
    super.dispose();
  }
}

bool isTabletLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;
