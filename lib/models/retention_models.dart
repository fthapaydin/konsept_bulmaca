import 'package:material_ui/material_ui.dart';

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
      color: Color(0xFF0F766E),
    ),
    PlayerRank(
      level: 2,
      title: 'Kelime Kaşifi',
      minStars: 9,
      nextStars: 24,
      icon: Icons.explore_rounded,
      color: Color(0xFF1D4ED8),
    ),
    PlayerRank(
      level: 3,
      title: 'Kare Avcısı',
      minStars: 24,
      nextStars: 48,
      icon: Icons.grid_on_rounded,
      color: Color(0xFFB45309),
    ),
    PlayerRank(
      level: 4,
      title: 'Bulmaca Ustası',
      minStars: 48,
      nextStars: 90,
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF6D28D9),
    ),
    PlayerRank(
      level: 5,
      title: 'Kelime Bilgesi',
      minStars: 90,
      nextStars: 150,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFBE185D),
    ),
    PlayerRank(
      level: 6,
      title: 'Büyük Efsane',
      minStars: 150,
      nextStars: null,
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFD97706),
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
      color: Color(0xFF0F766E),
    ),
    MissionItem(
      id: 'perfect_star',
      title: 'Kusursuz Çözüm',
      description: 'İpucu kullanmadan 3 yıldızlı bir bölüm bitir',
      metric: MissionMetric.perfectThreeStars,
      target: 1,
      rewardCoins: 40,
      icon: Icons.stars_rounded,
      color: Color(0xFFD97706),
    ),
    MissionItem(
      id: 'five_wins',
      title: 'Bulmaca Tutkunu',
      description: 'Toplam 5 bulmaca tamamla',
      metric: MissionMetric.solvedPuzzles,
      target: 5,
      rewardCoins: 50,
      icon: Icons.extension_rounded,
      color: Color(0xFF1D4ED8),
    ),
    MissionItem(
      id: 'stars_15',
      title: 'Yıldız Avcısı',
      description: 'Toplam 15 yıldız topla',
      metric: MissionMetric.totalStars,
      target: 15,
      rewardCoins: 60,
      icon: Icons.star_rounded,
      color: Color(0xFFF59E0B),
    ),
    MissionItem(
      id: 'yesilcam_5',
      title: 'Yeşilçam Hayranı',
      description: 'Yeşilçam Klasikleri paketinde 5 seviye çöz',
      metric: MissionMetric.packYesilcam,
      target: 5,
      rewardCoins: 60,
      icon: Icons.movie_filter_rounded,
      color: Color(0xFFB45309),
    ),
    MissionItem(
      id: 'english_5',
      title: 'İki Dilli Kaşif',
      description: 'İngilizce Kelime Avı paketinde 5 seviye çöz',
      metric: MissionMetric.packIngilizce,
      target: 5,
      rewardCoins: 60,
      icon: Icons.translate_rounded,
      color: Color(0xFF2563EB),
    ),
    MissionItem(
      id: 'streak_3',
      title: 'Günlük Alışkanlık',
      description: '3 gün üst üste Günün Bulmacasını çöz',
      metric: MissionMetric.dailyStreak,
      target: 3,
      rewardCoins: 75,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEA580C),
    ),
    MissionItem(
      id: 'fifteen_wins',
      title: 'Kare Ustası',
      description: 'Toplam 15 bulmaca tamamla',
      metric: MissionMetric.solvedPuzzles,
      target: 15,
      rewardCoins: 100,
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF6D28D9),
    ),
  ];
}
