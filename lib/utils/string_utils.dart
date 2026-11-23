/// String normalization and search utilities for Polish text.
/// Handles stripping diacritics, query normalization, and fast string matching.
library;

/// Map of Polish and common Latin diacritics to their ASCII counterparts.
const Map<int, String> _diacriticCodeUnitMap = {
  // Polish lowercase
  0x0105: 'a', // ą
  0x0107: 'c', // ć
  0x0119: 'e', // ę
  0x0142: 'l', // ł
  0x0144: 'n', // ń
  0x00F3: 'o', // ó
  0x015B: 's', // ś
  0x017A: 'z', // ź
  0x017C: 'z', // ż

  // Polish uppercase
  0x0104: 'A', // Ą
  0x0106: 'C', // Ć
  0x0118: 'E', // Ę
  0x0141: 'L', // Ł
  0x0143: 'N', // Ń
  0x00D3: 'O', // Ó
  0x015A: 'S', // Ś
  0x0179: 'Z', // Ź
  0x017B: 'Z', // Ż

  // Other common Latin diacritics
  0x00E0: 'a', // à
  0x00E1: 'a', // á
  0x00E2: 'a', // â
  0x00E3: 'a', // ã
  0x00E4: 'a', // ä
  0x00E5: 'a', // å
  0x00C0: 'A', // À
  0x00C1: 'A', // Á
  0x00C2: 'A', // Â
  0x00C3: 'A', // Ã
  0x00C4: 'A', // Ä
  0x00C5: 'A', // Å
  0x00E8: 'e', // è
  0x00E9: 'e', // é
  0x00EA: 'e', // ê
  0x00EB: 'e', // ë
  0x00C8: 'E', // È
  0x00C9: 'E', // É
  0x00CA: 'E', // Ê
  0x00CB: 'E', // Ë
  0x00EC: 'i', // ì
  0x00ED: 'i', // í
  0x00EE: 'i', // î
  0x00EF: 'i', // ï
  0x00CC: 'I', // Ì
  0x00CD: 'I', // Í
  0x00CE: 'I', // Î
  0x00CF: 'I', // Ï
  0x00F2: 'o', // ò
  0x00F4: 'o', // ô
  0x00F5: 'o', // õ
  0x00F6: 'o', // ö
  0x00D2: 'O', // Ò
  0x00D4: 'O', // Ô
  0x00D5: 'O', // Õ
  0x00D6: 'O', // Ö
  0x00F9: 'u', // ù
  0x00FA: 'u', // ú
  0x00FB: 'u', // û
  0x00FC: 'u', // ü
  0x00D9: 'U', // Ù
  0x00DA: 'U', // Ú
  0x00DB: 'U', // Û
  0x00DC: 'U', // Ü
};

/// Map of Polish and common Latin diacritics directly to lowercase ASCII.
const Map<int, String> _diacriticToLowerMap = {
  // Polish lowercase
  0x0105: 'a', // ą
  0x0107: 'c', // ć
  0x0119: 'e', // ę
  0x0142: 'l', // ł
  0x0144: 'n', // ń
  0x00F3: 'o', // ó
  0x015B: 's', // ś
  0x017A: 'z', // ź
  0x017C: 'z', // ż

  // Polish uppercase -> lowercase
  0x0104: 'a', // Ą
  0x0106: 'c', // Ć
  0x0118: 'e', // Ę
  0x0141: 'l', // Ł
  0x0143: 'n', // Ń
  0x00D3: 'o', // Ó
  0x015A: 's', // Ś
  0x0179: 'z', // Ź
  0x017B: 'z', // Ż

  // Other common Latin diacritics -> lowercase
  0x00E0: 'a', // à
  0x00E1: 'a', // á
  0x00E2: 'a', // â
  0x00E3: 'a', // ã
  0x00E4: 'a', // ä
  0x00E5: 'a', // å
  0x00C0: 'a', // À
  0x00C1: 'a', // Á
  0x00C2: 'a', // Â
  0x00C3: 'a', // Ã
  0x00C4: 'a', // Ä
  0x00C5: 'a', // Å
  0x00E8: 'e', // è
  0x00E9: 'e', // é
  0x00EA: 'e', // ê
  0x00EB: 'e', // ë
  0x00C8: 'e', // È
  0x00C9: 'e', // É
  0x00CA: 'e', // Ê
  0x00CB: 'e', // Ë
  0x00EC: 'i', // ì
  0x00ED: 'i', // í
  0x00EE: 'i', // î
  0x00EF: 'i', // ï
  0x00CC: 'i', // Ì
  0x00CD: 'i', // Í
  0x00CE: 'i', // Î
  0x00CF: 'i', // Ï
  0x00F2: 'o', // ò
  0x00F4: 'o', // ô
  0x00F5: 'o', // õ
  0x00F6: 'o', // ö
  0x00D2: 'o', // Ò
  0x00D4: 'o', // Ô
  0x00D5: 'o', // Õ
  0x00D6: 'o', // Ö
  0x00F9: 'u', // ù
  0x00FA: 'u', // ú
  0x00FB: 'u', // û
  0x00FC: 'u', // ü
  0x00D9: 'u', // Ù
  0x00DA: 'u', // Ú
  0x00DB: 'u', // Û
  0x00DC: 'u', // Ü
};

