import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grubasek/providers/auth_provider.dart';
import 'package:grubasek/services/hive_service.dart';

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
  });
}
