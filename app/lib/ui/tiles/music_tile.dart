import 'package:flutter/material.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/service/theme_provider.dart';
import 'package:mogicians_manual/service/toast_util.dart';

typedef ItemTapCallback = void Function(int);

class MusicTile extends StatefulWidget {
  MusicTile(this.item, this.index, this.callback, this.disabled)
    : super(key: ObjectKey(item));

  final MusicItem item;
  final int index;
  final ItemTapCallback callback;
  final bool disabled;

  @override
  State<MusicTile> createState() => _MusicTileState();
}

class _MusicTileState extends State<MusicTile> with ToastUtil {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: const BeveledRectangleBorder(),
      color: theme.cardColor,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (!widget.disabled) _onTapped(widget.item);
        },
        onLongPress: () {},
        child: Column(
          children: <Widget>[
            Container(color: theme.dividerColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  widget.disabled
                      ? _disabledControl(theme)
                      : _playControl(theme, widget.item.status),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: (theme.textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(letterSpacing: 1.1, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabledControl(ThemeData theme) =>
      Icon(Icons.block, size: 30, color: theme.unselectedWidgetColor);

  Widget _playControl(ThemeData theme, AudioStatus status) {
    switch (status) {
      case AudioStatus.stopped:
        return Icon(
          Icons.play_arrow,
          size: 30,
          color: theme.unselectedWidgetColor,
        );
      case AudioStatus.resumed:
        return Icon(
          Icons.pause_circle_filled,
          size: 30,
          color: theme.mogicianColors.activeControl,
        );
      case AudioStatus.paused:
        return Icon(
          Icons.play_circle_filled,
          size: 30,
          color: theme.mogicianColors.activeControl,
        );
    }
  }

  Future<void> _onTapped(MusicItem item) async {
    final player = MusicPlayer.of(context);
    switch (item.status) {
      case AudioStatus.stopped:
        if (await _tryAudio(() => player.resume(item: item), '播放')) {
          setState(() => widget.callback(widget.index));
        }
      case AudioStatus.resumed:
        if (await _tryAudio(player.pause, '暂停')) {
          setState(() => item.status = AudioStatus.paused);
        }
      case AudioStatus.paused:
        if (await _tryAudio(player.resume, '恢复播放')) {
          setState(() => item.status = AudioStatus.resumed);
        }
    }
  }

  /// Runs [action]; on failure shows a toast and returns false.
  ///
  /// The result is only meaningful while this tile is still mounted.
  Future<bool> _tryAudio(Future<void> Function() action, String subject) async {
    try {
      await action();
      return mounted;
    } catch (e) {
      debugPrint('Audio error while trying to $subject: $e');
      if (mounted) showToast(context, '试图$subject时发生错误');
      return false;
    }
  }
}
