import 'dart:math' as math;

import '../../models/puzzle_models.dart';
import 'notebook_models.dart';

/// Yerel misafir ilerlemesi ile Google hesabındaki bulut ilerlemesini hiçbir
/// kazanımı kaybetmeden akıllıca birleştirir (yüksek yıldız, rekor, çözülen
/// bölümler, kazanılan temalar ve İngilizce sözlük kelimeleri daima korunur).
class ProfileMerger {
  const ProfileMerger._();

  static PlayerProfile merge({
    required PlayerProfile local,
    required PlayerProfile cloud,
  }) {
    final mergedDailyDates = <String>{
      ...local.completedDailyDates,
      ...cloud.completedDailyDates,
    };

    final mergedBgs = <String>{
      ...local.unlockedBackgroundIds,
      ...cloud.unlockedBackgroundIds,
    };

    final mergedMegas = <String>{
      ...local.unlockedMegaIds,
      ...cloud.unlockedMegaIds,
    };

    final mergedMissions = <String>{
      ...local.claimedMissionIds,
      ...cloud.claimedMissionIds,
    };

    // İngilizce Kelime Defteri birleşimi (çözülme sayısı max, favori OR)
    final mergedWords = Map<String, LearnedWord>.from(cloud.learnedEnglishWords);
    for (final entry in local.learnedEnglishWords.entries) {
      final existing = mergedWords[entry.key];
      if (existing == null) {
        mergedWords[entry.key] = entry.value;
      } else {
        mergedWords[entry.key] = existing.copyWith(
          timesSolved: math.max(existing.timesSolved, entry.value.timesSolved),
          isFavorite: existing.isFavorite || entry.value.isFavorite,
        );
      }
    }

    // Bulmaca durumları birleşimi
    final mergedPuzzles = Map<String, PuzzleSaveState>.from(cloud.puzzleStates);
    for (final entry in local.puzzleStates.entries) {
      final existing = mergedPuzzles[entry.key];
      if (existing == null) {
        mergedPuzzles[entry.key] = entry.value;
      } else {
        mergedPuzzles[entry.key] = _mergePuzzleState(entry.value, existing);
      }
    }

    return PlayerProfile(
      coins: math.max(local.coins, cloud.coins),
      score: math.max(local.score, cloud.score),
      bestCombo: math.max(local.bestCombo, cloud.bestCombo),
      bestSprintScore: math.max(local.bestSprintScore, cloud.bestSprintScore),
      bestSprintPuzzles:
          math.max(local.bestSprintPuzzles, cloud.bestSprintPuzzles),
      letterHintTickets:
          math.max(local.letterHintTickets, cloud.letterHintTickets),
      wordHintTickets: math.max(local.wordHintTickets, cloud.wordHintTickets),
      checkHintTickets:
          math.max(local.checkHintTickets, cloud.checkHintTickets),
      dailyStreak: math.max(local.dailyStreak, cloud.dailyStreak),
      lastDailyDate: _latestIsoDate(local.lastDailyDate, cloud.lastDailyDate),
      lastDailyGiftDate:
          _latestIsoDate(local.lastDailyGiftDate, cloud.lastDailyGiftDate),
      completedDailyDates: mergedDailyDates,
      // Aktif cihazın ses/titreşim/tema tercihleri korunur
      soundEnabled: local.soundEnabled,
      hapticsEnabled: local.hapticsEnabled,
      selectedBackgroundId: local.selectedBackgroundId,
      unlockedBackgroundIds: mergedBgs,
      unlockedMegaIds: mergedMegas,
      claimedMissionIds: mergedMissions,
      learnedEnglishWords: mergedWords,
      puzzleStates: mergedPuzzles,
    );
  }

  static PuzzleSaveState _mergePuzzleState(
    PuzzleSaveState a,
    PuzzleSaveState b,
  ) {
    final completed = a.completed || b.completed;
    final stars = math.max(a.stars, b.stars);

    int? bestTime;
    if (a.bestTimeSeconds != null && b.bestTimeSeconds != null) {
      bestTime = math.min(a.bestTimeSeconds!, b.bestTimeSeconds!);
    } else {
      bestTime = a.bestTimeSeconds ?? b.bestTimeSeconds;
    }

    if (completed) {
      final preferred = a.completed ? a : b;
      return preferred.copyWith(
        completed: true,
        stars: stars,
        bestTimeSeconds: bestTime,
      );
    }

    // İkisi de devam ediyorsa daha çok harf girilmiş tahtayı koru
    return a.letters.length >= b.letters.length ? a : b;
  }

  static String? _latestIsoDate(String? a, String? b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;
    return a.compareTo(b) >= 0 ? a : b;
  }
}
