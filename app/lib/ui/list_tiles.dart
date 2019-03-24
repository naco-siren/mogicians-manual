import 'package:flutter/material.dart';

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:mogicians_manual/data/list_items.dart';

class HeaderTile extends StatelessWidget {
  HeaderTile(this._item);

  final HeaderItem _item;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 18, top: 20, bottom: 8),
        child: Text(
          _item.heading,
          style: Theme.of(context).textTheme.title.apply(
              color: Colors.yellowAccent.shade700,
              fontWeightDelta: 1,
          ),
        )
    );
  }
}

class TextTile extends StatefulWidget {
  TextTile(this._item);

  final TextItem _item;

  @override
  State createState() => _TextTileState(_item);
}

class _TextTileState extends State<TextTile> {
  _TextTileState(this._item);

  final TextItem _item;

  @override
  Widget build(BuildContext context) {
    return new Card(
        shape: BeveledRectangleBorder(),
        color: Colors.white,
        elevation: 2,
        child: InkWell(
          onTap: () {
            setState(() {
              _item.isExpanded = !_item.isExpanded;
            });
          },
          onLongPress: () {
            if (_item.isExpanded) {
              _copyToClipboard(_item.title, _item.body);
            }
          },
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _generateChildren(),
          )
        ),
        margin: EdgeInsets.all(0),
    );
  }

  List<Widget> _generateChildren() {
    List<Widget> contents = [];
    contents.add(Text(
      _item.title,
      style: Theme.of(context).textTheme.body1.apply(
          fontSizeFactor: 1.2
      ),
    ));
    if (_item.isExpanded) {
      contents.add(SizedBox(height: 8));
      contents.add(
        Text(
          _item.body,
          style: Theme.of(context).textTheme.body1.apply(
              fontSizeFactor: 1.1,
              color: Colors.grey.shade600,
          ),
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
          fontSize: 14.0
      );
    });
  }
}

class ImageTile extends StatefulWidget {
  ImageTile(this.item, this.isTablet);

  final ImageItem item;
  final bool isTablet;

  @override
  State createState() => _ImageTileState(item, isTablet);
}

class _ImageTileState extends State<ImageTile> {
  final double paddingTablet = 8.0;
  final double paddingPhone = 4.0;

  _ImageTileState(this._item, this.isTablet);

  final ImageItem _item;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final placeHolderImage = AssetImage('assets/images/dou_placeholder.jpg');

    return Padding(
        padding: EdgeInsets.all(isTablet ? paddingTablet : paddingPhone),
        child:
        Card(
          shape: BeveledRectangleBorder(),
          color: Colors.white,
          elevation: 2,
          child: InkWell(
            onTap: () {},
            onLongPress: () {},
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Text(
                      _item.title,
                      style: Theme.of(context).textTheme.caption.apply(
                        color: Colors.black,
                        fontSizeFactor: isTablet ? 1.3 : 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FadeInImage(
                      placeholder: placeHolderImage,
                      image: AssetImage('assets/images/${_item.src}')
                  )
                ]
            ),
          ),
          margin: EdgeInsets.all(0),
        )
    );
  }
}

class FooterTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(height: 64);
}
