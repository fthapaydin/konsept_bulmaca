# Konsept Bulmaca (Android-Öncelikli Flutter Kare Bulmaca Oyunu)

Tematik konsept dünyaları, mobil ekrana en uygun kademeli ızgara boyutları (`5×5 → 8×8`), özel Türkçe/İngilizce oyun klavyesi ve Günün Bulmacası moduyla çevrimdışı oynanabilen kare bulmaca oyunu.

## Konsept Paketleri (40 Seviye + 15 Günün Bulmacası)
1. **Yeşilçam Klasikleri** (`TR`) — Efsane filmler, karakterler, oyuncular ve replikler
2. **İngilizce Kelime Avı** (`EN`) — A1'den B2'ye Türkçe ipuçlarıyla İngilizce kelime pratiği (otomatik İngilizce QWERTY klavye)
3. **Türkiye & Mutfak** (`TR`) — İller, yöresel lezzetler, doğa ve tarihi miras
4. **Genel Kültür & Bilim** (`TR`) — Uzay, teknoloji, sanat, tarih ve spor
5. **Günün Bulmacası** (`TR`) — Her gün değişen karma konsept bulmaca, günlük seri (streak) ve `2×` altın ödülü

## Optimum Mobil Seviye Eğrisi
| Seviye | Boyut | Zorluk | Başlangıç Açık Harf |
| :--- | :---: | :--- | :---: |
| 1–2 | `5×5` | Başlangıç | 2 |
| 3–4 | `6×6` | Kolay | 1 |
| 5–6 | `7×7` | Orta | 1 |
| 7 | `7×7` | Zorlu | 0 |
| 8–10 | `8×8` | Zorlu / Usta | 0 |

## Komutlar

```bash
# Yeni bulmaca paketleri üret ve matematiksel olarak doğrula
python tools/generate_puzzles.py

# Test ve statik analiz
flutter analyze
flutter test

# Android çalıştırma ve APK derleme
flutter run

# Windows'ta 'Şahsi' yolundaki Türkçe karakter için güvenli release APK derleme:
powershell -ExecutionPolicy Bypass -File tools/build_apk.ps1
```
