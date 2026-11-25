# eKare Bulmaca (`fatalsoft.bulmaca`) — Gelir Modeli ve 90 Günlük Büyüme Yol Haritası

**Geliştirici:** FatalSoft Inc. (`fatalsoft.inc@gmail.com`)  
**Mevcut Durum:** `v1.0.0+1` imzalı `.aab` hazır, 117 doğrulanmış bulmaca (paket içi %0 tekrar), 90sn Mini Sprint, İki Sütunlu EN–TR Sözlük, 12×12–20×20 Dev Bulmacalar, sade gazete editoryal tasarım ve hazır `RewardAdService` arayüzü.

---

## 1. Ürünün Pazardaki Güçlü Yönleri (Neden Para Kazandırır?)

Türkiye Google Play'de **kare bulmaca ve kelime oyunları** en yüksek günlük geri dönüş (retention) oranına sahip kategorilerden biridir (25–65 yaş geniş kitle, otobüste/kahve molasında/akşam günlük alışkanlık). **eKare Bulmaca**'yı klasik rakiplerden ayıran 3 güçlü koz:

1. **Konsept Dünyaları (Yüksek Merak & İçerik Genişletilebilirliği):** *Yeşilçam*, *Türkiye & Mutfak*, *İngilizce A1–B1* ve *Genel Kültür* gibi temalar hem organik aramalarda niş kelimeleri yakalar hem de her ay yeni paketlerle oyuncuyu geri getirir.
2. **Eğlence + İngilizce Öğrenme Kesişimi:** İki sütunlu `İngilizce | Türkçe` Kelime Defteri, *"Anlamı Gizle"* ve Kart Tekrarı özelliği; oyunu sadece vakit geçirme değil, *"faydalı alışkanlık"* konumuna taşır. Bu kitlede **ödeme isteği ve reklam eCPM değeri** klasik oyunlardan daha yüksektir.
3. **Altyapı Gelir Elde Etmeye Zaten Hazır:** Artan ipucu fiyatlandırması (`10 → 15 → 25 → 40`), Puan/Altın çift ekonomisi, 10 tema ve soyutlanmış `RewardAdService` kodu halihazırda projede mevcut.

---

## 2. Hibrit Gelir Modeli (Oyuncuyu Kaçırmadan Gelir Maksimizasyonu)

Kare bulmaca oyuncusu agresif reklamdan nefret eder; 1 yıldızlı yorumların %80'i *"her tıklamada reklam çıkıyor"* şikayetidir. Bu yüzden **Ödüllü Reklam + Yumuşak Geçiş + Reklamsız Satın Alma** dengesi kurulmalıdır:

### A. Ödüllü Video Reklamlar (Google AdMob — Toplam Gelirin ~%55–65'i)
Oyuncu reklamı **kendi isteğiyle** ödül için izler; hem memnuniyet yüksek kalır hem de en yüksek eCPM buradan gelir:
1. **Altın/İpucu Bittiğinde:** *"Video İzle → +30 Altın"* veya *"Ücretsiz 1 Harf Aç"* (mevcut `10 → 15 → 25 → 40` artan ipucu eğrisiyle doğal talep yaratır).
2. **90sn Mini Sprint Ek Süre (En Yüksek Dönüşüm!):** 90 saniye dolduğunda rekor kırmaya yakın oyuncuya tur başına 1 kez *"Reklam İzle → +20 Saniye Devam Et"*.
3. **Bölüm Sonu 2× Ödül:** Bölüm tamamlandığında *"İzle → Kazandığın Altını 2'ye Katla"*.
4. **Günlük Hediye 2×:** `40 Altın` yerine `80 Altın` alma seçeneği.

### B. Kontrollü Geçiş Reklamları (Interstitial — Toplam Gelirin ~%15–20'si)
- **İlk 3 bölümde 0 zorunlu reklam** (oyuncu önce oyunun kalitesini görsün).
- Sonrasında yalnızca **her 3 bölüm bitişinde 1 kez** ve **en az 3 dakika aralıkla** (oyun ortasında ASLA çıkmaz).
- **Oyun ekranında alt banner reklam KULLANMA:** Özel klavye tuşlarına yanlış tıklama yaratır, hem kullanıcıyı kızdırır hem AdMob geçersiz trafik riskine yol açar.

