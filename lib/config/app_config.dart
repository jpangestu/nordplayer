import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:typed_config/typed_config.dart';

/// Current schema version for UI settings.
const currentSchemaVersion = 1;

class AppConfig(super.builder) extends Config {
  final themeMode = builder.defineEnum('themeMode', ThemeMode.system, values: ThemeMode.values);
}

// ================================================================================================
// Riverpod Stuff
// ================================================================================================
final _entryProviderCache = Expando<Object>();

/// Extension to add a reactive [provider] getter to [ConfigEntry].
extension ConfigEntryRiverpodX<T> on ConfigEntry<T> {
  Provider<T> get provider {
    final cached = _entryProviderCache[this];
    if (cached != null) return cached as Provider<T>;

    final created = Provider<T>((ref) {
      final sub = changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(sub.cancel);
      return value;
    });
    _entryProviderCache[this] = created;
    return created;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be initialized in main.dart');
});
