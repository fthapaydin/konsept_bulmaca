# Konsept Bulmaca (Android-Öncelikli Flutter Kare Bulmaca Oyunu)

Tamamen Türkçe arayüzlü, tematik konsept dünyaları, mobil ekrana en uygun kademeli ızgara boyutları (`5×5 → 8×8`), belirgin kare çizgileri, seçilebilir & ilerleyerek açılabilir 8 sanatsal arka plan, rütbe/görev sistemi ve Günün Bulmacası moduyla çevrimdışı oynanabilen kare bulmaca oyunu.

## Konsept Paketleri (80 Seviye + 15 Günün Bulmacası = 95 Doğrulanmış Bulmaca)
1. **Yeşilçam Klasikleri** (`TR` — 20 seviye) — Efsane filmler, karakterler, oyuncular ve replikler
2. **İngilizce Kelime Avı** (`EN` — 20 seviye) — Türkiye'de günlük hayattan kolayca çözülebilecek A1–A2–basit B1 kelimeler (otomatik İngilizce QWERTY klavye)
3. **Türkiye & Mutfak** (`TR` — 20 seviye) — İller, yöresel lezzetler, doğa ve tarihi miras
4. **Genel Kültür & Bilim** (`TR` — 20 seviye) — Uzay, teknoloji, sanat, tarih ve spor
5. **Günün Bulmacası** (`TR` — 15 karma bulmaca) — Her gün değişen bulmaca, günlük seri (streak) ve `2×` altın ödülü

## Optimum Mobil 20 Seviyeli Zorluk Eğrisi
| Seviye | Boyut | Zorluk | Başlangıç Açık Harf |
| :--- | :---: | :--- | :---: |
| 1–4 | `5×5` | Başlangıç | 1–2 |
| 5–9 | `6×6` | Kolay | 1–2 |
| 10–14 | `7×7` | Orta | 0–1 |
| 15–17 | `7×7` – `8×8` | Zorlu | 0 |
| 18–20 | `8×8` | Usta | 0 |

## Oyuncuyu Bağlayan Özellikler
- **8 Sanatsal Arka Plan:** Konsept Atmosferi, Pazar Gazetesi, Gece Yarısı (Koyu Mod), Yeşilçam Perdesi, Ege Kıyısı, Kapadokya Şafağı, Kuzey Işıkları ve Altın Galaksi (ilerleyerek ücretsiz açılır veya altınla erken alınır)
- **Canlı Animasyonlar:** Harf yerleştirme pop-in efekti, doğru kelimede yeşil parlama & seri bildirimi, bölüm sonunda konfeti yağmuru ve yaylı 3 yıldız kutlaması
- **Rütbe, Görevler & Jeton Merkezi:** 6 oyuncu rütbesi, 8 ödüllü ilerleme görevi, günlük `+40` hediye altın ve ileride AdMob bağlamaya hazır ödüllü video servis katmanı (`RewardAdService`)

## Komutlar

```bash
# 95 bulmacayı yeniden üret ve matematiksel olarak doğrula
python tools/generate_puzzles.py

# Test ve statik analiz
flutter analyze
flutter test

# Android çalıştırma ve release APK derleme
flutter run
powershell -ExecutionPolicy Bypass -File tools/build_apk.ps1
```
