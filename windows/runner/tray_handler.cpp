#include "tray_handler.h"
#include "resource.h"
#include <strsafe.h>

#define WM_TRAYICON (WM_USER + 1)
#define TRAY_ICON_ID 1001
#define TRAY_BLINK_TIMER_ID 2001

static TrayHandler* g_trayInstance = nullptr;

TrayHandler::TrayHandler() {
  g_trayInstance = this;
}

TrayHandler::~TrayHandler() {
  Destroy();
  g_trayInstance = nullptr;
}

bool TrayHandler::Init(HWND mainHwnd) {
  if (initialized_) return true;
  mainHwnd_ = mainHwnd;

  HINSTANCE hInstance = GetModuleHandle(NULL);

  WNDCLASSEX wc = {};
  wc.cbSize = sizeof(WNDCLASSEX);
  wc.lpfnWndProc = TrayWndProc;
  wc.hInstance = hInstance;
  wc.lpszClassName = L"KarnamaTray";
  RegisterClassEx(&wc);

  trayHwnd_ = CreateWindowEx(
    0, L"KarnamaTray", L"", WS_OVERLAPPEDWINDOW,
    0, 0, 0, 0, HWND_MESSAGE, NULL, hInstance, NULL
  );
  if (!trayHwnd_) return false;

  restIcon_ = (HICON)LoadImageW(hInstance, MAKEINTRESOURCEW(IDI_APP_ICON),
    IMAGE_ICON, 32, 32, LR_DEFAULTCOLOR);
  blinkOnIcon_ = CreateSimpleIcon(true);
  blinkOffIcon_ = CreateSimpleIcon(false);

  NOTIFYICONDATA nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = trayHwnd_;
  nid.uID = TRAY_ICON_ID;
  nid.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP;
  nid.uCallbackMessage = WM_TRAYICON;
  nid.hIcon = restIcon_ ? restIcon_ : blinkOffIcon_;
  wcscpy_s(nid.szTip, L"\u06A9\u0627\u0631\u0646\u0645\u0627");
  Shell_NotifyIcon(NIM_ADD, &nid);

  initialized_ = true;
  return true;
}

void TrayHandler::Destroy() {
  if (!initialized_) return;
  if (blinkTimer_) KillTimer(trayHwnd_, TRAY_BLINK_TIMER_ID);
  NOTIFYICONDATA nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = trayHwnd_;
  nid.uID = TRAY_ICON_ID;
  Shell_NotifyIcon(NIM_DELETE, &nid);
  if (blinkOnIcon_) { DestroyIcon(blinkOnIcon_); blinkOnIcon_ = nullptr; }
  if (blinkOffIcon_) { DestroyIcon(blinkOffIcon_); blinkOffIcon_ = nullptr; }
  if (restIcon_) { DestroyIcon(restIcon_); restIcon_ = nullptr; }
  if (trayHwnd_) DestroyWindow(trayHwnd_);
  trayHwnd_ = NULL;
  initialized_ = false;
}

void TrayHandler::UpdateTooltip(const wchar_t* text) {
  if (!initialized_) return;
  NOTIFYICONDATA nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = trayHwnd_;
  nid.uID = TRAY_ICON_ID;
  nid.uFlags = NIF_TIP;
  wcsncpy_s(nid.szTip, text, _TRUNCATE);
  Shell_NotifyIcon(NIM_MODIFY, &nid);
}

void TrayHandler::SetTrayIcon(HICON icon) {
  NOTIFYICONDATA nid = {};
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = trayHwnd_;
  nid.uID = TRAY_ICON_ID;
  nid.uFlags = NIF_ICON;
  nid.hIcon = icon;
  Shell_NotifyIcon(NIM_MODIFY, &nid);
}

void TrayHandler::StartBlink() {
  if (!initialized_ || blinking_) return;
  blinking_ = true;
  blinkState_ = false;
  if (blinkOnIcon_) SetTrayIcon(blinkOnIcon_);
  blinkTimer_ = SetTimer(trayHwnd_, TRAY_BLINK_TIMER_ID, 1000, NULL);
}

void TrayHandler::StopBlink() {
  if (!initialized_ || !blinking_) return;
  blinking_ = false;
  if (blinkTimer_) { KillTimer(trayHwnd_, TRAY_BLINK_TIMER_ID); blinkTimer_ = 0; }
  if (restIcon_) SetTrayIcon(restIcon_);
}

