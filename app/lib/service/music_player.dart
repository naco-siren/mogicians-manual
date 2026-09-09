import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart'
    show AudioInterruptionEvent, AudioInterruptionType, AudioSession;
import 'package:audioplayers/audioplayers.dart';

import 'package:mogicians_manual/data/list_items.dart';

/// What happens when a track reaches its end.
enum PlaybackMode {
  /// The track starts over (the app's historical behaviour).
  repeatOne,

  /// The next track in list order starts; the last one wraps to the first.
  repeatAll,

  /// The next track of a per-session random order starts.
  shuffle,
}

/// Drives the app-wide [AudioPlayer] through audio_service, so playback runs
/// inside a media foreground service: the system shows a notification with
/// shuffle / previous / play-pause / next / stop and, on Android 17+, keeps
/// the music audible while the app is in the background.
///
/// "Next" and "previous" walk the whole 唱 library (all sections) circularly,
/// in list order or, in [PlaybackMode.shuffle], in a random order drawn when
/// that mode is entered and kept until the mode changes or the app restarts.
class MogicianAudioHandler extends BaseAudioHandler {
  MogicianAudioHandler(this._player, {Random? random})
    : _random = random ?? Random() {
    _stateSubscription = _player.onPlayerStateChanged.listen(_onPlayerState);
    _completeSubscription = _player.onPlayerComplete.listen(_onTrackComplete);
    // Audio focus is handled through audio_session (see [attachSession]), so
    // audioplayers must not request it itself: its native focus handler
    // pauses the MediaPlayer without telling Dart, which would leave the
    // notification, the tab and the foreground service claiming playback.
    _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
  }

  static const List<int> _compactActionIndices = [0, 2, 3];

  final AudioPlayer _player;
  final Random _random;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<void> _completeSubscription;

  AudioSession? _session;
  final List<StreamSubscription<dynamic>> _sessionSubscriptions = [];
  bool _resumeAfterInterruption = false;

  List<MusicItem> _library = const [];
  List<MusicItem> _order = const [];
  MusicItem? _current;

  /// Bumped by every [playItem] and [stop]; a track switch that finds a
  /// newer generation after one of its awaits has been superseded and must
  /// not start playback.
  int _generation = 0;

  /// Number of [playItem] calls between their `stop()` and `resume()`; the
  /// player's transient "stopped" state is not published while it is > 0.
  int _switchesInFlight = 0;

  /// Every track of the 唱 tab in list order.
  set library(List<MusicItem> items) {
    _library = List.unmodifiable(items);
    _rebuildOrder();
  }

  PlaybackMode _mode = PlaybackMode.repeatOne;

  /// The current end-of-track behaviour; cycled by the card's mode button.
  PlaybackMode get mode => _mode;

  /// Lets [session] own audio focus for this player: playback activates it,
  /// interruptions (calls, other players) pause or duck the music, and
  /// unplugged headphones pause it.
  void attachSession(AudioSession session) {
    _session = session;
    _sessionSubscriptions
      ..add(session.interruptionEventStream.listen(_onInterruption))
      ..add(session.becomingNoisyEventStream.listen((_) => pause()));
  }

  /// Starts [item] from the beginning, looping.
  ///
  /// The track only becomes current (media item, tab highlight) once its
  /// source has loaded; on failure the real player state is published and
  /// the error rethrown so the caller can report it.
  Future<void> playItem(MusicItem item) async {
    _log('playItem ${item.title}');
    final generation = ++_generation;
    _switchesInFlight++;
    try {
      await _player.stop();
      await _player.setReleaseMode(_releaseMode);
      // AssetSource paths are relative to AudioCache's prefix ('assets/').
      await _player.setSource(AssetSource('audio/${item.src}'));
      if (generation != _generation) return;
      _current = item;
      mediaItem.add(MediaItem(id: item.path, title: item.title, album: '膜法指南'));
      await _activateSession();
      if (generation != _generation) return;
      await _player.resume();
    } catch (_) {
      if (generation == _generation) _publishPlayerState(_player.state);
      rethrow;
    } finally {
      _switchesInFlight--;
    }
  }

  @override
  Future<void> play() async {
    final current = _current;
    final idle =
        playbackState.value.processingState == AudioProcessingState.idle;
    if (current == null || idle) {
      // After Stop, or on a fresh engine started by a media key, the player
      // has nothing to resume: restart the current track, else the first of
      // the library, and with nothing known just clear the stale card.
      final item = current ?? (_order.isEmpty ? null : _order.first);
      if (item == null) {
        await stop();
        return;
      }
      await playItem(item);
      return;
    }
    await _activateSession();
    await _player.resume();
  }

  @override
  Future<void> pause() async {
    _resumeAfterInterruption = false;
    await _player.pause();
    await _session?.setActive(false);
  }

