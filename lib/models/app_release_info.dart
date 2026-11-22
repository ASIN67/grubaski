/// Model representing application release information stored in Supabase (`app_releases`)
/// or retrieved via GitHub Releases.
class AppReleaseInfo {
  final String? id;
  final String? platform;
  final String version;
  final int buildNumber;
  final String? releaseNotes;
  final String downloadUrl;
  final bool isMandatory;
  final DateTime publishedAt;
  final String? minSupportedVersion;

  AppReleaseInfo({
    this.id,
    this.platform,
    String? version,
    String? versionName,
    int? buildNumber,
    int? versionCode,
    String? releaseNotes,
    String? changelog,
    required this.downloadUrl,
    this.isMandatory = false,
    DateTime? publishedAt,
    this.minSupportedVersion,
  })  : version = version ?? versionName ?? '1.0.0',
        buildNumber = buildNumber ?? versionCode ?? 0,
        releaseNotes = releaseNotes ?? changelog,
        publishedAt = publishedAt ?? DateTime.now();

  /// Convenience getters for backwards compatibility / aliases
  String get versionName => version;
  int get versionCode => buildNumber;
  String? get changelog => releaseNotes;

  /// Factory constructing [AppReleaseInfo] from a JSON map (e.g. Supabase query).
  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['published_at'] ?? json['created_at'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    }

    final ver = json['version'] ?? json['version_name'];
    final bld = json['build_number'] ?? json['version_code'];
    final notes = json['release_notes'] ?? json['changelog'];
    final plat = json['platform']?.toString();

    return AppReleaseInfo(
      id: json['id']?.toString(),
      platform: plat,
      version: ver?.toString() ?? '1.0.0',
      buildNumber: (bld as num?)?.toInt() ?? 0,
      releaseNotes: notes?.toString(),
      downloadUrl: json['download_url'] as String? ?? '',
      isMandatory: json['is_mandatory'] as bool? ?? false,
      publishedAt: parsedDate,
      minSupportedVersion: json['min_supported_version'] as String?,
    );
  }

  /// Serializes instance into a JSON-compatible map for Supabase.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (platform != null) 'platform': platform,
      'version': version,
      'version_name': version,
      'build_number': buildNumber,
      'version_code': buildNumber,
      'release_notes': releaseNotes,
      'changelog': releaseNotes,
      'download_url': downloadUrl,
      'is_mandatory': isMandatory,
      'published_at': publishedAt.toIso8601String(),
      if (minSupportedVersion != null)
        'min_supported_version': minSupportedVersion,
    };
  }

  /// Checks if this release is newer than the given [currentVersion] and [currentBuildNumber].
  bool isNewerThan(String currentVersion, [int? currentBuildNumber]) {
    final cmp = compareSemver(version, currentVersion);
    if (cmp > 0) return true;
    if (cmp < 0) return false;

    // Versions are identical (e.g. 1.0.2 == 1.0.2).
    // Only return true if both build numbers are valid (> 0) and remote build is strictly greater.
    if (currentBuildNumber != null &&
        currentBuildNumber > 0 &&
        buildNumber > 0 &&
        buildNumber > currentBuildNumber) {
      return true;
    }
    return false;
  }

  /// Compares two Semantic Versioning strings (e.g., '1.1.0' vs '1.0.9').
  /// Returns 1 if v1 > v2, -1 if v1 < v2, and 0 if v1 == v2.
  static int compareSemver(String v1, String v2) {
    String clean(String v) {
      var s = v.trim().replaceFirst(RegExp(r'^[vV]'), '');
      if (s.contains('+')) {
        s = s.substring(0, s.indexOf('+')).trim();
      }
      if (s.contains('-')) {
        s = s.substring(0, s.indexOf('-')).trim();
      }
      return s;
    }

    final clean1 = clean(v1);
    final clean2 = clean(v2);

    final parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen =
        parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  @override
  String toString() =>
      'AppReleaseInfo(v$version+$buildNumber, mandatory: $isMandatory, url: $downloadUrl)';
}
