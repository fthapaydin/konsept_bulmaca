import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/economy/hint_pricing.dart';
import '../core/models/notebook_models.dart';
import '../core/models/profile_merger.dart';
import '../models/background_models.dart';
import '../models/puzzle_models.dart';
import '../models/retention_models.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/feedback_service.dart';
import '../services/puzzle_repository.dart';
import '../services/reward_ad_service.dart';
import '../services/storage_service.dart';
import '../utils/turkish_text.dart';

class CompletionReward {
  const CompletionReward({
    required this.stars,
    required this.coinsEarned,
    required this.comboCoinsEarned,
    required this.scoreEarned,
    required this.maxCombo,
    required this.elapsedSeconds,
    required this.isFirstCompletion,
    required this.newDailyStreak,
    this.newlyUnlockedBackgrounds = const [],
  });

  final int stars;
  final int coinsEarned;
  final int comboCoinsEarned;
  final int scoreEarned;
  final int maxCombo;
  final int elapsedSeconds;
  final bool isFirstCompletion;
  final int? newDailyStreak;
  final List<AppBackground> newlyUnlockedBackgrounds;

  int get totalCoinsWon => coinsEarned + comboCoinsEarned;
}

class ActionOutcome {
  const ActionOutcome({required this.success, required this.message});

  final bool success;
  final String message;
}

class HintChargeResult {
  const HintChargeResult({
    required this.paid,
    required this.usedTicket,
    required this.usedScore,
    required this.amountPaid,
  });

  final bool paid;
  final bool usedTicket;
  final bool usedScore;
  final int amountPaid;
}

class AppState extends ChangeNotifier {
  AppState({
    PuzzleRepository? repository,
    StorageService? storage,
    FeedbackService? feedback,
    RewardAdService? rewardAdService,
    AuthService? authService,
    CloudSyncService? cloudSyncService,
  })  : _repository = repository ?? PuzzleRepository(),
        _storage = storage ?? StorageService(),
        feedback = feedback ?? FeedbackService(),
        rewardAdService = rewardAdService ?? const PlaceholderRewardAdService(),
        _auth = authService ?? FirebaseGoogleAuthService(),
        _cloudSync = cloudSyncService ?? FirestoreCloudSyncService();

  static const int letterHintCost = 10;
  static const int wordHintCost = 25;
  static const int checkMistakesCost = 10;

  final PuzzleRepository _repository;
  final StorageService _storage;
  final FeedbackService feedback;
  final RewardAdService rewardAdService;
  final AuthService _auth;
  final CloudSyncService _cloudSync;

  bool _loading = true;
  String? _error;
  List<ConceptPack> _packs = const [];
  DailyBank? _dailyBank;
  MegaBank? _megaBank;
  SprintBank? _sprintBank;
  PlayerProfile _profile = const PlayerProfile();

  AuthUserInfo? _signedInUser;
  bool _authBusy = false;
  DateTime? _lastCloudSync;
  bool _backupBannerDismissed = false;
  Timer? _cloudPushTimer;

  bool get isLoading => _loading;
  String? get error => _error;
  List<ConceptPack> get packs => _packs;
  DailyBank? get dailyBank => _dailyBank;
  MegaBank? get megaBank => _megaBank;
  SprintBank? get sprintBank => _sprintBank;
  PlayerProfile get profile => _profile;

  AuthUserInfo? get signedInUser => _signedInUser;
  bool get isSignedIn => _signedInUser != null;
  bool get isCloudAvailable => _auth.isCloudAvailable;
  bool get isAuthBusy => _authBusy;
  DateTime? get lastCloudSync => _lastCloudSync;
  bool get shouldShowCloudBackupBanner =>
      !isSignedIn && !_backupBannerDismissed && totalSolvedPuzzles >= 2;

