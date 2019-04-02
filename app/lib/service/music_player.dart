import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

class MusicPlayer extends InheritedWidget {
  final AudioPlayer audioPlayer;

  MusicPlayer({@required this.audioPlayer, @required Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static MusicPlayer of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(MusicPlayer);
}
