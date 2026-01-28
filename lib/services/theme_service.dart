import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._internal();
  static final _instance = ThemeService._internal();
  factory ThemeService() => _instance;

  // Default to system to respect system settings immediately.
  ThemeMode _currentTheme = ThemeMode.system;

  final _controller = StreamController<ThemeMode>.broadcast();
  Stream<ThemeMode> get themeStream => _controller.stream;
  ThemeMode get currentTheme => _currentTheme;

  bool _isImmersive = true;

  // Immersive mode stream
  final _immersiveController = StreamController<bool>.broadcast();
  Stream<bool> get immersiveStream => _immersiveController.stream;
  bool get isImmersive => _isImmersive;

  /// Loads the saved theme from disk.
  /// If no file exists, it defaults to ThemeMode.system.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode');

    if (themeIndex != null) {
      _currentTheme = ThemeMode.values[themeIndex];
      _controller.add(_currentTheme);
    }

    // Load Immersive Mode
    _isImmersive = prefs.getBool('immersive_mode') ?? false;
    _immersiveController.add(_isImmersive);
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (_currentTheme == mode) return;

    _currentTheme = mode;
    _controller.add(mode); // Update UI immediately

    // Fire and forget storage (Performance: Don't block UI waiting for disk IO)
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('theme_mode', mode.index);
    });
  }

  // Update Set Logic
  Future<void> setImmersiveMode(bool value) async {
    if (_isImmersive == value) return;

    _isImmersive = value;
    _immersiveController.add(value); // Update UI

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('immersive_mode', value);
    });
  }

  // Cleanup for when the app dies (or if we switch to a disposable provider later)
  void dispose() {
    _controller.close();
  }
}
