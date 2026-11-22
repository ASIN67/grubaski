# -*- coding: utf-8 -*-
"""
High-volume curator for Polish supermarket staples from Open Food Facts API (v4).
Focuses on major Polish supermarket private labels (Biedronka, Lidl) and top national brands.
Sanitizes macros, verifies barcodes (EAN-13, EAN-8), eliminates duplicates,
and outputs clean JSON data to scratch/curated_products_v4.json.
"""

import glob
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

OFF_HOSTS = [
    'https://pl.openfoodfacts.org',
    'https://world.openfoodfacts.net',
    'https://world.openfoodfacts.org',
]

USER_AGENT = 'GrubasekFoodScanner/2.0 (Android/iOS/Web; contact: kowal@grubasek.app)'

TARGET_BRANDS = [
    # Biedronka private labels
    'biedronka', 'mleczna-dolina', 'kraina-wedlin', 'swiatowid', 'vital-fresh',
    'plony-natury', 'culineo', 'gustobello', 'marinero', 'vitanella', 'z-gruntu-dobre',
    # Lidl private labels
    'lidl', 'pilos', 'pikok', 'rzeźnik', 'chef-select', 'combino', 'crownfield',
    'solevita', 'freshona', 'snack-day', 'tastino', 'alesto', 'cien', 'crivit',
    # Top Polish Dairy
    'mlekovita', 'piatnica', 'bakoma', 'danone', 'zott', 'polmlek', 'osm-krasnystaw',
    'krasnystaw', 'laciate', 'mlekpol', 'jovita', 'jogobella', 'ehrmann',
    # Top Polish Meat, Fish, Deli
    'sokolow', 'morliny', 'krakus', 'tarczynski', 'duda', 'kaminiarz', 'balcerzak',
    'lisner', 'graal', 'superfish', 'abramczyk', 'vici',
    # Bakery, Grains, Pasta, Condiments
    'lubella', 'kupiec', 'melvit', 'sante', 'cenos', 'sonko', 'kresto', 'bakalland',
    'mamut', 'dan-cake', 'chabior', 'oskroba',
    # Sauces, Spices, Soups, Preserves
    'winiary', 'pudliszki', 'kotlin', 'roleski', 'develey', 'fanex', 'dawtona',
    'lowicz', 'profi', 'kamis', 'prymat', 'bonduelle', 'kwidzyn', 'urbanek',
    # Sweets, Snacks, Chocolate
    'wedel', 'wawel', 'milka', 'lajkonik', 'lorenz', 'lays', 'crunchips', 'cheetos',
    'wiejskie-ziemniaczki', 'prince-polo', 'grzeski', 'jezyki', 'delicje',
    'jutrzenka', 'colian', 'goplana', 'solidarnosc', 'krakuski',
    # Drinks & Beverages
    'tymbark', 'hortex', 'kubus', 'tarczyn', 'dr-witt', 'zywiec-zdroj', 'cisowianka',
    'naleczowianka', 'oshee', '4move', 'muszynianka', 'piwniczanka',
    # Fit, Supplements, Protein
    'kfd', 'sfd', 'olimp', 'allnutrition', 'activlab', 'biotechusa', 'barebells',
    # Frozen & Convenience
    'frosta', 'hortex', 'iglotex', 'u-jedrusia', 'jawo', 'delecta', 'dr-oetker',
]

def load_existing_database_barcodes() -> set[str]:
    """Scans all existing Dart category files for existing barcodes to avoid duplicates."""
    barcodes = set()
    category_files = glob.glob('lib/data/categories/*.dart')
    for fpath in category_files:
        try:
            with open(fpath, 'r', encoding='utf-8') as f:
                content = f.read()
            for m in re.finditer(r"barcode:\s*['\"](\d+)['\"]", content):
                barcodes.add(m.group(1).strip())
        except Exception as e:
            print(f"Warning reading {fpath}: {e}")
    return barcodes

def is_valid_barcode(code: str) -> bool:
    if not code:
        return False
    clean = code.strip()
    if not clean.isdigit():
        return False
    if len(clean) not in (8, 12, 13, 14):
        return False
    if len(set(clean)) == 1:
        return False
    if clean in ('12345678', '123456789012', '1234567890123', '0123456789012'):
        return False
    return True

