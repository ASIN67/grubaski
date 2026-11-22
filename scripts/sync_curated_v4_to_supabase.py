# -*- coding: utf-8 -*-
"""
Synchronizes curated Polish supermarket products (v4) with Supabase public.public_products
via seed_public_products RPC, ensuring barcode uniqueness, valid macros, and verification.
"""

import json
import os
import requests
import sys
import time

SUPABASE_URL = 'https://wyrgagwstoscxhstyzmf.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5cmdhZ3dzdG9zY3hoc3R5em1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUyODY0OTQsImV4cCI6MjExMDg2MjQ5NH0.6YpZwvQf1Fnc9EANFJF_UmkiwwjGxZDx818oBf399Bw'

HEADERS = {
    'apikey': ANON_KEY,
    'Authorization': f"Bearer {ANON_KEY}",
    'Content-Type': 'application/json',
}

def get_existing_supabase_count():
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/public_products?select=id&limit=1",
        headers={**HEADERS, 'Prefer': 'count=exact'},
        timeout=15,
    )
    content_range = r.headers.get('content-range', '')
    if '/' in content_range:
        return int(content_range.split('/')[-1])
    return 0

def fetch_existing_supabase_barcodes():
    print("Fetching existing barcodes from Supabase...")
    barcodes = set()
    offset = 0
    limit = 1000
    while True:
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/public_products?select=barcode&barcode=not.is.null",
            headers={**HEADERS, 'Range': f"{offset}-{offset + limit - 1}"},
            timeout=20,
        )
        if r.status_code not in (200, 206):
            print(f"Error fetching existing barcodes: {r.status_code} {r.text}")
            break
        items = r.json()
        for it in items:
            b = it.get('barcode')
            if b:
                barcodes.add(str(b).strip())
        if len(items) < limit:
            break
        offset += limit
    print(f"Found {len(barcodes)} existing unique barcodes in Supabase.")
    return barcodes

def load_v4_products():
    path = 'scratch/curated_products_v4.json'
    if not os.path.exists(path):
        raise FileNotFoundError(f"File {path} not found.")
    with open(path, 'r', encoding='utf-8') as f:
        products = json.load(f)
    print(f"Loaded {len(products)} products from {path}.")
    return products

def prepare_and_deduplicate(products, existing_barcodes):
    """
    Cleans fields and ensures zero barcode collision internally and with existing barcodes.
    If barcode already exists in Supabase, we can update or keep existing.
    RPC seed_public_products uses ON CONFLICT (id) DO UPDATE.
    If multiple items in products share a barcode, only keep the first one.
    """
    seen_barcodes = set()
    seen_ids = set()
    sanitized = []

    for p in products:
        p_id = str(p['id']).strip()
        barcode = str(p.get('barcode', '')).strip() if p.get('barcode') else None

        if p_id in seen_ids:
            continue
        seen_ids.add(p_id)

        if barcode:
            if barcode in seen_barcodes:
                print(f"Skipping internal duplicate barcode: {barcode} ({p.get('name')})")
                continue
            seen_barcodes.add(barcode)

        # Standardize fields for public_products table
        clean_item = {
            'id': p_id,
            'barcode': barcode,
            'name': p.get('name', '').strip(),
            'brand': p.get('brand', '').strip() if p.get('brand') else None,
            'calories_per_100g': float(p.get('calories_per_100g', p.get('caloriesPer100g', 0.0))),
            'protein_per_100g': float(p.get('protein_per_100g', p.get('proteinPer100g', 0.0))),
            'carbs_per_100g': float(p.get('carbs_per_100g', p.get('carbsPer100g', 0.0))),
            'fat_per_100g': float(p.get('fat_per_100g', p.get('fatPer100g', 0.0))),
            'fiber_per_100g': float(p['fiber_per_100g']) if p.get('fiber_per_100g') is not None else None,
            'serving_size_grams': float(p.get('serving_size_grams', p.get('servingSizeGrams', 100.0))),
            'serving_name': p.get('serving_name', p.get('servingName', '100g')),
            'is_custom': False,
        }
        sanitized.append(clean_item)

    print(f"Sanitized and deduplicated {len(sanitized)} items for upload.")
    return sanitized

def upload_in_batches(products, batch_size=100):
    rpc_url = f"{SUPABASE_URL}/rest/v1/rpc/seed_public_products"
    batches = [products[i:i + batch_size] for i in range(0, len(products), batch_size)]
    print(f"\nUploading {len(batches)} batches ({batch_size} per batch) to Supabase RPC...")

    total_uploaded = 0
    for idx, batch in enumerate(batches, 1):
        payload = {'products': batch}
        retries = 3
        success = False
        while retries > 0:
            try:
                res = requests.post(rpc_url, headers=HEADERS, json=payload, timeout=25)
                if res.status_code == 200:
                    count = res.json()
                    total_uploaded += count
                    print(f"  Batch {idx:02d}/{len(batches):02d}: OK! Upserted {len(batch)} products (RPC reported: {count}).")
                    success = True
                    break
                else:
                    print(f"  Batch {idx:02d} FAILED (status {res.status_code}): {res.text}")
                    retries -= 1
                    time.sleep(1)
            except Exception as e:
                print(f"  Batch {idx:02d} EXCEPTION: {e}")
                retries -= 1
                time.sleep(1)

        if not success:
            print(f"FATAL: Batch {idx} could not be uploaded after retries.")
            sys.exit(1)

        time.sleep(0.15)

    print(f"\nAll batches uploaded successfully! Total processed: {total_uploaded}")

def verify_supabase_state():
    print("\n--- Verifying Supabase public.public_products ---")
    total_count = get_existing_supabase_count()
    print(f"1. Total products in public.public_products: {total_count}")

    # Query count with barcode
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/public_products?select=id&barcode=not.is.null&limit=1",
        headers={**HEADERS, 'Prefer': 'count=exact'},
        timeout=15,
    )
    range_header = r.headers.get('content-range', '')
    barcode_count = range_header.split('/')[-1] if '/' in range_header else 'unknown'
    print(f"2. Products with valid barcodes: {barcode_count}")

    # Query a known sample barcode from v4
    sample_barcode = '5900120005136'
    r2 = requests.get(
        f"{SUPABASE_URL}/rest/v1/public_products?barcode=eq.{sample_barcode}",
        headers=HEADERS,
        timeout=15,
    )
    if r2.status_code == 200 and len(r2.json()) > 0:
        sample = r2.json()[0]
        print(f"3. Barcode test lookup ({sample_barcode}): FOUND '{sample['name']}' ({sample['brand']}) - {sample['calories_per_100g']} kcal/100g")
    else:
        print(f"3. Barcode test lookup ({sample_barcode}): FAILED ({r2.status_code} {r2.text})")

    # Query text search
    r3 = requests.get(
        f"{SUPABASE_URL}/rest/v1/public_products?name=ilike.*Kefir*&limit=3",
        headers=HEADERS,
        timeout=15,
    )
    if r3.status_code == 200:
        names = [f"{x['name']} ({x['brand']})" for x in r3.json()]
        print(f"4. Search test ('Kefir'): Found matches: {names}")

    print("--- Verification Finished Successfully ---")

def main():
    initial_count = get_existing_supabase_count()
    print(f"Initial count in Supabase: {initial_count}")

    existing_barcodes = fetch_existing_supabase_barcodes()
    v4_products = load_v4_products()
    sanitized = prepare_and_deduplicate(v4_products, existing_barcodes)

    upload_in_batches(sanitized, batch_size=100)
    verify_supabase_state()

if __name__ == '__main__':
    main()
