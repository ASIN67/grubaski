import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/app_release_info.dart';
import 'package:grubasek/utils/app_theme.dart';
import 'package:grubasek/widgets/update_prompt_dialog.dart';

void main() {
  group('UpdatePromptDialog Widget Tests', () {
    testWidgets('renders version name, changelog, and action buttons',
        (tester) async {
      final release = AppReleaseInfo(
        id: 'rel-1',
        platform: 'android',
        versionName: '1.2.0',
        versionCode: 3,
        downloadUrl: 'https://grubasek.pages.dev/download/grubasek.apk',
        changelog: '1. Dodano bazę 900+ produktów\n2. Dodano synchronizację chmurową',
        isMandatory: false,
        publishedAt: DateTime(2026, 11, 21),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: UpdatePromptDialog(release: release),
          ),
        ),
      );

      expect(find.text('Nowa wersja!'), findsOneWidget);
      expect(find.text('vv1.2.0'), findsNothing);
      expect(find.text('v1.2.0'), findsOneWidget);
      expect(find.text('Co nowego w tej aktualizacji:'), findsOneWidget);
      expect(find.textContaining('Dodano bazę 900+ produktów'), findsOneWidget);
      expect(find.text('Pobierz i zaktualizuj aplikację'), findsOneWidget);
      expect(find.text('Przypomnij mi później'), findsOneWidget);
    });

    testWidgets('mandatory update hides dismiss button', (tester) async {
      final release = AppReleaseInfo(
        id: 'rel-2',
        platform: 'android',
        versionName: '2.0.0',
        versionCode: 4,
        downloadUrl: 'https://grubasek.pages.dev/download/grubasek.apk',
        changelog: 'Krytyczna aktualizacja bezpieczeństwa',
        isMandatory: true,
        publishedAt: DateTime(2026, 11, 21),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: UpdatePromptDialog(release: release),
          ),
        ),
      );

      expect(find.text('Przypomnij mi później'), findsNothing);
      expect(find.text('Pobierz i zaktualizuj aplikację'), findsOneWidget);
    });
  });
}
