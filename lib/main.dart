import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'services/window_title_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  runApp(const KarnamaApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initWindowHandle();
  });
}

Future<void> _initWindowHandle() async {
  const channel = MethodChannel('karnama/window');
  try {
    final hwnd = await channel.invokeMethod<int>('getHwnd');
    if (hwnd != null && hwnd != 0) {
      WindowTitleService.instance.init(hwnd);
      WindowTitleService.instance.setTitle('\u06A9\u0627\u0631\u0646\u0645\u0627');
      WindowTitleService.instance.setTrayTooltip('\u06A9\u0627\u0631\u0646\u0645\u0627');
    }
  } catch (_) {}
}
