import 'dart:async';

import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';

import 'package:mogicians_manual/ui/mdi_icons.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mogicians_manual/ui/tabs.dart';
import 'package:mogicians_manual/data/models.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/service/theme_provider.dart';
import 'package:mogicians_manual/service/toast_util.dart';

class HomePage extends StatefulWidget {
  final String title;
  final bool isNovember;
  final ThemeMode themeMode;
  final VoidCallback onThemeModeChanged;

  const HomePage({
    super.key,
    required this.isNovember,
    required this.title,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with ToastUtil {
  int _selectedIndex = 0;

  final _shuoModel = TabShuoModel();
  final _xueModel = TabXueModel();
  final _douModel = TabDouModel();
  final _changModel = TabChangModel();
  final _genModel = TabGenModel();

  MogicianAudioHandler? _audioHandler;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  bool _libraryPublished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final handler = MusicPlayer.of(context).handler;
    if (_audioHandler == handler) return;
    _audioHandler = handler;

    // Keep the 唱 tab in step with the media notification's buttons.
    _playbackSubscription?.cancel();
    _playbackSubscription = handler.playbackState.listen((state) {
      // Playback that starts while nothing is selected (e.g. a media key
      // after Stop) still has a media item; re-select it first.
      if (state.playing && _changModel.curIdx < 0) {
        final id = handler.mediaItem.value?.id;
        if (id != null) _changModel.selectByPath(id);
      }
      _changModel.syncPlayback(
        playing: state.playing,
        stopped: state.processingState == AudioProcessingState.idle,
      );
    });
    _mediaItemSubscription?.cancel();
    _mediaItemSubscription = handler.mediaItem.listen((item) {
      if (item != null) _changModel.selectByPath(item.id);
    });

    // Hand the track list to the handler once the JSON has been loaded, so
    // next/previous/shuffle know the library.
    _changModel.addListener(_publishLibrary);
    _publishLibrary();
  }

  void _publishLibrary() {
    if (_libraryPublished) return;
    final tracks = _changModel.musicItems;
    if (tracks.isEmpty) return;
    _audioHandler?.library = tracks;
    _libraryPublished = true;
  }

  @override
  void dispose() {
    _changModel.removeListener(_publishLibrary);
    _playbackSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(widget.isNovember ? MdiIcons.candle : MdiIcons.glasses),
        title: Text(widget.title),
        actions: _getAppbarActions(),
      ),
      backgroundColor: Theme.of(context).mogicianColors.homeBackground,
      body: Center(child: _getTab()),
      bottomNavigationBar: _getBottomNav(),
    );
  }

  Widget _getTab() {
    final isNov = widget.isNovember;
    switch (_selectedIndex) {
      case 0:
        return ScopedModel<TabShuoModel>(
          model: _shuoModel,
          child: TabShuo(isNov),
        );
      case 1:
        return ScopedModel<TabXueModel>(model: _xueModel, child: TabXue(isNov));
      case 2:
        return ScopedModel<TabDouModel>(model: _douModel, child: TabDou(isNov));
      case 3:
        return ScopedModel<TabChangModel>(
          model: _changModel,
          child: TabChang(isNov, _selectMusicItem),
        );
      case 4:
        return ScopedModel<TabGenModel>(model: _genModel, child: TabGen(isNov));
      default:
        throw Exception('Invalid index!');
    }
  }

  List<Widget> _getAppbarActions() {
    final options = <ActionOption>[
      const ActionOption(
        title: '源码',
        iconData: MdiIcons.github,
        firstUrl: 'https://github.com/naco-siren/mogicians-manual/tree/master/app/README.md',
      ),
      const ActionOption(
        title: '反馈',
        iconData: Icons.bug_report,
        firstUrl: 'https://github.com/naco-siren/mogicians-manual/issues',
      ),
      const ActionOption(
        title: '开发者',
        iconData: MdiIcons.guyFawkesMask,
        firstUrl: 'https://naco-siren.github.io',
      ),
    ];

    if (!widget.isNovember) {
      options.insert(
        0,
        ActionOption(
          title: '夜间模式',
          iconData: MyThemeDataProvider.getBrightnessIcon(widget.themeMode),
        ),
      );
    }

    return <Widget>[
      IconButton(
        icon: Icon(options[0].iconData),
        onPressed: widget.onThemeModeChanged,
      ),
      IconButton(
        icon: Icon(options[1].iconData),
        onPressed: () => _launchUrl(options[1]),
      ),
      PopupMenuButton<ActionOption>(
        itemBuilder: (BuildContext context) =>
            options.skip(2).map((ActionOption option) {
              return PopupMenuItem<ActionOption>(
                value: option,
                child: Text(option.title),
              );
            }).toList(),
        onSelected: (option) => _launchUrl(option),
      ),
    ];
  }

  Future<void> _launchUrl(ActionOption option) async {
    for (final url in [option.firstUrl, option.secondUrl]) {
      if (url == null) continue;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }

    if (!mounted) return;
    showToast(context, 'Deep ♂ Dark ♂ Fantasy');
  }

  Widget _getBottomNav() => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(label: '【说】', icon: Icon(Icons.mic)),
      BottomNavigationBarItem(label: '【学】', icon: Icon(Icons.local_library)),
      BottomNavigationBarItem(
        label: '【逗】',
        icon: Icon(Icons.sentiment_very_satisfied),
      ),
      BottomNavigationBarItem(label: '【唱】', icon: Icon(Icons.music_note)),
      BottomNavigationBarItem(label: '【哏】', icon: Icon(Icons.school)),
    ],
    currentIndex: _selectedIndex,
    onTap: _selectTabItem,
  );

  void _selectTabItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectMusicItem(int index) {
    _changModel.curIdx = index;
  }
}

class ActionOption {
  final String title;
  final IconData iconData;
  final String? firstUrl;
  final String? secondUrl;

  const ActionOption({
    required this.title,
    required this.iconData,
    this.firstUrl,
    this.secondUrl,
  });
}
