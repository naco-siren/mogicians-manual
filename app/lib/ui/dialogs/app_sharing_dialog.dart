import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mogicians_manual/service/app_sharing.dart';
import 'package:mogicians_manual/service/toast_util.dart';

/// "分享安装包": hands the installed APK to another phone. Three situations:
///
/// * a phone-to-phone transfer app is installed: offer to send through it
///   (or to open it), which is what works best on Chinese phones;
/// * none is: suggest installing one, and offer the raw .apk or a .zip
///   wrapper through the system share sheet, each checked for receivers;
/// * Google Play installed this copy in pieces: it cannot be shared as a
///   file, so offer the download page instead.
Future<void> showAppSharingDialog(BuildContext context) async {
  final InstalledApp app;
  try {
    app = await AppSharing.describe();
  } on Object catch (error, stack) {
    debugPrint('showAppSharingDialog: $error\n$stack');
    showAppToast('读不到安装包信息');
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) {
      if (app.splitInstall) return _DownloadPageDialog(app);
      if (app.shareApps.isNotEmpty) return _TransferAppsDialog(app);
      return _FileDialog(app);
    },
  );
}

const _receiverTips =
    '对方那边：系统会要求允许"安装未知应用"；'
    '小米 / OPPO / vivo 可能提示"未备案"或"风险应用"；'
    '新款华为（HarmonyOS NEXT）装不了任何 APK。';

Future<void> _run(Future<void> Function() action, String failure) async {
  try {
    await action();
  } on Object catch (error, stack) {
    debugPrint('showAppSharingDialog: $error\n$stack');
    showAppToast(failure);
  }
}

class _TransferAppsDialog extends StatelessWidget {
  const _TransferAppsDialog(this.app);

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('分享安装包'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '这台手机上装了能面对面传文件的应用，用它发最省事'
              '（对方也要装同一个，收到后点开就能安装）：',
            ),
            const SizedBox(height: 12),
            for (final transfer in app.shareApps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.pop(context);
                    if (transfer.sendsApk || transfer.sendsZip) {
                      if (!transfer.sendsApk) showAppToast('正在打包 ZIP…');
                      _run(
                        () => AppSharing.share(
                          format: transfer.sendsApk
                              ? ShareFormat.apk
                              : ShareFormat.zip,
                          packageName: transfer.packageName,
                        ),
                        '打不开 ${transfer.label}',
                      );
                    } else {
                      _run(
                        () => AppSharing.open(transfer.packageName),
                        '打不开 ${transfer.label}',
                      );
                    }
                  },
                  child: Text(
                    transfer.sendsApk
                        ? '用 ${transfer.label} 发送'
                        : transfer.sendsZip
                        ? '用 ${transfer.label} 发送 ZIP'
                        : '打开 ${transfer.label}',
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '文件：${app.fileName}（约 ${app.sizeLabel}）'
              '${app.shareApps.any((a) => !a.sendsApk && !a.sendsZip) ? '\n"打开"的应用收不了外来文件，打开后在它里面选"应用"，找到膜法指南发送。' : ''}'
              '\n\n$_receiverTips',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showDialog<void>(
              context: context,
              builder: (context) => _FileDialog(app),
            );
          },
          child: const Text('其他方式'),
        ),
      ],
    );
  }
}

class _FileDialog extends StatelessWidget {
  const _FileDialog(this.app);

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('分享安装包'),
      content: SingleChildScrollView(
        child: Text(
          '${app.shareApps.isEmpty ? '这台手机上没有装面对面传文件的应用。建议先装一个'
                    '（例如小米的 ShareMe、快牙、LocalSend；对方也要装），'
                    '或者直接把文件发出去：' : '不经过传文件应用，直接把文件发出去：'}\n\n'
          '• APK：原样发送 ${app.fileName}（约 ${app.sizeLabel}）。'
          'QQ 收到后文件名会多一个 .1，对方去掉 .1 再安装\n'
          '• ZIP：打包成 zip 再发。蓝牙也肯收，QQ 不会改名，'
          '对方解压出 .apk 再安装\n\n'
          '$_receiverTips',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (app.apkReceivers == 0) {
              showAppToast('这台手机上没有能接收 APK 文件的应用，装个 QQ 或 LocalSend 再试');
              return;
            }
            Navigator.pop(context);
            _run(() => AppSharing.share(format: ShareFormat.apk), '分享失败');
          },
          child: const Text('发送 APK'),
        ),
        TextButton(
          onPressed: () {
            if (app.zipReceivers == 0) {
              showAppToast('这台手机上没有能接收 ZIP 文件的应用');
              return;
            }
            Navigator.pop(context);
            showAppToast('正在打包 ZIP…');
            _run(() => AppSharing.share(format: ShareFormat.zip), '打包失败');
          },
          child: const Text('发送 ZIP'),
        ),
      ],
    );
  }
}

class _DownloadPageDialog extends StatelessWidget {
  const _DownloadPageDialog(this.app);

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('暂时无法直接分享'),
      content: Text(
        '这份膜法指南 ${app.versionName} 是 Google Play 分块安装的，'
        '单独发出去的文件装不上。可以把下载页面发给对方，'
        '或者等这台手机更新到下一个版本后再试。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final opened = await launchUrl(
              AppSharing.downloadPage,
              mode: LaunchMode.externalApplication,
            );
            if (!opened) showAppToast('打不开下载页');
          },
          child: const Text('打开下载页'),
        ),
      ],
    );
  }
}
