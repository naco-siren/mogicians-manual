import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mogicians_manual/data/list_items.dart';


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