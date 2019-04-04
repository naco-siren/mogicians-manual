import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/service/music_player.dart';

typedef ItemTapCallback = void Function(int);

class HeaderTile extends StatelessWidget {
  HeaderTile(this._item);

  final HeaderItem _item;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.only(left: 18, top: 20, bottom: 8),
      child: Text(
        _item.heading,
        style: Theme.of(context).textTheme.title.apply(
              color: Colors.yellowAccent.shade700,
              fontWeightDelta: 1,
            ),
      ));
}

class TextTile extends StatefulWidget {
  TextTile(this.item);

  final TextItem item;

  @override
  State createState() => _TextTileState();
}

class _TextTileState extends State<TextTile> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      shape: BeveledRectangleBorder(),
      color: Colors.white,
      elevation: 2,
      child: InkWell(
          onTap: () {
            setState(() {
              item.isExpanded = !item.isExpanded;
            });
          },
          onLongPress: () {
            if (item.isExpanded) {
              _copyToClipboard(item.title, item.body);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _generateChildren(),
          )),
      margin: EdgeInsets.all(0),
    );
  }

  List<Widget> _generateChildren() {
    final item = widget.item;
    List<Widget> contents = [];
    contents.add(Text(
      item.title,
      style: Theme.of(context).textTheme.body1.copyWith(
          letterSpacing: 1.1, fontSize: 18),
    ));
    if (item.isExpanded) {
      contents.add(SizedBox(height: 8));
      contents.add(
        Text(
          item.body,
          style: Theme.of(context).textTheme.body1.copyWith(
              letterSpacing: 1.02,
              height: 1.05,
              fontSize: 16,
              color: Colors.grey.shade600),
        ),
      );
    }

    List<Widget> children = [];
    children.add(Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: contents,
      ),
    ));
    children.add(Container(
      color: Colors.grey.shade300,
      height: 1,
    ));

    return children;
  }

  void _copyToClipboard(String title, String body) {
    String content = '【$title】$body';
    ClipboardManager.copyToClipBoard(content).then((result) {
      Fluttertoast.showToast(
          msg: "已复制到剪贴板",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.grey.shade700.withOpacity(0.9),
          textColor: Colors.white,
          fontSize: 14.0);
    });
  }
}

class ImageTile extends StatefulWidget {
  ImageTile(this.item, this.isTablet);

  final ImageItem item;
  final bool isTablet;

  @override
  State createState() => _ImageTileState();
}

const double paddingTablet = 8.0;
const double paddingPhone = 4.0;

class _ImageTileState extends State<ImageTile> {
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.all(widget.isTablet ? paddingTablet : paddingPhone),
      child: Card(
        shape: BeveledRectangleBorder(),
        color: Colors.white,
        elevation: 2,
        child: InkWell(
          onTap: () => _toastSharingInfo(),
          onLongPress: () => _shareImage(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                widget.item.title,
                style: Theme.of(context).textTheme.caption.copyWith(
                      color: Colors.black,
                      fontSize: widget.isTablet ? 15 : 12,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            FadeInImage(
                placeholder: AssetImage('assets/images/dou_placeholder.jpg'),
                image: AssetImage(widget.item.path))
          ]),
        ),
        margin: EdgeInsets.all(0),
      ));

  void _toastSharingInfo() {
    Fluttertoast.showToast(
        msg: "长按图片来发送",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.grey.shade700.withOpacity(0.9),
        textColor: Colors.white,
        fontSize: 14.0);
  }

  void _shareImage() async {
    final item = widget.item;
    final ByteData bytes = await rootBundle.load(item.path);
    await EsysFlutterShare.shareImage(item.src, bytes, '发送【${item.title}】');
  }
}

class MusicTile extends StatefulWidget {
  MusicTile(this.item, this.index, this.callback);

  final MusicItem item;
  final int index;
  final ItemTapCallback callback;

  @override
  State createState() => _MusicTileState();
}

class _MusicTileState extends State<MusicTile> {
  @override
  Widget build(BuildContext context) => Card(
        key: ObjectKey(widget.item),
        shape: BeveledRectangleBorder(),
        color: Colors.white,
        elevation: 2,
        child: InkWell(
            onTap: () => _onTapped(context, widget.item),
            onLongPress: () {},
            child: Column(
              children: <Widget>[
                Container(
                  color: Colors.grey.shade300,
                  height: 1,
                ),
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        _playControl(widget.item.status),
                        SizedBox(width: 18),
                        Expanded(
                            child: Text(
                              widget.item.title,
                              style: Theme.of(context).textTheme.body1.copyWith(
                                  letterSpacing: 1.1, fontSize: 18),
                        )),
                      ],
                    ))
              ],
            )),
        margin: EdgeInsets.all(0),
      );

  Widget _playControl(AudioStatus status) {
    switch (status) {
      case AudioStatus.STOPPED:
        return Icon(Icons.play_arrow, size: 30, color: Colors.grey.shade400);
      case AudioStatus.RESUMED:
        return Icon(Icons.pause_circle_filled,
            size: 30, color: Colors.grey.shade700);
      case AudioStatus.PAUSED:
        return Icon(Icons.play_circle_filled,
            size: 30, color: Colors.grey.shade700);
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
    Fluttertoast.showToast(
        msg: "试图$subject时发生错误",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.grey.shade700.withOpacity(0.9),
        textColor: Colors.white,
        fontSize: 14.0);
  }
}

class FooterTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(height: 64);
}
