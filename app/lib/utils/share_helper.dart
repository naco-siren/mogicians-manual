import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/services.dart';
import 'package:mogicians_manual/data/list_items.dart';

void shareImage(ImageItem item) async {
  final ByteData bytes = await rootBundle.load(item.path);
  await EsysFlutterShare.shareImage(item.src, bytes, '发送【${item.title}】');
}