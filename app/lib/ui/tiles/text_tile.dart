import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mogicians_manual/data/list_items.dart';

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
    String content = '【$title】\n$body';
    ClipboardManager.copyToClipBoard(content).then((result) {
      Fluttertoast.showToast(
          msg: "已复制到剪贴板",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade700.withOpacity(0.9),
          textColor: Colors.white,
          fontSize: 14.0);
    });
  }
}