import 'package:flutter/widgets.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/data/list_items.dart';

/// Exposes the app-wide [AudioPlayer] to the widget tree.
class MusicPlayer extends InheritedWidget {
  const MusicPlayer({
    super.key,
    required this.audioPlayer,
    required super.child,
  });

  final AudioPlayer audioPlayer;

  /// Starts playing [item] from the beginning (looping), or resumes the
  /// paused track when [item] is null.
  ///
  /// Throws if the platform player reports an error.
  Future<void> resume({MusicItem? item}) async {
    if (item != null) {
      await audioPlayer.stop();
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      // AssetSource paths are relative to AudioCache's prefix ('assets/').
      await audioPlayer.setSource(AssetSource('audio/${item.src}'));
    }
    await audioPlayer.resume();
  }

  Future<void> pause() => audioPlayer.pause();

  @override
  bool updateShouldNotify(MusicPlayer oldWidget) =>
      audioPlayer != oldWidget.audioPlayer;

  static MusicPlayer of(BuildContext context) {
    final player = context.dependOnInheritedWidgetOfExactType<MusicPlayer>();
    assert(player != null, 'No MusicPlayer found in the widget tree');
    return player!;
  }
}
