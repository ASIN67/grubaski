import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/product_repository.dart';
import 'package:grubasek/services/cloud_sync_service.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/services/supabase_service.dart';
import 'package:hive/hive.dart';

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
}
