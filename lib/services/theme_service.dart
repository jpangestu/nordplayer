import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara/models/adaptive_background.dart';
import 'package:suara/models/texture_profile';
import 'package:suara/models/textured_layer.dart';

class ThemeService {
  ThemeService._internal();
  static final _instance = ThemeService._internal();
  factory ThemeService() => _instance;

  late final SharedPreferences _prefs;

  // Default to system to respect system settings immediately.
  ThemeMode _currentTheme = ThemeMode.system;
  ThemeMode get currentTheme => _currentTheme;

  final _themeController = StreamController<ThemeMode>.broadcast();
  Stream<ThemeMode> get themeStream => _themeController.stream;

  /// Set theme mode (dark/light/system)
  Future<void> setTheme(ThemeMode mode) async {
    if (_currentTheme == mode) return;

    _currentTheme = mode;
    _themeController.add(mode); // Update UI immediately

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('theme_mode', mode.index);
    });
  }

  //
  // =============================================================================
  // ADAPTIVE BACKGROUND
  // =============================================================================
  //

  // Default adaptive background mode value
  AdaptiveBackground _adaptiveBackground = AdaptiveBackground();
  AdaptiveBackground get adaptiveBackground => _adaptiveBackground;

  // Adaptive background mode stream
  final _adaptiveBackgroundController =
      StreamController<AdaptiveBackground>.broadcast();
  Stream<AdaptiveBackground> get adaptiveBackgroundStream =>
      _adaptiveBackgroundController.stream;

  /// Set adaptive background mode
  Future<void> setAdaptiveBackgroundMode(bool value) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(isEnabled: value);
    _adaptiveBackgroundController.add(_adaptiveBackground); // Update UI

    await _prefs.setBool('adaptive_background_mode', value);
  }

  /// Set adaptive background blur
  void setAdaptiveBackgroundBlur(double value) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(blur: value);
    _adaptiveBackgroundController.add(_adaptiveBackground); // Update UI
  }

  Future<void> saveAdaptiveBackgroundBlur(double value) async {
    await _prefs.setDouble('adaptive_background_blur', value);
  }

  /// Set adaptive background album art placement
  Future<void> setAdaptiveBackgroundFit(BoxFit fit) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(fit: fit);
    _adaptiveBackgroundController.add(_adaptiveBackground);

    await _prefs.setString('adaptive_background_fit', fit.name);
  }

  //
  // =============================================================================
  // TEXTURED LAYER
  // =============================================================================
  //

  // Textured layer
  TexturedLayer _texturedLayer = TexturedLayer();
  TexturedLayer get texturedLayer => _texturedLayer;

  final _texturedLayerController = StreamController<TexturedLayer>.broadcast();
  Stream<TexturedLayer> get texturedLayeredStream =>
      _texturedLayerController.stream;

  /// Set textured layer mode
  Future<void> setTexturedLayerMode(bool value) async {
    _texturedLayer = _texturedLayer.copyWith(isEnabled: value);
    _texturedLayerController.add(_texturedLayer); // Update UI

    await _prefs.setBool('textured_layer_mode', value);
  }

  /// Set textured layer opacity
  Future<void> setTexturedLayerOpacity(double value) async {
    _texturedLayer = _texturedLayer.copyWith(opacity: value);
    _texturedLayerController.add(_texturedLayer); // Update UI
  }

  Future<void> saveTexturedLayerOpacity(double value) async {
    await _prefs.setDouble('textured_layer_opacity', value);
  }

  /// Set textured layer placement
  Future<void> setTexturedLayerFit(BoxFit fit) async {
    _texturedLayer = _texturedLayer.copyWith(fit: fit);
    _texturedLayerController.add(_texturedLayer);

    await _prefs.setInt('textured_layer_fit', fit.index); // Save the enum index
  }

  // Default preset
  static const List<TextureProfile> _presets = [
    TextureProfile(
      id: 'default_glass',
      name: 'Frosted Glass',
      path: 'assets/texture_preset/glass.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'paper',
      name: 'Crumbled Paper',
      path: 'assets/texture_preset/paper.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'aged_paper',
      name: 'Aged Paper',
      path: 'assets/texture_preset/old_paper.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'rain',
      name: 'Rain',
      path: 'assets/texture_preset/rain.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'rain2',
      name: 'Rain 2',
      path: 'assets/texture_preset/rain2.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'rough_wall',
      name: 'Rough Wall',
      path: 'assets/texture_preset/rough_wall.png',
      type: TextureType.asset,
    ),
  ];

  // User's custom texture (Loaded from prefs)
  List<TextureProfile> _customTextures = [];

  Future<void> addCustomTexture(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = basename(sourcePath);
    final savedImage = await File(
      sourcePath,
    ).copy('${appDir.path}/textures/$fileName');

    final newProfile = TextureProfile(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}', // Unique ID
      name: fileName,
      path: savedImage.path,
      type: TextureType.file,
    );

    _customTextures.add(newProfile);

    // Save the list of custom textures to SharedPreferences (as JSON)
    _saveUserTexturesToDisk();

    // Immediately select it
    setTexture(newProfile);
  }

  static const String _customTexturesKey = 'custom_textures_list';

  // 1. Save to Disk
  Future<void> _saveUserTexturesToDisk() async {
    // Requires TextureProfile to have .toMap() implemented
    final String jsonString = jsonEncode(
      _customTextures.map((p) => p.toMap()).toList(),
    );
    await _prefs.setString(_customTexturesKey, jsonString);
  }

  // 2. Load from Disk
  // Future<void> _loadUserTexturesFromDisk(SharedPreferences prefs) async {
  //   final String? jsonString = prefs.getString(_customTexturesKey);
  //   if (jsonString != null) {
  //     try {
  //       final List<dynamic> decoded = jsonDecode(jsonString);
  //       _customTextures = decoded
  //           .map((item) => TextureProfile.fromMap(item))
  //           .toList();
  //     } catch (e) {
  //       print("Error loading textures: $e");
  //     }
  //   }
  // }

  /// Preset + User's custom texture
  List<TextureProfile> get allTextures => [..._presets, ..._customTextures];

  // Current selection
  TextureProfile get currentTexture {
    // If null (app first run), fallback to the first preset.
    return _texturedLayer.activeTexture ?? _presets.first;
  }

  Future<void> setTexture(TextureProfile profile) async {
    // Ipdate selected profile
    _texturedLayer = _texturedLayer.copyWith(activeTexture: profile);
    _texturedLayerController.add(_texturedLayer);

    // Save only the ID to disk
    _prefs.setString('texture_selected_id', profile.id);
  }

  // =============================================================================
  // GLOBAL DIMMER
  // =============================================================================

  double _dimmerLevel = 0.5;
  double get dimmerLevel => _dimmerLevel;

  final _dimmerController = StreamController<double>.broadcast();
  Stream<double> get dimmerStream => _dimmerController.stream;

  void setDimmer(double value) {
    _dimmerLevel = value;
    _dimmerController.add(_dimmerLevel); // Updates UI instantly (RAM only)
  }

  void saveDimmerLevel() {
    _prefs.setDouble('global_dimmer_level', _dimmerLevel);
  }

  //
  // =============================================================================
  // LOAD THEME, ADAPTIVE BACKGROUND, AND TEXTURED LAYER
  // =============================================================================
  //

  /// Loads the saved theme, adaptive background, and textured layer from disk.
  Future<void> loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs.getInt('theme_mode');

    if (themeIndex != null) {
      _currentTheme = ThemeMode.values[themeIndex];
      _themeController.add(_currentTheme);
    }

    // Load Adaptive Background
    final mode = _prefs.getBool('adaptive_background_mode');
    final blur = _prefs.getDouble('adaptive_background_blur');
    final fitString = _prefs.getString('adaptive_background_fit');
    final fit = BoxFit.values.firstWhere(
      (e) => e.name == fitString,
      orElse: () => BoxFit.cover,
    );

    _adaptiveBackground = AdaptiveBackground(
      isEnabled: mode ?? true,
      blur: blur ?? AdaptiveBackground.defaultBlur,
      fit: fit,
    );
    _adaptiveBackgroundController.add(adaptiveBackground);

    // Load Texture Layer
    final texturedMode = _prefs.getBool('textured_layer_mode');
    final texturedOpacity = _prefs.getDouble('textured_layer_opacity');
    final texturedFitIndex = _prefs.getInt('textured2_layer_fit');
    // If index is valid, use it. Otherwise default.
    final texturedFit =
        texturedFitIndex != null && texturedFitIndex < BoxFit.values.length
        ? BoxFit.values[texturedFitIndex]
        : TexturedLayer.defaultFit;

    _texturedLayer = TexturedLayer(
      isEnabled: texturedMode ?? false,
      opacity: texturedOpacity ?? TexturedLayer.defaultOpacity,
      fit: texturedFit,
    );
    _texturedLayerController.add(_texturedLayer);

    _dimmerLevel = _prefs.getDouble('global_dimmer_level') ?? 0.5;
    _dimmerController.add(_dimmerLevel);
  }

  // Cleanup for when the app dies
  void dispose() {
    _themeController.close();
    _adaptiveBackgroundController.close();
    _texturedLayerController.close();
  }
}
