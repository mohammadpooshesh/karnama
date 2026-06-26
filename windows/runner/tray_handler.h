#ifndef RUNNER_TRAY_HANDLER_H_
#define RUNNER_TRAY_HANDLER_H_

#include <windows.h>

class TrayHandler {
 public:
  TrayHandler();
  ~TrayHandler();

  bool Init(HWND mainHwnd);
  void Destroy();
  void UpdateTooltip(const wchar_t* text);
  void StartBlink();
  void StopBlink();
  bool IsBlinking() const { return blinking_; }
  void SetTimerState(int state) { timerState_ = state; }

 private:
  HWND mainHwnd_ = nullptr;
  HWND trayHwnd_ = nullptr;
  HICON restIcon_ = nullptr;
  HICON blinkOnIcon_ = nullptr;
  HICON blinkOffIcon_ = nullptr;
  int timerState_ = 0; // 0=stopped, 1=running, 2=paused
  bool initialized_ = false;
  bool blinking_ = false;
  bool blinkState_ = false;
  UINT_PTR blinkTimer_ = 0;

  static LRESULT CALLBACK TrayWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
  void ShowContextMenu(HWND hwnd);
  HICON CreateSimpleIcon(bool filled);
  void SetTrayIcon(HICON icon);
};

#endif
