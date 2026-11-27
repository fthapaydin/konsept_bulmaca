import 'package:material_ui/material_ui.dart';

/// eKare Bulmaca tek yetkili editoryal tasarım sistemi (bkz. DESIGN_SPEC.md).
/// Sıcak gazete kâğıdı, derin mürekkep ve tek imza vurgu rengi (antik pirinç).
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

  // Tek İmza Marka Vurgusu: Antik Pirinç
  static const Color brass = Color(0xFFA85513);
  static const Color brassBright = Color(0xFFE5A93B);
  static const Color brassSoft = Color(0xFFFBF2E2);
  static const Color brassBorder = Color(0xFFE6CCA0);

  // Yalnızca İşlevsel Anlamsal Durum Renkleri (Doğru / Hatalı)
  static const Color correct = Color(0xFF166534);
  static const Color correctBorder = Color(0xFF22C55E);
  static const Color correctSoft = Color(0xFFECFDF5);

  static const Color error = Color(0xFFB91C1C);
  static const Color errorBorder = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEF2F2);

  /// Tüm paketlerde tek ve sakin marka vurgusunu korur (gökkuşağı renk kaymasını önler).
  static Color editorialAccentForPack(String packId) => brass;

  static ThemeData buildTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brass,
      surface: paper,
      primary: ink,
      secondary: brass,
      error: error,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: hairline),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: -0.3,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: inkSoft,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: card,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: brassBright,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: hairlineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: inkSoft),
      ),
    );
  }
}
