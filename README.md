# eKare Bulmaca — Konsept Kare Bulmaca Dünyası (Android-Öncelikli Flutter)

Tamamen Türkçe arayüzlü, modüler mimarili, **0 kelime tekrarlı** tematik kare bulmacalar (`5×5 – 8×8`), **90 Saniyelik Mini Sprint (Hız Modu)**, **İngilizce Kelime Defteri (A1–B1 + Kart Tekrarı)**, **Dinamik Artan İpucu Fiyatlandırması (`10 → 15 → 25 → 40 → 60...`)**, **Dev Bulmacalar (`12×12`, `15×15`, `20×20`)**, **Katlanarak Artan Kombo Sistemi**, **Özel Uygulama İkonu + Açılış Ekranı + 8 Parçalı Ses Paketi** ve **10 sanatsal arka plan** içeren çevrimdışı Android bulmaca oyunu.

## İçerik Özeti (Toplam 117 Doğrulanmış Bulmaca — Paket İçi %0 Kelime Tekrarı!)
- **4 Konsept Paketi × 20 Seviye = 80 Benzersiz Bulmaca** (`5×5 → 6×6 → 7×7 → 8×8`):
  1. **Yeşilçam Klasikleri** (`TR` — 146 benzersiz kelime, 0 tekrar)
  2. **İngilizce Kelime Avı** (`EN` — 143 benzersiz A1–A2–B1 kelime, 0 tekrar)
  3. **Türkiye & Mutfak** (`TR` — 138 benzersiz kelime, 0 tekrar)
  4. **Genel Kültür & Bilim** (`TR` — 143 benzersiz kelime, 0 tekrar)
- **90sn Mini Sprint (Hız Modu):** 16 adet `5×5` hızlı bulmaca (`+5sn` kelime bonusu, `+15sn` tahta bonusu, `-5sn` pas, canlı kombo & rekor takibi)
- **İngilizce Kelime Defteri:** Çözülen tüm İngilizce kelimeleri Türkçe anlamı ve CEFR seviyesi (`A1/A2/B1`) ile otomatik kaydeder; arama, seviye/favori filtresi ve **Kart Tekrarı (Flashcard)** modu sunar.
- **Günün Bulmacası:** 15 karma günlük bulmaca, seri (streak) takibi ve `2×` altın ödülü
- **Dev Bulmacalar Arenası (6 Büyük Bulmaca):** `12×12` (×2), `15×15` (×3), `20×20` (46 bağlantılı kelime, yakınlaştır/kaydır + otomatik odak)

## Ekonomi & Dinamik İpucu Fiyatlandırması
- **Artan İpucu Eğrisi:** Ücretsiz ipucu hakları bittikten sonra aynı bölüm içinde harf ipucu bedeli adım adım artar (`10 → 15 → 25 → 40 → 60 → 85 → 115 → 150` Altın; Kelime: `25 → 40 → 60 → 85...`). Altın yetmediğinde otomatik olarak **Puan (`4×`)** ile ödenebilir.
- **Katlanarak Artan Kombo:** İpucusuz ardışık doğru kelimelerde `1× (+5 Altın/+20 Puan) → 2× (+10/+40) → 3× (+20/+80) → 4× (+40/+160) → 5×+ (+60..120 Altın)`.
- **Puan Mağazası & 12 Başarım Görevi:** Puan/Altın ile ipucu paketleri, Puan–Altın takası, 10 arka plan teması ve Dev Bulmaca erken açılımları.

## Modüler Klasör Mimarisi
```text
lib/
├── core/
│   ├── brand/brand_config.dart       # Merkezi marka (eKare Bulmaca) & modül tanımları
│   ├── economy/hint_pricing.dart     # Artan ipucu fiyatlandırma eğrisi
│   └── models/notebook_models.dart   # Kelime Defteri & CEFR ayrıştırıcı
├── features/
│   ├── sprint/mini_sprint_screen.dart      # 90sn Mini Sprint hız modu
│   └── notebook/word_notebook_screen.dart  # İngilizce Kelime Defteri & Kart Tekrarı
├── models/                           # Bulmaca, arka plan ve görev modelleri
├── services/                         # Offline depo, depolama, özel ses & haptik motoru
├── state/                            # AppState ve GameController
├── screens/                          # Ana ekran, seviye haritası, oyun, Dev Bulmacalar, galeri
└── widgets/                          # Izgara, TR/EN klavye, konfeti, ödül & mağaza
```

## Komutlar

```bash
# Tüm 117 benzersiz bulmacayı üret ve 0-tekrar doğrula
python tools/generate_puzzles.py

# Özel ses efektleri (8 WAV) ve uygulama ikonlarını yeniden üret
python tools/generate_sounds.py
powershell -ExecutionPolicy Bypass -File tools/install_app_icon.ps1

# Statik analiz ve testler (0-tekrar testi dahil)
dart analyze lib test tools/capture_screenshots_test.dart
flutter test

# Android çalıştırma, release APK ve Google Play imzalı AAB derleme
flutter run
powershell -ExecutionPolicy Bypass -File tools/build_apk.ps1
powershell -ExecutionPolicy Bypass -File tools/build_release.ps1
```

## Geliştirici & İletişim
- **Geliştirici:** FatalSoft Inc.
- **Android Paket Adı (`applicationId`):** `fatalsoft.bulmaca`
- **İletişim E-posta:** `fatalsoft.inc@gmail.com`
- **Gizlilik Politikası:** https://fthapaydin.github.io/konsept_bulmaca/privacy-policy.html
