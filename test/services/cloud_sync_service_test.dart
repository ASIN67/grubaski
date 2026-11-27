import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/diary_repository.dart';
import 'package:grubasek/repositories/product_repository.dart';
import 'package:grubasek/repositories/weight_repository.dart';
import 'package:grubasek/services/cloud_sync_service.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/services/supabase_service.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final hive = HiveService.instance;
  final supabase = SupabaseService.instance;
  late Directory tempDir;
  late CloudSyncService syncService;
  late ProductRepository productRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cloud_sync_test_');
    Hive.init(tempDir.path);
    hive.registerAdapters();

    await Hive.openBox<UserProfile>(HiveService.userProfileBoxName);
    await Hive.openBox<FoodProduct>(HiveService.foodProductsBoxName);
    await Hive.openBox<MealEntry>(HiveService.mealEntriesBoxName);
    await Hive.openBox<DailyWaterLog>(HiveService.waterLogsBoxName);
    await Hive.openBox<WeightEntry>(HiveService.weightEntriesBoxName);
    await Hive.openBox<BodyMeasurementsEntry>(
        HiveService.bodyMeasurementsEntriesBoxName);
    await Hive.openBox<dynamic>(HiveService.settingsBoxName);

    syncService = CloudSyncService(
      hiveService: hive,
      supabaseService: supabase,
    );
    productRepository = ProductRepository(
      hiveService: hive,
      supabaseService: supabase,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await hive.userProfileBox.clear();
    await hive.foodProductsBox.clear();
    await hive.mealEntriesBox.clear();
    await hive.waterLogsBox.clear();
    await hive.weightEntriesBox.clear();
    await hive.bodyMeasurementsEntriesBox.clear();
    await hive.settingsBox.clear();
  });

  group('CloudSyncService - Unauthenticated and Offline handling', () {
    test('returns clear error when user is not authenticated without throwing',
        () async {
      expect(syncService.isSyncing, isFalse);
      expect(syncService.lastSyncTime, isNull);

      final result = await syncService.syncAll();

      expect(result.success, isFalse);
      expect(result.message, contains('Zaloguj się'));
      expect(syncService.isSyncing, isFalse);
    });

    test('persists lastSyncTime upon setting in settingsBox', () async {
      final sampleTime = DateTime(2026, 11, 21, 15, 30);
      await hive.settingsBox.put(
        CloudSyncService.lastSyncTimestampKey,
        sampleTime.toIso8601String(),
      );

      expect(syncService.lastSyncTime, equals(sampleTime));
    });
  });

  group('ProductRepository - Supabase Integration Offline Safety', () {
    test(
        'createCustomProduct saves to Hive and attempts background upload safely without throwing',
        () async {
      final product = await productRepository.createCustomProduct(
        name: 'Domowy chleb żytni',
        brand: 'Wypiek własny',
        caloriesPer100g: 220,
        proteinPer100g: 6.5,
        carbsPer100g: 45,
        fatPer100g: 1.5,
        servingSizeGrams: 40,
        servingName: '1 kromka (40g)',
      );

      expect(product.id, isNotEmpty);
      expect(product.isCustom, isTrue);

      // Verify product is immediately saved to local Hive storage
      final stored = productRepository.getProductById(product.id);
      expect(stored, isNotNull);
      expect(stored!.name, equals('Domowy chleb żytni'));
      expect(stored.brand, equals('Wypiek własny'));
    });

    test(
        'searchProducts falls back gracefully to local Hive when remote Supabase/OFF is offline',
        () async {
      await productRepository.saveProduct(
        const FoodProduct(
          id: 'test_product_offline_unique',
          name: 'Unikalny Kefir Malina',
          brand: 'Pilos Test',
          caloriesPer100g: 45,
          proteinPer100g: 3.5,
          carbsPer100g: 4.0,
          fatPer100g: 1.5,
        ),
      );

      final results = await productRepository.searchProducts(
        'Unikalny Kefir',
        includeRemote: true,
      );

      expect(results, isNotEmpty);
      expect(results.first.name, equals('Unikalny Kefir Malina'));
    });
  });

  group('CloudSyncService - Custom Product Privacy Filter', () {
    test('syncCustomProducts excludes recipes and AI items from public upload',
        () async {
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      final ingredient = const FoodProduct(
        id: 'ing_1',
        name: 'Banan',
        caloriesPer100g: 89,
        proteinPer100g: 1.1,
        carbsPer100g: 23,
        fatPer100g: 0.3,
      );

      await hive.foodProductsBox.putAll({
        'custom_1': const FoodProduct(
          id: 'custom_1',
          name: 'Mój domowy chleb',
          brand: 'Domowy',
          caloriesPer100g: 240,
          proteinPer100g: 7,
          carbsPer100g: 46,
          fatPer100g: 2,
          isCustom: true,
        ),
        'recipe_1': FoodProduct(
          id: 'custom_recipe_by_ingredients',
          name: 'Naleśniki',
          caloriesPer100g: 300,
          proteinPer100g: 10,
          carbsPer100g: 40,
          fatPer100g: 10,
          isCustom: true,
          recipeIngredients: [
            RecipeIngredient(product: ingredient, grams: 100),
          ],
        ),
        'recipe_prefix': const FoodProduct(
          id: 'recipe_123',
          name: 'Zupa',
          caloriesPer100g: 120,
          proteinPer100g: 4,
          carbsPer100g: 15,
          fatPer100g: 4,
          isCustom: true,
        ),
        'ai_prefix': const FoodProduct(
          id: 'ai_999',
          name: 'Kurczak z ryżem',
          caloriesPer100g: 150,
          proteinPer100g: 15,
          carbsPer100g: 18,
          fatPer100g: 2,
          isCustom: true,
        ),
        'ai_oszacowanie': const FoodProduct(
          id: 'uuid_ai_1',
          name: 'Owsianka',
          brand: 'AI Oszacowanie',
          caloriesPer100g: 140,
          proteinPer100g: 5,
          carbsPer100g: 22,
          fatPer100g: 3,
          isCustom: true,
        ),
        'ai_finisher': const FoodProduct(
          id: 'uuid_ai_2',
          name: 'Omlet',
          brand: 'AI Dokończ moje makro',
          caloriesPer100g: 180,
          proteinPer100g: 14,
          carbsPer100g: 4,
          fatPer100g: 12,
          isCustom: true,
        ),
        'ai_brand_prefix': const FoodProduct(
          id: 'uuid_ai_3',
          name: 'Sałatka',
          brand: 'AI Generator',
          caloriesPer100g: 90,
          proteinPer100g: 4,
          carbsPer100g: 8,
          fatPer100g: 5,
          isCustom: true,
        ),
        'przepis_brand': const FoodProduct(
          id: 'uuid_przepis',
          name: 'Zapiekanka',
          brand: 'Przepis',
          caloriesPer100g: 200,
          proteinPer100g: 10,
          carbsPer100g: 20,
          fatPer100g: 8,
          isCustom: true,
        ),
        'sparkle_name': const FoodProduct(
          id: 'uuid_sparkle',
          name: '✨ Koktajl białkowy',
          caloriesPer100g: 110,
          proteinPer100g: 18,
          carbsPer100g: 6,
          fatPer100g: 1,
          isCustom: true,
        ),
      });

      final counts = await customSync.syncCustomProducts('user-1');

      expect(counts.uploaded, equals(1));
      expect(fakeSupabase.publicProducts.rows, hasLength(1));
      expect(fakeSupabase.publicProducts.rows.first['id'], equals('custom_1'));
    });
  });

  group('CloudSyncService - Deletion Tombstones & Resurrection Prevention',
      () {
    test(
        'DiaryRepository records deleted IDs and syncMealEntries deletes them remotely before download',
        () async {
      final diaryRepo = DiaryRepository(hiveService: hive);
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      const apple = FoodProduct(
        id: 'apple',
        name: 'Jabłko',
        caloriesPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
      );

      final entry1 = MealEntry(
        id: 'meal-1',
        dateKey: '2026-11-27',
        mealType: MealType.breakfast,
        grams: 150,
        product: apple,
      );
      await diaryRepo.saveEntry(entry1);

      // Remote already has both meal-1 and meal-2
      fakeSupabase.mealEntries.rows.addAll([
        {
          'id': 'meal-1',
          'user_id': 'user-1',
          'date_key': '2026-11-27',
          'meal_type': 'breakfast',
          'grams': 150,
          'product_snapshot': {'id': 'apple', 'name': 'Jabłko'},
        },
        {
          'id': 'meal-2',
          'user_id': 'user-1',
          'date_key': '2026-11-27',
          'meal_type': 'lunch',
          'grams': 200,
          'product_snapshot': {'id': 'apple', 'name': 'Jabłko'},
        },
      ]);

      await diaryRepo.deleteEntry('meal-1');
      expect(
        hive.settingsBox.get(DiaryRepository.deletedMealEntryIdsKey),
        contains('meal-1'),
      );

      final counts = await customSync.syncMealEntries('user-1');

      expect(counts.downloaded, equals(1));
      expect(hive.mealEntriesBox.containsKey('meal-1'), isFalse);
      expect(hive.mealEntriesBox.containsKey('meal-2'), isTrue);
      expect(
        hive.settingsBox.get(DiaryRepository.deletedMealEntryIdsKey),
        isNull,
      );
      expect(fakeSupabase.mealEntries.operations.first, startsWith('delete:'));
    });

    test(
        'WeightRepository records deleted IDs and syncWeightEntries deletes them remotely before download',
        () async {
      final weightRepo = WeightRepository(hiveService: hive);
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      final w1 = WeightEntry(
        id: 'weight-1',
        date: DateTime(2026, 11, 26),
        weightKg: 80.5,
      );
      await weightRepo.saveWeightEntry(w1);

      fakeSupabase.weightEntries.rows.addAll([
        {
          'id': 'weight-1',
          'user_id': 'user-1',
          'date': DateTime(2026, 11, 26).toUtc().toIso8601String(),
          'weight_kg': 80.5,
        },
        {
          'id': 'weight-2',
          'user_id': 'user-1',
          'date': DateTime(2026, 11, 27).toUtc().toIso8601String(),
          'weight_kg': 80.1,
        },
      ]);

      await weightRepo.deleteWeightEntry('weight-1');
      expect(
        hive.settingsBox.get(WeightRepository.deletedWeightEntryIdsKey),
        contains('weight-1'),
      );

      final counts = await customSync.syncWeightEntries('user-1');

      expect(counts.downloaded, equals(1));
      expect(hive.weightEntriesBox.containsKey('weight-1'), isFalse);
      expect(hive.weightEntriesBox.containsKey('weight-2'), isTrue);
      expect(
        hive.settingsBox.get(WeightRepository.deletedWeightEntryIdsKey),
        isNull,
      );
      expect(fakeSupabase.weightEntries.operations.first, startsWith('delete:'));
    });

    test('preserves pending tombstones if remote delete fails', () async {
      final diaryRepo = DiaryRepository(hiveService: hive);
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      fakeSupabase.mealEntries.state.throwOnDelete = true;
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      await diaryRepo.deleteEntry('meal-failed-delete');

      await expectLater(
        () => customSync.syncMealEntries('user-1'),
        throwsException,
      );

      expect(
        hive.settingsBox.get(DiaryRepository.deletedMealEntryIdsKey),
        contains('meal-failed-delete'),
      );
    });
  });

  group('CloudSyncService - User Profile Overwrite Protection', () {
    UserProfile makeProfile({
      required int dailyCaloriesGoal,
      double startWeightKg = 80.0,
    }) {
      return UserProfile(
        gender: Gender.male,
        age: 30,
        startWeightKg: startWeightKg,
        targetWeightKg: 75.0,
        heightCm: 180.0,
        activityLevel: ActivityLevel.moderate,
        goal: WeightGoal.reduction,
        dailyCaloriesGoal: dailyCaloriesGoal,
        proteinGoalGrams: 160,
        carbsGoalGrams: 220,
        fatGoalGrams: 70,
        waterGoalMl: 2500,
      );
    }

    Map<String, dynamic> makeRemoteProfileRow({
      required String userId,
      required int dailyCaloriesGoal,
      required String updatedAtIso,
    }) {
      return {
        'user_id': userId,
        'gender': 'male',
        'age': 30,
        'start_weight_kg': 82.0,
        'target_weight_kg': 75.0,
        'height_cm': 180.0,
        'activity_level': 'moderate',
        'goal': 'reduction',
        'weekly_pace_kg': 0.5,
        'daily_calories_goal': dailyCaloriesGoal,
        'protein_goal_grams': 160,
        'carbs_goal_grams': 220,
        'fat_goal_grams': 70,
        'water_goal_ml': 2500,
        'updated_at': updatedAtIso,
      };
    }

    test(
        'fresh device never synced before does not overwrite existing cloud profile',
        () async {
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      // Local onboarding profile created before signing in (no lastSync, no user_profile_updated_at)
      await hive.userProfileBox.put(
        CloudSyncService.userProfileHiveKey,
        makeProfile(dailyCaloriesGoal: 2000),
      );

      // Existing real profile in Supabase
      fakeSupabase.userProfiles.rows.add(
        makeRemoteProfileRow(
          userId: 'user-1',
          dailyCaloriesGoal: 2450,
          updatedAtIso: '2026-11-20T10:00:00.000Z',
        ),
      );

      final counts = await customSync.syncUserProfile('user-1');

      expect(counts.downloaded, equals(1));
      expect(counts.uploaded, equals(0));
      final stored =
          hive.userProfileBox.get(CloudSyncService.userProfileHiveKey);
      expect(stored, isNotNull);
      expect(stored!.dailyCaloriesGoal, equals(2450));
      expect(fakeSupabase.userProfiles.upsertCount, equals(0));
      expect(
        hive.settingsBox.get(CloudSyncService.userProfileUpdatedAtKey),
        equals('2026-11-20T10:00:00.000Z'),
      );
    });

    test('pulls newer remote profile when remote updated_at is newer than lastSync',
        () async {
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      await hive.userProfileBox.put(
        CloudSyncService.userProfileHiveKey,
        makeProfile(dailyCaloriesGoal: 2000),
      );
      await hive.settingsBox.put(
        CloudSyncService.lastSyncTimestampKey,
        '2026-11-20T10:00:00.000Z',
      );
      await hive.settingsBox.put(
        CloudSyncService.userProfileUpdatedAtKey,
        '2026-11-20T10:00:00.000Z',
      );

      fakeSupabase.userProfiles.rows.add(
        makeRemoteProfileRow(
          userId: 'user-1',
          dailyCaloriesGoal: 2600,
          updatedAtIso: '2026-11-21T12:00:00.000Z',
        ),
      );

      final counts = await customSync.syncUserProfile('user-1');

      expect(counts.downloaded, equals(1));
      expect(counts.uploaded, equals(0));
      expect(
        hive.userProfileBox
            .get(CloudSyncService.userProfileHiveKey)!
            .dailyCaloriesGoal,
        equals(2600),
      );
    });

    test('pushes local profile when local update is newer than remote',
        () async {
      final fakeSupabase = _FakeSupabaseService(userId: 'user-1');
      final customSync = CloudSyncService(
        hiveService: hive,
        supabaseService: fakeSupabase,
      );

      await hive.userProfileBox.put(
        CloudSyncService.userProfileHiveKey,
        makeProfile(dailyCaloriesGoal: 2150),
      );
      await hive.settingsBox.put(
        CloudSyncService.lastSyncTimestampKey,
        '2026-11-21T12:00:00.000Z',
      );
      await hive.settingsBox.put(
        CloudSyncService.userProfileUpdatedAtKey,
        '2026-11-22T09:00:00.000Z',
      );

      fakeSupabase.userProfiles.rows.add(
        makeRemoteProfileRow(
          userId: 'user-1',
          dailyCaloriesGoal: 1900,
          updatedAtIso: '2026-11-20T10:00:00.000Z',
        ),
      );

      final counts = await customSync.syncUserProfile('user-1');

      expect(counts.uploaded, equals(1));
      expect(counts.downloaded, equals(0));
      expect(fakeSupabase.userProfiles.upsertCount, equals(1));
      expect(
        fakeSupabase.userProfiles.rows.first['daily_calories_goal'],
        equals(2150),
      );
    });
  });
}

