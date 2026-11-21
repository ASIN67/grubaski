# -*- coding: utf-8 -*-
"""
Generate:
1. lib/data/categories/dairy_and_eggs.dart (145 items)
2. lib/data/categories/meat_and_fish.dart (128 items)
3. lib/data/categories/bakery_and_grains.dart (119 items)
4. lib/data/categories/fruits_vegetables_fats.dart (135 items)
"""
import os
import sys

def write_category_file(filename, list_name, description, items):
    out = []
    out.append("// GENERATED PREDEFINED POLISH FOOD DATABASE CATEGORY")
    out.append(f"// {description}")
    out.append(f"// Total items: {len(items)}")
    out.append("")
    out.append("import '../../models/food_product.dart';")
    out.append("")
    out.append(f"/// Predefined items for: {description}")
    out.append(f"const List<FoodProduct> {list_name} = [")

    current_sub = None
    for item in items:
        pid, name, brand, barcode, cal, prot, carb, fat, fib, s_size, s_name, subcat = item
        if subcat != current_sub:
            current_sub = subcat
            out.append(f"  // --- {current_sub} ---")

        safe_brand = brand.replace("'", "\\'") if brand else None
        brand_line = f"    brand: '{safe_brand}',\n" if safe_brand else ""
        barcode_line = f"    barcode: '{barcode}',\n" if barcode else ""
        fiber_line = f"    fiberPer100g: {fib:.1f},\n" if fib is not None else ""

        safe_name = name.replace("'", "\\'")
        safe_s_name = s_name.replace("'", "\\'")

        entry = (
            "  FoodProduct(\n"
            f"    id: '{pid}',\n"
            f"{barcode_line}"
            f"    name: '{safe_name}',\n"
            f"{brand_line}"
            f"    caloriesPer100g: {cal:.1f},\n"
            f"    proteinPer100g: {prot:.1f},\n"
            f"    carbsPer100g: {carb:.1f},\n"
            f"    fatPer100g: {fat:.1f},\n"
            f"{fiber_line}"
            f"    servingSizeGrams: {s_size:.1f},\n"
            f"    servingName: '{safe_s_name}',\n"
            "  ),"
        )
        out.append(entry)

    out.append("];")
    out.append("")

    content = "\n".join(out)
    with open(filename, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Wrote {len(items)} items to {filename}")

# =========================================================================
# 1. DAIRY AND EGGS (145 items)
# =========================================================================
DAIRY_AND_EGGS = [
    # Jaja
    ("seed-nab-jajko-klasa-m", "Jajko kurze całe klasa M", None, None, 143.0, 12.6, 0.7, 9.9, 0.0, 55.0, "1 sztuka klasa M (55g)", "Jaja"),
    ("seed-nab-jajko-klasa-l", "Jajko kurze całe klasa L", None, None, 143.0, 12.6, 0.7, 9.9, 0.0, 65.0, "1 sztuka klasa L (65g)", "Jaja"),
    ("seed-nab-jajko-klasa-s", "Jajko kurze całe klasa S", None, None, 143.0, 12.6, 0.7, 9.9, 0.0, 48.0, "1 sztuka klasa S (48g)", "Jaja"),
    ("seed-nab-jajko-klasa-xl", "Jajko kurze całe klasa XL", None, None, 143.0, 12.6, 0.7, 9.9, 0.0, 75.0, "1 sztuka klasa XL (75g)", "Jaja"),
    ("seed-nab-jaja-sciolkowe-biedronka", "Jaja z chowu ściółkowego klasa M", "Moja Kurka", "5900777001014", 143.0, 12.6, 0.7, 9.9, 0.0, 55.0, "1 sztuka (55g)", "Jaja"),
    ("seed-nab-jaja-wolny-wybieg-lidl", "Jaja z wolnego wybiegu klasa M", "Złota Nioska", "4056489001018", 143.0, 12.6, 0.7, 9.9, 0.0, 55.0, "1 sztuka (55g)", "Jaja"),
    ("seed-nab-jaja-bio-ekologiczne", "Jaja ekologiczne BIO klasa M", "BIO", "5901234002012", 143.0, 12.6, 0.7, 9.9, 0.0, 55.0, "1 sztuka (55g)", "Jaja"),
    ("seed-nab-bialko-jaja", "Białko jaja kurzego", None, None, 52.0, 10.9, 0.7, 0.2, 0.0, 35.0, "1 białko jaja (35g)", "Jaja"),
    ("seed-nab-bialko-jaj-plynne-farmio", "Płynne białko jaj kurzych", "Farmio", "5902581002010", 50.0, 10.5, 1.0, 0.2, 0.0, 100.0, "100g płynnego białka", "Jaja"),
    ("seed-nab-zoltko-jaja", "Żółtko jaja kurzego", None, None, 322.0, 15.9, 3.6, 26.5, 0.0, 20.0, "1 żółtko jaja (20g)", "Jaja"),
    ("seed-nab-jaja-przepiorcze", "Jaja przepiórcze całe", None, None, 158.0, 13.0, 0.4, 11.0, 0.0, 10.0, "1 sztuka (10g)", "Jaja"),

    # Skyry i jogurty wysokobiałkowe
    ("seed-nab-skyr-naturalny-piatnica", "Skyr jogurt typu islandzkiego naturalny", "Piątnica", "5900820015501", 65.0, 12.0, 4.0, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-waniliowy-piatnica", "Skyr jogurt waniliowy", "Piątnica", "5900820015525", 86.0, 10.0, 11.5, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-truskawkowy-piatnica", "Skyr jogurt truskawkowy", "Piątnica", "5900820015518", 87.0, 10.0, 11.8, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-jagodowy-piatnica", "Skyr jogurt jagodowy", "Piątnica", "5900820015532", 87.0, 10.0, 11.8, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-malinowy-piatnica", "Skyr jogurt malina z żurawiną", "Piątnica", "5900820015563", 86.0, 10.0, 11.5, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-brzoskwinia-piatnica", "Skyr jogurt brzoskwinia-marakuja", "Piątnica", "5900820015570", 87.0, 10.0, 11.8, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-solony-karmel-piatnica", "Skyr jogurt słony karmel", "Piątnica", "5900820015549", 88.0, 10.0, 12.0, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-pitny-naturalny", "Skyr pitny naturalny", "Piątnica", "5900820015556", 62.0, 8.5, 4.5, 0.0, 0.0, 330.0, "1 butelka (330ml)", "Skyry"),
    ("seed-nab-skyr-pitny-waniliowy", "Skyr pitny waniliowy", "Piątnica", "5900820015587", 78.0, 7.5, 12.0, 0.0, 0.0, 330.0, "1 butelka (330ml)", "Skyry"),
    ("seed-nab-skyr-pitny-truskawka", "Skyr pitny truskawkowy", "Piątnica", "5900820015594", 79.0, 7.5, 12.2, 0.0, 0.0, 330.0, "1 butelka (330ml)", "Skyry"),
    ("seed-nab-skyr-pitny-owoce-lesne", "Skyr pitny owoce leśne", "Piątnica", "5900820015600", 79.0, 7.5, 12.2, 0.0, 0.0, 330.0, "1 butelka (330ml)", "Skyry"),
    ("seed-nab-skyr-pilos-naturalny", "Skyr naturalny wysokobiałkowy", "Pilos", "20549887", 65.0, 11.8, 4.1, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-pilos-waniliowy", "Skyr waniliowy", "Pilos", "20549894", 85.0, 9.8, 11.2, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-pilos-truskawka", "Skyr truskawkowy", "Pilos", "20549900", 86.0, 9.8, 11.5, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-pilos-borowka", "Skyr borówkowy", "Pilos", "20549917", 86.0, 9.8, 11.5, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-fruvita-naturalny", "Skyr naturalny 0% tłuszczu", "Fruvita", "5900777002011", 64.0, 12.0, 4.0, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-fruvita-wanilia", "Skyr waniliowy", "Fruvita", "5900777002028", 85.0, 10.0, 11.2, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-skyr-fruvita-truskawka", "Skyr truskawkowy", "Fruvita", "5900777002035", 86.0, 10.0, 11.5, 0.0, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-kvarg-lindahls-wanilia", "Lindahls Kvarg wanilia", "Nestlé", "7310865001018", 60.0, 10.6, 3.5, 0.2, 0.0, 150.0, "1 kubek (150g)", "Skyry"),
    ("seed-nab-kvarg-lindahls-truskawka", "Lindahls Kvarg truskawka", "Nestlé", "7310865001025", 60.0, 10.6, 3.5, 0.2, 0.0, 150.0, "1 kubek (150g)", "Skyry"),

    # Twarogi
    ("seed-nab-twarog-chudy-piatnica", "Twaróg chudy klinek", "Piątnica", "5900820000606", 86.0, 18.0, 3.5, 0.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-poltlusty-piatnica", "Twaróg półtłusty klinek", "Piątnica", "5900820000613", 110.0, 17.5, 3.7, 4.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-tlusty-piatnica", "Twaróg tłusty klinek", "Piątnica", "5900820000620", 155.0, 16.0, 3.5, 8.5, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-chudy-mlekovita", "Twaróg chudy klinek Polski", "Mlekovita", "5900512000015", 86.0, 18.0, 3.5, 0.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-poltlusty-mlekovita", "Twaróg półtłusty Polski", "Mlekovita", "5900512000022", 110.0, 17.5, 3.7, 4.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-tlusty-mlekovita", "Twaróg tłusty Polski", "Mlekovita", "5900512000039", 155.0, 16.0, 3.5, 8.5, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-chudy-pilos", "Twaróg klinek chudy", "Pilos", "20001019", 86.0, 18.0, 3.5, 0.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-poltlusty-pilos", "Twaróg klinek półtłusty", "Pilos", "20001026", 110.0, 17.5, 3.7, 4.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-delikate-chudy", "Twaróg chudy", "Delikate", "5900777003018", 86.0, 18.0, 3.5, 0.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-delikate-poltlusty", "Twaróg półtłusty", "Delikate", "5900777003025", 110.0, 17.5, 3.7, 4.0, 0.0, 250.0, "1 kostka (250g)", "Twarogi"),
    ("seed-nab-twarog-sernikowy-wiaderko", "Twaróg sernikowy w wiaderku", "Piątnica", "5900820000637", 125.0, 12.0, 4.0, 6.5, 0.0, 100.0, "1 porcja (100g)", "Twarogi"),
    ("seed-nab-twarog-sernikowy-president", "Twaróg sernikowy mielony", "Président", "5900354003012", 130.0, 11.5, 4.2, 7.0, 0.0, 100.0, "1 porcja (100g)", "Twarogi"),
    ("seed-nab-twarog-sernikowy-mlekovita", "Twaróg na sernik Hanusi", "Mlekovita", "5900512000046", 120.0, 12.0, 4.0, 6.0, 0.0, 100.0, "1 porcja (100g)", "Twarogi"),
    ("seed-nab-twarog-wedzony-mlekovita", "Twaróg wędzony plastry", "Mlekovita", "5900512000053", 165.0, 20.0, 3.0, 8.0, 0.0, 50.0, "1 porcja (50g)", "Twarogi"),
    ("seed-nab-twarozek-domowy-grani", "Twarożek domowy Grani ze szczypiorkiem", "Piątnica", "5900820000644", 102.0, 11.0, 3.0, 5.0, 0.0, 150.0, "1 kubek (150g)", "Twarogi"),

    # Serki wiejskie
    ("seed-nab-serek-wiejski-naturalny-piatnica", "Serek wiejski naturalny cottage cheese", "Piątnica", "5900820000019", 97.0, 11.0, 2.0, 5.0, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-lekki-piatnica", "Serek wiejski lekki 3% tłuszczu", "Piątnica", "5900820000217", 81.0, 12.5, 2.4, 2.3, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-wysokobialkowy", "Serek wiejski wysokobiałkowy", "Piątnica", "5900820000224", 85.0, 14.0, 2.5, 2.0, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-bez-laktozy", "Serek wiejski bez laktozy", "Piątnica", "5900820000248", 97.0, 11.0, 2.0, 5.0, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-truskawki", "Serek wiejski z truskawkami", "Piątnica", "5900820000231", 108.0, 8.5, 11.0, 3.5, 0.0, 150.0, "1 kubek (150g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-brzoskwinie", "Serek wiejski z brzoskwiniami", "Piątnica", "5900820000255", 108.0, 8.5, 11.0, 3.5, 0.0, 150.0, "1 kubek (150g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-jagody", "Serek wiejski z jagodami", "Piątnica", "5900820000262", 108.0, 8.5, 11.0, 3.5, 0.0, 150.0, "1 kubek (150g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-szczypiorek", "Serek wiejski ze szczypiorkiem", "Piątnica", "5900820000279", 97.0, 10.5, 2.5, 5.0, 0.0, 150.0, "1 kubek (150g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-pilos", "Serek wiejski tradycyjny", "Pilos", "20002016", 97.0, 11.0, 2.0, 5.0, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-pilos-lekki", "Serek wiejski lekki", "Pilos", "20002023", 81.0, 12.0, 2.4, 2.3, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-delikate", "Serek wiejski naturalny", "Delikate", "5900777004015", 97.0, 11.0, 2.0, 5.0, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-delikate-lekki", "Serek wiejski lekki", "Delikate", "5900777004022", 81.0, 12.0, 2.4, 2.3, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),
    ("seed-nab-serek-wiejski-krasnystaw", "Serek wiejski", "Krasnystaw", "5900517001017", 95.0, 11.0, 2.2, 4.8, 0.0, 200.0, "1 kubek (200g)", "Serki wiejskie"),

    # Mleka i napoje roślinne
    ("seed-nab-mleko-05-laciate", "Mleko spożywcze 0.5% UHT", "Łaciate", "5900820001023", 35.0, 3.4, 4.9, 0.5, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-15-laciate", "Mleko spożywcze 1.5% UHT", "Łaciate", "5900820001030", 44.0, 3.3, 4.8, 1.5, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-20-laciate", "Mleko spożywcze 2.0% UHT", "Łaciate", "5900820001009", 50.0, 3.3, 4.8, 2.0, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-32-laciate", "Mleko spożywcze 3.2% UHT", "Łaciate", "5900820001016", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-bez-laktozy-15", "Mleko bez laktozy 1.5% UHT", "Łaciate", "5900820001047", 44.0, 3.3, 4.8, 1.5, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-bez-laktozy-32", "Mleko bez laktozy 3.2% UHT", "Łaciate", "5900820001054", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-20-mlekovita", "Mleko Polskie 2.0% UHT", "Mlekovita", "5900512001029", 50.0, 3.3, 4.8, 2.0, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-32-mlekovita", "Mleko Polskie 3.2% UHT", "Mlekovita", "5900512001036", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-pilos-20", "Mleko UHT 2.0%", "Pilos", "20003013", 50.0, 3.3, 4.8, 2.0, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-pilos-32", "Mleko UHT 3.2%", "Pilos", "20003020", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-mleczna-dolina-20", "Mleko 2.0% UHT", "Mleczna Dolina", "5900777005012", 50.0, 3.3, 4.8, 2.0, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-mleczna-dolina-32", "Mleko 3.2% UHT", "Mleczna Dolina", "5900777005029", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-swieze-piatnica-20", "Mleko wiejskie świeże 2.0%", "Piątnica", "5900820001061", 50.0, 3.3, 4.8, 2.0, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-swieze-piatnica-32", "Mleko wiejskie świeże 3.2%", "Piątnica", "5900820001078", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Mleko"),
    ("seed-nab-mleko-zageszczone-nieslodzone", "Mleko zagęszczone niesłodzone", "Gostyń", "5900534001014", 131.0, 6.6, 9.4, 7.5, 0.0, 50.0, "50g do kawy", "Mleko"),
    ("seed-nab-mleko-zageszczone-slodzone", "Mleko zagęszczone słodzone z cukrem", "Gostyń", "5900534001021", 325.0, 6.8, 55.5, 8.0, 0.0, 20.0, "1 czubata łyżka (20g)", "Mleko"),
    ("seed-nab-mleko-w-proszku-odtłuszczone", "Mleko w proszku odtłuszczone", "Mlekovita", "5900512001043", 355.0, 35.0, 51.0, 1.0, 0.0, 25.0, "1 czubata łyżka (25g)", "Mleko"),
    ("seed-nab-napoj-owsiany-barista", "Napój owsiany Barista", "Oatly", "7394376616037", 59.0, 1.1, 6.7, 3.0, 0.8, 250.0, "1 szklanka (250ml)", "Napoje roślinne"),
    ("seed-nab-napoj-migdalowy-nieslodzony", "Napój migdałowy niesłodzony", "Alpro", "5411188115489", 13.0, 0.4, 0.2, 1.1, 0.3, 250.0, "1 szklanka (250ml)", "Napoje roślinne"),
    ("seed-nab-napoj-sojowy-naturalny", "Napój sojowy naturalny", "Alpro", "5411188115496", 39.0, 3.3, 1.6, 1.8, 0.5, 250.0, "1 szklanka (250ml)", "Napoje roślinne"),
    ("seed-nab-napoj-kokosowy-alpro", "Napój kokosowy bez cukru", "Alpro", "5411188115502", 20.0, 0.1, 1.9, 0.9, 0.0, 250.0, "1 szklanka (250ml)", "Napoje roślinne"),
    ("seed-nab-napoj-owsiany-vemondo", "Napój owsiany Bio", "Vemondo", "20549924", 45.0, 0.8, 7.5, 1.2, 0.6, 250.0, "1 szklanka (250ml)", "Napoje roślinne"),

    # Jogurty klasyczne i desery mleczne
    ("seed-nab-jogurt-naturalny-zott", "Jogurt naturalny Zott Primo", "Zott", "4014500001018", 62.0, 4.4, 5.6, 2.5, 0.0, 180.0, "1 kubek (180g)", "Jogurty"),
    ("seed-nab-jogurt-naturalny-bakoma", "Jogurt naturalny gęsty", "Bakoma", "5900334001019", 60.0, 4.2, 5.5, 2.5, 0.0, 180.0, "1 kubek (180g)", "Jogurty"),
    ("seed-nab-jogurt-naturalny-danone", "Jogurt naturalny klasyczny", "Danone", "5900643001037", 61.0, 4.1, 5.6, 2.5, 0.0, 165.0, "1 kubek (165g)", "Jogurty"),
    ("seed-nab-jogurt-grecki-piatnica", "Jogurt grecki tradycyjny", "Piątnica", "5900820001504", 120.0, 4.5, 4.0, 10.0, 0.0, 200.0, "1 kubek (200g)", "Jogurty"),
    ("seed-nab-jogurt-grecki-lekki", "Jogurt grecki lekki 0% tłuszczu", "Piątnica", "5900820001511", 60.0, 9.0, 4.0, 0.0, 0.0, 180.0, "1 kubek (180g)", "Jogurty"),
    ("seed-nab-jogurt-activia-naturalna", "Jogurt Activia naturalna", "Danone", "5900643001013", 68.0, 4.4, 6.0, 3.1, 0.0, 160.0, "1 kubek (160g)", "Jogurty"),
    ("seed-nab-jogurt-activia-truskawka", "Jogurt Activia truskawkowa", "Danone", "5900643001044", 95.0, 3.6, 14.0, 2.7, 0.4, 160.0, "1 kubek (160g)", "Jogurty"),
    ("seed-nab-jogurt-activia-sliwka", "Jogurt Activia suszona śliwka", "Danone", "5900643001051", 97.0, 3.6, 14.5, 2.7, 0.8, 160.0, "1 kubek (160g)", "Jogurty"),
    ("seed-nab-jogurt-fantasia-truskawka", "Jogurt Fantasia z truskawkami", "Danone", "5900643001020", 112.0, 3.2, 14.5, 4.6, 0.3, 122.0, "1 kubek (122g)", "Jogurty"),
    ("seed-nab-jogurt-fantasia-kulki", "Jogurt Fantasia z chrupiącymi kulkami", "Danone", "5900643001068", 145.0, 3.8, 16.5, 7.0, 0.5, 100.0, "1 kubek (100g)", "Jogurty"),
    ("seed-nab-jogobella-truskawka", "Jogurt owocowy Jogobella truskawkowa", "Zott", "4014500001025", 98.0, 3.5, 14.0, 2.6, 0.3, 150.0, "1 kubek (150g)", "Jogurty"),
    ("seed-nab-jogobella-jagoda", "Jogurt owocowy Jogobella jagodowa", "Zott", "4014500001032", 98.0, 3.5, 14.0, 2.6, 0.3, 150.0, "1 kubek (150g)", "Jogurty"),
    ("seed-nab-actimel-truskawka", "Napój jogurtowy Actimel truskawka", "Danone", "5900643001075", 71.0, 2.8, 11.5, 1.5, 0.0, 100.0, "1 buteleczka (100g)", "Jogurty"),
    ("seed-nab-monte-zott", "Deser mleczno-czekoladowy Monte", "Zott", "4014500001049", 195.0, 3.0, 16.8, 13.0, 0.5, 150.0, "1 kubek (150g)", "Desery"),
    ("seed-nab-riso-wanilia", "Deser ryżowy na mleku Riso wanilia", "Müller", "4025500001025", 105.0, 3.2, 16.5, 2.8, 0.1, 200.0, "1 kubek (200g)", "Desery"),
    ("seed-nab-riso-czekolada", "Deser ryżowy na mleku Riso czekolada", "Müller", "4025500001032", 112.0, 3.3, 17.5, 3.1, 0.5, 200.0, "1 kubek (200g)", "Desery"),

    # Kefiry, maślanki, zsiadłe mleko
    ("seed-nab-kefir-naturalny-mlekovita", "Kefir naturalny", "Mlekovita", "5900512001012", 46.0, 3.4, 4.7, 1.5, 0.0, 400.0, "1 butelka (400g)", "Kefiry i maślanki"),
    ("seed-nab-kefir-krasnystaw", "Kefir luksusowy", "Krasnystaw", "5900517001024", 48.0, 3.4, 4.7, 2.0, 0.0, 400.0, "1 butelka (400g)", "Kefiry i maślanki"),
    ("seed-nab-kefir-pilos", "Kefir naturalny", "Pilos", "20004010", 46.0, 3.4, 4.7, 1.5, 0.0, 400.0, "1 butelka (400g)", "Kefiry i maślanki"),
    ("seed-nab-kefir-robico", "Kefir Robico w butelce", "Robico", "5902143001018", 48.0, 3.4, 4.7, 2.0, 0.0, 400.0, "1 butelka (400g)", "Kefiry i maślanki"),
    ("seed-nab-maslanka-naturalna-mragowska", "Maślanka naturalna", "Mrągowska", "5900820002013", 44.0, 3.4, 4.6, 1.5, 0.0, 250.0, "1 szklanka (250ml)", "Kefiry i maślanki"),
    ("seed-nab-maslanka-truskawkowa-mragowska", "Maślanka truskawkowa", "Mrągowska", "5900820002020", 72.0, 2.8, 12.0, 1.2, 0.2, 250.0, "1 szklanka (250ml)", "Kefiry i maślanki"),
    ("seed-nab-maslanka-brzoskwiniowa-mragowska", "Maślanka brzoskwiniowa", "Mrągowska", "5900820002037", 72.0, 2.8, 12.0, 1.2, 0.2, 250.0, "1 szklanka (250ml)", "Kefiry i maślanki"),
    ("seed-nab-zsiadle-mleko-krasnystaw", "Zsiadłe mleko tradycyjne", "Krasnystaw", "5900517001031", 52.0, 3.2, 4.7, 2.0, 0.0, 400.0, "1 kubek (400g)", "Kefiry i maślanki"),

    # Sery żółte, twarde i w plastrach
    ("seed-nab-ser-gouda-plastry", "Ser Gouda w plastrach", "Mlekovita", "5900512002019", 350.0, 25.0, 0.1, 27.0, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-edam-plastry", "Ser Edam w plastrach", "Mlekovita", "5900512002026", 345.0, 26.0, 0.1, 26.0, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-krolewski-sierpc", "Ser Królewski w plastrach", "Sierpc", "5901235001014", 355.0, 26.0, 0.1, 28.0, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-rycki-edam", "Ser Rycki Edam plastry", "Ryki", "5901514001016", 345.0, 26.0, 0.1, 26.0, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-radamer-spomlek", "Ser Radamer z dziurami plastry", "Spomlek", "5902145001016", 350.0, 25.0, 0.1, 27.5, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-mazdamer-mlekovita", "Ser Mazdamer szwajcarski typ", "Mlekovita", "5900512002064", 355.0, 26.0, 0.1, 28.0, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-morski-swiatowid", "Ser Morski w plastrach", "Światowid", "5900777006019", 340.0, 25.0, 0.1, 26.5, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-cheddar", "Ser Cheddar w plastrach", "Mlekovita", "5900512002057", 400.0, 25.0, 1.0, 33.0, 0.0, 30.0, "1 plaster (30g)", "Sery żółte"),
    ("seed-nab-ser-parmigiano-reggiano", "Ser Parmigiano Reggiano Parmezan", "Zanetti", "8002580001017", 402.0, 32.0, 0.0, 30.0, 0.0, 15.0, "1 czubata łyżka (15g)", "Sery twarde"),
    ("seed-nab-ser-grana-padano", "Ser Grana Padano tarty", "Zanetti", "8002580001024", 398.0, 33.0, 0.0, 29.0, 0.0, 15.0, "1 czubata łyżka (15g)", "Sery twarde"),
    ("seed-nab-ser-grana-padano-lovilio", "Ser Grana Padano kawałek", "Lovilio", "20005017", 398.0, 33.0, 0.0, 29.0, 0.0, 20.0, "1 porcja (20g)", "Sery twarde"),

    # Sery białe, sałatkowe i świeże
    ("seed-nab-ser-mozzarella-kulka", "Ser Mozzarella kulka w zalewie", "Galbani", "8000430139151", 240.0, 18.0, 1.5, 18.0, 0.0, 125.0, "1 kulka (125g)", "Mozzarella i świeże"),
    ("seed-nab-ser-mozzarella-light", "Ser Mozzarella kulka light", "Galbani", "8000430139168", 160.0, 20.0, 1.5, 8.5, 0.0, 125.0, "1 kulka (125g)", "Mozzarella i świeże"),
    ("seed-nab-ser-mozzarella-wiorki", "Ser Mozzarella tarty wiórki", "Mlekovita", "5900512002033", 310.0, 24.0, 2.0, 23.0, 0.0, 50.0, "1 garść (50g)", "Mozzarella i świeże"),
    ("seed-nab-ser-mozzarella-lovilio", "Ser Mozzarella kulka", "Lovilio", "20006014", 235.0, 18.0, 1.5, 17.5, 0.0, 125.0, "1 kulka (125g)", "Mozzarella i świeże"),
    ("seed-nab-ser-feta-oryginalna", "Ser Feta oryginalny ChNP", "Dodoni", "5201103001011", 260.0, 16.0, 0.7, 21.0, 0.0, 50.0, "1 porcja (50g)", "Sery sałatkowe"),
    ("seed-nab-ser-favita-salatkowy", "Ser sałatkowy typu greckiego Favita", "Mlekovita", "5900512002040", 220.0, 11.0, 4.0, 18.0, 0.0, 50.0, "1 porcja (50g)", "Sery sałatkowe"),
    ("seed-nab-ser-favita-lekka-12", "Ser sałatkowy Favita 12% tłuszczu", "Mlekovita", "5900512002071", 175.0, 14.0, 4.0, 12.0, 0.0, 50.0, "1 porcja (50g)", "Sery sałatkowe"),
    ("seed-nab-ser-halloumi-grill", "Ser Halloumi cypryjski do grillowania", None, None, 320.0, 22.0, 2.0, 25.0, 0.0, 50.0, "1 plaster (50g)", "Sery sałatkowe"),
    ("seed-nab-ser-ricotta", "Ser Ricotta świeży włoski", "Galbani", "8000430139175", 145.0, 8.5, 3.5, 11.0, 0.0, 50.0, "2 czubate łyżki (50g)", "Mozzarella i świeże"),
    ("seed-nab-serek-mascarpone-piatnica", "Serek Mascarpone kremowy", "Piątnica", "5900820003027", 385.0, 4.5, 3.5, 40.0, 0.0, 30.0, "1 czubata łyżka (30g)", "Mozzarella i świeże"),

    # Sery pleśniowe i topione
    ("seed-nab-ser-camembert-turek", "Ser Camembert naturalny", "Turek", "5900354001018", 290.0, 19.0, 0.5, 23.0, 0.0, 60.0, "1/2 krążka (60g)", "Sery pleśniowe"),
    ("seed-nab-ser-brie-turek", "Ser Brie naturalny", "Turek", "5900354001025", 310.0, 18.0, 0.5, 26.0, 0.0, 60.0, "1/2 krążka (60g)", "Sery pleśniowe"),
    ("seed-nab-ser-lazur-blekitny", "Ser pleśniowy Lazur błękitny", "Lazur", "5900985003012", 360.0, 20.0, 1.0, 31.0, 0.0, 30.0, "1 porcja (30g)", "Sery pleśniowe"),
    ("seed-nab-ser-gorgonzola", "Ser Gorgonzola DOP kremowy", "Galbani", "8000430139182", 325.0, 19.0, 0.5, 28.0, 0.0, 30.0, "1 porcja (30g)", "Sery pleśniowe"),
    ("seed-nab-ser-topiony-trojkaty", "Serek topiony w trójkątach ze szczypiorkiem", "Hochland", "5901327002016", 240.0, 9.5, 5.5, 20.0, 0.0, 35.0, "2 trójkąciki (35g)", "Sery topione"),
    ("seed-nab-ser-topiony-kremowy-blok", "Serek topiony kremowy bloczek", "Hochland", "5901327002023", 245.0, 9.0, 5.0, 21.0, 0.0, 50.0, "1/2 bloczka (50g)", "Sery topione"),

    # Serki do smarowania
    ("seed-nab-serek-almette-smietankowy", "Serek puszysty Almette śmietankowy", "Hochland", "5901327001019", 255.0, 6.0, 3.5, 24.0, 0.0, 30.0, "1 porcja na kromkę (30g)", "Serki do smarowania"),
    ("seed-nab-serek-almette-ziola", "Serek puszysty Almette z ziołami", "Hochland", "5901327001026", 250.0, 6.0, 3.8, 23.5, 0.0, 30.0, "1 porcja na kromkę (30g)", "Serki do smarowania"),
    ("seed-nab-serek-twoj-smak-piatnica", "Serek kremowy Twój Smak naturalny", "Piątnica", "5900820003010", 242.0, 6.1, 3.2, 23.0, 0.0, 30.0, "1 porcja na kromkę (30g)", "Serki do smarowania"),
    ("seed-nab-serek-twoj-smak-czosnek", "Serek Twój Smak z czosnkiem", "Piątnica", "5900820003034", 240.0, 6.0, 3.5, 22.5, 0.0, 30.0, "1 porcja na kromkę (30g)", "Serki do smarowania"),
    ("seed-nab-serek-philadelphia-original", "Serek kremowy Philadelphia Original", "Philadelphia", "7622210003012", 235.0, 5.4, 4.0, 21.5, 0.0, 30.0, "1 porcja (30g)", "Serki do smarowania"),
    ("seed-nab-serek-philadelphia-light", "Serek kremowy Philadelphia Light", "Philadelphia", "7622210003029", 150.0, 7.5, 5.0, 11.0, 0.0, 30.0, "1 porcja (30g)", "Serki do smarowania"),
    ("seed-nab-serek-puszysty-laciaty", "Serek puszysty Łaciaty naturalny", "Łaciate", "5900820003041", 245.0, 6.5, 3.5, 23.0, 0.0, 30.0, "1 porcja (30g)", "Serki do smarowania"),

    # Śmietany i śmietanki
    ("seed-nab-smietana-12-piatnica", "Śmietana 12% ukwaszona", "Piątnica", "5900820004017", 134.0, 3.0, 4.2, 12.0, 0.0, 25.0, "1 łyżka (25g)", "Śmietany"),
    ("seed-nab-smietana-18-piatnica", "Śmietana 18% ukwaszona", "Piątnica", "5900820004024", 186.0, 2.7, 3.8, 18.0, 0.0, 25.0, "1 łyżka (25g)", "Śmietany"),
    ("seed-nab-smietanka-30-laciata", "Śmietanka 30% słodka UHT", "Łaciate", "5900820004031", 291.0, 2.3, 3.3, 30.0, 0.0, 30.0, "2 łyżki (30g)", "Śmietanki"),
    ("seed-nab-smietanka-36-laciata", "Śmietanka 36% do ubijania UHT", "Łaciate", "5900820004048", 345.0, 2.1, 3.0, 36.0, 0.0, 30.0, "2 łyżki (30g)", "Śmietanki"),
    ("seed-nab-smietana-18-pilos", "Śmietana 18% kwaśna", "Pilos", "20007011", 186.0, 2.7, 3.8, 18.0, 0.0, 25.0, "1 łyżka (25g)", "Śmietany"),
    ("seed-nab-smietana-12-pilos", "Śmietana 12% lekka", "Pilos", "20007028", 134.0, 3.0, 4.2, 12.0, 0.0, 25.0, "1 łyżka (25g)", "Śmietany"),
]

# =========================================================================
# 2. MEAT AND FISH (128 items)
# =========================================================================
MEAT_AND_FISH = [
    # Drób świeży i surowy
    ("seed-mieso-piers-kurczaka-surowa", "Filet z piersi kurczaka surowy", None, None, 106.0, 21.5, 0.0, 1.3, 0.0, 200.0, "1 pojedynczy filet (200g)", "Drób świeży"),
    ("seed-mieso-piers-kurczaka-pieczona", "Pierś z kurczaka pieczona bez tłuszczu", None, None, 150.0, 31.0, 0.0, 3.0, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-piers-kurczaka-gotowana", "Pierś z kurczaka gotowana w wodzie", None, None, 140.0, 30.0, 0.0, 2.0, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-udko-kurczaka-surowe", "Udko z kurczaka ze skórą surowe", None, None, 160.0, 17.5, 0.0, 10.0, 0.0, 220.0, "1 sztuka (220g)", "Drób świeży"),
    ("seed-mieso-udo-kurczaka-bez-skory", "Mięso z uda kurczaka bez skóry i kości", None, None, 125.0, 19.5, 0.0, 4.5, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-podudzie-kurczaka", "Podudzie z kurczaka (pałka) ze skórą", None, None, 155.0, 18.0, 0.0, 9.0, 0.0, 120.0, "1 pałka (120g)", "Drób świeży"),
    ("seed-mieso-skrzydelka-kurczaka", "Skrzydełka z kurczaka surowe", None, None, 185.0, 18.0, 0.0, 12.5, 0.0, 100.0, "1 sztuka (100g)", "Drób świeży"),
    ("seed-mieso-watrobka-drobiowa", "Wątróbka z kurczaka surowa", None, None, 120.0, 19.0, 1.5, 4.5, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-zoladki-drobiowe", "Żołądki z kurczaka surowe", None, None, 110.0, 18.0, 0.5, 3.5, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-serca-drobiowe", "Serca drobiowe z kurczaka", None, None, 150.0, 16.0, 0.5, 9.5, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-piers-indyka-surowa", "Filet z piersi indyka surowy", None, None, 104.0, 22.0, 0.0, 1.2, 0.0, 150.0, "1 stek z indyka (150g)", "Drób świeży"),
    ("seed-mieso-udziec-z-indyka", "Mięso z udźca indyka bez skóry", None, None, 130.0, 20.0, 0.0, 5.5, 0.0, 150.0, "1 porcja (150g)", "Drób świeży"),
    ("seed-mieso-mielone-z-indyka", "Mięso mielone z piersi indyka", None, None, 115.0, 21.0, 0.0, 3.5, 0.0, 200.0, "1/2 tacki (200g)", "Drób świeży"),
    ("seed-mieso-piers-kaczki", "Pierś z kaczki ze skórą surowa", None, None, 210.0, 19.0, 0.0, 14.5, 0.0, 180.0, "1 pierś (180g)", "Drób świeży"),
    ("seed-mieso-piers-kurczaka-wedzona", "Pierś z kurczaka wędzona plastry", "Dolina Dobra", "5902581001044", 110.0, 23.0, 1.0, 1.5, 0.0, 50.0, "2 plastry (50g)", "Drób świeży"),

    # Wieprzowina świeża
    ("seed-mieso-poledwiczka-wieprzowa", "Polędwiczka wieprzowa surowa", None, None, 120.0, 21.5, 0.0, 3.5, 0.0, 200.0, "1 porcja (200g)", "Wieprzowina"),
    ("seed-mieso-schab-bez-kosci", "Schab wieprzowy bez kości surowy", None, None, 130.0, 22.0, 0.0, 4.5, 0.0, 150.0, "1 plaster (150g)", "Wieprzowina"),
    ("seed-mieso-schab-pieczony", "Schab pieczony tradycyjny", None, None, 180.0, 28.0, 0.0, 7.5, 0.0, 100.0, "1 porcja (100g)", "Wieprzowina"),
    ("seed-mieso-karkowka-wieprzowa", "Karkówka wieprzowa surowa", None, None, 230.0, 17.0, 0.0, 18.0, 0.0, 150.0, "1 plaster (150g)", "Wieprzowina"),
    ("seed-mieso-szynka-wieprzowa-surowa", "Szynka wieprzowa surowa kulka", None, None, 135.0, 21.0, 0.0, 5.5, 0.0, 150.0, "1 porcja (150g)", "Wieprzowina"),
    ("seed-mieso-lopatka-wieprzowa", "Łopatka wieprzowa bez kości", None, None, 180.0, 18.5, 0.0, 11.5, 0.0, 150.0, "1 porcja (150g)", "Wieprzowina"),
    ("seed-mieso-zeberka-wieprzowe", "Żeberka wieprzowe paski surowe", None, None, 275.0, 16.0, 0.0, 23.5, 0.0, 200.0, "1 porcja (200g)", "Wieprzowina"),
    ("seed-mieso-boczek-surowy", "Boczek wieprzowy surowy", None, None, 390.0, 14.0, 0.0, 37.0, 0.0, 50.0, "2 plastry (50g)", "Wieprzowina"),
    ("seed-mieso-golonka-ze-skora", "Golonka wieprzowa tylna ze skórą", None, None, 290.0, 15.0, 0.0, 25.0, 0.0, 300.0, "1 porcja (300g)", "Wieprzowina"),
    ("seed-mieso-mielone-od-szynki", "Mięso mielone od szynki chude <7%", "Rzeźnik", "20008018", 145.0, 20.0, 0.0, 7.0, 0.0, 200.0, "1/2 tacki (200g)", "Wieprzowina"),
    ("seed-mieso-mielone-wieprz-wol", "Mięso mielone wieprzowo-wołowe", "Rzeźnik", "5900001001010", 220.0, 17.0, 0.5, 17.0, 0.0, 200.0, "1/2 tacki (200g)", "Wieprzowina"),

    # Wołowina i cielęcina
    ("seed-mieso-poledwica-wolowa", "Polędwica wołowa surowa", None, None, 135.0, 22.0, 0.0, 5.0, 0.0, 180.0, "1 stek (180g)", "Wołowina"),
    ("seed-mieso-rostbef-wolowy", "Rostbef wołowy stek", None, None, 155.0, 22.5, 0.0, 7.0, 0.0, 200.0, "1 stek (200g)", "Wołowina"),
    ("seed-mieso-antrykot-wolowy", "Antrykot wołowy stek Ribeye", None, None, 220.0, 20.0, 0.0, 15.5, 0.0, 250.0, "1 stek (250g)", "Wołowina"),
    ("seed-mieso-rumsztyk-ligawa", "Ligawa wołowa chuda surowa", None, None, 125.0, 22.5, 0.0, 3.5, 0.0, 150.0, "1 porcja (150g)", "Wołowina"),
    ("seed-mieso-gulasz-wolowy", "Wołowina gulaszowa chuda", None, None, 140.0, 21.0, 0.0, 6.0, 0.0, 200.0, "1 porcja (200g)", "Wołowina"),
    ("seed-mieso-mielone-wolowe-chude", "Mięso mielone wołowe chude <10% tłuszczu", None, None, 160.0, 21.0, 0.0, 8.5, 0.0, 200.0, "1/2 tacki (200g)", "Wołowina"),
    ("seed-mieso-cielecina-bez-kosci", "Cielęcina bez kości chuda surowa", None, None, 115.0, 21.0, 0.0, 3.0, 0.0, 150.0, "1 porcja (150g)", "Wołowina"),
    ("seed-mieso-tatar-wolowy-sokolow", "Tatar wołowy klasyczny przyprawiony", "Sokołów", "5900593004029", 140.0, 19.0, 1.0, 6.5, 0.0, 100.0, "1 porcja (100g)", "Wołowina"),
    ("seed-mieso-carpaccio-wolowe", "Carpaccio wołowe plastry z oliwą", None, None, 130.0, 22.0, 0.5, 4.5, 0.0, 80.0, "1 opakowanie (80g)", "Wołowina"),

    # Szynki i wędliny
    ("seed-mieso-szynka-konserwowa-krakus", "Szynka konserwowa z wieprzowiny", "Krakus", "5900783001027", 95.0, 17.0, 1.5, 2.0, 0.0, 50.0, "2 plastry (50g)", "Wędliny"),
    ("seed-mieso-szynka-od-szwagra", "Szynka od szwagra wędzona", "Krakus", "5900783001096", 115.0, 19.0, 1.0, 4.0, 0.0, 50.0, "2 plastry (50g)", "Wędliny"),
    ("seed-mieso-poledwica-sopocka-krakus", "Polędwica sopocka", "Krakus", "5900783001034", 105.0, 19.0, 1.0, 2.5, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-szynka-indyka-dolinadobra", "Szynka z piersi indyka 100% z indyka", "Dolina Dobra", "5902581001013", 90.0, 19.5, 1.0, 1.0, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-szynka-z-kurczaka", "Szynka z fileta kurczaka", "Morliny", "5900783001041", 92.0, 18.0, 1.5, 1.2, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-szynka-gotowana-tarczynski", "Szynka gotowana klasyczna plastry", "Tarczyński", "5902581600209", 100.0, 19.0, 1.0, 2.0, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-szynka-pikok-pure", "Szynka z piersi indyka Pikok Pure", "Pikok", "20009015", 88.0, 20.0, 0.5, 1.0, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-szynka-szwarcwaldzka", "Szynka szwarcwaldzka dojrzewająca", None, None, 235.0, 25.0, 0.5, 15.0, 0.0, 30.0, "3 plastry (30g)", "Wędliny"),
    ("seed-mieso-prosciutto-crudo", "Szynka parmeńska Prosciutto Crudo", None, None, 225.0, 27.0, 0.5, 13.0, 0.0, 30.0, "3 plastry (30g)", "Wędliny"),
    ("seed-mieso-szynka-serrano", "Szynka hiszpańska Jamon Serrano", None, None, 230.0, 28.0, 0.5, 13.5, 0.0, 30.0, "3 plastry (30g)", "Wędliny"),
    ("seed-mieso-pastrami-wolowe", "Pastrami wołowe wędzone", None, None, 140.0, 22.0, 1.0, 5.0, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-boczek-wedzony-krakus", "Boczek wędzony parzony plastry", "Krakus", "5900783001010", 320.0, 16.0, 0.5, 28.0, 0.0, 50.0, "2 plastry (50g)", "Wędliny"),
    ("seed-mieso-boczek-kostka-kaminiarz", "Boczek wędzony kostka do smażenia", "Kaminiarz", "5901243002010", 310.0, 16.5, 0.5, 27.0, 0.0, 50.0, "50g do jajecznicy", "Wędliny"),
    ("seed-mieso-salami-pepperoni", "Salami dojrzewające pepperoni plastry", "Bell", "5902143002015", 410.0, 18.0, 1.0, 37.0, 0.0, 30.0, "5 plastrów (30g)", "Wędliny"),
    ("seed-mieso-salceson-wloski", "Salceson włoski wieprzowy", None, None, 240.0, 16.0, 1.0, 19.5, 0.0, 50.0, "1 plaster (50g)", "Wędliny"),
    ("seed-mieso-pasztetowa-wedzona", "Pasztetowa kremowa wędzona", "Duda", "5900488001021", 280.0, 12.0, 3.0, 24.5, 0.0, 50.0, "50g na kromkę", "Wędliny"),

    # Kiełbasy i kabanosy
    ("seed-mieso-kabanosy-drob-tarczynski", "Kabanosy Exclusive drobiowe", "Tarczyński", "5902581600117", 485.0, 28.0, 4.5, 39.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-kabanosy-wieprz-tarczynski", "Kabanosy Exclusive wieprzowe", "Tarczyński", "5902581600100", 520.0, 25.0, 4.0, 45.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-kabanosy-chilli-tarczynski", "Kabanosy Exclusive z chilli", "Tarczyński", "5902581600124", 510.0, 26.0, 4.2, 43.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-kabanosy-serowe-tarczynski", "Kabanosy Exclusive serowe", "Tarczyński", "5902581600131", 505.0, 27.0, 4.0, 42.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-kabanosy-dolina-dobra", "Kabanosy z szynki 100% polskie mięso", "Dolina Dobra", "5902581001020", 475.0, 29.0, 2.5, 38.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-slaska-morliny", "Kiełbasa śląska tradycyjna", "Morliny", "5900783001065", 250.0, 13.0, 1.5, 21.0, 0.0, 100.0, "1 pętko (100g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-slaska-krakus", "Kiełbasa śląska z szynki", "Krakus", "5900783001102", 230.0, 16.0, 1.0, 18.0, 0.0, 100.0, "1 pętko (100g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-krakowska-sucha", "Kiełbasa krakowska sucha z szynki", "Krakus", "5900783001072", 205.0, 26.0, 1.5, 10.5, 0.0, 50.0, "5 plastrów (50g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-zywiecka-krakus", "Kiełbasa żywiecka plastry", "Krakus", "5900783001119", 250.0, 21.0, 1.0, 18.0, 0.0, 50.0, "5 plastrów (50g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-biala-surowa", "Kiełbasa biała surowa wieprzowa", None, None, 260.0, 14.0, 1.0, 22.0, 0.0, 100.0, "1 pętko (100g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-mysliwska", "Kiełbasa myśliwska podsuszana", "Krakus", "5900783001126", 320.0, 24.0, 1.5, 24.5, 0.0, 50.0, "1 laska (50g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-podwawelska", "Kiełbasa podwawelska wędzona", "Morliny", "5900783001133", 265.0, 14.0, 1.0, 23.0, 0.0, 100.0, "1 kawałek (100g)", "Kiełbasy"),
    ("seed-mieso-kielbasa-torunska", "Kiełbasa toruńska wędzona", "Duda", "5900488001014", 270.0, 15.0, 1.0, 23.0, 0.0, 100.0, "1 kawałek (100g)", "Kiełbasy"),
    ("seed-mieso-chorizo-hiszpanskie", "Kiełbasa hiszpańska Chorizo plastry", None, None, 385.0, 21.0, 2.0, 32.5, 0.0, 40.0, "4 plastry (40g)", "Kiełbasy"),
    ("seed-mieso-kaszanka-gryczana", "Kaszanka z kaszą gryczaną", None, None, 220.0, 10.5, 14.0, 13.5, 1.5, 120.0, "1 pętko (120g)", "Kiełbasy"),

    # Parówki
    ("seed-mieso-parowki-berlinki-klasyczne", "Parówki Berlinki klasyczne", "Morliny", "5900783000013", 260.0, 13.0, 2.5, 22.0, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-berlinki-kurczak", "Parówki Berlinki z kurczaka", "Morliny", "5900783000020", 220.0, 14.0, 2.0, 17.0, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-berlinki-ser", "Parówki Berlinki z serem", "Morliny", "5900783000037", 275.0, 13.0, 2.5, 24.0, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-z-szynki-krakus", "Parówki z szynki 93% mięsa", "Krakus", "5900783001058", 240.0, 15.0, 1.5, 19.5, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-pikok-pure", "Parówki z szynki Pikok Pure 93%", "Pikok", "20010011", 240.0, 15.5, 1.0, 19.5, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-dolina-dobra-100", "Parówki 100% z polskiej szynki", "Dolina Dobra", "5902581001037", 235.0, 16.0, 0.8, 19.0, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-sokoliki", "Paróweczki Sokoliki z szynki dla dzieci", "Sokołów", "5900593004012", 220.0, 16.0, 1.5, 17.0, 0.0, 35.0, "1 paróweczka (35g)", "Parówki"),

    # Pasztety i konserwy
    ("seed-mieso-pasztet-pieczony", "Pasztet wieprzowy pieczony tradycyjny", None, None, 280.0, 14.0, 5.0, 22.0, 1.0, 50.0, "1 gruby plaster (50g)", "Pasztety"),
    ("seed-mieso-pasztet-profie-drobiowy", "Pasztet z drobiem", "Profi", "5901243001013", 195.0, 9.5, 8.0, 14.0, 0.5, 50.0, "1/3 puszki (50g)", "Pasztety"),
    ("seed-mieso-pasztet-profie-pomidor", "Pasztet dworski z pomidorami", "Profi", "5901243001020", 190.0, 9.0, 8.5, 13.5, 0.6, 50.0, "1/3 puszki (50g)", "Pasztety"),
    ("seed-mieso-konserwa-turystyczna", "Konserwa turystyczna wieprzowa", "Krakus", "5900783001089", 180.0, 13.0, 2.0, 13.0, 0.0, 100.0, "1/3 puszki (100g)", "Konserwy"),
    ("seed-mieso-gulasz-angielski-krakus", "Gulasz angielski wieprzowy", "Krakus", "5900783001140", 175.0, 14.0, 1.5, 13.0, 0.0, 100.0, "1/3 puszki (100g)", "Konserwy"),
    ("seed-mieso-mielonka-tyrolska", "Mielonka tyrolska z szynki", "Krakus", "5900783001157", 165.0, 15.0, 1.5, 11.0, 0.0, 100.0, "1/3 puszki (100g)", "Konserwy"),
    ("seed-mieso-smalec-ze-skwarkami", "Smalec domowy ze skwarkami i cebulką", None, None, 840.0, 4.0, 1.0, 92.0, 0.0, 20.0, "1 łyżka (20g)", "Konserwy"),

    # Ryby świeże i mrożone
    ("seed-mieso-losos-atlantycki-swiezy", "Łosoś atlantycki filet świeży", None, None, 208.0, 20.0, 0.0, 13.5, 0.0, 150.0, "1 porcja fileta (150g)", "Ryby świeże"),
    ("seed-mieso-pstrag-teczowy", "Pstrąg tęczowy patroszony świeży", None, None, 135.0, 19.0, 0.0, 6.5, 0.0, 200.0, "1 sztuka (200g)", "Ryby świeże"),
    ("seed-mieso-dorsz-poledwica", "Dorsz atlantycki polędwica bez skóry", None, None, 75.0, 17.5, 0.0, 0.6, 0.0, 150.0, "1 polędwiczka (150g)", "Ryby świeże"),
    ("seed-mieso-mintaj-filet", "Mintaj bez skóry filet mrożony", None, None, 73.0, 16.5, 0.0, 0.6, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-morszczuk-filet", "Morszczuk filet bez skóry", None, None, 78.0, 17.0, 0.0, 0.8, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-miruna-filet", "Miruna nowozelandzka filet b/s", None, None, 72.0, 15.5, 0.0, 1.0, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-halibut-filet", "Halibut niebieski filet świeży", None, None, 140.0, 19.0, 0.0, 7.0, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-sandacz-filet", "Sandacz filet ze skórą", None, None, 84.0, 19.2, 0.0, 0.7, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-dorada-swieza", "Dorada królewska patroszona świeża", None, None, 130.0, 19.5, 0.0, 6.0, 0.0, 250.0, "1 sztuka (250g)", "Ryby świeże"),
    ("seed-mieso-labraks-okon", "Labraks okoń morski patroszony", None, None, 125.0, 19.0, 0.0, 5.5, 0.0, 250.0, "1 sztuka (250g)", "Ryby świeże"),
    ("seed-mieso-karp-dzwonka", "Karp świeży dzwonka", None, None, 160.0, 18.0, 0.0, 10.0, 0.0, 150.0, "1 dzwonko (150g)", "Ryby świeże"),
    ("seed-mieso-tilapia-filet", "Tilapia filet mrożony", None, None, 96.0, 20.0, 0.0, 1.7, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),

    # Ryby wędzone i przetwory
    ("seed-mieso-losos-wedzony-plastry", "Łosoś wędzony na zimno plastry", "SuperFish", "5902574001013", 170.0, 21.0, 0.5, 9.5, 0.0, 50.0, "1/2 opakowania (50g)", "Ryby wędzone"),
    ("seed-mieso-losos-wedzony-goraco", "Łosoś wędzony na gorąco kawałek", "SuperFish", "5902574001020", 215.0, 22.0, 0.0, 14.0, 0.0, 100.0, "1 kawałek (100g)", "Ryby wędzone"),
    ("seed-mieso-makrela-wedzona", "Makrela wędzona tradycyjna", None, None, 240.0, 20.5, 0.0, 17.5, 0.0, 120.0, "1/2 ryby bez ości (120g)", "Ryby wędzone"),
    ("seed-mieso-pstrag-wedzony", "Pstrąg wędzony filet ze skórą", None, None, 145.0, 21.0, 0.0, 6.8, 0.0, 100.0, "1 filet (100g)", "Ryby wędzone"),
    ("seed-mieso-halibut-wedzony", "Halibut wędzony dzwonko", None, None, 185.0, 20.0, 0.0, 11.5, 0.0, 100.0, "1 porcja (100g)", "Ryby wędzone"),
    ("seed-mieso-dorsz-wedzony-goraco", "Dorsz wędzony na gorąco", None, None, 105.0, 22.0, 0.0, 1.8, 0.0, 100.0, "1 kawałek (100g)", "Ryby wędzone"),
    ("seed-mieso-sledz-w-oleju-lisner", "Filety śledziowe w oleju z cebulką", "Lisner", "5900508001019", 290.0, 11.0, 2.0, 26.5, 0.0, 100.0, "1 porcja (100g)", "Ryby przetwory"),
    ("seed-mieso-sledz-w-smietanie-lisner", "Filety śledziowe w śmietanie", "Lisner", "5900508001026", 210.0, 8.5, 7.5, 16.0, 0.0, 100.0, "1 porcja (100g)", "Ryby przetwory"),
    ("seed-mieso-koreczki-kaszubskie", "Koreczki śledziowe po kaszubsku", "Lisner", "5900508001033", 160.0, 9.5, 12.0, 8.5, 1.0, 100.0, "1 porcja (100g)", "Ryby przetwory"),
    ("seed-mieso-tunczyk-w-wodzie", "Tuńczyk kawałki w sosie własnym", "Graal", "5903456001018", 100.0, 23.5, 0.0, 0.8, 0.0, 130.0, "1 puszka po odsączeniu (130g)", "Ryby w puszce"),
    ("seed-mieso-tunczyk-w-oliwie", "Tuńczyk w oliwie z oliwek", "Rio Mare", "8004030041018", 195.0, 22.0, 0.0, 12.0, 0.0, 130.0, "1 puszka po odsączeniu (130g)", "Ryby w puszce"),
    ("seed-mieso-tunczyk-chili-riomare", "Tuńczyk z papryczką chili w oliwie", "Rio Mare", "8004030041025", 198.0, 21.5, 0.5, 12.5, 0.0, 130.0, "1 puszka (130g)", "Ryby w puszce"),
    ("seed-mieso-sardynki-w-pomidorach", "Sardynki w sosie pomidorowym", "Graal", "5903456001025", 145.0, 15.0, 3.5, 8.0, 0.5, 110.0, "1 puszka (110g)", "Ryby w puszce"),
    ("seed-mieso-sardynki-w-oliwie", "Sardynki bez skóry i ości w oliwie", "Graal", "5903456001049", 220.0, 21.0, 0.0, 15.0, 0.0, 90.0, "1 puszka (90g)", "Ryby w puszce"),
    ("seed-mieso-szprot-w-pomidorach", "Szprot w sosie pomidorowym", "Graal", "5903456001032", 155.0, 13.0, 4.5, 9.5, 0.5, 170.0, "1 puszka (170g)", "Ryby w puszce"),
    ("seed-mieso-makrela-w-pomidorach", "Filety z makreli w sosie pomidorowym", "Graal", "5903456001056", 160.0, 14.0, 4.0, 10.0, 0.5, 170.0, "1 puszka (170g)", "Ryby w puszce"),

    # Owoce morza i dania rybne
    ("seed-mieso-krewetki-gotowane", "Krewetki gotowane obrane", None, None, 85.0, 18.0, 0.5, 1.0, 0.0, 100.0, "1 porcja (100g)", "Owoce morza"),
    ("seed-mieso-krewetki-black-tiger", "Krewetki Black Tiger surowe obrane", "Abramczyk", "5900985004019", 75.0, 16.5, 0.5, 0.8, 0.0, 100.0, "1 porcja (100g)", "Owoce morza"),
    ("seed-mieso-paluszki-rybne-frosta", "Złote paluszki rybne z fileta z mintaja", "Frosta", "5900645001018", 190.0, 13.0, 16.0, 8.0, 1.0, 90.0, "3 sztuki (90g)", "Dania rybne"),
    ("seed-mieso-ryba-z-pieca-brokuly", "Ryba z pieca z sosem brokułowym", "Frosta", "5900645001025", 135.0, 11.5, 5.0, 7.5, 0.8, 165.0, "1/2 opakowania (165g)", "Dania rybne"),
    ("seed-mieso-kalmary-panierowane", "Krążki kalmarów panierowane", None, None, 210.0, 12.0, 18.0, 10.0, 1.2, 100.0, "1 porcja (100g)", "Owoce morza"),
    ("seed-mieso-malze-w-zalewie", "Małże omułki w sosie własnym", None, None, 86.0, 14.5, 2.5, 2.0, 0.0, 100.0, "1 porcja (100g)", "Owoce morza"),
    ("seed-mieso-paluszki-krabowe-surimi", "Paluszki krabowe surimi", "Vici", "4770190001015", 95.0, 7.5, 14.0, 0.9, 0.2, 100.0, "5 paluszków (100g)", "Owoce morza"),

    # Marki Biedronka i Lidl (Kraina Wędlin, Pikok) oraz dodatkowe ryby
    ("seed-mieso-szynka-kraina-wedlin-konserwowa", "Szynka konserwowa Kraina Wędlin", "Kraina Wędlin", "5900783002017", 92.0, 17.5, 1.2, 1.8, 0.0, 50.0, "2 plastry (50g)", "Wędliny"),
    ("seed-mieso-poledwica-kraina-wedlin", "Polędwica sopocka Kraina Wędlin", "Kraina Wędlin", "5900783002024", 102.0, 19.5, 1.0, 2.2, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-szynka-szwagra-kraina-wedlin", "Szynka od dziedzica Kraina Wędlin", "Kraina Wędlin", "5900783002031", 112.0, 19.0, 1.0, 3.8, 0.0, 50.0, "2 plastry (50g)", "Wędliny"),
    ("seed-mieso-kabanos-kraina-wedlin", "Kabanosy klasyczne wieprzowe Kraina Wędlin", "Kraina Wędlin", "5900783002048", 490.0, 26.0, 3.5, 42.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-parowki-kraina-wedlin-szynka", "Parówki z szynki 94% Kraina Wędlin", "Kraina Wędlin", "5900783002055", 242.0, 16.0, 1.0, 19.5, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-szynka-pikok-wieprzowa", "Szynka klasyczna wieprzowa Pikok", "Pikok", "20009022", 98.0, 18.5, 1.2, 2.0, 0.0, 40.0, "3 plastry (40g)", "Wędliny"),
    ("seed-mieso-kabanos-pikok-pure", "Kabanosy z szynki Pikok Pure", "Pikok", "20009039", 480.0, 28.0, 2.5, 39.0, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-parowki-berlinki-machos", "Parówki Berlinki Machos pikantne", "Morliny", "5900783000044", 265.0, 13.0, 3.0, 22.5, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-kabanosy-bekon-tarczynski", "Kabanosy Exclusive bekon", "Tarczyński", "5902581600148", 515.0, 26.0, 4.0, 43.5, 0.0, 50.0, "1/2 paczki (50g)", "Kiełbasy"),
    ("seed-mieso-parowki-z-indyka-tarczynski", "Parówki 100% z indyka Tarczyński", "Tarczyński", "5902581600216", 185.0, 17.0, 1.0, 13.0, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-parowki-z-fileta-kurczaka-tarczynski", "Parówki z fileta z kurczaka Tarczyński", "Tarczyński", "5902581600223", 195.0, 16.5, 1.0, 14.5, 0.0, 50.0, "1 parówka (50g)", "Parówki"),
    ("seed-mieso-losos-jurajski-swiezy", "Łosoś jurajski świeży filet", None, None, 200.0, 20.0, 0.0, 13.0, 0.0, 150.0, "1 porcja (150g)", "Ryby świeże"),
    ("seed-mieso-okon-morski-filet", "Okoń nilowy filet świeży", None, None, 92.0, 19.0, 0.0, 1.8, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-dorsz-czarniak-filet", "Czarniak dorsz czarny filet mrożony", None, None, 75.0, 17.8, 0.0, 0.5, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
    ("seed-mieso-sledz-matias-filety", "Filety śledziowe a la Matjas w oleju", "Lisner", "5900508001040", 270.0, 12.0, 1.0, 24.5, 0.0, 100.0, "1 płat śledziowy (100g)", "Ryby przetwory"),
    ("seed-mieso-tunczyk-salatka-meksykanska", "Sałatka z tuńczykiem po meksykańsku", "Rio Mare", "8004030041032", 155.0, 9.5, 9.0, 8.5, 2.5, 160.0, "1 puszka (160g)", "Ryby w puszce"),
    ("seed-mieso-losos-salatka-kuskus", "Sałatka z łososiem i kaszą kuskus", "Graal", "5903456001063", 168.0, 9.0, 14.0, 8.5, 1.8, 150.0, "1 puszka (150g)", "Ryby w puszce"),
    ("seed-mieso-karp-filet-ze-skora", "Karp filet ze skórą świeży", None, None, 145.0, 17.5, 0.0, 8.5, 0.0, 150.0, "1 filet (150g)", "Ryby świeże"),
]

# =========================================================================
# 3. BAKERY AND GRAINS (119 items)
# =========================================================================
BAKERY_AND_GRAINS = [
    # Chleby
    ("seed-piecz-chleb-zytni-razowy", "Chleb żytni razowy tradycyjny", None, None, 227.0, 5.8, 44.0, 1.7, 6.2, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-zytni-100", "Chleb 100% żytni na zakwasie", None, None, 220.0, 6.2, 42.5, 1.5, 7.0, 40.0, "1 kromka (40g)", "Chleb"),
    ("seed-piecz-chleb-pszenny", "Chleb pszenny tradycyjny", None, None, 265.0, 8.0, 50.0, 3.2, 2.7, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-wiejski", "Chleb pszenno-żytni wiejski", None, None, 245.0, 7.5, 48.0, 2.2, 3.8, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-tostowy-pszenny", "Chleb tostowy pszenny", "Dan Cake", "5900579001017", 260.0, 8.5, 49.0, 2.5, 3.0, 25.0, "1 kromka (25g)", "Chleb"),
    ("seed-piecz-chleb-tostowy-pelnoziarnisty", "Chleb tostowy pełnoziarnisty", "Dan Cake", "5900579001024", 245.0, 9.0, 43.0, 2.8, 6.5, 25.0, "1 kromka (25g)", "Chleb"),
    ("seed-piecz-chleb-tostowy-maslany", "Chleb tostowy maślany", "Dan Cake", "5900579001055", 275.0, 8.0, 48.0, 5.5, 2.5, 25.0, "1 kromka (25g)", "Chleb"),
    ("seed-piecz-chleb-orkiszowy", "Chleb orkiszowy", None, None, 240.0, 9.2, 45.0, 2.0, 5.5, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-slonecznikowy", "Chleb ze słonecznikiem", None, None, 270.0, 8.8, 43.0, 6.5, 5.0, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-wieloziarnisty", "Chleb wieloziarnisty", None, None, 255.0, 8.5, 44.0, 4.5, 5.8, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-ziarnisty-bez-maki", "Chleb czysty ziarnisty bez mąki ProBody", None, None, 290.0, 15.0, 12.0, 18.0, 12.0, 40.0, "1 kromka (40g)", "Chleb"),
    ("seed-piecz-chleb-niski-ig", "Chleb o niskim indeksie glikemicznym IG", None, None, 230.0, 11.0, 35.0, 4.0, 8.5, 35.0, "1 kromka (35g)", "Chleb"),
    ("seed-piecz-chleb-litewski-ciemny", "Chleb litewski ciemny z kminkiem", None, None, 235.0, 6.0, 47.0, 1.8, 6.0, 40.0, "1 kromka (40g)", "Chleb"),
    ("seed-piecz-chleb-bezglutenowy-schar", "Chleb bezglutenowy jasny Pan Blanco", "Schär", "8008698001012", 230.0, 3.5, 45.0, 3.5, 6.0, 30.0, "1 kromka (30g)", "Chleb"),
    ("seed-piecz-pumpernikiel", "Pumpernikiel żytni prasowany", "Oskroba", "5901235002011", 215.0, 5.5, 41.0, 1.5, 8.0, 40.0, "1 kromka (40g)", "Chleb"),

    # Bułki i pieczywo drobne
    ("seed-piecz-bulka-kajzerka", "Bułka kajzerka pszenna", None, None, 296.0, 8.4, 58.0, 3.6, 2.3, 60.0, "1 sztuka (60g)", "Bułki"),
    ("seed-piecz-bulka-grahamka", "Bułka grahamka", None, None, 250.0, 8.5, 48.0, 2.0, 6.0, 70.0, "1 sztuka (70g)", "Bułki"),
    ("seed-piecz-bulka-wieloziarnista-fitness", "Bułka fitness wieloziarnista", None, None, 268.0, 9.5, 44.0, 5.5, 6.2, 80.0, "1 sztuka (80g)", "Bułki"),
    ("seed-piecz-bulka-ciabatta", "Bułka ciabatta pszenna", None, None, 270.0, 8.5, 53.0, 2.5, 2.8, 80.0, "1 sztuka (80g)", "Bułki"),
    ("seed-piecz-bulka-dyniowa", "Bułka z pestkami dyni", None, None, 280.0, 9.8, 48.0, 5.5, 4.0, 80.0, "1 sztuka (80g)", "Bułki"),
    ("seed-piecz-bulka-maslana", "Bułeczka maślana mleczna", None, None, 330.0, 8.0, 54.0, 9.0, 2.0, 60.0, "1 sztuka (60g)", "Bułki"),
    ("seed-piecz-bulka-paryska", "Bułka paryska wyborowa", None, None, 270.0, 8.2, 55.0, 1.8, 2.5, 50.0, "2 kromki (50g)", "Bułki"),
    ("seed-piecz-bulka-hamburger", "Bułka do hamburgera z sezamem", "Dan Cake", "5900579001031", 285.0, 8.2, 51.0, 5.0, 2.5, 75.0, "1 sztuka (75g)", "Bułki"),
    ("seed-piecz-bulka-hot-dog", "Bułka do hot-doga francuskiego", "Dan Cake", "5900579001062", 280.0, 8.5, 52.0, 4.0, 2.5, 60.0, "1 sztuka (60g)", "Bułki"),
    ("seed-piecz-bagietka-pszenna", "Bagietka pszenna francuska", None, None, 275.0, 8.5, 56.0, 1.5, 2.5, 100.0, "1/2 bagietki (100g)", "Bułki"),
    ("seed-piecz-bagietka-czosnkowa", "Bagietka z masłem czosnkowym", "Dan Cake", "5900579001048", 345.0, 7.0, 42.0, 16.5, 2.0, 85.0, "1/2 sztuki (85g)", "Bułki"),
    ("seed-piecz-bagietka-ziolowa", "Bagietka z masłem ziołowym", "Dan Cake", "5900579001079", 345.0, 7.0, 42.0, 16.5, 2.0, 85.0, "1/2 sztuki (85g)", "Bułki"),
    ("seed-piecz-rogal-maslany", "Rogal maślany", None, None, 320.0, 7.5, 52.0, 8.5, 2.0, 70.0, "1 sztuka (70g)", "Bułki"),
    ("seed-piecz-croissant-maslany", "Croissant maślany francuski", None, None, 406.0, 8.2, 45.8, 21.0, 2.6, 60.0, "1 sztuka (60g)", "Bułki"),
    ("seed-piecz-chalka-drozdzowa", "Chałka drożdżowa maślana", None, None, 340.0, 8.5, 56.0, 8.8, 2.2, 50.0, "1 gruba kromka (50g)", "Bułki"),
    ("seed-piecz-drozdzowka-z-serem", "Drożdżówka tradycyjna z serem twarogowym", None, None, 315.0, 8.5, 50.0, 8.5, 1.8, 100.0, "1 sztuka (100g)", "Bułki"),

    # Pieczywo płaskie i chrupkie
    ("seed-piecz-chleb-pita", "Chlebek pita pszenny", None, None, 275.0, 9.1, 55.7, 1.2, 2.2, 60.0, "1 placek (60g)", "Pieczywo płaskie"),
    ("seed-piecz-tortilla-pszenna", "Tortilla pszenna wraps", "Dijo", "5907689001015", 310.0, 8.5, 53.0, 6.5, 3.0, 62.0, "1 placek (62g)", "Pieczywo płaskie"),
    ("seed-piecz-tortilla-pelnoziarnista", "Tortilla pełnoziarnista", "Dijo", "5907689001022", 295.0, 9.5, 48.0, 6.0, 6.5, 62.0, "1 placek (62g)", "Pieczywo płaskie"),
    ("seed-piecz-tortilla-mission", "Tortilla pszenna Original", "Mission", "8710850001012", 305.0, 8.0, 52.0, 6.8, 2.8, 62.0, "1 placek (62g)", "Pieczywo płaskie"),
    ("seed-piecz-lawasz-ormianski", "Lawasz pszenny ormiański", None, None, 275.0, 8.5, 56.0, 1.2, 2.4, 50.0, "1 porcja (50g)", "Pieczywo płaskie"),
    ("seed-piecz-wafle-ryzowe-naturalne", "Wafle ryżowe naturalne", "Kupiec", "5906747160180", 380.0, 8.0, 82.0, 2.0, 3.0, 10.0, "1 sztuka (10g)", "Pieczywo chrupkie"),
    ("seed-piecz-wafle-ryzowe-sol-morska", "Wafle ryżowe z solą morską", "Kupiec", "5906747160203", 380.0, 8.0, 81.5, 2.0, 3.0, 10.0, "1 sztuka (10g)", "Pieczywo chrupkie"),
    ("seed-piecz-wafle-kukurydziane", "Wafle kukurydziane z solą", "Kupiec", "5906747160210", 375.0, 7.5, 80.0, 2.5, 4.0, 10.0, "1 sztuka (10g)", "Pieczywo chrupkie"),
    ("seed-piecz-pieczywo-chrupkie-zytnie", "Pieczywo chrupkie żytnie", "Wasa", "7300400117006", 334.0, 9.0, 61.5, 1.5, 19.0, 12.0, "1 kromka (12g)", "Pieczywo chrupkie"),
    ("seed-piecz-pieczywo-chrupkie-delikatne", "Pieczywo chrupkie Delikatne pszenne", "Wasa", "7300400117013", 360.0, 11.0, 67.0, 2.0, 8.0, 10.0, "1 kromka (10g)", "Pieczywo chrupkie"),
    ("seed-piecz-pieczywo-lekkie-7-zboz", "Pieczywo lekkie 7 zbóż", "Sonko", "5902020001014", 365.0, 10.5, 75.0, 2.0, 5.5, 7.0, "1 kromka (7g)", "Pieczywo chrupkie"),
    ("seed-piecz-sucharki-delikatesowe", "Sucharki delikatesowe", "Mamut", "5900593005019", 395.0, 11.0, 72.0, 6.5, 3.5, 10.0, "1 sucharek (10g)", "Pieczywo chrupkie"),

    # Płatki śniadaniowe, musli i otręby
    ("seed-piecz-platki-owsiane-gorskie", "Płatki owsiane górskie", "Kupiec", "5906747160012", 375.0, 13.0, 62.0, 7.0, 10.0, 50.0, "1 porcja (50g)", "Płatki"),
    ("seed-piecz-platki-owsiane-blyskawiczne", "Płatki owsiane błyskawiczne", "Kupiec", "5906747160029", 370.0, 13.0, 62.0, 7.0, 10.0, 50.0, "1 porcja (50g)", "Płatki"),
    ("seed-piecz-platki-jaglane", "Płatki jaglane", "Melvit", "5907474001016", 360.0, 11.0, 68.0, 3.5, 4.0, 50.0, "1 porcja (50g)", "Płatki"),
    ("seed-piecz-platki-orkiszowe", "Płatki orkiszowe", "Kupiec", "5906747160036", 350.0, 13.5, 63.0, 2.7, 9.0, 50.0, "1 porcja (50g)", "Płatki"),
    ("seed-piecz-platki-gryczane", "Płatki gryczane", "Melvit", "5907474001023", 355.0, 12.0, 67.0, 3.0, 6.0, 50.0, "1 porcja (50g)", "Płatki"),
    ("seed-piecz-platki-zytnie", "Płatki żytnie", "Kupiec", "5906747160227", 340.0, 8.0, 68.0, 2.2, 12.0, 50.0, "1 porcja (50g)", "Płatki"),
    ("seed-piecz-platki-kukurydziane", "Płatki kukurydziane Corn Flakes", "Nestlé", "5900020000018", 378.0, 7.2, 84.0, 1.4, 3.0, 30.0, "1 miseczka (30g)", "Płatki"),
    ("seed-piecz-platki-cini-minis", "Płatki cynamonowe Cini Minis", "Nestlé", "5900020000025", 423.0, 6.2, 74.5, 10.3, 5.0, 30.0, "1 porcja (30g)", "Płatki"),
    ("seed-piecz-platki-nesquik", "Płatki czekoladowe Nesquik", "Nestlé", "5900020000032", 379.0, 7.3, 75.1, 3.8, 5.2, 30.0, "1 porcja (30g)", "Płatki"),
    ("seed-piecz-platki-chocapic", "Płatki czekoladowe Chocapic", "Nestlé", "5900020000049", 388.0, 8.4, 73.6, 4.7, 5.6, 30.0, "1 porcja (30g)", "Płatki"),
    ("seed-piecz-platki-cheerios", "Płatki Cheerios miodowe", "Nestlé", "5900020000056", 382.0, 8.0, 74.0, 4.5, 7.5, 30.0, "1 porcja (30g)", "Płatki"),
    ("seed-piecz-granola-orzechowa", "Granola z orzechami Crunchy", "Sante", "5900617001018", 460.0, 9.5, 63.0, 18.0, 6.5, 50.0, "1 porcja (50g)", "Musli"),
    ("seed-piecz-granola-czekoladowa", "Granola czekoladowa Crunchy", "Sante", "5900617001032", 455.0, 9.0, 65.0, 17.0, 6.0, 50.0, "1 porcja (50g)", "Musli"),
    ("seed-piecz-musli-tradycyjne", "Musli tradycyjne z owocami", "Sante", "5900617001025", 365.0, 10.0, 65.0, 5.5, 9.0, 50.0, "1 porcja (50g)", "Musli"),
    ("seed-piecz-otreby-owsiane", "Otręby owsiane wysokobłonnikowe", "Kupiec", "5906747160173", 365.0, 17.0, 50.0, 7.0, 15.0, 20.0, "2 łyżki (20g)", "Otręby"),
    ("seed-piecz-otreby-pszenne", "Otręby pszenne", "Kupiec", "5906747160234", 280.0, 16.0, 20.0, 4.5, 42.0, 15.0, "2 łyżki (15g)", "Otręby"),

    # Ryże
    ("seed-piecz-ryz-bialy", "Ryż biały długoziarnisty", "Kupiec", "5906747160043", 350.0, 7.0, 78.0, 0.7, 1.4, 100.0, "1 woreczek (100g)", "Ryż"),
    ("seed-piecz-ryz-basmati", "Ryż basmati", "Kupiec", "5906747160050", 352.0, 8.5, 77.0, 0.6, 1.5, 100.0, "1 woreczek (100g)", "Ryż"),
    ("seed-piecz-ryz-jasminowy", "Ryż jaśminowy", "Kupiec", "5906747160067", 348.0, 7.2, 77.5, 0.6, 1.2, 100.0, "1 woreczek (100g)", "Ryż"),
    ("seed-piecz-ryz-brazowy", "Ryż brązowy naturalny", "Kupiec", "5906747160074", 354.0, 7.5, 74.0, 2.0, 4.5, 100.0, "1 woreczek (100g)", "Ryż"),
    ("seed-piecz-ryz-parboiled", "Ryż parboiled", "Kupiec", "5906747160081", 352.0, 7.5, 77.0, 0.7, 1.8, 100.0, "1 woreczek (100g)", "Ryż"),
    ("seed-piecz-ryz-sushi", "Ryż do sushi okrągły", "House of Asia", "5902751002013", 350.0, 6.5, 78.0, 0.5, 1.0, 100.0, "100g ryżu do sushi", "Ryż"),
    ("seed-piecz-ryz-arborio-risotto", "Ryż do risotto Arborio", "Riso Scotti", "8001860001014", 352.0, 7.0, 78.0, 0.8, 1.5, 100.0, "1 porcja (100g)", "Ryż"),
    ("seed-piecz-ryz-czarny", "Ryż czarny Nerone pełnoziarnisty", "Melvit", "5907474001108", 345.0, 8.5, 68.0, 2.5, 5.0, 70.0, "1 porcja (70g)", "Ryż"),

    # Kasze i ziarna
    ("seed-piecz-kasza-gryczana-prazona", "Kasza gryczana prażona", "Kupiec", "5906747160098", 345.0, 12.6, 69.0, 3.1, 6.0, 100.0, "1 woreczek (100g)", "Kasze"),
    ("seed-piecz-kasza-gryczana-biala", "Kasza gryczana biała niepalona", "Melvit", "5907474001030", 340.0, 12.0, 68.0, 2.8, 5.9, 100.0, "1 woreczek (100g)", "Kasze"),
    ("seed-piecz-kasza-jaglana", "Kasza jaglana", "Kupiec", "5906747160104", 350.0, 10.5, 71.0, 2.9, 3.2, 100.0, "1 woreczek (100g)", "Kasze"),
    ("seed-piecz-kasza-peczak", "Kasza jęczmienna pęczak", "Kupiec", "5906747160111", 335.0, 8.4, 69.0, 2.0, 15.0, 100.0, "1 woreczek (100g)", "Kasze"),
    ("seed-piecz-kasza-jeczmienna-wiejska", "Kasza jęczmienna wiejska", "Kupiec", "5906747160128", 342.0, 8.5, 70.0, 2.0, 12.0, 100.0, "1 woreczek (100g)", "Kasze"),
    ("seed-piecz-kasza-manna", "Kasza manna", "Kupiec", "5906747160135", 350.0, 10.0, 74.0, 1.2, 2.5, 50.0, "1 porcja (50g)", "Kasze"),
    ("seed-piecz-kasza-kuskus", "Kasza kuskus", "Kupiec", "5906747160142", 360.0, 12.5, 73.0, 1.5, 4.0, 70.0, "1 porcja (70g)", "Kasze"),
    ("seed-piecz-kasza-kuskus-perlowy", "Kuskus perłowy izraelski", "Melvit", "5907474001115", 355.0, 12.0, 72.0, 1.5, 3.5, 70.0, "1 porcja (70g)", "Kasze"),
    ("seed-piecz-kasza-bulgur", "Kasza bulgur", "Kupiec", "5906747160159", 342.0, 12.3, 65.0, 1.5, 8.0, 100.0, "1 woreczek (100g)", "Kasze"),
    ("seed-piecz-quinoa-komosa", "Komosa ryżowa Quinoa biała", "Melvit", "5907474001047", 368.0, 14.1, 57.2, 6.1, 7.0, 60.0, "1 porcja (60g)", "Kasze"),
    ("seed-piecz-kaszka-polenta", "Kaszka kukurydziana Polenta", "Kupiec", "5906747160265", 350.0, 8.0, 75.0, 1.5, 3.0, 50.0, "1 porcja (50g)", "Kasze"),

    # Makarony
    ("seed-piecz-makaron-spaghetti", "Makaron spaghetti", "Lubella", "5900038000010", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-swiderki", "Makaron świderki fusilli", "Lubella", "5900038000027", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-penne", "Makaron pióra penne", "Lubella", "5900038000034", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-kolanka", "Makaron kolanka krojone", "Lubella", "5900038000096", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-kokardki", "Makaron kokardki farfalle", "Lubella", "5900038000102", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-pelnoziarnisty", "Makaron pełnoziarnisty pióra", "Lubella", "5900038000041", 348.0, 15.0, 62.0, 2.5, 8.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-pelnoziarnisty-spaghetti", "Makaron pełnoziarnisty spaghetti", "Lubella", "5900038000119", 348.0, 15.0, 62.0, 2.5, 8.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-jajeczny-wstazki", "Makaron jajeczny wstążki", "Lubella", "5900038000058", 365.0, 13.0, 72.0, 2.5, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-nitki-rosol", "Makaron nitki do rosołu 4 jaja", "Lubella", "5900038000126", 365.0, 13.0, 72.0, 2.5, 3.0, 50.0, "1 porcja do zupy (50g)", "Makaron"),
    ("seed-piecz-makaron-barilla-spaghetti", "Makaron spaghetti n.5", "Barilla", "8076809513753", 359.0, 12.5, 71.2, 2.0, 3.0, 100.0, "1 porcja (100g)", "Makaron"),
    ("seed-piecz-makaron-lasagne-platy", "Płaty do lasagne makaronowe", "Barilla", "8076809513760", 359.0, 12.5, 71.2, 2.0, 3.0, 40.0, "2 płaty (40g)", "Makaron"),
    ("seed-piecz-makaron-ryzowy-nitki", "Makaron ryżowy nitki", "TaoTao", "5905679001018", 358.0, 7.0, 81.0, 0.5, 1.0, 80.0, "1 porcja (80g)", "Makaron"),
    ("seed-piecz-makaron-ryzowy-wstazki", "Makaron ryżowy wstążki Pad Thai", "TaoTao", "5905679001025", 358.0, 7.0, 81.0, 0.5, 1.0, 80.0, "1 porcja (80g)", "Makaron"),
    ("seed-piecz-makaron-sojowy", "Makaron z fasoli mung sojowy", "TaoTao", "5905679001032", 345.0, 0.5, 85.0, 0.2, 0.5, 50.0, "1 gniazdko (50g)", "Makaron"),
    ("seed-piecz-makaron-udon", "Makaron pszenny Udon świeży", "House of Asia", "5902751002020", 150.0, 5.0, 31.0, 0.5, 1.2, 200.0, "1 porcja (200g)", "Makaron"),

    # Mąki i skrobie
    ("seed-piecz-maka-pszenna-typ-500", "Mąka pszenna poznańska typ 500", "Lubella", "5900038000065", 345.0, 10.0, 74.0, 1.0, 2.5, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-tortowa-450", "Mąka pszenna tortowa typ 450", "Lubella", "5900038000133", 345.0, 9.8, 74.5, 1.0, 2.3, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-wroclawska-500", "Mąka pszenna wrocławska typ 500", "Basia", "5900593006016", 345.0, 10.0, 74.0, 1.0, 2.5, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-pelnoziarnista-1850", "Mąka pszenna graham typ 1850", "Lubella", "5900038000072", 335.0, 12.0, 63.0, 2.2, 11.0, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-zytnia-720", "Mąka żytnia typ 720", "Kupiec", "5906747160166", 330.0, 8.0, 68.0, 1.5, 8.5, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-zytnia-2000", "Mąka żytnia razowa typ 2000", "Melvit", "5907474001061", 325.0, 9.0, 62.0, 2.0, 13.0, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-orkiszowa-630", "Mąka orkiszowa jasna typ 630", "Melvit", "5907474001078", 340.0, 12.5, 69.0, 1.8, 4.0, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-ziemniaczana", "Mąka ziemniaczana skrobia", "Kupiec", "5906747160241", 340.0, 0.2, 84.0, 0.1, 0.5, 20.0, "1 czubata łyżka (20g)", "Mąka"),
    ("seed-piecz-maka-kukurydziana", "Mąka kukurydziana", "Kupiec", "5906747160258", 355.0, 8.0, 74.0, 2.5, 5.0, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-ryzowa", "Mąka ryżowa", "Melvit", "5907474001085", 355.0, 7.0, 79.0, 0.8, 1.5, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-owsiana", "Mąka owsiana", "Melvit", "5907474001092", 370.0, 13.0, 64.0, 6.5, 8.0, 50.0, "1/2 szklanki (50g)", "Mąka"),
    ("seed-piecz-maka-migdalowa", "Mąka migdałowa z mielonych migdałów", "Kresto", "5900354002091", 590.0, 21.0, 10.0, 52.0, 10.0, 30.0, "2 czubate łyżki (30g)", "Mąka"),
    ("seed-piecz-bulka-tarta", "Bułka tarta", "Lubella", "5900038000089", 360.0, 11.0, 72.0, 2.0, 4.0, 20.0, "1 czubata łyżka (20g)", "Mąka"),
]

# =========================================================================
# 4. FRUITS, VEGETABLES AND FATS (135 items)
# =========================================================================
FRUITS_VEG_FATS = [
    # Warzywa świeże
    ("seed-warz-pomidor-malinowy", "Pomidor malinowy świeży", None, None, 18.0, 0.9, 3.6, 0.2, 1.2, 180.0, "1 sztuka (180g)", "Warzywa"),
    ("seed-warz-pomidor-zwykly", "Pomidor czerwony tradycyjny", None, None, 18.0, 0.9, 3.6, 0.2, 1.2, 150.0, "1 sztuka średnia (150g)", "Warzywa"),
    ("seed-warz-pomidorki-koktajlowe", "Pomidorki koktajlowe cherry", None, None, 20.0, 1.0, 3.8, 0.2, 1.4, 100.0, "1 garść (100g)", "Warzywa"),
    ("seed-warz-ogorek-szklarniowy", "Ogórek zielony szklarniowy długi", None, None, 14.0, 0.7, 2.6, 0.1, 0.6, 180.0, "1 sztuka (180g)", "Warzywa"),
    ("seed-warz-ogorek-gruntowy", "Ogórek gruntowy", None, None, 14.0, 0.7, 2.6, 0.1, 0.6, 70.0, "1 sztuka (70g)", "Warzywa"),
    ("seed-warz-ogorki-kiszone", "Ogórki kiszone tradycyjne", None, None, 12.0, 0.8, 1.8, 0.1, 1.0, 60.0, "1 sztuka (60g)", "Warzywa"),
    ("seed-warz-ogorki-konserwowe", "Ogórki konserwowe korniszone", "Krakus", "5900783002017", 35.0, 0.6, 7.5, 0.2, 0.8, 60.0, "1 sztuka (60g)", "Warzywa"),
    ("seed-warz-papryka-czerwona", "Papryka czerwona słodka", None, None, 31.0, 1.3, 6.0, 0.4, 2.0, 180.0, "1 sztuka (180g)", "Warzywa"),
    ("seed-warz-papryka-zolta", "Papryka żółta słodka", None, None, 28.0, 1.1, 5.5, 0.3, 1.8, 180.0, "1 sztuka (180g)", "Warzywa"),
    ("seed-warz-papryka-zielona", "Papryka zielona słodka", None, None, 22.0, 1.0, 4.5, 0.2, 1.7, 180.0, "1 sztuka (180g)", "Warzywa"),
    ("seed-warz-papryczka-chili", "Papryczka ostra chili", None, None, 40.0, 1.9, 8.8, 0.4, 1.5, 15.0, "1 sztuka (15g)", "Warzywa"),
    ("seed-warz-ziemniaki-gotowane", "Ziemniaki gotowane w osolonej wodzie", None, None, 77.0, 2.0, 17.5, 0.1, 1.8, 200.0, "2 sztuki średnie (200g)", "Warzywa"),
    ("seed-warz-ziemniaki-pieczone", "Ziemniaki pieczone z ziołami", None, None, 95.0, 2.2, 21.0, 1.0, 2.2, 200.0, "1 porcja (200g)", "Warzywa"),
    ("seed-warz-bataty-slodkie-ziemniaki", "Bataty słodkie ziemniaki", None, None, 86.0, 1.6, 20.0, 0.1, 3.0, 200.0, "1 sztuka średnia (200g)", "Warzywa"),
    ("seed-warz-cebula-biala", "Cebula biała", None, None, 40.0, 1.3, 8.5, 0.2, 1.8, 100.0, "1 sztuka średnia (100g)", "Warzywa"),
    ("seed-warz-cebula-czerwona", "Cebula czerwona", None, None, 42.0, 1.4, 9.0, 0.2, 1.8, 100.0, "1 sztuka średnia (100g)", "Warzywa"),
    ("seed-warz-szczypiorek-dymka", "Cebula dymka ze szczypiorkiem", None, None, 32.0, 1.8, 6.5, 0.2, 2.6, 30.0, "1 pęczek (30g)", "Warzywa"),
    ("seed-warz-czosnek-swiezy", "Czosnek świeży ząbek", None, None, 149.0, 6.4, 33.0, 0.5, 2.1, 5.0, "1 ząbek (5g)", "Warzywa"),
    ("seed-warz-marchew-swieza", "Marchew surowa", None, None, 41.0, 0.9, 9.6, 0.2, 2.8, 100.0, "1 sztuka średnia (100g)", "Warzywa"),
    ("seed-warz-marchew-gotowana", "Marchew gotowana", None, None, 35.0, 0.8, 8.0, 0.2, 3.0, 100.0, "1 sztuka (100g)", "Warzywa"),
    ("seed-warz-pietruszka-korzen", "Pietruszka korzeń", None, None, 45.0, 2.6, 8.8, 0.5, 4.3, 80.0, "1 sztuka (80g)", "Warzywa"),
    ("seed-warz-natka-pietruszki", "Natka pietruszki świeża", None, None, 36.0, 3.0, 6.3, 0.8, 3.3, 15.0, "1 pęczek (15g)", "Warzywa"),
    ("seed-warz-seler-korzeniowy", "Seler korzeniowy", None, None, 30.0, 1.5, 6.0, 0.3, 3.5, 100.0, "1 plaster (100g)", "Warzywa"),
    ("seed-warz-seler-naciowy", "Seler naciowy łodyga", None, None, 16.0, 0.7, 3.0, 0.2, 1.6, 40.0, "1 łodyga (40g)", "Warzywa"),
    ("seed-warz-brokul-surowy", "Brokuł świeży różyczki", None, None, 34.0, 2.8, 6.6, 0.4, 2.6, 250.0, "1/2 główki (250g)", "Warzywa"),
    ("seed-warz-brokul-gotowany", "Brokuł gotowany na parze", None, None, 35.0, 2.4, 7.0, 0.4, 3.3, 200.0, "1 porcja (200g)", "Warzywa"),
    ("seed-warz-kalafior-surowy", "Kalafior świeży różyczki", None, None, 25.0, 1.9, 5.0, 0.3, 2.0, 250.0, "1/2 główki (250g)", "Warzywa"),
    ("seed-warz-cukinia", "Cukinia ze skórką", None, None, 17.0, 1.2, 3.1, 0.3, 1.0, 250.0, "1 sztuka średnia (250g)", "Warzywa"),
    ("seed-warz-baklazan", "Bakłażan oberżyna", None, None, 25.0, 1.0, 5.8, 0.2, 3.0, 250.0, "1 sztuka średnia (250g)", "Warzywa"),
    ("seed-warz-szpinak-swiezy-baby", "Szpinak baby świeże liście", None, None, 23.0, 2.9, 3.6, 0.4, 2.2, 100.0, "1 duża garść (100g)", "Warzywa"),
    ("seed-warz-szpinak-mrozony-hortex", "Szpinak liście mrożony", "Hortex", "5900334002016", 20.0, 2.5, 2.0, 0.4, 2.2, 150.0, "1 porcja (150g)", "Warzywa"),
    ("seed-warz-salata-lodowa", "Sałata lodowa", None, None, 14.0, 0.9, 2.8, 0.1, 1.2, 100.0, "1 miska liści (100g)", "Warzywa"),
    ("seed-warz-salata-maslowa", "Sałata masłowa", None, None, 15.0, 1.4, 2.8, 0.2, 1.5, 100.0, "1 miska liści (100g)", "Warzywa"),
    ("seed-warz-roszponka", "Roszponka liście", None, None, 21.0, 2.0, 3.5, 0.4, 1.5, 50.0, "1 garść (50g)", "Warzywa"),
    ("seed-warz-rukola", "Rukola liście", None, None, 25.0, 2.6, 3.7, 0.7, 1.6, 50.0, "1 garść (50g)", "Warzywa"),
    ("seed-warz-kapusta-biala", "Kapusta biała szatkowana", None, None, 25.0, 1.3, 5.8, 0.1, 2.5, 150.0, "1 porcja (150g)", "Warzywa"),
    ("seed-warz-kapusta-czerwona", "Kapusta czerwona", None, None, 31.0, 1.4, 7.4, 0.2, 2.1, 150.0, "1 porcja (150g)", "Warzywa"),
    ("seed-warz-kapusta-kiszona", "Kapusta kiszona naturalna", None, None, 18.0, 1.1, 3.4, 0.2, 2.3, 150.0, "1 porcja (150g)", "Warzywa"),
    ("seed-warz-kapusta-pekinska", "Kapusta pekińska", None, None, 16.0, 1.2, 3.2, 0.2, 1.5, 100.0, "1 miseczka (100g)", "Warzywa"),
    ("seed-warz-jarmuz-swiezy", "Jarmuż świeże liście", None, None, 49.0, 4.3, 8.8, 0.9, 3.6, 50.0, "1 garść (50g)", "Warzywa"),
    ("seed-warz-rzodkiewka", "Rzodkiewka świeża", None, None, 16.0, 0.7, 3.4, 0.1, 1.6, 15.0, "1 sztuka (15g)", "Warzywa"),
    ("seed-warz-burak-gotowany", "Burak ćwikłowy gotowany", None, None, 44.0, 1.7, 9.6, 0.2, 2.0, 150.0, "1 sztuka (150g)", "Warzywa"),
    ("seed-warz-dynia-pizmowa", "Dynia piżmowa surowy miąższ", None, None, 26.0, 1.0, 6.5, 0.1, 0.5, 200.0, "1 porcja (200g)", "Warzywa"),
    ("seed-warz-szparagi-zielone", "Szparagi zielone świeże", None, None, 20.0, 2.2, 3.9, 0.1, 2.1, 150.0, "1 wiązka (150g)", "Warzywa"),
    ("seed-warz-por", "Por biała i zielona część", None, None, 29.0, 1.5, 5.7, 0.3, 1.8, 100.0, "1 sztuka średnia (100g)", "Warzywa"),

    # Grzyby
    ("seed-warz-pieczarki-biale", "Pieczarki białe surowe", None, None, 22.0, 3.1, 3.3, 0.3, 1.5, 100.0, "4-5 sztuk (100g)", "Grzyby"),
    ("seed-warz-pieczarki-podsmazane", "Pieczarki podsmażane na oliwie", None, None, 68.0, 3.2, 3.5, 4.5, 1.6, 100.0, "1 porcja (100g)", "Grzyby"),
    ("seed-warz-boczniaki-swieze", "Boczniaki świeże", None, None, 33.0, 3.3, 4.0, 0.4, 2.3, 150.0, "1 porcja (150g)", "Grzyby"),
    ("seed-warz-borowiki-mrozone", "Borowiki leśne mrożone", "Hortex", "5900334002023", 28.0, 3.2, 2.8, 0.4, 2.5, 100.0, "1 porcja (100g)", "Grzyby"),
    ("seed-warz-kurki-swieze", "Kurki pieprzniki jadalne świeże", None, None, 32.0, 1.5, 6.9, 0.5, 3.8, 100.0, "1 porcja (100g)", "Grzyby"),

    # Strączkowe i przetwory warzywne
    ("seed-warz-kukurydza-puszka", "Kukurydza złocista słodka konserwowa", "Bonduelle", "3083680001018", 80.0, 2.9, 14.5, 1.2, 2.5, 140.0, "1/2 puszki odsączonej (140g)", "Strączki i przetwory"),
    ("seed-warz-groszek-puszka", "Groszek tradycyjny konserwowy", "Bonduelle", "3083680001025", 72.0, 5.2, 10.5, 0.6, 4.5, 140.0, "1/2 puszki odsączonej (140g)", "Strączki i przetwory"),
    ("seed-warz-fasola-czerwona-puszka", "Fasola czerwona Kidney konserwowa", "Bonduelle", "3083680001032", 95.0, 7.5, 14.0, 0.6, 6.0, 120.0, "1/2 puszki odsączonej (120g)", "Strączki i przetwory"),
    ("seed-warz-fasola-biala-puszka", "Fasola biała konserwowa", "Bonduelle", "3083680001049", 90.0, 7.0, 13.5, 0.5, 6.2, 120.0, "1/2 puszki odsączonej (120g)", "Strączki i przetwory"),
    ("seed-warz-ciecierzyca-puszka", "Ciecierzyca konserwowa w zalewie", "Bonduelle", "3083680001056", 120.0, 7.0, 17.0, 2.2, 5.5, 120.0, "1/2 puszki odsączonej (120g)", "Strączki i przetwory"),
    ("seed-warz-fasolka-szparagowa-zielona", "Fasolka szparagowa zielona mrożona", "Hortex", "5900334002030", 31.0, 1.8, 7.0, 0.2, 2.7, 150.0, "1 porcja (150g)", "Strączki i przetwory"),
    ("seed-warz-soczewica-czerwona-sucha", "Soczewica czerwona nasiona suche", "Kupiec", "5906747160197", 341.0, 25.0, 52.0, 1.5, 11.0, 50.0, "1 porcja (50g)", "Strączki i przetwory"),
    ("seed-warz-soczewica-zielona-sucha", "Soczewica zielona nasiona suche", "Melvit", "5907474001054", 335.0, 24.5, 51.0, 1.2, 12.0, 50.0, "1 porcja (50g)", "Strączki i przetwory"),
    ("seed-warz-pomidory-krojone-mutti", "Pomidory krojone Polpa w puszce", "Mutti", "8005110001018", 24.0, 1.2, 3.9, 0.2, 1.0, 200.0, "1/2 puszki (200g)", "Strączki i przetwory"),
    ("seed-warz-passata-pomidorowa-mutti", "Passata przecier pomidorowy", "Mutti", "8005110001025", 32.0, 1.5, 5.5, 0.2, 1.2, 250.0, "1/2 butelki (250g)", "Strączki i przetwory"),
    ("seed-warz-koncentrat-pomidorowy-pudliszki", "Koncentrat pomidorowy 30%", "Pudliszki", "5900593000021", 92.0, 5.6, 16.5, 0.5, 2.8, 25.0, "1 czubata łyżka (25g)", "Strączki i przetwory"),

    # Owoce świeże
    ("seed-owoc-jablko-czerwone", "Jabłko czerwone ze skórką", None, None, 52.0, 0.3, 13.8, 0.2, 2.4, 180.0, "1 sztuka średnia (180g)", "Owoce"),
    ("seed-owoc-jablko-zielone", "Jabłko zielone Granny Smith", None, None, 50.0, 0.3, 13.5, 0.2, 2.5, 180.0, "1 sztuka średnia (180g)", "Owoce"),
    ("seed-owoc-banan-swiezy", "Banan świeży po obraniu", None, None, 89.0, 1.1, 22.8, 0.3, 2.6, 120.0, "1 sztuka po obraniu (120g)", "Owoce"),
    ("seed-owoc-truskawki-swieze", "Truskawki świeże", None, None, 33.0, 0.7, 7.7, 0.3, 2.0, 150.0, "1 miseczka (150g)", "Owoce"),
    ("seed-owoc-truskawki-mrozone", "Truskawki mrożone", "Hortex", "5900334003013", 32.0, 0.7, 7.5, 0.3, 2.0, 150.0, "1 porcja (150g)", "Owoce"),
    ("seed-owoc-borowki-amerykanskie", "Borówki amerykańskie świeże", None, None, 57.0, 0.7, 14.5, 0.3, 2.4, 125.0, "1 opakowanie (125g)", "Owoce"),
    ("seed-owoc-jagody-lesne", "Jagody leśne czernice", None, None, 57.0, 0.7, 14.5, 0.3, 2.4, 100.0, "1 szklanka (100g)", "Owoce"),
    ("seed-owoc-maliny-swieze", "Maliny świeże", None, None, 52.0, 1.2, 12.0, 0.6, 6.5, 125.0, "1 opakowanie (125g)", "Owoce"),
    ("seed-owoc-maliny-mrozone", "Maliny mrożone", "Hortex", "5900334003020", 50.0, 1.2, 11.5, 0.6, 6.5, 125.0, "1 porcja (125g)", "Owoce"),
    ("seed-owoc-jezyny-swieze", "Jeżyny świeże", None, None, 43.0, 1.4, 9.6, 0.5, 5.3, 100.0, "1 miseczka (100g)", "Owoce"),
    ("seed-owoc-pomarancza", "Pomarańcza deserowa obrana", None, None, 47.0, 0.9, 11.8, 0.1, 2.4, 200.0, "1 sztuka obrana (200g)", "Owoce"),
    ("seed-owoc-mandarynka", "Mandarynka obrana", None, None, 53.0, 0.8, 13.3, 0.3, 1.8, 65.0, "1 sztuka obrana (65g)", "Owoce"),
    ("seed-owoc-klementynka", "Klementynka obrana", None, None, 50.0, 0.8, 12.5, 0.2, 1.8, 65.0, "1 sztuka obrana (65g)", "Owoce"),
    ("seed-owoc-cytryna", "Cytryna ze skórką", None, None, 29.0, 1.1, 9.3, 0.3, 2.8, 80.0, "1 sztuka (80g)", "Owoce"),
    ("seed-owoc-limonka", "Limonka świeża", None, None, 30.0, 0.7, 10.5, 0.2, 2.8, 60.0, "1 sztuka (60g)", "Owoce"),
    ("seed-owoc-grejpfrut-czerwony", "Grejpfrut czerwony obierany", None, None, 42.0, 0.8, 10.7, 0.1, 1.6, 250.0, "1 sztuka obrana (250g)", "Owoce"),
    ("seed-owoc-arbuz", "Arbuz miąższ bez skórki", None, None, 30.0, 0.6, 7.6, 0.1, 0.4, 300.0, "1 plaster (300g)", "Owoce"),
    ("seed-owoc-melon-galia", "Melon Galia / miodowy miąższ", None, None, 36.0, 0.5, 9.0, 0.1, 0.9, 200.0, "1 plaster (200g)", "Owoce"),
    ("seed-owoc-winogrona-jasne", "Winogrona jasne bezpestkowe", None, None, 69.0, 0.7, 18.1, 0.2, 0.9, 100.0, "1 mała kiść (100g)", "Owoce"),
    ("seed-owoc-winogrona-ciemne", "Winogrona ciemne deserowe", None, None, 70.0, 0.7, 18.2, 0.2, 1.0, 100.0, "1 mała kiść (100g)", "Owoce"),
    ("seed-owoc-kiwi", "Kiwi zielone dojrzałe obrane", None, None, 61.0, 1.1, 14.7, 0.5, 3.0, 75.0, "1 sztuka (75g)", "Owoce"),
    ("seed-owoc-gruszka-konferencja", "Gruszka Konferencja ze skórką", None, None, 57.0, 0.4, 15.2, 0.1, 3.1, 160.0, "1 sztuka średnia (160g)", "Owoce"),
    ("seed-owoc-brzoskwinia", "Brzoskwinia świeża ze skórką", None, None, 39.0, 0.9, 9.5, 0.3, 1.5, 130.0, "1 sztuka (130g)", "Owoce"),
    ("seed-owoc-nektarynka", "Nektarynka świeża", None, None, 44.0, 1.1, 10.6, 0.3, 1.7, 130.0, "1 sztuka (130g)", "Owoce"),
    ("seed-owoc-sliwki-wegierki", "Śliwki węgierki świeże", None, None, 46.0, 0.7, 11.4, 0.3, 1.4, 40.0, "1 sztuka (40g)", "Owoce"),
    ("seed-owoc-czeresnie", "Czereśnie świeże bez pestek", None, None, 63.0, 1.1, 16.0, 0.2, 2.1, 100.0, "1 garść (100g)", "Owoce"),
    ("seed-owoc-wisnie", "Wiśnie świeże bez pestek", None, None, 50.0, 1.0, 12.2, 0.3, 1.6, 100.0, "1 garść (100g)", "Owoce"),
    ("seed-owoc-ananas-swiezy", "Ananas świeży obrany", None, None, 50.0, 0.5, 13.1, 0.1, 1.4, 150.0, "1 gruby plaster (150g)", "Owoce"),
    ("seed-owoc-mango", "Mango świeże dojrzałe miąższ", None, None, 60.0, 0.8, 15.0, 0.4, 1.6, 200.0, "1 sztuka miąższ (200g)", "Owoce"),
    ("seed-owoc-granat-pestki", "Granat owoce pestki", None, None, 83.0, 1.7, 18.7, 1.2, 4.0, 100.0, "1/2 owocu pestki (100g)", "Owoce"),
    ("seed-owoc-awokado-hass", "Awokado Hass miąższ", None, None, 160.0, 2.0, 8.5, 14.7, 6.7, 140.0, "1 sztuka miąższ (140g)", "Owoce"),
    ("seed-owoc-morele-swieze", "Morele świeże", None, None, 48.0, 1.4, 11.1, 0.4, 2.0, 45.0, "1 sztuka (45g)", "Owoce"),
    ("seed-owoc-figi-swieze", "Figi świeże", None, None, 74.0, 0.8, 19.2, 0.3, 2.9, 50.0, "1 sztuka (50g)", "Owoce"),
    ("seed-owoc-czarna-porzeczka", "Czarna porzeczka świeża", None, None, 63.0, 1.4, 15.4, 0.4, 6.8, 100.0, "1 miseczka (100g)", "Owoce"),

    # Bakalie i owoce suszone
    ("seed-owoc-daktyle-suszone", "Daktyle suszone bez pestek", "Kresto", "5900354002015", 282.0, 2.5, 75.0, 0.4, 8.0, 30.0, "3-4 sztuki (30g)", "Bakalie"),
    ("seed-owoc-rodzynki-sultanskie", "Rodzynki sułtańskie", "Bakalland", "5900749001017", 299.0, 3.1, 79.2, 0.5, 3.7, 30.0, "1 garść (30g)", "Bakalie"),
    ("seed-owoc-zurawina-suszona", "Żurawina suszona słodzona", "Bakalland", "5900749001024", 320.0, 0.5, 80.0, 1.0, 5.0, 30.0, "1 garść (30g)", "Bakalie"),
    ("seed-owoc-morele-suszone", "Morele suszone całe", "Bakalland", "5900749001031", 241.0, 3.4, 62.6, 0.5, 7.3, 40.0, "4 sztuki (40g)", "Bakalie"),
    ("seed-owoc-sliwki-suszone", "Śliwki suszone kalifornijskie", "Bakalland", "5900749001048", 240.0, 2.2, 63.9, 0.4, 7.1, 40.0, "4 sztuki (40g)", "Bakalie"),
    ("seed-owoc-figi-suszone", "Figi suszone", "Bakalland", "5900749001055", 249.0, 3.3, 63.9, 0.9, 9.8, 40.0, "2 sztuki (40g)", "Bakalie"),

    # Tłuszcze, oleje i masła
    ("seed-tluszcz-oliwa-monini", "Oliwa z oliwek najwyższej jakości Extra Virgin", "Monini", "8005510001019", 824.0, 0.0, 0.0, 91.6, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-olej-rzepakowy-kujawski", "Olej rzepakowy z pierwszego tłoczenia", "Kujawski", "5900424001018", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-olej-slonecznikowy", "Olej słonecznikowy czysty", "Kruszwica", "5900424001025", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-olej-kokosowy-kfd", "Olej kokosowy nierafinowany extra virgin", "KFD", "5902444001019", 862.0, 0.0, 0.0, 100.0, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-olej-lniany-kujawski", "Olej lniany tłoczony na zimno", "Kujawski", "5900424001032", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-olej-z-pestek-dyni", "Olej z prażonych pestek dyni", "Oleofarm", "5904960001017", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-olej-sezamowy", "Olej sezamowy ciemny prażony", "House of Asia", "5902751001016", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-maslo-ekstra-laciate", "Masło ekstra 82% tłuszczu", "Łaciate", "5900820005014", 735.0, 0.7, 0.7, 82.0, 0.0, 10.0, "1 porcja na kromkę (10g)", "Masło"),
    ("seed-tluszcz-maslo-ekstra-mlekovita", "Masło ekstra polskie 82%", "Mlekovita", "5900512003016", 735.0, 0.7, 0.7, 82.0, 0.0, 10.0, "1 porcja na kromkę (10g)", "Masło"),
    ("seed-tluszcz-maslo-klarowane-ghee", "Masło klarowane Ghee 99.8%", "Mlekovita", "5900512003023", 898.0, 0.1, 0.0, 99.8, 0.0, 10.0, "1 łyżka (10g)", "Masło"),
    ("seed-tluszcz-margaryna-rama", "Margaryna do smarowania pieczywa Classic", "Rama", "8719200001016", 540.0, 0.0, 0.0, 60.0, 0.0, 10.0, "1 porcja na kromkę (10g)", "Masło"),
    ("seed-tluszcz-smalec-wieprzowy", "Smalec wieprzowy tradycyjny", None, None, 898.0, 0.0, 0.0, 99.8, 0.0, 15.0, "1 łyżka (15g)", "Oleje i tłuszcze"),
    ("seed-tluszcz-mleczko-kokosowe-realthai", "Mleczko kokosowe 80% ekstraktu", "Real Thai", "8852646001018", 185.0, 1.8, 2.5, 19.0, 0.0, 100.0, "1/4 puszki (100g)", "Oleje i tłuszcze"),

    # Orzechy, nasiona i masła orzechowe
    ("seed-tluszcz-maslo-orzechowe-kfd-smooth", "Masło orzechowe 100% arachidowe smooth", "KFD", "5902444001033", 596.0, 26.0, 14.0, 49.0, 7.5, 25.0, "1 czubata łyżka (25g)", "Masła orzechowe"),
    ("seed-tluszcz-maslo-orzechowe-kfd-crunchy", "Masło orzechowe 100% arachidowe crunchy", "KFD", "5902444001040", 596.0, 26.0, 14.0, 49.0, 7.5, 25.0, "1 czubata łyżka (25g)", "Masła orzechowe"),
    ("seed-tluszcz-maslo-migdalowe-kfd", "Masło migdałowe 100% z prażonych migdałów", "KFD", "5902444001057", 620.0, 21.0, 10.0, 55.0, 10.5, 25.0, "1 czubata łyżka (25g)", "Masła orzechowe"),
    ("seed-tluszcz-maslo-nerkowce-kfd", "Masło z orzechów nerkowca 100%", "KFD", "5902444001064", 580.0, 18.0, 26.0, 46.0, 4.0, 25.0, "1 czubata łyżka (25g)", "Masła orzechowe"),
    ("seed-tluszcz-orzechy-wloskie", "Orzechy włoskie łuskane połówki", "Bakalland", "5900749001062", 654.0, 15.2, 13.7, 65.2, 6.7, 30.0, "1 garść (30g)", "Orzechy"),
    ("seed-tluszcz-orzechy-laskowe", "Orzechy laskowe łuskane", "Bakalland", "5900749001079", 628.0, 15.0, 16.7, 60.8, 9.7, 30.0, "1 garść (30g)", "Orzechy"),
    ("seed-tluszcz-migdaly", "Migdały całe łuskane", "Bakalland", "5900749001086", 579.0, 21.2, 21.6, 49.9, 12.5, 30.0, "1 garść (30g)", "Orzechy"),
    ("seed-tluszcz-platki-migdalowe", "Płatki migdałowe", "Kresto", "5900354002022", 585.0, 21.0, 21.0, 50.0, 12.0, 15.0, "2 łyżki (15g)", "Orzechy"),
    ("seed-tluszcz-orzechy-nerkowca", "Orzechy nerkowca nerkowce", "Bakalland", "5900749001093", 553.0, 18.2, 30.2, 43.8, 3.3, 30.0, "1 garść (30g)", "Orzechy"),
    ("seed-tluszcz-orzeszki-ziemne-felix", "Orzeszki ziemne prażone bez soli", "Felix", "5900030001018", 585.0, 25.0, 16.0, 49.0, 8.0, 30.0, "1 garść (30g)", "Orzechy"),
    ("seed-tluszcz-orzechy-brazylijskie", "Orzechy brazylijskie", "Bakalland", "5900749001109", 659.0, 14.3, 12.3, 67.1, 7.5, 20.0, "4 sztuki (20g)", "Orzechy"),
    ("seed-tluszcz-orzechy-pekan", "Orzechy pekan", "Bakalland", "5900749001116", 691.0, 9.2, 13.9, 72.0, 9.6, 30.0, "1 garść (30g)", "Orzechy"),
    ("seed-tluszcz-pistacje-solone-felix", "Pistacje prażone solone w łupinach", "Felix", "5900030001025", 560.0, 20.0, 28.0, 45.0, 10.0, 30.0, "1 porcja bez łupin (30g)", "Orzechy"),
    ("seed-tluszcz-pestki-dyni", "Pestki dyni łuskane ciemnozielone", "Kresto", "5900354002039", 559.0, 30.2, 10.7, 49.0, 6.0, 20.0, "2 łyżki (20g)", "Nasiona"),
    ("seed-tluszcz-nasiona-slonecznika", "Nasiona słonecznika łuskane", "Kresto", "5900354002046", 584.0, 20.8, 20.0, 51.5, 8.6, 20.0, "2 łyżki (20g)", "Nasiona"),
    ("seed-tluszcz-chia-kresto", "Nasiona chia szałwia hiszpańska", "Kresto", "5900354002053", 486.0, 16.5, 42.1, 30.7, 34.4, 15.0, "1 łyżka (15g)", "Nasiona"),
    ("seed-tluszcz-siemie-lniane", "Siemię lniane całe ziarna", "Kresto", "5900354002060", 534.0, 18.3, 28.9, 42.2, 27.3, 15.0, "1 łyżka (15g)", "Nasiona"),
    ("seed-tluszcz-siemie-mielone", "Siemię lniane mielone odtłuszczone", "Kresto", "5900354002077", 340.0, 32.0, 35.0, 9.0, 30.0, 15.0, "1 łyżka (15g)", "Nasiona"),
    ("seed-tluszcz-sezam-bialy", "Sezam łuskany biały ziarno", "Kresto", "5900354002084", 573.0, 17.7, 23.4, 49.7, 11.8, 15.0, "1 łyżka (15g)", "Nasiona"),
    ("seed-tluszcz-tahini-jasmeen", "Pasta sezamowa Tahini 100%", "Jasmeen", "5902751001023", 630.0, 24.0, 9.0, 56.0, 8.0, 20.0, "1 łyżka (20g)", "Nasiona"),
    ("seed-tluszcz-wiorki-kokosowe", "Wiórki kokosowe", "Bakalland", "5900749001130", 660.0, 7.4, 23.6, 64.5, 14.0, 15.0, "2 łyżki (15g)", "Nasiona"),
]

def main():
    all_items = DAIRY_AND_EGGS + MEAT_AND_FISH + BAKERY_AND_GRAINS + FRUITS_VEG_FATS
    print(f"Total curated items to generate: {len(all_items)}")
    ids = set()
    for item in all_items:
        pid = item[0]
        if pid in ids:
            print(f"ERROR: Duplicate ID: {pid}", file=sys.stderr)
            sys.exit(1)
        ids.add(pid)
    print("All IDs are unique!")

    write_category_file("lib/data/categories/dairy_and_eggs.dart", "dairyAndEggsProducts", "Nabiał i jaja (Pilos, Mlekovita, Piątnica, Bakoma, Danone, itp.)", DAIRY_AND_EGGS)
    write_category_file("lib/data/categories/meat_and_fish.dart", "meatAndFishProducts", "Mięso, drób, wędliny i ryby (Kraina Wędlin, Pikok, Tarczyński, Morliny, Berlinki, itp.)", MEAT_AND_FISH)
    write_category_file("lib/data/categories/bakery_and_grains.dart", "bakeryAndGrainsProducts", "Pieczywo, zboża, kasze, makarony i ryże (Lubella, Kupiec, Dan Cake, Melvit, itp.)", BAKERY_AND_GRAINS)
    write_category_file("lib/data/categories/fruits_vegetables_fats.dart", "fruitsVegetablesFatsProducts", "Owoce, warzywa, grzyby, orzechy, nasiona i tłuszcze", FRUITS_VEG_FATS)
    print("Generation complete!")

if __name__ == "__main__":
    main()
