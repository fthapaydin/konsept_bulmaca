import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/brand/brand_config.dart';
import '../models/puzzle_models.dart';

/// Cloud Firestore üzerinde kullanıcı profilini (`users/{uid}`) yedekleyen servis.
abstract class CloudSyncService {
  Future<PlayerProfile?> fetchProfile(String uid);
  Future<bool> pushProfile(String uid, PlayerProfile profile);
  Future<void> deleteCloudProfile(String uid);
}

class FirestoreCloudSyncService implements CloudSyncService {
  static const String _collection = 'users';
  static const Duration _timeout = Duration(seconds: 6);

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection(_collection).doc(uid);

  @override
  Future<PlayerProfile?> fetchProfile(String uid) async {
    try {
      final snap = await _doc(uid).get().timeout(_timeout);
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final rawProfile = data['profile'];
      if (rawProfile is Map<String, dynamic>) {
        return PlayerProfile.fromJson(rawProfile);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> pushProfile(String uid, PlayerProfile profile) async {
    try {
      await _doc(uid)
          .set(
            {
              'profile': profile.toJson(),
              'appVersion': BrandConfig.versionLabel,
              'packageId': BrandConfig.androidPackageId,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          )
          .timeout(_timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteCloudProfile(String uid) async {
    try {
      await _doc(uid).delete().timeout(_timeout);
    } catch (_) {
      // Belge zaten yoksa veya çevrimdışıysa hesap silmeyi bloklama
    }
  }
}

class NoOpCloudSyncService implements CloudSyncService {
  const NoOpCloudSyncService();

  @override
  Future<PlayerProfile?> fetchProfile(String uid) async => null;

  @override
  Future<bool> pushProfile(String uid, PlayerProfile profile) async => false;

  @override
  Future<void> deleteCloudProfile(String uid) async {}
}