class _FakeSupabaseService extends Fake implements SupabaseService {
  final String userId;
  final _FakeTable userProfiles = _FakeTable(conflictKey: 'user_id');
  final _FakeTable dailyWaterLogs = _FakeTable(conflictKey: 'date_key');
  final _FakeTable weightEntries = _FakeTable();
  final _FakeTable bodyMeasurements = _FakeTable();
  final _FakeTable mealEntries = _FakeTable();
  final _FakeTable publicProducts = _FakeTable();

  _FakeSupabaseService({required this.userId});

  @override
  bool get isAuthenticated => true;

  @override
  String? get currentUserId => userId;

  @override
  SupabaseQueryBuilder? get userProfilesTable => userProfiles;

  @override
  SupabaseQueryBuilder? get dailyWaterLogsTable => dailyWaterLogs;

  @override
  SupabaseQueryBuilder? get weightEntriesTable => weightEntries;

  @override
  SupabaseQueryBuilder? get bodyMeasurementsTable => bodyMeasurements;

  @override
  SupabaseQueryBuilder? get mealEntriesTable => mealEntries;

  @override
  SupabaseQueryBuilder? get publicProductsTable => publicProducts;
}

class _TableState {
  int upsertCount = 0;
  bool throwOnDelete = false;
}

class _FakeTable extends Fake implements SupabaseQueryBuilder {
  final String conflictKey;
  final List<Map<String, dynamic>> rows = [];
  final List<String> operations = [];
  final _TableState state = _TableState();

