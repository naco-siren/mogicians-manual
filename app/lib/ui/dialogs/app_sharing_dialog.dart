import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mogicians_manual/service/app_sharing.dart';
import 'package:mogicians_manual/service/toast_util.dart';

/// "分享安装包": explains what is about to be sent, then hands the installed
/// APK to the share sheet. A copy that Google Play installed in pieces cannot
/// be shared as a file, so that case offers the download page instead.
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
    builder: (context) => app.splitInstall
        ? _DownloadPageDialog(app)
        : _ShareInstallerDialog(app),
  );
}

class _ShareInstallerDialog extends StatelessWidget {
  const _ShareInstallerDialog(this.app);

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('分享安装包'),
      content: SingleChildScrollView(
        child: Text(
          '把这台手机上装好的膜法指南 ${app.versionName}'
          '（${app.fileName}，约 ${app.sizeLabel}）原样发给别人，'
          '对方不需要 Google Play 也能安装。\n\n'
          '对方那边：\n'
          '• 微信 / QQ 收到的文件名会多一个 .1，改回 .apk 再安装\n'
          '• 系统会要求允许"安装未知应用"\n'
          '• 小米 / OPPO / vivo 可能提示"未备案"或"风险应用"\n'
          '• 新款华为（HarmonyOS NEXT）装不了任何 APK',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await AppSharing.share();
            } on Object catch (error, stack) {
              debugPrint('AppSharing.share: $error\n$stack');
              showAppToast('分享失败');
            }
          },
          child: const Text('分享'),
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
