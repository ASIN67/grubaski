import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/services/supabase_config.dart';
import 'package:grubasek/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() {
    SupabaseConfig.clearForTesting();
  });

  tearDown(() {
    SupabaseConfig.reset();
  });

  group('SupabaseConfig Tests', () {
    test('isConfigured returns false when URL or anonKey are empty', () {
      SupabaseConfig.clearForTesting();
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('isConfigured returns true for valid URL and anonKey', () {
      SupabaseConfig.configure(
        url: 'https://xyzcompany.supabase.co',
        anonKey: 'sample-anon-key-12345',
      );

      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.url, 'https://xyzcompany.supabase.co');
      expect(SupabaseConfig.anonKey, 'sample-anon-key-12345');
    });

    test('isConfigured returns false for invalid URL', () {
      SupabaseConfig.configure(
        url: 'invalid-url',
        anonKey: 'sample-anon-key-12345',
      );

      expect(SupabaseConfig.isConfigured, isFalse);
    });
  });

  group('SupabaseService Tests', () {
    test('init() handles unconfigured environment gracefully without throwing', () async {
      SupabaseConfig.clearForTesting();
      final service = SupabaseService.instance;

      await service.init();

      expect(service.isInitialized, isFalse);
      expect(service.client, isNull);
      expect(service.isAuthenticated, isFalse);
      expect(service.currentUser, isNull);
      expect(service.currentUserId, isNull);
      expect(service.currentUserEmail, isNull);
      expect(service.publicProductsTable, isNull);
    });

    test('Auth methods throw AuthException when offline or uninitialized', () async {
      SupabaseConfig.clearForTesting();
      final service = SupabaseService.instance;
      await service.init();

      expect(
        () => service.signInWithPassword(email: 'test@example.com', password: 'secret'),
        throwsA(isA<AuthException>()),
      );

      expect(
        () => service.signUp(email: 'test@example.com', password: 'secret'),
        throwsA(isA<AuthException>()),
      );

      expect(
        () => service.resetPasswordForEmail('test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut completes silently when not authenticated', () async {
      final service = SupabaseService.instance;
      expect(() async => await service.signOut(), returnsNormally);
    });
  });
}
