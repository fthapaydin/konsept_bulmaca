import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/economy/hint_pricing.dart';
import '../models/puzzle_models.dart';
import '../models/retention_models.dart';
import '../utils/turkish_text.dart';
import 'app_state.dart';

enum HintStatus { ok, insufficientCoins, nothingToDo }

class HintFeedback {
  const HintFeedback(this.status, this.message);

  final HintStatus status;
  final String message;
}

class GameController extends ChangeNotifier {
  GameController({
    required this.puzzle,
    required this.storageKey,
    required this.language,
    required this.isDaily,
    required this.appState,
    this.rewardMultiplier = 1,
    this.persistSession = true,
    this.enableInternalTimer = true,
    this.initialComboCount = 0,
    this.onWordSolved,
    this.onPuzzleCompleted,
  }) {
    _wordComboCount = initialComboCount;
    _maxComboInSession = initialComboCount;
    _loadInitialState();
    _selectInitialCell();
    if (enableInternalTimer) {
      _startTimer();
    }
  }

  final CrosswordPuzzle puzzle;
  final String storageKey;
  final String language;
  final bool isDaily;
  final int rewardMultiplier;
  final bool persistSession;
  final bool enableInternalTimer;
  final int initialComboCount;
  final AppState appState;
  final void Function(int newCombo, int coinsEarned, int scoreEarned)?
      onWordSolved;
  final void Function(CompletionReward reward)? onPuzzleCompleted;

  final Map<String, String> _letters = {};
  final Set<String> _lockedCells = {};
  final Set<String> _wrongCells = {};
  final Set<String> _wrongEntryIds = {};
  final Set<String> _solvedEntryIds = {};
  final Set<String> _awardedEntryIds = {};

  late CellCoord _selectedCell;
  WordDirection _direction = WordDirection.across;
  int _elapsedSeconds = 0;
  int _hintsUsed = 0;
  int _letterPaidHints = 0;
  int _wordPaidHints = 0;
  int _checkPaidHints = 0;
  int _mistakesCount = 0;
  bool _isCompleted = false;
  String? _recentSolvedEntryId;
  String? _recentSolvedBanner;
  String? _activeErrorBanner;
  int _wordComboCount = 0;
  int _maxComboInSession = 0;
  int _sessionComboCoins = 0;
  int _sessionComboScore = 0;
  Timer? _timer;
  Timer? _flashTimer;
  Timer? _errorBannerTimer;
  bool _disposed = false;

  CellCoord get selectedCell => _selectedCell;
  WordDirection get direction => _direction;
  int get elapsedSeconds => _elapsedSeconds;
  int get hintsUsed => _hintsUsed;
  int get mistakesCount => _mistakesCount;
  bool get isCompleted => _isCompleted;
  String? get recentSolvedEntryId => _recentSolvedEntryId;
  String? get recentSolvedBanner => _recentSolvedBanner;
  String? get activeErrorBanner => _activeErrorBanner;
  int get wrongMarkedCellCount => _wrongCells.length;
  bool get hasWrongCompletedWord => _wrongEntryIds.isNotEmpty;
  int get wordComboCount => _wordComboCount;
  int get maxComboInSession => _maxComboInSession;
  int get sessionComboCoins => _sessionComboCoins;
  int get sessionComboScore => _sessionComboScore;
  ComboReward get nextComboReward => ComboEconomy.rewardFor(_wordComboCount + 1);

  /// Artan dinamik ipucu bedelleri (10 -> 15 -> 25 -> 40 -> 60...)
  int get nextLetterHintCoins =>
      HintPricingCurve.coinCostFor(HintTicketType.letter, _letterPaidHints);
  int get nextWordHintCoins =>
      HintPricingCurve.coinCostFor(HintTicketType.word, _wordPaidHints);
  int get nextCheckHintCoins =>
      HintPricingCurve.coinCostFor(HintTicketType.check, _checkPaidHints);

  String? letterAt(int r, int c) => _letters['$r,$c'];
  bool isLocked(int r, int c) => _lockedCells.contains('$r,$c');
  bool isWrong(int r, int c) => _wrongCells.contains('$r,$c');

