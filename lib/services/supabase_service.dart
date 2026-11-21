import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hive_service.dart';
import 'supabase_config.dart';

/// Pure Dart Hive-backed session storage for Supabase.
/// Bypasses native platform channels (shared_preferences) and operates consistently
/// across Web (IndexedDB), iOS (Safari PWA & native), Android, Windows, and macOS,
/// preventing MissingPluginException completely.
class HiveSupabaseLocalStorage extends LocalStorage {
  const HiveSupabaseLocalStorage();

  static const String _sessionKey = 'supabase_auth_persisted_session';

  Box<dynamic> get _box => HiveService.instance.settingsBox;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return _box.containsKey(_sessionKey);
  }

  @override
  Future<String?> accessToken() async {
    final dynamic val = _box.get(_sessionKey);
    if (val is String && val.isNotEmpty) {
      return val;
    }
    return null;
  }

  @override
  Future<void> removePersistedSession() async {
    await _box.delete(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _box.put(_sessionKey, persistSessionString);
  }
}

/// Pure Dart Hive-backed Gotrue PKCE async storage to eliminate all native channel dependencies.
class HiveGotrueAsyncStorage extends GotrueAsyncStorage {
  const HiveGotrueAsyncStorage();

  static const String _prefix = 'supabase_pkce_';
  Box<dynamic> get _box => HiveService.instance.settingsBox;

  @override
  Future<String?> getItem({required String key}) async {
    final dynamic val = _box.get('$_prefix$key');
    if (val is String && val.isNotEmpty) {
      return val;
    }
    return null;
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _box.put('$_prefix$key', value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _box.delete('$_prefix$key');
  }
}

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
        authOptions: const FlutterAuthClientOptions(
          localStorage: HiveSupabaseLocalStorage(),
          pkceAsyncStorage: HiveGotrueAsyncStorage(),
        ),
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

  /// Verifies a sign-up email confirmation code (OTP).
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException(
        'Brak połączenia z chmurą Supabase. Sprawdź połączenie z internetem.',
      );
    }

    return await c.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
    );
  }

  /// Resends a sign-up verification OTP email.
  Future<ResendResponse> resendSignUpOtp({
    required String email,
  }) async {
    final c = client;
    if (c == null) {
      throw const AuthException(
        'Brak połączenia z chmurą Supabase. Sprawdź połączenie z internetem.',
      );
    }

    return await c.auth.resend(
      email: email.trim(),
      type: OtpType.signup,
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
