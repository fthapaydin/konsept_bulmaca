import 'package:material_ui/material_ui.dart';
import '../utils/turkish_text.dart';

enum WordDirection {
  across,
  down;

  static WordDirection fromString(String value) =>
      value == 'down' ? WordDirection.down : WordDirection.across;

  String get labelTr => this == WordDirection.across ? 'YATAY' : 'DİKEY';

  WordDirection get opposite =>
      this == WordDirection.across ? WordDirection.down : WordDirection.across;
}

class CellCoord {
  const CellCoord(this.row, this.col);

  final int row;
  final int col;

  String get key => '$row,$col';

  static CellCoord fromKey(String key) {
    final parts = key.split(',');
    return CellCoord(int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellCoord && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

class PuzzleEntry {
  const PuzzleEntry({
    required this.number,
    required this.direction,
    required this.row,
    required this.col,
    required this.answer,
    required this.clue,
  });

  final int number;
  final WordDirection direction;
  final int row;
  final int col;
  final String answer;
  final String clue;

  int get length => answer.length;

  String get id => '${direction.name}_$number';

  List<CellCoord> get cells {
    final dr = direction == WordDirection.down ? 1 : 0;
    final dc = direction == WordDirection.across ? 1 : 0;
    return List<CellCoord>.generate(
      length,
      (i) => CellCoord(row + i * dr, col + i * dc),
    );
  }

  bool containsCell(int r, int c) {
    if (direction == WordDirection.across) {
      return r == row && c >= col && c < col + length;
    }
    return c == col && r >= row && r < row + length;
  }

  int indexOfCell(int r, int c) {
    if (!containsCell(r, c)) return -1;
    return direction == WordDirection.across ? c - col : r - row;
  }

  factory PuzzleEntry.fromJson(Map<String, dynamic> json) {
    return PuzzleEntry(
      number: json['number'] as int,
      direction: WordDirection.fromString(json['direction'] as String),
      row: json['row'] as int,
      col: json['col'] as int,
      answer: json['answer'] as String,
      clue: json['clue'] as String,
    );
  }
}

class CrosswordPuzzle {
  CrosswordPuzzle({
    required this.id,
    required this.level,
    required this.title,
    required this.difficulty,
    required this.rows,
    required this.cols,
    required this.revealed,
    required this.entries,
  }) {
    _solutionGrid = List.generate(rows, (_) => List<String?>.filled(cols, null));
    _numberGrid = List.generate(rows, (_) => List<int?>.filled(cols, null));
    _acrossMap = {};
    _downMap = {};
    _initialRevealedKeys = {};

    for (final entry in entries) {
      _numberGrid[entry.row][entry.col] = entry.number;
      final chars = entry.answer.characters.toList();
      final coords = entry.cells;
      for (var i = 0; i < coords.length; i++) {
        final coord = coords[i];
        _solutionGrid[coord.row][coord.col] = chars[i];
        if (entry.direction == WordDirection.across) {
          _acrossMap[coord.key] = entry;
        } else {
          _downMap[coord.key] = entry;
        }
      }
    }

    for (final coord in revealed) {
      _initialRevealedKeys.add(coord.key);
    }

    var count = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_solutionGrid[r][c] != null) count++;
      }
    }
    activeCellCount = count;
  }

  final String id;
  final int level;
  final String title;
  final String difficulty;
  final int rows;
  final int cols;
  final List<CellCoord> revealed;
  final List<PuzzleEntry> entries;

  late final List<List<String?>> _solutionGrid;
  late final List<List<int?>> _numberGrid;
  late final Map<String, PuzzleEntry> _acrossMap;
  late final Map<String, PuzzleEntry> _downMap;
  late final Set<String> _initialRevealedKeys;
  late final int activeCellCount;

  String? solutionAt(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return _solutionGrid[r][c];
  }

  bool isActiveCell(int r, int c) => solutionAt(r, c) != null;

  int? numberAt(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return _numberGrid[r][c];
  }

  bool isInitialRevealed(int r, int c) => _initialRevealedKeys.contains('$r,$c');

  PuzzleEntry? entryAt(int r, int c, WordDirection dir) {
    final key = '$r,$c';
    return dir == WordDirection.across ? _acrossMap[key] : _downMap[key];
  }

  List<PuzzleEntry> get acrossEntries =>
      entries.where((e) => e.direction == WordDirection.across).toList()
        ..sort((a, b) => a.number.compareTo(b.number));

  List<PuzzleEntry> get downEntries =>
      entries.where((e) => e.direction == WordDirection.down).toList()
        ..sort((a, b) => a.number.compareTo(b.number));

  List<PuzzleEntry> get orderedEntries => [...acrossEntries, ...downEntries];

  String get gridSizeLabel => '$rows×$cols';

  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) {
    final revRaw = (json['revealed'] as List<dynamic>? ?? []);
    final revealed = revRaw
        .map((pair) => CellCoord((pair as List)[0] as int, pair[1] as int))
        .toList();
    final entries = (json['entries'] as List<dynamic>)
        .map((e) => PuzzleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return CrosswordPuzzle(
      id: json['id'] as String,
      level: json['level'] as int,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      revealed: revealed,
      entries: entries,
    );
  }
}

class ConceptPack {
  const ConceptPack({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.language,
    required this.iconKey,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.levels,
  });

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String language;
  final String iconKey;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final List<CrosswordPuzzle> levels;

  IconData get icon => TurkishText.iconFromKey(iconKey);

