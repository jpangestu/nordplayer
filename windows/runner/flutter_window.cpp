#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  HWND hwnd = GetHandle();

  // Extend the frame into the client area by 1 pixel on the top
  // so that DWM retains the drop shadow, rounded corners, and aero snapping
  // when custom non-client handling is active.
  MARGINS margins = {0, 0, 1, 0};
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                   SWP_NOACTIVATE);

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  switch (message) {
    // WM_NCCALCSIZE calculates the size and position of the window's client area.
    // By handling this when wparam is TRUE and returning 0, we remove the native
    // Windows title bar while keeping native window behavior (resizing and shadows).
    case WM_NCCALCSIZE: {
      if (!wparam) {
        return 0;
      }
      auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
      if (::IsZoomed(hwnd)) {
        // When maximized, Windows expands the window frame ~8px beyond the display
        // to hide legacy borders, which would clip the custom title bar off-screen.
        // We snap the client rect to the monitor's work area (rcWork) to keep all
        // window edges and controls perfectly aligned with the visible desktop.
        HMONITOR monitor =
            ::MonitorFromRect(&params->rgrc[0], MONITOR_DEFAULTTONEAREST);
        if (monitor) {
          MONITORINFO monitor_info{};
          monitor_info.cbSize = sizeof(MONITORINFO);
          if (::GetMonitorInfoW(monitor, &monitor_info)) {
            params->rgrc[0] = monitor_info.rcWork;
          }
        }
      } else {
        // In restored (normal) mode:
        // - Retain 8px invisible non-client borders on left, bottom, and right so
        //   Windows handles native cursor resizing and DWM drop shadows automatically.
        // - Leave the top edge at 0 (unmodified) to eliminate the native title bar,
        //   allowing the custom title bar to render flush at the very top.
        params->rgrc[0].right -= 8;
        params->rgrc[0].bottom -= 8;
        params->rgrc[0].left += 8;
      }
      return 0;
    }

    // Set minimum window size
    case WM_GETMINMAXINFO: {
      auto* min_max_info = reinterpret_cast<MINMAXINFO*>(lparam);
      UINT dpi = FlutterDesktopGetDpiForMonitor(
          ::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST));
      double scale_factor = dpi / 96.0;
      min_max_info->ptMinTrackSize.x = static_cast<LONG>(640 * scale_factor);
      min_max_info->ptMinTrackSize.y = static_cast<LONG>(480 * scale_factor);
      return 0;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
