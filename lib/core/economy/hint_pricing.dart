import '../../models/retention_models.dart';

/// Her bulmaca oturumunda kullanım sayısına göre kademeli artan ipucu fiyat eğrisi.
/// Örnek Harf Aç: 10 -> 15 -> 25 -> 40 -> 60 -> 85 -> 115 -> 150
class HintPricingCurve {
  const HintPricingCurve._();

  static const List<int> letterCoinSteps = [10, 15, 25, 40, 60, 85, 115, 150];
  static const List<int> wordCoinSteps = [25, 40, 60, 85, 115, 150, 190, 240];
  static const List<int> checkCoinSteps = [10, 15, 25, 40, 60, 85, 115];

  /// Altın yerine puanla ödemede 1 Altın = 4 Puan dönüşümü.
  static const int scorePerCoin = 4;

  static int coinCostFor(HintTicketType type, int previousPaidUses) {
    final steps = switch (type) {
      HintTicketType.letter => letterCoinSteps,
      HintTicketType.word => wordCoinSteps,
      HintTicketType.check => checkCoinSteps,
    };
    final idx = previousPaidUses.clamp(0, steps.length - 1);
    return steps[idx];
  }

  static int scoreCostFor(HintTicketType type, int previousPaidUses) =>
      coinCostFor(type, previousPaidUses) * scorePerCoin;
}
