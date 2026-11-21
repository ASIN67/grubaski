# -*- coding: utf-8 -*-
"""
Generates SQL batches to seed Supabase public.public_products table
with sanitized Polish food products from Open Food Facts and the local default catalog.
"""

import glob
import json
import os
import re

def escape_sql(val):
    if val is None:
        return 'NULL'
    if isinstance(val, str):
        cleaned = val.replace("'", "''")
        return f"'{cleaned}'"
    if isinstance(val, bool):
        return 'TRUE' if val else 'FALSE'
    if isinstance(val, (int, float)):
        return str(val)
    return f"'{val}'"

def parse_dart_categories():
    products = []
    category_files = glob.glob('lib/data/categories/*.dart')
    product_pattern = re.compile(
        r"FoodProduct\s*\(\s*id:\s*'([^']+)'\s*,"
        r"(?:\s*barcode:\s*'([^']+)'\s*,)?"
        r"\s*name:\s*'([^']+)'\s*,"
        r"(?:\s*brand:\s*'([^']+)'\s*,)?"
        r"\s*caloriesPer100g:\s*([0-9.]+)\s*,"
        r"\s*proteinPer100g:\s*([0-9.]+)\s*,"
        r"\s*carbsPer100g:\s*([0-9.]+)\s*,"
        r"\s*fatPer100g:\s*([0-9.]+)\s*,"
        r"(?:\s*fiberPer100g:\s*([0-9.]+)\s*,)?"
        r"(?:\s*servingSizeGrams:\s*([0-9.]+)\s*,)?"
        r"(?:\s*servingName:\s*'([^']+)'\s*,)?"
    )

    for fpath in category_files:
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        for match in product_pattern.finditer(content):
            p_id = match.group(1)
            barcode = match.group(2)
            name = match.group(3)
            brand = match.group(4)
            kcal = float(match.group(5))
            prot = float(match.group(6))
            carb = float(match.group(7))
            fat = float(match.group(8))
            fiber = float(match.group(9)) if match.group(9) else None
            serving_size = float(match.group(10)) if match.group(10) else 100.0
            serving_name = match.group(11)

            products.append({
                'id': p_id,
                'barcode': barcode,
                'name': name,
                'brand': brand,
                'calories_per_100g': kcal,
                'protein_per_100g': prot,
                'carbs_per_100g': carb,
                'fat_per_100g': fat,
                'fiber_per_100g': fiber,
                'serving_size_grams': serving_size,
                'serving_name': serving_name or "100g",
                'is_custom': False,
            })

    return products

def main():
    dart_products = parse_dart_categories()
    print(f"Parsed {len(dart_products)} products from local Dart catalog.")

    off_products = []
    off_file = 'scripts/curated_open_food_facts_pl.json'
    if os.path.exists(off_file):
        with open(off_file, 'r', encoding='utf-8') as f:
            off_products = json.load(f)
        print(f"Loaded {len(off_products)} products from Open Food Facts curation.")

    # Merge and deduplicate by barcode or id
    all_products = {}
    barcodes_seen = set()

    # Prioritize OFF products for barcode richness, then Dart catalog
    for p in off_products:
        barcode = p.get('barcode')
        p_id = p.get('id')
        if barcode:
            barcodes_seen.add(barcode)
        all_products[p_id] = p

    for p in dart_products:
        barcode = p.get('barcode')
        p_id = p.get('id')
        if barcode and barcode in barcodes_seen:
            continue # already present from verified OFF
        all_products[p_id] = p
        if barcode:
            barcodes_seen.add(barcode)

    print(f"Total unified catalog to seed: {len(all_products)} products ({len(barcodes_seen)} with unique barcodes).")

    # Generate SQL batches of 80 products each
    batch_size = 80
    items = list(all_products.values())
    batches = [items[i:i + batch_size] for i in range(0, len(items), batch_size)]

    os.makedirs('scripts/sql_batches', exist_ok=True)
    for idx, batch in enumerate(batches):
        values_rows = []
        for p in batch:
            row_str = (
                f"({escape_sql(p['id'])}, {escape_sql(p.get('barcode'))}, {escape_sql(p['name'])}, "
                f"{escape_sql(p.get('brand'))}, {p['calories_per_100g']}, {p['protein_per_100g']}, "
                f"{p['carbs_per_100g']}, {p['fat_per_100g']}, {escape_sql(p.get('fiber_per_100g'))}, "
                f"{p['serving_size_grams']}, {escape_sql(p.get('serving_name'))}, FALSE, now(), now())"
            )
            values_rows.append(row_str)

        sql = (
            "INSERT INTO public.public_products (\n"
            "  id, barcode, name, brand, calories_per_100g, protein_per_100g,\n"
            "  carbs_per_100g, fat_per_100g, fiber_per_100g, serving_size_grams,\n"
            "  serving_name, is_custom, created_at, updated_at\n"
            ") VALUES \n" + ",\n".join(values_rows) + "\n"
            "ON CONFLICT (id) DO UPDATE SET\n"
            "  barcode = EXCLUDED.barcode,\n"
            "  name = EXCLUDED.name,\n"
            "  brand = EXCLUDED.brand,\n"
            "  calories_per_100g = EXCLUDED.calories_per_100g,\n"
            "  protein_per_100g = EXCLUDED.protein_per_100g,\n"
            "  carbs_per_100g = EXCLUDED.carbs_per_100g,\n"
            "  fat_per_100g = EXCLUDED.fat_per_100g,\n"
            "  fiber_per_100g = EXCLUDED.fiber_per_100g,\n"
            "  serving_size_grams = EXCLUDED.serving_size_grams,\n"
            "  serving_name = EXCLUDED.serving_name,\n"
            "  updated_at = now();\n"
        )

        with open(f"scripts/sql_batches/batch_{idx:03d}.sql", 'w', encoding='utf-8') as f:
            f.write(sql)

    print(f"Generated {len(batches)} SQL batch files in scripts/sql_batches/.")

if __name__ == '__main__':
    main()
