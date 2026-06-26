import 'dart:async';
import 'package:flutter/material.dart';
import '../models/jira_issue.dart';
import '../services/timer_service.dart';
import '../services/window_title_service.dart';
import '../widgets/persian_utils.dart';

class TimerProvider extends ChangeNotifier {
  final TimerService _timerService = TimerService();
  int _elapsedSeconds = 0;
  Timer? _idleTimer;
  StreamSubscription<void>? _trayPauseSub;
  StreamSubscription<void>? _trayStopSub;

  TimerProvider() {
    _timerService.tickStream.listen((seconds) {
      _elapsedSeconds = seconds;
      _updateTitleBar();
      _updateTrayTooltip();
      notifyListeners();
    });
    _startIdleCheck();
    _trayPauseSub = WindowTitleService.instance.onTrayPause.listen((_) {
      togglePause();
    });
    _trayStopSub = WindowTitleService.instance.onTrayStop.listen((_) {
      if (isRunning || isPaused) stopTimer();
    });
  }

  void _syncTimerState() {
    int state;
    if (isPaused) state = 2;
    else if (isRunning) state = 1;
    else state = 0;
    WindowTitleService.instance.setTimerState(state);
  }

  void _startIdleCheck() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_timerService.isRunning && !_timerService.isPaused) return;
      final idle = await WindowTitleService.instance.getIdleSeconds();
      if (idle >= 300 && (_timerService.isRunning || _timerService.isPaused)) {
        _timerService.stop();
        _elapsedSeconds = _timerService.totalElapsed;
        WindowTitleService.instance.setTitle('کارنما');
        WindowTitleService.instance.setTrayTooltip('کارنما');
        WindowTitleService.instance.stopBlink();
        _syncTimerState();
        notifyListeners();
      }
    });
  }

  void _updateTitleBar() {
    if (_elapsedSeconds > 0 && isRunning) {
      final time = PersianUtils.formatPersianDuration(_elapsedSeconds);
      final issueKey = activeIssue?.key;
      final title = (issueKey != null && issueKey.isNotEmpty)
          ? 'کارنما — $time — $issueKey'
          : 'کارنما — $time';
      WindowTitleService.instance.setTitle(title);
    } else {
      WindowTitleService.instance.setTitle('کارنما');
    }
  }

  void _updateTrayTooltip() {
    if (_elapsedSeconds > 0 && (isRunning || isPaused)) {
      final time = PersianUtils.formatPersianDuration(_elapsedSeconds);
      final state = isPaused ? '⏸ ' : '';
      final issueKey = activeIssue?.key;
      final tip = (issueKey != null && issueKey.isNotEmpty)
          ? '$stateکارنما — $time — $issueKey'
          : '$stateکارنما — $time';
      WindowTitleService.instance.setTrayTooltip(tip);
    } else {
      WindowTitleService.instance.setTrayTooltip('کارنما');
    }
  }

  bool get isRunning => _timerService.isRunning;
  bool get isPaused => _timerService.isPaused;
  JiraIssue? get activeIssue => _timerService.activeIssue;
  int get elapsedSeconds => _elapsedSeconds;
  DateTime? get startTime => _timerService.startTime;

  void startTimer({JiraIssue? issue}) {
    _timerService.start(issue: issue);
    _elapsedSeconds = 0;
    _updateTitleBar();
    _updateTrayTooltip();
    WindowTitleService.instance.startBlink();
    _syncTimerState();
    notifyListeners();
  }

  void pauseTimer() {
    _timerService.pause();
    _updateTrayTooltip();
    WindowTitleService.instance.stopBlink();
    _syncTimerState();
    notifyListeners();
  }

  void resumeTimer() {
    _timerService.resume();
    WindowTitleService.instance.startBlink();
    _syncTimerState();
    notifyListeners();
  }

  void togglePause() {
    if (_timerService.isPaused) {
      resumeTimer();
    } else if (_timerService.isRunning) {
      pauseTimer();
    }
  }

  void changeIssue(JiraIssue issue) {
    _timerService.changeIssue(issue);
    _updateTitleBar();
    _updateTrayTooltip();
    notifyListeners();
  }

  void stopTimer() {
    _timerService.stop();
    _elapsedSeconds = _timerService.totalElapsed;
    WindowTitleService.instance.setTitle('کارنما');
    WindowTitleService.instance.setTrayTooltip('کارنما');
    WindowTitleService.instance.stopBlink();
    _syncTimerState();
    notifyListeners();
  }

  void cancelTimer() {
    _timerService.cancel();
    _elapsedSeconds = 0;
    WindowTitleService.instance.setTitle('کارنما');
    WindowTitleService.instance.setTrayTooltip('کارنما');
    WindowTitleService.instance.stopBlink();
    _syncTimerState();
    notifyListeners();
  }

  @override
  void dispose() {
    _trayPauseSub?.cancel();
    _trayStopSub?.cancel();
    _idleTimer?.cancel();
    _timerService.dispose();
    super.dispose();
  }
}
