import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_release_info.dart';
import 'supabase_service.dart';

/// Encapsulates the outcome of an update check.
class UpdateCheckResult {
  final bool hasUpdate;
  final AppReleaseInfo? latestRelease;
  final String currentVersion;
  final int currentBuildNumber;
  final bool isMandatory;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestRelease,
    required this.currentVersion,
    this.currentBuildNumber = 0,
    this.isMandatory = false,
    this.errorMessage,
  });

  @override
  String toString() =>
      'UpdateCheckResult(hasUpdate: $hasUpdate, current: v$currentVersion+$currentBuildNumber, latest: ${latestRelease?.version}, mandatory: $isMandatory)';
}

/// Service managing remote version checks, Supabase `app_releases` queries,
/// in-app direct APK downloads, and native Android installation triggering.
class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService();
  final SupabaseService _supabaseService;

  static const MethodChannel _installerChannel =
      MethodChannel('com.example.grubasek/apk_installer');

  AppUpdateService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  /// Retrieves local platform version details using [PackageInfo].
  ///
  /// Falls back to safe defaults ('1.0.2', 3) in test environments or on unsupported platforms.
  Future<({String version, int buildNumber})> getCurrentVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version =
          packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.6';
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 7;
      return (version: version, buildNumber: buildNumber);
    } catch (e) {
      debugPrint('AppUpdateService: PackageInfo.fromPlatform fallback ($e)');
      return (version: '1.0.6', buildNumber: 7);
    }
  }

  /// Returns the current platform name ('android', 'ios', 'web', 'windows', etc.)
  String getCurrentPlatformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Returns local version info compatible with `({String versionName, int versionCode})`
  Future<({String versionName, int versionCode})> getLocalVersion() async {
    final info = await getCurrentVersionInfo();
    return (versionName: info.version, versionCode: info.buildNumber);
  }

  /// Queries Supabase for the latest published release and determines if an update is available.
  Future<UpdateCheckResult> checkForUpdate({
    String? currentVersionOverride,
    int? currentBuildOverride,
  }) async {
    String currentVersion = currentVersionOverride ?? '1.0.3';
    int currentBuildNumber = currentBuildOverride ?? 4;

    if (currentVersionOverride == null || currentBuildOverride == null) {
      final info = await getCurrentVersionInfo();
      currentVersion = currentVersionOverride ?? info.version;
      currentBuildNumber = currentBuildOverride ?? info.buildNumber;
    }

    final client = _supabaseService.client;
    if (client == null) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        errorMessage: 'Brak aktywnego połączenia z chmurą Supabase.',
      );
    }

    try {
      final currentPlatform = getCurrentPlatformName();

      // Query the latest release matching current platform and marked active
      final response = await client
          .from('app_releases')
          .select()
          .eq('platform', currentPlatform)
          .eq('is_active', true)
          .order('published_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
        );
      }

      final release = AppReleaseInfo.fromJson(response);
      final isNewer = release.isNewerThan(currentVersion, currentBuildNumber);

      // Determine if update is mandatory (flagged or current version below minSupportedVersion)
      bool isMandatory = release.isMandatory;
      if (release.minSupportedVersion != null &&
          release.minSupportedVersion!.isNotEmpty) {
        if (AppReleaseInfo.compareSemver(
                release.minSupportedVersion!, currentVersion) >
            0) {
          isMandatory = true;
        }
      }

      return UpdateCheckResult(
        hasUpdate: isNewer,
        latestRelease: release,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        isMandatory: isMandatory && isNewer,
      );
    } catch (e) {
      debugPrint('AppUpdateService: checkForUpdate error ($e)');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        errorMessage: 'Nie udało się sprawdzić aktualizacji: $e',
      );
    }
  }

  /// Downloads the APK file to local cache with live progress callback.
  Future<String?> downloadApkWithProgress({
    required String downloadUrl,
    required String targetVersion,
    required void Function(int received, int total, double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final cleanVer =
          targetVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = 'grubasek_update_$cleanVer.apk';
      final savePath = '${tempDir.path}/$fileName';

      // Delete existing partial/old file if present
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? (received / total) : 0.0;
          onProgress(received, total, progress);
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );

      if (await file.exists() && await file.length() > 0) {
        return savePath;
      }
      return null;
    } catch (e) {
      debugPrint('AppUpdateService: downloadApkWithProgress error ($e)');
      return null;
    }
  }

  /// Triggers Android's native package installer for the given [apkFilePath].
  Future<({bool success, String? error, bool permissionRequired})> installApk(
      String apkFilePath) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return (
        success: false,
        error: 'System nie obsługuje bezpośredniej instalacji pakietów APK.',
        permissionRequired: false
      );
    }

    try {
      final bool? result = await _installerChannel.invokeMethod<bool>(
        'installApk',
        {'filePath': apkFilePath},
      );
      return (
        success: result ?? false,
        error: null,
        permissionRequired: false
      );
    } on PlatformException catch (e) {
      debugPrint('AppUpdateService: installApk PlatformException ($e)');
      final isPermission = e.code == 'PERMISSION_REQUIRED';
      return (
        success: false,
        error: e.message,
        permissionRequired: isPermission
      );
    } catch (e) {
      debugPrint('AppUpdateService: installApk error ($e)');
      return (
        success: false,
        error: e.toString(),
        permissionRequired: false
      );
    }
  }

  /// Opens the system settings screen to allow installing unknown apps.
  Future<void> openInstallSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _installerChannel.invokeMethod('openInstallSettings');
    } catch (e) {
      debugPrint('AppUpdateService: openInstallSettings error ($e)');
    }
  }

  /// Fallback: Launches the download URL in the external system browser.
  Future<bool> launchDownload(String downloadUrl) async {
    final cleanUrl = downloadUrl.trim();
    if (cleanUrl.isEmpty) {
      debugPrint('AppUpdateService: Download URL is empty');
      return false;
    }

    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) {
      debugPrint('AppUpdateService: Invalid download URI ($cleanUrl)');
      return false;
    }

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('AppUpdateService: Error launching URL ($cleanUrl): $e');
      return false;
    }
  }
}

/// Global provider for [AppUpdateService].
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});
