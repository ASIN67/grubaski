/// Centralized configuration for Supabase backend.
///
/// Supports production defaults, runtime values via `--dart-define`,
/// and dynamic programmatic overrides for testing.
class SupabaseConfig {
  SupabaseConfig._();

  /// Default production Supabase credentials.
  static const String defaultUrl = 'https://wyrgagwstoscxhstyzmf.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5cmdhZ3dzdG9zY3hoc3R5em1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUyODY0OTQsImV4cCI6MjExMDg2MjQ5NH0.6YpZwvQf1Fnc9EANFJF_UmkiwwjGxZDx818oBf399Bw';
  static const String defaultPublishableKey =
      'sb_publishable_TtKL4UCc33OqvWkomEDUpQ_RwvrDPPY';

  /// Environment variables passed via --dart-define.
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _envPublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // Mutable overrides for dynamic testing or settings
  static String? _customUrl;
  static String? _customAnonKey;
  static String? _customPublishableKey;

  /// Active Supabase Project URL.
  static String get url {
    if (_customUrl != null) return _customUrl!;
    if (_envUrl.isNotEmpty) return _envUrl;
    return defaultUrl;
  }

  /// Active Supabase Anonymous public API Key.
  static String get anonKey {
    if (_customAnonKey != null) return _customAnonKey!;
    if (_envAnonKey.isNotEmpty) return _envAnonKey;
    return defaultAnonKey;
  }

  /// Active Supabase modern Publishable Key.
  static String get publishableKey {
    if (_customPublishableKey != null) return _customPublishableKey!;
    if (_envPublishableKey.isNotEmpty) return _envPublishableKey;
    return defaultPublishableKey;
  }

  /// Allows setting credentials programmatically at runtime.
  static void configure({
    required String url,
    required String anonKey,
    String? publishableKey,
  }) {
    _customUrl = url.trim();
    _customAnonKey = anonKey.trim();
    if (publishableKey != null) {
      _customPublishableKey = publishableKey.trim();
    }
  }

  /// Resets custom overrides back to production / environment defaults.
  static void reset() {
    _customUrl = null;
    _customAnonKey = null;
    _customPublishableKey = null;
  }

  /// Disables configuration for testing offline or unconfigured behavior.
  static void clearForTesting() {
    _customUrl = '';
    _customAnonKey = '';
    _customPublishableKey = '';
  }

  /// Whether Supabase credentials are validly populated.
  static bool get isConfigured {
    final activeUrl = url.trim();
    final activeKey = anonKey.trim();
    if (activeUrl.isEmpty || activeKey.isEmpty) return false;
    final uri = Uri.tryParse(activeUrl);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }
}
