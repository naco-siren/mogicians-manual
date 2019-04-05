import 'package:flutter/material.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/utils/share_helper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ImageViewer extends StatelessWidget {
  final ImageItem item;

  ImageViewer(this.item);

  @override
  Widget build(BuildContext context) {
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
              shareImage(item);
              _toastSharingInfo();
            },
          ),
        ],
        title: Text(item.title),
      ),
      body: Container(
          child: PhotoView(
        imageProvider: AssetImage(item.path),
      )),
    );
  }

  void _toastSharingInfo() {
    Fluttertoast.showToast(
        msg: "可在列表中长按图片来发送",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.grey.shade700.withOpacity(0.9),
        textColor: Colors.white,
        fontSize: 14.0);
  }
}
