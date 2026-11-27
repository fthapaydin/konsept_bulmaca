# eKare Bulmaca — Spec-Driven Design Specification (`v2.1`)

Bu belge, **eKare Bulmaca (`fatalsoft.bulmaca`)** uygulamasının tüm ekranları için bağlayıcı tasarım sözleşmesidir (Spec-Driven Development). Her yeni ekran, bileşen ve görsel güncelleme aşağıdaki kurallara uymak zorundadır.

---

## 1. Tasarım Felsefesi: Sakin Editoryal Gazete Bulmacası
- **Ton:** Ciddi, dingin, yüksek okunaklılıklı, zamansız gazete-bulmaca estetiği.
- **Yasaklar ("Cıvık" Görünüm Önleme Kuralları):**
  - Çok renkli (gökkuşağı) kategori başlıkları, parlak mor/turuncu/pembe/neon butonlar ve gradyanlar **yasaktır** (`#7C3AED`, `#5B21B6`, `#EDE9FE`, `#EA580C`, `#BE123C`, `#1E1B4B`, `#FDE047`, `#1D4ED8` kullanılmaz).
  - Kartların, istatistik kutularının, puan/altın rozetlerinin, görev/mağaza satırlarının ve ipucu butonlarının içine süs amaçlı ikon yığılması **yasaktır**.
  - Uygulama logosu ve büyük amblem kutuları ekranlara rastgele dağıtılmaz.

---

## 2. Tek Yetkili Renk Paleti (`AppPalette`)

Tüm UI bileşenleri yalnızca `lib/core/theme/app_theme.dart` içindeki `AppPalette` sabitlerini kullanır:

| Rol | Token | Hex | Kullanım |
|---|---|---|---|
| Zemin (Kağıt) | `AppPalette.paper` | `#F6F2EA` | Sayfa arka planı, bottom sheet zemini |
| Kart Yüzeyi | `AppPalette.card` | `#FFFDF9` | Kartlar, diyaloglar, tuş yüzeyleri |
| İkincil Yüzey | `AppPalette.cardMuted` | `#EFE9DC` | Sekme kanalları, pasif rozetler, klavye tepsisi |
| İnce Çizgi | `AppPalette.hairline` | `#E2D9C8` | Tüm kart kenarlıkları ve ayraçlar |
| Güçlü Çizgi | `AppPalette.hairlineStrong` | `#D0C4AE` | Aktif olmayan odak çizgileri, sürükleme tutamağı |
| Ana Mürekkep | `AppPalette.ink` | `#1D1916` | Başlıklar, koyu hero kartları, birincil butonlar |
| İkincil Mürekkep | `AppPalette.inkSoft` | `#5C5349` | Gövde metinleri, ikincil butonlar |
| Soluk Mürekkep | `AppPalette.inkMuted` | `#8C8174` | Alt başlıklar, yardımcı etiketler |
| **Tek Marka Vurgusu** | `AppPalette.brass` | `#A85513` | Aktif kare, seçili ipucu, ilerleme çubuğu, vurgulu metin |
| Koyu Zemin Vurgusu | `AppPalette.brassBright` | `#E5A93B` | Koyu (`ink`) zemin üstündeki metin/yıldız vurgusu |
| Yumuşak Vurgu Zemini | `AppPalette.brassSoft` | `#FBF2E2` | Altın rozeti, aktif soru kartı zemini |
| Vurgu Kenarlığı | `AppPalette.brassBorder` | `#E6CCA0` | `brassSoft` yüzey kenarlığı |
| Doğru (Anlamsal) | `AppPalette.correct` | `#166534` | **Sadece** çözülen kelime/tamamlanan durum |
| Hata (Anlamsal) | `AppPalette.error` | `#B91C1C` | **Sadece** hatalı kelime/harf, kritik uyarı, silme |

> Tüm konsept paketleri (Yeşilçam, İngilizce, Türkiye, Genel Kültür ve Dev Bulmacalar) aynı `AppPalette.ink` + `AppPalette.brass` sistemini kullanır; paketler renk cümbüşüyle değil, sade tipografi ve etiketlerle (`01`..`04`, `TR` / `EN`) ayrışır.

---

## 3. Logo ve İkon Kısıtlama Kuralları

### 3.1 Uygulama Logosu (`ekare_icon.png`)
Uygulama logosu **yalnızca şu 3 yerde** kullanılabilir:
1. Açılış ekranı (`EkareSplashView`)
2. Ana ekran üst başlığı (`HomeScreen` sol üst `38×38`)
3. Ayarlar → Hakkında bloğu (`StatsAndSettingsSheet`)