  factory ConceptPack.fromJson(Map<String, dynamic> json) {
    return ConceptPack(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      iconKey: json['icon'] as String,
      primaryColor: TurkishText.colorFromHex(json['primaryColor'] as String),
      secondaryColor: TurkishText.colorFromHex(json['secondaryColor'] as String),
      surfaceColor: TurkishText.colorFromHex(json['surfaceColor'] as String),
      levels: (json['levels'] as List<dynamic>)
          .map((e) => CrosswordPuzzle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DailyBank {
  const DailyBank({
    required this.id,
    required this.name,
    required this.language,
    required this.puzzles,
  });

  final String id;
  final String name;
  final String language;
  final List<CrosswordPuzzle> puzzles;

  CrosswordPuzzle puzzleForDate(DateTime date) {
    final epochDay = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2026, 1, 1))
        .inDays;
    final idx = ((epochDay % puzzles.length) + puzzles.length) % puzzles.length;
    return puzzles[idx];
  }

  factory DailyBank.fromJson(Map<String, dynamic> json) {
    return DailyBank(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      puzzles: (json['puzzles'] as List<dynamic>)
          .map((e) => CrosswordPuzzle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PuzzleSaveState {
  const PuzzleSaveState({
    required this.puzzleId,
    this.letters = const {},
    this.lockedCells = const {},
    this.elapsedSeconds = 0,
    this.hintsUsed = 0,
    this.mistakesCount = 0,
    this.completed = false,
    this.stars = 0,
    this.bestTimeSeconds,
  });

  final String puzzleId;
  final Map<String, String> letters;
  final Set<String> lockedCells;
  final int elapsedSeconds;
  final int hintsUsed;
  final int mistakesCount;
  final bool completed;
  final int stars;
  final int? bestTimeSeconds;

  bool get hasProgress => !completed && letters.isNotEmpty;

  PuzzleSaveState copyWith({
    Map<String, String>? letters,
    Set<String>? lockedCells,
    int? elapsedSeconds,
    int? hintsUsed,
    int? mistakesCount,
    bool? completed,
    int? stars,
    int? bestTimeSeconds,
  }) {
    return PuzzleSaveState(
      puzzleId: puzzleId,
      letters: letters ?? this.letters,
      lockedCells: lockedCells ?? this.lockedCells,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakesCount: mistakesCount ?? this.mistakesCount,
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'puzzleId': puzzleId,
        'letters': letters,
        'lockedCells': lockedCells.toList(),
        'elapsedSeconds': elapsedSeconds,
        'hintsUsed': hintsUsed,
        'mistakesCount': mistakesCount,
        'completed': completed,
        'stars': stars,
        'bestTimeSeconds': bestTimeSeconds,
      };

  factory PuzzleSaveState.fromJson(Map<String, dynamic> json) {
    final lettersRaw = (json['letters'] as Map<String, dynamic>? ?? {});
    final lockedRaw = (json['lockedCells'] as List<dynamic>? ?? []);
    return PuzzleSaveState(
      puzzleId: json['puzzleId'] as String,
      letters: lettersRaw.map((k, v) => MapEntry(k, v as String)),
      lockedCells: lockedRaw.map((e) => e as String).toSet(),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      mistakesCount: json['mistakesCount'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestTimeSeconds: json['bestTimeSeconds'] as int?,
    );
  }
}

class PlayerProfile {
  const PlayerProfile({
    this.coins = 150,
    this.dailyStreak = 0,
    this.lastDailyDate,
    this.completedDailyDates = const {},
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.selectedBackgroundId = 'concept_auto',
    this.unlockedBackgroundIds = const {},
    this.puzzleStates = const {},
  });

  final int coins;
  final int dailyStreak;
  final String? lastDailyDate;
  final Set<String> completedDailyDates;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final String selectedBackgroundId;
  final Set<String> unlockedBackgroundIds;
  final Map<String, PuzzleSaveState> puzzleStates;

  PlayerProfile copyWith({
    int? coins,
    int? dailyStreak,
    String? lastDailyDate,
    Set<String>? completedDailyDates,
    bool? soundEnabled,
    bool? hapticsEnabled,
    String? selectedBackgroundId,
    Set<String>? unlockedBackgroundIds,
    Map<String, PuzzleSaveState>? puzzleStates,
  }) {
    return PlayerProfile(
      coins: coins ?? this.coins,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyDate: lastDailyDate ?? this.lastDailyDate,
      completedDailyDates: completedDailyDates ?? this.completedDailyDates,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      selectedBackgroundId: selectedBackgroundId ?? this.selectedBackgroundId,
      unlockedBackgroundIds:
          unlockedBackgroundIds ?? this.unlockedBackgroundIds,
      puzzleStates: puzzleStates ?? this.puzzleStates,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'dailyStreak': dailyStreak,
        'lastDailyDate': lastDailyDate,
        'completedDailyDates': completedDailyDates.toList(),
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'selectedBackgroundId': selectedBackgroundId,
        'unlockedBackgroundIds': unlockedBackgroundIds.toList(),
        'puzzleStates': puzzleStates.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final statesRaw = (json['puzzleStates'] as Map<String, dynamic>? ?? {});
    final dailyRaw = (json['completedDailyDates'] as List<dynamic>? ?? []);
    final bgRaw = (json['unlockedBackgroundIds'] as List<dynamic>? ?? []);
    return PlayerProfile(
      coins: json['coins'] as int? ?? 150,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      lastDailyDate: json['lastDailyDate'] as String?,
      completedDailyDates: dailyRaw.map((e) => e as String).toSet(),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      selectedBackgroundId:
          json['selectedBackgroundId'] as String? ?? 'concept_auto',
      unlockedBackgroundIds: bgRaw.map((e) => e as String).toSet(),
      puzzleStates: statesRaw.map(
        (k, v) => MapEntry(k, PuzzleSaveState.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}
