import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/service/toast_util.dart';
import 'package:mogicians_manual/utils/image_obfuscator.dart';

/// The share in progress, if any. Obfuscating a large meme takes a second or
/// more on an old phone, and a second long-press in that time must not start
/// a second share: share_plus would complete the first one as "unavailable"
/// and clear its cache folder underneath the first chooser.
Future<void>? _inFlight;

/// Shares a meme as a freshly obfuscated copy (see [ImageObfuscator]), so the
/// file a messaging app receives is never byte- or pixel-identical to the
/// bundled asset or to any previous share of it. Never throws; failures are
/// logged and reported with a toast.
Future<void> shareImage(ImageItem item) {
  final pending = _inFlight;
  if (pending != null) return pending;
  final run = _shareImage(item);
  _inFlight = run.whenComplete(() => _inFlight = null);
  return run;
}

Future<void> _shareImage(ImageItem item) async {
  // Only say something when the obfuscating is slow enough to be noticed.
  final notice = Timer(const Duration(milliseconds: 400), () {
    showAppToast('正在生成新的图片…');
  });
  try {
    final data = await rootBundle.load(item.path);
    final original = Uint8List.sublistView(data);
    ObfuscatedImage obfuscated;
    try {
      obfuscated = await compute(_obfuscateForShare, (original, item.src));
    } on Object catch (error, stack) {
      // Better an unobfuscated meme than none at all.
      debugPrint('shareImage: obfuscating ${item.src} failed: $error\n$stack');
      obfuscated = ObfuscatedImage(
        original,
        fileName: item.src,
        mimeType: null,
      );
    }
    notice.cancel();
    await _share(
      title: item.title,
      bytes: obfuscated.bytes,
      fileName: obfuscated.fileName,
      mimeType: obfuscated.mimeType,
    );
  } on Object catch (error, stack) {
    debugPrint('shareImage: ${item.src} failed: $error\n$stack');
    showAppToast('分享失败');
  } finally {
    notice.cancel();
  }
}

Future<void> shareDocument(DocumentItem item) async {
  try {
    final data = await rootBundle.load(item.path);
    await _share(
      title: item.title,
      bytes: Uint8List.sublistView(data),
      fileName: '${item.title}.pdf',
      mimeType: 'application/pdf',
    );
  } on Object catch (error, stack) {
    debugPrint('shareDocument: ${item.src} failed: $error\n$stack');
    showAppToast('分享失败');
  }
}

/// Runs in a background isolate: decoding and re-encoding a large JPEG takes
/// a good fraction of a second on older phones.
ObfuscatedImage _obfuscateForShare((Uint8List, String) request) =>
    ImageObfuscator().obfuscate(request.$1, fileName: request.$2);

/// Hands bytes to the system share sheet.
///
/// The file is written to one fixed place per name (overwritten by the next
/// share of the same item) and handed over by path: share_plus copies it into
/// its own cache folder, which it clears on the next share, and exposes that
/// copy through its FileProvider. `XFile.fromData` would instead leave a new
/// uuid-named temp file behind on every share.
Future<void> _share({
  required String title,
  required Uint8List bytes,
  required String fileName,
  required String? mimeType,
}) async {
  final directory = Directory(
    '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}share',
  );
  await directory.create(recursive: true);
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      title: '发送【$title】',
      files: [XFile(file.path, mimeType: mimeType)],
    ),
  );
}
