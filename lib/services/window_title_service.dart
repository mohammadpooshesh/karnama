import 'dart:async';
import 'package:flutter/services.dart';

class WindowTitleService {
  static final WindowTitleService _instance = WindowTitleService._();
  WindowTitleService._();
  static WindowTitleService get instance => _instance;

  static const _channel = MethodChannel('karnama/window');
  bool _available = false;

  final _trayPauseController = StreamController<void>.broadcast();
  final _trayStopController = StreamController<void>.broadcast();
  Stream<void> get onTrayPause => _trayPauseController.stream;
  Stream<void> get onTrayStop => _trayStopController.stream;

  void init(int hwnd) {
    _available = hwnd != 0;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTrayPause') {
        _trayPauseController.add(null);
      } else if (call.method == 'onTrayStop') {
        _trayStopController.add(null);
      }
      return null;
    });
  }

  Future<void> setTitle(String title) async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('setWindowTitle', <dynamic>[title]);
    } catch (_) {}
  }

  Future<void> setTrayTooltip(String text) async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('setTrayTooltip', <dynamic>[text]);
    } catch (_) {}
  }

  Future<void> showWindow() async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('showWindow');
    } catch (_) {}
  }

  Future<void> minimizeWindow() async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('minimizeWindow');
    } catch (_) {}
  }

  Future<void> startBlink() async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('startBlink');
    } catch (_) {}
  }

  Future<void> stopBlink() async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('stopBlink');
    } catch (_) {}
  }

  Future<void> startWindowDrag() {
    if (!_available) return Future.value();
    try {
      return _channel.invokeMethod<void>('startWindowDrag');
    } catch (_) {
      return Future.value();
    }
  }

  Future<void> closeWindow() {
    if (!_available) return Future.value();
    try {
      return _channel.invokeMethod<void>('closeWindow');
    } catch (_) {
      return Future.value();
    }
  }

  Future<int> getIdleSeconds() async {
    if (!_available) return 0;
    try {
      return await _channel.invokeMethod<int>('getIdleSeconds') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setTimerState(int state) async {
    if (!_available) return;
    try {
      await _channel.invokeMethod<void>('setTimerState', <dynamic>[state]);
    } catch (_) {}
  }

  void dispose() {
    _trayPauseController.close();
  }
}