def is_garbage_name(name: str) -> bool:
    s = name.strip().lower()
    if len(s) < 2:
        return True
    if re.match(r'^[\s\.\,\-_=+!@#\$%\^&\*\(\)\d]+$', s) and not any(c.isalpha() for c in s):
        return True
    banned = {'test', 'asdf', 'qwer', 'brak', 'nieznany', 'unknown', 'delete', 'usun', 'null', 'none'}
    if s in banned:
        return True
    return False

def clean_name_and_brand(raw_name: str, raw_brand: str | None) -> tuple[str, str | None]:
    name = raw_name.strip()
    brand = raw_brand.strip() if raw_brand else None
    if brand:
        brand = brand.split(',')[0].strip()
        if not brand or brand.lower() in ('brak', 'unknown', 'nieznany', 'none', 'null'):
            brand = None

    if brand and name.lower().startswith(brand.lower() + ' '):
        name = name[len(brand):].strip()

    # Clean double spaces
    name = re.sub(r'\s+', ' ', name)
    if name and name[0].islower():
        name = name[0].upper() + name[1:]

    return name, brand

def sanitize_nutrition(nutr: dict) -> dict | None:
    def get_num(keys, fallback_keys=None, fallback_mult=1.0):
        for k in keys:
            v = nutr.get(k)
            if v is not None:
                try:
                    return float(v)
                except (ValueError, TypeError):
                    pass
        if fallback_keys:
            for k in fallback_keys:
                v = nutr.get(k)
                if v is not None:
                    try:
                        return float(v) * fallback_mult
                    except (ValueError, TypeError):
                        pass
        return 0.0

    prot = max(0.0, min(100.0, get_num(['proteins_100g', 'proteins_value', 'proteins'])))
    carb = max(0.0, min(100.0, get_num(['carbohydrates_100g', 'carbohydrates_value', 'carbohydrates'])))
    fat = max(0.0, min(100.0, get_num(['fat_100g', 'fat_value', 'fat'])))

    fiber_val = None
    for k in ['fiber_100g', 'fiber_value', 'fiber']:
        v = nutr.get(k)
        if v is not None:
            try:
                fv = float(v)
                if 0.0 <= fv <= 100.0:
                    fiber_val = round(fv, 1)
                    break
            except (ValueError, TypeError):
                pass

    macro_sum = prot + carb + fat
    # Strict macro sanity check: sum must not exceed 100g
    if macro_sum > 104.0:
        return None # Discard physically impossible macro entries
    if macro_sum > 100.0:
        # Minor rounding overshoot (e.g. 100.5g) -> normalize precisely to 100.0g
        scale = 100.0 / macro_sum
        prot = round(prot * scale, 1)
        carb = round(carb * scale, 1)
        fat = round(fat * scale, 1)

    theoretical_kcal = (prot * 4.0) + (carb * 4.0) + (fat * 9.0)

    kcal = get_num(
        ['energy-kcal_100g', 'energy-kcal_value', 'energy-kcal'],
        fallback_keys=['energy_100g', 'energy_value'],
        fallback_mult=0.239006,
    )

    if kcal <= 0.0 and theoretical_kcal > 0.0:
        kcal = theoretical_kcal
    elif kcal <= 0.0 and theoretical_kcal <= 0.0:
        return {
            'calories': 0.0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'fiber': None,
            'is_all_zero': True,
        }
    elif kcal > 900.0 or (theoretical_kcal > 15.0 and kcal > 2.8 * theoretical_kcal):
        # Check if energy was entered in kJ instead of kcal
        kj_to_kcal = kcal * 0.239006
        if kj_to_kcal <= 900.0 and abs(kj_to_kcal - theoretical_kcal) < 100.0:
            kcal = kj_to_kcal
        elif theoretical_kcal > 0.0:
            kcal = theoretical_kcal
        else:
            kcal = min(900.0, max(0.0, kcal))
    elif theoretical_kcal > 25.0 and abs(kcal - theoretical_kcal) > 120.0:
        kcal = theoretical_kcal

    kcal = round(max(0.0, min(900.0, kcal)), 1)
    prot = round(prot, 1)
    carb = round(carb, 1)
    fat = round(fat, 1)

    return {
        'calories': kcal,
        'protein': prot,
        'carbs': carb,
        'fat': fat,
        'fiber': fiber_val,
        'is_all_zero': False,
    }

def fetch_json(url: str, params: dict) -> dict | None:
    query_str = urllib.parse.urlencode(params)
    full_url = f"{url}?{query_str}"
    req = urllib.request.Request(full_url, headers={'User-Agent': USER_AGENT})
    for attempt in range(2):
        try:
            with urllib.request.urlopen(req, timeout=8) as resp:
                if resp.status == 200:
                    return json.loads(resp.read().decode('utf-8'))
        except Exception:
            time.sleep(0.5)
    return None

