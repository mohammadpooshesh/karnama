import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

typedef TrayCallback = void Function(int action);

class TrayService {
  static final TrayService _instance = TrayService._();
  TrayService._();
  static TrayService get instance => _instance;

  int _trayHwnd = 0;
  bool _initialized = false;
  TrayCallback? _callback;

  void init(TrayCallback callback) {
    _callback = callback;
  }

  bool show() {
    if (_initialized) return true;
    final hInstance = GetModuleHandle(Pointer<Utf16>.fromAddress(0));

    final className = 'KarnamaTray'.toNativeUtf16();

    final wc = calloc<WNDCLASS>();
    wc.ref.style = CS_HREDRAW | CS_VREDRAW;
    wc.ref.lpfnWndProc = Pointer.fromFunction<IntPtr Function(IntPtr, Uint32, IntPtr, IntPtr)>(_wndProc, 0);
    wc.ref.hInstance = hInstance;
    wc.ref.lpszClassName = className;
    RegisterClass(wc);
    free(wc);

    _trayHwnd = CreateWindowEx(
      0, className, Pointer<Utf16>.fromAddress(0), WS_OVERLAPPEDWINDOW,
      0, 0, 0, 0, 0, 0, hInstance, Pointer.fromAddress(0),
    );
    if (_trayHwnd == 0) return false;

    final nid = calloc<NOTIFYICONDATA>();
    nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
    nid.ref.hWnd = _trayHwnd;
    nid.ref.uID = 1001;
    nid.ref.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP;
    nid.ref.uCallbackMessage = WM_APP;
    nid.ref.hIcon = _createIcon();
    nid.ref.szTip = 'کارنما';
    Shell_NotifyIcon(NIM_ADD, nid);
    free(nid);
    free(className);

    _initialized = true;
    return true;
  }

  int _createIcon() {
    final hInstance = GetModuleHandle(Pointer<Utf16>.fromAddress(0));
    final hicon = LoadImageW(
      hInstance,
      MAKEINTRESOURCEW(101),
      IMAGE_ICON,
      16, 16,
      LR_DEFAULTCOLOR,
    );
    return hicon;
  }

  void hide() {
    if (!_initialized) return;
    final nid = calloc<NOTIFYICONDATA>();
    nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
    nid.ref.hWnd = _trayHwnd;
    nid.ref.uID = 1001;
    Shell_NotifyIcon(NIM_DELETE, nid);
    free(nid);
    _initialized = false;
  }

  void updateTooltip(String text) {
    if (!_initialized) return;
    final nid = calloc<NOTIFYICONDATA>();
    nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
    nid.ref.hWnd = _trayHwnd;
    nid.ref.uID = 1001;
    nid.ref.uFlags = NIF_TIP;
    nid.ref.szTip = text;
    Shell_NotifyIcon(NIM_MODIFY, nid);
    free(nid);
  }

  static int _wndProc(int hwnd, int msg, int wParam, int lParam) {
    if (msg == WM_APP) {
      if (lParam == WM_LBUTTONUP) {
        instance._callback?.call(0);
      } else if (lParam == WM_RBUTTONUP) {
        instance._showMenu(hwnd);
      }
    } else if (msg == WM_DESTROY) {
      PostQuitMessage(0);
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
  }

  void _showMenu(int hwnd) {
    final hmenu = CreatePopupMenu();
    _addItem(hmenu, 0, MF_BYPOSITION | MF_STRING, 1001, '▶ شروع تایمر');
    _addItem(hmenu, 1, MF_BYPOSITION | MF_SEPARATOR, 0, null);
    _addItem(hmenu, 2, MF_BYPOSITION | MF_STRING, 1002, '📋 باز کردن کارنما');
    _addItem(hmenu, 3, MF_BYPOSITION | MF_STRING, 1003, '⚙ تنظیمات');
    _addItem(hmenu, 4, MF_BYPOSITION | MF_SEPARATOR, 0, null);
    _addItem(hmenu, 5, MF_BYPOSITION | MF_STRING, 1004, '🚪 خروج');

    final pt = calloc<POINT>();
    GetCursorPos(pt);
    final cmd = TrackPopupMenu(
      hmenu, TPM_RETURNCMD | TPM_RIGHTALIGN | TPM_BOTTOMALIGN,
      pt.ref.x, pt.ref.y, 0, hwnd, Pointer<RECT>.fromAddress(0),
    );
    free(pt);

    if (cmd == 1001) _callback?.call(1);
    else if (cmd == 1002) _callback?.call(2);
    else if (cmd == 1003) _callback?.call(3);
    else if (cmd == 1004) _callback?.call(4);

    DestroyMenu(hmenu);
  }

  void _addItem(int hmenu, int position, int flags, int id, String? label) {
    final pLabel = label?.toNativeUtf16();
    InsertMenu(hmenu, position, flags, id, pLabel ?? Pointer<Utf16>.fromAddress(0));
    if (pLabel != null) free(pLabel);
  }

  void destroy() {
    hide();
  }
}
