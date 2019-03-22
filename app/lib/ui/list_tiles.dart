import 'package:flutter/material.dart';

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:mogicians_manual/data/list_items.dart';

class HeaderTile extends StatelessWidget {
  final HeaderItem item;
  
  HeaderTile(this.item);
  
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 18, top: 20, bottom: 8),
        child: Text(
          item.heading,
          style: Theme.of(context).textTheme.title.apply(
              color: Colors.yellowAccent.shade700,
              fontWeightDelta: 1,
          ),
        )
    );
  }
}

class TextTile extends StatefulWidget {
  final TextItem item;

  TextTile(this.item);

  @override
  State createState() => TextTileState(item);
}

class TextTileState extends State<TextTile> {
  final TextItem item;

  TextTileState(this.item);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return new Card(
        shape: BeveledRectangleBorder(),
        color: Colors.white,
        elevation: 2,
        child: InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          onLongPress: () {
            if (_expanded) {
              _copyToClipboard(item.title, item.body);
            }
          },
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: generateChildren(),
          )
        ),
        margin: EdgeInsets.all(0),
    );
  }

  List<Widget> generateChildren() {
    List<Widget> contents = [];
    contents.add(Text(
      item.title,
      style: Theme.of(context).textTheme.body1.apply(
          fontSizeFactor: 1.2
      ),
    ));
    if (_expanded) {
      contents.add(SizedBox(height: 8));
      contents.add(
        Text(
          item.body,
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

class FooterTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(height: 64);
}
