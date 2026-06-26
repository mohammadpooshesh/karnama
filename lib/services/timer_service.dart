import 'dart:async';
import '../models/jira_issue.dart';

class TimerService {
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _pausedAt;
  int _pausedSeconds = 0;
  int _elapsedSeconds = 0;
  bool _paused = false;
  JiraIssue? _activeIssue;
  final _tickController = StreamController<int>.broadcast();

  bool get isRunning => _timer != null && !_paused;
  bool get isPaused => _paused;
  JiraIssue? get activeIssue => _activeIssue;
  int get elapsedSeconds => _paused ? _pausedSeconds : _elapsedSeconds;
  Stream<int> get tickStream => _tickController.stream;
  DateTime? get startTime => _startTime;

  void start({JiraIssue? issue}) {
    _activeIssue = issue;
    _startTime = DateTime.now();
    _paused = false;
    _pausedSeconds = 0;
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _tickController.add(_elapsedSeconds);
    });
  }

  void pause() {
    if (_paused || !_timer!.isActive) return;
    _paused = true;
    _pausedSeconds = _elapsedSeconds;
    _pausedAt = DateTime.now();
    _timer?.cancel();
    _tickController.add(_pausedSeconds);
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    final pauseDuration = DateTime.now().difference(_pausedAt!);
    _startTime = _startTime!.add(pauseDuration);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _tickController.add(_elapsedSeconds);
    });
  }

  void togglePause() {
    if (_paused) resume();
    else pause();
  }

  void changeIssue(JiraIssue issue) {
    _activeIssue = issue;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _paused = false;
    _pausedSeconds = 0;
    _tickController.add(_elapsedSeconds);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _elapsedSeconds = 0;
    _pausedSeconds = 0;
    _paused = false;
    _activeIssue = null;
    _startTime = null;
    _pausedAt = null;
    _tickController.add(0);
  }

  int get totalElapsed =>
    _paused ? _pausedSeconds : _elapsedSeconds;

  void dispose() {
    _timer?.cancel();
    _tickController.close();
  }
}