  @override
  Future<void> stop() async {
    _generation++;
    _resumeAfterInterruption = false;
    await _player.stop();
    // Published explicitly: the player's own "stopped" event may be muted by
    // a switch that is still in flight (and that switch now stands down).
    _publishPlayerState(PlayerState.stopped);
    await _session?.setActive(false);
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _skip(1);

  @override
  Future<void> skipToPrevious() => _skip(-1);

  /// Switches the end-of-track behaviour. Entering [PlaybackMode.shuffle]
  /// draws a fresh random order; the choice is not persisted.
  Future<void> setMode(PlaybackMode mode) async {
    _log('mode $_mode -> $mode');
    _mode = mode;
    _rebuildOrder();
    await _player.setReleaseMode(_releaseMode);
    final state = playbackState.value;
    playbackState.add(
      state.copyWith(
        repeatMode: mode == PlaybackMode.repeatOne
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.all,
        shuffleMode: mode == PlaybackMode.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        controls: _controls(playing: state.playing),
        androidCompactActionIndices: _compactActionIndices,
      ),
    );
  }

  /// 单曲循环 → 全部循环 → 全部随机 → 单曲循环.
  Future<void> cycleMode() => setMode(
    PlaybackMode.values[(_mode.index + 1) % PlaybackMode.values.length],
  );

  /// The mode button is wired to the fast-forward media action (see
  /// [_controls]), so a fast-forward key press cycles the mode too.
  @override
  Future<void> fastForward() => cycleMode();

  // Requests from the system (Android Auto, Assistant) map onto the same
  // three modes.
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) => setMode(
    repeatMode == AudioServiceRepeatMode.one
        ? PlaybackMode.repeatOne
        : _mode == PlaybackMode.shuffle
        ? PlaybackMode.shuffle
        : PlaybackMode.repeatAll,
  );

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) => setMode(
    shuffleMode == AudioServiceShuffleMode.none
        ? (_mode == PlaybackMode.shuffle ? PlaybackMode.repeatAll : _mode)
        : PlaybackMode.shuffle,
  );

  ReleaseMode get _releaseMode =>
      _mode == PlaybackMode.repeatOne ? ReleaseMode.loop : ReleaseMode.stop;

  void _onTrackComplete(void _) {
    _log(
      'track complete, mode=$_mode, '
      'current=${_current?.title}, queue=${_order.length}',
    );
    if (_mode == PlaybackMode.repeatOne) return;
    // Auto-advance; a failed switch already publishes the real player state.
    unawaited(
      _skip(1).catchError((Object e) {
        _log('auto-advance failed: $e');
      }),
    );
  }

  Future<void> _skip(int delta) async {
    if (_order.isEmpty) return;
    final current = _current;
    final index = current == null ? -1 : _order.indexOf(current);
    final length = _order.length;
    await playItem(_order[(index + delta + length) % length]);
  }

  void _rebuildOrder() {
    _order = _mode == PlaybackMode.shuffle
        ? (List.of(_library)..shuffle(_random))
        : List.of(_library);
  }

  Future<void> _activateSession() async {
    await _session?.setActive(true);
  }

  Future<void> _onInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          await _player.setVolume(0.2);
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (!playbackState.value.playing) return;
          // Keep focus so the end of the interruption reaches us; a
          // transient one resumes the music, a permanent loss does not.
          await _player.pause();
          _resumeAfterInterruption = event.type == AudioInterruptionType.pause;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          await _player.setVolume(1);
        case AudioInterruptionType.pause:
          if (_resumeAfterInterruption) {
            _resumeAfterInterruption = false;
            await play();
          }
        case AudioInterruptionType.unknown:
          _resumeAfterInterruption = false;
      }
    }
  }

  List<MediaControl> _controls({required bool playing}) {
    final (modeIcon, modeLabel) = switch (_mode) {
      PlaybackMode.repeatOne => ('drawable/ic_repeat_one', '单曲循环'),
      PlaybackMode.repeatAll => ('drawable/ic_repeat', '全部循环'),
      PlaybackMode.shuffle => ('drawable/ic_shuffle', '全部随机'),
    };
    return [
      // The mode button rides on the fast-forward action (which this player
      // has no other use for): audio_service turns MediaControl.custom into a
      // media-session custom action only, and the notification-based media
      // card of Android 12 and below shows just the standard actions, so a
      // custom control would be invisible there. A standard action with our
      // own icon and label appears on every Android version.
      MediaControl(
        androidIcon: modeIcon,
        label: modeLabel,
        action: MediaAction.fastForward,
      ),
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
  }

  void _onPlayerState(PlayerState state) {
    _log(
      'player $state '
      '(switching=$_switchesInFlight)',
    );
    // The stop() inside a track switch is an implementation detail.
    if (state == PlayerState.stopped && _switchesInFlight > 0) return;
    // In the auto-advancing modes a finished track is immediately followed
    // by the next one; keep the "playing" state so the foreground service is
    // not torn down and restarted from the background in between.
    if (state == PlayerState.completed && _mode != PlaybackMode.repeatOne) {
      return;
    }
    _publishPlayerState(state);
  }

  void _publishPlayerState(PlayerState state) {
    final playing = state == PlayerState.playing;
    final stopped =
        state == PlayerState.stopped || state == PlayerState.disposed;
    playbackState.add(
      playbackState.value.copyWith(
        playing: playing,
        processingState: stopped
            ? AudioProcessingState.idle
            : AudioProcessingState.ready,
        controls: _controls(playing: playing),
        androidCompactActionIndices: _compactActionIndices,
      ),
    );
  }

  /// Diagnostics for the playback flow. [kDebugMode] is a compile-time
  /// constant, so release builds drop these calls entirely (the Flutter
  /// counterpart of an `#if DEBUG` block).
  void _log(String message) {
    if (kDebugMode) debugPrint('MogicianAudioHandler: $message');
  }

  Future<void> dispose() async {
    for (final subscription in _sessionSubscriptions) {
      await subscription.cancel();
    }
    await _stateSubscription.cancel();
    await _completeSubscription.cancel();
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