HICON TrayHandler::CreateSimpleIcon(bool filled) {
  const int w = 32, h = 32;
  const COLORREF orange = 0x00E8731A;
  const COLORREF dark = 0x002A2A2A;
  const COLORREF white = 0x00FFFFFF;

  HDC hdc = GetDC(NULL);
  HDC memDC = CreateCompatibleDC(hdc);
  HBITMAP hBitmap = CreateCompatibleBitmap(hdc, w, h);
  HBITMAP oldBmp = (HBITMAP)SelectObject(memDC, hBitmap);

  HBRUSH bgBrush = CreateSolidBrush(filled ? orange : dark);
  RECT rect = {0, 0, w, h};
  FillRect(memDC, &rect, bgBrush);
  DeleteObject(bgBrush);

  if (filled) {
    HPEN pen = CreatePen(PS_SOLID, 0, 0x00FFFFFF);
    HBRUSH fgBrush = CreateSolidBrush(white);
    SelectObject(memDC, pen);
    SelectObject(memDC, fgBrush);

    POINT play[3] = {{10, 8}, {10, 24}, {24, 16}};
    Polygon(memDC, play, 3);

    DeleteObject(pen);
    DeleteObject(fgBrush);
  } else {
    // Outline pause - two vertical bars
    HPEN pen = CreatePen(PS_SOLID, 3, white);
    SelectObject(memDC, pen);

    MoveToEx(memDC, 11, 8, NULL);
    LineTo(memDC, 11, 24);
    MoveToEx(memDC, 19, 8, NULL);
    LineTo(memDC, 19, 24);

    DeleteObject(pen);
  }

  SelectObject(memDC, oldBmp);

  ICONINFO ii = {};
  ii.fIcon = TRUE;
  ii.hbmMask = hBitmap;
  ii.hbmColor = hBitmap;
  HICON hIcon = CreateIconIndirect(&ii);

  DeleteObject(hBitmap);
  DeleteDC(memDC);
  ReleaseDC(NULL, hdc);
  return hIcon;
}

void TrayHandler::ShowContextMenu(HWND hwnd) {
  POINT pt;
  GetCursorPos(&pt);

  HMENU hMenu = CreatePopupMenu();

  if (timerState_ == 0) {
    AppendMenuW(hMenu, MF_STRING, 1001, L"\u25B6  \u0634\u0631\u0648\u0639 \u062A\u0627\u06CC\u0645\u0631");
  } else {
    AppendMenuW(hMenu, MF_STRING, 1001, L"\u23F9  \u062A\u0648\u0642\u0641");
    if (timerState_ == 1) {
      AppendMenuW(hMenu, MF_STRING, 1002, L"\u23F8  \u062A\u0648\u0642\u0641 \u0645\u0648\u0642\u062A");
    } else {
      AppendMenuW(hMenu, MF_STRING, 1002, L"\u25B6  \u0627\u062F\u0627\u0645\u0647");
    }
  }
  AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);
  AppendMenuW(hMenu, MF_STRING, 1003, L"\u25A3  \u0628\u0627\u0632 \u06A9\u0631\u062F\u0646 \u06A9\u0627\u0631\u0646\u0645\u0627");
  AppendMenuW(hMenu, MF_STRING, 1004, L"\u2699  \u062A\u0646\u0638\u06CC\u0645\u0627\u062A");
  AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);
  AppendMenuW(hMenu, MF_STRING, 1005, L"\u274C  \u062E\u0631\u0648\u062C");

  SetForegroundWindow(hwnd);
  int cmd = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_RIGHTALIGN | TPM_BOTTOMALIGN,
    pt.x, pt.y, 0, hwnd, NULL);
  DestroyMenu(hMenu);

  if (cmd == 1001 || cmd == 1003) {
    ShowWindow(mainHwnd_, SW_RESTORE);
    SetForegroundWindow(mainHwnd_);
    if (cmd == 1001 && timerState_ != 0) {
      PostMessageW(mainHwnd_, WM_USER + 101, 0, 0);
    }
  } else if (cmd == 1002) {
    if (mainHwnd_) {
      PostMessageW(mainHwnd_, WM_USER + 100, 0, 0);
    }
  } else if (cmd == 1004) {
    ShowWindow(mainHwnd_, SW_RESTORE);
    SetForegroundWindow(mainHwnd_);
  } else if (cmd == 1005) {
    DestroyWindow(mainHwnd_);
    PostQuitMessage(0);
  }
}

LRESULT CALLBACK TrayHandler::TrayWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  if (msg == WM_TRAYICON) {
    if (lParam == WM_LBUTTONUP) {
      if (g_trayInstance) {
        ShowWindow(g_trayInstance->mainHwnd_, SW_RESTORE);
        SetForegroundWindow(g_trayInstance->mainHwnd_);
      }
    } else if (lParam == WM_RBUTTONUP) {
      if (g_trayInstance) g_trayInstance->ShowContextMenu(hwnd);
    }
    return 0;
  } else if (msg == WM_TIMER && wParam == TRAY_BLINK_TIMER_ID) {
    if (g_trayInstance && g_trayInstance->blinking_) {
      g_trayInstance->blinkState_ = !g_trayInstance->blinkState_;
      HICON icon = g_trayInstance->blinkState_ ? g_trayInstance->blinkOnIcon_ : g_trayInstance->blinkOffIcon_;
      if (icon) g_trayInstance->SetTrayIcon(icon);
    }
    return 0;
  }
  return DefWindowProc(hwnd, msg, wParam, lParam);
}
