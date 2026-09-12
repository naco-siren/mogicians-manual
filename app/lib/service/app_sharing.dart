import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The copy of this app installed on the phone, as reported by Android.
class InstalledApp {
  const InstalledApp({
    required this.versionName,
    required this.fileName,
    required this.sizeBytes,
    required this.splitInstall,
  });

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
    versionName: map['versionName'] as String,
    fileName: map['fileName'] as String,
    sizeBytes: (map['sizeBytes'] as num).toInt(),
    splitInstall: map['splitInstall'] as bool,
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

  String get sizeLabel => '${(sizeBytes / (1024 * 1024)).round()} MB';
}

/// Hands this app's own installer to the system share sheet, so that people
/// without Google Play can be given the app phone to phone. Android only;
/// the Kotlin side is android/app/src/main/kotlin/com/example/app/AppSharing.kt.
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

  /// Opens the share sheet with the installed APK attached.
  static Future<void> share() => channel.invokeMethod<void>('share');
}
