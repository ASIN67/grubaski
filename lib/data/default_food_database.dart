// MODULAR PREDEFINED POLISH FOOD DATABASE (2800+ ITEMS)
// Aggregates modular categories from lib/data/categories/

import '../models/food_product.dart';
import 'categories/bakery_and_grains.dart';
import 'categories/beverages_and_sauces.dart';
import 'categories/dairy_and_eggs.dart';
import 'categories/fitness_and_supplements.dart';
import 'categories/fruits_vegetables_fats.dart';
import 'categories/meat_and_fish.dart';
import 'categories/open_food_facts_staples.dart';
import 'categories/polish_supermarket_staples.dart';
import 'categories/popular_polish_brands.dart';
import 'categories/ready_meals_and_fastfood.dart';
import 'categories/snacks_and_sweets.dart';

export 'categories/bakery_and_grains.dart';
export 'categories/beverages_and_sauces.dart';
export 'categories/dairy_and_eggs.dart';
export 'categories/fitness_and_supplements.dart';
export 'categories/fruits_vegetables_fats.dart';
export 'categories/meat_and_fish.dart';
export 'categories/open_food_facts_staples.dart';
export 'categories/polish_supermarket_staples.dart';
export 'categories/popular_polish_brands.dart';
export 'categories/ready_meals_and_fastfood.dart';
export 'categories/snacks_and_sweets.dart';

/// Comprehensive predefined catalog of staple and popular Polish food products.
///
/// Loaded on initial app launch (or database migration) into Hive foodProductsBox
/// for instant offline nutrition tracking, fast diacritics-insensitive search,
/// and precise portion calculations.
const List<FoodProduct> defaultFoodProducts = [
  ...dairyAndEggsProducts,
  ...meatAndFishProducts,
  ...bakeryAndGrainsProducts,
  ...fruitsVegetablesFatsProducts,
  ...readyMealsAndFastFood,
  ...snacksAndSweets,
  ...fitnessAndSupplements,
  ...beveragesAndSauces,
  ...openFoodFactsStaples,
  ...polishSupermarketStaples,
  ...popularPolishBrandsProducts,
];