  int get coins => _profile.coins;
  int get score => _profile.score;
  int get bestCombo => _profile.bestCombo;
  int get bestSprintScore => _profile.bestSprintScore;
  int get bestSprintPuzzles => _profile.bestSprintPuzzles;
  int get letterHintTickets => _profile.letterHintTickets;
  int get wordHintTickets => _profile.wordHintTickets;
  int get checkHintTickets => _profile.checkHintTickets;
  int get dailyStreak => _profile.dailyStreak;
  bool get soundEnabled => _profile.soundEnabled;
  bool get hapticsEnabled => _profile.hapticsEnabled;

  List<LearnedWord> get learnedEnglishWords {
    final list = _profile.learnedEnglishWords.values.toList();
    list.sort((a, b) => b.firstLearnedIso.compareTo(a.firstLearnedIso));
    return list;
  }

  int get learnedEnglishCount => _profile.learnedEnglishWords.length;

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
      _megaBank = content.megaBank;
      _sprintBank = content.sprintBank;
      _profile = loadedProfile;
      _syncFeedbackPrefs();

      // Misafir açılışını ASLA bloklamadan opsiyonel Firebase oturumunu kontrol et
      await _auth.initialize();
      _signedInUser = _auth.currentUser;
      if (_signedInUser != null) {
        unawaited(_pullAndMergeCloudSilently(_signedInUser!.uid));
      }
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

  bool isMegaUnlocked(MegaPuzzleItem item) {
    if (_profile.unlockedMegaIds.contains(item.puzzle.id)) return true;
    return totalSolvedPuzzles >= item.requiredSolved;
  }

