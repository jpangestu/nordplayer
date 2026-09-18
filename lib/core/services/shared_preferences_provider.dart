import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the pre-initialized [SharedPreferencesWithCache] instance.
///
/// Must be overridden in `main.dart` at app startup via `ProviderScope(overrides: [...])`.
final sharedPrefsProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be initialized in main.dart');
});
