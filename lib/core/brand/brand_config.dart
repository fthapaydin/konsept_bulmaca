import 'package:material_ui/material_ui.dart';

/// Merkezi marka ve modül yapılandırması.
/// Yeni oyun modları veya marka güncellemeleri tek bir dosyadan yönetilir.
class BrandConfig {
  const BrandConfig._();

  static const String appName = 'Karehane';
  static const String tagline = 'Konsept Kare Bulmaca';
  static const String versionLabel = 'v2.0';
  static const String developerName = 'FatalSoft Inc.';
  static const String contactEmail = 'fatalsoft.inc@gmail.com';
  static const String androidPackageId = 'fatalsoft.bulmaca';

  static const Color primaryAmber = Color(0xFFB45309);
  static const Color deepMahogany = Color(0xFF7C2D12);
  static const Color warmPaper = Color(0xFFF8F6F1);
  static const Color splashDark = Color(0xFF1B113C);
}

enum GameModuleId {
  dailyPuzzle,
  miniSprint,
  megaArena,
  englishNotebook,
  backgroundGallery,
  rewardsAndShop,
}

/// İleride yeni modüller (örn. Şans Çarkı, Turnuva, Günlük Meydan Okuma)
/// eklemeyi kolaylaştıran genişletilebilir modül tanımlayıcı.
class GameModuleDescriptor {
  const GameModuleDescriptor({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.badgeText,
  });

  final GameModuleId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String badgeText;
}
