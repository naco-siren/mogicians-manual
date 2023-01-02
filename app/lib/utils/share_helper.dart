import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mogicians_manual/data/list_items.dart';

void shareImage(ImageItem item) async {
  final ByteData bytes = await rootBundle.load(item.path);
  await Share.file('发送【${item.title}】', item.src, bytes.buffer.asUint8List(), 'image/png');
}

Future<File> loadDocument(DocumentItem item) async {
  // Double check if the file has already been pulled into internal storage
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/${item.title}.pdf');
  if (await file.exists()) {
    return file;
  }

  // Otherwise, export it from the root asset bundle
  final ByteData bytes = await rootBundle.load(item.path);
  await file.writeAsBytes(bytes.buffer.asUint8List());
  return file;
}

void shareDocument(String title, File file) async {
  await Share.file('发送【$title】', title + ".pdf", file.readAsBytesSync(), 'application/pdf');
}