  int get completedMegaCount {
    final bank = _megaBank;
    if (bank == null) return 0;
    return bank.items.where((i) => isLevelCompleted(i.puzzle)).length;
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
    if (_megaBank != null) {
      for (final item in _megaBank!.items) {
        if (isLevelCompleted(item.puzzle)) {
          count += item.puzzle.entries.length;
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
    PuzzleSaveState state, {
    bool notify = true,
  }) async {
    final existing = _profile.puzzleStates[storageKey];
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
    if (notify) {
      notifyListeners();
    }
    await _persistProfile();
  }

  Future<bool> spendCoins(int amount) async {
    if (_profile.coins < amount) return false;
    _profile = _profile.copyWith(coins: _profile.coins - amount);
    notifyListeners();
    await _persistProfile();
    return true;
  }

  /// Kademeli artan ipucu ödemesi:
  /// 1) Önce ücretsiz ipucu bilet hakkını kullanır,
  /// 2) Bilet yoksa artan Altın bedelini (10->15->25->40...) tahsil eder,
  /// 3) Altın yetmezse otomatik Puan karşılığı (4x) ile öder!
  Future<HintChargeResult> useEscalatingHint(
    HintTicketType type,
    int previousPaidUses,
  ) async {
    switch (type) {
      case HintTicketType.letter:
        if (_profile.letterHintTickets > 0) {
          _profile = _profile.copyWith(
            letterHintTickets: _profile.letterHintTickets - 1,
          );
          notifyListeners();
          await _persistProfile();
          return const HintChargeResult(
            paid: true,
            usedTicket: true,
            usedScore: false,
            amountPaid: 0,
          );
        }
      case HintTicketType.word:
        if (_profile.wordHintTickets > 0) {
          _profile = _profile.copyWith(
            wordHintTickets: _profile.wordHintTickets - 1,
          );
          notifyListeners();
          await _persistProfile();
          return const HintChargeResult(
            paid: true,
            usedTicket: true,
            usedScore: false,
            amountPaid: 0,
          );
        }
      case HintTicketType.check:
        if (_profile.checkHintTickets > 0) {
          _profile = _profile.copyWith(
            checkHintTickets: _profile.checkHintTickets - 1,
          );
          notifyListeners();
          await _persistProfile();
          return const HintChargeResult(
            paid: true,
            usedTicket: true,
            usedScore: false,
            amountPaid: 0,
          );
        }
    }

    final coinCost = HintPricingCurve.coinCostFor(type, previousPaidUses);
    if (_profile.coins >= coinCost) {
      _profile = _profile.copyWith(coins: _profile.coins - coinCost);
      notifyListeners();
      await _persistProfile();
      return HintChargeResult(
        paid: true,
        usedTicket: false,
        usedScore: false,
        amountPaid: coinCost,
      );
    }

    final scoreCost = HintPricingCurve.scoreCostFor(type, previousPaidUses);
    if (_profile.score >= scoreCost) {
      _profile = _profile.copyWith(score: _profile.score - scoreCost);
      notifyListeners();
      await _persistProfile();
      return HintChargeResult(
        paid: true,
        usedTicket: false,
        usedScore: true,
        amountPaid: scoreCost,
      );
    }

    return HintChargeResult(
      paid: false,
      usedTicket: false,
      usedScore: false,
      amountPaid: coinCost,
    );
  }

  /// Çözülen İngilizce kelimeleri otomatik "Kelime Defteri"ne kaydeder.
  Future<void> recordLearnedEnglishWords(List<PuzzleEntry> entries) async {
    if (entries.isEmpty) return;
    final updated = Map<String, LearnedWord>.from(_profile.learnedEnglishWords);
    final nowIso = DateTime.now().toIso8601String();
    var changed = false;

    for (final entry in entries) {
      final key = entry.answer.trim().toUpperCase();
      if (key.isEmpty) continue;
      final cleanedClue = entry.clue.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
      final parsed = LearnedWord.parseClue(cleanedClue);
      final existing = updated[key];
      if (existing != null) {
        updated[key] = existing.copyWith(timesSolved: existing.timesSolved + 1);
      } else {
        updated[key] = LearnedWord(
          word: key,
          meaning: parsed.meaning,
          cefrLevel: parsed.cefr,
          timesSolved: 1,
          firstLearnedIso: nowIso,
        );
      }
      changed = true;
    }

    if (changed) {
      _profile = _profile.copyWith(learnedEnglishWords: updated);
      notifyListeners();
      await _persistProfile();
    }
  }

  Future<void> toggleWordFavorite(String word) async {
    final key = word.toUpperCase();
    final existing = _profile.learnedEnglishWords[key];
    if (existing == null) return;
    final updated = Map<String, LearnedWord>.from(_profile.learnedEnglishWords);
    updated[key] = existing.copyWith(isFavorite: !existing.isFavorite);
    _profile = _profile.copyWith(learnedEnglishWords: updated);
    feedback.cellSelect();
    notifyListeners();
    await _persistProfile();
  }

  /// 90 saniyelik Mini Sprint tur sonu rekor ve ödüllerini kaydeder.
  Future<bool> recordSprintResult({
    required int sprintScore,
    required int puzzlesSolved,
    required int coinsBonus,
    required int maxCombo,
  }) async {
    final isNewRecord = sprintScore > _profile.bestSprintScore;
    _profile = _profile.copyWith(
      coins: _profile.coins + coinsBonus,
      score: _profile.score + sprintScore,
      bestSprintScore:
          isNewRecord ? sprintScore : _profile.bestSprintScore,
      bestSprintPuzzles: puzzlesSolved > _profile.bestSprintPuzzles
          ? puzzlesSolved
          : _profile.bestSprintPuzzles,
      bestCombo: maxCombo > _profile.bestCombo ? maxCombo : _profile.bestCombo,
    );
    notifyListeners();
    await _persistProfile();
    return isNewRecord;
  }

  /// Doğru çözülen her kelimede anında kombo altını ve puanı kazandırır.
  Future<void> awardComboWord({
    required int comboCount,
    required int coinsEarned,
    required int scoreEarned,
  }) async {
    final newBestCombo =
        comboCount > _profile.bestCombo ? comboCount : _profile.bestCombo;
    _profile = _profile.copyWith(
      coins: _profile.coins + coinsEarned,
      score: _profile.score + scoreEarned,
      bestCombo: newBestCombo,
    );
    notifyListeners();
    await _persistProfile();
  }

  AppBackground get selectedBackground =>
      BackgroundCatalog.byId(_profile.selectedBackgroundId);

  PlayerRank get currentRank => RankCatalog.forStars(totalStars);

  bool get canClaimDailyGift => _profile.lastDailyGiftDate != todayDateKey;

  int get perfectThreeStarCount => _profile.puzzleStates.values
      .where((s) => s.completed && s.stars == 3)
      .length;

  int missionProgress(MissionItem mission) {
    switch (mission.metric) {
      case MissionMetric.solvedPuzzles:
        return totalSolvedPuzzles;
      case MissionMetric.totalStars:
        return totalStars;
      case MissionMetric.dailyStreak:
        return dailyStreak;
      case MissionMetric.perfectThreeStars:
        return perfectThreeStarCount;
      case MissionMetric.bestCombo:
        return bestCombo;
      case MissionMetric.megaSolved:
        return completedMegaCount;
      case MissionMetric.sprintScore:
        return bestSprintScore;
      case MissionMetric.englishLearned:
        return learnedEnglishCount;
      case MissionMetric.packYesilcam:
        final pack = _packs.where((p) => p.id == 'yesilcam').firstOrNull;
        return pack == null ? 0 : completedCountForPack(pack);
      case MissionMetric.packIngilizce:
        final pack = _packs.where((p) => p.id == 'ingilizce').firstOrNull;
        return pack == null ? 0 : completedCountForPack(pack);
    }
  }

  bool isMissionClaimed(MissionItem mission) =>
      _profile.claimedMissionIds.contains(mission.id);

  bool canClaimMission(MissionItem mission) =>
      !isMissionClaimed(mission) && missionProgress(mission) >= mission.target;

  int get claimableMissionCount =>
      MissionCatalog.all.where(canClaimMission).length;

  int get pendingRewardCount =>
      (canClaimDailyGift ? 1 : 0) + claimableMissionCount;

  Future<int> claimDailyGift() async {
    if (!canClaimDailyGift) return 0;
    const reward = MissionCatalog.dailyGiftCoins;
    _profile = _profile.copyWith(
      coins: _profile.coins + reward,
      lastDailyGiftDate: todayDateKey,
    );
    feedback.wordSolved();
    notifyListeners();
    await _persistProfile();
    return reward;
  }

  Future<int> claimMission(MissionItem mission) async {
    if (!canClaimMission(mission)) return 0;
    final updated = Set<String>.from(_profile.claimedMissionIds)
      ..add(mission.id);
    _profile = _profile.copyWith(
      coins: _profile.coins + mission.rewardCoins,
      claimedMissionIds: updated,
    );
    feedback.wordSolved();
    notifyListeners();
    await _persistProfile();
    return mission.rewardCoins;
  }

  Future<int> watchRewardedAdForCoins() async {
    if (!rewardAdService.isAvailable) return 0;
    final rewarded = await rewardAdService.showRewardedAd();
    if (!rewarded) return 0;
    const bonus = MissionCatalog.rewardedAdCoins;
    _profile = _profile.copyWith(coins: _profile.coins + bonus);
    feedback.wordSolved();
    notifyListeners();
    await _persistProfile();
    return bonus;
  }

  Future<ActionOutcome> buyShopBundle(
    ShopBundle bundle, {
    required bool useScore,
  }) async {
    if (useScore) {
      if (_profile.score < bundle.scoreCost) {
        feedback.errorPulse();
        return ActionOutcome(
          success: false,
          message: 'Yeterli puanın yok (${bundle.scoreCost} puan gerekli).',
        );
      }
    } else {
      if (bundle.coinCost <= 0) {
        return const ActionOutcome(
          success: false,
          message: 'Bu takas yalnızca puan ile yapılır.',
        );
      }
      if (_profile.coins < bundle.coinCost) {
        feedback.errorPulse();
        return ActionOutcome(
          success: false,
          message: 'Yeterli altının yok (${bundle.coinCost} altın gerekli).',
        );
      }
    }

    var newCoins = useScore ? _profile.coins : _profile.coins - bundle.coinCost;
    var newScore =
        useScore ? _profile.score - bundle.scoreCost : _profile.score;
    var letterT = _profile.letterHintTickets;
    var wordT = _profile.wordHintTickets;
    var checkT = _profile.checkHintTickets;

    switch (bundle.type) {
      case ShopBundleType.letterPack:
        letterT += bundle.quantity;
      case ShopBundleType.wordPack:
        wordT += bundle.quantity;
      case ShopBundleType.checkPack:
        checkT += bundle.quantity;
      case ShopBundleType.scoreToCoins:
        newCoins += bundle.quantity;
    }

    _profile = _profile.copyWith(
      coins: newCoins,
      score: newScore,
      letterHintTickets: letterT,
      wordHintTickets: wordT,
      checkHintTickets: checkT,
    );
    feedback.wordSolved();
    notifyListeners();
    await _persistProfile();
    return ActionOutcome(
      success: true,
      message: '${bundle.title} hesabına eklendi!',
    );
  }

  Future<ActionOutcome> unlockMegaEarly(
    MegaPuzzleItem item, {
    required bool useScore,
  }) async {
    if (isMegaUnlocked(item)) {
      return const ActionOutcome(
        success: true,
        message: 'Bu dev bulmaca zaten açık.',
      );
    }
    if (useScore) {
      if (_profile.score < item.earlyUnlockScore) {
        feedback.errorPulse();
        return ActionOutcome(
          success: false,
          message: 'Yeterli puanın yok (${item.earlyUnlockScore} puan gerekli).',
        );
      }
    } else {
      if (_profile.coins < item.earlyUnlockCoins) {
        feedback.errorPulse();
        return ActionOutcome(
          success: false,
          message: 'Yeterli altının yok (${item.earlyUnlockCoins} altın gerekli).',
        );
      }
    }

    final updated = Set<String>.from(_profile.unlockedMegaIds)
      ..add(item.puzzle.id);
    _profile = _profile.copyWith(
      coins: useScore ? _profile.coins : _profile.coins - item.earlyUnlockCoins,
      score: useScore ? _profile.score - item.earlyUnlockScore : _profile.score,
      unlockedMegaIds: updated,
    );
    feedback.wordSolved();
    notifyListeners();
    await _persistProfile();
    return ActionOutcome(
      success: true,
      message: '${item.puzzle.title} açıldı! İyi oyunlar!',
    );
  }

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
    await _persistProfile();
    return true;
  }

  Future<ActionOutcome> unlockBackgroundWithCoins(AppBackground bg) async {
    if (isBackgroundUnlocked(bg)) {
      await selectBackground(bg.id);
      return ActionOutcome(success: true, message: '${bg.name} aktif edildi!');
    }
    if (_profile.coins < bg.coinCost) {
      feedback.errorPulse();
      return ActionOutcome(
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
    await _persistProfile();
    return ActionOutcome(
      success: true,
      message: '${bg.name} altınla açıldı ve uygulandı!',
    );
  }

  Future<ActionOutcome> unlockBackgroundWithScore(AppBackground bg) async {
    if (isBackgroundUnlocked(bg)) {
      await selectBackground(bg.id);
      return ActionOutcome(success: true, message: '${bg.name} aktif edildi!');
    }
    if (_profile.score < bg.scoreCost) {
      feedback.errorPulse();
      return ActionOutcome(
        success: false,
        message: 'Yeterli puanın yok (${bg.scoreCost} puan gerekli).',
      );
    }
    final updatedUnlocks = Set<String>.from(_profile.unlockedBackgroundIds)
      ..add(bg.id);
    _profile = _profile.copyWith(
      score: _profile.score - bg.scoreCost,
      unlockedBackgroundIds: updatedUnlocks,
      selectedBackgroundId: bg.id,
    );
    feedback.wordSolved();
    notifyListeners();
    await _persistProfile();
    return ActionOutcome(
      success: true,
      message: '${bg.name} puanla açıldı ve uygulandı!',
    );
  }

  Future<CompletionReward> completePuzzle({
    required String storageKey,
    required PuzzleSaveState finalState,
    required bool isDaily,
    int rewardMultiplier = 1,
    int sessionComboCoins = 0,
    int sessionComboScore = 0,
    int maxComboInSession = 0,
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

    final mult = isDaily ? 2 : rewardMultiplier;
    final baseReward = (stars * 10 + 10) * mult;
    var coinsEarned = 0;
    if (!wasCompleted) {
      coinsEarned = baseReward;
    } else if (stars > (existing?.stars ?? 0)) {
      coinsEarned = 10;
    }

    final completionBonusScore = !wasCompleted ? (stars * 40 * mult) : 20;

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
        final yesterday = TurkishText.dateKey(
          DateTime.now().subtract(const Duration(days: 1)),
        );
        if (_profile.lastDailyDate == yesterday) {
          newStreak = _profile.dailyStreak + 1;
        } else {
          newStreak = 1;
        }
        newLastDaily = today;
        streakAwarded = newStreak;
      }
    }

    final newBestCombo = maxComboInSession > _profile.bestCombo
        ? maxComboInSession
        : _profile.bestCombo;

    _profile = _profile.copyWith(
      coins: _profile.coins + coinsEarned,
      score: _profile.score + completionBonusScore,
      bestCombo: newBestCombo,
      dailyStreak: newStreak,
      lastDailyDate: newLastDaily,
      completedDailyDates: updatedDailyDates,
      puzzleStates: updatedMap,
    );

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
    await _persistProfile();

    return CompletionReward(
      stars: stars,
      coinsEarned: coinsEarned,
      comboCoinsEarned: sessionComboCoins,
      scoreEarned: completionBonusScore + sessionComboScore,
      maxCombo: maxComboInSession,
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
    await _persistProfile();
  }

  Future<void> toggleHaptics(bool enabled) async {
    _profile = _profile.copyWith(hapticsEnabled: enabled);
    _syncFeedbackPrefs();
    notifyListeners();
    await _persistProfile();
  }

  Future<void> resetAllProgress() async {
    _profile = PlayerProfile(
      soundEnabled: _profile.soundEnabled,
      hapticsEnabled: _profile.hapticsEnabled,
    );
    notifyListeners();
    await _persistProfile();
  }

  void dismissCloudBackupBanner() {
    _backupBannerDismissed = true;
    notifyListeners();
  }

  Future<void> _persistProfile() async {
    await _storage.saveProfile(_profile);
    _scheduleCloudPush();
  }

  void _scheduleCloudPush() {
    final user = _signedInUser;
    if (user == null || !_auth.isCloudAvailable) return;
    _cloudPushTimer?.cancel();
    _cloudPushTimer = Timer(const Duration(seconds: 3), () {
      unawaited(() async {
        final ok = await _cloudSync.pushProfile(user.uid, _profile);
        if (ok) {
          _lastCloudSync = DateTime.now();
          notifyListeners();
        }
      }());
    });
  }

  Future<void> _pullAndMergeCloudSilently(String uid) async {
    final remote = await _cloudSync.fetchProfile(uid);
    if (remote != null) {
      _profile = ProfileMerger.merge(local: _profile, cloud: remote);
      _syncFeedbackPrefs();
      await _storage.saveProfile(_profile);
    }
    final pushed = await _cloudSync.pushProfile(uid, _profile);
    if (pushed) {
      _lastCloudSync = DateTime.now();
    }
    notifyListeners();
  }

  /// İsteğe bağlı Google ile Giriş + akıllı yerel–bulut ilerleme birleştirme.
  Future<ActionOutcome> signInWithGoogleAndSync() async {
    if (_authBusy) {
      return const ActionOutcome(
        success: false,
        message: 'İşlem devam ediyor, lütfen bekleyin...',
      );
    }
    _authBusy = true;
    notifyListeners();
    try {
      final res = await _auth.signInWithGoogle();
      if (!res.success || res.user == null) {
        return ActionOutcome(success: false, message: res.message);
      }

      _signedInUser = res.user;
      final remote = await _cloudSync.fetchProfile(res.user!.uid);
      if (remote != null) {
        _profile = ProfileMerger.merge(local: _profile, cloud: remote);
        _syncFeedbackPrefs();
        await _storage.saveProfile(_profile);
      }
      final pushed = await _cloudSync.pushProfile(res.user!.uid, _profile);
      if (pushed) {
        _lastCloudSync = DateTime.now();
      }
      feedback.wordSolved();
      return ActionOutcome(
        success: true,
        message: remote != null
            ? 'Google hesabın bağlandı ve önceki bulut ilerlemen birleştirildi!'
            : 'Google hesabın bağlandı ve ilerlemen buluta yedeklendi!',
      );
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  /// Manuel tek dokunuş bulut yedekleme.
  Future<ActionOutcome> syncCloudNow() async {
    final user = _signedInUser;
    if (user == null) {
      return const ActionOutcome(
        success: false,
        message: 'Önce Google hesabını bağlamalısın.',
      );
    }
    if (_authBusy) {
      return const ActionOutcome(
        success: false,
        message: 'Yedekleme zaten sürüyor...',
      );
    }
    _authBusy = true;
    notifyListeners();
    try {
      final remote = await _cloudSync.fetchProfile(user.uid);
      if (remote != null) {
        _profile = ProfileMerger.merge(local: _profile, cloud: remote);
        await _storage.saveProfile(_profile);
      }
      final ok = await _cloudSync.pushProfile(user.uid, _profile);
      if (ok) {
        _lastCloudSync = DateTime.now();
        feedback.wordSolved();
        return const ActionOutcome(
          success: true,
          message: 'İlerlemen buluta başarıyla yedeklendi!',
        );
      }
      return const ActionOutcome(
        success: false,
        message: 'Buluta bağlanılamadı. İnternet bağlantını kontrol et.',
      );
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  /// Hesaptan çıkış yapar; cihazdaki mevcut ilerleme korunur (misafir olarak devam eder).
  Future<ActionOutcome> signOutGoogle() async {
    _cloudPushTimer?.cancel();
    await _auth.signOut();
    _signedInUser = null;
    _lastCloudSync = null;
    notifyListeners();
    return const ActionOutcome(
      success: true,
      message: 'Hesaptan çıkış yapıldı. Misafir olarak oynamaya devam edebilirsin.',
    );
  }

  /// Google Play politikasına tam uyumlu kalıcı hesap ve bulut verisi silme.
  Future<ActionOutcome> deleteAccountAndCloudData() async {
    if (_authBusy) {
      return const ActionOutcome(
        success: false,
        message: 'İşlem devam ediyor...',
      );
    }
    _authBusy = true;
    notifyListeners();
    try {
      _cloudPushTimer?.cancel();
      final uid = _signedInUser?.uid;
      if (uid != null) {
        await _cloudSync.deleteCloudProfile(uid);
      }
      final res = await _auth.deleteCurrentUser();
      if (!res.success) {
        // Silme iptal edildiyse veya başarısız olduysa bulut yedeğini geri yükle
        if (uid != null) {
          await _cloudSync.pushProfile(uid, _profile);
        }
        return ActionOutcome(success: false, message: res.message);
      }
      _signedInUser = null;
      _lastCloudSync = null;
      _profile = PlayerProfile(
        soundEnabled: _profile.soundEnabled,
        hapticsEnabled: _profile.hapticsEnabled,
      );
      await _storage.clearAll();
      return const ActionOutcome(
        success: true,
        message: 'Hesabın, bulut yedeğin ve yerel verilerin kalıcı olarak silindi.',
      );
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cloudPushTimer?.cancel();
    feedback.dispose();
    super.dispose();
  }
}
