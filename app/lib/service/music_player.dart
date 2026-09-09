import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/data/list_items.dart';

/// Drives the app-wide [AudioPlayer] through audio_service, so playback runs
/// inside a media foreground service: the system shows a notification with
/// shuffle / previous / play-pause / next / stop and, on Android 17+, keeps
/// the music audible while the app is in the background.
///
/// "Next" and "previous" walk the whole 唱 library (all sections) circularly,
/// either in list order or, while shuffle is on, in an order that is drawn
/// once per toggle and kept for the rest of the session.
class MogicianAudioHandler extends BaseAudioHandler {
  MogicianAudioHandler(this._player, {Random? random})
    : _random = random ?? Random() {
    _stateSubscription = _player.onPlayerStateChanged.listen(_onPlayerState);
  }

  static const List<int> _compactActionIndices = [0, 2, 3];

  final AudioPlayer _player;
  final Random _random;
  late final StreamSubscription<PlayerState> _stateSubscription;

  List<MusicItem> _library = const [];
  List<MusicItem> _order = const [];
  MusicItem? _current;

  /// True while [playItem] restarts the player for a new track, so the
  /// intermediate "stopped" state does not tear the service down.
  bool _switchingTrack = false;

  /// Every track of the 唱 tab in list order.
  set library(List<MusicItem> items) {
    _library = List.unmodifiable(items);
    _rebuildOrder();
  }

  bool get shuffleEnabled =>
      playbackState.value.shuffleMode == AudioServiceShuffleMode.all;

  /// Starts [item] from the beginning, looping.
  Future<void> playItem(MusicItem item) async {
    _current = item;
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

  @override
  Future<void> skipToNext() => _skip(1);

  @override
  Future<void> skipToPrevious() => _skip(-1);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    final state = playbackState.value;
    playbackState.add(
      state.copyWith(
        shuffleMode: enabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        controls: _controls(playing: state.playing, shuffle: enabled),
        androidCompactActionIndices: _compactActionIndices,
      ),
    );
    _rebuildOrder();
  }

  /// Turns shuffle on or off. Turning it on draws a new random order that is
  /// kept until it is toggled again or the app restarts.
  Future<void> toggleShuffle() => setShuffleMode(
    shuffleEnabled ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
  );

  /// The shuffle button is wired to the fast-forward media action (see
  /// [_controls]), so a fast-forward key press toggles shuffle too.
  @override
  Future<void> fastForward() => toggleShuffle();

  Future<void> _skip(int delta) async {
    if (_order.isEmpty) return;
    final current = _current;
    final index = current == null ? -1 : _order.indexOf(current);
    final length = _order.length;
    await playItem(_order[(index + delta + length) % length]);
  }

  void _rebuildOrder() {
    _order = shuffleEnabled
        ? (List.of(_library)..shuffle(_random))
        : List.of(_library);
  }

  List<MediaControl> _controls({required bool playing, required bool shuffle}) {
    return [
      // Shuffle rides on the fast-forward action (which this looping player
      // has no other use for): audio_service turns MediaControl.custom into a
      // media-session custom action only, and the notification-based media
      // card of Android 12 and below shows just the standard actions, so a
      // custom control would be invisible there. A standard action with our
      // own icon and label appears on every Android version.
      MediaControl(
        androidIcon: shuffle ? 'drawable/ic_shuffle_on' : 'drawable/ic_shuffle',
        label: shuffle ? '随机播放：开' : '随机播放：关',
        action: MediaAction.fastForward,
      ),
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
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
        controls: _controls(playing: playing, shuffle: shuffleEnabled),
        androidCompactActionIndices: _compactActionIndices,
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
