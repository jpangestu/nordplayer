import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:suara/models/app_config.dart';
import 'package:suara/models/adaptive_background.dart';
import 'package:suara/models/textured_layer.dart';
import 'package:suara/models/texture_profile.dart';

class ConfigService extends ChangeNotifier {
  ConfigService._internal();
  static final ConfigService _singleton = ConfigService._internal();
  factory ConfigService() => _singleton;

  AppConfig _config = const AppConfig();
  AppConfig get config => _config;

  File? _file; // The reference to config.json
  Timer? _debounce; // The timer to prevent writing too often

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _file = File(p.join(dir.path, 'config.json'));

    if (!_file!.existsSync()) {
      // First run: Create the file with default settings
      await _saveToDisk();
    } else {
      // Subsequent runs: Load the file
      try {
        final content = await _file!.readAsString();
        final jsonMap = jsonDecode(content);
        _config = AppConfig.fromJson(jsonMap);
        notifyListeners(); // Tell UI to refresh with loaded data
      } catch (e) {
        print("CONFIG ERROR: $e");
        // Optional: If file is corrupt, backup and reset
        await _file!.copy('${_file!.path}.bak');
        _config = const AppConfig();
        await _saveToDisk();
      }
    }
  }

  // Update
  void update({
    ThemeMode? themeMode,
    String? fontFamily,
    double? globalDimmer,
    AdaptiveBackground? adaptiveBackground,
    TexturedLayer? texturedLayer,
    // Helper: allows us to just pass a new texture profile directly
    TextureProfile? activeTexture,
  }) {
    // Logic: If user passed a specific texture, inject it into the layer logic
    TexturedLayer? newTextureLayer = texturedLayer;

    // If we received a specific texture, we update the texturedLayer object
    if (activeTexture != null) {
      final current = texturedLayer ?? _config.texturedLayer;
      newTextureLayer = current.copyWith(activeTexture: activeTexture);
    }

    // 1. Update Memory (Instant UI feedback)
    _config = _config.copyWith(
      themeMode: themeMode,
      fontFamily: fontFamily,
      globalDimmer: globalDimmer,
      adaptiveBackground: adaptiveBackground,
      texturedLayer: newTextureLayer,
    );
    notifyListeners(); // <--- Rebuilds your UI

    // 2. Save to Disk (Debounced)
    // Wait 500ms. If user changes nothing else, then write to file.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveToDisk);
  }

  Future<void> addCustomTexture(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();

    // Create a specific folder for textures to keep things clean
    final texDir = Directory(p.join(appDir.path, 'textures'));
    if (!texDir.existsSync()) await texDir.create();

    final fileName = p.basename(sourcePath);
    final savedFile = await File(
      sourcePath,
    ).copy(p.join(texDir.path, fileName));

    // Create the profile object
    final newProfile = TextureProfile(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: fileName,
      path: savedFile.path,
      type: TextureType.file,
    );

    // Update the config: Add to list AND select it immediately
    final updatedList = [..._config.customTextures, newProfile];
    final updatedLayer = _config.texturedLayer.copyWith(
      activeTexture: newProfile,
    );

    _config = _config.copyWith(
      customTextures: updatedList,
      texturedLayer: updatedLayer,
    );
    notifyListeners();
    _saveToDisk(); // Save immediately (no debounce needed for import)
  }

  Future<void> _saveToDisk() async {
    if (_file == null) return;
    try {
      const encoder = JsonEncoder.withIndent('  '); // Pretty print JSON
      await _file!.writeAsString(encoder.convert(_config.toJson()));
    } catch (e) {
      print("SAVE ERROR: $e");
    }
  }
}
