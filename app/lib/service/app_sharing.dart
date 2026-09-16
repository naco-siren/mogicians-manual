import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How the installer is handed over: the APK itself, or wrapped in a ZIP for
/// receivers that refuse .apk files (Bluetooth) or rename them (微信 / QQ).
enum ShareFormat { apk, zip }

/// A phone-to-phone transfer app found on this phone.
class ShareApp {
  const ShareApp({
    required this.packageName,
    required this.label,
    required this.sendsApk,
    required this.sendsZip,
  });

  factory ShareApp.fromMap(Map<Object?, Object?> map) => ShareApp(
    packageName: map['package'] as String,
    label: map['label'] as String,
    sendsApk: map['sendsApk'] as bool,
    sendsZip: map['sendsZip'] as bool,
  );

  final String packageName;
  final String label;

  /// Whether the app takes an .apk straight from the share sheet; if not, it
  /// can still be opened and asked to send an installed app itself.
  final bool sendsApk;
  final bool sendsZip;
}

/// The copy of this app installed on the phone, as reported by Android.
class InstalledApp {
  const InstalledApp({
    required this.versionName,
    required this.fileName,
    required this.sizeBytes,
    required this.splitInstall,
    this.shareApps = const [],
    this.apkReceivers = 0,
    this.zipReceivers = 0,
  });

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
    versionName: map['versionName'] as String,
    fileName: map['fileName'] as String,
    sizeBytes: (map['sizeBytes'] as num).toInt(),
    splitInstall: map['splitInstall'] as bool,
    shareApps: [
      for (final app in (map['shareApps'] as List<Object?>? ?? const []))
        ShareApp.fromMap(app! as Map<Object?, Object?>),
    ],
    apkReceivers: (map['apkReceivers'] as num?)?.toInt() ?? 0,
    zipReceivers: (map['zipReceivers'] as num?)?.toInt() ?? 0,
  );

  final String versionName;

  /// The name the receiver sees, e.g. `膜法指南-10.1.2.apk`.
  final String fileName;
  final int sizeBytes;

  /// True when Google Play installed this copy as base + configuration
  /// splits: its base.apk cannot be installed on its own, so it must not be
  /// shared. Builds ship without configuration splits now, so this only
  /// applies to installs that predate that and have not been updated since.
  final bool splitInstall;

  /// Transfer apps installed on this phone, best first.
  final List<ShareApp> shareApps;

  /// How many apps would appear in the share sheet for an .apk / a .zip.
  final int apkReceivers;
  final int zipReceivers;

  String get sizeLabel => '${(sizeBytes / (1024 * 1024)).round()} MB';
}

/// Hands this app's own installer to another phone, so that people without
/// Google Play can be given the app. Android only; the Kotlin side is
/// android/app/src/main/kotlin/com/example/app/AppSharing.kt.
class AppSharing {
  AppSharing._();

  static const channel = MethodChannel('mogicians_manual/app_sharing');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Where a copy that cannot be shared directly can be downloaded instead.
  static final Uri downloadPage = Uri.parse(
    'https://github.com/naco-siren/mogicians-manual/releases/latest',
  );

  static Future<InstalledApp> describe() async {
    final map = await channel.invokeMethod<Map<Object?, Object?>>('describe');
    return InstalledApp.fromMap(map!);
  }

  /// Sends the installer: through the system share sheet, or straight to
  /// [packageName] when given. A ZIP is built first when needed, which takes
  /// a few seconds on an old phone.
  static Future<void> share({
    required ShareFormat format,
    String? packageName,
  }) => channel.invokeMethod<void>('share', {
    'format': format.name,
    'package': packageName,
  });

  /// Opens a transfer app so the user can pick this app inside it.
  static Future<void> open(String packageName) =>
      channel.invokeMethod<void>('open', {'package': packageName});
}
