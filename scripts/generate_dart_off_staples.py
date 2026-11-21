# -*- coding: utf-8 -*-
"""
Generates lib/data/categories/open_food_facts_staples.dart from curated_open_food_facts_pl.json
"""

import json
import re
import glob

def escape_dart_str(s: str) -> str:
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')

def parse_existing_barcodes():
    barcodes = set()
    category_files = glob.glob('lib/data/categories/*.dart')
    for fpath in category_files:
        if 'open_food_facts_staples' in fpath:
            continue
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        for m in re.finditer(r"barcode:\s*'([^']+)'", content):
            barcodes.add(m.group(1).strip())
    return barcodes

def main():
    existing_barcodes = parse_existing_barcodes()
    print(f"Existing barcodes in categories: {len(existing_barcodes)}")

    with open('scripts/curated_open_food_facts_pl.json', 'r', encoding='utf-8') as f:
        products = json.load(f)

    unique_new = []
    seen = set()
    for p in products:
        b = p.get('barcode')
        if b and (b in existing_barcodes or b in seen):
            continue
        seen.add(b)
        unique_new.append(p)

    print(f"Unique new Open Food Facts staple products to add: {len(unique_new)}")

    out_lines = [
        "// GENERATED PREDEFINED POLISH FOOD DATABASE CATEGORY",
        "// Curated Polish staple products from Open Food Facts API (with verified EAN barcodes)",
        f"// Total items: {len(unique_new)}",
        "",
        "import '../../models/food_product.dart';",
        "",
        "/// Predefined curated items from Open Food Facts API",
        "const List<FoodProduct> openFoodFactsStaples = [",
    ]

    for p in unique_new:
        b_code = f"'{escape_dart_str(p['barcode'])}'" if p.get('barcode') else "null"
        brand_str = f"'{escape_dart_str(p['brand'])}'" if p.get('brand') else "null"
        name_str = f"'{escape_dart_str(p['name'])}'"
        fiber_str = f"{p['fiber_per_100g']}" if p.get('fiber_per_100g') is not None else "null"
        serving_name_str = f"'{escape_dart_str(p['serving_name'])}'" if p.get('serving_name') else "null"

        p_id = f"seed-off-{p['barcode']}" if p.get('barcode') else f"seed-off-{p['id']}"

        out_lines.append("  FoodProduct(")
        out_lines.append(f"    id: '{escape_dart_str(p_id)}',")
        if b_code != "null":
            out_lines.append(f"    barcode: {b_code},")
        out_lines.append(f"    name: {name_str},")
        if brand_str != "null":
            out_lines.append(f"    brand: {brand_str},")
        out_lines.append(f"    caloriesPer100g: {p['calories_per_100g']},")
        out_lines.append(f"    proteinPer100g: {p['protein_per_100g']},")
        out_lines.append(f"    carbsPer100g: {p['carbs_per_100g']},")
        out_lines.append(f"    fatPer100g: {p['fat_per_100g']},")
        if fiber_str != "null":
            out_lines.append(f"    fiberPer100g: {fiber_str},")
        out_lines.append(f"    servingSizeGrams: {p['serving_size_grams']},")
        if serving_name_str != "null":
            out_lines.append(f"    servingName: {serving_name_str},")
        out_lines.append("  ),")

    out_lines.append("];")
    out_lines.append("")

    with open('lib/data/categories/open_food_facts_staples.dart', 'w', encoding='utf-8') as f:
        f.write("\n".join(out_lines))

    print("Successfully wrote lib/data/categories/open_food_facts_staples.dart")

if __name__ == '__main__':
    main()
