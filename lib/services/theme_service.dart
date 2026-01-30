import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara/models/adaptive_background.dart';

class ThemeService {
  ThemeService._internal();
  static final _instance = ThemeService._internal();
  factory ThemeService() => _instance;

  // Default to system to respect system settings immediately.
  ThemeMode _currentTheme = ThemeMode.system;
  ThemeMode get currentTheme => _currentTheme;

  final _themeController = StreamController<ThemeMode>.broadcast();
  Stream<ThemeMode> get themeStream => _themeController.stream;

  // Default immersive mode value
  AdaptiveBackground _adaptiveBackground = AdaptiveBackground(isEnabled: true);
  AdaptiveBackground get adaptiveBackground => _adaptiveBackground;

  // Immersive mode stream
  final _adaptiveBackgroundController =
      StreamController<AdaptiveBackground>.broadcast();
  Stream<AdaptiveBackground> get adaptiveBackgroundStream =>
      _adaptiveBackgroundController.stream;

  /// Loads the saved theme from disk.
  /// If no file exists, it defaults to ThemeMode.system.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode');

    if (themeIndex != null) {
      _currentTheme = ThemeMode.values[themeIndex];
      _themeController.add(_currentTheme);
    }

    // Load Immersive Mode
    final mode = prefs.getBool('adaptive_background_mode');
    final blur = prefs.getDouble('adaptive_background_blur');
    final opacity = prefs.getDouble('adaptive_background_opacity');
    final fitIndex = prefs.getInt('adaptive_background_fit');
    // If index is valid, use it. Otherwise default.
    final fit = fitIndex != null && fitIndex < BoxFit.values.length
        ? BoxFit.values[fitIndex]
        : AdaptiveBackground.defaultFit;

    _adaptiveBackground = AdaptiveBackground(
      isEnabled: mode ?? true,
      blur: blur ?? AdaptiveBackground.defaultBlur,
      opacity: opacity ?? AdaptiveBackground.defaultOpacity,
      fit: fit,
    );
    _adaptiveBackgroundController.add(adaptiveBackground);
  }

  /// Set theme mode (dark/light/system)
  Future<void> setTheme(ThemeMode mode) async {
    if (_currentTheme == mode) return;

    _currentTheme = mode;
    _themeController.add(mode); // Update UI immediately

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('theme_mode', mode.index);
    });
  }

  /// Set adaptive background mode
  Future<void> setAdaptiveBackgroundMode(bool value) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(isEnabled: value);
    _adaptiveBackgroundController.add(_adaptiveBackground); // Update UI

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('adaptive_background_mode', value);
    });
  }

  /// Set adaptive background blur
  Future<void> setAdaptiveBackgroundBlur(double value) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(blur: value);
    _adaptiveBackgroundController.add(_adaptiveBackground); // Update UI

    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('adaptive_background_blur', value);
    });
  }

  /// Set adaptive background opacity
  Future<void> setAdaptiveBackgroundOpacity(double value) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(opacity: value);
    _adaptiveBackgroundController.add(_adaptiveBackground); // Update UI

    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('adaptive_background_opacity', value);
    });
  }

  /// Set adaptive background album art placement
  Future<void> setAdaptiveBackgroundFit(BoxFit fit) async {
    _adaptiveBackground = _adaptiveBackground.copyWith(fit: fit);
    _adaptiveBackgroundController.add(_adaptiveBackground);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('adaptive_background_fit', fit.index); // Save the enum index
    });
  }

  // Cleanup for when the app dies
  void dispose() {
    _themeController.close();
  }
}
