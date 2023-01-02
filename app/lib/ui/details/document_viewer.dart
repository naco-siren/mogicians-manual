import 'package:flutter/material.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/utils/share_helper.dart';

class DocumentViewer extends StatelessWidget {
  final DocumentItem item;

  DocumentViewer(this.item);

  @override
  Widget build(BuildContext context) {
    return
      FutureBuilder(
          future: loadDocument(item),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: <Widget>[
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {
                          // shareImage(item);
                          // _toastSharingInfo();
                        },
                      ),
                    ],
                    title: Text(item.title),
                  ),
                  body: Container(
                      child: PdfView(key: Key(item.title), path: snapshot.data)
                  ));
            } else {
              return const SizedBox(
                child: CircularProgressIndicator(),
                height: 40.0,
                width: 40.0,
              );
            }
          }
      );
  }
}
