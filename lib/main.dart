import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/theme_provider.dart';
import 'repositories/product_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/hive_service.dart';
import 'services/supabase_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER_ERROR: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A161B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFB7185).withOpacity(0.5),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFB7185),
              size: 18,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Wystąpił błąd wyświetlania elementu',
                style: TextStyle(
                  color: Color(0xFFF5F3FA),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  };

  // 1. Initialize Polish locale date formatting for intl
  await initializeDateFormatting('pl_PL', null);

  // 2. Initialize local Hive database and open all boxes
  await HiveService.instance.init();

  // 3. Initialize Supabase cloud service (safe offline fallback if unconfigured)
  await SupabaseService.instance.init();

  // 4. Background push of any local custom products to shared Supabase catalog
  ProductRepository().syncLocalCustomProducts();

  // 5. Check if user has already completed onboarding
  final userRepository = UserRepository();
  final bool isOnboardingCompleted = userRepository.hasProfile;

  runApp(
    ProviderScope(
      child: GrubasekApp(
        isOnboardingCompleted: isOnboardingCompleted,
      ),
    ),
  );
}

/// Root Application Widget for Grubasek.
class GrubasekApp extends ConsumerWidget {
  final bool isOnboardingCompleted;

  const GrubasekApp({
    super.key,
    required this.isOnboardingCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Grubasek',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('pl', 'PL'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl', 'PL'),
        Locale('en', 'US'),
      ],
      home: isOnboardingCompleted
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
    );
  }
}