/// Removes Polish (and common European) diacritical marks from [text],
/// preserving the casing of each character.
///
/// Examples:
/// - "bułka" -> "bulka"
/// - "twaróg" -> "twarog"
/// - "KIEŁBASA" -> "KIELBASA"
/// - "żółć" -> "zolc"
String removePolishDiacritics(String text) {
  if (text.isEmpty) return text;

  // Fast path: check if any code unit requires replacement (> 127)
  var hasDiacritic = false;
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) > 127 &&
        _diacriticCodeUnitMap.containsKey(text.codeUnitAt(i))) {
      hasDiacritic = true;
      break;
    }
  }

  if (!hasDiacritic) return text;

  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    final replacement = _diacriticCodeUnitMap[code];
    if (replacement != null) {
      buffer.write(replacement);
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}

/// Normalizes a string for fast search matching:
/// 1. Strips Polish and Latin diacritical marks (e.g. ą->a, ł->l, ó->o).
/// 2. Converts to lowercase.
/// 3. Trims whitespace and collapses multiple spaces into a single space.
///
/// Executes in a single high-performance pass without intermediate regex or string allocations.
///
/// Example:
/// - "  Bułka   GRAHAMKA  " -> "bulka grahamka"
String normalizeForSearch(String text) {
  if (text.isEmpty) return '';

  var start = 0;
  var end = text.length;

  // Trim leading whitespace
  while (start < end && text.codeUnitAt(start) <= 32) {
    start++;
  }
  // Trim trailing whitespace
  while (end > start && text.codeUnitAt(end - 1) <= 32) {
    end--;
  }

  if (start >= end) return '';

  final buffer = StringBuffer();
  var prevWasSpace = false;

  for (var i = start; i < end; i++) {
    final code = text.codeUnitAt(i);

    // Whitespace collapse
    if (code <= 32) {
      if (!prevWasSpace) {
        buffer.write(' ');
        prevWasSpace = true;
      }
      continue;
    }
    prevWasSpace = false;

    // Check Polish/Latin diacritics (all map to lowercase ASCII)
    final replacement = _diacriticToLowerMap[code];
    if (replacement != null) {
      buffer.write(replacement);
      continue;
    }

    // ASCII Uppercase A-Z -> a-z
    if (code >= 65 && code <= 90) {
      buffer.writeCharCode(code + 32);
      continue;
    }

    buffer.writeCharCode(code);
  }

  return buffer.toString();
}

/// Set of common Polish prepositions, conjunctions, and stop words
/// that are filtered out in multi-word product searches.
const Set<String> polishStopwords = {
  'z', 'ze', 'w', 'we', 'i', 'oraz', 'do', 'na', 'o', 'od', 'dla', 'a',
};

/// Common Polish brand aliases, colloquial abbreviations, and inflections.
const Map<String, List<String>> polishBrandAliases = {
  'mcdonald': ['mak', 'maka', 'maku', 'mcdonald', 'mcdonalds', 'mc'],
  'kfc': ['kfc', 'kentucky'],
  'biedronka': ['biedronka', 'biedronki', 'biedronce', 'biedra', 'biedry', 'biedrze', 'kraina wedlin'],
  'lidl': ['lidl', 'lidla', 'lidlu', 'pilos'],
  'piatnica': ['piatnica', 'piatnicy', 'piatnice'],
  'zabka': ['zabka', 'zabki', 'zabce'],
  'kfd': ['kfd'],
  'sfd': ['sfd'],
  'mlekovita': ['mlekovita', 'mlekovity', 'mlekovicie'],
  'lowicz': ['lowicz', 'lowicza'],
  'danone': ['danone', 'danona'],
  'zywiec': ['zywiec', 'zywca'],
  'pepsi': ['pepsi'],
  'coca-cola': ['cola', 'coca', 'cocacola'],
};

