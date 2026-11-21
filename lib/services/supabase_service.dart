import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Centralized service managing Supabase client initialization, authentication lifecycle,
/// and safe offline fallback.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;

  /// Whether Supabase SDK has been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// Active Supabase client, or null if uninitialized or offline.
  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Whether a user is currently authenticated with Supabase.
  bool get isAuthenticated => client?.auth.currentUser != null;

  /// Currently authenticated Supabase user, or null if guest / offline.
  User? get currentUser => client?.auth.currentUser;

  /// Unique Supabase user id of currently signed-in user.
  String? get currentUserId => currentUser?.id;

  /// Email of currently signed-in user.
  String? get currentUserEmail => currentUser?.email;

  /// Reactive stream of authentication state changes.
  Stream<AuthState>? get authStateChanges =>
      _isInitialized ? client?.auth.onAuthStateChange : null;

  /// Initializes Supabase SDK safely.
  ///
  /// If credentials are missing, blank, or invalid, or if running in an offline
  /// environment, this method safely logs the status and returns without throwing.
  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint(
        'SupabaseService: Supabase URL or Anon Key not configured. Running in pure local/offline mode.',
      );
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('SupabaseService: Successfully initialized Supabase client.');
    } catch (e, stack) {
      _isInitialized = false;
      debugPrint('SupabaseService: Initialization failed ($e). Operating in offline mode.');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION METHODS
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException(
        'Brak połączenia z chmurą Supabase. Sprawdź połączenie z internetem.',
      );
    }

    return await c.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new user account with email, password, and optional metadata.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException(
        'Brak połączenia z chmurą Supabase. Sprawdź połączenie z internetem.',
      );
    }

    return await c.auth.signUp(
      email: email.trim(),
      password: password,
      data: data,
    );
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    final c = client;
    if (c != null && isAuthenticated) {
      await c.auth.signOut();
    }
  }

  /// Sends a password reset email to the specified address.
  Future<void> resetPasswordForEmail(String email) async {
    final c = client;
    if (c == null) {
      throw const AuthException(
        'Brak połączenia z chmurą Supabase. Sprawdź połączenie z internetem.',
      );
    }

    await c.auth.resetPasswordForEmail(email.trim());
  }

  // ---------------------------------------------------------------------------
  // TABLE QUERY BUILDERS
  // ---------------------------------------------------------------------------

  SupabaseQueryBuilder? get publicProductsTable =>
      client?.from('public_products');

  SupabaseQueryBuilder? get userProfilesTable =>
      client?.from('user_profiles');

  SupabaseQueryBuilder? get mealEntriesTable =>
      client?.from('meal_entries');

  SupabaseQueryBuilder? get dailyWaterLogsTable =>
      client?.from('daily_water_logs');

  SupabaseQueryBuilder? get weightEntriesTable =>
      client?.from('weight_entries');

  SupabaseQueryBuilder? get bodyMeasurementsTable =>
      client?.from('body_measurements_entries');
}
