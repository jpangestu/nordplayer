#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupMouseCursorChannel();
  static LRESULT CALLBACK FlutterViewSubclassProc(
      HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam,
      UINT_PTR uIdSubclass, DWORD_PTR dwRefData);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Custom mouse cursor channel + FLUTTERVIEW subclass state to provide
  // native Windows grab/grabbing cursors for SystemMouseCursors.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      cursor_channel_;
  HWND flutter_view_hwnd_ = nullptr;
  HCURSOR grab_cursor_ = nullptr;
  HCURSOR grabbing_cursor_ = nullptr;
  HCURSOR current_cursor_ = nullptr;
  bool cursor_hidden_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