  int get upsertCount => state.upsertCount;

  _FakeTable({this.conflictKey = 'id'});

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeFilterBuilder<PostgrestList>(
      execute: (filters) async {
        operations.add('select');
        return _applyFilters(filters).map((r) => Map<String, dynamic>.from(r)).toList();
      },
      onMaybeSingle: (filters) async {
        operations.add('select_maybeSingle');
        final matched = _applyFilters(filters);
        return matched.isEmpty ? null : Map<String, dynamic>.from(matched.first);
      },
    );
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return _FakeFilterBuilder<dynamic>(
      execute: (_) async {
        operations.add('upsert');
        state.upsertCount++;
        final list = values is List
            ? values.cast<Map<String, dynamic>>()
            : [values as Map<String, dynamic>];
        for (final item in list) {
          final keyVal = item[conflictKey];
          final existingIndex = rows.indexWhere((r) => r[conflictKey] == keyVal);
          if (existingIndex >= 0) {
            rows[existingIndex] = Map<String, dynamic>.from(item);
          } else {
            rows.add(Map<String, dynamic>.from(item));
          }
        }
        return list;
      },
    );
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() {
    return _FakeFilterBuilder<dynamic>(
      execute: (filters) async {
        final inIds = filters.inFilters['id'] ?? const [];
        operations.add('delete:${inIds.join(",")}');
        if (state.throwOnDelete) {
          throw Exception('Simulated delete network failure');
        }
        rows.removeWhere((row) => _matchesFilters(row, filters));
        return null;
      },
    );
  }

