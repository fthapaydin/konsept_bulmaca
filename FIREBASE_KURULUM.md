# eKare Bulmaca — Google ile Giriş & Bulut Yedekleme Aktivasyon Rehberi (3 Dakika)

Uygulama içindeki **tüm Flutter kodu, akıllı yerel–bulut birleştirme (`ProfileMerger`), Gradle eklentisi, Hesap Silme ekranı ve Play Console web sayfaları** tamamen hazırdır.

Google ile Giriş ve Firestore Bulut Yedekleme'yi canlıya almak için yalnızca kendi Firebase hesabınızdan tek bir dosya (`google-services.json`) eklemeniz yeterlidir:

### 1. Firebase Projesi Oluşturun
1. https://console.firebase.google.com adresine gidin ve **Proje ekle** → ör. `eKare Bulmaca` oluşturun.
2. **Android uygulaması ekle** simgesine tıklayın:
   - **Android paket adı:** `fatalsoft.bulmaca`
   - **Uygulama takma adı:** `eKare Bulmaca`
   - **SHA-1 Sertifika Parmak İzi (Upload Keystore — hazır):**
     ```text
     20:5E:E0:3B:93:84:35:7E:B4:C9:2E:9F:78:F0:19:88:2F:8E:D4:D8
     ```
   - *(Önerilen)* **SHA-256 Parmak İzi:**
     ```text
     5E:CB:61:5C:B6:DF:DA:AC:9A:62:06:25:A5:72:75:1A:2E:D0:08:3F:57:A1:1D:08:F3:7E:C4:89:3D:69:2E:AB
     ```
3. İndirilen **`google-services.json`** dosyasını projede şu klasöre kopyalayın:
   ```text
   android/app/google-services.json
   ```

### 2. Google Play App Signing SHA-1'i Ekleyin *(Play Store Kullanıcıları İçin Zorunlu!)*
- Google Play Console → **eKare Bulmaca** → **Test et ve yayınla → Kurulum → Uygulama imzalama** sayfasındaki **"Uygulama imzalama anahtarı sertifikası" SHA-1** değerini kopyalayıp Firebase → Proje Ayarları → Android uygulamanıza **ikinci SHA-1** olarak ekleyin.

### 3. Firebase Console'da İki Servisi Açın
1. **Authentication → Sign-in method → Google → Etkinleştir → Kaydet** (Destek e-postası: `fatalsoft.inc@gmail.com`).
2. **Firestore Database → Veritabanı oluştur (Production mode, `eur3` Avrupa)** ve **Rules** sekmesine şu güvenli kuralı yapıştırın:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### 4. Yeni İmzalı Sürümü Derleyin
```powershell
powershell -ExecutionPolicy Bypass -File tools/build_release.ps1
```
Gradle `android/app/google-services.json` dosyasını otomatik algılar ve Google ile Giriş + Bulut Yedekleme doğrudan aktifleşir!

> **Not:** `google-services.json` henüz eklenmediyse bile uygulama asla çökmez; kullanıcılar %100 çevrimdışı misafir modunda sorunsuz oynamaya devam eder.
