#include "flutter_window.h"

#include <optional>
#include <string>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "tray_handler.h"

static TrayHandler g_tray;

static std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int wlen = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.c_str(), -1, nullptr, 0);
  if (wlen <= 0) {
    wlen = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  }
  if (wlen <= 0) return std::wstring();
  std::wstring result(wlen - 1, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, &result[0], wlen);
  return result;
}

static bool GetArgString(const flutter::EncodableValue* args, size_t index, std::string& out) {
  if (!args) return false;
  auto* list = std::get_if<flutter::EncodableList>(args);
  if (!list || list->size() <= index) return false;
  auto* str = std::get_if<std::string>(&(*list)[index]);
  if (!str) return false;
  out = *str;
  return true;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  g_tray.Init(GetHandle());

  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "karnama/window",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getHwnd") {
          result->Success(flutter::EncodableValue((int64_t)GetHandle()));
        } else if (call.method_name() == "setWindowTitle") {
          std::string title;
          if (GetArgString(call.arguments(), 0, title)) {
            std::wstring wtitle = Utf8ToWide(title);
            if (!wtitle.empty()) {
              SetWindowTextW(GetHandle(), wtitle.c_str());
            }
          }
          result->Success();
        } else if (call.method_name() == "setTrayTooltip") {
          std::string text;
          if (GetArgString(call.arguments(), 0, text)) {
            std::wstring wtext = Utf8ToWide(text);
            if (!wtext.empty()) {
              g_tray.UpdateTooltip(wtext.c_str());
            }
          }
          result->Success();
        } else if (call.method_name() == "startBlink") {
          g_tray.StartBlink();
          result->Success();
        } else if (call.method_name() == "stopBlink") {
          g_tray.StopBlink();
          result->Success();
        } else if (call.method_name() == "showWindow") {
          ShowWindow(GetHandle(), SW_RESTORE);
          SetForegroundWindow(GetHandle());
          result->Success();
        } else if (call.method_name() == "minimizeWindow") {
          ShowWindow(GetHandle(), SW_MINIMIZE);
          result->Success();
        } else if (call.method_name() == "startWindowDrag") {
          POINT pt;
          GetCursorPos(&pt);
          ReleaseCapture();
          PostMessageW(GetHandle(), WM_NCLBUTTONDOWN, HTCAPTION, MAKELPARAM(pt.x, pt.y));
          result->Success();
        } else if (call.method_name() == "closeWindow") {
          DestroyWindow(GetHandle());
          PostQuitMessage(0);
          result->Success();
        } else if (call.method_name() == "getIdleSeconds") {
          LASTINPUTINFO lii = {};
          lii.cbSize = sizeof(LASTINPUTINFO);
          if (GetLastInputInfo(&lii)) {
            DWORD now = GetTickCount();
            DWORD idleMs = now - lii.dwTime;
            result->Success(flutter::EncodableValue((int64_t)(idleMs / 1000)));
          } else {
            result->Success(flutter::EncodableValue(0));
          }
        } else if (call.method_name() == "setTimerState") {
          auto* list = std::get_if<flutter::EncodableList>(call.arguments());
          if (list && list->size() > 0) {
            auto* state = std::get_if<int>(&(*list)[0]);
            if (state) g_tray.SetTimerState(*state);
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  method_channel_ = std::move(channel);

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

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
    case WM_CLOSE:
      ShowWindow(hwnd, SW_MINIMIZE);
      return 0;
    case WM_USER + 100: {
      // Toggle pause from tray context menu
      if (method_channel_) {
        method_channel_->InvokeMethod("onTrayPause", nullptr);
      }
      return 0;
    }
    case WM_USER + 101: {
      // Stop/Start toggle from tray
      if (method_channel_) {
        method_channel_->InvokeMethod("onTrayStop", nullptr);
      }
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
