import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

/// Result summary of a cloud synchronization attempt.
class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;
  final DateTime syncedAt;

  const SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    required this.syncedAt,
  });

  @override
  String toString() =>
      'SyncResult(success: $success, uploaded: $uploadedCount, downloaded: $downloadedCount, msg: $message)';
}

/// Service managing bidirectional synchronization between local Hive storage
/// and remote Supabase PostgreSQL database.
class CloudSyncService {
  final HiveService _hiveService;
  final SupabaseService _supabaseService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  static const String lastSyncTimestampKey = 'last_cloud_sync_timestamp';

  CloudSyncService({
    HiveService? hiveService,
    SupabaseService? supabaseService,
  })  : _hiveService = hiveService ?? HiveService.instance,
        _supabaseService = supabaseService ?? SupabaseService.instance;

  /// Returns timestamp of the most recent successful sync, or null if never synced.
  DateTime? get lastSyncTime {
    final raw = _hiveService.settingsBox.get(lastSyncTimestampKey);
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// Performs full bidirectional sync of all user entities:
  /// - User Profile
  /// - Meal Entries
  /// - Water Logs
  /// - Weight Measurements
  /// - Body Circumferences
  /// - Custom Created Food Products
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Synchronizacja jest już w toku.',
        syncedAt: DateTime.now(),
      );
    }

    if (!_supabaseService.isAuthenticated) {
      return SyncResult(
        success: false,
        message: 'Zaloguj się, aby synchronizować dane z chmurą.',
        syncedAt: DateTime.now(),
      );
    }

    final userId = _supabaseService.currentUserId;
    final client = _supabaseService.client;
    if (userId == null || client == null) {
      return SyncResult(
        success: false,
        message: 'Brak połączenia z chmurą Supabase.',
        syncedAt: DateTime.now(),
      );
    }

    _isSyncing = true;
    var totalUploaded = 0;
    var totalDownloaded = 0;

    try {
      // 1. Sync User Profile
      final profileCounts = await syncUserProfile(userId);
      totalUploaded += profileCounts.uploaded;
      totalDownloaded += profileCounts.downloaded;

      // 2. Sync Daily Water Logs
      final waterCounts = await syncWaterLogs(userId);
      totalUploaded += waterCounts.uploaded;
      totalDownloaded += waterCounts.downloaded;

      // 3. Sync Weight Entries
      final weightCounts = await syncWeightEntries(userId);
      totalUploaded += weightCounts.uploaded;
      totalDownloaded += weightCounts.downloaded;

      // 4. Sync Body Measurements
      final bodyCounts = await syncBodyMeasurements(userId);
      totalUploaded += bodyCounts.uploaded;
      totalDownloaded += bodyCounts.downloaded;

      // 5. Sync Meal Entries
      final mealCounts = await syncMealEntries(userId);
      totalUploaded += mealCounts.uploaded;
      totalDownloaded += mealCounts.downloaded;

      // 6. Sync Custom Food Products to Public Catalog
      final productCounts = await syncCustomProducts(userId);
      totalUploaded += productCounts.uploaded;
      totalDownloaded += productCounts.downloaded;

      final now = DateTime.now();
      await _hiveService.settingsBox.put(
        lastSyncTimestampKey,
        now.toIso8601String(),
      );

      debugPrint(
        'CloudSyncService: Sync finished successfully. Uploaded: $totalUploaded, Downloaded: $totalDownloaded',
      );

      return SyncResult(
        success: true,
        message: 'Synchronizacja zakończona pomyślnie.',
        uploadedCount: totalUploaded,
        downloadedCount: totalDownloaded,
        syncedAt: now,
      );
    } catch (error, stack) {
      debugPrint('CloudSyncService: Sync error ($error)');
      if (kDebugMode) debugPrint(stack.toString());
      return SyncResult(
        success: false,
        message: 'Błąd synchronizacji: $error',
        uploadedCount: totalUploaded,
        downloadedCount: totalDownloaded,
        syncedAt: DateTime.now(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. USER PROFILE SYNC
  // ---------------------------------------------------------------------------
  Future<({int uploaded, int downloaded})> syncUserProfile(
      String userId) async {
    final table = _supabaseService.userProfilesTable;
    if (table == null) return (uploaded: 0, downloaded: 0);

    var up = 0;
    var down = 0;

    // Check remote profile
    final remoteData =
        await table.select().eq('user_id', userId).maybeSingle();

    final localProfile = _hiveService.userProfileBox.get('current');

    if (localProfile != null) {
      // Push local profile to Supabase
      await table.upsert({
        'user_id': userId,
        'gender': localProfile.gender.name,
        'age': localProfile.age,
        'start_weight_kg': localProfile.startWeightKg,
        'target_weight_kg': localProfile.targetWeightKg,
        'height_cm': localProfile.heightCm,
        'activity_level': localProfile.activityLevel.name,
        'goal': localProfile.goal.name,
        'weekly_pace_kg': localProfile.weeklyPaceKg,
        'daily_calories_goal': localProfile.dailyCaloriesGoal,
        'protein_goal_grams': localProfile.proteinGoalGrams,
        'carbs_goal_grams': localProfile.carbsGoalGrams,
        'fat_goal_grams': localProfile.fatGoalGrams,
        'water_goal_ml': localProfile.waterGoalMl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      up++;
    } else if (remoteData != null) {
      // Pull remote profile to local Hive
      final profile = _mapRowToUserProfile(remoteData);
      await _hiveService.userProfileBox.put('current', profile);
      down++;
    }

    return (uploaded: up, downloaded: down);
  }

  // ---------------------------------------------------------------------------
  // 2. WATER LOGS SYNC
  // ---------------------------------------------------------------------------
  Future<({int uploaded, int downloaded})> syncWaterLogs(String userId) async {
    final table = _supabaseService.dailyWaterLogsTable;
    if (table == null) return (uploaded: 0, downloaded: 0);

    var up = 0;
    var down = 0;

    // Upload local logs
    final localLogs = _hiveService.waterLogsBox.values.toList();
    if (localLogs.isNotEmpty) {
      final payload = localLogs.map((log) => {
            'user_id': userId,
            'date_key': log.dateKey,
            'amount_ml': log.amountMl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).toList();

      await table.upsert(payload, onConflict: 'user_id,date_key');
      up += localLogs.length;
    }

    // Download remote logs
    final remoteLogs = await table.select().eq('user_id', userId);
    for (final row in remoteLogs as List) {
      final map = row as Map<String, dynamic>;
      final dateKey = map['date_key'] as String;
      final amountMl = (map['amount_ml'] as num).toInt();
      final local = _hiveService.waterLogsBox.get(dateKey);
      if (local == null || local.amountMl != amountMl) {
        await _hiveService.waterLogsBox
            .put(dateKey, DailyWaterLog(dateKey: dateKey, amountMl: amountMl));
        down++;
      }
    }

    return (uploaded: up, downloaded: down);
  }

  // ---------------------------------------------------------------------------
  // 3. WEIGHT ENTRIES SYNC
  // ---------------------------------------------------------------------------
  Future<({int uploaded, int downloaded})> syncWeightEntries(
      String userId) async {
    final table = _supabaseService.weightEntriesTable;
    if (table == null) return (uploaded: 0, downloaded: 0);

    var up = 0;
    var down = 0;

    // Upload local weight entries
    final localEntries = _hiveService.weightEntriesBox.values.toList();
    if (localEntries.isNotEmpty) {
      final payload = localEntries.map((e) => {
            'id': e.id,
            'user_id': userId,
            'date': e.date.toUtc().toIso8601String(),
            'weight_kg': e.weightKg,
          }).toList();

      await table.upsert(payload, onConflict: 'id');
      up += localEntries.length;
    }

    // Download remote weight entries
    final remoteEntries = await table.select().eq('user_id', userId);
    for (final row in remoteEntries as List) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as String;
      if (!_hiveService.weightEntriesBox.containsKey(id)) {
        final entry = WeightEntry(
          id: id,
          date: DateTime.parse(map['date'] as String).toLocal(),
          weightKg: (map['weight_kg'] as num).toDouble(),
        );
        await _hiveService.weightEntriesBox.put(id, entry);
        down++;
      }
    }

    return (uploaded: up, downloaded: down);
  }

  // ---------------------------------------------------------------------------
  // 4. BODY MEASUREMENTS SYNC
  // ---------------------------------------------------------------------------
  Future<({int uploaded, int downloaded})> syncBodyMeasurements(
      String userId) async {
    final table = _supabaseService.bodyMeasurementsTable;
    if (table == null) return (uploaded: 0, downloaded: 0);

    var up = 0;
    var down = 0;

    // Upload local measurements
    final localEntries = _hiveService.bodyMeasurementsEntriesBox.values.toList();
    if (localEntries.isNotEmpty) {
      final payload = localEntries.map((e) {
        final id = e.date.toIso8601String().split('T').first;
        return {
          'id': id,
          'user_id': userId,
          'date': e.date.toUtc().toIso8601String(),
          'waist_cm': e.waistCm,
          'chest_cm': e.chestCm,
          'arm_cm': e.armCm,
          'hips_cm': e.hipsCm,
          'thigh_cm': e.thighCm,
        };
      }).toList();

      await table.upsert(payload, onConflict: 'id');
      up += localEntries.length;
    }

    // Download remote measurements
    final remoteEntries = await table.select().eq('user_id', userId);
    for (final row in remoteEntries as List) {
      final map = row as Map<String, dynamic>;
      final date = DateTime.parse(map['date'] as String).toLocal();
      final dateKey = date.toIso8601String().split('T').first;
      if (!_hiveService.bodyMeasurementsEntriesBox.containsKey(dateKey)) {
        final entry = BodyMeasurementsEntry(
          date: date,
          waistCm: (map['waist_cm'] as num?)?.toDouble(),
          chestCm: (map['chest_cm'] as num?)?.toDouble(),
          armCm: (map['arm_cm'] as num?)?.toDouble(),
          hipsCm: (map['hips_cm'] as num?)?.toDouble(),
          thighCm: (map['thigh_cm'] as num?)?.toDouble(),
        );
        await _hiveService.bodyMeasurementsEntriesBox.put(dateKey, entry);
        down++;
      }
    }

    return (uploaded: up, downloaded: down);
  }

  // ---------------------------------------------------------------------------
  // 5. MEAL ENTRIES SYNC
  // ---------------------------------------------------------------------------
  Future<({int uploaded, int downloaded})> syncMealEntries(
      String userId) async {
    final table = _supabaseService.mealEntriesTable;
    if (table == null) return (uploaded: 0, downloaded: 0);

    var up = 0;
    var down = 0;

    // Upload local meal entries
    final localEntries = _hiveService.mealEntriesBox.values.toList();
    if (localEntries.isNotEmpty) {
      final payload = localEntries.map((e) => {
            'id': e.id,
            'user_id': userId,
            'date_key': e.dateKey,
            'meal_type': e.mealType.name,
            'grams': e.grams,
            'product_snapshot': _productToSnapshot(e.product),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).toList();

      await table.upsert(payload, onConflict: 'id');
      up += localEntries.length;
    }

    // Download remote meal entries
    final remoteEntries = await table.select().eq('user_id', userId);
    for (final row in remoteEntries as List) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as String;
      if (!_hiveService.mealEntriesBox.containsKey(id)) {
        final entry = _mapRowToMealEntry(map);
        await _hiveService.mealEntriesBox.put(id, entry);
        down++;
      }
    }

    return (uploaded: up, downloaded: down);
  }

  // ---------------------------------------------------------------------------
  // 6. CUSTOM PRODUCTS SYNC (To Supabase public_products)
  // ---------------------------------------------------------------------------
  Future<({int uploaded, int downloaded})> syncCustomProducts(
      String userId) async {
    final table = _supabaseService.publicProductsTable;
    if (table == null) return (uploaded: 0, downloaded: 0);

    var up = 0;
    var down = 0;

    // Upload local custom products
    final localCustom = _hiveService.foodProductsBox.values
        .where((p) => p.isCustom)
        .toList();

    if (localCustom.isNotEmpty) {
      final payload = localCustom.map((p) => {
            'id': p.id,
            'barcode': p.barcode,
            'name': p.name,
            'brand': p.brand,
            'calories_per_100g': p.caloriesPer100g,
            'protein_per_100g': p.proteinPer100g,
            'carbs_per_100g': p.carbsPer100g,
            'fat_per_100g': p.fatPer100g,
            'fiber_per_100g': p.fiberPer100g,
            'serving_size_grams': p.servingSizeGrams,
            'serving_name': p.servingName,
            'is_custom': true,
            'created_by': userId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).toList();

      await table.upsert(payload, onConflict: 'id');
      up += localCustom.length;
    }

    // Download any authored products created by this user
    final remoteAuthored =
        await table.select().eq('created_by', userId);
    for (final row in remoteAuthored as List) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as String;
      if (!_hiveService.foodProductsBox.containsKey(id)) {
        final product = _mapRowToFoodProduct(map);
        await _hiveService.foodProductsBox.put(id, product);
        down++;
      }
    }

    return (uploaded: up, downloaded: down);
  }

  // ---------------------------------------------------------------------------
  // SERIALIZATION HELPERS
  // ---------------------------------------------------------------------------

  UserProfile _mapRowToUserProfile(Map<String, dynamic> row) {
    return UserProfile(
      gender: Gender.values.firstWhere(
        (g) => g.name == row['gender'],
        orElse: () => Gender.male,
      ),
      age: (row['age'] as num).toInt(),
      startWeightKg: (row['start_weight_kg'] as num).toDouble(),
      targetWeightKg: (row['target_weight_kg'] as num).toDouble(),
      heightCm: (row['height_cm'] as num).toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (a) => a.name == row['activity_level'],
        orElse: () => ActivityLevel.moderate,
      ),
      goal: WeightGoal.values.firstWhere(
        (g) => g.name == row['goal'],
        orElse: () => WeightGoal.reduction,
      ),
      weeklyPaceKg: (row['weekly_pace_kg'] as num?)?.toDouble() ?? 0.5,
      dailyCaloriesGoal: (row['daily_calories_goal'] as num).toInt(),
      proteinGoalGrams: (row['protein_goal_grams'] as num).toInt(),
      carbsGoalGrams: (row['carbs_goal_grams'] as num).toInt(),
      fatGoalGrams: (row['fat_goal_grams'] as num).toInt(),
      waterGoalMl: (row['water_goal_ml'] as num).toInt(),
    );
  }

  Map<String, dynamic> _productToSnapshot(FoodProduct product) {
    return {
      'id': product.id,
      'barcode': product.barcode,
      'name': product.name,
      'brand': product.brand,
      'caloriesPer100g': product.caloriesPer100g,
      'proteinPer100g': product.proteinPer100g,
      'carbsPer100g': product.carbsPer100g,
      'fatPer100g': product.fatPer100g,
      'fiberPer100g': product.fiberPer100g,
      'servingSizeGrams': product.servingSizeGrams,
      'servingName': product.servingName,
      'isCustom': product.isCustom,
      'isFavorite': product.isFavorite,
      'isQuickAdd': product.isQuickAdd,
    };
  }

  MealEntry _mapRowToMealEntry(Map<String, dynamic> row) {
    final snapshot = row['product_snapshot'] as Map<String, dynamic>;
    final product = FoodProduct(
      id: snapshot['id'] as String? ?? 'unknown',
      barcode: snapshot['barcode'] as String?,
      name: snapshot['name'] as String? ?? 'Produkt',
      brand: snapshot['brand'] as String?,
      caloriesPer100g:
          (snapshot['caloriesPer100g'] as num?)?.toDouble() ?? 0.0,
      proteinPer100g:
          (snapshot['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (snapshot['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
      fatPer100g: (snapshot['fatPer100g'] as num?)?.toDouble() ?? 0.0,
      fiberPer100g: (snapshot['fiberPer100g'] as num?)?.toDouble(),
      servingSizeGrams:
          (snapshot['servingSizeGrams'] as num?)?.toDouble() ?? 100.0,
      servingName: snapshot['servingName'] as String?,
      isCustom: snapshot['isCustom'] as bool? ?? false,
      isFavorite: snapshot['isFavorite'] as bool? ?? false,
      isQuickAdd: snapshot['isQuickAdd'] as bool? ?? false,
    );

    return MealEntry(
      id: row['id'] as String,
      dateKey: row['date_key'] as String,
      mealType: MealType.values.firstWhere(
        (m) => m.name == row['meal_type'],
        orElse: () => MealType.lunch,
      ),
      grams: (row['grams'] as num).toDouble(),
      product: product,
    );
  }

  FoodProduct _mapRowToFoodProduct(Map<String, dynamic> row) {
    return FoodProduct(
      id: row['id'] as String,
      barcode: row['barcode'] as String?,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      caloriesPer100g: (row['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (row['protein_per_100g'] as num).toDouble(),
      carbsPer100g: (row['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (row['fat_per_100g'] as num).toDouble(),
      fiberPer100g: (row['fiber_per_100g'] as num?)?.toDouble(),
      servingSizeGrams:
          (row['serving_size_grams'] as num?)?.toDouble() ?? 100.0,
      servingName: row['serving_name'] as String?,
      isCustom: row['is_custom'] as bool? ?? true,
    );
  }
}

/// Riverpod provider for [CloudSyncService].
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});
