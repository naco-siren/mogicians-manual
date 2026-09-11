import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';

import 'package:share_plus/share_plus.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/utils/image_obfuscator.dart';

/// Shares a meme as a freshly obfuscated copy (see [ImageObfuscator]), so the
/// file a messaging app receives is never byte- or pixel-identical to the
/// bundled asset or to any previous share of it.
Future<void> shareImage(ImageItem item) async {
  final data = await rootBundle.load(item.path);
  final original = Uint8List.sublistView(data);
  final obfuscated = await compute(_obfuscateForShare, (original, item.src));
  await _share(
    title: item.title,
    bytes: obfuscated.bytes,
    fileName: obfuscated.fileName,
    mimeType: obfuscated.mimeType,
  );
}

Future<void> shareDocument(DocumentItem item) async {
  final data = await rootBundle.load(item.path);
  await _share(
    title: item.title,
    bytes: Uint8List.sublistView(data),
    fileName: '${item.title}.pdf',
    mimeType: 'application/pdf',
  );
}

/// Runs in a background isolate: decoding and re-encoding a large JPEG takes
/// a good fraction of a second on older phones.
ObfuscatedImage _obfuscateForShare((Uint8List, String) request) =>
    ImageObfuscator().obfuscate(request.$1, fileName: request.$2);

/// Hands bytes to the system share sheet.
///
/// share_plus copies them into its own cache directory and exposes them
/// through its FileProvider, so nothing has to be written to app storage here.
/// The file name goes through [ShareParams.fileNameOverrides] because
/// `XFile.fromData(name:)` is ignored on Android/iOS (cross_file derives the
/// name from the empty path), which would otherwise share a random `.bin`.
Future<void> _share({
  required String title,
  required Uint8List bytes,
  required String fileName,
  required String? mimeType,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      title: '发送【$title】',
      files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
      fileNameOverrides: [fileName],
    ),
  );
}
