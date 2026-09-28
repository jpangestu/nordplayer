import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stateless service wrapper around [SharedPreferencesWithCache].
class const SharedPreferencesService(final SharedPreferencesWithCache _prefs) {
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}

/// Riverpod provider for [SharedPreferencesService].
final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SharedPreferencesService(prefs);
});
