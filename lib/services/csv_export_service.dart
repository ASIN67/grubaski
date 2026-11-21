import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meal_entry.dart';
import 'hive_service.dart';

/// Service responsible for exporting food diary entries to a standardized CSV format
/// with Polish localized columns and sharing it via the platform share sheet.
class CsvExportService {
  const CsvExportService();

  /// Polish CSV header row
  static const String csvHeader =
      'Data,Posiłek,Produkt,Marka,Gramy,Kalorie,Białko,Węglowodany,Tłuszcze,Błonnik';

  /// Generates CSV content from provided [entries] or all entries stored in Hive.
  String generateCsvContent({List<MealEntry>? entries}) {
    final list = entries ??
        HiveService.instance.mealEntriesBox.values.toList()
      ..sort((a, b) {
        final dateComp = b.dateKey.compareTo(a.dateKey);
        if (dateComp != 0) return dateComp;
        return a.mealType.index.compareTo(b.mealType.index);
      });

    final buffer = StringBuffer();
    // UTF-8 Byte Order Mark (BOM) to ensure Microsoft Excel correctly displays Polish diacritics
    buffer.write('\uFEFF');
    buffer.writeln(csvHeader);

    for (final entry in list) {
      final row = [
        _escapeCsvField(entry.dateKey),
        _escapeCsvField(entry.mealType.displayName),
        _escapeCsvField(entry.product.name),
        _escapeCsvField(entry.product.brand ?? ''),
        entry.weightGrams?.toStringAsFixed(1) ?? '',
        entry.calories.toStringAsFixed(1),
        entry.protein.toStringAsFixed(1),
        entry.carbs.toStringAsFixed(1),
        entry.fat.toStringAsFixed(1),
        entry.fiber.toStringAsFixed(1),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Exports diary history to a CSV file in the system temp directory
  /// and triggers platform share sheet using `share_plus`.
  Future<ShareResult> exportAndShareDiary({List<MealEntry>? entries}) async {
    try {
      final csvData = generateCsvContent(entries: entries);

      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
      final fileName = 'grubasek_dziennik_$timestamp.csv';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(csvData, flush: true);

      final xFile = XFile(
        file.path,
        mimeType: 'text/csv',
        name: fileName,
      );

      final result = await Share.shareXFiles(
        [xFile],
        subject: 'Eksport historii z aplikacji Grubasek',
        text: 'W załączniku znajduje się eksport historii posiłków z aplikacji Grubasek.',
      );

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error exporting diary to CSV: $e\n$stackTrace');
      rethrow;
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  String _pad(int number) => number.toString().padLeft(2, '0');
}
