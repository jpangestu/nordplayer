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

  @override
  /// Set null for solid
  void setWindowPlatformStyle(PlatformStyle? platformStyle) {
    if (platformStyle is! WindowsWindowStyle && platformStyle != null) return;
    final h = hwnd;
    if (h.address == 0) return;

    final isWindowsWindowStyle = platformStyle != null;

    // Reset any legacy composition accent policy
    final accent = calloc<ACCENT_POLICY>();
    final compData = calloc<WINDOWCOMPOSITIONATTRIBDATA>();
    try {
      accent.ref.AccentState = ACCENT_DISABLED;
      accent.ref.AccentFlags = 2;
      accent.ref.GradientColor = 0;
      accent.ref.AnimationId = 0;

      compData.ref.Attrib = WCA_ACCENT_POLICY;
      compData.ref.pvData = accent.cast();
      compData.ref.cbData = sizeOf<ACCENT_POLICY>();
      SetWindowCompositionAttribute(h, compData);
    } finally {
      free(accent);
      free(compData);
    }

    // DWM Frame Margins:
    // - System effects require -1 margins across the entire window.
    // - Solid / None restores standard {0, 0, 1, 0} margins.
    final margins = calloc<MARGINS>()
      ..ref.cxLeftWidth = isWindowsWindowStyle ? -1 : 0
      ..ref.cxRightWidth = isWindowsWindowStyle ? -1 : 0
      ..ref.cyTopHeight = isWindowsWindowStyle ? -1 : 1
      ..ref.cyBottomHeight = isWindowsWindowStyle ? -1 : 0;
    try {
      DwmExtendFrameIntoClientArea(h, margins);
    } finally {
      free(margins);
    }

    // Titlebar caption fill (0xFFFFFFFF = DWMWA_COLOR_DEFAULT) / (0xFFFFFFFE = DWMWA_COLOR_NONE)
    final captionColor = calloc<DWORD>()..value = isWindowsWindowStyle ? 0xFFFFFFFE : 0xFFFFFFFF;
    try {
      DwmSetWindowAttribute(h, DWMWA_CAPTION_COLOR, captionColor, sizeOf<DWORD>());
    } finally {
      free(captionColor);
    }

    // DWM System Backdrop Type:
    final backdropType = switch (platformStyle) {
      null => 1, // DWMSBT_NONE (1) No system backdrop / solid
      WindowsWindowStyle.mica => 2, // DWMSBT_MAINWINDOW (2) for Mica
      WindowsWindowStyle.acrylic => 3, // DWMSBT_TRANSIENTWINDOW (3) for Acrylic
      WindowsWindowStyle.micaAlt => 4, // DWMSBT_TABBEDWINDOW (4) for Mica Alt
    };

    final backdropPtr = calloc<DWORD>()..value = backdropType;
    try {
      DwmSetWindowAttribute(h, DWMWA_SYSTEMBACKDROP_TYPE, backdropPtr, sizeOf<DWORD>());
    } finally {
      free(backdropPtr);
    }

    // Force DWM to update frame composition immediately
    SetWindowPos(
      h,
      HWND(nullptr),
      0,
      0,
      0,
      0,
      SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE,
    );
  }
}
