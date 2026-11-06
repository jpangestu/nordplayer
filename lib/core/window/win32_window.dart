import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:win32/win32.dart';

/// Windows implemetations of [NativeWindow].
class Win32Window extends NativeWindow {
  HWND? _hwnd;

  /// Resolves and caches the top-level window handle for the current process.
  HWND get hwnd {
    if (!Platform.isWindows) return HWND(nullptr);
    if (_hwnd != null && _hwnd!.address != 0) return _hwnd!;

    // 1. Try active window on current platform thread
    final active = GetActiveWindow();
    if (active.address != 0) {
      final root = GetAncestor(active, GA_ROOT);
      if (root.address != 0) {
        _hwnd = root;
        return _hwnd!;
      }
      _hwnd = active;
      return _hwnd!;
    }

    // 2. Try foreground window if it belongs to this process
    final foreground = GetForegroundWindow();
    if (foreground.address != 0) {
      final processIdPtr = calloc<DWORD>();
      try {
        GetWindowThreadProcessId(foreground, processIdPtr);
        if (processIdPtr.value == GetCurrentProcessId()) {
          final root = GetAncestor(foreground, GA_ROOT);
          _hwnd = root.address != 0 ? root : foreground;
          return _hwnd!;
        }
      } finally {
        free(processIdPtr);
      }
    }

    // 3. Try FindWindow with the Flutter runner window class name
    final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toPcwstr();
    try {
      final found = FindWindow(className, null);
      if (found.value.address != 0) {
        _hwnd = found.value;
        return _hwnd!;
      }
    } finally {
      free(className);
    }

    return HWND(nullptr);
  }

  /// Synchronously returns whether the window is currently maximized.
  @override
  bool get isMaximized => hwnd.address != 0 && IsZoomed(hwnd);

  /// Synchronously returns whether the window is currently minimized.
  @override
  bool get isMinimized => hwnd.address != 0 && IsIconic(hwnd);

  /// Synchronously returns whether the window is currently focused.
  @override
  bool get isFocused {
    if (hwnd.address == 0) return true;
    final active = GetActiveWindow();
    if (active.address == 0) {
      final foreground = GetForegroundWindow();
      return foreground.address == hwnd.address ||
          GetAncestor(foreground, GA_ROOT).address == hwnd.address;
    }
    return active.address == hwnd.address || GetAncestor(active, GA_ROOT).address == hwnd.address;
  }

  /// Minimizes the window.
  @override
  void minimize() {
    if (hwnd.address != 0) ShowWindow(hwnd, SW_MINIMIZE);
  }

  /// Maximizes the window.
  @override
  void maximize() {
    if (hwnd.address != 0) {
      ShowWindow(hwnd, SW_MAXIMIZE);
      checkStateChanges();
    }
  }

  /// Restores the window from a maximized or minimized state.
  @override
  void restore() {
    if (hwnd.address != 0) {
      ShowWindow(hwnd, SW_RESTORE);
      checkStateChanges();
    }
  }

  /// Closes the window.
  @override
  void close() {
    if (hwnd.address != 0) {
      SendMessage(hwnd, WM_CLOSE, const WPARAM(0), const LPARAM(0));
    }
  }

  /// Starts native window dragging with Windows Aero Snap support.
  @override
  void startDragging() {
    if (hwnd.address != 0) {
      ReleaseCapture();
      SendMessage(hwnd, WM_NCLBUTTONDOWN, const WPARAM(HTCAPTION), const LPARAM(0));
      checkStateChanges();
    }
  }

  /// Starts native edge or corner window resizing.
  @override
  void startResizing(WindowResizeEdge edge) {
    if (hwnd.address != 0) {
      final hitTest = switch (edge) {
        WindowResizeEdge.left => HTLEFT,
        WindowResizeEdge.right => HTRIGHT,
        WindowResizeEdge.top || WindowResizeEdge.topCenter => HTTOP,
        WindowResizeEdge.bottom => HTBOTTOM,
        WindowResizeEdge.topLeft => HTTOPLEFT,
        WindowResizeEdge.topRight => HTTOPRIGHT,
        WindowResizeEdge.bottomLeft => HTBOTTOMLEFT,
        WindowResizeEdge.bottomRight => HTBOTTOMRIGHT,
      };
      ReleaseCapture();
      SendMessage(hwnd, WM_NCLBUTTONDOWN, WPARAM(hitTest), const LPARAM(0));
      checkStateChanges();
    }
  }
}
