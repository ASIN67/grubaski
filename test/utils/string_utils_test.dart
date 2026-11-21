import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/utils/string_utils.dart';

void main() {
  group('string_utils', () {
    test('removes all Polish diacritics (lowercase and uppercase)', () {
      expect(removePolishDiacritics('ąćęłńóśźż'), equals('acelnoszz'));
      expect(removePolishDiacritics('ĄĆĘŁŃÓŚŹŻ'), equals('ACELNOSZZ'));
      expect(removePolishDiacritics('Zażółć gęślą jaźń'), equals('Zazolc gesla jazn'));
    });

    test('preserves strings without diacritics', () {
      expect(removePolishDiacritics('jajko'), equals('jajko'));
      expect(removePolishDiacritics('skyr'), equals('skyr'));
      expect(removePolishDiacritics('12345'), equals('12345'));
      expect(removePolishDiacritics(''), equals(''));
    });

    test('normalizes Polish food names for search', () {
      expect(normalizeForSearch('bułka'), equals('bulka'));
      expect(normalizeForSearch('Bułka pszenna'), equals('bulka pszenna'));
      expect(normalizeForSearch('Twaróg chudy'), equals('twarog chudy'));
      expect(normalizeForSearch('Jajko kurze M'), equals('jajko kurze m'));
      expect(normalizeForSearch('  Kiełbasa   ŚLĄSKA  '), equals('kielbasa slaska'));
      expect(normalizeForSearch('Jogurt naturalny'), equals('jogurt naturalny'));
    });

    test('handles extension methods cleanly', () {
      expect('bułka'.stripPolishDiacritics(), equals('bulka'));
      expect('  TWARÓG  '.toSearchNormalized(), equals('twarog'));
    });
  });
}
