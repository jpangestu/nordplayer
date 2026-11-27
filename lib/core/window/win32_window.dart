import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:win32/win32.dart';

/// Windows implementation of [NativeWindow].
class Win32Window extends NativeWindow {
  static const _windowClassName = 'NORDPLAYER_WIN32_WINDOW';
  static const _win11Build22H2 = 22621;

  HWND? _hwnd;
  late final bool _supportsSystemBackdrop = OsVersion.current.build >= _win11Build22H2;
  bool _hasSystemBackdrop = false;
  int? _lastCaptionColorRef;

  /// Resolves and caches the top-level window handle for the current process.
  HWND get hwnd {
    if (!Platform.isWindows) return HWND(nullptr);
    if (_hwnd != null && _hwnd!.address != 0 && IsWindow(_hwnd)) return _hwnd!;
    _hwnd = null;

    final currentPid = GetCurrentProcessId();
    final processIdPtr = calloc<DWORD>();
    try {
      // 1. Enumerate top-level windows matching Nordplayer's unique class name and PID.
      // Checked first so a native modal dialog (e.g. file picker) can never be cached.
      final className = _windowClassName.toPcwstr();
      try {
        HWND? candidate;
        while (true) {
          final found = FindWindowEx(null, candidate, className, null).value;
          if (found.address == 0) break;
          GetWindowThreadProcessId(found, processIdPtr);
          if (processIdPtr.value == currentPid) {
            _hwnd = found;
            return _hwnd!;
          }
          candidate = found;
        }
      } finally {
        free(className);
      }

      // 2. Fallback: active window on current platform thread
      final active = GetActiveWindow();
      if (active.address != 0) {
        final root = GetAncestor(active, GA_ROOT);
        _hwnd = root.address != 0 ? root : active;
        return _hwnd!;
      }

      // 3. Fallback: foreground window if it belongs to this process
      final foreground = GetForegroundWindow();
      if (foreground.address != 0) {
        GetWindowThreadProcessId(foreground, processIdPtr);
        if (processIdPtr.value == currentPid) {
          final root = GetAncestor(foreground, GA_ROOT);
          _hwnd = root.address != 0 ? root : foreground;
          return _hwnd!;
        }
      }
    } finally {
      free(processIdPtr);
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
    final h = hwnd;
    if (h.address == 0) return true;
    final active = GetActiveWindow();
    if (active.address == 0) {
      final foreground = GetForegroundWindow();
      return foreground.address == h.address ||
          GetAncestor(foreground, GA_ROOT).address == h.address;
    }
    return active.address == h.address || GetAncestor(active, GA_ROOT).address == h.address;
  }

  /// Minimizes the window.
  @override
  void minimize() {
    final h = hwnd;
    if (h.address != 0) ShowWindow(h, SW_MINIMIZE);
  }

  /// Maximizes the window.
  @override
  void maximize() {
    final h = hwnd;
    if (h.address != 0) {
      ShowWindow(h, SW_MAXIMIZE);
      checkStateChanges();
    }
  }

  /// Restores the window from a maximized or minimized state.
  @override
  void restore() {
    final h = hwnd;
    if (h.address != 0) {
      ShowWindow(h, SW_RESTORE);
      checkStateChanges();
    }
  }

  /// Closes the window.
  @override
  void close() {
    final h = hwnd;
    if (h.address != 0) {
      PostMessage(h, WM_CLOSE, const WPARAM(0), const LPARAM(0));
    }
  }

  LPARAM _cursorPosLParam() {
    final pt = calloc<POINT>();
    try {
      if (!GetCursorPos(pt).value) return const LPARAM(0);
      return LPARAM(((pt.ref.y & 0xFFFF) << 16) | (pt.ref.x & 0xFFFF));
    } finally {
      free(pt);
    }
  }

  /// Starts native window dragging with Windows Aero Snap support.
  @override
  void startDragging() {
    final h = hwnd;
    if (h.address != 0) {
      ReleaseCapture();
      PostMessage(h, WM_NCLBUTTONDOWN, const WPARAM(HTCAPTION), _cursorPosLParam());
    }
  }

  /// Starts native edge or corner window resizing.
  @override
  void startResizing(WindowResizeEdge edge) {
    final h = hwnd;
    if (h.address != 0) {
      final hitTest = switch (edge) {
        WindowResizeEdge.left => HTLEFT,
        WindowResizeEdge.right => HTRIGHT,
        WindowResizeEdge.top => HTTOP,
        WindowResizeEdge.bottom => HTBOTTOM,
        WindowResizeEdge.topLeft => HTTOPLEFT,
        WindowResizeEdge.topRight => HTTOPRIGHT,
        WindowResizeEdge.bottomLeft => HTBOTTOMLEFT,
        WindowResizeEdge.bottomRight => HTBOTTOMRIGHT,
      };
      ReleaseCapture();
      PostMessage(h, WM_NCLBUTTONDOWN, WPARAM(hitTest), _cursorPosLParam());
    }
  }

  void _setAccentPolicy(HWND h, {required ACCENT_STATE state, int gradientColor = 0}) {
    final accent = calloc<ACCENT_POLICY>();
    final compData = calloc<WINDOWCOMPOSITIONATTRIBDATA>();
    try {
      accent.ref
        ..AccentState = state
        ..AccentFlags = 2
        ..GradientColor = gradientColor
        ..AnimationId = 0;

      compData.ref
        ..Attrib = WCA_ACCENT_POLICY
        ..pvData = accent.cast()
        ..cbData = sizeOf<ACCENT_POLICY>();
      SetWindowCompositionAttribute(h, compData);
    } finally {
      free(accent);
      free(compData);
    }
  }

  void _setFrameMargins(HWND h, {required bool extendFullFrame}) {
    final margins = calloc<MARGINS>()
      ..ref.cxLeftWidth = extendFullFrame ? -1 : 0
      ..ref.cxRightWidth = extendFullFrame ? -1 : 0
      ..ref.cyTopHeight = extendFullFrame ? -1 : 1
      ..ref.cyBottomHeight = extendFullFrame ? -1 : 0;
    try {
      DwmExtendFrameIntoClientArea(h, margins);
    } finally {
      free(margins);
    }
  }

  /// Set `null` for solid.
  @override
  void setWindowPlatformStyle(PlatformStyle? platformStyle) {
    if (platformStyle is! WindowsWindowStyle && platformStyle != null) return;
    final h = hwnd;
    if (h.address == 0) return;

    if (!_supportsSystemBackdrop) {
      _hasSystemBackdrop = false;
      // Windows 10 / Windows 11 21H2 fallback: DWMWA_SYSTEMBACKDROP_TYPE is unavailable.
      if (platformStyle == WindowsWindowStyle.acrylic) {
        _setFrameMargins(h, extendFullFrame: true);
        _setAccentPolicy(h, state: ACCENT_ENABLE_ACRYLICBLURBEHIND, gradientColor: 0x01000000);
      } else {
        _setAccentPolicy(h, state: ACCENT_DISABLED);
        _setFrameMargins(h, extendFullFrame: false);
      }

      SetWindowPos(
        h,
        HWND(nullptr),
        0,
        0,
        0,
        0,
        SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE,
      );
      return;
    }

    final isWindowsWindowStyle = platformStyle != null;
    _hasSystemBackdrop = isWindowsWindowStyle;

    // Reset any legacy composition accent policy
    _setAccentPolicy(h, state: ACCENT_DISABLED);

    // DWM Frame Margins:
    // - System effects require -1 margins across the entire window.
    // - Solid / None restores standard {0, 0, 1, 0} margins.
    _setFrameMargins(h, extendFullFrame: isWindowsWindowStyle);

    // Titlebar caption fill: DWMWA_COLOR_NONE (0xFFFFFFFE) for system backdrops,
    // otherwise the active theme surface COLORREF (or DWMWA_COLOR_DEFAULT 0xFFFFFFFF).
    final captionColor = calloc<DWORD>()
      ..value = isWindowsWindowStyle ? 0xFFFFFFFE : (_lastCaptionColorRef ?? 0xFFFFFFFF);
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

  /// Updates live DWM dark-mode styling and saves the current theme surface color and
  /// dark-mode flag to Windows Registry under HKCU\Software\Nordplayer so the native
  /// Win32 window and DWM caption bar match the active theme from the very first frame.
  @override
  void saveThemeColorForStartup({required Color color, required bool isDark}) {
    if (!Platform.isWindows) return;

    final r = (color.r * 255).round() & 0xFF;
    final g = (color.g * 255).round() & 0xFF;
    final b = (color.b * 255).round() & 0xFF;
    final colorValue = (r << 16) | (g << 8) | b; // 0x00RRGGBB for Registry
    final colorRef = (b << 16) | (g << 8) | r; // 0x00BBGGRR (Win32 COLORREF)
    _lastCaptionColorRef = colorRef;

    // Immediately update live DWM dark-mode attribute (and solid caption color when applicable).
    final h = hwnd;
    if (h.address != 0) {
      final darkModeData = calloc<DWORD>()..value = isDark ? 1 : 0;
      try {
        DwmSetWindowAttribute(h, DWMWA_USE_IMMERSIVE_DARK_MODE, darkModeData, sizeOf<DWORD>());
      } finally {
        free(darkModeData);
      }

      if (!_hasSystemBackdrop) {
        final captionData = calloc<DWORD>()..value = colorRef;
        try {
          DwmSetWindowAttribute(h, DWMWA_CAPTION_COLOR, captionData, sizeOf<DWORD>());
        } finally {
          free(captionData);
        }
      }
    }

    final subKey = r'Software\Nordplayer'.toPcwstr();
    final themeColorName = 'ThemeColor'.toPcwstr();
    final isDarkName = 'IsDarkMode'.toPcwstr();
    final phkResult = calloc<Pointer>();

    try {
      final createStatus = RegCreateKey(HKEY_CURRENT_USER, subKey, phkResult);

      if (createStatus == ERROR_SUCCESS) {
        final key = HKEY(phkResult.value);
        try {
          final colorData = calloc<DWORD>()..value = colorValue;
          final isDarkData = calloc<DWORD>()..value = isDark ? 1 : 0;

          try {
            RegSetValueEx(key, themeColorName, REG_DWORD, colorData.cast<Uint8>(), sizeOf<DWORD>());
            RegSetValueEx(key, isDarkName, REG_DWORD, isDarkData.cast<Uint8>(), sizeOf<DWORD>());
          } finally {
            free(colorData);
            free(isDarkData);
          }
        } finally {
          RegCloseKey(key);
        }
      }
    } finally {
      free(subKey);
      free(themeColorName);
      free(isDarkName);
      free(phkResult);
    }
  }
}
