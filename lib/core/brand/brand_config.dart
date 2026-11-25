import 'package:material_ui/material_ui.dart';

/// Merkezi marka ve modül yapılandırması.
/// Yeni oyun modları veya marka güncellemeleri tek bir dosyadan yönetilir.
class BrandConfig {
  const BrandConfig._();

  static const String appName = 'eKare Bulmaca';
  static const String shortName = 'eKare';
  static const String tagline = 'Konsept Kare Bulmaca';
  static const String versionLabel = 'v2.0';
  static const String developerName = 'FatalSoft Inc.';
  static const String contactEmail = 'fatalsoft.inc@gmail.com';
  static const String androidPackageId = 'fatalsoft.bulmaca';
  static const String iconAssetPath = 'assets/branding/ekare_icon.png';

  static const Color newsprintPaper = Color(0xFFF3EEE2);
  static const Color newsprintInk = Color(0xFF141210);
  static const Color primaryAmber = Color(0xFFA85513);
  static const Color warmPaper = Color(0xFFF6F2EA);
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
