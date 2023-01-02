import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/utils/share_helper.dart';

class DocumentViewer extends StatelessWidget {
  final DocumentItem item;

  DocumentViewer(this.item);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadDocument(item),
        builder: (context, snapshot) {
          final loaded = snapshot.connectionState == ConnectionState.done;
          final File file = snapshot.data;

          return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: _appBarActions(loaded, item.title, file),
                title: Text(item.title),
              ),
              body: _content(loaded, file?.path));
        });
  }

  List<Widget> _appBarActions(bool loaded, String title, File file) {
    final List<Widget> actions = [];
    if (loaded) {
      actions.add(IconButton(
        icon: Icon(Icons.share),
        onPressed: () {
          shareDocument(title, file);
        },
      ));
    }
    return actions;
  }

  Widget _content(bool loaded, String path) {
    final child = loaded
        ? PdfView(key: Key(item.title), path: path)
        : SizedBox(
            child: CircularProgressIndicator(),
            height: 80.0,
            width: 80.0,
          );

    return Container(child: child, alignment: Alignment.center);
  }
}
