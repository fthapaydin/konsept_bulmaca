import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';

class ComboReward {
  const ComboReward({
    required this.combo,
    required this.coins,
    required this.score,
  });

  final int combo;
  final int coins;
  final int score;
}

/// Ardışık ipucusuz ve hatasız doğru kelimelerde 2x ve üzeri katlanarak artan
/// altın + puan ödül motoru.
class ComboEconomy {
  static ComboReward rewardFor(int comboCount) {
    final c = comboCount < 1 ? 1 : comboCount;
    final int coins;
    final int score;
    switch (c) {
      case 1:
        coins = 5;
        score = 20;
      case 2:
        coins = 10;
        score = 40;
      case 3:
        coins = 20;
        score = 80;
      case 4:
        coins = 40;
        score = 160;
      default:
        coins = (40 + (c - 4) * 20).clamp(40, 120);
        score = (160 + (c - 4) * 80).clamp(160, 480);
    }
    return ComboReward(combo: c, coins: coins, score: score);
  }
}

enum HintTicketType { letter, word, check }

enum ShopBundleType { letterPack, wordPack, checkPack, scoreToCoins }

class ShopBundle {
  const ShopBundle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.quantity,
    required this.coinCost,
    required this.scoreCost,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final ShopBundleType type;
  final int quantity;
  final int coinCost; // 0 ise yalnızca puanla alınır
  final int scoreCost;
  final IconData icon;
  final Color color;
}

class ShopCatalog {
  static const List<ShopBundle> all = [
    ShopBundle(
      id: 'letter_pack_3',
      title: '3× Harf İpucu',
      subtitle: 'İstediğin 3 kutuyu ücretsiz aç',
      type: ShopBundleType.letterPack,
      quantity: 3,
      coinCost: 35,
      scoreCost: 150,
      icon: Icons.lightbulb_rounded,
      color: AppPalette.brass,
    ),
    ShopBundle(
      id: 'word_pack_2',
      title: '2× Kelime İpucu',
      subtitle: 'Zorlandığın 2 kelimeyi tamamen aç',
      type: ShopBundleType.wordPack,
      quantity: 2,
      coinCost: 65,
      scoreCost: 280,
      icon: Icons.auto_awesome_rounded,
      color: AppPalette.ink,
    ),
    ShopBundle(
      id: 'check_pack_5',
      title: '5× Hata Kontrolü',
      subtitle: '5 kez ücretsiz tahta kontrolü yap',
      type: ShopBundleType.checkPack,
      quantity: 5,
      coinCost: 35,
      scoreCost: 150,
      icon: Icons.fact_check_rounded,
      color: AppPalette.correct,
    ),
    ShopBundle(
      id: 'score_to_coins_50',
      title: '+50 Altın Takası',
      subtitle: 'Biriktirdiğin puanları altına çevir',
      type: ShopBundleType.scoreToCoins,
      quantity: 50,
      coinCost: 0,
      scoreCost: 200,
      icon: Icons.currency_exchange_rounded,
      color: AppPalette.brass,
    ),
    ShopBundle(
      id: 'score_to_coins_150',
      title: '+150 Altın Hazinesi',
      subtitle: 'Avantajlı puan – altın dönüşümü',
      type: ShopBundleType.scoreToCoins,
      quantity: 150,
      coinCost: 0,
      scoreCost: 500,
      icon: Icons.savings_rounded,
      color: AppPalette.brass,
    ),
  ];
}

class PlayerRank {
  const PlayerRank({
    required this.level,
    required this.title,
    required this.minStars,
    required this.nextStars,
    required this.icon,
    required this.color,
  });

  final int level;
  final String title;
  final int minStars;
  final int? nextStars;
  final IconData icon;
  final Color color;

  double progressFor(int stars) {
    if (nextStars == null) return 1.0;
    final span = nextStars! - minStars;
    if (span <= 0) return 1.0;
    return ((stars - minStars) / span).clamp(0.0, 1.0);
  }
}

class RankCatalog {
  static const List<PlayerRank> tiers = [
    PlayerRank(
      level: 1,
      title: 'Meraklı Çaylak',
      minStars: 0,
      nextStars: 9,
      icon: Icons.eco_rounded,
      color: AppPalette.inkSoft,
    ),
    PlayerRank(
      level: 2,
      title: 'Kelime Kaşifi',
      minStars: 9,
      nextStars: 24,
      icon: Icons.explore_rounded,
      color: AppPalette.ink,
    ),
    PlayerRank(
      level: 3,
      title: 'Kare Avcısı',
      minStars: 24,
      nextStars: 48,
      icon: Icons.grid_on_rounded,
      color: AppPalette.brass,
    ),
    PlayerRank(
      level: 4,
      title: 'Bulmaca Ustası',
      minStars: 48,
      nextStars: 90,
      icon: Icons.workspace_premium_rounded,
      color: AppPalette.brass,
    ),
    PlayerRank(
      level: 5,
      title: 'Kelime Bilgesi',
      minStars: 90,
      nextStars: 150,
      icon: Icons.auto_awesome_rounded,
      color: AppPalette.ink,
    ),
    PlayerRank(
      level: 6,
      title: 'Büyük Efsane',
      minStars: 150,
      nextStars: null,
      icon: Icons.emoji_events_rounded,
      color: AppPalette.brass,
    ),
  ];

