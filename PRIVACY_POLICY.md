# Gizlilik Politikası — eKare Bulmaca (`fatalsoft.bulmaca`)

**Uygulama:** eKare Bulmaca  
**Paket Adı:** `fatalsoft.bulmaca`  
**Geliştirici:** FatalSoft Inc.  
**İletişim:** `fatalsoft.inc@gmail.com`  
**Son Güncelleme:** 26 Kasım 2026  

---

## Türkçe

**Özet:** eKare Bulmaca misafir olarak tamamen çevrimdışı oynanır (giriş zorunlu değildir). Yalnızca kullanıcı kendi isteğiyle **Google ile Bağla** seçeneğini kullanırsa, ilerlemeyi bulutta yedeklemek için Firebase Authentication ve Cloud Firestore kullanılır.

1. **Toplanan Veriler:** Misafir modunda hiçbir kişisel veri toplanmaz. İsteğe bağlı Google girişi yapıldığında yalnızca kullanıcı kimliği (UID), ad, e-posta ve oyun yedeği cihazlar arası senkronizasyon amacıyla saklanır; üçüncü taraflara satılmaz.
2. **Yerel Depolama:** Bulmaca ilerlemeniz, yıldızlarınız, puan/altın bakiyeniz, Mini Sprint rekorunuz, İngilizce Kelime Defteri kayıtlarınız ve ses/titreşim tercihleriniz cihazınızda yerel olarak (`SharedPreferences`) saklanır.
3. **Veri ve Hesap Silme:** Uygulama içindeki *İstatistikler ve Ayarlar → Hesabı ve Bulut Verilerini Sil* seçeneğiyle bulut hesabınızı ve tüm verilerinizi anında kalıcı olarak silebilir veya `fatalsoft.inc@gmail.com` adresinden silme talep edebilirsiniz (`docs/delete-account.html`).
4. **Üçüncü Taraf Hizmetler:** Uygulamada üçüncü taraf reklam veya takip (tracking) SDK'sı bulunmamaktadır. Yalnızca kullanıcı isteğe bağlı Google girişi yaptığında Google Firebase Authentication ve Cloud Firestore bulut yedekleme için kullanılır. İleride isteğe bağlı ödüllü reklam eklenirse bu politika ve Google Play Veri Güvenliği beyanı önceden güncellenecektir.
5. **Çocukların Gizliliği:** 13 yaş altı çocuklar dahil hiçbir kullanıcıdan bilerek kişisel veri toplanmaz.
6. **İletişim:** Her türlü soru ve talebiniz için `fatalsoft.inc@gmail.com` adresinden bize ulaşabilirsiniz.

---

## English

**Summary:** eKare Bulmaca is playable fully offline as a guest with no login required. Only if you optionally choose **Sign in with Google** to back up progress across devices, Firebase Authentication and Cloud Firestore store your account identifier and gameplay progress backup.

1. **Information We Collect:** In Guest Mode, zero personal information is collected or transmitted. If you optionally link a Google account, only your Firebase UID, display name, email address, and gameplay progress backup are stored solely for cross-device cloud sync; data is never sold to third parties.
2. **On-Device Storage:** Game progress, scores, coins, Word Notebook entries, and preferences are stored locally on your device (`SharedPreferences`).
3. **Account & Data Deletion:** Delete local data anytime via *Settings → Reset All Progress*, or permanently delete your Google-linked Firebase account and cloud backup via *Settings → Delete Account & Cloud Data* (or request deletion via `fatalsoft.inc@gmail.com` / `docs/delete-account.html`).
4. **Third-Party Services:** The app contains no third-party advertising or tracking SDKs. Google Firebase Authentication and Cloud Firestore are used strictly when a user opts into cloud backup. If optional rewarded ads are introduced later, this policy and the Google Play Data Safety form will be updated beforehand.
5. **Children's Privacy:** We do not knowingly collect personal data from children under 13 or any other users.
6. **Contact:** FatalSoft Inc. — `fatalsoft.inc@gmail.com`
