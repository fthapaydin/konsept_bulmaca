# Konsept Bulmaca (Android-Öncelikli Flutter Kare Bulmaca Oyunu)

Tamamen Türkçe arayüzlü, tematik konsept dünyaları (`5×5 → 8×8`), ilerledikçe açılan **Dev Bulmacalar (`12×12`, `15×15`, `20×20` — yakınlaştır & kaydır + otomatik odak)**, katlanarak artan **Kombo Sistemi**, **Puan & Altın Mağazası**, **10 sanatsal arka plan** ve **Günün Bulmacası** moduyla çevrimdışı oynanabilen kare bulmaca oyunu.

## İçerik Özeti (Toplam 101 Doğrulanmış Bulmaca)
- **4 Konsept Paketi × 20 Seviye = 80 Bulmaca** (`5×5 → 6×6 → 7×7 → 8×8`):
  1. **Yeşilçam Klasikleri** (`TR`)
  2. **İngilizce Kelime Avı** (`EN` — Türkiye'de kolayca çözülebilen A1–A2–basit B1 kelimeler)
  3. **Türkiye & Mutfak** (`TR`)
  4. **Genel Kültür & Bilim** (`TR`)
- **Günün Bulmacası:** 15 karma günlük bulmaca, seri (streak) takibi ve `2×` altın ödülü
- **Dev Bulmacalar Arenası (6 Büyük Bulmaca):**
  - 2 adet `12×12` (*Yeşilçam Dev Gala*, *Türkiye Dev Haritası*)
  - 3 adet `15×15` (*İngilizce Mega Pratik*, *Bilim & Kültür Maratonu*, *Büyük Anadolu Efsanesi*)
  - 1 adet `20×20` (*20×20 Büyük Şampiyona* — 46 bağlantılı kelime, `3×` ödül!)

## Kombo, Puan & Altın Ekonomisi
- **Katlanarak Artan Kombo:** İpucusuz ve hatasız arka arkaya doğru kelime bildikçe ödül katlanır:
  - `1. Kelime`: `+5 Altın` • `+20 Puan`
  - `2× Kombo`: `+10 Altın` • `+40 Puan`
  - `3× Kombo`: `+20 Altın` • `+80 Puan`
  - `4× Kombo`: `+40 Altın` • `+160 Puan`
  - `5×+ Kombo`: `+60 → +120 Altın` • `+240 → +480 Puan`
- **Puan Mağazası:** Kazanılan **Puan** veya **Altın** ile indirimli Harf / Kelime / Hata Kontrolü ipucu paketleri, **Puan → Altın** takası, **10 arka plan teması** ve Dev Bulmaca erken açılımları yapılabilir.

## Komutlar

```bash
# Tüm 101 bulmacayı üret ve doğrula (sadece dev bulmacalar için --mega-only)
python tools/generate_puzzles.py

# Test ve statik analiz
flutter analyze
flutter test

# Android çalıştırma ve release APK derleme
flutter run
powershell -ExecutionPolicy Bypass -File tools/build_apk.ps1
```