  static PlayerRank forStars(int stars) {
    PlayerRank current = tiers.first;
    for (final tier in tiers) {
      if (stars >= tier.minStars) {
        current = tier;
      }
    }
    return current;
  }
}

enum MissionMetric {
  solvedPuzzles,
  totalStars,
  dailyStreak,
  packYesilcam,
  packIngilizce,
  perfectThreeStars,
  bestCombo,
  megaSolved,
  sprintScore,
  englishLearned,
}

class MissionItem {
  const MissionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.rewardCoins,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final MissionMetric metric;
  final int target;
  final int rewardCoins;
  final IconData icon;
  final Color color;
}

class MissionCatalog {
  static const int dailyGiftCoins = 40;
  static const int rewardedAdCoins = 30;

  static const List<MissionItem> all = [
    MissionItem(
      id: 'first_win',
      title: 'İlk Adım',
      description: 'İlk kare bulmacanı başarıyla tamamla',
      metric: MissionMetric.solvedPuzzles,
      target: 1,
      rewardCoins: 30,
      icon: Icons.flag_rounded,
      color: AppPalette.brass,
    ),
    MissionItem(
      id: 'combo_3',
      title: 'Kombo Ustası',
      description: 'Hatasız ve ipucusuz 3× kelime kombosu yakala',
      metric: MissionMetric.bestCombo,
      target: 3,
      rewardCoins: 50,
      icon: Icons.whatshot_rounded,
      color: AppPalette.brass,
    ),
    MissionItem(
      id: 'perfect_star',
      title: 'Kusursuz Çözüm',
      description: 'İpucu kullanmadan 3 yıldızlı bir bölüm bitir',
      metric: MissionMetric.perfectThreeStars,
      target: 1,
      rewardCoins: 40,
      icon: Icons.stars_rounded,
      color: AppPalette.brass,
    ),
    MissionItem(
      id: 'five_wins',
      title: 'Bulmaca Tutkunu',
      description: 'Toplam 5 bulmaca tamamla',
      metric: MissionMetric.solvedPuzzles,
      target: 5,
      rewardCoins: 50,
      icon: Icons.extension_rounded,
      color: AppPalette.ink,
    ),
    MissionItem(
      id: 'stars_15',
      title: 'Yıldız Avcısı',
      description: 'Toplam 15 yıldız topla',
      metric: MissionMetric.totalStars,
      target: 15,
      rewardCoins: 60,
      icon: Icons.star_rounded,
      color: AppPalette.brass,
    ),
    MissionItem(
      id: 'yesilcam_5',
      title: 'Yeşilçam Hayranı',
      description: 'Yeşilçam Klasikleri paketinde 5 seviye çöz',
      metric: MissionMetric.packYesilcam,
      target: 5,
      rewardCoins: 60,
      icon: Icons.movie_filter_rounded,
      color: AppPalette.brass,
    ),
    MissionItem(
      id: 'english_5',
      title: 'İki Dilli Kaşif',
      description: 'İngilizce Kelime Avı paketinde 5 seviye çöz',
      metric: MissionMetric.packIngilizce,
      target: 5,
      rewardCoins: 60,
      icon: Icons.translate_rounded,
      color: AppPalette.ink,
    ),
    MissionItem(
      id: 'mega_win',
      title: 'Dev Kare Fatihi',
      description: 'İlk 12×12 veya üzeri Dev Bulmacanı tamamla',
      metric: MissionMetric.megaSolved,
      target: 1,
      rewardCoins: 120,
      icon: Icons.grid_4x4_rounded,
      color: AppPalette.ink,
    ),
    MissionItem(
      id: 'streak_3',
      title: 'Günlük Alışkanlık',
      description: '3 gün üst üste Günün Bulmacasını çöz',
      metric: MissionMetric.dailyStreak,
      target: 3,
      rewardCoins: 75,
      icon: Icons.local_fire_department_rounded,
      color: AppPalette.brass,
    ),
    MissionItem(
      id: 'sprint_200',
      title: 'Hız Tutkunu',
      description: '90sn Mini Sprint modunda 200+ puan topla',
      metric: MissionMetric.sprintScore,
      target: 200,
      rewardCoins: 60,
      icon: Icons.bolt_rounded,
      color: AppPalette.ink,
    ),
    MissionItem(
      id: 'english_notebook_10',
      title: 'Kelime Koleksiyoneri',
      description: 'Kelime Defterine 10 İngilizce kelime kaydet',
      metric: MissionMetric.englishLearned,
      target: 10,
      rewardCoins: 60,
      icon: Icons.menu_book_rounded,
      color: AppPalette.ink,
    ),
    MissionItem(
      id: 'fifteen_wins',
      title: 'Kare Ustası',
      description: 'Toplam 15 bulmaca tamamla',
      metric: MissionMetric.solvedPuzzles,
      target: 15,
      rewardCoins: 100,
      icon: Icons.emoji_events_rounded,
      color: AppPalette.brass,
    ),
  ];
}
