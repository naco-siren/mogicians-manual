import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/data/list_items.dart';

/// Drives the app-wide [AudioPlayer] through audio_service, so playback runs
/// inside a media foreground service: the system shows a notification with
/// play/pause/stop and, on Android 17+, keeps the music audible while the app
/// is in the background.
class MogicianAudioHandler extends BaseAudioHandler {
  MogicianAudioHandler(this._player) {
    _stateSubscription = _player.onPlayerStateChanged.listen(_onPlayerState);
  }

  final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSubscription;

  /// True while [playItem] restarts the player for a new track, so the
  /// intermediate "stopped" state does not tear the service down.
  bool _switchingTrack = false;

  /// Starts [item] from the beginning, looping.
  Future<void> playItem(MusicItem item) async {
    mediaItem.add(MediaItem(id: item.path, title: item.title, album: '膜法指南'));
    _switchingTrack = true;
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      // AssetSource paths are relative to AudioCache's prefix ('assets/').
      await _player.setSource(AssetSource('audio/${item.src}'));
    } finally {
      _switchingTrack = false;
    }
    await _player.resume();
  }

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void _onPlayerState(PlayerState state) {
    if (_switchingTrack && state == PlayerState.stopped) return;
    final playing = state == PlayerState.playing;
    final stopped =
        state == PlayerState.stopped || state == PlayerState.disposed;
    playbackState.add(
      playbackState.value.copyWith(
        playing: playing,
        processingState: stopped
            ? AudioProcessingState.idle
            : AudioProcessingState.ready,
        controls: [
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1],
      ),
    );
  }

  Future<void> dispose() async {
    await _stateSubscription.cancel();
    await _player.dispose();
  }
}

/// Exposes the app-wide [MogicianAudioHandler] to the widget tree.
class MusicPlayer extends InheritedWidget {
  const MusicPlayer({super.key, required this.handler, required super.child});

  final MogicianAudioHandler handler;

  /// Starts playing [item] from the beginning (looping), or resumes the
  /// paused track when [item] is null.
  ///
  /// Throws if the platform player reports an error.
  Future<void> resume({MusicItem? item}) =>
      item == null ? handler.play() : handler.playItem(item);

  Future<void> pause() => handler.pause();

  @override
  bool updateShouldNotify(MusicPlayer oldWidget) =>
      handler != oldWidget.handler;

  static MusicPlayer of(BuildContext context) {
    final player = context.dependOnInheritedWidgetOfExactType<MusicPlayer>();
    assert(player != null, 'No MusicPlayer found in the widget tree');
    return player!;
  }
}
