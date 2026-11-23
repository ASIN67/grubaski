import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/default_food_database.dart';
import '../models/models.dart';

/// Centralized service managing Hive local database lifecycle,
/// manual TypeAdapter registration, typed Box accessors, and
/// automatic default product database seeding and version migrations.
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  // Box identifier constants
  static const String userProfileBoxName = 'user_profile_box';
  static const String foodProductsBoxName = 'food_products_box';
  static const String mealEntriesBoxName = 'meal_entries_box';
  static const String waterLogsBoxName = 'water_logs_box';
  static const String weightEntriesBoxName = 'weight_entries_box';
  static const String bodyMeasurementsEntriesBoxName =
      'body_measurements_entries_box';
  static const String settingsBoxName = 'settings_box';

  // Settings keys for database versioning and seeding
  static const String foodDatabaseVersionKey = 'food_database_version';
  static const String foodDatabaseSeededKey = 'food_database_seeded_v6';
  static const String foodDatabaseSeededV5Key = 'food_database_seeded_v5';
  static const String foodDatabaseSeededV4Key = 'food_database_seeded_v4';
  static const String foodDatabaseSeededV3Key = 'food_database_seeded_v3';
  static const String foodDatabaseSeededV2Key = 'food_database_seeded_v2';
  static const String foodDatabaseSeededV1Key = 'food_database_seeded_v1';
  static const int currentFoodDatabaseVersion = 6;

  /// Returns current food database version stored in settingsBox (or 0 if unseeded).
  int get currentDatabaseVersion {
    final v = settingsBox.get(foodDatabaseVersionKey);
    if (v is int) return v;
    if (settingsBox.get(foodDatabaseSeededKey) == true) return 6;
    if (settingsBox.get(foodDatabaseSeededV5Key) == true) return 5;
    if (settingsBox.get(foodDatabaseSeededV4Key) == true) return 4;
    if (settingsBox.get(foodDatabaseSeededV3Key) == true) return 3;
    if (settingsBox.get(foodDatabaseSeededV2Key) == true) return 2;
    if (settingsBox.get(foodDatabaseSeededV1Key) == true) return 1;
    return 0;
  }

  /// Initializes Hive for Flutter, registers all TypeAdapters, opens all
  /// application boxes, and seeds default food products if needed.
  ///
  /// An optional [customPath] can be passed (e.g. in test environments).
  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }

    registerAdapters();

    // Open all required typed boxes concurrently
    await Future.wait([
      _openBoxIfNotOpen<UserProfile>(userProfileBoxName),
      _openBoxIfNotOpen<FoodProduct>(foodProductsBoxName),
      _openBoxIfNotOpen<MealEntry>(mealEntriesBoxName),
      _openBoxIfNotOpen<DailyWaterLog>(waterLogsBoxName),
      _openBoxIfNotOpen<WeightEntry>(weightEntriesBoxName),
      _openBoxIfNotOpen<BodyMeasurementsEntry>(bodyMeasurementsEntriesBoxName),
      _openBoxIfNotOpen<dynamic>(settingsBoxName),
    ]);

    // Automatically seed default food products on first launch or migrate to latest version
    await seedDefaultProducts();

    debugPrint('HiveService initialized successfully. All boxes open.');
  }

  Future<Box<T>> _openBoxIfNotOpen<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }

  /// Seeds default food products into [foodProductsBox] or performs a non-destructive
  /// migration if updating to a newer database version (e.g. v2 with 900+ items).
  ///
  /// If [force] is false:
  /// - If [settingsBox] indicates v2 is already seeded and [foodProductsBox] is not empty, does nothing.
  /// - If [foodProductsBox] is empty, performs a fresh complete seed.
  /// - If existing products are present (migration scenario, e.g. from v1), safely inserts only newly
  ///   added products from [defaultFoodProducts] without overwriting existing entries, user favorites,
  ///   or custom products.
  ///
  /// If [force] is true:
  /// - Re-seeds/updates all [defaultFoodProducts] while preserving user favorite flags.
  Future<void> seedDefaultProducts({bool force = false}) async {
    final int version = currentDatabaseVersion;
    final bool isAlreadySeededV2 =
        version >= currentFoodDatabaseVersion &&
        settingsBox.get(foodDatabaseSeededKey) == true;

    if (!force && isAlreadySeededV2 && foodProductsBox.isNotEmpty) {
      return;
    }

    // Fresh install or completely empty box: seed everything
    if (foodProductsBox.isEmpty) {
      final entries = <String, FoodProduct>{
        for (final product in defaultFoodProducts) product.id: product,
      };
      if (entries.isNotEmpty) {
        await foodProductsBox.putAll(entries);
      }
      await settingsBox.put(foodDatabaseVersionKey, currentFoodDatabaseVersion);
      await settingsBox.put(foodDatabaseSeededKey, true);
      debugPrint(
        'HiveService: Freshly seeded ${entries.length} default food products (v$currentFoodDatabaseVersion).',
      );
      return;
    }

    // Force reseed: update default products while preserving favorites and custom items
    if (force) {
      final entries = <String, FoodProduct>{
        for (final product in defaultFoodProducts)
          product.id: () {
            final existing = foodProductsBox.get(product.id);
            if (existing != null && existing.isFavorite) {
              return product.copyWith(isFavorite: true);
            }
            return product;
          }(),
      };
      if (entries.isNotEmpty) {
        await foodProductsBox.putAll(entries);
      }
      await settingsBox.put(foodDatabaseVersionKey, currentFoodDatabaseVersion);
      await settingsBox.put(foodDatabaseSeededKey, true);
      debugPrint(
        'HiveService: Force reseeded ${entries.length} default food products (v$currentFoodDatabaseVersion).',
      );
      return;
    }

    // Migration scenario (version < 2 or unseeded v2 with existing products):
    // Only insert new products that are not yet in foodProductsBox
    final newEntries = <String, FoodProduct>{};
    for (final product in defaultFoodProducts) {
      if (!foodProductsBox.containsKey(product.id)) {
        newEntries[product.id] = product;
      }
    }

    if (newEntries.isNotEmpty) {
      await foodProductsBox.putAll(newEntries);
    }
    await settingsBox.put(foodDatabaseVersionKey, currentFoodDatabaseVersion);
    await settingsBox.put(foodDatabaseSeededKey, true);
    debugPrint(
      'HiveService: Migrated food database to v$currentFoodDatabaseVersion. Added ${newEntries.length} new products (Total in box: ${foodProductsBox.length}).',
    );
  }

  /// Registers all manual TypeAdapters required by the app.
  void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FoodProductAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MealEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(DailyWaterLogAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(WeightEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(BodyMeasurementsEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RecipeIngredientAdapter());
    }
  }

  // Typed Box Getters
  Box<UserProfile> get userProfileBox =>
      Hive.box<UserProfile>(userProfileBoxName);

  Box<FoodProduct> get foodProductsBox =>
      Hive.box<FoodProduct>(foodProductsBoxName);

  Box<MealEntry> get mealEntriesBox => Hive.box<MealEntry>(mealEntriesBoxName);

  Box<DailyWaterLog> get waterLogsBox =>
      Hive.box<DailyWaterLog>(waterLogsBoxName);

  Box<WeightEntry> get weightEntriesBox =>
      Hive.box<WeightEntry>(weightEntriesBoxName);

  Box<BodyMeasurementsEntry> get bodyMeasurementsEntriesBox =>
      Hive.box<BodyMeasurementsEntry>(bodyMeasurementsEntriesBoxName);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);

  /// Clears all stored data (e.g. on profile reset).
  ///
  /// If [reseedDefaults] is true, repopulates the default food database
  /// so that the product catalog remains functional immediately after reset.
  Future<void> clearAllData({bool reseedDefaults = true}) async {
    await Future.wait([
      userProfileBox.clear(),
      foodProductsBox.clear(),
      mealEntriesBox.clear(),
      waterLogsBox.clear(),
      weightEntriesBox.clear(),
      bodyMeasurementsEntriesBox.clear(),
      settingsBox.clear(),
    ]);

    if (reseedDefaults) {
      await seedDefaultProducts(force: true);
    }
  }
}