def fetch_products_for_brand(brand: str, page: int = 1, page_size: int = 50) -> list[dict]:
    params = {
        'countries_tags_en': 'poland',
        'brands_tags': brand,
        'page': page,
        'page_size': page_size,
        'fields': 'code,product_name,product_name_pl,brands,nutriments,serving_size,serving_quantity',
    }
    for host in OFF_HOSTS:
        url = f"{host}/api/v2/search"
        data = fetch_json(url, params)
        if data and 'products' in data:
            return data.get('products', [])
    return []

def main():
    print("=" * 70)
    print("GRUBASEK: Curating Polish Supermarket Food Database (v4)")
    print("=" * 70)

    existing_barcodes = load_existing_database_barcodes()
    print(f"Existing barcodes in local Dart catalog: {len(existing_barcodes)}")

    seen_barcodes = set(existing_barcodes)
    curated_products = []

    total_brands = len(TARGET_BRANDS)
    print(f"Querying Open Food Facts API for {total_brands} Polish brands/chains...")

    for idx, brand in enumerate(TARGET_BRANDS, start=1):
        brand_clean = brand.replace('-', ' ').title()
        brand_new_count = 0
        
        # Query pages 1 and 2
        for page in (1, 2):
            raw_products = fetch_products_for_brand(brand, page=page, page_size=50)
            if not raw_products:
                break

            for p in raw_products:
                code = (p.get('code') or '').strip()
                if not is_valid_barcode(code) or code in seen_barcodes:
                    continue

                raw_name = (p.get('product_name_pl') or p.get('product_name') or '').strip()
                if is_garbage_name(raw_name):
                    continue

                nutr = sanitize_nutrition(p.get('nutriments') or {})
                if not nutr:
                    continue

                name, b_name = clean_name_and_brand(raw_name, p.get('brands') or brand_clean)
                if not name or is_garbage_name(name):
                    continue

                if nutr.get('is_all_zero'):
                    lname = name.lower()
                    is_zero_drink = any(k in lname for k in ['woda', 'water', 'herbata', 'tea', 'kawa', 'coffee', 'zero', 'pepsi max', 'cola light', 'izotonik zero'])
                    if not is_zero_drink:
                        continue # Ignore unpopulated food items

                serving_size = 100.0
                sq = p.get('serving_quantity')
                if isinstance(sq, (int, float)) and 5.0 <= sq <= 2000.0:
                    serving_size = round(float(sq), 1)

                prod_id = f"seed-off-v4-{code}"
                serving_label = f"1 porcja ({int(serving_size)}g)" if serving_size != 100.0 else "100g"

                item = {
                    'id': prod_id,
                    'barcode': code,
                    'name': name,
                    'brand': b_name or brand_clean,
                    'calories_per_100g': nutr['calories'],
                    'protein_per_100g': nutr['protein'],
                    'carbs_per_100g': nutr['carbs'],
                    'fat_per_100g': nutr['fat'],
                    'fiber_per_100g': nutr['fiber'],
                    'serving_size_grams': serving_size,
                    'serving_name': serving_label,
                    'is_custom': False,
                    # Provide camelCase aliases for seamless ingestion in Dart or TS
                    'caloriesPer100g': nutr['calories'],
                    'proteinPer100g': nutr['protein'],
                    'carbsPer100g': nutr['carbs'],
                    'fatPer100g': nutr['fat'],
                    'fiberPer100g': nutr['fiber'],
                    'servingSizeGrams': serving_size,
                    'servingName': serving_label,
                }

                seen_barcodes.add(code)
                curated_products.append(item)
                brand_new_count += 1

            time.sleep(0.3) # Friendly rate limiting

        if (idx % 5 == 0) or idx == total_brands:
            print(f"[{idx}/{total_brands}] {brand_clean}: +{brand_new_count} items (total curated v4: {len(curated_products)})")

    os.makedirs('scratch', exist_ok=True)
    out_path = os.path.join('scratch', 'curated_products_v4.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(curated_products, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 70)
    print(f"SUCCESS: Curated {len(curated_products)} verified Polish supermarket products with barcodes.")
    print(f"Saved to: {out_path}")
    print("=" * 70)

if __name__ == '__main__':
    main()
