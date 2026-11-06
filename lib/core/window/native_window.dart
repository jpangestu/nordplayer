import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/window/win32_window.dart';

// Window System Architecture Overview:
//
// 1. Native Host (e.g. windows/runner/):
//    - win32_window.cpp: Base Win32 window creation, DPI-aware centering, and message loop.
//    - flutter_window.cpp: Strips native titlebar (WM_NCCALCSIZE), extends DWM frame into
//      the client area for native shadows and Aero snap (DwmExtendFrameIntoClientArea),
//      and enforces minimum window dimensions at the OS level (WM_GETMINMAXINFO).
//
// 2. Abstraction & Event Bridge (native_window.dart):
//    - [NativeWindow]: Native window abstraction class & singleton factory.
//    - [WidgetsBindingObserver]: To listens to OS-initiated changes (didChangeMetrics,
//      didChangeAppLifecycleState) and broadcasts them via [notifyListeners].
//    - Exposes [isWindowMaximizedProvider] & [isWindowFocusedProvider] for reactive UI updates.
//
// 3. Platform FFI Implementation (win32_window.dart, etc.):
//    - Maps Native window commands (maximize, restore, etc.) to the OS APIs (SW_MAXIMIZE, SW_RESTORE).
//    - Runs on Flutter's unified platform thread; no async thanks to "The Great Thread Merge".
//
// 4. UI Layer (lib/ui/shell/title_bar/):
//    - Window widgets (TitleBar, Windows11WindowControl, DragToMoveArea).
//    - Consumes [nativeWindowProvider] for commands and watches providers for reactive styling.

enum WindowResizeEdge {
  left,
  right,
  top,
  topCenter,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Abstract base controller for native desktop window operations.
///
/// Defines the cross-platform window contract and uses [WidgetsBindingObserver] to reactively
/// detect OS-driven metrics and lifecycle changes (maximizing, resizing, and focus loss).
abstract class NativeWindow with WidgetsBindingObserver {
  NativeWindow() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Factory singleton returning the current platform's implementation.
  static final NativeWindow instance = _createInstance();

  static NativeWindow _createInstance() {
    if (Platform.isWindows) {
      return Win32Window();
    }
    // Future platforms:
    // if (Platform.isLinux) return LinuxNativeWindow();
    return _NoOpNativeWindow();
  }

  bool get isMaximized;
  bool get isMinimized;
  bool get isFocused;

  void minimize();
  void maximize();
  void restore();
  void close();
  void startDragging();
  void startResizing(WindowResizeEdge edge);

  void popUpWindowMenu([Offset? globalPosition]) {}

  void toggleMaximize() {
    if (isMaximized) {
      restore();
    } else {
      maximize();
    }
  }

  // ==============================================================================================
  // State observation & listener management
  // ==============================================================================================

  bool _lastMaximizedState = false;
  bool _lastFocusedState = true;
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Called whenever the window might have changed state.
  void checkStateChanges() {
    // Cache the getters into local variables to query native OS APIs only once
    // and avoid inconsistent reads across the check and assignment.
    final currentMaximizedState = isMaximized;
    final currentFocusedState = isFocused;
    if (currentMaximizedState != _lastMaximizedState || currentFocusedState != _lastFocusedState) {
      _lastMaximizedState = currentMaximizedState;
      _lastFocusedState = currentFocusedState;
      notifyListeners();
    }
  }

  // didChangeMetrics tells us when window’s size, maximized status, or screen DPI changed.
  @override
  void didChangeMetrics() {
    checkStateChanges();
  }

  // didChangeAppLifecycleState tells us when the window gained focus (resumed),
  // lost focus (inactive), or was minimized (hidden); see [AppLifecycleState].
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    checkStateChanges();
  }

  @mustCallSuper
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listeners.clear();
  }
}

class _NoOpNativeWindow extends NativeWindow {
  @override
  bool get isMaximized => false;
  @override
  bool get isMinimized => false;
  @override
  bool get isFocused => true;

  @override
  void minimize() {}
  @override
  void maximize() {}
  @override
  void restore() {}
  @override
  void close() {}
  @override
  void startDragging() {}
  @override
  void startResizing(WindowResizeEdge edge) {}
}

// =============================================================================
// Riverpod Integration
// =============================================================================

/// Provider for the [NativeWindow] singleton instance.
final nativeWindowProvider = Provider<NativeWindow>((ref) => NativeWindow.instance);

/// Reactive provider for the window's maximized state.
final isWindowMaximizedProvider = NotifierProvider<WindowMaximizedNotifier, bool>(
  WindowMaximizedNotifier.new,
);

class WindowMaximizedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final window = ref.watch(nativeWindowProvider);
    void listener() {
      final maximized = window.isMaximized;
      if (state != maximized) {
        state = maximized;
      }
    }

    window.addListener(listener);
    ref.onDispose(() => window.removeListener(listener));
    return window.isMaximized;
  }
}

/// Reactive provider for the window's focus state.
final isWindowFocusedProvider = NotifierProvider<WindowFocusedNotifier, bool>(
  WindowFocusedNotifier.new,
);

class WindowFocusedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final window = ref.watch(nativeWindowProvider);
    void listener() {
      final focused = window.isFocused;
      if (state != focused) {
        state = focused;
      }
    }

    window.addListener(listener);
    ref.onDispose(() => window.removeListener(listener));
    return window.isFocused;
  }
}
