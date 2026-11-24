import 'package:flutter/foundation.dart';
import '../models/background_models.dart';
import '../models/puzzle_models.dart';
import '../services/feedback_service.dart';
import '../services/puzzle_repository.dart';
import '../services/storage_service.dart';
import '../utils/turkish_text.dart';

class CompletionReward {
  const CompletionReward({
    required this.stars,
    required this.coinsEarned,
    required this.elapsedSeconds,
    required this.isFirstCompletion,
    required this.newDailyStreak,
    this.newlyUnlockedBackgrounds = const [],
  });

  final int stars;
  final int coinsEarned;
  final int elapsedSeconds;
  final bool isFirstCompletion;
  final int? newDailyStreak;
  final List<AppBackground> newlyUnlockedBackgrounds;
}

class BackgroundUnlockResult {
  const BackgroundUnlockResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AppState extends ChangeNotifier {
  AppState({
    PuzzleRepository? repository,
    StorageService? storage,
    FeedbackService? feedback,
  })  : _repository = repository ?? PuzzleRepository(),
        _storage = storage ?? StorageService(),
        feedback = feedback ?? FeedbackService();

  static const int letterHintCost = 15;
  static const int wordHintCost = 40;
  static const int checkMistakesCost = 10;

  final PuzzleRepository _repository;
  final StorageService _storage;
  final FeedbackService feedback;

  bool _loading = true;
  String? _error;
  List<ConceptPack> _packs = const [];
  DailyBank? _dailyBank;
  PlayerProfile _profile = const PlayerProfile();

  bool get isLoading => _loading;
  String? get error => _error;
  List<ConceptPack> get packs => _packs;
  DailyBank? get dailyBank => _dailyBank;
  PlayerProfile get profile => _profile;

  int get coins => _profile.coins;
  int get dailyStreak => _profile.dailyStreak;
  bool get soundEnabled => _profile.soundEnabled;
  bool get hapticsEnabled => _profile.hapticsEnabled;

  String get todayDateKey => TurkishText.dateKey(DateTime.now());
  String get todayDailyStorageKey => 'daily_$todayDateKey';

  CrosswordPuzzle? get todayDailyPuzzle {
    final bank = _dailyBank;
    if (bank == null || bank.puzzles.isEmpty) return null;
    return bank.puzzleForDate(DateTime.now());
  }

  bool get isTodayDailyCompleted =>
      _profile.completedDailyDates.contains(todayDateKey);

  Future<void> initialize() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.loadAll(),
        _storage.loadProfile(),
      ]);
      final content = results[0] as LoadedPuzzleContent;
      final loadedProfile = results[1] as PlayerProfile;

      _packs = content.packs;
      _dailyBank = content.dailyBank;
      _profile = loadedProfile;
      _syncFeedbackPrefs();
    } catch (e) {
      _error = 'Bulmacalar yüklenirken bir sorun oluştu: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _syncFeedbackPrefs() {
    feedback.soundEnabled = _profile.soundEnabled;
    feedback.hapticsEnabled = _profile.hapticsEnabled;
  }

  PuzzleSaveState? stateFor(String storageKey) =>
      _profile.puzzleStates[storageKey];

  bool isLevelCompleted(CrosswordPuzzle puzzle) =>
      _profile.puzzleStates[puzzle.id]?.completed ?? false;

  bool isLevelUnlocked(ConceptPack pack, int levelIndex) {
    if (levelIndex <= 0) return true;
    if (levelIndex >= pack.levels.length) return false;
    return isLevelCompleted(pack.levels[levelIndex - 1]);
  }

  int completedCountForPack(ConceptPack pack) =>
      pack.levels.where(isLevelCompleted).length;

  int starsForPack(ConceptPack pack) {
    var total = 0;
    for (final lvl in pack.levels) {
      total += _profile.puzzleStates[lvl.id]?.stars ?? 0;
    }
    return total;
  }

  int maxStarsForPack(ConceptPack pack) => pack.levels.length * 3;

  int get totalSolvedPuzzles =>
      _profile.puzzleStates.values.where((s) => s.completed).length;

  int get totalStars => _profile.puzzleStates.values
      .fold<int>(0, (sum, s) => sum + s.stars);

  int get totalWordsSolved {
    var count = 0;
    for (final pack in _packs) {
      for (final lvl in pack.levels) {
        if (isLevelCompleted(lvl)) {
          count += lvl.entries.length;
        }
      }
    }
    count += _profile.completedDailyDates.length * 7;
    return count;
  }

  int? get fastestSolveSeconds {
    int? best;
    for (final state in _profile.puzzleStates.values) {
      if (state.completed && state.bestTimeSeconds != null) {
        if (best == null || state.bestTimeSeconds! < best) {
          best = state.bestTimeSeconds;
        }
      }
    }
    return best;
  }

  Future<void> savePuzzleProgress(
    String storageKey,
    PuzzleSaveState state,
  ) async {
    final existing = _profile.puzzleStates[storageKey];
    // Preserve prior completion / star record if replaying an already solved puzzle
    final merged = existing != null && existing.completed && !state.completed
        ? state.copyWith(
            completed: true,
            stars: existing.stars,
            bestTimeSeconds: existing.bestTimeSeconds,
          )
        : state;

    final updatedMap = Map<String, PuzzleSaveState>.from(_profile.puzzleStates);
    updatedMap[storageKey] = merged;
    _profile = _profile.copyWith(puzzleStates: updatedMap);
    notifyListeners();
    await _storage.saveProfile(_profile);
  }

  Future<bool> spendCoins(int amount) async {
    if (_profile.coins < amount) return false;
    _profile = _profile.copyWith(coins: _profile.coins - amount);
    notifyListeners();
    await _storage.saveProfile(_profile);
    return true;
  }

  AppBackground get selectedBackground =>
      BackgroundCatalog.byId(_profile.selectedBackgroundId);

  int backgroundMetricValue(UnlockMetric metric) {
    switch (metric) {
      case UnlockMetric.none:
        return 0;
      case UnlockMetric.solvedPuzzles:
        return totalSolvedPuzzles;
      case UnlockMetric.totalStars:
        return totalStars;
      case UnlockMetric.dailyStreak:
        return dailyStreak;
    }
  }

  bool isBackgroundUnlocked(AppBackground bg) {
    if (bg.isFreeStarter) return true;
    if (_profile.unlockedBackgroundIds.contains(bg.id)) return true;
    if (bg.unlockMetric != UnlockMetric.none &&
        backgroundMetricValue(bg.unlockMetric) >= bg.unlockTarget) {
      return true;
    }
    return false;
  }

  int get unlockedBackgroundCount =>
      BackgroundCatalog.all.where(isBackgroundUnlocked).length;

  Future<bool> selectBackground(String id) async {
    final bg = BackgroundCatalog.byId(id);
    if (!isBackgroundUnlocked(bg)) return false;
    _profile = _profile.copyWith(selectedBackgroundId: bg.id);
    feedback.cellSelect();
    notifyListeners();
    await _storage.saveProfile(_profile);
    return true;
  }

  Future<BackgroundUnlockResult> unlockBackgroundWithCoins(
    AppBackground bg,
  ) async {
    if (isBackgroundUnlocked(bg)) {
      await selectBackground(bg.id);
      return BackgroundUnlockResult(
        success: true,
        message: '${bg.name} aktif edildi!',
      );
    }
    if (_profile.coins < bg.coinCost) {
      feedback.errorPulse();
      return BackgroundUnlockResult(
        success: false,
        message: 'Yeterli altının yok (${bg.coinCost} altın gerekli).',
      );
    }
    final updatedUnlocks = Set<String>.from(_profile.unlockedBackgroundIds)
      ..add(bg.id);
    _profile = _profile.copyWith(
      coins: _profile.coins - bg.coinCost,
      unlockedBackgroundIds: updatedUnlocks,
      selectedBackgroundId: bg.id,
    );
    feedback.wordSolved();
    notifyListeners();
    await _storage.saveProfile(_profile);
    return BackgroundUnlockResult(
      success: true,
      message: '${bg.name} açıldı ve uygulandı!',
    );
  }

  Future<CompletionReward> completePuzzle({
    required String storageKey,
    required PuzzleSaveState finalState,
    required bool isDaily,
  }) async {
    final beforeUnlocked = BackgroundCatalog.all
        .where(isBackgroundUnlocked)
        .map((b) => b.id)
        .toSet();

    final existing = _profile.puzzleStates[storageKey];
    final wasCompleted = existing?.completed ?? false;

    final stars = calculateStars(
      hintsUsed: finalState.hintsUsed,
      mistakesCount: finalState.mistakesCount,
    );

    final baseReward = stars * 10 + 10; // 20 / 30 / 40 coins
    var coinsEarned = 0;
    if (!wasCompleted) {
      coinsEarned = isDaily ? baseReward * 2 : baseReward;
    } else if (stars > (existing?.stars ?? 0)) {
      coinsEarned = 10;
    }

    final bestTime = existing?.bestTimeSeconds == null
        ? finalState.elapsedSeconds
        : (finalState.elapsedSeconds < existing!.bestTimeSeconds!
            ? finalState.elapsedSeconds
            : existing.bestTimeSeconds!);

    final bestStars =
        stars > (existing?.stars ?? 0) ? stars : (existing?.stars ?? stars);

    final completedState = finalState.copyWith(
      completed: true,
      stars: bestStars,
      bestTimeSeconds: bestTime,
    );

    final updatedMap = Map<String, PuzzleSaveState>.from(_profile.puzzleStates);
    updatedMap[storageKey] = completedState;

    var newStreak = _profile.dailyStreak;
    String? newLastDaily = _profile.lastDailyDate;
    final updatedDailyDates = Set<String>.from(_profile.completedDailyDates);
    int? streakAwarded;

    if (isDaily) {
      final today = todayDateKey;
      if (!updatedDailyDates.contains(today)) {
        updatedDailyDates.add(today);
        final yesterday =
            TurkishText.dateKey(DateTime.now().subtract(const Duration(days: 1)));
        if (_profile.lastDailyDate == yesterday) {
          newStreak = _profile.dailyStreak + 1;
        } else {
          newStreak = 1;
        }
        newLastDaily = today;
        streakAwarded = newStreak;
      }
    }

    _profile = _profile.copyWith(
      coins: _profile.coins + coinsEarned,
      dailyStreak: newStreak,
      lastDailyDate: newLastDaily,
      completedDailyDates: updatedDailyDates,
      puzzleStates: updatedMap,
    );

    // Check any progression-earned backgrounds that just unlocked
    final newlyUnlocked = <AppBackground>[];
    final updatedUnlocks = Set<String>.from(_profile.unlockedBackgroundIds);
    for (final bg in BackgroundCatalog.all) {
      if (!beforeUnlocked.contains(bg.id) && isBackgroundUnlocked(bg)) {
        newlyUnlocked.add(bg);
        updatedUnlocks.add(bg.id);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      _profile = _profile.copyWith(unlockedBackgroundIds: updatedUnlocks);
    }

    notifyListeners();
    await _storage.saveProfile(_profile);

    return CompletionReward(
      stars: stars,
      coinsEarned: coinsEarned,
      elapsedSeconds: finalState.elapsedSeconds,
      isFirstCompletion: !wasCompleted,
      newDailyStreak: streakAwarded,
      newlyUnlockedBackgrounds: newlyUnlocked,
    );
  }

  static int calculateStars({
    required int hintsUsed,
    required int mistakesCount,
  }) {
    if (hintsUsed == 0 && mistakesCount <= 1) return 3;
    if (hintsUsed <= 2) return 2;
    return 1;
  }

  Future<void> toggleSound(bool enabled) async {
    _profile = _profile.copyWith(soundEnabled: enabled);
    _syncFeedbackPrefs();
    notifyListeners();
    await _storage.saveProfile(_profile);
  }

  Future<void> toggleHaptics(bool enabled) async {
    _profile = _profile.copyWith(hapticsEnabled: enabled);
    _syncFeedbackPrefs();
    notifyListeners();
    await _storage.saveProfile(_profile);
  }

  Future<void> resetAllProgress() async {
    _profile = PlayerProfile(
      soundEnabled: _profile.soundEnabled,
      hapticsEnabled: _profile.hapticsEnabled,
    );
    notifyListeners();
    await _storage.saveProfile(_profile);
  }
}