/// Checks if a normalized brand string matches a query token or stem directly or through aliases.
bool matchBrandAlias(String brandNorm, String queryToken, String queryStem) {
  final cleanBrand = brandNorm.replaceAll(RegExp(r'''['"`\-/,().:;%!?]'''), '');
  if (cleanBrand == queryToken || cleanBrand == queryStem) return true;
  if (cleanBrand.startsWith(queryToken) || cleanBrand.startsWith(queryStem)) return true;

  for (final entry in polishBrandAliases.entries) {
    final key = entry.key;
    if (cleanBrand.contains(key) || brandNorm.contains(key)) {
      if (entry.value.contains(queryToken) ||
          entry.value.contains(queryStem) ||
          entry.value.any((v) => queryToken.startsWith(v) || queryStem.startsWith(v))) {
        return true;
      }
    }
  }
  return false;
}

/// Extracts a simplified root stem for a Polish normalized word (lowercase, no diacritics).
/// Trims common grammatical inflection endings (declensions, plurals, adjectives)
/// so that e.g. "truskawka", "truskawkowy", "truskawkowe" all yield "truskawk",
/// "kurczaka", "kurczakiem", "kurczak" all yield "kurczak",
/// and "maka", "maku", "mak" all yield "mak".
String polishStem(String word) {
  if (word.length < 4) return word;

  // 1. Long adjective/inflection suffixes (length >= 7)
  if (word.length >= 7) {
    if (word.endsWith('owego') ||
        word.endsWith('owych') ||
        word.endsWith('owym') ||
        word.endsWith('owej')) {
      return word.substring(0, word.length - 5);
    }
    if (word.endsWith('kiem')) {
      return '${word.substring(0, word.length - 4)}k';
    }
    if (word.endsWith('nych') ||
        word.endsWith('nymi') ||
        word.endsWith('nego') ||
        word.endsWith('nemu')) {
      return word.substring(0, word.length - 4);
    }
  }

  // 2. Medium suffixes (length >= 6)
  if (word.length >= 6) {
    if (word.endsWith('owy') ||
        word.endsWith('owa') ||
        word.endsWith('owe') ||
        word.endsWith('ami') ||
        word.endsWith('ach')) {
      return word.substring(0, word.length - 3);
    }
    if (word.endsWith('skie') ||
        word.endsWith('skiej') ||
        word.endsWith('skim')) {
      return word.substring(0, word.length - 4);
    }
    if (word.endsWith('ska') || word.endsWith('ski')) {
      return word.substring(0, word.length - 3);
    }
  }

  // 3. Short suffixes (length >= 5)
  if (word.length >= 5) {
    if (word.endsWith('iem') ||
        word.endsWith('ych') ||
        word.endsWith('ich') ||
        word.endsWith('ego') ||
        word.endsWith('emu')) {
      return word.substring(0, word.length - 3);
    }
    if (word.endsWith('ow') ||
        word.endsWith('em') ||
        word.endsWith('am') ||
        word.endsWith('om') ||
        word.endsWith('ie') ||
        word.endsWith('ej')) {
      return word.substring(0, word.length - 2);
    }
  }

  // 4. Single-letter inflection endings (length >= 4)
  if (word.length >= 4) {
    final last = word.codeUnitAt(word.length - 1);
    // a, e, y, u, i, o
    if (last == 0x61 ||
        last == 0x65 ||
        last == 0x79 ||
        last == 0x75 ||
        last == 0x69 ||
        last == 0x6F) {
      return word.substring(0, word.length - 1);
    }
  }

  return word;
}

/// Splits text into normalized, diacritics-stripped tokens for search.
/// Replaces punctuation with spaces and filters out stopwords when multiple words exist.
List<String> tokenizeForSearch(String text) {
  if (text.isEmpty) return const [];
  final norm = normalizeForSearch(text);
  final clean = norm.replaceAll(RegExp(r'''['"`\-/,().:;%!?_#*+=\[\]]'''), ' ');
  final rawTokens = clean
      .split(' ')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  if (rawTokens.length > 1) {
    final filtered = rawTokens.where((t) => !polishStopwords.contains(t)).toList(growable: false);
    if (filtered.isNotEmpty) return filtered;
  }
  return rawTokens;
}

/// Extension providing easy string search normalization helpers.
extension StringSearchUtils on String {
  /// Returns a copy of this string with Polish diacritics replaced by Latin letters.
  String stripPolishDiacritics() => removePolishDiacritics(this);

  /// Returns this string normalized for search: lowercase, trimmed, no diacritics.
  String toSearchNormalized() => normalizeForSearch(this);

  /// Returns the Polish grammatical stem of this word.
  String toPolishStem() => polishStem(normalizeForSearch(this));
}
