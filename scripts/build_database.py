# -*- coding: utf-8 -*-
"""
Script to generate lib/data/default_food_database.dart
"""
import sys

# Structure of product:
# (id, name, brand, barcode, calories, protein, carbs, fat, fiber, serving_size, serving_name, category)

PRODUCTS = [
    # =========================================================================
    # 1. PIECZYWO I ZBOŻA (Bread, cereals, pasta, grains, flours)
    # =========================================================================
    ("seed-piecz-chleb-zytni-razowy", "Chleb żytni razowy", None, None, 227.0, 5.8, 44.0, 1.7, 6.2, 35.0, "1 kromka (35g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-pszenny", "Chleb pszenny tradycyjny", None, None, 265.0, 8.0, 50.0, 3.2, 2.7, 35.0, "1 kromka (35g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-tostowy-pszenny", "Chleb tostowy pszenny", "Dan Cake", "5900579001017", 260.0, 8.5, 49.0, 2.5, 3.0, 25.0, "1 kromka (25g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-tostowy-pelnoziarnisty", "Chleb tostowy pełnoziarnisty", "Dan Cake", "5900579001024", 245.0, 9.0, 43.0, 2.8, 6.5, 25.0, "1 kromka (25g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-orkiszowy", "Chleb orkiszowy", None, None, 240.0, 9.2, 45.0, 2.0, 5.5, 35.0, "1 kromka (35g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-slonecznikowy", "Chleb ze słonecznikiem", None, None, 270.0, 8.8, 43.0, 6.5, 5.0, 35.0, "1 kromka (35g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-wieloziarnisty", "Chleb wieloziarnisty", None, None, 255.0, 8.5, 44.0, 4.5, 5.8, 35.0, "1 kromka (35g)", "Pieczywo i zboża"),
    ("seed-piecz-bulka-kajzerka", "Bułka kajzerka pszenna", None, None, 296.0, 8.4, 58.0, 3.6, 2.3, 60.0, "1 sztuka (60g)", "Pieczywo i zboża"),
    ("seed-piecz-bulka-grahamka", "Bułka grahamka", None, None, 250.0, 8.5, 48.0, 2.0, 6.0, 70.0, "1 sztuka (70g)", "Pieczywo i zboża"),
    ("seed-piecz-bulka-wieloziarnista-fitness", "Bułka fitness wieloziarnista", None, None, 268.0, 9.5, 44.0, 5.5, 6.2, 80.0, "1 sztuka (80g)", "Pieczywo i zboża"),
    ("seed-piecz-bulka-ciabatta", "Bułka ciabatta", None, None, 270.0, 8.5, 53.0, 2.5, 2.8, 80.0, "1 sztuka (80g)", "Pieczywo i zboża"),
    ("seed-piecz-bulka-hamburger", "Bułka do hamburgera z sezamem", "Dan Cake", "5900579001031", 285.0, 8.2, 51.0, 5.0, 2.5, 75.0, "1 sztuka (75g)", "Pieczywo i zboża"),
    ("seed-piecz-rogal-maslany", "Rogal maślany", None, None, 320.0, 7.5, 52.0, 8.5, 2.0, 70.0, "1 sztuka (70g)", "Pieczywo i zboża"),
    ("seed-piecz-croissant-maslany", "Croissant maślany", None, None, 406.0, 8.2, 45.8, 21.0, 2.6, 60.0, "1 sztuka (60g)", "Pieczywo i zboża"),
    ("seed-piecz-bagietka-pszenna", "Bagietka pszenna francuska", None, None, 275.0, 8.5, 56.0, 1.5, 2.5, 100.0, "1/2 bagietki (100g)", "Pieczywo i zboża"),
    ("seed-piecz-bagietka-czosnkowa", "Bagietka z masłem czosnkowym", "Dan Cake", "5900579001048", 345.0, 7.0, 42.0, 16.5, 2.0, 85.0, "1/2 sztuki (85g)", "Pieczywo i zboża"),
    ("seed-piecz-chleb-pita", "Chlebek pita", None, None, 275.0, 9.1, 55.7, 1.2, 2.2, 60.0, "1 placek (60g)", "Pieczywo i zboża"),
    ("seed-piecz-tortilla-pszenna", "Tortilla pszenna wraps", "Dijo", "5907689001015", 310.0, 8.5, 53.0, 6.5, 3.0, 62.0, "1 placek (62g)", "Pieczywo i zboża"),
    ("seed-piecz-tortilla-pelnoziarnista", "Tortilla pełnoziarnista", "Dijo", "5907689001022", 295.0, 9.5, 48.0, 6.0, 6.5, 62.0, "1 placek (62g)", "Pieczywo i zboża"),
    ("seed-piecz-lawasz-ormianski", "Lawasz pszenny ormiański", None, None, 275.0, 8.5, 56.0, 1.2, 2.4, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-owsiane-gorskie", "Płatki owsiane górskie", "Kupiec", "5906747160012", 375.0, 13.0, 62.0, 7.0, 10.0, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-owsiane-blyskawiczne", "Płatki owsiane błyskawiczne", "Kupiec", "5906747160029", 370.0, 13.0, 62.0, 7.0, 10.0, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-jaglane", "Płatki jaglane", "Melvit", "5907474001016", 360.0, 11.0, 68.0, 3.5, 4.0, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-orkiszowe", "Płatki orkiszowe", "Kupiec", "5906747160036", 350.0, 13.5, 63.0, 2.7, 9.0, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-gryczane", "Płatki gryczane", "Melvit", "5907474001023", 355.0, 12.0, 67.0, 3.0, 6.0, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-kukurydziane", "Płatki kukurydziane Corn Flakes", "Nestlé", "5900020000018", 378.0, 7.2, 84.0, 1.4, 3.0, 30.0, "1 miseczka (30g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-cini-minis", "Płatki cynamonowe Cini Minis", "Nestlé", "5900020000025", 423.0, 6.2, 74.5, 10.3, 5.0, 30.0, "1 porcja (30g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-nesquik", "Płatki czekoladowe Nesquik", "Nestlé", "5900020000032", 379.0, 7.3, 75.1, 3.8, 5.2, 30.0, "1 porcja (30g)", "Pieczywo i zboża"),
    ("seed-piecz-platki-chocapic", "Płatki czekoladowe Chocapic", "Nestlé", "5900020000049", 388.0, 8.4, 73.6, 4.7, 5.6, 30.0, "1 porcja (30g)", "Pieczywo i zboża"),
    ("seed-piecz-granola-orzechowa", "Granola z orzechami Crunchy", "Sante", "5900617001018", 460.0, 9.5, 63.0, 18.0, 6.5, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-musli-tradycyjne", "Musli tradycyjne z owocami", "Sante", "5900617001025", 365.0, 10.0, 65.0, 5.5, 9.0, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-ryz-bialy", "Ryż biały długoziarnisty", "Kupiec", "5906747160043", 350.0, 7.0, 78.0, 0.7, 1.4, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-ryz-basmati", "Ryż basmati", "Kupiec", "5906747160050", 352.0, 8.5, 77.0, 0.6, 1.5, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-ryz-jasminowy", "Ryż jaśminowy", "Kupiec", "5906747160067", 348.0, 7.2, 77.5, 0.6, 1.2, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-ryz-brazowy", "Ryż brązowy naturalny", "Kupiec", "5906747160074", 354.0, 7.5, 74.0, 2.0, 4.5, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-ryz-parboiled", "Ryż parboiled", "Kupiec", "5906747160081", 352.0, 7.5, 77.0, 0.7, 1.8, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-gryczana-prazona", "Kasza gryczana prażona", "Kupiec", "5906747160098", 345.0, 12.6, 69.0, 3.1, 6.0, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-gryczana-biala", "Kasza gryczana biała niepalona", "Melvit", "5907474001030", 340.0, 12.0, 68.0, 2.8, 5.9, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-jaglana", "Kasza jaglana", "Kupiec", "5906747160104", 350.0, 10.5, 71.0, 2.9, 3.2, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-peczak", "Kasza jęczmienna pęczak", "Kupiec", "5906747160111", 335.0, 8.4, 69.0, 2.0, 15.0, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-jeczmienna-wiejska", "Kasza jęczmienna wiejska", "Kupiec", "5906747160128", 342.0, 8.5, 70.0, 2.0, 12.0, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-manna", "Kasza manna", "Kupiec", "5906747160135", 350.0, 10.0, 74.0, 1.2, 2.5, 50.0, "1 porcja (50g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-kuskus", "Kasza kuskus", "Kupiec", "5906747160142", 360.0, 12.5, 73.0, 1.5, 4.0, 70.0, "1 porcja (70g)", "Pieczywo i zboża"),
    ("seed-piecz-kasza-bulgur", "Kasza bulgur", "Kupiec", "5906747160159", 342.0, 12.3, 65.0, 1.5, 8.0, 100.0, "1 woreczek (100g)", "Pieczywo i zboża"),
    ("seed-piecz-quinoa-komosa", "Komosa ryżowa Quinoa biała", "Melvit", "5907474001047", 368.0, 14.1, 57.2, 6.1, 7.0, 60.0, "1 porcja (60g)", "Pieczywo i zboża"),
    ("seed-piecz-makaron-spaghetti", "Makaron spaghetti", "Lubella", "5900038000010", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Pieczywo i zboża"),
    ("seed-piecz-makaron-swiderki", "Makaron świderki fusilli", "Lubella", "5900038000027", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Pieczywo i zboża"),
    ("seed-piecz-makaron-penne", "Makaron pióra penne", "Lubella", "5900038000034", 356.0, 12.0, 73.0, 1.4, 3.0, 100.0, "1 porcja (100g)", "Pieczywo i zboża"),
    ("seed-piecz-makaron-pelnoziarnisty", "Makaron pełnoziarnisty pióra", "Lubella", "5900038000041", 348.0, 15.0, 62.0, 2.5, 8.0, 100.0, "1 porcja (100g)", "Pieczywo i zboża"),
    ("seed-piecz-makaron-jajeczny-wstazki", "Makaron jajeczny wstążki", "Lubella", "5900038000058", 365.0, 13.0, 72.0, 2.5, 3.0, 100.0, "1 porcja (100g)", "Pieczywo i zboża"),
    ("seed-piecz-makaron-ryzowy-nitki", "Makaron ryżowy nitki", "TaoTao", "5905679001018", 358.0, 7.0, 81.0, 0.5, 1.0, 80.0, "1 porcja (80g)", "Pieczywo i zboża"),
    ("seed-piecz-maka-pszenna-typ-500", "Mąka pszenna poznańska typ 500", "Lubella", "5900038000065", 345.0, 10.0, 74.0, 1.0, 2.5, 50.0, "1/2 szklanki (50g)", "Pieczywo i zboża"),
    ("seed-piecz-maka-pelnoziarnista-1850", "Mąka pszenna graham typ 1850", "Lubella", "5900038000072", 335.0, 12.0, 63.0, 2.2, 11.0, 50.0, "1/2 szklanki (50g)", "Pieczywo i zboża"),
    ("seed-piecz-maka-zytnia-720", "Mąka żytnia typ 720", "Kupiec", "5906747160166", 330.0, 8.0, 68.0, 1.5, 8.5, 50.0, "1/2 szklanki (50g)", "Pieczywo i zboża"),
    ("seed-piecz-bulka-tarta", "Bułka tarta", "Lubella", "5900038000089", 360.0, 11.0, 72.0, 2.0, 4.0, 20.0, "1 czubata łyżka (20g)", "Pieczywo i zboża"),
    ("seed-piecz-otreby-owsiane", "Otręby owsiane wysokobłonnikowe", "Kupiec", "5906747160173", 365.0, 17.0, 50.0, 7.0, 15.0, 20.0, "2 łyżki (20g)", "Pieczywo i zboża"),
    ("seed-piecz-wafle-ryzowe-naturalne", "Wafle ryżowe naturalne", "Kupiec", "5906747160180", 380.0, 8.0, 82.0, 2.0, 3.0, 10.0, "1 sztuka (10g)", "Pieczywo i zboża"),
    ("seed-piecz-pieczywo-chrupkie-zytnie", "Pieczywo chrupkie żytnie", "Wasa", "7300400117006", 334.0, 9.0, 61.5, 1.5, 19.0, 12.0, "1 kromka (12g)", "Pieczywo i zboża"),

    # =========================================================================
    # 2. NABIAŁ I JAJA (Dairy, cheeses, milks, eggs)
    # =========================================================================
    ("seed-nab-jajko-klasa-m", "Jajko kurze całe klasa M", None, None, 143.0, 12.6, 0.7, 9.9, 0.0, 55.0, "1 sztuka klasa M (55g)", "Nabiał i jaja"),
    ("seed-nab-jajko-klasa-l", "Jajko kurze całe klasa L", None, None, 143.0, 12.6, 0.7, 9.9, 0.0, 65.0, "1 sztuka klasa L (65g)", "Nabiał i jaja"),
    ("seed-nab-bialko-jaja", "Białko jaja kurzego", None, None, 52.0, 10.9, 0.7, 0.2, 0.0, 35.0, "1 białko jaja (35g)", "Nabiał i jaja"),
    ("seed-nab-zoltko-jaja", "Żółtko jaja kurzego", None, None, 322.0, 15.9, 3.6, 26.5, 0.0, 20.0, "1 żółtko jaja (20g)", "Nabiał i jaja"),
    ("seed-nab-skyr-naturalny-piatnica", "Skyr jogurt typu islandzkiego naturalny", "Piątnica", "5900820015501", 65.0, 12.0, 4.0, 0.0, 0.0, 150.0, "1 kubek (150g)", "Nabiał i jaja"),
    ("seed-nab-skyr-waniliowy-piatnica", "Skyr jogurt waniliowy", "Piątnica", "5900820015525", 86.0, 10.0, 11.5, 0.0, 0.0, 150.0, "1 kubek (150g)", "Nabiał i jaja"),
    ("seed-nab-skyr-truskawkowy-piatnica", "Skyr jogurt truskawkowy", "Piątnica", "5900820015518", 87.0, 10.0, 11.8, 0.0, 0.0, 150.0, "1 kubek (150g)", "Nabiał i jaja"),
    ("seed-nab-skyr-jagodowy-piatnica", "Skyr jogurt jagodowy", "Piątnica", "5900820015532", 87.0, 10.0, 11.8, 0.0, 0.0, 150.0, "1 kubek (150g)", "Nabiał i jaja"),
    ("seed-nab-skyr-solony-karmel-piatnica", "Skyr jogurt słony karmel", "Piątnica", "5900820015549", 88.0, 10.0, 12.0, 0.0, 0.0, 150.0, "1 kubek (150g)", "Nabiał i jaja"),
    ("seed-nab-skyr-pitny-naturalny", "Skyr pitny naturalny", "Piątnica", "5900820015556", 62.0, 8.5, 4.5, 0.0, 0.0, 330.0, "1 butelka (330ml)", "Nabiał i jaja"),
    ("seed-nab-twarog-chudy-piatnica", "Twaróg chudy klinek", "Piątnica", "5900820000606", 86.0, 18.0, 3.5, 0.0, 0.0, 250.0, "1 kostka (250g)", "Nabiał i jaja"),
    ("seed-nab-twarog-poltlusty-piatnica", "Twaróg półtłusty klinek", "Piątnica", "5900820000613", 110.0, 17.5, 3.7, 4.0, 0.0, 250.0, "1 kostka (250g)", "Nabiał i jaja"),
    ("seed-nab-twarog-tlusty-piatnica", "Twaróg tłusty klinek", "Piątnica", "5900820000620", 155.0, 16.0, 3.5, 8.5, 0.0, 250.0, "1 kostka (250g)", "Nabiał i jaja"),
    ("seed-nab-twarog-sernikowy-wiaderko", "Twaróg sernikowy w wiaderku", "Piątnica", "5900820000637", 125.0, 12.0, 4.0, 6.5, 0.0, 100.0, "1 porcja (100g)", "Nabiał i jaja"),
    ("seed-nab-serek-wiejski-naturalny-piatnica", "Serek wiejski naturalny cottage cheese", "Piątnica", "5900820000019", 97.0, 11.0, 2.0, 5.0, 0.0, 200.0, "1 kubek (200g)", "Nabiał i jaja"),
    ("seed-nab-serek-wiejski-lekki-piatnica", "Serek wiejski lekki 3% tłuszczu", "Piątnica", "5900820000217", 81.0, 12.5, 2.4, 2.3, 0.0, 200.0, "1 kubek (200g)", "Nabiał i jaja"),
    ("seed-nab-serek-wiejski-wysokobialkowy", "Serek wiejski wysokobiałkowy", "Piątnica", "5900820000224", 85.0, 14.0, 2.5, 2.0, 0.0, 200.0, "1 kubek (200g)", "Nabiał i jaja"),
    ("seed-nab-serek-wiejski-truskawki", "Serek wiejski z truskawkami", "Piątnica", "5900820000231", 108.0, 8.5, 11.0, 3.5, 0.0, 150.0, "1 kubek (150g)", "Nabiał i jaja"),
    ("seed-nab-mleko-05-laciate", "Mleko spożywcze 0.5% UHT", "Łaciate", "5900820001023", 35.0, 3.4, 4.9, 0.5, 0.0, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-mleko-15-laciate", "Mleko spożywcze 1.5% UHT", "Łaciate", "5900820001030", 44.0, 3.3, 4.8, 1.5, 0.0, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-mleko-20-laciate", "Mleko spożywcze 2.0% UHT", "Łaciate", "5900820001009", 50.0, 3.3, 4.8, 2.0, 0.0, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-mleko-32-laciate", "Mleko spożywcze 3.2% UHT", "Łaciate", "5900820001016", 60.0, 3.2, 4.8, 3.2, 0.0, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-mleko-bez-laktozy-15", "Mleko bez laktozy 1.5% UHT", "Łaciate", "5900820001047", 44.0, 3.3, 4.8, 1.5, 0.0, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-napoj-owsiany-barista", "Napój owsiany Barista", "Oatly", "7394376616037", 59.0, 1.1, 6.7, 3.0, 0.8, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-napoj-migdalowy-nieslodzony", "Napój migdałowy niesłodzony", "Alpro", "5411188115489", 13.0, 0.4, 0.2, 1.1, 0.3, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-napoj-sojowy-naturalny", "Napój sojowy naturalny", "Alpro", "5411188115496", 39.0, 3.3, 1.6, 1.8, 0.5, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-jogurt-naturalny-gesty", "Jogurt naturalny gęsty", "Bakoma", "5900334001019", 60.0, 4.2, 5.5, 2.5, 0.0, 180.0, "1 kubek (180g)", "Nabiał i jaja"),
    ("seed-nab-jogurt-grecki-piatnica", "Jogurt grecki tradycyjny", "Piątnica", "5900820001504", 120.0, 4.5, 4.0, 10.0, 0.0, 200.0, "1 kubek (200g)", "Nabiał i jaja"),
    ("seed-nab-jogurt-grecki-lekki", "Jogurt grecki lekki 0% tłuszczu", "Piątnica", "5900820001511", 60.0, 9.0, 4.0, 0.0, 0.0, 180.0, "1 kubek (180g)", "Nabiał i jaja"),
    ("seed-nab-jogurt-activia-naturalna", "Jogurt Activia naturalna", "Danone", "5900643001013", 68.0, 4.4, 6.0, 3.1, 0.0, 160.0, "1 kubek (160g)", "Nabiał i jaja"),
    ("seed-nab-jogurt-fantasia-truskawka", "Jogurt Fantasia z truskawkami", "Danone", "5900643001020", 112.0, 3.2, 14.5, 4.6, 0.3, 122.0, "1 kubek (122g)", "Nabiał i jaja"),
    ("seed-nab-kefir-naturalny-mlekovita", "Kefir naturalny", "Mlekovita", "5900512001012", 46.0, 3.4, 4.7, 1.5, 0.0, 400.0, "1 butelka (400g)", "Nabiał i jaja"),
    ("seed-nab-maslanka-naturalna-mragowska", "Maślanka naturalna", "Mrągowska", "5900820002013", 44.0, 3.4, 4.6, 1.5, 0.0, 250.0, "1 szklanka (250ml)", "Nabiał i jaja"),
    ("seed-nab-ser-gouda-plastry", "Ser Gouda w plastrach", "Mlekovita", "5900512002019", 350.0, 25.0, 0.1, 27.0, 0.0, 30.0, "1 plaster (30g)", "Nabiał i jaja"),
    ("seed-nab-ser-edam-plastry", "Ser Edam w plastrach", "Mlekovita", "5900512002026", 345.0, 26.0, 0.1, 26.0, 0.0, 30.0, "1 plaster (30g)", "Nabiał i jaja"),
    ("seed-nab-ser-krolewski-sierpc", "Ser Królewski w plastrach", "Sierpc", "5901235001014", 355.0, 26.0, 0.1, 28.0, 0.0, 30.0, "1 plaster (30g)", "Nabiał i jaja"),
    ("seed-nab-ser-mozzarella-kulka", "Ser Mozzarella kulka w zalewie", "Galbani", "8000430139151", 240.0, 18.0, 1.5, 18.0, 0.0, 125.0, "1 kulka (125g)", "Nabiał i jaja"),
    ("seed-nab-ser-mozzarella-light", "Ser Mozzarella kulka light", "Galbani", "8000430139168", 160.0, 20.0, 1.5, 8.5, 0.0, 125.0, "1 kulka (125g)", "Nabiał i jaja"),
    ("seed-nab-ser-mozzarella-wiorki", "Ser Mozzarella tarty wiórki", "Mlekovita", "5900512002033", 310.0, 24.0, 2.0, 23.0, 0.0, 50.0, "1 garść (50g)", "Nabiał i jaja"),
    ("seed-nab-ser-feta-oryginalna", "Ser Feta oryginalny ChNP", "Dodoni", "5201103001011", 260.0, 16.0, 0.7, 21.0, 0.0, 50.0, "1 porcja (50g)", "Nabiał i jaja"),
    ("seed-nab-ser-favita-salatkowy", "Ser sałatkowy typu greckiego Favita", "Mlekovita", "5900512002040", 220.0, 11.0, 4.0, 18.0, 0.0, 50.0, "1 porcja (50g)", "Nabiał i jaja"),
    ("seed-nab-ser-parmigiano-reggiano", "Ser Parmigiano Reggiano Parmezan", "Zanetti", "8002580001017", 402.0, 32.0, 0.0, 30.0, 0.0, 15.0, "1 czubata łyżka (15g)", "Nabiał i jaja"),
    ("seed-nab-ser-grana-padano", "Ser Grana Padano tarty", "Zanetti", "8002580001024", 398.0, 33.0, 0.0, 29.0, 0.0, 15.0, "1 czubata łyżka (15g)", "Nabiał i jaja"),
    ("seed-nab-ser-cheddar", "Ser Cheddar w plastrach", "Mlekovita", "5900512002057", 400.0, 25.0, 1.0, 33.0, 0.0, 30.0, "1 plaster (30g)", "Nabiał i jaja"),
    ("seed-nab-ser-camembert-turek", "Ser Camembert naturalny", "Turek", "5900354001018", 290.0, 19.0, 0.5, 23.0, 0.0, 60.0, "1/2 krążka (60g)", "Nabiał i jaja"),
    ("seed-nab-ser-brie-turek", "Ser Brie naturalny", "Turek", "5900354001025", 310.0, 18.0, 0.5, 26.0, 0.0, 60.0, "1/2 krążka (60g)", "Nabiał i jaja"),
    ("seed-nab-serek-almette-smietankowy", "Serek puszysty Almette śmietankowy", "Hochland", "5901327001019", 255.0, 6.0, 3.5, 24.0, 0.0, 30.0, "1 porcja (30g)", "Nabiał i jaja"),
    ("seed-nab-serek-twoj-smak-piatnica", "Serek kremowy Twój Smak naturalny", "Piątnica", "5900820003010", 242.0, 6.1, 3.2, 23.0, 0.0, 30.0, "1 porcja (30g)", "Nabiał i jaja"),
    ("seed-nab-smietana-12-piatnica", "Śmietana 12% ukwaszona", "Piątnica", "5900820004017", 134.0, 3.0, 4.2, 12.0, 0.0, 25.0, "1 łyżka (25g)", "Nabiał i jaja"),
    ("seed-nab-smietana-18-piatnica", "Śmietana 18% ukwaszona", "Piątnica", "5900820004024", 186.0, 2.7, 3.8, 18.0, 0.0, 25.0, "1 łyżka (25g)", "Nabiał i jaja"),
    ("seed-nab-smietanka-30-laciata", "Śmietanka 30% słodka UHT", "Łaciata", "5900820004031", 291.0, 2.3, 3.3, 30.0, 0.0, 30.0, "2 łyżki (30g)", "Nabiał i jaja"),
    ("seed-nab-smietanka-36-laciata", "Śmietanka 36% do ubijania UHT", "Łaciata", "5900820004048", 345.0, 2.1, 3.0, 36.0, 0.0, 30.0, "2 łyżki (30g)", "Nabiał i jaja"),

    # =========================================================================
    # 3. MIĘSO DRÓB I RYBY (Meat, poultry, cold cuts, fish, seafood)
    # =========================================================================
    ("seed-mieso-piers-kurczaka-surowa", "Filet z piersi kurczaka surowy", None, None, 106.0, 21.5, 0.0, 1.3, 0.0, 200.0, "1 pojedynczy filet (200g)", "Mięso drób i ryby"),
    ("seed-mieso-piers-kurczaka-pieczona", "Pierś z kurczaka pieczona bez tłuszczu", None, None, 150.0, 31.0, 0.0, 3.0, 0.0, 150.0, "1 porcja (150g)", "Mięso drób i ryby"),
    ("seed-mieso-udko-kurczaka-surowe", "Udko z kurczaka ze skórą surowe", None, None, 160.0, 17.5, 0.0, 10.0, 0.0, 220.0, "1 sztuka ze skórą i kością (220g)", "Mięso drób i ryby"),
    ("seed-mieso-udo-kurczaka-bez-skory", "Mięso z uda kurczaka bez skóry i kości", None, None, 125.0, 19.5, 0.0, 4.5, 0.0, 150.0, "1 porcja (150g)", "Mięso drób i ryby"),
    ("seed-mieso-skrzydelka-kurczaka", "Skrzydełka z kurczaka surowe", None, None, 185.0, 18.0, 0.0, 12.5, 0.0, 100.0, "1 sztuka (100g)", "Mięso drób i ryby"),
    ("seed-mieso-watrobka-drobiowa", "Wątróbka z kurczaka surowa", None, None, 120.0, 19.0, 1.5, 4.5, 0.0, 150.0, "1 porcja (150g)", "Mięso drób i ryby"),
    ("seed-mieso-piers-indyka-surowa", "Filet z piersi indyka surowy", None, None, 104.0, 22.0, 0.0, 1.2, 0.0, 150.0, "1 stek z indyka (150g)", "Mięso drób i ryby"),
    ("seed-mieso-mielone-z-indyka", "Mięso mielone z piersi indyka", None, None, 115.0, 21.0, 0.0, 3.5, 0.0, 200.0, "1/2 tacki (200g)", "Mięso drób i ryby"),
    ("seed-mieso-udziec-z-indyka", "Mięso z udźca indyka bez skóry", None, None, 130.0, 20.0, 0.0, 5.5, 0.0, 150.0, "1 porcja (150g)", "Mięso drób i ryby"),
    ("seed-mieso-mielone-wolowe-chude", "Mięso mielone wołowe chude <10% tłuszczu", None, None, 160.0, 21.0, 0.0, 8.5, 0.0, 200.0, "1/2 opakowania (200g)", "Mięso drób i ryby"),
    ("seed-mieso-mielone-wieprz-wol", "Mięso mielone wieprzowo-wołowe", "Rzeźnik", "5900001001010", 220.0, 17.0, 0.5, 17.0, 0.0, 200.0, "1/2 opakowania (200g)", "Mięso drób i ryby"),
    ("seed-mieso-poledwiczka-wieprzowa", "Polędwiczka wieprzowa surowa", None, None, 120.0, 21.5, 0.0, 3.5, 0.0, 200.0, "1 porcja (200g)", "Mięso drób i ryby"),
    ("seed-mieso-schab-bez-kosci", "Schab wieprzowy bez kości surowy", None, None, 130.0, 22.0, 0.0, 4.5, 0.0, 150.0, "1 plaster (150g)", "Mięso drób i ryby"),
    ("seed-mieso-karkowka-wieprzowa", "Karkówka wieprzowa surowa", None, None, 230.0, 17.0, 0.0, 18.0, 0.0, 150.0, "1 plaster (150g)", "Mięso drób i ryby"),
    ("seed-mieso-zeberka-wieprzowe", "Żeberka wieprzowe surowe", None, None, 275.0, 16.0, 0.0, 23.5, 0.0, 200.0, "1 porcja (200g)", "Mięso drób i ryby"),
    ("seed-mieso-szynka-wieprzowa-surowa", "Szynka wieprzowa surowa kulka", None, None, 135.0, 21.0, 0.0, 5.5, 0.0, 150.0, "1 porcja (150g)", "Mięso drób i ryby"),
    ("seed-mieso-boczek-surowy", "Boczek wieprzowy surowy", None, None, 390.0, 14.0, 0.0, 37.0, 0.0, 50.0, "2 plastry (50g)", "Mięso drób i ryby"),
    ("seed-mieso-boczek-wedzony-krakus", "Boczek wędzony parzony plastry", "Krakus", "5900783001010", 320.0, 16.0, 0.5, 28.0, 0.0, 50.0, "2 plastry (50g)", "Mięso drób i ryby"),
    ("seed-mieso-poledwica-wolowa", "Polędwica wołowa surowa", None, None, 135.0, 22.0, 0.0, 5.0, 0.0, 180.0, "1 stek (180g)", "Mięso drób i ryby"),
    ("seed-mieso-rostbef-wolowy", "Rostbef wołowy stek", None, None, 155.0, 22.5, 0.0, 7.0, 0.0, 200.0, "1 stek (200g)", "Mięso drób i ryby"),
    ("seed-mieso-antrykot-wolowy", "Antrykot wołowy stek Ribeye", None, None, 220.0, 20.0, 0.0, 15.5, 0.0, 250.0, "1 stek (250g)", "Mięso drób i ryby"),
    ("seed-mieso-gulasz-wolowy", "Wołowina gulaszowa chuda", None, None, 140.0, 21.0, 0.0, 6.0, 0.0, 200.0, "1 porcja (200g)", "Mięso drób i ryby"),
    ("seed-mieso-szynka-konserwowa-krakus", "Szynka konserwowa z wieprzowiny", "Krakus", "5900783001027", 95.0, 17.0, 1.5, 2.0, 0.0, 50.0, "2 plastry (50g)", "Mięso drób i ryby"),
    ("seed-mieso-poledwica-sopocka-krakus", "Polędwica sopocka", "Krakus", "5900783001034", 105.0, 19.0, 1.0, 2.5, 0.0, 40.0, "3 plastry (40g)", "Mięso drób i ryby"),
    ("seed-mieso-szynka-indyka-dolinadobra", "Szynka z piersi indyka 100% z indyka", "Dolina Dobra", "5902581001013", 90.0, 19.5, 1.0, 1.0, 0.0, 40.0, "3 plastry (40g)", "Mięso drób i ryby"),
    ("seed-mieso-szynka-z-kurczaka", "Szynka z fileta kurczaka", "Morliny", "5900783001041", 92.0, 18.0, 1.5, 1.2, 0.0, 40.0, "3 plastry (40g)", "Mięso drób i ryby"),
    ("seed-mieso-szynka-szwarcwaldzka", "Szynka szwarcwaldzka dojrzewająca", None, None, 235.0, 25.0, 0.5, 15.0, 0.0, 30.0, "3 plastry (30g)", "Mięso drób i ryby"),
    ("seed-mieso-prosciutto-crudo", "Szynka parmeńska Prosciutto Crudo", None, None, 225.0, 27.0, 0.5, 13.0, 0.0, 30.0, "3 plastry (30g)", "Mięso drób i ryby"),
    ("seed-mieso-kabanosy-drob-tarczynski", "Kabanosy Exclusive drobiowe", "Tarczyński", "5902581600117", 485.0, 28.0, 4.5, 39.0, 0.0, 50.0, "1/2 paczki (50g)", "Mięso drób i ryby"),
    ("seed-mieso-kabanosy-wieprz-tarczynski", "Kabanosy Exclusive wieprzowe", "Tarczyński", "5902581600100", 520.0, 25.0, 4.0, 45.0, 0.0, 50.0, "1/2 paczki (50g)", "Mięso drób i ryby"),
    ("seed-mieso-parowki-berlinki-klasyczne", "Parówki Berlinki klasyczne", "Morliny", "5900783000013", 260.0, 13.0, 2.5, 22.0, 0.0, 50.0, "1 parówka (50g)", "Mięso drób i ryby"),
    ("seed-mieso-parowki-berlinki-kurczak", "Parówki Berlinki z kurczaka", "Morliny", "5900783000020", 220.0, 14.0, 2.0, 17.0, 0.0, 50.0, "1 parówka (50g)", "Mięso drób i ryby"),
    ("seed-mieso-parowki-z-szynki-krakus", "Parówki z szynki 93% mięsa", "Krakus", "5900783001058", 240.0, 15.0, 1.5, 19.5, 0.0, 50.0, "1 parówka (50g)", "Mięso drób i ryby"),
    ("seed-mieso-kielbasa-slaska-morliny", "Kiełbasa śląska", "Morliny", "5900783001065", 250.0, 13.0, 1.5, 21.0, 0.0, 100.0, "1 pętko (100g)", "Mięso drób i ryby"),
    ("seed-mieso-kielbasa-krakowska-sucha", "Kiełbasa krakowska sucha z szynki", "Krakus", "5900783001072", 205.0, 26.0, 1.5, 10.5, 0.0, 50.0, "5 plastrów (50g)", "Mięso drób i ryby"),
    ("seed-mieso-kielbasa-torunska", "Kiełbasa toruńska wędzona", "Duda", "5900488001014", 270.0, 15.0, 1.0, 23.0, 0.0, 100.0, "1 kawałek (100g)", "Mięso drób i ryby"),
    ("seed-mieso-pasztet-pieczony", "Pasztet wieprzowy pieczony tradycyjny", None, None, 280.0, 14.0, 5.0, 22.0, 1.0, 50.0, "1 gruby plaster (50g)", "Mięso drób i ryby"),
    ("seed-mieso-pasztet-profie-drobiowy", "Pasztet z drobiem", "Profi", "5901243001013", 195.0, 9.5, 8.0, 14.0, 0.5, 50.0, "1/3 puszki (50g)", "Mięso drób i ryby"),
    ("seed-mieso-losos-atlantycki-swiezy", "Łosoś atlantycki filet świeży", None, None, 208.0, 20.0, 0.0, 13.5, 0.0, 150.0, "1 porcja fileta (150g)", "Mięso drób i ryby"),
    ("seed-mieso-losos-wedzony-plastry", "Łosoś wędzony na zimno plastry", "SuperFish", "5902574001013", 170.0, 21.0, 0.5, 9.5, 0.0, 50.0, "1/2 opakowania (50g)", "Mięso drób i ryby"),
    ("seed-mieso-losos-wedzony-goraco", "Łosoś wędzony na gorąco kawałek", "SuperFish", "5902574001020", 215.0, 22.0, 0.0, 14.0, 0.0, 100.0, "1 kawałek (100g)", "Mięso drób i ryby"),
    ("seed-mieso-pstrag-teczowy", "Pstrąg tęczowy patroszony świeży", None, None, 135.0, 19.0, 0.0, 6.5, 0.0, 200.0, "1 sztuka (200g)", "Mięso drób i ryby"),
    ("seed-mieso-dorsz-poledwica", "Dorsz atlantycki polędwica bez skóry", None, None, 75.0, 17.5, 0.0, 0.6, 0.0, 150.0, "1 polędwiczka (150g)", "Mięso drób i ryby"),
    ("seed-mieso-mintaj-filet", "Mintaj bez skóry filet mrożony", None, None, 73.0, 16.5, 0.0, 0.6, 0.0, 150.0, "1 filet (150g)", "Mięso drób i ryby"),
    ("seed-mieso-morszczuk-filet", "Morszczuk filet bez skóry", None, None, 78.0, 17.0, 0.0, 0.8, 0.0, 150.0, "1 filet (150g)", "Mięso drób i ryby"),
    ("seed-mieso-tunczyk-w-wodzie", "Tuńczyk kawałki w sosie własnym", "Graal", "5903456001018", 100.0, 23.5, 0.0, 0.8, 0.0, 130.0, "1 puszka po odsączeniu (130g)", "Mięso drób i ryby"),
    ("seed-mieso-tunczyk-w-oliwie", "Tuńczyk w oliwie z oliwek", "Rio Mare", "8004030041018", 195.0, 22.0, 0.0, 12.0, 0.0, 130.0, "1 puszka po odsączeniu (130g)", "Mięso drób i ryby"),
    ("seed-mieso-makrela-wedzona", "Makrela wędzona tradycyjna", None, None, 240.0, 20.5, 0.0, 17.5, 0.0, 120.0, "1/2 ryby bez ości (120g)", "Mięso drób i ryby"),
    ("seed-mieso-sledz-w-oleju-lisner", "Filety śledziowe w oleju z cebulką", "Lisner", "5900508001019", 290.0, 11.0, 2.0, 26.5, 0.0, 100.0, "1 porcja (100g)", "Mięso drób i ryby"),
    ("seed-mieso-sledz-w-smietanie-lisner", "Filety śledziowe w śmietanie", "Lisner", "5900508001026", 210.0, 8.5, 7.5, 16.0, 0.0, 100.0, "1 porcja (100g)", "Mięso drób i ryby"),
    ("seed-mieso-krewetki-gotowane", "Krewetki gotowane obrane", None, None, 85.0, 18.0, 0.5, 1.0, 0.0, 100.0, "1 porcja (100g)", "Mięso drób i ryby"),
    ("seed-mieso-paluszki-rybne-frosta", "Złote paluszki rybne z fileta z mintaja", "Frosta", "5900645001018", 190.0, 13.0, 16.0, 8.0, 1.0, 90.0, "3 sztuki (90g)", "Mięso drób i ryby"),
    ("seed-mieso-konserwa-turystyczna", "Konserwa turystyczna wieprzowa", "Krakus", "5900783001089", 180.0, 13.0, 2.0, 13.0, 0.0, 100.0, "1/3 puszki (100g)", "Mięso drób i ryby"),

    # =========================================================================
    # 4. WARZYWA I GRZYBY (Vegetables, legumes, mushrooms)
    # =========================================================================
    ("seed-warz-pomidor-malinowy", "Pomidor malinowy świeży", None, None, 18.0, 0.9, 3.6, 0.2, 1.2, 180.0, "1 sztuka (180g)", "Warzywa i grzyby"),
    ("seed-warz-pomidor-zwykly", "Pomidor czerwony tradycyjny", None, None, 18.0, 0.9, 3.6, 0.2, 1.2, 150.0, "1 sztuka średnia (150g)", "Warzywa i grzyby"),
    ("seed-warz-pomidorki-koktajlowe", "Pomidorki koktajlowe cherry", None, None, 20.0, 1.0, 3.8, 0.2, 1.4, 100.0, "1 garść (100g)", "Warzywa i grzyby"),
    ("seed-warz-ogorek-szklarniowy", "Ogórek zielony szklarniowy długi", None, None, 14.0, 0.7, 2.6, 0.1, 0.6, 180.0, "1 sztuka (180g)", "Warzywa i grzyby"),
    ("seed-warz-ogorek-gruntowy", "Ogórek gruntowy", None, None, 14.0, 0.7, 2.6, 0.1, 0.6, 70.0, "1 sztuka (70g)", "Warzywa i grzyby"),
    ("seed-warz-ogorki-kiszone", "Ogórki kiszone tradycyjne", None, None, 12.0, 0.8, 1.8, 0.1, 1.0, 60.0, "1 sztuka (60g)", "Warzywa i grzyby"),
    ("seed-warz-ogorki-konserwowe", "Ogórki konserwowe korniszone", "Krakus", "5900783002017", 35.0, 0.6, 7.5, 0.2, 0.8, 60.0, "1 sztuka (60g)", "Warzywa i grzyby"),
    ("seed-warz-papryka-czerwona", "Papryka czerwona słodka", None, None, 31.0, 1.3, 6.0, 0.4, 2.0, 180.0, "1 sztuka (180g)", "Warzywa i grzyby"),
    ("seed-warz-papryka-zolta", "Papryka żółta słodka", None, None, 28.0, 1.1, 5.5, 0.3, 1.8, 180.0, "1 sztuka (180g)", "Warzywa i grzyby"),
    ("seed-warz-papryka-zielona", "Papryka zielona słodka", None, None, 22.0, 1.0, 4.5, 0.2, 1.7, 180.0, "1 sztuka (180g)", "Warzywa i grzyby"),
    ("seed-warz-ziemniaki-gotowane", "Ziemniaki gotowane w osolonej wodzie", None, None, 77.0, 2.0, 17.5, 0.1, 1.8, 200.0, "2 sztuki średnie (200g)", "Warzywa i grzyby"),
    ("seed-warz-ziemniaki-pieczone", "Ziemniaki pieczone z ziołami", None, None, 95.0, 2.2, 21.0, 1.0, 2.2, 200.0, "1 porcja (200g)", "Warzywa i grzyby"),
    ("seed-warz-bataty-slodkie-ziemniaki", "Bataty słodkie ziemniaki", None, None, 86.0, 1.6, 20.0, 0.1, 3.0, 200.0, "1 sztuka średnia (200g)", "Warzywa i grzyby"),
    ("seed-warz-cebula-biala", "Cebula biała", None, None, 40.0, 1.3, 8.5, 0.2, 1.8, 100.0, "1 sztuka średnia (100g)", "Warzywa i grzyby"),
    ("seed-warz-cebula-czerwona", "Cebula czerwona", None, None, 42.0, 1.4, 9.0, 0.2, 1.8, 100.0, "1 sztuka średnia (100g)", "Warzywa i grzyby"),
    ("seed-warz-szczypiorek-dymka", "Cebula dymka ze szczypiorkiem", None, None, 32.0, 1.8, 6.5, 0.2, 2.6, 30.0, "1 pęczek (30g)", "Warzywa i grzyby"),
    ("seed-warz-czosnek-swiezy", "Czosnek świeży ząbek", None, None, 149.0, 6.4, 33.0, 0.5, 2.1, 5.0, "1 ząbek (5g)", "Warzywa i grzyby"),
    ("seed-warz-marchew-swieza", "Marchew surowa", None, None, 41.0, 0.9, 9.6, 0.2, 2.8, 100.0, "1 sztuka średnia (100g)", "Warzywa i grzyby"),
    ("seed-warz-marchew-gotowana", "Marchew gotowana", None, None, 35.0, 0.8, 8.0, 0.2, 3.0, 100.0, "1 sztuka (100g)", "Warzywa i grzyby"),
    ("seed-warz-pietruszka-korzen", "Pietruszka korzeń", None, None, 45.0, 2.6, 8.8, 0.5, 4.3, 80.0, "1 sztuka (80g)", "Warzywa i grzyby"),
    ("seed-warz-seler-korzeniowy", "Seler korzeniowy", None, None, 30.0, 1.5, 6.0, 0.3, 3.5, 100.0, "1 plaster (100g)", "Warzywa i grzyby"),
    ("seed-warz-seler-naciowy", "Seler naciowy łodyga", None, None, 16.0, 0.7, 3.0, 0.2, 1.6, 40.0, "1 łodyga (40g)", "Warzywa i grzyby"),
    ("seed-warz-brokul-surowy", "Brokuł świeży różyczki", None, None, 34.0, 2.8, 6.6, 0.4, 2.6, 250.0, "1/2 główki (250g)", "Warzywa i grzyby"),
    ("seed-warz-brokul-gotowany", "Brokuł gotowany na parze", None, None, 35.0, 2.4, 7.0, 0.4, 3.3, 200.0, "1 porcja (200g)", "Warzywa i grzyby"),
    ("seed-warz-kalafior-surowy", "Kalafior świeży różyczki", None, None, 25.0, 1.9, 5.0, 0.3, 2.0, 250.0, "1/2 główki (250g)", "Warzywa i grzyby"),
    ("seed-warz-cukinia", "Cukinia ze skórką", None, None, 17.0, 1.2, 3.1, 0.3, 1.0, 250.0, "1 sztuka średnia (250g)", "Warzywa i grzyby"),
    ("seed-warz-baklazan", "Bakłażan oberżyna", None, None, 25.0, 1.0, 5.8, 0.2, 3.0, 250.0, "1 sztuka średnia (250g)", "Warzywa i grzyby"),
    ("seed-warz-szpinak-swiezy-baby", "Szpinak baby świeże liście", None, None, 23.0, 2.9, 3.6, 0.4, 2.2, 100.0, "1 duża garść (100g)", "Warzywa i grzyby"),
    ("seed-warz-szpinak-mrozony-hortex", "Szpinak liście mrożony", "Hortex", "5900334002016", 20.0, 2.5, 2.0, 0.4, 2.2, 150.0, "1 porcja (150g)", "Warzywa i grzyby"),
    ("seed-warz-salata-lodowa", "Sałata lodowa", None, None, 14.0, 0.9, 2.8, 0.1, 1.2, 100.0, "1 miska liści (100g)", "Warzywa i grzyby"),
    ("seed-warz-salata-maslowa", "Sałata masłowa", None, None, 15.0, 1.4, 2.8, 0.2, 1.5, 100.0, "1 miska liści (100g)", "Warzywa i grzyby"),
    ("seed-warz-roszponka", "Roszponka liście", None, None, 21.0, 2.0, 3.5, 0.4, 1.5, 50.0, "1 garść (50g)", "Warzywa i grzyby"),
    ("seed-warz-rukola", "Rukola liście", None, None, 25.0, 2.6, 3.7, 0.7, 1.6, 50.0, "1 garść (50g)", "Warzywa i grzyby"),
    ("seed-warz-kapusta-biala", "Kapusta biała szatkowana", None, None, 25.0, 1.3, 5.8, 0.1, 2.5, 150.0, "1 porcja (150g)", "Warzywa i grzyby"),
    ("seed-warz-kapusta-czerwona", "Kapusta czerwona", None, None, 31.0, 1.4, 7.4, 0.2, 2.1, 150.0, "1 porcja (150g)", "Warzywa i grzyby"),
    ("seed-warz-kapusta-kiszona", "Kapusta kiszona naturalna", None, None, 18.0, 1.1, 3.4, 0.2, 2.3, 150.0, "1 porcja (150g)", "Warzywa i grzyby"),
    ("seed-warz-kapusta-pekinska", "Kapusta pekińska", None, None, 16.0, 1.2, 3.2, 0.2, 1.5, 100.0, "1 miseczka (100g)", "Warzywa i grzyby"),
    ("seed-warz-rzodkiewka", "Rzodkiewka świeża", None, None, 16.0, 0.7, 3.4, 0.1, 1.6, 15.0, "1 sztuka (15g)", "Warzywa i grzyby"),
    ("seed-warz-burak-gotowany", "Burak ćwikłowy gotowany", None, None, 44.0, 1.7, 9.6, 0.2, 2.0, 150.0, "1 sztuka (150g)", "Warzywa i grzyby"),
    ("seed-warz-dynia-pizmowa", "Dynia piżmowa surowy miąższ", None, None, 26.0, 1.0, 6.5, 0.1, 0.5, 200.0, "1 porcja (200g)", "Warzywa i grzyby"),
    ("seed-warz-szparagi-zielone", "Szparagi zielone świeże", None, None, 20.0, 2.2, 3.9, 0.1, 2.1, 150.0, "1 wiązka (150g)", "Warzywa i grzyby"),
    ("seed-warz-por", "Por biała i zielona część", None, None, 29.0, 1.5, 5.7, 0.3, 1.8, 100.0, "1 sztuka średnia (100g)", "Warzywa i grzyby"),
    ("seed-warz-kukurydza-puszka", "Kukurydza złocista słodka konserwowa", "Bonduelle", "3083680001018", 80.0, 2.9, 14.5, 1.2, 2.5, 140.0, "1/2 puszki odsączonej (140g)", "Warzywa i grzyby"),
    ("seed-warz-groszek-puszka", "Groszek tradycyjny konserwowy", "Bonduelle", "3083680001025", 72.0, 5.2, 10.5, 0.6, 4.5, 140.0, "1/2 puszki odsączonej (140g)", "Warzywa i grzyby"),
    ("seed-warz-fasola-czerwona-puszka", "Fasola czerwona Kidney konserwowa", "Bonduelle", "3083680001032", 95.0, 7.5, 14.0, 0.6, 6.0, 120.0, "1/2 puszki odsączonej (120g)", "Warzywa i grzyby"),
    ("seed-warz-fasola-biala-puszka", "Fasola biała konserwowa", "Bonduelle", "3083680001049", 90.0, 7.0, 13.5, 0.5, 6.2, 120.0, "1/2 puszki odsączonej (120g)", "Warzywa i grzyby"),
    ("seed-warz-ciecierzyca-puszka", "Ciecierzyca konserwowa w zalewie", "Bonduelle", "3083680001056", 120.0, 7.0, 17.0, 2.2, 5.5, 120.0, "1/2 puszki odsączonej (120g)", "Warzywa i grzyby"),
    ("seed-warz-soczewica-czerwona-sucha", "Soczewica czerwona nasiona suche", "Kupiec", "5906747160197", 341.0, 25.0, 52.0, 1.5, 11.0, 50.0, "1 porcja (50g)", "Warzywa i grzyby"),
    ("seed-warz-soczewica-zielona-sucha", "Soczewica zielona nasiona suche", "Melvit", "5907474001054", 335.0, 24.5, 51.0, 1.2, 12.0, 50.0, "1 porcja (50g)", "Warzywa i grzyby"),
    ("seed-warz-pomidory-krojone-mutti", "Pomidory krojone Polpa w puszce", "Mutti", "8005110001018", 24.0, 1.2, 3.9, 0.2, 1.0, 200.0, "1/2 puszki (200g)", "Warzywa i grzyby"),
    ("seed-warz-passata-pomidorowa-mutti", "Passata przecier pomidorowy", "Mutti", "8005110001025", 32.0, 1.5, 5.5, 0.2, 1.2, 250.0, "1/2 butelki (250g)", "Warzywa i grzyby"),
    ("seed-warz-koncentrat-pomidorowy-pudliszki", "Koncentrat pomidorowy 30%", "Pudliszki", "5900593000021", 92.0, 5.6, 16.5, 0.5, 2.8, 25.0, "1 czubata łyżka (25g)", "Warzywa i grzyby"),
    ("seed-warz-pieczarki-biale", "Pieczarki białe surowe", None, None, 22.0, 3.1, 3.3, 0.3, 1.5, 100.0, "4-5 sztuk (100g)", "Warzywa i grzyby"),
    ("seed-warz-pieczarki-podsmazane", "Pieczarki podsmażane na oliwie", None, None, 68.0, 3.2, 3.5, 4.5, 1.6, 100.0, "1 porcja (100g)", "Warzywa i grzyby"),
    ("seed-warz-boczniaki-swieze", "Boczniaki świeże", None, None, 33.0, 3.3, 4.0, 0.4, 2.3, 150.0, "1 porcja (150g)", "Warzywa i grzyby"),

    # =========================================================================
    # 5. OWOCE (Fruits, berries, dried fruits)
    # =========================================================================
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
    ("seed-owoc-papaja", "Papaja świeża dojrzała", None, None, 43.0, 0.5, 10.8, 0.3, 1.7, 150.0, "1 porcja (150g)", "Owoce"),
    ("seed-owoc-granat-pestki", "Granat owoce pestki", None, None, 83.0, 1.7, 18.7, 1.2, 4.0, 100.0, "1/2 owocu pestki (100g)", "Owoce"),
    ("seed-owoc-awokado-hass", "Awokado Hass miąższ", None, None, 160.0, 2.0, 8.5, 14.7, 6.7, 140.0, "1 sztuka miąższ (140g)", "Owoce"),
    ("seed-owoc-morele-swieze", "Morele świeże", None, None, 48.0, 1.4, 11.1, 0.4, 2.0, 45.0, "1 sztuka (45g)", "Owoce"),
    ("seed-owoc-figi-swieze", "Figi świeże", None, None, 74.0, 0.8, 19.2, 0.3, 2.9, 50.0, "1 sztuka (50g)", "Owoce"),
    ("seed-owoc-czarna-porzeczka", "Czarna porzeczka świeża", None, None, 63.0, 1.4, 15.4, 0.4, 6.8, 100.0, "1 miseczka (100g)", "Owoce"),
    ("seed-owoc-czerwona-porzeczka", "Czerwona porzeczka świeża", None, None, 56.0, 1.4, 13.8, 0.2, 4.3, 100.0, "1 miseczka (100g)", "Owoce"),
    ("seed-owoc-agrest", "Agrest świeży", None, None, 44.0, 0.9, 10.2, 0.6, 4.3, 100.0, "1 miseczka (100g)", "Owoce"),
    ("seed-owoc-daktyle-suszone", "Daktyle suszone bez pestek", "Kresto", "5900354002015", 282.0, 2.5, 75.0, 0.4, 8.0, 30.0, "3-4 sztuki (30g)", "Owoce"),
    ("seed-owoc-rodzynki-sultanskie", "Rodzynki sułtańskie", "Bakalland", "5900749001017", 299.0, 3.1, 79.2, 0.5, 3.7, 30.0, "1 garść (30g)", "Owoce"),
    ("seed-owoc-zurawina-suszona", "Żurawina suszona słodzona", "Bakalland", "5900749001024", 320.0, 0.5, 80.0, 1.0, 5.0, 30.0, "1 garść (30g)", "Owoce"),
    ("seed-owoc-morele-suszone", "Morele suszone całe", "Bakalland", "5900749001031", 241.0, 3.4, 62.6, 0.5, 7.3, 40.0, "4 sztuki (40g)", "Owoce"),
    ("seed-owoc-sliwki-suszone", "Śliwki suszone kalifornijskie", "Bakalland", "5900749001048", 240.0, 2.2, 63.9, 0.4, 7.1, 40.0, "4 sztuki (40g)", "Owoce"),
    ("seed-owoc-figi-suszone", "Figi suszone", "Bakalland", "5900749001055", 249.0, 3.3, 63.9, 0.9, 9.8, 40.0, "2 sztuki (40g)", "Owoce"),

    # =========================================================================
    # 6. TŁUSZCZE NASIONA I ORZECHY (Oils, butter, nuts, seeds, spreads)
    # =========================================================================
    ("seed-tluszcz-oliwa-monini", "Oliwa z oliwek najwyższej jakości Extra Virgin", "Monini", "8005510001019", 824.0, 0.0, 0.0, 91.6, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-rzepakowy-kujawski", "Olej rzepakowy z pierwszego tłoczenia", "Kujawski", "5900424001018", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-slonecznikowy", "Olej słonecznikowy czysty", "Kruszwica", "5900424001025", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-kokosowy-kfd", "Olej kokosowy nierafinowany extra virgin", "KFD", "5902444001019", 862.0, 0.0, 0.0, 100.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-kokosowy-rafinowany", "Olej kokosowy rafinowany bezzapachowy", "KFD", "5902444001026", 862.0, 0.0, 0.0, 100.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-lniany-kujawski", "Olej lniany tłoczony na zimno", "Kujawski", "5900424001032", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-z-pestek-dyni", "Olej z prażonych pestek dyni", "Oleofarm", "5904960001017", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-olej-sezamowy", "Olej sezamowy ciemny prażony", "House of Asia", "5902751001016", 828.0, 0.0, 0.0, 92.0, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-ekstra-laciate", "Masło ekstra 82% tłuszczu", "Łaciate", "5900820005014", 735.0, 0.7, 0.7, 82.0, 0.0, 10.0, "1 porcja na kromkę (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-ekstra-mlekovita", "Masło ekstra polskie 82%", "Mlekovita", "5900512003016", 735.0, 0.7, 0.7, 82.0, 0.0, 10.0, "1 porcja na kromkę (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-klarowane-ghee", "Masło klarowane Ghee 99.8%", "Mlekovita", "5900512003023", 898.0, 0.1, 0.0, 99.8, 0.0, 10.0, "1 łyżka (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-margaryna-rama", "Margaryna do smarowania pieczywa Classic", "Rama", "8719200001016", 540.0, 0.0, 0.0, 60.0, 0.0, 10.0, "1 porcja na kromkę (10g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-smalec-wieprzowy", "Smalec wieprzowy tradycyjny", None, None, 898.0, 0.0, 0.0, 99.8, 0.0, 15.0, "1 łyżka (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-orzechowe-kfd-smooth", "Masło orzechowe 100% arachidowe smooth", "KFD", "5902444001033", 596.0, 26.0, 14.0, 49.0, 7.5, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-orzechowe-kfd-crunchy", "Masło orzechowe 100% arachidowe crunchy", "KFD", "5902444001040", 596.0, 26.0, 14.0, 49.0, 7.5, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-migdalowe-kfd", "Masło migdałowe 100% z prażonych migdałów", "KFD", "5902444001057", 620.0, 21.0, 10.0, 55.0, 10.5, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-maslo-nerkowce-kfd", "Masło z orzechów nerkowca 100%", "KFD", "5902444001064", 580.0, 18.0, 26.0, 46.0, 4.0, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzechy-wloskie", "Orzechy włoskie łuskane połówki", "Bakalland", "5900749001062", 654.0, 15.2, 13.7, 65.2, 6.7, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzechy-laskowe", "Orzechy laskowe łuskane", "Bakalland", "5900749001079", 628.0, 15.0, 16.7, 60.8, 9.7, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-migdaly", "Migdały całe łuskane", "Bakalland", "5900749001086", 579.0, 21.2, 21.6, 49.9, 12.5, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-platki-migdalowe", "Płatki migdałowe", "Kresto", "5900354002022", 585.0, 21.0, 21.0, 50.0, 12.0, 15.0, "2 łyżki (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzechy-nerkowca", "Orzechy nerkowca nerkowce", "Bakalland", "5900749001093", 553.0, 18.2, 30.2, 43.8, 3.3, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzeszki-ziemne-felix", "Orzeszki ziemne prażone bez soli", "Felix", "5900030001018", 585.0, 25.0, 16.0, 49.0, 8.0, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzechy-brazylijskie", "Orzechy brazylijskie", "Bakalland", "5900749001109", 659.0, 14.3, 12.3, 67.1, 7.5, 20.0, "4 sztuki (20g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzechy-pekan", "Orzechy pekan", "Bakalland", "5900749001116", 691.0, 9.2, 13.9, 72.0, 9.6, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-orzechy-makadamia", "Orzechy makadamia", "Bakalland", "5900749001123", 718.0, 7.9, 13.8, 75.8, 8.6, 30.0, "1 garść (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-pistacje-solone-felix", "Pistacje prażone solone w łupinach", "Felix", "5900030001025", 560.0, 20.0, 28.0, 45.0, 10.0, 30.0, "1 porcja bez łupin (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-pestki-dyni", "Pestki dyni łuskane ciemnozielone", "Kresto", "5900354002039", 559.0, 30.2, 10.7, 49.0, 6.0, 20.0, "2 łyżki (20g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-nasiona-slonecznika", "Nasiona słonecznika łuskane", "Kresto", "5900354002046", 584.0, 20.8, 20.0, 51.5, 8.6, 20.0, "2 łyżki (20g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-chia-kresto", "Nasiona chia szałwia hiszpańska", "Kresto", "5900354002053", 486.0, 16.5, 42.1, 30.7, 34.4, 15.0, "1 łyżka (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-siemie-lniane", "Siemię lniane całe ziarna", "Kresto", "5900354002060", 534.0, 18.3, 28.9, 42.2, 27.3, 15.0, "1 łyżka (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-siemie-mielone", "Siemię lniane mielone odtłuszczone", "Kresto", "5900354002077", 340.0, 32.0, 35.0, 9.0, 30.0, 15.0, "1 łyżka (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-sezam-bialy", "Sezam łuskany biały ziarno", "Kresto", "5900354002084", 573.0, 17.7, 23.4, 49.7, 11.8, 15.0, "1 łyżka (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-tahini-jasmeen", "Pasta sezamowa Tahini 100%", "Jasmeen", "5902751001023", 630.0, 24.0, 9.0, 56.0, 8.0, 20.0, "1 łyżka (20g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-wiorki-kokosowe", "Wiórki kokosowe", "Bakalland", "5900749001130", 660.0, 7.4, 23.6, 64.5, 14.0, 15.0, "2 łyżki (15g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-mleczko-kokosowe-realthai", "Mleczko kokosowe 80% ekstraktu", "Real Thai", "8852646001018", 185.0, 1.8, 2.5, 19.0, 0.0, 100.0, "1/4 puszki (100g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-mleczko-kokosowe-light", "Mleczko kokosowe light", "Real Thai", "8852646001025", 68.0, 0.7, 1.8, 6.5, 0.0, 100.0, "1/4 puszki (100g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-majonez-winiary", "Majonez dekoracyjny tradycyjny", "Winiary", "5900455000018", 704.0, 1.3, 2.6, 76.3, 0.0, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-majonez-kielecki", "Majonez Kielecki oryginalny", "Społem Kielce", "5900122001012", 631.0, 1.8, 2.5, 68.0, 0.0, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-majonez-lekki-winiary", "Majonez lekki o obniżonej zawartości tłuszczu", "Winiary", "5900455000025", 320.0, 0.8, 8.5, 32.0, 0.0, 25.0, "1 czubata łyżka (25g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-sos-czosnkowy-roleski", "Sos czosnkowy kremowy", "Roleski", "5900593001011", 350.0, 1.2, 8.0, 35.0, 0.0, 30.0, "2 łyżki (30g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-pesto-zielone-barilla", "Sos Pesto alla Genovese zielone", "Barilla", "8076809001015", 482.0, 5.0, 9.8, 46.0, 3.0, 45.0, "1 porcja do makaronu (45g)", "Tłuszcze nasiona i orzechy"),
    ("seed-tluszcz-pesto-czerwone-barilla", "Sos Pesto Rosso suszone pomidory", "Barilla", "8076809001022", 430.0, 4.0, 13.0, 40.0, 3.5, 45.0, "1 porcja do makaronu (45g)", "Tłuszcze nasiona i orzechy"),

    # =========================================================================
    # 7. NAPOJE (Waters, coffees, teas, sodas, juices, beers, wines)
    # =========================================================================
    ("seed-napoj-woda-niegazowana", "Woda mineralna niegazowana", "Żywiec Zdrój", "5900245001017", 0.0, 0.0, 0.0, 0.0, 0.0, 500.0, "1 butelka (500ml)", "Napoje"),
    ("seed-napoj-woda-gazowana-cisowianka", "Woda mineralna gazowana", "Cisowianka", "5900985001018", 0.0, 0.0, 0.0, 0.0, 0.0, 500.0, "1 butelka (500ml)", "Napoje"),
    ("seed-napoj-muszynianka", "Woda wysokozmineralizowana Muszynianka", "Muszynianka", "5900985001025", 0.0, 0.0, 0.0, 0.0, 0.0, 500.0, "1 butelka (500ml)", "Napoje"),
    ("seed-napoj-kawa-czarna", "Kawa czarna parzona bez cukru", None, None, 2.0, 0.1, 0.3, 0.0, 0.0, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-espresso", "Kawa Espresso bez cukru", None, None, 2.0, 0.1, 0.4, 0.1, 0.0, 30.0, "1 filiżanka (30ml)", "Napoje"),
    ("seed-napoj-kawa-z-mlekiem", "Kawa z mlekiem 2% (200ml kawy + 50ml mleka)", None, None, 26.0, 1.7, 2.5, 1.0, 0.0, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-cappuccino", "Kawa Cappuccino z ekspresu bez cukru", None, None, 45.0, 2.8, 4.0, 1.8, 0.0, 200.0, "1 filiżanka (200ml)", "Napoje"),
    ("seed-napoj-caffe-latte", "Kawa Caffe Latte z mlekiem 2%", None, None, 48.0, 3.2, 4.6, 1.9, 0.0, 300.0, "1 duża szklanka (300ml)", "Napoje"),
    ("seed-napoj-kawa-rozpuszczalna", "Kawa rozpuszczalna proszek", "Nescafé", "7613035001018", 120.0, 7.0, 23.0, 0.2, 0.0, 4.0, "1 czubata łyżeczka (4g)", "Napoje"),
    ("seed-napoj-herbata-czarna", "Herbata czarna napar bez cukru", "Lipton", "8722700001015", 1.0, 0.0, 0.2, 0.0, 0.0, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-herbata-zielona", "Herbata zielona napar bez cukru", "Tetley", "5900570001016", 1.0, 0.0, 0.2, 0.0, 0.0, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-herbata-mietowa", "Napar z mięty pieprzowej bez cukru", "Herbapol", "5900985002015", 1.0, 0.0, 0.2, 0.0, 0.0, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-herbata-owocowa", "Herbata owocowa malinowa bez cukru", "Herbapol", "5900985002022", 2.0, 0.0, 0.4, 0.0, 0.0, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-coca-cola", "Coca-Cola Original", "Coca-Cola", "5449000000996", 42.0, 0.0, 10.6, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-coca-cola-zero", "Coca-Cola Zero Cukru", "Coca-Cola", "5449000131805", 0.3, 0.0, 0.0, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-pepsi-max", "Pepsi Max bez cukru", "Pepsi", "5900497001018", 0.5, 0.0, 0.0, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-pepsi-original", "Pepsi Original", "Pepsi", "5900497001025", 43.0, 0.0, 11.0, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-sprite", "Sprite gazowany", "Sprite", "5449000010018", 40.0, 0.0, 10.0, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-fanta-orange", "Fanta Orange pomarańczowa", "Fanta", "5449000020017", 41.0, 0.0, 10.1, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-7up", "7UP cytryna limonka", "7UP", "5900497001032", 41.0, 0.0, 10.0, 0.0, 0.0, 330.0, "1 puszka (330ml)", "Napoje"),
    ("seed-napoj-monster-energy-org", "Monster Energy oryginalny", "Monster Energy", "5060166691018", 47.0, 0.0, 12.0, 0.0, 0.0, 500.0, "1 puszka (500ml)", "Napoje"),
    ("seed-napoj-monster-ultra-white", "Monster Energy Ultra White bez cukru", "Monster Energy", "5060166691025", 2.5, 0.0, 0.9, 0.0, 0.0, 500.0, "1 puszka (500ml)", "Napoje"),
    ("seed-napoj-monster-mango-loco", "Monster Energy Mango Loco", "Monster Energy", "5060166691032", 48.0, 0.0, 12.2, 0.0, 0.0, 500.0, "1 puszka (500ml)", "Napoje"),
    ("seed-napoj-red-bull", "Red Bull napój energetyzujący", "Red Bull", "90162602", 45.0, 0.0, 11.0, 0.0, 0.0, 250.0, "1 puszka (250ml)", "Napoje"),
    ("seed-napoj-red-bull-sugarfree", "Red Bull Sugarfree bez cukru", "Red Bull", "90162800", 3.0, 0.0, 0.0, 0.0, 0.0, 250.0, "1 puszka (250ml)", "Napoje"),
    ("seed-napoj-sok-jablkowy-tymbark", "Sok jabłkowy 100% tłoczony", "Tymbark", "5900334004010", 43.0, 0.1, 10.5, 0.1, 0.1, 250.0, "1 szklanka (250ml)", "Napoje"),
    ("seed-napoj-sok-pomaranczowy-tymbark", "Sok pomarańczowy 100%", "Tymbark", "5900334004027", 43.0, 0.7, 9.8, 0.1, 0.2, 250.0, "1 szklanka (250ml)", "Napoje"),
    ("seed-napoj-sok-multiwitamina-tymbark", "Sok multiwitamina 100%", "Tymbark", "5900334004034", 45.0, 0.5, 10.5, 0.1, 0.3, 250.0, "1 szklanka (250ml)", "Napoje"),
    ("seed-napoj-sok-pomidorowy-dawtona", "Sok pomidorowy 100% z solą morską", "Dawtona", "5900593003015", 17.0, 0.8, 3.0, 0.1, 0.8, 250.0, "1 szklanka (250ml)", "Napoje"),
    ("seed-napoj-tymbark-jablko-mieta", "Napój jabłko-mięta szklana butelka", "Tymbark", "5900334004041", 38.0, 0.1, 9.3, 0.0, 0.0, 250.0, "1 butelka (250ml)", "Napoje"),
    ("seed-napoj-tymbark-jablko-wisnia", "Napój jabłko-wiśnia szklana butelka", "Tymbark", "5900334004058", 38.0, 0.1, 9.3, 0.0, 0.0, 250.0, "1 butelka (250ml)", "Napoje"),
    ("seed-napoj-kubus-marchew-banan", "Sok przecierowy marchew-banan-jabłko", "Kubuś", "5900334004065", 48.0, 0.4, 11.0, 0.1, 1.2, 300.0, "1 butelka (300ml)", "Napoje"),
    ("seed-napoj-piwo-zywiec-jasne", "Piwo jasne pełne 5.6% alk.", "Żywiec", "5900245002014", 42.0, 0.5, 3.5, 0.0, 0.0, 500.0, "1 puszka (500ml)", "Napoje"),
    ("seed-napoj-piwo-zywiec-00", "Piwo bezalkoholowe 0.0%", "Żywiec", "5900245002021", 21.0, 0.3, 4.8, 0.0, 0.0, 500.0, "1 butelka (500ml)", "Napoje"),
    ("seed-napoj-piwo-warka-radler-00", "Piwo bezalkoholowe Warka Radler Cytryna 0.0%", "Warka", "5900245002038", 32.0, 0.1, 7.8, 0.0, 0.0, 500.0, "1 puszka (500ml)", "Napoje"),
    ("seed-napoj-wino-czerwone-wytrawne", "Wino czerwone wytrawne 12%", None, None, 83.0, 0.1, 2.5, 0.0, 0.0, 150.0, "1 kieliszek (150ml)", "Napoje"),
    ("seed-napoj-wino-biale-wytrawne", "Wino białe wytrawne 11%", None, None, 79.0, 0.1, 2.0, 0.0, 0.0, 150.0, "1 kieliszek (150ml)", "Napoje"),
    ("seed-napoj-prosecco", "Wino musujące Prosecco wytrawne 11%", None, None, 75.0, 0.1, 1.8, 0.0, 0.0, 150.0, "1 kieliszek (150ml)", "Napoje"),
    ("seed-napoj-wodka-czysta-40", "Wódka czysta 40% obj.", None, None, 222.0, 0.0, 0.0, 0.0, 0.0, 50.0, "1 kieliszek (50ml)", "Napoje"),
    ("seed-napoj-whisky-40", "Whisky szkocka 40% obj.", None, None, 222.0, 0.0, 0.1, 0.0, 0.0, 50.0, "1 porcja (50ml)", "Napoje"),
    ("seed-napoj-kompot-truskawkowy", "Kompot z truskawek lekko słodzony", None, None, 28.0, 0.2, 6.8, 0.1, 0.4, 250.0, "1 szklanka (250ml)", "Napoje"),
    ("seed-napoj-barszcz-czerwony-krakus", "Barszcz czerwony czysty koncentrat", "Krakus", "5900783003014", 32.0, 0.7, 7.0, 0.1, 0.2, 250.0, "1 kubek (250ml)", "Napoje"),
    ("seed-napoj-zurek-butelka-krakus", "Żurek tradycyjny zakwas butelka", "Krakus", "5900783003021", 45.0, 0.8, 9.5, 0.5, 0.2, 250.0, "1 talerz zupy (250ml)", "Napoje"),

    # =========================================================================
    # 8. FIT I ODŻYWKI (Proteins, bars, supplements, sugar substitutes)
    # =========================================================================
    ("seed-fit-wpc-80-naturalne-kfd", "KFD Premium WPC 80 białko serwatkowe naturalne", "KFD", "5902444000012", 400.0, 80.0, 6.0, 6.5, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-wpc-80-wanilia-kfd", "KFD Premium WPC 80 białko waniliowe", "KFD", "5902444000029", 395.0, 78.0, 7.5, 6.0, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-wpc-80-czekolada-kfd", "KFD Premium WPC 80 białko czekoladowe", "KFD", "5902444000036", 390.0, 76.0, 8.0, 6.5, 1.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-wpc-80-slony-karmel-kfd", "KFD Premium WPC 80 białko słony karmel", "KFD", "5902444000043", 392.0, 77.0, 7.5, 6.0, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-wpc-80-truskawka-kfd", "KFD Premium WPC 80 białko truskawkowe", "KFD", "5902444000050", 392.0, 77.0, 7.5, 6.0, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-wpi-90-izolat-kfd", "KFD Premium WPI 90 izolat białka serwatkowego", "KFD", "5902444000067", 365.0, 88.0, 1.5, 1.0, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-wpi-90-wanilia-kfd", "KFD Premium WPI 90 izolat waniliowy", "KFD", "5902444000074", 365.0, 86.0, 2.0, 1.0, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-kazeina-micelarna-kfd", "KFD Premium Micellar Casein kazeina micelarna", "KFD", "5902444000081", 360.0, 77.0, 6.0, 1.5, 0.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-bialko-weganskie-sfd", "SFD Vegan Protein białko roślinne", "SFD", "5902837001015", 375.0, 70.0, 9.0, 5.0, 4.0, 30.0, "1 miarka (30g)", "Fit i odżywki"),
    ("seed-fit-kreatyna-mono-kfd", "KFD Premium Creatine monohydrat kreatyny", "KFD", "5902444000098", 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, "1 miarka (5g)", "Fit i odżywki"),
    ("seed-fit-kreatyna-jablczan-kfd", "KFD Premium TCM jabłczan kreatyny", "KFD", "5902444000104", 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, "1 miarka (5g)", "Fit i odżywki"),
    ("seed-fit-pre-workout-kfd", "KFD Premium Pre-Workout przedtreningówka", "KFD", "5902444000111", 20.0, 0.0, 4.0, 0.0, 0.0, 10.0, "1 miarka (10g)", "Fit i odżywki"),
    ("seed-fit-bcaa-kfd", "KFD Premium BCAA 2:1:1 proszek aminokwasy", "KFD", "5902444000128", 15.0, 3.5, 0.2, 0.0, 0.0, 10.0, "1 porcja (10g)", "Fit i odżywki"),
    ("seed-fit-kolagen-kfd", "KFD Premium Collagen Plus kolagen w proszku", "KFD", "5902444000135", 320.0, 78.0, 1.0, 0.1, 0.0, 20.0, "1 miarka (20g)", "Fit i odżywki"),
    ("seed-fit-elektrolity-kfd", "KFD Elektrolity w proszku", "KFD", "5902444000142", 15.0, 0.0, 3.5, 0.0, 0.0, 8.0, "1 porcja (8g)", "Fit i odżywki"),
    ("seed-fit-baton-barebells-salty-peanut", "Baton proteinowy Barebells Salty Peanut", "Barebells", "7340001800103", 364.0, 36.0, 29.0, 15.0, 6.5, 55.0, "1 baton (55g)", "Fit i odżywki"),
    ("seed-fit-baton-barebells-caramel-cashew", "Baton proteinowy Barebells Caramel Cashew", "Barebells", "7340001800110", 367.0, 36.0, 27.0, 15.0, 7.0, 55.0, "1 baton (55g)", "Fit i odżywki"),
    ("seed-fit-baton-barebells-cookies-cream", "Baton proteinowy Barebells Cookies & Cream", "Barebells", "7340001800127", 358.0, 36.0, 27.0, 15.0, 7.5, 55.0, "1 baton (55g)", "Fit i odżywki"),
    ("seed-fit-baton-barebells-white-almond", "Baton proteinowy Barebells White Chocolate Almond", "Barebells", "7340001800134", 369.0, 36.0, 28.0, 16.0, 6.5, 55.0, "1 baton (55g)", "Fit i odżywki"),
    ("seed-fit-baton-fretka-kfd", "Baton wysokobiałkowy Fretka Karmel", "KFD", "5902444000159", 370.0, 30.0, 32.0, 15.0, 8.0, 50.0, "1 baton (50g)", "Fit i odżywki"),
    ("seed-fit-baton-go-on-protein-33", "Baton proteinowy Go On Protein 33% z wanilią", "Sante", "5900617002015", 388.0, 33.0, 30.0, 16.0, 9.0, 50.0, "1 baton (50g)", "Fit i odżywki"),
    ("seed-fit-pudding-ehrmann-czekolada", "Pudding proteinowy czekoladowy High Protein", "Ehrmann", "4002933000010", 76.0, 10.0, 5.5, 1.5, 0.5, 200.0, "1 kubek (200g)", "Fit i odżywki"),
    ("seed-fit-pudding-ehrmann-wanilia", "Pudding proteinowy waniliowy High Protein", "Ehrmann", "4002933000027", 76.0, 10.0, 5.5, 1.5, 0.1, 200.0, "1 kubek (200g)", "Fit i odżywki"),
    ("seed-fit-pudding-ehrmann-karmel", "Pudding proteinowy karmelowy High Protein", "Ehrmann", "4002933000034", 76.0, 10.0, 5.5, 1.5, 0.1, 200.0, "1 kubek (200g)", "Fit i odżywki"),
    ("seed-fit-pudding-ehrmann-orzech", "Pudding proteinowy orzech laskowy High Protein", "Ehrmann", "4002933000041", 79.0, 10.0, 5.5, 1.8, 0.5, 200.0, "1 kubek (200g)", "Fit i odżywki"),
    ("seed-fit-kaszka-ehrmann-protein", "Kaszka manna proteinowa High Protein", "Ehrmann", "4002933000058", 82.0, 10.0, 7.5, 1.2, 0.5, 200.0, "1 kubek (200g)", "Fit i odżywki"),
    ("seed-fit-mus-ehrmann-mousse", "Mus proteinowy czekoladowy High Protein Mousse", "Ehrmann", "4002933000065", 76.0, 10.0, 4.0, 2.0, 0.5, 200.0, "1 kubek (200g)", "Fit i odżywki"),
    ("seed-fit-napoj-ehrmann-czekolada", "Napój proteinowy czekoladowy Drink", "Ehrmann", "4002933000072", 65.0, 10.0, 5.0, 0.3, 0.5, 250.0, "1 butelka (250ml)", "Fit i odżywki"),
    ("seed-fit-napoj-ehrmann-wanilia", "Napój proteinowy waniliowy Drink", "Ehrmann", "4002933000089", 62.0, 10.0, 4.8, 0.2, 0.1, 250.0, "1 butelka (250ml)", "Fit i odżywki"),
    ("seed-fit-milchreis-protein-muller", "Deser ryżowy Milchreis High Protein wanilia", "Müller", "4025500001018", 85.0, 7.0, 11.5, 1.1, 0.2, 180.0, "1 kubek (180g)", "Fit i odżywki"),
    ("seed-fit-maslo-orzechowe-proszek-kfd", "KFD Pure Peanut Powder masło w proszku", "KFD", "5902444000166", 450.0, 50.0, 20.0, 15.0, 12.0, 15.0, "1 łyżka (15g)", "Fit i odżywki"),
    ("seed-fit-erytrytol-kfd", "Erytrytol słodzik stołowy 100%", "KFD", "5902444000173", 0.0, 0.0, 100.0, 0.0, 0.0, 10.0, "2 łyżeczki (10g)", "Fit i odżywki"),
    ("seed-fit-ksylitol-cukier-brzozowy", "Ksylitol fiński cukier brzozowy", "Danisco", "5901234001015", 240.0, 0.0, 100.0, 0.0, 0.0, 10.0, "2 łyżeczki (10g)", "Fit i odżywki"),
    ("seed-fit-sos-zero-czekolada-kfd", "KFD Sos Zero kalorii Czekolada", "KFD", "5902444000180", 12.0, 0.5, 2.0, 0.2, 1.5, 15.0, "1 porcja (15g)", "Fit i odżywki"),
    ("seed-fit-sos-zero-karmel-kfd", "KFD Sos Zero kalorii Słony Karmel", "KFD", "5902444000197", 10.0, 0.2, 1.8, 0.1, 1.0, 15.0, "1 porcja (15g)", "Fit i odżywki"),
    ("seed-fit-dzem-100-truskawka-lowicz", "Dżem 100% z owoców truskawka", "Łowicz", "5900334005017", 140.0, 0.6, 34.0, 0.2, 1.8, 25.0, "1 czubata łyżka (25g)", "Fit i odżywki"),
    ("seed-fit-fruzelina-wisniowa-bez-cukru", "Frużelina wiśniowa bez cukru Frulove", "AllNutrition", "5902837001022", 55.0, 0.8, 14.0, 0.2, 2.0, 30.0, "1 czubata łyżka (30g)", "Fit i odżywki"),
    ("seed-fit-olej-spray-kfd", "KFD Cooking Spray 100% olej rzepakowy w sprayu", "KFD", "5902444000203", 828.0, 0.0, 0.0, 92.0, 0.0, 1.0, "1 psiknięcie (1g)", "Fit i odżywki"),
    ("seed-fit-platki-drozdzowe", "Płatki drożdżowe nieaktywne", "Targroch", "5902213001016", 340.0, 45.0, 35.0, 4.0, 20.0, 10.0, "1 łyżka (10g)", "Fit i odżywki"),
    ("seed-fit-izotonik-iso-plus-olimp", "Olimp Iso Plus proszek do napoju izotonicznego", "Olimp", "5901330001019", 350.0, 0.0, 87.0, 0.0, 0.0, 17.5, "1 porcja na bidon (17.5g)", "Fit i odżywki"),

    # =========================================================================
    # 9. SŁODYCZE I PRZEKĄSKI (Chocolates, bars, biscuits, chips, snacks)
    # =========================================================================
    ("seed-slod-czekolada-mleczna-wedel", "Czekolada mleczna klasyczna", "E.Wedel", "5901588015568", 535.0, 6.8, 56.5, 31.0, 2.5, 25.0, "1 rządek (25g)", "Słodycze i przekąski"),
    ("seed-slod-czekolada-gorzka-wedel", "Czekolada gorzka 64%", "E.Wedel", "5901588015575", 510.0, 6.2, 49.0, 30.5, 9.0, 25.0, "1 rządek (25g)", "Słodycze i przekąski"),
    ("seed-slod-czekolada-gorzka-lindt-85", "Czekolada gorzka Excellence 85% Cacao", "Lindt", "3046920028004", 584.0, 11.0, 19.0, 51.0, 13.0, 20.0, "2 kostki (20g)", "Słodycze i przekąski"),
    ("seed-slod-czekolada-biala-wedel", "Czekolada biała", "E.Wedel", "5901588015582", 545.0, 6.5, 57.0, 32.0, 0.0, 25.0, "1 rządek (25g)", "Słodycze i przekąski"),
    ("seed-slod-czekolada-milka-mleczna", "Czekolada mleczna Alpine Milk", "Milka", "7622210001018", 530.0, 6.3, 58.5, 29.5, 1.8, 25.0, "1 rządek (25g)", "Słodycze i przekąski"),
    ("seed-slod-czekolada-milka-orzechy", "Czekolada mleczna z całymi orzechami laskowymi", "Milka", "7622210001025", 555.0, 8.1, 51.5, 35.0, 3.2, 25.0, "1 rządek (25g)", "Słodycze i przekąski"),
    ("seed-slod-czekolada-milka-oreo", "Czekolada mleczna z kawałkami ciastek Oreo", "Milka", "7622210001032", 555.0, 5.3, 56.0, 34.0, 1.4, 25.0, "1 rządek (25g)", "Słodycze i przekąski"),
    ("seed-slod-ptasie-mleczko-wanilia-wedel", "Ptasie Mleczko waniliowe w czekoladzie deserowej", "E.Wedel", "5901588015551", 440.0, 3.5, 59.0, 21.0, 2.0, 36.0, "3 kostki (36g)", "Słodycze i przekąski"),
    ("seed-slod-ptasie-mleczko-czekolada", "Ptasie Mleczko czekoladowe", "E.Wedel", "5901588015599", 445.0, 4.0, 57.0, 22.0, 2.5, 36.0, "3 kostki (36g)", "Słodycze i przekąski"),
    ("seed-slod-barylki-z-alkoholem-wedel", "Baryłki z alkoholem czekoladki nadziewane", "E.Wedel", "5901588015605", 435.0, 3.2, 62.0, 16.5, 2.0, 40.0, "2 sztuki (40g)", "Słodycze i przekąski"),
    ("seed-slod-torcik-wedlowski", "Torcik Wedlowski wafel z kremem orzechowym", "E.Wedel", "5901588015612", 535.0, 8.5, 54.0, 31.0, 3.0, 50.0, "1 trójkąt (50g)", "Słodycze i przekąski"),
    ("seed-slod-prince-polo-xxl", "Wafle Prince Polo XXL w czekoladzie", "Olza", "5900130012345", 530.0, 6.0, 60.0, 29.0, 2.5, 50.0, "1 wafelek XXL (50g)", "Słodycze i przekąski"),
    ("seed-slod-princessa-mleczna", "Wafel Princessa Mleczna", "Nestlé", "5900020001015", 542.0, 6.4, 56.7, 31.8, 1.8, 45.0, "1 wafel (45g)", "Słodycze i przekąski"),
    ("seed-slod-grzeski-kakaowe", "Wafle Grześki kakaowe w czekoladzie deserowej", "Goplana", "5900352001010", 547.0, 7.1, 54.0, 33.0, 3.2, 36.0, "1 sztuka (36g)", "Słodycze i przekąski"),
    ("seed-slod-pryncypalki-klasyczne", "Wafle Pryncypałki w czekoladzie", "Dr Gerard", "5900743001019", 526.0, 6.5, 58.0, 29.0, 3.5, 30.0, "2 sztuki (30g)", "Słodycze i przekąski"),
    ("seed-slod-kinder-bueno", "Batoniki Kinder Bueno", "Ferrero", "8000500001018", 572.0, 8.6, 49.5, 37.3, 1.5, 43.0, "1 opakowanie / 2 batony (43g)", "Słodycze i przekąski"),
    ("seed-slod-kinder-bueno-white", "Batoniki Kinder Bueno White", "Ferrero", "8000500001025", 571.0, 8.8, 50.5, 36.5, 1.2, 39.0, "1 opakowanie / 2 batony (39g)", "Słodycze i przekąski"),
    ("seed-slod-kinder-chocolate", "Czekolada mleczna Kinder Chocolate", "Ferrero", "8000500001032", 566.0, 8.7, 53.5, 35.0, 0.9, 25.0, "2 batoniki (25g)", "Słodycze i przekąski"),
    ("seed-slod-kinder-country", "Batonik ze zbożami Kinder Country", "Ferrero", "8000500001049", 561.0, 8.6, 54.9, 33.8, 1.7, 23.5, "1 sztuka (23.5g)", "Słodycze i przekąski"),
    ("seed-slod-kinder-maxi", "Batonik Kinder Maxi", "Ferrero", "8000500001056", 566.0, 8.7, 53.5, 35.0, 0.9, 21.0, "1 sztuka (21g)", "Słodycze i przekąski"),
    ("seed-slod-snickers", "Batonik orzechowy Snickers", "Mars", "5000159461122", 488.0, 8.6, 60.0, 23.0, 2.3, 50.0, "1 baton (50g)", "Słodycze i przekąski"),
    ("seed-slod-twix", "Batoniki kruchy wafel z karmelem Twix", "Mars", "5000159459228", 495.0, 4.5, 65.0, 24.0, 1.4, 50.0, "1 opakowanie / 2 paluszki (50g)", "Słodycze i przekąski"),
    ("seed-slod-kitkat-4-finger", "Batonik wafel w czekoladzie KitKat 4 Finger", "Nestlé", "7613035002015", 515.0, 6.8, 62.0, 26.5, 2.2, 41.5, "1 baton (41.5g)", "Słodycze i przekąski"),
    ("seed-slod-lion", "Batonik karmelowo-czekoladowy Lion", "Nestlé", "7613035002022", 485.0, 5.0, 66.0, 22.0, 1.5, 42.0, "1 baton (42g)", "Słodycze i przekąski"),
    ("seed-slod-mars-baton", "Batonik nugat i karmel Mars", "Mars", "5000159407236", 448.0, 4.0, 70.0, 17.0, 1.2, 51.0, "1 baton (51g)", "Słodycze i przekąski"),
    ("seed-slod-bounty", "Batonik kokosowy w czekoladzie Bounty", "Mars", "5000159418546", 488.0, 3.8, 59.0, 26.0, 1.6, 57.0, "1 opakowanie / 2 sztuki (57g)", "Słodycze i przekąski"),
    ("seed-slod-nutella-krem", "Krem do smarowania orzechowo-kakaowy Nutella", "Ferrero", "8000500001063", 539.0, 6.3, 57.5, 30.9, 3.0, 25.0, "1 czubata łyżka (25g)", "Słodycze i przekąski"),
    ("seed-slod-ciastka-oreo", "Ciastka markizy kakaowe Oreo", "Mondelēz", "7622210002015", 474.0, 5.4, 68.0, 19.0, 2.7, 44.0, "4 ciastka (44g)", "Słodycze i przekąski"),
    ("seed-slod-ciastka-jezyki-classic", "Ciastka Jeżyki Classic karmel orzech", "Goplana", "5900352001027", 488.0, 5.6, 60.0, 24.0, 3.0, 35.0, "2 ciastka (35g)", "Słodycze i przekąski"),
    ("seed-slod-delicje-pomaranczowe", "Biszkopty z galaretką Delicje Pomarańczowe", "E.Wedel", "5901588015629", 375.0, 3.5, 70.0, 8.5, 2.2, 30.0, "2 ciastka (30g)", "Słodycze i przekąski"),
    ("seed-slod-delicje-wisniowe", "Biszkopty z galaretką Delicje Wiśniowe", "E.Wedel", "5901588015636", 375.0, 3.5, 70.0, 8.5, 2.2, 30.0, "2 ciastka (30g)", "Słodycze i przekąski"),
    ("seed-slod-pieguski-milka", "Ciastka kruche z kawałkami czekolady Pieguski", "Milka", "7622210002022", 495.0, 5.5, 64.0, 24.0, 2.4, 40.0, "3 ciastka (40g)", "Słodycze i przekąski"),
    ("seed-slod-pierniki-torunskie-kopernik", "Pierniki toruńskie z nadzieniem morelowym", "Kopernik", "5900445001018", 360.0, 4.5, 72.0, 5.0, 3.0, 45.0, "3 sztuki (45g)", "Słodycze i przekąski"),
    ("seed-slod-zelki-haribo-zlote-misie", "Żelki Haribo Złote Misie", "Haribo", "4001686001017", 343.0, 6.9, 77.0, 0.5, 0.1, 50.0, "1/2 małej paczki (50g)", "Słodycze i przekąski"),
    ("seed-slod-zelki-haribo-wummis", "Żelki dżdżownice kwaśne Wummis", "Haribo", "4001686001024", 335.0, 5.8, 76.0, 0.5, 0.1, 50.0, "1/2 małej paczki (50g)", "Słodycze i przekąski"),
    ("seed-slod-krowki-mleczne-wawel", "Krówki mleczne tradycyjne", "Wawel", "5900120001014", 415.0, 4.5, 75.0, 10.5, 0.0, 30.0, "2 sztuki (30g)", "Słodycze i przekąski"),
    ("seed-slod-michalki-klasyczne-wawel", "Cukierki czekoladowe Michałki z Wawelu klasyczne", "Wawel", "5900120001021", 535.0, 9.0, 52.0, 32.0, 4.5, 35.0, "2 sztuki (35g)", "Słodycze i przekąski"),
    ("seed-slod-michalki-biale-wawel", "Cukierki czekoladowe Michałki z Wawelu białe", "Wawel", "5900120001038", 545.0, 9.5, 51.0, 33.5, 3.5, 35.0, "2 sztuki (35g)", "Słodycze i przekąski"),
    ("seed-slod-mieszanka-wedlowska", "Cukierki czekoladowe Mieszanka Wedlowska", "E.Wedel", "5901588015643", 510.0, 5.5, 58.0, 28.0, 2.5, 30.0, "2 sztuki (30g)", "Słodycze i przekąski"),
    ("seed-slod-toffifee", "Czekoladki orzech laskowy w karmelu Toffifee", "Storck", "4014400901015", 522.0, 6.0, 59.0, 28.7, 2.2, 33.0, "4 sztuki (33g)", "Słodycze i przekąski"),
    ("seed-slod-lody-big-milk", "Lody śmietankowe na patyku Big Milk", "Algida", "8711327001018", 140.0, 2.8, 18.0, 6.0, 0.1, 65.0, "1 sztuka (65g)", "Słodycze i przekąski"),
    ("seed-slod-lody-magnum-classic", "Lody w czekoladzie deserowej Magnum Classic", "Algida", "8711327001025", 335.0, 3.8, 30.0, 21.0, 1.8, 85.0, "1 sztuka (85g)", "Słodycze i przekąski"),
    ("seed-slod-lody-magnum-almond", "Lody waniliowe z migdałami Magnum Almond", "Algida", "8711327001032", 345.0, 4.8, 31.0, 22.0, 2.0, 85.0, "1 sztuka (85g)", "Słodycze i przekąski"),
    ("seed-slod-rozek-cornetto-classico", "Rożek lodowy Cornetto Classico", "Algida", "8711327001049", 270.0, 3.5, 33.0, 13.5, 1.2, 75.0, "1 rożek (75g)", "Słodycze i przekąski"),
    ("seed-slod-chipsy-lays-solone", "Chipsy ziemniaczane Lay's Solone", "Lay's", "5900649000015", 535.0, 6.1, 53.0, 32.0, 4.2, 30.0, "1 mała miska (30g)", "Słodycze i przekąski"),
    ("seed-slod-chipsy-lays-paprykowe", "Chipsy ziemniaczane Lay's Paprykowe", "Lay's", "5900649000022", 525.0, 6.3, 53.0, 31.0, 4.5, 30.0, "1 mała miska (30g)", "Słodycze i przekąski"),
    ("seed-slod-chipsy-lays-fromage", "Chipsy ziemniaczane Lay's Fromage", "Lay's", "5900649000039", 528.0, 6.2, 53.0, 31.5, 4.3, 30.0, "1 mała miska (30g)", "Słodycze i przekąski"),
    ("seed-slod-chipsy-lays-zielona-cebulka", "Chipsy ziemniaczane Lay's Zielona Cebulka", "Lay's", "5900649000046", 530.0, 6.2, 52.5, 32.0, 4.4, 30.0, "1 mała miska (30g)", "Słodycze i przekąski"),
    ("seed-slod-chipsy-lays-pieczone-oven", "Chipsy pieczone Lay's Oven Baked solone", "Lay's", "5900649000053", 440.0, 6.5, 69.0, 14.0, 5.0, 30.0, "1 porcja (30g)", "Słodycze i przekąski"),
    ("seed-slod-nachos-doritos-ser", "Nachos kukurydziane Doritos Cheese serowe", "Doritos", "5900649000060", 498.0, 6.5, 60.0, 24.5, 4.0, 50.0, "1 porcja (50g)", "Słodycze i przekąski"),
    ("seed-slod-paluszki-slone-lajkonik", "Paluszki tradycyjne z solą", "Lajkonik", "5900154000012", 385.0, 10.5, 75.0, 4.0, 3.5, 40.0, "1 garść (40g)", "Słodycze i przekąski"),
    ("seed-slod-precelki-chrupkie-lajkonik", "Precelki chrupkie solone", "Lajkonik", "5900154000029", 395.0, 10.0, 74.0, 5.5, 3.8, 40.0, "1 garść (40g)", "Słodycze i przekąski"),
    ("seed-slod-krakersy-super-lajkonik", "Krakersy Super Krakersy solone", "Lajkonik", "5900154000036", 470.0, 9.0, 63.0, 19.5, 3.0, 40.0, "8 sztuk (40g)", "Słodycze i przekąski"),
    ("seed-slod-popcorn-maslany-felix", "Popcorn maślany do mikrofalówki", "Felix", "5900030002015", 465.0, 8.5, 55.0, 22.0, 10.0, 50.0, "1/2 torebki (50g)", "Słodycze i przekąski"),
    ("seed-slod-chrupki-flips", "Chrupki kukurydziane tradycyjne Flips", "Flips", "5900570002013", 385.0, 8.5, 77.0, 3.0, 3.5, 25.0, "1 miska (25g)", "Słodycze i przekąski"),
    ("seed-slod-chrupki-orzechowe-curly", "Chrupki orzechowe Curly", "Lorenz", "5900570002020", 505.0, 13.0, 51.0, 27.0, 4.5, 40.0, "1 porcja (40g)", "Słodycze i przekąski"),
    ("seed-slod-cheetos-serowe", "Chrupki kukurydziane Cheetos Cheese serowe", "Cheetos", "5900649000077", 485.0, 6.0, 63.0, 23.0, 2.0, 30.0, "1 mała miska (30g)", "Słodycze i przekąski"),
    ("seed-slod-cheetos-ketchup", "Chrupki kukurydziane Cheetos Ketchup", "Cheetos", "5900649000084", 485.0, 6.0, 63.0, 23.0, 2.0, 30.0, "1 mała miska (30g)", "Słodycze i przekąski"),
]

def main():
    print(f"Total products planned: {len(PRODUCTS)}")
    
    # Validation checks
    ids = set()
    categories = set()
    for item in PRODUCTS:
        pid, name, brand, barcode, cal, prot, carb, fat, fib, s_size, s_name, cat = item
        if pid in ids:
            print(f"ERROR: Duplicate ID: {pid}", file=sys.stderr)
            sys.exit(1)
        ids.add(pid)
        categories.add(cat)
        
        assert cal >= 0, f"Negative calories: {pid}"
        assert prot >= 0, f"Negative protein: {pid}"
        assert carb >= 0, f"Negative carbs: {pid}"
        assert fat >= 0, f"Negative fat: {pid}"
        assert s_size > 0, f"Invalid serving size: {pid}"
        assert len(s_name) > 0, f"Empty serving name: {pid}"

    print(f"Categories ({len(categories)}): {sorted(list(categories))}")

    # Build Dart file
    out = []
    out.append("// GENERATED PREDEFINED POLISH FOOD DATABASE")
    out.append("// Total items: %d" % len(PRODUCTS))
    out.append("// Categories: %s" % ", ".join(sorted(list(categories))))
    out.append("")
    out.append("import '../models/food_product.dart';")
    out.append("")
    out.append("/// Predefined catalog of staple and popular Polish food products.")
    out.append("///")
    out.append("/// Loaded on first launch into Hive foodProductsBox for instant offline-first")
    out.append("/// nutrition tracking, search, and portion calculation.")
    out.append("const List<FoodProduct> defaultFoodProducts = [")

    current_cat = None
    for item in PRODUCTS:
        pid, name, brand, barcode, cal, prot, carb, fat, fib, s_size, s_name, cat = item
        if cat != current_cat:
            current_cat = cat
            out.append(f"  // ===========================================================================")
            out.append(f"  // Kategoria: {current_cat}")
            out.append(f"  // ===========================================================================")

        safe_brand = brand.replace("'", "\\'") if brand else None
        brand_line = f"    brand: '{safe_brand}',\n" if safe_brand else ""
        barcode_line = f"    barcode: '{barcode}',\n" if barcode else ""
        fiber_line = f"    fiberPer100g: {fib:.1f},\n" if fib is not None else ""

        # Escape single quotes in name or serving if any
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
    with open("lib/data/default_food_database.dart", "w", encoding="utf-8") as f:
        f.write(content)

    print("Successfully written lib/data/default_food_database.dart!")

if __name__ == "__main__":
    main()