  /// Başlangıç/ipucu ile açılan kareler VEYA zaten doğru çözülmüş (yeşil)
  /// kesişen bir kelimeye ait kareler korunur; başka kelimede silme/yazma
  /// yapılırken bu doğru harfler asla silinmez veya bozulmaz.
  bool isCellProtected(int r, int c) =>
      _lockedCells.contains('$r,$c') || isCellInSolvedEntry(r, c);

  PuzzleEntry? get activeEntry =>
      puzzle.entryAt(_selectedCell.row, _selectedCell.col, _direction) ??
      puzzle.entryAt(_selectedCell.row, _selectedCell.col, _direction.opposite);

  bool isInActiveEntry(int r, int c) {
    final entry = activeEntry;
    return entry != null && entry.containsCell(r, c);
  }

  bool isEntrySolved(PuzzleEntry entry) {
    final answerChars = entry.answer.characters.toList();
    final cells = entry.cells;
    for (var i = 0; i < cells.length; i++) {
      if (_letters[cells[i].key] != answerChars[i]) return false;
    }
    return true;
  }

  bool isCellInSolvedEntry(int r, int c) {
    final across = puzzle.entryAt(r, c, WordDirection.across);
    if (across != null && _solvedEntryIds.contains(across.id)) return true;
    final down = puzzle.entryAt(r, c, WordDirection.down);
    if (down != null && _solvedEntryIds.contains(down.id)) return true;
    return false;
  }

  /// Kelimenin tüm kareleri dolmuş ama en az bir harf yanlışsa anında uyarır.
  bool isCellInWrongEntry(int r, int c) {
    final across = puzzle.entryAt(r, c, WordDirection.across);
    if (across != null && _wrongEntryIds.contains(across.id)) return true;
    final down = puzzle.entryAt(r, c, WordDirection.down);
    if (down != null && _wrongEntryIds.contains(down.id)) return true;
    return false;
  }

  bool isEntryCompletelyFilled(PuzzleEntry entry) {
    for (final cell in entry.cells) {
      if ((_letters[cell.key] ?? '').isEmpty) return false;
    }
    return true;
  }

