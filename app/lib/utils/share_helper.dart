import 'package:flutter/services.dart';

import 'package:share_plus/share_plus.dart';

import 'package:mogicians_manual/data/list_items.dart';

Future<void> shareImage(ImageItem item) =>
    _shareAsset(title: item.title, assetPath: item.path, fileName: item.src);

Future<void> shareDocument(DocumentItem item) => _shareAsset(
  title: item.title,
  assetPath: item.path,
  fileName: '${item.title}.pdf',
  mimeType: 'application/pdf',
);

/// Hands a bundled asset to the system share sheet.
///
/// share_plus copies the bytes into its own cache directory and exposes them
/// through its FileProvider, so nothing has to be written to app storage here.
/// When [mimeType] is omitted share_plus derives it from [fileName].
Future<void> _shareAsset({
  required String title,
  required String assetPath,
  required String fileName,
  String? mimeType,
}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await SharePlus.instance.share(
    ShareParams(
      title: '发送【$title】',
      files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
    ),
  );
}
