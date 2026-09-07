// Smoke tests for the home page: the tabs render, JSON assets load, and the
// music tab drives the (faked) audio platform.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mogicians_manual/main.dart';
import 'package:mogicians_manual/ui/tiles/music_tile.dart';
import 'package:mogicians_manual/ui/tiles/text_tile.dart';

void main() {
  late _FakeAudioplayersPlatform audioPlatform;

  setUp(() {
    audioPlatform = _FakeAudioplayersPlatform();
    AudioplayersPlatformInterface.instance = audioPlatform;
    GlobalAudioplayersPlatformInterface.instance =
        _FakeGlobalAudioplayersPlatform();
    AudioCache.instance = _FakeAudioCache();
  });

  testWidgets('home page shows the title and the five tabs', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('膜法指南'), findsOneWidget);
    for (final label in ['【说】', '【学】', '【逗】', '【唱】', '【哏】']) {
      expect(find.text(label), findsOneWidget);
    }
    // The first tab loads its JSON asset and renders text tiles.
    expect(find.byType(TextTile), findsWidgets);
  });

  testWidgets('tapping a music item starts playback and shows the pause icon', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('【唱】'));
    await tester.pumpAndSettle();
    expect(find.byType(MusicTile), findsWidgets);
    expect(find.byIcon(Icons.pause_circle_filled), findsNothing);

    await tester.tap(find.byType(MusicTile).first);
    await _pumpFrames(tester);
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    expect(audioPlatform.calls, containsAllInOrder(['setSourceUrl', 'resume']));
    expect(audioPlatform.lastSourceUrl, endsWith('.aac'));

    // Tapping again pauses it.
    await tester.tap(find.byType(MusicTile).first);
    await _pumpFrames(tester);
    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_filled), findsNothing);
    expect(audioPlatform.calls, contains('pause'));
  });
}

/// Pumps a few frames instead of [WidgetTester.pumpAndSettle]: while a track is
/// "playing", audioplayers' FramePositionUpdater schedules a frame per frame,
/// so the tree never settles.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Answers every player call with success and emits the `prepared` event
/// that [AudioPlayer.setSource] waits for.
class _FakeAudioplayersPlatform extends AudioplayersPlatformInterface {
  final calls = <String>[];
  String? lastSourceUrl;
  final _events = <String, StreamController<AudioEvent>>{};

  @override
  Stream<AudioEvent> getEventStream(String playerId) => _events
      .putIfAbsent(playerId, () => StreamController<AudioEvent>.broadcast())
      .stream;

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    String? mimeType,
    bool? isLocal,
  }) async {
    calls.add('setSourceUrl');
    lastSourceUrl = url;
    _events[playerId]?.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    calls.add(_symbolName(name));
    if (name == #getCurrentPosition || name == #getDuration) {
      return Future<int?>.value();
    }
    return Future<void>.value();
  }

  static String _symbolName(Symbol symbol) {
    final raw = symbol.toString(); // Symbol("name")
    return raw.substring(8, raw.length - 2);
  }
}

class _FakeGlobalAudioplayersPlatform
    extends GlobalAudioplayersPlatformInterface {
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Skips copying assets to disk (real file I/O never completes under the
/// widget tester's fake async zone) and just hands back a plausible file URI.
class _FakeAudioCache extends AudioCache {
  @override
  Future<Uri> load(String fileName) async =>
      Uri.file('/fake-cache/$prefix$fileName');
}
