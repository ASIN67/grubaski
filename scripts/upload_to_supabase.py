# -*- coding: utf-8 -*-
"""
Uploads the complete unified catalog of Polish food products (with EAN barcodes)
to Supabase public.public_products using the seed_public_products RPC.
"""

import glob
import json
import os
import re
import requests
import time

SUPABASE_URL = 'https://wyrgagwstoscxhstyzmf.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5cmdhZ3dzdG9zY3hoc3R5em1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUyODY0OTQsImV4cCI6MjExMDg2MjQ5NH0.6YpZwvQf1Fnc9EANFJF_UmkiwwjGxZDx818oBf399Bw'

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
    print("Preparing unified Polish food catalog for Supabase...")
    dart_products = parse_dart_categories()
    print(f"Loaded {len(dart_products)} products from local categories.")

    off_products = []
    if os.path.exists('scripts/curated_open_food_facts_pl.json'):
        with open('scripts/curated_open_food_facts_pl.json', 'r', encoding='utf-8') as f:
            off_products = json.load(f)
        print(f"Loaded {len(off_products)} products from Open Food Facts JSON.")

    unified = {}
    barcodes = set()

    # Prioritize Open Food Facts items
    for p in off_products:
        unified[p['id']] = p
        if p.get('barcode'):
            barcodes.add(p['barcode'])

    for p in dart_products:
        p_id = p['id']
        barcode = p.get('barcode')
        if barcode and barcode in barcodes and p_id not in unified:
            continue
        unified[p_id] = p
        if barcode:
            barcodes.add(barcode)

    items = list(unified.values())
    print(f"Total unified catalog: {len(items)} products ({len(barcodes)} with barcodes).")

    rpc_url = f"{SUPABASE_URL}/rest/v1/rpc/seed_public_products"
    headers = {
        'apikey': ANON_KEY,
        'Authorization': f"Bearer {ANON_KEY}",
        'Content-Type': 'application/json',
    }

    batch_size = 150
    batches = [items[i:i + batch_size] for i in range(0, len(items), batch_size)]
    print(f"Uploading {len(batches)} batches of up to {batch_size} products each to Supabase...")

    total_uploaded = 0
    for idx, batch in enumerate(batches, 1):
        payload = {'products': batch}
        res = requests.post(rpc_url, headers=headers, json=payload, timeout=20)
        if res.status_code == 200:
            count = res.json()
            total_uploaded += count
            print(f"  Batch {idx}/{len(batches)}: successfully processed {len(batch)} items (response count: {count}).")
        else:
            print(f"  Batch {idx}/{len(batches)}: FAILED ({res.status_code}): {res.text}")
            break
        time.sleep(0.2)

    print(f"\nFinished uploading! Total products processed: {total_uploaded}")

if __name__ == '__main__':
    main()
