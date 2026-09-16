import 'package:flutter_test/flutter_test.dart';

import 'package:mogicians_manual/service/app_sharing.dart';

void main() {
  test('InstalledApp reads the Android map and rounds the size', () {
    final app = InstalledApp.fromMap({
      'versionName': '10.1.2',
      'fileName': '膜法指南-10.1.2.apk',
      'sizeBytes': 147077449,
      'splitInstall': false,
      'shareApps': [
        {
          'package': 'com.xiaomi.midrop',
          'label': 'ShareMe',
          'sendsApk': true,
          'sendsZip': false,
        },
      ],
      'apkReceivers': 2,
      'zipReceivers': 3,
    });
    expect(app.versionName, '10.1.2');
    expect(app.fileName, '膜法指南-10.1.2.apk');
    expect(app.sizeLabel, '140 MB');
    expect(app.splitInstall, isFalse);
    expect(app.shareApps.single.packageName, 'com.xiaomi.midrop');
    expect(app.shareApps.single.sendsApk, isTrue);
    expect(app.shareApps.single.sendsZip, isFalse);
    expect(app.apkReceivers, 2);
    expect(app.zipReceivers, 3);
  });

  test('the optional fields default to nothing installed', () {
    final app = InstalledApp.fromMap({
      'versionName': '1',
      'fileName': 'x.apk',
      'sizeBytes': 1,
      'splitInstall': true,
    });
    expect(app.shareApps, isEmpty);
    expect(app.apkReceivers, 0);
    expect(app.zipReceivers, 0);
  });

  test('the download page points at the latest GitHub release', () {
    expect(AppSharing.downloadPage.host, 'github.com');
    expect(AppSharing.downloadPage.path, endsWith('/releases/latest'));
  });
}
