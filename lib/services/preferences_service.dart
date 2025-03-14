import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PreferencesService {
  static const String _photoConsentKey = 'photo_consent';
  static const String _deleteHashesKey = 'imgur_delete_hashes';

  static PreferencesService? _instance;
  late SharedPreferences _prefs;

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getPhotoConsent() {
    return _prefs.getBool(_photoConsentKey) ?? false;
  }

  Future<void> setPhotoConsent(bool value) async {
    await _prefs.setBool(_photoConsentKey, value);
  }

  /// Saves a delete hash for an Imgur image
  Future<void> saveDeleteHash(String imageId, String deleteHash) async {
    // Get existing hashes
    final Map<String, dynamic> hashes = _getDeleteHashes();

    // Add or update the delete hash for this image ID
    hashes[imageId] = deleteHash;

    // Save the updated hashes map
    await _prefs.setString(_deleteHashesKey, jsonEncode(hashes));
  }

  /// Gets a delete hash for an Imgur image by its ID
  String? getDeleteHash(String imageId) {
    final Map<String, dynamic> hashes = _getDeleteHashes();
    return hashes[imageId] as String?;
  }

  /// Gets all stored delete hashes
  Map<String, dynamic> _getDeleteHashes() {
    final String hashesJson = _prefs.getString(_deleteHashesKey) ?? '{}';
    try {
      return jsonDecode(hashesJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Removes a delete hash for an Imgur image
  Future<void> removeDeleteHash(String imageId) async {
    final Map<String, dynamic> hashes = _getDeleteHashes();

    if (hashes.containsKey(imageId)) {
      hashes.remove(imageId);
      await _prefs.setString(_deleteHashesKey, jsonEncode(hashes));
    }
  }

  /// Clears all stored delete hashes
  Future<void> clearDeleteHashes() async {
    await _prefs.remove(_deleteHashesKey);
  }
}
