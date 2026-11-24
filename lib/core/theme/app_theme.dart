import 'package:material_ui/material_ui.dart';

/// Karehane bütünsel editoryal tasarım sistemi ("Kağıt, Mürekkep & Antik Altın").
/// Uygulamanın her ekranında tek, sakin ve zarif bir renk dili korur;
/// karmaşık gökkuşağı gradyanları yerine sıcak kâğıt, derin mürekkep ve
/// tek imza vurgu rengi (antik pirinç/altın) kullanır.
class AppPalette {
  const AppPalette._();

  // Zemin & Kâğıt Yüzeyleri
  static const Color paper = Color(0xFFF6F2EA);
  static const Color card = Color(0xFFFFFDF9);
  static const Color cardMuted = Color(0xFFEFE9DC);
  static const Color hairline = Color(0xFFE2D9C8);
  static const Color hairlineStrong = Color(0xFFD0C4AE);

  // Mürekkep (Tipografi & Koyu Vurgu Kartları)
  static const Color ink = Color(0xFF1D1916);
  static const Color inkSurface = Color(0xFF26211D);
  static const Color inkSoft = Color(0xFF5C5349);
  static const Color inkMuted = Color(0xFF8C8174);

  // Tek İmza Marka Vurgusu: Antik Altın / Pirinç
  static const Color brass = Color(0xFFA85513);
  static const Color brassBright = Color(0xFFE5A93B);
  static const Color brassSoft = Color(0xFFFBF2E2);
  static const Color brassBorder = Color(0xFFE6CCA0);

  // Yalnızca Oyun İçi Anlamsal Durum Renkleri (Doğru / Hatalı)
  static const Color correct = Color(0xFF166534);
  static const Color correctBorder = Color(0xFF22C55E);
  static const Color correctSoft = Color(0xFFECFDF5);

  static const Color error = Color(0xFFB91C1C);
  static const Color errorBorder = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEF2F2);

  /// Konsept paketleri için yumuşatılmış, birbiriyle uyumlu editoryal mürekkep tonları.
  static Color editorialAccentForPack(String packId) {
    switch (packId) {
      case 'yesilcam':
        return const Color(0xFF9A461C); // Sepya Sinema Bronzu
      case 'ingilizce':
        return const Color(0xFF2C4A73); // Oxford Mürekkep Laciverti
      case 'turkiye':
        return const Color(0xFF1F5D57); // Boğaz Çini Yeşili
      case 'genel_kultur':
        return const Color(0xFF523C66); // Akademik Mürdüm
      default:
        return brass;
    }
  }
}
