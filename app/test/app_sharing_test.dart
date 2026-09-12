import 'package:flutter_test/flutter_test.dart';

import 'package:mogicians_manual/service/app_sharing.dart';

void main() {
  test('InstalledApp reads the Android map and rounds the size', () {
    final app = InstalledApp.fromMap({
      'versionName': '10.1.2',
      'fileName': '膜法指南-10.1.2.apk',
      'sizeBytes': 147077449,
      'splitInstall': false,
    });
    expect(app.versionName, '10.1.2');
    expect(app.fileName, '膜法指南-10.1.2.apk');
    expect(app.sizeLabel, '140 MB');
    expect(app.splitInstall, isFalse);
  });

  test('the download page points at the latest GitHub release', () {
    expect(AppSharing.downloadPage.host, 'github.com');
    expect(AppSharing.downloadPage.path, endsWith('/releases/latest'));
  });
}
