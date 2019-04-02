import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mogicians_manual/data/list_items.dart';

class MusicPlayer extends InheritedWidget {
  final AudioPlayer audioPlayer;

  MusicPlayer({@required this.audioPlayer, @required Widget child})
      : super(child: child);

  Future<int> resume({MusicItem item}) async {
    if (item != null) {
      final file =
          new File('${(await getTemporaryDirectory()).path}/${item.src}');
      await file.writeAsBytes(
          (await rootBundle.load(item.path)).buffer.asUint8List());
      await audioPlayer.setUrl(file.path);
      await audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
    return await audioPlayer.resume();
  }

  Future<int> pause() async => await audioPlayer.pause();

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static MusicPlayer of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(MusicPlayer);
}
