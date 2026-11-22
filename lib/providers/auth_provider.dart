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

/// Result of an account registration attempt.
enum SignUpStatus {
  signedIn,
  needsEmailConfirmation,
  failed,
}

/// Details returned from an account registration call.
class SignUpResult {
  final SignUpStatus status;
  final String? message;
  final String? email;

  const SignUpResult({
    required this.status,
    this.message,
    this.email,
  });

  bool get isSuccess =>
      status == SignUpStatus.signedIn ||
      status == SignUpStatus.needsEmailConfirmation;
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
  final String? pendingConfirmationEmail;

  const UserAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.email,
    this.errorMessage,
    this.syncStatus = SyncStatus.idle,
    this.lastSyncTime,
    this.syncErrorMessage,
    this.pendingConfirmationEmail,
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
    String? Function()? pendingConfirmationEmail,
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
      pendingConfirmationEmail: pendingConfirmationEmail != null
          ? pendingConfirmationEmail()
          : this.pendingConfirmationEmail,
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
  /// If email confirmation is enabled on Supabase, returns [SignUpStatus.needsEmailConfirmation].
  Future<SignUpResult> signUp({
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
      final session = response.session;

      if (session != null && user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => user,
          email: () => user.email,
          pendingConfirmationEmail: () => null,
          errorMessage: () => null,
        );
        return const SignUpResult(
          status: SignUpStatus.signedIn,
          message: 'Konto utworzone pomyślnie! Zalogowano.',
        );
      } else if (user != null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          pendingConfirmationEmail: () => email.trim(),
          errorMessage: () => null,
        );
        return SignUpResult(
          status: SignUpStatus.needsEmailConfirmation,
          email: email.trim(),
          message:
              'Wysłaliśmy 6-cyfrowy kod potwierdzający na adres ${email.trim()}. Wpisz go, aby aktywować konto.',
        );
      } else {
        const msg = 'Rejestracja nie powiodła się. Spróbuj ponownie.';
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: () => msg,
        );
        return const SignUpResult(
          status: SignUpStatus.failed,
          message: msg,
        );
      }
    } on AuthException catch (e) {
      final msg = _mapAuthError(e.message);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => msg,
      );
      return SignUpResult(
        status: SignUpStatus.failed,
        message: msg,
      );
    } catch (e) {
      final msg = _mapAuthError(e.toString());
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => msg,
      );
      return SignUpResult(
        status: SignUpStatus.failed,
        message: msg,
      );
    }
  }

  /// Verifies the 6-digit email confirmation code (OTP) for the specified account.
  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: () => null,
    );

    try {
      final response = await _supabaseService.verifyEmailOtp(
        email: email.trim(),
        token: token.trim(),
      );

      final user = response.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => user,
          email: () => user.email,
          pendingConfirmationEmail: () => null,
          errorMessage: () => null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: () =>
              'Nie udało się zweryfikować kodu. Spróbuj ponownie.',
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

  /// Resends the sign-up verification OTP code to the user's email.
  Future<bool> resendSignUpOtp({required String email}) async {
    try {
      await _supabaseService.resendSignUpOtp(email: email.trim());
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

  /// Sets or clears the pending confirmation email.
  void setPendingConfirmationEmail(String? email) {
    state = state.copyWith(
      pendingConfirmationEmail: () => email?.trim(),
    );
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
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'Adres e-mail nie został jeszcze potwierdzony. Wpisz kod przesłany na Twoją pocztę.';
    } else if (lower.contains('token has expired') ||
        lower.contains('token is expired') ||
        lower.contains('otp expired') ||
        lower.contains('expired token')) {
      return 'Kod weryfikacyjny wygasł. Poproś o nowy kod.';
    } else if (lower.contains('invalid token') ||
        lower.contains('token is invalid') ||
        lower.contains('otp invalid') ||
        lower.contains('invalid otp')) {
      return 'Nieprawidłowy kod weryfikacyjny. Sprawdź i wpisz 6 cyfr ponownie.';
    } else if (lower.contains('missingpluginexception')) {
      return 'Wystąpił problem ze sterownikiem pamięci podręcznej. Zresetuj aplikację.';
    } else if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Nieprawidłowy adres e-mail lub hasło.';
    } else if (lower.contains('user already registered') ||
        lower.contains('already in use') ||
        lower.contains('already registered')) {
      return 'Konto z tym adresem e-mail już istnieje.';
    } else if (lower.contains('password should be at least')) {
      return 'Hasło musi zawierać co najmniej 6 znaków.';
    } else if (lower.contains('over_email_send_rate_limit') ||
        lower.contains('email rate limit') ||
        lower.contains('rate limit') ||
        lower.contains('too many requests')) {
      return 'Zbyt wiele prób wysyłania e-maili w chmurze (limit darmowego Supabase: 3 maile/godz.). Odczekaj chwilę lub wyłącz "Confirm email" w panelu Supabase.';
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
