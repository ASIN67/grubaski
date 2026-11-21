import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_sync_service.dart';
import '../services/supabase_service.dart';

/// Authentication status representation.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

/// Cloud data synchronization status.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Immutable state containing user authentication and sync details.
class UserAuthState {
  final AuthStatus status;
  final User? user;
  final String? email;
  final String? errorMessage;
  final SyncStatus syncStatus;
  final DateTime? lastSyncTime;
  final String? syncErrorMessage;

  const UserAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.email,
    this.errorMessage,
    this.syncStatus = SyncStatus.idle,
    this.lastSyncTime,
    this.syncErrorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isLoading => status == AuthStatus.loading;

  bool get isSyncing => syncStatus == SyncStatus.syncing;

  UserAuthState copyWith({
    AuthStatus? status,
    User? Function()? user,
    String? Function()? email,
    String? Function()? errorMessage,
    SyncStatus? syncStatus,
    DateTime? Function()? lastSyncTime,
    String? Function()? syncErrorMessage,
  }) {
    return UserAuthState(
      status: status ?? this.status,
      user: user != null ? user() : this.user,
      email: email != null ? email() : this.email,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncTime: lastSyncTime != null ? lastSyncTime() : this.lastSyncTime,
      syncErrorMessage:
          syncErrorMessage != null ? syncErrorMessage() : this.syncErrorMessage,
    );
  }
}

/// Notifier managing authentication sessions, registration, login, and cloud sync trigger.
class AuthNotifier extends StateNotifier<UserAuthState> {
  final Ref ref;
  final SupabaseService _supabaseService;
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier(this.ref, {SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance,
        super(const UserAuthState()) {
    _init();
  }

  void _init() {
    try {
      DateTime? initialLastSync;
      try {
        initialLastSync = ref.read(cloudSyncServiceProvider).lastSyncTime;
      } catch (_) {}

      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => currentUser,
          email: () => currentUser.email,
          lastSyncTime: () => initialLastSync,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          lastSyncTime: () => initialLastSync,
        );
      }

      final stream = _supabaseService.authStateChanges;
      if (stream != null) {
        _authSubscription = stream.listen(
          (data) {
            final session = data.session;
            final user = session?.user;
            if (user != null) {
              state = state.copyWith(
                status: AuthStatus.authenticated,
                user: () => user,
                email: () => user.email,
                errorMessage: () => null,
              );
            } else {
              state = state.copyWith(
                status: AuthStatus.unauthenticated,
                user: () => null,
                email: () => null,
              );
            }
          },
          onError: (err) {
            debugPrint('AuthNotifier stream error: $err');
          },
        );
      }
    } catch (e) {
      debugPrint('AuthNotifier init error: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Logs in an existing user with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: () => null,
    );

    try {
      final response = await _supabaseService.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => user,
          email: () => user.email,
          errorMessage: () => null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: () =>
              'Nie udało się zalogować. Sprawdź wprowadzone dane.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => _mapAuthError(e.toString()),
      );
      return false;
    }
  }

  /// Registers a new user account with email and password.
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: () => null,
    );

    try {
      final response = await _supabaseService.signUp(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => user,
          email: () => user.email,
          errorMessage: () => null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: () => 'Rejestracja nie powiodła się. Spróbuj ponownie.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => _mapAuthError(e.toString()),
      );
      return false;
    }
  }

  /// Sends a password reset email.
  Future<bool> resetPassword({required String email}) async {
    try {
      await _supabaseService.resetPasswordForEmail(email.trim());
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        errorMessage: () => _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: () => _mapAuthError(e.toString()),
      );
      return false;
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      debugPrint('AuthNotifier signOut error: $e');
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: () => null,
      email: () => null,
      errorMessage: () => null,
      syncStatus: SyncStatus.idle,
      syncErrorMessage: () => null,
    );
  }

  /// Clears any transient error message.
  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }

  /// Triggers cloud synchronization between Hive and Supabase.
  Future<bool> syncData() async {
    if (!state.isAuthenticated) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        syncErrorMessage: () =>
            'Musisz być zalogowany, aby zsynchronizować dane z chmurą.',
      );
      return false;
    }

    state = state.copyWith(
      syncStatus: SyncStatus.syncing,
      syncErrorMessage: () => null,
    );

    try {
      final syncService = ref.read(cloudSyncServiceProvider);
      final result = await syncService.syncAll();

      if (result.success) {
        state = state.copyWith(
          syncStatus: SyncStatus.success,
          lastSyncTime: () => result.syncedAt,
          syncErrorMessage: () => null,
        );
        return true;
      } else {
        state = state.copyWith(
          syncStatus: SyncStatus.error,
          syncErrorMessage: () => result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        syncErrorMessage: () => 'Błąd synchronizacji: $e',
      );
      return false;
    }
  }

  /// Translates raw auth error messages into user-friendly Polish text.
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Nieprawidłowy adres e-mail lub hasło.';
    } else if (lower.contains('user already registered') ||
        lower.contains('already in use') ||
        lower.contains('already registered')) {
      return 'Konto z tym adresem e-mail już istnieje.';
    } else if (lower.contains('password should be at least')) {
      return 'Hasło musi zawierać co najmniej 6 znaków.';
    } else if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Zbyt wiele prób w krótkim czasie. Odczekaj chwilę.';
    } else if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('połączenia')) {
      return 'Brak połączenia z siecią. Sprawdź swoje połączenie z internetem.';
    } else if (lower.contains('invalid email')) {
      return 'Nieprawidłowy format adresu e-mail.';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for user authentication and cloud sync status.
final authProvider =
    StateNotifierProvider<AuthNotifier, UserAuthState>((ref) {
  return AuthNotifier(ref);
});
