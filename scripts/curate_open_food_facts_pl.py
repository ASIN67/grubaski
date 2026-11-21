# -*- coding: utf-8 -*-
"""
Curates, cleans, and sanitizes Polish food products with barcodes from Open Food Facts API.
Filters out community user errors, impossible macros, corrupted barcodes, and kJ/kcal mistakes.
Generates SQL seed script for Supabase public_products table and local Dart data.
"""

import json
import re
import sys
import time
import urllib.parse
import urllib.request
import uuid

OFF_HOSTS = [
    'https://pl.openfoodfacts.org',
    'https://world.openfoodfacts.net',
    'https://world.openfoodfacts.org',
]

USER_AGENT = 'GrubasekApp - Android/iOS/Web - Version 1.0 - https://grubasek.pages.dev'

BRANDS = [
    'biedronka', 'lidl', 'pilos', 'mlekovita', 'piatnica', 'bakoma', 'danone',
    'zott', 'winiary', 'pudliszki', 'kotlin', 'dawtona', 'krakus', 'morliny',
    'tarczynski', 'pikok', 'sokolow', 'lubella', 'kupiec', 'melvit', 'sante',
    'wedel', 'wawel', 'milka', 'lajkonik', 'lorenz', 'lays', 'tymbark',
    'hortex', 'zywiec', 'cisowianka', 'naleczowianka', 'kfd', 'sfd', 'olimp',
    'frosta', 'lisner', 'graal', 'delecta', 'dr-oetker', 'bonduelle'
]

CATEGORIES = [
    'dairies', 'cheeses', 'meats', 'breads', 'cereals-and-their-products',
    'plant-based-foods', 'beverages', 'snacks', 'sweet-snacks', 'groceries'
]

def is_dummy_barcode(code: str) -> bool:
    if not code or len(code) < 8 or len(code) > 14 or not code.isdigit():
        return True
    if len(set(code)) == 1:
        return True
    if code in ('12345678', '123456789012', '1234567890123'):
        return True
    return False

def is_garbage_name(name: str) -> bool:
    s = name.strip().lower()
    if len(s) < 2:
        return True
    if re.match(r'^[\s\.\,\-_=+!@#\$%\^&\*\(\)]+$', s):
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
        if not brand or brand.lower() in ('brak', 'unknown', 'nieznany'):
            brand = None

    if brand and name.lower().startswith(brand.lower() + ' '):
        name = name[len(brand):].strip()

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
                fiber_val = round(max(0.0, min(100.0, float(v))), 1)
                break
            except (ValueError, TypeError):
                pass

    macro_sum = prot + carb + fat
    if macro_sum > 105.0:
        if macro_sum <= 130.0:
            scale = 100.0 / macro_sum
            prot = round(prot * scale, 1)
            carb = round(carb * scale, 1)
            fat = round(fat * scale, 1)
        else:
            return None # Impossible macros

    theoretical_kcal = (prot * 4.0) + (carb * 4.0) + (fat * 9.0)

    kcal = get_num(
        ['energy-kcal_100g', 'energy-kcal_value', 'energy-kcal'],
        fallback_keys=['energy_100g', 'energy_value'],
        fallback_mult=0.239006
    )

    if kcal <= 0.0 and theoretical_kcal > 0.0:
        kcal = theoretical_kcal
    elif kcal <= 0.0 and theoretical_kcal <= 0.0:
        # Check if caller allows it for natural zero-calorie drinks
        return {
            'calories': 0.0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'fiber': None,
            'is_all_zero': True,
        }
    elif kcal > 950.0 or (theoretical_kcal > 15.0 and kcal > 2.8 * theoretical_kcal):
        kj_to_kcal = kcal * 0.239006
        if kj_to_kcal <= 900.0 and abs(kj_to_kcal - theoretical_kcal) < 120.0:
            kcal = kj_to_kcal
        elif theoretical_kcal > 0.0:
            kcal = theoretical_kcal
        else:
            kcal = min(900.0, max(0.0, kcal))
    elif theoretical_kcal > 30.0 and abs(kcal - theoretical_kcal) > 150.0:
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
    }

def fetch_json(url: str, params: dict) -> dict | None:
    query_str = urllib.parse.urlencode(params)
    full_url = f"{url}?{query_str}"
    req = urllib.request.Request(full_url, headers={'User-Agent': USER_AGENT})
    for attempt in range(2):
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                if resp.status == 200:
                    return json.loads(resp.read().decode('utf-8'))
        except Exception as e:
            time.sleep(1.0)
    return None

def fetch_products_for_tag(tag_type: str, tag_value: str, page_size: int = 50) -> list[dict]:
    params = {
        'countries_tags_en': 'poland',
        f'{tag_type}_tags': tag_value,
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
    print("Curating Polish food products from Open Food Facts API...")
    seen_barcodes = set()
    curated_products = []

    # 1. Fetch by brands
    for brand in BRANDS:
        print(f"Fetching brand: {brand}...", end=" ", flush=True)
        products = fetch_products_for_tag('brands', brand, page_size=40)
        valid_count = 0
        for p in products:
            code = (p.get('code') or '').strip()
            if is_dummy_barcode(code) or code in seen_barcodes:
                continue
            
            raw_name = (p.get('product_name_pl') or p.get('product_name') or '').strip()
            if is_garbage_name(raw_name):
                continue

            nutr = sanitize_nutrition(p.get('nutriments') or {})
            if not nutr:
                continue

            name, b_name = clean_name_and_brand(raw_name, p.get('brands') or brand)
            if not name:
                continue

            if nutr.get('is_all_zero'):
                lname = name.lower()
                is_zero_drink = any(k in lname for k in ['woda', 'water', 'herbata', 'tea', 'kawa', 'coffee', 'zero', 'pepsi max', 'cola light'])
                if not is_zero_drink:
                    continue # Discard empty unpopulated food items

            serving_size = 100.0
            sq = p.get('serving_quantity')
            if isinstance(sq, (int, float)) and 5.0 <= sq <= 2000.0:
                serving_size = float(sq)

            prod = {
                'id': f"off-{code}",
                'barcode': code,
                'name': name,
                'brand': b_name or brand.capitalize(),
                'calories_per_100g': nutr['calories'],
                'protein_per_100g': nutr['protein'],
                'carbs_per_100g': nutr['carbs'],
                'fat_per_100g': nutr['fat'],
                'fiber_per_100g': nutr['fiber'],
                'serving_size_grams': serving_size,
                'serving_name': f"1 porcja ({int(serving_size)}g)" if serving_size != 100.0 else "100g",
                'is_custom': False,
            }
            seen_barcodes.add(code)
            curated_products.append(prod)
            valid_count += 1

        print(f"added {valid_count} (total: {len(curated_products)})")
        time.sleep(1.0) # Be polite to OFF API

    print(f"\nTotal curated & sanitized Polish products with barcodes: {len(curated_products)}")

    # Save to JSON
    with open('scripts/curated_open_food_facts_pl.json', 'w', encoding='utf-8') as f:
        json.dump(curated_products, f, ensure_ascii=False, indent=2)
    print("Saved to scripts/curated_open_food_facts_pl.json")

if __name__ == '__main__':
    main()
