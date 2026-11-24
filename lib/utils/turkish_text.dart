import 'package:material_ui/material_ui.dart';

class TurkishText {
  static const Map<String, String> _trUpper = {
    'i': 'İ',
    'ı': 'I',
    'ş': 'Ş',
    'ğ': 'Ğ',
    'ü': 'Ü',
    'ö': 'Ö',
    'ç': 'Ç',
  };

  static const Set<String> validTrLetters = {
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
    'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
    'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z',
  };

  static const Set<String> validEnLetters = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
  };

  static String normalizeLetter(String raw, {required String language}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final ch = trimmed.characters.first;
    if (language == 'tr') {
      final mapped = _trUpper[ch] ?? ch.toUpperCase();
      return validTrLetters.contains(mapped) ? mapped : '';
    }
    final upper = ch.toUpperCase();
    return validEnLetters.contains(upper) ? upper : '';
  }

  static String formatDuration(int totalSeconds) {
    final clamped = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = clamped ~/ 60;
    final seconds = clamped % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  static String dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatTurkishDate(DateTime dt) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static Color colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    final value = int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(value);
  }

  static IconData iconFromKey(String key) {
    switch (key) {
      case 'movie':
        return Icons.movie_filter_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'explore':
        return Icons.explore_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'calendar':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.grid_on_rounded;
    }
  }
}
