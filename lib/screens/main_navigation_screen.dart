import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_type.dart';
import '../services/app_update_service.dart';
import '../widgets/update_prompt_dialog.dart';
import 'add_product_screen.dart';
import 'diary_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';

/// Keeps each primary tab mounted while switching between destinations.
class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesQuietly();
    });
  }

  Future<void> _checkForUpdatesQuietly() async {
    try {
      final result = await AppUpdateService.instance.checkForUpdate();
      if (result.hasUpdate && result.latestRelease != null && mounted) {
        await UpdatePromptDialog.show(context, release: result.latestRelease!);
      }
    } catch (e) {
      debugPrint('MainNavigation: Silent update check failed ($e)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DiaryScreen(),
          AddProductScreen(initialMealType: MealType.breakfast),
          const ProgressScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                label: 'Dziennik',
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
              ),
              NavigationDestination(
                label: 'Dodaj / Skanuj',
                icon: Icon(Icons.add_circle_outline_rounded),
                selectedIcon: Icon(Icons.add_circle_rounded),
              ),
              NavigationDestination(
                label: 'Postępy',
                icon: Icon(Icons.trending_up_rounded),
                selectedIcon: Icon(Icons.insights_rounded),
              ),
              NavigationDestination(
                label: 'Profil',
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