### 3.2 İzin Verilen İkonlar (Yalnızca İşlevsel Gezinme / Kontrol)
- Geri (`arrow_back_ios_new_rounded`), Kapat (`close_rounded`), Ayarlar (`tune_rounded`), Tema (`palette_outlined`), Sıfırla (`refresh_rounded`), İleri/Geri ok (`chevron_left/right_rounded`), Arama (`search_rounded`), Klavye Sil (`backspace_outlined`), Klavye Yön (`swap_horiz/vert_rounded`), Kilitli durum (`lock_outline_rounded`), Yıldız puanı (`star_rounded` / `star_outline_rounded` — yalnızca kazanılan yıldız gösteriminde).

### 3.3 Kaldırılan Süs İkonları & Amblemleri
- Ana ekran kartlarındaki kutulu amblem/logo blokları kaldırılır; yerine yalın tipografik etiketler (`01`..`04`, `90 SN`, `A1–B1`, `12×12–20×20`) kullanılır.
- Puan (`P`) ve Altın rozetlerinde şimşek (`bolt`) ve para (`monetization_on`) ikonları **kullanılmaz**; sade metin (`390 Altın`, `1200 P`) kullanılır.
- Oyun içi joker butonlarında (`Harf`, `Kelime`, `Kontrol`, `Sorular`) ve kombo bandında süs ikonu kullanılmaz.
- Ödül/Görevler ve Mağaza satırlarında renkli ikon kareleri kullanılmaz; temiz tipografi, ilerleme çubuğu ve tek renkli (`ink` / `brass`) aksiyon butonları kullanılır.
- Diyalog (Kutlama, Kilit Açma, Mini Sprint Bitiş) metrik kartlarında ve aksiyon butonlarında süs ikonu kullanılmaz.

---

## 4. Ekran Bazlı Kabul Kriterleri
1. **Ana Ekran (`HomeScreen`):** Tek logo üst başlıkta; sakin `ink` Günün Bulmacası kartı, ikonsuz Rütbe şeridi, ikonsuz Mini Sprint & Kelime Defteri kartları, numaralı (`01`–`04`) sakin Konsept Paketleri ve sade Dev Bulmacalar şeridi.
2. **Seviye Haritası (`PackLevelsScreen`):** Tüm paketlerde tutarlı `ink` üst başlık, ikonsuz bilgi etiketleri, `ink` "Oyna/Devam Et" butonu ve temiz 2 sütunlu seviye kartları.
3. **Oyun Ekranı (`GameScreen`) & Mini Sprint (`MiniSprintScreen`):** Birleşik `paper`/`ink`/`brass` arayüz, ikonsuz joker çubuğu, sakin `ink` kombo bandı, yeni eşit-genişlikli editöryel klavye, çözülmüş kesişen harf koruması ve aktif soruya odaklanan Sorular sayfası.
4. **Ödül & Mağaza (`RewardsCenterSheet`):** Tamamen `AppPalette` üzerinde çalışan, ikonsuz sekme ve görev/paket satırları.
5. **Arka Plan Galerisi (`BackgroundGalleryScreen`) & Dev Bulmacalar (`MegaPuzzlesScreen`):** Gökkuşağı renklerden arındırılmış, tutarlı `ink`/`brass` kart ve buton dili.
6. **Kutlama Diyaloğu (`CompletionDialog`):** Sakin `card` zemin, `brassBright` yıldızlar, ikonsuz 3'lü metrik satırı ve tek `ink` birincil buton.

---

## 5. Doğrulama Kriterleri (Definition of Done)
- `flutter analyze --no-pub` → **0 hata / 0 uyarı**
- `flutter test --no-pub` → **Tüm testler %100 başarılı**
- UI katmanında (`lib/screens/`, `lib/widgets/`, `lib/features/`) yasaklı parlak/gökkuşağı hex kodları (`#7C3AED`, `#5B21B6`, `#EDE9FE`, `#EA580C`, `#BE123C`, `#1E1B4B`, `#FDE047`, `#1D4ED8`) **0 adet**
- Güncel ekran görüntülerinin görsel olarak denetlenmesi (Ana Ekran, Oyun, Mağaza, Dev Bulmacalar, Arka Plan Galerisi, Kutlama, Mini Sprint)
- İmzalı Android Release APK üretimi ve imza doğrulaması (`apksigner`)
