import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
/// and external download/installation triggering.
class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService();
  final SupabaseService _supabaseService;

  AppUpdateService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  /// Retrieves local platform version details using [PackageInfo].
  ///
  /// Falls back to safe defaults ('1.0.0', 1) in test environments or on unsupported platforms.
  Future<({String version, int buildNumber})> getCurrentVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.1';
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 2;
      return (version: version, buildNumber: buildNumber);
    } catch (e) {
      debugPrint('AppUpdateService: PackageInfo.fromPlatform fallback ($e)');
      return (version: '1.0.1', buildNumber: 2);
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
    String currentVersion = currentVersionOverride ?? '1.0.0';
    int currentBuildNumber = currentBuildOverride ?? 1;

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
      // Query the latest release ordered by published_at or created_at descending
      final response = await client
          .from('app_releases')
          .select()
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
      if (release.minSupportedVersion != null && release.minSupportedVersion!.isNotEmpty) {
        if (AppReleaseInfo.compareSemver(release.minSupportedVersion!, currentVersion) > 0) {
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

  /// Launches the download URL (e.g. GitHub release APK or https://grubasek.pages.dev/)
  /// in the external system browser or package installer.
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
