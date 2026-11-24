import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/puzzle_models.dart';

class StorageService {
  static const String _profileKey = 'konsept_bulmaca_profile_v1';

  Future<PlayerProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      return const PlayerProfile();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProfile.fromJson(decoded);
    } catch (_) {
      return const PlayerProfile();
    }
  }

  Future<void> saveProfile(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
