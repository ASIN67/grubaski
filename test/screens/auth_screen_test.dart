import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:grubasek/screens/auth/forgot_password_sheet.dart';
import 'package:grubasek/screens/auth/login_screen.dart';
import 'package:grubasek/screens/auth/register_screen.dart';
import 'package:grubasek/screens/profile_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/app_theme.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('auth_test_');
    await HiveService.instance.init(customPath: tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Auth Screens Widget Tests', () {
    testWidgets('LoginScreen renders header, fields, and action buttons',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      expect(find.text('Witaj w Grubasku'), findsOneWidget);
      expect(find.text('Adres e-mail'), findsOneWidget);
      expect(find.text('Hasło'), findsOneWidget);
      expect(find.text('Nie pamiętasz hasła?'), findsOneWidget);
      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.text('Nie masz konta? Zarejestruj się'), findsOneWidget);
      expect(find.text('Kontynuuj w trybie gościa (offline)'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders fields and validation on empty submit',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Stwórz konto'), findsOneWidget);
      expect(find.text('Adres e-mail'), findsOneWidget);
      expect(find.text('Hasło'), findsOneWidget);
      expect(find.text('Powtórz hasło'), findsOneWidget);
      expect(find.text('Zarejestruj się'), findsOneWidget);

      await tester.tap(find.text('Zarejestruj się'));
      await tester.pumpAndSettle();

      expect(find.text('Podaj adres e-mail'), findsOneWidget);
      expect(find.text('Wpisz hasło'), findsOneWidget);
    });

    testWidgets('ForgotPasswordSheet renders instructions and input',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: ForgotPasswordSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Zresetuj hasło'), findsOneWidget);
      expect(find.text('Adres e-mail'), findsOneWidget);
      expect(find.text('Wyślij link resetujący'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders Account Card with guest mode button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Profil i ustawienia'), findsOneWidget);
      expect(find.text('Konto i chmura'), findsOneWidget);
      expect(find.text('Tryb gościa'), findsOneWidget);
      expect(find.text('Zaloguj / Zarejestruj się'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
