import 'package:flutter/material.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/service/music_player.dart';
import 'package:mogicians_manual/service/toast_util.dart';

typedef ItemTapCallback = void Function(int);


class MusicTile extends StatefulWidget {
  MusicTile(this.item, this.index, this.callback);

  final MusicItem item;
  final int index;
  final ItemTapCallback callback;

  @override
  State createState() => _MusicTileState();
}

class _MusicTileState extends State<MusicTile> with ToastUtil {
  @override
  Widget build(BuildContext context) => Card(
    key: ObjectKey(widget.item),
    shape: BeveledRectangleBorder(),
    color: Theme.of(context).cardColor,
    elevation: 2,
    child: InkWell(
        onTap: () => _onTapped(context, widget.item),
        onLongPress: () {},
        child: Column(
          children: <Widget>[
            Container(
              color: Theme.of(context).dialogBackgroundColor,
              height: 1,
            ),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _playControl(context, widget.item.status),
                    SizedBox(width: 18),
                    Expanded(
                        child: Text(
                          widget.item.title,
                          style: Theme.of(context).textTheme.bodyText2.copyWith(
                              letterSpacing: 1.1, fontSize: 18),
                        )),
                  ],
                ))
          ],
        )),
    margin: EdgeInsets.all(0),
  );

  Widget _playControl(BuildContext context, AudioStatus status) {
    switch (status) {
      case AudioStatus.STOPPED:
        return Icon(Icons.play_arrow,
            size: 30, color: Theme.of(context).unselectedWidgetColor);
      case AudioStatus.RESUMED:
        return Icon(Icons.pause_circle_filled,
            size: 30, color: Theme.of(context).toggleableActiveColor);
      case AudioStatus.PAUSED:
        return Icon(Icons.play_circle_filled,
            size: 30, color: Theme.of(context).toggleableActiveColor);
      default:
        throw Exception("Invalid audio status!");
    }
  }

  void _onTapped(BuildContext context, MusicItem item) async {
    final player = MusicPlayer.of(context);
    switch (widget.item.status) {
      case AudioStatus.STOPPED:
        if (await player.resume(item: item) == 1) {
          setState(() => widget.callback(widget.index));
        } else {
          _toastError("播放");
        }
        break;
      case AudioStatus.RESUMED:
        if (await player.pause() == 1) {
          setState(() => widget.item.status = AudioStatus.PAUSED);
        } else {
          _toastError("暂停");
        }
        break;
      case AudioStatus.PAUSED:
        if (await player.resume() == 1) {
          setState(() => widget.item.status = AudioStatus.RESUMED);
        } else {
          _toastError("恢复播放");
        }
        break;
    }
  }

  void _toastError(String subject) {
    showToast(context, "试图$subject时发生错误");
  }
}

