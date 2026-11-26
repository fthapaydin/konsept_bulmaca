import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Giriş yapmış kullanıcının sade profil özeti.
class AuthUserInfo {
  const AuthUserInfo({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim();
    }
    return 'Google Oyuncusu';
  }

  String get initials {
    final source = label.trim();
    if (source.isEmpty) return 'G';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source[0].toUpperCase();
  }
}

class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.cancelled = false,
  });

  final bool success;
  final String message;
  final AuthUserInfo? user;
  final bool cancelled;
}

/// İsteğe bağlı Google ile Giriş + Hesap Silme soyutlaması.
/// İlk açılışı asla kilitlemez; misafir modunu 1. sınıf destekler.
abstract class AuthService {
  bool get isCloudAvailable;
  AuthUserInfo? get currentUser;

  Future<void> initialize();
  Future<AuthResult> signInWithGoogle();
  Future<void> signOut();
  Future<AuthResult> deleteCurrentUser();
}

/// Firebase + Google Sign-In v7 gerçek implementasyonu.
/// google-services.json henüz eklenmemişse çökmeden çevrimdışı misafir modunda kalır.
class FirebaseGoogleAuthService implements AuthService {
  bool _cloudAvailable = false;
  bool _googleInitialized = false;

  @override
  bool get isCloudAvailable => _cloudAvailable;

  @override
  AuthUserInfo? get currentUser {
    if (!_cloudAvailable) return null;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return AuthUserInfo(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _cloudAvailable = true;
    } catch (_) {
      // google-services.json eklenmediyse veya test ortamındaysa güvenle misafir moduna düş
      _cloudAvailable = false;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    if (!_cloudAvailable) {
      return const AuthResult(
        success: false,
        message:
            'Bulut girişi için Firebase yapılandırması (google-services.json) henüz aktif değil.',
      );
    }

    try {
      await _ensureGoogleSignInInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return const AuthResult(
          success: false,
          message: 'Bu cihazda Google ile giriş desteklenmiyor.',
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Google kimlik belirteci alınamadı. Lütfen tekrar deneyin.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCred.user;
      if (fbUser == null) {
        return const AuthResult(
          success: false,
          message: 'Giriş tamamlanamadı. Lütfen tekrar deneyin.',
        );
      }

      return AuthResult(
        success: true,
        message: 'Google hesabın bağlandı ve bulut yedekleme aktif!',
        user: AuthUserInfo(
          uid: fbUser.uid,
          displayName: fbUser.displayName ?? account.displayName,
          email: fbUser.email ?? account.email,
          photoUrl: fbUser.photoURL ?? account.photoUrl,
        ),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthResult(
          success: false,
          cancelled: true,
          message: 'Google girişi iptal edildi.',
        );
      }
      return AuthResult(
        success: false,
        message: 'Google girişi başarısız oldu (${e.code.name}).',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: 'Hesap bağlanamadı (${e.code}). İnternet bağlantını kontrol et.',
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Giriş sırasında beklenmedik bir sorun oluştu.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!_cloudAvailable) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
  }

  @override
  Future<AuthResult> deleteCurrentUser() async {
    if (!_cloudAvailable) {
      return const AuthResult(
        success: true,
        message: 'Yerel veriler temizlendi.',
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const AuthResult(
          success: true,
          message: 'Aktif bulut hesabı bulunamadı.',
        );
      }

      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          await _ensureGoogleSignInInitialized();
          final account = await GoogleSignIn.instance.authenticate();
          final idToken = account.authentication.idToken;
          if (idToken != null && idToken.isNotEmpty) {
            final cred = GoogleAuthProvider.credential(idToken: idToken);
            await user.reauthenticateWithCredential(cred);
            await user.delete();
          } else {
            return const AuthResult(
              success: false,
              message: 'Güvenlik doğrulaması tamamlanamadı. Tekrar deneyin.',
            );
          }
        } else {
          rethrow;
        }
      }

      try {
        if (_googleInitialized) {
          await GoogleSignIn.instance.disconnect();
        }
      } catch (_) {}

      return const AuthResult(
        success: true,
        message: 'Hesabın ve bulut verilerin kalıcı olarak silindi.',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthResult(
          success: false,
          cancelled: true,
          message: 'Hesap silme doğrulaması iptal edildi.',
        );
      }
      return const AuthResult(
        success: false,
        message: 'Hesap silinirken doğrulama hatası oluştu.',
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Hesap silinemedi. İnternet bağlantını kontrol edip tekrar dene.',
      );
    }
  }
}

/// Testler veya tamamen çevrimdışı oturumlar için sessiz misafir servisi.
class OfflineAuthService implements AuthService {
  const OfflineAuthService();

  @override
  bool get isCloudAvailable => false;

  @override
  AuthUserInfo? get currentUser => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthResult> signInWithGoogle() async => const AuthResult(
        success: false,
        message: 'Çevrimdışı modda Google girişi kullanılamıyor.',
      );

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResult> deleteCurrentUser() async => const AuthResult(
        success: true,
        message: 'Yerel veriler silindi.',
      );
}
