/// English IPA units and notation aliases used by the backend comparison.
/// Matching units keeps /ɪ/ distinct from /eɪ/ and /ʃ/ from /tʃ/.
abstract final class IpaSymbols {
  static const _multi = [
    'tʃ',
    'dʒ',
    'iː',
    'ɑː',
    'ɔː',
    'uː',
    'ɜː',
    'eɪ',
    'aɪ',
    'aʊ',
    'oʊ',
    'əʊ',
    'ɔɪ',
    'ɪə',
    'eə',
    'ʊə',
  ];
  static const _aliases = {
    'ɹ': 'r',
    'ɫ': 'l',
    'g': 'ɡ',
    'e': 'ɛ',
    'əʊ': 'oʊ',
    'ᵻ': 'ɪ',
  };

  static List<String> tokenize(String ipa) {
    var value = ipa
        .replaceAll(':', 'ː')
        .replaceAll('ɚ', 'ər')
        .replaceAll('ɝ', 'ɜːr')
        .replaceAll(RegExp(r'[ˈˌ/\[\].\sˑ͡]'), '');
    final result = <String>[];
    while (value.isNotEmpty) {
      var unit = value.substring(0, 1);
      for (final symbol in _multi) {
        if (value.startsWith(symbol)) {
          unit = symbol;
          break;
        }
      }
      result.add(_aliases[unit] ?? unit);
      value = value.substring(unit.length);
    }
    return result;
  }

  /// A cluster must occur inside one word, never across a word boundary.
  static bool containsSequence(String ipa, String target) {
    final wanted = tokenize(target);
    if (wanted.isEmpty || wanted.contains('∅')) return false;
    for (final word in ipa.split(RegExp(r'[\s/\[\]]+'))) {
      final units = tokenize(word);
      for (var start = 0; start + wanted.length <= units.length; start++) {
        var matches = true;
        for (var index = 0; index < wanted.length; index++) {
          if (units[start + index] != wanted[index]) {
            matches = false;
            break;
          }
        }
        if (matches) return true;
      }
    }
    return false;
  }
}
