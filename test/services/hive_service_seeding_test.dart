import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/data/default_food_database.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  final hiveService = HiveService.instance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_seeder_test_');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('HiveService.init() seeds default food products (v2 with 800+ items) and sets flags', () async {
    await hiveService.init(customPath: tempDir.path);

    expect(hiveService.foodProductsBox.length, equals(defaultFoodProducts.length));
    expect(hiveService.foodProductsBox.length, greaterThanOrEqualTo(800));

    final isSeededV2 = hiveService.settingsBox.get(HiveService.foodDatabaseSeededKey);
    final version = hiveService.settingsBox.get(HiveService.foodDatabaseVersionKey);
    expect(isSeededV2, isTrue);
    expect(version, equals(2));

    // Verify sample product from dairy
    final sample1 = hiveService.foodProductsBox.get('seed-nab-skyr-naturalny-piatnica');
    expect(sample1, isNotNull);
    expect(sample1!.name, contains('Skyr'));
    expect(sample1.brand, 'Piątnica');

    // Verify sample product from ready meals
    final sample2 = hiveService.foodProductsBox.get('seed-dania-pierogi-ruskie-jedrus');
    expect(sample2, isNotNull);
    expect(sample2!.name, 'Pierogi ruskie');
    expect(sample2.brand, 'U Jędrusia');
  });

  test('Non-destructive migration from v1 to v2 preserves custom items and user favorites', () async {
    // 1. Manually setup a simulated v1 state with 1 seed product and 1 custom product
    Hive.init(tempDir.path);
    hiveService.registerAdapters();

    final productBox = await Hive.openBox<FoodProduct>(HiveService.foodProductsBoxName);
    final settingsBox = await Hive.openBox<dynamic>(HiveService.settingsBoxName);

    // Seed flag v1
    await settingsBox.put(HiveService.foodDatabaseSeededV1Key, true);

    // Existing product from v1 marked as favorite by user
    const favoritedV1Product = FoodProduct(
      id: 'seed-piecz-chleb-zytni-razowy',
      name: 'Chleb żytni razowy',
      caloriesPer100g: 227.0,
      proteinPer100g: 5.8,
      carbsPer100g: 44.0,
      fatPer100g: 1.7,
      isFavorite: true,
    );

    // Custom user product
    const customUserProduct = FoodProduct(
      id: 'custom-user-lunch-bowl',
      name: 'Moja miska z kurczakiem',
      caloriesPer100g: 145.0,
      proteinPer100g: 18.0,
      carbsPer100g: 12.0,
      fatPer100g: 3.0,
      isCustom: true,
    );

    await productBox.put(favoritedV1Product.id, favoritedV1Product);
    await productBox.put(customUserProduct.id, customUserProduct);
    expect(productBox.length, equals(2));

    // 2. Run seedDefaultProducts() migration
    await hiveService.seedDefaultProducts(force: false);

    // 3. Verify migration results
    expect(settingsBox.get(HiveService.foodDatabaseSeededKey), isTrue);
    expect(settingsBox.get(HiveService.foodDatabaseVersionKey), equals(2));

    // Total products should be defaultFoodProducts + 1 (custom product)
    expect(productBox.length, equals(defaultFoodProducts.length + 1));
    expect(productBox.length, greaterThanOrEqualTo(800));

    // Custom product is completely untouched
    final retrievedCustom = productBox.get(customUserProduct.id);
    expect(retrievedCustom, isNotNull);
    expect(retrievedCustom!.name, 'Moja miska z kurczakiem');
    expect(retrievedCustom.isCustom, isTrue);

    // Existing favorited product retains favorite flag
    final retrievedFavorite = productBox.get(favoritedV1Product.id);
    expect(retrievedFavorite, isNotNull);
    expect(retrievedFavorite!.isFavorite, isTrue);
  });

  test('Calling seedDefaultProducts without force when already seeded v2 does nothing', () async {
    await hiveService.init(customPath: tempDir.path);
    final countBefore = hiveService.foodProductsBox.length;

    await hiveService.seedDefaultProducts(force: false);
    expect(hiveService.foodProductsBox.length, equals(countBefore));
  });

  test('seedDefaultProducts recovers automatically if box is cleared', () async {
    await hiveService.init(customPath: tempDir.path);
    expect(hiveService.foodProductsBox.isNotEmpty, isTrue);

    // Wipe box but leave flags
    await hiveService.foodProductsBox.clear();
    expect(hiveService.foodProductsBox.isEmpty, isTrue);

    // Re-seed runs and populates all products
    await hiveService.seedDefaultProducts(force: false);
    expect(hiveService.foodProductsBox.length, equals(defaultFoodProducts.length));
  });

  test('seedDefaultProducts with force=true updates items and preserves user favorites', () async {
    await hiveService.init(customPath: tempDir.path);

    const testId = 'seed-piecz-chleb-zytni-razowy';
    final product = hiveService.foodProductsBox.get(testId)!;

    await hiveService.foodProductsBox.put(testId, product.copyWith(isFavorite: true));
    expect(hiveService.foodProductsBox.get(testId)!.isFavorite, isTrue);

    await hiveService.seedDefaultProducts(force: true);

    final reseededProduct = hiveService.foodProductsBox.get(testId)!;
    expect(reseededProduct.isFavorite, isTrue);
  });

  test('clearAllData with reseedDefaults=true clears user data and reseeds default products', () async {
    await hiveService.init(customPath: tempDir.path);

    const userProfile = UserProfile(
      gender: Gender.male,
      age: 30,
      startWeightKg: 85.0,
      targetWeightKg: 78.0,
      heightCm: 180.0,
      activityLevel: ActivityLevel.moderate,
      goal: WeightGoal.reduction,
      dailyCaloriesGoal: 2200,
      proteinGoalGrams: 160,
      carbsGoalGrams: 230,
      fatGoalGrams: 70,
      waterGoalMl: 2500,
    );
    await hiveService.userProfileBox.put('profile', userProfile);
    expect(hiveService.userProfileBox.isNotEmpty, isTrue);

    await hiveService.clearAllData(reseedDefaults: true);

    expect(hiveService.userProfileBox.isEmpty, isTrue);
    expect(hiveService.foodProductsBox.length, equals(defaultFoodProducts.length));
    expect(hiveService.settingsBox.get(HiveService.foodDatabaseSeededKey), isTrue);
    expect(hiveService.settingsBox.get(HiveService.foodDatabaseVersionKey), equals(2));
  });

  test('clearAllData with reseedDefaults=false completely wipes all boxes', () async {
    await hiveService.init(customPath: tempDir.path);
    expect(hiveService.foodProductsBox.isNotEmpty, isTrue);

    await hiveService.clearAllData(reseedDefaults: false);

    expect(hiveService.foodProductsBox.isEmpty, isTrue);
    expect(hiveService.settingsBox.get(HiveService.foodDatabaseSeededKey), isNull);
  });
}