### C. Uygulama İçi Satın Alımlar (Google Play Billing — Toplam Gelirin ~%20–30'u)
| Ürün | Tür | Önerilen TR Fiyatı | Neden Satar? |
| :--- | :--- | :--- | :--- |
| **Reklamsız Oyna + 300 Altın** | Tek seferlik | `49,99 ₺ – 69,99 ₺` | Türkiye'de bulmaca oyunlarının en çok satan ürünü. Zorunlu geçiş reklamlarını kalıcı kapatır. |
| **Başlangıç Destek Paketi** | Tek seferlik (1 kez) | `29,99 ₺` | `500 Altın + 5 Harf + 3 Kelime İpucu` (ilk gün teklifi). |
| **İpucu & Altın Sandıkları** | Tüketilebilir | `39,99 ₺ / 89,99 ₺ / 169,99 ₺` | Özellikle `15×15` ve `20×20` Dev Bulmaca seven oyuncular alır. |
| **eKare Plus (İleri Aşama)** | Aylık / Yıllık Abonelik | `39,99 ₺/ay` veya `299 ₺/yıl` | Reklamsız + sınırsız Hata Kontrolü + tüm temalar + tüm Dev Bulmacalar + İngilizce sesli telaffuz. |

---

## 3. Gerçekçi Gelir Projeksiyonu (Türkiye + Avrupa Türk Diasporası)

> **Önemli Strateji:** Google Play'de oyunu yalnızca Türkiye'ye değil; **Almanya, Hollanda, Avusturya, Belçika, Fransa, İngiltere, İsviçre ve ABD** ülkelerine de mutlaka açık yayınlayın. Bu ülkelerdeki Türkçe konuşan oyuncuların AdMob eCPM değeri Türkiye'nin **3×–5× katıdır**!

Ortalama varsayımlar (hibrit TR + %20 Avrupa trafiği, oyuncu başı günde ~2 ödüllü + ~1 geçiş reklamı, %1,5 IAP dönüşümü):

| Günlük Aktif Kullanıcı (DAU) | Aylık Tahmini Reklam Geliri | Aylık Tahmini IAP Geliri | Toplam Tahmini Aylık Gelir |
| :--- | :--- | :--- | :--- |
| **500 DAU** *(Başlangıç)* | `$120 – $250` | `$40 – $90` | **`$160 – $340 / ay`** |
| **2.000 DAU** *(İlk Büyüme)* | `$500 – $1.000` | `$180 – $380` | **`$680 – $1.380 / ay`** |
| **10.000 DAU** *(Oturmuş Oyun)* | `$2.600 – $5.200` | `$950 – $2.000` | **`$3.550 – $7.200 / ay`** |
| **30.000 DAU** *(Kategori Liderleri)* | `$8.000 – $15.000` | `$3.000 – $6.500` | **`$11.000 – $21.500 / ay`** |

*(Not: Rakamlar kategori ortalamalarına dayalı tahmindir; elde tutma oranı D7 > %15 ve puanlama > 4.5★ olduğunda üst banda yaklaşılır.)*

---

## 4. 90 Günlük Aşamalı İlerleme Yol Haritası

### Faz 1 (Gün 1–14): Yayın, Ölçüm ve İlk Gelir Altyapısı (`v1.0 → v1.1`)
- [ ] **Google Play Yayın Süreci:** Kapalı test (kişisel hesapta 12 test kullanıcısı × 14 gün) tamamlanıp Üretim'e çıkılır; tüm Avrupa/ABD diasporası ülkeleri açılır.
- [ ] **Firebase Analytics + Crashlytics:** Hangi bölümde oyuncuların en çok zorlandığı, D1/D7 geri dönüş oranları ve çökme raporları izlenir.
- [ ] **Google AdMob Entegrasyonu (`google_mobile_ads`):** Mevcut `PlaceholderRewardAdService` yerine gerçek `AdMobRewardAdService` bağlanır (Ödüllü Video + 3 bölümde 1 yumuşak geçiş reklamı).
- [ ] **`docs/app-ads.txt` Yayını:** AdMob yayıncı satırı web sitemize (`docs/app-ads.txt`) eklenir.
- [ ] **Gizlilik Politikası & Veri Güvenliği Güncellemesi:** AdMob ve Firebase eklendiğinde `docs/privacy-policy.html` ve Play Console Data Safety formu güncellenir.

