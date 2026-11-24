/// İngilizce Kelime Avı / Mega / Mini Sprint modlarında çözülen İngilizce
/// kelimelerin otomatik kaydedildiği "Kelime Defteri" kaydı.
class LearnedWord {
  const LearnedWord({
    required this.word,
    required this.meaning,
    required this.cefrLevel,
    this.timesSolved = 1,
    this.isFavorite = false,
    required this.firstLearnedIso,
  });

  final String word;
  final String meaning;
  final String cefrLevel; // A1, A2, B1
  final int timesSolved;
  final bool isFavorite;
  final String firstLearnedIso;

  LearnedWord copyWith({
    String? meaning,
    String? cefrLevel,
    int? timesSolved,
    bool? isFavorite,
  }) {
    return LearnedWord(
      word: word,
      meaning: meaning ?? this.meaning,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      timesSolved: timesSolved ?? this.timesSolved,
      isFavorite: isFavorite ?? this.isFavorite,
      firstLearnedIso: firstLearnedIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'cefrLevel': cefrLevel,
        'timesSolved': timesSolved,
        'isFavorite': isFavorite,
        'firstLearnedIso': firstLearnedIso,
      };

  factory LearnedWord.fromJson(Map<String, dynamic> json) {
    return LearnedWord(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      timesSolved: json['timesSolved'] as int? ?? 1,
      isFavorite: json['isFavorite'] as bool? ?? false,
      firstLearnedIso: json['firstLearnedIso'] as String? ?? '',
    );
  }

  /// "Mutlu (A1)" veya "Sabah (A2-B1)" şeklindeki ipucundan anlam ve CEFR ayırır.
  static ({String meaning, String cefr}) parseClue(String rawClue) {
    final cleaned = rawClue.trim();
    final match = RegExp(r'^(.*?)\s*\((A1|A2|B1|A1-A2|A2-B1)\)\s*$')
        .firstMatch(cleaned);
    if (match != null) {
      final meaning = match.group(1)!.trim();
      final rawLevel = match.group(2)!;
      final normalizedCefr = rawLevel.contains('B1')
          ? 'B1'
          : (rawLevel.contains('A2') ? 'A2' : 'A1');
      return (meaning: meaning, cefr: normalizedCefr);
    }
    return (meaning: cleaned, cefr: 'A2');
  }
}
