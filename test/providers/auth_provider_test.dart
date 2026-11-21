import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grubasek/providers/auth_provider.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/services/supabase_service.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('auth_provider_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveService.settingsBoxName);
  });

  group('AuthProvider State & Methods Tests', () {
    test('initial state defaults to unauthenticated or offline', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.user, isNull);
      expect(state.email, isNull);
    });

    test('clearError resets error message to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      notifier.clearError();

      final state = container.read(authProvider);
      expect(state.errorMessage, isNull);
    });

    test('signOut sets status to unauthenticated and clears user', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.signOut();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.email, isNull);
    });

    test('syncData returns false and sets error when unauthenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.syncData();

      expect(result, isFalse);
      final state = container.read(authProvider);
      expect(state.syncStatus, SyncStatus.error);
      expect(state.syncErrorMessage, contains('zalogowany'));
    });

    test('HiveSupabaseLocalStorage persists and removes session without platform channels', () async {
      const storage = HiveSupabaseLocalStorage();
      await storage.initialize();

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);

      await storage.persistSession('test-token-string-12345');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), 'test-token-string-12345');

      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });

    test('HiveGotrueAsyncStorage persists and removes PKCE keys without platform channels', () async {
      const storage = HiveGotrueAsyncStorage();

      expect(await storage.getItem(key: 'code_verifier'), isNull);

      await storage.setItem(key: 'code_verifier', value: 'secret_verifier_abc');
      expect(await storage.getItem(key: 'code_verifier'), 'secret_verifier_abc');

      await storage.removeItem(key: 'code_verifier');
      expect(await storage.getItem(key: 'code_verifier'), isNull);
    });

    test('setPendingConfirmationEmail updates state properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      expect(container.read(authProvider).pendingConfirmationEmail, isNull);

      notifier.setPendingConfirmationEmail('user@test.com');
      expect(container.read(authProvider).pendingConfirmationEmail, 'user@test.com');

      notifier.setPendingConfirmationEmail(null);
      expect(container.read(authProvider).pendingConfirmationEmail, isNull);
    });
  });
}
