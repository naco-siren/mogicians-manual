// Smoke tests for the home page: the tabs render, JSON assets load, and the
// music tab drives the (faked) audio platform.

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mogicians_manual/main.dart';
import 'package:mogicians_manual/service/app_sharing.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/ui/home.dart';
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
    await tester.pumpWidget(
      MyApp(audioHandler: MogicianAudioHandler(AudioPlayer())),
    );
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
    await tester.pumpWidget(
      MyApp(audioHandler: MogicianAudioHandler(AudioPlayer())),
    );
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
  testWidgets('next, previous and the playback modes move the highlight', (
    tester,
  ) async {
    final handler = MogicianAudioHandler(AudioPlayer(), random: Random(7));
    await tester.pumpWidget(MyApp(audioHandler: handler));
    await tester.pumpAndSettle();
    await tester.tap(find.text('【唱】'));
    await tester.pumpAndSettle();

    // The tile that shows the pause icon (only built while on screen).
    Finder playingTile() => find.ancestor(
      of: find.byIcon(Icons.pause_circle_filled),
      matching: find.byType(MusicTile),
    );
    String? currentId() => handler.mediaItem.value?.id;

    expect(handler.mode, PlaybackMode.repeatOne);
    await tester.tap(find.byType(MusicTile).first);
    await _pumpFrames(tester);
    final firstId = currentId();
    expect(firstId, isNotNull);

    // Next in list order highlights the second tile.
    await handler.skipToNext();
    await _pumpFrames(tester);
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    expect(
      tester.widget<MusicTile>(playingTile()).item.path,
      tester.widget<MusicTile>(find.byType(MusicTile).at(1)).item.path,
    );
    expect(currentId(), isNot(firstId));

    // Previous goes back; from the first track it wraps around to the last
    // one (off screen, so only the handler's current item can be checked),
    // and next from there wraps back to the first.
    await handler.skipToPrevious();
    await _pumpFrames(tester);
    expect(currentId(), firstId);
    expect(tester.widget<MusicTile>(playingTile()).item.path, firstId);
    await handler.skipToPrevious();
    await _pumpFrames(tester);
    expect(currentId(), isNot(firstId));
    await handler.skipToNext();
    await _pumpFrames(tester);
    expect(currentId(), firstId);

    // 全部循环 keeps list order.
    await handler.cycleMode();
    expect(handler.mode, PlaybackMode.repeatAll);
    await handler.skipToNext();
    await _pumpFrames(tester);
    expect(
      currentId(),
      tester.widget<MusicTile>(find.byType(MusicTile).at(1)).item.path,
    );
    await handler.skipToPrevious();
    await _pumpFrames(tester);
    expect(currentId(), firstId);

    // 全部随机: next picks a different track and previous undoes it.
    await handler.cycleMode();
    expect(handler.mode, PlaybackMode.shuffle);
    await handler.skipToNext();
    await _pumpFrames(tester);
    expect(currentId(), isNot(firstId));
    await handler.skipToPrevious();
    await _pumpFrames(tester);
    expect(currentId(), firstId);
    expect(tester.widget<MusicTile>(playingTile()).item.path, firstId);

    await handler.cycleMode();
    expect(handler.mode, PlaybackMode.repeatOne);

    // Leave the player paused so audioplayers' frame-based position
    // updater is not still scheduling frames when the tree is torn down.
    await handler.pause();
    await _pumpFrames(tester);
  });

  testWidgets('a finished track advances only in the all-tracks modes', (
    tester,
  ) async {
    final handler = MogicianAudioHandler(AudioPlayer());
    await tester.pumpWidget(MyApp(audioHandler: handler));
    await tester.pumpAndSettle();
    await tester.tap(find.text('【唱】'));
    await tester.pumpAndSettle();
    String? currentId() => handler.mediaItem.value?.id;

    await tester.tap(find.byType(MusicTile).first);
    await _pumpFrames(tester);
    final firstId = currentId();
    final secondId = tester
        .widget<MusicTile>(find.byType(MusicTile).at(1))
        .item
        .path;

    // 单曲循环: completion is ignored (the platform loops natively).
    audioPlatform.emitComplete();
    await _pumpFrames(tester);
    expect(currentId(), firstId);
    expect(audioPlatform.calls.last, isNot('resume'));

    // 全部循环: completion starts the next track and stays "playing".
    await handler.cycleMode();
    await _pumpFrames(tester);
    audioPlatform.emitComplete();
    await _pumpFrames(tester);
    expect(currentId(), secondId);
    expect(handler.playbackState.value.playing, isTrue);
    expect(
      find.descendant(
        of: find.byType(MusicTile).at(1),
        matching: find.byIcon(Icons.pause_circle_filled),
      ),
      findsOneWidget,
    );

    await handler.pause();
    await _pumpFrames(tester);
  });
  group('分享安装包', () {
    const shareMe = <String, Object?>{
      'package': 'com.xiaomi.midrop',
      'label': 'ShareMe',
      'sendsApk': true,
      'sendsZip': true,
    };
    const zapya = <String, Object?>{
      'package': 'com.dewmobile.kuaiya.play',
      'label': 'Zapya',
      'sendsApk': false,
      'sendsZip': false,
    };

    /// Answers the Android side of AppSharing and records the calls made.
    List<MethodCall> fakeAppSharing(
      WidgetTester tester, {
      bool split = false,
      List<Map<String, Object?>> shareApps = const [],
      int apkReceivers = 3,
      int zipReceivers = 4,
    }) {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppSharing.channel,
        (call) async {
          calls.add(call);
          if (call.method == 'describe') {
            return <String, Object?>{
              'versionName': '10.1.2',
              'fileName': '膜法指南-10.1.2.apk',
              'sizeBytes': 147 * 1024 * 1024,
              'splitInstall': split,
              'shareApps': shareApps,
              'apkReceivers': apkReceivers,
              'zipReceivers': zipReceivers,
            };
          }
          return null;
        },
      );
      // Toasts go through a platform channel that has no home in tests.
      const toast = MethodChannel('PonnamKarthik/fluttertoast');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        toast,
        (call) async => true,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AppSharing.channel,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          toast,
          null,
        );
      });
      return calls;
    }

    List<String> methods(List<MethodCall> calls) => [
      for (final c in calls) c.method,
    ];

    Future<void> openFromMenu(WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(audioHandler: MogicianAudioHandler(AudioPlayer())),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byType(PopupMenuButton<ActionOption>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('分享安装包'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers the installed transfer apps first', (tester) async {
      final calls = fakeAppSharing(tester, shareApps: [shareMe, zapya]);
      await openFromMenu(tester);
      expect(find.text('用 ShareMe 发送'), findsOneWidget);
      expect(find.text('打开 Zapya'), findsOneWidget);
      expect(find.textContaining('找到膜法指南发送'), findsOneWidget);
      expect(find.text('发送 APK'), findsNothing);

      await tester.tap(find.text('用 ShareMe 发送'));
      await tester.pumpAndSettle();
      expect(methods(calls), ['describe', 'share']);
      expect(calls.last.arguments, {
        'format': 'apk',
        'package': 'com.xiaomi.midrop',
      });
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('an app that only takes ZIPs gets the ZIP', (tester) async {
      const zipOnly = <String, Object?>{
        'package': 'com.example.ziponly',
        'label': 'ZipOnly',
        'sendsApk': false,
        'sendsZip': true,
      };
      final calls = fakeAppSharing(tester, shareApps: [zipOnly]);
      await openFromMenu(tester);
      await tester.tap(find.text('用 ZipOnly 发送 ZIP'));
      await tester.pumpAndSettle();
      expect(methods(calls), ['describe', 'share']);
      expect(calls.last.arguments, {
        'format': 'zip',
        'package': 'com.example.ziponly',
      });
      await tester.pump(const Duration(seconds: 2)); // let the toast expire
    });

    testWidgets('an app that cannot take the file is opened instead', (
      tester,
    ) async {
      final calls = fakeAppSharing(tester, shareApps: [zapya]);
      await openFromMenu(tester);
      await tester.tap(find.text('打开 Zapya'));
      await tester.pumpAndSettle();
      expect(methods(calls), ['describe', 'open']);
      expect(calls.last.arguments, {'package': 'com.dewmobile.kuaiya.play'});
    });

    testWidgets('其他方式 leads to the plain file dialog', (tester) async {
      final calls = fakeAppSharing(tester, shareApps: [shareMe]);
      await openFromMenu(tester);
      await tester.tap(find.text('其他方式'));
      await tester.pumpAndSettle();
      expect(find.text('发送 APK'), findsOneWidget);
      expect(find.text('发送 ZIP'), findsOneWidget);
      expect(find.textContaining('147 MB'), findsOneWidget);
      expect(find.textContaining('没有装面对面传文件的应用'), findsNothing);

      await tester.tap(find.text('发送 ZIP'));
      await tester.pumpAndSettle();
      expect(methods(calls), ['describe', 'share']);
      expect(calls.last.arguments, {'format': 'zip', 'package': null});
      await tester.pump(const Duration(seconds: 2)); // let the toast expire
    });

    testWidgets('without transfer apps the file dialog sends the APK', (
      tester,
    ) async {
      final calls = fakeAppSharing(tester);
      await openFromMenu(tester);
      expect(find.textContaining('膜法指南-10.1.2.apk'), findsOneWidget);
      expect(find.textContaining('没有装面对面传文件的应用'), findsOneWidget);
      expect(find.text('用 ShareMe 发送'), findsNothing);

      await tester.tap(find.text('发送 APK'));
      await tester.pumpAndSettle();
      expect(methods(calls), ['describe', 'share']);
      expect(calls.last.arguments, {'format': 'apk', 'package': null});
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a file type nobody can receive is not sent', (tester) async {
      final calls = fakeAppSharing(tester, apkReceivers: 0, zipReceivers: 0);
      await openFromMenu(tester);
      await tester.tap(find.text('发送 APK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('发送 ZIP'));
      await tester.pumpAndSettle();
      expect(methods(calls), ['describe']);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pump(const Duration(seconds: 2)); // let the toasts expire
    });

    testWidgets('a copy installed in pieces by Play gets the download page', (
      tester,
    ) async {
      final calls = fakeAppSharing(tester, split: true, shareApps: [shareMe]);
      await openFromMenu(tester);
      expect(find.text('暂时无法直接分享'), findsOneWidget);
      expect(find.text('打开下载页'), findsOneWidget);
      expect(find.text('用 ShareMe 发送'), findsNothing);
      expect(methods(calls), ['describe']);
    });
  });

  testWidgets('the image tab scrolls past the first sections without jumping', (
    tester,
  ) async {
    await tester.pumpWidget(
      MyApp(audioHandler: MogicianAudioHandler(AudioPlayer())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('【逗】'));
    await tester.pumpAndSettle();
    expect(find.text('高清'), findsOneWidget);

    // Scroll through 高清 and 原生 (the point where the old sliver layout
    // threw the viewport back to the top) and on to the third header.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('颜艺'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('颜艺'), findsOneWidget);
    expect(find.text('高清'), findsNothing);
    expect(tester.getTopLeft(find.text('颜艺')).dy, greaterThan(0));
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

  /// Pretends every player just reached the end of its track.
  void emitComplete() {
    for (final controller in _events.values) {
      controller.add(const AudioEvent(eventType: AudioEventType.complete));
    }
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
