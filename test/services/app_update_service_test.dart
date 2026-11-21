import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/app_release_info.dart';
import 'package:grubasek/services/app_update_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AppReleaseInfo Model Tests', () {
    test('fromJson correctly parses release record from Supabase', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'platform': 'android',
        'version': '1.0.1',
        'build_number': 2,
        'download_url': 'https://grubasek.pages.dev/download/grubasek.apk',
        'release_notes': 'Nowe funkcje i poprawki błędów',
        'is_mandatory': true,
        'published_at': '2026-11-21T20:00:00.000Z',
      };

      final release = AppReleaseInfo.fromJson(json);

      expect(release.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(release.platform, 'android');
      expect(release.version, '1.0.1');
      expect(release.versionName, '1.0.1');
      expect(release.buildNumber, 2);
      expect(release.versionCode, 2);
      expect(release.downloadUrl,
          'https://grubasek.pages.dev/download/grubasek.apk');
      expect(release.releaseNotes, 'Nowe funkcje i poprawki błędów');
      expect(release.changelog, 'Nowe funkcje i poprawki błędów');
      expect(release.isMandatory, isTrue);
      expect(release.publishedAt.year, 2026);
    });

    test('toJson produces valid serializable map', () {
      final release = AppReleaseInfo(
        id: 'test-id',
        platform: 'android',
        version: '1.0.0',
        buildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Init',
        isMandatory: false,
        publishedAt: DateTime(2026, 11, 21),
      );

      final map = release.toJson();
      expect(map['build_number'], 1);
      expect(map['version_code'], 1);
      expect(map['version'], '1.0.0');
      expect(map['version_name'], '1.0.0');
      expect(map['platform'], 'android');
      expect(map['is_mandatory'], isFalse);
    });

    test('SemVer comparison correctly determines newer versions', () {
      expect(AppReleaseInfo.compareSemver('1.0.1', '1.0.0'), greaterThan(0));
      expect(AppReleaseInfo.compareSemver('1.1.0', '1.0.9'), greaterThan(0));
      expect(AppReleaseInfo.compareSemver('2.0.0', '1.9.9'), greaterThan(0));
      expect(AppReleaseInfo.compareSemver('1.0.0', '1.0.0'), equals(0));
      expect(AppReleaseInfo.compareSemver('1.0.0', '1.0.1'), lessThan(0));
    });

    test('isNewerThan checks version and buildNumber', () {
      final release = AppReleaseInfo(
        version: '1.0.1',
        buildNumber: 2,
        downloadUrl: 'https://example.com',
      );

      expect(release.isNewerThan('1.0.0', 1), isTrue);
      expect(release.isNewerThan('1.0.1', 1), isTrue);
      expect(release.isNewerThan('1.0.1', 2), isFalse);
      expect(release.isNewerThan('1.0.2', 3), isFalse);
    });
  });

  group('AppUpdateService Platform & Version Tests', () {
    test('getCurrentPlatformName returns valid platform string', () {
      final platform = AppUpdateService.instance.getCurrentPlatformName();
      expect(platform, isNotEmpty);
    });

    test('getCurrentVersionInfo returns fallback without throwing', () async {
      final local = await AppUpdateService.instance.getCurrentVersionInfo();
      expect(local.version, isNotEmpty);
      expect(local.buildNumber, greaterThanOrEqualTo(1));
    });

    test('getLocalVersion returns compatible tuple', () async {
      final local = await AppUpdateService.instance.getLocalVersion();
      expect(local.versionName, isNotEmpty);
      expect(local.versionCode, greaterThanOrEqualTo(1));
    });
  });
}