### Faz 2 (Gün 15–45): Tutundurma (Retention) & Satın Alma Motoru (`v1.2`)
- [ ] **Google Play Billing (`in_app_purchase`):** *"Reklamsız Oyna + 300 Altın"* ve altın/ipucu paketleri Puan Mağazası'na eklenir.
- [ ] **Mini Sprint "+20sn Ek Süre" & Bölüm Sonu "2× Altın":** En yüksek gelir getiren iki ödüllü reklam noktası devreye alınır.
- [ ] **Akıllı Yerel Hatırlatmalar (`flutter_local_notifications`):** Oyuncuyu rahatsız etmeden, sadece günün bulmacasını çözmediyse akşam 20:30'da tek nazik bildirim (*"Günün Bulmacası hazır — serini koru!"*). D7 geri dönüşü %30–50 artırır.
- [ ] **İngilizce Sözlüğe Sesli Telaffuz (`flutter_tts`):** Kelime Defterim'de her İngilizce kelimenin yanına telaffuz dinleme butonu eklenir (büyük kullanıcı sevgisi ve 5★ yorum kaynağı!).
- [ ] **Akıllı Mağaza Puanlama İsteği (`in_app_review`):** Oyuncu 5. bölümü 3 yıldızla bitirdiği mutlu anda (asla hata yaptıktan sonra değil!) tek seferlik nazik puanlama isteği gösterilir.

### Faz 3 (Gün 46–75): Viral Büyüme, ASO & Yeni İçerik Dalgaları (`v1.3`)
- [ ] **Wordle Tarzı Gazete Kupürü Paylaşım Kartı:** Günün Bulmacası veya Mini Sprint bitince WhatsApp / Instagram Story'de tek dokunuşla paylaşılabilir görsel skor kartı (*"eKare Bulmaca • 25 Kasım • 01:08 • 3★ • 4× Kombo"*). Sıfır maliyetli organik indirme motoru!
- [ ] **2 Yeni Yüksek Talep Konsept Paketi (0 Kelime Tekrarlı):**
  - *90'lar & Türkçe Müzik* (20 bölüm — çok yüksek sosyal medya paylaşımı)
  - *YKS / YDS İngilizce (B1–B2)* (20 bölüm — öğrenci & genç yetişkin kitlesi)
- [ ] **Play Console ASO & A/B Testleri:** İkon, özellik grafiği ve ekran görüntüsü sıralaması için Google Play Store Listing Experiments açılır; Türkçe arama kelimeleri (*kare bulmaca, internetsiz bulmaca, yeşilçam bulmaca, ingilizce kelime bulmaca*) performansına göre başlık/alt başlık optimize edilir.
- [ ] **Kısa Video İçerikleri (Ücretsiz Trafik):** TikTok / Instagram Reels / YouTube Shorts'ta haftada 3 adet 15 saniyelik *"Bu Yeşilçam sorusunu 5 saniyede bilebilir misin?"* veya *"90sn Mini Sprint rekor denemesi"* videoları (açıklamada Play Store linki).

### Faz 4 (Gün 76–90+): Ölçekleme & Sürekli Gelir (`v2.0`)
- [ ] **Haftalık Mini Sprint Liderlik Tablosu:** Hafif bulut skor tablosu (Google Play Games Services / Firestore) ile haftalık rekabet ve ödüller.
- [ ] **Uzaktan İçerik Güncelleme (Remote Puzzle Packs):** Uygulama güncellemesi gerektirmeden her ay yeni *Günün Bulmacası* takvimi ve yeni konsept paketleri indirebilme.
- [ ] **Kârlı Reklam Ölçekleme (Google App Campaigns):** Organik veride **Kullanıcı Başı Ömür Boyu Gelir (LTV) > Kurulum Maliyeti (CPI)** kanıtlandıktan sonra küçük günlük bütçeyle (`100–250 ₺/gün`) Türkiye + Almanya/Hollanda Türkçe hedeflemesiyle büyüme test edilir.

---

## 5. Kritik Kurallar & Uzak Durulacak Hatalar

1. **AdMob Hesap Güvenliği:** Geliştirme ve test sırasında **her zaman Google'ın resmi Test Ad Unit ID'lerini** kullan; kendi canlı reklamlarına asla tıklama (kalıcı AdMob ban sebebidir).
2. **İlk 30 Günde Hemen Reklama Para Yakma:** Önce organik ilk 200–500 oyuncuda **D1 (> %35)**, **D7 (> %15)** ve **Crash-free (> %99.5)** metriklerini doğrula; sızıntısı olan kovaya reklam bütçesi harcama.
3. **Veri Odaklı Zorluk Ayarı:** Analytics'te oyuncuların %40'ından fazlasının takılıp çıktığı bir seviye görürsen o bölümün ipuçlarını/açık harflerini anında iyileştir.
4. **Sürekli Canlılık:** Play Store algoritması 3–4 haftada bir düzenli güncellenen (yeni paket / küçük iyileştirme) uygulamaları aramalarda yukarı taşır.
