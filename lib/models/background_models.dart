import 'package:material_ui/material_ui.dart';

enum BackgroundArtworkType {
  conceptAuto,
  newspaperCream,
  midnightStars,
  yesilcamCinema,
  iznikTiles,
  aegeanCoast,
  cappadociaDawn,
  autumnForest,
  auroraNight,
  goldenGalaxy,
}

enum UnlockMetric {
  none,
  solvedPuzzles,
  totalStars,
  dailyStreak,
}

class AppBackground {
  const AppBackground({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.artwork,
    required this.gradientColors,
    required this.accentColor,
    required this.isDark,
    this.unlockMetric = UnlockMetric.none,
    this.unlockTarget = 0,
    this.coinCost = 0,
    this.scoreCost = 0,
  });

  final String id;
  final String name;
  final String subtitle;
  final BackgroundArtworkType artwork;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isDark;
  final UnlockMetric unlockMetric;
  final int unlockTarget;
  final int coinCost;
  final int scoreCost;

  bool get isFreeStarter =>
      unlockMetric == UnlockMetric.none && coinCost == 0 && scoreCost == 0;

  String get unlockRequirementLabel {
    switch (unlockMetric) {
      case UnlockMetric.none:
        return 'Başlangıçta Açık';
      case UnlockMetric.solvedPuzzles:
        return '$unlockTarget bulmaca çöz';
      case UnlockMetric.totalStars:
        return '$unlockTarget yıldız topla';
      case UnlockMetric.dailyStreak:
        return '$unlockTarget günlük seri yap';
    }
  }
}

class BackgroundCatalog {
  static const String defaultId = 'concept_auto';

  static const List<AppBackground> all = [
    AppBackground(
      id: 'concept_auto',
      name: 'Konsept Atmosferi',
      subtitle: 'Her temanın kendi yumuşak renk tonuna uyum sağlar',
      artwork: BackgroundArtworkType.conceptAuto,
      gradientColors: [Color(0xFFFDFBF7), Color(0xFFF3EFE6)],
      accentColor: Color(0xFFB45309),
      isDark: false,
    ),
    AppBackground(
      id: 'gazete_krem',
      name: 'Pazar Gazetesi',
      subtitle: 'Klasik kare bulmaca sıcak kâğıt dokusu',
      artwork: BackgroundArtworkType.newspaperCream,
      gradientColors: [Color(0xFFFAF6EC), Color(0xFFF1E7D2)],
      accentColor: Color(0xFF78716C),
      isDark: false,
    ),
    AppBackground(
      id: 'gece_yarisi',
      name: 'Gece Yarısı',
      subtitle: 'Göz yormayan koyu lacivert gece modu',
      artwork: BackgroundArtworkType.midnightStars,
      gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF172038)],
      accentColor: Color(0xFF93C5FD),
      isDark: true,
    ),
    AppBackground(
      id: 'yesilcam_sinema',
      name: 'Yeşilçam Perdesi',
      subtitle: 'Nostaljik sinema ışıkları ve film şeridi dokusu',
      artwork: BackgroundArtworkType.yesilcamCinema,
      gradientColors: [Color(0xFF3B120C), Color(0xFF6B2111), Color(0xFF270E0A)],
      accentColor: Color(0xFFFBBF24),
      isDark: true,
      unlockMetric: UnlockMetric.solvedPuzzles,
      unlockTarget: 3,
      coinCost: 100,
      scoreCost: 350,
    ),
    AppBackground(
      id: 'osmanli_cini',
      name: 'İznik Çinisi',
      subtitle: 'Kobalt ve turkuaz geleneksel geometrik çini deseni',
      artwork: BackgroundArtworkType.iznikTiles,
      gradientColors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFFBAE6FD)],
      accentColor: Color(0xFF2C4A73),
      isDark: false,
      unlockMetric: UnlockMetric.solvedPuzzles,
      unlockTarget: 6,
      coinCost: 120,
      scoreCost: 450,
    ),
    AppBackground(
      id: 'ege_kiyisi',
      name: 'Ege Kıyısı',
      subtitle: 'Ferah turkuaz dalgalar ve Akdeniz güneşi',
      artwork: BackgroundArtworkType.aegeanCoast,
      gradientColors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF4DD0E1)],
      accentColor: Color(0xFF0E7490),
      isDark: false,
      unlockMetric: UnlockMetric.totalStars,
      unlockTarget: 9,
      coinCost: 150,
      scoreCost: 550,
    ),
    AppBackground(
      id: 'kapadokya_safak',
      name: 'Kapadokya Şafağı',
      subtitle: 'Gün doğumu gökyüzünde süzülen sıcak hava balonları',
      artwork: BackgroundArtworkType.cappadociaDawn,
      gradientColors: [Color(0xFFFFEDD5), Color(0xFFFDBA74), Color(0xFFFB7185)],
      accentColor: Color(0xFF9A3412),
      isDark: false,
      unlockMetric: UnlockMetric.totalStars,
      unlockTarget: 18,
      coinCost: 200,
      scoreCost: 750,
    ),
    AppBackground(
      id: 'sonbahar_ormani',
      name: 'Sonbahar Akşamı',
      subtitle: 'Sıcak kızıl yapraklar ve dingin akşam güneşi',
      artwork: BackgroundArtworkType.autumnForest,
      gradientColors: [Color(0xFF451A03), Color(0xFF7C2D12), Color(0xFF9A3412)],
      accentColor: Color(0xFFFDBA74),
      isDark: true,
      unlockMetric: UnlockMetric.solvedPuzzles,
      unlockTarget: 12,
      coinCost: 220,
      scoreCost: 850,
    ),
    AppBackground(
      id: 'kuzey_isiklari',
      name: 'Kuzey Işıkları',
      subtitle: 'Gece göğünde parlayan zümrüt ve mor aurora şeritleri',
      artwork: BackgroundArtworkType.auroraNight,
      gradientColors: [Color(0xFF041C2C), Color(0xFF0B3B49), Color(0xFF14243A)],
      accentColor: Color(0xFF34D399),
      isDark: true,
      unlockMetric: UnlockMetric.dailyStreak,
      unlockTarget: 2,
      coinCost: 250,
      scoreCost: 950,
    ),
    AppBackground(
      id: 'altin_galaksi',
      name: 'Altın Galaksi',
      subtitle: 'Usta oyuncular için altın takımyıldızlı gece göğü',
      artwork: BackgroundArtworkType.goldenGalaxy,
      gradientColors: [Color(0xFF09090B), Color(0xFF18181B), Color(0xFF271F11)],
      accentColor: Color(0xFFFCD34D),
      isDark: true,
      unlockMetric: UnlockMetric.totalStars,
      unlockTarget: 30,
      coinCost: 350,
      scoreCost: 1300,
    ),
  ];

  static AppBackground byId(String id) {
    for (final bg in all) {
      if (bg.id == id) return bg;
    }
    return all.first;
  }
}