  List<Map<String, dynamic>> _applyFilters(_FilterSpec filters) {
    return rows.where((row) => _matchesFilters(row, filters)).toList();
  }

  bool _matchesFilters(Map<String, dynamic> row, _FilterSpec filters) {
    for (final entry in filters.eqFilters.entries) {
      if (row[entry.key] != entry.value) return false;
    }
    for (final entry in filters.inFilters.entries) {
      if (!entry.value.contains(row[entry.key])) return false;
    }
    return true;
  }
}

class _FilterSpec {
  final Map<String, Object> eqFilters = {};
  final Map<String, List<dynamic>> inFilters = {};
}

class _FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final Future<T> Function(_FilterSpec filters) execute;
  final Future<Map<String, dynamic>?> Function(_FilterSpec filters)? onMaybeSingle;
  final _FilterSpec _filters = _FilterSpec();

  _FakeFilterBuilder({
    required this.execute,
    this.onMaybeSingle,
  });

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    _filters.eqFilters[column] = value;
    return this;
  }

  @override
  PostgrestFilterBuilder<T> inFilter(String column, List values) {
    _filters.inFilters[column] = List<dynamic>.from(values);
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return _FakeTransformBuilder<Map<String, dynamic>?>(
      () => onMaybeSingle!(_filters),
    );
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return execute(_filters).then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return execute(_filters).catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return execute(_filters).whenComplete(action);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return execute(_filters).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<T> asStream() => execute(_filters).asStream();
}

class _FakeTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final Future<T> Function() execute;

  _FakeTransformBuilder(this.execute);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return execute().then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return execute().catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return execute().whenComplete(action);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return execute().timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<T> asStream() => execute().asStream();
}