  double get completionProgress {
    if (puzzle.activeCellCount == 0) return 0;
    var filled = 0;
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (puzzle.isActiveCell(r, c) &&
            (_letters['$r,$c']?.isNotEmpty ?? false)) {
          filled++;
        }
      }
    }
    return filled / puzzle.activeCellCount;
  }

  int get solvedWordsCount => _solvedEntryIds.length;

  void _loadInitialState() {
    for (final coord in puzzle.revealed) {
      final sol = puzzle.solutionAt(coord.row, coord.col);
      if (sol != null) {
        _letters[coord.key] = sol;
        _lockedCells.add(coord.key);
      }
    }

    if (persistSession) {
      final saved = appState.stateFor(storageKey);
      if (saved != null && !saved.completed) {
        _letters.addAll(saved.letters);
        _lockedCells.addAll(saved.lockedCells);
        _elapsedSeconds = saved.elapsedSeconds;
        _hintsUsed = saved.hintsUsed;
        _mistakesCount = saved.mistakesCount;
      }
    }

    _recomputeSolvedEntries();
    _awardedEntryIds.addAll(_solvedEntryIds);
  }

  void _selectInitialCell() {
    final ordered = puzzle.orderedEntries;
    if (ordered.isEmpty) {
      _selectedCell = const CellCoord(0, 0);
      return;
    }
    for (final entry in ordered) {
      for (final cell in entry.cells) {
        if ((_letters[cell.key] ?? '').isEmpty) {
          _selectedCell = cell;
          _direction = entry.direction;
          return;
        }
      }
    }
    _selectedCell = CellCoord(ordered.first.row, ordered.first.col);
    _direction = ordered.first.direction;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || _isCompleted) return;
      _elapsedSeconds++;
      if (persistSession && _elapsedSeconds % 10 == 0) {
        _persistProgress();
      }
      notifyListeners();
    });
  }

  void pauseTimer({bool silent = false}) {
    _timer?.cancel();
    if (persistSession) {
      _persistProgress(notify: !silent);
    }
  }

  void resumeTimer() {
    if (enableInternalTimer &&
        !_isCompleted &&
        (_timer == null || !_timer!.isActive)) {
      _startTimer();
    }
  }

  void selectCell(int r, int c) {
    if (!puzzle.isActiveCell(r, c)) return;
    appState.feedback.cellSelect();

    final coord = CellCoord(r, c);
    if (coord == _selectedCell) {
      final opp = puzzle.entryAt(r, c, _direction.opposite);
      if (opp != null) {
        _direction = _direction.opposite;
      }
    } else {
      _selectedCell = coord;
      if (puzzle.entryAt(r, c, _direction) == null) {
        final opp = puzzle.entryAt(r, c, _direction.opposite);
        if (opp != null) {
          _direction = _direction.opposite;
        }
      }
    }
    notifyListeners();
  }

  void toggleDirection() {
    final opp =
        puzzle.entryAt(_selectedCell.row, _selectedCell.col, _direction.opposite);
    if (opp != null) {
      _direction = _direction.opposite;
      appState.feedback.cellSelect();
      notifyListeners();
    } else {
      nextClue();
    }
  }

  void selectEntry(PuzzleEntry entry) {
    _direction = entry.direction;
    CellCoord? target;
    for (final cell in entry.cells) {
      if (!isCellProtected(cell.row, cell.col) &&
          (_letters[cell.key] ?? '').isEmpty) {
        target = cell;
        break;
      }
    }
    target ??= entry.cells.firstWhere(
      (cell) => !isCellProtected(cell.row, cell.col),
      orElse: () => entry.cells.first,
    );
    _selectedCell = target;
    appState.feedback.cellSelect();
    notifyListeners();
  }

  void nextClue() {
    final ordered = puzzle.orderedEntries;
    if (ordered.isEmpty) return;
    final current = activeEntry;
    final idx =
        current == null ? -1 : ordered.indexWhere((e) => e.id == current.id);
    final next = ordered[(idx + 1) % ordered.length];
    selectEntry(next);
  }

  void previousClue() {
    final ordered = puzzle.orderedEntries;
    if (ordered.isEmpty) return;
    final current = activeEntry;
    final idx =
        current == null ? 0 : ordered.indexWhere((e) => e.id == current.id);
    final prev = ordered[(idx - 1 + ordered.length) % ordered.length];
    selectEntry(prev);
  }

  Future<void> inputLetter(String raw) async {
    if (_isCompleted) return;
    final letter = TurkishText.normalizeLetter(raw, language: language);
    if (letter.isEmpty) return;

    appState.feedback.keyTap();

    var target = _selectedCell;
    if (isCellProtected(target.row, target.col)) {
      final entry = activeEntry;
      if (entry != null) {
        final idx = entry.indexOfCell(target.row, target.col);
        CellCoord? editable;
        // 1) İleri yönde boş ve korunmayan kare
        for (var i = idx + 1; i < entry.cells.length; i++) {
          final c = entry.cells[i];
          if (!isCellProtected(c.row, c.col) &&
              (_letters[c.key] ?? '').isEmpty) {
            editable = c;
            break;
          }
        }
        // 2) Kelime başından itibaren boş ve korunmayan kare
        if (editable == null) {
          for (var i = 0; i < idx; i++) {
            final c = entry.cells[i];
            if (!isCellProtected(c.row, c.col) &&
                (_letters[c.key] ?? '').isEmpty) {
              editable = c;
              break;
            }
          }
        }
        // 3) İleri veya baştan herhangi bir düzenlenebilir (korunmayan) kare
        if (editable == null) {
          for (var i = idx + 1; i < entry.cells.length; i++) {
            final c = entry.cells[i];
            if (!isCellProtected(c.row, c.col)) {
              editable = c;
              break;
            }
          }
        }
        if (editable == null) {
          for (var i = 0; i < idx; i++) {
            final c = entry.cells[i];
            if (!isCellProtected(c.row, c.col)) {
              editable = c;
              break;
            }
          }
        }
        if (editable == null) {
          _advanceAfterEdit(target);
          notifyListeners();
          return;
        }
        target = editable;
        _selectedCell = editable;
      } else {
        return;
      }
    }

    _letters[target.key] = letter;
    _wrongCells.remove(target.key);

    final newlySolvedList = _checkNewlySolvedEntries(target);
    _checkCompletedWrongEntries(target);

    if (newlySolvedList.isNotEmpty) {
      _clearErrorBanner();
      await _grantComboForSolvedEntries(newlySolvedList);
    }

    if (_isBoardCompletelyCorrect()) {
      await _finishPuzzle();
      return;
    }

    _advanceAfterEdit(target);
    notifyListeners();
    if (persistSession) {
      unawaited(_persistProgress());
    }
  }

  Future<void> _grantComboForSolvedEntries(List<PuzzleEntry> solvedList) async {
    var totalCoins = 0;
    var totalScore = 0;
    PuzzleEntry? lastFlash;
    final freshEnglish = <PuzzleEntry>[];

    for (final entry in solvedList) {
      lastFlash = entry;
      if (language == 'en') {
        freshEnglish.add(entry);
      }
      if (_awardedEntryIds.contains(entry.id)) continue;
      _awardedEntryIds.add(entry.id);
      _wordComboCount++;
      if (_wordComboCount > _maxComboInSession) {
        _maxComboInSession = _wordComboCount;
      }
      final reward = ComboEconomy.rewardFor(_wordComboCount);
      totalCoins += reward.coins;
      totalScore += reward.score;
    }

    if (freshEnglish.isNotEmpty) {
      await appState.recordLearnedEnglishWords(freshEnglish);
    }

    if (totalCoins > 0 || totalScore > 0) {
      _sessionComboCoins += totalCoins;
      _sessionComboScore += totalScore;
      if (persistSession) {
        await appState.awardComboWord(
          comboCount: _wordComboCount,
          coinsEarned: totalCoins,
          scoreEarned: totalScore,
        );
      }
      onWordSolved?.call(_wordComboCount, totalCoins, totalScore);

      if (lastFlash != null) {
        final label = _wordComboCount >= 4
            ? '$_wordComboCount× SÜPER KOMBO! +$totalCoins Altın • +$totalScore Puan'
            : _wordComboCount >= 2
                ? '$_wordComboCount× KOMBO! +$totalCoins Altın • +$totalScore Puan'
                : 'Doğru! +$totalCoins Altın • +$totalScore Puan';
        _triggerWordSolvedFlash(lastFlash.id, banner: label);
      }
      if (_wordComboCount >= 2) {
        appState.feedback.comboSolved();
      } else {
        appState.feedback.wordSolved();
      }
    } else if (lastFlash != null) {
      _triggerWordSolvedFlash(lastFlash.id, banner: 'Süper! Kelime Doğru!');
      appState.feedback.wordSolved();
    }
  }

  void backspace() {
    if (_isCompleted) return;
    appState.feedback.backspaceTap();

    final curKey = _selectedCell.key;
    if (!isCellProtected(_selectedCell.row, _selectedCell.col) &&
        (_letters[curKey]?.isNotEmpty ?? false)) {
      _letters.remove(curKey);
      _wrongCells.remove(curKey);
      _recomputeSolvedEntries();
      _recomputeWrongEntries();
      notifyListeners();
      if (persistSession) unawaited(_persistProgress());
      return;
    }

    final entry = activeEntry;
    if (entry != null) {
      final idx = entry.indexOfCell(_selectedCell.row, _selectedCell.col);
      // Geriye doğru tararken kilitli veya çözülmüş kesişen kelime harflerini
      // kesinlikle atla; yalnızca düzenlenebilir (korunmayan) harfleri sil.
      for (var i = idx - 1; i >= 0; i--) {
        final prevCell = entry.cells[i];
        if (!isCellProtected(prevCell.row, prevCell.col)) {
          _selectedCell = prevCell;
          _letters.remove(prevCell.key);
          _wrongCells.remove(prevCell.key);
          _recomputeSolvedEntries();
          _recomputeWrongEntries();
          notifyListeners();
          if (persistSession) unawaited(_persistProgress());
          return;
        }
      }
    }
  }

  /// Sil tuşuna uzun basıldığında aktif kelimedeki yalnızca düzenlenebilir
  /// harfleri temizler; çözülmüş kesişen kelimelerin doğru harflerini korur.
  void clearActiveWordEditableCells() {
    if (_isCompleted) return;
    final entry = activeEntry;
    if (entry == null) return;

    var removedAny = false;
    CellCoord? firstEditable;
    for (final cell in entry.cells) {
      if (!isCellProtected(cell.row, cell.col)) {
        firstEditable ??= cell;
        if (_letters.remove(cell.key) != null) {
          removedAny = true;
        }
        _wrongCells.remove(cell.key);
      }
    }

    if (removedAny || firstEditable != null) {
      if (firstEditable != null) {
        _selectedCell = firstEditable;
      }
      appState.feedback.backspaceTap();
      _recomputeSolvedEntries();
      _recomputeWrongEntries();
      notifyListeners();
      if (persistSession) unawaited(_persistProgress());
    }
  }

  Future<HintFeedback> revealSelectedCell() async {
    if (_isCompleted) {
      return const HintFeedback(
        HintStatus.nothingToDo,
        'Bulmaca zaten tamamlandı.',
      );
    }

    CellCoord? target;
    final selSol = puzzle.solutionAt(_selectedCell.row, _selectedCell.col);
    if (!isCellProtected(_selectedCell.row, _selectedCell.col) &&
        _letters[_selectedCell.key] != selSol) {
      target = _selectedCell;
    } else {
      final entry = activeEntry;
      if (entry != null) {
        for (final cell in entry.cells) {
          final sol = puzzle.solutionAt(cell.row, cell.col);
          if (!isCellProtected(cell.row, cell.col) &&
              _letters[cell.key] != sol) {
            target = cell;
            break;
          }
        }
      }
    }

    if (target == null) {
      return const HintFeedback(
        HintStatus.nothingToDo,
        'Bu kelimedeki tüm harfler zaten doğru!',
      );
    }

    final charge = await appState.useEscalatingHint(
      HintTicketType.letter,
      _letterPaidHints,
    );
    if (!charge.paid) {
      appState.feedback.errorPulse();
      final needScore = HintPricingCurve.scoreCostFor(
        HintTicketType.letter,
        _letterPaidHints,
      );
      return HintFeedback(
        HintStatus.insufficientCoins,
        'Yeterli bakiye yok (${charge.amountPaid} altın veya $needScore puan gerekli).',
      );
    }

    if (!charge.usedTicket) {
      _letterPaidHints++;
    }

    final sol = puzzle.solutionAt(target.row, target.col)!;
    _letters[target.key] = sol;
    _lockedCells.add(target.key);
    _wrongCells.remove(target.key);
    _selectedCell = target;
    _hintsUsed++;
    _wordComboCount = 0;

    final newlySolved = _checkNewlySolvedEntries(target);
    if (language == 'en' && newlySolved.isNotEmpty) {
      await appState.recordLearnedEnglishWords(newlySolved);
    }
    for (final e in newlySolved) {
      _awardedEntryIds.add(e.id);
    }
    if (newlySolved.isNotEmpty) {
      _triggerWordSolvedFlash(newlySolved.first.id, banner: 'Kelime Tamamlandı!');
    }

    if (_isBoardCompletelyCorrect()) {
      await _finishPuzzle();
      return const HintFeedback(
        HintStatus.ok,
        'Son harf açıldı, bulmaca tamamlandı!',
      );
    }

    _advanceAfterEdit(target);
    appState.feedback.hintUsed();
    notifyListeners();
    if (persistSession) unawaited(_persistProgress());

    final nextPrice = nextLetterHintCoins;
    final msg = charge.usedTicket
        ? 'Harf açıldı! (1 ipucu hakkı kullanıldı)'
        : charge.usedScore
            ? 'Harf açıldı! (-${charge.amountPaid} puan • Sonraki: $nextPrice altın)'
            : 'Harf açıldı! (-${charge.amountPaid} altın • Sonraki: $nextPrice altın)';
    return HintFeedback(HintStatus.ok, msg);
  }

  Future<HintFeedback> revealActiveWord() async {
    if (_isCompleted) {
      return const HintFeedback(
        HintStatus.nothingToDo,
        'Bulmaca zaten tamamlandı.',
      );
    }
    final entry = activeEntry;
    if (entry == null) {
      return const HintFeedback(HintStatus.nothingToDo, 'Önce bir kelime seçin.');
    }
    if (isEntrySolved(entry)) {
      return const HintFeedback(
        HintStatus.nothingToDo,
        'Seçili kelime zaten doğru çözülmüş!',
      );
    }

    final charge = await appState.useEscalatingHint(
      HintTicketType.word,
      _wordPaidHints,
    );
    if (!charge.paid) {
      appState.feedback.errorPulse();
      final needScore = HintPricingCurve.scoreCostFor(
        HintTicketType.word,
        _wordPaidHints,
      );
      return HintFeedback(
        HintStatus.insufficientCoins,
        'Yeterli bakiye yok (${charge.amountPaid} altın veya $needScore puan gerekli).',
      );
    }

    if (!charge.usedTicket) {
      _wordPaidHints++;
    }

    final chars = entry.answer.characters.toList();
    final cells = entry.cells;
    for (var i = 0; i < cells.length; i++) {
      _letters[cells[i].key] = chars[i];
      _lockedCells.add(cells[i].key);
      _wrongCells.remove(cells[i].key);
    }
    _hintsUsed += 2;
    _wordComboCount = 0;
    _recomputeSolvedEntries();
    _awardedEntryIds.addAll(_solvedEntryIds);
    if (language == 'en') {
      await appState.recordLearnedEnglishWords([entry]);
    }
    _triggerWordSolvedFlash(entry.id, banner: 'Kelime Açıldı!');

    if (_isBoardCompletelyCorrect()) {
      await _finishPuzzle();
      return const HintFeedback(
        HintStatus.ok,
        'Kelime açıldı ve bulmaca tamamlandı!',
      );
    }

    _jumpToNextIncompleteWord();
    appState.feedback.hintUsed();
    notifyListeners();
    if (persistSession) unawaited(_persistProgress());

    final nextPrice = nextWordHintCoins;
    final msg = charge.usedTicket
        ? 'Kelime açıldı! (1 ipucu hakkı kullanıldı)'
        : charge.usedScore
            ? 'Kelime açıldı! (-${charge.amountPaid} puan • Sonraki: $nextPrice altın)'
            : 'Kelime açıldı! (-${charge.amountPaid} altın • Sonraki: $nextPrice altın)';
    return HintFeedback(HintStatus.ok, msg);
  }

  Future<HintFeedback> checkMistakes() async {
    if (_isCompleted) {
      return const HintFeedback(
        HintStatus.nothingToDo,
        'Bulmaca zaten tamamlandı.',
      );
    }

    final editableFilled = <CellCoord>[];
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        if (!puzzle.isActiveCell(r, c)) continue;
        final key = '$r,$c';
        if (!isCellProtected(r, c) && (_letters[key]?.isNotEmpty ?? false)) {
          editableFilled.add(CellCoord(r, c));
        }
      }
    }

    if (editableFilled.isEmpty) {
      return const HintFeedback(
        HintStatus.nothingToDo,
        'Kontrol edilecek harf henüz girilmedi.',
      );
    }

    final charge = await appState.useEscalatingHint(
      HintTicketType.check,
      _checkPaidHints,
    );
    if (!charge.paid) {
      appState.feedback.errorPulse();
      return HintFeedback(
        HintStatus.insufficientCoins,
        'Yeterli bakiye yok (${charge.amountPaid} altın gerekli).',
      );
    }

    if (!charge.usedTicket) {
      _checkPaidHints++;
    }

    _wrongCells.clear();
    var wrongCount = 0;
    for (final cell in editableFilled) {
      final sol = puzzle.solutionAt(cell.row, cell.col);
      if (_letters[cell.key] != sol) {
        _wrongCells.add(cell.key);
        wrongCount++;
      }
    }

    if (wrongCount > 0) {
      _mistakesCount += wrongCount;
      _wordComboCount = 0;
      _recomputeWrongEntries();
      _triggerErrorBanner(
        '$wrongCount hatalı harf kırmızı ile işaretlendi — üzerine yazarak düzelt',
      );
      appState.feedback.errorPulse();
      notifyListeners();
      if (persistSession) unawaited(_persistProgress());
      return HintFeedback(
        HintStatus.ok,
        '$wrongCount hatalı harf kırmızı ile işaretlendi.',
      );
    } else {
      _wrongEntryIds.clear();
      _clearErrorBanner();
      appState.feedback.wordSolved();
      notifyListeners();
      return HintFeedback(
        HintStatus.ok,
        charge.usedTicket
            ? 'Harika! Tüm harfler doğru (1 kontrol hakkı kullanıldı).'
            : 'Harika! Yazdığın tüm harfler doğru görünüyor.',
      );
    }
  }

  Future<void> resetBoard() async {
    _letters.clear();
    _lockedCells.clear();
    _wrongCells.clear();
    _wrongEntryIds.clear();
    _clearErrorBanner();
    _solvedEntryIds.clear();
    _awardedEntryIds.clear();
    _isCompleted = false;
    _elapsedSeconds = 0;
    _hintsUsed = 0;
    _letterPaidHints = 0;
    _wordPaidHints = 0;
    _checkPaidHints = 0;
    _mistakesCount = 0;
    _wordComboCount = 0;
    _maxComboInSession = 0;
    _sessionComboCoins = 0;
    _sessionComboScore = 0;

    for (final coord in puzzle.revealed) {
      final sol = puzzle.solutionAt(coord.row, coord.col);
      if (sol != null) {
        _letters[coord.key] = sol;
        _lockedCells.add(coord.key);
      }
    }

    _recomputeSolvedEntries();
    _awardedEntryIds.addAll(_solvedEntryIds);
    _selectInitialCell();
    if (enableInternalTimer) _startTimer();
    notifyListeners();
    if (persistSession) await _persistProgress();
  }

  void _advanceAfterEdit(CellCoord edited) {
    final entry = activeEntry;
    if (entry != null) {
      final idx = entry.indexOfCell(edited.row, edited.col);
      for (var i = idx + 1; i < entry.cells.length; i++) {
        final cell = entry.cells[i];
        if (!isCellProtected(cell.row, cell.col) &&
            (_letters[cell.key] ?? '').isEmpty) {
          _selectedCell = cell;
          return;
        }
      }
      for (var i = 0; i < idx; i++) {
        final cell = entry.cells[i];
        if (!isCellProtected(cell.row, cell.col) &&
            (_letters[cell.key] ?? '').isEmpty) {
          _selectedCell = cell;
          return;
        }
      }
      if (isEntrySolved(entry)) {
        _jumpToNextIncompleteWord();
        return;
      }
      for (var i = idx + 1; i < entry.cells.length; i++) {
        final cell = entry.cells[i];
        if (!isCellProtected(cell.row, cell.col)) {
          _selectedCell = cell;
          return;
        }
      }
    }
  }

  void _jumpToNextIncompleteWord() {
    final ordered = puzzle.orderedEntries;
    if (ordered.isEmpty) return;
    final current = activeEntry;
    final startIdx = current == null
        ? 0
        : (ordered.indexWhere((e) => e.id == current.id) + 1) % ordered.length;

    for (var offset = 0; offset < ordered.length; offset++) {
      final candidate = ordered[(startIdx + offset) % ordered.length];
      if (!isEntrySolved(candidate)) {
        _direction = candidate.direction;
        for (final cell in candidate.cells) {
          if (!isCellProtected(cell.row, cell.col) &&
              (_letters[cell.key] ?? '').isEmpty) {
            _selectedCell = cell;
            return;
          }
        }
        _selectedCell = candidate.cells.firstWhere(
          (c) => !isCellProtected(c.row, c.col),
          orElse: () => candidate.cells.first,
        );
        return;
      }
    }
  }

  List<PuzzleEntry> _checkNewlySolvedEntries(CellCoord coord) {
    final newly = <PuzzleEntry>[];
    for (final dir in [WordDirection.across, WordDirection.down]) {
      final entry = puzzle.entryAt(coord.row, coord.col, dir);
      if (entry == null) continue;
      final solved = isEntrySolved(entry);
      if (solved && !_solvedEntryIds.contains(entry.id)) {
        _solvedEntryIds.add(entry.id);
        newly.add(entry);
      } else if (!solved) {
        _solvedEntryIds.remove(entry.id);
      }
    }
    return newly;
  }

  void _recomputeSolvedEntries() {
    _solvedEntryIds.clear();
    for (final entry in puzzle.entries) {
      if (isEntrySolved(entry)) {
        _solvedEntryIds.add(entry.id);
      }
    }
  }

  void _recomputeWrongEntries() {
    _wrongEntryIds.clear();
    for (final entry in puzzle.entries) {
      if (isEntryCompletelyFilled(entry) && !isEntrySolved(entry)) {
        _wrongEntryIds.add(entry.id);
      }
    }
  }

  void _checkCompletedWrongEntries(CellCoord coord) {
    var worstWrongLetters = 0;
    for (final dir in [WordDirection.across, WordDirection.down]) {
      final entry = puzzle.entryAt(coord.row, coord.col, dir);
      if (entry == null) continue;
      if (isEntryCompletelyFilled(entry) && !isEntrySolved(entry)) {
        _wrongEntryIds.add(entry.id);
        final chars = entry.answer.characters.toList();
        var wrongInEntry = 0;
        for (var i = 0; i < entry.cells.length; i++) {
          if (_letters[entry.cells[i].key] != chars[i]) wrongInEntry++;
        }
        if (wrongInEntry > worstWrongLetters) {
          worstWrongLetters = wrongInEntry;
        }
      } else {
        _wrongEntryIds.remove(entry.id);
      }
    }

    if (worstWrongLetters > 0) {
      _wordComboCount = 0;
      appState.feedback.errorPulse();
      _triggerErrorBanner(
        'Hatalı kelime! $worstWrongLetters harf yanlış — düzelt veya Kontrol et',
      );
    }
  }

  void _triggerErrorBanner(String message) {
    _errorBannerTimer?.cancel();
    _activeErrorBanner = message;
    _errorBannerTimer = Timer(const Duration(milliseconds: 2800), () {
      if (_disposed) return;
      _activeErrorBanner = null;
      notifyListeners();
    });
  }

  void _clearErrorBanner() {
    _errorBannerTimer?.cancel();
    _activeErrorBanner = null;
  }

  void _triggerWordSolvedFlash(String entryId, {required String banner}) {
    _flashTimer?.cancel();
    _recentSolvedEntryId = entryId;
    _recentSolvedBanner = banner;
    _flashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (_disposed) return;
      _recentSolvedEntryId = null;
      _recentSolvedBanner = null;
      notifyListeners();
    });
  }

  bool _isBoardCompletelyCorrect() {
    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        final sol = puzzle.solutionAt(r, c);
        if (sol != null && _letters['$r,$c'] != sol) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _finishPuzzle() async {
    _isCompleted = true;
    _timer?.cancel();
    _wrongCells.clear();
    _wrongEntryIds.clear();
    _clearErrorBanner();
    _recomputeSolvedEntries();
    appState.feedback.puzzleSolved();

    if (language == 'en') {
      await appState.recordLearnedEnglishWords(puzzle.entries);
    }

    if (persistSession) {
      final reward = await appState.completePuzzle(
        storageKey: storageKey,
        finalState: _buildSaveState(completed: true),
        isDaily: isDaily,
        rewardMultiplier: rewardMultiplier,
        sessionComboCoins: _sessionComboCoins,
        sessionComboScore: _sessionComboScore,
        maxComboInSession: _maxComboInSession,
      );
      notifyListeners();
      onPuzzleCompleted?.call(reward);
    } else {
      notifyListeners();
      onPuzzleCompleted?.call(
        CompletionReward(
          stars: 3,
          coinsEarned: 20,
          comboCoinsEarned: _sessionComboCoins,
          scoreEarned: 100 + _sessionComboScore,
          maxCombo: _maxComboInSession,
          elapsedSeconds: _elapsedSeconds,
          isFirstCompletion: true,
          newDailyStreak: null,
        ),
      );
    }
  }

  PuzzleSaveState _buildSaveState({required bool completed}) {
    return PuzzleSaveState(
      puzzleId: puzzle.id,
      letters: Map<String, String>.from(_letters),
      lockedCells: Set<String>.from(_lockedCells),
      elapsedSeconds: _elapsedSeconds,
      hintsUsed: _hintsUsed,
      mistakesCount: _mistakesCount,
      completed: completed,
    );
  }

  Future<void> _persistProgress({bool notify = true}) async {
    if (_disposed || _isCompleted || !persistSession) return;
    await appState.savePuzzleProgress(
      storageKey,
      _buildSaveState(completed: false),
      notify: notify,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _flashTimer?.cancel();
    _errorBannerTimer?.cancel();
    super.dispose();
  }
}
